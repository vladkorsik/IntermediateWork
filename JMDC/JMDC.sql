/*********************************************
* Script to create input tables according to *
* http://www.ohdsi.org/web/wiki/doku.php?id=documentation:international_drugs *
* for JMDC drugs                  *
*********************************************/

/*
o   A = ampoule (parenteral)

o   Syg = syringe

o   Bag = infusion bag

o   V = vial (oral)

o   Bot = bottle (topical or oral)

In the Brand Name column, there are records “Deleted NHI price” and “Crude Drugs”. Disregard.

drop sequence new_vocab;
/*
declare
 ex number;
begin
  select max(cast(substr(concept_code, 5) as integer))+1 into ex from devv5.concept where concept_code like 'OMOP%' and concept_code not like '% %'; -- Last valid value of the OMOP123-type codes
  begin
    execute immediate 'create sequence new_vocab increment by 1 start with ' || ex || ' nocycle cache 20 noorder';
    exception
      when others then null;
  end;
end;
;
*/
commit;

/*
-- drop table jmdc;
create table jmdc (
  Drug_code integer,
  Claim_code integer,
  WHO_ATC_code varchar2(255),
  WHO_ATC_name varchar2(255),
  General_name varchar2(255),
  Brand_name varchar2(255),
  Standardized_unit varchar(100),
  frequency varchar(10),
  concept_id integer,
  concept_name varchar2(255),
  concept_class_id varchar2(20)
)
nologging
;
truncate table jmdc;
*/
-------------------------------------------------------------------------------------------------

-- Create products
drop table drug_concept_stage;
create table drug_concept_stage (
  concept_name varchar2(255),
  vocabulary_id varchar2(20),
  concept_class_id varchar2(20),
  standard_concept varchar2(1),
  concept_code varchar2(255), -- need a long one because Ingredient and Dose Form string used as concept_code
  possible_excipient varchar2(1),
  valid_start_date date,
  valid_end_date date,
  invalid_reason varchar2(1)
)
NOLOGGING;

-- Create products
drop table non_drug;
create table non_drug (
  concept_name varchar2(255),
  vocabulary_id varchar2(20),
  concept_class_id varchar2(20),
  standard_concept varchar2(1),
  concept_code varchar2(255), -- need a long one because Ingredient and Dose Form string used as concept_code
  possible_excipient varchar2(1),
  valid_start_date date,
  valid_end_date date,
  invalid_reason varchar2(1)
)
NOLOGGING;

drop table relationship_to_concept;
create table relationship_to_concept (
  concept_code_1 varchar2(255),
  vocabulary_id_1 varchar2(20),
  concept_id_2 integer,
  precedence integer,
  conversion_factor float
)
NOLOGGING;

drop table internal_relationship_stage;
create table internal_relationship_stage (
  concept_code_1 varchar2(255),
  vocabulary_id_1 varchar2(20),
  concept_code_2 varchar2(255),
  vocabulary_id_2 varchar2(20)
)
NOLOGGING;

drop table ds_stage;
create table ds_stage (
  drug_concept_code	varchar2(255),  --	The source code of the Drug or Drug Component, either Branded or Clinical.
  ingredient_concept_code	varchar2(255), --	The source code for one of the Ingredients.
  amount_value float,	-- The numeric value for absolute content (usually solid formulations).
  amount_unit varchar2(255), --	The verbatim unit of the absolute content (solids).
  numerator_value float, --	The numerator value for a concentration (usally liquid formulations).
  numerator_unit varchar(255), --	The verbatim numerator unit of a concentration (liquids).
  denominator_value float, --	The denominator value for a concentration (usally liquid formulations).
  denominator_unit varchar2(255), --	The verbatim denominator unit of a concentration (liquids).
  box_size integer
)
NOLOGGING;

-- Prepare
-- Create copy of input data
drop table j purge;
create table j as select * from jmdc;

