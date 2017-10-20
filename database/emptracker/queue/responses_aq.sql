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
