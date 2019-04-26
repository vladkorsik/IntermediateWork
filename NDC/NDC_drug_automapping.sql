--table with drugs to be mapped
DROP TABLE IF EXISTS NDC_drugs_to_map
;
CREATE TABLE IF NOT EXISTS NDC_drugs_to_map AS
    (SELECT *
    FROM ndc_drugs
    UNION ALL
    SELECT *
    FROM ndc_remains
    )
;


--table with completed mapping
DROP TABLE IF EXISTS NDC_drugs_mapped
;
CREATE TABLE IF NOT EXISTS NDC_drugs_mapped AS
    (SELECT concept_id,
            concept_name,
            concept_id as target_concept_id,
            concept_name as target_concept_name,
            concept_class_id as target_concept_class_id,
            vocabulary_id as target_vocabulary_id
     FROM devv5.concept
    WHERE FALSE
    )
;

--0
--identical names
INSERT INTO NDC_drugs_mapped
SELECT n.concept_id AS concept_id,
       n.concept_name AS concept_name,
       c2.concept_id as target_concept_id,
       c2.concept_name as target_concept_name,
       c2.vocabulary_id as target_vocabulary_id,
       c2.concept_class_id as target_concept_class_id
FROM NDC_drugs_to_map n
JOIN devv5.concept c2 ON lower(trim(n.concept_name)) = lower(c2.concept_name)
                             and c2.vocabulary_id in ('RxNorm', 'RxNorm Extension')
                             and c2.standard_concept = 'S'
                             and c2.invalid_reason is NULL;
DELETE FROM NDC_drugs_to_map WHERE concept_id IN (SELECT concept_id FROM NDC_drugs_mapped);


--1
INSERT INTO NDC_drugs_mapped
SELECT n.concept_id AS concept_id,
       n.concept_name AS concept_name,
       c2.concept_id as target_concept_id,
       c2.concept_name as target_concept_name,
       c2.vocabulary_id as target_vocabulary_id,
       c2.concept_class_id as target_concept_class_id
FROM NDC_drugs_to_map n
JOIN devv5.concept c2 ON trim(regexp_replace(lower(n.concept_name),' \[.*\]','')) = lower(c2.concept_name)
                             and c2.vocabulary_id in ('RxNorm', 'RxNorm Extension')
                             and c2.standard_concept = 'S'
                             and c2.invalid_reason is NULL;

DELETE FROM NDC_drugs_to_map WHERE concept_id IN (SELECT concept_id FROM NDC_drugs_mapped);


--2
INSERT INTO NDC_drugs_mapped
SELECT n.concept_id AS concept_id,
       n.concept_name AS concept_name,
       c2.concept_id as target_concept_id,
       c2.concept_name as target_concept_name,
       c2.vocabulary_id as target_vocabulary_id,
       c2.concept_class_id as target_concept_class_id
FROM NDC_drugs_to_map n
JOIN devv5.concept c2 ON regexp_replace(trim(regexp_replace(lower(n.concept_name),'injection','injectable solution')), ' \[.*\]', '') = lower(c2.concept_name)
                             and c2.vocabulary_id in ('RxNorm', 'RxNorm Extension')
                             and c2.standard_concept = 'S'
                             and c2.invalid_reason is NULL;

DELETE FROM NDC_drugs_to_map WHERE concept_id IN (SELECT concept_id FROM NDC_drugs_mapped);






select n.concept_id, n.concept_name, c2.* from NDC_drugs_to_map n
join devv5.concept c2 on regexp_replace(trim(regexp_replace(lower(n.concept_name),'injection','injectable solution')), ' \[.*\]', '') = lower(c2.concept_name)
                             and c2.vocabulary_id in ('RxNorm', 'RxNorm Extension')
                             and c2.standard_concept = 'S';


--checking for duplicates
with duplicates as (Select concept_id, count(distinct target_concept_id)
From NDC_drugs_mapped
Group by concept_id
Having count(distinct target_concept_id) > 1)
select n.concept_id, n.concept_name, n.target_concept_id, n.target_concept_name, n.target_concept_class_id, n.target_vocabulary_id, d.count
from NDC_drugs_mapped n join duplicates d on n.concept_id = d.concept_id;
