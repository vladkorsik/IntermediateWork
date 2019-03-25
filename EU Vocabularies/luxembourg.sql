--lux
--drugs
create table EU_LU_CNS_DRUG( "code" varchar, "name" varchar,"ATC" varchar,"A" varchar,"B" varchar,"C" varchar,"D" varchar,"E" varchar,"F" varchar,"G" varchar,"H" varchar);
--count of codes =4695
select count (distinct "code" ) from EU_LU_CNS_DRUG;

--count of atccodes in CNSdrug = 1028
select count (distinct "ATC" ) from EU_LU_CNS_DRUG;

--Проверка качества джойна с одним словарем
-- актуально только когда джойним ОДИН словарь
--для ICD джойним всегда ДВА, поэтому для ICD SQL скрипт чуть ниже
--каунт отсюда не берем
select gm."ATC", gm.name, c.concept_name
from EU_LU_CNS_DRUG gm
join devv5.concept c
         on c.concept_code = regexp_replace(gm."ATC", '\"','','g')
            AND c.vocabulary_id in ('ATC') -- vocabulary to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes
order by random ()
limit 1000
;

--COUNT of OMOPed source codes
--1026
SELECT COUNT (*)
FROM (
    SELECT DISTINCT "ATC" as concept_code
    FROM EU_LU_CNS_DRUG
         ) as a
where exists
      (select 1
      from devv5.concept c
      where regexp_replace(a.concept_code, '\"','','g') = c.concept_code
            and c.vocabulary_id in ('ATC') -- target vobulary(ies) initially confirmed above as equivalent by meaning
)
;
--COUNT of mapped source codes
--764
SELECT COUNT (*)
FROM (
    SELECT DISTINCT "ATC" as concept_code
    FROM EU_LU_CNS_DRUG
         ) as a
where exists
      (select 1
      from devv5.concept c
            join devv5.concept_relationship cr
                  ON c.concept_id = cr.concept_id_1
      where regexp_replace(a.concept_code, '\"','','g') = c.concept_code
            and c.vocabulary_id in ('ATC')  -- target vobulary(ies) initially confirmed above as equivalent by meaning
            and cr.relationship_id = 'Maps to'
            and cr.invalid_reason is null)
;
