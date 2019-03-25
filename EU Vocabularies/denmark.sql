--denmark
--icd2013list
create table EU_den_ICD (dcode varchar, dname varchar);

--Число концептов в source vocabulary
--17663
select count (distinct dcode)
from EU_den_ICD
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
select gm.dcode, gm.dname, c.concept_name
from EU_den_ICD gm
join devv5.concept c
         on regexp_replace(c.concept_code,'\.','','g') = regexp_replace(gm.dcode, '^D','')
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where NOT exists(
    select 1
      from devv5.concept cc
      where regexp_replace(cc.concept_code,'\.','','g') = regexp_replace(gm.dcode, '^D','')
      and cc.vocabulary_id in ('ICD10CM') -- vocabulary to be excluded
    )
order by random ()
limit 1000
;

--Проверка качества джойна с ICD10CM, исключая ICD10
--то есть наоборот
--каунт отсюда не берем
select gm.dcode, gm.dname, c.concept_name
from EU_den_ICD gm
join devv5.concept c
         on regexp_replace(c.concept_code,'\.','','g') = regexp_replace(gm.dcode, '^D','')
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where NOT exists(
    select 1
      from devv5.concept cc
      where regexp_replace(cc.concept_code,'\.','','g') = regexp_replace(gm.dcode, '^D','')
      and cc.vocabulary_id in ('ICD10') -- vocabulary to be excluded
    )
order by random ()
limit 1000
;

--Проверка качества джойна с ICD10CM и ICD10
-- (обязательное наличие кода сразу в 2х словорях, и при этом с одинаковыми именами в разных словарях)
--каунт тут не берем
select gm.dcode, gm.dname, c.concept_name
from EU_den_ICD gm
join devv5.concept c
         on regexp_replace(c.concept_code,'\.','','g') = regexp_replace(gm.dcode, '^D','')
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where exists(
    select 1
      from devv5.concept cc
      where regexp_replace(cc.concept_code,'\.','','g') = regexp_replace(gm.dcode, '^D','')
      and cc.vocabulary_id in ('ICD10') -- vocabulary to be mandatory matched
    )

AND exists(
    select 1
      from devv5.concept cc
      where regexp_replace(cc.concept_code,'\.','','g') = regexp_replace(gm.dcode, '^D','')
      and cc.vocabulary_id in ('ICD10CM') -- vocabulary to be mandatory matched
    )

AND exists(
    select 1
      from devv5.concept cc
      JOIN devv5.concept ccc
          ON cc.concept_name = ccc.concept_name AND cc.concept_code = ccc.concept_code
      where gm.dcode = cc.concept_code AND cc.vocabulary_id in ('ICD10') AND ccc.vocabulary_id in ('ICD10CM')
    )

order by random ()
limit 1000
;

--Проверка качества джойна с ICD10CM и ICD10
-- (обязательное наличие кода сразу в 2х словорях, но при этом с разными именами в разных словарях)
--каунт отсюда не берем
select gm.dcode, c.vocabulary_id, gm.dname, c.concept_name
from EU_den_ICD gm
join devv5.concept c
         on regexp_replace(c.concept_code,'\.','','g') = regexp_replace(gm.dcode, '^D','')
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where exists(
    select 1
      from devv5.concept cc
      where regexp_replace(cc.concept_code,'\.','','g') = regexp_replace(gm.dcode, '^D','')
      and cc.vocabulary_id in ('ICD10') -- vocabulary to be mandatory matched
    )

AND exists(
    select 1
      from devv5.concept cc
      where regexp_replace(cc.concept_code,'\.','','g') = regexp_replace(gm.dcode, '^D','')
      and cc.vocabulary_id in ('ICD10CM') -- vocabulary to be mandatory matched
    )

AND NOT exists(
    select 1
      from devv5.concept cc
      JOIN devv5.concept ccc
          ON cc.concept_name = ccc.concept_name AND cc.concept_code = ccc.concept_code
      where gm.dcode = cc.concept_code AND cc.vocabulary_id in ('ICD10') AND ccc.vocabulary_id in ('ICD10CM')
    )

order by c.concept_code
limit 1000
;

--не заджойнилось с целевым словарем (в случае ICD берем сразу ДВА целевых словаря)
--это пытаемся заджонить вручную (Афина + SQL)
--каунт отсюда не берем
select distinct dcode, dname
from  EU_den_ICD gm
left join devv5.concept c
on regexp_replace(c.concept_code,'\.','','g') = regexp_replace(gm.dcode, '^D','')
         and  c.vocabulary_id in ('ICD10', 'ICD10CM') --target vocabs
where c.concept_code is null
;

--COUNT of OMOPed source codes
--8862
SELECT COUNT (*)
FROM (
    SELECT DISTINCT dcode as concept_code
    FROM EU_den_ICD gm
         ) as a
