--vaccines, antibodies, microorganism preparations
with inclusion as (SELECT
        --general
        'vaccine|virus|Microb|Micr(o|)org|Bacter|Booster|antigen|serum|sera|antiserum|globin|globulin|strain|antibody|conjugate|split|live|attenuate|Adjuvant|cellular|inactivate|antitoxin|toxoid|Rho|whole( |-|)cell|polysaccharide'
        || '|' ||
        --vaccine abbrevations
        'DTaP|dTpa|tDPP|Tdap|MMR'
        || '|' ||
        -- influenza
        'influenza|Grippe|Gripe|Orthomyxov|flu$|H(a|)emagglutinin|Neuraminidase|(h\d{1,2}n\d{1,2}(?!\d))|IIV|LAIV'
        || '|' ||
        --botulism
        'botul|Clostrid|Klostrid|C\.b|C\. b'
        || '|' ||
        --gas-gangrene
        '(Gas).*(Gangrene)|(Gangrene).*(Gas)|C\. p|C\.p|perfringens|novyi|C\.n|C\. n|septicum|C\. s|C\.s|ramnosum|C\.r|C\. r'
        || '|' ||
        --staphylococcus
        'staphyloc|aureus|S\. a|S\. a|epidermidis|S\.e|S\. e'
        || '|' ||
        --cytomegalovirus
        'cytomegalov|cmv|herpes|HHV'
        || '|' ||
        --Coxiella Burnetii
        'Coxiella|burnetii|C\.b|C\. b|Q( |-|)fever'
        || '|' ||
        --anthrax
        'anthrax|antrax|Bacil|anthracis|B\.a|B\. a' 
        || '|' ||
        --brucella
        'brucel|(undulant|Mediterranean|Bang).*(fever|disease)|(fever|disease).*(undulant|Mediterranean|Bang)|melitensis|B\.m|B\. m|abortus|B\.a|B\. a' 
        || '|' ||
        --rubella
        'rubella|RuV|Rubiv|Togav|Wistar|(RA).*(27).*(3)'
        || '|' ||
        --mumps
        'mumps|rubulavirus|Jeryl|Lynn'
        || '|' ||
        --measles
        'measles|morbilliv|morbiliv|MeV|Ender|Edmonston'
        || '|' ||
        --poliomyelitis
        'polio|Enterovi|Mahoney|MEF( |-|)1|Saukett|Sabin|IPV|OPV'
        || '|' ||
        --diphtheria
        'dipht|Dipth|Coryne|Corine|C\.d|C\. d'
        || '|' ||
        --tetanus
        'tetan|C\.t|C\. t|Clostrid|Klostrid'
        || '|' ||
        --pertussis
        'pertus|Bord|B\. p|B\.p|Pertactin|Fimbri(a|)e|Filamentous'
        || '|' ||
        --hepatitis B
        'hepat|HBV|Orthohepad|Hepadn|ADW2|HBSAG|CpG|HepB|HBIG|Hepa( |-|)Gam'
        || '|' ||
        --hemophilus influenzae B
        'h(a|)emophilus|influenz|hib|H\.inf|H\. inf|Ross|HbOC|PRP(-| |)OMP|PRP(-| |)T|PRP(-| |)D'
        || '|' ||
        --Neisseria
        'mening|N\.m|N\. m|Neis|CRM197|MenB|MenC(-| |)TT|MenY(-| |)TT|MenD|MenAC|MenCY|PsA(-| |)TT|MenACWY|MPSV|MCV'
        || '|' ||
        --rabies
        'rabies|rhabdo|rabdo|lyssav|PM( |-|)1503|1503( |-|)3M'
        || '|' ||
        --papillomavirus
        'papilloma|HPV'
        || '|' ||
        --smallpox
        'smallpox|small-pox|Variola|Poxv|Orthopoxv|Vaccinia|VACV|VV|Cowpox|Monkeypox|Dryvax|Imvamune|ACAM2000|Calf lymph'
        || '|' ||
        --yellow fever
        'Yellow Fever|Yellow-Fever|Flaviv|17D( |-|)204'
        || '|' ||
        --varicella/zoster
        'varicel|zoster|herpes|chickenpox|VZV|HHV|chicken-pox|(Oka).*(Merck)|ZVL|RZV|VAR'
        || '|' ||
        --rota virus
        'rota( |-|)v|Reov|RV1|RV5'
        || '|' ||
        --hepatitis A
        'hepat|HAV|HM175|HepA'
        || '|' ||
        --typhoid
        'typh|Salmone|S\.t|S\. t|S\.e|S\. e|Ty21|ty( |-|)2'
        || '|' ||
        --encephalitis
        'encephalitis|tick|Flaviv|Japanese'
        || '|' ||
        --typhus exanthematicus
        'typhus|exanthematicus|Rickettsia|prowaz|R\.p|R\. p|Orientia|tsutsug|O\.t|O\. t|R\. ty|R\. ty|felis|typhi|R\. f|R\. f'
        || '|' ||
        --tuberculosis
        'tuberc|M\. t|M\.t|M\. b|M\.b|M\. a|M\.a|mycobacterium|bcg|Calmet|Guerin|bovis|africanum|Tice|Connaught|Montreal'
        || '|' ||
        --pneumococcus
        'pneumo|S\.pn|S\. pn|PCV|PPSV'
        || '|' ||
        --plague
        'plague|Yersinia|Y\.p|Y\. p'
        || '|' ||
        --cholera
        'choler|Vibri|V\.c|V\. c|Inaba|Ogawa'
),

