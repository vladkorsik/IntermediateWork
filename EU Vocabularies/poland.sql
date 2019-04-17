--poland
--icd10
create table EU_PL_ICD10pl (code varchar, name varchar);

select distinct code from EU_PL_ICD10pl;

--Число концептов в source vocabulary
--12562
select count (distinct code)
from EU_PL_ICD10pl
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
select gm.code, gm.name, c.concept_name
from EU_PL_ICD10pl gm
join devv5.concept c
         on regexp_replace (gm.code, '\*|\†|\.', '', 'g')= regexp_replace (c.concept_code,'\.','','g')
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where NOT exists(
    select 1
      from devv5.concept cc
      where regexp_replace (gm.code, '\*|\†|\.', '', 'g')= regexp_replace (cc.concept_code,'\.','','g')
      and cc.vocabulary_id in ('ICD10CM') -- vocabulary to be excluded
    )
order by random ()
limit 1000
;

--Проверка качества джойна с ICD10CM, исключая ICD10
--то есть наоборот
--каунт отсюда не берем
select gm.code, gm.name, c.concept_name
from EU_PL_ICD10pl gm
join devv5.concept c
         on regexp_replace (gm.code, '\*|\†|\.', '', 'g')= regexp_replace (c.concept_code,'\.','','g')
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where NOT exists(
    select 1
      from devv5.concept cc
      where regexp_replace (gm.code, '\*|\†|\.', '', 'g')= regexp_replace (cc.concept_code,'\.','','g')
      and cc.vocabulary_id in ('ICD10') -- vocabulary to be excluded
    )
order by random ()
limit 1000
;

--Проверка качества джойна с ICD10CM и ICD10
-- (обязательное наличие кода сразу в 2х словорях, и при этом с одинаковыми именами в разных словарях)
--каунт тут не берем
select gm.code, gm.name, c.concept_name
from EU_PL_ICD10pl gm
join devv5.concept c
         on regexp_replace (gm.code, '\*|\†|\.', '', 'g')= regexp_replace (c.concept_code,'\.','','g')
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where exists(
    select 1
      from devv5.concept cc
      where regexp_replace (gm.code, '\*|\†|\.', '', 'g')= regexp_replace (cc.concept_code,'\.','','g')
      and cc.vocabulary_id in ('ICD10') -- vocabulary to be mandatory matched
    )

AND exists(
    select 1
      from devv5.concept cc
      where regexp_replace (gm.code, '\*|\†|\.', '', 'g')= regexp_replace (cc.concept_code,'\.','','g')
      and cc.vocabulary_id in ('ICD10CM') -- vocabulary to be mandatory matched
    )

AND exists(
    select 1
      from devv5.concept cc
      JOIN devv5.concept ccc
          ON cc.concept_name = ccc.concept_name AND cc.concept_code = ccc.concept_code
      where regexp_replace (gm.code, '\*|\†|\.', '', 'g')= regexp_replace (cc.concept_code,'\.','','g') AND cc.vocabulary_id in ('ICD10') AND ccc.vocabulary_id in ('ICD10CM')
    )

order by random ()
limit 1000
;


--Проверка качества джойна с ICD10CM и ICD10
-- (обязательное наличие кода сразу в 2х словорях, но при этом с разными именами в разных словарях)
--каунт отсюда не берем
select gm.code, c.vocabulary_id, gm.name, c.concept_name
from EU_PL_ICD10pl gm
join devv5.concept c
         on regexp_replace (gm.code, '\*|\†|\.', '', 'g')= regexp_replace (c.concept_code,'\.','','g')
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where exists(
    select 1
      from devv5.concept cc
      where regexp_replace (gm.code, '\*|\†|\.', '', 'g')= regexp_replace (cc.concept_code,'\.','','g')
      and cc.vocabulary_id in ('ICD10') -- vocabulary to be mandatory matched
    )

AND exists(
    select 1
      from devv5.concept cc
      where regexp_replace (gm.code, '\*|\†|\.', '', 'g')= regexp_replace (cc.concept_code,'\.','','g')
      and cc.vocabulary_id in ('ICD10CM') -- vocabulary to be mandatory matched
    )

