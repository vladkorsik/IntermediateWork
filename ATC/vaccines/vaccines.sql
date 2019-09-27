--The SQL code for ATC vaccines treatment and mapping
SET SCHEMA 'dev_atc';
SET search_path TO dev_atc;


--Split of vaccines into self sufficient ingredients:
CREATE TABLE manual_split AS

--Choosing meningococci with duplication for serogroups;
with duplicate_meningococci as (
SELECT id, atc_code, atc_name, regexp_replace (atc_name, ',(?=C)|,(?=Y)|,(?=W)|\s\+\s(?=C)', ' and meningococcus ', 'g') as atc_name2
FROM dev_atc.manual
WHERE atc_name  ilike '%men%'

UNION ALL
--Choosing the rest of vaccines, excliding saline, etc.
SELECT id, atc_code, atc_name, atc_name as atc_name2
FROM dev_atc.manual
WHERE atc_name not ilike '%men%' AND atc_name not in ('sodium chloride, hypertonic') AND atc_name not ilike '%levodopa%'
),

split_names as (
SELECT id, atc_code, atc_name, regexp_split_to_table (atc_name2, '-(?!135)|[[:blank:]]and[[:blank:]](?!toxoids)|,[[:blank:]]combinations[[:blank:]]with[[:blank:]](?!toxoids)|(?<=mumps),\s(?=rubella)') as atc_name3
FROM duplicate_meningococci
),

clean_names as (
SELECT id, atc_code, atc_name, atc_name3, regexp_replace (atc_name3, ',|(?<=typhoid)(\s)*vaccine(,)*\s*|(\s)*bivalent(,)*\s*|(\s)*tetravalent(,)*\s*|(\s)*combinations(,)*\s*|(\s)*with(,)*\s*|(\s)*and(,)*\s*|(\s)*whole(,)*\s*|(?<!vari)(\s)*cell(,)*\s*|(\s)*attenuated(,)*\s*|(\s)*purified(,)*\s*|(\s)*polysaccharide(s)*(,)*\s*|(\s)*antigen(s)*(,)*\s*|(\s)*conjugated(,)*\s*|(\s)*inactivated(,)*\s*|(\s)*live(,)*\s*|(?<!tetanus(\s)*|diphtheria(\s)*)(\s)*toxoid(s*)(,)*\s*', '', 'g') as atc_name4
FROM split_names
),

charact as (
SELECT id, atc_code, atc_name, atc_name3, regexp_matches (atc_name3, 'purified\spolysaccharide\santigen|live\sattenuated|combinations\swith\stoxoids|purified\santigen\,\scombinations\swith\stoxoids|inactivated\,\swhole cell\,\scombinations\swith\stoxoids|vaccine\,\sinactivated\,\swhole\scell|inactivated\,\swhole\scell|purified\santigen|attenuated|purified\s*polysaccharides\santigen\sconjugated|purified\s*polysaccharides\santigen|polysaccharide|antigen|vesicular|conjugated|live|(?<!pertussis\sand\s)toxoids', 'g') as charact
FROM split_names
),

split as (

SELECT DISTINCT cn.atc_code, cn.atc_name, cn.atc_name3, cn.atc_name4, c.charact
FROM clean_names cn
LEFT JOIN charact c
  ON cn.atc_code = c.atc_code AND cn.atc_name3 = c.atc_name3
  ORDER BY cn.atc_code, cn.atc_name
),

charact2 as (
SELECT atc_code, atc_name, atc_name3, atc_name4, regexp_replace (unnest(charact), ',|\s((?=\s))', '', 'g') as charact
FROM split
),

final as (
SELECT s.atc_code,s.atc_name, s.atc_name3, s.atc_name4, c2.charact
FROM split s
LEFT JOIN charact2 c2
  ON s.atc_code = c2.atc_code
),

final2 as(

SELECT atc_code, atc_name, atc_name4 || ' ' || charact as ingredient_name
FROM final
WHERE charact is not null

UNION ALL

SELECT atc_code, atc_name, atc_name4 as ingredient_name
FROM final
WHERE charact is null
ORDER BY atc_code
)
SELECT * from final2
;




--Correction of hemophilus influenzae B ingredient name:
update dev_atc.manual_split
set ingredient_name = 'hemophilus influenzae B combinations with toxoids'

where ingredient_name = 'hemophilus influenzae B'
  AND atc_code = 'J07AG52';



--Creation of empty rtc preliminary table
CREATE TABLE dev_atc.relationship_to_concept_preliminary
AS (select * from dev_atc.relationship_to_concept
   WHERE FALSE)
;

--Retrieve the mapping:
--SELECT * FROM dev_atc.relationship_to_concept_preliminary;

--Clean the table:
--DELETE FROM dev_atc.relationship_to_concept_preliminary;


/*
--Catching the distinct ingredient names (48)
SELECT DISTINCT ingredient_name
FROM dev_atc.manual_split
ORDER BY ingredient_name
;*/


--ATC Vaccines split ingredients manual mapping to RxNorm population:
INSERT INTO dev_atc.relationship_to_concept_preliminary (concept_code_1, vocabulary_id_1, concept_id_2, precedence, conversion_factor)

VALUES
('cholera vaccine inactivated whole cell',                              'ATC',    595252,         1,         cast (null as int)),
('cholera vaccine inactivated whole cell',                              'ATC',    636164,         3,         cast (null as int)),
('cholera vaccine inactivated whole cell',                              'ATC',    636167,         4,         cast (null as int)),
('cholera vaccine inactivated whole cell',                              'ATC',    43560345,         2,         cast (null as int)),

('diphtheria',                                                          'ATC',    529303,         1,         cast (null as int)),

('diphtheria toxoid',                                                   'ATC',    529303,         1,         cast (null as int)),

('hemophilus influenzae B',                                             'ATC',    529118,         6,         cast (null as int)),
('hemophilus influenzae B',                                             'ATC',    530007,         5,         cast (null as int)),
('hemophilus influenzae B',                                             'ATC',    586306,         4,         cast (null as int)),
('hemophilus influenzae B',                                             'ATC',    19048700,         2,         cast (null as int)),
('hemophilus influenzae B',                                             'ATC',    19113026,         1,         cast (null as int)),
('hemophilus influenzae B',                                             'ATC',    43012721,         3,         cast (null as int)),

('hemophilus influenzae B combinations with toxoids',                   'ATC',    529118,         1,         cast (null as int)),
('hemophilus influenzae B combinations with toxoids',                   'ATC',    19048700,         2,         cast (null as int)),
('hemophilus influenzae B combinations with toxoids',                   'ATC',    19113026,         3,         cast (null as int)),
('hemophilus influenzae B combinations with toxoids',                   'ATC',    43012721,         4,         cast (null as int)),

('hemophilus influenzae B conjugated',                                  'ATC',    529118,         3,         cast (null as int)),
('hemophilus influenzae B conjugated',                                  'ATC',    530007,         2,         cast (null as int)),
('hemophilus influenzae B conjugated',                                  'ATC',    19048700,         1,         cast (null as int)),
('hemophilus influenzae B conjugated',                                  'ATC',    19113026,         4,         cast (null as int)),
('hemophilus influenzae B conjugated',                                  'ATC',    43012721,         5,         cast (null as int)),
('hemophilus influenzae B conjugated',                                  'ATC',    586306,         6,         cast (null as int)),

('hepatitis A',                                                         'ATC',    529660,         2,         cast (null as int)),
('hepatitis A',                                                         'ATC',    596876,         1,         cast (null as int)),
('hepatitis A',                                                         'ATC',    44814322,         3,         cast (null as int)),

('hepatitis B',                                                         'ATC',    528323,         1,         cast (null as int)),
('hepatitis B',                                                         'ATC',    43532382,         2,         cast (null as int)),
('hepatitis B',                                                         'ATC',    43532406,         3,         cast (null as int)),

('measles live attenuated',                                             'ATC',    532272,         2,         cast (null as int)),
('measles live attenuated',                                             'ATC',    590675,         1,         cast (null as int)),
('measles live attenuated',                                             'ATC',    594249,         3,         cast (null as int)),
('measles live attenuated',                                             'ATC',    42903450,         4,         cast (null as int)),

('meningococcus A',                                                     'ATC',    509079,         1,         cast (null as int)),
('meningococcus A',                                                     'ATC',    528271,         2,         cast (null as int)),
('meningococcus A',                                                     'ATC',    40173198,         3,         cast (null as int)),

('meningococcus A purified polysaccharides antigen',                    'ATC',    509079,         1,         cast (null as int)),
('meningococcus A purified polysaccharides antigen',                    'ATC',    528271,         2,         cast (null as int)),
('meningococcus A purified polysaccharides antigen',                    'ATC',    40173198,         3,         cast (null as int)),

('meningococcus A purified polysaccharides antigen conjugated',         'ATC',    528271,         1,         cast (null as int)),
('meningococcus A purified polysaccharides antigen conjugated',         'ATC',    40173198,         2,         cast (null as int)),
('meningococcus A purified polysaccharides antigen conjugated',         'ATC',    509079,         3,         cast (null as int)),

('meningococcus B multicomponent vaccine',                              'ATC',    19016540,         2,         cast (null as int)),
('meningococcus B multicomponent vaccine',                              'ATC',    45775636,         1,         cast (null as int)),

('meningococcus B outer membrane vesicle vaccine',                      'ATC',    19016540,         2,         cast (null as int)),
('meningococcus B outer membrane vesicle vaccine',                      'ATC',    45775636,         1,         cast (null as int)),

('meningococcus C',                                                     'ATC',    509081,         1,         cast (null as int)),
('meningococcus C',                                                     'ATC',    528295,         2,         cast (null as int)),
('meningococcus C',                                                     'ATC',    40173205,         3,         cast (null as int)),

('meningococcus C conjugated',                                          'ATC',    528295,         1,         cast (null as int)),
('meningococcus C conjugated',                                          'ATC',    40173205,         2,         cast (null as int)),
('meningococcus C conjugated',                                          'ATC',    509081,         3,         cast (null as int)),

('meningococcus C purified polysaccharides antigen',                    'ATC',    509081,         1,         cast (null as int)),
('meningococcus C purified polysaccharides antigen',                    'ATC',    528295,         2,         cast (null as int)),
('meningococcus C purified polysaccharides antigen',                    'ATC',    40173205,         3,         cast (null as int)),

('meningococcus C purified polysaccharides antigen conjugated',         'ATC',    528295,         1,         cast (null as int)),
('meningococcus C purified polysaccharides antigen conjugated',         'ATC',    40173205,         2,         cast (null as int)),
('meningococcus C purified polysaccharides antigen conjugated',         'ATC',    509081,         3,         cast (null as int)),


('meningococcus W-135 purified polysaccharides antigen',                'ATC',    514012,         1,         cast (null as int)),
('meningococcus W-135 purified polysaccharides antigen',                'ATC',    528297,         2,         cast (null as int)),
('meningococcus W-135 purified polysaccharides antigen',                'ATC',    40173207,         3,         cast (null as int)),

('meningococcus W-135 purified polysaccharides antigen conjugated',     'ATC',    514012,         3,         cast (null as int)),
('meningococcus W-135 purified polysaccharides antigen conjugated',     'ATC',    528297,         1,         cast (null as int)),
('meningococcus W-135 purified polysaccharides antigen conjugated',     'ATC',    40173207,         2,         cast (null as int)),

