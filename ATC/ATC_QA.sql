
-- ADD FORMS for drugs based on ATC4/3 etc.
select distinct c2.* from reference
join concept c on atc_code = c.concept_code
join devv5.concept_ancestor ca on ca.descendant_concept_id = c.concept_id
join concept c2 on c2.concept_id = ancestor_concept_id
where atc_code = c.concept_code
and c2.concept_name ~ 'SYSTEMIC|ORAL|OPHTHAL|RECTAL|TOPICAL|NASAL'
and c2.concept_code not like 'J%';

-- check drugs whith precise routes
select distinct * from atc_drugs_scraper
  join reference using (atc_code)
where adm_r not in ('N','O','P','R','SL','TD','V');

select * from atc_drug_scraper a left join dev_atc.final_assembly_woca -- 1647
using (atc_code)
where sdrug is null and length(atc_code) = 7;

drop table temp_check;
create table temp_check as
select distinct atc_name, c.concept_name
from final_assembly f
  join devv5.concept_ancestor ca on ca.descendant_concept_id = f.concept_id
  join concept c on c.concept_id = ca.ancestor_concept_id and c.concept_class_id = 'Ingredient'
where not atc_name ~ 'combination|agents|drugs|supplements|corticosteroids|compounds|sulfonylureas|preparations|thiazides|antacid|antiinfectives|calcium$|potassium$|sodium$|antiseptics|antibiotics|mydriatics|psycholeptic|other|diuretic|nitrates|analgesics'
and c.concept_name not in ('Inert Ingredients') -- a component of contraceptive packs
;
select * from temp_check
where atc_name in (select atc_name from temp_check group by atc_name having count(1)>1);


drop table tempt;
create table tempt as
select * from drug_concept_stage where concept_code not in (select concept_code_1 from internal_relationship_stage)
and concept_class_id = 'Drug Product';

insert into internal_relationship_stage
select distinct concept_code, regexp_replace(concept_code,'\w+ ','') from tempt
join reference using (concept_code)
join atc_drugs_scraper using (atc_code)
where not atc_name ~ 'and|vaccine|antigen|-|comb|with|excl'
and regexp_replace(concept_code,'\w+ ','')!=concept_code
;

insert into internal_relationship_stage
select distinct concept_code, regexp_replace(concept_code,'\w+ ','')
from
  tempt where concept_code like 'J05AR08%';

insert into internal_relationship_stage
select distinct concept_code, 'rilpivirine'
from
  tempt where concept_code like 'J05AR08%';
