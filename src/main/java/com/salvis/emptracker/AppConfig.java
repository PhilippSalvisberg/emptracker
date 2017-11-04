package com.salvis.emptracker;

import java.sql.SQLException;

import javax.jms.ConnectionFactory;
import javax.jms.JMSException;
import javax.jms.Session;
import javax.jms.TopicConnectionFactory;
import javax.sql.DataSource;

import org.apache.log4j.Logger;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.PropertySource;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.jms.listener.DefaultMessageListenerContainer;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.EnableTransactionManagement;

import oracle.jms.AQjmsFactory;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;
import twitter4j.Twitter;
import twitter4j.TwitterFactory;
import twitter4j.conf.ConfigurationBuilder;

@EnableTransactionManagement
@Configuration
@PropertySource(value = "file:${user.home}/emptracker.properties", ignoreResourceNotFound = true)
public class AppConfig {
	private final Logger logger = Logger.getLogger(AppConfig.class);

	@Value("${db.url}")
	private String url;

	@Value("${db.user}")
	private String user;

	@Value("${db.password}")
	private String password;

	@Value("${db.queue}")
	private String queueName;
	
	@Value("${app.name}")
	private String appName;
	
	@Value("${twitter4j.oauth.consumerKey}")
	private String consumerKey;

	@Value("${twitter4j.oauth.consumerSecret}")
	private String consumerSecret;

	@Value("${twitter4j.oauth.accessToken}")
	private String accessToken;

	@Value("${twitter4j.oauth.accessTokenSecret}")
	private String accessTokenSecret;
	
	@Bean
	public Twitter twitter() {
		ConfigurationBuilder cb = new ConfigurationBuilder();
		cb.setOAuthConsumerKey(consumerKey)
			.setOAuthConsumerSecret(consumerSecret)
			.setOAuthAccessToken(accessToken)
			.setOAuthAccessTokenSecret(accessTokenSecret);
		TwitterFactory tf = new TwitterFactory(cb.build());
		Twitter twitter = tf.getInstance();
		return twitter;
	}
	
	@Bean
	public ConnectionFactory connectionFactory() {
		logger.info("connectionFactory() called.");
		TopicConnectionFactory connectionFactory;
		try {
			connectionFactory = AQjmsFactory.getTopicConnectionFactory(messageDataSource());
		} catch (JMSException e) {
			throw new RuntimeException("cannot get connection factory.");
		}
		return connectionFactory;
	}

	@Bean
	public TextMessageListener messageListener() {
		logger.info("messageListener() called.");
		return new TextMessageListener();
	}

	@Bean
	public DefaultMessageListenerContainer messageListenerContainer() {
		logger.info("messageListenerContainer() called.");
		DefaultMessageListenerContainer cont = new DefaultMessageListenerContainer();
		cont.setMessageListener(messageListener());
		cont.setConnectionFactory(connectionFactory());
		cont.setDestinationName(queueName);
		cont.setPubSubDomain(true);
		cont.setSubscriptionName(appName);
		cont.setSubscriptionDurable(true);
		cont.setMessageSelector("msg_type IN ('AGGR', 'TWEET')");
		cont.setSessionAcknowledgeMode(Session.SESSION_TRANSACTED);
		cont.setSessionTransacted(true);
		cont.setConcurrency("1-4");
		cont.setMaxMessagesPerTask(20);
		cont.setReceiveTimeout(10);
		return cont;
	}
	
	@Bean
	public DataSource messageDataSource() {
		logger.info("messageDataSource() called.");
		PoolDataSource pds = PoolDataSourceFactory.getPoolDataSource();
		try {
			pds.setConnectionFactoryClassName("oracle.jdbc.OracleDriver");
			// see https://docs.oracle.com/database/122/JJUAR/oracle/ucp/jdbc/PoolDataSource.html
			pds.setURL(url);
			pds.setUser(user);
			pds.setPassword(password);
			// close inactive connections within the pool after 60 seconds
			pds.setInactiveConnectionTimeout(60); 
			// return inactive connections to the pool after ... seconds, e.g. to recover from network failure
			// if connection is idle for the configured number of seconds, but JMS based operation is
			// not yet completed, then the session is returned to the pool, even if a subsequent response and
			// commit would have been possible. Hence this timeout is set to 0.
			pds.setAbandonedConnectionTimeout(0); 
			// allow a borrowed connection to be used infinitely, required for long running transactions 
			pds.setTimeToLiveConnectionTimeout(0);
			// check all timeout settings every 30 seconds
			pds.setTimeoutCheckInterval(30);
		} catch (SQLException e) {
			throw new RuntimeException("driver not found");
		}
		return pds;
	}
	
    @Bean
    public PlatformTransactionManager txManager() {
        return new DataSourceTransactionManager(messageDataSource());
    }	
}