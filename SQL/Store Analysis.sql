USE ABC_Inventory_Analytics;
GO

-- View 3: Store Analysis
-- Purpose: Analyze store-level consumption value
-- and contribution for Power BI.

CREATE OR ALTER VIEW analysis.vw_Store_Analysis
AS
WITH StoreSummary AS
(
    SELECT
        Store,
        COUNT(DISTINCT ProductNo) AS ProductCount,
        SUM(QuantitySold) AS TotalQuantitySold,
        SUM(NumberOfTransactions) AS TotalTransactions,
        SUM(COGS) AS ConsumptionValue
    FROM clean.RetailSales
    WHERE
        IsReturn = 0
        AND QuantitySold > 0
        AND ProductNo IS NOT NULL
        AND Store IS NOT NULL
    GROUP BY Store
),
StoreContribution AS
(
    SELECT
        Store,
        ProductCount,
        TotalQuantitySold,
        TotalTransactions,
        ConsumptionValue,

        CAST(
            ConsumptionValue * 100.0
            / SUM(ConsumptionValue) OVER ()
            AS DECIMAL(10,2)
        ) AS ContributionPercentage
    FROM StoreSummary
)
SELECT
    Store,
    ProductCount,
    TotalQuantitySold,
    TotalTransactions,
    ConsumptionValue,
    ContributionPercentage,

    ROW_NUMBER() OVER
    (
        ORDER BY ConsumptionValue DESC, Store
    ) AS StoreRank

FROM StoreContribution;
GO

--Check 1 — Overall store totals
SELECT
    COUNT(*) AS TotalStores,
    SUM(ProductCount) AS TotalStoreProductCounts,
    SUM(TotalQuantitySold) AS TotalQuantitySold,
    SUM(TotalTransactions) AS TotalTransactions,
    SUM(ConsumptionValue) AS TotalConsumptionValue
FROM analysis.vw_Store_Analysis;

--Check 2 — Top 10 stores
SELECT TOP 10
    StoreRank,
    Store,
    ProductCount,
    TotalQuantitySold,
    TotalTransactions,
    ConsumptionValue,
    ContributionPercentage
FROM analysis.vw_Store_Analysis
ORDER BY StoreRank;