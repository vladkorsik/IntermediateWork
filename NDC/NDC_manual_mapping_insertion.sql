--26 000
SELECT *
FROM dev_ndc.concept_relationship_manual
;

--check if current RxNorm and possible RxE MINs solve the NDC problem
    with all_ndc as (
    select c1.concept_id as ndc_id,
           c1.concept_name as ndc_name,
           array_agg(distinct ds.ingredient_concept_id order by ds.ingredient_concept_id) ndc_arr
    from concept c1
    join concept_relationship r on r.concept_id_1 = c1.concept_id and r.invalid_reason is null and r.relationship_id = 'Maps to'
    join drug_strength ds on ds.drug_concept_id = r.concept_id_2
    where c1.vocabulary_id = 'NDC'
    and c1.concept_id in (SELECT DISTINCT c1.concept_id
                            FROM devv5.concept c1

                                     JOIN devv5.concept_relationship cr1
                                          ON c1.concept_id = cr1.concept_id_1 AND cr1.relationship_id = 'Maps to' AND cr1.invalid_reason IS NULL

                                     JOIN devv5.concept c2
                                          ON cr1.concept_id_2 = c2.concept_id AND c2.standard_concept = 'S' AND c2.invalid_reason IS NULL

                            WHERE c1.vocabulary_id = 'NDC'

                            GROUP BY c1.concept_id
                            HAVING count(DISTINCT c2.concept_id) > 1
                            ORDER BY c1.concept_id
        )
    group by c1.concept_id, c1.concept_name
    )

    select distinct n.ndc_id, n.ndc_name, c3.concept_id as rx_id, c3.concept_name as rx_name, cl_drugs.form_id, cl_drugs.form_name
    from all_ndc n
    join (
    	select c1.concept_id as form_id,
    	       c1.concept_name as form_name,
    	       array_agg(ds.ingredient_concept_id order by ds.ingredient_concept_id) drugs_arr
        from concept c1
        join drug_strength ds on ds.drug_concept_id = c1.concept_id
        where c1.vocabulary_id like 'Rx%'
        and c1.concept_class_id = 'Clinical Drug Form'
        group by c1.concept_id, c1.concept_name

    ) cl_drugs on cl_drugs.drugs_arr=n.ndc_arr    join concept_relationship r3 on n.ndc_id = r3.concept_id_1 and r3.invalid_reason is null and r3.relationship_id = 'Maps to'
    join concept c3 on r3.concept_id_2 = c3.concept_id
    --where form_id is null
    order by 1,2,3,4,5,6
;




--mappings gone somehow
SELECT *
FROM devv5.concept_relationship
WHERE concept_id_1 = 45247212;

SELECT *
FROM devv5.concept
WHERE concept_id in (19077990);


SELECT *
FROM dev_ndc.concept_relationship_manual
WHERE concept_code_1 in ('00002732125')
;



--WHERE ARE these mappings in Athena???
SELECT cr.*
FROM devv5.concept c
JOIN devv5.concept_relationship cr
    ON c.concept_id = cr.concept_id_1
        AND cr.relationship_id = 'Maps to'
        AND cr.invalid_reason IS NULL
WHERE c.concept_id in (45093672, 44974183, 44872068, 45212903, 44940458)
;

--check NDC to RxE mapping (1973)
SELECT *
FROM devv5.concept c
WHERE vocabulary_id = 'NDC'
AND EXISTS (SELECT 1
            FROM devv5.concept_relationship cr
            JOIN devv5.concept cc
            ON cr.concept_id_2 = cc.concept_id
            WHERE c.concept_id = cr.concept_id_1
            AND cc.standard_concept = 'S'
            AND cc.vocabulary_id = 'RxNorm Extension'
            AND cc.invalid_reason IS NULL);


--all existing relationships for concept in CR
SELECT DISTINCT cr.*, c.*
FROM devv5.concept_relationship cr
JOIN devv5.concept c
    ON cr.concept_id_2 = c.concept_id
    AND cr.concept_id_1 = 40098687  --concept_id

WHERE c.domain_id = 'Drug'
ORDER BY concept_class_id
;


--amphetamines
SELECT *
FROM devv5.concept c
WHERE vocabulary_id = 'NDC'

AND concept_name ~* 'imatinib|dasatinib|bosutinib|nilotinib|ponatinib|vedolizumab|adalimumab|amphetamine|methamphetamine|methylphenidate'

AND NOT EXISTS( select 1
                from devv5.concept_relationship cr
                where cr.concept_id_1 = c.concept_id and cr.relationship_id = 'Maps to' and cr.invalid_reason is null)
