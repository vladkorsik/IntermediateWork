select CURRENT_USER;
show search_path;


--Create_DEV_from_DevV5_DDL
--https://github.com/OHDSI/Vocabulary-v5.0/blob/master/working/Create_DEV_from_DevV5_DDL.sql



--Fast recreate;
--Use this script to recreate main tables (concept, concept_relationship, concept_synonym etc) without dropping your schema
--devv5 - static variable;


--recreate with default settings (copy from devv5, w/o ancestor, deprecated relationships and synonyms (faster)
SELECT devv5.FastRecreateSchema(main_schema_name=>'devv5');

--same as above, but table concept_ancestor is included
SELECT devv5.FastRecreateSchema(main_schema_name=>'devv5', include_concept_ancestor=>true);

--full recreate, all tables are included (much slower)
SELECT devv5.FastRecreateSchema(main_schema_name=>'devv5', include_concept_ancestor=>true, include_deprecated_rels=>true, include_synonyms=>true);

--preserve old concept_ancestor, but it will be ignored if the include_concept_ancestor is set to true
SELECT devv5.FastRecreateSchema(main_schema_name=>'devv5', drop_concept_ancestor=>false);


SELECT devv5.FastRecreateSchema(main_schema_name=>'devv5', include_synonyms=>true);


--GenericUpdate; devv5 - static variable
DO $_$
BEGIN
	PERFORM devv5.GenericUpdate();
END $_$;


--QA checks
select * from QA_TESTS.GET_CHECKS();



--get_summary - changes in tables between dev-schema (current) and devv5/prodv5/any other schema
--supported tables: concept, concept_relationship, concept_ancestor


--first clean cache
select * from qa_tests.purge_cache();


--summary (table to check, schema to compare)
select * from qa_tests.get_summary (table_name=>'concept',pCompareWith=>'devv5');


--summary (table to check, schema to compare)
select * from qa_tests.get_summary (table_name=>'concept_relationship',pCompareWith=>'devv5');

--summary (table to check, schema to compare)
select * from qa_tests.get_summary (table_name=>'concept_ancestor',pCompareWith=>'devv5');




--Statistics QA checks
--changes in tables between dev-schema (current) and devv5/prodv5/any other schema
select * from qa_tests.get_domain_changes(pCompareWith=>'devv5'); --Domain changes
select * from qa_tests.get_newly_concepts(pCompareWith=>'devv5'); --Newly added concepts grouped by vocabulary_id and domain
select * from qa_tests.get_standard_concept_changes(pCompareWith=>'devv5'); --Standard concept changes
select * from qa_tests.get_newly_concepts_standard_concept_status(pCompareWith=>'devv5'); --Newly added concepts and their standard concept status
select * from qa_tests.get_changes_concept_mapping(pCompareWith=>'devv5'); --Changes of concept mapping status grouped by target domain







--check first vacant concept_id for manual change
SELECT MAX (concept_id) + 1 FROM devv5.concept WHERE concept_id >= 31967 AND concept_id < 72245;