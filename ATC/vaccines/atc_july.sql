--July 4th
-- list of brand names for clinical drug forms
INSERT INTO ATC_brands
select distinct a.atc_code, a.atc_name, c3.concept_name as target_concept_name
from dev_vkorsik.atc_july a
join  devv5.concept_relationship cr
on a.concept_id=cr.concept_id_1
join devv5.concept c
on c.concept_id=cr.concept_id_2
join devv5.concept_relationship cr2
on cr.concept_id_2=cr2.concept_id_1
join devv5.concept c2
on c2.concept_id=cr2.concept_id_1
join devv5.concept_relationship cr3
on cr3.concept_id_1=c2.concept_id
join devv5.concept c3
on cr3.concept_id_2=c3.concept_id
where a.concept_class_id ~*'clinic'
and cr.relationship_id~*'has trade'
  and cr2.relationship_id='Has brand name'
  and cr3.relationship_id='Has brand name'
and cr.invalid_reason is null
;

--list of brand names for ingredients
INSERT INTO ATC_brands
select distinct a.atc_code, a.atc_name, c.concept_name as target_concept_name
from dev_vkorsik.atc_july a
join devv5.concept_relationship cr
on a.concept_id=cr.concept_id_1
join devv5.concept c
on c.concept_id=cr.concept_id_2
where a.concept_class_id !~*'branded'
and a.concept_class_id !~*'clinic'
    and cr.relationship_id='Has brand name'
 and not exists (select 1
  from  devv5.concept_relationship cr2
      join devv5.concept c2
      on cr2.concept_id_2=c2.concept_id
  where c2.concept_id=c.concept_id
  group by cr2.concept_id_2
      having count(distinct c2.concept_id)>1
      )
and cr.invalid_reason is null
;

--list of brand names for Branded Drug Forms
select distinct a.atc_code, a.atc_name, c.concept_name as target_concept_name
from dev_vkorsik.atc_july a
join devv5.concept_relationship cr
on a.concept_id=cr.concept_id_1
join devv5.concept c on c.concept_id=cr.concept_id_2
where a.concept_class_id ~*'branded'
and cr.relationship_id='Has brand name'
;


--create atc_july
create table atc_july
(atc_code varchar,	atc_name varchar,	comment	varchar,
concept_id integer,	concept_code varchar,
concept_name varchar,	concept_class_id	varchar,
standard_concept varchar,	invalid_reason varchar,	domain_id	varchar,
vocabulary_id	varchar, ingr_no varchar)
;
--drop table
drop table ATC_july
;

--all possible relationship types
SELECT cr.*
FROM devv5.concept_relationship cr
JOIN devv5.concept c
    ON c.concept_id = cr.concept_id_1 AND c.concept_class_id = 'Ingredient' AND c.standard_concept = 'S'
JOIN devv5.concept cc
    ON cc.concept_id = cr.concept_id_2 AND cc.concept_class_id = 'Clinical Drug Form' AND cc.standard_concept = 'S';
--WHERE cr.relationship_id = ''
;
--all existing relationships for concept
SELECT DISTINCT cr.relationship_id, c.*
FROM devv5.concept_relationship cr
JOIN devv5.concept c
    ON cr.concept_id_2 = c.concept_id
    AND cr.concept_id_1 = 21061379 --concept_id
WHERE c.domain_id = 'Drug'
;
--ATC_brande table creation
create  table ATC_brands as (select distinct a.atc_code, a.atc_name, c.concept_name as target_concept_name
from dev_vkorsik.atc_july a
join devv5.concept_relationship cr
on a.concept_id=cr.concept_id_1
join devv5.concept c on c.concept_id=cr.concept_id_2
where a.concept_class_id ~*'branded'
and cr.relationship_id='Has brand name')
;
--drop table
drop table ATC_brands
;

--status of table
select distinct *
    from ATC_brands
;