;


--drug list, including manually mapped
SELECT *
FROM dalex.ndc_source
WHERE concept_id not in (SELECT concept_id FROM dalex.ndc_non_drugs)
;


--drug list, excluding manually mapped
SELECT *
FROM dalex.ndc_drugs
UNION ALL
SELECT *
FROM dalex.ndc_remains
;

SELECT *
FROM dev_ndc.concept_relationship_manual;

--I.

--1. Fast recreate NDC schema
--2. NDC load_stage run to 1319
--3. 1322 added mappings from CR_manual
--4. Generic update

-- 1-to-many mapping, when it's not Ingredient, Clin Drug Comp, Brand Drug Comp


--II. Issues - mapping corrections

--III. New mappings

--1. Issues

--2. Rest of NDC having similar to RxNorm name

--3. Non-structured names = usagi + manual mapping


--before mapping modofications
CREATE TABLE dalex.ndc_concept_relationship_manual_2019_08_27 AS
    (SELECT * FROM dev_ndc.concept_relationship_manual);

--modifications on 2019_08_30
CREATE TABLE dalex.ndc_concept_relationship_manual_2019_08_30_modifications as (
    SELECT *
    FROM dalex.ndc_concept_relationship_manual_2019_09_02
        EXCEPT
    SELECT *
    FROM dalex.ndc_concept_relationship_manual_2019_08_27
)
;

--after deprication of wrong mapping
CREATE TABLE dalex.ndc_concept_relationship_manual_2019_09_02 AS
    (SELECT * FROM dev_ndc.concept_relationship_manual);


--after deletion, deprication and insertion on 2019-09-16
CREATE TABLE dalex.ndc_concept_relationship_manual_2019_09_16 AS
    (SELECT * FROM dev_ndc.concept_relationship_manual);


--after deprication of wrong mapping 2019_12_05
CREATE TABLE dalex.ndc_concept_relationship_manual_2019_12_05 AS
    (SELECT * FROM dev_ndc.concept_relationship_manual);


--check the current version of CR_manual
SELECT a.*, 'front' as schema
FROM (   SELECT *
         FROM dalex.ndc_concept_relationship_manual_2019_12_05

         EXCEPT

         SELECT *
         FROM dev_ndc.concept_relationship_manual
     ) as a

UNION ALL

SELECT b.*, 'back' as schema
FROM (   SELECT *
         FROM dev_ndc.concept_relationship_manual

         EXCEPT

         SELECT *
         FROM dalex.ndc_concept_relationship_manual_2019_09_16
     ) as b
;

--REVERT CR_MANUAL
/*TRUNCATE TABLE dev_ndc.concept_relationship_manual;
INSERT INTO dev_ndc.concept_relationship_manual
SELECT *
FROM dalex.ndc_concept_relationship_manual_2019_09_02*/
;



--DROP TABLE IF EXISTS NDC_manual;
CREATE TABLE NDC_manual (LIKE devv5.concept);

SELECT *
FROM NDC_manual;

--1st portion
INSERT INTO NDC_manual
SELECT DISTINCT c.*
FROM dev_rxnorm.deprecated_rx d
JOIN devv5.concept c
    ON drug_concept_id = concept_id
        AND vocabulary_id = 'NDC'
WHERE NOT EXISTS    (SELECT 1
                    FROM devv5.concept_relationship cr
                    WHERE   cr.concept_id_1 = c.concept_id
                        AND cr.relationship_id = 'Maps to'
                        AND cr.invalid_reason IS NULL)
    AND c.concept_id NOT IN (SELECT concept_id FROM NDC_manual)
;

--2nd portion
INSERT INTO NDC_manual
select DISTINCT * from devv5.concept
where not exists (select 1 from devv5.concept_relationship cr where concept_id_1 = concept_id and relationship_id = 'Maps to' and cr.invalid_reason is null)
    AND vocabulary_id = 'NDC'
    AND concept_code in