-- Remove pseudo brands
update j set brand_name = null where brand_name in (
  'Acrinol and Zinc Oxide Oil', 
  'Caffeine and Sodium Benzoate',
  'Compound Oxycodone and Atropine',
  'Crude Drugs',
  'Deleted NHI price', 
  'Glycerin and Potash', 
  'Morphine and Atropine', 
  'Opium Alkaloids and Atropine', 
  'Opium Alkaloids and Scopolamine', 
  'Phenol and Zinc Oxide Liniment', 
  'Scopolia Extract and Tannic Acid', 
  'Sulfur and Camphor',
  'Sulfur,Salicylic Acid and Thianthol', 
  'Swertia and Sodium Bicarbonate',
  'Weak Opium Alkaloids and Scopolamine'
)
or lower(brand_name)=lower(general_name)
;
-- Remove devices from list
-- Radiopharmaceuticals, scintigraphic material and blood products
insert into non_drug
select distinct 
  general_name||' '||standardized_unit||' ['||brand_name||']' as concept_name,
  'JMDC' as vocabulary_id,
  'Device' as concept_class_id,
  null as standard_concept,
  drug_code as concept_code,
  null as possible_excipient,
  null as valid_start_date, null as valid_end_date, null as invalid_reason
from (
  select distinct drug_code, general_name, standardized_unit, brand_name from j
) where (
  general_name like '%(99mTc)%' or
  general_name like '%(123I)%' or
  general_name like '%(131I)%' or
  general_name like '%(89Sr)%' or 
  general_name like '%(9 Cl)%' or 
  general_name like '%(111In)%' or 
  general_name like '%(13C)%' or 
  general_name like '%(51Cr)%' or 
  general_name like '%(201Tl)%' or 
  general_name like '%(133Xe)%' or 
  general_name like '%(90Y)%' or 
  general_name like '%(81mKr)%' or 
  general_name like '%(90Y)%' or 
  general_name like '%(67Ga)%' or
  general_name like '%cellulose,oxidized%' or
  (general_name like '%blood%' and general_name not like '%coagulation%') or 
  general_name like '%plasma%'
);

/* For Anna
Add:
- Purified Tuberculin
- 

delete from j where drug_code in (select concept_code from non_drug);

/************************************
* 1. Create drug products *
*************************************/
-- Branded Drugs
insert into drug_concept_stage
select distinct 
  substr(general_name||' '||standardized_unit||' ['||brand_name||']', 1, 255) as concept_name,
  'JMDC' as vocabulary_id,
  'Branded Drug' as concept_class_id,
  null as standard_concept,
  drug_code as concept_code,
  null as possible_excipient,
  null as valid_start_date, null as valid_end_date, null as invalid_reason
from (
  select distinct drug_code, general_name, standardized_unit, brand_name from j where brand_name is not null
);

-- Clinical Drugs
insert into drug_concept_stage
select distinct 
  substr(general_name||' '||standardized_unit, 1, 255) as concept_name,
  'JMDC' as vocabulary_id,
  'Clinical Drug' as concept_class_id,
  null as standard_concept,
  drug_code as concept_code,
  null as possible_excipient,
  null as valid_start_date, null as valid_end_date, null as invalid_reason
from (
  select distinct drug_code, general_name, standardized_unit, brand_name from j where brand_name is null
);


/*************************************************
* 2. Create parsed Ingredients and relationships *
*************************************************/
-- Collect mono-ingredients
drop table pi purge;
create table pi as
select distinct
  drug_code,
  general_name as ing_name
from j
where general_name not like '%/%'
and general_name not like '% and %';

-- Split poly-ingredients
insert into pi
with j_slash as (
  select drug_code, replace(general_name, ' and ', '/') as concept_name from j
)
select distinct
  drug_code,
  regexp_substr (concept_name, '[^/]+', 1, rn) as ing_name
from j_slash
cross join (
  select rownum rn
  from (
    select max(regexp_count (concept_name, '/') + 1) mx
    from j_slash
  )
connect by level <= mx
)
where regexp_substr (concept_name, '[^/]+', 1, rn) is not null
and concept_name like '%/%'
;

insert into drug_concept_stage
select
  ing_name as concept_name,
  'JMDC' as vocabulary_id,
  'Ingredient' as concept_class_id,
  null as standard_concept,
  'OMOP'||new_vocab.nextval as concept_code,
  null as possible_excipient,
  null as valid_start_date, null as valid_end_date, null as invalid_reason
from (
  select distinct ing_name from pi
);

-- create relationship between products and ingredients
insert into internal_relationship_stage
select distinct
  pi.drug_code as concept_code_1, 'JMDC' as vocabulary_id_1,
  dcs.concept_code as concept_code_2, 'JMDC' as vocabulary_id_2
