SELECT DISTINCT c1.concept_id,
                c1.concept_name,
                c1.domain_id,
                c1.vocabulary_id,
                c1.concept_class_id,
                c1.concept_code,
                c2.vocabulary_id as source_vocabulary_id,
                string_agg (DISTINCT c2.concept_code, ', ' ORDER BY c2.concept_code) as source_code

/*SELECT DISTINCT c1.concept_id || '|' ||
                c1.concept_name || '|' ||
                c1.domain_id || '|' ||
                c1.vocabulary_id || '|' ||
                c1.concept_class_id || '|' ||
                c1.concept_code || '|' ||
                c2.vocabulary_id || '|' ||
                string_agg (DISTINCT c2.concept_code, ', ')*/


FROM devv5.concept_ancestor ca1

JOIN devv5.concept c1
    ON ca1.descendant_concept_id = c1.concept_id

JOIN devv5.concept_relationship cr1
    ON ca1.descendant_concept_id = cr1.concept_id_2 AND cr1.relationship_id = 'Maps to' AND cr1.invalid_reason IS NULL

JOIN devv5.concept c2
    ON cr1.concept_id_1 = c2.concept_id

WHERE ca1.ancestor_concept_id = 4266367
AND ca1.descendant_concept_id != c2.concept_id
--AND (c2.vocabulary_id like '%ICD%' OR c2.vocabulary_id like '%KCD%')

GROUP BY        c1.concept_id,
                c1.concept_name,
                c1.domain_id,
                c1.vocabulary_id,
                c1.concept_class_id,
                c1.concept_code,
                c2.vocabulary_id
;



SELECT concept_id || '|' ||
       concept_name || '|' ||
       domain_id || '|' ||
       vocabulary_id || '|' ||
       concept_class_id || '|' ||
       concept_code

FROM devv5.concept c

WHERE c.concept_id IN (4146943, 46274061, 42537960, 4112824, 4299935, 46269706)

ORDER BY concept_name
;