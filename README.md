# emptracker

## Introduction
EmpTracker is a demo application to track changes in EMP table of an OracleDatabase and tweet about salary changes.

![Twitter Screenshot](https://raw.github.com/PhilippSalvisberg/emptracker/main/src/main/resources/twitter_emptracker_scott_miller.png)

## Prerequisites

* Oracle Database 11.1 or higher
* Oracle client (SQL\*Plus, SQLcl or SQL Developer) to connect to the database
* Twitter Account and [OAuth credentials](https://apps.twitter.com/)
* Java SE Development Kit 8
* Apache Maven 3

## Installation

1. Clone or download this repository. Extract the downloaded zip file, if you have chosen the download option.

2. Open a terminal window and change to the directory containing this README.md file

		cd (...)

3. Create an Oracle user for the emptracker database objects. The default username and password is ```emptracker```.
   * optionally change username, password and tablespace in the installation script [database/emptracker/user/emptracker.sql](https://github.com/PhilippSalvisberg/emptracker/blob/main/database/emptracker/user/emptracker.sql)

   * connect as sys to the target database

			sqlplus / as sysdba

   * execute the script [database/emptracker/user/emptracker.sql](https://github.com/PhilippSalvisberg/emptracker/blob/main/database/emptracker/user/emptracker.sql)

			@database/emptracker/user/emptracker.sql
			EXIT

4. Install database objects

   * connect to the emptracker user created in the previous step

			sqlplus emptracker/emptracker

   * execute the script [database/install.sql](https://github.com/PhilippSalvisberg/emptracker/blob/main/database/install.sql)

			@database/install.sql
			EXIT

5. Change [src/main/resources/application.properties](https://github.com/PhilippSalvisberg/emptracker/blob/main/src/main/resources/application.properties)

   * Database properties ```db.url```, ```db.user``` and ```db.password```
   * Twitter credentials ```twitter4j.oauth.consumerKey```, ```twitter4j.oauth. consumerSecret ```, ```twitter4j.oauth. accessToken ``` and ```twitter4j.oauth. accessTokenSecret ```

6. Run Spring Boot application

		mvn spring-boot:run
		
## Usage

The [demo](https://github.com/PhilippSalvisberg/emptracker/blob/main/database/demo/demo.sql) SQL script shows how to post a tweet from the database.

## Issues

Please file your bug reports, enhancement requests, questions and other support requests within [Github's issue tracker](https://help.github.com/articles/about-issues/):

* [Existing issues](https://github.com/PhilippSalvisberg/emptracker/issues)
* [submit new issue](https://github.com/PhilippSalvisberg/emptracker/issues/new)

## How to Contribute

1. Describe your idea by [submitting an issue](https://github.com/PhilippSalvisberg/emptracker/issues/new)
2. [Fork the plsql-utils respository](https://github.com/PhilippSalvisberg/emptracker/fork)
3. [Create a branch](https://help.github.com/articles/creating-and-deleting-branches-within-your-repository/), commit and publish your changes and enhancements
4. [Create a pull request](https://help.github.com/articles/creating-a-pull-request/)

## License

EmpTracker is licensed under the Apache License, Version 2.0. You may obtain a copy of the License at <http://www.apache.org/licenses/LICENSE-2.0>.
