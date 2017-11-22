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

CREATE OR REPLACE TRIGGER emp_au_trg
   AFTER UPDATE OF sal ON emp
   FOR EACH ROW
DECLARE
   PROCEDURE enqueue IS
      l_enqueue_options sys.dbms_aq.enqueue_options_t;
      l_message_props   sys.dbms_aq.message_properties_t;
      l_jms_message     sys.aq$_jms_text_message := sys.aq$_jms_text_message.construct;
      l_msgid           RAW(16);
      e_no_recipients   EXCEPTION;
      PRAGMA exception_init(e_no_recipients, -24033);
   BEGIN
      l_jms_message.clear_properties();
      l_message_props.correlation := sys_guid;
      l_message_props.priority := 3;
      l_message_props.expiration := 300; -- 5 minutes
      l_jms_message.set_replyto(sys.aq$_agent('ALL_RESPONSES', 'RESPONSES_AQ', 0));
      l_jms_message.set_string_property('msg_type', 'RAW');
      l_jms_message.set_string_property('ename', :old.ename);
      l_jms_message.set_double_property('old_sal', :old.sal);
      l_jms_message.set_double_property('new_sal', :new.sal);
      sys.dbms_aq.enqueue(
         queue_name         => 'requests_aq',
         enqueue_options    => l_enqueue_options,
         message_properties => l_message_props,
         payload            => l_jms_message,
         msgid              => l_msgid
      );
   EXCEPTION
      WHEN e_no_recipients THEN
         NULL; -- OK, topic is not of interest
   END enqueue;
BEGIN
   IF :old.sal != :new.sal THEN
      enqueue;
   END IF;
END;
/
