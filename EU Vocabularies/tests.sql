SELECT *
FROM devv5.concept c

WHERE vocabulary_id = 'GGR' AND c.invalid_reason IS NULL
AND NOT EXISTS (SELECT 1
    FROM devv5.concept_relationship cr
    WHERE cr.concept_id_1 = c.concept_id
    AND cr.relationship_id = 'Maps to'
    AND cr.invalid_reason IS NULL)
;