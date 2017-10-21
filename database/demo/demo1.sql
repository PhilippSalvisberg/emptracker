-- 5 Tweets
UPDATE emp SET sal = sal * 2;
ROLLBACK;
UPDATE emp SET sal = sal + 100 WHERE JOB = 'SALESMAN';
UPDATE emp SET sal = sal + 200 WHERE ename IN ('MARTIN' ,'SCOTT');
COMMIT;

-- 1 Tweet
UPDATE emp SET sal = sal - 10 WHERE ename = 'SCOTT';
UPDATE emp SET sal = sal - 20 WHERE ename = 'SCOTT';
UPDATE emp SET sal = sal - 30 WHERE ename = 'SCOTT';
UPDATE emp SET sal = sal - 40 WHERE ename = 'SCOTT';
COMMIT;
