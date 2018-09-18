
insert into deprecated_rx_1
select c.concept_id, c.concept_name, c2.concept_id, c2.concept_name from devv5.concept c
  join devv5.concept c2
  on c.concept_name = regexp_replace (c2.concept_name,'Injection','Injectable Solution') --and c.cocnept_name!=c2
     and c.vocabulary_id = 'RxNorm' and c2.vocabulary_id = 'RxNorm'
     and c.invalid_reason = 'D' and c2.invalid_reason is null
     and c.concept_class_id = c2.concept_class_id
  left join devv5.concept_relationship cr on cr.concept_id_1 = c.concept_id and cr.invalid_reason is null and cr.relationship_id = 'Maps to'
where cr.concept_id_2 is null
and ( c.concept_id, c2.concept_id) not in
    (select old_id, new_id from dev_rxnorm.deprecated_rx_1)
;

create table rxnorm_to_insert as
select c.* from dev_rxnorm.deprecated_rx
left join dev_rxnorm.deprecated_rx_1 on drug_concept_id=old_id
join concept c on drug_concept_id = concept_id and vocabulary_id ='RxNorm'
where new_id is null;

delete from rxnorm_to_insert
where concept_id in 
(select old_id from deprecated_rx_1);

-- ingredients
create table irs as
select r.concept_code as cc1, c.concept_code as cc2
from rxnorm_to_insert r
join concept c on substring(r.concept_name,'\w+\s\w+') = c.concept_name and c.concept_class_id = 'Ingredient' and c.vocabulary_id = 'RxNorm' and c.standard_concept = 'S'
where r.concept_name not like '% / %';

insert into irs
select r.concept_code, c.concept_code
from rxnorm_to_insert r
join concept c on lower(substring(r.concept_name,'\w+')) = lower(c.concept_name) and c.concept_class_id = 'Ingredient' and c.vocabulary_id = 'RxNorm' and c.standard_concept = 'S'
where r.concept_name not like '% / %'
and r.concept_code not in
(select cc1 from irs);

create table tmpr as
select * from rxnorm_to_insert where concept_code not in (select cc1 from irs);

alter table tmpr
alter column standard_concept type varchar (255);

