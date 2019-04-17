--Sweden
--ICD10-SE
create table EU_SE_ICD10_SE_2019 (
Kod varchar,
	Kodtext varchar);

--Число концептов в EU_SE_ICD10_SE_2019
--35698
select count (distinct kod)
from EU_SE_ICD10_SE_2019
;

select * 
from EU_SE_ICD10_SE_2019 where kod like 'W5552'
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
select gm.kod, c.concept_code, gm.kodtext, c.concept_name
from EU_SE_ICD10_SE_2019 gm
join devv5.concept c
         on regexp_replace (c.concept_code,'\.','','g') = gm.kod
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where NOT exists(
    select 1
      from devv5.concept cc
      where gm.kod = regexp_replace (cc.concept_code,'\.','','g')
      and cc.vocabulary_id in ('ICD10CM') -- vocabulary to be excluded
    )
order by random ()
limit 1000
;

--Проверка качества джойна с ICD10CM, исключая ICD10
--каунт отсюда не берем
select gm.kod, c.concept_code, gm.kodtext, c.concept_name
from EU_SE_ICD10_SE_2019 gm
join devv5.concept c
         on regexp_replace (c.concept_code,'\.','','g') = gm.kod
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where NOT exists(
    select 1
      from devv5.concept cc
      where gm.kod = regexp_replace (cc.concept_code,'\.','','g')
      and cc.vocabulary_id in ('ICD10') -- vocabulary to be excluded
    )
order by random ()
limit 1000
;

--Проверка качества джойна с ICD10CM и ICD10
-- (обязательное наличие кода сразу в 2х словорях, и при этом с одинаковыми именами в разных словарях)
--каунт тут не берем
select gm.kod, gm.kodtext, c.concept_name
from EU_SE_ICD10_SE_2019 gm
join devv5.concept c
         on  gm.kod=regexp_replace (c.concept_code,'\.','','g')
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where exists(
    select 1
      from devv5.concept cc
      where gm.kod = regexp_replace (cc.concept_code,'\.','','g')
      and cc.vocabulary_id in ('ICD10') -- vocabulary to be mandatory matched
    )

AND exists(
    select 1
      from devv5.concept cc
      where gm.kod = regexp_replace (cc.concept_code,'\.','','g')
      and cc.vocabulary_id in ('ICD10CM') -- vocabulary to be mandatory matched
    )

AND exists(
    select 1
      from devv5.concept cc
      JOIN devv5.concept ccc
          ON cc.concept_name = ccc.concept_name AND cc.concept_code = ccc.concept_code
      where gm.kod = regexp_replace (cc.concept_code,'\.','','g') AND cc.vocabulary_id in ('ICD10') AND ccc.vocabulary_id in ('ICD10CM')
    )

order by random ()
limit 1000
;

--Проверка качества джойна с ICD10CM и ICD10
-- (обязательное наличие кода сразу в 2х словорях, но при этом с разными именами в разных словарях)
--каунт отсюда не берем
select gm.kod, c.vocabulary_id, gm.kodtext, c.concept_name
from EU_SE_ICD10_SE_2019 gm
join devv5.concept c
         on gm.kod=regexp_replace (c.concept_code,'\.','','g')
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where exists(
    select 1
      from devv5.concept cc
      where gm.kod = regexp_replace(cc.concept_code,'\.','','g')
      and cc.vocabulary_id in ('ICD10') 
      ) -- vocabulary to be mandatory matched
    

AND exists(
    select 1
      from devv5.concept cc
      where gm.kod = regexp_replace (cс.concept_code,'\.','','g')
      and cc.vocabulary_id in ('ICD10CM') -- vocabulary to be mandatory matched
    )

AND NOT exists(
    select 1
      from devv5.concept cc
      JOIN devv5.concept ccc
          ON cc.concept_name = ccc.concept_name AND cc.concept_code = ccc.concept_code
      where gm.kod = regexp_replace (cс.concept_code,'\.','','g') AND cc.vocabulary_id in ('ICD10') AND ccc.vocabulary_id in ('ICD10CM')
    )

order by c.concept_code
limit 100
;

