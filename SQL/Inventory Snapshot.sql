USE ABC_Inventory_Analytics;
GO

-- View 4: Inventory Snapshot
-- Purpose: Provide active inventory records
-- as of 24 April 2026 for Power BI.

CREATE OR ALTER VIEW analysis.vw_Inventory_Snapshot
AS
SELECT
    InventoryRowID,
    StartDate,
    EndDate,
    IsOpenEnded,
    StockStatus,
    Supplier,
    ProductNo,
    ProductDescription,
    ProductDivision,
    ProductCategory,
    ProductSubcategory,
    ProductSegment,
    Store,
    StoreType,
    SalesChannel,
    QuantityOnHand,
    StockSellingAmount,
    CostOfStocks,
    StockUnitSellingPrice,
    StockUnitCostPrice
FROM clean.RetailInventory
WHERE
    StartDate <= '2026-04-24'
    AND EndDate >= '2026-04-24';
GO

--Check 1 — Overall inventory position
SELECT
    COUNT(*) AS InventoryRecords,
    COUNT(DISTINCT ProductNo) AS UniqueProducts,
    COUNT(DISTINCT Store) AS UniqueStores,
    SUM(QuantityOnHand) AS TotalStockQuantity,
    SUM(CostOfStocks) AS TotalInventoryCostValue,
    SUM(StockSellingAmount) AS TotalInventorySellingValue
FROM analysis.vw_Inventory_Snapshot;

--Check 2 — Stock status breakdown
SELECT
    CASE
        WHEN QuantityOnHand > 0 THEN 'Positive Stock'
        WHEN QuantityOnHand = 0 THEN 'Zero Stock'
        ELSE 'Negative Stock'
    END AS StockPosition,
    COUNT(*) AS InventoryRecords,
    SUM(QuantityOnHand) AS TotalQuantity,
    SUM(CostOfStocks) AS InventoryCostValue
FROM analysis.vw_Inventory_Snapshot
GROUP BY
    CASE
        WHEN QuantityOnHand > 0 THEN 'Positive Stock'
        WHEN QuantityOnHand = 0 THEN 'Zero Stock'
        ELSE 'Negative Stock'
    END
ORDER BY StockPosition;