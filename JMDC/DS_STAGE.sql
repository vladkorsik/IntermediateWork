DELETE FROM ds_stage;

--Insertion to DS_STAGE using pi

--g|mg|ug|mEq|MBq|IU|KU|U
INSERT into ds_stage
SELECT DISTINCT j.drug_code,
                dcs.concept_code,
                CAST(substring(regexp_replace(standardized_unit, '[,()]', '', 'g') from '^(\d+\.*\d*)(?=(g|mg|ug|mEq|MBq|IU|KU|U)(|1T|1Syg|1A|1V|1Bag|each/V|1C|1Pack|1Pc|1Kit|1Sheet|1Bot|1Bls|1P|(\d+\.*\d*)(cm|mm)(2|\*(\d+\.*\d*)(cm|mm)))(|1Sheet)($))') as double precision),
                substring(regexp_replace(standardized_unit, '[,()]', '', 'g') from '(?<=^(\d+\.*\d*))(g|mg|ug|mEq|MBq|IU|KU|U)(?=(|1T|1Syg|1A|1V|1Bag|each/V|1C|1Pack|1Pc|1Kit|1Sheet|1Bot|1Bls|1P|(\d+\.*\d*)(cm|mm)(2|\*(\d+\.*\d*)(cm|mm)))(|1Sheet)($))')
FROM j
         JOIN pi ON j.drug_code = pi.drug_code
         JOIN drug_concept_stage dcs ON pi.ing_name = dcs.concept_name

WHERE general_name !~ '\/'
  AND regexp_replace(standardized_unit, '[,()]', '', 'g') ~ '^(\d+\.*\d*)(g|mg|ug|mEq|MBq|IU|KU|U)(|1T|1Syg|1A|1V|1Bag|each/V|1C|1Pack|1Pc|1Kit|1Sheet|1Bot|1Bls|1P|(\d+\.*\d*)(cm|mm)(2|\*(\d+\.*\d*)(cm|mm)))(|1Sheet)($)'
  AND dcs.concept_class_id = 'Ingredient';

--QA of parsing
SELECT DISTINCT standardized_unit,
                amount_value,
                amount_unit,
                numerator_value,
                numerator_unit,
                denominator_value,
                denominator_unit,
                box_size
FROM j
         LEFT JOIN ds_stage ds ON j.drug_code = ds.drug_concept_code
WHERE general_name !~ '\/'
  AND regexp_replace(standardized_unit, '[,()]', '', 'g') ~ '^(\d+\.*\d*)(g|mg|ug|mEq|MBq|IU|KU|U)(|1T|1Syg|1A|1V|1Bag|each/V|1C|1Pack|1Pc|1Kit|1Sheet|1Bot|1Bls|1P|(\d+\.*\d*)(cm|mm)(2|\*(\d+\.*\d*)(cm|mm)))(|1Sheet)($)';

--liquid % / ml|l
INSERT into ds_stage
SELECT DISTINCT j.drug_code,
                dcs.concept_code,
                CAST(null as double precision),
                null,
                CAST(substring(standardized_unit from '^(\d+\.*\d*)(?=(%)(\d+\.*\d*)(mL|L)(|1Syg|1V|1A|1Bag|1Bot|1Kit|1Pack|V|1Pc)($))') as double precision)
                    * CAST(substring(standardized_unit from '(?<=^(\d+\.*\d*)(%))(\d+\.*\d*)(?=(mL|L)(|1Syg|1V|1A|1Bag|1Bot|1Kit|1Pack|V|1Pc)($))') as double precision)
                    * CASE  WHEN standardized_unit ~ '^(\d+\.*\d*)(\%)(\d+\.*\d*)(mL)(|1Syg|1V|1A|1Bag|1Bot|1Kit|1Pack|V|1Pc)($)' THEN 10
                            WHEN standardized_unit ~ '^(\d+\.*\d*)(\%)(\d+\.*\d*)(L)(|1Syg|1V|1A|1Bag|1Bot|1Kit|1Pack|V|1Pc)($)'  THEN 10000 END,
                'mg',
                CAST(substring(standardized_unit from '(?<=^(\d+\.*\d*)(%))(\d+\.*\d*)(?=(mL|L)(|1Syg|1V|1A|1Bag|1Bot|1Kit|1Pack|V|1Pc)($))') as double precision)
                    * CASE  WHEN standardized_unit ~ '^(\d+\.*\d*)(\%)(\d+\.*\d*)(mL)(|1Syg|1V|1A|1Bag|1Bot|1Kit|1Pack|V|1Pc)($)' THEN 1
                            WHEN standardized_unit ~ '^(\d+\.*\d*)(\%)(\d+\.*\d*)(L)(|1Syg|1V|1A|1Bag|1Bot|1Kit|1Pack|V|1Pc)($)'  THEN 1000 END,
                'ml'
