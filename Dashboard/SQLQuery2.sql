USE ABC_Inventory_Analytics;
GO

DROP TABLE IF EXISTS clean.RetailSales;
GO

SELECT
    IDENTITY(BIGINT, 1, 1) AS SalesRowID,

    Transaction_Date AS TransactionDate,
    NULLIF(LTRIM(RTRIM(Sales_Type)), '') AS SalesType,
    Is_Return AS IsReturn,
    NULLIF(LTRIM(RTRIM(Reason_of_Return)), '') AS ReturnReason,
    NULLIF(LTRIM(RTRIM(Supplier)), '') AS Supplier,
    NULLIF(LTRIM(RTRIM(Product_No)), '') AS ProductNo,
    NULLIF(LTRIM(RTRIM(Product_Description)), '') AS ProductDescription,
    NULLIF(LTRIM(RTRIM(Product_Division)), '') AS ProductDivision,
    NULLIF(LTRIM(RTRIM(Product_Category)), '') AS ProductCategory,
    NULLIF(LTRIM(RTRIM(Product_Subcategory)), '') AS ProductSubcategory,
    NULLIF(LTRIM(RTRIM(Product_Segment)), '') AS ProductSegment,
    NULLIF(LTRIM(RTRIM(Store)), '') AS Store,
    NULLIF(LTRIM(RTRIM(Sales_Channel)), '') AS SalesChannel,

    CAST(Qty_Sold AS INT) AS QuantitySold,
    CAST(Sales_Amount AS DECIMAL(18,2)) AS SalesAmount,
    CAST(Cogs AS DECIMAL(18,2)) AS COGS,
    CAST(Number_of_Transactions AS INT) AS NumberOfTransactions

INTO clean.RetailSales
FROM dbo.Retail_Sales;
GO

DROP TABLE IF EXISTS clean.RetailInventory;
GO

SELECT
    IDENTITY(BIGINT, 1, 1) AS InventoryRowID,

    Start_Date AS StartDate,
    End_Date AS EndDate,

    CASE
        WHEN End_Date = '9999-12-31' THEN 1
        ELSE 0
    END AS IsOpenEnded,

    NULLIF(LTRIM(RTRIM(Stock_Status)), '') AS StockStatus,
    NULLIF(LTRIM(RTRIM(Supplier)), '') AS Supplier,
    NULLIF(LTRIM(RTRIM(Product_No)), '') AS ProductNo,
    NULLIF(LTRIM(RTRIM(Product_Description)), '') AS ProductDescription,
    NULLIF(LTRIM(RTRIM(Product_Division)), '') AS ProductDivision,
    NULLIF(LTRIM(RTRIM(Product_Category)), '') AS ProductCategory,
    NULLIF(LTRIM(RTRIM(Product_Subcategory)), '') AS ProductSubcategory,
    NULLIF(LTRIM(RTRIM(Product_Segment)), '') AS ProductSegment,
    NULLIF(LTRIM(RTRIM(Store)), '') AS Store,
    NULLIF(LTRIM(RTRIM(Store_Type)), '') AS StoreType,
    NULLIF(LTRIM(RTRIM(Sales_Channel)), '') AS SalesChannel,

    CAST(Qty_on_hand AS INT) AS QuantityOnHand,

    TRY_CONVERT(DECIMAL(18,2), Stocks_Selling_Amount) AS StockSellingAmount,
    TRY_CONVERT(DECIMAL(18,2), Cost_of_Stocks) AS CostOfStocks,
    TRY_CONVERT(DECIMAL(18,4), Stock_Unit_Selling_Price) AS StockUnitSellingPrice,
    TRY_CONVERT(DECIMAL(18,4), Stock_Unit_Cost_Price) AS StockUnitCostPrice

INTO clean.RetailInventory
FROM dbo.Retail_Inventory;
GO

SELECT
    'Raw Sales' AS TableName,
    COUNT(*) AS TotalRows
FROM dbo.Retail_Sales

UNION ALL

SELECT
    'Clean Sales',
    COUNT(*)
FROM clean.RetailSales

UNION ALL

SELECT
    'Raw Inventory',
    COUNT(*)
FROM dbo.Retail_Inventory

UNION ALL

SELECT
    'Clean Inventory',
    COUNT(*)
FROM clean.RetailInventory;

SELECT TOP 10 *
FROM clean.RetailSales;

SELECT TOP 10 *
FROM clean.RetailInventory;