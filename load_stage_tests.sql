--create temp tables
DROP TABLE IF EXISTS concept_tmp_2020_03_04_3;
CREATE TABLE IF NOT EXISTS concept_tmp_2020_03_04_3
as (select * from concept);

DROP TABLE IF EXISTS concept_relationship_tmp_2020_03_04_3;
CREATE TABLE IF NOT EXISTS concept_relationship_tmp_2020_03_04_3
as (select * from concept_relationship);

DROP TABLE IF EXISTS concept_ancestor_tmp_2020_03_04_3;
CREATE TABLE IF NOT EXISTS concept_ancestor_tmp_2020_03_04_3
as (select * from concept_ancestor);



--compare concept between schemas
with first as (
                SELECT a.*, 'concept_tmp_2020_03_04_3' as schema
                FROM (   SELECT --concept_id,
                                concept_name,
                                domain_id,
                                vocabulary_id,
                                concept_class_id,
                                standard_concept,
                                concept_code,
                                valid_start_date,
                                valid_end_date,
                                invalid_reason
                         FROM dev_loinc.concept_tmp_2020_03_04_3

                         EXCEPT

                         SELECT --concept_id,
                                concept_name,
                                domain_id,
                                vocabulary_id,
                                concept_class_id,
                                standard_concept,
                                concept_code,
                                valid_start_date,
                                valid_end_date,
                                invalid_reason
                         FROM dev_loinc.concept_tmp_2020_02_25_1
                     ) as a ),

second as (

                SELECT b.*, 'concept_tmp_2020_02_25_1' as schema
                FROM (   SELECT --concept_id,
                                concept_name,
                                domain_id,
                                vocabulary_id,
                                concept_class_id,
                                standard_concept,
                                concept_code,
                                valid_start_date,
                                valid_end_date,
                                invalid_reason
                         FROM dev_loinc.concept_tmp_2020_02_25_1

                         EXCEPT

                         SELECT --concept_id,
                                concept_name,
                                domain_id,
                                vocabulary_id,
                                concept_class_id,
                                standard_concept,
                                concept_code,
                                valid_start_date,
                                valid_end_date,
                                invalid_reason
                         FROM dev_loinc.concept_tmp_2020_03_04_3
                     ) as b )

--changed and new concepts
SELECT *
from first
WHERE vocabulary_id = 'LOINC'
UNION ALL
SELECT *
from second
WHERE vocabulary_id = 'LOINC'


--new concepts
--SELECT * from first
--WHERE concept_id NOT IN (SELECT concept_id FROM second)

--changed concepts
/*SELECT first.*, devv5.levenshtein(first.concept_name, second.concept_name)
from first
LEFT JOIN second ON first.concept_id = second.concept_id

WHERE first.concept_id IN (SELECT concept_id FROM second)


UNION ALL

SELECT second.*, devv5.levenshtein(second.concept_name, first.concept_name)
from second
LEFT JOIN first ON first.concept_id = second.concept_id*/
;


--compare CR between schemas
with first as (
    SELECT a.concept_id_1,
           a.concept_id_2,
           a.relationship_id,
           a.invalid_reason,
           a.valid_start_date,
           a.valid_end_date,
           'concept_relationship_tmp_2020_02_25_2' as schema,
           c.vocabulary_id

    FROM (SELECT *--concept_id_1, concept_id_2, relationship_id, invalid_reason
          FROM dev_loinc.concept_relationship_tmp_2020_02_25_2

              EXCEPT

          SELECT *--concept_id_1, concept_id_2, relationship_id, invalid_reason
          FROM dev_loinc.concept_relationship_tmp_2020_02_25_1
         ) as a

             LEFT JOIN dev_loinc.concept c
                       ON concept_id_1 = c.concept_id
),

second  as (

    SELECT b.concept_id_1,
           b.concept_id_2,
           b.relationship_id,
           b.invalid_reason,
           b.valid_start_date,
           b.valid_end_date,
           'concept_relationship_tmp_2020_02_25_1' as schema,
           c.vocabulary_id

    FROM (SELECT *--concept_id_1, concept_id_2, relationship_id, invalid_reason
          FROM dev_loinc.concept_relationship_tmp_2020_02_25_1

              EXCEPT

          SELECT *--concept_id_1, concept_id_2, relationship_id, invalid_reason
          FROM dev_loinc.concept_relationship_tmp_2020_02_25_2
         ) as b

             LEFT JOIN dev_loinc.concept c
                       ON concept_id_1 = c.concept_id
)
--changed and new relationships
SELECT *
FROM first
--WHERE vocabulary_id IN ('NDC', 'SPL') AND relationship_id = 'Maps to'
UNION ALL
SELECT *
FROM second
--WHERE vocabulary_id IN ('NDC', 'SPL') AND relationship_id = 'Maps to'

