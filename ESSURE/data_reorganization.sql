--OpenClaims dataset

CREATE TABLE essure_results_open
(
	analysisId integer,
  targetId integer,
  comparatorId integer,
  outcomeId integer,
  outcomeName varchar(254),
  timeatrisk integer,
  rr varchar(254),
  ci95lb varchar(254),
  ci95ub varchar(254),
  p varchar(254),
  target integer,
  comparator integer,
  targetDays varchar(254),
  comparatorDays varchar(254),
  eventsTarget varchar(254),
  eventsComparator integer,
  IRtarget float,
  IRcomparator float,
  logRr varchar(254),
  seLogRr varchar(254),
  calibratedP varchar(254),
  calibratedP_lb95ci varchar(254),
  calibratedP_ub95ci varchar(254),
  null_mean varchar(254),
  null_sd varchar(254)
  );

UPDATE essure_results_open
SET timeatrisk = 3
    WHERE analysisId = 1;
UPDATE essure_results_open
SET timeatrisk = 6
    WHERE analysisId = 2;
UPDATE essure_results_open
SET timeatrisk = 12
    WHERE analysisId = 3;
UPDATE essure_results_open
SET timeatrisk = 24
    WHERE analysisId = 4;
UPDATE essure_results_open
SET timeatrisk = 36
    WHERE analysisId = 5;
UPDATE essure_results_open
SET timeatrisk = 48
    WHERE analysisId = 6;
UPDATE essure_results_open
SET timeatrisk = 60
    WHERE analysisId = 7;
    
UPDATE essure_results_open
SET outcomeName = 'Need for subsequent surgery'
    WHERE outcomeId = 321;
UPDATE essure_results_open
SET outcomeName = 'Chronic pain'
    WHERE outcomeId = 468;
UPDATE essure_results_open
SET outcomeName = 'Repeated Sterilization'
    WHERE outcomeId = 476;
UPDATE essure_results_open
SET outcomeName = 'Depression'
    WHERE outcomeId = 478;
UPDATE essure_results_open
SET outcomeName = 'Abnormal uterine bleeding'
    WHERE outcomeId = 479;
UPDATE essure_results_open
SET outcomeName = 'Opioid administrations'
    WHERE outcomeId = 480;
UPDATE essure_results_open
SET outcomeName = 'FDA approved antidepressants administrations'
    WHERE outcomeId = 489;
UPDATE essure_results_open
SET outcomeName = 'Any antidepressant administrations'
    WHERE outcomeId = 490;
UPDATE essure_results_open
SET outcomeName = 'Pregnancy'
    WHERE outcomeId = 999;
UPDATE essure_results_open
SET outcomeName = ''
    WHERE outcomeId not in (321, 468, 476, 478, 479, 480, 489, 490, 999);

--IRtarget and IRcomparator calculations
UPDATE essure_results_open
SET IRtarget = (cast(eventsTarget as float)/target)*100;
UPDATE essure_results_open
SET IRcomparator = (cast(eventsComparator as float)/comparator)*100;

--These statements return data in user-friendly way to import data in Google sheets document
SELECT * FROM essure_results_open
where targetId = 3200 and comparatorId = 3180
order by outcomeId, analysisId;

SELECT * FROM essure_results_open
where targetId = 3200 and comparatorId = 3190
order by outcomeId, analysisId;

--Returns data in R friendly way to build graphs after it
--Insert output into corresponding fields in R code to build graphs faster
--1st chart with IR
with sorted_results as (select * from essure_results_open
                        where targetId = 3200 and comparatorId = 3180
and outcomeId = 321 order by analysisId)

SELECT targetId,
       string_agg(cast(round(cast(IRtarget as numeric), 2) as varchar), ', ') as IRtarget,
       comparatorId,
       string_agg(cast(round(cast(IRcomparator as numeric), 2) as varchar), ', ') as IRcomparator,
       outcomeName
FROM sorted_results
group by targetId, comparatorId, outcomeName;

--Check if the previous code returns right data
SELECT analysisId,
       targetId,
       IRtarget,
       comparatorId,
       IRcomparator
FROM essure_results_open
where targetId = 3200 and comparatorId = 3180
and outcomeId = 321
order by analysisId;

--Returns data in R friendly way to build graphs after it
--Insert output into corresponding fields in R code to build graphs faster
--2nd chart with RR
with sorted_results as (select * from essure_results_open
                        where targetId = 3200 and comparatorId = 3180
and outcomeId = 321 order by analysisId)

SELECT targetId,
       string_agg(cast(round(cast(rr as numeric), 2) as varchar), ', ') as RR,
       comparatorId,
       string_agg(cast(round(cast(ci95lb as numeric), 2) as varchar), ', ') as CIlow,
       string_agg(cast(round(cast(ci95ub as numeric), 2) as varchar), ', ') as CIup,
       outcomeName