('meningococcus Y purified polysaccharides antigen',                    'ATC',    514015,         1,         cast (null as int)),
('meningococcus Y purified polysaccharides antigen',                    'ATC',    528301,         2,         cast (null as int)),
('meningococcus Y purified polysaccharides antigen',                    'ATC',    40173209,         3,         cast (null as int)),

('meningococcus Y purified polysaccharides antigen conjugated',         'ATC',    514015,         3,         cast (null as int)),
('meningococcus Y purified polysaccharides antigen conjugated',         'ATC',    528301,         1,         cast (null as int)),
('meningococcus Y purified polysaccharides antigen conjugated',         'ATC',    40173209,         2,         cast (null as int)),

('mumps immunoglobulin',                                                'ATC',    0,         0,         cast (null as int)),

('mumps live attenuated',                                               'ATC',    523620,         2,         cast (null as int)),
('mumps live attenuated',                                               'ATC',    529713,         1,         cast (null as int)),
('mumps live attenuated',                                               'ATC',    43532049,         3,         cast (null as int)),

('other meningococcal monovalent purified polysaccharides antigen',     'ATC',    515671,         6,         cast (null as int)),
('other meningococcal monovalent purified polysaccharides antigen',     'ATC',    19016540,         1,         cast (null as int)),
('other meningococcal monovalent purified polysaccharides antigen',     'ATC',    45775636,         2,         cast (null as int)),
('other meningococcal monovalent purified polysaccharides antigen',     'ATC',    509081,         3,         cast (null as int)),
('other meningococcal monovalent purified polysaccharides antigen',     'ATC',    514012,         4,         cast (null as int)),
('other meningococcal monovalent purified polysaccharides antigen',     'ATC',    514015,         5,         cast (null as int)),

('other meningococcal polyvalent purified polysaccharides antigen',     'ATC',    515671,         7,         cast (null as int)),
('other meningococcal polyvalent purified polysaccharides antigen',     'ATC',    19016540,         1,         cast (null as int)),
('other meningococcal polyvalent purified polysaccharides antigen',     'ATC',    45775636,         2,         cast (null as int)),
('other meningococcal polyvalent purified polysaccharides antigen',     'ATC',    509081,         3,         cast (null as int)),
('other meningococcal polyvalent purified polysaccharides antigen',     'ATC',    514012,         4,         cast (null as int)),
('other meningococcal polyvalent purified polysaccharides antigen',     'ATC',    514015,         5,         cast (null as int)),
('other meningococcal polyvalent purified polysaccharides antigen',     'ATC',    509079,         6,         cast (null as int)),

('paratyphi types',                                                     'ATC',    0,         0,         cast (null as int)),

('pertussis',                                                           'ATC',    529218,         2,         cast (null as int)),
('pertussis',                                                           'ATC',    19033193,         1,         cast (null as int)),
('pertussis',                                                           'ATC',    46221326,         3,         cast (null as int)),

('pertussis immunoglobulin',                                            'ATC',    0,         0,         cast (null as int)),

('pertussis inactivated whole cell',                                    'ATC',    19033193,         1,         cast (null as int)),
('pertussis inactivated whole cell',                                    'ATC',    46221326,         2,         cast (null as int)),

('pertussis inactivated whole cell combinations with toxoids',          'ATC',    19033193,         1,         cast (null as int)),
('pertussis inactivated whole cell combinations with toxoids',          'ATC',    46221326,         2,         cast (null as int)),

('pertussis purified antigen',                                          'ATC',    529218,         1,         cast (null as int)),
('pertussis purified antigen',                                          'ATC',    19033193,         2,         cast (null as int)),
('pertussis purified antigen',                                          'ATC',    46221326,         3,         cast (null as int)),

('pertussis purified antigen combinations with toxoids',                'ATC',    529218,         1,         cast (null as int)),
('pertussis purified antigen combinations with toxoids',                'ATC',    19033193,         2,         cast (null as int)),
('pertussis purified antigen combinations with toxoids',                'ATC',    46221326,         3,         cast (null as int)),

('poliomyelitis',                                                       'ATC',    523283,         1,         cast (null as int)),
('poliomyelitis',                                                       'ATC',    523365,         2,         cast (null as int)),
('poliomyelitis',                                                       'ATC',    523367,         3,         cast (null as int)),
('poliomyelitis',                                                       'ATC',    43532418,         4,         cast (null as int)),

('rubella',                                                             'ATC',    523212,         2,         cast (null as int)),
('rubella',                                                             'ATC',    19136026,         1,         cast (null as int)),
('rubella',                                                             'ATC',    43012953,         3,         cast (null as int)),

('rubella immunoglobulin',                                              'ATC',    0,         0,         cast (null as int)),

('rubella live attenuated',                                             'ATC',    523212,         1,         cast (null as int)),
('rubella live attenuated',                                             'ATC',    19136026,         2,         cast (null as int)),
('rubella live attenuated',                                             'ATC',    43012953,         3,         cast (null as int)),

('tetanus',                                                             'ATC',    529411,         1,         cast (null as int)),

('tetanus antitoxin',                                                   'ATC',    35604680,         1,         cast (null as int)),

('tetanus immunoglobulin',                                              'ATC',    35604680,         1,         cast (null as int)),

('tetanus toxoid',                                                      'ATC',    529411,         1,         cast (null as int)),

('typhoid',                                                             'ATC',    523202,         4,         cast (null as int)),
('typhoid',                                                             'ATC',    532881,         3,         cast (null as int)),
('typhoid',                                                             'ATC',    19052554,         2,         cast (null as int)),
('typhoid',                                                             'ATC',    35603020,         1,         cast (null as int)),

('typhoid inactivated whole cell',                                      'ATC',    35603020,         1,         cast (null as int)),

('typhoid oral live attenuated',                                        'ATC',    523202,           1,         cast (null as int)),
('typhoid oral live attenuated',                                        'ATC',    19052554,         2,         cast (null as int)),
('typhoid oral live attenuated',                                        'ATC',    35603020,         3,         cast (null as int)),

('typhoid purified polysaccharide antigen',                             'ATC',    532881,           1,         cast (null as int)),
('typhoid purified polysaccharide antigen',                             'ATC',    19052554,         3,         cast (null as int)),
('typhoid purified polysaccharide antigen',                             'ATC',    35603020,         2,         cast (null as int)),

('typhoid vaccine inactivated whole cell',                              'ATC',    35603020,         1,         cast (null as int)),

('typhus exanthematicus inactivated whole cell',                        'ATC',    35603020,         1,         cast (null as int)),

('varicella live attenuated',                                           'ATC',    42800027,         1,         cast (null as int)),
('varicella live attenuated',                                           'ATC',    532454,         2,         cast (null as int))
;


/*--auto-mapping of ingredients:
SELECT DISTINCT atc_name, c.*
FROM dev_atc.manual_split

LEFT JOIN devv5.concept c
         ON c.concept_name ilike ('%' || atc_name || '%') AND c.vocabulary_id = 'RxNorm' AND c.standard_concept = 'S' AND c.domain_id = 'Drug' AND c.concept_class_id = 'Ingredient'
;

SELECT DISTINCT atc_name, c.*
FROM dev_atc.manual_split

LEFT JOIN devv5.concept c
         ON c.concept_name ~* atc_name AND c.vocabulary_id = 'RxNorm' AND c.standard_concept = 'S' AND c.domain_id = 'Drug' AND c.concept_class_id = 'Ingredient'
;

--1st word
SELECT substring('!@#$%^&*~\/  !@#$%first@#$% !@#$%222!@#$% !@#$%second!@#$% third \waa' from '\w+')
;
--2nd word
SELECT substring('!@#$%^&*~\/  !@#$%first@#$% !@#$%222!@#$% !@#$%second!@#$% third \waa' from '(?<=.*\w+.*\s+.*)\w+')
;

--3rd word
SELECT substring('!@#$%^&*~\/  !@#$%first@#$% !@#$%222!@#$% !@#$%second!@#$% third \waa' from '(?<=.*\w+.*\s+.*\w+.*\s+.*)\w+')
;


SELECT substring(atc_name from '\w+') || ' ' ||substring(atc_name from '(?<=.*\w+.*\s+.*)\w+') || ' ' || substring(atc_name from '(?<=.*\w+.*\s+.*\w+.*\s+.*)\w+')
FROM dev_atc.manual_split
;

SELECT DISTINCT *
FROM dev_atc.manual_split
       LEFT JOIN devv5.concept c ON c.concept_name ~* (substring(ingredient_name from '\w+') || ' ' ||
                                                       substring(ingredient_name from '(?<=.*\w+.*\s+.*)\w+'))


                                      AND c.vocabulary_id = 'RxNorm'
                                      AND c.standard_concept = 'S'
                                      AND c.domain_id = 'Drug'
                                      AND c.concept_class_id = 'Ingredient';

SELECT DISTINCT *
FROM dev_atc.manual_split
       LEFT JOIN devv5.concept c ON (c.concept_name ~* (substring(ingredient_name from '\w+') || ' ' ||
                                                       substring(ingredient_name from '(?<=.*\w+.*\s+.*)\w+'))
        OR c.concept_name ~* (substring(ingredient_name from '(?<=.*\w+.*\s+.*)\w+') || ' ' || substring(ingredient_name from '\w+'))
        OR c.concept_name ~* substring(ingredient_name from '\w+')
        OR c.concept_name ~* substring(ingredient_name from '(?<=.*\w+.*\s+.*)\w+')
                                        )
                                      AND c.vocabulary_id = 'RxNorm'
                                      AND c.standard_concept = 'S'
                                      AND c.domain_id = 'Drug'
                                      AND c.concept_class_id = 'Ingredient';*/

/*--Simple attempt of mapping
with first as (SELECT dev_atc.manual.atc_code, atc_name, regexp_split_to_table (dev_atc.manual.atc_name, '-|[[:blank:]]and[[:blank:]]|,[[:blank:]]combinations[[:blank:]]with[[:blank:]]') as name
FROM dev_atc.manual
WHERE dev_atc.manual.atc_name not ilike '%men%' AND dev_atc.manual.atc_name not in ('sodium chloride, hypertonic') AND dev_atc.manual.atc_name not ilike '%levodopa%')

SELECT * from first
LEFT JOIN devv5.concept c
ON c.concept_name ilike ('%' || name || '%') AND c.vocabulary_id = 'RxNorm' AND c.standard_concept = 'S' AND c.domain_id = 'Drug' AND c.concept_class_id = 'Ingredient'
ORDER BY atc_code, concept_name asc
;*/


/*--Getting all ancestors of vaccines:
SELECT DISTINCT c2.*

FROM dev_atc.manual atc

JOIN devv5.concept c
ON atc.atc_code = c.concept_code

JOIN devv5.concept_ancestor ca
ON c.concept_id = ca.descendant_concept_id AND ca.max_levels_of_separation > 0

JOIN devv5.concept c2
ON ca.ancestor_concept_id = c2.concept_id

WHERE atc.atc_name not in ('sodium chloride, hypertonic') AND atc.atc_name not ilike '%levodopa%'
;*/