from pi join drug_concept_stage dcs on dcs.concept_name=pi.ing_name and dcs.concept_class_id='Ingredient';

/*************************************************
* 3. Create parsed Brand Names and relationships *
*************************************************/

insert into drug_concept_stage
select
  brand_name as concept_name,
  'JMDC' as vocabulary_id,
  'Brand Name' as concept_class_id,
  null as standard_concept,
  'OMOP'||new_vocab.nextval as concept_code,
  null as possible_excipient,
  null as valid_start_date, null as valid_end_date, null as invalid_reason
from (
  select distinct brand_name from j where brand_name is not null
);

-- create relationship between products and ingredients
insert into internal_relationship_stage
select distinct
  j.drug_code as concept_code_1, 'JMDC' as vocabulary_id_1,
  dcs.concept_code as concept_code_2, 'JMDC' as vocabulary_id_2
from j join drug_concept_stage dcs on dcs.concept_name=j.brand_name and dcs.concept_class_id='Brand Name'
;

/*********************************
* 4. Create and link Drug Strength
*********************************/

-- remove junk from standard_unit
update j set standardized_unit = regexp_replace(standardized_unit, '\(forGeneralDiagnosis\)', '') where standardized_unit like '%(forGeneralDiagnosis)%';
update j set standardized_unit = regexp_replace(standardized_unit, '\(forGeneralDiagnosis/forOnePerson\)', '') where standardized_unit like '%(forGeneralDiagnosis/forOnePerson)%';
update j set standardized_unit = regexp_replace(standardized_unit, '\(forStrongResponsePerson\)', '') where standardized_unit like '%(forStrongResponsePerson)%';
update j set standardized_unit = regexp_replace(standardized_unit, '\(MixedPreparedInjection\)', '') where standardized_unit like '%(MixedPreparedInjection)%';
update j set standardized_unit = regexp_replace(standardized_unit, 'w/NS', '') where standardized_unit like '%w/NS%';
update j set standardized_unit = regexp_replace(standardized_unit, '\(w/Soln\)', '') where standardized_unit like '%(w/Soln)%';
update j set standardized_unit = regexp_replace(standardized_unit, '\(asSoln\)', '') where standardized_unit like '%(asSoln)%';
update j set standardized_unit = regexp_replace(standardized_unit, '\(w/DrainageBag\)', '') where standardized_unit like '%(w/DrainageBag)%';
update j set standardized_unit = regexp_replace(standardized_unit, '\(w/Sus\)', '') where standardized_unit like '%(w/Sus)%';
update j set standardized_unit = regexp_replace(standardized_unit, '\(asgoserelin\)', '') where standardized_unit like '%(asgoserelin)%';
update j set standardized_unit = regexp_replace(standardized_unit, '\(Amountoftegafur\)', '') where standardized_unit like '%(Amountoftegafur)%';
update j set standardized_unit = regexp_replace(standardized_unit, '\(as levofloxacin\)', '') where standardized_unit like '%(as levofloxacin)%';
update j set standardized_unit = regexp_replace(standardized_unit, '\(as phosphorus\)', '') where standardized_unit like '%(as phosphorus)%';
update j set standardized_unit = regexp_replace(standardized_unit, '\(asActivatedform\)', '') where standardized_unit like '%(asActivatedform)%';
update j set standardized_unit = regexp_replace(standardized_unit, 'teriparatideacetate', '') where standardized_unit like '%teriparatideacetate%';
update j set standardized_unit = regexp_replace(standardized_unit, 'Elcatonin', '') where standardized_unit like '%Elcatonin%';
update j set standardized_unit = regexp_replace(standardized_unit, '\(asSuspendedLiquid\)', '') where standardized_unit like '%(asSuspendedLiquid)%';
update j set standardized_unit = regexp_replace(standardized_unit, '\(mixedOralLiquid\)', '') where standardized_unit like '%(mixedOralLiquid)%';
update j set standardized_unit = regexp_replace(standardized_unit, '\(w/Soln,Dil\)', '') where standardized_unit like '%(w/Soln,Dil)%';
update j set standardized_unit = regexp_replace(standardized_unit, 'DomesticStandard', '') where standardized_unit like '%DomesticStandard%';
update j set standardized_unit = regexp_replace(standardized_unit, 'million', '000000') where standardized_unit like '%million%';
update j set standardized_unit = regexp_replace(standardized_unit, 'U\.S\.P\.', '') where standardized_unit like '%U.S.P.%';
update j set standardized_unit = regexp_replace(standardized_unit, 'about', '') where standardized_unit like '%about%';
update j set standardized_unit = regexp_replace(standardized_unit, 'iron', '') where standardized_unit like '%iron%';
update j set standardized_unit = regexp_replace(standardized_unit, ':240times', '') where standardized_unit like '%:240times%';
update j set standardized_unit = regexp_replace(standardized_unit, 'low\-molecularheparin', '') where standardized_unit like '%low-molecularheparin%';
update j set standardized_unit = regexp_replace(standardized_unit, '\(asCalculatedamountofD\-arabinose\)', '') where standardized_unit like '%(asCalculatedamountofD-arabinose)%';
update j set standardized_unit = regexp_replace(standardized_unit, 'w/5%GlucoseInjection', '') where standardized_unit like '%w/5\%GlucoseInjection%' escape '\';
update j set standardized_unit = regexp_replace(standardized_unit, 'w/WaterforInjection', '') where standardized_unit like '%w/WaterforInjection%';
update j set standardized_unit = regexp_replace(standardized_unit, '\(w/SodiumBicarbonate\)', '') where standardized_unit like '%(w/SodiumBicarbonate)%';
update j set standardized_unit = regexp_replace(standardized_unit, 'potassium', '') where standardized_unit like '%potassium%';
update j set standardized_unit = regexp_replace(standardized_unit, '\(Amountoftrifluridine\)', '') where standardized_unit like '%(Amountoftrifluridine)%';
update j set standardized_unit = regexp_replace(standardized_unit, 'FRM', '') where standardized_unit like '%FRM%';
update j set standardized_unit = regexp_replace(standardized_unit, 'NormalHumanPlasma', '') where standardized_unit like '%NormalHumanPlasma%';
update j set standardized_unit = regexp_replace(standardized_unit, 'Anti-factorXa', '') where standardized_unit like '%Anti-factorXa%';
update j set standardized_unit = regexp_replace(standardized_unit, '\(w/SodiumBicarbonateSoln\)', '') where standardized_unit like '%(w/SodiumBicarbonateSoln)%';
update j set standardized_unit = regexp_replace(standardized_unit, ',CorSoln', '') where standardized_unit like '%,CorSoln%';
update j set standardized_unit = regexp_replace(standardized_unit, '1Set', '') where standardized_unit like '%1Set%';
update j set standardized_unit = regexp_replace(standardized_unit, 'AmountforOnce', '') where standardized_unit like '%AmountforOnce%';
update j set standardized_unit = regexp_replace(standardized_unit, '\(w/Dil\)', '') where standardized_unit like '%(w/Dil)%';

