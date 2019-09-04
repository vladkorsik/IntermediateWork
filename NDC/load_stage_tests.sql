--check mappings to be dropped
SELECT crs.concept_code_1, c.concept_name, crs.concept_code_2, cc.concept_name
FROM concept_relationship_stage crs

LEFT JOIN devv5.concept c
    ON crs.concept_code_1 = c.concept_code AND c.vocabulary_id = 'NDC'

LEFT JOIN devv5.concept cc
    ON crs.concept_code_2 = cc.concept_code AND cc.vocabulary_id like 'RxNorm%'



WHERE crs.invalid_reason IS NULL
AND
concept_code_1 IN (SELECT r.concept_code_1
FROM concept_relationship_stage r
WHERE r.relationship_id = 'Maps to'
	AND r.invalid_reason IS NULL
	AND r.vocabulary_id_1 = 'NDC'
	AND r.vocabulary_id_2 = 'RxNorm'
	AND concept_code_1 IN (
		--get all duplicate NDC mappings to packs
		SELECT concept_code_1
		FROM concept_relationship_stage r_int
		WHERE r_int.relationship_id = 'Maps to'
			AND r_int.invalid_reason IS NULL
			AND r_int.vocabulary_id_1 = 'NDC'
			AND r_int.vocabulary_id_2 = 'RxNorm'
		GROUP BY concept_code_1
		HAVING count(*) > 1
		)
	AND concept_code_2 NOT IN (
		--exclude 'true' mappings [Branded->Clinical]
		SELECT c_int.concept_code
		FROM concept_relationship_stage r_int,
			concept c_int
		WHERE r_int.relationship_id = 'Maps to'
			AND r_int.invalid_reason IS NULL
			AND r_int.vocabulary_id_1 = r.vocabulary_id_1
			AND r_int.vocabulary_id_2 = r.vocabulary_id_2
			AND c_int.concept_code = r_int.concept_code_2
			AND c_int.vocabulary_id = r_int.vocabulary_id_2
			AND r_int.concept_code_1 = r.concept_code_1
		ORDER BY c_int.invalid_reason NULLS FIRST,
			CASE c_int.concept_class_id
				WHEN 'Branded Pack'
					THEN 1
				WHEN 'Clinical Pack'
					THEN 2
				WHEN 'Quant Branded Drug'
					THEN 3
				WHEN 'Quant Clinical Drug'
					THEN 4
				WHEN 'Branded Drug'
					THEN 5
				WHEN 'Clinical Drug'
					THEN 6
				ELSE 7
				END,
			c_int.valid_start_date DESC,
			c_int.concept_id
			LIMIT 1
		))

;


--searching of 1-to-many mappings
--Check mapping added to cr_stage
with tab as (
    SELECT DISTINCT s.*
    FROM dalex.NDC_manual_mapped s
)


SELECT *, c.concept_name, c.concept_class_id
FROM dev_ndc.concept_relationship_stage crs

LEFT JOIN devv5.concept c
    ON c.concept_id = crs.concept_id_2



WHERE crs.concept_code_1 in (
        SELECT source_concept_code
        FROM tab
        GROUP BY source_concept_code
        HAVING count(*) > 1)

AND NOT exists (select 1 from devv5.concept_relationship crr where crr.concept_id_1 = crs.concept_id_1 and crr.relationship_id = 'Maps to' and crr.invalid_reason is null)
;


--searching of 1-to-many mappings
--Check mapping added to cr
with tab as (
    SELECT DISTINCT s.*
    FROM dalex.NDC_manual_mapped s
)


SELECT *, c.concept_name, c.concept_class_id
FROM dev_ndc.concept_relationship cr

LEFT JOIN devv5.concept c
    ON c.concept_id = cr.concept_id_2



WHERE cr.concept_id_1 in (
        SELECT source_concept_id
        FROM tab
        GROUP BY source_concept_id
        HAVING count(*) = 1)

AND NOT exists (select 1 from devv5.concept_relationship crr where crr.concept_id_1 = cr.concept_id_1 and crr.relationship_id = 'Maps to' and crr.invalid_reason is null)
;










SELECT *
FROM prodv5.concept_relationship
WHERE concept_id_1 = 45359210;

SELECT *
FROM prodv5ё.concept
WHERE concept_id IN (
19037485,
19078242,
40220493

    )
;




SELECT *
FROM devv5.concept_relationship
WHERE concept_id_1 = 45359210;


SELECT *
FROM devv5.concept
WHERE concept_id IN (
19037485,
19078242,
40220493

    )
;





SELECT *
FROM devv5.concept_relationship
WHERE concept_id_1 = 45222514
;

SELECT *
FROM prodv5.concept_relationship
WHERE concept_id_1 = 45222514
;


CREATE TABLE dev_ndc.concept_relationship_old AS
    (SELECT *
     FROM dev_ndc.concept_relationship)
;





SELECT *
FROM dev_ndc.concept_relationship_old

EXCEPT

SELECT *
FROM dev_ndc.concept_relationship


