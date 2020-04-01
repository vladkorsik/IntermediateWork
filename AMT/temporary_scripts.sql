-- ALTER TABLE relationship_to_concept
--     ADD COLUMN mapping_type VARCHAR;

--============================================RTC===============================================
/***********************************/
--1. Ingredient
--TEMPORARY SCRIPT

DROP TABLE IF EXISTS ingredient_mapped;
CREATE TABLE IF NOT EXISTS ingredient_mapped
(
    name         varchar(255),
    new_name     varchar(255),
    concept_id_2 integer,
    precedence   integer,
    mapping_type varchar(50)
);

--population of ingredient_mapped from rtc backup
WITH rtc AS (
            SELECT DISTINCT *
            FROM relationship_to_concept_bckp300817
            )
INSERT
INTO ingredient_mapped (name, new_name, concept_id_2, precedence, mapping_type)
SELECT DISTINCT
    dcs.concept_name,
    NULL,
    c.concept_id,
    rtc.precedence,
    'rtc_backup' AS mapping_type
FROM rtc
JOIN drug_concept_stage dcs
    ON rtc.concept_code_1 = dcs.concept_code AND dcs.concept_class_id = 'Ingredient'
JOIN concept c
    ON c.concept_id = rtc.concept_id_2 AND c.concept_class_id = 'Ingredient'
WHERE dcs.concept_name NOT IN (
                              SELECT dcs.concept_name
                              FROM rtc
                              JOIN drug_concept_stage dcs
                                  ON rtc.concept_code_1 = dcs.concept_code
                              JOIN concept c
                                  ON c.concept_id = rtc.concept_id_2
                              GROUP BY dcs.concept_name, rtc.precedence
                              HAVING COUNT(DISTINCT c.concept_id) > 1
                              )
;


--CHECKS
-- get mapping for review

WITH automapped        AS (
                          SELECT DISTINCT dcs.concept_name AS name, rtc.mapping_type, c.*
                          FROM relationship_to_concept rtc
                          JOIN drug_concept_stage dcs
                              ON dcs.concept_code = rtc.concept_code_1
                          JOIN concept c
                              ON rtc.concept_id_2 = c.concept_id
                          WHERE c.concept_class_id = 'Ingredient'
                          ),
     ingredient_mapped AS (
                          SELECT DISTINCT im.name AS name, im.mapping_type, c.*
                          FROM ingredient_mapped im
                          JOIN concept c
                              ON c.concept_id = im.concept_id_2
                          )
SELECT *
FROM automapped
UNION ALL
SELECT *
FROM ingredient_mapped
WHERE name NOT IN (
                  SELECT name
                  FROM automapped
                  )
ORDER BY mapping_type, name;


--check inserted mapping with precedence > 1
SELECT *
FROM ingredient_mapped im
JOIN devv5.concept c
    ON im.concept_id_2 = c.concept_id

WHERE im.name IN
      (
      SELECT im.name
      FROM ingredient_mapped im
      GROUP BY im.name
      HAVING COUNT(*) > 1
      )
;

/****************************************/
--2. Brand Names
--TEMPORARY SCRIPT

DROP TABLE IF EXISTS brand_name_mapped;
CREATE TABLE IF NOT EXISTS brand_name_mapped
(
    name         varchar(255),
    new_name     varchar(255),
    concept_id_2 integer,
    precedence   integer,
    mapping_type varchar(50)
);

--population of brand_name_mapped from rtc backup
WITH rtc AS (
            SELECT DISTINCT *
            FROM relationship_to_concept_bckp300817
            )
INSERT
INTO brand_name_mapped (name, new_name, concept_id_2, precedence, mapping_type)
SELECT DISTINCT
    dcs.concept_name,
    NULL,
    c.concept_id,
    rtc.precedence,
    'rtc_backup' AS mapping_type
FROM rtc
JOIN drug_concept_stage dcs
    ON rtc.concept_code_1 = dcs.concept_code AND dcs.concept_class_id = 'Brand Name'
JOIN concept c
    ON c.concept_id = rtc.concept_id_2 AND c.concept_class_id = 'Brand Name'
WHERE dcs.concept_name NOT IN (
                              SELECT dcs.concept_name
                              FROM rtc
                              JOIN drug_concept_stage dcs
                                  ON rtc.concept_code_1 = dcs.concept_code
                              JOIN concept c
                                  ON c.concept_id = rtc.concept_id_2
                              GROUP BY dcs.concept_name, rtc.precedence
                              HAVING COUNT(DISTINCT c.concept_id) > 1
                              )
  AND dcs.concept_name NOT LIKE '%Alustal%'
;


