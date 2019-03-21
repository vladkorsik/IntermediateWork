create table OPCS48
(
  code varchar(50),
  description varchar(500)
);

--Число концептов в source vocabulary
--11000
select count (distinct code)
from OPCS48
;

--Число концептов в target CDM vocabulary
--OPCS4 11000
select vocabulary_id, COUNT (DISTINCT concept_code)
from devv5.concept
WHERE vocabulary_id in ('OPCS4')
GROUP BY vocabulary_id
;

--Проверка качества джойна с одним словарем
-- актуально только когда джойним ОДИН словарь
--для ICD джойним всегда ДВА, поэтому для ICD SQL скрипт чуть ниже
--каунт отсюда не берем
select code, description, c.concept_name
from OPCS48
join devv5.concept c
         on c.concept_code = code
            AND c.vocabulary_id in ('OPCS4') -- vocabulary to be joined
            --AND concept_code like '%%' --uncomment here to use any patterns to check separately different portions of source vocabulary codes
order by random ()
limit 1000
;

--не заджойнилось с целевым словарем (в случае ICD берем сразу ДВА целевых словаря)
--это пытаемся заджонить вручную (Афина + SQL)
--каунт отсюда не берем
select distinct code, description
from  OPCS48
left join devv5.concept c
on code=c.concept_code
         and  c.vocabulary_id in ('OPCS4') --target vocabs
where c.concept_code is null
;

--COUNT of OMOPed source codes
--11000
SELECT COUNT (*)
FROM (
    SELECT DISTINCT code as concept_code
    FROM OPCS48
         ) as a
where exists
      (select 1
      from devv5.concept c
      where a.concept_code = c.concept_code
            and c.vocabulary_id in ('OPCS4') -- target vobulary(ies) initially confirmed above as equivalent by meaning
)
;

--COUNT of mapped source codes
--10939
SELECT COUNT (*)
FROM (
    SELECT DISTINCT code as concept_code
    FROM OPCS48
         ) as a
where exists
      (select 1
      from devv5.concept c
            join devv5.concept_relationship cr
                  ON c.concept_id = cr.concept_id_1
      where a.concept_code = c.concept_code
            and c.vocabulary_id in ('OPCS4')  -- target vobulary(ies) initially confirmed above as equivalent by meaning
            and cr.relationship_id = 'Maps to'
            and cr.invalid_reason is null)
;
