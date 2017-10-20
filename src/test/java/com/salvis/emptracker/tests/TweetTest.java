package com.salvis.emptracker.tests;

import org.junit.Assert;
import org.junit.Test;

import com.salvis.emptracker.TwitterEmpTracker;

import twitter4j.Status;

public class TweetTest {

	@Test
	public void postTweet() {
		TwitterEmpTracker twitter = new TwitterEmpTracker();
		String text = "SCOTT got a pay raise of $150. Making $3000 a month now. Congrats.";
		Status status = twitter.updateStatus(text);
		Assert.assertEquals(text, status.getText());
	}

}