DELETE
-- SELECT
--     bnm.name, NULL  AS new_name, 'REVIEW' AS comment, NULL AS precedence, c.concept_id AS target_concept_id,
--     c.concept_code, c.concept_name, c.concept_class_id, c.standard_concept, c.invalid_reason, c.domain_id,
--     c.vocabulary_id AS target_vocabulary_id
FROM brand_name_mapped bnm
-- JOIN concept c
--     ON bnm.concept_id_2 = c.concept_id
WHERE name IN
      ('Abilify Maintena', 'Abisart Hct', 'Accomin Adult Mixture', 'Aciclovir Cold Sore',
       'Aciclovir Intravenous Pfizer', 'Acid AND Heartburn Relief', 'Acid AND Heartburn Relief Extra Strength',
       'Actair Continuation Treatment Ir', 'Actair Initiation Treatment', 'Actair Ir', 'Actilyse Cathflo',
       'Action Cold AND Flu', 'Adesan Hct', 'Adrenaline MIN-I-Jet', 'After WORK', 'Airomir Autohaler',
       'Alendro Once Weekly', 'Alen Plus D', 'Aluminium Acetate Apf', 'Alustal House Dust Mites EXTRACT',
       'Alustal House Dust Mites EXTRACT Initial Treatment SET', 'Amethocaine Hydrochloride Minims', 'Amolin Baby',
       'Anticol Max', 'Anti Diarrhoea', 'Anti - Fungal', 'Antifungal Clotrimazole',
       'Antifungal Clotrimazole Women''S Combination Treatment', 'Antifungal Clotrimazole Women''S Treatment',
       'Anti - Fungal Nail Treatment', 'Anti Fungal V', 'Antihistamine Elixir',
       'Anti - Inflammatory Naproxen Pain Relief', 'Anti - Inflammatory Pain Relief',
       'Antiseptic Plus', 'Antitussive WITH Diphenhydramine Cough Medicine FOR The FAMILY',
       'Antiviral Cold Sore', 'Apidra Solostar', 'Aporyl Anti-Fungal Nail Treatment', 'Aranesp Sureclick', 'Aspirin Ec',
       'Aspirin Extra Strength', 'Aspirin Low Dose', 'Aspro Clear', 'Aspro Clear Extra Strength', 'Aspro Protect',
       'Atropine Sulfate MIN-I-Jet', 'Atropine Sulfate Pfizer', 'Atropine Sulphate Minims',
       'Avagard Antiseptic Surgical Hand Scrub WITH Chlorhexidine Gluconate',
       'Avagard Antiseptic Surgical Hand Scrub WITH Povidone-Iodine', 'Avapro Hct', 'Azclear ACTION',
       'Benadryl Pe Chesty Cough AND Nasal Congestion', 'Benadryl Pe Dry Cough AND Nasal Congestion',
       'Benadryl Pe FOR The FAMILY Chesty Cough AND Nasal Congestion',
       'Benadryl Pe FOR The FAMILY Dry Cough AND Nasal Congestion', 'Betoptic S', 'Biodone Forte', 'Bio Zinc',
       'Blistex Medicated Lip', 'Blistex Ultra Lip Balm', 'Brenda - 35 Ed', 'Bricanyl Turbuhaler',
       'Brolene Eye Ointment', 'Bronchitis Cough Medicine', 'Calcium Chloride MIN-I-Jet', 'Calmative Pain Relief',
       'Caltrate Plus WITH Vitamin D', 'Caltrate Plus WITH Vitamin D AND Minerals', 'Candesartan Cilexetil Combi',
       'Candesartan Hct', 'Candesartan Hctz', 'Carboplatin Pfizer', 'Ceclor Cd', 'Cefaclor Cd', 'Cefaclor - Cd',
       'Centavite Adult', 'Cetirizine Hydrochloride Hayfever AND Allergy Relief', 'Chloramphenicol Minims',
       'Chlorhexidine Gluconate AND Cetrimide Pfizer', 'Chlorhexidine Gluconate Catheter Prep Pfizer',
       'Chlorhexidine Gluconate IN Alcohol Pfizer', 'Chlorhexidine Gluconate Pfizer',
       'Chlorpromazine Hydrochloride Mixture Forte', 'Cisplatin Pfizer', 'Citrulline Easy', 'Clamoxyl Duo',
       'Clamoxyl Duo Forte', 'Clopidogrel Plus Aspirin', 'Clopixol Acuphase',
       'Clotrimazole DAY Thrush Treatment', 'Clotrimazole DAY Treatment', 'Clotrimazole Thrush Treatment',
       'Cmv Immunoglobulin-Vf', 'Cocaine Hydrochloride Eye Drops Strong Apf', 'Codral Cold AND Flu',
       'Codral Cold AND Flu Plus Cough', 'Codral Original Cold AND Flu',
       'Codral Original Cold AND Flu Max', 'Codral Original Cold AND Flu Plus Cough', 'Cold AND Flu DAY AND Night',
       'Cold AND Flu DAY AND Night Pe', 'Cold AND Flu DAY AND Night Relief', 'Cold AND Flu DAY AND Night Relief Pe',
       'Cold AND Flu DAY Pe', 'Cold AND Flu Night TIME Relief Pe', 'Cold AND Flu Pe', 'Cold AND Flu Plus Cough',
       'Cold AND Flu Plus Cough DAY AND Night', 'Cold AND Flu Relief',
       'Cold AND Flu Relief DAY AND Night', 'Cold AND Flu Relief Pe',
       'Cold AND Allergy Children''S Mixture', 'Cold And Allergy Infant''S Drops', 'Cold AND Allergy Mixture',
       'Cold AND Allergy Syrup', 'Coldguard Cold AND Flu', 'Coldguard Cold AND Flu WITH Antihistamine',
       'Cold Sore Fighter', 'Congested Cold AND Cough Elixir', 'Congested Cold AND Cough Paediatric Drops',
       'Congested Cough Medicine',
       'Congested Cough Mixture', 'Cough AND Cold Children''S', 'Cutan Alcohol Foam Antiseptic Handrub',
       'Cyclopentolate Hydrochloride Minims',
       'Cystitis Relief', 'Cytarabine Pfizer', 'Daily Dose Aspirin', 'Daivonex', 'Daivonex', 'Daivonex Scalp',
       'Daivonex Scalp', 'Dalacin C',
       'Dalacin T', 'Dalacin V', 'Daunorubicin Pfizer', 'Day Plus Night Cold And Flu',
       'Day Plus Night Cold And Flu Relief', 'Day Plus Night Sinus Relief', 'Debug Hand Hygiene',
       'Decongestant And Antihistamine Elixir', 'Decongestant And Antihistamine Infant Elixir',
       'Decongestant And Antihistamine Mixture', 'Decongestant And Expectorant Cough Medicine',
       'Decongestant And Expectorant Mixture', 'Decongestant Cough Mixture', 'Decongestant Pe', 'Dencorub Arthritis',
       'Dencorub Arthritis Ice Therapy', 'Dermadrate Dry Skin Treatment',
       'Dermo Relief', 'Diabact Ubt', 'Diasp Sr', 'Dilart Hct', 'Diltiazem Hydrochloride Cd',
       'Dimetapp Children''S Ibuprofen Pain AND Fever Relief',
       'Dimetapp Pe Sinus Pain', 'Dimetapp Pe Sinus Pain AND Allergy', 'Dolased Pain Relief',
       'Duro - Tuss Chesty Cough Forte',
       'Duro - Tuss Chesty Cough Plus Nasal Decongestant', 'Duro - Tuss Chesty Cough Tablet Forte', 'Duro - Tuss Cough',
       'Duro - Tuss Dry Cough Liquid Forte', 'Duro - Tuss Dry Cough Plus Nasal Decongestant',
       'Duro - Tuss Pe Chesty Cough Plus Nasal Decongestant', 'Duro - Tuss Pe Dry Cough Plus Nasal Decongestant',
       'Ear Care Antiseptic', 'Ear Clear FOR Ear Ache', 'Ear Clear FOR Ear Wax Removal', 'Ear Clear FOR Swimmers',
       'Ephedrine Instillation Apf', 'Essential Enzymes', 'Ethical Nutrients Digestion Plus',
       'Etoposide Pfizer', 'Extra Strength Mini-Tab', 'Extra Strength Pain Relief', 'Extra Strong Pain Relief',
       'Famciclovir Once', 'Felodil Xr', 'Felodur Er', 'Femizol Clotrimazole Thrush Treatment', 'Femrelief One',
       'Ferrum H', 'Fibre Health Granular', 'Fibre Health Smooth', 'Fleet Ready-TO-Use', 'Floxapen Forte',
       'Fluorescein Sodium Minims', 'Fluoride Neutral', 'Fluorouracil Pfizer', 'Fosamax Once Weekly',
       'Fosamax Plus D-Cal', 'Fosamax Plus Once Weekly', 'Gastrogel Antacid', 'Gastrogel - Ranitidine',
       'Gastrogel - Ranitidine Extra Strength',
       'Gaviscon Cool', 'Genotropin Goquick', 'Gentamicin Pfizer', 'Genteal Gel', 'Gliclazide Mr', 'Glucose MIN-I-Jet',
       'Haemorrhoid AND Pruritis Relief', 'Hair A-Gain', 'Hair Retreva', 'Hair Revive Extra Strength',
       'Hayfever AND Sinus Pain Relief Pe', 'Hayfever Sinus Relief',
       'Hayfever Sinus Relief Pe', 'Head Cold AND Allergy Elixir', 'Head Cold Relief', 'Heparinised Saline Pfizer',
       'Hepatitis B Immunoglobulin-Vf', 'Humalog Mix', 'Humalog Mix Kwikpen', 'Humulin Nph Isophane',
       'Humulin R Regular', 'Hydrogen Peroxide Pfizer', 'Ibuprofen Blue', 'Ibuprofen Blue Capseal',
       'Ibuprofen Blue Period Pain', 'Ibuprofen Blue Period Pain Capseal',
       'Ibuprofen Blue Tabsule', 'Ibuprofen Children''S', 'Ibuprofen Migraine Pain',
       'Ibuprofen Pain And Fever 6 Months To 12 Years', 'Ibuprofen Pain Relief', 'Ibuprofen Period Pain',
       'Ipecacuanha And Tolu Mixture Cough Expectorant', 'Irbesartan Hct', 'Isopto Carbachol',
       'Isopto Carpine', 'Isopto Homatropine', 'Isopto Tears', 'Junior Cold And Flu Medicine', 'Junior Cough And Cold',
       'Junior Cough And Cold Elixir', 'Junior Decongestant Mixture', 'Karbesat Hct', 'Karvol Decongestant',
       'Kiddicol Children''S Cough Mixture',
       'Lemsip Cold AND Flu',
       'Lemsip Cold AND Flu WITH Decongestant', 'Lemsip Multi-Relief Cold AND Flu',
       'Lemsip Pharmacy Flu Strength Nightime',
       'Leucovorin Calcium Pfizer', 'Levo / Carbidopa', 'Lignocaine Hydrochloride AND Fluorescein Sodium Minims',
       'Lignocaine Hydrochloride MIN-I-Jet', 'Lignocaine Pfizer', 'Lignocaine WITH Chlorhexidine Gluconate Pfizer',
       'Lignospan Special', 'Liposomal Doxorubicin',
       'Liquifilm Tears', 'Liquid Pedvaxhib', 'Liquid Vitamin E Micelle E', 'Lmx Topical Anaesthetic', 'Locilan',
       'Logicin Flu Strength',
       'Logicin Rapid Relief', 'Logicin Rapid Relief Nasal', 'Logicin Sinus', 'Mabthera Sc', 'Madopar', 'Madopar Hbs',
       'Madopar Rapid', 'Mencevax Acwy', 'Menomune - A / C / Y / W', 'Menthol Apf', 'Methopt Tears',
       'Methotrexate Pfizer',
       'Metronidazole Pfizer', 'Midazolam Pfizer',
       'Mirtazapine Odt', 'Mitomycin - C Kyowa', 'Mitozantrone Pfizer', 'Momex Sr', 'Monofix - Vf', 'Morphine Mr',
       'Morphine Sulfate Mr',
       'Ms - 2 Step', 'Ms Contin', 'Ms Mono', 'Ms Normal', 'Multi - B Forte', 'Myconail Anti-Fungal Nail Laquer Kit',
       'Naphcon Forte',
       'Nappy Rash Soothing AND Healing', 'Naproxen Sodium Anti-Inflammatory Pain Relief', 'Naropin WITH Fentanyl',
       'Nasal Decongestant Pe',
       'Nasal Decongestant Plus Pain Relief Pe', 'Nemdyn Otic', 'Neutrogena T/Gel Therapeutic',
       'Neutrogena T/Gel Therapeutic Conditioner',
       'Neutrogena T/Gel Therapeutic Plus', 'Nifedipine Xr', 'No - Doz Awakeners', 'Noriday', 'Normacol Plus',
       'Novomix Flexpen',
       'Nurocain WITH Adrenaline IN Dental', 'Obstetric Care', 'Odaplix Sr', 'Olanzapine Odt', 'Olmetec Plus',
       'Oncotice Bcg',
       'Ondansetron Odt', 'Ondansetron Pfizer', 'Ondansetron Zydis', 'Optiray - 160', 'Optiray - 320',
       'Optiray - 320 Ultraject',
       'Optiray - 350', 'Optiray - 350 Ultraject', 'Oralife Peppermint Lip Treatment', 'Orthoclone Okt',
       'Ostelin Osteoguard',
       'Ostelin Vitamin D', 'Ostelin Vitamin D AND Calcium', 'Ostelin Vitamin D Kids', 'Osteoeze Tabsule',
       'Osteoeze Tabsule Forte', 'Osteo Pain Relief Paracetamol', 'Osteo Paracetamol', 'Osteo Relief Paracetamol',
       'Ostran - Odt',
       'Otocomb Otic', 'Oxaliplatin Pfi', 'Oxy Antiseptic Medicated Skin Wash', 'Oxybuprocaine Hydrochloride Minims',
       'Oxycodone Ir', 'Oxycodone Mr', 'Oxy Skin Toned', 'Oziclide Mr',
       'Paedamin Children''S Antihistamine Children''S',
       'Paedamin Children''S Decongestant And Antihistamine',
       'Paedamin Decongestant And Antihistamine Syrup For Children', 'Pain Plus Relief',
       'Painstop For Children Day-Time Pain Reliever', 'Painstop For Children Night-Time Pain Reliever',
       'Panadol Allergy Sinus', 'Panadol Back And Neck Long Lasting', 'Panadol Back And Neck Pain Relief',
       'Panadol Children''S',
       'Panadol Children''S 1 To 5 Years', 'Panadol Children''S 3+ YEARS', 'Panadol Children''S 5 To 12 Years',
       'Panadol Children''S 6 MONTHS TO 5 YEARS', 'Panadol Children''S 7+ Years',
       'Panadol Children''S Drops 1 MONTH TO 2 YEARS', 'Panadol Cold AND Flu',
       'Panadol Cold AND Flu Max', 'Panadol Cold AND Flu Max Plus Decongestant',
       'Panadol Cold AND Flu Plus Decongestant',
       'Panadol Cold AND Flu Relief Pe', 'Panadol Flu Strength DAY AND Night Pe', 'Panadol Optizorb', 'Panadol Osteo',
       'Panadol Rapid', 'Panadol Rapid Soluble', 'Panadol Sinus', 'Panadol Sinus Pe Night AND', 'Panadol Sinus Relief',
       'Panadol Sinus Relief Pe', 'Panafen Ib', 'Panafen Plus', 'Panoxyl Wash', 'Pantoprazole Heartburn Relief',
       'Panvax Hn Junior Vaccine', 'Panvax Hn Vaccine', 'Paracetamol 1 TO 5 YEARS', 'Paracetamol 5 TO 12 YEARS',
       'Paracetamol AND Codeine Phosphate Gold Plus', 'Paracetamol Capseal', 'Paracetamol Children 1 TO 5 YEARS',
       'Paracetamol Children 5 TO 12 YEARS', 'Paracetamol Children''S', 'Paracetamol Children''S 1 TO 5 YEARS',
       'Paracetamol Children''S 5 To 12 Years', 'Paracetamol Children''S 6 TO 12 YEARS',
       'Paracetamol Children''S Concentrated 5 To 12 Years', 'Paracetamol Extra', 'Paracetamol Extra Plus',
       'Paracetamol Infant And Children 1 Month To 2 Years', 'Paracetamol Infant And Children 1 Month To 4 Years',
       'Paracetamol Infant Drops', 'Paracetamol Minitab', 'Paracetamol Pain And Fever 1 Month To 2 Years',
       'Paracetamol Pain And Fever 1 To 5 Years', 'Paracetamol Pain And Fever 5 To 12 Years', 'Paracetamol Pain Relief',
       'Paracetamol Plus Codeine', 'Paracetamol Plus Codeine And Calmative', 'Paracetamol Tabsule', 'Pedoz Anti-Fungal',
       'Pegatron Combination Therapy With Clearclick Injector', 'Pegatron Combination Therapy With Redipen Injector',
       'Penta-Vite', 'Penta-Vite Multivitamins For Infants 0 To 3 Years',
       'Penta-Vite Multi-Vitamins For Infants 0 To 3 Years', 'Perindopril Erbumine Combi', 'Period Pain Relief',
       'Pharmorubicin', 'Pharmorubicin Rd', 'Phenylephrine Hydrochloride Minims', 'Pholcodine Dry Forte',
       'Pilocarpine Nitrate Minims', 'Plasma-Lyte Replacement', 'Plasma-Lyte Replacement In Glucose',
       'Povidone-Iodine Pfizer', 'Pramipexole Er', 'Pramipexole Xr', 'Prednefrin Forte',
       'Prednisolone Sodium Phosphate Minims', 'Premia Continuous', 'Primoteston Depot', 'Prostin E', 'Prostin F Alpha',
       'Prostin Vr', 'Pva Forte', 'Pva Tears', 'Pyralin En', 'Pyrenel Foam',
       'Pyrifoam Lice Breaker', 'Qv Flare Up Bath Oil', 'Qv Intensive Moisturising Cleanser', 'Ranital Forte',
       'Ranitidine Forte', 'Reddymax Plus D-Cal', 'Reditron-Odt', 'Reflux Relief Extra Strength', 'Rehydration Formula',
       'Rehydration Formula Effervescent', 'Rejuvenail Anti-Fungal', 'Repatha Sureclick', 'Replete Extra Strength',
       'Replete Regular Strength',
       'Rescue Me Acne Blemish Treatment', 'Risedro Once A Week', 'Rispaccord', 'Rispaccord-0.5', 'Risperdal Quicklet',
       'Rizatriptan Odt', 'Robitussin Chesty Cough', 'Robitussin Chesty Cough And Nasal Congestion Pe',
       'Robitussin Chesty Cough And Nasal Congestion Ps', 'Robitussin Chesty Cough Forte',
       'Robitussin Cold And Flu Junior', 'Robitussin Cold And Flu Plus Decongestant',
       'Robitussin Cough And Chest Congestion', 'Robitussin Dm-P Extra Strength', 'Robitussin Dry Cough Forte',
       'Robitussin Ex', 'Robitussin Head Cold And Sinus', 'Robitussin Sinus Relief', 'Ropicor-0.5',
       'Rosuzet Composite Pack', 'Saizen Clickeasy', 'Salazopyrin', 'Salazopyrin En', 'Salbutamol Pfizer',
       'Salbutamol Respule', 'Salbutamol Sterineb Pfizer', 'Sandostatin Lar', 'Seebri Breezhaler', 'Selemite B',
       'Septrin Forte', 'Sifrol Er', 'Siguent Hycor', 'Sildenafil Pht', 'Sinemet Cr',
       'Sinus Allergy And Pain Relief Pe', 'Sinus And Hayfever Relief', 'Sinus And Nasal Decongestant Non Drowsy',
       'Sinus And Nasal Decongestant Relief', 'Sinus And Nasal Relief', 'Sinus And Pain', 'Sinus And Pain Relief',
       'Sinus Pain', 'Sinus Pain Relief', 'Sinus-Pain Relief', 'Sinus Pe', 'Sinus With Antihistamine',
       'Sinus With Antihistamine Pe', 'Sinutab Pe Sinus', 'Allergy And Pain Relief', 'Sinutab Pe Sinus And Pain Relief',
       'Sinutab Sinus', 'Allergy And Pain Relief', 'Sinutab Sinus And Pain Relief', 'Skin Active Eczema',
       'Skin Active Pine Tar With Menthol', 'Skin Irritation', 'Skin Relief Sorbolene Moisturiser With Glycerin',
       'Skin Therapy Lotion', 'Sodium Bicarbonate Min-I-Jet', 'Sodium Chloride Minims', 'Solastick Spf +',
       'Somatuline Autogel', 'Somatuline La',
       'Sorbolene Cream', 'Sorbolene Cream With Glycerin', 'Sore Throat Gargle', 'Sore Throat Lozenge',
       'South Australian Shark Cartilage', 'Spiriva Respimat', 'Stelazine Forte', 'Stomach Ache And Pain Relief',
       'Stomach Ease', 'Strepfen Intensive',
       'Striverdi Respimat', 'Strong Pain Caplet', 'Strong Pain Plus', 'Strong Pain Relief', 'Strong Pain Relief Plus',
       'Strong Pain Relief Tabsule',
       'Strong Pain With Calmative', 'Styptic Pencil', 'Sudafed Nasal Decongestant', 'Sudafed Pe Nasal Decongestant',
       'Sudafed Pe Sinus And Anti-Inflammatory Pain Relief', 'Sudafed Pe Sinus And Pain Relief',
       'Sudafed Pe Sinus Day And Night Relief', 'Sudafed Pe Sinus Plus Allergy And Pain Relief',
       'Sudafed Sinus And Nasal Congestion', 'Sudafed Sinus And Nasal Decongestant',
       'Sudafed Sinus Day Plus Night Relief', 'Sudafed Sinus Hour Relief', 'Sudafed Sinus Plus Allergy And Pain Relief',
       'Sudafed Sinus Plus Anti-Inflammatory Pain Relief', 'Sudafed Sinus Plus Pain Relief',
       'Sunscreen Spf + Sensitive', 'Sunsense Sensitive Spf +', 'Sunsense Spf +', 'Sunsense Ultra Spf +',
       'Suvacid Heartburn Relief', 'Symbicort Rapihaler', 'Symbicort Turbuhaler', 'Synacthen Depot', 'Tazocin',
       'Tazocin Ef', 'Tears Naturale', 'Tea Tree Cold Sore', 'Telmisartan Hct', 'Tenaxil Sr',
       'Thrombix Low Dose Aspirin', 'Thrush Relief', 'Thrush Treatment Duo', 'Thymol Mouthwash Red', 'Tiger Balm Red',
       'Tiger Balm White', 'Tirofiban Ac', 'Tisseel Duo',
       'Tixylix Chest Rub Essential Oils Children''S YR+',
       'Tixylix Dry Cough AND Cold 2 YEARS+', 'Tixylix Night Cough AND Cold 2 YEARS+', 'Tobramycin Pfizer',
       'Tobramycin Pf Pfizer', 'Toothache Drops', 'Topizol Antifungal', 'Torlemo Dt', 'Tortrigine Dt',
       'Tramadol Hydrochloride Sr',
       'Tramadol Sr', 'Travacalm Ho',
       'Travacalm Original', 'Triclosan Pre-Op Wash', 'Tropicamide Minims', 'Ultibro Breezhaler', 'Unisom Sleepgel',
       'Univent Cipule', 'Valerian Forte', 'Vallergan Forte', 'Valsartan Hctz', 'Venlafaxine Sr', 'Venlafaxine Xr',
       'Venlexor Xr',
       'Veracaps Sr', 'Vicks Inhaler', 'Vicks Sinex',
       'Vicks Sinex Extrafresh', 'Vicks Sinex HOUR Ultra Fine Mist', 'Vicks Vaporub Greaseless',
       'Vicks Vaporub Vaporizing',
       'Videx Ec', 'Viekira Pak', 'Viekira Pak-Rbv', 'Vincristine Sulfate Pfizer', 'Viodine Povidone-Iodine Antiseptic',
       'Viodine Povidone-Iodine Concentrated Gargle', 'Visine Advanced Relief', 'Vitalipid N Adult',
       'Vitalipid N Infant', 'Vosol Complete Care FOR Swimmer''S Ear', 'Wart Removal Gel', 'Worming Tablet',
       'Worm Treatment', 'X-Opaque-Hd', 'Zoton Fastab', 'Panadol Extra', 'Panadol Extra Optizorb');

