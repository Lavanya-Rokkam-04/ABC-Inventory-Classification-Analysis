# ABC Inventory Classification and Stock Analysis using SQL Server and Power BI

ABC Inventory Classification and Stock Analysis using SQL Server and Power BI
# ABC Inventory Classification & Stock Analysis

## 1. Project Overview

This project analyzes retail sales and inventory data to classify products using the ABC inventory management technique. It explores product consumption value, category performance, store performance, inventory distribution, and negative stock exceptions.

The objective is to support better inventory prioritization and provide actionable business insights through SQL Server and Power BI.

## 2. Tools and Technologies

- Microsoft SQL Server
- SQL
- Microsoft Power BI Desktop
- DAX
- Microsoft Excel / CSV

## 3. Data Scope

The analysis uses two source datasets:

- Retail Sales
- Retail Inventory

The observed sales period is June 1, 2025 to April 24, 2026. The inventory analysis uses a snapshot dated April 24, 2026.

## 4. Methodology

### Data Preparation
- Imported the source CSV files into SQL Server.
- Reviewed and cleaned the data.
- Created clean sales and inventory tables.
- Validated record counts between raw and cleaned tables.

### ABC Classification
Products were classified based on consumption value, calculated using positive non-return sales cost of goods sold (COGS).

- **A Class:** Products contributing approximately the first 80% of cumulative consumption value.
- **B Class:** Products contributing approximately the next 15%.
- **C Class:** Products contributing the remaining 5%.

### Inventory Analysis
Analyzed inventory quantity and cost value, including positive, zero, and negative stock records. Negative stock records were retained as exceptions for investigation.

### Power BI
Created analytical views in SQL Server and used them in Power BI to build an interactive, multi-page dashboard.

## 5. Key Findings

### ABC Classification
- 2,326 products were classified.
- A-class products account for 79.99% of observed-period consumption value.
- B-class products account for 15.01%.
- C-class products account for 5.00%.

### Category Analysis
- The analysis covers 27 product categories.
- The top three categories contribute 47.80% of consumption value.

### Inventory Analysis
- The inventory snapshot contains 22,701 records across 40 stores.
- Net stock quantity is 37,187 units.
- Inventory cost value is approximately ₹18.04 lakh.
- There are 2,784 zero-stock records and 321 negative-stock records.

### Inventory by ABC Class
- A-class products account for 66.20% of inventory cost value.
- B-class products account for 25.14%.
- C-class products account for 8.66%.

### Negative Stock Exceptions
- 321 negative-stock records were identified.
- These records involve 270 products across 37 stores.
- The exceptions provide a basis for inventory reconciliation and operational investigation.

## 6. Dashboard Pages

1. **Home – Executive Overview:** Project introduction and navigation.
2. **Product Analysis:** ABC classification, product contribution, and Pareto analysis.
3. **Category & Inventory Analysis:** Category performance, ABC distribution, and stock value.
4. **Inventory Health, Risk & Store Performance:** Inventory health, store performance, and negative-stock exceptions.

## 7. Important Notes and Limitations

- Consumption value represents the observed sales period; it should not be interpreted as annual consumption.
- The inventory snapshot is dated April 24, 2026.
- Negative stock records are retained rather than adjusted to zero.
- Inventory selling value minus cost value is not necessarily realized profit.
- Higher inventory cost share relative to consumption share may warrant review, but does not independently prove overstock or slow-moving inventory.
- Slow-moving inventory was not calculated because the available analytical views do not contain the required last-sale information.

## 8. Conclusion

This project demonstrates how SQL-based data preparation and analysis can be combined with Power BI to provide visibility into product prioritization, category contribution, store performance, and inventory exceptions. The findings can help support inventory planning, stock monitoring, and further operational investigation.