exclusion as (SELECT
    'Oil|Oxybenzone|Homosalate|Vitamin|collagenase|sal[yi]c|Nitrate|alumin|octocry|pholcodine|Chlorhexidine|methyl|Methoxy|Anthranilate|Ethanol|Action|Allevyn' || '|' ||
    'Serapine|Seralin|Olive|Diarrhoea|Antihistamine|Antitussive|Arginaid|Ointment|Persist|Benadryl|Benserazide|Blistex|Liver|Minoxidil|Ablavar|Inhibitor|Sanitiser|Anti(-| |)Bacterial' || '|' ||
    'Anti(-| |)microbial|Brivaracetam|Calamine|Gold|Caustic|Varenicline|Vardenafil|Codral|Coldguard|Oestrogen|Crosvar|pad|Cymevene|Cold|Cough|Antiseptic|Elmendos|Emend' || '|' ||
    'Fluorescein|Horseradish|Glivec|glucose|Haemorrhoid|Heparin(?! bind)|Hepasol|Hepsera|Imbruvica|Lavender|Levosimendan|Stick|Energy|Mendeleev|Border|Nexavar|Valsartan|Nuvaring|Oruvail' || '|' ||
    'Seravit|Pevaryl|Alanine|Magnesium|Autohaler|Inhaler|Rivaroxaban|Simvar|Stivarga|Tamarindus|Tamiflu|Tenderwet|Tevaripiprazole|Truvada|Zyprexa'

    )


select * from (
    SELECT DISTINCT dcs.*
    FROM drug_concept_stage dcs
    WHERE dcs.concept_name ~* (select * from inclusion)
        AND dcs.concept_name !~* (select * from exclusion)
        AND dcs.concept_class_id NOT IN ('Unit', 'Supplier')

    UNION

    SELECT DISTINCT dcs2.*
    FROM drug_concept_stage dcs1
    JOIN sources.amt_rf2_full_relationships fr
        ON dcs1.concept_code = fr.sourceid::text
    JOIN drug_concept_stage dcs2
        ON dcs2.concept_code = fr.destinationid::text
    WHERE dcs1.concept_name ~* (select * from inclusion)
      AND dcs1.concept_name !~* (select * from exclusion)
      AND dcs1.concept_class_id NOT IN ('Unit', 'Supplier')
) a
WHERE concept_class_id IN ('Ingredient'
                           ,'Drug Product'
                           ,'Device'
                          )
;