FROM j
         JOIN pi ON j.drug_code = pi.drug_code
         JOIN drug_concept_stage dcs ON pi.ing_name = dcs.concept_name

WHERE general_name !~ '\/'
  AND standardized_unit ~ '^(\d+\.*\d*)(\%)(\d+\.*\d*)(mL|L)(|1Syg|1V|1A|1Bag|1Bot|1Kit|1Pack|V|1Pc)($)'
  AND dcs.concept_class_id = 'Ingredient';

--QA of parsing (mL)
SELECT DISTINCT standardized_unit,
                amount_value,
                amount_unit,
                numerator_value,
                numerator_unit,
                denominator_value,
                denominator_unit,
                box_size
FROM j
         LEFT JOIN ds_stage ds ON j.drug_code = ds.drug_concept_code
WHERE general_name !~ '\/'
  AND standardized_unit ~ '^(\d+\.*\d*)(\%)(\d+\.*\d*)(mL)(|1Syg|1V|1A|1Bag|1Bot|1Kit|1Pack|V|1Pc)($)';

--QA of parsing (L)
SELECT DISTINCT standardized_unit,
                amount_value,
                amount_unit,
                numerator_value,
                numerator_unit,
                denominator_value,
                denominator_unit,
                box_size
FROM j
         LEFT JOIN ds_stage ds ON j.drug_code = ds.drug_concept_code
WHERE general_name !~ '\/'
  AND standardized_unit ~ '^(\d+\.*\d*)(\%)(\d+\.*\d*)(L)(|1Syg|1V|1A|1Bag|1Bot|1Kit|1Pack|V|1Pc)($)';

--solid % / g|mg
INSERT into ds_stage
SELECT DISTINCT j.drug_code,
                dcs.concept_code,
                CAST(null as double precision),
                null,
                CAST(substring(standardized_unit from '^(\d+\.*\d*)(?=(%)(\d+\.*\d*)(mg|g)(|1Pack|1Bot|1can|1V|1Pc)($))') as double precision)
                    * CAST(substring(standardized_unit from '(?<=^(\d+\.*\d*)(%))(\d+\.*\d*)(?=(mg|g)(|1Pack|1Bot|1can|1V|1Pc)($))') as double precision)
                    * CASE  WHEN standardized_unit ~ '^(\d+\.*\d*)(\%)(\d+\.*\d*)(g)(|1Pack|1Bot|1can|1V|1Pc)($)' THEN 10
                            WHEN standardized_unit ~ '^(\d+\.*\d*)(\%)(\d+\.*\d*)(mg)(|1Pack|1Bot|1can|1V|1Pc)($)'  THEN 0.01 END,
                'mg',
                CAST(substring(standardized_unit from '(?<=^(\d+\.*\d*)(%))(\d+\.*\d*)(?=(mg|g)(|1Pack|1Bot|1can|1V|1Pc)($))') as double precision)
                    * CASE  WHEN standardized_unit ~ '^(\d+\.*\d*)(\%)(\d+\.*\d*)(g)(|1Pack|1Bot|1can|1V|1Pc)($)' THEN 1000
                            WHEN standardized_unit ~ '^(\d+\.*\d*)(\%)(\d+\.*\d*)(mg)(|1Pack|1Bot|1can|1V|1Pc)($)'  THEN 1 END,
                'mg'
FROM j
         JOIN pi ON j.drug_code = pi.drug_code
         JOIN drug_concept_stage dcs ON pi.ing_name = dcs.concept_name

WHERE general_name !~ '\/'
  AND standardized_unit ~ '^(\d+\.*\d*)(\%)(\d+\.*\d*)(mg|g)(|1Pack|1Bot|1can|1V|1Pc)($)'
  AND dcs.concept_class_id = 'Ingredient';

