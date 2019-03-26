--NL
--ICD10NL2014

--ICD10NL v2
CREATE TABLE EU_NL_ICD10_NL_v2 (
     Code         varchar,
      Level         varchar,
      Classkind           varchar,
      preferred         varchar,
      definition        varchar,
      description          varchar,
      relatedTerm      varchar,
      remark varchar,
      inclusion         varchar,
      exclusion   varchar,
      codinghint   varchar,
      footnote   varchar,
      note          varchar);
select * from EU_NL_ICD10_NL_v2 limit 10;
-- ICD10NL count=39075    
select count (distinct code) from  EU_NL_ICD10_NL_v2;

--ICD10NL OMOPed count=16716
select count (distinct nl.code)
 from EU_NL_ICD10_NL_v2 nl 
 join devv5.concept c 
 on regexp_replace(nl.code, '\*|\+', '', 'g')=c.concept_code 
 and vocabulary_id ilike 'ICD10%';
 
--NL
-- ICD10NL Mapped count 16637
SELECT COUNT ( * )
FROM (
    SELECT DISTINCT code as concept_code
    FROM EU_NL_ICD10_NL_v2
         ) as a
where exists
(select 1
from devv5.concept c
join devv5.concept_relationship cr
ON c.concept_id = cr.concept_id_1
where regexp_replace (a.concept_code, '\*|\+', '', 'g') = c.concept_code
and c.vocabulary_id in ('ICD10', 'ICD10CM')
and cr.relationship_id = 'Maps to'
and cr.invalid_reason is null); 

--COUNT of OMOPED ICD10NL v2 = 16716
SELECT COUNT ( * )
FROM (
    SELECT DISTINCT code as concept_code
    FROM EU_NL_ICD10_NL_v2
         ) as a
where exists
(select 1
from devv5.concept c join EU_NL_ICD10_NL_v2 
on regexp_replace (a.concept_code, '\*|\+', '', 'g') = c.concept_code
and c.vocabulary_id in ('ICD10', 'ICD10CM')
)
;

--Germany
--ICD10-GM
--Creation of source table


--Число концептов в source vocabulary
--39075
select count (distinct regexp_replace(code, '\*|\+', '', 'g'))
from EU_NL_ICD10_NL_v2
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
select gm.code, gm.preferred, c.concept_name
from EU_NL_ICD10_NL_v2 gm
join devv5.concept c
         on c.concept_code = gm.code
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where NOT exists(
    select 1
      from devv5.concept cc
      where gm.code = cc.concept_code
      and cc.vocabulary_id in ('ICD10CM') -- vocabulary to be excluded
    )
order by random ()
limit 1000
;

--Проверка качества джойна с ICD10CM, исключая ICD10
--то есть наоборот
--каунт отсюда не берем
select gm.code, gm.preferred, c.concept_name
from EU_NL_ICD10_NL_v2 gm
join devv5.concept c
         on  regexp_replace(gm.code, '\*|\+', '', 'g')=c.concept_code
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where NOT exists(
    select 1
      from devv5.concept cc
      where  regexp_replace(gm.code, '\*|\+', '', 'g') = cc.concept_code
      and cc.vocabulary_id in ('ICD10') -- vocabulary to be excluded
    )
order by random ();

--Проверка качества джойна с ICD10CM и ICD10
-- (обязательное наличие кода сразу в 2х словорях, и при этом с одинаковыми именами в разных словарях)
--каунт тут не берем
select  gm.code, gm.preferred, c.concept_name
from EU_NL_ICD10_NL_v2 gm
join devv5.concept c
        on  regexp_replace(gm.code, '\*|\+', '', 'g')=c.concept_code
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where exists(
    select 1
      from devv5.concept cc
      where  gm.code = cc.concept_code
      and cc.vocabulary_id in ('ICD10') -- vocabulary to be mandatory matched
    )

AND exists(
    select 1
      from devv5.concept cc
      where  gm.code = cc.concept_code
      and cc.vocabulary_id in ('ICD10CM') -- vocabulary to be mandatory matched
    )

AND exists(
    select 1
      from devv5.concept cc
      JOIN devv5.concept ccc
          ON cc.concept_name = ccc.concept_name AND cc.concept_code = ccc.concept_code
      where  gm.code = cc.concept_code AND cc.vocabulary_id in ('ICD10') AND ccc.vocabulary_id in ('ICD10CM')
    )

order by random ()
limit 1000
;


--Проверка качества джойна с ICD10CM и ICD10
-- (обязательное наличие кода сразу в 2х словорях, но при этом с разными именами в разных словарях)
--каунт отсюда не берем
select  gm.code, c.vocabulary_id, gm.preferred, c.concept_name
from EU_NL_ICD10_NL_v2 gm
join devv5.concept c
        on  regexp_replace(gm.code, '\*|\+', '', 'g')=c.concept_code
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where exists(
    select 1
      from devv5.concept cc
      where  gm.code = cc.concept_code
      and cc.vocabulary_id in ('ICD10') -- vocabulary to be mandatory matched
    )

AND exists(
    select 1
      from devv5.concept cc
      where  gm.code = cc.concept_code
      and cc.vocabulary_id in ('ICD10CM') -- vocabulary to be mandatory matched
    )

AND NOT exists(
    select 1
      from devv5.concept cc
      JOIN devv5.concept ccc
          ON cc.concept_name = ccc.concept_name AND cc.concept_code = ccc.concept_code
      where  gm.code = cc.concept_code AND cc.vocabulary_id in ('ICD10') AND ccc.vocabulary_id in ('ICD10CM')
    )

order by c.concept_code
limit 1000
;

