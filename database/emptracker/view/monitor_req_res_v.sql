CREATE OR REPLACE VIEW monitor_req_res_v AS
SELECT req.corr_id,
       req.consumer_name AS request_consumer,
       res.consumer_name AS response_consumer,
       req.user_data.get_string_property('ename') AS ename,
       req.user_data.get_double_property('old_sal') AS old_sal,
       req.user_data.get_double_property('new_sal') AS new_sal,
       res.user_data.text_vc AS response_text,
       req.enq_timestamp AS request_timestamp,
       res.enq_timestamp - req.enq_timestamp AS response_time
  FROM aq$requests_qt req
  LEFT JOIN aq$responses_qt res
    ON req.corr_id = res.corr_id
       AND res.user_data.get_string_property('JMS_OracleConnectionID') IS NOT NULL
 ORDER BY req.enq_timestamp DESC, res.enq_timestamp DESC;
