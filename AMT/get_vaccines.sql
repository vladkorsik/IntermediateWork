with vaccs as (SELECT
        -- influenza
        'influenza|Grippe|Orthomyxov|flu$' || '|' ||
        --rubella
        'rubella|RuV|Rubiv|Togav'  || '|' ||
        --mumps
        'mumps|rubulavirus' || '|' ||
        --measles
        'measles|morbilliv|morbiliv|MeV' || '|' ||
        --poliomyelitis
        'polio|Enterovi' || '|' ||
        --diphtheria
        'dipht|Coryne|Corine|C\.d|C\. d' || '|' ||
        --tetanus
        'tetan|C\.t|C\. t|Clostrid|Klostrid' || '|' ||
        --pertussis
        'pertus|Bord|B\. p|B\.p|Pertactin|Fimbriae|Filamentous' || '|' ||
        --hepatitis B
        'hepat|HBV|Orthohepad|Hepadn' || '|' ||
        --hemophilus influenzae B
        'hemophilus|haemophilus|influenz| hib|hib |H\.inf|H\. inf' || '|' ||
        --Neisseria
        'mening|N\.m|N\. m|Neis' || '|' ||
        --rabies
        'rabies|rhabdo|rabdo|lyssav' || '|' ||
        --papillomavirus
        'papilloma|HPV' || '|' ||
        --smallpox
        'smallpox|small-pox|Variola|Poxv|Orthopoxv' || '|' ||
        --yellow fever
        'Yellow Fever|Yellow-Fever|Flaviv' || '|' ||
        --varicella/zoster
        'varicel|zoster|herpes|chickenpox|VZV|HHV|chicken-pox' || '|' ||
        --rota virus
        'rotav|Reov' || '|' ||
        --hepatitis A
        'hepat|HAV' || '|' ||
        --typhoid
        'typh|Salmone|S\.t|S\. t|S\.e|S\. e' || '|' ||
        --encephalitis
        'encephalitis|tick|Flaviv|Japanese' || '|' ||
        --typhus exanthematicus
        'typhus|exanthematicus|Rickettsia|prowaz|R\.p|R\. p|Orientia|tsutsug|O\.t|O\. t|R\. ty|R\. ty|felis|typhi|R\. f|R\. f' || '|' ||
        --tuberculosis
        'tuberc|M\. t|M\.t|mycobacterium|bcg|Calmet|Guerin' || '|' ||
        --pneumococcus
        'pneumo|S\.pn|S\. pn' || '|' ||
        --plague
        'plague|Yersinia|Y\.p|Y\. p' || '|' ||
        --cholera
        'choler|Vibri|V\.c|V\. c')
select * from (
    SELECT dcs.*
    FROM drug_concept_stage dcs
    WHERE dcs.concept_name ~* (select * from vaccs)
        and dcs.concept_class_id = 'Ingredient'
    UNION
    SELECT DISTINCT dcs2.*
    FROM drug_concept_stage dcs1
    JOIN sources.amt_rf2_full_relationships fr
        ON dcs1.concept_code = fr.sourceid::text
    JOIN drug_concept_stage dcs2
        ON dcs2.concept_code = fr.destinationid::text
    WHERE dcs1.concept_name ~* (select * from vaccs)
      AND dcs2.concept_class_id = 'Ingredient'
) a
 where concept_name !~* 'oxyb|collagenase|[fl]ovir|sal[yi]c|homosa|emtricit|nitr|tinib|alumin|octocry|pholcodine|ketopro|chlorhex|methyl|Methoxy|Anthranilate|Ethanol';
