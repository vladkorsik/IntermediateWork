--drop table
--drop table ATC_july;

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
                            from dev_vkorsik.atc_july a
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

from dev_vkorsik.atc_july a

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

from dev_vkorsik.atc_july a

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

  and not exists (select 1
                 from devv5.concept_relationship cr4
                          join devv5.concept c4
                               on cr4.concept_id_2 = c4.concept_id AND cr4.invalid_reason IS NULL AND c4.concept_class_id = 'Ingredient' AND c4.standard_concept = 'S' AND cr4.relationship_id = 'RxNorm has ing'
                 where c0.concept_id = cr4.concept_id_1
                 group by cr4.concept_id_1
                 having count(distinct cr4.concept_id_2) > 1
    )
;




--TODO: form the list what brand-names are affected by
--TODO просмотреть списокна предмет других символов
--TODO объеденияемы брэнл-неймы оценить
--status of table
select distinct trim (lower(regexp_replace(target_concept_name, '\.|\-|\\|\/|\*|\,| ', '', 'g')))
    from ATC_brands;



--TODO их нужно расставить по каунтам (сколько данный брэнд-нэйм имеет вадидных ссылок (через валиндные ссылки br dr form) на клин драг форм стандартные)
SELECT DISTINCT target_concept_name, atc_code, atc_name, 0 as count
FROM ATC_brands
ORDER BY count DESC, target_concept_name;