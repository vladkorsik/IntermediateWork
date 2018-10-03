-- 0. creating a table with aggregated RxNorm/RxE ingredients
drop table if exists rx_combo;
create table rx_combo as
select drug_concept_id, 
  string_agg(ingredient_concept_id::varchar, '-' order by ingredient_concept_id) as i_combo
from drug_strength
join concept on concept_id = drug_concept_id and concept_class_id in ('Clinical Drug Form') -- 'Clinical Drug Comp' doesn exist
group by drug_concept_id
;

-- 1. Precise combos (and)

drop table if exists simple_comb;
create table simple_comb as
with ing as
(select i.concept_code_1,i.concept_code_2, atc_name,precedence,rtc.concept_id_2 as ing from atc_1_comb
left join reference using (atc_code)
join internal_relationship_stage i  on coalesce (concept_code,atc_code) = concept_code_1
join drug_concept_stage d on d.concept_code = concept_code_2 and concept_class_id = 'Ingredient'
join relationship_to_concept rtc on rtc.concept_code_1 = d.concept_code
 where  atc_name ~ ' and ' and not atc_name ~ 'excl|combinations of|derivate|other|with'
),
form as
(select i.concept_code_1,rtc.concept_id_2 as form  from atc_1_comb
left join reference using (atc_code)
join internal_relationship_stage i on coalesce (concept_code,atc_code) = concept_code_1
join drug_concept_stage d on d.concept_code = concept_code_2 and concept_class_id = 'Dose Form'
join relationship_to_concept rtc on rtc.concept_code_1 = d.concept_code
 where  atc_name ~ ' and ' and not atc_name ~ 'excl|combinations of|derivate|other|with'
)
select distinct i.concept_code_1,i.concept_code_2, atc_name, ing,form,precedence
from ing i
left join form f on i.concept_code_1=f.concept_code_1;

--mapping 1 to 1, use drugs where 2 ingredient_id occur
drop table if exists atc_combo;
create table atc_combo as
select concept_code_1, 
  string_agg(ing::varchar, '-' order by ing) as i_combo
from simple_comb
where concept_code_1 in 
(select concept_code_1 from simple_comb
where concept_code_2 in
(select concept_code_2 from (select distinct concept_code_2, ing from simple_comb) s
group by concept_code_2 having count(1)=1)
group by concept_code_1 having count(1)=2) 
group by concept_code_1
;

drop table if exists atc_to_drug_1;
create table atc_to_drug_1 as
select concept_code_1, atc_name, c2.concept_id, c2.concept_name, c2.concept_class_id 
from atc_combo
join simple_comb using (concept_code_1)
join rx_combo using (i_combo)
join concept c on c.concept_id=drug_concept_id
join concept_relationship cr on concept_id_1 = c.concept_id and cr.invalid_reason is null and relationship_id = 'RxNorm has dose form' 
and concept_id_2 = form
join concept c2 on concept_id_1 = c2.concept_id
;
insert into atc_to_drug_1
select concept_code_1, atc_name, c.concept_id, c.concept_name, c.concept_class_id
from atc_combo
join simple_comb using (concept_code_1)
join rx_combo using (i_combo)
join concept c on c.concept_id=drug_concept_id
where concept_code_1 not in (select concept_code_1 from atc_to_drug_1) and concept_code_1 not like '% %' --w/o forms
;