/************************************************
* 3. Create parsed Dose Forms and relationships *
************************************************/
-- Create rough dose forms
insert into drug_concept_stage (concept_name, vocabulary_id, concept_class_id, standard_concept, concept_code, possible_excipient, valid_start_date, valid_end_date, invalid_reason)
  values ('Inhalant', 'JMDC', 'Dose Form', null, 'OMOP'||new_vocab.nextval, null, null, null, null);
insert into drug_concept_stage (concept_name, vocabulary_id, concept_class_id, standard_concept, concept_code, possible_excipient, valid_start_date, valid_end_date, invalid_reason)
  values ('Capsule', 'JMDC', 'Dose Form', null, 'OMOP'||new_vocab.nextval, null, null, null, null);
insert into drug_concept_stage (concept_name, vocabulary_id, concept_class_id, standard_concept, concept_code, possible_excipient, valid_start_date, valid_end_date, invalid_reason)
  values ('Tablet', 'JMDC', 'Dose Form', null, 'OMOP'||new_vocab.nextval, null, null, null, null);
insert into drug_concept_stage (concept_name, vocabulary_id, concept_class_id, standard_concept, concept_code, possible_excipient, valid_start_date, valid_end_date, invalid_reason)
  values ('Injectant', 'JMDC', 'Dose Form', null, 'OMOP'||new_vocab.nextval, null, null, null, null);
