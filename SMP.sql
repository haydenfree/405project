-- Hayden Free
-- Cole Terrell
USE mysql;
DROP DATABASE SMPDB_test;
CREATE DATABASE SMPDB_test;
USE SMPDB_test;
CREATE TABLE Identity 
        (idnum BIGINT AUTO_INCREMENT PRIMARY KEY,
         handle   VARCHAR(100) UNIQUE,
         pass     VARCHAR(100) NOT NULL,
         fullname VARCHAR(100) NOT NULL,
         location VARCHAR(100),
         email    VARCHAR(100) NOT NULL,
         bdate    DATE NOT NULL,
         joined   TIMESTAMP
        ) COMMENT="The Identity Table";
CREATE TABLE Story 
        (sidnum  BIGINT AUTO_INCREMENT PRIMARY KEY,
         idnum   BIGINT,
         chapter VARCHAR(100) NOT NULL,
         url     VARCHAR(100),
         expires DATETIME,
         tstamp  TIMESTAMP,
         FOREIGN KEY(idnum) REFERENCES Identity(idnum)
        ) COMMENT="The Story Table";
CREATE TABLE Follows 
        (follower   BIGINT,
         followed   BIGINT,
         tstamp     TIMESTAMP,
	 FOREIGN KEY(follower) REFERENCES Identity(idnum),
	 FOREIGN KEY(followed) REFERENCES Identity(idnum)
        ) COMMENT="The Follows Table";
CREATE TABLE Reprint
        (rpnum      BIGINT AUTO_INCREMENT PRIMARY KEY,
         idnum      BIGINT,
         sidnum     BIGINT,
         likeit     BOOLEAN,
         tstamp  TIMESTAMP,
	 FOREIGN KEY(idnum) REFERENCES Identity(idnum),
	 FOREIGN KEY(sidnum) REFERENCES Story(sidnum)
        ) COMMENT="The Reprint Table";
CREATE TABLE Block 
        (blknum     BIGINT AUTO_INCREMENT PRIMARY KEY,
         idnum      BIGINT,
         blocked    BIGINT,
         tstamp     TIMESTAMP,
	 FOREIGN KEY(idnum)   REFERENCES Identity(idnum),
	 FOREIGN KEY(blocked) REFERENCES Identity(idnum)
        ) COMMENT="The Block Table";
GRANT ALL ON SMPDB_test.* TO 'ccte222'@localhost IDENTIFIED BY 'mysqlpass'; 
GRANT ALL on SMPDB_test.* TO 'paul'@'belgarath.cs.uky.edu' IDENTIFIED BY 'jellydonuts!';
GRANT ALL on SMPDB_test.* TO 'paul'@'paul.cs.uky.edu' IDENTIFIED BY 'jellydonuts!'; 
FLUSH privileges;