/*--Shorten the words
SELECT string_agg (left(word, -2), ' ') AS our_meningococcus
  FROM regexp_split_to_table('meningococcus A,C,Y,W-135, tetravalent purified polysaccharides antigen conjugated', '\s+') t(word);
;*/


/*--Demonstration of hierarchy:
SELECT *
FROM dev_atc.relationship_to_concept rtc

JOIN dev_atc.internal_relationship_stage irs
ON rtc.concept_code_1 = irs.concept_code_2
LIMIT 100
;

SELECT *
FROM dev_atc.relationship_to_concept rtc
WHERE concept_code_1 = 'Beclamide'
;

SELECT *
FROM dev_atc.internal_relationship_stage
WHERE concept_code_1 like '%M05BA02%'
;*/


/*
SELECT * FROM dev_atc.relationship_to_concept_preliminary
;*/



/*--Getting all ancestors of insulins:
SELECT DISTINCT c2.*

FROM dev_atc.atc_drugs_scraper atc

JOIN devv5.concept c
ON atc.atc_code = c.concept_code

JOIN devv5.concept_ancestor ca
ON c.concept_id = ca.descendant_concept_id AND ca.max_levels_of_separation > 0

JOIN devv5.concept c2
ON ca.ancestor_concept_id = c2.concept_id

WHERE atc.atc_name ILIKE '%insu%'
;

-- Verification the child names without 'insu'
SELECT *
FROM devv5.concept_ancestor ca
JOIN devv5.concept c
ON ca.descendant_concept_id = c.concept_id AND ca.ancestor_concept_id = 21600713

WHERE c.vocabulary_id = 'ATC' AND c.concept_name not ILIKE '%insu%'
;*/



--retrieving of all the vaccines from atc_drugs_scraper
SELECT *
FROM atc_drugs_scraper
WHERE length(atc_code) < 7 AND
   atc_code ~* '^J06|^J07'
ORDER BY atc_code;


--what is already mapped
select *
FROM final_assembly
WHERE length(atc_code) = 7 AND
   atc_code ~* '^J07'
--AND concept_class_id = 'Clinical Drug Form'
;

--what is really already mapped
select *
FROM class_to_rx_descendant
WHERE length(class_code) = 7 AND
   class_code ~* '^J06|^J07'
--AND concept_class_id = 'Clinical Drug Form'
;

--what is not mapped manually
SELECT DISTINCT atc_code, atc_name
FROM atc_drugs_scraper
WHERE length(atc_code) = 7 AND
   atc_code ~* '^J06|^J07'

EXCEPT

select DISTINCT atc_code, atc_name
FROM manual_split
WHERE length(atc_code) = 7 AND
   atc_code ~* '^J06|^J07'

ORDER BY atc_code
;


select *
FROM relationship_to_concept_preliminary
;




--mapping of mono-ingredient vaccines
SELECT /*m.atc_code, m.atc_name, c.concept_id,c.concept_code,
       c.concept_name, c.concept_class_id, c.standard_concept,
       c.invalid_reason,c.domain_id, c.vocabulary_id*/
DISTINCT
FROM manual m
LEFT JOIN manual_split ms
ON m.atc_code=ms.atc_code
LEFT JOIN relationship_to_concept_preliminary pre
ON ms.ingredient_name=pre.concept_code_1
LEFT JOIN devv5.concept_relationship cr
ON pre.concept_id_2=cr.concept_id_1
    LEFT JOIN devv5.concept cc
    ON cc.concept_id=pre.concept_id_2
LEFT JOIN devv5.concept c ON c.concept_id=cr.concept_id_2
WHERE EXISTS (
    SELECT 1
FROM dev_atc.manual m1
LEFT JOIN manual_split ms1
ON m1.atc_code=ms1.atc_code
    WHERE m.atc_code=m1.atc_code
GROUP BY m1.atc_code
HAVING count (DISTINCT ms1.ingredient_name)<2
    )
  /*AND NOT exists(SELECT 1
             FROM devv5.concept c2
                 JOIN devv5.concept_relationship cr2
                           ON c2.concept_id = cr2.concept_id_2
             WHERE cr2.relationship_id = 'RxNorm ing of'
  AND c2.concept_id=c.concept_id
             GROUP BY c2.concept_id
             HAVING COUNT(DISTINCT cr2.concept_id_1)>2
    )*/
AND c.vocabulary_id IN ('RxNorm' ,'RxNorm Extension')
AND c.concept_class_id='Clinical Drug Form'
AND c.standard_concept='S'
;


select *
FROM relationship_to_concept_preliminary;

SELECT *
FROM manual m

WHERE exists (
    SELECT 1
FROM dev_atc.manual m1
left join manual_split ms1
on m1.atc_code=ms1.atc_code
    where m.atc_code=m1.atc_code
group by m1.atc_code
having count (distinct ms1.ingredient_name)=1
    )

;


select distinct m.atc_code,
                m.atc_name,
                c.concept_id,
                c.concept_code,
                c.concept_name,
                c.concept_class_id,
                c.standard_concept,
                c.invalid_reason,
                c.domain_id,
                c.vocabulary_id
from manual m
         left join manual_split ms
                   on m.atc_code = ms.atc_code
         join relationship_to_concept_preliminary pre
              on ms.ingredient_name = pre.concept_code_1
         join devv5.concept_relationship cr
              on pre.concept_id_2 = cr.concept_id_1
         join devv5.concept cc
              on cc.concept_id = pre.concept_id_2
         left join devv5.concept c
                   on c.concept_id = cr.concept_id_2
                       and c.vocabulary_id = 'RxNorm'
                       and c.concept_class_id = 'Clinical Drug Form'
                       and c.standard_concept = 'S'
where exists(
        SELECT 1
        FROM dev_atc.manual m1
                 left join manual_split ms1
                           on m1.atc_code = ms1.atc_code
        where m.atc_code = m1.atc_code
        group by m1.atc_code
        having count(distinct ms1.ingredient_name) = 1
    )

  and not exists(select 1
                 from devv5.concept c2
                          join devv5.concept_relationship cr2
                               on c2.concept_id = cr2.concept_id_2
                 where cr2.relationship_id = 'RxNorm ing of'
                   and c2.concept_id = c.concept_id
                 group by c2.concept_id
                 having count(distinct cr2.concept_id_1) > 2
    )
;




--DROP TABLE vaccines_atc_to_Rx_RxE;
CREATE TABLE vaccines_atc_to_Rx_RxE (
    atc_code varchar,
    atc_name varchar,
    comments varchar,
    concept_id int,
    concept_code varchar,
    concept_name varchar,
    concept_class_id varchar,
    standard_concept varchar,
    invalid_reason varchar,
    domain_id varchar,
    vocabulary_id varchar
) WITH OIDS;

SELECT *
FROM vaccines_atc_to_Rx_RxE;


--DROP TABLE vaccines_mistakes;
CREATE TABLE vaccines_mistakes (
    comments varchar,
    concept_id int,
    concept_code varchar,
    concept_name varchar,
    concept_class_id varchar,
    standard_concept varchar,
    invalid_reason varchar,
    domain_id varchar,
    vocabulary_id varchar
) WITH OIDS;

SELECT *
FROM vaccines_mistakes;

--TODO Check if both tables have correct concept_id
SELECT *
FROM vaccines_atc_to_Rx_RxE j1
WHERE NOT EXISTS (  SELECT *
                    FROM vaccines_atc_to_Rx_RxE j2
                    JOIN devv5.concept c
                        ON j2.concept_id = c.concept_id
                            AND c.concept_name = j2.concept_name
                            AND c.vocabulary_id = j2.vocabulary_id
                            AND c.domain_id = j2.domain_id
                            AND c.standard_concept = 'S'
                            AND c.invalid_reason is NULL
                    WHERE j1.OID = j2.OID
                  );

SELECT *
FROM vaccines_mistakes j1
WHERE NOT EXISTS (  SELECT *
                    FROM vaccines_mistakes j2
                    JOIN devv5.concept c
                        ON j2.concept_id = c.concept_id
                            AND c.concept_name = j2.concept_name
                            AND c.vocabulary_id = j2.vocabulary_id
                            AND c.domain_id = j2.domain_id
                            AND c.standard_concept = 'S'
                            AND c.invalid_reason is NULL
                    WHERE j1.OID = j2.OID
                  );

--TODO: check if concept is existing in both lists (ATC + corrections)
SELECT concept_id
FROM vaccines_atc_to_Rx_RxE t1
WHERE EXISTS (
    SELECT 1
    FROM vaccines_mistakes t2
    WHERE t1.concept_id = t2.concept_id);

--TODO: check concepts mentioned twice
SELECT *
FROM vaccines_atc_to_Rx_RxE t1
WHERE concept_id != 0
    AND
    concept_id in (
    SELECT concept_id
    FROM vaccines_atc_to_Rx_RxE t2
    GROUP BY concept_id
    HAVING COUNT (*) > 1
    );

SELECT *
FROM vaccines_mistakes t1
WHERE concept_id != 0
    AND
    concept_id in (
    SELECT concept_id
    FROM vaccines_mistakes t2
    GROUP BY concept_id
    HAVING COUNT (*) > 1
    );

--TODO Check whether all ATC J06-07 are mapped
SELECT DISTINCT atc_code
FROM atc_drugs_scraper
WHERE length(atc_code) = 7 AND
   atc_code ~* '^J06|^J07'

EXCEPT

SELECT DISTINCT atc_code
FROM vaccines_atc_to_Rx_RxE;



