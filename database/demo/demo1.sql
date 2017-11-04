-- reinstall
@@../uninstall.sql
@@../install.sql

-- 5 Tweets
UPDATE emp SET sal = sal * 2;
ROLLBACK;
UPDATE emp SET sal = sal + 100 WHERE JOB = 'SALESMAN';
UPDATE emp SET sal = sal + 200 WHERE ename IN ('MARTIN' ,'SCOTT');
COMMIT;

-- Monitor queues
SELECT * FROM MONITOR_REQUESTS_V;
SELECT * FROM MONITOR_RESPONSES_V;
SELECT * FROM MONITOR_REQ_RES_V;

-- 0 Tweet
BEGIN
   UPDATE emp SET sal = sal - 10 WHERE ename = 'SCOTT';
   UPDATE emp SET sal = sal - 20 WHERE ename = 'SCOTT';
   UPDATE emp SET sal = sal - 30 WHERE ename = 'SCOTT';
   UPDATE emp SET sal = sal - 40 WHERE ename = 'SCOTT';
   FOR i IN 1..200 LOOP
      UPDATE emp SET sal = sal + 0.5 WHERE ename = 'SCOTT';
   END LOOP;
   COMMIT;
END;
/
