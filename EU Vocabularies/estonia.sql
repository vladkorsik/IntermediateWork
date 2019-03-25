--Estonia
--Drug
--ATC

Create table EU_EE_ATC_v1 
( ATC_kood varchar,	Nimi varchar);

--Число концептов в source vocabulary
--5168
select count (distinct ATC_kood)
from  EU_EE_ATC_v1 
;

--Число концептов в target CDM vocabulary
--ATC 6211
select vocabulary_id, COUNT (DISTINCT concept_code)
from devv5.concept
WHERE vocabulary_id in ('ATC')
GROUP BY vocabulary_id
;

--Проверка качества джойна с одним словарем
-- актуально только когда джойним ОДИН словарь
--для ICD джойним всегда ДВА, поэтому для ICD SQL скрипт чуть ниже
--каунт отсюда не берем
select gm.ATC_kood, gm.nimi, c.concept_name
from EU_EE_ATC_v1  gm
join devv5.concept c
         on c.concept_code = gm.ATC_kood
            AND c.vocabulary_id in ('ATC') -- vocabulary to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes
order by random ()
limit 1000
;

--Проверка качества джойна с одним словарем
-- актуально только когда джойним ОДИН словарь
--для ICD джойним всегда ДВА, поэтому для ICD SQL скрипт чуть ниже
--каунт отсюда не берем
select gm.ATC_kood, gm.nimi, c.concept_name
from EU_EE_ATC_v1  gm
join devv5.concept c
         on c.concept_code = gm.ATC_kood
            AND c.vocabulary_id in ('EphMRA ATC') -- vocabulary to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes
order by random ();

--Проверка качества джойна с ATC, исключая EphMRA ATC
--каунт отсюда не берем
select gm.ATC_kood, gm.nimi, c.concept_name
from EU_EE_ATC_v1 gm
join devv5.concept c
         on c.concept_code = gm.ATC_kood
            AND c.vocabulary_id in ('ATC', 'EphMRA ATC') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where NOT exists(
    select 1
      from devv5.concept cc
      where gm.ATC_kood = cc.concept_code
      and cc.vocabulary_id in ('EphMRA ATC') -- vocabulary to be excluded
    )
order by random ()
limit 1000
;

--Проверка качества джойна с ATC, исключая EphMRA ATC
--каунт отсюда не берем
select gm.ATC_kood, gm.nimi, c.concept_name
from EU_EE_ATC_v1 gm
join devv5.concept c
         on c.concept_code = gm.ATC_kood
            AND c.vocabulary_id in ('ATC', 'EphMRA ATC') -- vocabularies to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes

where NOT exists(
    select 1
      from devv5.concept cc
      where gm.ATC_kood = cc.concept_code
      and cc.vocabulary_id in ('ATC') -- vocabulary to be excluded
    )
order by random ()
limit 1000
;

--COUNT of OMOPed source codes
--4536
SELECT COUNT (*)
FROM (
    SELECT DISTINCT ATC_kood as concept_code
    FROM EU_EE_ATC_v1
         ) as a
where exists
      (select 1
      from devv5.concept c
      where a.concept_code = c.concept_code
            and c.vocabulary_id in ('ATC', 'EphMRA ATC') -- target vobulary(ies) initially confirmed above as equivalent by meaning
)
;

--COUNT of mapped source codes
--2435
SELECT COUNT (*)
FROM (
    SELECT DISTINCT ATC_kood as concept_code
    FROM EU_EE_ATC_v1
         ) as a
where exists
      (select 1
      from devv5.concept c
            join devv5.concept_relationship cr
                  ON c.concept_id = cr.concept_id_1
      where a.concept_code = c.concept_code
            and c.vocabulary_id in ('ATC', 'EphMRA ATC')  -- target vobulary(ies) initially confirmed above as equivalent by meaning
            and cr.relationship_id = 'Maps to'
            and cr.invalid_reason is null)
;

--не заджойнилось с целевым словарем (в случае ICD берем сразу ДВА целевых словаря)
--это пытаемся заджонить вручную (Афина + SQL)
--каунт отсюда не берем
select distinct ATC_kood, nimi
from  EU_EE_ATC_v1 gm
left join devv5.concept c
on gm.ATC_kood=c.concept_code
         and  c.vocabulary_id in ('ATC', 'EphMRA ATC') --target vocabs
where c.concept_code is null;



--LOINC fo Labs in Estonia
create table EU_EE_LAB_LOINC (id	varchar, Loinc_code varchar,	LongCommonName varchar);


--Число концептов в target CDM vocabulary
--LOINC 152444
select vocabulary_id, COUNT (DISTINCT concept_code)
from devv5.concept
WHERE vocabulary_id in ('LOINC')
GROUP BY vocabulary_id
;

--Проверка качества джойна с одним словарем
-- актуально только когда джойним ОДИН словарь
--для ICD джойним всегда ДВА, поэтому для ICD SQL скрипт чуть ниже
--каунт отсюда не берем
select gm.Loinc_code, gm.LongCommonName, c.concept_name
from EU_EE_LAB_LOINC  gm
join devv5.concept c
         on c.concept_code = gm.Loinc_code
            AND c.vocabulary_id in ('LOINC') -- vocabulary to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes
order by random ()
limit 1000
;

--COUNT of OMOPed source codes
--3680
SELECT COUNT (*)
FROM (
    SELECT DISTINCT Loinc_code as concept_code
    FROM  EU_EE_LAB_LOINC
         ) as a
where exists
      (select 1
      from devv5.concept c
      where regexp_replace (a.concept_code, '\.','', 'g') = c.concept_code
            and c.vocabulary_id in ('LOINC') -- target vobulary(ies) initially confirmed above as equivalent by meaning
)
;

--COUNT of mapped source codes
--3677
SELECT COUNT (*)
FROM (
    SELECT DISTINCT Loinc_code as concept_code
    FROM EU_EE_LAB_LOINC
         ) as a
where exists
      (select 1
      from devv5.concept c
            join devv5.concept_relationship cr
                  ON c.concept_id = cr.concept_id_1
     where regexp_replace (a.concept_code, '\.','', 'g') = c.concept_code
            and c.vocabulary_id in ('LOINC')  -- target vobulary(ies) initially confirmed above as equivalent by meaning
            and cr.relationship_id = 'Maps to'
            and cr.invalid_reason is null)
;

--не заджойнилось с целевым словарем (в случае ICD берем сразу ДВА целевых словаря)
--это пытаемся заджонить вручную (Афина + SQL)
--каунт отсюда не берем
select distinct Loinc_code, LongCommonName
from EU_EE_LAB_LOINC gm
left join devv5.concept c
on regexp_replace (gm.Loinc_code, '\.','', 'g') = c.concept_code
         and  c.vocabulary_id in ('LOINC') --target vocabs
where c.concept_code is null;