-- introducing precedence
insert into atc_to_drug_1
with atc_comb as
(with hold as (select *
from  simple_comb s
where
not exists (select 1 from simple_comb s2 where s2.concept_code_2=s.concept_code_2 and s2.precedence>1) -- we hold
)
select h.concept_code_1, s.atc_name, case when h.ing>s.ing then s.ing||'-'||h.ing else h.ing||'-'||s.ing end as i_combo, h.form
from hold h
join simple_comb s on h.concept_code_1=s.concept_code_1 and h.ing!=s.ing
where h.concept_code_1 not in (select concept_code_1 from atc_to_drug_1))
select concept_code_1, atc_name, c.concept_id, c.concept_name, c.concept_class_id
from atc_comb
join rx_combo using (i_combo)
join concept c on c.concept_id=drug_concept_id
join concept_relationship cr on concept_id_1 = c.concept_id and cr.invalid_reason is null and relationship_id = 'RxNorm has dose form'
and concept_id_2 = form
join concept c2 on concept_id_2 = c2.concept_id
;
insert into atc_to_drug_1
with atc_comb as
(with hold as (select *
from  simple_comb s
where
not exists (select 1 from simple_comb s2 where s2.concept_code_2=s.concept_code_2 and s2.precedence>1) -- we hold
)
select h.concept_code_1, s.atc_name, case when h.ing>s.ing then s.ing||'-'||h.ing else h.ing||'-'||s.ing end as i_combo, h.form
from hold h
join simple_comb s on h.concept_code_1=s.concept_code_1 and h.ing!=s.ing
where h.concept_code_1 not in (select concept_code_1 from atc_to_drug_1))
select concept_code_1, atc_name, c.concept_id, c.concept_name, c.concept_class_id
from atc_comb
join rx_combo using (i_combo)
join concept c on c.concept_id=drug_concept_id
where concept_code_1 not like '% %' --w/o forms
;
--2nd usual combos
drop table verysimple_comb;
create table verysimple_comb as
with ing as
(select i.concept_code_1,i.concept_code_2, atc_name,rtc.concept_id_2 as ing, 'ing' as flag
from atc_1_comb
left join reference using (atc_code)
join internal_relationship_stage i  on coalesce (concept_code,atc_code) = concept_code_1
join drug_concept_stage d on d.concept_code = concept_code_2 and concept_class_id = 'Ingredient'
join relationship_to_concept rtc on rtc.concept_code_1 = d.concept_code
 where  atc_name ~ 'comb' and not atc_name ~ 'excl|combinations of|derivate|other|with'
),
form as
(select i.concept_code_1,rtc.concept_id_2 as form  from atc_1_comb
left join reference using (atc_code)
join internal_relationship_stage i on coalesce (concept_code,atc_code) = concept_code_1
join drug_concept_stage d on d.concept_code = concept_code_2 and concept_class_id = 'Dose Form'
join relationship_to_concept rtc on rtc.concept_code_1 = d.concept_code
 where  atc_name ~ 'comb' and not atc_name ~ 'excl|combinations of|derivate|other|with'
),
addit as
(select i.concept_code_1, i.concept_code_2, atc_name, rtc.concept_id_2 as ing, 'with' as flag
from atc_1_comb a
left join reference r using (atc_code)
join concept c on regexp_replace(c.concept_code,'.$','') = regexp_replace (a.atc_code,'.$','') and c.concept_class_id = 'ATC 5th'
join internal_relationship_stage i  on coalesce (r.concept_code,atc_code) = concept_code_1
join drug_concept_stage d on d.concept_code = concept_code_2 and d.concept_class_id = 'Ingredient'
join relationship_to_concept rtc on rtc.concept_code_1 = d.concept_code
	)

select distinct i.concept_code_1,i.concept_code_2, atc_name, ing,form, flag
from
	( select * from ing
	 union all
	 select * from addit )i
left join form f on i.concept_code_1=f.concept_code_1
order by i.concept_code_1;

create table atc_to_drug_2 as 
with secondary_table as (
select a.concept_id, a.concept_name ,a.concept_class_id,a.vocabulary_id, c.concept_id_2,r.i_combo
 from rx_combo r
join concept a on r.drug_concept_id = a.concept_id
 join concept_relationship c  on c.concept_id_1 = a.concept_id
 where a.concept_class_id = 'Clinical Drug Form'
 and a.vocabulary_id like 'RxNorm'--temporary remove RXE
 and a.invalid_reason is null
 and relationship_id = 'RxNorm has dose form'
 and c.invalid_reason is null
),
	primary_table as (
			select v.concept_code_1, v.form, v.atc_name, case when v.ing>v2.ing then cast(v2.ing as varchar)||'-'||cast(v.ing as varchar)
																		  else cast(v.ing as varchar)||'-'||cast(v2.ing as varchar) end as atc_combo
from verysimple_comb v
join verysimple_comb v2 on v.concept_code_1 = v2.concept_code_1 and v.flag = 'ing' and v2.flag = 'with'
where v.ing!=v2.ing)
select distinct p.concept_code_1, atc_name, s.concept_id, s.concept_name, s.concept_class_id
from primary_table p
	join secondary_table s