--не заджойнилось с целевым словарем (в случае ICD берем сразу ДВА целевых словаря)
--это пытаемся заджонить вручную (Афина + SQL)
--каунт отсюда не берем
select distinct code, preferred
from  EU_NL_ICD10_NL_v2 gm
left join devv5.concept c
on  regexp_replace(gm.code, '\*|\+', '', 'g')=c.concept_code
         and  c.vocabulary_id in ('ICD10', 'ICD10CM') --target vocabs
where c.concept_code is null
;

--COUNT of OMOPed source codes
--16716
SELECT COUNT (*)
FROM (
    SELECT DISTINCT code as concept_code
    FROM EU_NL_ICD10_NL_v2 
         ) as a
where exists
      (select 1
      from devv5.concept cc
      where regexp_replace(a.concept_code, '\*|\+', '', 'g') = cc.concept_code
            and cc.vocabulary_id in ('ICD10', 'ICD10CM') -- target vobulary(ies) initially confirmed above as equivalent by meaning
)
;

--COUNT of mapped source codes
--16637
SELECT COUNT (*)
FROM (
    SELECT DISTINCT code as concept_code
    FROM EU_NL_ICD10_NL_v2
         ) as a
where exists
      (select 1
      from devv5.concept c
            join devv5.concept_relationship cr
                  ON c.concept_id = cr.concept_id_1
      where regexp_replace(a.concept_code, '\*|\+', '', 'g') = c.concept_code
            and c.vocabulary_id in ('ICD10', 'ICD10CM')  -- target vobulary(ies) initially confirmed above as equivalent by meaning
            and cr.relationship_id = 'Maps to'
            and cr.invalid_reason is null)
;

--каунт сорс кодов, заджойненных только с ICD10
--3246
SELECT COUNT (*)
FROM (
    SELECT DISTINCT code as concept_code
    FROM EU_NL_ICD10_NL_v2
         ) as a

where exists
      (select 1
      from devv5.concept c
      where regexp_replace(a.concept_code, '\*|\+', '', 'g') = c.concept_code
            and c.vocabulary_id in ('ICD10', 'ICD10CM')

AND NOT exists(
    select 1
      from devv5.concept cc
      where regexp_replace(a.concept_code, '\*|\+', '', 'g') = cc.concept_code
      and cc.vocabulary_id in ('ICD10CM')
    )
)
;

--каунт сорс кодов, заджойненных только с ICD10CM
--1159
SELECT COUNT (*)
FROM (
    SELECT DISTINCT code as concept_code
    FROM EU_NL_ICD10_NL_v2
         ) as a

where exists
      (select 1
      from devv5.concept c
      where regexp_replace(a.concept_code, '\*|\+', '', 'g') = c.concept_code
            and c.vocabulary_id in ('ICD10', 'ICD10CM')

AND NOT exists(
    select 1
      from devv5.concept cc
      where regexp_replace(a.concept_code, '\*|\+', '', 'g') = cc.concept_code
      and cc.vocabulary_id in ('ICD10')
    )
)
;

--каунт сорс кодов, заджойненных сразу с ICD10 и ICD10CM
--12311
SELECT COUNT (*)
FROM (
    SELECT DISTINCT code as concept_code
    FROM EU_NL_ICD10_NL_v2
         ) as a

where exists
      (select 1
      from devv5.concept c
      where regexp_replace(a.concept_code, '\*|\+', '', 'g') = c.concept_code
            and c.vocabulary_id in ('ICD10')

AND exists(
    select 1
      from devv5.concept cc
      where regexp_replace(a.concept_code, '\*|\+', '', 'g') = cc.concept_code
      and cc.vocabulary_id in ('ICD10CM')
    )
)
;
--LOINC nl
--count of source LOinc NL=52516
SELECT count(DISTINCT code) 
FROM sources.mrconso 
where sab = 'LNC-NL-NL';

--OMAPed LOINC nl 52516
SELECT COUNT ( * )
FROM (
    SELECT DISTINCT code as concept_code
    FROM sources.mrconso where sab = 'LNC-NL-NL'
         ) as a
where exists
(select 1
from devv5.concept c
where a.concept_code = c.concept_code
and c.vocabulary_id in ('LOINC') 
)
;
--coutn of mapped loinc nl =51879
SELECT COUNT (*)
FROM (
    SELECT DISTINCT code as concept_code
    FROM sources.mrconso where sab = 'LNC-NL-NL'
         ) as a
where exists
      (select 1
      from devv5.concept c
            join devv5.concept_relationship cr
                  ON c.concept_id = cr.concept_id_1
      where a.concept_code = c.concept_code
            and c.vocabulary_id in ('LOINC')  -- target vobulary(ies) initially confirmed above as equivalent by meaning
            and cr.relationship_id = 'Maps to'
            and cr.invalid_reason is null)
;

select distinct sab from sources.mrconso where sab like  'MSH%';

--MeSH Dut
--count of source MSHDUT=15166
SELECT count(DISTINCT code) 
FROM sources.mrconso 
where sab = 'MSHDUT';

--MSHDUT omaped count 5021
SELECT COUNT ( * )
FROM (
    SELECT DISTINCT code as concept_code
    FROM sources.mrconso where sab = 'MSHDUT'
         ) as a
where exists
(select 1
from devv5.concept c
where a.concept_code = c.concept_code
and c.vocabulary_id in ('MeSH') 
)
;

--coutn of mapped MSHDUT =4901
SELECT COUNT (*)
FROM (
    SELECT DISTINCT code as concept_code
    FROM sources.mrconso where sab = 'MSHDUT'
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
