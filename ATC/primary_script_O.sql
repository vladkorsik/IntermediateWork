--delete empty rows from the website
delete from atc_drugs_scraper
where atc_code = '';

--fix the data shift from the website
update atc_drugs_scraper
set ddd = 60, u = 'mg',adm_r = 'O'
where atc_code = 'B01AF03';

--create temp. tables for concept dose forms

--create temp. table inhalant
create table dev_inhal as (
select * from concept
where concept_class_id = 'Dose Form'
and concept_name like '%Inhal%'
and concept_name not like '%Nasal%'
and vocabulary_id like '%RxNorm%'
and invalid_reason is null);

insert into dev_inhal
select * from concept
where concept_class_id = 'Dose Form'
and concept_name = 'Oral Spray'
and vocabulary_id like '%RxNorm%'
and invalid_reason is null;

--create temp. table parenteral
create table dev_parenteral as (
select * from 
(select * from concept 
where concept_name like '%Inje%' 
or concept_name like '%Intr%'
) as concept_name 
where concept_class_id = 'Dose Form' 
and vocabulary_id like '%RxNorm%'
and concept_name not like '%tracheal%'
and concept_name not like '%uterine%'
and invalid_reason is null);

--create temp. table sublingual and buccal
create table dev_sub as 
(select * from 
(select * from concept 
where concept_name like '%Sub%' 
or concept_name like '%ucca%'
) as concept_name 
where concept_class_id = 'Dose Form' 
and concept_name not like '%tracheal%'
and concept_name not like '%uterine%'
and vocabulary_id like '%RxNorm%'
and invalid_reason is null);

--create temp. table nasal
create table dev_nasal as 
(select * from concept 
where concept_name like '%Nasal%' 
and concept_class_id = 'Dose Form' 
and vocabulary_id like '%RxNorm%'
and invalid_reason is null);

--create temp. table oral
create table dev_oral as (
select * from concept 
where concept_name like '%Oral%' 
and concept_class_id = 'Dose Form' 
and vocabulary_id like '%RxNorm%'
and invalid_reason is null);

--create temp. table topical
create table dev_topic as
(select * from concept
where lower(concept_name) ~ 'topic'
and concept_class_id = 'Dose Form' 
and vocabulary_id like '%RxNorm%'
and invalid_reason is null);

insert into dev_topic
select * from concept
where lower(concept_name) ~ 'medicated'
and concept_class_id = 'Dose Form' 
and vocabulary_id like '%RxNorm%'
and invalid_reason is null;

insert into dev_topic
select * from concept
where lower(concept_name) in ('transdermal system', 'drug implant', 'prefilled applicator', 'powder spray', 'paste')
and concept_class_id = 'Dose Form' 
and vocabulary_id like '%RxNorm%'
and invalid_reason is null;

--create temp. table rectal
create table dev_rectal as(
select * from concept
where lower(concept_name) ~ 'rectal'
and concept_class_id = 'Dose Form' 
and vocabulary_id like '%RxNorm%'
and invalid_reason is null);

--create temp. table vaginal
create table dev_vaginal as
(select * from concept
where lower(concept_name) ~ 'vaginal'
and concept_class_id = 'Dose Form' 
and vocabulary_id like '%RxNorm%'
and invalid_reason is null);

--create temp. table urethral
create table dev_urethral as
(select * from concept
where lower(concept_name) ~ 'urethral'
and concept_class_id = 'Dose Form' 
and vocabulary_id like '%RxNorm%'
and invalid_reason is null);

--add dose forms to internal_relationship_stage

--oral
insert into internal_relationship_stage (concept_code_1, concept_code_2)
select distinct atc_code||' '||concept_name, concept_name from atc_drugs_scraper, dev_oral
where adm_r = 'O';

--sublingual
insert into internal_relationship_stage (concept_code_1, concept_code_2)
select distinct atc_code||' '||concept_name, concept_name from atc_drugs_scraper, dev_sub
where adm_r = 'SL';

--topical
insert into internal_relationship_stage (concept_code_1, concept_code_2)
select distinct atc_code||' '||concept_name, concept_name from atc_drugs_scraper, dev_topic
where adm_r = 'TD';
insert into internal_relationship_stage (concept_code_1, concept_code_2)
select distinct atc_code||' '||concept_name, concept_name from atc_drugs_scraper, dev_topic
where adm_r = 'implant';

