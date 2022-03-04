/*
Cleaning Data in SQL Queries
*/

SELECT *
FROM PortfolioProject..NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------
-- Standardize Date Format
-- KEEPING IT SIMPLE

ALTER TABLE PortfolioProject..NashvilleHousing
ALTER COLUMN SaleDate Date

-- STARTING A TRANSACTION

BEGIN TRAN
ALTER TABLE PortfolioProject..NashvilleHousing
ALTER COLUMN SaleDate Date
SELECT SaleDate FROM PortfolioProject..NashvilleHousing
--ROLLBACK TRAN
COMMIT TRAN

 --------------------------------------------------------------------------------------------------------------------------
-- Populate Property Address data

SELECT *
FROM PortfolioProject..NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID


SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM PortfolioProject..NashvilleHousing A
JOIN PortfolioProject..NashvilleHousing B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress IS NULL


UPDATE A
SET PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM PortfolioProject..NashvilleHousing A
JOIN PortfolioProject..NashvilleHousing B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress IS NULL

--------------------------------------------------------------------------------------------------------------------------
-- Breaking out Address into Individual Columns (Address, City, State)

--   PROPERTY ADDRESS
SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing


SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City
FROM PortfolioProject..NashvilleHousing


ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255),
PropertyCity NVARCHAR(255)


UPDATE PortfolioProject..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1),
	PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))


--   OWNER ADDRESS
SELECT OwnerAddress
FROM PortfolioProject..NashvilleHousing


SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS OwnerSplitAddress,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS OwnerCity,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS OwnerState
FROM PortfolioProject..NashvilleHousing


ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255),
OwnerCity NVARCHAR(255),
OwnerState NVARCHAR(255)


UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

--------------------------------------------------------------------------------------------------------------------------
-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT SoldAsVacant, Count(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant


SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END
FROM PortfolioProject..NashvilleHousing


UPDATE PortfolioProject..NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END

-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remove Duplicates
-- In this case, ROW_NUMBER() and RANK() return the same values.

BEGIN TRAN;
WITH RowNumberCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
		PARTITION BY ParcelID,
					 PropertyAddress,
					 SaleDate,
					 SalePrice,
					 LegalReference
					 ORDER BY UniqueID
					 ) RowNumber
FROM PortfolioProject..NashvilleHousing
)
DELETE
FROM RowNumberCTE
WHERE RowNumber <> 1;
--ROLLBACK TRAN
COMMIT TRAN

---------------------------------------------------------------------------------------------------------
-- Delete Unused Columns (Occasional)
-- Running a transaction beforehand to be certain of the deleted values
-- Unused Columns: PropertyAddress, OwnerAddress and OwnerState (The only state is TN: Tennessee).

BEGIN TRAN
ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, OwnerState
SELECT * FROM PortfolioProject..NashvilleHousing
--ROLLBACK TRAN
COMMIT TRAN