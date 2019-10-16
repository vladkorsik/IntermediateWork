--create temp tables
--DROP TABLE dev_ndc.concept_relationship_tmp;
CREATE TABLE dev_ndc.concept_relationship_tmp
as (select * from dev_ndc.concept_relationship);


--DROP TABLE dev_ndc.concept_tmp;
CREATE TABLE dev_ndc.concept_tmp
as (select * from dev_ndc.concept);




--compare concept between schemas
SELECT a.*, 'devv5' as schema
FROM (   SELECT concept_id,
                concept_name,
                domain_id,
                vocabulary_id,
                concept_class_id,
                standard_concept,
                concept_code,
                valid_start_date,
                valid_end_date,
                invalid_reason
         FROM devv5.concept


         EXCEPT

         SELECT concept_id,
                concept_name,
                domain_id,
                vocabulary_id,
                concept_class_id,
                standard_concept,
                concept_code,
                valid_start_date,
                valid_end_date,
                invalid_reason
         FROM prodv5.concept
     ) as a

UNION ALL

SELECT b.*, 'prodv5' as schema
FROM (   SELECT concept_id,
                concept_name,
                domain_id,
                vocabulary_id,
                concept_class_id,
                standard_concept,
                concept_code,
                valid_start_date,
                valid_end_date,
                invalid_reason
         FROM prodv5.concept

         EXCEPT

         SELECT concept_id,
                concept_name,
                domain_id,
                vocabulary_id,
                concept_class_id,
                standard_concept,
                concept_code,
                valid_start_date,
                valid_end_date,
                invalid_reason
         FROM devv5.concept
     ) as b
;


SELECT *
FROM devv5.concept
WHERE concept_id IN (44818378)
;


SELECT *
FROM devv5.concept_relationship
WHERE concept_id_1 = 44818378
;



--compare CR between schemas
with a as (
    SELECT a.concept_id_1,
           a.concept_id_2,
           a.relationship_id,
           a.invalid_reason,
           a.valid_start_date,
           a.valid_end_date,
           'devv5' as schema,
           c.vocabulary_id
    FROM (SELECT *--concept_id_1, concept_id_2, relationship_id, invalid_reason
          FROM devv5.concept_relationship
              EXCEPT

          SELECT *--concept_id_1, concept_id_2, relationship_id, invalid_reason
          FROM dev_ndc.concept_relationship
         ) as a
             LEFT JOIN devv5.concept c
                       ON concept_id_1 = c.concept_id

    UNION ALL

    SELECT b.concept_id_1,
           b.concept_id_2,
           b.relationship_id,
           b.invalid_reason,
           b.valid_start_date,
           b.valid_end_date,
           'dev_ndc' as schema,
           c.vocabulary_id
    FROM (SELECT *--concept_id_1, concept_id_2, relationship_id, invalid_reason
          FROM dev_ndc.concept_relationship
              EXCEPT

          SELECT *--concept_id_1, concept_id_2, relationship_id, invalid_reason
          FROM devv5.concept_relationship
         ) as b
             LEFT JOIN devv5.concept c
                       ON concept_id_1 = c.concept_id
)

SELECT *
FROM a
WHERE relationship_id = 'Maps to'
;


--compare CR_stage between current and tmp
SELECT a.concept_code_1, a.concept_code_2, a.vocabulary_id_1, a.vocabulary_id_2, a.relationship_id, a.invalid_reason, a.valid_start_date, a.valid_end_date, 'current' as schema, c.vocabulary_id
FROM (   SELECT *--concept_id_1, concept_id_2, relationship_id, invalid_reason
         FROM concept_relationship_stage

         EXCEPT

         SELECT *--concept_id_1, concept_id_2, relationship_id, invalid_reason
         FROM concept_relationship_stage_tmp
     ) as a
LEFT JOIN devv5.concept c
    ON concept_code_1 = c.concept_code AND vocabulary_id_1 = c.vocabulary_id

UNION ALL

SELECT b.concept_code_1, b.concept_code_2, b.vocabulary_id_1, b.vocabulary_id_2, b.relationship_id, b.invalid_reason, b.valid_start_date, b.valid_end_date, 'temp' as schema, c.vocabulary_id
FROM (   SELECT *--concept_id_1, concept_id_2, relationship_id, invalid_reason
         FROM concept_relationship_stage_tmp

         EXCEPT

         SELECT *--concept_id_1, concept_id_2, relationship_id, invalid_reason
         FROM concept_relationship_stage
     ) as b
LEFT JOIN devv5.concept c
    ON concept_code_1 = c.concept_code AND vocabulary_id_1 = c.vocabulary_id
;





SELECT *
FROM devv5.concept_relationship
WHERE concept_id_1 = 40177067;


SELECT *
FROM devv5.concept
WHERE concept_id = 40177067;