--nasal
insert into internal_relationship_stage (concept_code_1, concept_code_2)
select distinct atc_code||' '||concept_name, concept_name from atc_drugs_scraper, dev_nasal
where adm_r = 'N';

--rectal
insert into internal_relationship_stage (concept_code_1, concept_code_2)
select distinct atc_code||' '||concept_name, concept_name from atc_drugs_scraper, dev_rectal
where adm_r = 'R';

--vaginal
insert into internal_relationship_stage (concept_code_1, concept_code_2)
select distinct atc_code||' '||concept_name, concept_name from atc_drugs_scraper, dev_vaginal
where adm_r = 'V';

--urethral
insert into internal_relationship_stage (concept_code_1, concept_code_2)
select distinct atc_code||' '||concept_name, concept_name from atc_drugs_scraper, dev_urethral
where adm_r = 'U';
insert into internal_relationship_stage (concept_code_1, concept_code_2)
select distinct atc_code||' '||concept_name, concept_name from atc_drugs_scraper, dev_urethral
where adm_r = 'intravesical';

--inhalant
insert into internal_relationship_stage (concept_code_1, concept_code_2)
select distinct atc_code||' '||concept_name, concept_name from atc_drugs_scraper, dev_inhal
where lower(adm_r) ~ 'inh');

--parenteral
insert into internal_relationship_stage (concept_code_1, concept_code_2)
select distinct atc_code||' '||concept_name, concept_name from atc_drugs_scraper, dev_parenteral
where adm_r = 'P';
insert into internal_relationship_stage (concept_code_1, concept_code_2)
select distinct atc_code||' '||concept_name, concept_name from atc_drugs_scraper, dev_parenteral
where adm_r = 'Instill.sol.';

--add ingredients to internal_relationship_stage

--ingredients for oral
insert into internal_relationship_stage (concept_code_1, concept_code_2)
with primary_table as (
select atc_code||' '||concept_name as dose, atc_name from atc_drugs_scraper, dev_oral
where adm_r = 'O')
select distinct a.*, c.concept_name from primary_table a
join concept_synonym b
on lower(b.concept_synonym_name) = a.atc_name
join concept c
on c.concept_id = b.concept_id
and c.standard_concept = 'S'
and c.concept_class_id = 'Ingredient'
and c.invalid_reason is null;

--ingredients for sublingual
insert into internal_relationship_stage (concept_code_1, concept_code_2)
with primary_table as (
select atc_code||' '||concept_name as dose, atc_name from atc_drugs_scraper, dev_sub
where adm_r = 'SL')
select distinct a.*, c.concept_name from primary_table a
join concept_synonym b
on lower(b.concept_synonym_name) = a.atc_name
join concept c
on c.concept_id = b.concept_id
and c.standard_concept = 'S'
and c.concept_class_id = 'Ingredient'
and c.invalid_reason is null;

--ingredients for topical
insert into internal_relationship_stage (concept_code_1, concept_code_2)
with primary_table as (
select atc_code||' '||concept_name as dose, atc_name from atc_drugs_scraper, dev_topic
where adm_r = 'TD')
select distinct a.*, c.concept_name from primary_table a
join concept_synonym b
on lower(b.concept_synonym_name) = a.atc_name
join concept c
on c.concept_id = b.concept_id
and c.standard_concept = 'S'
and c.concept_class_id = 'Ingredient'
and c.invalid_reason is null;

insert into internal_relationship_stage (concept_code_1, concept_code_2)
with primary_table as (
select atc_code||' '||concept_name as dose, atc_name from atc_drugs_scraper, dev_topic
where adm_r = 'implant')
select distinct a.*, c.concept_name from primary_table a
join concept_synonym b
on lower(b.concept_synonym_name) = a.atc_name
join concept c
on c.concept_id = b.concept_id
and c.standard_concept = 'S'
and c.concept_class_id = 'Ingredient'
and c.invalid_reason is null;

