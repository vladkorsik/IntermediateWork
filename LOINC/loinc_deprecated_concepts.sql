--Mapping source table creation
--DROP TABLE dev_loinc.loinc_deprecated_concepts_source;

CREATE TABLE dev_loinc.loinc_deprecated_concepts_source WITH OIDS AS
SELECT concept_id as source_concept_id,
       concept_name as source_code_description,
       domain_id as source_domain_id,
       vocabulary_id as source_vocabulary_id,
       concept_class_id as source_concept_class_id,
       standard_concept as source_standard_concept,
       concept_code as source_code,
       valid_start_date source_valid_start_date,
       valid_end_date as source_valid_end_date,
       invalid_reason as source_invalid_reason
FROM devv5.concept c
WHERE c.vocabulary_id = 'LOINC'
    AND c.concept_class_id IN ('Lab Test')
    AND (c.standard_concept = 'S' OR c.standard_concept IS NULL)
    AND c.concept_name NOT LIKE '%HEDIS%'
    AND NOT EXISTS (
        SELECT 1
        FROM devv5.concept_relationship cr
        WHERE c.concept_id = cr.concept_id_1
            AND cr.invalid_reason IS NULL
            AND cr.relationship_id = 'Maps to'
    )
;


--auto-mapping
SELECT *
FROM dev_loinc.loinc_deprecated_concepts_source s
JOIN devv5.concept c
    ON regexp_replace (replace(lower(s.source_code_description), 'deprecated ', ''), ' |/.|/,', '') = regexp_replace(lower(c.concept_name), ' |/.|/,', '')
        AND c.standard_concept = 'S' AND c.vocabulary_id = 'LOINC'
;




--check if everything uploaded correctly and count of uploaded rows
SELECT *
FROM dev_loinc.loinc_deprecated_concepts_source;


--check source_code uniqueness
--if not using several source_vocabularies yet
SELECT DISTINCT source_code
FROM  dev_loinc.loinc_deprecated_concepts_source
GROUP BY source_code
HAVING COUNT(1) > 1;

--Mapping result table creation
--DROP TABLE dev_loinc.loinc_deprecated_concepts;

CREATE TABLE dev_loinc.loinc_deprecated_concepts (
sort int,
source_concept_id int,
source_code_description varchar(255),
source_code varchar(255),
--counts int,
--to_value varchar(255),
comments varchar(255),
target_concept_id int,
target_concept_code varchar(255),
target_concept_name varchar(255),
--target_concept_class_id varchar(255),
--target_standard_concept varchar(255),
--target_invalid_reason varchar(255),
--target_domain_id varchar(255),
target_vocabulary_id varchar(255)
) WITH OIDS;


--check if everything uploaded correctly and count of uploaded rows
SELECT *
FROM dev_loinc.loinc_deprecated_concepts;


--check if any source code/description are lost
SELECT *
FROM dev_loinc.loinc_deprecated_concepts_source s
WHERE NOT EXISTS(SELECT 1
                 FROM dev_loinc.loinc_deprecated_concepts m
                 WHERE s.source_code = m.source_code
                   AND s.source_code_description = m.source_code_description
    );


--check if any source code/description are modified
--when working with custom mapping
SELECT *
FROM dev_loinc.loinc_deprecated_concepts m
WHERE NOT EXISTS(SELECT 1
                 FROM dev_loinc.loinc_deprecated_concepts_source s
                 WHERE s.source_code = m.source_code
                   AND s.source_code_description = m.source_code_description
    );


--check if any source code/description are modified
--when working with mapping of concepts from vocabularies
SELECT devv5.levenshtein(lower(m.source_code_description), lower(c.concept_name)) as name_diff, m.*, c.*
FROM dev_loinc.loinc_deprecated_concepts m
LEFT JOIN devv5.concept c
    ON m.source_concept_id = c.concept_id
WHERE NOT EXISTS(SELECT 1
                 FROM devv5.concept s
                 WHERE s.concept_id = m.source_concept_id
                      AND s.concept_code = m.source_code
                      AND s.concept_name = m.source_code_description
                      AND s.vocabulary_id = '' --vocabulary to be specified
    );



--Check if everything above the threshold is mapped
--Threshold: 0
SELECT s.source_code, s.source_code_description, s.counts, m.target_concept_id
FROM dev_loinc.loinc_deprecated_concepts_source s
LEFT JOIN dev_loinc.loinc_deprecated_concepts m
    ON m.source_code = s.source_code
WHERE s.counts >= 0 --add threshold here
AND m.target_concept_id IS NULL
;


