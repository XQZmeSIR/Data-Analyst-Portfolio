-- ============================================================
-- RFM SEGMENTATION ANALYSIS
-- Dataset: checks (pharmacy sales)
-- ============================================================
-- RFM stands for:
--   Recency  — How recently did the customer purchase?
--   Frequency — How often do they purchase?
--   Monetary  — How much do they spend?
--
-- We score each dimension 1-4, then combine into segments.
-- ============================================================


-- ============================================================
-- STEP 1: Calculate Raw RFM Values
-- ============================================================
-- For each customer, compute:
--   R: days since last purchase (lower = better)
--   F: total number of transactions (higher = better)
--   M: total spend (higher = better)

WITH reference_date AS (
    -- Using the max date in the dataset as "today"
    SELECT MAX(datetime) AS today FROM checks
),
rfm_raw AS (
    SELECT
        c.card,
        EXTRACT(DAY FROM rd.today - MAX(c.datetime)) AS recency,
        COUNT(*) AS frequency,
        SUM(c.summ) AS monetary
    FROM checks c
    CROSS JOIN reference_date rd
    GROUP BY c.card, rd.today
)
SELECT * FROM rfm_raw
ORDER BY recency ASC, frequency DESC, monetary DESC
LIMIT 20;

-- Explanation:
-- We use a CTE to define "today" as the most recent transaction date.
-- Then for each customer we calculate the three raw metrics.
-- Low recency = purchased recently (good).
-- High frequency = buys often (good).
-- High monetary = spends a lot (good).


-- ============================================================
-- STEP 2: Score Each Dimension (1-4 using NTILE)
-- ============================================================
-- NTILE(4) splits customers into 4 groups per dimension.
-- Important: for Recency, LOWER is better, so we reverse the order.

WITH reference_date AS (
    SELECT MAX(datetime) AS today FROM checks
),
rfm_raw AS (
    SELECT
        c.card,
        EXTRACT(DAY FROM rd.today - MAX(c.datetime)) AS recency,
        COUNT(*) AS frequency,
        SUM(c.summ) AS monetary
    FROM checks c
    CROSS JOIN reference_date rd
    GROUP BY c.card, rd.today
),
rfm_scored AS (
    SELECT
        card,
        recency,
        frequency,
        monetary,
        -- Recency: lower days = better, so ORDER BY recency ASC gets score 1 to best customers
        NTILE(4) OVER (ORDER BY recency ASC) AS r_score,
        -- Frequency: higher = better
        NTILE(4) OVER (ORDER BY frequency ASC) AS f_score,
        -- Monetary: higher = better
        NTILE(4) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_raw
)
SELECT
    card,
    recency,
    frequency,
    ROUND(monetary, 2) AS monetary,
    r_score,
    f_score,
    m_score
FROM rfm_scored
ORDER BY r_score DESC, f_score DESC, m_score DESC
LIMIT 20;

-- Explanation:
-- NTILE(4) assigns 1-4 to each dimension.
-- For recency: score 4 = most recent (best), score 1 = least recent.
-- For frequency/monetary: score 4 = highest (best), score 1 = lowest.
-- NOTE: NTILE ordering can vary by SQL dialect. Verify that score 4
-- actually corresponds to "best" in your environment.


-- ============================================================
-- STEP 3: Combine Scores into RFM Cell
-- ============================================================
-- Concatenate the three scores into a single string like '432'.
-- This gives each customer an RFM "address".

WITH reference_date AS (
    SELECT MAX(datetime) AS today FROM checks
),
rfm_raw AS (
    SELECT
        c.card,
        EXTRACT(DAY FROM rd.today - MAX(c.datetime)) AS recency,
        COUNT(*) AS frequency,
        SUM(c.summ) AS monetary
    FROM checks c
    CROSS JOIN reference_date rd
    GROUP BY c.card, rd.today
),
rfm_scored AS (
    SELECT
        card,
        recency,
        frequency,
        monetary,
        NTILE(4) OVER (ORDER BY recency ASC) AS r_score,
        NTILE(4) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(4) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_raw
)
SELECT
    card,
    recency,
    frequency,
    ROUND(monetary, 2) AS monetary,
    r_score,
    f_score,
    m_score,
    r_score || f_score || m_score AS rfm_cell
FROM rfm_scored
ORDER BY rfm_cell DESC
LIMIT 20;

-- Explanation:
-- The rfm_cell '444' means the customer is top-tier on all three
-- dimensions: recent, frequent, and high spender.
-- '111' means the opposite: hasn't bought in a while, rare visits, low spend.


-- ============================================================
-- STEP 4: Assign Customer Segments
-- ============================================================
-- Use CASE logic on the RFM scores to create business-meaningful
-- segments. This is where RFM becomes actionable.

