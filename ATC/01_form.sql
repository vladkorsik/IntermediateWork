/*************************************
Prerequisites: 
get atc_drug_scraper using atc-grabber
************************************/

-- watch for A01 - stomatological
-- additionally need to map
create table manual as
select * from atc_1_comb where atc_name like 'meningo%';
insert into manual
select * from atc_1 where atc_name like '%sodium chloride, hypertonic%';
insert into manual
select * from atc_1_comb where atc_name like '%hemophilus influenzae B%';
insert into manual
select * from atc_1_comb where atc_name like '%hepatitis B%';
insert into manual
select * from atc_1_comb where atc_name like '%beta-lactamase inhibitor%';
insert into manual
select * from atc_1_comb where atc_name like '%decarboxylase inhibitor%';
insert into manual
select * from atc_1_comb where atc_name like '%mould fungus%';
insert into manual
select * from atc_1_comb where atc_name like '%ordinary salt%';


--bckps
create table drug_concept_stage_1
as select * from drug_concept_stage;
create table internal_relationship_stage_1
as select * from internal_relationship_stage;
create table ds_stage_1
as select * from ds_stage;
create table relationship_to_concept_1
as select * from relationship_to_concept;
create table dev_ingredient_stage_1
as select * from dev_ingredient_stage;



-- updating source data: forms
UPDATE atc_1_comb
SET atc_name = 'progestogen and estrogen',
    adm_r = 'V'
WHERE atc_code = 'G02BB01';


 -- add buccal and others
drop table if exists forms ;
create table forms as
(
select concept_name as form, 'inh' as label
from concept
where concept_class_id = 'Dose Form' and concept_name like '%Inhal%' and concept_name not like '%Nasal%' and vocabulary_id like 'RxNorm%' and invalid_reason is null

union all

select concept_name, 'oph' as flag
from concept
where concept_class_id = 'Dose Form' and concept_name like '%Ophthal%' and vocabulary_id like '%RxNorm%' and invalid_reason is null

union all

select concept_name, 'p' as flag
from concept
where concept_class_id = 'Dose Form' and concept_name ~ 'Oral|Inject|Cartridge|Syringe|Intra|Implant' and vocabulary_id like 'RxNorm%' and invalid_reason is null

union all

select concept_name, 's' as flag
from concept
where concept_class_id = 'Dose Form' and concept_name ~ 'Oral|Inject|Cartridge|Syringe|Intra|Oral|Implant' and vocabulary_id like 'RxNorm%' and invalid_reason is null

union all

select concept_name, 'o' as flag
from concept
where concept_class_id = 'Dose Form' and concept_name like '%Oral|Chewab%' and vocabulary_id like 'RxNorm%' and invalid_reason is null

union all

select concept_name, 'dressing' as flag
from concept
where concept_class_id = 'Dose Form' and concept_name = 'Medicated Pad' and vocabulary_id like 'RxNorm%' and invalid_reason is null

union all

select concept_name, 'i' as flag
from concept
where concept_class_id = 'Dose Form' and concept_name = 'Irrigation Solution' and vocabulary_id like 'RxNorm%' and invalid_reason is null

union all

select concept_name, 't' as flag
from concept
where concept_class_id = 'Dose Form' and concept_name like '%Topical%' and vocabulary_id like 'RxNorm%' and invalid_reason is null

union all

select concept_name, 'ot' as flag
from concept
where concept_class_id = 'Dose Form' and concept_name like '%Otic%' and vocabulary_id like 'RxNorm%' and invalid_reason is null

union all

select concept_name, 'e' as flag
from concept
where concept_class_id = 'Dose Form' and concept_name in ('Enema','Rectal Suspension','Rectal Solution') and vocabulary_id like 'RxNorm%' and invalid_reason is null

union all

select concept_name, 'v' as flag
from concept
where concept_class_id = 'Dose Form' and concept_name like '%Vaginal%' and vocabulary_id like 'RxNorm%' and invalid_reason is null

union all
    
select concept_name, 'r' as flag
from concept
where concept_class_id = 'Dose Form' and concept_name ~ 'Rectal|Enema' and vocabulary_id like 'RxNorm%' and invalid_reason is null  
    
union all    

select concept_name, 'n' as flag
from concept
where concept_class_id = 'Dose Form' and concept_name like '%Nasal%' and vocabulary_id like 'RxNorm%' and invalid_reason is null
);

insert into forms 
select distinct c2.concept_name, 'th'
from concept c 
join concept_relationship cr on cr.concept_id_1 = c.concept_id and cr.invalid_reason is null and cr.relationship_id = 'ATC - RxNorm'
join concept_relationship cr2 on cr.concept_id_2 = cr2.concept_id_1 and cr2.invalid_reason is null and cr2.relationship_id = 'RxNorm has dose form'
join concept c2 on cr2.concept_id_2 = c2.concept_id and c2.vocabulary_id = 'RxNorm' 
where c.concept_code like 'R02%' and c.vocabulary_id = 'ATC'
and c2.concept_name not like 'Topical%' -- Exclude Topical route from throat preparation

