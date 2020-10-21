--check active queries in Postgres
SELECT *
FROM pg_stat_activity
--WHERE pid = 123
WHERE state = 'active';


--DO syntax
--https://github.com/Alexdavv/IntermediateWork/blob/master/DO%20syntax.sql


--check first vacant concept_id for manual change
SELECT MAX (concept_id) + 1 FROM devv5.concept WHERE concept_id >= 31967 AND concept_id < 72245;


--check first vacant concept_code among OMOP generated
select 'OMOP'||max(replace(concept_code, 'OMOP','')::int4)+1 from devv5.concept where concept_code like 'OMOP%'  and concept_code not like '% %';


--create sequence starting from first vacant concept_code among OMOP generated
DO $$
DECLARE
	ex INTEGER;
BEGIN
	SELECT MAX(REPLACE(concept_code, 'OMOP','')::int4)+1 INTO ex FROM (
		SELECT concept_code FROM concept WHERE concept_code LIKE 'OMOP%'  AND concept_code NOT LIKE '% %' -- Last valid value of the OMOP123-type codes
			) AS s0;
	DROP SEQUENCE IF EXISTS omop_seq;
	EXECUTE 'CREATE SEQUENCE omop_seq INCREMENT BY 1 START WITH ' || ex || ' NO CYCLE CACHE 20';
END$$;


-- Drug Forms currently used in OMOP Drugs
with ings AS (

SELECT DISTINCT c.*
FROM devv5.concept c

JOIN devv5.concept_relationship cr
    ON c.concept_id = cr.concept_id_1
        AND cr.invalid_reason IS NULL
        --AND cr.relationship_id = 'RxNorm dose form of'

JOIN devv5.concept cc
    ON cr.concept_id_2 = cc.concept_id
        AND cc.vocabulary_id like 'RxNorm%'
        AND cc.invalid_reason IS NULL
        AND cc.standard_concept = 'S'

WHERE c.vocabulary_id like 'RxNorm%'
    AND c.concept_class_id = 'Dose Form'
    AND c.invalid_reason IS NULL)

SELECT DISTINCT string_agg (DISTINCT c3.concept_name, ' | '),
                ings.concept_id,
                ings.concept_code,
                ings.concept_name,
                ings.concept_class_id,
                ings.standard_concept,
                ings.invalid_reason,
                ings.domain_id,
                ings.vocabulary_id

FROM ings

LEFT JOIN devv5.concept_relationship cr2
    ON ings.concept_id = cr2.concept_id_1
        AND cr2.relationship_id = 'RxNorm is a'
        AND cr2.invalid_reason IS NULL

LEFT JOIN devv5.concept c3
    ON cr2.concept_id_2 = c3.concept_id
    AND c3.concept_class_id IN ('Dose Form Group')

GROUP BY
                ings.concept_id,
                ings.concept_code,
                ings.concept_name,
                ings.concept_class_id,
                ings.standard_concept,
                ings.invalid_reason,
                ings.domain_id,
                ings.vocabulary_id

ORDER BY 1
;


-- Drug Forms currently NOT used in OMOP Drugs
SELECT DISTINCT c.*
FROM devv5.concept c
WHERE c.vocabulary_id like 'RxNorm%'
    AND c.concept_class_id = 'Dose Form'
    AND c.invalid_reason IS NULL
    AND c.concept_id NOT IN (
            SELECT DISTINCT c.concept_id
            FROM devv5.concept c

            JOIN devv5.concept_relationship cr
                ON c.concept_id = cr.concept_id_1
                    AND cr.invalid_reason IS NULL
                    AND cr.relationship_id = 'RxNorm dose form of'

            JOIN devv5.concept cc
                ON cr.concept_id_2 = cc.concept_id
                    AND cc.vocabulary_id like 'RxNorm%'
                    AND cc.invalid_reason IS NULL
                    AND cc.standard_concept = 'S'

            WHERE c.vocabulary_id like 'RxNorm%'
                AND c.concept_class_id = 'Dose Form'
                AND c.invalid_reason IS NULL
            )
;