--TODO: check if some forms are lost
--DROP TABLE vaccine_all_possible_ingredients;
CREATE TABLE vaccine_all_possible_ingredients as (

--influenza
SELECT concept_id FROM (
SELECT concept_id, concept_name
FROM devv5.concept
WHERE concept_name ~* 'influenza|Grippe|Orthomyxov|flu$'
AND concept_name !~* 'Haemophilus'
AND domain_id = 'Drug'
AND concept_class_id = 'Ingredient'
AND standard_concept = 'S'
ORDER BY concept_name
) as a

UNION ALL

--rubella
SELECT concept_id FROM (
SELECT concept_id, concept_name
FROM devv5.concept
WHERE concept_name ~* 'rubella|RuV|Rubiv|Togav'
AND concept_name !~* 'extract|balsam|Peruvoside|Pyruvate|Peruvianum|Phenylpyruvic|Phenylpyruvic|Physalis|Pyruvaldehyde'
AND domain_id = 'Drug'
AND concept_class_id = 'Ingredient'
AND standard_concept = 'S'
ORDER BY concept_name
) as a

UNION ALL

--mumps
SELECT concept_id FROM (
SELECT concept_id, concept_name
FROM devv5.concept
WHERE concept_name ~* 'mumps|rubulavirus'
AND concept_name !~* 'skin'
AND domain_id = 'Drug'
AND concept_class_id = 'Ingredient'
AND standard_concept = 'S'
ORDER BY concept_name
) as a

UNION ALL

--measles
SELECT concept_id FROM (
SELECT concept_id, concept_name
FROM devv5.concept
WHERE concept_name ~* 'measles|morbilliv|morbiliv|MeV'
AND concept_name !~* 'amenamevir|mevalonolactone'
AND domain_id = 'Drug'
AND concept_class_id = 'Ingredient'
AND standard_concept = 'S'
ORDER BY concept_name
) as a

UNION ALL

--poliomyelitis
SELECT concept_id FROM (
SELECT concept_id, concept_name
FROM devv5.concept
WHERE concept_name ~* 'polio|Enterovi'
--AND concept_name !~* ''
AND domain_id = 'Drug'
AND concept_class_id = 'Ingredient'
AND standard_concept = 'S'
ORDER BY concept_name
) as a

UNION ALL

--diphtheria
SELECT concept_id FROM (
SELECT concept_id, concept_name
FROM devv5.concept
WHERE concept_name ~* 'dipht|Coryne|Corine|C\.d|C\. d'
AND concept_name !~* 'Neisseria meningitidis serogroup|Streptococcus pneumoniae serotype|dioscorine|gonadotropin releasing factor|Diphtherial respiratory pseudomembrane preparation|Antitoxin'
AND domain_id = 'Drug'
AND concept_class_id = 'Ingredient'
AND standard_concept = 'S'
ORDER BY concept_name
) as a

UNION ALL

--tetanus
SELECT concept_id FROM (
SELECT concept_id, concept_name
FROM devv5.concept
WHERE concept_name ~* 'tetan|C\.t|C\. t|Clostrid|Klostrid'
AND concept_name !~* 'Neisseria meningitidis|butyricum|Cefotetan|histolyticum|difficile|perfringens|botulinum|Haemophilus influenzae'
AND domain_id = 'Drug'
AND concept_class_id = 'Ingredient'
AND standard_concept = 'S'
) as a

UNION ALL

--pertussis
SELECT concept_id FROM (
SELECT concept_id, concept_name
FROM devv5.concept
WHERE concept_name ~* 'pertus|Bord|B\. p|B\.p|Pertactin|Fimbriae|Filamentous'
AND concept_name !~* 'Human Sputum\, Bordetella Pertussis Infected'
AND domain_id = 'Drug'
AND concept_class_id = 'Ingredient'
AND standard_concept = 'S'
) as a

UNION ALL

--hepatitis B
SELECT concept_id FROM (
SELECT concept_id, concept_name, vocabulary_id
FROM devv5.concept
WHERE concept_name ~* 'hepat|HBV|Orthohepad|Hepadn'
AND concept_name !~* 'Anemone|oscillococcinum|Hepatitis A|NOSODES|Hepatitis C'
AND domain_id = 'Drug'
AND concept_class_id = 'Ingredient'
AND standard_concept = 'S'
) as a

UNION ALL

--hemophilus influenzae B
SELECT concept_id FROM (
SELECT concept_id, concept_name
FROM devv5.concept
WHERE concept_name ~* 'hemophilus|haemophilus|influenz| hib|hib |H\.inf|H\. inf'
AND concept_name !~* 'virus|tipepidine hibenzate|Influenzinum for homeopathic preparations'
AND domain_id = 'Drug'
AND concept_class_id = 'Ingredient'
AND standard_concept = 'S'
ORDER BY concept_name
) as a

UNION ALL

--Neisseria
SELECT concept_id FROM (
SELECT concept_id, concept_name
FROM devv5.concept
WHERE concept_name ~* 'mening|N\.m|N\. m|Neis'
AND concept_name !~* 'Haemophilus influenzae b|neisseria catarrhalis flava'
AND domain_id = 'Drug'
AND concept_class_id = 'Ingredient'
AND standard_concept = 'S'
) as a

UNION ALL

--rabies
SELECT concept_id FROM (
SELECT concept_id, concept_name, vocabulary_id
FROM devv5.concept
WHERE concept_name ~* 'rabies|rhabdo|rabdo|lyssav'
--AND concept_name !~* 'globulin|SERUM'
AND domain_id = 'Drug'
AND concept_class_id = 'Ingredient'
AND standard_concept = 'S'
) as a

UNION ALL

--papillomavirus
SELECT concept_id FROM (
SELECT concept_id, concept_name, vocabulary_id
FROM devv5.concept
WHERE concept_name ~* 'papilloma|HPV'
--AND concept_name !~* ''
AND domain_id = 'Drug'
AND concept_class_id = 'Ingredient'
AND standard_concept = 'S'
) as a

UNION ALL

--smallpox
SELECT concept_id FROM (
SELECT concept_id, concept_name, vocabulary_id
FROM devv5.concept
WHERE concept_name ~* 'smallpox|small-pox|Variola|Poxv|Orthopoxv'
--AND concept_name !~* ''
AND domain_id = 'Drug'
AND concept_class_id = 'Ingredient'
AND standard_concept = 'S'
) as a

UNION ALL

--yellow fever
SELECT concept_id FROM (
SELECT concept_id, concept_name, vocabulary_id
FROM devv5.concept
WHERE concept_name ~* 'Yellow Fever|Yellow-Fever|Flaviv'
--AND concept_name !~* ''
AND domain_id = 'Drug'
AND concept_class_id = 'Ingredient'
AND standard_concept = 'S'
) as a

UNION ALL

--varicella/zoster
SELECT concept_id FROM (
SELECT concept_id, concept_name, vocabulary_id
FROM devv5.concept
WHERE concept_name ~* 'varicel|zoster|herpes|chickenpox|VZV|HHV|chicken-pox'
AND concept_name !~* 'herpesvirus (6|5|1|2)|marina'
AND domain_id = 'Drug'
AND concept_class_id = 'Ingredient'
AND standard_concept = 'S'
) as a

UNION ALL

--rota virus
SELECT concept_id FROM (
SELECT concept_id, concept_name, vocabulary_id
FROM devv5.concept
WHERE concept_name ~* 'rotav|Reov'
AND concept_name !~* 'drotaverin'
AND domain_id = 'Drug'
AND concept_class_id = 'Ingredient'
AND standard_concept = 'S'
) as a

UNION ALL

--hepatitis A
SELECT concept_id FROM (
SELECT concept_id, concept_name, vocabulary_id
FROM devv5.concept
WHERE concept_name ~* 'hepat|HAV'
AND concept_name !~* 'hepatitis B|Hepatitis C|ethaverine|Anemone Hepatica|oscillococcinum|root|NOSODES'
AND domain_id = 'Drug'
AND concept_class_id = 'Ingredient'
AND standard_concept = 'S'
) as a

UNION ALL

--typhoid
SELECT concept_id FROM (
SELECT concept_id, concept_name, vocabulary_id
FROM devv5.concept
WHERE concept_name ~* 'typh|Salmone|S\.t|S\. t|S\.e|S\. e'
AND concept_name !~* 'Chondrodendron Platyphyllum|platyphylla|Styphnolobium|platyphyllos|Typhonium|enteritidis'
AND domain_id = 'Drug'
AND concept_class_id = 'Ingredient'
AND standard_concept = 'S'
) as a

UNION ALL

--encephalitis
SELECT concept_id FROM (
SELECT concept_id, concept_name, vocabulary_id
FROM devv5.concept
WHERE concept_name ~* 'encephalitis|tick|Flaviv|Japanese'
AND concept_name !~* 'Antivenom|extract'
AND domain_id = 'Drug'
AND concept_class_id = 'Ingredient'
AND standard_concept = 'S'
) as a

UNION ALL

--typhus exanthematicus
SELECT concept_id FROM (
SELECT concept_id, concept_name, vocabulary_id
FROM devv5.concept
WHERE concept_name ~* 'typhus|exanthematicus|Rickettsia|prowaz|R\.p|R\. p|Orientia|tsutsug|O\.t|O\. t|R\. ty|R\. ty|felis|typhi|R\. f|R\. f'
AND concept_name !~* 'extract|Salmonella|ty-2|rickettsii|Vi|catus'
AND domain_id = 'Drug'
AND concept_class_id = 'Ingredient'
AND standard_concept = 'S'
) as a

UNION ALL

--tuberculosis
SELECT concept_id FROM (
SELECT concept_id, concept_name
FROM devv5.concept
WHERE concept_name ~* 'tuberc|M\. t|M\.t|mycobacterium|bcg|Calmet|Guerin'
AND concept_name !~* 'Tuberculin|phlei'
AND domain_id = 'Drug'
AND concept_class_id = 'Ingredient'
AND standard_concept = 'S'
) as a

UNION ALL

--pneumococcus
SELECT concept_id FROM (
SELECT concept_id, concept_name
FROM devv5.concept
WHERE concept_name ~* 'pneumo|S\.pn|S\. pn'
AND concept_name !~* 'Klebsiella pneumoniae|Legionella pneumophila|Mycoplasma pneumoniae'
AND domain_id = 'Drug'
AND concept_class_id = 'Ingredient'
AND standard_concept = 'S'
) as a

UNION ALL

--plague
SELECT concept_id FROM (
SELECT concept_id, concept_name
FROM devv5.concept
WHERE concept_name ~* 'plague|Yersinia|Y\.p|Y\. p'
AND concept_name !~* 'Yersinia enterocolitica'
AND domain_id = 'Drug'
AND concept_class_id = 'Ingredient'
AND standard_concept = 'S'
) as a

UNION ALL

--cholera
SELECT concept_id FROM (
SELECT concept_id, concept_name
FROM devv5.concept
WHERE concept_name ~* 'choler|Vibri|V\.c|V\. c'
--AND concept_name !~* ''
AND domain_id = 'Drug'
AND concept_class_id = 'Ingredient'
AND standard_concept = 'S'
ORDER BY concept_name
) as a
);

SELECT *
FROM vaccine_all_possible_ingredients;


SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

    AND concept_id NOT IN (SELECT concept_id FROM vaccines_atc_to_rx_rxe UNION ALL SELECT concept_id FROM vaccines_mistakes)

    AND EXISTS  (SELECT 1
                 FROM devv5.concept_relationship cr
                 WHERE cr.concept_id_1 in (SELECT concept_id FROM vaccine_all_possible_ingredients)
                 AND cr.concept_id_2 = c.concept_id
                 )

ORDER BY concept_name
;



--TODO: check if ingredients having no forms are lost in mapping
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.concept_id in (SELECT * FROM vaccine_all_possible_ingredients)
  AND c.concept_id NOT IN (SELECT concept_id FROM vaccines_atc_to_rx_rxe UNION ALL SELECT concept_id FROM vaccines_mistakes)

    AND NOT EXISTS  (SELECT 1
                    FROM devv5.concept_relationship cr
                    JOIN devv5.concept cc
                    ON cr.concept_id_1 = cc.concept_id AND cc.concept_class_id = 'Clinical Drug Form'

                    WHERE c.concept_id = cr.concept_id_2
                        AND cr.invalid_reason IS NULL
                    )
ORDER BY concept_name
;







--to find the form
--influenza, inactivated, whole virus
--influenza, inactivated, split virus or surface antigen
--influenza, live attenuated
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'influenza|Grippe|Orthomyxov|flu$'
                                             AND concept_name !~* 'Haemophilus'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             --AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;

