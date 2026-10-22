-- =====================================================================
-- 03_import_checks.sql
-- Confirms the import is complete and the data is structurally sound
-- before any analysis. Every row should show PASS.
-- =====================================================================

USE wise_assets;

WITH checks AS (

    -- Completeness: every source row arrived
    SELECT 1 AS id, 'Customers: row count' AS check_name,
           CAST(COUNT(*) AS CHAR) AS actual, '10000' AS expected
    FROM profile_lifetime_activity
    UNION ALL
    SELECT 2, 'Holdings: row count',
           CAST(COUNT(*) AS CHAR), '18010'
    FROM profile_holdings_monthly
    UNION ALL
    SELECT 3, 'Onboarding: row count',
           CAST(COUNT(*) AS CHAR), '10'
    FROM profiles_onboarded_monthly

    -- Customer mix
    UNION ALL
    SELECT 4, 'Customers: Personal',
           CAST(SUM(class = 'Personal') AS CHAR), '8487'
    FROM profile_lifetime_activity
    UNION ALL
    SELECT 5, 'Customers: Business',
           CAST(SUM(class = 'Business') AS CHAR), '1513'
    FROM profile_lifetime_activity

    -- Date coverage of each table
    UNION ALL
    SELECT 6, 'Customers: first signup date',
           CAST(DATE(MIN(profile_created)) AS CHAR), '2023-01-01'
    FROM profile_lifetime_activity
    UNION ALL
    SELECT 7, 'Customers: last signup date',
           CAST(DATE(MAX(profile_created)) AS CHAR), '2023-06-30'
    FROM profile_lifetime_activity
    UNION ALL
    SELECT 8, 'Holdings: first month',
           CAST(MIN(month_balance) AS CHAR), '2023-01-01'
    FROM profile_holdings_monthly
    UNION ALL
    SELECT 9, 'Holdings: last month',
           CAST(MAX(month_balance) AS CHAR), '2023-06-01'
    FROM profile_holdings_monthly
    UNION ALL
    SELECT 10, 'Holdings: distinct customers',
           CAST(COUNT(DISTINCT profile_id) AS CHAR), '5387'
    FROM profile_holdings_monthly
    UNION ALL
    SELECT 11, 'Onboarding: last month',
           CAST(MAX(month) AS CHAR), '2023-05-01'
    FROM profiles_onboarded_monthly

    -- Logic: no product used before the profile existed
    UNION ALL
    SELECT 12, 'Customers: events before signup',
           CAST(COUNT(*) AS CHAR), '0'
    FROM profile_lifetime_activity
    WHERE first_completed_action < profile_created
       OR first_send             < profile_created
       OR first_balance          < profile_created
       OR first_top_up           < profile_created
       OR first_account_details  < profile_created
       OR first_direct_debit     < profile_created
       OR first_card             < profile_created
       OR first_assets           < profile_created

    -- Blanks loaded as NULL, not as zero dates
    UNION ALL
    SELECT 13, 'Customers: zero dates loaded',
           CAST(COUNT(*) AS CHAR), '0'
    FROM profile_lifetime_activity
    WHERE YEAR(first_send) = 0
       OR YEAR(first_assets) = 0
       OR YEAR(first_direct_debit) = 0
)

SELECT
    check_name,
    actual,
    expected,
    CASE WHEN actual = expected THEN 'PASS' ELSE 'FAIL' END AS result
FROM checks
ORDER BY id;