(
'00703415691','55648018601','00703415591','00009076502','58178001703','68382036310','52152060955','55390004701','68152010303','68382036306','00019945220','58468017001','00002762361','00019945002',
'00019945206','69945045204','69945045208','55513005404','68152010404','25021024602','00013252686','24535083101','55390080510','00703485291','63323012550','55513001401','00019945005','65174088050',
'50419051106','58468003002','00019945200','69945045200','69945045002','17156052401','00019945106','00019945201','69945045201','51808012701','00009090920','51808012801','00019945207','55390004801',
'69945045209','68382036330','69945045207','69945045206','00013220001','69945045220','00703415491','53270010101','58178001701','69945045104','69945045210','00009090916','00019945103','69945045202',
'00019945212','00019945217','00015355427','55390021501','63629666001','00019945203','69945045102','65174088025','00013220101','12516059204','00009338901','00013220201','69945045003','00019945208',
'65841074430','69945045212','00019945102','00019945211','51808011901','00019945209','69945045250','69945045215','00019945003','55513005401','00009090908','65841074410','69945045106','00074368001',
'69945045275','00008004501','69945045217','69945045005','38423011001','00019945204','69945045203','69945045103','00019945202','69945045004','00019945001','00019945004','69945045205','00019945007',
'00019945215','55390021701','00019945210','00009092003','55390021601','00019945104','69945045211','00019945275','00019945250','65841074406','69945045007','00009091205','53225365001','00944262001',
'65174088000','52584045182','00075800501','00019945205','00008004502','69945045001'
)
    AND concept_id not in (SELECT concept_id FROM NDC_manual)
;

--small manual portion
INSERT INTO NDC_manual
SELECT DISTINCT *
FROM devv5.concept
WHERE concept_id in (1583470, 1583469, 36186003, 36186029, 36186052, 36491356)
    AND not exists (select 1 from devv5.concept_relationship cr where concept_id_1 = concept_id and relationship_id = 'Maps to' and cr.invalid_reason is null)
    AND concept_id not in (SELECT concept_id FROM NDC_manual)
;

--adding 3rd manual portion of I
INSERT INTO NDC_manual
SELECT DISTINCT *
FROM devv5.concept c
WHERE concept_name ~* 'I-131| i 131|i131|131i|131 i|131-i|sodium iodide'
    AND c.vocabulary_id = 'NDC'
    AND not exists (select 1 from devv5.concept_relationship cr where concept_id_1 = concept_id and relationship_id = 'Maps to' and cr.invalid_reason is null)
    AND concept_id not in (SELECT concept_id FROM NDC_manual)
ORDER BY concept_code
;


--mapped portions
--DROP table NDC_cerner_drugs_mapping;
CREATE TABLE NDC_cerner_drugs_mapping (
    table_name varchar(255),
    source_code varchar(255),
    source_code_description varchar(255),
    code_vocabulary varchar(255),
    target_concept_id int,
    device_flag varchar(255)
);

SELECT *
FROM NDC_cerner_drugs_mapping
;

--DROP table NDC_mapping_from_forum;
CREATE TABLE NDC_mapping_from_forum (
    source_concept_id int,
    target_concept_id int);

SELECT *
FROM NDC_mapping_from_forum
;

--table for all adequate previous mapping
--DROP TABLE NDC_cerner_and_forum_drugs_mapping;
CREATE TABLE NDC_cerner_and_forum_drugs_mapping AS (
SELECT DISTINCT c.concept_code, c.concept_id, c.concept_name, NULL as comments, cc.concept_id as target_concept_id, cc.concept_code as target_concept_code, cc.concept_name as target_concept_name, cc.concept_class_id, cc.standard_concept, cc.invalid_reason, cc.domain_id, cc.vocabulary_id
FROM devv5.concept c
LEFT JOIN NDC_cerner_drugs_mapping m1
    ON c.concept_code = m1.source_code
LEFT JOIN NDC_mapping_from_forum m2
    ON c.concept_id = m2.source_concept_id
LEFT JOIN devv5.concept cc
    ON  cc.standard_concept = 'S'
           AND cc.invalid_reason IS NULL
           AND cc.vocabulary_id in ('CVX', 'RxNorm', 'RxNorm Extension')
           AND (cc.concept_id = m1.target_concept_id OR cc.concept_id = m2.target_concept_id)

WHERE TRUE
    AND cc.concept_id IS NOT NULL
    AND cc.concept_id != 0
    AND not exists (select 1 from devv5.concept_relationship cr where concept_id_1 = c.concept_id and relationship_id = 'Maps to' and cr.invalid_reason is null)
    AND c.vocabulary_id = 'NDC'
    AND c.concept_id NOT IN (SELECT concept_id FROM NDC_manual)

ORDER BY c.concept_code, c.concept_name, cc.concept_name
);



SELECT DISTINCT *
FROM NDC_cerner_and_forum_drugs_mapping;