--to find the form
--rubella, live attenuated
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'rubella|RuV|Rubiv|Togav'
                                             AND concept_name !~* 'extract|Immunoglobulin|balsam|Peruvoside|Pyruvate|Peruvianum|Phenylpyruvic|Phenylpyruvic|Physalis|Pyruvaldehyde'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('Measles Vaccine', 'MEASLES VIRUS VACCINE,LIVE ATTENUATED', 'Measles Virus Vaccine Live, Enders'' attenuated Edmonston strain', 'Mumps Virus Vaccine Live, Jeryl Lynn Strain')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             --AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--rubella, combinations with mumps, live attenuated
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'rubella|RuV|Rubiv|Togav'
                                             AND concept_name !~* 'extract|Immunoglobulin|balsam|Peruvoside|Pyruvate|Peruvianum|Phenylpyruvic|Phenylpyruvic|Physalis|Pyruvaldehyde'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

        AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'mumps|rubulavirus'
                                             AND concept_name !~* 'skin'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('Measles Vaccine', 'MEASLES VIRUS VACCINE,LIVE ATTENUATED', 'Measles Virus Vaccine Live, Enders'' attenuated Edmonston strain')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             --AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;



--to find the form
--measles, combinations with mumps and rubella, live attenuated
--measles, combinations with mumps, rubella and varicella, live attenuated
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'measles|morbilliv|morbiliv|MeV'
                                             AND concept_name !~* 'amenamevir|mevalonolactone'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'rubella|RuV|Rubiv|Togav'
                                             AND concept_name !~* 'extract|Immunoglobulin|balsam|Peruvoside|Pyruvate|Peruvianum|Phenylpyruvic|Phenylpyruvic|Physalis|Pyruvaldehyde'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

        AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'mumps|rubulavirus'
                                             AND concept_name !~* 'skin'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--measles, combinations with rubella, live attenuated
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'measles|morbilliv|morbiliv|MeV'
                                             AND concept_name !~* 'amenamevir|mevalonolactone'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'rubella|RuV|Rubiv|Togav'
                                             AND concept_name !~* 'extract|Immunoglobulin|balsam|Peruvoside|Pyruvate|Peruvianum|Phenylpyruvic|Phenylpyruvic|Physalis|Pyruvaldehyde'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('Mumps Vaccine', 'Mumps Virus Vaccine Live, Jeryl Lynn Strain')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             --AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--measles, combinations with mumps, live attenuated
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'measles|morbilliv|morbiliv|MeV'
                                             AND concept_name !~* 'amenamevir|mevalonolactone'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

      AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'mumps|rubulavirus'
                                             AND concept_name !~* 'skin'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('Rubella Virus Vaccine Live (Wistar RA 27-3 Strain)')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--measles, live attenuated
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'measles|morbilliv|morbiliv|MeV'
                                             AND concept_name !~* 'amenamevir|mevalonolactone'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('Mumps Vaccine', 'Mumps Virus Vaccine Live, Jeryl Lynn Strain', 'Rubella virus')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--mumps, live attenuated
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'mumps|rubulavirus'
                                             AND concept_name !~* 'skin'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('MEASLES VIRUS VACCINE,LIVE ATTENUATED', 'Measles Vaccine', 'Measles Virus Vaccine Live, Enders'' attenuated Edmonston strain', 'Rubella virus vaccine',
                                                                    'Measles Virus Vaccine Live, Enders'' attenuated Edmonston strain', 'Rubella virus', 'Rubella Virus Vaccine Live (Wistar RA 27-3 Strain)')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--poliomyelitis oral, monovalent, live attenuated
--poliomyelitis oral, bivalent, live attenuated
--poliomyelitis oral, trivalent, live attenuated
--poliomyelitis, trivalent, inactivated, whole virus
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'polio|Enterovi'
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('poliomyelitis, trivalent, inactivated, whole virus', 'acellular pertussis vaccine, inactivated', 'diphtheria toxoid vaccine, inactivated')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--diphtheria-poliomyelitis-tetanus
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'polio|Enterovi'
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

      AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'dipht|Coryne|Corine|C\.d|C\. d'
                                             AND concept_name !~* 'Neisseria meningitidis serogroup|Streptococcus pneumoniae serotype|dioscorine|gonadotropin releasing factor|Diphtherial respiratory pseudomembrane preparation|Antitoxin'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

      AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'tetan|C\.t|C\. t|Clostrid|Klostrid'
                                             AND concept_name !~* 'Neisseria meningitidis|butyricum|Cefotetan|histolyticum|difficile|perfringens|botulinum|Haemophilus influenzae|immune globulin'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('acellular pertussis vaccine, inactivated', 'Bordetella pertussis', 'Haemophilus influenzae type b, capsular polysaccharide inactivated tetanus toxoid conjugate vaccine',
                                                                   'influenza B virus antigen, Hong Kong 330-2001', 'Pertussis Vaccine')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--diphtheria-pertussis-poliomyelitis-tetanus
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

    AND EXISTS  (SELECT 1
              FROM devv5.concept_relationship cr
              WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                           SELECT concept_id, concept_name
                                           FROM devv5.concept
                                           WHERE concept_name ~* 'pertus|Bord|B\. p|B\.p|Pertactin|Fimbriae|Filamentous'
                                           AND concept_name !~* 'Human Sputum\, Bordetella Pertussis Infected'
                                           AND domain_id = 'Drug'
                                           AND concept_class_id = 'Ingredient'
                                           AND standard_concept = 'S'
                                           ) as a )
              AND cr.concept_id_2 = c.concept_id
              )

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'polio|Enterovi'
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('Haemophilus influenzae type b', 'Haemophilus influenzae b (Ross strain) capsular polysaccharide Meningococcal Protein Conjugate Vaccine', 'influenza B virus antigen, Hong Kong 330-2001',
                                                                   'Haemophilus influenzae type b, capsular polysaccharide inactivated tetanus toxoid conjugate vaccine', 'Hepatitis B Surface Antigen Vaccine', 'Haemophilus B Conjugate Vaccine')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--diphtheria-pertussis-poliomyelitis-tetanus-hepatitis B
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

    AND EXISTS  (SELECT 1
              FROM devv5.concept_relationship cr
              WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                           SELECT concept_id, concept_name
                                           FROM devv5.concept
                                           WHERE concept_name ~* 'pertus|Bord|B\. p|B\.p|Pertactin|Fimbriae|Filamentous'
                                           AND concept_name !~* 'Human Sputum\, Bordetella Pertussis Infected'
                                           AND domain_id = 'Drug'
                                           AND concept_class_id = 'Ingredient'
                                           AND standard_concept = 'S'
                                           ) as a )
              AND cr.concept_id_2 = c.concept_id
              )

    AND EXISTS  (SELECT 1
          FROM devv5.concept_relationship cr
          WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                       SELECT concept_id, concept_name, vocabulary_id
                                       FROM devv5.concept
                                       WHERE concept_name ~* 'hepat|HBV|Orthohepad|Hepadn'
                                       AND concept_name !~* 'Anemone|oscillococcinum|globulin|Hepatitis A|NOSODES|Hepatitis C'
                                       AND domain_id = 'Drug'
                                       AND concept_class_id = 'Ingredient'
                                       AND standard_concept = 'S'
                                       ) as a )
          AND cr.concept_id_2 = c.concept_id
          )

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'polio|Enterovi'
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('Haemophilus B Conjugate Vaccine', 'Haemophilus influenzae b (Ross strain) capsular polysaccharide Meningococcal Protein Conjugate Vaccine', 'Haemophilus influenzae',
                                                                   'Haemophilus influenzae type b, capsular polysaccharide inactivated tetanus toxoid conjugate vaccine', 'Haemophilus influenzae type b')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--diphtheria-hepatitis B-tetanus
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

    AND EXISTS  (SELECT 1
          FROM devv5.concept_relationship cr
          WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                       SELECT concept_id, concept_name, vocabulary_id
                                       FROM devv5.concept
                                       WHERE concept_name ~* 'hepat|HBV|Orthohepad|Hepadn'
                                       AND concept_name !~* 'Anemone|oscillococcinum|globulin|Hepatitis A|NOSODES|Hepatitis C'
                                       AND domain_id = 'Drug'
                                       AND concept_class_id = 'Ingredient'
                                       AND standard_concept = 'S'
                                       ) as a )
          AND cr.concept_id_2 = c.concept_id
          )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('poliovirus vaccine inactivated, type 1 (Mahoney)', 'Haemophilus influenzae type b', 'Haemophilus B Conjugate Vaccine', 'Human poliovirus', 'Hepatitis A Vaccine, Inactivated', 'Hepatitis A Vaccine (Inactivated) Strain HM175',
                                                                   'Haemophilus influenzae b (Ross strain) capsular polysaccharide Meningococcal Protein Conjugate Vaccine', 'Haemophilus influenzae', 'Hepatitis A Virus', 'acellular pertussis vaccine, inactivated')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--diphtheria-hepatitis B-pertussis-tetanus
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

    AND EXISTS  (SELECT 1
              FROM devv5.concept_relationship cr
              WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                           SELECT concept_id, concept_name
                                           FROM devv5.concept
                                           WHERE concept_name ~* 'pertus|Bord|B\. p|B\.p|Pertactin|Fimbriae|Filamentous'
                                           AND concept_name !~* 'Human Sputum\, Bordetella Pertussis Infected'
                                           AND domain_id = 'Drug'
                                           AND concept_class_id = 'Ingredient'
                                           AND standard_concept = 'S'
                                           ) as a )
              AND cr.concept_id_2 = c.concept_id
              )

    AND EXISTS  (SELECT 1
          FROM devv5.concept_relationship cr
          WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                       SELECT concept_id, concept_name, vocabulary_id
                                       FROM devv5.concept
                                       WHERE concept_name ~* 'hepat|HBV|Orthohepad|Hepadn'
                                       AND concept_name !~* 'Anemone|oscillococcinum|globulin|Hepatitis A|NOSODES|Hepatitis C'
                                       AND domain_id = 'Drug'
                                       AND concept_class_id = 'Ingredient'
                                       AND standard_concept = 'S'
                                       ) as a )
          AND cr.concept_id_2 = c.concept_id
          )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('poliovirus vaccine inactivated, type 1 (Mahoney)', 'Haemophilus influenzae type b', 'Haemophilus B Conjugate Vaccine', 'Human poliovirus')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--diphtheria-hemophilus influenzae B-pertussis-tetanus-hepatitis B
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'hemophilus|haemophilus|influenz| hib|hib |H\.inf|H\. inf'
                                             AND concept_name !~* 'virus|tipepidine hibenzate|Influenzinum for homeopathic preparations|immunoserum'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND EXISTS  (SELECT 1
              FROM devv5.concept_relationship cr
              WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                           SELECT concept_id, concept_name
                                           FROM devv5.concept
                                           WHERE concept_name ~* 'pertus|Bord|B\. p|B\.p|Pertactin|Fimbriae|Filamentous'
                                           AND concept_name !~* 'Human Sputum\, Bordetella Pertussis Infected'
                                           AND domain_id = 'Drug'
                                           AND concept_class_id = 'Ingredient'
                                           AND standard_concept = 'S'
                                           ) as a )
              AND cr.concept_id_2 = c.concept_id
              )

    AND EXISTS  (SELECT 1
          FROM devv5.concept_relationship cr
          WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                       SELECT concept_id, concept_name, vocabulary_id
                                       FROM devv5.concept
                                       WHERE concept_name ~* 'hepat|HBV|Orthohepad|Hepadn'
                                       AND concept_name !~* 'Anemone|oscillococcinum|globulin|Hepatitis A|NOSODES|Hepatitis C'
                                       AND domain_id = 'Drug'
                                       AND concept_class_id = 'Ingredient'
                                       AND standard_concept = 'S'
                                       ) as a )
          AND cr.concept_id_2 = c.concept_id
          )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('poliovirus vaccine inactivated, type 1 (Mahoney)')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--diphtheria-hemophilus influenzae B-pertussis-poliomyelitis-tetanus-hepatitis B
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'hemophilus|haemophilus|influenz| hib|hib |H\.inf|H\. inf'
                                             AND concept_name !~* 'virus|tipepidine hibenzate|Influenzinum for homeopathic preparations|immunoserum'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND EXISTS  (SELECT 1
              FROM devv5.concept_relationship cr
              WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                           SELECT concept_id, concept_name
                                           FROM devv5.concept
                                           WHERE concept_name ~* 'pertus|Bord|B\. p|B\.p|Pertactin|Fimbriae|Filamentous'
                                           AND concept_name !~* 'Human Sputum\, Bordetella Pertussis Infected'
                                           AND domain_id = 'Drug'
                                           AND concept_class_id = 'Ingredient'
                                           AND standard_concept = 'S'
                                           ) as a )
              AND cr.concept_id_2 = c.concept_id
              )

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'polio|Enterovi'
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND EXISTS  (SELECT 1
          FROM devv5.concept_relationship cr
          WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                       SELECT concept_id, concept_name, vocabulary_id
                                       FROM devv5.concept
                                       WHERE concept_name ~* 'hepat|HBV|Orthohepad|Hepadn'
                                       AND concept_name !~* 'Anemone|oscillococcinum|globulin|Hepatitis A|NOSODES|Hepatitis C'
                                       AND domain_id = 'Drug'
                                       AND concept_class_id = 'Ingredient'
                                       AND standard_concept = 'S'
                                       ) as a )
          AND cr.concept_id_2 = c.concept_id
          )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--diphtheria-hemophilus influenzae B-pertussis-poliomyelitis-tetanus
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'hemophilus|haemophilus|influenz| hib|hib |H\.inf|H\. inf'
                                             AND concept_name !~* 'virus|tipepidine hibenzate|Influenzinum for homeopathic preparations|immunoserum'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND EXISTS  (SELECT 1
              FROM devv5.concept_relationship cr
              WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                           SELECT concept_id, concept_name
                                           FROM devv5.concept
                                           WHERE concept_name ~* 'pertus|Bord|B\. p|B\.p|Pertactin|Fimbriae|Filamentous'
                                           AND concept_name !~* 'Human Sputum\, Bordetella Pertussis Infected'
                                           AND domain_id = 'Drug'
                                           AND concept_class_id = 'Ingredient'
                                           AND standard_concept = 'S'
                                           ) as a )
              AND cr.concept_id_2 = c.concept_id
              )

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'polio|Enterovi'
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('Hepatitis B Surface Antigen Vaccine')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--diphtheria-hemophilus influenzae B-pertussis-tetanus-hepatitis B-meningococcus A + C
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'hemophilus|haemophilus|influenz| hib|hib |H\.inf|H\. inf'
                                             AND concept_name !~* 'virus|tipepidine hibenzate|Influenzinum for homeopathic preparations|immunoserum'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND EXISTS  (SELECT 1
              FROM devv5.concept_relationship cr
              WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                           SELECT concept_id, concept_name
                                           FROM devv5.concept
                                           WHERE concept_name ~* 'pertus|Bord|B\. p|B\.p|Pertactin|Fimbriae|Filamentous'
                                           AND concept_name !~* 'Human Sputum\, Bordetella Pertussis Infected'
                                           AND domain_id = 'Drug'
                                           AND concept_class_id = 'Ingredient'
                                           AND standard_concept = 'S'
                                           ) as a )
              AND cr.concept_id_2 = c.concept_id
              )

    AND EXISTS  (SELECT 1
          FROM devv5.concept_relationship cr
          WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                       SELECT concept_id, concept_name, vocabulary_id
                                       FROM devv5.concept
                                       WHERE concept_name ~* 'hepat|HBV|Orthohepad|Hepadn'
                                       AND concept_name !~* 'Anemone|oscillococcinum|globulin|Hepatitis A|NOSODES|Hepatitis C'
                                       AND domain_id = 'Drug'
                                       AND concept_class_id = 'Ingredient'
                                       AND standard_concept = 'S'
                                       ) as a )
          AND cr.concept_id_2 = c.concept_id
          )

    AND EXISTS  (SELECT 1
              FROM devv5.concept_relationship cr
              WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                           SELECT concept_id, concept_name
                                           FROM devv5.concept
                                           WHERE concept_name ~* 'mening|N\.m|N\. m|Neis'
                                           AND concept_name !~* 'Haemophilus influenzae b|GROUP Y|W-135|Group c|group B|neisseria catarrhalis flava'
                                           AND domain_id = 'Drug'
                                           AND concept_class_id = 'Ingredient'
                                           AND standard_concept = 'S'
                                           ) as a )
              AND cr.concept_id_2 = c.concept_id
              )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--hemophilus influenzae B and hepatitis B
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'hemophilus|haemophilus|influenz| hib|hib |H\.inf|H\. inf'
                                             AND concept_name !~* 'virus|tipepidine hibenzate|Influenzinum for homeopathic preparations|immunoserum'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND EXISTS  (SELECT 1
          FROM devv5.concept_relationship cr
          WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                       SELECT concept_id, concept_name, vocabulary_id
                                       FROM devv5.concept
                                       WHERE concept_name ~* 'hepat|HBV|Orthohepad|Hepadn'
                                       AND concept_name !~* 'Anemone|oscillococcinum|globulin|Hepatitis A|NOSODES|Hepatitis C'
                                       AND domain_id = 'Drug'
                                       AND concept_class_id = 'Ingredient'
                                       AND standard_concept = 'S'
                                       ) as a )
          AND cr.concept_id_2 = c.concept_id
          )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('acellular pertussis vaccine, inactivated', 'poliovirus vaccine inactivated, type 1 (Mahoney)')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--hemophilus influenzae B and poliomyelitis
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'hemophilus|haemophilus|influenz| hib|hib |H\.inf|H\. inf'
                                             AND concept_name !~* 'virus|tipepidine hibenzate|Influenzinum for homeopathic preparations|immunoserum'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'polio|Enterovi'
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('acellular pertussis vaccine, inactivated', 'Bordetella pertussis', 'Hepatitis B Surface Antigen Vaccine', 'Pertussis Vaccine')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;