--QA of parsing
SELECT DISTINCT standardized_unit,
                amount_value,
                amount_unit,
                numerator_value,
                numerator_unit,
                denominator_value,
                denominator_unit,
                box_size
FROM j
         LEFT JOIN ds_stage ds ON j.drug_code = ds.drug_concept_code
WHERE general_name !~ '\/'
  AND standardized_unit ~ '^(\d+\.*\d*)(\%)(\d+\.*\d*)(mg|g)(|1Pack|1Bot|1can|1V|1Pc)($)';

--mg|mol|ug|g|IU|U|mEq / mL|uL|g
INSERT into ds_stage
SELECT DISTINCT j.drug_code,
                dcs.concept_code,
                CAST(null as double precision),
                null,
                CAST(substring(regexp_replace(standardized_unit, ',', '', 'g') from '^(\d+\.*\d*)(?=(mg|mol|ug|g|IU|U|mEq)(\d+\.*\d*)(mL|uL|g)(|1A|1Pc|1Syg|1Kit|1Bot|V|1V|1Bag|1Pack)($))') as double precision),
                substring(regexp_replace(standardized_unit, ',', '', 'g') from '(?<=^(\d+\.*\d*))(mg|mol|ug|g|IU|U|mEq)(?=(\d+\.*\d*)(mL|uL|g)(|1A|1Pc|1Syg|1Kit|1Bot|V|1V|1Bag|1Pack)($))'),
                CAST(substring(regexp_replace(standardized_unit, ',', '', 'g') from '(?<=^(\d+\.*\d*)(mg|mol|ug|g|IU|U|mEq))(\d+\.*\d*)(?=(mL|uL|g)(|1A|1Pc|1Syg|1Kit|1Bot|V|1V|1Bag|1Pack)($))') as double precision),
                substring(regexp_replace(standardized_unit, ',', '', 'g') from '(?<=^(\d+\.*\d*)(mg|mol|ug|g|IU|U|mEq)(\d+\.*\d*))(mL|uL|g)(?=(|1A|1Pc|1Syg|1Kit|1Bot|V|1V|1Bag|1Pack)($))')
FROM j
         JOIN pi ON j.drug_code = pi.drug_code
         JOIN drug_concept_stage dcs ON pi.ing_name = dcs.concept_name

WHERE general_name !~ '\/'
  AND regexp_replace(standardized_unit, ',', '', 'g') ~ '^(\d+\.*\d*)(mg|mol|ug|g|IU|U|mEq)(\d+\.*\d*)(mL|uL|g)(|1A|1Pc|1Syg|1Kit|1Bot|V|1V|1Bag|1Pack)($)'
  AND dcs.concept_class_id = 'Ingredient';

--QA of parsing
SELECT DISTINCT standardized_unit,
                amount_value,
                amount_unit,
                numerator_value,
                numerator_unit,
                denominator_value,
                denominator_unit,
                box_size
FROM j
         LEFT JOIN ds_stage ds ON j.drug_code = ds.drug_concept_code
WHERE general_name !~ '\/'
  AND regexp_replace(standardized_unit, ',', '', 'g') ~ '^(\d+\.*\d*)(mg|mol|ug|g|IU|U|mEq)(\d+\.*\d*)(mL|uL|g)(|1A|1Pc|1Syg|1Kit|1Bot|V|1V|1Bag|1Pack)($)';

-- ug/actuat1
INSERT into ds_stage
SELECT DISTINCT j.drug_code,
                dcs.concept_code,
                CAST(null as double precision),
                null,
                CAST(substring(standardized_unit from '^(\d+\.*\d*)(?=(ug)(\d+\.*\d*)(Bls)(1Pc|1Kit)($))') as double precision)
                    * CAST(substring(standardized_unit from '(?<=^(\d+\.*\d*)(ug))(\d+\.*\d*)(?=(Bls)(1Pc|1Kit)($))') as double precision),
                substring(standardized_unit from '(?<=^(\d+\.*\d*))(ug)(?=(\d+\.*\d*)(Bls)(1Pc|1Kit)($))'),
                CAST(substring(standardized_unit from '(?<=^(\d+\.*\d*)(ug))(\d+\.*\d*)(?=(Bls)(1Pc|1Kit)($))') as double precision),
                'actuat'
