CREATE OR REPLACE PROCEDURE raw_enq_callback(
   context  IN RAW,
   reginfo  IN SYS.AQ$_REG_INFO,
   descr    IN SYS.AQ$_DESCRIPTOR,
   payload  IN RAW,
   payloadl IN NUMBER
) IS
   co_max_array_size CONSTANT PLS_INTEGER := 20000000; -- 2147483647;
   l_msg_count       PLS_INTEGER;
   l_jms_message     sys.aq$_jms_text_message;
   t_jms_message     sys.aq$_jms_text_messages;
   l_dequeue_options sys.dbms_aq.dequeue_options_t;
   l_enqueue_options sys.dbms_aq.enqueue_options_t;
   l_message_props   sys.dbms_aq.message_properties_t;
   t_message_props   sys.dbms_aq.message_properties_array_t;
   l_msgid           RAW(16);
   t_msgid           sys.dbms_aq.msgid_array_t;
   e_no_msg          EXCEPTION;
   PRAGMA EXCEPTION_INIT(e_no_msg, -25228);
   --
   PROCEDURE log_it(in_text VARCHAR2) IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
       l_jms_message := sys.aq$_jms_text_message.construct;
       l_message_props.expiration := 1;
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
BEGIN
   -- callback called for each message in a group
   -- one call will process all messages of a group
   l_dequeue_options.consumer_name := descr.consumer_name;
   l_dequeue_options.navigation    := sys.dbms_aq.first_message_one_group;
   l_dequeue_options.wait          := sys.dbms_aq.no_wait;
   l_msg_count := dbms_aq.dequeue_array(
      queue_name               => descr.queue_name,
      dequeue_options          => l_dequeue_options,
      array_size               => co_max_array_size,
      message_properties_array => t_message_props,
      payload_array            => t_jms_message,
      msgid_array              => t_msgid
   );
   log_it(
      'dequeued ' || l_msg_count || ' messages triggered by msg_id ' || 
      descr.msg_id || ' in transaction ' || 
      ltrim(t_message_props(1).transaction_group)
   );
   COMMIT;
EXCEPTION
   WHEN e_no_msg THEN
      log_it('dequeued 0 messages triggered by msg_id ' || descr.msg_id);
END raw_enq_callback;
/