--to find the form
--diphtheria-rubella-tetanus
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'dipht|Coryne|Corine|C\.d|C\. d'
                                             AND concept_name !~* 'Neisseria meningitidis serogroup|Streptococcus pneumoniae serotype|dioscorine|gonadotropin releasing factor|Diphtherial respiratory pseudomembrane preparation'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'rubella|RuV|Rubiv|Togav'
                                             AND concept_name !~* 'extract|Immunoglobulin|balsam|Peruvoside|Pyruvate|Peruvianum|Phenylpyruvic|Phenylpyruvic|Physalis|Pyruvaldehyde'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

      AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'tetan|C\.t|C\. t|Clostrid|Klostrid'
                                             AND concept_name !~* 'Neisseria meningitidis|butyricum|Cefotetan|histolyticum|difficile|perfringens|botulinum|Haemophilus influenzae|immune globulin'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;



--to find the form
--rabies, inactivated, whole virus
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

          AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name, vocabulary_id
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'rabies|rhabdo|rabdo|lyssav'
                                             AND concept_name !~* 'globulin|SERUM'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--papillomavirus (human types 6, 11, 16, 18)
--papillomavirus (human types 16, 18)
--papillomavirus (human types 6, 11, 16, 18, 31, 33, 45, 52, 58)
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

          AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name, vocabulary_id
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'papilloma|HPV'
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--smallpox, live attenuated
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

          AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name, vocabulary_id
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'smallpox|small-pox|Variola|Poxv|Orthopoxv'
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--yellow fever, live attenuated
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

          AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name, vocabulary_id
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'Yellow Fever|Yellow-Fever|Flaviv'
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;



--to find the form
--varicella, live attenuated
--zoster, live attenuated
--zoster, purified antigen
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

          AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name, vocabulary_id
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'varicel|zoster|herpes|chickenpox|VZV|HHV|chicken-pox'
                                             AND concept_name !~* 'herpesvirus (6|5|1|2)|marina|globulin'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('Measles Virus Vaccine Live, Enders'' attenuated Edmonston strain', 'MEASLES VIRUS VACCINE,LIVE ATTENUATED', 'Measles Vaccine', 'Measles Vaccine', 'Mumps virus',
                                                                    'Mumps Virus Vaccine Live, Jeryl Lynn Strain', 'Measles Vaccine', 'Mumps Vaccine', 'Rubella virus vaccine')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--rota virus, live attenuated
--rota virus, pentavalent, live, reassorted
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

          AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name, vocabulary_id
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'rotav|Reov'
                                             AND concept_name !~* 'drotaverin'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;



--to find the form
--hepatitis B, purified antigen
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

          AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name, vocabulary_id
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'hepat|HBV|Orthohepad|Hepadn'
                                             AND concept_name !~* 'Anemone|oscillococcinum|globulin|Hepatitis A|NOSODES|Hepatitis C'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('acellular pertussis vaccine, inactivated', 'Haemophilus B Conjugate Vaccine', 'Hepatitis A Vaccine (Inactivated) Strain HM175', 'Hepatitis A Vaccine, Inactivated',
                                                                   'Haemophilus influenzae type b, capsular polysaccharide inactivated tetanus toxoid conjugate vaccine', 'Hepatitis A Virus', 'Haemophilus influenzae',
                                                                   'Haemophilus influenzae b (Ross strain) capsular polysaccharide Meningococcal Protein Conjugate Vaccine')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--J07BC20	combinations
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

        AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name, vocabulary_id
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'hepat|HAV'
                                             AND concept_name !~* 'hepatitis B|Hepatitis C|ethaverine|globulin|Anemone Hepatica|oscillococcinum|root|NOSODES'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

          AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name, vocabulary_id
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'hepat|HBV|Orthohepad|Hepadn'
                                             AND concept_name !~* 'Anemone|oscillococcinum|globulin|Hepatitis A|NOSODES|Hepatitis C'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--hepatitis A, inactivated, whole virus
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

        AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name, vocabulary_id
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'hepat|HAV'
                                             AND concept_name !~* 'hepatitis B|Hepatitis C|ethaverine|globulin|Anemone Hepatica|oscillococcinum|root|NOSODES'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('Typhoid Vaccine Live Ty21a', 'Typhoid Vi Polysaccharide Vaccine, S typhi Ty2 strain', 'Salmonella Typhi Inactivated Antigen', 'Hepatitis B Surface Antigen Vaccine',
                                                                   'Hepatitis B (rDNA) vaccine (adsorbed)')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--typhoid-hepatitis A
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

      AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name, vocabulary_id
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'typh|Salmone|S\.t|S\. t|S\.e|S\. e'
                                             AND concept_name !~* 'Chondrodendron Platyphyllum|Paratyph|platyphylla|Styphnolobium|platyphyllos|Typhonium|enteritidis'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

        AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name, vocabulary_id
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'hepat|HAV'
                                             AND concept_name !~* 'hepatitis B|Hepatitis C|ethaverine|globulin|Anemone Hepatica|oscillococcinum|root|NOSODES'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--encephalitis, tick borne, inactivated, whole virus
