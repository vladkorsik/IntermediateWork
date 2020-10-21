--check active queries in Postgres
SELECT *
FROM pg_stat_activity
--WHERE pid = 123
WHERE state = 'active';


--DO syntax
--https://github.com/Alexdavv/IntermediateWork/blob/master/DO%20syntax.sql


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