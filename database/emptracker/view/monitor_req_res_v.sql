CREATE OR REPLACE VIEW monitor_req_res_v AS
SELECT req.corr_id,
       res.msg_state AS response_state,
       res.retry_count AS response_retry_count,
       res.consumer_name AS to_consumer,
       req.consumer_name AS from_consumer,
       req.user_data.get_string_property('ename') AS ename,
       req.user_data.get_double_property('old_sal') AS old_sal,
       req.user_data.get_double_property('new_sal') AS new_sal,
       req.user_data.text_vc AS request_text,
       res.user_data.text_vc AS response_text,
       req.enq_timestamp AS request_timestamp,
       res.enq_timestamp - req.enq_timestamp AS response_time
  FROM aq$requests_qt req
  LEFT JOIN aq$responses_qt res
    ON req.corr_id = res.corr_id
 WHERE req.user_data.get_string_property('msg_type') = 'AGGR'
 ORDER BY req.enq_time DESC;