AND NOT exists(
    select 1
      from devv5.concept cc
      JOIN devv5.concept ccc
          ON cc.concept_name = ccc.concept_name AND cc.concept_code = ccc.concept_code
      where regexp_replace (gm.code, '\*|\†|\.', '', 'g')= regexp_replace (cc.concept_code,'\.','','g') AND cc.vocabulary_id in ('ICD10') AND ccc.vocabulary_id in ('ICD10CM')
    )

order by c.concept_code
limit 1000
;

--не заджойнилось с целевым словарем (в случае ICD берем сразу ДВА целевых словаря)
--это пытаемся заджонить вручную (Афина + SQL)
--каунт отсюда не берем
select distinct code, name
from  EU_PL_ICD10pl gm
left join devv5.concept c
on regexp_replace (gm.code, '\*|\†|\.', '', 'g')= regexp_replace (c.concept_code,'\.','','g')
         and  c.vocabulary_id in ('ICD10', 'ICD10CM') --target vocabs
where c.concept_code is null
;

--COUNT of OMOPed source codes
--12425
SELECT COUNT (*)
FROM (
    SELECT DISTINCT code as concept_code
    FROM EU_PL_ICD10pl
         ) as a
where exists
      (select 1
      from devv5.concept c
      where regexp_replace (a.concept_code, '\*|\†|\.', '', 'g') = regexp_replace (c.concept_code,'\.','','g')
            and c.vocabulary_id in ('ICD10', 'ICD10CM') -- target vobulary(ies) initially confirmed above as equivalent by meaning
)
;

--COUNT of mapped source codes
--12353
SELECT COUNT (*)
FROM (
    SELECT DISTINCT code as concept_code
    FROM EU_PL_ICD10pl
         ) as a
where exists
      (select 1
      from devv5.concept c
            join devv5.concept_relationship cr
                  ON c.concept_id = cr.concept_id_1
      where regexp_replace (a.concept_code, '\*|\†|\.', '', 'g') = regexp_replace (c.concept_code,'\.','','g')
            and c.vocabulary_id in ('ICD10', 'ICD10CM')  -- target vobulary(ies) initially confirmed above as equivalent by meaning
            and cr.relationship_id = 'Maps to'
            and cr.invalid_reason is null)
;

--каунт сорс кодов, заджойненных только с ICD10
--1608
SELECT COUNT (*)
FROM (
    SELECT DISTINCT code as concept_code
    FROM EU_PL_ICD10pl
         ) as a

where exists
      (select 1
      from devv5.concept c
      where regexp_replace (a.concept_code, '\*|\†|\.', '', 'g') = regexp_replace (c.concept_code,'\.','','g')
            and c.vocabulary_id in ('ICD10', 'ICD10CM')

AND NOT exists(
    select 1
      from devv5.concept cc
      where regexp_replace (a.concept_code, '\*|\†|\.', '', 'g') = regexp_replace (cc.concept_code,'\.','','g')
      and cc.vocabulary_id in ('ICD10CM')
    )
)
;

--каунт сорс кодов, заджойненных только с ICD10CM
--20
SELECT COUNT (*)
FROM (
    SELECT DISTINCT code as concept_code
    FROM EU_PL_ICD10pl
         ) as a

where exists
      (select 1
      from devv5.concept c
      where regexp_replace (a.concept_code, '\*|\†|\.', '', 'g') = regexp_replace (c.concept_code,'\.','','g')
            and c.vocabulary_id in ('ICD10', 'ICD10CM')

AND NOT exists(
    select 1
      from devv5.concept cc
      where regexp_replace (a.concept_code, '\*|\†|\.', '', 'g') = regexp_replace (cc.concept_code,'\.','','g')
      and cc.vocabulary_id in ('ICD10')
    )
)
;

--каунт сорс кодов, заджойненных сразу с ICD10 и ICD10CM
--10797
SELECT COUNT (*)
FROM (
    SELECT DISTINCT code as concept_code
    FROM EU_PL_ICD10pl
         ) as a

where exists
      (select 1
      from devv5.concept c
      where regexp_replace (a.concept_code, '\*|\†|\.', '', 'g') = regexp_replace (c.concept_code,'\.','','g')
            and c.vocabulary_id in ('ICD10')

AND exists(
    select 1
      from devv5.concept cc
      where regexp_replace (a.concept_code, '\*|\†|\.', '', 'g') = regexp_replace (cc.concept_code,'\.','','g')
      and cc.vocabulary_id in ('ICD10CM')
    )
)
;