where exists
      (select 1
      from devv5.concept c
      where regexp_replace(c.concept_code,'\.','','g') = regexp_replace(a.concept_code, '^D','')
            and c.vocabulary_id in ('ICD10', 'ICD10CM') -- target vobulary(ies) initially confirmed above as equivalent by meaning
)
;

--COUNT of mapped source codes
--8800
SELECT COUNT (*)
FROM (
    SELECT DISTINCT dcode as concept_code
    FROM EU_den_ICD
         ) as a
where exists
      (select 1
      from devv5.concept c
            join devv5.concept_relationship cr
                  ON c.concept_id = cr.concept_id_1
      where regexp_replace(c.concept_code,'\.','','g') = regexp_replace(a.concept_code, '^D','')
            and c.vocabulary_id in ('ICD10', 'ICD10CM')  -- target vobulary(ies) initially confirmed above as equivalent by meaning
            and cr.relationship_id = 'Maps to'
            and cr.invalid_reason is null)
;

--каунт сорс кодов, заджойненных только с ICD10
--1060
SELECT COUNT (*)
FROM (
    SELECT DISTINCT dcode as concept_code
    FROM EU_den_ICD
         ) as a

where exists
      (select 1
      from devv5.concept c
      where  regexp_replace(c.concept_code,'\.','','g') = regexp_replace(a.concept_code, '^D','')
            and c.vocabulary_id in ('ICD10', 'ICD10CM')

AND NOT exists(
    select 1
      from devv5.concept cc
      where  rregexp_replace(cc.concept_code,'\.','','g') = regexp_replace(a.concept_code, '^D','')
      and cc.vocabulary_id in ('ICD10CM')
    )
)
;
--каунт сорс кодов, заджойненных только с ICD10CM
--178
SELECT COUNT (*)
FROM (
    SELECT DISTINCT dcode as concept_code
    FROM EU_den_ICD
         ) as a

where exists
      (select 1
      from devv5.concept c
      where regexp_replace(c.concept_code,'\.','','g') = regexp_replace(a.concept_code, '^D','')
            and c.vocabulary_id in ('ICD10', 'ICD10CM')

AND NOT exists(
    select 1
      from devv5.concept cc
      where regexp_replace(cc.concept_code,'\.','','g') = regexp_replace(a.concept_code, '^D','')
      and cc.vocabulary_id in ('ICD10')
    )
)
;

--каунт сорс кодов, заджойненных сразу с ICD10 и ICD10CM
--7624
SELECT COUNT (*)
FROM (
    SELECT DISTINCT dcode as concept_code
    FROM EU_den_ICD
         ) as a

where exists
      (select 1
      from devv5.concept c
      where regexp_replace(c.concept_code,'\.','','g') = regexp_replace(a.concept_code, '^D','')
            and c.vocabulary_id in ('ICD10')

AND exists(
    select 1
      from devv5.concept cc
      where regexp_replace(cc.concept_code,'\.','','g') = regexp_replace(a.concept_code, '^D','')
      and cc.vocabulary_id in ('ICD10CM')
    )
)
;

--sks_denmark
--adm - is probably for observations (others)
create table EU_den_sks_adm (adm varchar, name varchar, sks varchar, num varchar);
--adm count=1806
select count (distinct adm) from EU_den_sks_adm;
select distinct adm, name from EU_den_sks_adm;

--opr -operations (procedures)
create table EU_den_sks_opr (opr varchar, name varchar, sks varchar, num varchar);
--opr count= 11294
select count (distinct opr) from EU_den_sks_opr;

--pro - observations (others)
create table EU_den_sks_pro (pro varchar, name varchar, sks varchar, num varchar);
--pro count=9079
select count (distinct pro) from EU_den_sks_pro;

select distinct pro, name from EU_den_sks_pro;

--res - observation (other)
create table EU_den_sks_res (res varchar, name varchar, sks varchar, num varchar);
--res count=564
select count (distinct res) from EU_den_sks_res;

select distinct res, name from EU_den_sks_res;

--spc - observation (other)
create table EU_den_sks_spc (spc varchar, name varchar, sks varchar, num varchar);
--spc count=139
select count (distinct spc) from EU_den_sks_spc;

select distinct spc, name from EU_den_sks_spc;

--til - anatomical localization and smth like this (other)
create table EU_den_sks_til (til varchar, name varchar, sks varchar, num varchar);
--til count= 6909
select count (distinct til) from EU_den_sks_til;

select distinct til, name from EU_den_sks_til;

--uly - ?????????? (other)
create table EU_den_sks_uly (uly varchar,  name varchar, a varchar, b varchar, c varchar, d varchar, e varchar, f varchar,g varchar, h varchar, i varchar,j varchar);
--uly count=6203
select count (distinct uly) from EU_den_sks_uly;

select distinct uly, name||a as namex from EU_den_sks_uly;

--und - procedures diognostic (procedures)
create table  EU_den_sks_UND (UND varchar, name varchar, sks varchar, num varchar);

--und count=583
select count (distinct und) from EU_den_sks_UND;

select distinct und, name from EU_den_sks_UND;
 
 