FROM sorted_results
group by targetId, comparatorId, outcomeName;

--PharMetrix Plus dataset

CREATE TABLE Essure_results_pharm
(
	analysisId integer,
  targetId integer,
  comparatorId integer,
  outcomeId integer,
  rr varchar(254),
  ci95lb varchar(254),
  ci95ub varchar(254),
  p varchar(254),
  target integer,
  comparator integer,
  targetDays varchar(254),
  comparatorDays varchar(254),
  eventsTarget varchar(254),
  eventsComparator integer,
  logRr varchar(254),
  seLogRr varchar(254),
  calibratedP varchar(254),
  calibratedP_lb95ci varchar(254),
  calibratedP_ub95ci varchar(254),
  null_mean varchar(254),
  null_sd varchar(254)
);

ALTER TABLE Essure_results_pharm
    ADD COLUMN outcomeName varchar(254),
    ADD COLUMN timeatrisk integer,
    ADD COLUMN IRtarget float,
    ADD COLUMN IRcomparator float;
    
UPDATE Essure_results_pharm
SET timeatrisk = 3
    WHERE analysisId = 1;
UPDATE Essure_results_pharm
SET timeatrisk = 6
    WHERE analysisId = 2;
UPDATE Essure_results_pharm
SET timeatrisk = 12
    WHERE analysisId = 3;
UPDATE Essure_results_pharm
SET timeatrisk = 24
    WHERE analysisId = 4;
UPDATE Essure_results_pharm
SET timeatrisk = 36
    WHERE analysisId = 5;
UPDATE Essure_results_pharm
SET timeatrisk = 48
    WHERE analysisId = 6;
UPDATE Essure_results_pharm
SET timeatrisk = 60
    WHERE analysisId = 7;

UPDATE Essure_results_pharm
SET outcomeName = 'Need for subsequent surgery'
    WHERE outcomeId = 321;
UPDATE Essure_results_pharm
SET outcomeName = 'Chronic pain'
    WHERE outcomeId = 468;
UPDATE Essure_results_pharm
SET outcomeName = 'Repeated Sterilization'
    WHERE outcomeId = 476;
UPDATE Essure_results_pharm
SET outcomeName = 'Depression'
    WHERE outcomeId = 478;
UPDATE Essure_results_pharm
SET outcomeName = 'Abnormal uterine bleeding'
    WHERE outcomeId = 479;
UPDATE Essure_results_pharm
SET outcomeName = 'Opioid administrations'
    WHERE outcomeId = 480;
UPDATE Essure_results_pharm
SET outcomeName = 'FDA approved antidepressants administrations'
    WHERE outcomeId = 489;
UPDATE Essure_results_pharm
SET outcomeName = 'Any antidepressant administrations'
    WHERE outcomeId = 490;
UPDATE Essure_results_pharm
SET outcomeName = 'Pregnancy'
    WHERE outcomeId = 999;
UPDATE Essure_results_pharm
SET outcomeName = ''
    WHERE outcomeId not in (321, 468, 476, 478, 479, 480, 489, 490, 999);

UPDATE Essure_results_pharm
SET IRtarget = (cast(eventsTarget as float)/target)*100;
UPDATE Essure_results_pharm
SET IRcomparator = (cast(eventsComparator as float)/comparator)*100;

SELECT * FROM Essure_results_pharm
where targetId = 3200 and comparatorId = 3180
order by outcomeId, analysisId;

SELECT * FROM Essure_results_pharm
where targetId = 3200 and comparatorId = 3190
order by outcomeId, analysisId;

--1st chart with IR
with sorted_results as (select * from Essure_results_pharm
                        where targetId = 3200 and comparatorId = 3190
and outcomeId = 999 order by analysisId)

SELECT targetId,
       string_agg(cast(round(cast(IRtarget as numeric), 2) as varchar), ', ') as IRtarget,
       comparatorId,
       string_agg(cast(round(cast(IRcomparator as numeric), 2) as varchar), ', ') as IRcomparator,
       outcomeName
FROM sorted_results
group by targetId, comparatorId, outcomeName;

--2nd chart with RR
with sorted_results as (select * from Essure_results_pharm
                        where targetId = 3200 and comparatorId = 3190
and outcomeId = 999 order by analysisId)

SELECT targetId,
       string_agg(cast(round(cast(rr as numeric), 2) as varchar), ', ') as RR,
       comparatorId,
       string_agg(cast(round(cast(ci95lb as numeric), 2) as varchar), ', ') as CIlow,
       string_agg(cast(round(cast(ci95ub as numeric), 2) as varchar), ', ') as CIup,
       outcomeName
FROM sorted_results
group by targetId, comparatorId, outcomeName;