--не заджойнилось с целевым словарем (в случае ICD берем сразу ДВА целевых словаря)
--это пытаемся заджонить вручную (Афина + SQL)
--каунт отсюда не берем
select distinct kod, kodtext
from  EU_SE_ICD10_SE_2019 gm
left join devv5.concept c
on gm.kod=regexp_replace (c.concept_code,'\.','','g')
         and  c.vocabulary_id in ('ICD10', 'ICD10CM') --target vocabs
where c.concept_code is null
;

--COUNT of OMOPed source codes
--12580
SELECT COUNT (*)
FROM (
    SELECT DISTINCT kod as concept_code
    FROM EU_SE_ICD10_SE_2019
         ) as a
where exists
      (select 1
      from devv5.concept c
      where a.concept_code = regexp_replace (c.concept_code, '\.','','g')
            and c.vocabulary_id in ('ICD10', 'ICD10CM') -- target vobulary(ies) initially confirmed above as equivalent by meaning
)
;

--COUNT of mapped source codes
--12503
SELECT COUNT (*)
FROM (
    SELECT DISTINCT kod as concept_code
    FROM EU_SE_ICD10_SE_2019
         ) as a
where exists
      (select 1
      from devv5.concept c
            join devv5.concept_relationship cr
                  ON c.concept_id = cr.concept_id_1
      where a.concept_code = regexp_replace (c.concept_code, '\.','','g')
            and c.vocabulary_id in ('ICD10', 'ICD10CM')  -- target vobulary(ies) initially confirmed above as equivalent by meaning
            and cr.relationship_id = 'Maps to'
            and cr.invalid_reason is null)
;

--каунт сорс кодов, заджойненных только с ICD10
--1666
SELECT COUNT (*)
FROM (
    SELECT DISTINCT kod as concept_code
    FROM EU_SE_ICD10_SE_2019
         ) as a

where exists
      (select 1
      from devv5.concept c
      where a.concept_code = regexp_replace (c.concept_code, '\.','','g')
            and c.vocabulary_id in ('ICD10', 'ICD10CM')

AND NOT exists(
    select 1
      from devv5.concept cc
      where a.concept_code = regexp_replace (cc.concept_code, '\.','','g')
      and cc.vocabulary_id in ('ICD10CM')
    )
)
;

--каунт сорс кодов, заджойненных только с ICD10CM
--779
SELECT COUNT (*)
FROM (
    SELECT DISTINCT kod as concept_code
    FROM EU_SE_ICD10_SE_2019
         ) as a

where exists
      (select 1
      from devv5.concept c
      where left (a.concept_code, 4) = regexp_replace (c.concept_code, '\.','','g')
      or left (a.concept_code, 3) = regexp_replace (c.concept_code, '\.','','g')
            and c.vocabulary_id in ('ICD10', 'ICD10CM')

AND NOT exists(
    select 1
      from devv5.concept cc
      where a.concept_code = regexp_replace (cc.concept_code, '\.','','g')
      and cc.vocabulary_id in ('ICD10')
    )
)
;

--каунт сорс кодов, заджойненных сразу с ICD10 и ICD10CM
--10135
SELECT COUNT (*)
FROM (
    SELECT DISTINCT kod as concept_code
    FROM EU_SE_ICD10_SE_2019
         ) as a

where exists
      (select 1
      from devv5.concept c
      where a.concept_code = regexp_replace (c.concept_code, '\.','','g')
            and c.vocabulary_id in ('ICD10')

AND exists(
    select 1
      from devv5.concept cc
      where a.concept_code = regexp_replace (cc.concept_code, '\.','','g')
      and cc.vocabulary_id in ('ICD10CM')
    )
)
;
select * from devv5.vocabulary;


--drugs
-- EU_SE_NSL for ingridients

create table EU_SE_NSL (
timestamp	varchar, ns1SeNSLid varchar,
ns1Name varchar,	ns1RecommendedNameClassLx varchar,
ns1NarcoticClass varchar,	ns1RelatedSeNSLid varchar,	ns1SubstSubstRelationLx varchar);

--count of distinct NSL2019 ingridients   =6279
select count (distinct ns1SeNSLid) from EU_SE_NSL;



