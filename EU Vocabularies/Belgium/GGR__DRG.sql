--Belgium
--GGR
--24494 concepts OMOPed
SELECT count(DISTINCT concept_code)
    FROM devv5.concept
    where vocabulary_id = 'GGR';

--16907 Mapped to standard
SELECT COUNT (*)
FROM (
    SELECT DISTINCT concept_code
    FROM devv5.concept
    where vocabulary_id = 'GGR'
         ) as a
where exists
      (select 1
      from devv5.concept c
            join devv5.concept_relationship cr
                  ON c.concept_id = cr.concept_id_1
      where a.concept_code = c.concept_code
            and cr.relationship_id = 'Maps to'
            and cr.invalid_reason is null)
;

--DRG
--1362 concepts OMOPed
SELECT count(DISTINCT concept_id)
    FROM devv5.concept
    where vocabulary_id = 'DRG';

--752 Mapped to standard
SELECT COUNT (*)
FROM devv5.concept c
      join devv5.concept_relationship cr
            ON c.concept_id = cr.concept_id_1
      where c.vocabulary_id = 'DRG'
            and cr.relationship_id = 'Maps to'
            and cr.invalid_reason is null
;
