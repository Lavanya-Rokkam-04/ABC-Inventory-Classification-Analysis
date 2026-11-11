USE ABC_Inventory_Analytics;
GO

-- View 6: Negative Stock Exceptions
-- Purpose: Identify products with negative stock
-- for inventory monitoring and Power BI reporting.
-- Snapshot date: 24 April 2026.

CREATE OR ALTER VIEW analysis.vw_Negative_Stock_Exceptions
AS
SELECT
    I.InventoryRowID,
    I.Store,
    I.ProductNo,
    I.ProductDescription,
    I.ProductCategory,
    I.ProductSubcategory,
    I.ProductSegment,
    COALESCE(A.ABCClass, 'Unclassified') AS ABCClass,
    I.QuantityOnHand,
    I.CostOfStocks,
    I.StockUnitCostPrice,
    I.StockStatus,
    I.Supplier
FROM analysis.vw_Inventory_Snapshot I
LEFT JOIN analysis.vw_ABC_Classification A
    ON I.ProductNo = A.ProductNo
WHERE I.QuantityOnHand < 0;
GO

--Check 1 — Overall negative stock exceptions
SELECT
    COUNT(*) AS NegativeStockRecords,
    COUNT(DISTINCT ProductNo) AS AffectedProducts,
    COUNT(DISTINCT Store) AS AffectedStores,
    SUM(QuantityOnHand) AS TotalNegativeStockQuantity,
    SUM(CostOfStocks) AS NegativeInventoryCostValue
FROM analysis.vw_Negative_Stock_Exceptions;

--Check 2 — Negative stock by ABC class
SELECT
    ABCClass,
    COUNT(*) AS NegativeStockRecords,
    COUNT(DISTINCT ProductNo) AS AffectedProducts,
    SUM(QuantityOnHand) AS TotalNegativeStockQuantity,
    SUM(CostOfStocks) AS NegativeInventoryCostValue
FROM analysis.vw_Negative_Stock_Exceptions
GROUP BY ABCClass
ORDER BY
    CASE ABCClass
        WHEN 'A' THEN 1
        WHEN 'B' THEN 2
        WHEN 'C' THEN 3
        ELSE 4
    END;

--Check 3 — Review individual exceptions
SELECT TOP 20
    Store,
    ProductNo,
    ProductDescription,
    ProductCategory,
    ABCClass,
    QuantityOnHand,
    CostOfStocks,
    StockUnitCostPrice,
    StockStatus
FROM analysis.vw_Negative_Stock_Exceptions
ORDER BY QuantityOnHand ASC, Store, ProductNo;