--CHECKS
-- get mapping for review
WITH automapped        AS (
                          SELECT DISTINCT dcs.concept_name AS name, rtc.mapping_type, c.*
                          FROM relationship_to_concept rtc
                          JOIN drug_concept_stage dcs
                              ON dcs.concept_code = rtc.concept_code_1
                          JOIN concept c
                              ON rtc.concept_id_2 = c.concept_id
                          WHERE c.concept_class_id = 'Brand NAME'
                          ),

     brand_name_mapped AS (
                          SELECT DISTINCT bnm.name AS name, bnm.mapping_type, c.*
                          FROM brand_name_mapped bnm
                          JOIN concept c
                              ON c.concept_id = bnm.concept_id_2
                          )

SELECT *
FROM automapped

UNION ALL

SELECT *
FROM brand_name_mapped
WHERE name NOT IN (
                  SELECT name
                  FROM automapped
                  )

ORDER BY mapping_type, name;


--check inserted mapping with precedence > 1
SELECT *
FROM brand_name_mapped bnm
JOIN devv5.concept c
    ON bnm.concept_id_2 = c.concept_id

WHERE bnm.name IN
      (
      SELECT bnm.name
      FROM brand_name_mapped bnm
      GROUP BY bnm.name
      HAVING COUNT(*) > 1
      )
