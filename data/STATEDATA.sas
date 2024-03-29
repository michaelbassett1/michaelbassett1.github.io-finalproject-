/*FINAL PROJECT - DATA CLEANING*/
/*STATE DATA*/

/*IMPORTING IN AS16 FILE - HAS 2016 AND 2015 FIGURES*/ 
/*10,346 OBS*/ 
PROC IMPORT DATAFILE = 'H:\3.Teams and Projects\gradproject\AS16.XLSX'
OUT=AS16
DBMS=XLSX
REPLACE;
RUN;

/*PULLING ONLY THE VARIABLES WE NEED*/ 
PROC SQL NOPRINT; 

CREATE TABLE AS16_2 AS
SELECT	IFC(NAICS_ID EQ '31-33','31',NAICS_ID) AS NAICS LABEL="",
		NAICS_DISPLAY_LABEL AS NAICS_DESC LABEL="",
		GEO_DISPLAY_LABEL AS STATE LABEL="",
		YEAR_ID AS YEAR LABEL="",
		RCPTOT, 
		CSTMTOT,
		PAYANN,
		EMP
FROM AS16
ORDER BY CALCULATED NAICS, STATE, YEAR; 

QUIT; 

/*IMPORTING IN AS14 FILE - HAS 2014 FIGURES*/ 
/*10,324 OBS. LESS THAN THE FIRST FILE*/ 
PROC IMPORT DATAFILE = 'H:\3.Teams and Projects\gradproject\AS14.XLSX'
OUT=AS14
DBMS=XLSX
REPLACE;
RUN;

/*PULLING ONLY THE VARIABLES WE NEED*/ 
PROC SQL NOPRINT; 

CREATE TABLE AS14_2 AS
SELECT	IFC(NAICS_ID EQ '31-33','31',NAICS_ID) AS NAICS LABEL="",
		NAICS_DISPLAY_LABEL AS NAICS_DESC LABEL="",
		GEO_DISPLAY_LABEL AS STATE LABEL="",
		YEAR_ID AS YEAR LABEL="",
		RCPTOT, 
		CSTMTOT,
		PAYANN,
		EMP
FROM AS14
ORDER BY CALCULATED NAICS, STATE, YEAR; 

QUIT; 

/*5158*/ 
DATA AS14_3;
SET AS14_2;
IF YEAR=2015 THEN DELETE; 
RUN;

/*IMPORTING IN AS13 FILE - HAS 2013 FIGURES*/ 
/*ALSO SOME 2012 FIGURES*/ 
/*15,104 OBS. MORE THAN THE FIRST FILE*/ 
/*THIS IS PROBABLY WHEN THERE'S CASES WHERE THERE WERE 0 ESTABS OR SOMETHING LIKE THAT?*/
PROC IMPORT DATAFILE = 'H:\3.Teams and Projects\gradproject\AS13.XLSX'
OUT=AS13
DBMS=XLSX
REPLACE;
RUN;

/*PULLING ONLY THE VARIABLES WE NEED*/ 
PROC SQL NOPRINT; 

CREATE TABLE AS13_2 AS
SELECT	IFC(NAICS_ID EQ '31-33','31',NAICS_ID) AS NAICS LABEL="",
		NAICS_DISPLAY_LABEL AS NAICS_DESC LABEL="",
		GEO_DISPLAY_LABEL AS STATE LABEL="",
		YEAR_ID AS YEAR LABEL="",
		RCPTOT, 
		CSTMTOT,
		PAYANN,
		EMP
FROM AS13
ORDER BY CALCULATED NAICS, STATE, YEAR; 

QUIT; 

/*9946*/ 
DATA AS13_3;
SET AS13_2;
IF YEAR=2014 THEN DELETE; 
RUN;

/*NOW THAT ALL FIVE YEARS HAVE BEEN PULLED, CREATING THE DATASET THAT HAS EVERYTHING TOGETHER*/ 
DATA AS5YEARS;
SET AS16_2;
RUN; 

PROC APPEND BASE=AS5YEARS DATA=AS14_3; 
RUN; 

PROC APPEND BASE=AS5YEARS DATA=AS13_3;
RUN; 

/*NOW HAS 24450 OBS*/ 

/*NOW MAKING THE TABLES FOR EACH OF THE FOUR CORE VARIABLES*/ 

/*RCPTOT*/ 
PROC SQL NOPRINT; 

