package com.salvis.emptracker;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.Properties;

import twitter4j.Status;
import twitter4j.Twitter;
import twitter4j.TwitterException;
import twitter4j.TwitterFactory;
import twitter4j.conf.ConfigurationBuilder;

public class TwitterEmpTracker {
	static final String PROPERTY_FILE = "/etc/emptracker.properties";
	
	private Twitter twitter;
	
	public TwitterEmpTracker() {
		Properties p = new Properties();
		try {
			FileInputStream fis = new FileInputStream(PROPERTY_FILE);
			p.load(fis);
			fis.close();
			ConfigurationBuilder cb = new ConfigurationBuilder();
			cb.setDebugEnabled(p.getProperty("debug", "false").equals("true"))
				.setOAuthConsumerKey(p.getProperty("oauth.consumerKey"))
				.setOAuthConsumerSecret(p.getProperty("oauth.consumerSecret"))
				.setOAuthAccessToken(p.getProperty("oauth.accessToken"))
				.setOAuthAccessTokenSecret(p.getProperty("oauth.accessTokenSecret"));
			TwitterFactory tf = new TwitterFactory(cb.build());
			twitter = tf.getInstance();
		} catch (FileNotFoundException e) {
			throw new RuntimeException("Property file " + PROPERTY_FILE + " is missing.");
		} catch (IOException e) {
			throw new RuntimeException("Error reading " + PROPERTY_FILE + ".");
		}
	}
	
	public Status updateStatus(String text) {
		try {
			return twitter.updateStatus(text);
		} catch (TwitterException e) {
			throw new RuntimeException(e.getMessage());
		}
	}
}