;

/****************************************/
--3. Supplier
--TEMPORARY SCRIPT

DROP TABLE IF EXISTS supplier_mapped;
CREATE TABLE IF NOT EXISTS supplier_mapped
(
    name         varchar(255),
    new_name     varchar(255),
    concept_id_2 integer,
    precedence   integer,
    mapping_type varchar(50)
);

--population of supplier_mapped from rtc backup
WITH rtc AS (
            SELECT DISTINCT *
            FROM relationship_to_concept_bckp300817
            )
INSERT
INTO supplier_mapped (name, new_name, concept_id_2, precedence, mapping_type)
SELECT DISTINCT
    dcs.concept_name,
    NULL,
    c.concept_id,
    rtc.precedence,
    'rtc_backup' AS mapping_type
FROM rtc
JOIN drug_concept_stage dcs
    ON rtc.concept_code_1 = dcs.concept_code AND dcs.concept_class_id = 'Supplier'
JOIN concept c
    ON c.concept_id = rtc.concept_id_2 AND c.concept_class_id = 'Supplier'
WHERE dcs.concept_name NOT IN (
                              SELECT dcs.concept_name
                              FROM rtc
                              JOIN drug_concept_stage dcs
                                  ON rtc.concept_code_1 = dcs.concept_code
                              JOIN concept c
                                  ON c.concept_id = rtc.concept_id_2
                              GROUP BY dcs.concept_name, rtc.precedence
                              HAVING COUNT(DISTINCT c.concept_id) > 1
                              )