--ingredients for nasal
insert into internal_relationship_stage (concept_code_1, concept_code_2)
with primary_table as (
select atc_code||' '||concept_name as dose, atc_name from atc_drugs_scraper a, dev_nasal
where a.adm_r = 'N')
select distinct a.*, c.concept_name from primary_table a
join concept_synonym b
on lower(b.concept_synonym_name) = a.atc_name
join concept c
on c.concept_id = b.concept_id
and c.standard_concept = 'S'
and c.concept_class_id = 'Ingredient'
and c.invalid_reason is null;

--ingredients for parenteral
insert into internal_relationship_stage (concept_code_1, concept_code_2)
with primary_table as (
select atc_code||' '||concept_name as dose, atc_name from atc_drugs_scraper a, dev_parenteral
where a.adm_r = 'P')
select distinct a.*, c.concept_name from primary_table a
join concept_synonym b
on lower(b.concept_synonym_name) = a.atc_name
join concept c
on c.concept_id = b.concept_id
and c.standard_concept = 'S'
and c.concept_class_id = 'Ingredient'
and c.invalid_reason is null;

--ingredients for rectal
insert into internal_relationship_stage (concept_code_1, concept_code_2)
with primary_table as (
select atc_code||' '||concept_name as dose, atc_name from atc_drugs_scraper a, dev_rectal
where a.adm_r = 'R')
select distinct a.*, c.concept_name from primary_table a
join concept_synonym b
on lower(b.concept_synonym_name) = a.atc_name
join concept c
on c.concept_id = b.concept_id
and c.standard_concept = 'S'
and c.concept_class_id = 'Ingredient'
and c.invalid_reason is null;

--ingredients for urethral
insert into internal_relationship_stage (concept_code_1, concept_code_2)
with primary_table as (
select atc_code||' '||concept_name as dose, atc_name from atc_drugs_scraper a, dev_urethral
where a.adm_r = 'U')
select distinct a.*, c.concept_name from primary_table a
join concept_synonym b
on lower(b.concept_synonym_name) = a.atc_name
join concept c
on c.concept_id = b.concept_id
and c.standard_concept = 'S'
and c.concept_class_id = 'Ingredient'
and c.invalid_reason is null;

insert into internal_relationship_stage (concept_code_1, concept_code_2)
with primary_table as (
select atc_code||' '||concept_name as dose, atc_name from atc_drugs_scraper a, dev_urethral
where a.adm_r = 'intravesical')
select distinct a.*, c.concept_name from primary_table a
join concept_synonym b
on lower(b.concept_synonym_name) = a.atc_name
join concept c
on c.concept_id = b.concept_id
and c.standard_concept = 'S'
and c.concept_class_id = 'Ingredient'
and c.invalid_reason is null;

--ingredients for vaginal
insert into internal_relationship_stage (concept_code_1, concept_code_2)
with primary_table as (
select atc_code||' '||concept_name as dose, atc_name from atc_drugs_scraper a, dev_vaginal
where a.adm_r = 'V')
select distinct a.*, c.concept_name from primary_table a
join concept_synonym b
on lower(b.concept_synonym_name) = a.atc_name
join concept c
on c.concept_id = b.concept_id
and c.standard_concept = 'S'
and c.concept_class_id = 'Ingredient'
and c.invalid_reason is null;

--ingredients for inhalant
insert into internal_relationship_stage (concept_code_1, concept_code_2)
with primary_table as (
select atc_code||' '||concept_name as dose, atc_name from atc_drugs_scraper a, dev_inhal
where lower(a.adm_r) ~ 'inh')
select distinct a.*, c.concept_name from primary_table a
join concept_synonym b
on lower(b.concept_synonym_name) = a.atc_name
join concept c
on c.concept_id = b.concept_id
and c.standard_concept = 'S'
and c.concept_class_id = 'Ingredient'
and c.invalid_reason is null;

--ingredients without dose form
insert into internal_relationship_stage (concept_code_1, concept_code_2)
select distinct a.atc_code, c.concept_name from atc_drugs_scraper a
join concept_synonym b
on lower(b.concept_synonym_name) = a.atc_name
join concept c
on c.concept_id = b.concept_id
and adm_r is null
and length(atc_code) = 7
and c.standard_concept = 'S'
and c.concept_class_id = 'Ingredient'
and c.invalid_reason is null;

