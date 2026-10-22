-- =====================================================================
-- 04_funnel.sql
-- Q1(a): conversion funnel to Assets
-- Reconciles to Excel tab 2_Funnel: 10,000 / 10,000 / 5,879 / 5,879 / 225
-- =====================================================================|

Select *
From profile_lifetime_activity;

USE wise_assets;

-- Version 1: quick check against Excel (one row)
-- COUNT(column) skips NULLs, so it counts only customers who did that step
SELECT
    COUNT(*)                      AS signed_up,
    COUNT(first_completed_action) AS first_action,
    COUNT(first_balance)          AS held_balance,
    COUNT(first_top_up)           AS funded,
    COUNT(first_assets)           AS invested,
    ROUND(COUNT(first_assets) * 100.0 / COUNT(*), 2)            AS conversion_all_pct,
    ROUND(COUNT(first_assets) * 100.0 / COUNT(first_top_up), 2) AS conversion_funded_pct
FROM profile_lifetime_activity;

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
ORDER BY step_num;

-- Version 2: funnel by step (one row per step, used for Power BI)
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