;


--CHECKS
-- get mapping for review
WITH automapped      AS (
                        SELECT DISTINCT dcs.concept_name AS name, rtc.mapping_type, c.*
                        FROM relationship_to_concept rtc
                        JOIN drug_concept_stage dcs
                            ON dcs.concept_code = rtc.concept_code_1
                        JOIN concept c
                            ON rtc.concept_id_2 = c.concept_id
                        WHERE c.concept_class_id = 'Supplier'
                        ),

     supplier_mapped AS (
                        SELECT DISTINCT sm.name AS name, sm.mapping_type, c.*
                        FROM supplier_mapped sm
                        JOIN concept c
                            ON c.concept_id = sm.concept_id_2
                        )

SELECT *
FROM automapped

UNION ALL

SELECT *
FROM supplier_mapped
WHERE name NOT IN (
                  SELECT name
                  FROM automapped
                  )

ORDER BY mapping_type, name;


--check inserted mapping with precedence > 1
SELECT *
FROM supplier_mapped sm
JOIN devv5.concept c
    ON sm.concept_id_2 = c.concept_id

WHERE sm.name IN
      (
      SELECT sm.name
      FROM supplier_mapped sm
      GROUP BY sm.name
      HAVING COUNT(*) > 1
      )
;


/****************************************/
--4. Dose Form
--TEMPORARY SCRIPT

