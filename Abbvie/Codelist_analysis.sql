create table Abbvie_united_codelist
(
  code varchar(100),
  description varchar(500),
  vocab varchar(100),
  file_desc varchar(100)
);
--1883
select count(*) from Abbvie_united_codelist;

--1642
select count(distinct code) from Abbvie_united_codelist
where vocab = 'NDC';
--74
select count(distinct code) from Abbvie_united_codelist
where vocab = 'CPT-4';
--15
select count(distinct code) from Abbvie_united_codelist
where vocab = 'HCPCS';
--73
select count(distinct code) from Abbvie_united_codelist
where vocab = 'ICD-10';
--79
select count(distinct code) from Abbvie_united_codelist
where vocab = 'ICD-9';

--ICD-9
--32 of 79 perfect join
select code, description, vocab, file_desc,
       c.concept_id, c.concept_name, c.vocabulary_id from Abbvie_united_codelist ab
join devv5.concept c
         on c.concept_code = ab.code
             and c.concept_name = ab.description
            AND c.vocabulary_id in ('ICD9CM', 'ICD9Proc')
where ab.vocab = 'ICD-9';

--5 of 79 good join: source description is missing
select code, description, vocab, file_desc,
       c.concept_id, c.concept_name, c.vocabulary_id from Abbvie_united_codelist ab
join devv5.concept c
         on c.concept_code = ab.code
             and c.concept_name != ab.description
            AND c.vocabulary_id in ('ICD9CM', 'ICD9Proc')
where ab.vocab = 'ICD-9';

--42 of 79 WRONG CODES
select * from Abbvie_united_codelist
where code not in (
select code from Abbvie_united_codelist ab
join devv5.concept c
         on c.concept_code = ab.code
            AND c.vocabulary_id in ('ICD9CM', 'ICD9Proc')
where ab.vocab = 'ICD-9')
and vocab = 'ICD-9';


--ICD-10
--73 of 73 perfect join
select distinct code from Abbvie_united_codelist ab
join devv5.concept c
         on c.concept_code = ab.code
             and c.concept_name = ab.description
            AND c.vocabulary_id in ('ICD10', 'ICD10CM', 'ICD10PCS')
where ab.vocab = 'ICD-10';


--HCPCS
--15 of 15 perfect join
select distinct code from Abbvie_united_codelist ab
join devv5.concept c
         on c.concept_code = ab.code
             and c.concept_name = ab.description
            AND c.vocabulary_id in ('HCPCS')
where ab.vocab = 'HCPCS';


--CPT-4
--39 of 74 perfect join
select code, description, vocab, file_desc,
       c.concept_id, c.concept_name, c.vocabulary_id from Abbvie_united_codelist ab
join devv5.concept c
         on c.concept_code = ab.code
             and c.concept_name = ab.description
            AND c.vocabulary_id in ('CPT4')
where ab.vocab = 'CPT-4';

--16 of 74 good join: source description is missing or slightly modified (checked manually)
select code, description, vocab, file_desc,
       c.concept_id, c.concept_name, c.vocabulary_id from Abbvie_united_codelist ab
join devv5.concept c
         on c.concept_code = ab.code
             and c.concept_name != ab.description
            AND c.vocabulary_id in ('CPT4')
where ab.vocab = 'CPT-4';

--19 of 74: WRONG CODES
--Manually checked: ICD-9 proc codes
select * from Abbvie_united_codelist
where code not in (
select code from Abbvie_united_codelist ab
join devv5.concept c
         on c.concept_code = ab.code
            AND c.vocabulary_id in ('CPT4')
where ab.vocab = 'CPT-4')
and vocab = 'CPT-4';


--NDC
--1298 of 1642 good join
select code, description, vocab, file_desc,
       c.concept_id, c.concept_name, c.vocabulary_id from Abbvie_united_codelist ab
join devv5.concept c
         on c.concept_code = ab.code
            AND c.vocabulary_id in ('NDC')
where ab.vocab = 'NDC';

--344 of 1642: WRONG CODES
select * from Abbvie_united_codelist
where code not in (
select code from Abbvie_united_codelist ab
join devv5.concept c
         on c.concept_code = ab.code
            AND c.vocabulary_id in ('NDC')
where ab.vocab = 'NDC')
and vocab = 'NDC';





--WS-Elagolix: WS-UF-related Hysterectomy codes ICD9 codes [ICD-9]
--ADD:
--68.71	Laparoscopic radical vaginal hysterectomy [LRVH]

--WS-Elagolix: WS-UF-related Myomectomy codes CPT4 codes [CPT-4]
--ADD:
--45108	Anorectal myomectomy

--WS-Elagolix: WS-UF-related Myomectomy codes ICD9 codes [ICD-9]
--ADD:
--48.92	Anorectal myectomy

--WS-Elagolix: WS-UF-related Ultrasound codes CPT4 codes [CPT-4]
--ADD:
--0404T	Transcervical uterine fibroid(s) ablation with ultrasound guidance, radiofrequency
--58674	Laparoscopy, surgical, ablation of uterine fibroid(s) including intraoperative ultrasound guidance and monitoring, radiofrequency
--0336T	Laparoscopy, surgical, ablation of uterine fibroid(s), including intraoperative ultrasound guidance and monitoring, radiofrequency
--1014458	Focused ultrasound ablation of uterine leiomyomata, including MR guidance

--WS-Elagolix: WS-UF-related nonsteroidal anti inflammatory RX HCPCS codes [HCPCS]
--THERE ARE A LOT OF NSAID, actually. Source table contains only one NSAID

--WS-Elagolix: uterine fibroids UF ICD9 codes [ICD-9]
--ADD:
--218	Uterine leiomyoma (parent of included concept)