--new mappings
/*SELECT * from first
WHERE concept_id_1 NOT IN (SELECT concept_id_1 FROM second WHERE concept_id_1 IS NOT NULL) AND vocabulary_id IN ('NDC', 'SPL') AND relationship_id = 'Maps to'*/


--changed mappings
/*SELECT f.concept_id_1,
       c.concept_code,
       c.concept_name,
       f.concept_id_2,
       cc.concept_name,
       f.relationship_id,
       f.invalid_reason,
       f.valid_start_date,
       f.valid_end_date,
       f.schema,
       f.vocabulary_id
from first f
LEFT JOIN devv5.concept c
    ON f.concept_id_1 = c.concept_id
LEFT JOIN devv5.concept cc
    ON f.concept_id_2 = cc.concept_id
WHERE concept_id_1 IN (SELECT concept_id_1 FROM second WHERE concept_id_1 IS NOT NULL)
    AND f.vocabulary_id IN ('NDC', 'SPL') AND relationship_id = 'Maps to'

UNION ALL

SELECT s.concept_id_1,
       c.concept_code,
       c.concept_name,
       s.concept_id_2,
       cc.concept_name,
       s.relationship_id,
       s.invalid_reason,
       s.valid_start_date,
       s.valid_end_date,
       s.schema,
       s.vocabulary_id
from second s
LEFT JOIN devv5.concept c
    ON s.concept_id_1 = c.concept_id
LEFT JOIN devv5.concept cc
    ON s.concept_id_2 = cc.concept_id
WHERE concept_id_1 IN (SELECT concept_id_1 FROM first WHERE concept_id_1 IS NOT NULL)
    AND s.vocabulary_id IN ('NDC', 'SPL') AND relationship_id = 'Maps to'*/
;


--compare CR_stage between schemas
with first as (
    SELECT a.concept_code_1,
           a.concept_code_2,
           a.vocabulary_id_1,
           a.vocabulary_id_2,
           a.relationship_id,
           a.invalid_reason,
           --a.valid_start_date,
           --a.valid_end_date,
           'dev_loinc' as schema

    FROM (SELECT concept_id_1,
                 concept_id_2,
                 concept_code_1,
                 concept_code_2,
                 vocabulary_id_1,
                 vocabulary_id_2,
                 relationship_id,
                 --valid_start_date,
                 --valid_end_date,
                 invalid_reason
          FROM dev_loinc.concept_relationship_stage

              EXCEPT

          SELECT concept_id_1,
                 concept_id_2,
                 concept_code_1,
                 concept_code_2,
                 vocabulary_id_1,
                 vocabulary_id_2,
                 relationship_id,
                 --valid_start_date,
                 --valid_end_date,
                 invalid_reason
          FROM dev_test.concept_relationship_stage
         ) as a

),

second  as (

    SELECT b.concept_code_1,
           b.concept_code_2,
           b.vocabulary_id_1,
           b.vocabulary_id_2,
           b.relationship_id,
           b.invalid_reason,
           --b.valid_start_date,
           --b.valid_end_date,
           'dev_test' as schema

    FROM (SELECT concept_id_1,
                 concept_id_2,
                 concept_code_1,
                 concept_code_2,
                 vocabulary_id_1,
                 vocabulary_id_2,
                 relationship_id,
                 --valid_start_date,
                 --valid_end_date,
                 invalid_reason
          FROM dev_test.concept_relationship_stage

              EXCEPT

          SELECT concept_id_1,
                 concept_id_2,
                 concept_code_1,
                 concept_code_2,
                 vocabulary_id_1,
                 vocabulary_id_2,
                 relationship_id,
                 --valid_start_date,
                 --valid_end_date,
                 invalid_reason
          FROM dev_loinc.concept_relationship_stage
         ) as b

)
--changed and new relationships
SELECT *
FROM first
WHERE vocabulary_id_1 IN ('LOINC')-- AND relationship_id = 'Maps to'
UNION ALL
SELECT *
FROM second
WHERE vocabulary_id_1 IN ('LOINC')-- AND relationship_id = 'Maps to'

