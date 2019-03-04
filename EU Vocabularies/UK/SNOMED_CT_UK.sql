--UK
Create table UK_snomed (
  id bigint,
  moduleid bigint,
  conceptId bigint,
  typeId bigint,
  term varchar(500),
  caseSignificanceId bigint
);

--Число концептов в source vocabulary
--99737 unique IDs among 221989 concepts
select count(distinct conceptId) from UK_snomed;

--Codes with the same ID are synonyms
select * from UK_snomed
where conceptId in
      (select conceptId from UK_snomed group by conceptId having count(conceptId) > 1)
order by conceptId;

--Число концептов в target CDM vocabulary
--SNOMED 861732
select vocabulary_id, COUNT (DISTINCT concept_code)
from devv5.concept
WHERE vocabulary_id in ('SNOMED')
GROUP BY vocabulary_id
;

--Проверка качества джойна с целевыми словарем
--каунт отсюда не берем
select sm.id, sm.term, c.concept_name
from UK_snomed sm
join devv5.concept c
         on c.concept_code = CAST(sm.conceptId as varchar)
            AND c.vocabulary_id in ('SNOMED') -- vocabulary to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes
order by random ()
limit 1000
;

--не заджойнилось с целевым словарем (в случае ICD берем сразу ДВА целевых словаря)
--это пытаемся заджонить вручную (Афина + SQL)
--каунт отсюда не берем
select distinct sm.conceptId, sm.term
from  UK_snomed sm
left join devv5.concept c
on cast(sm.conceptId AS varchar) = c.concept_code
         and  c.vocabulary_id in ('SNOMED') --target vocabs
where c.concept_code is null
;

--COUNT of OMOPed source codes
--46275
SELECT COUNT (*)
FROM (
    SELECT DISTINCT conceptId as concept_code
    FROM uk_snomed
         ) as a
where exists
      (select 1
      from devv5.concept c
      where CAST(a.concept_code AS varchar) = c.concept_code
            and c.vocabulary_id in ('SNOMED') -- target vobulary(ies) initially confirmed above as equivalent by meaning
)
;

--COUNT of mapped source codes
--42892
SELECT COUNT (*)
FROM (
    SELECT DISTINCT conceptId as concept_code
    FROM UK_snomed
         ) as a
where exists
      (select 1
      from devv5.concept c
            join devv5.concept_relationship cr
                  ON c.concept_id = cr.concept_id_1
      where CAST(a.concept_code AS varchar) = c.concept_code
            and c.vocabulary_id in ('SNOMED')  -- target vobulary(ies) initially confirmed above as equivalent by meaning
            and cr.relationship_id = 'Maps to'
            and cr.invalid_reason is null)
;
