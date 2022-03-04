set global local_infile=true;
SET SQL_SAFE_UPDATES = 0;
LOAD DATA INFILE
"C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/BaltimoreCrimeData.csv"
INTO TABLE crimedata
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

CREATE TABLE crimedata (
CrimeDate VARCHAR(100),
CrimeTime VARCHAR(100),
CrimeCode VARCHAR(100),
Location VARCHAR(100),
Description VARCHAR(100),
InsideOutside VARCHAR(100),
Weapon VARCHAR(100),
PostalCode VARCHAR(100),
District VARCHAR(100),
Neighborhood VARCHAR(100),
LocationLatLong VARCHAR(100),
TotalIncidents VARCHAR(100)
);

DROP TABLE crimedata;

-- Explore Data
SELECT * FROM crimedata;

-- Clear Up/Specify Zipcode
UPDATE crimedata
SET PostalCode = CONCAT(21, PostalCode);

-- Clean up Spelling Errors and Wrong District
SELECT COUNT(DISTINCT Neighborhood) FROM crimedata;
SELECT COUNT(DISTINCT District) FROM crimedata;

SELECT DISTINCT District FROM crimedata ORDER BY District ASC;

SELECT District, COUNT(District) FROM crimedata
WHERE District LIKE '%South%'
GROUP BY District;

SELECT District, COUNT(District) FROM crimedata
WHERE District LIKE '%North%'
GROUP BY District;

UPDATE crimedata
SET District = 'SOUTHWESTERN'
WHERE District LIKE '%Southw%';

UPDATE crimedata
SET District = 'SOUTHEASTERN'
WHERE District LIKE '%Southes%';

UPDATE crimedata
SET District = 'NORTHEASTERN'
WHERE District LIKE '%Northes%';

UPDATE crimedata
SET District = 'EASTERN'
WHERE District LIKE 'Gay Street';

-- Convert CrimeTime From String to Time
SELECT CONVERT(CrimeTime, TIME), CrimeCode, Location from crimedata;

SELECT CrimeTime, CrimeCode FROM crimedata;

ALTER TABLE crimedata MODIFY CrimeTime TIME;

UPDATE crimedata
SET CrimeTime = CONVERT(CrimeTime, TIME);

-- Convert CrimeData from String to Data
SELECT STR_TO_DATE(CrimeDate, '%m/%d/%Y') FROM crimedata;

UPDATE crimedata
SET CrimeDate = STR_TO_DATE(CrimeDate, '%m/%d/%Y');

ALTER TABLE crimedata MODIFY CrimeDate DATE;

SELECT * FROM crimedata;
SELECT CrimeDate FROM crimedata;

-- Explore Data: What Seasons and Months do Crime Occur the most?
CREATE VIEW CrimeByMonth AS
SELECT MONTHNAME(CrimeDate) as Crime_Month, AVG(COUNT(Description)) as CrimeCount FROM crimedata
GROUP BY MONTHNAME(CrimeDate)
ORDER BY CrimeCount DESC;

CREATE VIEW CrimeByMonthYear AS
SELECT CONCAT(MONTHNAME(CrimeDate), ', ', YEAR(CrimeDate)) as CrimeMonthYear, COUNT(Description) as NumberOfIncidents from crimedata
GROUP BY CONCAT(MONTHNAME(CrimeDate), ', ', YEAR(CrimeDate));


-- Explore Data: What crime(s) are commited the most?
CREATE VIEW CrimeByOccurence AS
SELECT Description, COUNT(Description) as COUNT from crimedata
GROUP BY Description
ORDER BY COUNT DESC;

-- Explore Data: Which Districts Commit the most Homicides or Shootings?
CREATE VIEW CrimeByDistrict AS
SELECT District, COUNT(Description) as MurderAndShooting_Count FROM crimedata
WHERE Description LIKE 'Shooting' OR Description LIKE 'Homicide'
GROUP BY District
ORDER BY MurderANDShooting_Count DESC;

-- Explore Data: Which Postal Codes are the safest to live in? Which Postal Codes are the most dangerous?
SELECT PostalCode, COUNT(PostalCode) FROM crimedata
GROUP BY PostalCode;

Create view SafeDangerousZipCodes AS
SELECT PostalCode, COUNT(PostalCode) as NumberOfIncidents From crimedata
WHERE char_length(PostalCode) = 5 AND PostalCode NOT LIKE '%.%'
GROUP BY PostalCode
ORDER BY NumberOfIncidents ASC;

SELECT * FROM Crimedata;
SELECT Distinct(Weapon) from crimedata
WHERE Weapon NOT LIKE ''
GROUP BY Weapon;

CREATE VIEW IncidentsPerNeighborhood AS
SELECT DISTINCT(Neighborhood), COUNT(Description) as NumberOfIncidents FROM crimedata
WHERE Neighborhood NOT LIKE '' AND Neighborhood NOT LIKE 'Eastern' AND Neighborhood NOT LIKE 'NORTHEASTERN'
GROUP BY Neighborhood
ORDER BY NumberOfIncidents;