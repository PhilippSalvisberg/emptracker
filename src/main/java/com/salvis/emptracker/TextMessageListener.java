package com.salvis.emptracker;

import java.sql.SQLException;

import javax.annotation.PostConstruct;
import javax.annotation.PreDestroy;
import javax.jms.JMSException;
import javax.jms.Session;
import javax.jms.TextMessage;
import javax.jms.Topic;
import javax.jms.TopicSession;

import org.apache.log4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jms.listener.SessionAwareMessageListener;
import org.springframework.stereotype.Component;

import oracle.jms.AQjmsAgent;
import oracle.jms.AQjmsTopicPublisher;
import twitter4j.Status;
import twitter4j.Twitter;

@Component
public class TextMessageListener implements SessionAwareMessageListener<TextMessage> {
	private final Logger logger = Logger.getLogger(TextMessageListener.class.getName());

	@Autowired
	private Twitter twitter;

	@Value("${msg.salaryIncreaseTemplate}")
	private String salaryIncreaseTemplate;

	@Value("${msg.salaryDecreaseTemplate}")
	private String salaryDecreaseTemplate;
	
	private String getText(String ename, Double oldSal, Double newSal) {
		String template;
		if (newSal > oldSal) {
			Double more = newSal - oldSal;
			template = salaryIncreaseTemplate.replace("@{more}", String.format("%.2f", more));
		} else {
			Double less = oldSal - newSal;
			template = salaryDecreaseTemplate.replace("@{less}", String.format("%.2f", less));
		}
		return template.replace("@{ename}", ename.substring(0, 1) + ename.substring(1).toLowerCase())
				.replace("@{new_sal}", String.format("%.2f", newSal))
				.replace("@{old_sal}", String.format("%.2f", oldSal));
	}

	private void sendResponse(final TextMessage request, final Session session, String text) throws JMSException, SQLException {
		// prepare "empty" response
		TextMessage response = null;
		AQjmsAgent replyTo = (AQjmsAgent) request.getJMSReplyTo();
		if (replyTo != null) {
			String correlationId = request.getJMSCorrelationID();
			response = session.createTextMessage();
			response.setJMSCorrelationID(correlationId);
			response.setText(text);
			// create a publisher using the current database session (connection)
			Topic topic = session.createTopic(replyTo.getAddress());
			AQjmsTopicPublisher publisher = (AQjmsTopicPublisher) ((TopicSession) session).createPublisher(topic);
			AQjmsAgent[] recipients = { replyTo };
			// inherit message expiration from request
			long timeToLive;
			long jmsExpiration = request.getJMSExpiration();
			if (jmsExpiration > 0) {
				timeToLive = jmsExpiration - request.getJMSTimestamp();
			} else {
				timeToLive = -1; // forever
			}
			publisher.setTimeToLive(timeToLive);
			// ready to publish response
			publisher.publish(response, recipients);
			logger.info("response for correlationId " + correlationId + " sent.");
		}
	}

	@PostConstruct
	public void initialize() {
		logger.info("TextMessageListener initialized.");
	}

	@PreDestroy
	public void cleanup() {
		logger.info("TextMessageListener cleaned up.");
	}

	public void onMessage(final TextMessage request, final Session session) {
		String correlationId = null;
		try {
			correlationId = request.getJMSCorrelationID();
			logger.debug("processing message with correlationId " + correlationId + "...");
			String text = request.getText();
			if (text == null || text.isEmpty()) {
				String ename = request.getStringProperty("ename");
				Double oldSal = request.getDoubleProperty("old_sal");
				Double newSal = request.getDoubleProperty("new_sal");
				text = getText(ename, oldSal, newSal);
			}
			logger.info(text);
			Status status = twitter.updateStatus(text);
			String screenName = status.getUser().getScreenName();
			logger.debug("tweet by " + screenName);
			sendResponse(request, session, screenName + ": " + text);
			session.commit();
		} catch (Exception e) {
			try {
				session.rollback(); // increment retry count / expire message
			} catch (JMSException e1) {
				logger.error("Cound not rollback session (to increment retry count). Error was : " + e1.toString());
			}
			String errorText = "message with correlationId " + correlationId + " processed with error: " + e.toString();
			logger.error(errorText);
			try {
				sendResponse(request, session, errorText);
				session.commit();
			} catch (Exception e1) {
				logger.error("Could not send response for correlationId " + correlationId + ". Got error_ " + e1.toString());
			}
			throw new RuntimeException(errorText);
		}
	}
}
