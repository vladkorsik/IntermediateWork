drop table final_assembly;
create table final_assembly 
as
select  distinct s.*, c.concept_id, c.concept_name, c.concept_class_id, '2' as order
from atc_to_drug_2 a
join atc_drugs_scraper s on substring (concept_code_1,'\w+')=atc_code
join devv5.concept_ancestor on ancestor_concept_id = a.concept_id
join concept c on c.concept_id = descendant_concept_id and c.vocabulary_id = 'RxNorm' and c.concept_class_id not like '%Group%'-- temporary exclude RxE
;
insert into final_assembly
select  distinct s.*, c.concept_id, c.concept_name, c.concept_class_id, '3' as order
from atc_to_drug_3 a
join atc_drugs_scraper s on substring (concept_code_1,'\w+')=atc_code
join devv5.concept_ancestor on ancestor_concept_id = a.concept_id
join concept c on c.concept_id = descendant_concept_id  and c.vocabulary_id = 'RxNorm' and c.concept_class_id not like '%Group%' -- temporary exclude RxE
where descendant_concept_id not in (select concept_id from final_assembly)
;
insert into final_assembly
select  distinct s.*, c.concept_id, c.concept_name, c.concept_class_id, '4' as order
from atc_to_drug_4 a
join atc_drugs_scraper s on substring (concept_code_1,'\w+')=atc_code
join devv5.concept_ancestor on ancestor_concept_id = a.concept_id
join concept c on c.concept_id = descendant_concept_id  and c.vocabulary_id = 'RxNorm'  and c.concept_class_id not like '%Group%'-- temporary exclude RxE
where descendant_concept_id not in (select concept_id from final_assembly)
;

--table wo ancestor
drop table final_assembly_woCA;
create table final_assembly_woCA 
as
select  distinct atc_code, a.atc_name, a.concept_id, a.concept_name, a.concept_class_id, '1' as order
from atc_to_drug_1 a
join atc_drugs_scraper s on substring (concept_code_1,'\w+')=atc_code
;
insert into final_assembly_woCA
select  distinct atc_code, a.atc_name, a.concept_id, a.concept_name, a.concept_class_id, '2' as order
from atc_to_drug_2 a
join atc_drugs_scraper s on substring (concept_code_1,'\w+')=atc_code
where atc_code not in 
(select atc_code from final_assembly_woCA)
;
insert into final_assembly_woCA
select  distinct atc_code, a.atc_name, a.concept_id, a.concept_name, a.concept_class_id, '3' as order
from atc_to_drug_3 a
join atc_drugs_scraper s on substring (concept_code_1,'\w+')=atc_code
where atc_code not in 
(select atc_code from final_assembly_woCA)
;
insert into final_assembly_woCA
select  distinct atc_code,  a.atc_name, a.concept_id, a.concept_name, a.concept_class_id, '4' as order
from atc_to_drug_4 a
join atc_drugs_scraper s on substring (concept_code_1,'\w+')=atc_code
where atc_code not in 
(select atc_code from final_assembly_woCA);
