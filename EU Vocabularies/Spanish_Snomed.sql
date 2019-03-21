--Source codes were imported from 2 files:
--sct2_Description_SpanishExtensionFull-es_INT_20181031.txt
--sct2_TextDefinition_SpanishExtensionFull-es_INT_20181031.txt

--Number of source codes
--413538
select count (distinct conceptid)
from snomed_spain
;

--COUNT of OMOPed source codes
--413532
SELECT count(*)
FROM (
    SELECT distinct snomed_spain.conceptid as concept_code
    FROM snomed_spain
         ) as a
where exists
      (select 1
      from devv5.concept c
      where a.concept_code = CAST(c.concept_code as bigint)
            and c.vocabulary_id in ('SNOMED'))
;

--COUNT of mapped source codes
--376052
SELECT COUNT (*)
FROM (
    SELECT DISTINCT conceptid as concept_code
    FROM snomed_spain
         ) as a
where exists
      (select 1
      from devv5.concept c
            join devv5.concept_relationship cr
                  ON c.concept_id = cr.concept_id_1
      where CAST(a.concept_code as varchar) = c.concept_code
            and c.vocabulary_id in ('SNOMED')  -- target vobulary(ies) initially confirmed above as equivalent by meaning
            and cr.relationship_id = 'Maps to'
            and cr.invalid_reason is null)
;
