USE ABC_Inventory_Analytics;
GO

/*========================================================
  PRODUCT-LEVEL ANALYSIS
  Objective:
  Analyze product consumption value, product rankings,
  individual contributions and cumulative contributions.
========================================================*/


/*========================================================
  TASK 1: PREPARE THE ANALYSIS SCHEMA
  Purpose:
  Create the analysis schema if it does not already exist.
========================================================*/

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'analysis'
)
    EXEC('CREATE SCHEMA analysis');
GO


/*========================================================
  TASK 2: CALCULATE PRODUCT-LEVEL CONSUMPTION VALUE
  Purpose:
  Calculate total consumption value for each product.
  Exclude returns and non-positive quantities.
========================================================*/

DROP TABLE IF EXISTS analysis.ProductABC;
GO

WITH ProductConsumption AS
(
    SELECT
        ProductNo,
        MAX(ProductDescription) AS ProductDescription,
        MAX(ProductCategory) AS ProductCategory,
        MAX(ProductSubcategory) AS ProductSubcategory,
        SUM(COGS) AS ConsumptionValue
    FROM clean.RetailSales
    WHERE IsReturn = 0
      AND QuantitySold > 0
      AND ProductNo IS NOT NULL
    GROUP BY ProductNo
    HAVING SUM(COGS) > 0
),


/*========================================================
  TASK 3: RANK PRODUCTS BY CONSUMPTION VALUE
  Purpose:
  Rank products from highest to lowest consumption value.
  Calculate total and cumulative consumption value.
========================================================*/

RankedProducts AS
(
    SELECT
        ProductNo,
        ProductDescription,
        ProductCategory,
        ProductSubcategory,
        ConsumptionValue,

        ROW_NUMBER() OVER (
            ORDER BY ConsumptionValue DESC, ProductNo
        ) AS ProductRank,

        SUM(ConsumptionValue) OVER () AS TotalConsumptionValue,

        SUM(ConsumptionValue) OVER (
            ORDER BY ConsumptionValue DESC, ProductNo
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS CumulativeConsumptionValue

    FROM ProductConsumption
),


/*========================================================
  TASK 4: CALCULATE INDIVIDUAL AND CUMULATIVE CONTRIBUTION
  Purpose:
  Calculate each product's percentage contribution
  and its cumulative percentage contribution.
========================================================*/

ABCClassification AS
(
    SELECT
        *,
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

    FROM RankedProducts
)


/*========================================================
  TASK 5: ABC INVENTORY CLASSIFICATION
  Purpose:
  Classify products into A, B and C based on cumulative
  consumption value contribution.
========================================================*/

SELECT
    ProductNo,
    ProductDescription,
    ProductCategory,
    ProductSubcategory,
    ConsumptionValue,
    ProductRank,
    ContributionPercentage,
    CumulativePercentage,

    CASE
        WHEN CumulativePercentage <= 80 THEN 'A'
        WHEN CumulativePercentage <= 95 THEN 'B'
        ELSE 'C'
    END AS ABCClass

INTO analysis.ProductABC
FROM ABCClassification;
GO


/*========================================================
  TASK 6: IDENTIFY TOP 20 PRODUCTS
  Business question:
  Which products contribute the most to consumption value?
========================================================*/

SELECT TOP 20
    *
FROM analysis.ProductABC
ORDER BY ProductRank;


/*========================================================
  TASK 7: ANALYZE ABC CLASS PRODUCT DISTRIBUTION
  Business questions:
  How many products belong to each ABC class?
  What percentage of consumption value does each
  ABC class contribute?
========================================================*/

SELECT
    ABCClass,
    COUNT(*) AS ProductCount,
    SUM(ConsumptionValue) AS TotalConsumptionValue,
    CAST(
        SUM(ConsumptionValue) * 100.0 /
        (SELECT SUM(ConsumptionValue)
         FROM analysis.ProductABC)
        AS DECIMAL(10,2)
    ) AS ValueSharePercentage

FROM analysis.ProductABC
GROUP BY ABCClass
ORDER BY ABCClass;


/*========================================================
  TASK 8: CALCULATE OVERALL PRODUCT CONSUMPTION VALUE
  Business questions:
  How many distinct products are analyzed?
  What is their total consumption value?
========================================================*/

SELECT
    COUNT(*) AS TotalProducts,
    SUM(ConsumptionValue) AS TotalConsumptionValue

FROM analysis.ProductABC;


SELECT TOP 30
    ProductSegment,
    COUNT(DISTINCT ProductNo) AS ProductCount,
    SUM(COGS) AS ConsumptionValue
FROM clean.RetailSales
WHERE IsReturn = 0
  AND QuantitySold > 0
  AND ProductNo IS NOT NULL
  AND ProductSegment IS NOT NULL
GROUP BY ProductSegment
ORDER BY ConsumptionValue DESC;


/*========================================================
  TASK 9: IDENTIFY AND RANK LEADING PRODUCT RANGES

  Business questions:
  1. Which product ranges generate the highest consumption?
  2. How many distinct products belong to each range?
  3. What percentage of total consumption comes from each range?
  4. What is the cumulative contribution of each range?
========================================================*/

WITH ProductRangeConsumption AS
(
    SELECT
        ProductSegment AS ProductRange,
        COUNT(DISTINCT ProductNo) AS ProductCount,
        SUM(COGS) AS ConsumptionValue

    FROM clean.RetailSales

    WHERE IsReturn = 0
      AND QuantitySold > 0
      AND ProductNo IS NOT NULL
      AND ProductSegment IS NOT NULL

    GROUP BY ProductSegment

    HAVING SUM(COGS) > 0
),

RankedProductRanges AS
(
    SELECT
        ProductRange,
        ProductCount,
        ConsumptionValue,

        ROW_NUMBER() OVER (
            ORDER BY ConsumptionValue DESC, ProductRange
        ) AS RangeRank,

        SUM(ConsumptionValue) OVER () AS TotalConsumptionValue,

        SUM(ConsumptionValue) OVER (
            ORDER BY ConsumptionValue DESC, ProductRange
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS CumulativeConsumptionValue

    FROM ProductRangeConsumption
)

SELECT
    ProductRange,
    ProductCount,
    ConsumptionValue,
    RangeRank,

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

FROM RankedProductRanges

ORDER BY RangeRank;
GO

