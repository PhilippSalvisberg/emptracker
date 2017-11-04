/*
* Copyright 2017 Philipp Salvisberg <philipp.salvisberg@trivadis.com>
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

-- reinstall
@@../uninstall.sql
@@../install.sql

-- tweet
SELECT tweet('Hello World!') FROM DUAL;

-- monitor queues
SELECT * FROM monitor_requests_v order by enq_timestamp;
SELECT * FROM monitor_responses_v order by enq_timestamp;
SELECT * FROM monitor_req_res_v order by request_timestamp;

-- 5 tweets
UPDATE emp SET sal = sal * 2;
ROLLBACK;
UPDATE emp SET sal = sal + 100 WHERE JOB = 'SALESMAN';
UPDATE emp SET sal = sal + 200 WHERE ename IN ('MARTIN' ,'SCOTT');
COMMIT;

-- no tweet
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
