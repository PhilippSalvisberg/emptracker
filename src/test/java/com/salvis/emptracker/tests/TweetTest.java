package com.salvis.emptracker.tests;

import org.junit.Assert;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.junit4.SpringRunner;

import com.salvis.emptracker.AppConfig;

import twitter4j.Status;
import twitter4j.Twitter;
import twitter4j.TwitterException;

@RunWith(SpringRunner.class)
@SpringBootTest
@Import(AppConfig.class)
public class TweetTest {
	
	@Autowired
	private Twitter twitter;

	@Test
	public void postTweet() throws TwitterException {
		String text = "SCOTT got a pay raise of $150. Making $3000 a month now. Congrats.";
		Status status = twitter.updateStatus(text);
		Assert.assertEquals(text, status.getText());
	}

}
