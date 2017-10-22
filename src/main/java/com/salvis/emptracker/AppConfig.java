package com.salvis.emptracker;

import java.sql.SQLException;

import javax.jms.ConnectionFactory;
import javax.jms.JMSException;
import javax.jms.Session;
import javax.jms.TopicConnectionFactory;
import javax.sql.DataSource;

import org.apache.log4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.jms.listener.DefaultMessageListenerContainer;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.EnableTransactionManagement;

import oracle.jms.AQjmsFactory;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

@EnableTransactionManagement
@Configuration
public class AppConfig {
	private final Logger logger = Logger.getLogger(AppConfig.class);

	@Autowired(required = false)
	@Qualifier("aqUrl")
	private String aqUrl = "jdbc:oracle:thin:@localhost:1521:odb";

	@Autowired(required = false)
	@Qualifier("aqUserName")
	private String aqUserName = "emptracker";

	@Autowired(required = false)
	@Qualifier("aqPassword")
	private String aqPassword = "emptracker";

	@Autowired(required = false)
	@Qualifier("requestQueueName")
	private String requestQueueName = "requests_aq";
	
	@Autowired(required = false)
	@Qualifier("appName")
	private String appName = "EmpTracker";

	@Autowired(required = false)
	@Qualifier("concurrency")
	private String concurrency = "1-4";
	
	@Autowired(required = false)
	@Qualifier("receiveTimeout")
	private Integer receiveTimeout = 1;
	
	@Autowired(required = false)
	@Qualifier("maxMessagesPerTask")
	private Integer maxMessagesPerTask = 1;
	
	@Autowired(required = false)
	@Qualifier("subscriptionDurable")
	private Boolean subscriptionDurable = true;
	
	@Bean
	public TwitterEmpTracker twitter() {
		return new TwitterEmpTracker();
	}
	
	@Bean
	public ConnectionFactory connectionFactory() {
		logger.info("connectionFactory() called.");
		TopicConnectionFactory connectionFactory;
		try {
			connectionFactory = AQjmsFactory.getTopicConnectionFactory(aqDataSource());
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
	public DefaultMessageListenerContainer salChangeJmsContainer() {
		logger.info("salChangeJmsContainer() called.");
		DefaultMessageListenerContainer cont = new DefaultMessageListenerContainer();
		cont.setMessageListener(messageListener());
		cont.setConnectionFactory(connectionFactory());
		cont.setDestinationName(requestQueueName);
		cont.setPubSubDomain(true);
		cont.setSubscriptionName(appName);
		cont.setSubscriptionDurable(subscriptionDurable);
		cont.setMessageSelector("msg_type = 'AGGR'");
		cont.setSessionAcknowledgeMode(Session.SESSION_TRANSACTED);
		cont.setSessionTransacted(true);
		cont.setConcurrency(concurrency);
		cont.setMaxMessagesPerTask(maxMessagesPerTask);
		cont.setReceiveTimeout(receiveTimeout);
		return cont;
	}
	
	@Bean
	public DataSource aqDataSource() {
		logger.info("aqDataSource() called.");
		PoolDataSource pds = PoolDataSourceFactory.getPoolDataSource();
		try {
			pds.setConnectionFactoryClassName("oracle.jdbc.OracleDriver");
			String url = aqUrl;
			// see https://docs.oracle.com/database/122/JJUAR/oracle/ucp/jdbc/PoolDataSource.html
			pds.setURL(url);
			pds.setUser(aqUserName);
			pds.setPassword(aqPassword);
			// close inactive connections within the pool after 60 seconds
			pds.setInactiveConnectionTimeout(60); 
			// return inactive connections to the pool after ... seconds, e.g. to recover from network failure
			// if connection is idle for the configured number of seconds, but but JMS based operation is
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
        return new DataSourceTransactionManager(aqDataSource());
    }
	
}