CREATE TABLE ST_RCPTOT AS
SELECT	NAICS,
		LENGTH(NAICS) AS LEVEL,
		NAICS_DESC,
		STATE,
		YEAR,
		RCPTOT
FROM AS5YEARS
ORDER BY NAICS,STATE, YEAR; 

QUIT; 

PROC TRANSPOSE DATA=ST_RCPTOT OUT=ST_RCPTOT2;
BY NAICS STATE; 
ID YEAR;
VAR RCPTOT;
RUN; 

PROC SQL NOPRINT; 

/*5268 ROWS*/ 
CREATE TABLE ST_RCPTOT3 AS
SELECT DISTINCT
		A.NAICS,
		B.LEVEL,
		B.NAICS_DESC,
		A.STATE,
		A._NAME_ AS VARIABLE LABEL="",
		"Total value of shipments and receipts for services ($1,000)" AS VAR_DESC,
		A._2012,
		A._2013,
		A._2014,
		A._2015,
		A._2016
FROM ST_RCPTOT2 AS A
LEFT JOIN ST_RCPTOT AS B
ON A.NAICS=B.NAICS 
ORDER BY B.LEVEL, A.NAICS, A.STATE; 

/*FOR STATE DATA, THERE ARE MORE DISCLOSURE ISSUES. 
IDENTIFYING WHAT FLAGS ARE BEING DISPLAYED, SO THAT LATER WE CAN DELETE THEM
ONLY NON NUMBER VALUES ARE '' AND 'D'*/ 
CREATE TABLE RCPTOTFLAGS2012 AS
SELECT	_2012,
		COUNT(_2012) AS COUNT
FROM ST_RCPTOT3
GROUP BY _2012
ORDER BY _2012 DESC; 

/*FLAGS ARE S, D, AND ''*/ 
CREATE TABLE RCPTOTFLAGS2016 AS
SELECT	_2016,
		COUNT(_2016) AS COUNT
FROM ST_RCPTOT3
GROUP BY _2016
ORDER BY _2016 DESC; 
QUIT; 

/*DELETING ROWS WITHOUT APPROPRIATE 2012 AND 2016 DATA*/ 
/*DECREASES FROM 5268 TO 2725 OBS*/ 
DATA ST_RCPTOT4; 
SET ST_RCPTOT3; 
IF _2012='D' THEN DELETE; 
IF _2012='' THEN DELETE;
IF _2016='D' THEN DELETE; 
IF _2016='S' THEN DELETE;
IF _2016='' THEN DELETE; 
RUN; 

/*CSTMTOT*/ 
PROC SQL NOPRINT; 

CREATE TABLE ST_CSTMTOT AS
SELECT	NAICS,
		LENGTH(NAICS) AS LEVEL,
		NAICS_DESC,
		STATE,
		YEAR,
		CSTMTOT
FROM AS5YEARS
ORDER BY NAICS,STATE, YEAR; 

QUIT; 

PROC TRANSPOSE DATA=ST_CSTMTOT OUT=ST_CSTMTOT2;
BY NAICS STATE; 
ID YEAR;
VAR CSTMTOT;
RUN; 

PROC SQL NOPRINT; 

/*5268 ROWS*/ 
CREATE TABLE ST_CSTMTOT3 AS
SELECT DISTINCT
		A.NAICS,
		B.LEVEL,
		B.NAICS_DESC,
		A.STATE,
		A._NAME_ AS VARIABLE LABEL="",
		"Total cost of materials ($1,000)" AS VAR_DESC,
		A._2012,
		A._2013,
		A._2014,
		A._2015,
		A._2016
FROM ST_CSTMTOT2 AS A
LEFT JOIN ST_CSTMTOT AS B
ON A.NAICS=B.NAICS 
ORDER BY B.LEVEL, A.NAICS, A.STATE; 

/*ONLY NON NUMBER VALUES ARE '' AND 'D'*/ 
CREATE TABLE CSTMTOTFLAGS2012 AS
SELECT	_2012,
		COUNT(_2012) AS COUNT
FROM ST_CSTMTOT3
GROUP BY _2012
ORDER BY _2012 DESC; 

/*FLAGS ARE S, D, AND ''*/ 
CREATE TABLE CSTMTOTFLAGS2016 AS
SELECT	_2016,
		COUNT(_2016) AS COUNT