FROM j
         JOIN pi ON j.drug_code = pi.drug_code
         JOIN drug_concept_stage dcs ON pi.ing_name = dcs.concept_name

WHERE general_name !~ '\/'
  AND standardized_unit ~ '^(\d+\.*\d*)(ug)(\d+\.*\d*)(Bls)(1Pc|1Kit)($)'
  AND dcs.concept_class_id = 'Ingredient';

--QA of parsing
SELECT DISTINCT standardized_unit,
                amount_value,
                amount_unit,
                numerator_value,
                numerator_unit,
                denominator_value,
                denominator_unit,
                box_size
FROM j
         LEFT JOIN ds_stage ds ON j.drug_code = ds.drug_concept_code
WHERE general_name !~ '\/'
  AND standardized_unit ~ '^(\d+\.*\d*)(ug)(\d+\.*\d*)(Bls)(1Pc|1Kit)($)';

-- ug/actuat2
INSERT into ds_stage
SELECT DISTINCT j.drug_code,
                dcs.concept_code,
                CAST(null as double precision),
                null,
                CAST(substring(regexp_replace(standardized_unit, '[()]', '', 'g') from '^(\d+\.*\d*)(?=(mg|ug)(1Bot|1Kit)(\d+\.*\d*)(ug)($))') as double precision),
                substring(regexp_replace(standardized_unit, '[()]', '', 'g') from '(?<=^(\d+\.*\d*))(mg|ug)(?=(1Bot|1Kit)(\d+\.*\d*)(ug)($))'),
                CAST(substring(regexp_replace(standardized_unit, '[()]', '', 'g') from '^(\d+\.*\d*)(?=(mg|ug)(1Bot|1Kit)(\d+\.*\d*)(ug)($))') as double precision)
                    * CASE  WHEN regexp_replace(standardized_unit, '[()]', '', 'g') ~ '^(\d+\.*\d*)(ug)(1Bot|1Kit)(\d+\.*\d*)(ug)($)' THEN 1
                            WHEN regexp_replace(standardized_unit, '[()]', '', 'g') ~ '^(\d+\.*\d*)(mg)(1Bot|1Kit)(\d+\.*\d*)(ug)($)'  THEN 1000 END
                    / CAST(substring(regexp_replace(standardized_unit, '[()]', '', 'g') from '(?<=^(\d+\.*\d*)(mg|ug)(1Bot|1Kit))(\d+\.*\d*)(?=(ug)($))') as double precision),
                'actuat'
FROM j
         JOIN pi ON j.drug_code = pi.drug_code
         JOIN drug_concept_stage dcs ON pi.ing_name = dcs.concept_name

WHERE general_name !~ '\/'
  AND regexp_replace(standardized_unit, '[()]', '', 'g') ~ '^(\d+\.*\d*)(mg|ug)(1Bot|1Kit)(\d+\.*\d*)(ug)($)'
  AND dcs.concept_class_id = 'Ingredient';

--QA of parsing
SELECT DISTINCT standardized_unit,
                amount_value,
                amount_unit,
                numerator_value,
                numerator_unit,
                denominator_value,
                denominator_unit,
                box_size
FROM j
         LEFT JOIN ds_stage ds ON j.drug_code = ds.drug_concept_code
WHERE general_name !~ '\/'
  AND regexp_replace(standardized_unit, '[()]', '', 'g') ~ '^(\d+\.*\d*)(mg|ug)(1Bot|1Kit)(\d+\.*\d*)(ug)($)';

--g|mg from kits
INSERT into ds_stage
SELECT DISTINCT j.drug_code,
                dcs.concept_code,
                CAST(substring(regexp_replace(standardized_unit, '[()]', '', 'g') from '^(\d+\.*\d*)(?=(g|mg)(1Kit)(\d+\.*\d*)(mL))') as double precision),
                substring(regexp_replace(standardized_unit, '[()]', '', 'g') from '(?<=^(\d+\.*\d*))(g|mg)(?=(1Kit)(\d+\.*\d*)(mL))')
