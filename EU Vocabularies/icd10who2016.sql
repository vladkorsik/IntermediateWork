--icd10who2016
create table EU_WHO_icd_10_WHO (code varchar, name varchar, class varchar, kind varchar);

--Число концептов в source vocabulary
--11133
select count (distinct code)
from EU_WHO_icd_10_WHO where class='category' and name is not null;

--Проверка качества джойна с одним словарем
-- актуально только когда джойним ОДИН словарь
--для ICD джойним всегда ДВА, поэтому для ICD SQL скрипт чуть ниже
--каунт отсюда не берем
select gm.code, gm.name, c.concept_name
from EU_WHO_icd_10_who gm
join devv5.concept c
         on c.concept_code = gm.code
            AND c.vocabulary_id in ('ICD10')
           where length(name)>0  and kind='preferred' and class='category'-- vocabulary to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes
order by random ()
limit 1000
;

--Проверка качества джойна с ICD10, исключая ICD10CM
--каунт отсюда не берем
select gm.code, gm.name, c.concept_name
from EU_WHO_icd_10_who gm
join devv5.concept c
         on c.concept_code = gm.code
         and length(name)>0  and kind='preferred' and class='category'
            AND c.vocabulary_id in ('ICD10', 'ICD10CM')
where NOT exists(
    select 1
      from devv5.concept cc
      where gm.code = cc.concept_code
      and length(name)>0  and kind='preferred' and class='category'
      and cc.vocabulary_id in ('ICD10CM') -- vocabulary to be excluded
    )
order by random ()
limit 1000
;

--Проверка качества джойна с ICD10CM, исключая ICD10
--то есть наоборот
--каунт отсюда не берем
select gm.code, gm.name, c.concept_name
from EU_WHO_icd_10_who gm
join devv5.concept c
         on c.concept_code = gm.code
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') 
            and length(name)>0  and kind='preferred' and class='category'

where NOT exists(
    select 1
      from devv5.concept cc
      where gm.code = cc.concept_code
      and cc.vocabulary_id in ('ICD10')
      and length(name)>0  and kind='preferred' and class='category'
    )
order by random ()
limit 1000
;

--Проверка качества джойна с ICD10CM и ICD10
-- (обязательное наличие кода сразу в 2х словорях, и при этом с одинаковыми именами в разных словарях)
--каунт тут не берем
select gm.code, gm.name, c.concept_name
from EU_WHO_icd_10_WHO gm
join devv5.concept c
         on c.concept_code = gm.code
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') 
             and length(name)>0  and kind='preferred' and class='category'
            -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where exists(
    select 1
      from devv5.concept cc
      where gm.code = cc.concept_code
       and length(name)>0  and kind='preferred' and class='category'
      and cc.vocabulary_id in ('ICD10') -- vocabulary to be mandatory matched
    )

AND exists(
    select 1
      from devv5.concept cc
      where gm.code = cc.concept_code
       and length(name)>0  and kind='preferred' and class='category'
      and cc.vocabulary_id in ('ICD10CM') -- vocabulary to be mandatory matched
    )

AND exists(
    select 1
      from devv5.concept cc
      JOIN devv5.concept ccc
          ON cc.concept_name = ccc.concept_name AND cc.concept_code = ccc.concept_code
      where gm.code = cc.concept_code AND cc.vocabulary_id in ('ICD10') AND ccc.vocabulary_id in ('ICD10CM')
       and length(name)>0  and kind='preferred' and class='category'
    )

order by random ()
limit 1000
;

--Проверка качества джойна с ICD10CM и ICD10
-- (обязательное наличие кода сразу в 2х словорях, но при этом с разными именами в разных словарях)
--каунт отсюда не берем
select gm.code, c.vocabulary_id, gm.name, c.concept_name
from EU_WHO_icd_10_WHO gm
join devv5.concept c
         on c.concept_code = gm.code
         and length(name)>0  and kind='preferred' and class='category'
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where exists(
    select 1
      from devv5.concept cc
      where gm.code = cc.concept_code
      and length(name)>0  and kind='preferred' and class='category'
      and cc.vocabulary_id in ('ICD10') -- vocabulary to be mandatory matched
    )

AND exists(
    select 1
      from devv5.concept cc
      where gm.code = cc.concept_code
      and length(name)>0  and kind='preferred' and class='category'
      and cc.vocabulary_id in ('ICD10CM') -- vocabulary to be mandatory matched
    )

AND NOT exists(
    select 1
      from devv5.concept cc
      JOIN devv5.concept ccc
          ON cc.concept_name = ccc.concept_name AND cc.concept_code = ccc.concept_code
      where gm.code = cc.concept_code AND cc.vocabulary_id in ('ICD10') AND ccc.vocabulary_id in ('ICD10CM')
      and length(name)>0  and kind='preferred' and class='category'
    )

order by c.concept_code
limit 1000
;

--не заджойнилось с целевым словарем (в случае ICD берем сразу ДВА целевых словаря)
--это пытаемся заджонить вручную (Афина + SQL)
--каунт отсюда не берем
select distinct code, name
from  EU_WHO_icd_10_who gm
left join devv5.concept c
on gm.code=c.concept_code
         and  c.vocabulary_id in ('ICD10', 'ICD10CM')
         and length(name)>0  and kind='preferred' and class='category' --target vocabs
where c.concept_code is null
;

--COUNT of OMOPed source codes
--11133
SELECT COUNT (*)
FROM (
    SELECT DISTINCT code as concept_code
    FROM EU_WHO_icd_10_who
         ) as a
where exists
      (select 1
      from devv5.concept c
      where a.concept_code = c.concept_code
            and c.vocabulary_id in ('ICD10', 'ICD10CM') -- target vobulary(ies) initially confirmed above as equivalent by meaning
)
;
--COUNT of mapped source codes
--11062
SELECT COUNT (*)
FROM (
    SELECT DISTINCT code as concept_code
    FROM EU_who_icd_10_who
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
--1424
SELECT COUNT (*)
FROM (
    SELECT DISTINCT code as concept_code
    FROM EU_who_icd_10_who
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
--0
SELECT COUNT (*)
FROM (
    SELECT DISTINCT code as concept_code
    FROM EU_Who_icd_10_who
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
--9709
SELECT COUNT (*)
FROM (
    SELECT DISTINCT code as concept_code
    FROM EU_who_icd_10_who
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

select distinct code, name
from  EU_WHO_icd_10_who gm
left join devv5.concept c
on gm.code=c.concept_code
         and  c.vocabulary_id in ('ICD10')
         and length(name)>0  and kind='preferred' and class='category' --target vocabs
where c.concept_code is null
;
