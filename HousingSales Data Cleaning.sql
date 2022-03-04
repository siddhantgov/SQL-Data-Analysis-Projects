-- Create table to import CSV file
CREATE TABLE housing_data (
	UniqueID INT,
    ParcelID VARCHAR(100),
    LandUse VARCHAR(100),
    PropertyAddress VARCHAR (100),
    SaleDate VARCHAR(100),
    SalePrice VARCHAR(100),
    LegalReference VARCHAR(100),
    SoldAsVacant VARCHAR(10),
    OwnerName VARCHAR(100),
    OwnerAddress VARCHAR(100),
    Acreage VARCHAR(100),
    TaxDistrict VARCHAR(100),
    LandValue VARCHAR(100),
    BuildingValue VARCHAR(100),
    TotalValue VARCHAR(100),
    YearBuilt VARCHAR(100),
    Bedrooms VARCHAR(100),
    FullBathrooms VARCHAR(100),
    HalfBathrooms VARCHAR(100)
    );

-- In case we need to remake table due to warnings and errors
DROP TABLE housing_data;

-- Allow table alterations without key
SET SQL_SAFE_UPDATES = 0;

-- Allow mySQL Workbench to load in local files
show global variables like 'local_infile';
set global local_infile=true;


-- Load CSV file into mySQL table
LOAD DATA INFILE
"C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Nashville Housing Data for Data Cleaning.csv"
INTO TABLE housing_data
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- Browse and explore table data
SELECT * FROM housing_data;


-- Change Sale Date Into Proper Date Format
SELECT STR_TO_DATE(SaleDate, '%M %d, %Y') as SaleDate from housing_data;

UPDATE housing_data
SET SaleDate = STR_TO_DATE(SaleDate, '%M %d, %Y');

SELECT SaleDate FROM housing_data;

-- Fix Null Property Address
UPDATE housing_data
SET PropertyAddress=NULL
WHERE PropertyAddress LIKE '';

SELECT * FROM housing_data
WHERE PropertyAddress IS NULL;

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IFNULL(a.PropertyAddress, b.PropertyAddress)
FROM housing_data a 
JOIN housing_data b
on a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;


-- Temp Table
CREATE TABLE housing_temp (
UniqueID2 INT,
ParcelID2 VARCHAR(100),
PropertyAddress2 VARCHAR(100)
);

DROP TABLE housing_temp;

INSERT INTO housing_temp(UniqueID2, ParcelID2, PropertyAddress2) SELECT UniqueID, ParcelID, PropertyAddress FROM housing_data;

-- Temp Table 2
CREATE TABLE housing_temp2(
ParcelID3 VARCHAR(100),
PropertyAddress3 VARCHAR(100)
);

DROP TABLE housing_temp2;

INSERT INTO housing_temp2(ParcelID3, PropertyAddress3) SELECT ParcelID2, PropertyAddress2 FROM
housing_data join housing_temp
ON ParcelID = ParcelID2
AND UniqueID <> UniqueID2
WHERE PropertyAddress IS NULL;

-- Get the Data We Need For Temp Table Above
SELECT ParcelID, PropertyAddress, ParcelID2, PropertyAddress2 FROM
housing_data join housing_temp
ON ParcelID = ParcelID2
AND UniqueID <> UniqueID2
WHERE PropertyAddress IS NULL;

UPDATE housing_data
SET PropertyAddress = (SELECT PropertyAddress2 FROM
housing_temp join housing_
ON ParcelID = ParcelID2
AND UniqueID <> UniqueID2
WHERE PropertyAddress IS NULL);


-- Finalize Property Address Fixes
UPDATE housing_data
INNER JOIN housing_temp2 on housing_data.ParcelID = housing_temp2.ParcelID3
SET housing_data.PropertyAddress = housing_temp2.PropertyAddress3;


-- Breaking Address Into Individual Columns Address, City, State
Select PropertyAddress FROM housing_data;

-- Check Splice Address into City and Street Address
SELECT SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress)-1) as ADDRESS FROM housing_data;
SELECT SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress)+1, length(PropertyAddress)) as City FROM housing_data;

-- Make Table To Copy Data (mySQL does not allow copy from same table join)
CREATE TABLE StreetTemp(
StreetAddress VARCHAR(100),
City VARCHAR(100),
PropertyAddress VARCHAR(100)
);

