--czech republic
--ICD10

create table EU_CZ_MKN10
( KodSTeckou	varchar, CleneniNaPatemMiste varchar,	Nazev varchar,	NazevPlny varchar
)
;

select * from EU_CZ_MKN10 limit 1000;


--Число концептов в source vocabulary
--38756
select count (distinct KodSTeckou)
from  EU_CZ_MKN10
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
select gm.KodSTeckou, gm.nazev, c.concept_name
from  EU_CZ_MKN10  gm
join devv5.concept c
         on c.concept_code = gm.KodSTeckou
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where NOT exists(
    select 1
      from devv5.concept cc
      where gm.KodSTeckou = cc.concept_code
      and cc.vocabulary_id in ('ICD10CM') -- vocabulary to be excluded
    )
order by random ()
limit 1000
;

--Проверка качества джойна с ICD10CM, исключая ICD10
--то есть наоборот
--каунт отсюда не берем
select gm.KodSTeckou, gm.nazevplny, c.concept_name
from  EU_CZ_MKN10  gm
join devv5.concept c
         on c.concept_code = gm.KodSTeckou
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where NOT exists(
    select 1
      from devv5.concept cc
      where gm.KodSTeckou = cc.concept_code
      and cc.vocabulary_id in ('ICD10') -- vocabulary to be excluded
    )
order by random ()
limit 1000
;

--Проверка качества джойна с ICD10CM и ICD10
-- (обязательное наличие кода сразу в 2х словорях, и при этом с одинаковыми именами в разных словарях)
--каунт тут не берем
select gm.KodSTeckou, gm.nazev, c.concept_name
from  EU_CZ_MKN10  gm
join devv5.concept c
         on c.concept_code = gm.KodSTeckou
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where exists(
    select 1
      from devv5.concept cc
      where gm.KodSTeckou = cc.concept_code
      and cc.vocabulary_id in ('ICD10') -- vocabulary to be mandatory matched
    )

AND exists(
    select 1
      from devv5.concept cc
      where gm.KodSTeckou = cc.concept_code
      and cc.vocabulary_id in ('ICD10CM') -- vocabulary to be mandatory matched
    )

AND exists(
    select 1
      from devv5.concept cc
      JOIN devv5.concept ccc
          ON cc.concept_name = ccc.concept_name AND cc.concept_code = ccc.concept_code
      where gm.KodSTeckou = cc.concept_code AND cc.vocabulary_id in ('ICD10') AND ccc.vocabulary_id in ('ICD10CM')
    )

order by random ()
limit 1000
;


--Проверка качества джойна с ICD10CM и ICD10
-- (обязательное наличие кода сразу в 2х словорях, но при этом с разными именами в разных словарях)
--каунт отсюда не берем
select gm.KodSTeckou, c.vocabulary_id, gm.nazev, c.concept_name
from  EU_CZ_MKN10  gm
join devv5.concept c
         on c.concept_code = gm.KodSTeckou
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where exists(
    select 1
      from devv5.concept cc
      where gm.KodSTeckou = cc.concept_code
      and cc.vocabulary_id in ('ICD10') -- vocabulary to be mandatory matched
    )

AND exists(
    select 1
      from devv5.concept cc
      where gm.KodSTeckou = cc.concept_code
      and cc.vocabulary_id in ('ICD10CM') -- vocabulary to be mandatory matched
    )

AND NOT exists(
    select 1
      from devv5.concept cc
      JOIN devv5.concept ccc
          ON cc.concept_name = ccc.concept_name AND cc.concept_code = ccc.concept_code
      where gm.KodSTeckou = cc.concept_code AND cc.vocabulary_id in ('ICD10') AND ccc.vocabulary_id in ('ICD10CM')
    )

order by c.concept_code
limit 1000
;

--не заджойнилось с целевым словарем (в случае ICD берем сразу ДВА целевых словаря)
--это пытаемся заджонить вручную (Афина + SQL)
--каунт отсюда не берем
select distinct KodSTeckou, nazev
from   EU_CZ_MKN10  gm
left join devv5.concept c
on gm.KodSTeckou=c.concept_code
         and  c.vocabulary_id in ('ICD10', 'ICD10CM') --target vocabs
where c.concept_code is null
;

