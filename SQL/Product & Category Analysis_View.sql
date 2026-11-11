USE ABC_Inventory_Analytics;
GO

-- View 2: Product & Category Analysis
-- Purpose: Summarize observed-period consumption
-- value and product contribution by category.

CREATE OR ALTER VIEW analysis.vw_Category_Analysis
AS
WITH CategorySummary AS
(
    SELECT
        ProductCategory,
        COUNT(*) AS ProductCount,
        SUM(ConsumptionValue) AS ConsumptionValue
    FROM analysis.ProductABC
    GROUP BY ProductCategory
),
CategoryContribution AS
(
    SELECT
        ProductCategory,
        ProductCount,
        ConsumptionValue,

        CAST(
            ConsumptionValue * 100.0
            / SUM(ConsumptionValue) OVER ()
            AS DECIMAL(10,2)
        ) AS ContributionPercentage
    FROM CategorySummary
)
SELECT
    ProductCategory,
    ProductCount,
    ConsumptionValue,
    ContributionPercentage,

    CAST(
        SUM(ContributionPercentage) OVER
        (
            ORDER BY ConsumptionValue DESC, ProductCategory
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )
        AS DECIMAL(10,2)
    ) AS CumulativePercentage,

    ROW_NUMBER() OVER
    (
        ORDER BY ConsumptionValue DESC, ProductCategory
    ) AS CategoryRank

FROM CategoryContribution;
GO

--CHECK ONE
SELECT
    COUNT(*) AS TotalCategories,
    SUM(ProductCount) AS TotalProducts,
    SUM(ConsumptionValue) AS TotalConsumptionValue
FROM analysis.vw_Category_Analysis;

--CHECK TWO
SELECT TOP 10
    CategoryRank,
    ProductCategory,
    ProductCount,
    ConsumptionValue,
    ContributionPercentage,
    CumulativePercentage
FROM analysis.vw_Category_Analysis
ORDER BY CategoryRank;