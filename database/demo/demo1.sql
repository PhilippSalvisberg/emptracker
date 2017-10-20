SET ECHO ON TERMOUT ON SERVEROUTPUT ON SIZE 1000000 PAGESIZE 100 LINESIZE 250 FEEDBACK ON TIMING OFF

CREATE OR REPLACE PROCEDURE enqueue_callback(
   context  IN RAW,
   reginfo  IN SYS.AQ$_REG_INFO,
   descr    IN SYS.AQ$_DESCRIPTOR,
   payload  IN RAW,
   payloadl IN NUMBER
) IS
   l_jms_message     sys.aq$_jms_text_message;
   l_dequeue_options sys.dbms_aq.dequeue_options_t;
   l_enqueue_options sys.dbms_aq.enqueue_options_t;
   l_message_props   sys.dbms_aq.message_properties_t;
   l_msgid           RAW(16);
BEGIN
   l_dequeue_options.msgid         := descr.msg_id;
   l_dequeue_options.consumer_name := descr.consumer_name;
   dbms_aq.dequeue(
      queue_name         => descr.queue_name,
      dequeue_options    => l_dequeue_options,
      message_properties => l_message_props,
      payload            => l_jms_message,
      msgid              => l_msgid
   );
   IF l_jms_message IS NOT NULL THEN
      l_message_props.expiration := 1;
      l_jms_message.set_text(
         l_jms_message.get_string_property('ename') 
         || ' got a sal increase of $'
         || to_char(l_jms_message.get_double_property('new_sal') 
                  - l_jms_message.get_double_property('old_sal'))
      );
      dbms_aq.enqueue(
         queue_name         => l_jms_message.get_replyto().address,
         enqueue_options    => l_enqueue_options,
         message_properties => l_message_props,
         payload            => l_jms_message,
         msgid              => l_msgid
      );
      COMMIT;
   END IF;
END enqueue_callback;
/

BEGIN 
   dbms_aqadm.add_subscriber(
      queue_name => 'requests_aq', 
      subscriber => sys.aq$_agent('MORE_SAL', 'REQUESTS_AQ', 0),
      rule       => q'[tab.user_data.get_double_property('new_sal') > tab.user_data.get_double_property('old_sal')]'
   );
END;
/

BEGIN
   dbms_aqadm.add_subscriber(
      queue_name => 'responses_aq', 
      subscriber => sys.aq$_agent('ALL_RESPONSES', 'REQUESTS_AQ', 0)
   );
END;
/

BEGIN 
   dbms_aq.register(
      reg_list => sys.aq$_reg_info_list(
                     sys.aq$_reg_info(
                        'REQUESTS_AQ:MORE_SAL', 
                        DBMS_AQ.NAMESPACE_AQ, 
                        'plsql://enqueue_callback',
                        NULL
                     )
                  ), 
      reg_count => 1
   ); 
END;
/

UPDATE emp 
   SET sal = sal + 20 
 WHERE ename = 'SCOTT';
COMMIT;

SELECT * FROM monitor_requests_v
ORDER BY enq_timestamp desc;

SELECT * FROM monitor_responses_v 
ORDER BY request_timestamp desc;