--encephalitis, Japanese, inactivated, whole virus
--encephalitis, Japanese, live attenuated
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

      AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name, vocabulary_id
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'encephalitis|tick|Flaviv|Japanese'
                                             AND concept_name !~* 'Immunoglobulin|Antivenom|extract'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--typhus exanthematicus, inactivated, whole cell
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

      AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name, vocabulary_id
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'typhus|exanthematicus|Rickettsia|prowaz|R\.p|R\. p|Orientia|tsutsug|O\.t|O\. t|R\. ty|R\. ty|felis|typhi|R\. f|R\. f'
                                             AND concept_name !~* 'extract|Salmonella|ty-2|rickettsii|Vi|catus'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--typhoid, oral, live attenuated
--typhoid, inactivated, whole cell
--typhoid, purified polysaccharide antigen
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

      AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name, vocabulary_id
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'typh|Salmone|S\.t|S\. t|S\.e|S\. e'
                                             AND concept_name !~* 'Chondrodendron Platyphyllum|Paratyph|platyphylla|Styphnolobium|platyphyllos|Typhonium|enteritidis'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('Hepatitis A Vaccine (Inactivated) Strain HM175', 'Hepatitis A Vaccine, Inactivated', 'Hepatitis A Virus', 'diphtheria toxoid vaccine, inactivated')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;



--to find the form
--tuberculosis, live attenuated
--BCG vaccine (from L03AX Other immunostimulants)
SELECT concept_id,
       concept_code,
       concept_name,
       concept_class_id,
       standard_concept,
       invalid_reason,
       domain_id,
       vocabulary_id
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

      AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'tuberc|M\. t|M\.t|mycobacterium|bcg|Calmet|Guerin'
                                             AND concept_name !~* 'Tuberculin|phlei|immunoserum'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--tetanus toxoid
--tetanus toxoid, combinations with diphtheria toxoid
--tetanus toxoid, combinations with tetanus immunoglobulin
SELECT *
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

      AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'tetan|C\.t|C\. t|Clostrid|Klostrid'
                                             AND concept_name !~* 'Neisseria meningitidis|butyricum|Cefotetan|histolyticum|difficile|perfringens|botulinum|Haemophilus influenzae|immune globulin'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('acellular pertussis vaccine, inactivated', 'Bordetella pertussis', 'Candida albicans allergenic extract', 'Haemophilus influenzae type b, capsular polysaccharide inactivated tetanus toxoid conjugate vaccine',
                                                                   'Haemophilus B Conjugate Vaccine', 'influenza B virus antigen', 'influenza B virus antigen, Hong Kong 330-2001', 'Pertussis Vaccine', 'Human poliovirus', 'poliovirus vaccine inactivated, type 1 (Mahoney)',
                                                                   'Typhoid Vaccine Live Ty21a', 'Haemophilus capsular oligosaccharide', 'Influenza Virus Vaccine, Inactivated A-California-07-2009 X-179A (H1N1) strain', 'meningococcal group C polysaccharide')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--pneumococcus, purified polysaccharides antigen
--pneumococcus, purified polysaccharides antigen conjugated
--pneumococcus purified polysaccharides antigen and haemophilus influenzae, conjugated
SELECT *
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

      AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'pneumo|S\.pn|S\. pn'
                                             AND concept_name !~* 'Klebsiella pneumoniae|Legionella pneumophila|Mycoplasma pneumoniae'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('Staphylococcus aureus', 'Klebsiella pneumoniae', 'Mycobacterium bovis', 'streptococcus pneumoniae immunoserum rabbit')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--plague, inactivated, whole cell
SELECT *
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

      AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'plague|Yersinia|Y\.p|Y\. p'
                                             AND concept_name !~* 'Yersinia enterocolitica'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--pertussis, inactivated, whole cell, combinations with toxoids
--pertussis, purified antigen, combinations with toxoids
SELECT *
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

      AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'pertus|Bord|B\. p|B\.p|Pertactin|Fimbriae|Filamentous'
                                             AND concept_name !~* 'Human Sputum\, Bordetella Pertussis Infected'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

      AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'diphthe|tetan|Coryne|Corine|C\.d|C\. d|C\.t|C\. t|Clostrid|Klostrid'
                                             AND concept_name !~* ('dioscorine|collagenase Clostridium histolyticum|Clostridium botulinum|Clostridium perfringens|clostridium butyricum|Clostridium difficile|Cefotetan|Neisseria meningitidis|' ||
                                                                'Streptococcus pneumoniae|Diphtherial respiratory pseudomembrane preparation|gonadotropin releasing factor analog-diphtheria toxoid conjugate|' ||
                                                                'Haemophilus influenzae type b, capsular polysaccharide inactivated tetanus toxoid conjugate vaccine|Diphtheria Antitoxin|Equine diphtheria antitoxin|Tetanus immune globulin')
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('poliovirus vaccine inactivated, type 1 (Mahoney)', 'Hepatitis B Surface Antigen Vaccine', 'Haemophilus influenzae type b, capsular polysaccharide inactivated tetanus toxoid conjugate vaccine',
                                                                   'influenza B virus antigen', 'Human poliovirus')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;



--to find the form
--pertussis, inactivated, whole cell
--pertussis, purified antigen
SELECT *
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

      AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'pertus|Bord|B\. p|B\.p|Pertactin|Fimbriae|Filamentous'
                                             AND concept_name !~* 'Human Sputum\, Bordetella Pertussis Infected'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('diphtheria toxoid vaccine, inactivated')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--meningococcus A,C,Y,W-135, tetravalent purified polysaccharides antigen
--meningococcus A,C,Y,W-135, tetravalent purified polysaccharides antigen conjugated
SELECT *
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

      AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'mening|N\.m|N\. m|Neis'
                                             AND concept_name !~* 'Haemophilus influenzae b|GROUP Y|W-135|Group c|group B|neisseria catarrhalis flava'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

      AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'mening|N\.m|N\. m|Neis'
                                             AND concept_name !~* 'Haemophilus influenzae b|GROUP Y|W-135|Group a|group B|neisseria catarrhalis flava'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

      AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'mening|N\.m|N\. m|Neis'
                                             AND concept_name !~* 'Haemophilus influenzae b|GROUP c|W-135|Group a|group B|neisseria catarrhalis flava'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

      AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'mening|N\.m|N\. m|Neis'
                                             AND concept_name !~* 'Haemophilus influenzae b|GROUP c|GROUP y|Group a|group B|neisseria catarrhalis flava'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('Haemophilus capsular oligosaccharide', 'diphtheria toxoid vaccine, inactivated')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;



--to find the form
--meningococcus B, outer membrane vesicle vaccine
--meningococcus B, multicomponent vaccine
SELECT *
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

      AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'mening|N\.m|N\. m|Neis'
                                             AND concept_name !~* 'Haemophilus influenzae b|GROUP Y|W-135|Group c|group A|neisseria catarrhalis flava'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('Haemophilus capsular oligosaccharide', 'Influenza A virus vaccine, A-Texas-50-2012 (H3N2)-like virus')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--to find the form
--meningococcus C, purified polysaccharides antigen conjugated
SELECT *
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

      AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'mening|N\.m|N\. m|Neis'
                                             AND concept_name !~* 'Haemophilus influenzae b|GROUP Y|W-135|Group B|group A|neisseria catarrhalis flava'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('Neisseria meningitidis serogroup A capsular polysaccharide diphtheria toxoid protein conjugate vaccine', 'meningococcal group A polysaccharide', 'Diphtheria Antitoxin',
                                                                   'Haemophilus B Conjugate Vaccine', 'influenza B virus antigen, Hong Kong 330-2001', 'Haemophilus capsular oligosaccharide', 'Neisseria meningitidis serogroup A oligosaccharide diphtheria CRM197 protein conjugate vaccine',
                                                                   'Haemophilus influenzae type b, capsular polysaccharide inactivated tetanus toxoid conjugate vaccine', 'Neisseria meningitidis serogroup W-135 capsular polysaccharide diphtheria toxoid protein conjugate vaccine',
                                                                   'Neisseria meningitidis serogroup W-135 oligosaccharide diphtheria CRM197 protein conjugate vaccine')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;

--to find the form
--meningococcus A,C, bivalent purified polysaccharides antigen
SELECT *
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

      AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'mening|N\.m|N\. m|Neis'
                                             AND concept_name !~* 'Haemophilus influenzae b|GROUP Y|W-135|Group B|Group C|neisseria catarrhalis flava'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )


        AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'mening|N\.m|N\. m|Neis'
                                             AND concept_name !~* 'Haemophilus influenzae b|GROUP Y|W-135|Group B|Group A|neisseria catarrhalis flava'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('Haemophilus influenzae type b, capsular polysaccharide inactivated tetanus toxoid conjugate vaccine', 'influenza B virus antigen, Hong Kong 330-2001', 'Haemophilus capsular oligosaccharide',
                                                                   'MENINGOCOCCAL POLYSACCHARIDE VACCINE GROUP W-135', 'Haemophilus B Conjugate Vaccine', 'Neisseria meningitidis serogroup W-135 oligosaccharide diphtheria CRM197 protein conjugate vaccine',
                                                                   'Neisseria meningitidis polysaccharide group Y tetanus toxoid conjugate', 'Neisseria meningitidis serogroup W-135 capsular polysaccharide diphtheria toxoid protein conjugate vaccine')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;



--to find the form
--meningococcus A, purified polysaccharides antigen conjugated
SELECT *
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

      AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'mening|N\.m|N\. m|Neis'
                                             AND concept_name !~* 'Haemophilus influenzae b|GROUP Y|W-135|Group B|group C|neisseria catarrhalis flava'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('meningococcal group C polysaccharide', 'Neisseria meningitidis polysaccharide group Y tetanus toxoid conjugate', 'Neisseria meningitidis serogroup C oligosaccharide diphtheria CRM197 protein conjugate vaccine',
                                                                    'Haemophilus capsular oligosaccharide', 'Haemophilus influenzae type b, capsular polysaccharide inactivated tetanus toxoid conjugate vaccine', 'Neisseria meningitidis serogroup C capsular polysaccharide diphtheria toxoid protein conjugate vaccine')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;

--to find the form
--meningococcus A, purified polysaccharides antigen
SELECT *
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

      AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'mening|N\.m|N\. m|Neis'
                                             AND concept_name !~* 'Haemophilus influenzae b|GROUP Y|W-135|Group B|neisseria catarrhalis flava|group C|conjugate'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('Haemophilus capsular oligosaccharide', 'meningococcal group C polysaccharide')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;

--to find the form
--hemophilus influenzae B, combinations with meningococcus C, conjugated
SELECT *
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'hemophilus|haemophilus|influenz| hib|hib |H\.inf|H\. inf'
                                             AND concept_name !~* 'virus|tipepidine hibenzate|Influenzinum for homeopathic preparations'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

      AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'mening|N\.m|N\. m|Neis'
                                             AND concept_name !~* 'Haemophilus influenzae b|GROUP Y|W-135|Group B|group A|meningococcal group B vaccine|neisseria catarrhalis flava'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('MENINGOCOCCAL POLYSACCHARIDE VACCINE GROUP Y')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;

