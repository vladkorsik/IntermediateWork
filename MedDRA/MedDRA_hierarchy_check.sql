--Check the parents of MedDRA code (including itselt)
SELECT cc.concept_name, cc.concept_class_id, ca.max_levels_of_separation, cc.concept_code
FROM devv5.concept c

JOIN devv5.concept_ancestor ca
    ON c.concept_id = ca.descendant_concept_id
JOIN devv5.concept cc
    ON ca.ancestor_concept_id = cc.concept_id

WHERE c.concept_code = '10058482' AND c.vocabulary_id = 'MedDRA' AND cc.vocabulary_id = 'MedDRA'
ORDER BY ca.max_levels_of_separation DESC;




--Check the children of MedDRA code (including itselt)
SELECT cc.concept_name, cc.concept_class_id, ca.max_levels_of_separation, cc.concept_code
FROM devv5.concept c

JOIN devv5.concept_ancestor ca
    ON c.concept_id = ca.ancestor_concept_id
JOIN devv5.concept cc
    ON ca.descendant_concept_id = cc.concept_id

WHERE c.concept_code = '10058482' AND c.vocabulary_id = 'MedDRA' AND cc.vocabulary_id = 'MedDRA'
ORDER BY ca.max_levels_of_separation;




