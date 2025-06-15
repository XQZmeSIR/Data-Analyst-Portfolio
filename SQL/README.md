# Coffee Shop Sales Analysis

## Overview
This project involves analyzing sales data from a coffee shop to gain insights into product performance and customer behavior. The dataset contains transaction records, including details about the date, payment method, coffee products sold, and revenue generated.  

I took the [dataset](https://www.kaggle.com/datasets/ihelon/coffee-sales) in .csv format from Kaggle and imported it into DBeaver.

What was used: SELECT, CTE, GROUPING, SUBQUERIES, D 

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
