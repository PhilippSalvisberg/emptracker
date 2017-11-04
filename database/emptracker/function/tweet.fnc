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

CREATE OR REPLACE FUNCTION tweet(in_text IN VARCHAR2) RETURN VARCHAR2 IS
   PRAGMA AUTONOMOUS_TRANSACTION;
   co_timeout    CONSTANT INTEGER := 5;
   l_correlation VARCHAR2(128);
   --
   FUNCTION enqueue(in_text IN VARCHAR2) RETURN VARCHAR2 IS
      l_enqueue_options sys.dbms_aq.enqueue_options_t;
      l_message_props   sys.dbms_aq.message_properties_t;
      l_jms_message     sys.aq$_jms_text_message := sys.aq$_jms_text_message.construct;
      l_msgid           RAW(16);
   BEGIN
      l_jms_message.clear_properties();
      l_message_props.correlation := sys_guid;
      l_message_props.priority := 3;
      l_message_props.expiration := co_timeout;
      l_jms_message.set_replyto(sys.aq$_agent('ALL_RESPONSES', 'RESPONSES_AQ', 0));
      l_jms_message.set_string_property('msg_type', 'TWEET');
      l_jms_message.set_text(in_text);
      dbms_aq.enqueue(queue_name         => 'requests_aq',
                      enqueue_options    => l_enqueue_options,
                      message_properties => l_message_props,
                      payload            => l_jms_message,
                      msgid              => l_msgid);
      COMMIT;
      RETURN l_message_props.correlation;
   END enqueue;
   --
   FUNCTION dequeue(in_correlation IN VARCHAR2) RETURN VARCHAR2 IS
      l_jms_message     sys.aq$_jms_text_message;
      l_dequeue_options sys.dbms_aq.dequeue_options_t;
      l_message_props   sys.dbms_aq.message_properties_t;
      l_msgid           RAW(16);
      l_text            VARCHAR2(4000 BYTE);
      l_msg_type        VARCHAR2(20 BYTE);
      e_no_msg EXCEPTION;
      PRAGMA EXCEPTION_INIT(e_no_msg, -25228);
   BEGIN
      l_dequeue_options.consumer_name := 'ALL_RESPONSES';
      l_dequeue_options.navigation    := sys.dbms_aq.first_message;
      l_dequeue_options.wait          := co_timeout;
      l_dequeue_options.correlation   := in_correlation;
      BEGIN
         dbms_aq.dequeue(queue_name         => 'responses_aq',
                         dequeue_options    => l_dequeue_options,
                         message_properties => l_message_props,
                         payload            => l_jms_message,
                         msgid              => l_msgid);
         l_jms_message.get_text(l_text);
         l_msg_type := l_jms_message.get_string_property('msg_type');
         COMMIT;
         RETURN l_msg_type || ': ' || l_text;
      EXCEPTION
         WHEN e_no_msg THEN
            COMMIT;
            RETURN 'ERROR: no response message received within ' ||
               co_timeout || ' seconds.';
      END;
   END dequeue;
BEGIN
   l_correlation := enqueue(in_text => in_text);
   RETURN dequeue(in_correlation => l_correlation);
END tweet;
/