INSERT INTO NDC_manual
SELECT DISTINCT c.*
FROM devv5.concept c
JOIN NDC_cerner_and_forum_drugs_mapping b
    ON c.concept_id = b.concept_id AND c.vocabulary_id = 'NDC'
WHERE not exists (select 1 from devv5.concept_relationship cr where cr.concept_id_1 = c.concept_id and cr.relationship_id = 'Maps to' and cr.invalid_reason is null)
    AND c.concept_id not in (SELECT concept_id FROM NDC_manual)
;

--DROP table NDC_manual_portion4_consolidated;
CREATE TABLE NDC_manual_portion4_consolidated (
    concept_code varchar(255),
    concept_id int
) WITH OIDS;

SELECT *
FROM NDC_manual_portion4_consolidated;

--4th portion
INSERT INTO NDC_manual
select DISTINCT c.*
from devv5.concept c
where not exists (select 1 from devv5.concept_relationship cr where cr.concept_id_1 = c.concept_id and cr.relationship_id = 'Maps to' and cr.invalid_reason is null)
    AND vocabulary_id = 'NDC'
    AND (concept_code in (SELECT concept_code FROM NDC_manual_portion4_consolidated)
        OR concept_id in (SELECT concept_id FROM NDC_manual_portion4_consolidated))

    AND concept_id not in (SELECT concept_id FROM NDC_manual)

ORDER BY concept_name, concept_code
;

SELECT DISTINCT *
FROM NDC_manual
;


--DROP TABLE NDC_manual_mapped;
CREATE TABLE NDC_manual_mapped (
    source_concept_id int,
    source_concept_code varchar(255),
    source_concept_name varchar,
    comments varchar,
    flag varchar,
    target_concept_id varchar(255),
    target_concept_code varchar(255),
    target_concept_name varchar(255),
    target_concept_class_id varchar(255),
    target_standard_concept varchar(255),
    target_invalid_reason varchar(255),
    target_domain_id varchar(255),
    target_vocabulary_id varchar(255)
                               )
WITH OIDS;


SELECT *
FROM NDC_manual_mapped;

--check if any source code/description are lost
SELECT *
FROM NDC_manual s
WHERE NOT EXISTS(SELECT 1
                 FROM NDC_manual_mapped m
                 WHERE s.concept_id = m.source_concept_id
                      AND s.concept_code = m.source_concept_code
                      AND s.concept_name = m.source_concept_name

    );

--check if any source code/description are modified
SELECT *
FROM NDC_manual_mapped m
WHERE NOT EXISTS(SELECT 1
                 FROM devv5.concept s
                 WHERE s.concept_id = m.source_concept_id
                      AND s.concept_code = m.source_concept_code
                      AND s.concept_name = m.source_concept_name
                      AND s.vocabulary_id = 'NDC'
    );

--check if target concepts exist in the concept table
SELECT *
FROM NDC_manual_mapped j1
WHERE NOT EXISTS (  SELECT *
                    FROM NDC_manual_mapped j2
                    JOIN devv5.concept c
                        ON j2.target_concept_id = c.concept_id::varchar
                            AND c.concept_name = j2.target_concept_name
                            AND c.vocabulary_id = j2.target_vocabulary_id
                            AND c.domain_id = j2.target_domain_id
                            AND c.standard_concept = 'S'
                            AND c.invalid_reason is NULL
                    WHERE j1.OID = j2.OID
                  );



--at the same time in both lists
SELECT *
FROM NDC_manual_mapped m
WHERE m.flag = 'var'
     AND EXISTS(SELECT 1
         FROM NDC_manual_mapped mm
         WHERE m.flag = 'mand'
         AND m.source_concept_id = mm.source_concept_id
          )
;





--1-to-many mapping
with tab as (
    SELECT DISTINCT s.*
    FROM dalex.NDC_manual_mapped s
)

SELECT DISTINCT *
FROM tab
WHERE source_concept_id in (

    SELECT source_concept_id
    FROM tab
    GROUP BY source_concept_id
    HAVING count (*) > 1)
;



--Check Device mapped to Drug domain
SELECT *
FROM NDC_manual_mapped m

WHERE
      target_concept_id != 'device'
      AND source_concept_id IN (SELECT concept_id FROM ndc_non_drugs)
;

--Check Devices, that were NOT recognized by script
SELECT *
FROM NDC_manual_mapped m

WHERE
      target_concept_id = 'device'
      AND source_concept_id NOT IN (SELECT concept_id FROM ndc_non_drugs)
;





