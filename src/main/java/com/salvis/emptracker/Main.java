package com.salvis.emptracker;

import org.apache.log4j.Logger;
import org.springframework.context.support.FileSystemXmlApplicationContext;

public class Main {
	private static final Logger logger = Logger.getLogger(Main.class.getName());

	public static void main(String[] args) {
		final FileSystemXmlApplicationContext context = new FileSystemXmlApplicationContext("applicationContext.xml");
		final ShutdownThread shutdown = new ShutdownThread();
		shutdown.add(context);
		while (true) {
			try {
				Thread.sleep(1000);
			} catch (InterruptedException e) {
				logger.debug("Interrupted.");
				break;
			}
		}
		context.close();
	}
}
