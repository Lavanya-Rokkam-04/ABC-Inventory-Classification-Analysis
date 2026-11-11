-- Data Cleaning and Validation
-- CHECK FOR NULL VALUES


SELECT
    COUNT(*) AS TotalRows,

    SUM(CASE WHEN Start_Date IS NULL THEN 1 ELSE 0 END) AS Missing_Start_Date,
    SUM(CASE WHEN End_Date IS NULL THEN 1 ELSE 0 END) AS Missing_End_Date,
    SUM(CASE WHEN Stock_Status IS NULL THEN 1 ELSE 0 END) AS Missing_Stock_Status,
    SUM(CASE WHEN Supplier IS NULL THEN 1 ELSE 0 END) AS Missing_Supplier,
    SUM(CASE WHEN Product_No IS NULL THEN 1 ELSE 0 END) AS Missing_Product_No,
    SUM(CASE WHEN Product_Description IS NULL THEN 1 ELSE 0 END) AS Missing_Product_Description,
    SUM(CASE WHEN Product_Division IS NULL THEN 1 ELSE 0 END) AS Missing_Product_Division,
    SUM(CASE WHEN Product_Category IS NULL THEN 1 ELSE 0 END) AS Missing_Product_Category,
    SUM(CASE WHEN Product_Subcategory IS NULL THEN 1 ELSE 0 END) AS Missing_Product_Subcategory,
    SUM(CASE WHEN Product_Segment IS NULL THEN 1 ELSE 0 END) AS Missing_Product_Segment,
    SUM(CASE WHEN Store IS NULL THEN 1 ELSE 0 END) AS Missing_Store,
    SUM(CASE WHEN Store_Type IS NULL THEN 1 ELSE 0 END) AS Missing_Store_Type,
    SUM(CASE WHEN Sales_Channel IS NULL THEN 1 ELSE 0 END) AS Missing_Sales_Channel,
    SUM(CASE WHEN Qty_on_hand IS NULL THEN 1 ELSE 0 END) AS Missing_Qty_on_hand,
    SUM(CASE WHEN Stocks_Selling_Amount IS NULL THEN 1 ELSE 0 END) AS Missing_Stocks_Selling_Amount,
    SUM(CASE WHEN Cost_of_Stocks IS NULL THEN 1 ELSE 0 END) AS Missing_Cost_of_Stocks,
    SUM(CASE WHEN Stock_Unit_Selling_Price IS NULL THEN 1 ELSE 0 END) AS Missing_Unit_Selling_Price,
    SUM(CASE WHEN Stock_Unit_Cost_Price IS NULL THEN 1 ELSE 0 END) AS Missing_Unit_Cost_Price

FROM dbo.Retail_Inventory;

-- CHECK FOR BLANK TEXT VALUES

SELECT
    SUM(CASE WHEN LTRIM(RTRIM(Stock_Status)) = '' THEN 1 ELSE 0 END) AS Blank_Stock_Status,
    SUM(CASE WHEN LTRIM(RTRIM(Supplier)) = '' THEN 1 ELSE 0 END) AS Blank_Supplier,
    SUM(CASE WHEN LTRIM(RTRIM(Product_No)) = '' THEN 1 ELSE 0 END) AS Blank_Product_No,
    SUM(CASE WHEN LTRIM(RTRIM(Product_Description)) = '' THEN 1 ELSE 0 END) AS Blank_Product_Description,
    SUM(CASE WHEN LTRIM(RTRIM(Product_Category)) = '' THEN 1 ELSE 0 END) AS Blank_Product_Category,
    SUM(CASE WHEN LTRIM(RTRIM(Store)) = '' THEN 1 ELSE 0 END) AS Blank_Store,
    SUM(CASE WHEN LTRIM(RTRIM(Sales_Channel)) = '' THEN 1 ELSE 0 END) AS Blank_Sales_Channel
FROM dbo.Retail_Inventory;

-- CHECK NEGATIVE AND ZERO STOCK

SELECT
    COUNT(*) AS Total_Rows,
    SUM(CASE WHEN Qty_on_hand < 0 THEN 1 ELSE 0 END) AS Negative_Stock_Rows,
    SUM(CASE WHEN Qty_on_hand = 0 THEN 1 ELSE 0 END) AS Zero_Stock_Rows,
    SUM(CASE WHEN Qty_on_hand > 0 THEN 1 ELSE 0 END) AS Positive_Stock_Rows
FROM dbo.Retail_Inventory;

-- CHECK THE DATA RANGE

SELECT
    MIN(Start_Date) AS Earliest_Start_Date,
    MAX(Start_Date) AS Latest_Start_Date,
    MIN(End_Date) AS Earliest_End_Date,
    MAX(End_Date) AS Latest_End_Date
FROM dbo.Retail_Inventory;

-- INVESTIGATE NEGATIVE STOCK RECORDS
SELECT TOP 50
    Start_Date,
    End_Date,
    Stock_Status,
    Product_No,
    Product_Description,
    Product_Category,
    Store,
    Qty_on_hand,
    Cost_of_Stocks,
    Stock_Unit_Cost_Price
FROM dbo.Retail_Inventory
WHERE Qty_on_hand < 0
ORDER BY Qty_on_hand ASC;

-- CHECK THE INVENTORY SNAPSHOT

DECLARE @SnapshotDate DATE = '2026-04-24';

SELECT
    COUNT(*) AS Active_Inventory_Rows,
    COUNT(DISTINCT Product_No) AS Active_Products,
    COUNT(DISTINCT Store) AS Active_Stores
FROM dbo.Retail_Inventory
WHERE Start_Date <= @SnapshotDate
  AND End_Date >= @SnapshotDate;

-- check whether multiple records are active for the same product and store
DECLARE @SnapshotDate DATE = '2026-04-24';

SELECT
    Product_No,
    Store,
    COUNT(*) AS Active_Records
FROM dbo.Retail_Inventory
WHERE Start_Date <= @SnapshotDate
  AND End_Date >= @SnapshotDate
GROUP BY Product_No, Store
HAVING COUNT(*) > 1
ORDER BY Active_Records DESC;

