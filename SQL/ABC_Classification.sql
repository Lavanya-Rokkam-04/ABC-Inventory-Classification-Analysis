USE ABC_Inventory_Analytics;
GO

-- View 1: ABC Classification
-- Purpose: Provide product-level ABC analysis for Power BI.

CREATE OR ALTER VIEW analysis.vw_ABC_Classification
AS
SELECT
    ProductNo,
    ProductDescription,
    ProductCategory,
    ProductSubcategory,
    ConsumptionValue,
    ProductRank,
    ContributionPercentage,
    CumulativePercentage,
    ABCClass
FROM analysis.ProductABC;
GO

-- Check 1: Total products and consumption value

SELECT
    COUNT(*) AS TotalProducts,
    SUM(ConsumptionValue) AS TotalConsumptionValue
FROM analysis.vw_ABC_Classification;


-- Check 2: ABC classification summary

SELECT
    ABCClass,
    COUNT(*) AS ProductCount,
    SUM(ConsumptionValue) AS TotalConsumptionValue,
    SUM(ContributionPercentage) AS TotalContributionPercentage
FROM analysis.vw_ABC_Classification
GROUP BY ABCClass
ORDER BY ABCClass;