union all

select distinct c2.concept_name, 'lo' --local oral
from concept c 
join concept_relationship cr on cr.concept_id_1 = c.concept_id and cr.invalid_reason is null and cr.relationship_id = 'ATC - RxNorm'
join concept_relationship cr2 on cr.concept_id_2 = cr2.concept_id_1  and cr2.relationship_id = 'RxNorm has dose form'
join concept c2 on cr2.concept_id_2 = c2.concept_id and c2.vocabulary_id = 'RxNorm' 
where c.concept_code like 'A01A%' and c.vocabulary_id = 'ATC'
;

-- re-do reference

-- creating reference table with atc_code and corresonding code+form
create table reference as
select atc_code,concept_code 
from drug_concept_stage 
join atc_drugs_scraper on substring (concept_name,'\w+') = atc_code
;


--missing forms
-- create intermediate tables with forms identified based on parent ATC codes
drop table systemic;
create table systemic as
select atc_code from reference where concept_code ~ 'R03C|A14|D10B|D01B|R06|D05B|H02|G03A|R03D|^H|^J'
and atc_code=concept_code
and atc_code not like 'S02%';

drop table rectal;
create table rectal as
select atc_code from reference where concept_code ~'C05A'
and atc_code = concept_code;

drop table nasal;
create table nasal as
select atc_code from reference where concept_code  ~ 'R01' and not concept_code  ~ '^R01B'
and atc_code=concept_code;

drop table irrig;
create table irrig as
select atc_code from reference where concept_code  ~ 'B05C'
and atc_code=concept_code;

drop table inhal;
create table inhal as
select atc_code from reference where concept_code  ~ 'R03B|R03AC05'--rimiterol
and atc_code=concept_code;

drop table dressing;
create table dressing as
select atc_code from reference where concept_code  ~ '^D09'
and atc_code=concept_code;

drop table oral;
create table oral as
select atc_code from reference where concept_code  ~ 'A07|R01B|V04CA02|A06AD'-- V04CA02 oral glucose tolerance test; A06AD - oral laxatives
and atc_code=concept_code
and atc_code not like 'S02%';

drop table parent;
create table parent as
select atc_code from reference where concept_code  ~ 'B05A|B05Z|B05X|B05D|B05B|R07AA02|L03AX10'--natural phospholipids, immunocyanin
and atc_code=concept_code;

drop table ophth;
create table ophth as
select atc_code from reference where concept_code  ~ 'S03|S01|S01X|S01XA20'
and atc_code=concept_code;

drop table otic;
create table otic as
select atc_code from reference where concept_code  like 'S02%'
and atc_code=concept_code;
 
drop table topical;
create table topical as
select atc_code from reference where concept_code  ~ 'M02|R01A|D05A|D06B|G02B|D01A|D10A|R01AA14|B02BC|N01B|C05BA|^D'
and atc_code=concept_code;

drop table throat;
create table throat as
select atc_code from reference where concept_code  like 'R02%'
and atc_code=concept_code;

drop table enema;
create table enema as
select atc_code from reference where concept_code  like 'A06AG%'
and atc_code=concept_code;

drop table vaginal;
create table vaginal as
select atc_code from reference where concept_code ~ 'G02CC|G01A'
and atc_code=concept_code;

drop table localoral;
create table localoral as
select atc_code from reference where concept_code  like 'A01A%'
and atc_code=concept_code;

--repeate for all
delete from reference where atc_code in (select atc_code from systemic);
insert into reference 
select distinct atc_code, atc_code||' '||form
from 
(select atc_code, 's' as label from systemic) s
join forms using (label);

insert into drug_concept_stage
select distinct atc_code||' '||form,'ATC','Drug Product',null,atc_code||' '||form, null,'Drug',current_date, to_date ('YYYYMMDD','20991231'), null, null
from 
(select atc_code, 's' as label from systemic) s
join forms using (label);

delete from drug_concept_stage where concept_code in
(select atc_code from systemic);

insert into internal_relationship_stage
select distinct new_code, concept_code_2 from internal_relationship_stage 
join  
( select atc_code||' '||form as new_code, form,atc_code from 
(select atc_code, 's' as label from systemic) s
join forms using (label)) s
on atc_code = concept_code_1;

insert into internal_relationship_stage
select distinct new_code, form from internal_relationship_stage 
join  
( select atc_code||' '||form as new_code, form,atc_code from 
(select atc_code, 's' as label from systemic) s
join forms using (label)) s
on atc_code = concept_code_1;

delete from internal_relationship_stage
where concept_code_1 in
( select atc_code from 
(select atc_code, 's' as label from systemic) s
join forms using (label)) ;

insert into reference
values ('G02BB01','G02BB01 Vaginal Ring');