UPDATE tmpr   SET standard_concept = '3322' WHERE concept_id = 19131440 AND   concept_name = '1 ML Diazepam 0.005 MG/MG Prefilled Applicator [Diastat]' AND   domain_id = 'Drug' AND   vocabulary_id = 'RxNorm' AND   concept_class_id = 'Quant Branded Drug' AND   standard_concept IS NULL AND   concept_code = '801960' AND   valid_start_date = DATE '2008-07-27' AND   valid_end_date = DATE '2016-10-02' AND   invalid_reason = 'D';
UPDATE tmpr   SET standard_concept = '3966' WHERE concept_id = 40240352 AND   concept_name = '10 ML Ephedrine sulfate 5 MG/ML Prefilled Syringe' AND   domain_id = 'Drug' AND   vocabulary_id = 'RxNorm' AND   concept_class_id = 'Quant Clinical Drug' AND   standard_concept IS NULL AND   concept_code = '1115906' AND   valid_start_date = DATE '2011-07-31' AND   valid_end_date = DATE '2016-05-01' AND   invalid_reason = 'D';
UPDATE tmpr   SET standard_concept = '6847' WHERE concept_id = 42708203 AND   concept_name = '10 ML Methohexital Sodium 10 MG/ML Prefilled Syringe' AND   domain_id = 'Drug' AND   vocabulary_id = 'RxNorm' AND   concept_class_id = 'Quant Clinical Drug' AND   standard_concept IS NULL AND   concept_code = '1244230' AND   valid_start_date = DATE '2012-05-07' AND   valid_end_date = DATE '2016-05-01' AND   invalid_reason = 'D';
UPDATE tmpr   SET standard_concept = '8163' WHERE concept_id = 42708066 AND   concept_name = '10 ML Phenylephrine Hydrochloride 0.04 MG/ML Prefilled Syringe' AND   domain_id = 'Drug' AND   vocabulary_id = 'RxNorm' AND   concept_class_id = 'Quant Clinical Drug' AND   standard_concept IS NULL AND   concept_code = '1242900' AND   valid_start_date = DATE '2012-05-07' AND   valid_end_date = DATE '2015-10-04' AND   invalid_reason = 'D';
UPDATE tmpr   SET standard_concept = '10154' WHERE concept_id = 836227 AND   concept_name = '10 ML Succinylcholine Chloride 20 MG/ML Prefilled Syringe' AND   domain_id = 'Drug' AND   vocabulary_id = 'RxNorm' AND   concept_class_id = 'Quant Clinical Drug' AND   standard_concept IS NULL AND   concept_code = '797224' AND   valid_start_date = DATE '2008-06-29' AND   valid_end_date = DATE '2016-06-05' AND   invalid_reason = 'D';
UPDATE tmpr   SET standard_concept = '19831' WHERE concept_id = 40173444 AND   concept_name = '200 ACTUAT Budesonide 0.16 MG/ACTUAT Dry Powder Inhaler' AND   domain_id = 'Drug' AND   vocabulary_id = 'RxNorm' AND   concept_class_id = 'Quant Clinical Drug' AND   standard_concept IS NULL AND   concept_code = '966525' AND   valid_start_date = DATE '2010-04-04' AND   valid_end_date = DATE '2016-05-01' AND   invalid_reason = 'D';
UPDATE tmpr   SET standard_concept = '3322' WHERE concept_id = 19131444 AND   concept_name = '3 ML Diazepam 0.005 MG/MG Prefilled Applicator [Diastat]' AND   domain_id = 'Drug' AND   vocabulary_id = 'RxNorm' AND   concept_class_id = 'Quant Branded Drug' AND   standard_concept IS NULL AND   concept_code = '801964' AND   valid_start_date = DATE '2008-07-27' AND   valid_end_date = DATE '2016-10-02' AND   invalid_reason = 'D';
UPDATE tmpr   SET standard_concept = '4337' WHERE concept_id = 42707399 AND   concept_name = '55 ML Fentanyl 0.01 MG/ML Prefilled Syringe' AND   domain_id = 'Drug' AND   vocabulary_id = 'RxNorm' AND   concept_class_id = 'Quant Clinical Drug' AND   standard_concept IS NULL AND   concept_code = '1233803' AND   valid_start_date = DATE '2012-05-07' AND   valid_end_date = DATE '2016-05-01' AND   invalid_reason = 'D';
UPDATE tmpr   SET standard_concept = '1514' WHERE concept_id = 43560048 AND   concept_name = 'Betamethasone 0.284 MG/ML / Gentamicin Sulfate (USP) 0.57 MG/ML [Betagen br AND of Betamethasone  AND Gentamicin]' AND   domain_id = 'Drug' AND   vocabulary_id = 'RxNorm' AND   concept_class_id = 'Branded Drug Comp' AND   standard_concept IS NULL AND   concept_code = '1435264' AND   valid_start_date = DATE '2013-09-03' AND   valid_end_date = DATE '2017-08-06' AND   invalid_reason = 'D';
UPDATE tmpr   SET standard_concept = '4337' WHERE concept_id = 40225917 AND   concept_name = 'Bupivacaine Hydrochloride 0.625 MG/ML / Fentanyl 0.002 MG/ML Injectable Solution' AND   domain_id = 'Drug' AND   vocabulary_id = 'RxNorm' AND   concept_class_id = 'Clinical Drug' AND   standard_concept IS NULL AND   concept_code = '1012661' AND   valid_start_date = DATE '2010-10-03' AND   valid_end_date = DATE '2016-05-01' AND   invalid_reason = 'D';
UPDATE tmpr   SET standard_concept = '4337' WHERE concept_id = 40225920 AND   concept_name = 'Bupivacaine Hydrochloride 0.625 MG/ML / Fentanyl 0.005 MG/ML Injectable Solution' AND   domain_id = 'Drug' AND   vocabulary_id = 'RxNorm' AND   concept_class_id = 'Clinical Drug' AND   standard_concept IS NULL AND   concept_code = '1012665' AND   valid_start_date = DATE '2010-10-03' AND   valid_end_date = DATE '2016-05-01' AND   invalid_reason = 'D';
UPDATE tmpr   SET standard_concept = '4337' WHERE concept_id = 40225925 AND   concept_name = 'Bupivacaine Hydrochloride 1 MG/ML / Fentanyl 0.002 MG/ML Injectable Solution' AND   domain_id = 'Drug' AND   vocabulary_id = 'RxNorm' AND   concept_class_id = 'Clinical Drug' AND   standard_concept IS NULL AND   concept_code = '1012668' AND   valid_start_date = DATE '2010-10-03' AND   valid_end_date = DATE '2016-05-01' AND   invalid_reason = 'D';
UPDATE tmpr   SET standard_concept = '4337' WHERE concept_id = 40225928 AND   concept_name = 'Bupivacaine Hydrochloride 1 MG/ML / Fentanyl 0.005 MG/ML Injectable Solution' AND   domain_id = 'Drug' AND   vocabulary_id = 'RxNorm' AND   concept_class_id = 'Clinical Drug' AND   standard_concept IS NULL AND   concept_code = '1012672' AND   valid_start_date = DATE '2010-10-03' AND   valid_end_date = DATE '2016-05-01' AND   invalid_reason = 'D';
UPDATE tmpr   SET standard_concept = '4337' WHERE concept_id = 40225935 AND   concept_name = 'Bupivacaine Hydrochloride 1.25 MG/ML / Fentanyl 0.002 MG/ML Injectable Solution' AND   domain_id = 'Drug' AND   vocabulary_id = 'RxNorm' AND   concept_class_id = 'Clinical Drug' AND   standard_concept IS NULL AND   concept_code = '1012688' AND   valid_start_date = DATE '2010-10-03' AND   valid_end_date = DATE '2016-05-01' AND   invalid_reason = 'D';
UPDATE tmpr   SET standard_concept = '4337' WHERE concept_id = 40225939 AND   concept_name = 'Bupivacaine Hydrochloride 1.25 MG/ML / Fentanyl 0.005 MG/ML Injectable Solution' AND   domain_id = 'Drug' AND   vocabulary_id = 'RxNorm' AND   concept_class_id = 'Clinical Drug' AND   standard_concept IS NULL AND   concept_code = '1012697' AND   valid_start_date = DATE '2010-10-03' AND   valid_end_date = DATE '2016-05-01' AND   invalid_reason = 'D';
UPDATE tmpr   SET standard_concept = '4910' WHERE concept_id = 40174630 AND   concept_name = 'EGG YOLK PHOSPHOLIPIDS 12 MG/ML / Glycerin 25 MG/ML / Soybean Oil 100 MG/ML Injectable Suspension [Liposyn III]' AND   domain_id = 'Drug' AND   vocabulary_id = 'RxNorm' AND   concept_class_id = 'Branded Drug' AND   standard_concept IS NULL AND   concept_code = '902325' AND   valid_start_date = DATE '2010-04-04' AND   valid_end_date = DATE '2016-07-31' AND   invalid_reason = 'D';
UPDATE tmpr   SET vocabulary_id = 'RxNorm',       standard_concept = '8339' WHERE concept_id = 1746120 AND   concept_name = 'Piperacillin 60 MG/ML / tazobactam 7.5 MG/ML Injectable Solution' AND   domain_id = 'Drug' AND   vocabulary_id = 'RxNorm' AND   concept_class_id = 'Clinical Drug' AND   standard_concept IS NULL AND   concept_code = '312443' AND   valid_start_date = DATE '1970-01-01' AND   valid_end_date = DATE '2016-05-01' AND   invalid_reason = 'D';
INSERT INTO tmpr(  concept_id,  concept_name,  domain_id,  vocabulary_id,  concept_class_id,  standard_concept,  concept_code,  valid_start_date,  valid_end_date,  invalid_reason)VALUES(  43560048,  'Betamethasone 0.284 MG/ML / Gentamicin Sulfate (USP) 0.57 MG/ML [Betagen br AND of Betamethasone  AND Gentamicin]',  'Drug',  'RxNorm',  'Branded Drug Comp',  '1596450',  '1435264',  DATE '2013-09-03',  DATE '2017-08-06',  'D');
INSERT INTO tmpr(  concept_id,  concept_name,  domain_id,  vocabulary_id,  concept_class_id,  standard_concept,  concept_code,  valid_start_date,  valid_end_date,  invalid_reason)VALUES(  40225917,  'Bupivacaine Hydrochloride 0.625 MG/ML / Fentanyl 0.002 MG/ML Injectable Solution',  'Drug',  NULL,  'Clinical Drug',  '1815',  '1012661',  NULL,  NULL,  NULL);
INSERT INTO tmpr(  concept_id,  concept_name,  domain_id,  vocabulary_id,  concept_class_id,  standard_concept,  concept_code,  valid_start_date,  valid_end_date,  invalid_reason)VALUES(  40225920,  'Bupivacaine Hydrochloride 0.625 MG/ML / Fentanyl 0.005 MG/ML Injectable Solution',  'Drug',  NULL,  'Clinical Drug',  '1815',  '1012665',  NULL,  NULL,  NULL);
INSERT INTO tmpr(  concept_id,  concept_name,  domain_id,  vocabulary_id,  concept_class_id,  standard_concept,  concept_code,  valid_start_date,  valid_end_date,  invalid_reason)VALUES(  40225925,  'Bupivacaine Hydrochloride 1 MG/ML / Fentanyl 0.002 MG/ML Injectable Solution',  'Drug',  NULL,  'Clinical Drug',  '1815',  '1012668',  NULL,  NULL,  NULL);
INSERT INTO tmpr(  concept_id,  concept_name,  domain_id,  vocabulary_id,  concept_class_id,  standard_concept,  concept_code,  valid_start_date,  valid_end_date,  invalid_reason)VALUES(  40225928,  'Bupivacaine Hydrochloride 1 MG/ML / Fentanyl 0.005 MG/ML Injectable Solution',  'Drug',  NULL,  'Clinical Drug',  '1815',  '1012672',  NULL,  NULL,  NULL);
INSERT INTO tmpr(  concept_id,  concept_name,  domain_id,  vocabulary_id,  concept_class_id,  standard_concept,  concept_code,  valid_start_date,  valid_end_date,  invalid_reason)VALUES(  40225935,  'Bupivacaine Hydrochloride 1.25 MG/ML / Fentanyl 0.002 MG/ML Injectable Solution',  'Drug',  NULL,  'Clinical Drug',  '1815',  '1012688',  NULL,  NULL,  NULL);
INSERT INTO tmpr(  concept_id,  concept_name,  domain_id,  vocabulary_id,  concept_class_id,  standard_concept,  concept_code,  valid_start_date,  valid_end_date,  invalid_reason)VALUES(  40225939,  'Bupivacaine Hydrochloride 1.25 MG/ML / Fentanyl 0.005 MG/ML Injectable Solution',  'Drug',  NULL,  'Clinical Drug',  '1815',  '1012697',  NULL,  NULL,  NULL);
INSERT INTO tmpr(  concept_id,  concept_name,  domain_id,  vocabulary_id,  concept_class_id,  standard_concept,  concept_code,  valid_start_date,  valid_end_date,  invalid_reason)VALUES(  40174630,  'EGG YOLK PHOSPHOLIPIDS 12 MG/ML / Glycerin 25 MG/ML / Soybean Oil 100 MG/ML Injectable Suspension [Liposyn III]',  NULL,  NULL,  'Branded Drug',  '314605',  '902325',  NULL,  NULL,  NULL);
INSERT INTO tmpr(  concept_id,  concept_name,  domain_id,  vocabulary_id,  concept_class_id,  standard_concept,  concept_code,  valid_start_date,  valid_end_date,  invalid_reason)VALUES(  40174630,  'EGG YOLK PHOSPHOLIPIDS 12 MG/ML / Glycerin 25 MG/ML / Soybean Oil 100 MG/ML Injectable Suspension [Liposyn III]',  NULL,  NULL,  'Branded Drug',  '9949',  '902325',  NULL,  NULL,  NULL);
INSERT INTO tmpr(  concept_id,  concept_name,  domain_id,  vocabulary_id,  concept_class_id,  standard_concept,  concept_code,  valid_start_date,  valid_end_date,  invalid_reason)VALUES(  1746120,  'Piperacillin 60 MG/ML / tazobactam 7.5 MG/ML Injectable Solution',  'Drug',  'RxNorm',  'Clinical Drug',  '37617',  '312443',  NULL,  NULL,  NULL);