--insert concept_code_2 into relationship_to_concept
insert into relationship_to_concept(concept_code_1, vocabulary_id_1, concept_id_2)
select distinct concept_code_2, 'ATC', concept_id from internal_relationship_stage
join concept
on concept_code_2 = concept_name
and vocabulary_id ~ 'RxNorm'
and invalid_reason is null

--insert data into drug_concept_stage
insert into drug_concept_stage (concept_name, vocabulary_id, concept_class_id, standard_concept, concept_code, possible_excipient, domain_id)
select concept_code_1, 'ATC', 'Drug Product', 'S', concept_code_1, null, 'Drug'from internal_relationship_stage

insert into drug_concept_stage (concept_name, vocabulary_id, concept_class_id, standard_concept, concept_code, possible_excipient, domain_id)
select distinct concept_code_2, 'ATC', 'Dose form', 'S', concept_code_2, null, 'Drug'from internal_relationship_stage, concept
where concept_code_2 = concept_name
and concept_class_id = 'Dose Form'
and vocabulary_id ~ 'RxNorm'
and invalid_reason is null

insert into drug_concept_stage (concept_name, vocabulary_id, concept_class_id, standard_concept, concept_code, possible_excipient, domain_id)
select distinct concept_code_2, 'ATC', 'Ingredient', 'S', concept_code_2, null, 'Drug'from internal_relationship_stage, concept
where concept_code_2 = concept_name
and concept_class_id = 'Ingredient'
and vocabulary_id ~ 'RxNorm'
and standard_concept = 'S'
and invalid_reason is null

update drug_concept_stage
set valid_start_date = '1970-01-01'

update drug_concept_stage
set valid_end_date = '2099-12-31'

--insert into internal_relationship_stage combinations that contain 'and' without dose form
insert into internal_relationship_stage (concept_code_1, concept_code_2)
with primary_table as (select * from atc_drugs_scraper
where length(atc_code) = 7
and atc_name like '%and %')
select atc_code, atc_code||'-'||split_part(atc_name, ' and ', 1) from primary_table
where atc_name not like '%,%'
and atc_name not like '%combination%'
and adm_r is null

insert into internal_relationship_stage (concept_code_1, concept_code_2)
with primary_table as (select * from atc_drugs_scraper
where length(atc_code) = 7
and atc_name like '%and %')
select atc_code, atc_code||'-'||split_part(atc_name, 'and ', 2) from primary_table
where atc_name not like '%,%'
and atc_name not like '%combination%'
and adm_r is null

--insert into internal_relationship_stage combinations that contain 'and' oral
insert into internal_relationship_stage (concept_code_1, concept_code_2)
with primary_table as (select * from atc_drugs_scraper
where length(atc_code) = 7
and atc_name like '%and %')
select atc_code||' '||concept_name, atc_code||'-'||split_part(atc_name, ' and ', 1) from primary_table, dev_oral
where atc_name not like '%,%'
and atc_name not like '%combination%'
and adm_r = 'O'

insert into internal_relationship_stage (concept_code_1, concept_code_2)
with primary_table as (select * from atc_drugs_scraper
where length(atc_code) = 7
and atc_name like '%and %')
select atc_code||' '||concept_name, atc_code||'-'||split_part(atc_name, 'and ', 2) from primary_table, dev_oral
where atc_name not like '%,%'
and atc_name not like '%combination%'
and adm_r = 'O'

--insert into internal_relationship_stage combinations that contain 'and' parenteral
insert into internal_relationship_stage (concept_code_1, concept_code_2)
with primary_table as (select * from atc_drugs_scraper
where length(atc_code) = 7
and atc_name like '%and %')
select atc_code||' '||concept_name, atc_code||'-'||split_part(atc_name, ' and ', 1) from primary_table, dev_parenteral
where atc_name not like '%,%'
and atc_name not like '%combination%'
and adm_r = 'P'

with primary_table as (select * from atc_drugs_scraper
where length(atc_code) = 7
and atc_name like '%and %')
select atc_code||' '||concept_name, atc_code||'-'||split_part(atc_name, 'and ', 2) from primary_table, dev_parenteral
where atc_name not like '%,%'
and atc_name not like '%combination%'
and adm_r = 'P'
