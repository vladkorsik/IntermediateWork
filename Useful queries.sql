-- Drug Forms currently used in OMOP Drugs
SELECT DISTINCT c.*
FROM devv5.concept c

JOIN devv5.concept_relationship cr
    ON c.concept_id = cr.concept_id_1
        AND cr.invalid_reason IS NULL
        --AND cr.relationship_id = 'RxNorm dose form of'

JOIN devv5.concept cc
    ON cr.concept_id_2 = cc.concept_id
        AND cc.vocabulary_id like 'RxNorm%'
        AND cc.invalid_reason IS NULL
        AND cc.standard_concept = 'S'

WHERE c.vocabulary_id like 'RxNorm%'
    AND c.concept_class_id = 'Dose Form'
    AND c.invalid_reason IS NULL
;

-- Drug Forms currently NOT used in OMOP Drugs
SELECT DISTINCT c.*
FROM devv5.concept c
WHERE c.vocabulary_id like 'RxNorm%'
    AND c.concept_class_id = 'Dose Form'
    AND c.invalid_reason IS NULL
    AND c.concept_id NOT IN (
            SELECT DISTINCT c.concept_id
            FROM devv5.concept c

            JOIN devv5.concept_relationship cr
                ON c.concept_id = cr.concept_id_1
                    AND cr.invalid_reason IS NULL
                    AND cr.relationship_id = 'RxNorm dose form of'

            JOIN devv5.concept cc
                ON cr.concept_id_2 = cc.concept_id
                    AND cc.vocabulary_id like 'RxNorm%'
                    AND cc.invalid_reason IS NULL
                    AND cc.standard_concept = 'S'

            WHERE c.vocabulary_id like 'RxNorm%'
                AND c.concept_class_id = 'Dose Form'
                AND c.invalid_reason IS NULL
            )
;