--check if target concepts exist in the concept table
SELECT *
FROM dev_loinc.loinc_deprecated_concepts j1
WHERE NOT EXISTS (  SELECT *
                    FROM dev_loinc.loinc_deprecated_concepts j2
                    JOIN devv5.concept c
                        ON j2.target_concept_id = c.concept_id
                            AND replace (lower(c.concept_name), ' ', '') = replace (lower(j2.target_concept_name), ' ', '')
                            AND c.vocabulary_id = j2.target_vocabulary_id
                            AND c.domain_id = j2.target_domain_id
                            AND c.standard_concept = 'S'
                            AND c.invalid_reason is NULL
                    WHERE j1.OID = j2.OID
                  );


--'Maps to' mapping to abnormal domains/classes
with tab as (
    SELECT DISTINCT s.*
    FROM dev_loinc.loinc_deprecated_concepts s
)

SELECT *
FROM tab
WHERE source_code in (
    SELECT source_code
    FROM tab a
    WHERE EXISTS(   SELECT 1
                    FROM tab b
                    WHERE a.source_code = b.source_code
                        AND b.target_domain_id not in ('Observation', 'Procedure', 'Condition', 'Drug', 'Measurement')--, 'Device') --add Device if needed
                        AND (b.to_value !~* 'value' OR length(b.to_value) = 0 OR b.to_value IS NULL) --just exclude this line from script if 'to_value' field is not used
                )
    OR
          EXISTS(   SELECT 1
                    FROM tab bb
                    WHERE a.source_code = bb.source_code
                        AND bb.target_concept_class_id IN ('Organism', 'Attribute', 'Answer', 'Qualifier Value')
                        AND (bb.to_value !~* 'value' OR length(bb.to_value) = 0 OR bb.to_value IS NULL) --just exclude this line from script if 'to_value' field is not used
                )
    )
;


--check value ambiguous mapping (2 Observation/Measurement for 1 value)
with tab as (
    SELECT DISTINCT s.*
    FROM dev_loinc.loinc_deprecated_concepts s
)

SELECT *
FROM tab t
LEFT JOIN devv5.concept c
    ON t.target_concept_id = c.concept_id

WHERE source_code in (
    SELECT source_code
    FROM tab a
    WHERE EXISTS(   SELECT 1
                    FROM tab b
                    WHERE a.source_code = b.source_code
                      AND b.target_domain_id in ('Observation', 'Measurement')
                      AND (b.to_value !~* 'value' OR length(b.to_value) = 0 OR b.to_value IS NULL)
                    GROUP BY b.source_code
                    HAVING count (*) > 1
              )

    AND EXISTS(   SELECT 1
                    FROM tab bb
                    WHERE a.source_code = bb.source_code
                      AND bb.to_value ~* 'value'
            )
              )
ORDER BY source_code
;


--check value ambiguous mapping (2 values for 1 Observation/Measurement)
with tab as (
    SELECT DISTINCT s.*
    FROM dev_loinc.loinc_deprecated_concepts s
)

SELECT *
FROM tab
WHERE source_code in (
    SELECT source_code
    FROM tab a
    WHERE EXISTS(   SELECT 1
                    FROM tab b
                    WHERE a.source_code = b.source_code
                      AND b.target_domain_id in ('Observation', 'Measurement')
                      AND (b.to_value !~* 'value' OR length(b.to_value) = 0 OR b.to_value IS NULL)
              )

    AND EXISTS(   SELECT 1
                    FROM tab bb
                    WHERE a.source_code = bb.source_code
                      AND bb.to_value ~* 'value'
                    GROUP BY bb.source_code
                    HAVING count (*) > 1
            )
              )
ORDER BY source_code
;


--check value without corresponded Observation/Measurement
with tab as (
    SELECT DISTINCT s.*
    FROM dev_loinc.loinc_deprecated_concepts s
)

SELECT *
FROM tab
WHERE source_code in (
    SELECT source_code
    FROM tab a
    WHERE NOT EXISTS(   SELECT 1
                    FROM tab b
                    WHERE a.source_code = b.source_code
                      AND b.target_domain_id in ('Observation', 'Measurement')
                      AND (b.to_value !~* 'value' OR length(b.to_value) = 0 OR length(b.to_value) IS NULL)
              )

    AND EXISTS(   SELECT 1
                    FROM tab bb
                    WHERE a.source_code = bb.source_code AND bb.to_value ~* 'value'
            )
              )
;


--Check 'History of' concepts without to value
--EXCLUDE target_concept_id THAT NOT NEEDED
with tab as (
    SELECT DISTINCT s.*
    FROM dev_loinc.loinc_deprecated_concepts s
)