--Script to run:
--to deprecate wrong mappings
--1. done
/*UPDATE dev_ndc.concept_relationship_manual
SET invalid_reason = 'D',
    valid_end_date = current_date
WHERE concept_code_1 in ('91237000148', '91237000144',
                         '10939082522','40985022731', '11845014957', '43072000746', '40986001651', '11917005315', '41163040347', '11917003949', '52569013434', '10939014433', '49348080130', '58487080031',
                         '11822880370', '10939031944', '48107004972')
;*/

--Check
SELECT *
FROM dev_ndc.concept_relationship_manual
WHERE concept_code_1 in ('91237000148', '91237000144',
                         '10939082522','40985022731', '11845014957', '43072000746', '40986001651', '11917005315', '41163040347', '11917003949', '52569013434', '10939014433', '49348080130', '58487080031',
                         '11822880370', '10939031944', '48107004972')
;


--to deprecate updated mappings
--2. done
/*DELETE FROM dev_ndc.concept_relationship_manual crm
WHERE concept_code_1 in (SELECT concept_code_1 FROM dalex.ndc_concept_relationship_manual_2019_09_16_modifications)
AND invalid_reason IS NULL
AND (concept_code_1, concept_code_2, vocabulary_id_1, vocabulary_id_2, relationship_id) NOT IN (SELECT concept_code_1, concept_code_2, vocabulary_id_1, vocabulary_id_2, relationship_id
                                                                                                FROM dalex.ndc_concept_relationship_manual_2019_09_16_modifications)

AND NOT EXISTS (SELECT 1 FROM devv5.concept_relationship cr
                LEFT JOIN devv5.concept c ON cr.concept_id_1 = c.concept_id
                LEFT JOIN devv5.concept cc ON cr.concept_id_2 = cc.concept_id
                WHERE crm.concept_code_1 = c.concept_code AND crm.vocabulary_id_1 = c.vocabulary_id
                    AND crm.concept_code_2 = cc.concept_code AND crm.vocabulary_id_2 = cc.vocabulary_id
                    AND cr.relationship_id = crm.relationship_id
                    AND cr.invalid_reason IS NULL
    )
;*/

/*UPDATE dev_ndc.concept_relationship_manual crm
SET invalid_reason = 'D',
    valid_end_date = TO_DATE('20190915', 'YYYYMMDD')
WHERE concept_code_1 in (SELECT concept_code_1 FROM dalex.ndc_concept_relationship_manual_2019_09_16_modifications)
AND invalid_reason IS NULL
AND (concept_code_1, concept_code_2, vocabulary_id_1, vocabulary_id_2, relationship_id) NOT IN (SELECT concept_code_1, concept_code_2, vocabulary_id_1, vocabulary_id_2, relationship_id
                                                                                                FROM dalex.ndc_concept_relationship_manual_2019_09_16_modifications)
;*/

/*UPDATE dev_ndc.concept_relationship_manual crm
SET valid_start_date = TO_DATE('20190916', 'YYYYMMDD'),
    valid_end_date =  to_date('20991231', 'YYYYMMDD')
WHERE invalid_reason IS NULL
AND (concept_code_1, concept_code_2, vocabulary_id_1, vocabulary_id_2, relationship_id) IN (SELECT concept_code_1, concept_code_2, vocabulary_id_1, vocabulary_id_2, relationship_id
                                                                                                FROM dalex.ndc_concept_relationship_manual_2019_09_16_modifications)
;*/




--Check
SELECT *
FROM dev_ndc.concept_relationship_manual
WHERE concept_code_1 in (SELECT concept_code_1 FROM dalex.ndc_concept_relationship_manual_2019_09_16_modifications)
;



--to deprecate wrong mappings
--done
/*UPDATE dev_ndc.concept_relationship_manual
SET invalid_reason = 'D',
    valid_end_date = current_date
WHERE concept_code_1 in ('63323025410', '87701040161', '10939032544', '59707000155', '08080100008', '52569013481', '30142032910', '68016001173', '11917008790', '52569013475', '91237000100',
                         '68016001170', '40986002399', '96295011031', '52569013478', '11917012943', '41163023213', '49348073701', '96295011308', '41163023199', '52569013479',
                         '50428193592', '92896000008', '68016002399', '68016001171', '08080100006', '11822324050', '08080100004', '10939027601'
    )
AND vocabulary_id_1 = 'NDC'
;*/

