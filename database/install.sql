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

SET DEFINE OFF
SET SCAN OFF
SET ECHO OFF
SET SERVEROUTPUT ON SIZE 1000000
SPOOL install.log

PROMPT ======================================================================
PROMPT This script installs Oracle database objects for emptracker.
PROMPT
PROMPT Connect to the target user (schema) of your choice.
PROMPT See user/emptracker.sql for required privileges.
PROMPT ======================================================================
PROMPT

PROMPT ======================================================================
PROMPT create request and response queue tables
PROMPT ======================================================================
PROMPT
@./emptracker/queue_table/requests_qt.sql
@./emptracker/queue_table/responses_qt.sql

PROMPT ======================================================================
PROMPT create request and response queues and enable enqueue/dequeue ops
PROMPT ======================================================================
PROMPT
@./emptracker/queue/requests_aq.sql
@./emptracker/queue/responses_aq.sql

PROMPT ======================================================================
PROMPT create PL/SQL callback procedure
PROMPT ======================================================================
PROMPT
@./emptracker/procedure/raw_enq_callback.sql

PROMPT ======================================================================
PROMPT create monitoring views
PROMPT ======================================================================
PROMPT
@./emptracker/view/monitor_requests_v.sql
@./emptracker/view/monitor_responses_v.sql
@./emptracker/view/monitor_req_res_v.sql

PROMPT ======================================================================
PROMPT create demo tables
PROMPT ======================================================================
PROMPT
@./emptracker/table/dept.sql
@./emptracker/table/emp.sql

PROMPT ======================================================================
PROMPT create trigger to enqueue sal changes
PROMPT ======================================================================
PROMPT
@./emptracker/trigger/emp_au_trg.sql



SPOOL OFF