SELECT *
FROM tab
WHERE source_code in (
    SELECT source_code
    FROM tab a
    WHERE EXISTS(   SELECT 1
                    FROM tab b
                    WHERE a.source_code = b.source_code AND b.target_concept_id IN(4215685 --Past history of procedure
                                                                                   ,4214956 --History of clinical finding in subject
                                                                                   ,4195979 --H/O: Disorder
                                                                                   ,4210989 --Family history with explicit context
                                                                                   ,4167217 --Family history of clinical finding
                                                                                   ,4175586 --Family history of procedure
                                                                                   ,4236282 --Family history unknown
                                                                                   ,4051104 --No family history of
                                                                                   ,4219847 --Disease suspected
                                                                                   ,4199812 --Disorder excluded
                                                                                   ,40481925 --No history of clinical finding in subject
                                                                                   ,4022772 --Condition severity
                                                                                    )
        )

    AND NOT EXISTS( SELECT 1
                    FROM tab c
                    WHERE a.source_code = c.source_code AND c.to_value ~* 'value')
        )
;


-- Check maps_to/maps_to_value vocabularies consistency
with tab as (
    SELECT DISTINCT s.*
    FROM dev_loinc.loinc_deprecated_concepts s
)

SELECT *
FROM tab
WHERE source_code in (
    SELECT source_code
    FROM tab a
    WHERE EXISTS(SELECT 1
                 FROM tab b
                 WHERE a.source_code = b.source_code AND a.target_vocabulary_id != b.target_vocabulary_id
              )

    AND EXISTS( SELECT 1
                    FROM tab c
                    WHERE a.source_code = c.source_code AND c.to_value ~* 'value'
            )
        )
ORDER BY source_code, to_value -- add/replace source_code to source_code_description if needed
;


--1-to-many mapping
with tab as (
    SELECT DISTINCT s.*
    FROM dev_loinc.loinc_deprecated_concepts s
)

SELECT *
FROM tab
WHERE source_code in (

    SELECT source_code
    FROM tab
    GROUP BY source_code
    HAVING count (*) > 1)
ORDER BY source_code
;


--1 maps_to mapping and 1 maps_to_value/unit/modifier/qualifier mapping
WITH tab AS (
    SELECT DISTINCT s.*
    FROM dev_loinc.loinc_deprecated_concepts s
)

SELECT *
FROM tab t
WHERE source_code in (
        SELECT source_code
        FROM tab
        GROUP BY source_code
        HAVING count(*) = 2
)
    AND EXISTS(SELECT 1
               FROM tab b
               WHERE t.source_code = b.source_code
                 AND b.to_value ~* 'value|modifier|qualifier|unit')
ORDER BY source_code, to_value
;


--all other 1-to-many mappings
with tab as (
    SELECT DISTINCT s.*
    FROM dev_loinc.loinc_deprecated_concepts s
)

SELECT *
FROM tab
WHERE source_code IN (
    SELECT source_code
    FROM tab
    GROUP BY source_code
    HAVING count(*) > 1)

    AND source_code NOT IN (
        SELECT source_code
        FROM tab t
        WHERE source_code in (
                SELECT source_code
                FROM tab
                GROUP BY source_code
                HAVING count(*) = 2
        )
            AND EXISTS(SELECT 1
                       FROM tab b
                       WHERE t.source_code = b.source_code
                         AND b.to_value ~* 'value|modifier|qualifier|unit')
    )
ORDER BY source_code, to_value
;


--check key terms lose
WITH tab AS (
    SELECT DISTINCT s.*
    FROM dev_loinc.loinc_deprecated_concepts s
)
SELECT *
FROM tab a
WHERE source_code ~* 'acute|chronic|recurrent' --choose key terms
  AND NOT EXISTS(SELECT 1
                 FROM tab b
                 WHERE a.source_code = b.source_code
                   AND b.target_concept_name ~* 'acute|chronic|recurrent') --choose same key terms
  --AND target_concept_id != 0 --add if needed
ORDER BY source_code;