--Check
SELECT *
FROM devv5.concept c
LEFT JOIN dev_ndc.concept_relationship_manual crm
ON c.concept_code = crm.concept_code_1
WHERE c.concept_code in ('63323025410', '87701040161', '10939032544', '59707000155', '08080100008', '52569013481', '30142032910', '68016001173', '11917008790', '52569013475', '91237000100',
                         '68016001170', '40986002399', '96295011031', '52569013478', '11917012943', '41163023213', '49348073701', '96295011308', '41163023199', '52569013479',
                         '50428193592', '92896000008', '68016002399', '68016001171', '08080100006', '11822324050', '08080100004', '10939027601'
    )
    AND c.vocabulary_id = 'NDC'
;



--3. mapping insertion
--1426 inserted
--DROP TABLE dalex.ndc_concept_relationship_manual_2019_09_16_modifications;
CREATE TABLE dalex.ndc_concept_relationship_manual_2019_09_16_modifications AS (
with tab as (
    SELECT DISTINCT s.*
    FROM dalex.NDC_manual_mapped s
)


SELECT DISTINCT m.source_concept_code as concept_code_1,
                c.concept_code as concept_code_2,
                cc.vocabulary_id as vocabulary_id_1,
                c.vocabulary_id as vocabulary_id_2,
                'Maps to' as relationship_id,
                --CASE WHEN cc.valid_start_date < TO_DATE('19700101', 'YYYYMMDD') THEN TO_DATE('19700101', 'YYYYMMDD') ELSE cc.valid_start_date END as valid_start_date,
                TO_DATE('20190916', 'YYYYMMDD') as valid_start_date,
                to_date('20991231', 'YYYYMMDD') AS valid_end_date,
                NULL as invalid_reason
FROM tab m

LEFT JOIN devv5.concept c
    ON m.target_concept_id = c.concept_id::varchar

LEFT JOIN devv5.concept cc
    ON m.source_concept_code = cc.concept_code AND cc.vocabulary_id = 'NDC'

WHERE m.target_concept_id != '0' AND m.target_concept_id != 'device' AND c.concept_id IS NOT NULL AND cc.concept_code IS NOT NULL


AND NOT exists (select 1 from devv5.concept_relationship cr where cr.concept_id_1 = m.source_concept_id and cr.relationship_id = 'Maps to' and cr.invalid_reason is null)


ORDER BY 1,2,3,4,5,6,7,8
)
;

--3.1. Insertion
--done
--INSERT INTO dev_ndc.concept_relationship_manual
SELECT *
FROM dalex.ndc_concept_relationship_manual_2019_09_16_modifications
WHERE (concept_code_1, concept_code_2, vocabulary_id_1, vocabulary_id_2, relationship_id) NOT IN (  SELECT concept_code_1, concept_code_2, vocabulary_id_1, vocabulary_id_2, relationship_id
                                                                                                    FROM dev_ndc.concept_relationship_manual
                                                                                                    WHERE invalid_reason IS NULL)
;





--List of NDC_manual to be mapped
SELECT DISTINCT
                concept_id as source_concept_id,
                concept_code as source_concept_code,
                concept_name as source_concept_name
FROM NDC_manual
--exclude concepts already in NDC_manual_mapped table
WHERE concept_id NOT IN (SELECT source_concept_id FROM dalex.NDC_manual_mapped WHERE source_concept_id IS NOT NULL)
;





--check if old D mappings are useful
--list to be reviewed
SELECT DISTINCT c.concept_id as source_concept_id,
                c.concept_code as source_concept_code,
                c.concept_name as source_concept_name,
                NULL as comments,
                ccc.concept_id as target_concept_id,
                ccc.concept_code as target_concept_code,
                ccc.concept_name as target_concept_name,
                ccc.concept_class_id as target_concept_class_id,
                ccc.standard_concept as target_standard_concept,
                ccc.invalid_reason as target_invalid_reason,
                ccc.domain_id as target_domain_id,
                ccc.vocabulary_id as target_vocabulary_id,
                regexp_replace(c.concept_name, '^\d*\.*\d*( )*(ML|HR|ACTUAT|MG)*( )*|^\{( )*\d*( )*\(*\d*\.*\d*( )*(ML|HR|ACTUAT|MG)*( )*\)*( )*\(*', '', 'g') as sort

FROM devv5.concept_relationship cr

JOIN devv5.concept c
    ON cr.concept_id_1 = c.concept_id AND c.vocabulary_id = 'NDC'

JOIN devv5.concept cc
    ON cr.concept_id_2 = cc.concept_id

JOIN devv5.concept_relationship crr
    ON cc.concept_id = crr.concept_id_1 AND crr.relationship_id IN ('Maps to', 'RxNorm replaced by', 'Concept replaced by') AND crr.invalid_reason IS NULL

