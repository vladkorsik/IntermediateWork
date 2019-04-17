--Germany 
--ICD10-GM
CREATE TABLE EU_DEU_ICD10_GM_2019 (
      Ebene         varchar(1),
      Ort           varchar(1),
      Art           varchar(1),
      KapNr         varchar(2),
      GrVon         varchar(3),
      Code          varchar(7) PRIMARY KEY,
      NormCode      varchar(6),
      CodeOhnePunkt varchar(5),
      Titel         varchar(255),
      Dreisteller   varchar(255),
      Viersteller   varchar(255),
      F?nfsteller   varchar(255),
      P295          varchar(1),
      P301          varchar(1),
      MortL1Code    varchar(5),
      MortL2Code    varchar(5),
      MortL3Code    varchar(5),
      MortL4Code    varchar(5),
      MorbLCode     varchar(5),
      SexCode       varchar(1),
      SexFehlerTyp  varchar(1),
      AltUnt        varchar(4),
      AltOb         varchar(4),
      AltFehlerTyp  varchar(1),
      Exot          varchar(1),
      Belegt        varchar(1),
      IfSGMeldung   varchar(1),
      IfSGLabor     varchar(1)
);

--ICD10WHO
CREATE TABLE EU_DEU_ICD10_WHO_2019 (
      Ebene         varchar(1),
      Ort           varchar(1),
      Art           varchar(1),
      KapNr         varchar(2) ,
      GrVon         varchar(3),
      Code          varchar(7)PRIMARY KEY,
      NormCode      varchar(6)UNIQUE,
      CodeOhnePunkt varchar(5)UNIQUE,
      Titel         varchar(255),
      Dreisteller   varchar(255),
      Viersteller   varchar(255),
      F?nfsteller   varchar(255),
      MortL1Code    varchar(5),
      MortL2Code    varchar(5),
      MortL3Code    varchar(5),
      MortL4Code    varchar(5),
      MorbLCode     varchar(5),
      SexCode       varchar(1),
      SexFehlerTyp  varchar(1),
      AltUntNeu     varchar(4),
      AltObNeu      varchar(4),
      AltFehlerTyp  varchar(1),
      Exot          varchar(1),
      UC            varchar(1)
);

--Germany
--ICD10-GM
--Creation of source table
CREATE TABLE EU_DEU_ICD10_GM_2019 (
      Ebene         varchar(1),
      Ort           varchar(1),
      Art           varchar(1),
      KapNr         varchar(2),
      GrVon         varchar(3),
      Code          varchar(7) PRIMARY KEY,
      NormCode      varchar(6),
      CodeOhnePunkt varchar(5),
      Titel         varchar(255),
      Dreisteller   varchar(255),
      Viersteller   varchar(255),
      F?nfsteller   varchar(255),
      P295          varchar(1),
      P301          varchar(1),
      MortL1Code    varchar(5),
      MortL2Code    varchar(5),
      MortL3Code    varchar(5),
      MortL4Code    varchar(5),
      MorbLCode     varchar(5),
      SexCode       varchar(1),
      SexFehlerTyp  varchar(1),
      AltUnt        varchar(4),
      AltOb         varchar(4),
      AltFehlerTyp  varchar(1),
      Exot          varchar(1),
      Belegt        varchar(1),
      IfSGMeldung   varchar(1),
      IfSGLabor     varchar(1)
)
;

--Число концептов в source vocabulary
--16126
select count (distinct normcode)
from EU_DEU_ICD10_GM_2019
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
select gm.normcode, gm.titel, c.concept_name
from EU_DEU_ICD10_GM_2019 gm
join devv5.concept c
         on c.concept_code = gm.normcode
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where NOT exists(
    select 1
      from devv5.concept cc
      where gm.normcode = cc.concept_code
      and cc.vocabulary_id in ('ICD10CM') -- vocabulary to be excluded
    )
order by random ()
limit 1000
;

--Проверка качества джойна с ICD10CM, исключая ICD10
--то есть наоборот
--каунт отсюда не берем
select gm.normcode, gm.titel, c.concept_name
from EU_DEU_ICD10_GM_2019 gm
join devv5.concept c
         on c.concept_code = gm.normcode
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where NOT exists(
    select 1
      from devv5.concept cc
      where gm.normcode = cc.concept_code
      and cc.vocabulary_id in ('ICD10') -- vocabulary to be excluded
    )
