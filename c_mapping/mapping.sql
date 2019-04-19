-- 01 vocabulary_name

--Mapping source table
DROP TABLE projectname_vocabularyname_source;

CREATE TABLE projectname_vocabularyname_source (
source_code_description varchar(255),
source_code varchar(255),
counts int
) WITH OIDS;

--check if everything uploaded correctly and count of uploaded rows
SELECT *
FROM projectname_vocabularyname_source;


--Mapping result table
DROP TABLE projectname_vocabularyname;

CREATE TABLE projectname_vocabularyname (
source_code_description varchar(255),
source_code varchar(255),
counts int,
to_value varchar(255),
comments varchar(255),
target_concept_id int,
concept_code varchar(255),
concept_name varchar(255),
concept_class_id varchar(255),
standard_concept varchar(255),
invalid_reason varchar(255),
domain_id varchar(255),
target_vocabulary_id varchar(255)
) WITH OIDS;

--check if everything uploaded correctly and count of uploaded rows
SELECT *
FROM projectname_vocabularyname;

--check if any source codes are lost
SELECT *
FROM projectname_vocabularyname_source s
WHERE NOT EXISTS (  SELECT 1
                    FROM projectname_vocabularyname m
                    WHERE s.source_code = m.source_code);

--check if any source codes are modified
SELECT *
FROM projectname_vocabularyname m
WHERE NOT EXISTS (  SELECT 1
                    FROM projectname_vocabularyname_source s
                    WHERE s.source_code = m.source_code);

--check if target concepts exist in the concept table
SELECT *
FROM projectname_vocabularyname j1
WHERE NOT EXISTS (  SELECT *
                    FROM projectname_vocabularyname j2
                    JOIN devv5.concept c
                        ON j2.target_concept_id = c.concept_id
                            AND c.concept_name = j2.concept_name
                            AND c.vocabulary_id = j2.target_vocabulary_id
                            AND c.domain_id = j2.domain_id
                            AND c.standard_concept = 'S'
                            AND c.invalid_reason is NULL
                    WHERE j1.OID = j2.OID
                  );

--1-to-many mapping
SELECT source_code
FROM projectname_vocabularyname
GROUP BY source_code
HAVING count (*) > 1;

--check value ambiguous mapping
with tab as (
    SELECT DISTINCT s.*
    FROM projectname_vocabularyname s
)

SELECT *
FROM tab
WHERE source_code in (
    SELECT source_code
    FROM tab a
    WHERE EXISTS(   SELECT 1
                    FROM tab b
                    WHERE a.source_code = b.source_code AND b.domain_id in ('Observation', 'Measurement') AND (b.to_value != 'to value' OR length(b.to_value) = 0)
                    GROUP BY b.source_code
                    HAVING count (*) > 1
              )

    AND EXISTS(   SELECT 1
                    FROM tab c
                    WHERE a.source_code = c.source_code AND c.to_value in ('to value', 'to_value')
              )

    )
;

--check value without corresponded Observation/Measurement
with tab as (
    SELECT DISTINCT s.*
    FROM projectname_vocabularyname s
)

SELECT *
FROM tab
WHERE source_code in (
    SELECT source_code
    FROM tab a
    WHERE NOT EXISTS(   SELECT 1
                    FROM tab b
                    WHERE a.source_code = b.source_code AND b.domain_id in ('Observation', 'Measurement') AND (b.to_value != 'to value' OR length(b.to_value) = 0)
              )

    AND EXISTS(   SELECT 1
                    FROM tab c
                    WHERE a.source_code = c.source_code AND c.to_value in ('to value', 'to_value')
              )

    )
;

--codes count
SELECT DISTINCT source_code
FROM projectname_vocabularyname;

--codes count diff
SELECT DISTINCT source_code
FROM projectname_vocabularyname

EXCEPT

SELECT DISTINCT source_code
FROM projectname_vocabularyname_source
;


--mapping results
SELECT DISTINCT source_code as source_code,
       '0' as source_concept_id,
       CASE WHEN to_value = 'to value' THEN 'vocabularyname_maps_to_value' WHEN length (to_value) = 0 THEN 'vocabularyname_maps_to' ELSE NULL END as source_vocabulary_id,
       source_code as source_code_description,
       target_concept_id,
       CASE WHEN target_concept_id = 0 THEN 'None' ELSE target_vocabulary_id END as target_vocabulary_id,
       '1970-01-01' as valid_start_date,
       '2099-12-31' as valid_end_date,
       NULL as invalid_reason
FROM projectname_vocabularyname;