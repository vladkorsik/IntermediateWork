DO $external_do_tag$
BEGIN

        --some queries (except SELECT)
        DROP TABLE IF EXISTS addd;
        CREATE TABLE addd as SELECT 111;
        INSERT INTO addd SELECT 222;

        --DO inside DO
        DO $internal_do_tag$ --should NOT match DO tag of another level
        BEGIN
            --some other queries (except SELECT)
            DROP TABLE IF EXISTS addd2;
            CREATE TABLE addd2 as SELECT 333;
            INSERT INTO addd2 SELECT 444;
        END $internal_do_tag$;

        --DO with FUNCTION inside DO
        DO $_$ --tags on single level may be non-unique (see below)
        BEGIN
            PERFORM vocabulary_pack.AddNewConcept(
                  pConcept_name     =>'123',
                  pDomain_id        =>'Drug',
                  pVocabulary_id    =>'RxNorm Extension',
                  pConcept_class_id =>'Ingredient',
                  pStandard_concept =>'S',
                  pConcept_code     =>'OMOP2'
            );
        END $_$;

        --another DO with FUNCTION inside DO
        DO $_$ --tags on single level may be non-unique (see above)
        BEGIN
            PERFORM vocabulary_pack.AddNewConcept(
                  pConcept_name     =>'124',
                  pDomain_id        =>'Drug',
                  pVocabulary_id    =>'RxNorm Extension',
                  pConcept_class_id =>'Ingredient',
                  pStandard_concept =>'S',
                  pConcept_code     =>'OMOP3'
            );
        END $_$;

END $external_do_tag$
;




SELECT * FROM addd;
SELECT * FROM addd2;
DROP TABLE addd;
DROP TABLE addd2;

SELECT *
FROM concept
WHERE concept_code IN ('OMOP1', 'OMOP2', 'OMOP3');

DELETE FROM concept
WHERE concept_code IN ('OMOP1', 'OMOP2', 'OMOP3');

DELETE
FROM concept_relationship
WHERE concept_id_2 IN (32695, 32696, 32697);

DELETE
FROM concept_synonym
WHERE concept_id IN (32695, 32696, 32697);