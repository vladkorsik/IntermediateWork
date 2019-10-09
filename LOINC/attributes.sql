--STEP 1: Uploading necessary additional LOINC Files
/*
2 files are required to proceed with LOINC attributes being added to CDM (LOINC version 2,66) - SEPTEMBER 2019
Part - contains all necessary information related to each LOINC attribute
LoincPartLink - contains all links between LOINC attributes and LOINC concepts
Both files can be found on https://loinc.org/downloads/accessory-files/
*/

--Step 0
--Run query to recreate devv5 in your schema

--STEP 1: Additional sources uploading
--I used tables in my own schema because they were not presented in sources till 04.10.2019

--DROP TABLE Loinc_PartLink;
CREATE TABLE Loinc_PartLink (
    LoincNumber varchar(255),
    LongCommonName varchar(512),
    PartNumber varchar(255),
    PartName varchar(255),
    PartCodeSystem varchar(100),
    PartTypeName varchar(100),
    LinkTypeName varchar(100),
    Property varchar(100)
) WITH OIDS;

--DROP TABLE LOINC_Part;
CREATE TABLE LOINC_Part (
    PartNumber varchar(255),
    PartTypeName varchar(255),
    PartName varchar(255),
    PartDisplayName varchar(255),
    Status varchar(255)
) WITH OIDS;


--STEP 2: Inserting into concept, concept_synonym and concept_relationship

--Populating concept_stage
with s AS (SELECT DISTINCT pl.PartNumber, p.PartDisplayName, pl.parttypename
FROM sources.loinc_partlink pl
JOIN sources.loinc_part p
ON pl.PartNumber = p.PartNumber
WHERE pl.LinkTypeName IN ('Primary')    --or any other too
  AND pl.PartTypeName IN ('SYSTEM', 'METHOD', 'PROPERTY', 'TIME', 'COMPONENT', 'SCALE')
AND pl.PartNumber NOT IN (SELECT DISTINCT concept_code FROM concept_stage WHERE concept_code IS NOT NULL)     --to exclude duplicates inserted during previous load_stage code
)

INSERT INTO concept_stage (concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, valid_start_date, valid_end_date, invalid_reason)
SELECT DISTINCT trim(s.PartDisplayName) AS concept_name,
                'Measurement' AS domain_id,
                'LOINC' AS vocabulary_id,
                CASE WHEN s.parttypename = 'SYSTEM' THEN 'LOINC System'
                     WHEN s.parttypename = 'METHOD' THEN 'LOINC Method'
                     WHEN s.parttypename = 'PROPERTY' THEN 'LOINC Property'
                     WHEN s.parttypename = 'TIME' THEN 'LOINC Time'
                     WHEN s.parttypename = 'COMPONENT' THEN 'LOINC Component'
                     WHEN s.parttypename = 'SCALE' THEN 'LOINC Scale'
                     ELSE 'LOINC Attribute'             --To check, should be 0 rows with this concept_class_id
                     END AS concept_class_id,
                'C' AS standard_concept,                --Classification
                s.PartNumber AS concept_code,
                '1970-01-01'::date as valid_start_date, --Valid start date should be the date of last update
                '2099-12-31'::date as valid_end_date,
                NULL AS invalid_reason
FROM s
;

--Populating concept_synonym
--Inserting synonyms for concepts where PartName != PartDisplayName
with s AS (SELECT DISTINCT pl.PartNumber, p.PartName
FROM sources.loinc_partlink pl
JOIN sources.loinc_part p
ON pl.PartNumber = p.PartNumber
WHERE pl.LinkTypeName IN ('Primary')
  AND pl.PartTypeName IN ('SYSTEM', 'METHOD', 'PROPERTY', 'TIME', 'COMPONENT', 'SCALE')
AND pl.PartNumber IN (SELECT DISTINCT concept_code FROM concept_stage WHERE concept_code IS NOT NULL)
AND pl.PartName != p.PartDisplayName
and p.partnumber NOT IN (SELECT DISTINCT synonym_concept_code FROM concept_synonym_stage WHERE synonym_concept_code IS NOT NULL))

