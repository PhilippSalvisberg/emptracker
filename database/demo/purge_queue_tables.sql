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

DECLARE
   o_purge_options   sys.dbms_aqadm.aq$_purge_options_t;
BEGIN
   sys.dbms_aqadm.purge_queue_table(
      queue_table       => 'REQUESTS_QT',
      purge_condition   => NULL,
      purge_options     => o_purge_options
   );
   sys.dbms_aqadm.purge_queue_table(
      queue_table       => 'RESPONSES_QT',
      purge_condition   => NULL,
      purge_options     => o_purge_options
   );
END;
/
