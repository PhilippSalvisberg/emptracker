-- create queue
BEGIN
   dbms_aqadm.create_queue (
      queue_name          => 'RESPONSES_AQ',
      queue_table         => 'RESPONSES_QT',
      max_retries         => 1,
      retry_delay         => 5, -- seconds
      retention_time      => 60*60*24*7 -- 1 week
   );
END;
/

-- start queue
BEGIN
   dbms_aqadm.start_queue(
      queue_name => 'RESPONSES_AQ',
      enqueue    => TRUE,
      dequeue    => TRUE
   );
END;
/

-- subscribe to all response messages (used for debug purposes only)
BEGIN
   dbms_aqadm.add_subscriber(
      queue_name => 'responses_aq',
      subscriber => sys.aq$_agent('ALL_RESPONSES', 'RESPONSES_AQ', 0)
   );
END;
/