JOIN devv5.concept ccc
    ON crr.concept_id_2 = ccc.concept_id AND ccc.standard_concept = 'S'


WHERE TRUE
    AND cr.relationship_id IN ('Maps to', 'RxNorm replaced by', 'Concept replaced by') AND cr.invalid_reason IS NOT NULL

--have no valid 'Maps to' mapping currently
AND NOT EXISTS    (SELECT 1
                    FROM devv5.concept_relationship crrrr
                    WHERE   crrrr.concept_id_1 = c.concept_id
                        AND crrrr.relationship_id = 'Maps to'
                        AND crrrr.invalid_reason IS NULL)

--exclude concepts already in NDC_manual_mapped table
AND c.concept_id NOT IN (SELECT source_concept_id FROM dalex.NDC_manual_mapped WHERE source_concept_id IS NOT NULL)

ORDER BY regexp_replace(c.concept_name, '^\d*\.*\d*( )*(ML|HR|ACTUAT|MG)*( )*|^\{( )*\d*( )*\(*\d*\.*\d*( )*(ML|HR|ACTUAT|MG)*( )*\)*( )*\(*', '', 'g'),
         c.concept_code
;


SELECT *
FROM relationship
;





--2020-02-17
--NDC_manual_portion5
--https://github.com/OHDSI/Vocabulary-v5.0/issues/277

CREATE TABLE dalex.NDC_manual_portion5 (
    drug_source_value varchar(255),
    drug_source_concept_id int,
    concept_name varchar(255),
    vocabulary_id varchar(255),
    concept_class_id varchar(255),
    standard_concept varchar(255),
    valid_start_date date,
    valid_end_date date,
    invalid_reason varchar(255),
    row_counts int
) WITH OIDS;


--check source consistency
SELECT *
FROM dalex.NDC_manual_portion5 s

LEFT JOIN devv5.concept c
    ON s.drug_source_value = c.concept_code
        AND s.drug_source_concept_id = c.concept_id
        AND s.vocabulary_id = c.vocabulary_id
WHERE c.concept_id IS NULL
;




--select for manual mapping
SELECT DISTINCT
                c.concept_id,
                c.concept_code,
                c.concept_name,
                s.row_counts

FROM dalex.NDC_manual_portion5 s

JOIN devv5.concept c
    ON s.drug_source_value = c.concept_code
        AND s.drug_source_concept_id = c.concept_id
        AND s.vocabulary_id = c.vocabulary_id

LEFT JOIN devv5.concept_synonym cs
    ON c.concept_id = cs.concept_id

WHERE c.vocabulary_id = 'NDC'

AND not exists (select 1 from devv5.concept_relationship cr where cr.concept_id_1 = c.concept_id and cr.relationship_id = 'Maps to' and cr.invalid_reason is null)

AND c.concept_id NOT IN (select source_concept_id FROM dalex.NDC_manual_mapped WHERE source_concept_id IS NOT NULL)

ORDER BY s.row_counts DESC
;



--NDC_manual_portion6
--https://github.com/OHDSI/Vocabulary-v5.0/issues/100#issuecomment-590992058

CREATE TABLE dalex.NDC_manual_portion6 (
    concept_id int,
    code varchar(255),
    concept_name varchar(255),
    concept_class_id varchar(255),
    vocabulary_id varchar(255),
    count int
) WITH OIDS;


--check source consistency
SELECT s.concept_id,
       s.code,
       s.concept_name,
       s.concept_class_id,
       s.vocabulary_id,
       s.count
FROM dalex.NDC_manual_portion6 s

LEFT JOIN devv5.concept c
    ON      s.concept_id = c.concept_id
        AND s.code = c.concept_code
        --AND s.concept_name = c.concept_name --concept_name was slightly modified for 2 concepts
        --AND s.concept_class_id = c.concept_class_id --Domain was changed for 16 concepts
        AND s.vocabulary_id = c.vocabulary_id

WHERE c.concept_id IS NULL
;




