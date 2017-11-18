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

CREATE OR REPLACE PROCEDURE raw_enq_callback(
   context  IN RAW,
   reginfo  IN SYS.AQ$_REG_INFO,
   descr    IN SYS.AQ$_DESCRIPTOR,
   payload  IN RAW,
   payloadl IN NUMBER
) IS
   l_msg_count       PLS_INTEGER;
   l_jms_message     sys.aq$_jms_text_message;
   t_jms_message     sys.aq$_jms_text_messages;
   l_dequeue_options sys.dbms_aq.dequeue_options_t;
   l_enqueue_options sys.dbms_aq.enqueue_options_t;
   l_message_props   sys.dbms_aq.message_properties_t;
   t_message_props   sys.dbms_aq.message_properties_array_t;
   l_msgid           RAW(16);
   t_msgid           sys.dbms_aq.msgid_array_t;
   l_aggr_count      INTEGER := 0;
   --
   PROCEDURE log_it(
      in_text     IN VARCHAR2,
      in_msg_type IN VARCHAR2 := 'INFO'
   ) IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
       l_jms_message := sys.aq$_jms_text_message.construct;
       l_jms_message.set_string_property('msg_type', in_msg_type);
       l_message_props.expiration := 1;
       l_message_props.correlation := NULL;
       l_jms_message.set_text(in_text);
       dbms_aq.enqueue(
          queue_name         => 'responses_aq',
          enqueue_options    => l_enqueue_options,
          message_properties => l_message_props,
          payload            => l_jms_message,
          msgid              => l_msgid
       );
       COMMIT;
   END log_it;
   --
   PROCEDURE enqueue_aggr(
     in_index   INTEGER,
     in_ename   VARCHAR,
     in_old_sal NUMBER,
     in_new_sal NUMBER
   ) IS
      e_no_recipients EXCEPTION;
      PRAGMA exception_init(e_no_recipients, -24033);
   BEGIN
      l_jms_message := sys.aq$_jms_text_message.construct;
      l_jms_message.set_replyto(t_jms_message(in_index).get_replyto);
      l_jms_message.set_string_property('msg_type', 'AGGR');
      l_jms_message.set_string_property('ename', in_ename);
      l_jms_message.set_double_property('old_sal', in_old_sal);
      l_jms_message.set_double_property('new_sal', in_new_sal);
      l_message_props.expiration := t_message_props(in_index).expiration;
      l_message_props.correlation := t_message_props(in_index).correlation;
      dbms_aq.enqueue(
         queue_name         => descr.queue_name,
         enqueue_options    => l_enqueue_options,
         message_properties => l_message_props,
         payload            => l_jms_message,
         msgid              => l_msgid
      );
      l_aggr_count := l_aggr_count + 1;
   EXCEPTION
      WHEN e_no_recipients THEN
         log_it(
            in_text     => 'AGGR topic is not of interest.' ||
                           ' ename: ' || l_jms_message.get_string_property('ename') ||
                           ' old_sal: ' || l_jms_message.get_double_property('old_sal') ||
                           ' new_sal: ' || l_jms_message.get_double_property('new_sal'),
            in_msg_type => 'WARNING'
         );
   END enqueue_aggr;
   --
   PROCEDURE dequeue_all IS
      e_no_msg          EXCEPTION;
      PRAGMA EXCEPTION_INIT(e_no_msg, -25228);
   BEGIN
      -- callback called for each message in a group
      -- one call will process all messages of a group
      -- group is limited to 1000 messages, this should be enough
      -- very large groups will be processed independently and
      -- may lead to additional notifications
      l_dequeue_options.consumer_name := descr.consumer_name;
      l_dequeue_options.navigation    := sys.dbms_aq.first_message_one_group;
      l_dequeue_options.wait          := sys.dbms_aq.no_wait;
      l_msg_count := dbms_aq.dequeue_array(
         queue_name               => descr.queue_name,
         dequeue_options          => l_dequeue_options,
         array_size               => 1000,
         message_properties_array => t_message_props,
         payload_array            => t_jms_message,
         msgid_array              => t_msgid
      );
      log_it(
         'dequeued ' || l_msg_count || ' RAW messages triggered by msg_id ' ||
         descr.msg_id || ' in transaction ' ||
         ltrim(t_message_props(1).transaction_group)
      );
   EXCEPTION
      WHEN e_no_msg THEN
         -- dequeue is triggered for every msg_id, hence this exception is expected and ignored
         NULL;
   END dequeue_all;
   --
   PROCEDURE copy_id_to_jms_messages IS
   BEGIN
      FOR i IN 1..l_msg_count LOOP
         t_jms_message(i).set_int_property('id', i);
      END LOOP copy_id;
   END copy_id_to_jms_messages;
   --
   PROCEDURE enqueue_aggr_messages IS
   BEGIN
      <<aggr>>
      FOR r IN (
         WITH
            msg AS (
               SELECT m.get_int_property('id') AS id,
                      m.get_string_property('ename') AS ename,
                      m.get_double_property('old_sal') AS old_sal,
                      m.get_double_property('new_sal') AS new_sal
                 FROM TABLE(t_jms_message) m
            ),
            base AS (
               SELECT MAX(id) OVER(PARTITION BY ename) AS id,
                      ename,
                      FIRST_VALUE(old_sal) OVER(PARTITION BY ename ORDER BY id) AS old_sal,
                      LAST_VALUE(new_sal) OVER(PARTITION BY ename ORDER BY id
                         ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS new_sal
                 FROM msg
            )
            SELECT DISTINCT id, ename, old_sal, new_sal
              FROM base
             WHERE old_sal != new_sal
      ) LOOP
         enqueue_aggr(
            in_index => r.id,
            in_ename => r.ename,
            in_old_sal => r.old_sal,
            in_new_sal => r.new_sal
         );
      END LOOP aggr;
      log_it('enqueued ' || l_aggr_count || ' AGGR messages triggered by msg_id ' ||
         descr.msg_id || ' in transaction ' ||
         ltrim(t_message_props(1).transaction_group)
      );
   END enqueue_aggr_messages;
BEGIN
   dequeue_all;
   copy_id_to_jms_messages;
   enqueue_aggr_messages;
EXCEPTION
   WHEN OTHERS then
      log_it(
         in_text     => 'Got the following error while processing msg_id ' ||
                        descr.msg_id || ' in transaction ' ||
                        ltrim(t_message_props(1).transaction_group) ||
                        ': ' || SQLERRM,
         in_msg_type => 'ERROR'
      );
END raw_enq_callback;
/
