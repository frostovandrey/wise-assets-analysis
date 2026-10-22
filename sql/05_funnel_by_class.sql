-- =====================================================================
-- 05_funnel_by_class.sql
-- Q1(b) Driver 1: Personal vs Business
-- Reconciles to Excel tab 3_Drivers (Driver 1)
-- =====================================================================

USE wise_assets;

SELECT
    class,
    COUNT(*)                                                    AS signed_up,
    COUNT(first_top_up)                                         AS funded,
    COUNT(first_assets)                                         AS invested,
    ROUND(COUNT(first_top_up) * 100.0 / COUNT(*), 2)            AS funded_pct,
    ROUND(COUNT(first_assets) * 100.0 / COUNT(*), 2)            AS conversion_all_pct,
    ROUND(COUNT(first_assets) * 100.0 / COUNT(first_top_up), 2) AS conversion_funded_pct
FROM profile_lifetime_activity
GROUP BY class
ORDER BY class;