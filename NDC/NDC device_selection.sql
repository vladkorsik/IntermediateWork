--TODO Get made them Devices (exist just in concept table, not in source. Need to use manual change https://github.com/OHDSI/Vocabulary-v5.0/tree/master/working/manual_changes)
/*UPDATE concept
SET concept_class_id = 'Device',
    domain_id = 'Device',
    standard_concept = 'S'
WHERE concept_code in ('000199602', '00019N602', '000199601', '065174461', '00019N601')
    AND vocabulary_id = 'NDC'
;*/


--TODO: to check non-drugs here: https://github.com/OHDSI/Vocabulary-v5.0/issues/31

--TODO: and here: http://forums.ohdsi.org/t/ndc-codes-with-letters/1142

--TODO: add parenteral nutrition:
--EGG YOLK PHOSPHOLIPIDS 12 MG/ML / Glycerin 25 MG/ML / Safflower Oil 50 MG/ML / Soybean Oil 50 MG/ML Injectable Suspension [Liposyn II]
--EGG YOLK PHOSPHOLIPIDS 12 MG/ML / Glycerin 25 MG/ML / Safflower Oil 100 MG/ML / Soybean Oil 100 MG/ML Injectable Suspension [Liposyn II 20 %]
--EGG YOLK PHOSPHOLIPIDS 12 MG/ML / Glycerin 25 MG/ML / Safflower Oil 100 MG/ML / Soybean Oil 100 MG/ML Injectable Suspension [Liposyn II 20 %]
--EGG YOLK PHOSPHOLIPIDS 12 MG/ML / Glycerin 25 MG/ML / Safflower Oil 100 MG/ML / Soybean Oil 100 MG/ML Injectable Suspension [Liposyn II 20 %]
--EGG YOLK PHOSPHOLIPIDS 12 MG/ML / Glycerin 25 MG/ML / Soybean Oil 100 MG/ML Injectable Suspension [Liposyn III 10 %]
--EGG YOLK PHOSPHOLIPIDS 12 MG/ML / Glycerin 25 MG/ML / Safflower Oil 100 MG/ML / Soybean Oil 100 MG/ML Injectable Suspension [Liposyn II 20 %]
--EGG YOLK PHOSPHOLIPIDS 12 MG/ML / Glycerin 25 MG/ML / Safflower Oil 50 MG/ML / Soybean Oil 50 MG/ML Injectable Suspension [Liposyn II]
--EGG YOLK PHOSPHOLIPIDS 12 MG/ML / Glycerin 25 MG/ML / Safflower Oil 50 MG/ML / Soybean Oil 50 MG/ML Injectable Suspension [Liposyn II]
--EGG YOLK PHOSPHOLIPIDS 12 MG/ML / Glycerin 25 MG/ML / Safflower Oil 100 MG/ML / Soybean Oil 100 MG/ML Injectable Suspension [Liposyn II]
--EGG YOLK PHOSPHOLIPIDS 12 MG/ML / Glycerin 25 MG/ML / Safflower Oil 100 MG/ML / Soybean Oil 100 MG/ML Injectable Suspension [Liposyn II]
--EGG YOLK PHOSPHOLIPIDS 12 MG/ML / Glycerin 25 MG/ML / Soybean Oil 100 MG/ML Injectable Suspension [Liposyn III]
--EGG YOLK PHOSPHOLIPIDS 12 MG/ML / Glycerin 25 MG/ML / Soybean Oil 100 MG/ML Injectable Suspension [Liposyn III]

--TODO: Add:
--SOD METABISULFITE
--'device' pattern

--TODO CHeck drugs here:
SELECT *
FROM NDC_manual_mapped m

WHERE
      target_concept_id != 'device'
      AND source_concept_id IN (SELECT concept_id FROM ndc_non_drugs);


--ToDO Check Devices were NOT recornized by script:
SELECT *
FROM NDC_manual_mapped m

WHERE
      target_concept_id = 'device'
      AND source_concept_id NOT IN (SELECT concept_id FROM ndc_non_drugs)
;



--Reference
--https://naturallysavvy.com/care/beware-your-antiperspirant-is-a-drug/
--https://www.fda.gov/Drugs/ResourcesForYou/Consumers/BuyingUsingMedicineSafely/UnderstandingOver-the-CounterMedicines/ucm239463.htm



--DROP TABLE IF EXISTS NDC_source;
CREATE TABLE NDC_source as (
select * from devv5.concept
where vocabulary_id = 'NDC'
AND not exists
(select 1 from devv5.concept_relationship cr where concept_id_1 = concept_id and relationship_id = 'Maps to' and cr.invalid_reason is null)
);


--START
DROP TABLE IF EXISTS NDC_remains;
CREATE TABLE NDC_remains as (SELECT * FROM NDC_source)
;

DROP TABLE IF EXISTS NDC_non_drugs;
CREATE TABLE NDC_non_drugs (LIKE NDC_source)
;

DROP TABLE IF EXISTS NDC_drugs;
CREATE TABLE NDC_drugs (LIKE NDC_source)
;

--TODO: check if we need this
--Excluding mapping done manually
--DELETE FROM NDC_remains
--WHERE concept_id in (SELECT concept_id FROM dalex.NDC_manual)
;

--0
--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
WHERE concept_name ~* ('Dextromethorphan|Hydrocort|METRONIDAZOLE|(?<!(titan|Octinoxate|octocrylene|homosalate|octisalate|niacinamide|adenosine|avobenzone|ensulizole|oxybenzone).*)(Salicylic|saliclylic)(?!.*(titan|Octinoxate|octocrylene|homosalate|' ||
      'octisalate|niacinamide|adenosine|avobenzone|ensulizole|oxybenzone))|neomycin|ibuprofen|acetaminophen|fentanyl|Estradiol|lidocaine|Benzocaine|albuterol')
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--1
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
WHERE concept_name ~* 'sun|spf|jart' and concept_name !~* 'sunmark(?!( witch hazel| BENZOIN COMPOUND TINCTURE))|childrens first aid|^first aid|(?<!SPF30 SUNSCREEN AND anti)bacterial|baceterial|hp_|foot care|tattoo care|tablet'
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
WHERE concept_name ~* 'sun|spf' and concept_name ~* 'sunmark(?!( witch hazel| BENZOIN COMPOUND TINCTURE))|childrens first aid|^first aid|(?<!SPF30 SUNSCREEN AND anti)bacterial|baceterial|hp_|foot care|tattoo care|tablet'
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--2
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
WHERE concept_name ~* 'antiperspirant|Anti-Perspirant|Anti Perspirant|deodorant|desodorant|DEODERANT' and concept_name !~* 'triclocarban|Triclosan|chloroxylenol|aluminum sesquichlorohydrate|ALUMINUM CHLOR|ALUMINUM ZIRCONIUM|tetrachlorohydrex'
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
WHERE concept_name ~* 'antiperspirant|Anti-Perspirant|Anti Perspirant|deodorant|desodorant|DEODERANT' and concept_name ~* 'triclocarban|Triclosan|chloroxylenol|aluminum sesquichlorohydrate|ALUMINUM CHLOR|ALUMINUM ZIRCONIUM|tetrachlorohydrex'
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--3
--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
WHERE concept_name ~* 'kp_|hp_'
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--4
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
WHERE concept_name ~* 'SELF|TRAIN|DAIL|DRESS|BANDAGE|MGMT|PANTS|CATHETER' and concept_name !~* ('SELF PITY|homeo|ALUMINUM CHLOROHYDRATE|aluminum zirconium|formula|DAILY-VITE|Miconazole|HOMEOPATHIC|H-BALM|haemophilus influenzae|BACILLUS CALMETTE-GUERIN|' ||
                                                                              'Benzethonium|FLUORIDE|VACCINE|VITAMIN(?!.* c daily moist)|VIT-|MULTIVIT|(?<!(titan|Octinoxate|octocrylene|homosalate|octisalate|niacinamide|adenosine|avobenzone|ensulizole|oxybenzone).*)' ||
                                                                              '(benzoyl peroxide|glycerin|glycerol)(?!.*(titan|Octinoxate|octocrylene|homosalate|octisalate|niacinamide|adenosine|avobenzone|ensulizole|oxybenzone))|arsenicum alb')
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
WHERE concept_name ~* 'SELF|TRAIN|DAIL|DRESS|BANDAGE|MGMT|PANTS|CATHETER' and concept_name ~* ('SELF PITY|homeo|ALUMINUM CHLOROHYDRATE|aluminum zirconium|formula|DAILY-VITE|Miconazole|HOMEOPATHIC|H-BALM|haemophilus influenzae|BACILLUS CALMETTE-GUERIN|' ||
                                                                              'Benzethonium|FLUORIDE|VACCINE|VITAMIN(?!.* c daily moist)|VIT-|MULTIVIT|(?<!(titan|Octinoxate|octocrylene|homosalate|octisalate|niacinamide|adenosine|avobenzone|ensulizole|oxybenzone).*)' ||
                                                                              '(benzoyl peroxide|glycerin|glycerol)(?!.*(titan|Octinoxate|octocrylene|homosalate|octisalate|niacinamide|adenosine|avobenzone|ensulizole|oxybenzone))|arsenicum alb')
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--5
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
WHERE concept_name ~* 'STICK|primer|moisture|mask' and concept_name !~* ('(?<!(titan|Octinoxate|octocrylene|homosalate|octisalate|niacinamide|adenosine|avobenzone|ensulizole|oxybenzone).*)(allantoin|glycerin|glycerol)(?!.*(titan|Octinoxate|octocrylene|' ||
                                                       'homosalate|octisalate|niacinamide|adenosine|avobenzone|ensulizole|oxybenzone))|thyroid|panthenol|povidone|ALUMINUM ZIRCONIUM|tetrachlorohydrex|ALUMINUM CHLOR')
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
WHERE concept_name ~* 'STICK|primer|moisture|mask' and concept_name ~* ('(?<!(titan|Octinoxate|octocrylene|homosalate|octisalate|niacinamide|adenosine|avobenzone|ensulizole|oxybenzone).*)(allantoin|glycerin|glycerol)(?!.*(titan|Octinoxate|octocrylene|' ||
                                                       'homosalate|octisalate|niacinamide|adenosine|avobenzone|ensulizole|oxybenzone))|thyroid|panthenol|povidone|ALUMINUM ZIRCONIUM|tetrachlorohydrex|ALUMINUM CHLOR')
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--6
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
WHERE concept_name ~* 'CLEANSER|PRIMER|shampoo|MOISTURIZER' and concept_name !~* ('triclocarban|Triclosan|(?<!(titan|Octinoxate|octocrylene|homosalate|octisalate|niacinamide|adenosine|avobenzone|ensulizole|oxybenzone).*)(benzoyl peroxide|ALCOHOL|glycerin|' ||
                                                                'glycerol)(?!.*(titan|Octinoxate|octocrylene|homosalate|octisalate|niacinamide|adenosine|avobenzone|ensulizole|oxybenzone))|benzalkonium chloride|pyrithione|Selenium Sulfide|Coal Tar|' ||
                                                                'Anthralin|Chloroxylenol|CHLORHEXIDINE|BENZETHONIUM|Ascorbic Acid|ANTIBACTERIAL|ciclopirox|defendex|homeopathic|Hydrocortisone|Ketoconazole|niacinamide|panthenol')
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
WHERE concept_name ~* 'CLEANSER|PRIMER|shampoo|MOISTURIZER' and concept_name ~* ('triclocarban|Triclosan|(?<!(titan|Octinoxate|octocrylene|homosalate|octisalate|niacinamide|adenosine|avobenzone|ensulizole|oxybenzone).*)(benzoyl peroxide|ALCOHOL|glycerin|' ||
                                                                'glycerol)(?!.*(titan|Octinoxate|octocrylene|homosalate|octisalate|niacinamide|adenosine|avobenzone|ensulizole|oxybenzone))|benzalkonium chloride|pyrithione|Selenium Sulfide|Coal Tar|' ||
                                                                'Anthralin|Chloroxylenol|CHLORHEXIDINE|BENZETHONIUM|Ascorbic Acid|ANTIBACTERIAL|ciclopirox|defendex|homeopathic|Hydrocortisone|Ketoconazole|niacinamide|panthenol')
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--7
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
WHERE concept_name ~* 'pampers|plastic|elastic|tube' and concept_name !~* 'flower|asclepias|INDUSTROTOX|arsenicum|HEADACHE FLATULENCE|DIOSCOREA|CONSTIPATION|TUBERCULIN|BACILLINUM PULMO|BABY COLIC|HOMEOPATHIC|benzalkonium|pollen|root|ASTHMA|CYCLAMEN|D-102'
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
WHERE concept_name ~* 'pampers|plastic|elastic|tube' and concept_name ~* 'flower|asclepias|INDUSTROTOX|arsenicum|HEADACHE FLATULENCE|DIOSCOREA|CONSTIPATION|TUBERCULIN|BACILLINUM PULMO|BABY COLIC|HOMEOPATHIC|benzalkonium|pollen|root|ASTHMA|CYCLAMEN|D-102'
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--8
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
WHERE concept_name ~* 'lotion|sanitizer|AEROSOL' and concept_name !~* ('albuterol|Benzalkonium Chloride|pyrithione|ALUMINUM CHLOR|sesquichlorohydrate|conazole|(?<!(titan|Octinoxate|octocrylene|homosalate|octisalate|niacinamide|adenosine|avobenzone|' ||
                                                     'ensulizole|oxybenzone).*)(zinc|glycerin|glycerol|allantoin)(?!.*(titan|Octinoxate|octocrylene|homosalate|octisalate|niacinamide|adenosine|avobenzone|ensulizole|oxybenzone))|Minoxidil|Triclosan|' ||
                                                     'Triamcinolone|clobetasol|chloroxylenol|undecylenic|cortizone|triclosan|diclofenac|methasone|lidocain|hydrocortisone|ipratropium|loxapine|metronidazole|niacinamide|panthenol|(?<!(titan|Octinoxate|' ||
                                                     'octocrylene|homosalate|octisalate|niacinamide|adenosine|avobenzone|ensulizole|oxybenzone).*)(alcohol|Ethanol)(?=.*(\.7|\.6|6 |6\.2 |652|672|693|710|60\%|22|33|545|585))(?!.*(titan|Octinoxate|' ||
                                                     'octocrylene|homosalate|octisalate|niacinamide|adenosine|avobenzone|ensulizole|oxybenzone))')
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
WHERE concept_name ~* 'lotion|sanitizer|AEROSOL' and concept_name ~* ('albuterol|Benzalkonium Chloride|pyrithione|ALUMINUM CHLOR|sesquichlorohydrate|conazole|(?<!(titan|Octinoxate|octocrylene|homosalate|octisalate|niacinamide|adenosine|avobenzone|' ||
                                                     'ensulizole|oxybenzone).*)(zinc|glycerin|glycerol|allantoin)(?!.*(titan|Octinoxate|octocrylene|homosalate|octisalate|niacinamide|adenosine|avobenzone|ensulizole|oxybenzone))|Minoxidil|Triclosan|' ||
                                                     'Triamcinolone|clobetasol|chloroxylenol|undecylenic|cortizone|triclosan|diclofenac|methasone|lidocain|hydrocortisone|ipratropium|loxapine|metronidazole|niacinamide|panthenol|(?<!(titan|Octinoxate|' ||
                                                     'octocrylene|homosalate|octisalate|niacinamide|adenosine|avobenzone|ensulizole|oxybenzone).*)(alcohol|Ethanol)(?=.*(\.7|\.6|6 |6\.2 |652|672|693|710|60\%|22|33|545|585))(?!.*(titan|Octinoxate|' ||
                                                     'octocrylene|homosalate|octisalate|niacinamide|adenosine|avobenzone|ensulizole|oxybenzone))')
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--9
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
WHERE concept_name ~* 'home' AND concept_name ~* 'NLIHOME DENTAL CARE|Petrolat|ACME|menthol kit'
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
WHERE concept_name ~* 'home' AND concept_name !~* 'NLIHOME DENTAL CARE|Petrolat|ACME|menthol kit'
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--10
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
WHERE concept_name ~* 'SURG|UROLOG|EDUC|GLOVE|blistex' AND concept_name !~* ('(?<!(titan|Octinoxate|octocrylene|homosalate|octisalate|niacinamide|adenosine|avobenzone|ensulizole|oxybenzone).*)(glycerin|glycerol)(?!.*(titan|Octinoxate|octocrylene|homosalate|' ||
                                                   'octisalate|niacinamide|adenosine|avobenzone|ensulizole|oxybenzone))|hypericum|alcohol \.7|reducer|BETASEPT|Chloroxylenol|Triclosan|aluminum zirconium|toxoid|POVIDONE|Lansoprazole|dexamethasone|' ||
                                                   'Famotidine|ranitidine|aluminium zirconium|Cimetidine|phenol|benzokaine')
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
WHERE concept_name ~* 'SURG|UROLOG|EDUC|GLOVE|blistex' AND concept_name ~* ('(?<!(titan|Octinoxate|octocrylene|homosalate|octisalate|niacinamide|adenosine|avobenzone|ensulizole|oxybenzone).*)(glycerin|glycerol)(?!.*(titan|Octinoxate|octocrylene|homosalate|' ||
                                                   'octisalate|niacinamide|adenosine|avobenzone|ensulizole|oxybenzone))|hypericum|alcohol \.7|reducer|BETASEPT|Chloroxylenol|Triclosan|aluminum zirconium|toxoid|POVIDONE|Lansoprazole|dexamethasone|' ||
                                                   'Famotidine|ranitidine|aluminium zirconium|Cimetidine|phenol|benzokaine')
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;


--11(0)
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
    where concept_name ~* 'leaf|venom|flower|root|detox'
and concept_name !~*'titan|Octinoxate|Octisalate|oxybenzone|ensulizole|octocrylene|homosalate';

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;


--11(1)
--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
where concept_name ~* ('seed|pollen|flos|cartilago|suppositor|tincture|pellet|officinal|occidentalis|vegetabilis|homeopathic|' ||

                       'aspidosperma|aconitum|adrenalinum|aesculus|allium|anemarrhena|anthracinum|apis mel|aralia|argentum|arnica|arsenic|' ||
                       'ascorbic acid|atropa|aurum|baptisia|belladonna|bellis|berber|bryonia|calcarea|calendula|cantharis|' ||
                       'chamomilla|cinchona|colchicum|collinsonia|colocynthis|conium|crotalus|digitalis|echinacea|' ||
                       'equisetum|eupatorium|euphrasia|folic acid|gelsemium|graphites|hamamelis|histaminum|hydrastis|' ||
                       'hypericum|ignatia|ipecac|iris versicolor|kreosotum|lachesis|ledum|lycopodium|mezereum|millefolium|myrrha|' ||
                       'nasturtium|phytolacca|plantago|pulsatilla|pyrogenium|riboflavin|thyroidinum|tocopherol|trifolium pratense|vomica|QUEBRACHO|' ||
                       'ruta graveolens|dulcamara')
and concept_name !~* 'scrub|rosehip|peeling'
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--11(2)
--Code for DRUGS
INSERT INTO NDC_drugs
select * from NDC_remains
   where concept_name ~* ('(?<!(titan|Octinoxate|octocrylene|homosalate|octisalate|avobenzone|ensulizole|oxybenzone).*)(niacinamide)(?!.*(titan|Octinoxate|octocrylene|homosalate|octisalate|avobenzone|ensulizole|oxybenzone))|' ||
                          'Alclometasone|5-Hydroxytryptophan|6-Aminocaproic Acid|Acebutolol|Acetazolamide|Acetylcarnitine|Acetylcysteine|Activated Charcoal|Acyclovir|' ||
                         'adalimumab|Albendazole|Albumin Human, USP|Alendronate|alfuzosin|Allopurinol|alogliptin|Alprazolam|Alprostadil|Amantadine|Amikacin|Amiloride|Aminophylline|Amiodarone|Amitriptyline|Amlodipine|Ammonium Chloride|Amobarbital|' ||
                         'Amoxicillin|Amphetamine|Amphotericin B|Ampicillin|Antipyrine|Apomorphine|aripiprazole|Articaine|Aspartate|Aspirin|Atazanavir|Atenolol|atomoxetine|' ||
                         'atorvastatin|Atropine|attapulgite|azatadine|Azathioprine|azelastine|Azithromycin|Bacitracin|Baclofen|Barbital|Beclomethasone|benazepril|bendamustine|' ||
                         'Bendroflumethiazide|Benzalkonium|Benzethonium|benzyl benzoate|BETAHISTINE|Betamethasone|Bethanechol|Bisacodyl|' ||
                         'Bisoprolol|Botulinum Toxin Type A|Bran|brilliant green|brimonidine|Bromhexine|Bromocriptine|Brompheniramine|Budesonide|' ||
                         'buflomedil|Bumetanide|Bupivacaine|Buprenorphine|Bupropion|butalbital|Caffeine|Calcitriol|canagliflozin|candesartan|Captopril|' ||
                         'Carbachol|Carbamazepine|carbetapentane|Carbidopa|carbinoxamine|Carisoprodol|carprofen|Carteolol|carvedilol|Cefaclor|Cefadroxil|Cefazolin|Cefixime|Cefotaxime|cefpodoxime|cefprozil|Ceftazidime|ceftiofur|Cefuroxime|celecoxib|Cephalexin|Cetirizine|' ||
                         'chlophedianol|Chloramphenicol|chlorcyclizine|Chlordiazepoxide|Chlorhexidine|Chlorobutanol|Chlorophyll|chlorophyllin|Chloroquine|Chlorothiazide|chloroxylenol|Chlorphenesin|Chlorpheniramine|Chlorpromazine|Chlorpropamide|Chlortetracycline|Chlorthalidone|Chlorzoxazone|' ||
                         'Cholecalciferol|Cholestyramine Resin|Choline|Chorionic Gonadotropin|CHROMIUM PICOLINATE|CHYMOTRYPSIN|ciclopirox|Cimetidine|Ciprofloxacin|Cisapride|Citalopram|Clarithromycin|Clavulanate|Clemastine|Clenbuterol|Clindamycin|Clioquinol|clobazam|Clobetasol|Clomipramine|Clonazepam|Clonidine|clorazepate|Clotrimazole|Cloxacillin|' ||
                         'Clozapine|cobamamide|cobicistat|Cocaine|Codeine|Colchicine|Colistin|Corticotropin|Cortisone|coumarin|Cromolyn|Cyclandelate|Cyclizine|cyclobenzaprine|Cyclophosphamide|Cyclosporine|Dalteparin|Dantrolene|dapagliflozin|Dapsone|darbepoetin alfa|darunavir|deferasirox|deflazacort|Desipramine|' ||
                         'desloratadine|desmopressin|Desvenlafaxine|dexbrompheniramine|dexchlorpheniramine|Dexmedetomidine|dexmethylphenidate|Dextran 70|Dextroamphetamine|Diazepam|Diazoxide|Dibucaine|Diclofenac|Dicloxacillin|Dicyclomine|Didanosine|Diethylpropion|Diethylstilbestrol|Digitoxin|Digoxin|dihydrocodeine|' ||
                         'Dihydroergocristine|Dihydroergotamine|Dihydrotachysterol|Diltiazem|Dimenhydrinate|Dimethyl Sulfoxide|Diphenhydramine|Dipyridamole|Disopyramide|Disulfiram|Dobutamine|docetaxel|Docusate|domiphen|Domperidone|donepezil|Dopamine|Doxazosin|Doxepin|Doxercalciferol|Doxycycline|Doxylamine|duloxetine|dyclonine|' ||
                         'Dyphylline|Econazole|efavirenz|eltrombopag|emtricitabine|Enalapril|enrofloxacin|entacapone|Ephedrine|Epinephrine|Epirubicin|Epoetin Alfa|' ||
                         'Ergocalciferol|Ergonovine|Ergotamine|Erythromycin|Escherichia coli|Esomeprazole|Estriol|Estrogens, Conjugated (USP)|Estrone|Ethambutol|Etodolac|Eucalyptol|ezetimibe|factor IX|Factor VIII|Famotidine|febantel|Felodipine|Fenofibrate|Fenoprofen|ferric ammonium citrate|ferric sulfate|Ferrous fumarate|ferrous gluconate|ferrous sulfate|fexofenadine|Fibrinogen|Filgrastim|Flecainide|Fluconazole|flunixin|fluocinolone|' ||
                         'Fluorometholone|Fluorouracil|Fluoxetine|Fluoxymesterone|Fluphenazine|Flurbiprofen|Fluvoxamine|Follicle Stimulating Hormone|Follitropin Alfa|formoterol|Fosinopril|Furazolidone|Furosemide|gabapentin|Galantamine|Ganciclovir|gatifloxacin|gemcitabine|Gemfibrozil|Gentamicin|Ginkgo biloba extract|glimepiride|Glipizide|Glucosamine|Glyburide|Glycine|Glycopyrrolate|Gramicidin|Granisetron|Griseofulvin|guaiacolsulfonate|Guaifenesin|' ||
                         'Guanethidine|Guanfacine|Haloperidol|Helium|heparin|hepatitis B immune globulin|Heptaminol|Hexachlorophene|Hexylresorcinol|Histamine|homatropine|Hydralazine|Hydrochlorothiazide|Hydrocodone|' ||
                         'Hydrofluoric Acid|Hydrogen Peroxide|Hydromorphone|hydroxyurea|Hydroxyzine|Hyoscyamine|Hypochlorite|Ibrutinib|idebenone|Idoxuridine|Ifosfamide|iloperidone|Imipramine|Immunoglobulin G|Indapamide|Indomethacin|Inositol|insulin, isophane|Insulin Lispro|Insulin, Regular, Pork|Interferon Alfa-2a|Interferon Alfa-2b|Interferon beta-1a|Intrinsic factor|Iodoquinol|Ipratropium|irbesartan|Isoetharine|isometheptene|isoniazid|Isopropamide|' ||
                         'Isoproterenol|Isosorbide|Isosorbide Dinitrate|Isotretinoin|Isradipine|Itraconazole|ivacaftor|Ivermectin|Kanamycin|Ketoconazole|Ketoprofen|Ketorolac|Ketotifen|Labetalol|Lactobacillus|Lactobacillus acidophilus|Lamivudine|lamotrigine|lansoprazole|lanthanum carbonate|lenalidomide|Leuprolide|Levamisole|Levetiracetam|Levocarnitine|Levodopa|Levofloxacin|Levonorgestrel|levothyroxine|Lincomycin|liothyronine|Lisdexamfetamine|Lisinopril|' ||
                         'Lithium Carbonate|lithium citrate|Liver Extract|lomitapide|Loperamide|Loratadine|Lorazepam|Losartan|loteprednol etabonate|Lovastatin|Loxapine|lufenuron|Luteinizing Hormone|Mannitol|' ||
                         'Mebendazole|Mechlorethamine|Meclizine|mecobalamin|Medroxyprogesterone|Megestrol|meloxicam|Memantine|Meperidine|Mepivacaine|' ||
                         'Meprobamate|Merbromin|mesalamine|Mesna|Mestranol|metaproterenol|Metformin|Methadone|Methamphetamine|Methenamine|' ||
                         'Methimazole|Methocarbamol|Methotrexate|Methscopolamine|Methyclothiazide|Methyldopa|Methylphenidate|Methyltestosterone|' ||
                         'Metipranolol|Metoclopramide|Metolazone|Metoprolol|Mexiletine|Miconazole|Midazolam|Midodrine|milbemycin oxime|milnacipran|' ||
                         'Minocycline|Mirtazapine|montelukast|Moxidectin|Mycophenolic Acid|Nadolol|Nafcillin|Naloxone|Naltrexone|Naphazoline|Naproxen|' ||
                         'nefazodone|Neostigmine|Nevirapine|Nicardipine|Nifedipine|Nimodipine|Nisoldipine|nitazoxanide|Nitrofurantoin|Nitrofurazone|' ||
                         'Nitrogen|Nitroglycerin|Nitrous Oxide|Nizatidine|Norepinephrine|Norethindrone|Norgestrel|Nortriptyline|Nystatin|Octreotide|' ||
                         'Ofloxacin|olanzapine|olmesartan|Omeprazole|Ondansetron|Opium|Orphenadrine|Oxacillin|Oxazepam|oxcarbazepine|oxybutynin|' ||
                         'Oxycodone|Oxygen|Oxymetazoline|Oxymorphone|Oxyquinoline|Oxytetracycline|Oxytocin|paliperidone|palonosetron|pamabrom|' ||
                         'pamidronate|Pancreatin|pantoprazole|Papaverine|paricalcitol|Paroxetine|peginterferon alfa-2b|Penbutolol|Penicillamine|' ||
                         'Penicillin G|Penicillin V|Pentazocine|Pentobarbital|Pentosan Polysulfate|Pentoxifylline|perampanel|Permethrin|Perphenazine|' ||
                         'Phenazopyridine|phendimetrazine|Pheniramine|Phenobarbital|Phentermine|Phenylbutazone|phenylbutyrate|Phenylephrine|' ||
                         'Phenylpropanolamine|phenyltoloxamine|Phenytoin|Physostigmine|Phytosterols|Pilocarpine|Pindolol|pioglitazone|Piperacillin|' ||
                         'piperazine|Piracetam|pirbuterol|Piroxicam|pitavastatin|podophyllin|polidocanol|Polymyxin B|' ||
                         'ropivacaine|morphine|Ranitidine|propafenone|propranolol|Zolpidem|venlafaxine|tetracycline|triamcinolone|trospium|Theophylline|tramadol|verapamil|trazodone|' ||
                         'tapendalol|Scopalamine|rotigotine|Ropinirole|benzoyl peroxide|coal tar')
     and concept_name !~* 'phenylalanine'
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--12
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
where concept_name ~* ('glyceryl stearate|Aluminum stearate|Amber|Arbutin|BEMOTRIZINOL|BISOCTRIZOLE|Benzene|Collagen|Diamond|ETHYL DIHYDROXYPROPYL PABA|' ||
      'Ecamsule|Hydroxyproline|Kinetin|Octinoxate|POLYSILICONE-15|Propolis|RNA|Silicon|TRISILOXANE|Uric Acid|' ||
      'amiloxate|avobenzone|benzimidazole|benzophenone|cinnamate|diethylamino hydroxybenzoyl hexyl benzoate|' ||
      'dioxybenzone|drometrizole|drometrizole trisiloxane|ensulizole|enzacamene|hexyl salicylate|homosalate|' ||
      'meradimate|neral|octisalate|octocrylene|octyltriethoxysilane|olive oil|oxybenzone|padimate-O|' ||
      'resveratrol|stearate|sulisobenzone|titan')
and concept_name !~* ('Triclosan|triclocarban|Triamcinolone|Testosterone|pyridoxine|Naproxen|Ipecac|Iodine|Immunoglobulin|Histidine|Histamine|Folic Acid|Escherichia coli|Epinephrine|Cortisone|Corticotropin|zeel|' ||
                      '(?<!(titan|Octinoxate|octocrylene|homosalate|octisalate|avobenzone|ensulizole|oxybenzone).*)(vitamin|detox)(?!.*(titan|Octinoxate|octocrylene|homosalate|octisalate|avobenzone|ensulizole|oxybenzone))|' ||
                      'tablet|plaster|FNG I|silent nights|' ||
                      'sleep |external analgesic|phenylephrine')
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
where concept_name ~* ('glyceryl stearate|Aluminum stearate|Amber|Arbutin|BEMOTRIZINOL|BISOCTRIZOLE|Benzene|Collagen|Diamond|ETHYL DIHYDROXYPROPYL PABA|' ||
      'Ecamsule|Hydroxyproline|Kinetin|Octinoxate|POLYSILICONE-15|Propolis|RNA|Silicon|TRISILOXANE|Uric Acid|' ||
      'amiloxate|avobenzone|benzimidazole|benzophenone|cinnamate|diethylamino hydroxybenzoyl hexyl benzoate|' ||
      'dioxybenzone|drometrizole|drometrizole trisiloxane|ensulizole|enzacamene|hexyl salicylate|homosalate|' ||
      'meradimate|neral|octisalate|octocrylene|octyltriethoxysilane|olive oil|oxybenzone|padimate-O|' ||
      'resveratrol|stearate|sulisobenzone|titan')
and concept_name ~* ('Triclosan|triclocarban|Triamcinolone|Testosterone|pyridoxine|Naproxen|Ipecac|Iodine|Immunoglobulin|Histidine|Histamine|Folic Acid|Escherichia coli|Epinephrine|Cortisone|Corticotropin|zeel|' ||
                      '(?<!(titan|Octinoxate|octocrylene|homosalate|octisalate|avobenzone|ensulizole|oxybenzone).*)(vitamin|detox)(?!.*(titan|Octinoxate|octocrylene|homosalate|octisalate|avobenzone|ensulizole|oxybenzone))|' ||
                      'tablet|plaster|FNG I|silent nights|' ||
                      'sleep |external analgesic|phenylephrine')
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--13
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
where concept_name ~* 'luer|anesthesia|stom|bag|pump|infusion|clamp|pouch|stomy|anesthesia|needle|strip|fluorescein|connect'
  and concept_name !~* ('connective tissue|STOMAPLEX|chelone|FORMULA|TINCTURE|ANTACID|STOMACH CRAMPS|SPLEENEX|' ||
      'Relief|LUMBAGOFORCE|GASTROPANPAR|echinacea|hydroquinone|apomorphine|GRAPHITES|calendula|paulinia|acetyl coenzyme|' ||
      'ALLERGEN|calcarea|DIATHESIS|betaine|Cortisol|cannabidiol|Buprenorphine|tablet|cabbage|Bismuth|naja naja|' ||
      'APPETITE|ascorbic acid|atropa|ALUMINUM HYDROXIDE|broccoli|hyoscyamus|needle oil|Oxymetazoline|nitroglycerin|' ||
      'pumpkin|VITAMIN')
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
where concept_name ~* 'luer|anesthesia|stom|bag|pump|infusion|clamp|pouch|stomy|anesthesia|needle|strip|fluorescein|connect'
  and concept_name ~* ('connective tissue|STOMAPLEX|chelone|FORMULA|TINCTURE|ANTACID|STOMACH CRAMPS|SPLEENEX|' ||
      'Relief|LUMBAGOFORCE|GASTROPANPAR|echinacea|hydroquinone|apomorphine|GRAPHITES|calendula|paulinia|acetyl coenzyme|' ||
      'ALLERGEN|calcarea|DIATHESIS|betaine|Cortisol|cannabidiol|Buprenorphine|tablet|cabbage|Bismuth|naja naja|' ||
      'APPETITE|ascorbic acid|atropa|ALUMINUM HYDROXIDE|broccoli|hyoscyamus|needle oil|Oxymetazoline|nitroglycerin|' ||
      'pumpkin|VITAMIN')
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--14
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
where concept_name ~* 'BRACH|^GU |^MIX |GRAFT|HYDROPHILIC|CRANI|SNARE|MESH|EPIDURAL|LENS|CROWN|SACRO|ILIAC|SEPARAT|LUBRICANT|CAUDAL|PLANTAR|OXYGENATOR|HOOK|MANIPUL'
and concept_name !~* 'aluminum chloride|BUPIV|OPHTHALMIC|EYE(?!glass)|tears|DROPS|SUCRAID'
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
where concept_name ~* 'BRACH|^GU |^MIX |GRAFT|HYDROPHILIC|CRANI|SNARE|MESH|EPIDURAL|LENS|CROWN|SACRO|ILIAC|SEPARAT|LUBRICANT|CAUDAL|PLANTAR|OXYGENATOR|HOOK|MANIPUL'
and concept_name ~* 'aluminum chloride|BUPIV|OPHTHALMIC|EYE(?!glass)|tears|DROPS|SUCRAID'
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--15
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
    where concept_name ~* 'PADDING|THIN|ROLL|APPLICELL| BODY |POSITION|GOAL|HEAD|NORET|TUBING|STRAP|^NM|DRAIN|^CL |^LOW |HISTOPLASMA|BLOOD|FOLLOW|CYTOLOGY|FIBULA|SEGMENT'
and concept_name !~* ('tears|PLEO PIN|Triclosan|TEREBINTHINA|Terbutaline|anguilla|NATURASIL|LICEFREEE|lice ice|carduus|borax|lecithin|matricaria|hydrate|aconit|menstruation|interferon|head cold|hemacord|cord blood|cyanocobalamin|chewable|headache|' ||
    'chemicals|cell salts|aluminum chlor|aluminum sesquichlorohydrate|Aluminum Zirconium|BIO-COMBINATION|chinese|cartilage')
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
    where concept_name ~* 'PADDING|THIN|ROLL|APPLICELL| BODY |POSITION|GOAL|HEAD|NORET|TUBING|STRAP|^NM|DRAIN|^CL |^LOW |HISTOPLASMA|BLOOD|FOLLOW|CYTOLOGY|FIBULA|SEGMENT'
and concept_name ~* ('tears|PLEO PIN|Triclosan|TEREBINTHINA|Terbutaline|anguilla|NATURASIL|LICEFREEE|lice ice|carduus|borax|lecithin|matricaria|hydrate|aconit|menstruation|interferon|head cold|hemacord|cord blood|cyanocobalamin|chewable|headache|' ||
    'chemicals|cell salts|aluminum chlor|aluminum sesquichlorohydrate|Aluminum Zirconium|BIO-COMBINATION|chinese|cartilage')
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--16
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
        where concept_name ~* 'BASEPLATE|HEPATO|BILLIAR|SCAPULA|VIEW|ACETABULA|LABOR|PATELLA|VERTEBR|ABLAT|LINER|MANDIBUL|MRI |LEFT|RIGHT|SACRL|PINN |PLUG|SHOULDER'
and concept_name !~* 'triclosan|tetrofosmin|nicotine|hepatolite|CHITOPREX|antacid|capsaicin|niacinamide|atriplex wrightii|allantoin'
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
        where concept_name ~* 'BASEPLATE|HEPATO|BILLIAR|SCAPULA|VIEW|ACETABULA|LABOR|PATELLA|VERTEBR|ABLAT|LINER|MANDIBUL|MRI |LEFT|RIGHT|SACRL|PINN |PLUG|SHOULDER'
and concept_name ~* 'triclosan|tetrofosmin|nicotine|hepatolite|CHITOPREX|antacid|capsaicin|niacinamide|atriplex wrightii|allantoin'
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--17
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
    where concept_name ~* 'ACCESS|TITER|ANTIBODY|CULTURE|ANAL| EXAM|^LIQUID|^SUPPOSITORY|OGRAM|GRAPHY|SEDATION|ADMIN|SUSPENSORY|^SUT |^SUTR |SWALLOW|^SYN |^END'
and concept_name !~* 'Trolamine Salicylate|fumarate|tenofovir|Topical Analgesic|Oral Pain Reliever|MEPHITIS|milk|capsaicin|dexamethasone'
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
    where concept_name ~* 'ACCESS|TITER|ANTIBODY|CULTURE|ANAL| EXAM|^LIQUID|^SUPPOSITORY|OGRAM|GRAPHY|SEDATION|ADMIN|SUSPENSORY|^SUT |^SUTR |SWALLOW|^SYN |^END'
and concept_name ~* 'Trolamine Salicylate|fumarate|tenofovir|Topical Analgesic|Oral Pain Reliever|MEPHITIS|milk|capsaicin|dexamethasone'
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--18
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
    where concept_name ~* 'CANNU|MUSCLE|PORT|TRIPLE|SCAPLE|MOTOR|SPEECH|ANEURYSM|THORACIC|POULTICE|HARMONIC|WOUND|FISTULA|FRACT|HARMONIC|MOTOR|SPEECH|BYPASS|LUPUS|ASSEMBLY'
and concept_name !~* 'VERTEBRA THORACICA|vitamin|TRIPLE (COMPLEX|sleep)|pituitarum|Triclocarban|povidone|HCB-TONE|fragaria|felis catus|BAMBOO SAP PATCH|natural medicine|oyster shell|atriplex|abobotulinumtoxinA| support |milk|aluminum zirconium|aluminum sesquichlorohydrate'
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
    where concept_name ~* 'CANNU|MUSCLE|PORT|TRIPLE|SCAPLE|MOTOR|SPEECH|ANEURYSM|THORACIC|POULTICE|HARMONIC|WOUND|FISTULA|FRACT|HARMONIC|MOTOR|SPEECH|BYPASS|LUPUS|ASSEMBLY'
and concept_name ~* 'VERTEBRA THORACICA|vitamin|TRIPLE (COMPLEX|sleep)|pituitarum|Triclocarban|povidone|HCB-TONE|fragaria|felis catus|BAMBOO SAP PATCH|natural medicine|oyster shell|atriplex|abobotulinumtoxinA| support |milk|aluminum zirconium|aluminum sesquichlorohydrate'
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--19
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
    where concept_name ~* 'CHAMBER|DUAL|PULSE|KIDNEY|LEAD|BLADD|TWISTER|LUNG|BIOPSY|TRUNC|STRIP|STABLE|BRUSH|HEMO|HAEMO|SATURAT|METAB|FOLLOW|QUANT'
and concept_name !~* ('STREPTOCOCCUS|TOTAL LEAD|TETRAHYDROZOLINE|Tioconazole|TOLNAFTATE|Simethicone|RENINUM|HEMORRHOID|Sore Throat|LOZENGE|allantoin|ear|HEMOTREAT|OB METAB|NICOTINE|LUNG|kidney bean|Hydroquinone|datura stramonium|castor|niacinamide|' ||
    'benzoyl peroxide|praziquantel|soybean|CONSTIPATION|dextran|Haemophilus influenzae|dextrose|povidone|vaccine|antacid|hemorrhoidal|BLADDER (2\.2|irritation)|capsaicin')
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
    where concept_name ~* 'CHAMBER|DUAL|PULSE|KIDNEY|LEAD|BLADD|TWISTER|LUNG|BIOPSY|TRUNC|STRIP|STABLE|BRUSH|HEMO|HAEMO|SATURAT|METAB|FOLLOW|QUANT'
and concept_name ~* ('STREPTOCOCCUS|TOTAL LEAD|TETRAHYDROZOLINE|Tioconazole|TOLNAFTATE|Simethicone|RENINUM|HEMORRHOID|Sore Throat|LOZENGE|allantoin|ear|HEMOTREAT|OB METAB|NICOTINE|LUNG|kidney bean|Hydroquinone|datura stramonium|castor|niacinamide|' ||
    'benzoyl peroxide|praziquantel|soybean|CONSTIPATION|dextran|Haemophilus influenzae|dextrose|povidone|vaccine|antacid|hemorrhoidal|BLADDER (2\.2|irritation)|capsaicin')
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--20
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
    where concept_name ~* 'SHUNT|ORTHOPED|PIECE|VALVE|EXTENTI|EXTEND|DRAINAGE|ABSCESS|URINA|URINE|ALYSIS|^TABLE |^TABLET|STAP|RETRACT|DEEP|ELECTRO|ROTAT|STAPL|CODE |ANTIBIOTIC|TROCAR'
and concept_name !~* 'triclosan|quetiapine|staphysagria|Snail secre|Quinidine|rivastigmine|RENA CODE|rurina|pramipexole|pineal|coccus|NICOTINE|tacrolimus|Divalproex|FESOTERODINE|eye|allantoin|mercaptopurine|levodopa|niaspan'
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
    where concept_name ~* 'SHUNT|ORTHOPED|PIECE|VALVE|EXTENTI|EXTEND|DRAINAGE|ABSCESS|URINA|URINE|ALYSIS|^TABLE |^TABLET|STAP|RETRACT|DEEP|ELECTRO|ROTAT|STAPL|CODE |ANTIBIOTIC|TROCAR'
and concept_name ~* 'triclosan|quetiapine|staphysagria|Snail secre|Quinidine|rivastigmine|RENA CODE|rurina|pramipexole|pineal|coccus|NICOTINE|tacrolimus|Divalproex|FESOTERODINE|eye|allantoin|mercaptopurine|levodopa|niaspan'
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--21
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
    where concept_name ~* '^NAIL |PUNCTURE| ELEC | SEP | GENE |ARRAN|GANG|SCREW|SPIN|GUIDE|VASCULAR|CONTROL'
and concept_name !~* 'hydroquinone|GINSENG|spinal|somatropin|SMOKE|PRUNUS SPINOSA|aluminum zirconium|nicotine|influenza|mushroom|allantoin|INTRASPINAL|biotin|COCA-GLYCERINE'
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
    where concept_name ~* '^NAIL |PUNCTURE| ELEC | SEP | GENE |ARRAN|GANG|SCREW|SPIN|GUIDE|VASCULAR|CONTROL'
and concept_name ~* 'hydroquinone|GINSENG|spinal|somatropin|SMOKE|PRUNUS SPINOSA|aluminum zirconium|nicotine|influenza|mushroom|allantoin|INTRASPINAL|biotin|COCA-GLYCERINE'
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--22
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
    where concept_name ~* 'CLIN |TARG|LEVEL|FACET|EPIDUR|BLOOD|TRAY|VERTEB'
and concept_name !~* 'Tolnaftate|Sulfacetamide|panthenol|Bacitraycin|bexarotene'
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
    where concept_name ~* 'CLIN |TARG|LEVEL|FACET|EPIDUR|BLOOD|TRAY|VERTEB'
and concept_name ~* 'Tolnaftate|Sulfacetamide|panthenol|Bacitraycin|bexarotene'
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--23
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
    where concept_name ~* 'TRIATH|ILLIARY|ADJUST|AUGMENTAT|CLOSE| CORD | ENDO |SIZE|FEMORA|FEED|BREAST|TIBIA|INSERT|GASTR|KNEE|ˆSSD|ˆSU|ˆTUBE| CTA |POST'
and concept_name !~* 'allantoin|breast care|candida|coxsackie|thymus|serotonin|Pentagastrin|thyro(x|id)'
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
    where concept_name ~* 'TRIATH|ILLIARY|ADJUST|AUGMENTAT|CLOSE| CORD | ENDO |SIZE|FEMORA|FEED|BREAST|TIBIA|INSERT|GASTR|KNEE|ˆSSD|ˆSU|ˆTUBE| CTA |POST'
and concept_name ~* 'allantoin|breast care|candida|coxsackie|thymus|serotonin|Pentagastrin|thyro(x|id)'
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--24
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
    where concept_name ~* 'MOBIL|ATTENT|OTHER|METABOL|CARRY|AORTIC|CMRM|DELIVER|HAND|CHANGE|SUPPLY|HEALI|SPINAL|CAPSTONE|SPACER'
and concept_name !~* 'triclosan|panthenol|alcohol|archangelica|antacid|ginseng'
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
    where concept_name ~* 'MOBIL|ATTENT|OTHER|METABOL|CARRY|AORTIC|CMRM|DELIVER|HAND|CHANGE|SUPPLY|HEALI|SPINAL|CAPSTONE|SPACER'
and concept_name ~* 'triclosan|panthenol|alcohol|archangelica|antacid|ginseng'
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--25
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
    where concept_name ~* 'ANES|ASSESS|LIFEST|CARDIO|ARREST|TEMPLATE|CEVALVE|AORTA|DETAIL'
and concept_name !~* 'capsaicin|CARDIOFORCE|aorta 6|cardiopress|Encephalitis'
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
    where concept_name ~* 'ANES|ASSESS|LIFEST|CARDIO|ARREST|TEMPLATE|CEVALVE|AORTA|DETAIL'
and concept_name ~* 'capsaicin|CARDIOFORCE|aorta 6|cardiopress|Encephalitis'
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--26
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
    where concept_name ~* 'COSMET|HIP |WRIST|CHEST|ˆUS |ARTH|DELIV|PORTAB|MAMM|REDUCE|SAMPL'
and concept_name !~* 'natural medicine liquid|toxicodendron|avocado|capsaicin|t relief|nicotine|hydroquinone|chestnut'
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
    where concept_name ~* 'COSMET|HIP |WRIST|CHEST|ˆUS |ARTH|DELIV|PORTAB|MAMM|REDUCE|SAMPL'
and concept_name ~* 'natural medicine liquid|toxicodendron|avocado|capsaicin|t relief|nicotine|hydroquinone|chestnut'
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--27
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
    where concept_name ~* 'MANAG|PAIN|DISEAS|DIAGN|DYAL|LIVER|WEEK|INJECTOR'
and concept_name !~* 'auto-injector|ketamine|trolamine|aloe vera|orajel|capsicum annuum|capsaicin|ginger|dexamethasone|povidone|MOSQUITO|coffee bean|musca domes|coxiflu|HEPATINUM|liver (boost|care|comp|tonic)|LV-FX|MEDTYCHOLL-B|OLEUM MORRHUAE'
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
    where concept_name ~* 'MANAG|PAIN|DISEAS|DIAGN|DYAL|LIVER|WEEK|INJECTOR'
and concept_name ~* 'auto-injector|ketamine|trolamine|aloe vera|orajel|capsicum annuum|capsaicin|ginger|dexamethasone|povidone|MOSQUITO|coffee bean|musca domes|coxiflu|HEPATINUM|liver (boost|care|comp|tonic)|LV-FX|MEDTYCHOLL-B|OLEUM MORRHUAE'
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--28
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
where concept_name ~* '^CAP|^INJ|LOCK|IMPLANT|CEMENT|FILLER|BONE|FAT |OIL |ˆCOIL|SYSTEM|STOOL|PHARMACY|TYPE'
and concept_name !~* ('triclosan|Undecylenic Acid|tioconazole|antacid|vaccine|myobloc|category|formula|cold remedy|nicotine|phenol|antigen|pramoxine|Simethicone|laxative|enema|egg yolk|female care|LICE|pancreas|' ||
                      'vitamin|capreomycinca|capsaicin|Capreomycin|capsicum|carboneum|canakinumab|goserelin|healthy bone|histrelin|osteobios|MEDULLOSSEINUM|polifeprosan')
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
where concept_name ~* '^CAP|^INJ|LOCK|IMPLANT|CEMENT|FILLER|BONE|FAT |OIL |ˆCOIL|SYSTEM|STOOL|PHARMACY|TYPE'
and concept_name ~* ('triclosan|Undecylenic Acid|tioconazole|antacid|vaccine|myobloc|category|formula|cold remedy|nicotine|phenol|antigen|pramoxine|Simethicone|laxative|enema|egg yolk|female care|LICE|pancreas|' ||
                      'vitamin|capreomycinca|capsaicin|Capreomycin|capsicum|carboneum|canakinumab|goserelin|healthy bone|histrelin|osteobios|MEDULLOSSEINUM|polifeprosan')
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--TODO: we exclude if just one component is a device. What if another component is a drug?
--i.e. Benoxinate 4 MG/ML / Sodium Fluorescein 2.5 MG/ML Ophthalmic Solution [Fluress]


--29
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
where concept_name ~*
      ('Ethiodol|ethiodized oil|Lipiodol|Lipiodol Ultra-Fluide|Cystografin|diatrizoate|Gastrografin|Gastrograffin|Hexabrix|' ||
       'ioxaglate|Hypaque|Hypaque|MD-76|MD-Gastroview|Reno-30|Reno-60|Reno-Dip|Renocal|Renografin|Sinografin|' ||
       'iodipamide|Lymphazurin|isosulfan blue|Omniscan|gadodiamide|Eovist|gadoxetate disodium|Dotarem|' ||
       'gadoterate meglumine|Gadavist|gadobutrol|Magnevist|gadopentetate dimeglumine|Ablavar|gadofosveset trisodium|' ||
       'Feridex|ferumoxides|GastroMARK|ferumoxsil|Multihance|Gadobenate Dimeglumine|OptiMARK|gadoversetamide|Prohance|gadoteridol|' ||
       'Teslascan|mangafodipir|Vasovist|AK-Fluor|fluorescein|Angioscein|Fluorescite|IC-Green|indocyanine green|IC GREEN|' ||
       'Spy Agent Green|barium sulfate|Readi-Cat|Volumen|Readi-Cat|Anatrast|Bar-Test|Baricon|Baro-Cat|Barobag|' ||
       'Barosperse|CheeTah|Digibar|E-Z-Cat|E-Z-Cat Dry|E-Z-HD|E-Z-Paque|E-Z Disk|E-Z Dose Kit|E-Z Paste|Entero VU|' ||
       'Entrobar|Entroease|Esobar|Esopho-Cat|Flo-Coat|HD 85|HD 200 Plus|Intropaste|Liquid E-Z Paque|Liquid Polibar|' ||
       'Maxibar|Polibar ACB|Polibar Plus|Prepcat|Scan C|SilQ Vanilla|Sitzmarks|Tagitol V|Tomocat|Tonopaque|Varibar|' ||
       'Visipaque (Pro)|iodixanol|Isovue-200|iopamidol|Isovue|iohexol|Omnipaque|Optiray|ioversol|Oraltag|' ||
       'Oxilan|ioxilan|Ultravist|iopromide|Definity|Optison|perflutren|paque|DEFINITY|' ||
       'filter|terumo|brace|adapt|bottl')
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--30
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
where concept_name ~* 'syringe|toner|meter|exten|tier(?!e)|paste|exten'
and concept_name !~* 'alumin(ium|um) zirconium|prefilled|havrix|ketamine|PENTOTHAL|SODIUM CITRATE|zolmitriptan|testosterone|salmeterol|mometazone|nafarelin|niacinamide|allantoin|vitamin|capsaicin|calcitonin|fluticasone|flunisolide|lidocane|melatonin'
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
where concept_name ~* 'syringe|toner|meter|exten|tier(?!e)|paste|exten'
and concept_name ~* 'alumin(ium|um) zirconium|prefilled|havrix|ketamine|PENTOTHAL|SODIUM CITRATE|zolmitriptan|testosterone|salmeterol|mometazone|nafarelin|niacinamide|allantoin|vitamin|capsaicin|calcitonin|fluticasone|flunisolide|lidocane|melatonin'
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--31
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
where concept_name ~* 'alanine|arginine|asparagine|aspartic acid|cysteine|glutamine|glutamic acid|glycine|histidine|isoleucine|leucine|lysine|methionine|phenylalanine|proline|serine|threonine|tryptophan|tyrosine|valine'
and concept_name !~* 'intravenous|injection|BIO VISCUM|e\.o\.l\.|neuro 3|rimantadine'
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
where concept_name ~* 'alanine|arginine|asparagine|aspartic acid|cysteine|glutamine|glutamic acid|glycine|histidine|isoleucine|leucine|lysine|methionine|phenylalanine|proline|serine|threonine|tryptophan|tyrosine|valine'
and concept_name ~* 'intravenous|injection|BIO VISCUM|e\.o\.l\.|neuro 3|rimantadine'
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--32
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
where concept_name ~* 'albumin|mouthwash|DRSS|tegaderm|diapers|isotope|technetium'
and concept_name !~* 'phenol|albuminuriaforce|THERAPEUTIC|tositumomab'
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
where concept_name ~* 'albumin|mouthwash|DRSS|tegaderm|diapers|isotope|technetium'
and concept_name ~* 'phenol|albuminuriaforce|THERAPEUTIC|tositumomab'
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;

--33
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
where concept_name ~* 'glycerin|glycerol|dimethicon'
and concept_name !~* ('Thermus Thermophilus|CARBOXYMETHYLCELLULOSE SODIUM|niacin|progesterone|hypromellose|phenol|INTRAVENOUS|diluent|' ||
    'allantoin|aluminum hydroxide|panthenol|CHEWABLE|vitamin|simethicone')
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
where concept_name ~* 'glycerin|glycerol|dimethicon'
and concept_name ~* ('Thermus Thermophilus|CARBOXYMETHYLCELLULOSE SODIUM|niacin|progesterone|hypromellose|phenol|INTRAVENOUS|diluent|' ||
    'allantoin|aluminum hydroxide|panthenol|CHEWABLE|vitamin|simethicone')
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;


--34
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
where concept_name ~* 'kit'
and concept_name !~* ('allantoin|first aid|skin care|remedy|cold|asthma|melphalan|latrodectus|aralast|eczema|aridol|bartonella|borrelia|Bismuth|cabozantinib|' ||
                     'cerliponase|CANDIDA ALBICANS|CARMUSTINE|ceretec|cetylpyridin|certolizumab|clopidogrel|cyanocobalamin|CYCLOPHEN|cyclo/gaba|' ||
                     'decitabine|mupirocin|tretinoin|dexamethasone|desirudin|dexrazoxane|dimethyl fumarate|panthenol|EPSTEIN-BARR|enterococcinum|' ||
                     'Aptiom|exametazime|exenatide|fluticasone|glucagon|Halobetasol|helicobacter|trastuzumab|somatropin|hydroquinone|hydroxocobalamin|' ||
                     'ibritumomab|influenza|romidepsin|abrot|cabazitaxel|kenalog|ketophene|lice|vincristine|Meningococcal|menotropins|sumatriptan|' ||
                     'mitomycin|nabumetone|Neisseria|nicotine|risperidone|Povidone|RABAVERT|REFILL 6|ribavirin|risperidone|rotavirus|varicella|pegvisomant|' ||
                     'sumatriptan|tenecteplase|thyrotropin|Tizanidine|temsirolimus|tositumomab|tolnaftate|Triclosan|triptorelin|cholera|vitamin|varenicline|' ||
                     'zoledronic|BODYANEW|antigen|traumeel|pleo|t-relief|paire')
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
where concept_name ~* 'kit'
and concept_name ~* ('allantoin|first aid|skin care|remedy|cold|asthma|melphalan|latrodectus|aralast|eczema|aridol|bartonella|borrelia|Bismuth|cabozantinib|' ||
                     'cerliponase|CANDIDA ALBICANS|CARMUSTINE|ceretec|cetylpyridin|certolizumab|clopidogrel|cyanocobalamin|CYCLOPHEN|cyclo/gaba|' ||
                     'decitabine|mupirocin|tretinoin|dexamethasone|desirudin|dexrazoxane|dimethyl fumarate|panthenol|EPSTEIN-BARR|enterococcinum|' ||
                     'Aptiom|exametazime|exenatide|fluticasone|glucagon|Halobetasol|helicobacter|trastuzumab|somatropin|hydroquinone|hydroxocobalamin|' ||
                     'ibritumomab|influenza|romidepsin|abrot|cabazitaxel|kenalog|ketophene|lice|vincristine|Meningococcal|menotropins|sumatriptan|' ||
                     'mitomycin|nabumetone|Neisseria|nicotine|risperidone|Povidone|RABAVERT|REFILL 6|ribavirin|risperidone|rotavirus|varicella|pegvisomant|' ||
                     'sumatriptan|tenecteplase|thyrotropin|Tizanidine|temsirolimus|tositumomab|tolnaftate|Triclosan|triptorelin|cholera|vitamin|varenicline|' ||
                     'zoledronic|BODYANEW|antigen|traumeel|pleo|t-relief|paire')
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;


--35
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
WHERE concept_name ~* 'set|BATTER|BUBBLE(gum| gum)|INTRODUCER|lanolin|petrolatum|tape|N95 RESPIRATOR|adenosine(?=.*(topical|cream))|wipe|cath|container|cntainr|thermo|sheath|auto(squeeze|drop)|sheet|camino|flav(or|our)|remover|adhesive|dispens'
and concept_name !~* 'treatment|treamtent|INFLUENZA|PENTAMIDINE|vitamin|alosetron|tapentadol|ertapenem|panthenol|tranexamic|antacid|bismuth|nicotine|chewable'
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
WHERE concept_name ~* 'set|BATTER|BUBBLE(gum| gum)|INTRODUCER|lanolin|petrolatum|tape|N95 RESPIRATOR|adenosine(?=.*(topical|cream))|wipe|cath|container|cntainr|thermo|sheath|auto(squeeze|drop)|sheet|camino|flav(or|our)|remover|adhesive|dispens'
and concept_name ~* 'treatment|treamtent|INFLUENZA|PENTAMIDINE|vitamin|alosetron|tapentadol|ertapenem|panthenol|tranexamic|antacid|bismuth|nicotine|chewable'
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;


--36
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
where concept_name ~* ('applicator|flange|flng|barrier|wrap|pedial|moistur|pregnancy|sponge|food color|collect|flexiflo|reservoir|resto|sock|ovulation|' ||
      '(biovol|cherry|rice|cola|orange|sweet oral|sweet sf|raspberry|simple|syrplata|toa) syrup|cleaner|curity|pad|swab')
and concept_name !~* 'alzair|atopaderm|allantoin|nonoxynol|triclosan|povidone|minoxidil|rosuvastatin|toremifene|pramoxine|Hydroquinone|zicam'
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
where concept_name ~* ('applicator|flange|flng|barrier|wrap|pedial|moistur|pregnancy|sponge|food color|collect|flexiflo|reservoir|resto|sock|ovulation|' ||
      '(biovol|cherry|rice|cola|orange|sweet oral|sweet sf|raspberry|simple|syrplata|toa) syrup|cleaner|curity|pad|swab')
and concept_name ~* 'alzair|atopaderm|allantoin|nonoxynol|triclosan|povidone|minoxidil|rosuvastatin|toremifene|pramoxine|Hydroquinone|zicam'
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;


--37
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
where concept_name ~* 'cream|creme'
and concept_name !~* ('menthol|allantoin|vitamin|dioscorea|fluocinonide|Halobetasol|Halcinonide|Hydroquinone|LULICONAZOLE|pimecrolimus|pharmax|' ||
                      'Progesterone|sulfadiazine|aluminum chlorohydrate|sulconazol|Terbinafin|terconazol|Testosterone|Tolnaftate|hormone|Tretinoin|' ||
                      'Trolamine|typhonium|sulfanilamide|triclosan|dimthicon')
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
where concept_name ~* 'cream|creme'
and concept_name ~* ('allantoin|vitamin|dioscorea|fluocinonide|Halobetasol|Halcinonide|Hydroquinone|LULICONAZOLE|pimecrolimus|pharmax|' ||
                      'Progesterone|sulfadiazine|aluminum chlorohydrate|sulconazol|Terbinafin|terconazol|Testosterone|Tolnaftate|hormone|Tretinoin|' ||
                      'Trolamine|typhonium|sulfanilamide|triclosan|dimthicon')
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;


--38
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
where concept_name ~* 'rinse|Monoject|COOLER'
;


DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;


--39
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
where concept_name ~* 'menthol'
and concept_name !~* 'capsaicin|calamin'
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
where concept_name ~* 'menthol'
and concept_name ~* 'capsaicin|calamin'
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;


--40
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
where concept_name ~* ('F(?=.*18)|Chrom(?=.*51)|Xe(?=.*133)|Iod(?=.*123)|I( 123|-123)|rubidium(?=.*82)|Thall(?=.*201)|' ||
      'Indium|in(?=.*111)|Iod(?=.*125)|I( 125|-125)|Cesium|Tc(?=.*99)|techn|ammonia N(?=.*13)|c-13|NH3')
and concept_name !~* ('INFLUENZ|cold|multiple|vitamin|cough|Ceftibuten|armodafinil|' ||
    'borax|triclosan|allantoin|vagina|zinc|carboplatin|doxor(u|i)b|Cladribine|vanco|dexametha|alumin|primaqui|sulfasalazine|Fludarabine|Desferrioxamine|ZEVALIN');
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
where concept_name ~* ('F(?=.*18)|Chrom(?=.*51)|Xe(?=.*133)|Iod(?=.*123)|I( 123|-123)|rubidium(?=.*82)|Thall(?=.*201)|' ||
      'Indium|in(?=.*111)|Iod(?=.*125)|I( 125|-125)|Cesium|Tc(?=.*99)|techn|ammonia N(?=.*13)|c-13|NH3')
and concept_name ~* ('INFLUENZ|cold|multiple|vitamin|cough|Ceftibuten|armodafinil|' ||
    'borax|triclosan|allantoin|vagina|zinc|carboplatin|doxor(u|i)b|Cladribine|vanco|dexametha|alumin|primaqui|sulfasalazine|Fludarabine|Desferrioxamine|ZEVALIN');
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;


--------------------------------------------------

--------------------------------------------------

select count (*)
from NDC_remains;

SELECT *
FROM NDC_remains
;


--Test for titan in drugs
SELECT *
FROM ndc_drugs
WHERE concept_name ~* 'titan|Octinoxate|Octisalate|oxybenzone|ensulizole|octocrylene|homosalate'
;

--Real test for titan in drugs
SELECT *
FROM ndc_drugs
WHERE concept_name ~* 'titan|Octinoxate|Octisalate|oxybenzone|ensulizole|octocrylene|homosalate'
and concept_name !~* 'hp_|homeo|pellet|Salicylic Acid|progesterone|hydroquinone|caffeine|IDEBENONE'
;

SELECT *
FROM ndc_remains
WHERE concept_name ~* 'titan|Octinoxate|Octisalate|oxybenzone|ensulizole|octocrylene|homosalate'
--and concept_name !~* 'niacinamide|hp_|homeo|pellet|Salicylic Acid|progesterone|hydroquinone|caffeine|IDEBENONE'
;

SELECT *
FROM ndc_non_drugs
WHERE concept_name ~* 'vitamin'
;


--Example
--Example
--Example
--Example
--Code for NON-DRUGS
INSERT INTO NDC_non_drugs
SELECT *
FROM NDC_remains
WHERE concept_name
;

--Code for DRUGS
INSERT INTO NDC_drugs
SELECT *
FROM NDC_remains
WHERE concept_name
;

DELETE FROM NDC_remains
WHERE concept_id in (select concept_id from NDC_drugs UNION ALL select concept_id from NDC_non_drugs)
;
--Example
--Example
--Example
--Example





--workshop
SELECT *
FROM NDC_remains
WHERE concept_name

EXCEPT

SELECT *
FROM NDC_remains
where concept_name ~* 'Albumin Human,'

ORDER BY concept_name
;

--Check in non_drugs
SELECT *
FROM ndc_non_drugs
where concept_name ~* 'F(?=.*18)|Chrom(?=.*51)|Xe(?=.*133)|Iod(?=.*123)|I( 123|-123)|rubidium(?=.*82)|Thall(?=.*201)'

;

--Check in drugs
SELECT *
FROM ndc_drugs
where concept_name ~* 'F(?=.*18)|Chrom(?=.*51)|Xe(?=.*133)|Iod(?=.*123)|I( 123|-123)|rubidium(?=.*82)|Thall(?=.*201)'

;

--Check in Source
SELECT concept_name
FROM NDC_source
WHERE concept_name ~* 'Hyoscyamine'
GROUP BY concept_name
;




--Check mask for potential drugs
with ingredients as (
SELECT DISTINCT concept_name, concept_id
FROM devv5.concept c
WHERE c.vocabulary_id = 'RxNorm' AND c.domain_id = 'Drug' AND c.concept_class_id = 'Ingredient' AND c.standard_concept = 'S'

),

drugs as (
SELECT DISTINCT concept_name
FROM NDC_remains
WHERE concept_name ~* 'titan|Octinoxate|Octisalate|oxybenzone|ensulizole|octocrylene|homosalate'
)

/*SELECT DISTINCT i.concept_name
FROM ingredients i
JOIN drugs d
    ON d.concept_name ilike '%' || i.concept_name || '%'
EXCEPT*/

SELECT DISTINCT i.concept_name
FROM ingredients i
JOIN drugs d
    ON d.concept_name ilike '%' || i.concept_name || '%'
    WHERE EXISTS
              (SELECT 1
              FROM devv5.concept_ancestor ca
                JOIN devv5.concept c
                  ON c.concept_id = ca.descendant_concept_id

              WHERE i.concept_id = ca.ancestor_concept_id
                AND c.domain_id = 'Drug' AND c.vocabulary_id = 'RxNorm' AND c.concept_class_id = 'Clinical Drug' AND c.standard_concept = 'S'
              GROUP BY ca.ancestor_concept_id
                HAVING COUNT(*) > 5
              )
;
