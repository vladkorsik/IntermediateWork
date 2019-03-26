--France
--OMAP-BDPM Count=40399
select count (*) from devv5.concept where vocabulary_id like '%BDPM%';

--COUNT of mapped BDPM 21753
SELECT COUNT ( * )
FROM (
    SELECT DISTINCT concept_code as concept_code
    FROM devv5.concept where vocabulary_id in ('BDPM')
         ) as a
where exists
(select 1
from devv5.concept c
join devv5.concept_relationship cr
ON c.concept_id = cr.concept_id_1
where a.concept_code = c.concept_code
and c.vocabulary_id in ('BDPM')
and cr.relationship_id = 'Maps to'
and cr.invalid_reason is null)
;
select * FROM devv5.concept where vocabulary_id in ('BDPM') limit 1000;

--BDPM2019
Create table EU_FR_BDPM_CIP_2019 (
CIP13 	varchar,
CIP7	varchar, LIBELLE varchar);

--Проверка качества джойна со словарем
select cip13, libelle, c.concept_name
from EU_FR_BDPM_CIP_2019
join devv5.concept c on c.concept_code=cip13 where c.vocabulary_id='BDPM' 
order by random () 
limit 100;

--count total BDPM source = 42547
select count (distinct cip13) from EU_FR_BDPM_CIP_2019;

--COUNT of OMOPED 20449
SELECT COUNT ( * )
FROM (
SELECT DISTINCT cip13 
as concept_code    
FROM EU_FR_BDPM_CIP_2019
 ) as a
where exists 
(select 1
 from devv5.concept c 
where a.concept_code = c.concept_code
and c.vocabulary_id in ('BDPM'))
;

--COUNT of mapped 18463
SELECT COUNT ( * )
FROM (
SELECT DISTINCT cip13 
as concept_code   
 FROM EU_FR_BDPM_CIP_2019
         ) as a 
where exists 
(select 1
 from devv5.concept c 
join devv5.concept_relationship cr 
ON c.concept_id = cr.concept_id_1
where a.concept_code = c.concept_code 
and c.vocabulary_id in ('BDPM')
and cr.relationship_id = 'Maps to'
and cr.invalid_reason is null)
;

---не заджойнилось сорс_словарь с CDM-овым 22098
select distinct cip13,LIBELLE
from  EU_FR_BDPM_CIP_2019
left join devv5.concept c
on cip13=c.concept_code and  c.vocabulary_id ilike 'BDPM'
where c.concept_code is null;
--_____
select distinct sab from sources.mrconso where sab like  'MSH%' or sab like 'LNC%';

--count of source LNC-FR-FR = 48447
SELECT count(DISTINCT code) 
FROM sources.mrconso
 where sab = 'LNC-FR-FR';

--LOINC_FR omaped count 48447
SELECT COUNT ( * )
FROM (
    SELECT DISTINCT code as concept_code
    FROM sources.mrconso where sab = 'LNC-FR-FR'
         ) as a
where exists
(select 1
from devv5.concept c
where a.concept_code = c.concept_code
and c.vocabulary_id in ('LOINC') 
)
;

--count of Mapped LNC-FR-FR=48433
SELECT COUNT (*)
FROM (
    SELECT DISTINCT code as concept_code
    FROM sources.mrconso where sab = 'LNC-FR-FR'
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
--source MeSH FR count =28939
select count (distinct code) 
from sources.mrconso 
where sab = 'MSHFRE';


--OMAPed MeSH FR count = 7767
SELECT COUNT ( * )
FROM (
    SELECT DISTINCT code as concept_code
    FROM sources.mrconso where sab = 'MSHFRE'
         ) as a
where exists
(select 1
from devv5.concept c
where a.concept_code = c.concept_code
and c.vocabulary_id in ('MeSH') 
)
;

--count of Mapped MSHFRE=7589
SELECT COUNT (*)
FROM (
    SELECT DISTINCT code as concept_code
    FROM sources.mrconso where sab = 'MSHFRE'
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
--devices
--lpp
create table EU_FR_LPP_2019 (code varchar,	Name varchar);

--LPP count 2404
select count (distinct code) from EU_FR_LPP_2019;

