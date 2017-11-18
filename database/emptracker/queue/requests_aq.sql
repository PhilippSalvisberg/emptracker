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
      queue_name          => 'REQUESTS_AQ',
      queue_table         => 'REQUESTS_QT',
      max_retries         => 1,
      retry_delay         => 2, -- seconds
      retention_time      => 60*60*24*7 -- 1 week
   );
END;
/

-- start queue
BEGIN
   dbms_aqadm.start_queue(
      queue_name => 'REQUESTS_AQ',
      enqueue    => TRUE,
      dequeue    => TRUE
   );
END;
/

-- subscribe to all raw messages (not aggregated messages)
BEGIN
   dbms_aqadm.add_subscriber(
      queue_name => 'requests_aq',
      subscriber => sys.aq$_agent('RAW_ENQ', 'REQUESTS_AQ', 0),
      rule       => q'[tab.user_data.get_string_property('msg_type') = 'RAW']'
   );
END;
/

-- register PL/SQL callback procedure to aggregate messages
BEGIN
   dbms_aq.register(
      reg_list => sys.aq$_reg_info_list(
                     sys.aq$_reg_info(
                        name      => 'REQUESTS_AQ:RAW_ENQ',
                        namespace => DBMS_AQ.NAMESPACE_AQ,
                        callback  => 'plsql://raw_enq_callback?PR=0',
                        context   => NULL
                     )
                  ),
      reg_count => 1
   );
END;
/
