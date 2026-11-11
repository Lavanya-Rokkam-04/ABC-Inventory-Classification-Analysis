/*==============================================================
  INVENTORY POSITION ANALYSIS

  TASK 1: INVENTORY SNAPSHOT VALIDATION

  Snapshot Date: 2026-04-24

  Purpose:
  Identify inventory records active on the snapshot date
  and check whether any ProductNo + Store combinations
  have multiple active records.
==============================================================*/

USE ABC_Inventory_Analytics;
GO

-- Step 1: Count active inventory records

WITH ActiveInventory AS
(
    SELECT *
    FROM clean.RetailInventory
    WHERE StartDate <= '2026-04-24'
      AND EndDate >= '2026-04-24'
)

SELECT
    COUNT(*) AS ActiveInventoryRows,
    COUNT(DISTINCT ProductNo) AS UniqueProducts,
    COUNT(DISTINCT Store) AS UniqueStores,
    COUNT(DISTINCT ProductNo + '|' + Store) AS UniqueProductStoreCombinations
FROM ActiveInventory;


-- Step 2: Check for multiple active records
-- for the same product and store

WITH ActiveInventory AS
(
    SELECT *
    FROM clean.RetailInventory
    WHERE StartDate <= '2026-04-24'
      AND EndDate >= '2026-04-24'
)

SELECT
    ProductNo,
    Store,
    COUNT(*) AS ActiveRecordCount
FROM ActiveInventory
GROUP BY
    ProductNo,
    Store
HAVING COUNT(*) > 1
ORDER BY ActiveRecordCount DESC;

/*==============================================================
  TASK 2: OVERALL INVENTORY POSITION

  Snapshot Date: 2026-04-24

  Purpose:
  Calculate total stock quantity, inventory cost value,
  and the number of products and stores in the snapshot.

  Important:
  Negative stock quantities are retained as recorded.
==============================================================*/

WITH ActiveInventory AS
(
    SELECT *
    FROM clean.RetailInventory
    WHERE StartDate <= '2026-04-24'
      AND EndDate >= '2026-04-24'
)

SELECT
    COUNT(*) AS InventoryRecords,

    COUNT(DISTINCT ProductNo) AS UniqueProducts,

    COUNT(DISTINCT Store) AS UniqueStores,

    SUM(QuantityOnHand) AS TotalStockQuantity,

    SUM(CostOfStocks) AS TotalInventoryCostValue,

    SUM(StockSellingAmount) AS TotalInventorySellingValue,

    SUM(CASE
        WHEN QuantityOnHand > 0 THEN 1
        ELSE 0
    END) AS PositiveStockRecords,

    SUM(CASE
        WHEN QuantityOnHand = 0 THEN 1
        ELSE 0
    END) AS ZeroStockRecords,

    SUM(CASE
        WHEN QuantityOnHand < 0 THEN 1
        ELSE 0
    END) AS NegativeStockRecords

FROM ActiveInventory;

/*==============================================================
  TASK 3: INVENTORY VALUE BY ABC CLASS

  Snapshot Date: 2026-04-24

  Purpose:
  Analyze stock quantity and inventory cost value by
  ABC classification.

  Business Questions:
  1. How much inventory cost value is held in A, B and C?
  2. What percentage of total inventory value belongs
     to each ABC class?
  3. How much stock quantity is held in each class?
  4. Are there inventory products without an ABC classification?
==============================================================*/

WITH ActiveInventory AS
(
    SELECT *
    FROM clean.RetailInventory
    WHERE StartDate <= '2026-04-24'
      AND EndDate >= '2026-04-24'
),

InventoryABC AS
(
    SELECT
        AI.ProductNo,
        AI.QuantityOnHand,
        AI.CostOfStocks,
        AI.StockSellingAmount,
        PA.ABCClass
    FROM ActiveInventory AI
    LEFT JOIN analysis.ProductABC PA
        ON AI.ProductNo = PA.ProductNo
),

ClassSummary AS
(
    SELECT
        COALESCE(ABCClass, 'Unclassified') AS ABCClass,

        COUNT(*) AS InventoryRecords,

        COUNT(DISTINCT ProductNo) AS ProductCount,

        SUM(QuantityOnHand) AS TotalStockQuantity,

        SUM(CostOfStocks) AS InventoryCostValue,

        SUM(StockSellingAmount) AS InventorySellingValue

    FROM InventoryABC
    GROUP BY ABCClass
)

SELECT
    ABCClass,
    InventoryRecords,
    ProductCount,
    TotalStockQuantity,
    InventoryCostValue,
    InventorySellingValue,

    CAST(
        InventoryCostValue * 100.0 /
        NULLIF(SUM(InventoryCostValue) OVER (), 0)
        AS DECIMAL(10,2)
    ) AS InventoryCostValuePercentage

FROM ClassSummary
ORDER BY
    CASE ABCClass
        WHEN 'A' THEN 1
        WHEN 'B' THEN 2
        WHEN 'C' THEN 3
        ELSE 4
    END;

/*==============================================================
  TASK 4: STORE-WISE INVENTORY POSITION

  Snapshot Date: 2026-04-24

  Purpose:
  Calculate stock quantity, inventory cost value and
  inventory selling value by store.

  Business Questions:
  1. Which stores hold the highest inventory cost value?
  2. What percentage of total inventory value does
     each store represent?
  3. How is inventory distributed across the store network?
==============================================================*/