DROP TABLE IF EXISTS dose_form_mapped;
CREATE TABLE IF NOT EXISTS dose_form_mapped
(
    name         varchar(255),
    new_name     varchar(255),
    concept_id_2 integer,
    precedence   integer,
    mapping_type varchar(50)
);

--population of dose_form_mapped from rtc backup
WITH rtc AS (
            SELECT DISTINCT *
            FROM relationship_to_concept_bckp300817
            )
INSERT
INTO dose_form_mapped (name, new_name, concept_id_2, precedence, mapping_type)
SELECT DISTINCT
    dcs.concept_name,
    NULL,
    c.concept_id,
    rtc.precedence,
    'rtc_backup' AS mapping_type
FROM rtc
JOIN drug_concept_stage dcs
    ON rtc.concept_code_1 = dcs.concept_code AND dcs.concept_class_id = 'Dose Form'
JOIN concept c
    ON c.concept_id = rtc.concept_id_2 AND c.concept_class_id = 'Dose Form'
WHERE dcs.concept_name NOT IN (
                              SELECT dcs.concept_name
                              FROM rtc
                              JOIN drug_concept_stage dcs
                                  ON rtc.concept_code_1 = dcs.concept_code
                              JOIN concept c
                                  ON c.concept_id = rtc.concept_id_2
                              GROUP BY dcs.concept_name, rtc.precedence
                              HAVING COUNT(DISTINCT c.concept_id) > 1
                              )
  AND dcs.concept_name <> 'Solution'
