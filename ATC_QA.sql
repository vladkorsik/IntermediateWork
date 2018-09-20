
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

