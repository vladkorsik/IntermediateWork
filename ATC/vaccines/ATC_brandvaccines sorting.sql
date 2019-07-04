--check
SELECT *
FROM dev_vkorsik.atc_google_source a1
WHERE NOT EXISTS (  SELECT *
                    FROM dev_vkorsik.atc_google_source a2
                    JOIN devv5.concept c
                        ON a2.concept_id = c.concept_id
                            AND c.concept_name = a2.concept_name
                            AND c.vocabulary_id = a2.vocabulary_id
                            AND c.domain_id = a2.domain_id
                            AND c.standard_concept='S'
                            AND c.invalid_reason is NULL
                    WHERE a1.atc_code = a2.atc_code
 )
;

--drop table
--drop table atc_google_source;

--rename atc_july to atc_google_source
ALTER TABLE atc_july
    RENAME TO atc_google_source;

--create atc_july
create table atc_july
(
    atc_code         varchar,
    atc_name         varchar,
    comment          varchar,
    concept_id       integer,
    concept_code     varchar,
    concept_name     varchar,
    concept_class_id varchar,
    standard_concept varchar,
    invalid_reason   varchar,
    domain_id        varchar,
    vocabulary_id    varchar,
    ingr_no          varchar
)
;


--drop table
--drop table ATC_brands;


--ATC_brande table creation
create table ATC_brands as (select distinct a.atc_code,
                                            a.atc_name,
                                            c.concept_name as target_concept_name
                            from dev_vkorsik.atc_google_source a
                                     join devv5.concept_relationship cr
                                          on a.concept_id = cr.concept_id_1
                                     join devv5.concept c
                                         on c.concept_id = cr.concept_id_2
                            where a.concept_class_id = 'Branded Drug Form'
                              and cr.relationship_id = 'Has brand name' AND cr.invalid_reason IS NULL)
;


-- list of brand names for clinical drug forms
INSERT INTO ATC_brands
select distinct a.atc_code,
                a.atc_name,
                c2.concept_name as target_concept_name

from dev_vkorsik.atc_google_source a

         join devv5.concept_relationship cr
              on a.concept_id = cr.concept_id_1 AND cr.relationship_id = 'Has tradename' AND cr.invalid_reason IS NULL
         join devv5.concept c
              on c.concept_id = cr.concept_id_2 AND c.concept_class_id = 'Branded Drug Form' AND c.standard_concept = 'S'

         join devv5.concept_relationship cr2
              on c.concept_id = cr2.concept_id_1 AND cr2.relationship_id = 'Has brand name' AND cr2.invalid_reason IS NULL
         join devv5.concept c2
              on c2.concept_id = cr2.concept_id_2 AND c2.concept_class_id = 'Brand Name'

where a.concept_class_id = 'Clinical Drug Form'
;




--list of brand names for ingredients
INSERT INTO ATC_brands
select distinct a.atc_code,
                a.atc_name,
                c2.concept_name as target_concept_name

from dev_vkorsik.atc_google_source a

         join devv5.concept_relationship cr0
              on a.concept_id = cr0.concept_id_1 AND cr0.relationship_id = 'RxNorm ing of' AND cr0.invalid_reason IS NULL
         join devv5.concept c0
              on c0.concept_id = cr0.concept_id_2 AND c0.concept_class_id = 'Clinical Drug Form' AND c0.standard_concept = 'S'


         join devv5.concept_relationship cr
              on c0.concept_id = cr.concept_id_1 AND cr.relationship_id = 'Has tradename' AND cr.invalid_reason IS NULL
         join devv5.concept c
              on c.concept_id = cr.concept_id_2 AND c.concept_class_id = 'Branded Drug Form' AND c.standard_concept = 'S'

         join devv5.concept_relationship cr2
              on c.concept_id = cr2.concept_id_1 AND cr2.relationship_id = 'Has brand name' AND cr2.invalid_reason IS NULL
         join devv5.concept c2
              on c2.concept_id = cr2.concept_id_2 AND c2.concept_class_id = 'Brand Name'


where a.concept_class_id = 'Ingredient'

/*  and not exists (select 1
                 from devv5.concept_relationship cr4
                          join devv5.concept c4
                               on cr4.concept_id_2 = c4.concept_id AND cr4.invalid_reason IS NULL AND c4.concept_class_id = 'Ingredient' AND c4.standard_concept = 'S' AND cr4.relationship_id = 'RxNorm has ing'
                 where c0.concept_id = cr4.concept_id_1
                 group by cr4.concept_id_1
                 having count(distinct cr4.concept_id_2) > 1
    )*/
;




--form the list what brand-names are affected by
--find symbols  demarcating parts of Brand-name list in ARC_brands - NOTHING new
--analyze "fused" brand-names

--status of table
select distinct * from ATC_brands

--Corrected name field
select distinct ab.*
    from ATC_brands ab
join ATC_brands ab2
    on trim (lower(regexp_replace(ab.target_concept_name, '\.|\-|\\|\/|\*|\,| ', '', 'g')))= trim (lower(regexp_replace(ab2.target_concept_name, '\.|\-|\\|\/|\*|\,| ', '', 'g')))
where ab.target_concept_name!=ab2.target_concept_name;




-- Count distinct Cl dr forms linked to Brand-Name, with valid and standard relations and concepts
/*SELECT DISTINCT target_concept_name, atc_code, atc_name, 0 as count
FROM ATC_brands
ORDER BY count DESC, target_concept_name;*/

create table atc_brandlist_count as(
select trim (lower(regexp_replace(ab.target_concept_name, '\.|\-|\\|\/|\*|\,| ', '', 'g'))) as target_brand, ab.atc_name,ab.atc_code,
       count(distinct c3.concept_id) as count
from ATC_brands ab
         join devv5.concept c
              on c.concept_name = ab.target_concept_name and c.concept_class_id = 'Brand Name'
         join devv5.concept_relationship cr
              on c.concept_id = cr.concept_id_1
         join devv5.concept c2
              on cr.concept_id_2 = c2.concept_id and cr.relationship_id = 'Brand name of' and
                 c2.concept_class_id = 'Branded Drug Form' AND c2.standard_concept = 'S' and c2.invalid_reason is null
    and cr.invalid_reason is null
         join devv5.concept_relationship cr2
              on c2.concept_id = cr2.concept_id_1 and cr2.relationship_id = 'Tradename of' and
                 cr2.invalid_reason is null
         join devv5.concept c3
              on cr2.concept_id_2 = c3.concept_id and c3.concept_class_id = 'Clinical Drug Form' and
                 c3.standard_concept = 'S' and c3.invalid_reason is null
group by target_brand, ab.atc_name, ab.atc_code
order by count desc, target_brand desc);

select * from atc_brandlist_count;


