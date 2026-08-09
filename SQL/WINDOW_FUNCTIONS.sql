-- ============================================================
-- WINDOW FUNCTIONS PRACTICE
-- Dataset: checks (pharmacy sales)
-- ============================================================
-- Table structure:
--   datetime       TIMESTAMP
--   shop           VARCHAR(20)
--   card           VARCHAR(100)
--   bonus_earned   INTEGER
--   bonus_spent    INTEGER
--   summ           NUMERIC
--   summ_with_disc NUMERIC
--   doc_id         VARCHAR(100)
-- ============================================================


-- ============================================================
-- EXERCISE 1: Time Between Customer Purchases (LAG)
-- ============================================================
-- Question: For each customer, how many days passed between
--           their consecutive purchases?

SELECT
    card,
    datetime AS current_purchase,
    LAG(datetime) OVER (PARTITION BY card ORDER BY datetime) AS previous_purchase,
    DATE_PART('day',
        datetime - LAG(datetime) OVER (PARTITION BY card ORDER BY datetime)
    ) AS days_between
FROM checks
ORDER BY card, datetime;

-- Explanation:
-- LAG(datetime) looks at the previous row within the same customer (PARTITION BY card)
-- ordered by time. We then subtract to get the interval in days.
-- NULL in previous_purchase means this is the customer's first purchase in the data.


-- ============================================================
-- EXERCISE 2: Running Total of Revenue per Customer
-- ============================================================
-- Question: What is the cumulative spend for each customer
--           over time?

SELECT
    card,
    datetime,
    summ,
    SUM(summ) OVER (
        PARTITION BY card
        ORDER BY datetime
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM checks
ORDER BY card, datetime;

-- Explanation:
-- SUM() OVER with PARTITION BY card and ORDER BY datetime creates
-- a cumulative sum that grows with each transaction.
-- ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW means "from the
-- very first row up to now" — this is the default when you use ORDER BY.


-- ============================================================
-- EXERCISE 3: Rank Customers by Total Spend
-- ============================================================
-- Question: Rank all customers by their total spending.
--           Who are the top spenders?

WITH customer_totals AS (
    SELECT
        card,
        SUM(summ) AS total_spend,
        COUNT(*) AS total_transactions
    FROM checks
    GROUP BY card
)
SELECT
    card,
    total_spend,
    total_transactions,
    RANK() OVER (ORDER BY total_spend DESC) AS spend_rank,
    DENSE_RANK() OVER (ORDER BY total_spend DESC) AS dense_spend_rank
FROM customer_totals
ORDER BY spend_rank
LIMIT 20;

-- Explanation:
-- First we aggregate to get each customer's total, then rank them.
-- RANK(): gaps in ranking when there are ties (1, 2, 2, 4).
-- DENSE_RANK(): no gaps (1, 2, 2, 3). Use DENSE_RANK when you
-- want consecutive numbering.


-- ============================================================
-- EXERCISE 4: Rank Shops by Daily Revenue
-- ============================================================
-- Question: For each day, rank shops by their total revenue.

SELECT
    DATE(datetime) AS sale_date,
    shop,
    SUM(summ) AS daily_revenue,
    RANK() OVER (
        PARTITION BY DATE(datetime)
        ORDER BY SUM(summ) DESC
    ) AS daily_shop_rank
FROM checks
GROUP BY DATE(datetime), shop
ORDER BY sale_date, daily_shop_rank;

-- Explanation:
-- We partition by date so each day starts a new ranking.
-- Within each day, shops are ranked by revenue.
-- Useful for identifying which shop leads on any given day.


-- ============================================================
-- EXERCISE 5: Rolling 3-Transaction Average per Customer
-- ============================================================
-- Question: What is the rolling average spend across the last
--           3 transactions for each customer?

SELECT
    card,
    datetime,
    summ,
    ROUND(AVG(summ) OVER (
        PARTITION BY card
        ORDER BY datetime
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_avg_3
FROM checks
ORDER BY card, datetime;

-- Explanation:
-- ROWS BETWEEN 2 PRECEDING AND CURRENT ROW creates a window of
-- 3 rows: the current row and the 2 before it.
-- This gives a moving average that smooths out spending patterns.
-- Change 2 to 6 for a 7-transaction rolling average, etc.


-- ============================================================
-- EXERCISE 6: First and Last Purchase per Customer
-- ============================================================
-- Question: When was each customer's first and last purchase?
--           How many days have they been active?

SELECT DISTINCT
    card,
    FIRST_VALUE(datetime) OVER (
        PARTITION BY card ORDER BY datetime
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS first_purchase,
    LAST_VALUE(datetime) OVER (
        PARTITION BY card ORDER BY datetime
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS last_purchase,
    DATE_PART('day',
        LAST_VALUE(datetime) OVER (
            PARTITION BY card ORDER BY datetime
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) -
        FIRST_VALUE(datetime) OVER (
            PARTITION BY card ORDER BY datetime
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        )
    ) AS days_active
FROM checks
ORDER BY days_active DESC NULLS LAST;

-- Explanation:
-- FIRST_VALUE gets the first value in the window, LAST_VALUE gets the last.
-- ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING means the
-- entire partition — so first/last across all transactions.
-- We use DISTINCT because each customer appears once.


-- ============================================================
-- EXERCISE 7: Percentile Rank of Customer Spend
-- ============================================================
-- Question: Where does each customer fall in the spend distribution?
--           What percentile are they in?

WITH customer_totals AS (
    SELECT
        card,
        SUM(summ) AS total_spend
    FROM checks
    GROUP BY card
)
SELECT
    card,
    total_spend,
    PERCENT_RANK() OVER (ORDER BY total_spend) AS percentile,
    ROUND(PERCENT_RANK() OVER (ORDER BY total_spend) * 100, 1) || '%' AS percentile_label
FROM customer_totals
ORDER BY total_spend DESC
LIMIT 20;

-- Explanation:
-- PERCENT_RANK() returns a value between 0 and 1 representing the
-- relative position of each row within the result set.
-- 0.0 = lowest spender, 1.0 = highest spender.
-- Useful for identifying top 10%, bottom 20%, etc.


-- ============================================================
-- EXERCISE 8: Split Customers into 4 Spend Tiers (NTILE)
-- ============================================================
-- Question: Divide all customers into 4 quartiles based on
--           their total spending.

WITH customer_totals AS (
    SELECT
        card,
        SUM(summ) AS total_spend,
        COUNT(*) AS transactions
    FROM checks
    GROUP BY card
)
SELECT
    card,
    total_spend,
    transactions,
    NTILE(4) OVER (ORDER BY total_spend DESC) AS spend_tier,
    CASE NTILE(4) OVER (ORDER BY total_spend DESC)
        WHEN 1 THEN 'Top 25%'
        WHEN 2 THEN 'Upper-Mid 25%'
        WHEN 3 THEN 'Lower-Mid 25%'
        WHEN 4 THEN 'Bottom 25%'
    END AS tier_label
FROM customer_totals
ORDER BY spend_tier, total_spend DESC;

-- Explanation:
-- NTILE(n) divides the result set into n roughly equal groups.
-- Here we split customers into 4 tiers by spend.
-- Combined with CASE, we get human-readable labels.
-- This is the foundation for RFM scoring (next file).