insert into irs
select concept_code, standard_concept from tmpr;

insert into irs
select r.concept_code,c.concept_code 
from devv5.concept_relationship 
join rxnorm_to_insert r on concept_id_1 = concept_id
join concept c on c.concept_id = concept_id_2 and relationship_id in ('Has brand name','RxNorm has dose form');


create table dss as
select * from ds_stage where 1=0;

-- only single ingredients
insert into dss
with a as ( 
select substring(r.concept_name, '(^\d+\s(MG|ML|ACTUAT))') as quant, substring(r.concept_name,'/(ML|MG|ACTUAT)')  as denom, trim(substring (r.concept_name,'((\s\d+(\.\d+)?)\s*(MG|MEQ|UNT|MMOL))')) as dosage,
r.concept_name, r.concept_code as drug_concept_code, c.concept_code as ingredient_concept_code
from rxnorm_to_insert r
join irs on cc1=r.concept_code
join concept c on cc2=c.concept_code and c.vocabulary_id='RxNorm' and c.concept_class_id = 'Ingredient'
where r.concept_name not like '% / %')
select drug_concept_code, ingredient_concept_code,null, 
case when denom is null then substring (dosage, '\d+\.?\d?')::float else null end, 
case when denom is null then regexp_replace (dosage, '\d+\.?\d?\s+','') else null end,
case when denom is not null and quant is not null then substring (dosage, '\d+\.?\d?')::float*substring (quant, '\d+\.?\d?')::float
     when denom is not null and quant is null then substring (dosage, '\d+\.?\d?')::float else null end,
case when denom is not null then regexp_replace (dosage, '\d*\.?\d*\s+','') else null end,
case when quant is not null then substring (quant, '\d+\.?\d?')::float  else null end,
case when quant is not null then regexp_replace (quant, '\d+\.?\d?','')
     when denom is not null and quant is null then denom else null end
from a;
;

-- multiple ingredients
select substring(r.concept_name, '(^\d+\s(MG|ML|ACTUAT))') as quant, substring(r.concept_name,'/(ML|MG|ACTUAT)')  as denom, 
trim(substring (r.concept_name,'((\s\d+(\.\d+)?)\s*(MG|MEQ|UNT|MMOL))')) as dosage,
--r.concept_name, r.concept_code as drug_concept_code, c.concept_code as ingredient_concept_code, c.concept_name,
;

select 
  trim(unnest(regexp_matches(r.concept_name, '[^\s/\s]+', 'g'))) as ing, regexp_matches(r.concept_name, '[^/]+', 'g')
from rxnorm_to_insert r
join irs on cc1=r.concept_code
join concept c on cc2=c.concept_code and c.vocabulary_id='RxNorm' and c.concept_class_id = 'Ingredient'
where r.concept_name  like '% / %'
order by r.concept_code
;
