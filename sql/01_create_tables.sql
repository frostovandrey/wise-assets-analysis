-- =====================================================================
-- 01_create_tables.sql
-- Wise Assets adoption project: database and table definitions
-- Target: MySQL 8.0.16 or newer
--
-- Run this first. It is safe to re-run: it drops and rebuilds the three
-- tables, so reload the data afterwards (02_load_data.sql).
-- =====================================================================

CREATE DATABASE IF NOT EXISTS wise_assets
    DEFAULT CHARACTER SET utf8mb4;

USE wise_assets;

-- Drop children before the parent so the foreign key does not block it
DROP TABLE IF EXISTS profile_holdings_monthly;
DROP TABLE IF EXISTS profiles_onboarded_monthly;
DROP TABLE IF EXISTS profile_lifetime_activity;


-- ---------------------------------------------------------------------
-- 1. profile_lifetime_activity
--    One row per sampled customer (10,000 profiles created Jan-Jun 2023).
--    Each first_* column is the first time the customer used that product.
--    NULL = the customer never used it.
-- ---------------------------------------------------------------------
CREATE TABLE profile_lifetime_activity (
    profile_id              BIGINT       NOT NULL,
    profile_created         DATETIME     NOT NULL,
    class                   VARCHAR(10)  NOT NULL,
    first_completed_action  DATETIME(3)  NULL,
    first_send              DATETIME(3)  NULL,
    first_balance           DATETIME(3)  NULL,
    first_top_up            DATETIME(3)  NULL,
    first_account_details   DATETIME(3)  NULL,
    first_direct_debit      DATETIME(3)  NULL,
    first_card              DATETIME(3)  NULL,
    first_assets            DATETIME(3)  NULL,
    PRIMARY KEY (profile_id),
    CONSTRAINT chk_activity_class CHECK (class IN ('Personal', 'Business'))
);


-- ---------------------------------------------------------------------
-- 2. profile_holdings_monthly
--    One row per customer per month (Jan-Jun 2023), values in GBP.
--    Total holdings = cash + equity + interest.
--    NULL in the equity / interest columns = customer held none that month.
--    NULL in beginning_total = no balance at the start of that month.
-- ---------------------------------------------------------------------
CREATE TABLE profile_holdings_monthly (
    profile_id                    BIGINT         NOT NULL,
    month_balance                 DATE           NOT NULL,
    beginning_total_holdings_gbp  DECIMAL(12,2)  NULL,
    end_total_holdings_gbp        DECIMAL(12,2)  NOT NULL,
    beginning_equity_gbp          DECIMAL(12,2)  NULL,
    end_equity_gbp                DECIMAL(12,2)  NULL,
    beginning_interest_gbp        DECIMAL(12,2)  NULL,
    end_interest_gbp              DECIMAL(12,2)  NULL,
    PRIMARY KEY (profile_id, month_balance),
    CONSTRAINT fk_holdings_profile
        FOREIGN KEY (profile_id)
        REFERENCES profile_lifetime_activity (profile_id)
);


-- ---------------------------------------------------------------------
-- 3. profiles_onboarded_monthly
--    Aggregate number of new profiles across ALL Wise customers
--    (not just the sample), by month and class, Jan-May 2023.
-- ---------------------------------------------------------------------
CREATE TABLE profiles_onboarded_monthly (
    month          DATE         NOT NULL,
    class          VARCHAR(10)  NOT NULL,
    count_profile  INT          NOT NULL,
    PRIMARY KEY (month, class),
    CONSTRAINT chk_onboarded_class CHECK (class IN ('Personal', 'Business'))
);