WITH reference_date AS (
    SELECT MAX(datetime) AS today FROM checks
),
rfm_raw AS (
    SELECT
        c.card,
        EXTRACT(DAY FROM rd.today - MAX(c.datetime)) AS recency,
        COUNT(*) AS frequency,
        SUM(c.summ) AS monetary
    FROM checks c
    CROSS JOIN reference_date rd
    GROUP BY c.card, rd.today
),
rfm_scored AS (
    SELECT
        card,
        recency,
        frequency,
        monetary,
        NTILE(4) OVER (ORDER BY recency ASC) AS r_score,
        NTILE(4) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(4) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_raw
),
rfm_segmented AS (
    SELECT
        card,
        recency,
        frequency,
        ROUND(monetary, 2) AS monetary,
        r_score,
        f_score,
        m_score,
        r_score || f_score || m_score AS rfm_cell,
        CASE
            -- Champions: recent, frequent, high spenders
            WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3
                THEN 'Champions'
            -- Loyal Customers: frequent and high spenders but not the most recent
            WHEN f_score >= 3 AND m_score >= 3
                THEN 'Loyal Customers'
            -- Potential Loyalists: recent buyers with moderate frequency
            WHEN r_score >= 3 AND f_score >= 2
                THEN 'Potential Loyalists'
            -- Recent Customers: very recent but low frequency/spend (new or one-time)
            WHEN r_score >= 3 AND f_score <= 2
                THEN 'Recent Customers'
            -- At Risk: used to be frequent/high spenders but haven't returned
            WHEN f_score >= 3 AND r_score <= 2
                THEN 'At Risk'
            -- Can\'t Lose Them: high monetary but low recency and frequency
            WHEN m_score >= 3 AND r_score <= 2 AND f_score <= 2
                THEN 'Cant Lose Them'
            -- Hibernating: low on all dimensions but not the worst
            WHEN r_score <= 2 AND f_score <= 2 AND m_score >= 2
                THEN 'Hibernating'
            -- Lost: lowest scores across the board
            WHEN r_score <= 1 AND f_score <= 1
                THEN 'Lost'
            ELSE 'Other'
        END AS segment
    FROM rfm_scored
)
SELECT * FROM rfm_segmented
ORDER BY segment, monetary DESC;

-- Explanation:
-- The CASE statement maps RFM score combinations to business segments.
-- These segments drive different marketing actions:
--   Champions       → reward programs, early access
--   Loyal Customers → loyalty perks, referral programs
--   Potential Loyalists → onboarding campaigns, upsell
--   Recent Customers → welcome series, first-repeat offers
--   At Risk → win-back campaigns, discounts
--   Cant Lose Them → personal outreach, high-value incentives
--   Hibernating → reactivation campaigns
--   Lost → low-cost re-engagement or deprioritize


-- ============================================================
-- STEP 5: Segment Summary Statistics
-- ============================================================
-- How many customers are in each segment? What's the average
-- recency, frequency, and monetary per segment?

WITH reference_date AS (
    SELECT MAX(datetime) AS today FROM checks
),
rfm_raw AS (
    SELECT
        c.card,
        EXTRACT(DAY FROM rd.today - MAX(c.datetime)) AS recency,
        COUNT(*) AS frequency,
        SUM(c.summ) AS monetary
    FROM checks c
    CROSS JOIN reference_date rd
    GROUP BY c.card, rd.today
),
rfm_scored AS (
    SELECT
        card,
        recency,
        frequency,
        monetary,
        NTILE(4) OVER (ORDER BY recency ASC) AS r_score,
        NTILE(4) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(4) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_raw
),
rfm_segmented AS (
    SELECT
        card,
        recency,
        frequency,
        monetary,
        CASE
            WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Champions'
            WHEN f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
            WHEN r_score >= 3 AND f_score >= 2 THEN 'Potential Loyalists'
            WHEN r_score >= 3 AND f_score <= 2 THEN 'Recent Customers'
            WHEN f_score >= 3 AND r_score <= 2 THEN 'At Risk'
            WHEN m_score >= 3 AND r_score <= 2 AND f_score <= 2 THEN 'Cant Lose Them'
            WHEN r_score <= 2 AND f_score <= 2 AND m_score >= 2 THEN 'Hibernating'
            WHEN r_score <= 1 AND f_score <= 1 THEN 'Lost'
            ELSE 'Other'
        END AS segment
    FROM rfm_scored
)
SELECT
    segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(recency), 0) AS avg_recency_days,
    ROUND(AVG(frequency), 1) AS avg_frequency,
    ROUND(AVG(monetary), 2) AS avg_monetary,
    ROUND(SUM(monetary), 2) AS total_revenue
FROM rfm_segmented
GROUP BY segment
ORDER BY total_revenue DESC;

-- Explanation:
-- This is the "dashboard view" of your RFM analysis.
-- Shows which segments are largest, most active, and most valuable.
-- Use this to prioritize marketing budget and efforts.


-- ============================================================
-- STEP 6: RFM Distribution Heatmap Data
-- ============================================================
-- Count customers in each RFM cell to see where they cluster.

WITH reference_date AS (
    SELECT MAX(datetime) AS today FROM checks
),
rfm_raw AS (
    SELECT
        c.card,
        EXTRACT(DAY FROM rd.today - MAX(c.datetime)) AS recency,
        COUNT(*) AS frequency,
        SUM(c.summ) AS monetary
    FROM checks c
    CROSS JOIN reference_date rd
    GROUP BY c.card, rd.today
),
rfm_scored AS (
    SELECT
        card,
        NTILE(4) OVER (ORDER BY recency ASC) AS r_score,
        NTILE(4) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(4) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_raw
)
SELECT
    r_score,
    f_score,
    m_score,
    COUNT(*) AS customer_count
FROM rfm_scored
GROUP BY r_score, f_score, m_score
ORDER BY r_score, f_score, m_score;

-- Explanation:
-- This produces a 4x4x4 cube of customer counts.
-- Useful for seeing the distribution — are most customers in '444'
-- (champions) or '111' (lost)? Tells you about customer health.
