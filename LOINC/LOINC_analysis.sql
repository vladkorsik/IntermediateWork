--This file contains all the test, statistics and other secondary code to LOINC

--Relationships from this subquery (7484 distinct relationships between LOINC Parts) can be added only with help of Loinc_partlink, but not LOINC_hierarchy
WITH a AS (
    SELECT concept_code_1,
           c.concept_name,
           c.concept_class_id,
           relationship_id,
           concept_code_2,
           j.concept_name,
           j.concept_class_id
    FROM dev_loinc.concept_relationship_stage r
             JOIN dev_loinc.concept_stage c ON (r.concept_code_1, r.vocabulary_id_1) = (c.concept_code, c.vocabulary_id)
        AND c.vocabulary_id = 'LOINC' AND c.concept_class_id IN
                                          ('LOINC Component', 'LOINC System', 'LOINC Property', 'LOINC Method',
                                           'LOINC Time', 'LOINC Scale')
             JOIN dev_loinc.concept_stage j ON (r.concept_code_2, r.vocabulary_id_2) = (j.concept_code, j.vocabulary_id)
        AND j.vocabulary_id = 'LOINC' AND j.concept_class_id IN
                                          ('LOINC Component', 'LOINC System', 'LOINC Property', 'LOINC Method',
                                           'LOINC Time', 'LOINC Scale')
    WHERE (concept_code_1, concept_code_2) NOT IN (SELECT immediate_parent, code FROM sources.loinc_hierarchy)
    ORDER BY c.concept_name
)

SELECT DISTINCT a.*
FROM a
JOIN sources.loinc_hierarchy lh
    ON lh.immediate_parent = a.concept_code_1
    AND lh.code = a.concept_code_2
ORDER BY a.concept_code_1;


--Subsumes relationships between 'LP-' concepts built from loinc_hierarchy
SELECT lh.immediate_parent, cs.concept_name AS parent_name, cs.concept_class_id AS parent_concept_class_id, cr.relationship_id, css.concept_code, css.concept_name, css.concept_class_id
FROM sources.loinc_hierarchy lh
JOIN concept_stage cs
ON lh.immediate_parent = cs.concept_code
AND cs.concept_class_id in ('LOINC Component', 'LOINC System', 'LOINC Property', 'LOINC Method', 'LOINC Time', 'LOINC Scale')
JOIN concept_relationship_stage cr
ON lh.immediate_parent = cr.concept_code_1
JOIN concept_stage css
ON css.concept_code = lh.code
AND cs.concept_class_id in ('LOINC Component', 'LOINC System', 'LOINC Property', 'LOINC Method', 'LOINC Time', 'LOINC Scale')
WHERE relationship_id = 'Subsumes'
ORDER BY lh.immediate_parent;


--Look at the concepts that have
--              parttypename IN ('SYSTEM', 'METHOD', 'PROPERTY', 'TIME', 'COMPONENT', 'SCALE')
--but with      linktypename != 'Primary'
SELECT DISTINCT p.partnumber, p.partdisplayname, p.parttypename, pl.linktypename
FROM sources.loinc_part p
JOIN sources.loinc_partlink pl
ON p.partnumber = pl.partnumber
WHERE p.parttypename IN ('SYSTEM', 'METHOD', 'PROPERTY', 'TIME', 'COMPONENT', 'SCALE')
AND pl.linktypename != 'Primary';


/*Concepts with parttypename IN ('SYSTEM', 'METHOD', 'PROPERTY', 'TIME', 'COMPONENT', 'SCALE') - 6 parttypes we agreed to include in CDM
  without analogues in 'Primary' (linktypename = 'Primary') concepts
    9053 distinct parts
  */
SELECT DISTINCT p.partnumber, p.partdisplayname, p.parttypename, pl.linktypename
FROM sources.loinc_part p
JOIN sources.loinc_partlink pl
ON p.partnumber = pl.partnumber
WHERE p.parttypename IN ('SYSTEM', 'METHOD', 'PROPERTY', 'TIME', 'COMPONENT', 'SCALE')
AND pl.linktypename != 'Primary'
AND p.partnumber NOT IN (SELECT DISTINCT pl.partnumber FROM sources.loinc_partlink pl
    WHERE pl.linktypename = 'Primary'
    AND pl.parttypename IN ('SYSTEM', 'METHOD', 'PROPERTY', 'TIME', 'COMPONENT', 'SCALE')
    AND pl.parttypename IS NOT NULL)
;

--Также интересно заджойнить loinc_hierarchy и loinc_partlink,  чтобы посмотреть какие закономерности в построении иерархии для loinc parts присутствуют в сорсе
--Not sure this code will be helpful somehow
SELECT lh.immediate_parent, p.partdisplayname AS parent_name, p.parttypename, pl.linktypename, lh.code, lh.code_text
FROM sources.loinc_hierarchy lh
JOIN sources.loinc_partlink pl
ON lh.immediate_parent = pl.partnumber
JOIN sources.loinc_part p
ON lh.immediate_parent = p.partnumber
ORDER BY lh.immediate_parent;