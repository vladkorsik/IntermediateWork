--get insulin drugs from dcs
SELECT *
FROM drug_concept_stage dcs
WHERE dcs.concept_name ~* ('insul|aspart |lispro|glulisine|velosulin|glargin|detemir|degludec' ||

                           'actrap|afrezza|apidra|basaglar|fiasp|humalog|' ||
                           'humuli|hypurin|lantus|levemir|novolin|novolog|' ||
                           'novomix|novorapid|mixtard|optisulin|protaphane|' ||
                           'ryzodeg|semglee|soluqua|toujeo|tresiba')
  AND concept_class_id NOT IN ('Ingredient', 'Brand Name')
ORDER BY concept_name;


--get mapping from source drugs to RxE created
SELECT dcs.concept_code, dcs.concept_name, cr.relationship_id, c2.concept_id, c2.concept_name
FROM drug_concept_stage dcs
JOIN concept c1
    ON dcs.concept_name = c1.concept_name
JOIN concept_relationship cr
    ON c1.concept_id = cr.concept_id_1
LEFT JOIN concept c2
    ON c2.concept_id = cr.concept_id_2
WHERE dcs.concept_name ~* ('insul|aspart |lispro|glulisine|velosulin|glargin|detemir|degludec' ||
                           'actrap|afrezza|apidra|basaglar|fiasp|humalog|' ||
                           'humuli|hypurin|lantus|levemir|novolin|novolog|' ||
                           'novomix|novorapid|mixtard|optisulin|protaphane|' ||
                           'ryzodeg|semglee|soluqua|toujeo|tresiba')
  AND dcs.concept_class_id NOT IN ('Ingredient', 'Brand Name')
  AND cr.relationship_id = 'Maps to'
ORDER BY dcs.concept_name;