order by random ()
limit 1000
;

--Проверка качества джойна с ICD10CM и ICD10
-- (обязательное наличие кода сразу в 2х словорях, и при этом с одинаковыми именами в разных словарях)
--каунт тут не берем
select gm.normcode, gm.titel, c.concept_name
from EU_DEU_ICD10_GM_2019 gm
join devv5.concept c
         on c.concept_code = gm.normcode
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where exists(
    select 1
      from devv5.concept cc
      where gm.normcode = cc.concept_code
      and cc.vocabulary_id in ('ICD10') -- vocabulary to be mandatory matched
    )

AND exists(
    select 1
      from devv5.concept cc
      where gm.normcode = cc.concept_code
      and cc.vocabulary_id in ('ICD10CM') -- vocabulary to be mandatory matched
    )

AND exists(
    select 1
      from devv5.concept cc
      JOIN devv5.concept ccc
          ON cc.concept_name = ccc.concept_name AND cc.concept_code = ccc.concept_code
      where gm.normcode = cc.concept_code AND cc.vocabulary_id in ('ICD10') AND ccc.vocabulary_id in ('ICD10CM')
    )

order by random ()
limit 1000
;


--Проверка качества джойна с ICD10CM и ICD10
-- (обязательное наличие кода сразу в 2х словорях, но при этом с разными именами в разных словарях)
--каунт отсюда не берем
select gm.normcode, c.vocabulary_id, gm.titel, c.concept_name
from EU_DEU_ICD10_GM_2019 gm
join devv5.concept c
         on c.concept_code = gm.normcode
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where exists(
    select 1
      from devv5.concept cc
      where gm.normcode = cc.concept_code
      and cc.vocabulary_id in ('ICD10') -- vocabulary to be mandatory matched
    )

AND exists(
    select 1
      from devv5.concept cc
      where gm.normcode = cc.concept_code
      and cc.vocabulary_id in ('ICD10CM') -- vocabulary to be mandatory matched
    )

AND NOT exists(
    select 1
      from devv5.concept cc
      JOIN devv5.concept ccc
          ON cc.concept_name = ccc.concept_name AND cc.concept_code = ccc.concept_code
      where gm.normcode = cc.concept_code AND cc.vocabulary_id in ('ICD10') AND ccc.vocabulary_id in ('ICD10CM')
    )

order by c.concept_code
limit 1000
;

--не заджойнилось с целевым словарем (в случае ICD берем сразу ДВА целевых словаря)
--это пытаемся заджонить вручную (Афина + SQL)
--каунт отсюда не берем
select distinct normcode, titel
from  EU_DEU_ICD10_GM_2019 gm
left join devv5.concept c
on gm.normcode=c.concept_code
         and  c.vocabulary_id in ('ICD10', 'ICD10CM') --target vocabs
where c.concept_code is null
;

--COUNT of OMOPed source codes
--14608
SELECT COUNT (*)
FROM (
    SELECT DISTINCT normcode as concept_code
    FROM EU_DEU_ICD10_GM_2019
         ) as a
where exists
      (select 1
      from devv5.concept c
      where a.concept_code = c.concept_code
            and c.vocabulary_id in ('ICD10', 'ICD10CM') -- target vobulary(ies) initially confirmed above as equivalent by meaning
)
;

