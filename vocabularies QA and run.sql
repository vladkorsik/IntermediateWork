select CURRENT_USER;
show search_path;


--Create_DEV_from_DevV5_DDL
--https://github.com/OHDSI/Vocabulary-v5.0/blob/master/working/Create_DEV_from_DevV5_DDL.sql



--Fast recreate
--Use this script to recreate main tables (concept, concept_relationship, concept_synonym etc) without dropping your schema
--devv5 - static variable;

--recreate with default settings (copy from devv5, w/o ancestor, deprecated relationships and synonyms (faster)
--SELECT devv5.FastRecreateSchema(main_schema_name=>'devv5');

--same as above, but table concept_ancestor is included
--SELECT devv5.FastRecreateSchema(main_schema_name=>'devv5', include_concept_ancestor=>true);

--full recreate, all tables are included (much slower)
SELECT devv5.FastRecreateSchema(main_schema_name=>'devv5', include_concept_ancestor=>true, include_deprecated_rels=>true, include_synonyms=>true);

--preserve old concept_ancestor, but it will be ignored if the include_concept_ancestor is set to true
--SELECT devv5.FastRecreateSchema(main_schema_name=>'devv5', drop_concept_ancestor=>false);

--SELECT devv5.FastRecreateSchema(main_schema_name=>'devv5', include_synonyms=>true);



--DRUG input tables checks
--Errors
--RUN https://github.com/OHDSI/Vocabulary-v5.0/blob/master/working/input_QA_integratable_E.sql --All queries should retrieve NULL

--Warnings
--RUN https://github.com/OHDSI/Vocabulary-v5.0/blob/master/working/input_QA_integratable_W.sql --All non-NULL results should be reviewed

--Old checks
--RUN all queries from Vocabulary-v5.0/working/drug_stage_tables_QA.sql --All queries should retrieve NULL
--RUN all queries from Vocabulary-v5.0/working/Drug_stage_QA_optional.sql --All queries should retrieve NULL, but see comment inside



--stage tables checks
DO $_$
BEGIN
	PERFORM qa_tests.check_stage_tables ();
END $_$;



--GenericUpdate; devv5 - static variable
DO $_$
BEGIN
	PERFORM devv5.GenericUpdate();
END $_$;



--Basic tables checks
--RUN all queries from Vocabulary-v5.0/working/CreateNewVocabulary_QA.sql --All queries should retrieve NULL



--DRUG basic tables checks
--RUN all queries from Vocabulary-v5.working/Basic_tables_QA.sql --All queries should retrieve NULL



--QA checks
--should retrieve NULL
select * from QA_TESTS.GET_CHECKS();



--Manual checks after generic
--RUN and review the results: https://github.com/OHDSI/Vocabulary-v5.0/blob/master/working/manual_checks_after_generic.sql


--Vocabulary-specific manual checks can be found in the manual_work directory in each vocabulary


--manual ConceptAncestor (needed vocabularies are to be specified)
/* DO $_$
 BEGIN
    PERFORM VOCABULARY_PACK.pManualConceptAncestor(
    pVocabularies => 'SNOMED,LOINC'
 );
 END $_$;*/




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