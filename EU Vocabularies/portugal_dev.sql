--portugal
--cdm devices
create table EU_Port_dev (code1 varchar,	NPDM1	varchar,
code2 varchar,	NPDM2	varchar,
code3	varchar, NPDM3	varchar,
code4	varchar, NPDM4 varchar,
code5 varchar,	NPDM5	varchar,
code6 varchar,	NPDM6	varchar,
code7	varchar, NPDM7	varchar,
code8	varchar, NPDM8 varchar);

select * from EU_Port_dev limit 10;
--54936
select 
count (distinct code1)  from EU_Port_dev ;
--58806
select 
count (distinct code2)   from EU_Port_dev;
--58480
select 
count (distinct code3)   from EU_Port_dev;
--57328
select 
count (distinct code4)   from EU_Port_dev;
--58048
select 
count (distinct code5)   from EU_Port_dev;
--51867
select 
count (distinct code6)   from EU_Port_dev;
--51986
select 
count (distinct code7)   from EU_Port_dev;
--19162
select 
count (distinct code8)   from EU_Port_dev;
;

select  code1 from EU_Port_dev 
union select code2  from EU_Port_dev
union select code3 from EU_Port_dev
union select code4 from EU_Port_dev
union select code5  from EU_Port_dev
union select code6  from EU_Port_dev
union select code7 from EU_Port_dev
union select code8 from EU_Port_dev;



select count (distinct code1) 
from EU_Port_dev 
union select count (distinct code2) from EU_Port_dev
union select count (distinct code3) from EU_Port_dev
union select count (distinct code4) from EU_Port_dev
union select count (distinct code5) from EU_Port_dev
union select count (distinct code6) from EU_Port_dev
union select count (distinct code7) from EU_Port_dev
union select count (distinct code8)from EU_Port_dev;

SELECT count(DISTINCT code)
FROM (
SELECT code1 as code 
FROM EU_Port_dev
UNION ALL
SELECT code2 as code
FROM EU_Port_dev
UNION ALL
SELECT code3 as code
FROM EU_Port_dev
UNION ALL
SELECT code4 as code
FROM EU_Port_dev
UNION ALL
SELECT code5 as code
FROM EU_Port_dev
UNION ALL
SELECT code6 as code
FROM EU_Port_dev
UNION ALL
SELECT code7 as code
FROM EU_Port_dev
UNION ALL
SELECT code8 as code
FROM EU_Port_dev) as a;
