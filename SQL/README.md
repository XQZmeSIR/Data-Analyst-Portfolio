# SQL Portfolio

A collection of SQL analysis projects demonstrating skills from basic queries to advanced window functions and customer segmentation.

## Projects

| File | Topic | Key Techniques |
|------|-------|----------------|
| `COHORT_RFM_DATA.sql` | Pharmacy sales dataset (raw data + inserts) | Table creation, data loading |
| `WINDOW_FUNCTIONS.sql` | 8 progressive exercises on window functions | LAG, LEAD, RANK, NTILE, PERCENT_RANK, running totals, rolling averages |
| `RFM_ANALYSIS.sql` | Full RFM customer segmentation pipeline | CTEs, NTILE scoring, CASE segmentation, aggregate analytics |

---

# Coffee Shop Sales Analysis

## Overview
This project involves analyzing sales data from a coffee shop to gain insights into product performance and customer behavior. The dataset `coffee-shop.csv` contains transaction records, including details about the date, payment method, coffee products sold, and revenue generated.  

I took the [dataset](https://www.kaggle.com/datasets/ihelon/coffee-sales) in .csv format from Kaggle and imported it into DBeaver.

What was used: `SELECT, CTE, AGGREGATE FUNCTIONS, WINDOW FUNCTIONS, GROUPING, SUBQUERIES, STRFTIME()`

## Dataset
The dataset used for this analysis is stored in the `data/` directory in CSV format. It includes the following columns:
- **date**: The date of the transaction.
- **datetime**: The exact date and time of the transaction.
- **cash_type**: The payment method (e.g., card).
- **card**: Anonymized card identifier.
- **money**: The amount of money spent in the transaction.
- **coffee_name**: The name of the coffee product sold.

## SQL Analysis
The SQL scripts for analyzing the dataset are located in the `sql/` directory. The analysis includes various queries to answer business questions such as:
- What's the total revenue per day? Sort by date.
- Show each coffee product's total sales count and revenue. Order by best-selling.
- What percentage of transactions are card vs. cash? (Assume cash_type has 'cash' entries too).
- Which hour of the day (e.g., 10 AM, 2 PM) has the highest number of orders?
- Which days had the highest total revenue?
- Find transactions with identical datetime, card, and coffee_name (potential system errors).


### Key Queries
```sql
SELECT *
FROM COFFEE_SHOP CS;


--Daily Revenue Report ❓
--What's the total revenue per day? Sort by date.
SELECT STRFTIME('%d-%m-%Y', DATE) AS [Day], SUM(MONEY) || ' $' AS [Total Revenue per day]
FROM COFFEE_SHOP CS
GROUP BY DATE

--Product Performance ❓
--Show each coffee product's total sales count and revenue. Order by best-selling.
SELECT COFFEE_NAME AS [Coffee Name], COUNT(COFFEE_NAME) AS [Total Sales], SUM(MONEY) AS [Total Revenue]
FROM COFFEE_SHOP CS
GROUP BY COFFEE_NAME
ORDER BY "Total Sales" DESC

--Payment Method Analysis ❓
--What percentage of transactions are card vs. cash? (Assume cash_type has 'cash' entries too).
WITH all_values AS (
	SELECT COUNT(*) AS total_count
	FROM COFFEE_SHOP
	)
SELECT 
	CASH_TYPE AS [Payment Method],
	COUNT(CASH_TYPE) AS [Payment Count],
	ROUND(COUNT(CASH_TYPE) * 100.0 / av.total_count) || '%' AS [%, card vs cash]
FROM COFFEE_SHOP CS, all_values av
GROUP BY CASH_TYPE;

----Без использования CTE.
SELECT 
	CASH_TYPE,
	COUNT(CASH_TYPE),
	ROUND(COUNT(CASH_TYPE) * 100.0 / (SELECT count(*) FROM COFFEE_SHOP)) || '%' AS [%, card vs cash]
FROM COFFEE_SHOP CS
GROUP BY CASH_TYPE;


--Peak Hour Identification ❓
--Which hour of the day (e.g., 10 AM, 2 PM) has the highest number of orders?
SELECT STRFTIME('%H', DATETIME) AS [Order Hour], COUNT(*) AS [Orders]
FROM COFFEE_SHOP CS
GROUP BY "Order Hour"
ORDER BY Orders DESC
------ LIMIT 1;  -- По желанию: Чтобы получить только пиковый час

--Peak Sales Days ❓
--Which days had the highest total revenue?
SELECT DATE, COUNT(*) AS [Total Transactions], SUM(MONEY) AS [Total Revenue]
FROM COFFEE_SHOP CS
GROUP BY DATE
ORDER BY "Total Revenue" DESC
LIMIT 5;  -- Can be adjusted

--Duplicate Transactions ❓
--Find transactions with identical datetime, card, and coffee_name (potential system errors).
SELECT DATETIME, CARD, COFFEE_NAME,
	ROW_NUMBER() OVER (ORDER BY COFFEE_NAME)
FROM COFFEE_SHOP CS

SELECT DATETIME, CARD, COFFEE_NAME,
	COUNT(*) AS duplicate_count
FROM COFFEE_SHOP CS
GROUP BY 1, 2, 3
HAVING duplicate_count > 1

```

---

# Window Functions Practice

## Overview
8 progressive exercises using the pharmacy `checks` dataset, building from basic LAG/LEAD to NTILE tiering.

What was used: `LAG, LEAD, RANK, DENSE_RANK, NTILE, PERCENT_RANK, FIRST_VALUE, LAST_VALUE, SUM/AVG OVER, CTE, CASE`

### Exercises
| # | Topic | Function |
|---|-------|----------|
| 1 | Time between customer purchases | `LAG()` |
| 2 | Running total of revenue per customer | `SUM() OVER (ORDER BY ...)` |
| 3 | Rank customers by total spend | `RANK()`, `DENSE_RANK()` |
| 4 | Rank shops by daily revenue | `RANK() OVER (PARTITION BY ...)` |
| 5 | Rolling 3-transaction average | `AVG() OVER (ROWS BETWEEN ...)` |
| 6 | First and last purchase per customer | `FIRST_VALUE()`, `LAST_VALUE()` |
| 7 | Percentile rank of customer spend | `PERCENT_RANK()` |
| 8 | Split customers into 4 spend tiers | `NTILE(4)` |

---

# RFM Customer Segmentation

## Overview
Full RFM (Recency, Frequency, Monetary) analysis pipeline that scores customers and assigns business segments. Built as a progressive extension of the window functions exercises.

What was used: `CTE, NTILE, LAG, SUM/COUNT OVER, CASE WHEN, aggregate functions`

### Pipeline Steps
| Step | What it does |
|------|--------------|
| 1 | Calculate raw RFM values (days since last purchase, transaction count, total spend) |
| 2 | Score each dimension 1-4 using `NTILE(4)` |
| 3 | Combine scores into an RFM cell (e.g., `432`) |
| 4 | Assign customer segments: Champions, Loyal, Potential Loyalists, Recent, At Risk, Can't Lose Them, Hibernating, Lost |
| 5 | Segment summary statistics (counts, averages, total revenue) |
| 6 | RFM distribution heatmap data (customer counts per RFM cell) |
