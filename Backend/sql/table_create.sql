DROP DATABASE IF EXISTS Athlead;
CREATE DATABASE IF NOT EXISTS Athlead;
USE Athlead;

DROP TABLE IF EXISTS METRIC;
DROP TABLE IF EXISTS CONTESTRESULT;
DROP TABLE IF EXISTS PARENT;
DROP TABLE IF EXISTS HELPER;
DROP TABLE IF EXISTS CONTEST;
DROP TABLE IF EXISTS SPORTFEST;
DROP TABLE IF EXISTS DETAILS;
DROP TABLE IF EXISTS PERSON;
DROP TABLE IF EXISTS LOCATION;
DROP TABLE IF EXISTS C_TEMPLATE;

CREATE TABLE LOCATION(
    ID varchar(36) PRIMARY KEY,
    CITY VARCHAR(255) NOT NULL,
    ZIPCODE VARCHAR(255) NOT NULL,
    STREET VARCHAR(255) NOT NULL,
    STREETNUMBER VARCHAR(255) NOT NULL,
    NAME VARCHAR(255) NOT NULL
);

CREATE TABLE PERSON(
    ID varchar(36) PRIMARY KEY,
    FIRSTNAME VARCHAR(255) NOT NULL,
    LASTNAME VARCHAR(255) NOT NULL,
    EMAIL VARCHAR(255) NOT NULL,
    PHONE VARCHAR(255) NOT NULL,
    GRADE VARCHAR(255),
    BIRTH_YEAR VARCHAR(255),
    ROLE varchar(255) NOT NULL,
    GENDER varchar(8) NOT NULL,
    PICS BIT NOT NULL,
    PASSWORD varchar(127) NOT NULL,
    CONSTRAINT NAME UNIQUE (FIRSTNAME,LASTNAME),
    CONSTRAINT EMAIL UNIQUE (EMAIL)
);

CREATE TABLE PARENT(
    PARENT_ID varchar(36) NOT NULL,
    CHILD_ID varchar(36) NOT NULL,
    FOREIGN KEY (PARENT_ID) REFERENCES PERSON(ID),
    FOREIGN KEY (CHILD_ID) REFERENCES PERSON(ID),
    CONSTRAINT ParentChild UNIQUE (PARENT_ID, CHILD_ID)
);

CREATE TABLE HELPER(
    CONTEST_ID varchar(36) NOT NULL,
    HELPER_ID varchar(36) NOT NULL,
    CONSTRAINT ContestHelper UNIQUE (CONTEST_ID, HELPER_ID)
);

CREATE TABLE DETAILS(
    ID varchar(36) PRIMARY KEY,
    LOCATION_ID varchar(36) NOT NULL,
    CONTACTPERSON_ID varchar(36) NOT NULL,
    NAME VARCHAR(255) NOT NULL,
    START DATETIME NOT NULL,
    END DATETIME NOT NULL,
    FOREIGN KEY (LOCATION_ID) REFERENCES LOCATION(ID),
    FOREIGN KEY (CONTACTPERSON_ID) REFERENCES PERSON(ID),
    CONSTRAINT NAME UNIQUE (NAME)
);

CREATE TABLE SPORTFEST(
    ID varchar(36) PRIMARY KEY,
    DETAILS_ID varchar(36) NOT NULL,
    FOREIGN KEY (DETAILS_ID) REFERENCES DETAILS(ID)
);

CREATE TABLE METRIC(
    ID varchar(36) PRIMARY KEY,
    VALUE DOUBLE NOT NULL,
    UNIT varchar(255) NOT NULL
);

CREATE TABLE C_TEMPLATE(
    ID varchar(36) PRIMARY KEY,
    NAME varchar(255) NOT NULL,
    DESCRIPTION varchar(255),
    GRADERANGE varchar(255),
    EVALUATION varchar(255) NOT NULL,
    UNIT varchar(255) NOT NULL,
    CONSTRAINT UNIQUE_NAME UNIQUE (NAME)
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
  METRIC_ID varchar(36),
  FOREIGN KEY (CONTEST_ID) REFERENCES CONTEST(ID),
  FOREIGN KEY (PERSON_ID) REFERENCES PERSON(ID),
  CONSTRAINT UNIQUE_PERSON_RESULT UNIQUE (PERSON_ID, CONTEST_ID)
);