;


--CHECKS
-- get mapping for review
WITH automapped       AS (
                         SELECT DISTINCT dcs.concept_name AS name, rtc.mapping_type, c.*
                         FROM relationship_to_concept rtc
                         JOIN drug_concept_stage dcs
                             ON dcs.concept_code = rtc.concept_code_1
                         JOIN concept c
                             ON rtc.concept_id_2 = c.concept_id
                         WHERE c.concept_class_id = 'Dose Form'
                         ),

     dose_form_mapped AS (
                         SELECT DISTINCT dfm.name AS name, dfm.mapping_type, c.*
                         FROM dose_form_mapped dfm
                         JOIN concept c
                             ON c.concept_id = dfm.concept_id_2
                         )

SELECT *
FROM automapped

UNION ALL

SELECT *
FROM dose_form_mapped
WHERE name NOT IN (
                  SELECT name
                  FROM automapped
                  )

ORDER BY mapping_type, name;


--check inserted mapping with precedence > 1
SELECT *
FROM dose_form_mapped dfm
JOIN devv5.concept c
    ON dfm.concept_id_2 = c.concept_id

WHERE dfm.name IN
      (
      SELECT dfm.name
      FROM dose_form_mapped dfm
      GROUP BY dfm.name
      HAVING COUNT(*) > 1
      )