--select for manual mapping
with source as (

SELECT DISTINCT
                c.concept_id,
                c.concept_code,
                c.concept_name,
                s.count as row_counts
                --,cs.concept_synonym_name --empty here

FROM dalex.NDC_manual_portion6 s

JOIN devv5.concept c
    ON s.code = c.concept_code
        AND s.concept_id = c.concept_id
        AND s.vocabulary_id = c.vocabulary_id

LEFT JOIN devv5.concept_synonym cs
    ON c.concept_id = cs.concept_id AND cs.concept_synonym_name != c.concept_name

WHERE c.vocabulary_id = 'NDC'

AND not exists (select 1 from devv5.concept_relationship cr where cr.concept_id_1 = c.concept_id and cr.relationship_id = 'Maps to' and cr.invalid_reason is null)

AND c.concept_id NOT IN (select source_concept_id FROM dalex.NDC_manual_mapped WHERE source_concept_id IS NOT NULL)



--adding part of portion5
UNION ALL

SELECT DISTINCT
                c.concept_id,
                c.concept_code,
                c.concept_name,
                s.row_counts
                --,cs.concept_synonym_name --empty here

FROM dalex.NDC_manual_portion5 s

JOIN devv5.concept c
    ON s.drug_source_value = c.concept_code
        AND s.drug_source_concept_id = c.concept_id
        AND s.vocabulary_id = c.vocabulary_id

LEFT JOIN devv5.concept_synonym cs
    ON c.concept_id = cs.concept_id AND cs.concept_synonym_name != c.concept_name

WHERE c.vocabulary_id = 'NDC'

AND not exists (select 1 from devv5.concept_relationship cr where cr.concept_id_1 = c.concept_id and cr.relationship_id = 'Maps to' and cr.invalid_reason is null)

AND c.concept_id NOT IN (select source_concept_id FROM dalex.NDC_manual_mapped WHERE source_concept_id IS NOT NULL)

)

SELECT DISTINCT
       concept_id,
       concept_code,
       concept_name,
       sum (row_counts) as row_counts

FROM source

GROUP BY concept_id,
         concept_code,
         concept_name

ORDER BY sum (row_counts) DESC
;






--DROP TABLE dalex.NDC_manual_mapped;
CREATE TABLE dalex.NDC_manual_mapped (
    source_concept_id int,
    source_concept_code varchar(255),
    source_concept_name varchar,
    source_counts int,
    comments varchar,
    --flag varchar,
    target_concept_id varchar(255),
    target_concept_code varchar(255),
    target_concept_name varchar(255),
    target_concept_class_id varchar(255),
    target_standard_concept varchar(255),
    target_invalid_reason varchar(255),
    target_domain_id varchar(255),
    target_vocabulary_id varchar(255)
                               )
WITH OIDS;


SELECT *
FROM NDC_manual_mapped;


--check if any source code/description are lost
SELECT *
FROM NDC_manual s
WHERE NOT EXISTS(SELECT 1
                 FROM NDC_manual_mapped m
                 WHERE s.concept_id = m.source_concept_id
                      AND s.concept_code = m.source_concept_code
                      AND s.concept_name = m.source_concept_name

    );

--check if any source code/description are modified
SELECT *
FROM NDC_manual_mapped m
WHERE NOT EXISTS(SELECT 1
                 FROM devv5.concept s
                 WHERE s.concept_id = m.source_concept_id
                      AND s.concept_code = m.source_concept_code
                      AND s.concept_name = m.source_concept_name
                      AND s.vocabulary_id = 'NDC'
    );

--check if target concepts exist in the concept table
SELECT *
FROM NDC_manual_mapped j1
WHERE NOT EXISTS (  SELECT *
                    FROM NDC_manual_mapped j2
                    JOIN devv5.concept c
                        ON j2.target_concept_id = c.concept_id::varchar
                            AND c.concept_name = j2.target_concept_name
                            AND c.vocabulary_id = j2.target_vocabulary_id
                            AND c.domain_id = j2.target_domain_id
                            AND c.standard_concept = 'S'
                            AND c.invalid_reason is NULL
                    WHERE j1.OID = j2.OID
                  );




--1-to-many mapping
with tab as (
    SELECT DISTINCT s.*
    FROM dalex.NDC_manual_mapped s
)

SELECT DISTINCT *
FROM tab
WHERE source_concept_id in (

    SELECT source_concept_id
    FROM tab
    GROUP BY source_concept_id
    HAVING count (*) > 1)
;



--Check Device mapped to Drug domain
SELECT *
FROM NDC_manual_mapped m

WHERE
      target_concept_id != 'device'
      AND source_concept_id IN (SELECT concept_id FROM ndc_non_drugs)
;

--Check Devices, that were NOT recognized by script
SELECT *
FROM NDC_manual_mapped m

WHERE
      target_concept_id = 'device'
      AND source_concept_id NOT IN (SELECT concept_id FROM ndc_non_drugs)
;