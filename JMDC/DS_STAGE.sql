--Insertion to DS_STAGE using pi
--solid grams
INSERT into ds_stage
SELECT DISTINCT j.drug_code,
                dcs.concept_code,
                CAST (substring (standardized_unit from '^\d+') as double precision),
                substring (standardized_unit from 'g')
FROM j

JOIN pi
    ON j.drug_code = pi.drug_code

JOIN drug_concept_stage dcs
    ON pi.ing_name = dcs.concept_name

WHERE general_name !~* '\/' AND standardized_unit ~* '^\d+g$';

--QA of parsing
SELECT DISTINCT standardized_unit, amount_value, amount_unit, numerator_value, numerator_unit, denominator_value, denominator_unit, box_size
FROM j
LEFT JOIN ds_stage ds
   ON j.drug_code = ds.drug_concept_code
WHERE general_name !~* '\/' AND standardized_unit ~* '^\d+g$';

--liquid % + ml
INSERT into ds_stage
SELECT DISTINCT j.drug_code,
                dcs.concept_code,
                CAST (null as double precision),
                null,
                CAST (substring (lower (standardized_unit) from  '^\d+\.*\d*(?=\%)') as double precision) * CAST (substring (lower (standardized_unit) from '(?<=%)\d+(?=ml$)') as double precision) * 10,
                'mg',
                CAST (substring (lower (standardized_unit) from '(?<=%)\d+(?=ml$)') as double precision),
                'ml'
FROM j

JOIN pi
    ON j.drug_code = pi.drug_code

JOIN drug_concept_stage dcs
    ON pi.ing_name = dcs.concept_name

WHERE general_name !~* '\/' AND standardized_unit ~* '^\d+\.*\d*\%\d+ml$';

--QA of parsing
SELECT DISTINCT standardized_unit, amount_value, amount_unit, numerator_value, numerator_unit, denominator_value, denominator_unit, box_size
FROM j
LEFT JOIN ds_stage ds
   ON j.drug_code = ds.drug_concept_code
WHERE general_name !~* '\/' AND standardized_unit ~* '^\d+\.*\d*\%\d+ml$';

--solid % + g
INSERT into ds_stage
SELECT DISTINCT j.drug_code,
                dcs.concept_code,
                CAST (null as double precision),
                null,
                CAST (substring (standardized_unit from '^\d+\.*\d*(?=\%)') as double precision) * CAST (substring (standardized_unit from '(?<=%)\d+(?=g$)') as double precision) *10,
                'mg',
                CAST (substring (standardized_unit from '(?<=%)\d+(?=g$)') as double precision) * 1000,
                'mg'
FROM j

JOIN pi
    ON j.drug_code = pi.drug_code

JOIN drug_concept_stage dcs
    ON pi.ing_name = dcs.concept_name

WHERE general_name !~* '\/' AND standardized_unit ~* '^\d+\.*\d*\%\d+g$';

--QA of parsing
SELECT DISTINCT standardized_unit, amount_value, amount_unit, numerator_value, numerator_unit, denominator_value, denominator_unit, box_size
FROM j
LEFT JOIN ds_stage ds
   ON j.drug_code = ds.drug_concept_code
WHERE general_name !~* '\/' AND standardized_unit ~* '^\d+\.*\d*\%\d+g$';



/*

--Check1
SELECT DISTINCT standardized_unit, amount_value, amount_unit, numerator_value, numerator_unit, denominator_value, denominator_unit, box_size
FROM j
LEFT JOIN ds_stage ds
   ON j.drug_code = ds.drug_concept_code
WHERE general_name !~* '\/' AND standardized_unit ~* '^\d+\.*\d*\%\d+ml$';

--Check2
SELECT DISTINCT standardized_unit
FROM j
WHERE general_name !~* '\/' AND standardized_unit ~* '%' AND standardized_unit not in (SELECT DISTINCT standardized_unit FROM j WHERE general_name !~* '\/' AND standardized_unit ~* '^\d+\.*\d*\%\d+ml$');



SELECT *
FROM j;


SELECT *
FROM ds_stage
WHERE drug_concept_code = '100000008353';

DELETE FROM ds_stage;

SELECT *
FROM drug_concept_stage
WHERE concept_code = '100000008850';

SELECT *
FROM dev_jmdc.aut_ingredient_mapped
;

SELECT *
FROM dev_jmdc.jmdc
;


SELECT *
FROM j
WHERE drug_code = '100000011709'
WHERE standardized_unit = '7%20mL1A'
;

SELECT *
FROM j
WHERE general_name !~* '\/' AND concept_name is null
WHERE drug_code = '100000059335'
;

SELECT *
FROM pi
WHERE drug_code = '100000059335';





--INSERTION to DS_STAGE without pi???
SELECT DISTINCT j.drug_code, dcs.concept_code
FROM j

JOIN drug_concept_stage dcs
    ON j.concept_name = dcs.concept_name

WHERE general_name !~* '\/' AND standardized_unit ~* '^\d+g$';


--FULL QA of parsing
SELECT DISTINCT standardized_unit, amount_value, amount_unit, numerator_value, numerator_unit, denominator_value, denominator_unit, box_size

FROM j
JOIN ds_stage ds
ON j.drug_code = ds.drug_concept_code;

*/