USE ABC_Inventory_Analytics;
GO

-- View 5: Inventory by ABC Classification
-- Purpose: Summarize inventory position by ABC class.
-- Snapshot date: 24 April 2026.

CREATE OR ALTER VIEW analysis.vw_Inventory_By_ABC
AS
WITH InventorySummary AS
(
    SELECT
        COALESCE(A.ABCClass, 'Unclassified') AS ABCClass,

        COUNT(*) AS InventoryRecords,
        COUNT(DISTINCT I.ProductNo) AS ProductCount,

        SUM(I.QuantityOnHand) AS TotalStockQuantity,
        SUM(I.CostOfStocks) AS InventoryCostValue,
        SUM(I.StockSellingAmount) AS InventorySellingValue

    FROM analysis.vw_Inventory_Snapshot I

    LEFT JOIN analysis.vw_ABC_Classification A
        ON I.ProductNo = A.ProductNo

    GROUP BY
        COALESCE(A.ABCClass, 'Unclassified')
)
SELECT
    ABCClass,
    InventoryRecords,
    ProductCount,
    TotalStockQuantity,
    InventoryCostValue,
    InventorySellingValue,

    CAST(
        InventoryCostValue * 100.0
        / SUM(InventoryCostValue) OVER ()
        AS DECIMAL(10,2)
    ) AS InventoryCostValueShare

FROM InventorySummary;
GO

--Check 1 — Overall totals
SELECT
    SUM(InventoryRecords) AS TotalInventoryRecords,
    SUM(ProductCount) AS TotalProductCounts,
    SUM(TotalStockQuantity) AS TotalStockQuantity,
    SUM(InventoryCostValue) AS TotalInventoryCostValue,
    SUM(InventorySellingValue) AS TotalInventorySellingValue
FROM analysis.vw_Inventory_By_ABC;

--Check 2 — ABC classification summary
SELECT
    ABCClass,
    InventoryRecords,
    ProductCount,
    TotalStockQuantity,
    InventoryCostValue,
    InventorySellingValue,
    InventoryCostValueShare
FROM analysis.vw_Inventory_By_ABC
ORDER BY
    CASE ABCClass
        WHEN 'A' THEN 1
        WHEN 'B' THEN 2
        WHEN 'C' THEN 3
        ELSE 4
    END;