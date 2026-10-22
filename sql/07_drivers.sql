-- =====================================================================
-- 07_drivers.sql
-- Q1(b): what is associated with converting to Assets
-- Reconciles to Excel tab 3_Drivers (Drivers 2, 3, 4, 5)
-- These are associations, not causes.
-- =====================================================================

USE wise_assets;

-- ---------------------------------------------------------------------
-- Part A: by signup month (Driver 2)
-- Later cohorts convert better despite having LESS time: first sign of acceleration
-- ---------------------------------------------------------------------
SELECT
    DATE_FORMAT(profile_created, '%Y-%m')                       AS cohort,
    COUNT(*)                                                    AS signed_up,
    COUNT(first_top_up)                                         AS funded,
    COUNT(first_assets)                                         AS invested,
    ROUND(COUNT(first_top_up) * 100.0 / COUNT(*), 2)            AS funded_pct,
    ROUND(COUNT(first_assets) * 100.0 / COUNT(*), 2)            AS conversion_all_pct,
    ROUND(COUNT(first_assets) * 100.0 / COUNT(first_top_up), 2) AS conversion_funded_pct
FROM profile_lifetime_activity
GROUP BY DATE_FORMAT(profile_created, '%Y-%m')
ORDER BY DATE_FORMAT(profile_created, '%Y-%m');


-- ---------------------------------------------------------------------
-- Part B: by other products used, ever (Driver 3)
-- Direct debit = strongest signal; sending money = weakest
-- (Assets is for money that stays at Wise, not money that moves through it)
-- ---------------------------------------------------------------------
SELECT
    'Sent money abroad'                                         AS product,
    COUNT(*)                                                    AS customers,
    COUNT(first_top_up)                                         AS funded,
    COUNT(first_assets)                                         AS invested,
    ROUND(COUNT(first_assets) * 100.0 / COUNT(*), 2)            AS conversion_all_pct,
    ROUND(COUNT(first_assets) * 100.0 / COUNT(first_top_up), 2) AS conversion_funded_pct
FROM profile_lifetime_activity
WHERE first_send IS NOT NULL

UNION ALL

SELECT
    'Account details',
    COUNT(*),
    COUNT(first_top_up),
    COUNT(first_assets),
    ROUND(COUNT(first_assets) * 100.0 / COUNT(*), 2),
    ROUND(COUNT(first_assets) * 100.0 / COUNT(first_top_up), 2)
FROM profile_lifetime_activity
WHERE first_account_details IS NOT NULL

UNION ALL

SELECT
    'Direct debit',
    COUNT(*),
    COUNT(first_top_up),
    COUNT(first_assets),
    ROUND(COUNT(first_assets) * 100.0 / COUNT(*), 2),
    ROUND(COUNT(first_assets) * 100.0 / COUNT(first_top_up), 2)
FROM profile_lifetime_activity
WHERE first_direct_debit IS NOT NULL

UNION ALL

SELECT
    'Card',
    COUNT(*),
    COUNT(first_top_up),
    COUNT(first_assets),
    ROUND(COUNT(first_assets) * 100.0 / COUNT(*), 2),
    ROUND(COUNT(first_assets) * 100.0 / COUNT(first_top_up), 2)
FROM profile_lifetime_activity
WHERE first_card IS NOT NULL

ORDER BY conversion_all_pct DESC;


-- ---------------------------------------------------------------------
-- Part C: by number of products used (Driver 4)
-- Products counted: send, balance, account details, direct debit, card
-- Each (... IS NOT NULL) returns 1/0, so adding them counts products per customer
-- Conversion climbs from 0.26% at 1 product to 12% at 5: depth of relationship matters
-- ---------------------------------------------------------------------
WITH num_of_prod AS (
    SELECT
        first_assets,
          (first_send            IS NOT NULL)
        + (first_balance         IS NOT NULL)
        + (first_account_details IS NOT NULL)
        + (first_direct_debit    IS NOT NULL)
        + (first_card            IS NOT NULL) AS n_products
    FROM profile_lifetime_activity
)
SELECT
    n_products,
    COUNT(*)                                         AS customers,
    COUNT(first_assets)                              AS invested,
    ROUND(COUNT(first_assets) * 100.0 / COUNT(*), 2) AS conversion_all_pct
FROM num_of_prod
GROUP BY n_products
ORDER BY n_products;


-- ---------------------------------------------------------------------
-- Part D: by peak month-end CASH balance (Driver 5)
-- Cash, not total holdings: equity and interest ARE the Assets product (circular)
-- LEFT JOIN keeps all 10,000 customers; those with no holdings rows get their own band
-- Flat ~3.3% up to £1k, then 5.8% at £1k-10k and 7.5% at £10k+
-- ---------------------------------------------------------------------
WITH peak AS (
    SELECT
        profile_id,
        MAX(end_total_holdings_gbp
            - COALESCE(end_equity_gbp, 0)
            - COALESCE(end_interest_gbp, 0)) AS peak_cash
    FROM profile_holdings_monthly
    GROUP BY profile_id
),
categorised AS (
    SELECT
        pla.first_assets,
        CASE
            WHEN p.peak_cash IS NULL   THEN '0. No holdings data'
            WHEN p.peak_cash <= 0      THEN '1. Zero'
            WHEN p.peak_cash < 10      THEN '2. GBP 0-10'
            WHEN p.peak_cash < 100     THEN '3. GBP 10-100'
            WHEN p.peak_cash < 1000    THEN '4. GBP 100-1k'
            WHEN p.peak_cash < 10000   THEN '5. GBP 1k-10k'
            WHEN p.peak_cash >= 10000  THEN '6. GBP 10k+'
        END AS cash_category
    FROM profile_lifetime_activity pla
    LEFT JOIN peak p
        ON p.profile_id = pla.profile_id
)
SELECT
    cash_category,
    COUNT(*)                                         AS customers,
    COUNT(first_assets)                              AS invested,
    ROUND(COUNT(first_assets) * 100.0 / COUNT(*), 2) AS conversion_all_pct
FROM categorised
GROUP BY cash_category
ORDER BY cash_category;


