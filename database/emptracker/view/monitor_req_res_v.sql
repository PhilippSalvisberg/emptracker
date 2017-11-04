/*
* Copyright 2017 Philipp Salvisberg <philipp.salvisberg@trivadis.com>
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

CREATE OR REPLACE VIEW monitor_req_res_v AS
SELECT req.corr_id,
       to_number(req.enq_txn_id) AS enq_tid,
       req.consumer_name AS request_consumer,
       res.consumer_name AS response_consumer,
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
       AND res.user_data.get_string_property('JMS_OracleConnectionID') IS NOT NULL
 ORDER BY req.enq_timestamp DESC, res.enq_timestamp DESC;
