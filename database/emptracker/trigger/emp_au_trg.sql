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
      l_message_props.expiration := 30; -- 30 seconds
      l_jms_message.set_replyto(sys.aq$_agent('ALL_RESPONSES', 'RESPONSES_AQ', 0));
      l_jms_message.set_string_property('ename', :old.ename);
      l_jms_message.set_double_property('old_sal', coalesce(:old.sal, 0));
      l_jms_message.set_double_property('new_sal', coalesce(:new.sal, 0));
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
   IF coalesce(:old.sal, 0) != coalesce(:new.sal, 0) THEN
      enqueue;
   END IF;
END;
/
