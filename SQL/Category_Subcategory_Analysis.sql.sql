
USE ABC_Inventory_Analytics;
GO

/*==============================================================
  CATEGORY & SUBCATEGORY ANALYSIS

  TASK 1: CATEGORY CONSUMPTION VALUE AND CONTRIBUTION ANALYSIS

  Purpose:
  Calculate consumption value for each product category,
  rank categories, and calculate their contribution to
  total observed-period consumption value.

  Business Questions:
  1. Which categories contribute the most value?
  2. What percentage of total value does each category represent?
  3. Which categories contribute most cumulatively?

  Calculation Basis:
  - Exclude return transactions.
  - Include only positive quantities sold.
  - Exclude records without a ProductNo or ProductCategory.
==============================================================*/

WITH CategoryConsumption AS
(
    -- Step 1: Calculate consumption value for each category
    SELECT
        ProductCategory,
        COUNT(DISTINCT ProductNo) AS ProductCount,
        SUM(COGS) AS ConsumptionValue
    FROM clean.RetailSales
    WHERE IsReturn = 0
      AND QuantitySold > 0
      AND ProductNo IS NOT NULL
      AND ProductCategory IS NOT NULL
    GROUP BY ProductCategory
    HAVING SUM(COGS) > 0
),

RankedCategories AS
(
    -- Step 2: Rank categories and calculate cumulative value
    SELECT
        ProductCategory,
        ProductCount,
        ConsumptionValue,

        ROW_NUMBER() OVER
        (
            ORDER BY ConsumptionValue DESC, ProductCategory
        ) AS CategoryRank,

        SUM(ConsumptionValue) OVER () AS TotalConsumptionValue,

        SUM(ConsumptionValue) OVER
        (
            ORDER BY ConsumptionValue DESC, ProductCategory
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS CumulativeConsumptionValue

    FROM CategoryConsumption
)

-- Step 3: Display category analysis results
SELECT
    ProductCategory,
    ProductCount,
    ConsumptionValue,
    CategoryRank,

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

FROM RankedCategories
ORDER BY CategoryRank;


/*==============================================================
  TASK 2: SUBCATEGORY CONSUMPTION ANALYSIS

  Purpose:
  Calculate consumption value by product category and
  subcategory, rank subcategories, and calculate their
  contribution to total consumption value.

  Business Questions:
  1. Which subcategories contribute the most value?
  2. Which subcategories are the leading contributors
     within their respective categories?
  3. How concentrated is consumption value across
     subcategories?
==============================================================*/

WITH SubcategoryConsumption AS
(
    -- Step 1: Calculate consumption value by category
    -- and subcategory
    SELECT
        ProductCategory,
        ProductSubcategory,
        COUNT(DISTINCT ProductNo) AS ProductCount,
        SUM(COGS) AS ConsumptionValue
    FROM clean.RetailSales
    WHERE IsReturn = 0
      AND QuantitySold > 0
      AND ProductNo IS NOT NULL
      AND ProductCategory IS NOT NULL
      AND ProductSubcategory IS NOT NULL
    GROUP BY
        ProductCategory,
        ProductSubcategory
    HAVING SUM(COGS) > 0
),

RankedSubcategories AS
(
    -- Step 2: Rank subcategories within each category
    -- and calculate their overall contribution
    SELECT
        ProductCategory,
        ProductSubcategory,
        ProductCount,
        ConsumptionValue,

        ROW_NUMBER() OVER
        (
            ORDER BY ConsumptionValue DESC,
                     ProductCategory,
                     ProductSubcategory
        ) AS SubcategoryRank,

        SUM(ConsumptionValue) OVER () AS TotalConsumptionValue,

        SUM(ConsumptionValue) OVER
        (
            ORDER BY ConsumptionValue DESC,
                     ProductCategory,
                     ProductSubcategory
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS CumulativeConsumptionValue,

        ROW_NUMBER() OVER
        (
            PARTITION BY ProductCategory
            ORDER BY ConsumptionValue DESC,
                     ProductSubcategory
        ) AS CategorySubcategoryRank

    FROM SubcategoryConsumption
)

-- Step 3: Display subcategory analysis results
SELECT
    ProductCategory,
    ProductSubcategory,
    ProductCount,
    ConsumptionValue,
    SubcategoryRank,
    CategorySubcategoryRank,

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

FROM RankedSubcategories
ORDER BY SubcategoryRank;


/*==============================================================
  TASK 3: ABC PRODUCT DISTRIBUTION BY CATEGORY

  Purpose:
  Analyse how A, B and C classified products are
  distributed across product categories.

  Business Questions:
  1. How many A, B and C products exist in each category?
  2. Which categories have the highest number of A products?
  3. What is the ABC product mix within each category?

  Note:
  ABC classification is based on overall product
  consumption value, not separately recalculated
  within each category.
==============================================================*/

SELECT
    ProductCategory,

    COUNT(DISTINCT ProductNo) AS TotalProducts,

    COUNT(DISTINCT CASE
        WHEN ABCClass = 'A' THEN ProductNo
    END) AS A_Products,

    COUNT(DISTINCT CASE
        WHEN ABCClass = 'B' THEN ProductNo
    END) AS B_Products,

    COUNT(DISTINCT CASE
        WHEN ABCClass = 'C' THEN ProductNo
    END) AS C_Products,

    CAST(
        COUNT(DISTINCT CASE
            WHEN ABCClass = 'A' THEN ProductNo
        END) * 100.0 /
        NULLIF(COUNT(DISTINCT ProductNo), 0)
        AS DECIMAL(10,2)
    ) AS A_ProductPercentage,

    CAST(
        COUNT(DISTINCT CASE
            WHEN ABCClass = 'B' THEN ProductNo
        END) * 100.0 /
        NULLIF(COUNT(DISTINCT ProductNo), 0)
        AS DECIMAL(10,2)
    ) AS B_ProductPercentage,

    CAST(
        COUNT(DISTINCT CASE
            WHEN ABCClass = 'C' THEN ProductNo
        END) * 100.0 /
        NULLIF(COUNT(DISTINCT ProductNo), 0)
        AS DECIMAL(10,2)
    ) AS C_ProductPercentage

FROM analysis.ProductABC
GROUP BY ProductCategory
ORDER BY TotalProducts DESC;


/*==============================================================
  VALIDATION: COMPARE CATEGORY COUNTS
==============================================================*/

SELECT
    'Sales Data' AS Source,
    COUNT(DISTINCT ProductCategory) AS CategoryCount
FROM clean.RetailSales
WHERE IsReturn = 0
  AND QuantitySold > 0
  AND ProductNo IS NOT NULL
  AND ProductCategory IS NOT NULL

UNION ALL

SELECT
    'Product ABC Table' AS Source,
    COUNT(DISTINCT ProductCategory) AS CategoryCount
FROM analysis.ProductABC;

/*==============================================================
  VALIDATION: IDENTIFY MISSING CATEGORY
==============================================================*/

SELECT DISTINCT
    s.ProductCategory
FROM clean.RetailSales s
WHERE s.IsReturn = 0
  AND s.QuantitySold > 0
  AND s.ProductNo IS NOT NULL
  AND s.ProductCategory IS NOT NULL

EXCEPT

SELECT DISTINCT
    ProductCategory
FROM analysis.ProductABC;