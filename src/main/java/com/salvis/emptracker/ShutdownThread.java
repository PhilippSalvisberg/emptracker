package com.salvis.emptracker;


import org.apache.log4j.Logger;
import org.springframework.context.support.FileSystemXmlApplicationContext;

public class ShutdownThread {
	private final Logger logger = Logger.getLogger(ShutdownThread.class);
	
	public void add(FileSystemXmlApplicationContext ctx) {
		final FileSystemXmlApplicationContext context = ctx;
		Runtime.getRuntime().addShutdownHook(new Thread() {
			@Override
			public void run() {
				context.close();
				logger.info("Application terminated gracefully.");
			}
		});
	}
}