insert into drug_concept_stage (concept_name, vocabulary_id, concept_class_id, standard_concept, concept_code, possible_excipient, valid_start_date, valid_end_date, invalid_reason)
  values ('Topical', 'JMDC', 'Dose Form', null, 'OMOP'||new_vocab.nextval, null, null, null, null);
insert into drug_concept_stage (concept_name, vocabulary_id, concept_class_id, standard_concept, concept_code, possible_excipient, valid_start_date, valid_end_date, invalid_reason)
  values ('Patch', 'JMDC', 'Dose Form', null, 'OMOP'||new_vocab.nextval, null, null, null, null);
insert into drug_concept_stage (concept_name, vocabulary_id, concept_class_id, standard_concept, concept_code, possible_excipient, valid_start_date, valid_end_date, invalid_reason)
  values ('Unknown', 'JMDC', 'Dose Form', null, 'OMOP'||new_vocab.nextval, null, null, null, null);

-- Create dose form for each record
insert into internal_relationship_stage
with u as (
  select drug_code,
    case
      when u2='bls' then 'Inhalant'
      when u2='c' then 'Capsule'
      when u2='t' then 'Tablet'
      when u1='u' and u2='mlv' then 'Injectant'
      when u2 in ('kit', 'syg', 'a', 'v') then 'Injectant'
      when u3 in ('kit', 'syg', 'a', 'v') then 'Injectant'
      when u1='g' and u2 is null and u3 is null then 'Topical'
      when u3='bot' then 'Topical'
      when u1='mg' and u2='ml' and u3 is null then 'Topical'
      when u1='mg' and u2='g' and u3 is null then 'Topical'
      else 'Unknown'
    end as df
  from (
    select 
      drug_code, 
      cast(substr(dose, s1+1, s2-s1-1) as varchar(20)) as u1,
      cast(substr(dose, s3+1, s4-s3-1) as varchar(20)) as u2,
      cast(substr(dose, s5+1) as varchar(20)) as u3
    from (
      select 
        drug_code, dose,
        instr(dose, '|', 1, 1) as s1, instr(dose, '|', 1, 2) as s2, instr(dose, '|', 1, 3) as s3, instr(dose, '|', 1, 4) as s4, instr(dose, '|', 1, 5) as s5
      from (
        select 
          drug_code,
          regexp_replace(lower(translate(standardized_unit, 'a(),', 'a')), '([0-9\.,]+)([a-z%]+)([0-9\.,]+)?([a-z%]+)?([0-9\.,]+)?([a-z%]+)?', '\1|\2|\3|\4|\5|\6') as dose
        from j -- join drug_concept_stage dcs on dcs.concept_code=j.drug_code
        where standardized_unit not like '%Sheet%' and standardized_unit not like '%cm*%' and standardized_unit not like '%mm*%'
        and drug_code not in (100000063966, 100000013362) -- immunoglobulin with histamine, bacitracin/fradiomycin sulfate - ??????????
      )
    )
  )
)
select distinct
  u.drug_code as concept_code_1, 'JMDC' as vocabulary_id_1,
  df.concept_code as concept_code_2, 'JMDC' as vocabulary_id_2
from u join drug_concept_stage df on df.concept_name=u.df and df.concept_class_id='Dose Form'
;


-- Patches
insert into internal_relationship_stage
select 
  drug_code as concept_code_1, 'JMDC' as vocabulary_id_1,
  (select concept_code from drug_concept_stage where concept_name='Patch') as concept_code_2, 'JMDC' as vocabulary_id_2
from j where standardized_unit like '%Sheet%' or standardized_unit like '%cm*%' or standardized_unit like '%mm*%';

-- Manual ones
insert into internal_relationship_stage (concept_code_1, vocabulary_id_1, concept_code_2, vocabulary_id_2) 
  values ('100000063966', 'JMDC', (select concept_code from drug_concept_stage where concept_name='Injectant'), 'JMDC'); -- immunoglobulin with histamine
insert into internal_relationship_stage (concept_code_1, vocabulary_id_1, concept_code_2, vocabulary_id_2) 
  values ('100000013362', 'JMDC', (select concept_code from drug_concept_stage where concept_name='Topical'), 'JMDC'); -- bacitracin/fradiomycin sulfate

commit;

