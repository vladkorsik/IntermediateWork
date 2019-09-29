--STEP 1: Uploading necessary additional LOINC Files
/*
2 files are required to proceed with LOINC attributes being added to CDM (LOINC version 2,66) - SEPTEMBER 2019
Part - contains all necessary information related to each LOINC attribute
LoincPartLink - contains all links between LOINC attributes and LOINC concepts
Both files can be found on https://loinc.org/downloads/accessory-files/
*/

--TODO: Should we edit names of Loinc parts to remove unnecessary dots, etc?
--TODO: Populate concept_synonym
--TODO: Check double concept relationship. They exist because Linktype = DetailedModel duplicates Linktype = Primary for cases where there is no detailed info
--TODO: Remove from concept concepts with name '-', etc.

--Run query to recreate devv5 in your schema

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


--STEP 2: Concept populating

--Populating with new attributes that are not already present in CDM, which are everything except Components
--INSERT INTO concept_stage
SELECT DISTINCT 0 AS concept_id,
                s.partdisplayname AS concept_name,
                'Measurement' AS domain_id,
                'LOINC' AS vocabulary_id,
                'LOINC Attribute' AS concept_class_id,
                'C' AS standard_concept,                --Classification
                s.partnumber AS concept_code,
                '1970-01-01'::date as valid_start_date, --Valid start date should be the date of last update
                '2099-12-31'::date as valid_end_date,
                NULL AS invalid_reason
FROM LOINC_Part s
WHERE s.parttypename != 'COMPONENT'
AND s.status = 'ACTIVE';

--TODO: Create new concept relationship (see file on google sheets)
--Populating concept_relationships
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
FROM Loinc_PartLink s
JOIN devv5.concept c
ON s.loincnumber = c.concept_code
JOIN concept_stage cs
ON cs.concept_code = s.partnumber
WHERE c.vocabulary_id = 'LOINC'
AND parttypename != 'COMPONENT'
ORDER BY concept_id_1;


--Check Loinc Parts for future relationship_id
SELECT * FROM Loinc_PartLink WHERE PartTypeName = 'SCALE'
ORDER BY LoincNumber;

SELECT DISTINCT partname FROM Loinc_PartLink WHERE PartTypeName = 'SCALE';

SELECT * FROM Loinc_PartLink WHERE partname = '{Setting}'
ORDER BY LoincNumber;

--These LOINC codes potentially have 'double' concept relationships
/*
10000-8
10000-8
10001-6
10001-6
10002-4
10002-4
10003-2
10003-2
10004-0
10004-0
*/


--Currently we create concept for each record with different concept_code.
--TODO: Maybe use different approach? Any other approach will lead to problem with concept_codes but also removes excessive concepts from CDM
SELECT *
FROM LOINC_Part p
WHERE p.partname IN
      (SELECT p.partname FROM LOINC_Part GROUP BY p.partname HAVING COUNT(*) > 1)
ORDER BY p.partname;

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
WHERE s.partnumber ~~* 'LP%'
AND s.parttypename = 'COMPONENT'
AND s.status = 'ACTIVE'
AND lh.immediate_parent IS NULL
;

--RESULT: All CONCEPT WITH HIERARCHY ARE INCLUDED IN CDM