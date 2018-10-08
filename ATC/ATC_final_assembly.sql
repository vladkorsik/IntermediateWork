drop table final_assembly;
create table final_assembly
as
select  distinct s.*, c.concept_id, c.concept_name, c.concept_class_id, '1' as order
from atc_to_drug_1 a
join atc_drugs_scraper s on substring (concept_code_1,'\w+')=atc_code
join devv5.concept_ancestor on ancestor_concept_id = a.concept_id
join concept c on c.concept_id = descendant_concept_id and vocabulary_id like 'RxNorm%' and c.standard_concept = 'S'
 ;
delete from final_assembly
where atc_code ~ 'G03FB|G03AB' and concept_class_id not like '%Pack%';

insert into final_assembly
select  distinct s.*, c.concept_id, c.concept_name, c.concept_class_id, '2' as order
from atc_to_drug_2 a
join atc_drugs_scraper s on substring (concept_code_1,'\w+')=atc_code
join devv5.concept_ancestor on ancestor_concept_id = a.concept_id
join concept c on c.concept_id = descendant_concept_id  and c.vocabulary_id like 'RxNorm%' and c.standard_concept = 'S'
where descendant_concept_id not in (select concept_id from final_assembly)
;

insert into final_assembly
select  distinct s.*, c.concept_id, c.concept_name, c.concept_class_id, '3' as order
from atc_to_drug_3 a
join atc_drugs_scraper s on substring (concept_code_1,'\w+')=atc_code
join devv5.concept_ancestor on ancestor_concept_id = a.concept_id
join concept c on c.concept_id = descendant_concept_id  and c.vocabulary_id like 'RxNorm%' and c.standard_concept = 'S'
where descendant_concept_id not in (select concept_id from final_assembly)
;
insert into final_assembly
select  distinct s.*, c.concept_id, c.concept_name, c.concept_class_id, '4' as order
from atc_to_drug_4 a
join atc_drugs_scraper s on substring (concept_code_1,'\w+')=atc_code
join devv5.concept_ancestor on ancestor_concept_id = a.concept_id
join concept c on c.concept_id = descendant_concept_id  and c.vocabulary_id like 'RxNorm%' and c.standard_concept = 'S'
where descendant_concept_id not in (select concept_id from final_assembly)
;

insert into final_assembly
select  distinct s.*, c.concept_id, c.concept_name, c.concept_class_id, '5' as order
from atc_to_drug_5 a
join atc_drugs_scraper s on substring (concept_code_1,'\w+')=atc_code
join devv5.concept_ancestor on ancestor_concept_id = a.concept_id
join concept c on c.concept_id = descendant_concept_id  and c.vocabulary_id like 'RxNorm%' and c.standard_concept = 'S'
where descendant_concept_id not in (select concept_id from final_assembly)
;

insert into final_assembly
select  distinct s.*, c.concept_id, c.concept_name, c.concept_class_id, '6' as order
from atc_to_drug_6 a
join atc_drugs_scraper s on substring (concept_code_1,'\w+')=atc_code
join devv5.concept_ancestor on ancestor_concept_id = a.concept_id
join concept c on c.concept_id = descendant_concept_id  and c.vocabulary_id like 'RxNorm%' and c.standard_concept = 'S'
where descendant_concept_id not in (select concept_id from final_assembly)
;

delete from final_assembly where concept_name like '%insulin%';
insert into final_assembly
select distinct s.*, c.concept_id, c.concept_name, c.concept_class_id, '7' as order
from atc_to_drug_manual m
join atc_drugs_scraper s using (atc_code)
join devv5.concept_ancestor ca on ca.ancestor_concept_id = m.concept_id
join concept c on c.concept_id = ca.descendant_concept_id;

delete from  final_assembly
where atc_name like '%and estrogen%' -- if there are regular estiol/estradiol/EE
and concept_id in (select concept_id from final_assembly group by concept_id having count(1)>1);

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
and a.concept_id not in
(select concept_id from final_assembly_woCA)
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

insert into final_assembly_woCA
select  distinct atc_code,  a.atc_name, a.concept_id, a.concept_name, a.concept_class_id, '5' as order
from atc_to_drug_5 a
join atc_drugs_scraper s on substring (concept_code_1,'\w+')=atc_code
where atc_code not in 
(select atc_code from final_assembly_woCA);

insert into final_assembly_woCA
select  distinct atc_code,  a.atc_name, a.concept_id, a.concept_name, a.concept_class_id, '6' as order
from atc_to_drug_6 a
join atc_drugs_scraper s on substring (concept_code_1,'\w+')=atc_code
where atc_code not in 
(select atc_code from final_assembly_woCA);

delete from final_assembly_woca where concept_name like '%insulin%';
insert into final_assembly_woca
select distinct atc_code,m.atc_name, m.concept_id, m.concept_name, m.concept_class_id, '7' as order
from atc_to_drug_manual m
join atc_drugs_scraper s using (atc_code)
;

insert into final_assembly_woca
select f.atc_code, f.atc_name, c.concept_id, c.concept_name, c.concept_class_id, f.order
from final_assembly_woca f
join devv5.concept_ancestor ca
on ca.ancestor_concept_id = f.concept_id
join devv5.concept c on c.concept_id = descendant_concept_id and c.concept_class_id like '%Pack%'
where atc_code like 'G03FB%'; -- packs
delete from final_assembly_woca
where atc_code like 'G03FB%' and concept_class_id in ('Clinical Drug Form','Ingredient');


delete from  final_assembly_woca
where atc_name like '%and estrogen%' -- if there are regular estiol/estradiol/EE
and concept_id in (select concept_id from final_assembly_woca group by concept_id having count(1)>1);