-- Write mappings to RxNorm Dose Forms
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082224, 1); --Topical Cream
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082200, 2); --Rectal Suppository
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19130307, 3); --Medicated Pad
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19095912, 4); --Topical Spray
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082225, 5); --Topical Lotion
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19008697, 6); --Medicated Shampoo
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19112648, 7); --Douche
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082651, 8); --Oral Granules
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19126590, 9); --Mouthwash
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082109, 10); --Medicated Liquid Soap
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19135438, 11); --Augmented Topical Cream
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082627, 12); --Enema
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082227, 13); --Topical Ointment
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19126920, 14); --Prefilled Syringe
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19011167, 15); --Nasal Spray
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19093368, 16); --Vaginal Suppository
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19095918, 17); --Oral Paste
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19095972, 18); --Topical Foam
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082259, 19); --Inhalant Powder
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19010878, 20); --Vaginal Cream
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 46234466, 21); --Auto-Injector
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082197, 22); --Rectal Cream
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082574, 23); --Rectal Foam
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082251, 24); --Oral Wafer
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19095911, 25); --Oral Spray
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082573, 26); --Oral Tablet
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082103, 27); --?????? ??? ????????? ?????? ????
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082168, 28); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082170, 29); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082079, 30); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082191, 31); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082228, 32); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19135866, 33); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082077, 34); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19095973, 35); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19129634, 36); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082253, 37); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082104, 38); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19001949, 39); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082229, 40); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 46234469, 41); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19095898, 42); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082076, 43); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082258, 44); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082255, 45); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19135925, 46); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19095916, 47); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082080, 48); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082285, 49); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082286, 50); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082195, 51); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082165, 52); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19009068, 53); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082167, 54); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19016586, 55); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19095976, 56); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082108, 57); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082226, 58); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19102295, 59); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082110, 60); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 44817840, 61); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19126918, 62); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19124968, 63); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19129139, 64); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19095900, 65); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19102296, 66); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082282, 67); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 46234468, 68); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19010880, 69); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19126316, 70); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19010962, 71); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082166, 72); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19126919, 73); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19127579, 74); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 46234467, 75); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 40175589, 76); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082281, 77); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19059413, 78); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082196, 79); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082163, 80); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082169, 81); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19095917, 82); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19095971, 83); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082162, 84); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 40164192, 85); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082105, 86); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082222, 87); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082575, 88); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082652, 89); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 45775489, 90); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 45775491, 91); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082164, 92); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 40167393, 93); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082287, 94); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082194, 95); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082576, 96); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19095975, 97); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082628, 98); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 46275062, 99); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19010879, 100); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 46234410, 101); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19135439, 102); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19095977, 103); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082199, 104); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082283, 105); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19095974, 106); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19135446, 107); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19130329, 108); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 45775490, 109); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 45775492, 110); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19082101, 111); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 19135440, 112); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 45775488, 113); --
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Unknown', 'JMDC', 44784844, 114); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19082225, 1); --Topical Lotion
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19082224, 2); --Topical Cream
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 40228565, 3); --Oil
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19082228, 4); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19095912, 5); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 46234410, 6); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19082227, 7); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19082226, 8); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19095972, 9); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19095973, 10); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19082628, 11); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19135438, 12); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19135446, 13); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19135439, 14); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19135440, 15); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19129401, 16); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19082287, 17); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19135925, 18); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19082194, 19); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19095975, 20); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19082164, 21); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19110977, 22); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19082161, 23); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19082576, 24); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19082169, 25); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19082193, 26); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19082197, 27); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19010878, 28); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19112544, 29); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19082163, 30); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19082166, 31); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19095916, 32); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19095917, 33); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19095974, 34); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19010880, 35); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19011932, 36); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19095900, 37); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19011167, 38); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19095911, 39); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19082281, 40); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19082199, 41); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19095899, 42); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19112649, 43); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19082110, 44); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19082165, 45); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19082195, 46); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 45775488, 47); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19095977, 48); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19082167, 49); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19082196, 50); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19082102, 51); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Topical', 'JMDC', 19010879, 52); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Inhalant', 'JMDC', 19127579, 1); --Dry Powder Inhaler
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Inhalant', 'JMDC', 19082259, 2); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Inhalant', 'JMDC', 19095898, 3); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Inhalant', 'JMDC', 19126918, 4); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Inhalant', 'JMDC', 19082162, 5); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Inhalant', 'JMDC', 19126919, 6); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Inhalant', 'JMDC', 19082258, 7); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Inhalant', 'JMDC', 19018195, 8); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Capsule', 'JMDC', 19082168, 1); --Oral Capsule
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Capsule', 'JMDC', 19082077, 2); --Extended Release Oral Capsule
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Capsule', 'JMDC', 19082255, 3); --Delayed Release Oral Capsule
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Capsule', 'JMDC', 19103220, 4); --12 hour Extended Release Capsule
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Capsule', 'JMDC', 19082256, 5); --24 Hour Extended Release Capsule
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Capsule', 'JMDC', 19021887, 6); --Capsule
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Capsule', 'JMDC', 19082255, 7); --Delayed Release Oral Capsule
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Tablet', 'JMDC', 19082573, 1); --Oral Tablet
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Tablet', 'JMDC', 19082076, 2); --Disintegrating Oral Tablet
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Tablet', 'JMDC', 19001949, 3); --Delayed Release Oral Tablet
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Tablet', 'JMDC', 19082079, 4); --Extended Release Oral Tablet
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Tablet', 'JMDC', 19135866, 5); --Chewable Tablet
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Tablet', 'JMDC', 19082285, 6); --Sublingual Tablet
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Tablet', 'JMDC', 19010962, 7); --Vaginal Tablet
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Tablet', 'JMDC', 19082253, 8); --Oral Lozenge
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Tablet', 'JMDC', 40175589, 9); --Buccal Tablet
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Tablet', 'JMDC', 19082050, 10); --24 Hour Extended Release Tablet
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Tablet', 'JMDC', 19082048, 11); --12 hour Extended Release Tablet
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Tablet', 'JMDC', 44817840, 12); --Effervescent Oral Tablet
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Tablet', 'JMDC', 19001943, 13); --Tablet
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Tablet', 'JMDC', 19082222, 14); --Sustained Release Buccal Tablet
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Injectant', 'JMDC', 19082103, 1); --Injectable Solution
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Injectant', 'JMDC', 46234469, 2); --Injection
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Injectant', 'JMDC', 19082104, 3); --Injectable Suspension
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Injectant', 'JMDC', 19126920, 4); --Prefilled Syringe
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Injectant', 'JMDC', 46234467, 5); --Pen Injector
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Injectant', 'JMDC', 46234466, 6); --Auto-Injector
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Injectant', 'JMDC', 44784844, 7); --Injectable Foam
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Injectant', 'JMDC', 46234468, 8); --Cartridge
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Injectant', 'JMDC', 19095913, 9); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Injectant', 'JMDC', 19095914, 10); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Injectant', 'JMDC', 19082105, 11); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Injectant', 'JMDC', 46275062, 12); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Injectant', 'JMDC', 19095915, 13); --
Insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence) values ('Injectant', 'JMDC', 19082260, 14); --

