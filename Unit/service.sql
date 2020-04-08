--check active queries
SELECT *
FROM pg_stat_activity
--WHERE pid = 123
WHERE state = 'active';











