-- =====================================================================
-- 08_cohort_triangle.sql
-- Q2: cohort development triangle (observed part)
-- Cumulative investors by signup cohort and months since signup.
-- Reconciles to Excel tab 4_Cohort_Triangle (observed triangle, counts and %).
-- Output is long format (one row per cohort per age): feeds the Power BI heatmap.
-- =====================================================================

USE wise_assets;

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