-- write mappings to real units
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence, conversion_factor) values ('u', 'JMDC', 8510, 1, 1); -- to unit
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence, conversion_factor) values ('iu', 'JMDC', 8510, 1, 1); -- to international unit
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence, conversion_factor) values ('g', 'JMDC', 8576, 1, 1000); -- to milligram
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence, conversion_factor) values ('g', 'JMDC', 8587, 2, 1); -- to milliliter
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence, conversion_factor) values ('mg', 'JMDC', 8576, 1, 1); -- to milligram
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence, conversion_factor) values ('mg', 'JMDC', 8587, 2, 0.001); -- to milliliter
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence, conversion_factor) values ('ml', 'JMDC', 8587, 1, 1); -- to milliliter
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence, conversion_factor) values ('mlv', 'JMDC', 8587, 1, 1); -- to milliliter
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence, conversion_factor) values ('mlv', 'JMDC', 8576, 2, 1000); -- to milligram
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence, conversion_factor) values ('ml', 'JMDC', 8587, 1, 1); -- to milliliter
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence, conversion_factor) values ('ml', 'JMDC', 8576, 2, 1000); -- to milligram
insert into relationship_to_concept (concept_code_1, vocabulary_id_1, concept_id_2, precedence, conversion_factor) values ('%', 'JMDC', 8554, 2, 1);
commit;

-- left to do:

JMDC.sql
Displaying JMDC.sql.

