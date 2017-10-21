CREATE OR REPLACE VIEW monitor_responses_v AS
SELECT q.msgid AS msg_id,
       q.corrid AS corr_id,
       coalesce(s.name, h.name) AS consumer_name,
       CASE
          WHEN q.user_data.get_string_property('JMS_OracleConnectionID') IS NOT NULL THEN
             'Java'
          ELSE
             'PL/SQL'
       END AS origin,
       coalesce(q.user_data.get_string_property('msg_type'), 'INFO') AS msg_type,
       q.user_data.text_vc AS msg_text,
       q.enq_time AS enq_timestamp
  FROM responses_qt q
  JOIN aq$_responses_qt_h h
    ON h.msgid = q.msgid
  LEFT JOIN aq$_responses_qt_s s
    ON s.subscriber_id = h.subscriber#
 ORDER BY q.enq_time DESC;