FROM j
         JOIN pi ON j.drug_code = pi.drug_code
         JOIN drug_concept_stage dcs ON pi.ing_name = dcs.concept_name

WHERE general_name !~ '\/'
  AND regexp_replace(standardized_unit, '[()]', '', 'g') ~ '^(\d+\.*\d*)(g|mg)(1Kit)(\d+\.*\d*)(mL)'
  AND dcs.concept_class_id = 'Ingredient';

--QA of parsing
SELECT DISTINCT standardized_unit,
                amount_value,
                amount_unit,
                numerator_value,
                numerator_unit,
                denominator_value,
                denominator_unit,
                box_size
FROM j
         LEFT JOIN ds_stage ds ON j.drug_code = ds.drug_concept_code
WHERE general_name !~ '\/'
  AND regexp_replace(standardized_unit, '[()]', '', 'g') ~ '^(\d+\.*\d*)(g|mg)(1Kit)(\d+\.*\d*)(mL)';



--Check1
--records with remaining units
SELECT * FROM j WHERE standardized_unit in (

--remaining units list
SELECT DISTINCT standardized_unit
FROM j
WHERE general_name !~ '\/'

  AND standardized_unit not in (SELECT DISTINCT * FROM (
                                SELECT DISTINCT standardized_unit FROM j WHERE general_name !~ '\/' AND regexp_replace(standardized_unit, '[,()]', '', 'g') ~ '^(\d+\.*\d*)(g|mg|ug|mEq|MBq|IU|KU|U)(|1T|1Syg|1A|1V|1Bag|each/V|1C|1Pack|1Pc|1Kit|1Sheet|1Bot|1Bls|1P|(\d+\.*\d*)(cm|mm)(2|\*(\d+\.*\d*)(cm|mm)))(|1Sheet)($)'
                                UNION ALL
                                SELECT DISTINCT standardized_unit FROM j WHERE general_name !~ '\/' AND standardized_unit ~ '^(\d+\.*\d*)(\%)(\d+\.*\d*)(mL|L)(|1Syg|1V|1A|1Bag|1Bot|1Kit|1Pack|V|1Pc)($)'
                                UNION ALL
                                SELECT DISTINCT standardized_unit FROM j WHERE general_name !~ '\/' AND standardized_unit ~ '^(\d+\.*\d*)(\%)(\d+\.*\d*)(mg|g)(|1Pack|1Bot|1can|1V|1Pc)($)'
                                UNION ALL
                                SELECT DISTINCT standardized_unit FROM j WHERE general_name !~ '\/' AND regexp_replace(standardized_unit, ',', '', 'g') ~ '^(\d+\.*\d*)(mg|mol|ug|g|IU|U|mEq)(\d+\.*\d*)(mL|uL|g)(|1A|1Pc|1Syg|1Kit|1Bot|V|1V|1Bag|1Pack)($)'
                                UNION ALL
                                SELECT DISTINCT standardized_unit FROM j WHERE general_name !~ '\/' AND standardized_unit ~ '^(\d+\.*\d*)(ug)(\d+\.*\d*)(Bls)(1Pc|1Kit)($)'
                                UNION ALL
                                SELECT DISTINCT standardized_unit FROM j WHERE general_name !~ '\/' AND regexp_replace(standardized_unit, '[()]', '', 'g') ~ '^(\d+\.*\d*)(mg|ug)(1Bot|1Kit)(\d+\.*\d*)(ug)($)'
                                UNION ALL
                                SELECT DISTINCT standardized_unit FROM j WHERE general_name !~ '\/' AND regexp_replace(standardized_unit, '[()]', '', 'g') ~ '^(\d+\.*\d*)(g|mg)(1Kit)(\d+\.*\d*)(mL)'
                                ) as a )
ORDER BY standardized_unit
)
ORDER BY standardized_unit;

--Check2
-- QA of all parsing
SELECT DISTINCT standardized_unit,
                amount_value,
                amount_unit,
                numerator_value,
                numerator_unit,
                denominator_value,
                denominator_unit,
                box_size
FROM j
    JOIN ds_stage ds ON j.drug_code = ds.drug_concept_code
ORDER BY standardized_unit;

--Check3
-->100%
SELECT * FROM j WHERE standardized_unit ~ '1\d\d\%' AND general_name !~ '\/';