on s.concept_id_2 = p.form
and s.i_combo = p.atc_combo
;

insert into atc_to_drug_2
with primary_table as (
			select v.concept_code_1, v.form, v.atc_name, case when v.ing>v2.ing then cast(v2.ing as varchar)||'-'||cast(v.ing as varchar)
																		  else cast(v.ing as varchar)||'-'||cast(v2.ing as varchar) end as atc_combo
from verysimple_comb v
join verysimple_comb v2 on v.concept_code_1 = v2.concept_code_1 and v.flag = 'ing' and v2.flag = 'with'
where v.ing!=v2.ing)
select distinct p.concept_code_1, atc_name, c.concept_id, c.concept_name, c.concept_class_id
from primary_table p
join rx_combo r on p.atc_combo = r.i_combo
join concept c on c.concept_id = r.drug_concept_id  and c.concept_class_id = 'Clinical Drug Form' and c.vocabulary_id = 'RxNorm'
where p.concept_code_1 not like '% %'--exclude ATC with forms
;

-- 3. ATC combos with exclusions
drop table if exists compl_combo;
create table compl_combo as
with hold as (
select *  from dev_combo_stage d
join relationship_to_concept on concept_code_1 = ing and flag = 'ing' --we hold
where not exists (select 1 from dev_combo_stage d2 where d.atc_code = d2.atc_code and d.ing = d2.ing and precedence>1) -- we hold, exclude multiple for now
),
excl as (
select * from dev_combo_stage d
join relationship_to_concept on concept_code_1 = ing and flag = 'excl' --we exclude
),
additional as (
select * from dev_combo_stage d
join relationship_to_concept on concept_code_1 = ing and flag = 'with' --we add
)

select distinct r.concept_code as concept_code_1, h. atc_name, drug_concept_id as concept_id, concept_name,concept_class_id
from hold h
join reference r on r.atc_code = h.atc_code
left join additional a on h.atc_code=a.atc_code
join excl e on h.atc_code=e.atc_code
join rx_combo on i_combo ~ cast(h.concept_id_2 as varchar) and not i_combo ~ cast(e.concept_id_2 as varchar) and i_combo like '%-%'
join concept c on c.concept_id = drug_concept_id
where a.atc_name is null
;

--with no excluded
insert into compl_combo
with hold as (
select *  from dev_combo_stage d
join relationship_to_concept on concept_code_1 = ing and flag = 'ing' --we hold
where not exists (select 1 from dev_combo_stage d2 where d.atc_code = d2.atc_code and d.ing = d2.ing and precedence>1) -- we hold, exclude multiple for now
),
excl as (
select * from dev_combo_stage d
join relationship_to_concept on concept_code_1 = ing and flag = 'excl' --we exclude
),
additional as (
select * from dev_combo_stage d
join relationship_to_concept on concept_code_1 = ing and flag = 'with' --we add
)

select distinct r.concept_code as concept_code_1, h. atc_name, drug_concept_id as concept_id, concept_name,concept_class_id
from hold h
join reference r on r.atc_code = h.atc_code
join additional a on h.atc_code=a.atc_code
left join excl e on e.atc_code = h.atc_code 
join rx_combo on i_combo ~ cast(h.concept_id_2 as varchar) and i_combo ~ cast(a.concept_id_2 as varchar) and i_combo like '%-%'
join concept c on c.concept_id = drug_concept_id
where e.atc_name is null
;
--with
drop table if exists atc_to_drug_3;
create table atc_to_drug_3 as
select c.* from compl_combo c
join internal_relationship_stage i on i.concept_code_1=c.concept_code_1
join relationship_to_concept rtc on rtc.concept_code_1 = i.concept_code_2
join concept_relationship cr  on cr.concept_id_1 = c.concept_id
and relationship_id = 'RxNorm has dose form'  and cr.invalid_reason is null
where cr.concept_id_2 = rtc.concept_id_2
and atc_name like '%with%'
;
--inserting everything that goes without a form
insert into atc_to_drug_3
select * from compl_combo
where concept_code_1 not like '% %' and atc_name like '%with%';