--detect duplicates record located far away from each other in the csv file
--Option A (Oleg's)
WITH
ordered_source AS (
    SELECT s.*
    FROM dev_loinc.loinc_deprecated_concepts s
    ORDER BY s.sort
),

numbered_source AS (
    SELECT s.*, row_number() OVER () AS row_num
    FROM ordered_source s
    ),

source_code_counts AS (
    SELECT source_code,
           count(source_code) AS counts
    FROM numbered_source
    GROUP BY source_code
    ),

result AS (
    SELECT ns1.source_code,
           (max(ns2.row_num)) AS init_sum,
           (min(ns2.row_num) + scc.counts - 1) AS second_sum,
           CASE WHEN (max(ns2.row_num)) != (min(ns2.row_num) + scc.counts - 1) THEN 1 ELSE 0 END AS flag

    FROM numbered_source ns1

    JOIN numbered_source ns2
        ON ns1.source_code = ns2.source_code

    JOIN source_code_counts scc
        ON ns1.source_code = scc.source_code

    GROUP BY ns1.source_code, scc.counts
    )

SELECT source_code FROM result
WHERE flag = 1
;


--Option B (Artem's)
WITH tab AS (
    WITH tb AS (
        WITH t AS (
                WITH t0 AS (
                SELECT source_code, source_code_description, target_concept_id
                FROM dev_loinc.loinc_deprecated_concepts
                ORDER BY sort
                )
        SELECT source_code, source_code_description, target_concept_id, ROW_NUMBER() OVER () AS r_num
        FROM t0
            )
    SELECT *, ROW_number() OVER (PARTITION BY source_code ORDER BY r_num) AS group_row
    FROM t
        )
SELECT *,
max(r_num) OVER (PARTITION BY source_code)     AS max_row,
min(r_num) OVER (PARTITION BY source_code)     AS min_row,
max(group_row) OVER (PARTITION BY source_code) AS max_in_group,
min(group_row) OVER (PARTITION BY source_code) AS min_in_group
FROM tb t
    )

SELECT DISTINCT source_code
FROM tab
WHERE max_in_group - min_in_group <> max_row - min_row
  AND source_code IS NOT NULL
;

--codes count
SELECT DISTINCT source_code
FROM dev_loinc.loinc_deprecated_concepts;


--codes count diff
SELECT DISTINCT source_code
FROM dev_loinc.loinc_deprecated_concepts

EXCEPT

SELECT DISTINCT source_code
FROM dev_loinc.loinc_deprecated_concepts_source
;


--Problem vocabs: stats
SELECT source_vocabulary_id, target_vocabulary_id, error_code, count(1) AS affected_concepts FROM (
SELECT source_concept_id, m.concept_code, source_code_description, source_vocabulary_id, c.vocabulary_id AS target_vocabulary_id, c.concept_id,
       CASE WHEN c.vocabulary_id IN ('ATC', 'CIEL', 'Currency', 'DPD', 'GGR', 'MeSH', 'GCN_SEQNO', 'ICD9CM',
                                    'KCD7', 'MEDRT', 'Multum', 'NDFRT', 'OSM', 'Read', 'Revenue Code', 'OXMIS', 'SMQ', 'PCORNet',
                                    'SPL', 'UB04 Point of Origin', 'UB04 Pt dis status', 'US Census', 'VA Class', 'VA Product', 'UB04 Pri Typ of Adm',
                                    'ICD10', 'ICD10CM', 'Cohort', 'EphMRA ATC', 'NFC', 'CDM', 'Metadata', 'Relationship', 'Vocabulary',
                                    'Death Type', 'Cost Type', 'Obs Period Type', 'Meas Type', 'Visit Type', 'Specimen Type', 'Condition Type', 'Drug Type',
                                    'Episode Type', 'Procedure Type', 'Note Type', 'Observation Type', 'Device Type', 'Concept Class', 'Domain') THEN 'Never used'

            WHEN c.vocabulary_id IN ('HemOnc', 'NAACCR', 'OPCS4', 'PPI', 'HCPCS', 'ICD10PCS', 'ICD9Proc', 'dm+d', 'APC', 'SNOMED Veterinary', 'DRG', 'JMDC', 'NDC', 'AMT', 'MMI', 'BDPM', 'MDC') THEN 'Not commonly used'

            WHEN c.vocabulary_id IN ('PHDSC', 'CMS Place of Service', 'Plan', 'Ethnicity', 'Episode', 'ABMS', 'HES Specialty', 'Cost', 'Visit', 'UCUM',
                                     'Sponsor', 'Plan Stop Reason', 'Medicare Specialty', 'Race', 'Provider',  'Gender', 'NUCC', 'Supplier', 'UB04 Typ bill') THEN 'Used ONLY in certain types of mapping'

            WHEN c.vocabulary_id IN ('CDT', 'DA_France', 'ETC', 'GPI', 'GRR', 'Indication', 'LPD_Australia', 'LPD_Belgium',
                                    'SUS', 'Multilex', 'Gemscript', 'ISBT', 'ISBT Attribute', 'KDC') THEN 'License required'

            WHEN c.vocabulary_id IN ('CPT4', 'MedDRA') THEN 'EULA required'

            WHEN c.vocabulary_id IN ('None') THEN 'Mapped to 0'

            WHEN c.vocabulary_id IN ('CCS', 'AMIS', 'EU Product') THEN 'Currently not available' END AS error_code

FROM dev_loinc.loinc_deprecated_concepts m
JOIN devv5.concept c
ON c.concept_id = m.target_concept_id) a
WHERE error_code IS NOT NULL
GROUP BY source_vocabulary_id, error_code, target_vocabulary_id
ORDER BY error_code, a.target_vocabulary_id, source_vocabulary_id
;

--Problem vocabs: mapping list
SELECT a.source_concept_id,
       a.concept_code,
       a.source_code_description,
       a.source_vocabulary_id,
       a.relationship_id,
       error_code,
       a.concept_id,
       COALESCE(c2.concept_name, mm.source_code_description) as concept_name,
       COALESCE(c2.concept_code, mm.concept_code) as concept_code,
       COALESCE(c2.concept_class_id, mm.source_concept_class_id) as concept_class_id,
       COALESCE(c2.domain_id, mm.source_domain_id) as domain_id,
       COALESCE(c2.standard_concept, mm.standard_concept) as standard_concept,
       COALESCE(c2.invalid_reason, mm.invalid_reason) as invalid_reason,
       COALESCE(c2.vocabulary_id, mm.source_vocabulary_id) as vocabulary_id
    FROM (
    SELECT source_concept_id, m.concept_code, source_code_description, source_vocabulary_id, c.vocabulary_id, c.concept_id, m.relationship_id, m.source_concept_class_id,
       CASE WHEN c.vocabulary_id IN ('ATC', 'CIEL', 'Currency', 'DPD', 'GGR', 'MeSH', 'GCN_SEQNO', 'ICD9CM',
                                    'KCD7', 'MEDRT', 'Multum', 'NDFRT', 'OSM', 'Read', 'Revenue Code', 'OXMIS', 'SMQ', 'PCORNet',
                                    'SPL', 'UB04 Point of Origin', 'UB04 Pt dis status', 'US Census', 'VA Class', 'VA Product', 'UB04 Pri Typ of Adm',
                                    'ICD10', 'ICD10CM', 'Cohort', 'EphMRA ATC', 'NFC', 'CDM', 'Metadata', 'Relationship', 'Vocabulary',
                                    'Death Type', 'Cost Type', 'Obs Period Type', 'Meas Type', 'Visit Type', 'Specimen Type', 'Condition Type', 'Drug Type',
                                    'Episode Type', 'Procedure Type', 'Note Type', 'Observation Type', 'Device Type', 'Concept Class', 'Domain') THEN 'Never used'

            WHEN c.vocabulary_id IN ('HemOnc', 'NAACCR', 'OPCS4', 'PPI', 'HCPCS', 'ICD10PCS', 'ICD9Proc', 'dm+d', 'APC', 'SNOMED Veterinary', 'DRG', 'JMDC', 'NDC', 'AMT', 'MMI', 'BDPM', 'MDC') THEN 'Not commonly used'

            WHEN c.vocabulary_id IN ('PHDSC', 'CMS Place of Service', 'Plan', 'Ethnicity', 'Episode', 'ABMS', 'HES Specialty', 'Cost', 'Visit', 'UCUM',
                                     'Sponsor', 'Plan Stop Reason', 'Medicare Specialty', 'Race', 'Provider',  'Gender', 'NUCC', 'Supplier', 'UB04 Typ bill') THEN 'Used ONLY in certain types of mapping'

            WHEN c.vocabulary_id IN ('CDT', 'DA_France', 'ETC', 'GPI', 'GRR', 'Indication', 'LPD_Australia', 'LPD_Belgium',
                                    'SUS', 'Multilex', 'Gemscript', 'ISBT', 'ISBT Attribute', 'KDC') THEN 'License required'

            WHEN c.vocabulary_id IN ('CPT4', 'MedDRA') THEN 'EULA required'

            WHEN c.vocabulary_id IN ('None') THEN 'Mapped to 0'

            WHEN c.vocabulary_id IN ('CCS', 'AMIS', 'EU Product') THEN 'Currently not available' END AS error_code

    FROM dev_loinc.loinc_deprecated_concepts m
    JOIN devv5.concept c
    ON c.concept_id = m.target_concept_id) a
LEFT JOIN devv5.concept c2
    ON a.concept_id = c2.concept_id
LEFT JOIN dev_loinc.loinc_deprecated_concepts mm
    ON a.concept_id = mm.source_concept_id
WHERE error_code IS NOT NULL
ORDER BY a.error_code, a.source_vocabulary_id, a.source_concept_id
;