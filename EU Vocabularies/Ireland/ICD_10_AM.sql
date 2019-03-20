create table ICD_10_AM_part
(
  code varchar(50),
  description varchar(500),
  ICD10code varchar(50)
)

--Число концептов в source vocabulary
--4635
select count (distinct code)
from ICD_10_AM_part
;

--Число концептов в target CDM vocabulary
--ICD10 16321
--ICD10CM 109706
select vocabulary_id, COUNT (DISTINCT concept_code)
from devv5.concept
WHERE vocabulary_id in ('ICD10', 'ICD10CM')
GROUP BY vocabulary_id
;

--Проверка качества джойна с ICD10, исключая ICD10CM
--каунт отсюда не берем
select am.code, am.description, c.concept_name
from ICD_10_AM_part am
join devv5.concept c
         on c.concept_code = am.code
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where NOT exists(
    select 1
      from devv5.concept cc
      where am.code = cc.concept_code
      and cc.vocabulary_id in ('ICD10CM') -- vocabulary to be excluded
    )
order by random ()
limit 1000
;

--Проверка качества джойна с ICD10CM, исключая ICD10
--то есть наоборот
--каунт отсюда не берем
select am.code, am.description, c.concept_name
from ICD_10_AM_part am
join devv5.concept c
         on c.concept_code = am.code
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where NOT exists(
    select 1
      from devv5.concept cc
      where am.code = cc.concept_code
      and cc.vocabulary_id in ('ICD10') -- vocabulary to be excluded
    )
order by random ()
limit 1000
;

--Проверка качества джойна с ICD10CM и ICD10
-- (обязательное наличие кода сразу в 2х словорях, и при этом с одинаковыми именами в разных словарях)
--каунт тут не берем
select am.code, am.description, c.concept_name
from ICD_10_AM_part am
join devv5.concept c
         on c.concept_code = am.code
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where exists(
    select 1
      from devv5.concept cc
      where am.code = cc.concept_code
      and cc.vocabulary_id in ('ICD10') -- vocabulary to be mandatory matched
    )

AND exists(
    select 1
      from devv5.concept cc
      where am.code = cc.concept_code
      and cc.vocabulary_id in ('ICD10CM') -- vocabulary to be mandatory matched
    )

AND exists(
    select 1
      from devv5.concept cc
      JOIN devv5.concept ccc
          ON cc.concept_name = ccc.concept_name AND cc.concept_code = ccc.concept_code
      where am.code = cc.concept_code AND cc.vocabulary_id in ('ICD10') AND ccc.vocabulary_id in ('ICD10CM')
    )

order by random ()
limit 1000
;


--Проверка качества джойна с ICD10CM и ICD10
-- (обязательное наличие кода сразу в 2х словорях, но при этом с разными именами в разных словарях)
--каунт отсюда не берем
select am.code, c.vocabulary_id, am.description, c.concept_name
from ICD_10_AM_part am
join devv5.concept c
         on c.concept_code = am.code
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where exists(
    select 1
      from devv5.concept cc
      where am.code = cc.concept_code
      and cc.vocabulary_id in ('ICD10') -- vocabulary to be mandatory matched
    )

AND exists(
    select 1
      from devv5.concept cc
      where am.code = cc.concept_code
      and cc.vocabulary_id in ('ICD10CM') -- vocabulary to be mandatory matched
    )

AND NOT exists(
    select 1
      from devv5.concept cc
      JOIN devv5.concept ccc
          ON cc.concept_name = ccc.concept_name AND cc.concept_code = ccc.concept_code
      where am.code = cc.concept_code AND cc.vocabulary_id in ('ICD10') AND ccc.vocabulary_id in ('ICD10CM')
    )

order by c.concept_code
limit 1000
;

--не заджойнилось с целевым словарем (в случае ICD берем сразу ДВА целевых словаря)
--это пытаемся заджонить вручную (Афина + SQL)
--каунт отсюда не берем
select distinct am.code, am.description
from  ICD_10_AM_part am
left join devv5.concept c
on am.code = c.concept_code
         and  c.vocabulary_id in ('ICD10', 'ICD10CM') --target vocabs
where c.concept_code is null
;

--COUNT of OMOPed source codes
--1447
SELECT COUNT (*)
FROM (
    SELECT DISTINCT code as concept_code
    FROM ICD_10_AM_part
         ) as a
where exists
      (select 1
      from devv5.concept c
      where a.concept_code = c.concept_code
            and c.vocabulary_id in ('ICD10', 'ICD10CM') -- target vobulary(ies) initially confirmed above as equivalent by meaning
)
;

--COUNT of mapped source codes
--1425
SELECT COUNT (*)
FROM (
    SELECT DISTINCT code as concept_code
    FROM ICD_10_AM_part
         ) as a
where exists
      (select 1
      from devv5.concept c
            join devv5.concept_relationship cr
                  ON c.concept_id = cr.concept_id_1
      where a.concept_code = c.concept_code
            and c.vocabulary_id in ('ICD10', 'ICD10CM')  -- target vobulary(ies) initially confirmed above as equivalent by meaning
            and cr.relationship_id = 'Maps to'
            and cr.invalid_reason is null)
;

--каунт сорс кодов, заджойненных только с ICD10
--12
SELECT COUNT (*)
FROM (
    SELECT DISTINCT code as concept_code
    FROM ICD_10_AM_part
         ) as a

where exists
      (select 1
      from devv5.concept c
      where a.concept_code = c.concept_code
            and c.vocabulary_id in ('ICD10', 'ICD10CM')

AND NOT exists(
    select 1
      from devv5.concept cc
      where a.concept_code = cc.concept_code
      and cc.vocabulary_id in ('ICD10CM')
    )
)
;

--каунт сорс кодов, заджойненных только с ICD10CM
--1371
SELECT COUNT (*)
FROM (
    SELECT DISTINCT code as concept_code
    FROM ICD_10_AM_part
         ) as a

where exists
      (select 1
      from devv5.concept c
      where a.concept_code = c.concept_code
            and c.vocabulary_id in ('ICD10', 'ICD10CM')

AND NOT exists(
    select 1
      from devv5.concept cc
      where a.concept_code = cc.concept_code
      and cc.vocabulary_id in ('ICD10')
    )
)
;

--каунт сорс кодов, заджойненных сразу с ICD10 и ICD10CM
--64
SELECT COUNT (*)
FROM (
    SELECT DISTINCT code as concept_code
    FROM ICD_10_AM_part
         ) as a

where exists
      (select 1
      from devv5.concept c
      where a.concept_code = c.concept_code
            and c.vocabulary_id in ('ICD10')

AND exists(
    select 1
      from devv5.concept cc
      where a.concept_code = cc.concept_code
      and cc.vocabulary_id in ('ICD10CM')
    )
)
;
