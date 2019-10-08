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

SELECT * FROM Loinc_PartLink;

--DROP TABLE LOINC_Part;
-- all dev_vkorsik.fields with varchar(255)
CREATE TABLE LOINC_Part AS
(SELECT *
FROM dev_vkorsik.LOINC_Part_primary_source)
;

CREATE TABLE LOINC_Part (
    PartNumber varchar(255),
    PartTypeName varchar(255),
    PartName varchar(255),
    PartDisplayName varchar(255),
    Status varchar(255)
) WITH OIDS;

SELECT * FROM LOINC_Part;


--STEP 2: Inserting into concept and concept_relationship
--Populating concept_stage
with s AS (SELECT DISTINCT pl.PartNumber, pl.PartName
FROM Loinc_PartLink pl
JOIN LOINC_Part p
ON pl.PartNumber = p.PartNumber
WHERE pl.LinkTypeName IN ('Primary', 'DetailedModel', 'SyntaxEnhancement')
  AND pl.PartTypeName IN ('SYSTEM', 'METHOD', 'PROPERTY', 'TIME', 'COMPONENT', 'SCALE')
AND pl.PartNumber NOT IN (SELECT DISTINCT concept_code FROM concept_stage)
AND p.Status = 'ACTIVE')

--INSERT INTO concept_stage
SELECT DISTINCT s.PartName AS concept_name,
                'Measurement' AS domain_id,
                'LOINC' AS vocabulary_id,
                'LOINC Attribute' AS concept_class_id,
                'C' AS standard_concept,                --Classification
                s.PartNumber AS concept_code,
                '1970-01-01'::date as valid_start_date, --Valid start date should be the date of last update
                '2099-12-31'::date as valid_end_date,
                NULL AS invalid_reason
FROM s
;

--Populating concept_synonym
with s AS (SELECT DISTINCT pl.PartNumber, p.PartDisplayName
FROM Loinc_PartLink pl
JOIN LOINC_Part p
ON pl.PartNumber = p.PartNumber
WHERE pl.LinkTypeName IN ('Primary', 'DetailedModel', 'SyntaxEnhancement')
  AND pl.PartTypeName IN ('SYSTEM', 'METHOD', 'PROPERTY', 'TIME', 'COMPONENT', 'SCALE')
AND pl.PartNumber NOT IN (SELECT DISTINCT concept_code FROM concept_stage)
AND p.Status = 'ACTIVE'
AND pl.PartName != p.PartDisplayName)

--INSERT INTO concept_synonym_stage
SELECT DISTINCT s.PartDisplayName AS synonym_name,
    s.PartNumber AS synonym_concept_code,
    'LOINC' AS synonym_vocabulary_id,
    4180186 AS language_concept_id --English language
FROM s
;

SELECT DISTINCT LoincNumber, PartNumber, PartTypeName
FROM Loinc_PartLink
WHERE LinkTypeName IN ('Primary', 'DetailedModel', 'SyntaxEnhancement')
AND PartTypeName = 'COMPONENT'
GROUP BY LoincNumber, PartNumber, PartTypeName, LinkTypeName
ORDER BY LoincNumber
;




WITH s AS (SELECT DISTINCT loincnumber, PartNumber, PartTypeName FROM Loinc_PartLink)

--INSERT INTO concept_relationship_stage
SELECT DISTINCT c.concept_id AS concept_id_1,
                cs.concept_id AS concept_id_2,
                s.loincnumber AS concept_code_1,
                cs.concept_code AS concept_code_2,
                'LOINC' AS vocabulary_id_1,
                'LOINC' AS vocabulary_id_2,
                s.parttypename AS relationship_id,
                '1970-01-01'::date as valid_start_date, --Valid start date should be the date of last update
                '2099-12-31'::date as valid_end_date,
                NULL AS invalid_reason
FROM s
JOIN devv5.concept c
ON s.loincnumber = c.concept_code
JOIN concept_stage cs
ON cs.concept_code = s.partnumber
WHERE c.vocabulary_id = 'LOINC'
AND parttypename != 'COMPONENT'
ORDER BY concept_id_1;

--Populate concept_synonym
--for concepts where partdisplayname != partname
--INSERT INTO concept_synonym_stage
SELECT DISTINCT cs.concept_id AS synonym_concept_id,
    s.partname AS synonym_name,
    s.partnumber AS synonym_concept_code,
    'LOINC' AS synonym_vocabulary_id,
    4180186 AS language_concept_id --English language
FROM LOINC_Part s
JOIN concept_stage cs
ON s.partnumber = cs.concept_code
WHERE s.partdisplayname != s.partname;


SELECT DISTINCT language_concept_id, c.* FROM devv5.concept_synonym
LEFT JOIN devv5.concept c
on language_concept_id = c.concept_id;

--Check Loinc Parts for future relationship_id
SELECT * FROM Loinc_PartLink WHERE PartTypeName = 'SCALE'
ORDER BY LoincNumber;

SELECT DISTINCT partname FROM Loinc_PartLink WHERE PartTypeName = 'SCALE';

SELECT * FROM Loinc_PartLink WHERE partname = '{Setting}'
ORDER BY LoincNumber;



SELECT DISTINCT *
FROM Loinc_PartLink s
LEFT JOIN sources.loinc_hierarchy lh
ON s.PartNumber = immediate_parent
WHERE LinkTypeName = 'Primary'
AND PartTypeName = 'COMPONENT'
AND immediate_parent IS NULL;


SELECT * FROM Loinc_PartLink s
WHERE PartNumber NOT IN (SELECT DISTINCT concept_code FROM devv5.concept WHERE vocabulary_id = 'LOINC')
AND PartTypeName = 'COMPONENT'
AND LinkTypeName = 'Primary';


SELECT DISTINCT *
FROM Loinc_PartLink s
WHERE LinkTypeName = 'Primary'
AND PartTypeName = 'COMPONENT'
AND s.PartNumber NOT IN (SELECT DISTINCT immediate_parent FROM sources.loinc_hierarchy);



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

SELECT * FROM sources.loinc_partlink;

SELECT lh.immediate_parent, p.PartTypeName
FROM sources.loinc_hierarchy lh
JOIN LOINC_Part p
ON lh.immediate_parent = p.PartNumber
WHERE p.Status = 'ACTIVE'
AND p.parttypename = 'COMPONENT';

--Code to check concepts that has relationship between parts (specify component if needed)
SELECT immediate_parent, p.PartDisplayName, p.PartTypeName, code, code_text, pp.PartTypeName
FROM sources.loinc_hierarchy lh
JOIN LOINC_Part p
ON lh.immediate_parent = p.PartNumber
JOIN LOINC_Part pp
ON code = pp.PartNumber
WHERE p.Status = 'ACTIVE' AND pp.Status = 'ACTIVE';