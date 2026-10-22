-- =====================================================================
-- 02_load_data.sql
-- Loads the three CSV files into the tables from 01_create_tables.sql
--
-- BEFORE RUNNING:
--   1. Run:  SHOW VARIABLES LIKE 'secure_file_priv';
--      MySQL only reads files from the folder it shows. On Windows this is
--      usually  C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/
--      (8.4 instead of 8.0 if you installed 8.4).
--   2. Copy the three CSV files into that folder.
--   3. If your folder differs, replace the path in the three
--      LOAD DATA lines below (use forward slashes / even on Windows).
--   4. Do not open and re-save the CSVs in Excel: it changes the date
--      formats and breaks the import.
--
-- If secure_file_priv shows NULL, LOAD DATA is disabled on your install.
-- Use 02_alt_insert_data.sql instead (same result, no settings needed).
-- =====================================================================

USE wise_assets;

-- Empty CSV cells must become NULL, not errors, hence the
-- @variable + NULLIF pattern. TRIM handles Windows line endings (\r)
-- on the last column of each file.

-- 1. Customers (load first: the holdings table references it)
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/profile_lifetime_activity.csv'
INTO TABLE profile_lifetime_activity
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(profile_id, profile_created, class,
 @first_completed_action, @first_send, @first_balance, @first_top_up,
 @first_account_details, @first_direct_debit, @first_card, @first_assets)
SET
    first_completed_action = NULLIF(@first_completed_action, ''),
    first_send             = NULLIF(@first_send, ''),
    first_balance          = NULLIF(@first_balance, ''),
    first_top_up           = NULLIF(@first_top_up, ''),
    first_account_details  = NULLIF(@first_account_details, ''),
    first_direct_debit     = NULLIF(@first_direct_debit, ''),
    first_card             = NULLIF(@first_card, ''),
    first_assets           = NULLIF(TRIM(TRAILING '\r' FROM @first_assets), '');

-- 2. Monthly holdings
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/profile_holdings_monthly.csv'
INTO TABLE profile_holdings_monthly
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(profile_id, month_balance,
 @beginning_total_holdings_gbp, end_total_holdings_gbp,
 @beginning_equity_gbp, @end_equity_gbp,
 @beginning_interest_gbp, @end_interest_gbp)
SET
    beginning_total_holdings_gbp = NULLIF(@beginning_total_holdings_gbp, ''),
    beginning_equity_gbp         = NULLIF(@beginning_equity_gbp, ''),
    end_equity_gbp               = NULLIF(@end_equity_gbp, ''),
    beginning_interest_gbp       = NULLIF(@beginning_interest_gbp, ''),
    end_interest_gbp             = NULLIF(TRIM(TRAILING '\r' FROM @end_interest_gbp), '');

-- 3. Onboarding totals (whole customer base)
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/profiles_onboarded_monthly.csv'
INTO TABLE profiles_onboarded_monthly
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(month, class, @count_profile)
SET
    count_profile = TRIM(TRAILING '\r' FROM @count_profile);