INSERT INTO concept_synonym_stage (synonym_name, synonym_concept_code, synonym_vocabulary_id, language_concept_id)
SELECT DISTINCT s.PartName AS synonym_name,
    s.PartNumber AS synonym_concept_code,
    'LOINC' AS synonym_vocabulary_id,
    4180186 AS language_concept_id      --English language
FROM s
;

--Populating concept_relationship
WITH s AS (SELECT DISTINCT loincnumber, p.PartNumber, p.PartTypeName
           FROM sources.loinc_partlink pl
           JOIN sources.loinc_part p
           ON pl.PartNumber = p.PartNumber
           WHERE pl.LinkTypeName IN ('Primary')
           AND pl.PartTypeName IN ('SYSTEM', 'METHOD', 'PROPERTY', 'TIME', 'COMPONENT', 'SCALE')
           AND pl.PartNumber IN (SELECT DISTINCT concept_code FROM concept_stage)
           AND loincnumber IN (SELECT DISTINCT concept_code FROM concept_stage)
           )

INSERT INTO concept_relationship_stage (concept_code_1, concept_code_2, vocabulary_id_1, vocabulary_id_2, relationship_id, valid_start_date, valid_end_date, invalid_reason)
SELECT DISTINCT s.loincnumber AS concept_code_1,
                partnumber AS concept_code_2,
                'LOINC' AS vocabulary_id_1,
                'LOINC' AS vocabulary_id_2,
                CASE WHEN s.parttypename = 'SYSTEM' THEN 'Has finding site'
                     WHEN s.parttypename = 'METHOD' THEN 'Has method'
                     WHEN s.parttypename = 'PROPERTY' THEN 'Has property'
                     WHEN s.parttypename = 'TIME' THEN 'Has time aspect'
                     WHEN s.parttypename = 'COMPONENT' THEN 'Has component'
                     WHEN s.parttypename = 'SCALE' THEN 'Has scale type'
                     END AS relationship_id,
                '1970-01-01'::date as valid_start_date, --Valid start date should be the date of last update
                '2099-12-31'::date as valid_end_date,
                NULL AS invalid_reason
FROM s
ORDER BY concept_code_1;










--ANALYSIS OF COMPONENTS THAT ARE NOT CURRENTLY PRESENT IN CDM
--Components not present in devv5 but present in Loinc_Parts
SELECT *
FROM LOINC_Part s
LEFT JOIN devv5.concept c
ON s.partnumber = c.concept_code
WHERE s.partnumber ~~* 'LP%'
AND s.parttypename = 'COMPONENT'
AND s.status = 'ACTIVE'
AND c.concept_id is NULL;

--Components not present in devv5, but present in loinc_hierarchy
--0 concepts
SELECT *
FROM sources.loinc_hierarchy lh
LEFT JOIN devv5.concept c
ON lh.immediate_parent = c.concept_code
WHERE c.vocabulary_id = 'LOINC'
AND c.concept_id IS NULL;

--Components present in Loinc_Part, but not present in loinc_hierarchy
SELECT *
FROM LOINC_Part s
LEFT JOIN sources.loinc_hierarchy lh
ON s.partnumber = lh.immediate_parent
   OR s.partnumber = lh.code
WHERE s.partnumber ~~* 'LP%'
AND s.parttypename = 'COMPONENT'
AND s.status = 'ACTIVE'
AND lh.immediate_parent IS NULL
;

--RESULT: All CONCEPT WITH HIERARCHY ARE INCLUDED IN CDM

--Code to check concepts that has relationship between parts (specify component if needed)
SELECT immediate_parent, p.PartDisplayName, p.PartTypeName, code, code_text, pp.PartTypeName
FROM sources.loinc_hierarchy lh
JOIN LOINC_Part p
ON lh.immediate_parent = p.PartNumber
JOIN LOINC_Part pp
ON code = pp.PartNumber
WHERE p.Status = 'ACTIVE' AND pp.Status = 'ACTIVE';