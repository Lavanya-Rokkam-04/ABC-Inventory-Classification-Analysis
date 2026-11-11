
USE ABC_Inventory_Analytics;
GO

/*==============================================================
  STORE-LEVEL ANALYSIS

  TASK 1: STORE CONSUMPTION VALUE AND CONTRIBUTION

  Purpose:
  Calculate consumption value by store, rank stores,
  and calculate their contribution to total value.

  Business Questions:
  1. Which stores contribute the highest consumption value?
  2. What percentage of total value does each store contribute?
  3. Which stores contribute most cumulatively?
==============================================================*/

WITH StoreConsumption AS
(
    -- Step 1: Calculate store-level consumption metrics
    SELECT
        Store,
        COUNT(DISTINCT ProductNo) AS ProductCount,
        SUM(QuantitySold) AS TotalQuantitySold,
        SUM(COGS) AS ConsumptionValue,
        SUM(NumberOfTransactions) AS TotalTransactions
    FROM clean.RetailSales
    WHERE IsReturn = 0
      AND QuantitySold > 0
      AND ProductNo IS NOT NULL
      AND Store IS NOT NULL
    GROUP BY Store
    HAVING SUM(COGS) > 0
),

RankedStores AS
(
    -- Step 2: Rank stores and calculate cumulative value
    SELECT
        *,
        ROW_NUMBER() OVER
        (
            ORDER BY ConsumptionValue DESC, Store
        ) AS StoreRank,

        SUM(ConsumptionValue) OVER () AS TotalConsumptionValue,

        SUM(ConsumptionValue) OVER
        (
            ORDER BY ConsumptionValue DESC, Store
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS CumulativeConsumptionValue

    FROM StoreConsumption
)

-- Step 3: Display store-level analysis
SELECT
    Store,
    ProductCount,
    TotalQuantitySold,
    TotalTransactions,
    ConsumptionValue,
    StoreRank,

    CAST(
        ConsumptionValue * 100.0 /
        NULLIF(TotalConsumptionValue, 0)
        AS DECIMAL(10,2)
    ) AS ContributionPercentage,

    CAST(
        CumulativeConsumptionValue * 100.0 /
        NULLIF(TotalConsumptionValue, 0)
        AS DECIMAL(10,2)
    ) AS CumulativePercentage

FROM RankedStores
ORDER BY StoreRank;

/*==============================================================
  TASK 2: ABC PRODUCT DISTRIBUTION BY STORE

  Purpose:
  Analyze the number and percentage of A, B and C
  products available in each store's sales assortment.

  Business Questions:
  1. How many A, B and C products does each store sell?
  2. What percentage of each store's assortment belongs
     to each ABC class?
  3. Which stores have a higher or lower proportion of
     financially important A products?
==============================================================*/

WITH StoreProducts AS
(
    SELECT DISTINCT
        Store,
        ProductNo
    FROM clean.RetailSales
    WHERE IsReturn = 0
      AND QuantitySold > 0
      AND ProductNo IS NOT NULL
      AND Store IS NOT NULL
)

SELECT
    SP.Store,

    COUNT(DISTINCT SP.ProductNo) AS TotalProducts,

    COUNT(DISTINCT CASE
        WHEN PA.ABCClass = 'A' THEN SP.ProductNo
    END) AS A_Products,

    COUNT(DISTINCT CASE
        WHEN PA.ABCClass = 'B' THEN SP.ProductNo
    END) AS B_Products,

    COUNT(DISTINCT CASE
        WHEN PA.ABCClass = 'C' THEN SP.ProductNo
    END) AS C_Products,

    CAST(
        COUNT(DISTINCT CASE
            WHEN PA.ABCClass = 'A' THEN SP.ProductNo
        END) * 100.0 /
        NULLIF(COUNT(DISTINCT SP.ProductNo), 0)
        AS DECIMAL(10,2)
    ) AS A_ProductPercentage,

    CAST(
        COUNT(DISTINCT CASE
            WHEN PA.ABCClass = 'B' THEN SP.ProductNo
        END) * 100.0 /
        NULLIF(COUNT(DISTINCT SP.ProductNo), 0)
        AS DECIMAL(10,2)
    ) AS B_ProductPercentage,

    CAST(
        COUNT(DISTINCT CASE
            WHEN PA.ABCClass = 'C' THEN SP.ProductNo
        END) * 100.0 /
        NULLIF(COUNT(DISTINCT SP.ProductNo), 0)
        AS DECIMAL(10,2)
    ) AS C_ProductPercentage

FROM StoreProducts SP

INNER JOIN analysis.ProductABC PA
    ON SP.ProductNo = PA.ProductNo

GROUP BY SP.Store
ORDER BY SP.Store;

/*==============================================================
  TASK 3: STORE CONSUMPTION VALUE BY ABC CLASS

  Purpose:
  Calculate each store's consumption value from A, B and C
  products and measure each class's percentage contribution.

  Business Questions:
  1. How much consumption value comes from A, B and C products
     in each store?
  2. What percentage of each store's consumption value comes
     from each ABC class?
  3. Which stores depend most heavily on A-class products?
==============================================================*/

WITH StoreABCConsumption AS
(
    SELECT
        S.Store,
        P.ABCClass,
        SUM(S.COGS) AS ConsumptionValue
    FROM clean.RetailSales S
    INNER JOIN analysis.ProductABC P
        ON S.ProductNo = P.ProductNo
    WHERE S.IsReturn = 0
      AND S.QuantitySold > 0
      AND S.ProductNo IS NOT NULL
      AND S.Store IS NOT NULL
    GROUP BY
        S.Store,
        P.ABCClass
),

StoreClassSummary AS
(
    SELECT
        Store,

        SUM(CASE WHEN ABCClass = 'A'
            THEN ConsumptionValue ELSE 0 END) AS A_ConsumptionValue,

        SUM(CASE WHEN ABCClass = 'B'
            THEN ConsumptionValue ELSE 0 END) AS B_ConsumptionValue,

        SUM(CASE WHEN ABCClass = 'C'
            THEN ConsumptionValue ELSE 0 END) AS C_ConsumptionValue,

        SUM(ConsumptionValue) AS TotalConsumptionValue

    FROM StoreABCConsumption
    GROUP BY Store
)

SELECT
    Store,
    A_ConsumptionValue,
    B_ConsumptionValue,
    C_ConsumptionValue,
    TotalConsumptionValue,

    CAST(A_ConsumptionValue * 100.0 /
        NULLIF(TotalConsumptionValue, 0)
        AS DECIMAL(10,2)) AS A_ValuePercentage,

    CAST(B_ConsumptionValue * 100.0 /
        NULLIF(TotalConsumptionValue, 0)
        AS DECIMAL(10,2)) AS B_ValuePercentage,

    CAST(C_ConsumptionValue * 100.0 /
        NULLIF(TotalConsumptionValue, 0)
        AS DECIMAL(10,2)) AS C_ValuePercentage

FROM StoreClassSummary
ORDER BY TotalConsumptionValue DESC;