--to find the form
--hemophilus influenzae B, combinations with pertussis and toxoids
SELECT *
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'hemophilus|haemophilus|influenz| hib|hib |H\.inf|H\. inf'
                                             AND concept_name !~* 'virus|tipepidine hibenzate|Influenzinum for homeopathic preparations'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

      AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'diphthe|tetan|Coryne|Corine|C\.d|C\. d|C\.t|C\. t|Clostrid|Klostrid'
                                             AND concept_name !~* 'dioscorine|collagenase Clostridium histolyticum|Clostridium botulinum|Clostridium perfringens|clostridium butyricum|Clostridium difficile|Cefotetan|Neisseria meningitidis|Streptococcus pneumoniae|Diphtherial respiratory pseudomembrane preparation|gonadotropin releasing factor analog-diphtheria toxoid conjugate|Haemophilus influenzae type b, capsular polysaccharide inactivated tetanus toxoid conjugate vaccine'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'

                                             UNION ALL

                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('Haemophilus B Conjugate Vaccine', 'Haemophilus influenzae', 'Haemophilus influenzae type b', 'Haemophilus influenzae type b, capsular polysaccharide inactivated tetanus toxoid conjugate vaccine')
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

      AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'pertus|Bord|B\. p|B\.p|Pertactin|Fimbriae|Filamentous'
                                             AND concept_name !~* 'Human Sputum\, Bordetella Pertussis Infected'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('Hepatitis B Surface Antigen Vaccine', 'poliovirus vaccine inactivated, type 1 (Mahoney)')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;

--to find the form
--hemophilus influenzae B, combinations with toxoids
SELECT *
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'hemophilus|haemophilus|influenz| hib|hib |H\.inf|H\. inf'
                                             AND concept_name !~* 'virus|tipepidine hibenzate|Influenzinum for homeopathic preparations'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

      AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'diphthe|tetan|Coryne|Corine|C\.d|C\. d|C\.t|C\. t|Clostrid|Klostrid'
                                             AND concept_name !~* 'dioscorine|collagenase Clostridium histolyticum|Clostridium botulinum|Clostridium perfringens|clostridium butyricum|Clostridium difficile|Cefotetan|Neisseria meningitidis|Streptococcus pneumoniae|Diphtherial respiratory pseudomembrane preparation|gonadotropin releasing factor analog-diphtheria toxoid conjugate|Haemophilus influenzae type b\, capsular polysaccharide inactivated tetanus toxoid conjugate vaccine'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'

                                             UNION ALL

                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name in ('Haemophilus B Conjugate Vaccine', 'Haemophilus influenzae', 'Haemophilus influenzae type b', 'Haemophilus influenzae type b, capsular polysaccharide inactivated tetanus toxoid conjugate vaccine')
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (
                                             SELECT concept_id
                                             FROM devv5.concept
                                             WHERE concept_name in ('acellular pertussis vaccine, inactivated', 'Bordetella pertussis', 'Hepatitis B Surface Antigen Vaccine', 'poliovirus vaccine inactivated, type 1 (Mahoney)', 'Pertussis Vaccine',
                                                                    'APIS MELLIFERA VEN PROTEIN', 'Aconitum napellus extract', 'Staphylococcus aureus', 'Candida albicans', 'Klebsiella pneumoniae', 'Neisseria meningitidis serogroup A capsular polysaccharide diphtheria toxoid protein conjugate vaccine',
                                                                    'meningococcal group C polysaccharide')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;

--to find the form
--hemophilus influenzae B, purified antigen conjugated
SELECT *
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'hemophilus|haemophilus|influenz| hib|hib |H\.inf|H\. inf'
                                             AND concept_name !~* 'virus|tipepidine hibenzate|Influenzinum for homeopathic preparations'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (
                                             SELECT concept_id
                                             FROM devv5.concept
                                             WHERE concept_name in ('acellular pertussis vaccine, inactivated', 'Aconitum napellus extract', 'APIS MELLIFERA VEN PROTEIN', 'ECHINACEA ANGUSTIFOLIA Extract', 'diphtheria toxoid vaccine, inactivated',
                                                                   'Staphylococcus aureus', 'Candida albicans', 'Enterococcus faecalis', 'Klebsiella pneumoniae', 'Hepatitis B Surface Antigen Vaccine', 'meningococcal group C polysaccharide',
                                                                   'tetanus toxoid vaccine, inactivated', 'Neisseria meningitidis serogroup A capsular polysaccharide diphtheria toxoid protein conjugate vaccine')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;

--to find the form
--diphtheria toxoid
SELECT *
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'diphthe|Coryne|Corine|C\.d|C\. d'
                                             AND concept_name !~* 'Neisseria meningitidis serogroup|Streptococcus pneumoniae serotype|dioscorine|gonadotropin releasing factor|Diphtherial respiratory pseudomembrane preparation'
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (
                                             SELECT concept_id
                                             FROM devv5.concept
                                             WHERE concept_name in ('Bordetella pertussis', 'Candida albicans allergenic extract', 'acellular pertussis vaccine, inactivated', 'Pertussis Vaccine', 'tetanus toxoid vaccine, inactivated',
                                                                    'pneumococcal capsular polysaccharide type 14 vaccine', 'Haemophilus capsular oligosaccharide', 'Neisseria meningitidis serogroup A oligosaccharide diphtheria CRM197 protein conjugate vaccine',
                                                                    'Neisseria meningitidis serogroup C oligosaccharide diphtheria CRM197 protein conjugate vaccine', 'tetanus toxin', 'Haemophilus influenzae type b, capsular polysaccharide inactivated tetanus toxoid conjugate vaccine',
                                                                    'influenza B virus antigen')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;

--to find the form
--cholera
SELECT *
FROM devv5.concept c
WHERE c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    AND c.concept_class_id = 'Clinical Drug Form'

    AND EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (SELECT concept_id FROM (
                                             SELECT concept_id, concept_name
                                             FROM devv5.concept
                                             WHERE concept_name ~* 'choler|Vibri|V\.c|V\. c'
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             ) as a )
                AND cr.concept_id_2 = c.concept_id
                )

    AND NOT EXISTS  (SELECT 1
                FROM devv5.concept_relationship cr
                WHERE cr.concept_id_1 in    (
                                             SELECT concept_id
                                             FROM devv5.concept
                                             WHERE concept_name in ('Escherichia coli')
                                             --AND concept_name !~* ''
                                             AND domain_id = 'Drug'
                                             AND concept_class_id = 'Ingredient'
                                             AND standard_concept = 'S'
                                             ORDER BY concept_name
                                             )
                AND cr.concept_id_2 = c.concept_id
                )
ORDER BY concept_name
;


--all existing relationships for concept in CR
SELECT DISTINCT cr.*, c.*
FROM devv5.concept_relationship cr
JOIN devv5.concept c
    ON cr.concept_id_2 = c.concept_id
    AND cr.concept_id_1 = 40149003  --concept_id

WHERE c.domain_id = 'Drug'
ORDER BY concept_class_id
;


--all existing ancestors for concept in CA
SELECT DISTINCT ca.*, c.*
FROM devv5.concept_ancestor ca
JOIN devv5.concept c
    ON ca.ancestor_concept_id = c.concept_id
    AND ca.descendant_concept_id = 40173224  --concept_id

WHERE c.domain_id = 'Drug'
ORDER BY concept_class_id
;

--all existing descendants for concept in CA
SELECT DISTINCT ca.*, c.*
FROM devv5.concept_ancestor ca
JOIN devv5.concept c
    ON ca.descendant_concept_id = c.concept_id
    AND ca.ancestor_concept_id = 40173224  --concept_id

WHERE c.domain_id = 'Drug'
ORDER BY concept_class_id
;






--check Clinical Drug Forms associated with name
SELECT DISTINCT c.*
FROM devv5.concept c
WHERE c.domain_id = 'Drug'
  AND c.standard_concept = 'S'
  AND c.concept_class_id = 'Clinical Drug Form'

AND EXISTS(SELECT 1
            FROM devv5.concept_relationship cr
            JOIN devv5.concept c2
                ON cr.concept_id_2 = c2.concept_id
                    AND c2.concept_name ~* '\[Infanrix' --name
            WHERE cr.concept_id_1 = c.concept_id)
;


--check Branded Drug Forms associated with concept
SELECT DISTINCT c.*
FROM devv5.concept c
WHERE c.domain_id = 'Drug'
  AND c.concept_class_id = 'Branded Drug Form'

AND EXISTS(SELECT 1
            FROM devv5.concept_relationship cr
            JOIN devv5.concept c2
                ON cr.concept_id_2 = c2.concept_id
                    AND c2.concept_id = 41173770 --concept_id
            WHERE cr.concept_id_1 = c.concept_id)
;


--check Clinical Drug Form associated with concept
SELECT DISTINCT c.*
FROM devv5.concept c
WHERE c.domain_id = 'Drug'
  AND c.concept_class_id = 'Clinical Drug Form'

AND EXISTS(SELECT 1
            FROM devv5.concept_relationship cr
            JOIN devv5.concept c2
                ON cr.concept_id_2 = c2.concept_id
                    AND c2.concept_id = 40045078 --concept_id
            WHERE cr.concept_id_1 = c.concept_id)
;



--all possible relationship types
SELECT cr.*
FROM devv5.concept_relationship cr
JOIN devv5.concept c
    ON c.concept_id = cr.concept_id_1 AND c.concept_class_id = 'Ingredient' AND c.standard_concept = 'S'
JOIN devv5.concept cc
    ON cc.concept_id = cr.concept_id_2 AND cc.concept_class_id = 'Clinical Drug Form' AND cc.standard_concept = 'S'
--WHERE cr.relationship_id = 'RxNorm ing of'
;


--find relevant vaccine concepts
SELECT DISTINCT c.concept_id,
       c.concept_code,
       c.concept_name,
       c.concept_class_id,
       c.standard_concept,
       c.invalid_reason,
       c.domain_id,
       c.vocabulary_id
FROM devv5.concept c
JOIN devv5.concept_synonym s
    ON c.concept_id = s.concept_id

WHERE
        EXISTS  (SELECT 1
                 FROM devv5.concept_ancestor ca
                 WHERE ca.ancestor_concept_id IN (SELECT concept_id FROM dev_atc.vaccines_atc_to_Rx_RxE)
                    AND ca.descendant_concept_id = c.concept_id
                 )

    AND c.standard_concept = 'S'
    AND c.domain_id = 'Drug'
    --AND c.concept_class_id IN ('Clinical Drug Form', 'Clinical Drug', 'Branded Drug Form', 'Branded Drug')
    AND c.concept_class_id NOT IN ('Branded Drug Box', 'Marketed Product', 'Quant Branded Box')


    AND (c.concept_name ilike '%prevnar%' OR s.concept_synonym_name ilike '%prevnar%')


ORDER BY concept_class_id, concept_name
;

--all existing relationships for concept in CR
SELECT DISTINCT c.*
FROM devv5.concept_relationship cr
JOIN devv5.concept c
    ON cr.concept_id_2 = c.concept_id
    AND cr.concept_id_1 = 40174005  --concept_id

WHERE c.domain_id = 'Drug'
AND cr.invalid_reason IS NULL
AND c.vocabulary_id like 'Rx%'
ORDER BY concept_class_id
;