--COUNT of OMOPed source codes
--16761
SELECT COUNT (*)
FROM (
    SELECT DISTINCT KodSTeckou as concept_code
    FROM  EU_CZ_MKN10 
         ) as a
where exists
      (select 1
      from devv5.concept c
      where a.concept_code = c.concept_code
            and c.vocabulary_id in ('ICD10', 'ICD10CM') -- target vobulary(ies) initially confirmed above as equivalent by meaning
)
;

--COUNT of mapped source codes
--16679
SELECT COUNT (*)
FROM (
    SELECT DISTINCT KodSTeckou as concept_code
    FROM  EU_CZ_MKN10 
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
--3254
SELECT COUNT (*)
FROM (
    SELECT DISTINCT KodSTeckou as concept_code
    FROM  EU_CZ_MKN10 
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
--1207
SELECT COUNT (*)
FROM (
    SELECT DISTINCT KodSTeckou as concept_code
    FROM  EU_CZ_MKN10 
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
--12300
SELECT COUNT (*)
FROM (
    SELECT DISTINCT KodSTeckou as concept_code
    FROM  EU_CZ_MKN10 
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
--______________
--Count of MeShCze = 28939
SELECT count(DISTINCT code) 
FROM sources.mrconso 
where sab = 'MSHCZE';

--MSHCZE omaped count 7767
SELECT COUNT ( * )
FROM (
    SELECT DISTINCT code as concept_code
    FROM sources.mrconso where sab = 'MSHCZE'
         ) as a
where exists
(select 1
from devv5.concept c
where a.concept_code = c.concept_code
and c.vocabulary_id in ('MeSH') 
)
;


--COUNT of MSHCZE mapped source codes
--7589
SELECT COUNT (*)
FROM (
    SELECT DISTINCT code as concept_code
    FROM sources.mrconso where sab = 'MSHCZE'
         ) as a
where exists
      (select 1
      from devv5.concept c
            join devv5.concept_relationship cr
                  ON c.concept_id = cr.concept_id_1
      where a.concept_code = c.concept_code
            and c.vocabulary_id in ('MeSH')  -- target vobulary(ies) initially confirmed above as equivalent by meaning
            and cr.relationship_id = 'Maps to'
            and cr.invalid_reason is null)
;

select distinct sab 
from sources.mrconso 
where sab like  'LNC%';

--MeShCze 28939
SELECT count(DISTINCT code) 
FROM sources.mrconso 
where sab = 'MSHGER';

--condition disbility
--ICF2016 czech count 1417
select count (distinct code)
from eu_czech_icf_who_2016 
where level in ('3','4','5');

--drugs SUKL
create table EU_CZ_SUKL_2019 
(KOD_SUKL	varchar, NAZEV varchar,	
SILA	varchar, FORMA	varchar, 
BALENI varchar,	CESTA varchar,
DOPLNEK varchar, OBAL varchar, DRZ	varchar, 
ZEMDRZ varchar,	AKT_DRZ varchar,	AKT_ZEM varchar,
REG varchar,	V_PLATDO varchar,	NEOMEZ varchar,
UVADENIDO varchar,	IS_ varchar,	ATC_WHO varchar
)
;
--Число концептов в source vocabulary
--SUKL count=64659
select count (distinct KOD_SUKL)
from EU_CZ_SUKL_2019
;

--Число концептов в source vocabulary
--ATC count =1736
select count (distinct ATC_WHO)
from EU_CZ_SUKL_2019
;

--Число концептов в target CDM vocabulary
--ATC=6211
select vocabulary_id, COUNT (DISTINCT concept_code)
from devv5.concept
WHERE vocabulary_id in ('ATC')
GROUP BY vocabulary_id
;

--Проверка качества джойна с одним словарем
-- актуально только когда джойним ОДИН словарь
--для ICD джойним всегда ДВА, поэтому для ICD SQL скрипт чуть ниже
--каунт отсюда не берем
select gm.ATC_WHO, gm.NAZEV, c.concept_name
from EU_CZ_SUKL_2019 gm
join devv5.concept c
         on c.concept_code = gm.ATC_WHO
            AND c.vocabulary_id in ('ATC') -- vocabulary to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes
order by random ()
limit 1000
;