FROM ST_CSTMTOT3
GROUP BY _2016
ORDER BY _2016 DESC; 
QUIT; 

/*DELETING ROWS WITHOUT APPROPRIATE 2012 AND 2016 DATA*/ 
/*DECREASES FROM 5268 TO 2805 OBS*/ 
DATA ST_CSTMTOT4; 
SET ST_CSTMTOT3; 
IF _2012='D' THEN DELETE; 
IF _2012='' THEN DELETE;
IF _2016='D' THEN DELETE; 
IF _2016='S' THEN DELETE;
IF _2016='' THEN DELETE; 
RUN; 

/*PAYANN*/ 
PROC SQL NOPRINT; 

CREATE TABLE ST_PAYANN AS
SELECT	NAICS,
		LENGTH(NAICS) AS LEVEL,
		NAICS_DESC,
		STATE,
		YEAR,
		PAYANN
FROM AS5YEARS
ORDER BY NAICS,STATE, YEAR; 

QUIT; 

PROC TRANSPOSE DATA=ST_PAYANN OUT=ST_PAYANN2;
BY NAICS STATE; 
ID YEAR;
VAR PAYANN;
RUN; 

PROC SQL NOPRINT; 

/*5268 ROWS*/ 
CREATE TABLE ST_PAYANN3 AS
SELECT DISTINCT
		A.NAICS,
		B.LEVEL,
		B.NAICS_DESC,
		A.STATE,
		A._NAME_ AS VARIABLE LABEL="",
		"Annual payroll ($1,000)" AS VAR_DESC,
		A._2012,
		A._2013,
		A._2014,
		A._2015,
		A._2016
FROM ST_PAYANN2 AS A
LEFT JOIN ST_PAYANN AS B
ON A.NAICS=B.NAICS 
ORDER BY B.LEVEL, A.NAICS, A.STATE; 

/*ONLY NON NUMBER VALUES ARE '' AND 'D'*/ 
CREATE TABLE PAYANNFLAGS2012 AS
SELECT	_2012,
		COUNT(_2012) AS COUNT
FROM ST_PAYANN3
GROUP BY _2012
ORDER BY _2012 DESC; 

/*FLAGS ARE S, D, AND ''*/ 
CREATE TABLE PAYANNFLAGS2016 AS
SELECT	_2016,
		COUNT(_2016) AS COUNT
FROM ST_PAYANN3
GROUP BY _2016
ORDER BY _2016 DESC; 
QUIT; 

/*DELETING ROWS WITHOUT APPROPRIATE 2012 AND 2016 DATA*/ 
/*DECREASES FROM 5268 TO 3656 OBS*/ 
DATA ST_PAYANN4; 
SET ST_PAYANN3; 
IF _2012='D' THEN DELETE; 
IF _2012='' THEN DELETE;
IF _2016='D' THEN DELETE; 
IF _2016='S' THEN DELETE;
IF _2016='' THEN DELETE; 
RUN; 

/*EMP*/ 
PROC SQL NOPRINT; 

CREATE TABLE ST_EMP AS
SELECT	NAICS,
		LENGTH(NAICS) AS LEVEL,
		NAICS_DESC,
		STATE,
		YEAR,
		EMP
FROM AS5YEARS
ORDER BY NAICS,STATE, YEAR; 

QUIT; 

PROC TRANSPOSE DATA=ST_EMP OUT=ST_EMP2;
BY NAICS STATE; 
ID YEAR;
VAR EMP;
RUN; 

PROC SQL NOPRINT; 

/*5268 ROWS*/ 
CREATE TABLE ST_EMP3 AS
SELECT DISTINCT
		A.NAICS,
		B.LEVEL,
		B.NAICS_DESC,
		A.STATE,
		A._NAME_ AS VARIABLE LABEL="",
		"Number of employees" AS VAR_DESC,
		A._2012,
		A._2013,
		A._2014,
		A._2015,
		A._2016
FROM ST_EMP2 AS A
LEFT JOIN ST_EMP AS B
ON A.NAICS=B.NAICS 
ORDER BY B.LEVEL, A.NAICS, A.STATE; 

/*NON NUMBER VALUES ARE a,b,c,e,f,g,h,i,j,k, and ''*/ 
CREATE TABLE EMPFLAGS2012 AS
SELECT	_2012,
		COUNT(_2012) AS COUNT
