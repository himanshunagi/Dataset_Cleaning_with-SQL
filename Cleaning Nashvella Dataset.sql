#Cleaning Data in SQL Queries

Select *
From `Cleaning.Housing`

#Standardize Date Format

-- Step 1: Create a new column
ALTER TABLE `Cleaning.Housing`
ADD COLUMN SaleDateConverted DATE;

-- Step 2: Update the new column with converted dates
UPDATE `Cleaning.Housing`
SET SaleDateConverted = PARSE_DATE('%B %d, %Y', SaleDate);

-- Step 3: Create a new table with the desired schema
CREATE TABLE `Cleaning.Housing_temp`
AS SELECT *, FORMAT_DATE('%m/%d/%Y', SaleDateConverted) AS SaleDateConverted
FROM `Cleaning.Housing`;

-- Step 4: Delete the original table
DROP TABLE `Cleaning.Housing`;

-- Step 5: Rename the new table to the original table name
ALTER TABLE `Cleaning.Housing_temp`
RENAME TO `Cleaning.Housing`;

#Populate Property Address data

Select *
From `Cleaning.Housing`
--Where PropertyAddress is null
order by ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IFNULL(a.PropertyAddress, b.PropertyAddress) AS MergedPropertyAddress
FROM `Cleaning.Housing` a
JOIN `Cleaning.Housing` b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID_ <> b.UniqueID_
WHERE a.PropertyAddress IS NULL;

Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM `Cleaning.Housing` a
JOIN `Cleaning.Housing` b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID_ <> b.UniqueID_
WHERE a.PropertyAddress IS NULL;

#Breaking out Address into Individual Columns (Address, City, State)

Select PropertyAddress
From `Cleaning.Housing`
--Where PropertyAddress is null
--order by ParcelID

SELECT
SUBSTR(PropertyAddress, 1, STRPOS(PropertyAddress, ',') - 1) AS Address,
SUBSTR(PropertyAddress, STRPOS(PropertyAddress, ',') + 1) AS Address2
FROM `Cleaning.Housing`;

ALTER TABLE `Cleaning.Housing`
ADD COLUMN PropertySplitAddress STRING;

UPDATE `Cleaning.Housing`
SET PropertySplitAddress = SUBSTR(PropertyAddress, 1, STRPOS(PropertyAddress, ',') - 1);

ALTER TABLE `Cleaning.Housing`
ADD COLUMN PropertySplitCity STRING;

UPDATE `Cleaning.Housing`
SET PropertySplitCity = SUBSTR(PropertyAddress, STRPOS(PropertyAddress, ',') + 1);

Select OwnerAddress
FROM `Cleaning.Housing`

SELECT
  SPLIT(OwnerAddress, ',')[ORDINAL(3)] AS AddressPart3,
  SPLIT(OwnerAddress, ',')[ORDINAL(2)] AS AddressPart2,
  SPLIT(OwnerAddress, ',')[ORDINAL(1)] AS AddressPart1
FROM `Cleaning.Housing`;

-- Add OwnerSplitAddress column
ALTER TABLE `Cleaning.Housing`
ADD COLUMN OwnerSplitAddress STRING;

-- Update OwnerSplitAddress with parsed address part 3
UPDATE `Cleaning.Housing`
SET OwnerSplitAddress = SPLIT(REPLACE(OwnerAddress, ',', '.'), '.')[SAFE_OFFSET(3)];

-- Add OwnerSplitCity column
ALTER TABLE `Cleaning.Housing`
ADD COLUMN OwnerSplitCity STRING;

-- Update OwnerSplitCity with parsed address part 2
UPDATE `Cleaning.Housing`
SET OwnerSplitCity = SPLIT(REPLACE(OwnerAddress, ',', '.'), '.')[SAFE_OFFSET(2)];

-- Add OwnerSplitState column
ALTER TABLE `Cleaning.Housing`
ADD COLUMN OwnerSplitState STRING;

-- Update OwnerSplitState with parsed address part 1
UPDATE `Cleaning.Housing`
SET OwnerSplitState = SPLIT(REPLACE(OwnerAddress, ',', '.'), '.')[SAFE_OFFSET(1)];


#Change Y and N to Yes and No in "Sold as Vacant" field

SELECT SoldAsVacant, COUNT(SoldAsVacant) AS Count
FROM `Cleaning.Housing`
GROUP BY SoldAsVacant
ORDER BY Count;

SELECT SoldAsVacant,
       IF(SoldAsVacant, 'Yes', 'No') AS SoldAsVacantModified
FROM `Cleaning.Housing`;

UPDATE `Cleaning.Housing`
SET SoldAsVacant = CASE 
                      WHEN SoldAsVacant THEN true
                      ELSE false
                   END;


#Remove Duplicates

WITH RowNumCTE AS (
  SELECT *,
    ROW_NUMBER() OVER (
      PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
      ORDER BY UniqueID_
    ) AS row_num
  FROM `Cleaning.Housing`
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

#Delete Unused Columns

-- Create a new table with the desired schema
CREATE TABLE `Cleaning.Housing_New`
(
  -- List all columns except the columns to be dropped
  Column1 STRING,
  Column2 INT64,
  Column3 FLOAT64,
  -- ... add other columns as needed
)
OPTIONS(
  'description', 'New table with updated schema'
);

-- Copy data from the old table to the new table
INSERT INTO `Cleaning.Housing_New` 
SELECT 
  Column1,
  Column2,
  Column3,
  -- ... copy other columns as needed
FROM `Cleaning.Housing`;

-- Delete the old table
DROP TABLE `Cleaning.Housing`;

-- Rename the new table to the original table name
ALTER TABLE `Cleaning.Housing`
SET OPTIONS (
  description = 'Cleaned'
);
