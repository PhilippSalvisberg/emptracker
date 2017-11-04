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