CREATE TABLE StateTemp(
PropertyAddress VARCHAR(100),
OwnerStreet VARCHAR(100),
OwnerCity VARCHAR(100),
OwnerState VARCHAR(100)
);

DROP TABLE StateTemp;
-- Insert Splice Address into Seperate Table
INSERT INTO StreetTemp(StreetAddress, City, PropertyAddress) SELECT SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress)-1), 
SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress)+1, length(PropertyAddress)), PropertyAddress FROM housing_data;
INSERT INTO StreetTemp(PropertyAddress) SELECT PropertyAddress FROM housing_data;

INSERT INTO StateTemp(PropertyAddress, State) SELECT PropertyAddress FROM housing_data;

-- Check tables to make sure data is clean, no errors
SELECT * FROM housing_data;
SELECT * FROM StreetTemp;


-- Add columns on original/main table to copy StreetAddress and City too
ALTER TABLE housing_data
ADD COLUMN StreetAddress VARCHAR(100);

ALTER TABLE housing_data
ADD COLUMN City VARCHAR(100);

SET SQL_SAFE_UPDATES = 0;

UPDATE housing_data set housing_data.StreetAddress = (
SELECT streettemp.StreetAddress
FROM StreetTemp INNER JOIN housing_data ON Streettemp.PropertyAddress = housing_data.PropertyAddress);

-- Create index (table had none) on PropertyAddress column to speed up execution
CREATE INDEX tracker on housing_data(PropertyAddress);
DROP INDEX tracker2 on housing_data;

-- Finalize/Execute the copy from StreetTemp table to Housing_Data table

UPDATE housing_data
INNER JOIN streettemp on streettemp.PropertyAddress= housing_data.PropertyAddress
SET housing_data.StreetAddress = StreetTemp.StreetAddress;

UPDATE housing_data
INNER JOIN streettemp on streettemp.PropertyAddress= housing_data.PropertyAddress
SET housing_data.City = StreetTemp.City;



SELECT * FROM statetemp;
SELECT * FROM housing_data;

-- Add new columns to housing_data to store information being copied
ALTER TABLE housing_data
ADD COLUMN OwnerStreet VARCHAR(100);

ALTER TABLE housing_data
ADD COLUMN OwnerCity VARCHAR(100);

ALTER TABLE housing_data
ADD COLUMN OwnerState VARCHAR(100);

SELECT PropertyAddress FROM housing_data;

-- Insert Spliced Street, City, State from OWNER Address Into Temp Table
INSERT INTO StateTemp(PropertyAddress,OwnerStreet,OwnerCity,OwnerState) SELECT PropertyAddress, SUBSTRING(OwnerAddress, 1, LOCATE(',', OwnerAddress)-1), 
SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',',1), SUBSTRING(OwnerAddress, LENGTH(OwnerAddress)-2) FROM housing_data;

-- Copy Seperated Street,City,State into housing_data table
SELECT OwnerAddress from housing_data;
UPDATE housing_data
INNER JOIN StateTemp on statetemp.PropertyAddress = housing_data.PropertyAddress
SET housing_data.OwnerStreet = statetemp.OwnerStreet,
housing_data.OwnerCity = statetemp.OwnerCity,
housing_data.OwnerState = statetemp.OwnerState;

UPDATE housing_data
SET SoldAsVacant = 'Yes'
WHERE SoldAsVacant LIKE 'Y';

UPDATE housing_data
SET SoldAsVacant = 'No'
WHERE SoldAsVacant = 'N';

SELECT Distinct(SoldAsVacant), count(SoldAsVacant) 
FROM housing_data
GROUP BY SoldAsVacant;

-- Remove Duplicates (not recommended to practice)
-- Using CTE, RowNumber and Partition By
WITH RowNumCTE AS (
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY ParcelID,
			 PropertyAddress,
             SalePrice,
             SaleDate,
             LegalReference
             ORDER BY 
					UniqueID
                    )
						row_num
                        FROM housing_data
)
-- mySQL requires delete to be used on actual table and not CTE!
-- DELETE FROM housing_data USING housing_data JOIN RowNumCTE on housing_data.ParcelID = RowNumCte.ParcelID
-- SELECT * FROM RowNumCTE
SELECT * FROM RowNumCTE
WHERE row_num > 1;

-- Delete Unused Columns
ALTER TABLE housing_data
DROP COLUMN PropertyAddress,
DROP COLUMN OwnerAddress;

