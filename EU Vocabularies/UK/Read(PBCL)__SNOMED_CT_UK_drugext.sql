--PBCL
--as part of Read vocab
create table pbcl
(
  code varchar(50),
  description varchar(500)
);

--Число концептов в source vocabulary
--3923
select count(distinct code) from pbcl;

--Число концептов в target CDM vocabulary
--Read 108681
select vocabulary_id, COUNT (DISTINCT concept_code)
from devv5.concept
WHERE vocabulary_id in ('Read')
GROUP BY vocabulary_id
;

--COUNT of OMOPed source codes
--3750
select count(pbcl.code)
from pbcl
join devv5.concept c
         on regexp_replace(c.concept_code, '.00', '.') = pbcl.code
            AND c.vocabulary_id in ('Read')
;

--COUNT of mapped source codes
--3750
SELECT count(*)
FROM (
    SELECT DISTINCT concept_code as concept_code
    FROM pbcl
join devv5.concept c
         on regexp_replace(c.concept_code, '.00', '.') = pbcl.code
         ) as a
where exists
      (select 1
      from devv5.concept c
            join devv5.concept_relationship cr
                  ON c.concept_id = cr.concept_id_1
      where a.concept_code = c.concept_code
            and c.vocabulary_id in ('Read')  -- target vobulary(ies) initially confirmed above as equivalent by meaning
            and cr.relationship_id = 'Maps to'
            and cr.invalid_reason is null)
;




--SNOMED_CT_UK_drug
create table uk_snomed_drug
(
  id varchar(50),
  moduleId varchar(50),
  conceptId varchar(50),
  typeId varchar(50),
  term varchar(500)
);

--Число концептов в source vocabulary
--440206
select count(distinct conceptId) from uk_snomed_drug;

--Число концептов в target CDM vocabulary
--Snomed 861732
select vocabulary_id, COUNT (DISTINCT concept_code)
from devv5.concept
WHERE vocabulary_id in ('SNOMED')
GROUP BY vocabulary_id
;

--Проверка качества джойна с целевыми словарем
--каунт отсюда не берем
select sm.id, sm.term, c.concept_name
from uk_snomed_drug sm
join devv5.concept c
         on c.concept_code = sm.conceptId
            AND c.vocabulary_id in ('SNOMED') -- vocabulary to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes
order by random ()
limit 1000
;

--не заджойнилось с целевым словарем (в случае ICD берем сразу ДВА целевых словаря)
--это пытаемся заджонить вручную (Афина + SQL)
--каунт отсюда не берем
select distinct sm.conceptId, sm.term
from  uk_snomed_drug sm
left join devv5.concept c
on cast(sm.conceptId AS varchar) = c.concept_code
         and  c.vocabulary_id in ('SNOMED') --target vocabs
where c.concept_code is null
;

--COUNT of OMOPed source codes
--358733
SELECT COUNT (*)
FROM (
    SELECT DISTINCT conceptId as concept_code
    FROM uk_snomed_drug
         ) as a
where exists
      (select 1
      from devv5.concept c
      where CAST(a.concept_code AS varchar) = c.concept_code
            and c.vocabulary_id in ('SNOMED') -- target vobulary(ies) initially confirmed above as equivalent by meaning
)
;

--COUNT of mapped source codes
--192889
SELECT COUNT (*)
FROM (
    SELECT DISTINCT conceptId as concept_code
    FROM uk_snomed_drug
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