SELECT *
FROM dev_ypaulenka.concept c
WHERE concept_id = 45340431;









--to check mappings are gone from devv_ndc
with gone as (
SELECT cr.*
FROM devv5.concept_relationship cr

JOIN devv5.concept c
    ON cr.concept_id_1 = c.concept_id AND c.vocabulary_id = 'NDC'

JOIN devv5.concept cc
    ON cr.concept_id_2 = cc.concept_id AND cc.standard_concept = 'S' AND cc.invalid_reason IS NULL

WHERE cr.invalid_reason IS NULL AND cr.relationship_id = 'Maps to'

    AND NOT EXISTS(
        SELECT 1
        FROM dev_ndc.concept_relationship cr2
        WHERE cr2.concept_id_1 = cr.concept_id_1
            AND cr2.relationship_id = cr.relationship_id
            AND cr2.invalid_reason IS NULL
    )
)
SELECT * FROM gone
;




--check if all the mapping was inserted
--check CR
SELECT *
FROM dalex.ndc_concept_relationship_manual_2019_09_16_modifications crm
LEFT JOIN devv5.concept c
    ON crm.concept_code_1 = c.concept_code AND crm.vocabulary_id_1 = c.vocabulary_id

LEFT JOIN devv5.concept cc
    ON crm.concept_code_2 = cc.concept_code AND crm.vocabulary_id_2 = cc.vocabulary_id

WHERE NOT EXISTS    (
    SELECT 1
    FROM dev_ndc.concept_relationship cr
    WHERE cr.concept_id_1 = c.concept_id AND
          cr.concept_id_2 = cc.concept_id AND
          crm.relationship_id = cr.relationship_id AND
          cr.invalid_reason IS NULL
    )

AND NOT EXISTS(
    SELECT 1
    FROM dev_ndc.concept_relationship crr
    WHERE crr.concept_id_1 = c.concept_id AND
          crm.relationship_id = crr.relationship_id AND
          crr.invalid_reason IS NULL
    )
;

--check if all the mapping was inserted
--check CR_stage
SELECT *
FROM dalex.ndc_concept_relationship_manual_2019_09_16_modifications crm
LEFT JOIN devv5.concept c
    ON crm.concept_code_1 = c.concept_code AND crm.vocabulary_id_1 = c.vocabulary_id

WHERE NOT EXISTS    (
    SELECT 1
    FROM dev_ndc.concept_relationship_stage cr
    WHERE cr.concept_code_1 = crm.concept_code_1 AND
          cr.concept_code_2 = crm.concept_code_2 AND
          cr.vocabulary_id_1 = crm.vocabulary_id_1 AND
          cr.vocabulary_id_2 = crm.vocabulary_id_2 AND
          crm.relationship_id = cr.relationship_id AND
          cr.invalid_reason IS NULL
    )
AND NOT EXISTS(
    SELECT 1
    FROM dev_ndc.concept_relationship crr
    WHERE crr.concept_id_1 = c.concept_id AND
          crm.relationship_id = crr.relationship_id AND
          crr.invalid_reason IS NULL
    )
;

--check if 1-to-many mapping originates only from CR_manual
SELECT *
FROM dev_ndc.concept_relationship cr
WHERE concept_id_1 IN (
    SELECT concept_id_1
    FROM dev_ndc.concept_relationship crr
    JOIN devv5.concept c
        ON crr.concept_id_1 = c.concept_id
            AND c.vocabulary_id = 'NDC'
    WHERE crr.invalid_reason IS NULL
        AND crr.relationship_id = 'Maps to'
    GROUP BY concept_id_1
    HAVING COUNT(*) > 1
    )
AND cr.invalid_reason IS NULL
AND NOT EXISTS (SELECT 1
                FROM dev_ndc.concept_relationship_manual crm
                LEFT JOIN devv5.concept cc ON crm.concept_code_1 = cc.concept_code AND crm.vocabulary_id_1 = cc.vocabulary_id
                LEFT JOIN devv5.concept ccc ON crm.concept_code_2 = ccc.concept_code AND crm.vocabulary_id_2 = ccc.vocabulary_id
                WHERE cr.concept_id_1 = cc.concept_id
                    AND cr.concept_id_2 = ccc.concept_id
                    AND cr.relationship_id = crm.relationship_id
                    AND crm.invalid_reason IS NULL
        )
;




SELECT *
FROM concept_relationship_manual;



SELECT *
FROM dev_ndc.concept_relationship_manual
WHERE concept_code_1 = '54569650500';

SELECT *
FROM dev_ndc.concept_relationship_stage
WHERE concept_code_1 = '54569650500';

SELECT *
FROM dev_ndc.concept_relationship
WHERE concept_id_1 = 45013905;

SELECT *
FROM devv5.concept_relationship
WHERE concept_id_1 = 45842474;

