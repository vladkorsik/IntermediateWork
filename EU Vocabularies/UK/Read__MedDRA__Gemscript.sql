--UK
--Read
--108681 concepts OMOPed
SELECT count(DISTINCT concept_code)
    FROM devv5.concept
    where vocabulary_id = 'Read';

--100042 Mapped to standard
SELECT COUNT (*)
FROM (
    SELECT DISTINCT concept_code
    FROM devv5.concept
    where vocabulary_id = 'Read'
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

--MedDRA
--99645 concepts OMOPed
SELECT count(DISTINCT concept_code)
    FROM devv5.concept
    where vocabulary_id = 'MedDRA';

--2010 Mapped to standard
SELECT COUNT (*)
FROM (
    SELECT DISTINCT concept_code
    FROM devv5.concept
    where vocabulary_id = 'MedDRA'
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

--Gemscript
--253003 concepts OMOPed
SELECT count(DISTINCT concept_code)
    FROM devv5.concept
    where vocabulary_id = 'Gemscript';

--235576 Mapped to standard
SELECT COUNT (*)
FROM (
    SELECT DISTINCT concept_code
    FROM devv5.concept
    where vocabulary_id = 'Gemscript'
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
