
--MeddraToSnomed statistics
--Number of meddra codes in devv5 schema=105787
SELECT count(distinct concept_code)
FROM devv5.concept c
WHERE vocabulary_id='MedDRA'
;
-- MedDRA codes distribution by classes in dev schema
SELECT concept_class_id,count(distinct concept_code) as abs_count,round(count(distinct concept_code)::numeric/105787*100,3)as portion_of_codes
FROM devv5.concept c
WHERE vocabulary_id='MedDRA'
group by 1
order by 2 desc
;
-- Number of codes used in RWD =8294
SELECT count (distinct source_code)
FROM dev_jnj.jj_general_custom_mapping s
WHERE s.source_vocabulary_id='JJ_MedDRA_maps_to'

-- MedDRA codes distribution by classes in RWD
SELECT c.concept_class_id,count(distinct source_code) as abs_count,round(count( distinct s.source_code)::numeric/8294*100,3)as portion_of_total_meddra_codes
FROM dev_jnj.jj_general_custom_mapping s
JOIN devv5.concept c
ON s.source_code=c.concept_code
AND c.vocabulary_id='MedDRA'
WHERE s.source_vocabulary_id='JJ_MedDRA_maps_to'
group by 1
order by 2 desc
;

--Number of meddra codes in refset = 6374
Select count(distinct referencedcomponentid)
from dev_meddra.der2_srefset_meddratosnomedmap
;
--MedDRA codes distribution by classes in refset
SELECT  c.concept_class_id,count(distinct c.concept_code) as abs_count,round(count(distinct c.concept_code)::numeric/6374*100,3) as portion_of_codes
FROM dev_meddra.der2_srefset_meddratosnomedmap s
JOIN devv5.concept c
ON s.referencedcomponentid::varchar=c.concept_code
AND c.vocabulary_id='MedDRA'
group by 1
Order by 3 desc
;

-- Is our devv5 schema meddra have all the concepts from refset?
--check if any  code are lost
SELECT *
FROM dev_meddra.der2_srefset_meddratosnomedmap s
WHERE NOT EXISTS(SELECT 1
               FROM devv5.concept m
WHERE vocabulary_id='MedDRA'
                 AND s.referencedcomponentid::varchar  = m.concept_code
                    );
-- Conclusion 1 - The refset looks representative if comper with RWD and General OMOPed meddra

--What is a number of codes with 1 to many mappings (aka postcoordianted) in RefSet?
-- 0 meddra codes from refset have 1toMany mappings
SELECT *
FROM dev_meddra.der2_srefset_meddratosnomedmap
WHERE referencedcomponentid IN (
    SELECT referencedcomponentid
FROM dev_meddra.der2_srefset_meddratosnomedmap
    GROUP BY 1 having count(maptarget)>1)
;

--What is a number of codes with 1 to many mappings (aka postcoordianted) in Real World Data (RWD) by Odysseus?
--1-to-many mapping
-- 1236 1 to many codes
with tab as (
    SELECT DISTINCT s.*
    FROM dev_jnj.jj_general_custom_mapping  s
    WHERE s.source_vocabulary_id IN ('JJ_MedDRA_maps_to',
'JJ_MedDRA_maps_to_value')
)

SELECT count(distinct source_code)
FROM tab
WHERE source_code in (

    SELECT source_code
    FROM tab
    GROUP BY source_code
    HAVING count (*) > 1)
;

--all other 1-to-many mappings
-- 1 Maps to only
---- 460  1 to many Only codes
with tab as (
      SELECT DISTINCT s.*
    FROM dev_jnj.jj_general_custom_mapping  s
    WHERE s.source_vocabulary_id IN ('JJ_MedDRA_maps_to',
'JJ_MedDRA_maps_to_value')
)

