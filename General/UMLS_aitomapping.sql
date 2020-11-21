SELECT
    s.*,
    c.concept_id as target_concept_id,
    c.concept_name as target_concept_name,
    c.domain_id as target_domain_id,
    c.vocabulary_id as target_vocabulary_id,
    c.concept_class_id as target_concept_class_id,
    c.standard_concept as target_standard_concept,
    c.concept_code as target_concept_code,
    c.invalid_reason as target_invalid_reason
FROM working_schema.projectname_vocabularyname_source s
JOIN sources.mrconso m
ON lower(regexp_replace(s.source_code,'\s','','g'))=lower(regexp_replace(m.str,'\s','','g')) -- or s.source_code_description
AND m.lat IN ('ENG'/*,'FRE','GER'*/)
    JOIN sources.mrconso m2
    ON m.cui=m2.cui
JOIN voc_schema.concept c
ON c.concept_code=m2.code
AND CASE WHEN lower(m2.sab)<>lower(c.vocabulary_id) AND m2.sab ilike 'LNC%' THEN 'LOINC'
                  WHEN lower(m2.sab)<>lower(c.vocabulary_id) AND m2.sab ilike 'SNOMED%' THEN 'SNOMED'
                 WHEN lower(m2.sab)<>lower(c.vocabulary_id) AND m2.sab ilike 'MSH%' THEN 'MeSH'
                 WHEN lower(m2.sab)<>lower(c.vocabulary_id) AND m2.sab IN ('ICD10','ICD10AE','ICD10AM','ICD10AMAE') THEN 'ICD10CM'
     WHEN lower(m2.sab)<>lower(c.vocabulary_id) AND m2.sab ilike 'MDR%' THEN 'MedDRA'
ELSE upper(m2.sab) END =upper(c.vocabulary_id)
WHERE c.standard_concept='S'
;

SELECT
    s.*,
    c.concept_id as target_concept_id,
    c.concept_name as target_concept_name,
    c.domain_id as target_domain_id,
    c.vocabulary_id as target_vocabulary_id,
    c.concept_class_id as target_concept_class_id,
    c.standard_concept as target_standard_concept,
    c.concept_code as target_concept_code,
    c.invalid_reason as target_invalid_reason
FROM dev_merck.merck_premier_ph_labrestest_source s
LEFT JOIN sources.mrconso m
ON lower(s.source_code)=lower(m.str) -- or s.source_code_description
AND m.lat IN ('ENG'/*,'FRE','GER'*/)
    LEFT JOIN sources.mrconso m2
    ON m.cui=m2.cui
LEFT JOIN devv5.concept c
ON c.concept_code=m2.code
AND CASE WHEN lower(m2.sab)<>lower(c.vocabulary_id) AND m2.sab ilike 'LNC%' THEN 'LOINC'
                  WHEN lower(m2.sab)<>lower(c.vocabulary_id) AND m2.sab ilike 'SNOMED%' THEN 'SNOMED'
                 WHEN lower(m2.sab)<>lower(c.vocabulary_id) AND m2.sab ilike 'MSH%' THEN 'MeSH'
                 WHEN lower(m2.sab)<>lower(c.vocabulary_id) AND m2.sab IN ('ICD10','ICD10AE','ICD10AM','ICD10AMAE') THEN 'ICD10CM'
     WHEN lower(m2.sab)<>lower(c.vocabulary_id) AND m2.sab ilike 'MDR%' THEN 'MedDRA'
ELSE upper(m2.sab) END =upper(c.vocabulary_id)
AND  c.standard_concept='S'
;
