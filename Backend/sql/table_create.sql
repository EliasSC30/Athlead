DROP DATABASE IF EXISTS Athlead;
CREATE DATABASE IF NOT EXISTS Athlead;
USE Athlead;

DROP TABLE IF EXISTS SPORTFEST;
DROP TABLE IF EXISTS CONTEST;
DROP TABLE IF EXISTS LOCATION;
DROP TABLE IF EXISTS DETAILS;
DROP TABLE IF EXISTS METRIC;
DROP TABLE IF EXISTS PERSON;
DROP TABLE IF EXISTS CONTACTINFO;
DROP TABLE IF EXISTS CONTESTRESULT;


CREATE TABLE LOCATION (
    ID varchar(36) PRIMARY KEY,
    CITY VARCHAR(255) NOT NULL,
    ZIPCODE VARCHAR(255) NOT NULL,
    STREET VARCHAR(255) NOT NULL,
    STREETNUMBER VARCHAR(255) NOT NULL,
    NAME VARCHAR(255)
);

CREATE TABLE CONTACTINFO (
    ID varchar(36) PRIMARY KEY,
    FIRSTNAME VARCHAR(255) NOT NULL,
    LASTNAME VARCHAR(255) NOT NULL,
    EMAIL VARCHAR(255) NOT NULL,
    PHONE VARCHAR(255) NOT NULL,
    GRADE VARCHAR(255),
    BIRTH_YEAR VARCHAR(255)
);

CREATE TABLE PERSON (
    ID varchar(36) PRIMARY KEY,
    CONTACTINFO_ID varchar(36) UNIQUE NOT NULL,
    ROLE varchar(255) NOT NULL,
    FOREIGN KEY (CONTACTINFO_ID) REFERENCES CONTACTINFO(ID)
);
CREATE TABLE DETAILS (
    ID varchar(36) PRIMARY KEY,
    LOCATION_ID varchar(36) NOT NULL,
    CONTACTPERSON_ID varchar(36) NOT NULL,
    NAME VARCHAR(255),
    START DATETIME NOT NULL,
    END DATETIME NOT NULL,
    FOREIGN KEY (LOCATION_ID) REFERENCES LOCATION(ID),
    FOREIGN KEY (CONTACTPERSON_ID) REFERENCES PERSON(ID)
);

CREATE TABLE SPORTFEST (
    ID varchar(36) PRIMARY KEY,
    DETAILS_ID varchar(36) NOT NULL,
    FOREIGN KEY (DETAILS_ID) REFERENCES DETAILS(ID)
);
CREATE TABLE METRIC(
    ID varchar(36) PRIMARY KEY,
    TIME DOUBLE,
    TIMEUNIT varchar(255),
    LENGTH DOUBLE,
    LENGTHUNIT varchar(255),
    WEIGHT DOUBLE,
    WEIGHTUNIT varchar(255),
    AMOUNT DOUBLE
);

CREATE TABLE C_TEMPLATE(
    ID varchar(36) PRIMARY KEY,
    NAME varchar(255) NOT NULL,
    DESCRIPTION varchar(255),
    GRADERANGE varchar(255),
    EVALUATION varchar(255) NOT NULL,
    UNIT varchar(255) NOT NULL
);

CREATE TABLE CONTEST(
    ID varchar(36) PRIMARY KEY,
    SPORTFEST_ID varchar(36) NOT NULL,
    DETAILS_ID varchar(36) NOT NULL,
    C_TEMPLATE_ID varchar(36) NOT NULL,
    FOREIGN KEY (SPORTFEST_ID) REFERENCES SPORTFEST(ID),
    FOREIGN KEY (DETAILS_ID) REFERENCES DETAILS(ID),
    FOREIGN KEY (C_TEMPLATE_ID) REFERENCES C_TEMPLATE(ID)
);

CREATE TABLE CONTESTRESULT(
  ID varchar(36) PRIMARY KEY,
  PERSON_ID varchar(36) NOT NULL,
  CONTEST_ID varchar(36) NOT NULL,
  METRIC_ID varchar(36) NOT NULL,
  FOREIGN KEY (METRIC_ID) REFERENCES METRIC(ID),
  FOREIGN KEY (CONTEST_ID) REFERENCES CONTEST(ID),
  FOREIGN KEY (PERSON_ID) REFERENCES PERSON(ID),
  CONSTRAINT UNIQUE_PERSON_RESULT UNIQUE (PERSON_ID, CONTEST_ID)
);

CREATE TABLE AUTHENTICATION(
  AUTH varchar(255) PRIMARY KEY,
  PERSON_ID varchar(255) NOT NULL,
  FOREIGN KEY (PERSON_ID) REFERENCES PERSON(ID)
);
