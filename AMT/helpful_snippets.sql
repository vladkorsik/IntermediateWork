--get all units suitable for to be mapped to
WITH tab AS (
            SELECT DISTINCT amount_unit_concept_id AS unit_id
            FROM drug_strength
            UNION
            SELECT DISTINCT numerator_unit_concept_id AS unit_id
            FROM drug_strength
            UNION
            SELECT DISTINCT denominator_unit_concept_id AS unit_id
            FROM drug_strength
            )
SELECT t.UNIT_ID, c.concept_name, c.concept_code, c.vocabulary_id
FROM tab t
JOIN concept c
    ON t.unit_id = c.concept_id
WHERE t.unit_id IS NOT NULL;

------------------------get suppliers with relations
SELECT DISTINCT dcs4.concept_name
                --dcs2.concept_name, dcs2.concept_code, dcs4.concept_name, dcs4.concept_code, dcs4.concept_class_id
FROM dev_amt.drug_concept_stage dcs1
JOIN dev_amt.internal_relationship_stage irs
    ON dcs1.concept_code = irs.concept_code_2
JOIN dev_amt.drug_concept_stage dcs2
    ON irs.concept_code_1 = dcs2.concept_code AND dcs2.concept_class_id = 'Drug Product'
LEFT JOIN dev_amt.internal_relationship_stage irs2
    ON dcs2.concept_code = irs2.concept_code_1
LEFT JOIN dev_amt.drug_concept_stage dcs4
    ON irs2.concept_code_2 = dcs4.concept_code

WHERE dcs1.concept_code IN (
                           SELECT dcs3.concept_code
                           FROM dev_amt.drug_concept_stage dcs3
                           WHERE dcs3.concept_class_id IN ('Dose Form', 'Supplier', 'Brand Name', 'Unit', 'Ingredient')
                           )
  AND dcs4.concept_class_id = 'Supplier'
-- ORDER BY dcs2.concept_name
;


--using attribute name find all drugs and all their existing attributes (set dcs3.concept_name)
SELECT dcs2.concept_name, dcs2.concept_code, dcs4.concept_name, dcs4.concept_code, dcs4.concept_class_id
FROM dev_amt.drug_concept_stage dcs1
JOIN dev_amt.internal_relationship_stage irs
    ON dcs1.concept_code = irs.concept_code_2
JOIN dev_amt.drug_concept_stage dcs2
    ON irs.concept_code_1 = dcs2.concept_code AND dcs2.concept_class_id = 'Drug Product'
LEFT JOIN dev_amt.internal_relationship_stage irs2
    ON dcs2.concept_code = irs2.concept_code_1
LEFT JOIN dev_amt.drug_concept_stage dcs4
    ON irs2.concept_code_2 = dcs4.concept_code
WHERE dcs1.concept_code IN (
                           SELECT dcs3.concept_code
                           FROM dev_amt.drug_concept_stage dcs3
                           WHERE dcs3.concept_name = 'Tomato Extract'
                             AND dcs3.concept_class_id IN ('Dose Form', 'Supplier', 'Brand Name', 'Unit', 'Ingredient')
                           )
ORDER BY dcs2.concept_name
;



--Using unit name find all source drugs for this unit as well as value and full concept_name (set u.concept_name)
SELECT str_ref.value, sn.concept_name, dcs.*
FROM concept_stage_sn sn
JOIN sources.amt_rf2_ss_strength_refset str_ref
    ON sn.concept_code = str_ref.unitid::text
JOIN sources.amt_rf2_full_relationships fr
    ON str_ref.referencedcomponentid = fr.id
JOIN drug_concept_stage dcs
    ON fr.sourceid::text = dcs.concept_code
WHERE sn.concept_code IN (
                         SELECT u.unitid::text
                         FROM unit u
                         WHERE u.concept_name ILIKE '%%'
                         )
  AND dcs.concept_name ILIKE '%glycerol%';



--Using drug concept code find its units
WITH drug_code AS (
                  SELECT '1425271000168104'
                  )
SELECT str_ref.value, dcs2.concept_name, sn.concept_name, dcs.*
FROM drug_concept_stage dcs
JOIN sources.amt_rf2_full_relationships fr
    ON fr.sourceid::text = dcs.concept_code
JOIN sources.amt_rf2_ss_strength_refset str_ref
    ON fr.id = str_ref.referencedcomponentid
JOIN concept_stage_sn sn
    ON sn.concept_code = str_ref.unitid::text
JOIN drug_concept_stage dcs2
    ON fr.destinationid::text = dcs2.concept_code
WHERE dcs.concept_code IN (
                          SELECT *
                          FROM drug_code
                          );



-- get all relations of a drug product
SELECT *
FROM internal_relationship_stage irs
JOIN drug_concept_stage dcs
    ON irs.concept_code_2 = dcs.concept_code
WHERE irs.concept_code_1 = '776862004';