--COUNT of mapped source codes
--14510
SELECT COUNT (*)
FROM (
    SELECT DISTINCT normcode as concept_code
    FROM EU_DEU_ICD10_GM_2019
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
--2620
SELECT COUNT (*)
FROM (
    SELECT DISTINCT normcode as concept_code
    FROM EU_DEU_ICD10_GM_2019
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
--1135
SELECT COUNT (*)
FROM (
    SELECT DISTINCT normcode as concept_code
    FROM EU_DEU_ICD10_GM_2019
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
--10853
SELECT COUNT (*)
FROM (
    SELECT DISTINCT normcode as concept_code
    FROM EU_DEU_ICD10_GM_2019
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

--EU_DEU_ICD10_WHO_2019
--Число концептов в source vocabulary
--12220
select count (distinct normcode)
from EU_DEU_ICD10_WHO_2019
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
select w.normcode, w.titel, c.concept_name
from EU_DEU_ICD10_WHO_2019 w
join devv5.concept c
         on c.concept_code = w.normcode
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where NOT exists(
    select 1
      from devv5.concept cc
      where w.normcode = cc.concept_code
      and cc.vocabulary_id in ('ICD10CM') -- vocabulary to be excluded
    )
order by random ()
limit 1000
;

--Проверка качества джойна с ICD10CM, исключая ICD10
--то есть наоборот
--каунт отсюда не берем
select gm.normcode, gm.titel, c.concept_name
from EU_DEU_ICD10_WHO_2019 gm
join devv5.concept c
         on c.concept_code = gm.normcode
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where NOT exists(
    select 1
      from devv5.concept cc
      where gm.normcode = cc.concept_code
      and cc.vocabulary_id in ('ICD10') -- vocabulary to be excluded
    )
order by random ()
limit 1000
;

--Проверка качества джойна с ICD10CM и ICD10
-- (обязательное наличие кода сразу в 2х словорях, и при этом с одинаковыми именами в разных словарях)
--каунт тут не берем
select gm.normcode, gm.titel, c.concept_name
from EU_DEU_ICD10_WHO_2019 gm
join devv5.concept c
         on c.concept_code = gm.normcode
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where exists(
    select 1
      from devv5.concept cc
      where gm.normcode = cc.concept_code
      and cc.vocabulary_id in ('ICD10') -- vocabulary to be mandatory matched
    )

AND exists(
    select 1
      from devv5.concept cc
      where gm.normcode = cc.concept_code
      and cc.vocabulary_id in ('ICD10CM') -- vocabulary to be mandatory matched
    )

AND exists(
    select 1
      from devv5.concept cc
      JOIN devv5.concept ccc
          ON cc.concept_name = ccc.concept_name AND cc.concept_code = ccc.concept_code
      where gm.normcode = cc.concept_code AND cc.vocabulary_id in ('ICD10') AND ccc.vocabulary_id in ('ICD10CM')
    )

order by random ()
limit 1000
;


--Проверка качества джойна с ICD10CM и ICD10
-- (обязательное наличие кода сразу в 2х словорях, но при этом с разными именами в разных словарях)
--каунт отсюда не берем
select gm.normcode, c.vocabulary_id, gm.titel, c.concept_name
from EU_DEU_ICD10_WHO_2019 gm
join devv5.concept c
         on c.concept_code = gm.normcode
            AND c.vocabulary_id in ('ICD10', 'ICD10CM') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where exists(
    select 1
      from devv5.concept cc
      where gm.normcode = cc.concept_code
      and cc.vocabulary_id in ('ICD10') -- vocabulary to be mandatory matched
    )

AND exists(
    select 1
      from devv5.concept cc
      where gm.normcode = cc.concept_code
      and cc.vocabulary_id in ('ICD10CM') -- vocabulary to be mandatory matched
    )

AND NOT exists(
    select 1
      from devv5.concept cc
      JOIN devv5.concept ccc
          ON cc.concept_name = ccc.concept_name AND cc.concept_code = ccc.concept_code
      where gm.normcode = cc.concept_code AND cc.vocabulary_id in ('ICD10') AND ccc.vocabulary_id in ('ICD10CM')
    )

order by c.concept_code
limit 1000
;

--не заджойнилось с целевым словарем (в случае ICD берем сразу ДВА целевых словаря)
--это пытаемся заджонить вручную (Афина + SQL)
--каунт отсюда не берем
select distinct normcode, titel
from  EU_DEU_ICD10_WHO_2019 gm
left join devv5.concept c
on gm.normcode=c.concept_code
         and  c.vocabulary_id in ('ICD10', 'ICD10CM') --target vocabs
where c.concept_code is null
;

--COUNT of OMOPed source codes
--12179
SELECT COUNT (*)
FROM (
    SELECT DISTINCT normcode as concept_code
    FROM EU_DEU_ICD10_WHO_2019
         ) as a
where exists
      (select 1
      from devv5.concept c
      where a.concept_code = c.concept_code
            and c.vocabulary_id in ('ICD10', 'ICD10CM') -- target vobulary(ies) initially confirmed above as equivalent by meaning
)
;

--COUNT of mapped source codes
--14510
SELECT COUNT (*)
FROM (
    SELECT DISTINCT normcode as concept_code
    FROM EU_DEU_ICD10_WHO_2019
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
--1585
SELECT COUNT (*)
FROM (
    SELECT DISTINCT normcode as concept_code
    FROM EU_DEU_ICD10_WHO_2019
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
--8
SELECT COUNT (*)
FROM (
    SELECT DISTINCT normcode as concept_code
    FROM EU_DEU_ICD10_WHO_2019
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
--10586
SELECT COUNT (*)
FROM (
    SELECT DISTINCT normcode as concept_code
    FROM EU_DEU_ICD10_WHO_2019
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
--ICDO3 count in CDM=60280
SELECT COUNT (distinct concept_id)
    FROM devv5.concept
         where vocabulary_id in ('ICDO3');

-- AMIS for drugs 
-- Число drug AMIS концептов в OMAP 140083

SELECT COUNT (distinct concept_id)
    FROM devv5.concept
         where vocabulary_id in ('AMIS') and domain_id='Drug';

-- AMIS count of mapped 102723
select count (distinct concept_id)
from devv5.concept c
join devv5.concept_relationship cr
ON c.concept_id = cr.concept_id_1
where c.vocabulary_id in ('AMIS')
and domain_id='Drug'
and cr.relationship_id = 'Maps to'
and cr.invalid_reason is null;

--MeSH 2019 germany
CREATE TABLE ClassificationCodes (
  CC    Varchar,
  ENR   varchar);
 ALTER TABLE ClassificationCodes RENAME TO  EU_DEU_MeSH_2019;

select * from EU_DEU_MeSH_2019 limit 100;
--COUNT of MeSH2109 29349
select count (distinct enr) from EU_DEU_MeSH_2019;

--Проверка качества джойна с одним словарем
-- актуально только когда джойним ОДИН словарь
--для ICD джойним всегда ДВА, поэтому для ICD SQL скрипт чуть ниже
--каунт отсюда не берем
select gm.enr, gm.cc, c.concept_name
from EU_DEU_MeSH_2019 gm
join devv5.concept c
         on c.concept_code = gm.enr
            AND c.vocabulary_id in ('MeSH') -- vocabulary to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes
order by random ()
limit 1000
;

--COUNT of OMOPED MeSH2019 7947
SELECT COUNT ( * )
FROM (
    SELECT DISTINCT enr as concept_code
    FROM EU_DEU_MeSH_2019
         ) as a
where exists
(select 1
from devv5.concept c
where a.concept_code = c.concept_code
and c.vocabulary_id in ('MeSH') 
)
;

--COUNT of mapped MeSH2019 7769
SELECT COUNT ( * )
FROM (
    SELECT DISTINCT enr as concept_code
    FROM EU_DEU_MeSH_2019
         ) as a
where exists
(select 1
from devv5.concept c
join devv5.concept_relationship cr
ON c.concept_id = cr.concept_id_1
where a.concept_code = c.concept_code
and c.vocabulary_id in ('MeSH')
and cr.relationship_id = 'Maps to'
and cr.invalid_reason is null)
;

--
--ops
select count (distinct kode) from eu_deu_ops;



--СOUNT OF  MAPPED MeSHGer=7589
SELECT COUNT (*)
FROM (
    SELECT DISTINCT code as concept_code
    FROM sources.mrconso where sab = 'MSHGER'
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

--count of source LNC-DE-DE = 11059
SELECT count(DISTINCT code) FROM sources.mrconso where sab = 'LNC-DE-DE';

--LOINC_DE omaped count
SELECT COUNT ( * )
FROM (
    SELECT DISTINCT code as concept_code
    FROM sources.mrconso where sab = 'LNC-DE-DE'
         ) as a
where exists
(select 1
from devv5.concept c
where a.concept_code = c.concept_code
and c.vocabulary_id in ('LOINC') 
)
;

--count of Mapped LNC-DE-DE=10916
SELECT COUNT (*)
FROM (
    SELECT DISTINCT code as concept_code
    FROM sources.mrconso where sab = 'LNC-DE-DE'
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

