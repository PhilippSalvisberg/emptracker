BEGIN
   dbms_aqadm.create_queue_table (
      queue_table          => 'RESPONSES_QT',
      queue_payload_type   => 'SYS.AQ$_JMS_TEXT_MESSAGE',
      sort_list            => 'PRIORITY,ENQ_TIME',
      multiple_consumers   => TRUE
   );
END;
/
