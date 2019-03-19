SELECT COUNT (*)
FROM (
    SELECT DISTINCT source_code as concept_code
    FROM tested_vocabulary
         ) as a
WHERE EXISTS
      (select 1
      FROM concept c
      WHERE a.concept_code = c.concept_code
            AND c.vocabulary_id in ('ICD10', 'ICD10CM')
);