FROM ST_EMP3
GROUP BY _2012
ORDER BY _2012 DESC; 

/*FLAGS ARE S, a,b,c,e,f,g,h,i,j, and ''*/ 
CREATE TABLE EMPFLAGS2016 AS
SELECT	_2016,
		COUNT(_2016) AS COUNT
FROM ST_EMP3
GROUP BY _2016
ORDER BY _2016 DESC; 
QUIT; 

/*DELETING ROWS WITHOUT APPROPRIATE 2012 AND 2016 DATA*/ 
/*DECREASES FROM 5268 TO 3810 OBS*/ 
DATA ST_EMP4; 
SET ST_EMP3; 
IF _2012='a' THEN DELETE;
IF _2012='b' THEN DELETE;
IF _2012='c' THEN DELETE;
IF _2012='e' THEN DELETE;
IF _2012='f' THEN DELETE;
IF _2012='g' THEN DELETE;
IF _2012='h' THEN DELETE;
IF _2012='i' THEN DELETE;
IF _2012='j' THEN DELETE;
IF _2012='k' THEN DELETE;
IF _2012='' THEN DELETE;

IF _2016='S' THEN DELETE; 
IF _2016='a' THEN DELETE; 
IF _2016='b' THEN DELETE; 
IF _2016='c' THEN DELETE; 
IF _2016='e' THEN DELETE; 
IF _2016='f' THEN DELETE; 
IF _2016='g' THEN DELETE; 
IF _2016='h' THEN DELETE; 
IF _2016='i' THEN DELETE; 
IF _2016='j' THEN DELETE; 
IF _2016='' THEN DELETE; 


RUN; 

/*looks good*/ 

/*LASTLY, MAKING A DATASET THAT IS SIMPLY THE 2016 DATA FOR ALL FOUR VARIABLES JUST IN CASE WE NEED IT*/ 

PROC SQL NOPRINT; 

/*5182*/ 
CREATE TABLE AS2016ONLY AS
SELECT	*
FROM AS5YEARS
WHERE YEAR EQ 2016; 

/*FLAGS ARE S AND D*/ 
CREATE TABLE RCPTOTFLAGS AS
SELECT	RCPTOT,
		COUNT(RCPTOT) AS COUNT
FROM AS2016ONLY 
GROUP BY RCPTOT
ORDER BY RCPTOT DESC; 

/*FLAGS ARE S AND D*/ 
CREATE TABLE CSTMTOTFLAGS AS
SELECT	CSTMTOT,
		COUNT(CSTMTOT) AS COUNT
FROM AS2016ONLY 
GROUP BY CSTMTOT
ORDER BY CSTMTOT DESC; 

/*FLAGS ARE S AND D*/ 
CREATE TABLE PAYANNFLAGS AS 
SELECT	PAYANN,
		COUNT(PAYANN) AS COUNT
FROM AS2016ONLY
GROUP BY PAYANN
ORDER BY PAYANN DESC; 

/*FLAGS ARE S,a,b,c,e,f,g,h,i,j*/ 
CREATE TABLE EMPFLAGS AS
SELECT	EMP,
		COUNT(EMP) AS COUNT
FROM AS2016ONLY
GROUP BY EMP
ORDER BY EMP DESC; 

/*DELETING ROWS WITH SUPPRESSIONS*/ 
/*GOES FROM 5182 TO 3383 ROWS*/ 
DATA AS2016ONLY_NEW;
SET AS2016ONLY; 
IF RCPTOT EQ 'S' THEN DELETE; 
IF RCPTOT EQ 'D' THEN DELETE; 
IF CSTMTOT EQ 'S' THEN DELETE; 
IF CSTMTOT EQ 'D' THEN DELETE; 
IF PAYANN EQ 'S' THEN DELETE; 
IF PAYANN EQ 'D' THEN DELETE; 
IF EMP EQ 'S' THEN DELETE; 
IF EMP EQ 'a' THEN DELETE; 
IF EMP EQ 'b' THEN DELETE; 
IF EMP EQ 'c' THEN DELETE; 
IF EMP EQ 'e' THEN DELETE; 
IF EMP EQ 'f' THEN DELETE; 
IF EMP EQ 'g' THEN DELETE; 
IF EMP EQ 'h' THEN DELETE; 
IF EMP EQ 'i' THEN DELETE; 
IF EMP EQ 'j' THEN DELETE; 
RUN; 



