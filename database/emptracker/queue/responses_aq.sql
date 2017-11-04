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

-- create queue
BEGIN
   dbms_aqadm.create_queue (
      queue_name          => 'RESPONSES_AQ',
      queue_table         => 'RESPONSES_QT',
      max_retries         => 1,
      retry_delay         => 2, -- seconds
      retention_time      => 60*60*24*7 -- 1 week
   );
END;
/

-- start queue
BEGIN
   dbms_aqadm.start_queue(
      queue_name => 'RESPONSES_AQ',
      enqueue    => TRUE,
      dequeue    => TRUE
   );
END;
/

-- subscribe to all response messages (used for debug purposes only)
BEGIN
   dbms_aqadm.add_subscriber(
      queue_name => 'responses_aq',
      subscriber => sys.aq$_agent('ALL_RESPONSES', 'RESPONSES_AQ', 0)
   );
END;
/