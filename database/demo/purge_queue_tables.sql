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
