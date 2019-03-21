--UK
Create table UK_dmd (
  id bigint,
  Name varchar(500)
);

--Число концептов в source vocabulary
--343227
select count(distinct id) from UK_dmd;

--Число концептов в target CDM vocabulary
--dmd 349916
--SNOMED 861732
select vocabulary_id, COUNT (DISTINCT concept_code)
from devv5.concept
WHERE vocabulary_id in ('dm+d', 'SNOMED')
GROUP BY vocabulary_id
;

--Проверка качества джойна с целевыми словарем
--каунт отсюда не берем
select dm.*, c.concept_name
from UK_dmd dm
join devv5.concept c
         on c.concept_code = CAST(dm.id as varchar)
            AND c.vocabulary_id in ('dm+d', 'SNOMED') -- vocabulary to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes
order by random ()
limit 1000
;

--не заджойнилось с целевым словарем (в случае ICD берем сразу ДВА целевых словаря)
--это пытаемся заджонить вручную (Афина + SQL)
--каунт отсюда не берем
select distinct id, Name
from  UK_dmd dm
left join devv5.concept c
on cast(dm.id AS varchar) = c.concept_code
         and  c.vocabulary_id in ('dm+d', 'SNOMED') --target vocabs
where c.concept_code is null
;

--COUNT of OMOPed source codes
--342411
SELECT COUNT (*)
FROM (
    SELECT DISTINCT id as concept_code
    FROM uk_dmd
         ) as a
where exists
      (select 1
      from devv5.concept c
      where CAST(a.concept_code AS varchar) = c.concept_code
            and c.vocabulary_id in ('dm+d', 'SNOMED') -- target vobulary(ies) initially confirmed above as equivalent by meaning
)
;

--COUNT of mapped source codes
--338411
SELECT COUNT (*)
FROM (
    SELECT DISTINCT id as concept_code
    FROM UK_dmd
         ) as a
where exists
      (select 1
      from devv5.concept c
            join devv5.concept_relationship cr
                  ON c.concept_id = cr.concept_id_1
      where CAST(a.concept_code AS varchar) = c.concept_code
            and c.vocabulary_id in ('dm+d', 'SNOMED')  -- target vobulary(ies) initially confirmed above as equivalent by meaning
            and cr.relationship_id = 'Maps to'
            and cr.invalid_reason is null)
;
