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
