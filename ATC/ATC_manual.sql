--The SQL code for ATC vaccines treatment and mapping
--SET SCHEMA 'dev_atc';
--SET search_path TO dev_atc;



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

/*      --S.typhi vaccine
--Oral live attenuated Ty21a:
Vivotif, Typhoral L,

--IM Ty2 strain Vi Polysaccharide:
Typhim VI, Typherix, ViATIM, Hepatyrix, Vivaxim, Typhim V

      --Rubella Vaccines:
--Wistar RA 27-3 Strain (523212):
Meruvax II, M-M-R II, Biavax II, Roeteln, ProQuad, Priorix, Ervevax, M-M-RVAXPRO, RUDIVAX, M.M.R. VaxPro, Rubellovac, Mmr Triplovax

--Unknown:
Pluserix, Mmr Vax

--Matsuba, DCRB19, Takahashi, Matsuura and TO-336 strains used primarily in Japan, and the BRD-2 strain used primarily in China


      --Mumps Vaccines:
--RIT 4385 (derived from Jeryl Lynn strain):
PRIORIX, Mmr Priorix,

--Jeryl Lynn Strain:
MUMPSVAX, M-M-R II, Biavax II, ProQuad, M-M-RVAXPRO, M.M.R. VaxPro, Mmr Triplovax, Mm Vax, Mm Diplovax, ProQuad

--Nt-5/2 (CSF isolate of Urabe-AM9):
Pluserix
--Urabe-AM9:
Rimparix

      --Mening POLYSACCHARIDE vaccine:
--AC
Meningovax-AC, Mengivac A + C,
--ACWY
Menomune A/C/Y/W-135, ACWY Vax, MENCEVAX, Menomune-A,

        --  Meningococcus Tetanus Toxoid Conjugate Vaccine
--C
Menitorix, Neisvac C
--CY
MENHIBRIX, MenHi
--ACWY
Nimenrix

        -- Meningococcus oligosaccharide diphtheria CRM197 protein conjugate vaccine
--C
Menjugate, Meningitec
--ACYW
Menveo,
--CWY
Mencwy (perhaps like a component of Menveo)
        -- Meningococcus Polysaccharide Diphtheria Toxoid Protein Conjugate Vaccine
--ACYW
Menactra
         --MEASLES vaccines:
--Enders attenuated Edmonston strain:
M-M-R II, ProQuad, M-M-RVAXPRO, Attenuvax, M-R-Vax II, Mmr Triplovax, Mm Vax, Mm Diplovax, ProQuad

--Schwarz strain:
Mmr Priorix, Priorix-Tetra, Priorix, Rouvax, Rimparix*/



/*--auto-mapping of ingredients attempt:
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

--change to check smth