-- =====================================================================
-- 09_powerbi_views.sql
-- Views that Power BI connects to (saved queries that behave like tables)
-- Re-run this file any time to rebuild them (CREATE OR REPLACE)
-- =====================================================================

USE wise_assets;


-- 1. Funnel: one row per step (funnel chart)
CREATE OR REPLACE VIEW vw_funnel AS
WITH funnel AS (
    SELECT 1 AS step_num, 'Profile created' AS step, COUNT(*) AS customers
    FROM profile_lifetime_activity
    UNION ALL
    SELECT 2, 'Completed first action', COUNT(first_completed_action)
    FROM profile_lifetime_activity
    UNION ALL
    SELECT 3, 'Held a balance', COUNT(first_balance)
    FROM profile_lifetime_activity
    UNION ALL
    SELECT 4, 'Funded (top-up)', COUNT(first_top_up)
    FROM profile_lifetime_activity
    UNION ALL
    SELECT 5, 'Invested in Assets', COUNT(first_assets)
    FROM profile_lifetime_activity
)
SELECT
    step_num, step, customers,
    ROUND(customers * 100.0 / FIRST_VALUE(customers) OVER (ORDER BY step_num), 2) AS pct_of_signups,
    ROUND(customers * 100.0 / LAG(customers) OVER (ORDER BY step_num), 2)         AS step_conversion
FROM funnel
ORDER BY step_num;


-- 2. Cohort triangle: one row per cohort x age (heatmap)
CREATE OR REPLACE VIEW vw_cohort_triangle AS
WITH RECURSIVE
-- Ages 0 to 12 (no table holds this list, so we generate it)
ages AS (
    SELECT 0 AS age
    UNION ALL
    SELECT age + 1 FROM ages WHERE age < 12
),
-- One row per cohort: size, and the oldest age it can reach.
-- 202401 = January 2024, the last month in the activity data.
cohorts AS (
    SELECT
        DATE_FORMAT(profile_created, '%Y-%m')                              AS cohort,
        COUNT(profile_created)                                             AS cohort_size,
        PERIOD_DIFF(202401, DATE_FORMAT(MIN(profile_created), '%Y%m'))     AS max_age
    FROM profile_lifetime_activity
    GROUP BY cohort
),
-- New investors per cohort per age. PERIOD_DIFF counts calendar months,
-- matching MS_TO_ASSETS in Excel (TIMESTAMPDIFF would not).
new_inv AS (
    SELECT
    DATE_FORMAT(profile_created, '%Y-%m') AS cohort,
    PERIOD_DIFF(DATE_FORMAT(first_assets, '%Y%m'), DATE_FORMAT(profile_created, '%Y%m')) AS age,
    COUNT(*) AS new_investors
FROM profile_lifetime_activity
WHERE first_assets IS NOT NULL
GROUP BY cohort, age
ORDER BY cohort, age
),
-- Every cohort x every age it has reached: the triangle shape (63 cells)
grid AS (
    SELECT c.cohort, c.cohort_size, a.age
    FROM cohorts c
    CROSS JOIN ages a
    WHERE a.age <= c.max_age
)
-- Fill gaps with 0, then a running total per cohort.
-- Key finding: at age 7, Jan-23 = 1.33% vs Jun-23 = 2.80% (later cohorts convert ~2x faster)
SELECT
    g.cohort,
    g.age,
    g.cohort_size,
    COALESCE(n.new_investors, 0) AS new_investors,
    SUM(COALESCE(n.new_investors, 0))
        OVER (PARTITION BY g.cohort ORDER BY g.age)                  AS cum_investors,
    ROUND(SUM(COALESCE(n.new_investors, 0))
        OVER (PARTITION BY g.cohort ORDER BY g.age) * 100.0
        / g.cohort_size, 2)                                          AS cum_pct
FROM grid g
LEFT JOIN new_inv n
    ON n.cohort = g.cohort AND n.age = g.age
ORDER BY g.cohort, g.age;


-- 3. Customers: one row per customer with flags (KPIs, drivers, slicers)
CREATE OR REPLACE VIEW vw_customers AS
WITH peak AS (
    SELECT
        profile_id,
        MAX(end_total_holdings_gbp
            - COALESCE(end_equity_gbp, 0)
            - COALESCE(end_interest_gbp, 0)) AS peak_cash
    FROM profile_holdings_monthly
    GROUP BY profile_id
)
SELECT
    pla.profile_id,
    pla.class,
    DATE_FORMAT(pla.profile_created, '%Y-%m')      AS cohort,
    (pla.first_top_up          IS NOT NULL)        AS is_funded,
    (pla.first_assets          IS NOT NULL)        AS is_investor,
    (pla.first_send            IS NOT NULL)        AS used_send,
    (pla.first_account_details IS NOT NULL)        AS used_account_details,
    (pla.first_direct_debit    IS NOT NULL)        AS used_direct_debit,
    (pla.first_card            IS NOT NULL)        AS used_card,
      (pla.first_send            IS NOT NULL)
    + (pla.first_balance         IS NOT NULL)
    + (pla.first_account_details IS NOT NULL)
    + (pla.first_direct_debit    IS NOT NULL)
    + (pla.first_card            IS NOT NULL)      AS n_products,
    PERIOD_DIFF(DATE_FORMAT(pla.first_assets, '%Y%m'),
                DATE_FORMAT(pla.profile_created, '%Y%m')) AS months_to_invest,
    CASE
        WHEN p.peak_cash IS NULL   THEN '0. No holdings data'
        WHEN p.peak_cash <= 0      THEN '1. Zero'
        WHEN p.peak_cash < 10      THEN '2. GBP 0-10'
        WHEN p.peak_cash < 100     THEN '3. GBP 10-100'
        WHEN p.peak_cash < 1000    THEN '4. GBP 100-1k'
        WHEN p.peak_cash < 10000   THEN '5. GBP 1k-10k'
        WHEN p.peak_cash >= 10000  THEN '6. GBP 10k+'
    END                                            AS cash_category
FROM profile_lifetime_activity pla
LEFT JOIN peak p
    ON p.profile_id = pla.profile_id;
    
    
    -- CHECK
SELECT COUNT(*), SUM(is_funded), SUM(is_investor) FROM vw_customers;  -- 10000 / 5879 / 225
SELECT * FROM vw_funnel;                                              -- 5 rows
SELECT COUNT(*) FROM vw_cohort_triangle;                              -- 63

