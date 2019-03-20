SELECT COUNT (*)
FROM (
    SELECT DISTINCT source_code as concept_code
    FROM tested_vocabulary
         ) as a
WHERE EXISTS
      (SELECT 1
      FROM concept c
      WHERE a.concept_code = c.concept_code
            AND c.vocabulary_id in ('ICD10', 'ICD10CM')
      );


SELECT COUNT (*)
FROM (
    SELECT DISTINCT source_code as concept_code
    FROM tested_vocabulary
         ) as a
WHERE EXISTS
      (SELECT 1
      FROM concept c
            JOIN concept_relationship cr
                  ON c.concept_id = cr.concept_id_1
      WHERE a.concept_code = c.concept_code
            AND c.vocabulary_id in ('ICD10', 'ICD10CM')
            AND cr.relationship_id = 'Maps to'
            AND cr.invalid_reason IS NULL
      );




SELECT t.source_code, t.concept_name, c.concept_name
FROM tested_vocabulary t

JOIN concept c
         ON c.concept_code = t.source_code
             AND c.vocabulary_id in ('ICD10', 'ICD10CM')

WHERE NOT exists(
      SELECT 1
      FROM concept cc
      WHERE t.source_code = cc.concept_code
      AND cc.vocabulary_id in ('ICD10')
    )
ORDER BY RANDOM ()
LIMIT 1000;


.