--start removing falsly assign combo based on WHO rank

-- zero rank
delete from atc_to_drug_3
where concept_code_1 ~ 'M03BA73|M03BA72|N02AC74' and concept_name ~* 'Salicylamide|Phenazone|Aspirin|Acetaminophen|Dipyrocetyl|Bucetin|Phenacetin|Methadone'
;
--starts the official rank
delete from atc_to_drug_3
where concept_code_1 ~ 'N02BB74' and concept_name ~* 'Salicylamide|Phenazone|Aspirin|Acetaminophen|Dipyrocetyl|Bucetin|Phenacetin'
;
delete from atc_to_drug_3
where concept_code_1 ~ 'N02BA75' and concept_name ~* 'Phenazone|Aspirin|Acetaminophen|Dipyrocetyl|Bucetin|Phenacetin'
;
delete from atc_to_drug_3
where concept_code_1 ~ 'N02BB71' and concept_name ~* 'Aspirin|Acetaminophen|Dipyrocetyl|Bucetin|Phenacetin'
;
delete from atc_to_drug_3
where concept_code_1 ~ 'N02BA71' and concept_name ~* 'Acetaminophen|Dipyrocetyl|Bucetin|Phenacetin'
;
delete from atc_to_drug_3
where concept_code_1 ~ 'N02BE71' and concept_name ~* 'Dipyrocetyl|Bucetin|Phenacetin'
;
delete from  atc_to_drug_3
where concept_code_1 ~ 'N02' and concept_name ~ 'Codeine' and not atc_name ~ 'codeine';

delete from atc_to_drug_3 where  concept_id in --removing duplicates 
(select concept_id from atc_to_drug_1);

--excl
drop table if exists atc_to_drug_4;
create table atc_to_drug_4 as
select c.* from compl_combo c
join internal_relationship_stage i on i.concept_code_1=c.concept_code_1
join relationship_to_concept rtc on rtc.concept_code_1 = i.concept_code_2
join concept_relationship cr  on cr.concept_id_1 = c.concept_id
and relationship_id = 'RxNorm has dose form'  and cr.invalid_reason is null
where cr.concept_id_2 = rtc.concept_id_2
and atc_name not like '%with%'
;
--inserting everything that goes without a form
insert into atc_to_drug_4
select * from compl_combo
where concept_code_1 not like '% %' and atc_name not like '%with%';

-- zero rank
delete from atc_to_drug_4
where concept_code_1 ~ 'M03BA53|M03BA52|N02AC54' and concept_name ~* 'Salicylamide|Phenazone|Aspirin|Acetaminophen|Dipyrocetyl|Bucetin|Phenacetin|Methadone'
;
--starts the official rank
delete from atc_to_drug_4
where concept_code_1 ~ 'N02BB54' and concept_name ~* 'Salicylamide|Phenazone|Aspirin|Acetaminophen|Dipyrocetyl|Bucetin|Phenacetin'
;
delete from atc_to_drug_4
where concept_code_1 ~ 'N02BA55' and concept_name ~* 'Phenazone|Aspirin|Acetaminophen|Dipyrocetyl|Bucetin|Phenacetin'
;
delete from atc_to_drug_4
where concept_code_1 ~ 'N02BB51' and concept_name ~* 'Aspirin|Acetaminophen|Dipyrocetyl|Bucetin|Phenacetin'
;
delete from atc_to_drug_4
where concept_code_1 ~ 'N02BA51' and concept_name ~* 'Acetaminophen|Dipyrocetyl|Bucetin|Phenacetin'
;
delete from atc_to_drug_4
where concept_code_1 ~ 'N02BE51' and concept_name ~* 'Dipyrocetyl|Bucetin|Phenacetin'
;
delete from  atc_to_drug_4
where concept_code_1 ~ 'N02' and concept_name ~ 'Codeine' and not atc_name ~ 'codeine';

delete from atc_to_drug_4 where  concept_id in --removing duplicates 
(select concept_id from atc_to_drug_1);

