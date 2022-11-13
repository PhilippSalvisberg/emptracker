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

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;

import com.salvis.emptracker.AppConfig;

import twitter4j.Twitter;
import twitter4j.TwitterException;
import twitter4j.v1.Status;

@SpringBootTest(classes=AppConfig.class)
@Import(AppConfig.class)
public class TweetTest {
	
	@Autowired
	private Twitter twitter;

	@Test
	public void postTweet() throws TwitterException {
		String text = "SCOTT got a pay raise of $250. Making $3100 a month now. Congrats.";
		Status status = twitter.v1().tweets().updateStatus(text);
		Assertions.assertEquals(text, status.getText());
	}

}
