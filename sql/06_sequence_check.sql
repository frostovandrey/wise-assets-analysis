-- =====================================================================
-- 06_sequence_check.sql
-- Q1(a) Funnel 3: what the 225 investors had done BEFORE investing
-- Reconciles to Excel tab 2_Funnel (Funnel 3): 225/225/132/114/28/23
-- =====================================================================

USE wise_assets;

-- Version 1: one row
-- A comparison returns 1 (true) / 0 (false) / NULL (date missing), and SUM skips NULLs
SELECT
    COUNT(*)                                   AS investors,
    SUM(first_balance         <= first_assets) AS balance_before,
    SUM(first_top_up          <= first_assets) AS top_up_before,
    SUM(first_account_details <= first_assets) AS account_details_before,
    SUM(first_card            <= first_assets) AS card_before,
    SUM(first_send            <= first_assets) AS send_before,
    SUM(first_direct_debit    <= first_assets) AS direct_debit_before
FROM profile_lifetime_activity
WHERE first_assets IS NOT NULL;

-- Version 2: one row per product (used for Power BI)
WITH seq AS (
    SELECT
        COUNT(*)                                   AS investors,
        SUM(first_balance         <= first_assets) AS balance_before,
        SUM(first_top_up          <= first_assets) AS top_up_before,
        SUM(first_account_details <= first_assets) AS account_details_before,
        SUM(first_card            <= first_assets) AS card_before,
        SUM(first_send            <= first_assets) AS send_before,
        SUM(first_direct_debit    <= first_assets) AS direct_debit_before
    FROM profile_lifetime_activity
    WHERE first_assets IS NOT NULL
)
SELECT 'Held a balance' AS product, balance_before AS used_before,
       ROUND(balance_before * 100.0 / investors, 2) AS pct_of_investors
FROM seq
UNION ALL
SELECT 'Funded (top-up)', top_up_before, ROUND(top_up_before * 100.0 / investors, 2) FROM seq
UNION ALL
SELECT 'Account details', account_details_before, ROUND(account_details_before * 100.0 / investors, 2) FROM seq
UNION ALL
SELECT 'Card', card_before, ROUND(card_before * 100.0 / investors, 2) FROM seq
UNION ALL
SELECT 'Sent money abroad', send_before, ROUND(send_before * 100.0 / investors, 2) FROM seq
UNION ALL
SELECT 'Direct debit', direct_debit_before, ROUND(direct_debit_before * 100.0 / investors, 2) FROM seq;