--atenolol and other diuretics, combinations, one of a kind
delete from atc_to_drug_4
where concept_code_1 ~ 'C07CB53|C07DB01' and concept_name not like '%/%/%';
delete from atc_to_drug_4
where concept_code_1 ~ 'C07CB03' and concept_name  like '%/%/%';

--5th Forms
drop table if exists primary_table;
create table primary_table as
with ing as
(select i.concept_code_1,atc_name,rtc.concept_id_2 as ing from atc_1
left join reference using (atc_code)
join internal_relationship_stage i  on coalesce (concept_code,atc_code) = concept_code_1
join drug_concept_stage d on d.concept_code = concept_code_2 and concept_class_id = 'Ingredient'
join relationship_to_concept rtc on rtc.concept_code_1 = d.concept_code
),
form as
(select i.concept_code_1,rtc.concept_id_2 as form  from atc_1
left join reference using (atc_code)
join internal_relationship_stage i on coalesce (concept_code,atc_code) = concept_code_1
join drug_concept_stage d on d.concept_code = concept_code_2 and concept_class_id = 'Dose Form'
join relationship_to_concept rtc on rtc.concept_code_1 = d.concept_code
)
select distinct i.concept_code_1, atc_name, ing,form
from ing i
left join form f on i.concept_code_1=f.concept_code_1;

drop table if exists atc_to_drug_5;
create table atc_to_drug_5 as
with secondary_table as (
select a.concept_id, a.concept_name ,a.concept_class_id,a.vocabulary_id,c.concept_id_2 as sform, b.ingredient_concept_id as sing 
 from concept a
 join drug_strength b on b.drug_concept_id = a.concept_id
 join concept_relationship c on c.concept_id_1 = a.concept_id
 where a.concept_class_id = 'Clinical Drug Form'
 and a.vocabulary_id = 'RxNorm'--temporary remove RXE
 and a.invalid_reason is null and relationship_id = 'RxNorm has dose form'
 and c.invalid_reason is null
 and not exists (select 1 from drug_strength d where d.drug_concept_id = b.drug_concept_id and d.ingredient_concept_id!=b.ingredient_concept_id) -- excluding combos
)
select distinct p.concept_code_1, atc_name, s.concept_id, s.concept_name, s.concept_class_id 
from primary_table p, secondary_table s
where s.sform = p.form
and s.sing = p.ing
;
--manually excluded drugs based on Precise Ingredients
insert into atc_to_drug_5
select 'B02BD11','catridecacog', concept_id, concept_name, concept_class_id
	from concept where vocabulary_id = 'RxNorm' and concept_name like 'coagulation factor XIII a-subunit (recombinant)%' and standard_concept='S'
or concept_id = 35603348 -- the whole hierarchy
;

insert into atc_to_drug_5
select 'B02BD14','susoctocog alfa', concept_id, concept_name, concept_class_id
from concept where vocabulary_id like 'RxNorm%' and concept_name like 'antihemophilic factor, porcine B-domain truncated recombinant%' and standard_concept='S'
or concept_id in (35603348,44109089) -- the whole hierarchy
;
delete from atc_to_drug_5
where concept_code_1 = 'B02BD14' and concept_name like '%Tretten%' --catridecacog
;

--6th ingredients
drop table if exists atc_to_drug_6;
create table atc_to_drug_6 as
with secondary_table as (
 select a.concept_id, a.concept_name ,a.concept_class_id,a.vocabulary_id, b.ingredient_concept_id as sing 
 from concept a
 join drug_strength b
 on b.drug_concept_id = a.concept_id
 where a.concept_class_id = 'Ingredient' and a.invalid_reason is null
 and a.vocabulary_id = 'RxNorm'--temporary remove RXE
and not exists (select 1 from drug_strength d where d.drug_concept_id = b.drug_concept_id and d.ingredient_concept_id!=b.ingredient_concept_id) -- excluding combos
)
select distinct p.concept_code_1, atc_name, s.concept_id, s.concept_name, s.concept_class_id 
from primary_table p, secondary_table s
where s.sing = p.ing
and p.form is null
and p.concept_code_1 not in (select concept_code from reference where concept_code!=atc_code)-- exclude drugs that should have forms (will remain unmapped)
;
delete from atc_to_drug_6
where atc_name = 'amino acids';
