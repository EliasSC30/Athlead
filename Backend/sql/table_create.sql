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
    PHONE VARCHAR(255) NOT NULL
);

CREATE TABLE PERSON (
    ID varchar(36) PRIMARY KEY,
    CONTACTINFO_ID varchar(36) UNIQUE NOT NULL,
    ROLE ENUM('ADMIN', 'JUDGE', 'CONTESTANT') NOT NULL,
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
    TIMEUNIT ENUM('SECONDS', 'MINUTES', 'HOURS'),
    LENGTH DOUBLE,
    LENGTHUNIT ENUM('CENTIMETERS', 'METERS', 'KILOMETERS'),
    WEIGHT DOUBLE,
    WEIGHTUNIT ENUM('GRAMS', 'KILOGRAMS', 'TONS'),
    AMOUNT DOUBLE
);
CREATE TABLE CONTESTRESULT(
    ID varchar(36) PRIMARY KEY,
    PERSON_ID varchar(36) NOT NULL,
    CONTESTRESULT_ID varchar(36) NOT NULL,
    METRIC_ID varchar(36) NOT NULL,
    FOREIGN KEY (METRIC_ID) REFERENCES METRIC(ID),
    FOREIGN KEY (PERSON_ID) REFERENCES PERSON(ID),
    FOREIGN KEY (CONTESTRESULT_ID) REFERENCES CONTESTRESULT(ID)
);
CREATE TABLE CONTEST (
    ID varchar(36) PRIMARY KEY,
    SPORTFEST_ID varchar(36) NOT NULL,
    DETAILS_ID varchar(36) NOT NULL,
    CONTESTRESULT_ID varchar(36) NOT NULL,
    FOREIGN KEY (CONTESTRESULT_ID) REFERENCES CONTESTRESULT(ID),
    FOREIGN KEY (SPORTFEST_ID) REFERENCES SPORTFEST(ID),
    FOREIGN KEY (DETAILS_ID) REFERENCES DETAILS(ID)
);