;


/****************************************/
--5. Unit
--TEMPORARY SCRIPT

DROP TABLE IF EXISTS unit_mapped;
CREATE TABLE IF NOT EXISTS unit_mapped
(
    name              varchar(255),
    new_name          varchar(255),
    concept_id_2      integer,
    precedence        integer,
    conversion_factor float,
    mapping_type      VARCHAR(50)
);

--population of unit_mapped from rtc backup
WITH rtc AS (
            SELECT DISTINCT *
            FROM relationship_to_concept_bckp300817
            )
INSERT
INTO unit_mapped (name, new_name, concept_id_2, precedence, conversion_factor, mapping_type)
SELECT DISTINCT
    dcs.concept_name,
    NULL,
    c.concept_id,
    rtc.precedence,
    rtc.conversion_factor,
    'rtc_backup' AS mapping_type
FROM rtc
JOIN drug_concept_stage dcs
    ON rtc.concept_code_1 = dcs.concept_code AND dcs.concept_class_id = 'Unit'
JOIN concept c
    ON c.concept_id = rtc.concept_id_2 AND c.concept_class_id = 'Unit'
WHERE dcs.concept_name NOT IN (
                              SELECT dcs.concept_name
                              FROM rtc
                              JOIN drug_concept_stage dcs
                                  ON rtc.concept_code_1 = dcs.concept_code
                              JOIN concept c
                                  ON c.concept_id = rtc.concept_id_2
                              GROUP BY dcs.concept_name, rtc.precedence
                              HAVING COUNT(DISTINCT c.concept_id) > 1
                              )
;



--CHECKS
-- get mapping for review
WITH automapped  AS (
                    SELECT DISTINCT dcs.concept_name AS name, rtc.mapping_type, c.*
                    FROM relationship_to_concept rtc
                    JOIN drug_concept_stage dcs
                        ON dcs.concept_code = rtc.concept_code_1
                    JOIN concept c
                        ON rtc.concept_id_2 = c.concept_id
                    WHERE c.concept_class_id = 'Unit'
                    ),
     unit_mapped AS (
                    SELECT DISTINCT um.name AS name, um.mapping_type, c.*
                    FROM unit_mapped um
                    JOIN concept c
                        ON c.concept_id = um.concept_id_2
                    )
SELECT *
FROM automapped
UNION ALL
SELECT *
FROM unit_mapped
WHERE name NOT IN (
                  SELECT name
                  FROM automapped
                  )
ORDER BY mapping_type, name;


--check inserted mapping with precedence > 1
SELECT *
FROM unit_mapped um
JOIN devv5.concept c
    ON um.concept_id_2 = c.concept_id
WHERE um.name IN
      (
      SELECT um.name
      FROM unit_mapped um
      GROUP BY um.name
      HAVING COUNT(*) > 1
      )
;

--===============================================================================================
