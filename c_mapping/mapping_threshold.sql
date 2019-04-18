--TODO: Use alias for table names

--STEP 1: Creating source table
create table tab_conditions_for_custom_mapping
(
  count int,
  code int,
  name varchar(500)
);

--3085
--Total number of rows
--Junk codes removed by hand
select count(*) from tab_conditions_for_custom_mapping
where code not in ('16157', '15007', '18817', '17340', '16931', '16587', '17336', '15313', '15038');

--105787
--Total number of counts excluding junk codes
--Junk codes removed by hand
select SUM(count) from tab_conditions_for_custom_mapping
where code not in ('16157', '15007', '18817', '17340', '16931', '16587', '17336', '15313', '15038');



--STEP 2: Mapping to concepts including synonyms

--You can edit preferred domains

create table tab_conditions_mapped as (
--334 rows
--Join with concept
select con.code, con.name, con.count, c.concept_id, c.concept_name
from tab_conditions_for_custom_mapping con
join devv5.concept c
         on con.name = c.concept_name
where c.standard_concept = 'S'

  and c.domain_id in ('Condition', 'Observation')     --HERE

union all
--39 rows
--Join with synonyms
select a.code, a.name, a.count, co.concept_id, co.concept_name
from  (select code, name, count
       from tab_conditions_for_custom_mapping con
left join devv5.concept c
on con.name = c.concept_name

         and c.domain_id in ('Condition', 'Observation')     --HERE

where c.concept_code is null) as a
join devv5.concept_synonym c
on a.name = c.concept_synonym_name
join devv5.concept co
on c.concept_id = co.concept_id
where co.standard_concept = 'S'

and co.domain_id in ('Condition', 'Observation'))     --HERE
;

--Concepts that should be mapped manually
create table tab_conditions_not_mapped as (
select * from tab_conditions_for_custom_mapping
where code not in (
    select code from tab_conditions_mapped
    )
and code not in ('16157', '15007', '18817', '17340', '16931', '16587', '17336', '15313', '15038'));
;

--3006
select SUM(count) from tab_conditions_mapped;


--STEP 3: Calculating numbers
SELECT count(code)+373 as mapped_codes, 1 as full_covered_count_of_records, 100.0 as percent_covered from tab_conditions_not_mapped
union all
SELECT count(code) as mapped_codes, 0 as full_covered_count_of_records, round((SUM(count)*100.0/105787), 2) as percent_covered from tab_conditions_mapped
union all
SELECT count(code)+373 as mapped_codes, 100 as full_covered_count_of_records, round(((SUM(count)+3006)*100.0/105787), 1) as percent_covered from tab_conditions_not_mapped
where count >= 100
union all
SELECT count(code)+373 as mapped_codes, 20 as full_covered_count_of_records, round(((SUM(count)+3006)*100.0/105787), 1) as percent_covered from tab_conditions_not_mapped
where count >= 20
union all
SELECT count(code)+373 as mapped_codes, 10 as full_covered_count_of_records, round(((SUM(count)+3006)*100.0/105787), 1) as percent_covered from tab_conditions_not_mapped
where count >= 10
union all
SELECT count(code)+373 as mapped_codes, 5 as full_covered_count_of_records, round(((SUM(count)+3006)*100.0/105787), 1) as percent_covered from tab_conditions_not_mapped
where count >= 5
union all
SELECT count(code)+373 as mapped_codes, 3 as full_covered_count_of_records, round(((SUM(count)+3006)*100.0/105787), 1) as percent_covered from tab_conditions_not_mapped
where count >= 3
union all
SELECT count(code)+373 as mapped_codes, 2 as full_covered_count_of_records, round(((SUM(count)+3006)*100.0/105787), 1) as percent_covered from tab_conditions_not_mapped
where count >= 2
order by percent_covered asc;


DROP TABLE tab_conditions_mapped;
DROP TABLE tab_conditions_not_mapped;
