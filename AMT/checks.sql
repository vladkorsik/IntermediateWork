--using attribute name find all drugs and their all existing attributes
SELECT dcs2.concept_name,  dcs2.concept_code, dcs4.concept_name, dcs4.concept_class_id
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
                           WHERE concept_name = 'Cold And Flu Day And Night'
                             AND dcs3.concept_class_id IN ('Dose Form', 'Supplier', 'Brand Name', 'Unit', 'Ingredient')
                           )
ORDER BY dcs2.concept_name
;