--new mappings
/*SELECT * from first
WHERE concept_id_1 NOT IN (SELECT concept_id_1 FROM second WHERE concept_id_1 IS NOT NULL) AND vocabulary_id IN ('NDC', 'SPL') AND relationship_id = 'Maps to'*/


--changed mappings
/*SELECT f.concept_id_1,
       c.concept_code,
       c.concept_name,
       f.concept_id_2,
       cc.concept_name,
       f.relationship_id,
       f.invalid_reason,
       f.valid_start_date,
       f.valid_end_date,
       f.schema,
       f.vocabulary_id
from first f
LEFT JOIN devv5.concept c
    ON f.concept_id_1 = c.concept_id
LEFT JOIN devv5.concept cc
    ON f.concept_id_2 = cc.concept_id
WHERE concept_id_1 IN (SELECT concept_id_1 FROM second WHERE concept_id_1 IS NOT NULL)
    AND f.vocabulary_id IN ('NDC', 'SPL') AND relationship_id = 'Maps to'

UNION ALL

SELECT s.concept_id_1,
       c.concept_code,
       c.concept_name,
       s.concept_id_2,
       cc.concept_name,
       s.relationship_id,
       s.invalid_reason,
       s.valid_start_date,
       s.valid_end_date,
       s.schema,
       s.vocabulary_id
from second s
LEFT JOIN devv5.concept c
    ON s.concept_id_1 = c.concept_id
LEFT JOIN devv5.concept cc
    ON s.concept_id_2 = cc.concept_id
WHERE concept_id_1 IN (SELECT concept_id_1 FROM first WHERE concept_id_1 IS NOT NULL)
    AND s.vocabulary_id IN ('NDC', 'SPL') AND relationship_id = 'Maps to'*/
;





--compare CA between schemas
with first as (
    SELECT a.ancestor_concept_id,
           a.descendant_concept_id,
           a.min_levels_of_separation,
           a.max_levels_of_separation,
           'concept_ancestor_tmp_2020_02_19_1' as schema,
           anc.vocabulary_id as ancestor_vocabulary_id,
           des.vocabulary_id as descendant_vocabulary_id

    FROM (SELECT *
          FROM dev_loinc.concept_ancestor_tmp_2020_02_19_1

              EXCEPT

          SELECT *
          FROM dev_loinc.concept_ancestor_tmp_2020_02_19_2
         ) as a

             LEFT JOIN dev_loinc.concept anc
                       ON a.ancestor_concept_id = anc.concept_id

             LEFT JOIN dev_loinc.concept des
                       ON a.descendant_concept_id = des.concept_id
),

second  as (

    SELECT b.ancestor_concept_id,
           b.descendant_concept_id,
           b.min_levels_of_separation,
           b.max_levels_of_separation,
           'concept_ancestor_tmp_2020_02_19_2' as schema,
           anc.vocabulary_id as ancestor_vocabulary_id,
           des.vocabulary_id as descendant_vocabulary_id

    FROM (SELECT *
          FROM dev_loinc.concept_ancestor_tmp_2020_02_19_2

              EXCEPT

          SELECT *
          FROM dev_loinc.concept_ancestor_tmp_2020_02_19_1
         ) as b

             LEFT JOIN dev_loinc.concept anc
                       ON b.ancestor_concept_id = anc.concept_id

             LEFT JOIN dev_loinc.concept des
                       ON b.descendant_concept_id = des.concept_id
)
SELECT *
FROM first
--WHERE   (ancestor_vocabulary_id IN ('LOINC', 'SNOMED') AND descendant_vocabulary_id IN ('LOINC')) AND ancestor_concept_id != descendant_concept_id

UNION ALL

SELECT *
FROM second
--WHERE   (ancestor_vocabulary_id IN ('LOINC', 'SNOMED') AND descendant_vocabulary_id IN ('LOINC')) AND ancestor_concept_id != descendant_concept_id
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


SELECT DISTINCT c.*

FROM devv5.concept_relationship cr

JOIN devv5.concept c
    ON cr.concept_id_1 = c.concept_id AND c.vocabulary_id = 'NDC'

JOIN devv5.concept cc
    ON cr.concept_id_2 = cc.concept_id AND cc.vocabulary_id = 'NDC'


WHERE TRUE
    AND cr.relationship_id = 'Maps to' AND cr.invalid_reason IS  NULL AND cr.valid_start_date > '2019-11-05'