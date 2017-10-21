package com.salvis.emptracker;

import javax.annotation.PostConstruct;
import javax.annotation.PreDestroy;
import javax.jms.JMSException;
import javax.jms.Session;
import javax.jms.TextMessage;
import javax.jms.Topic;
import javax.jms.TopicSession;

import org.apache.log4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.jms.listener.SessionAwareMessageListener;
import org.springframework.stereotype.Component;

import oracle.jms.AQjmsAgent;
import oracle.jms.AQjmsTopicPublisher;

@Component
public class TextMessageListener implements SessionAwareMessageListener<TextMessage> {
	private final Logger logger = Logger.getLogger(TextMessageListener.class.getName());
	
	@Autowired
	private TwitterEmpTracker twitter;

	@Autowired(required = false)
	@Qualifier("salaryIncreaseTemplate")
	private String salaryIncreaseTemplate = "OMG ${ename} got a pay raise of $${more}. Making $${new_sal} a month now. Congrats. #OnCommitTrigger at #DOAG2017";
	
	@Autowired(required = false)
	@Qualifier("salaryDecreaseTemplate")
	private String salaryDecreaseTemplate = "Oh no, ${ename} got a pay reduction of $${less}. Making $${new_sal} a month now. #OnCommitTrigger at #DOAG2017";	
	
	private String getText(String ename, Double oldSal, Double newSal) {
		String template;
		if (newSal > oldSal) {
			Double more = newSal - oldSal;
			template = salaryIncreaseTemplate.replace("${more}", String.format("%.2f", more));
		} else {
			Double less = oldSal - newSal;
			template = salaryDecreaseTemplate.replace("${less}", String.format("%.2f", less));
		}
		return template.replace("${ename}", ename.substring(0, 1) + ename.substring(1).toLowerCase())
				.replace("${new_sal}", String.format("%.2f", newSal)).replace("${old_sal}", String.format("%.2f", oldSal));
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

		String messageId = null;
		try {
			messageId = request.getJMSMessageID();
			logger.debug("processing message " + messageId + "...");
			// prepare "empty" response
			TextMessage response = null;
			AQjmsAgent replyTo = (AQjmsAgent) request.getJMSReplyTo();
			response = session.createTextMessage();
			response.setJMSCorrelationID(request.getJMSCorrelationID());
			// get text to post
			String text = getText(request.getStringProperty("ename"), request.getDoubleProperty("old_sal"), request.getDoubleProperty("new_sal"));
			logger.info("sending " + text);
			twitter.updateStatus(text);
			response.setText(text);
			// create a publisher using the current database session
			// (connection)
			Topic topic = session.createTopic(replyTo.getAddress());
			AQjmsTopicPublisher publisher = (AQjmsTopicPublisher) ((TopicSession) session)
					.createPublisher(topic);
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
			logger.debug("published response for message " + messageId + " (expires in "
					+ Long.toString(timeToLive) + ").");
			session.commit();
		} catch (Exception e) {
			try {
				session.rollback(); // increment retry count / expire message
			} catch (JMSException e1) {
				logger.error("Cound not rollback session (to increment retry count). Error was : " + e1.getMessage());
			} // expire message
			String errorText = "message " + messageId + " processed with error: " + e.getMessage();
			logger.error(errorText);
			throw new RuntimeException(errorText);
		}
	}
}