SELECT count(distinct source_code)
FROM tab
WHERE source_code IN (
    SELECT source_code
    FROM tab
    GROUP BY source_code
    HAVING count(*) > 1)

    AND source_code NOT IN (
        SELECT source_code
        FROM tab t
        WHERE source_code in (
                SELECT source_code
                FROM tab
                GROUP BY source_code
                HAVING count(*)>1
        )
            AND EXISTS(SELECT 1
                       FROM tab b
                       WHERE t.source_code = b.source_code
                         AND b.source_vocabulary_id ~* 'value|modifier|qualifier|unit')
    )
;

--654/(1236-460) are 1var+1val
--1 maps_to mapping and 1 maps_to_value/unit/modifier/qualifier mapping
WITH tab AS (
    SELECT DISTINCT s.*
    FROM dev_jnj.jj_general_custom_mapping  s
    WHERE s.source_vocabulary_id IN ('JJ_MedDRA_maps_to',
'JJ_MedDRA_maps_to_value')
)

SELECT count(distinct source_code)
FROM tab t
WHERE source_code in (
        SELECT source_code
        FROM tab
        GROUP BY source_code
        HAVING count(*) =2
)
    AND EXISTS(SELECT 1
               FROM tab b
               WHERE t.source_code = b.source_code
                 AND b.source_vocabulary_id ~* 'value|modifier|qualifier|unit')
;

-- How many codes do not appear in real world data  but exist in RefSet
SELECT count(distinct referencedcomponentid) as non_in_real_world_data_abs_count, round(count(distinct s.referencedcomponentid)::numeric/6374*100,3) as portion_of_codes
FROM dev_meddra.der2_srefset_meddratosnomedmap s
WHERE  referencedcomponentid::varchar NOT  IN (   SELECT DISTINCT source_code
    FROM dev_jnj.jj_general_custom_mapping  s
    WHERE s.source_vocabulary_id IN ('JJ_MedDRA_maps_to',
'JJ_MedDRA_maps_to_value')
)
;



SELECT
FROM dev_meddra.der2_srefset_meddratosnomedmap s
JOIN devv5.concept c
ON s.maptarget::varchar=c.concept_code
AND c.vocabulary_id='SNOMED'
WHERE  referencedcomponentid::varchar NOT  IN (   SELECT DISTINCT source_code
    FROM dev_jnj.jj_general_custom_mapping  s
    WHERE s.source_vocabulary_id IN ('JJ_MedDRA_maps_to',
'JJ_MedDRA_maps_to_value')
)
;




-- Internal RefSet mapping statisctics

-- How often does Refset provide mapping to 1 SNOMED CODE?
-- 3994
SELECT  count(*)
FROM dev_meddra.der2_srefset_meddratosnomedmap s
WHERE maptarget IN (
    SELECT maptarget
FROM dev_meddra.der2_srefset_meddratosnomedmap
    GROUP BY 1 having count(distinct referencedcomponentid)>1)
;
-- RefSet TO SNOMED mapping stistics
SELECT  c.domain_id as target_domain,c.concept_class_id as target_concept_class,count( s.referencedcomponentid) as abs_meddra_code_count,round(count( s.referencedcomponentid)::numeric/6374*100,3)as portion_of_total_meddra_codes
FROM dev_meddra.der2_srefset_meddratosnomedmap s
JOIN devv5.concept c
ON s.maptarget::varchar=c.concept_code
AND c.vocabulary_id='SNOMED'
group by 1,2
ORDER BY 1,2,4 desc
;
-- RWD TO SNOMED mapping spastics
SELECT  c.domain_id as target_domain,source_vocabulary_id,c.concept_class_id as target_concept_class,count( distinct s.source_code) as abs_meddra_code_count
FROM dev_jnj.jj_general_custom_mapping s
JOIN devv5.concept c
ON s.target_concept_id=c.concept_id
WHERE s.source_vocabulary_id IN ('JJ_MedDRA_maps_to',
'JJ_MedDRA_maps_to_value')
AND c.vocabulary_id='SNOMED'
group by 1,2,3
ORDER BY 1,2,4 desc
;