WITH ActiveInventory AS
(
    SELECT *
    FROM clean.RetailInventory
    WHERE StartDate <= '2026-04-24'
      AND EndDate >= '2026-04-24'
),

StoreInventory AS
(
    SELECT
        Store,
        COUNT(DISTINCT ProductNo) AS ProductCount,
        SUM(QuantityOnHand) AS TotalStockQuantity,
        SUM(CostOfStocks) AS InventoryCostValue,
        SUM(StockSellingAmount) AS InventorySellingValue
    FROM ActiveInventory
    WHERE Store IS NOT NULL
    GROUP BY Store
),

RankedStores AS
(
    SELECT
        *,
        ROW_NUMBER() OVER (
            ORDER BY InventoryCostValue DESC, Store
        ) AS StoreRank,

        SUM(InventoryCostValue) OVER () AS TotalInventoryCostValue,

        SUM(InventoryCostValue) OVER (
            ORDER BY InventoryCostValue DESC, Store
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS CumulativeInventoryCostValue

    FROM StoreInventory
)

SELECT
    Store,
    ProductCount,
    TotalStockQuantity,
    InventoryCostValue,
    InventorySellingValue,
    StoreRank,

    CAST(
        InventoryCostValue * 100.0 /
        NULLIF(TotalInventoryCostValue, 0)
        AS DECIMAL(10,2)
    ) AS InventoryValuePercentage,

    CAST(
        CumulativeInventoryCostValue * 100.0 /
        NULLIF(TotalInventoryCostValue, 0)
        AS DECIMAL(10,2)
    ) AS CumulativePercentage

FROM RankedStores
ORDER BY StoreRank;

/*==============================================================
  TASK 5: NEGATIVE STOCK EXCEPTION ANALYSIS

  Snapshot Date: 2026-04-24

  Purpose:
  Identify products and stores with negative stock
  and quantify their inventory cost impact.

  Business Questions:
  1. Which stores have negative stock records?
  2. Which products have negative stock?
  3. What is the total negative stock quantity?
  4. What is the total negative inventory cost value?
==============================================================*/

WITH ActiveInventory AS
(
    SELECT *
    FROM clean.RetailInventory
    WHERE StartDate <= '2026-04-24'
      AND EndDate >= '2026-04-24'
)

SELECT
    Store,
    ProductNo,
    ProductDescription,
    ProductCategory,
    QuantityOnHand,
    CostOfStocks,
    StockUnitCostPrice,
    StockStatus
FROM ActiveInventory
WHERE QuantityOnHand < 0
ORDER BY
    QuantityOnHand ASC,
    Store,
    ProductNo;

/*==============================================================
  TASK 5A: NEGATIVE STOCK SUMMARY BY STORE

  Purpose:
  Identify stores with the highest negative stock quantities
  and negative inventory cost values.
==============================================================*/

WITH ActiveInventory AS
(
    SELECT *
    FROM clean.RetailInventory
    WHERE StartDate <= '2026-04-24'
      AND EndDate >= '2026-04-24'
)

SELECT
    Store,
    COUNT(*) AS NegativeStockRecords,
    COUNT(DISTINCT ProductNo) AS AffectedProducts,
    SUM(QuantityOnHand) AS TotalNegativeStockQuantity,
    SUM(CostOfStocks) AS NegativeInventoryCostValue

FROM ActiveInventory
WHERE QuantityOnHand < 0

GROUP BY Store

ORDER BY
    TotalNegativeStockQuantity ASC,
    Store;

-- Task 5B: Negative Stock by Product Category
-- Business Question:
-- Which product categories contribute most to negative inventory?

WITH ActiveInventory AS
(
    SELECT *
    FROM clean.RetailInventory
    WHERE StartDate <= '2026-04-24'
      AND EndDate >= '2026-04-24'
)
SELECT
    ProductCategory,
    COUNT(*) AS NegativeStockRecords,
    COUNT(DISTINCT ProductNo) AS AffectedProducts,
    SUM(QuantityOnHand) AS TotalNegativeStockQuantity,
    SUM(CostOfStocks) AS NegativeInventoryCostValue
FROM ActiveInventory
WHERE QuantityOnHand < 0
GROUP BY ProductCategory
ORDER BY
    SUM(CostOfStocks) ASC;

-- Task 5C: Negative Stock by ABC Class
-- Business Question:
-- Which ABC class contributes most to negative inventory exceptions?

WITH ActiveInventory AS
(
    SELECT *
    FROM clean.RetailInventory
    WHERE StartDate <= '2026-04-24'
      AND EndDate >= '2026-04-24'
)
SELECT
    COALESCE(A.ABCClass, 'Unclassified') AS ABCClass,
    COUNT(*) AS NegativeStockRecords,
    COUNT(DISTINCT I.ProductNo) AS AffectedProducts,
    SUM(I.QuantityOnHand) AS TotalNegativeStockQuantity,
    SUM(I.CostOfStocks) AS NegativeInventoryCostValue
FROM ActiveInventory I
LEFT JOIN analysis.ProductABC A
    ON I.ProductNo = A.ProductNo
WHERE I.QuantityOnHand < 0
GROUP BY COALESCE(A.ABCClass, 'Unclassified')
ORDER BY
    CASE COALESCE(A.ABCClass, 'Unclassified')
        WHEN 'A' THEN 1
        WHEN 'B' THEN 2
        WHEN 'C' THEN 3
        ELSE 4
    END;