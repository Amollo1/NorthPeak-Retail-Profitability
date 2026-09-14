-- ============================================================================
-- NorthPeak Retail — Profitability Decline Analysis
-- 00_schema_ddl.sql
--
-- Purpose: Create the star schema (fact + dimension tables) in PostgreSQL.
-- Run this BEFORE the Python data generation script loads any data.
--
-- Design reference: docs/data_model.md
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 0. Schema setup
-- ----------------------------------------------------------------------------
DROP SCHEMA IF EXISTS northpeak CASCADE;
CREATE SCHEMA northpeak;
SET search_path TO northpeak;

-- ----------------------------------------------------------------------------
-- 1. dim_date
--    Role-playing dimension: referenced twice from fact_sales
--    (order_date_key and ship_date_key)
-- ----------------------------------------------------------------------------
CREATE TABLE dim_date (
    date_key        INT PRIMARY KEY,              -- format YYYYMMDD
    full_date       DATE NOT NULL UNIQUE,
    day             SMALLINT NOT NULL,
    month           SMALLINT NOT NULL,
    month_name      VARCHAR(10) NOT NULL,
    quarter         SMALLINT NOT NULL,
    year            SMALLINT NOT NULL,
    day_of_week     VARCHAR(10) NOT NULL,
    is_weekend      BOOLEAN NOT NULL,
    fiscal_quarter  VARCHAR(7) NOT NULL,           -- e.g. 'FY24-Q1'
    CONSTRAINT chk_month CHECK (month BETWEEN 1 AND 12),
    CONSTRAINT chk_quarter CHECK (quarter BETWEEN 1 AND 4)
);

-- ----------------------------------------------------------------------------
-- 2. dim_customer
-- ----------------------------------------------------------------------------
CREATE TABLE dim_customer (
    customer_key    SERIAL PRIMARY KEY,
    customer_id     VARCHAR(20) NOT NULL UNIQUE,   -- business/natural key
    customer_name   VARCHAR(150) NOT NULL,
    segment         VARCHAR(20) NOT NULL,
    join_date       DATE,
    CONSTRAINT chk_segment CHECK (segment IN ('Consumer', 'Corporate', 'Home Office'))
);

-- ----------------------------------------------------------------------------
-- 3. dim_product
-- ----------------------------------------------------------------------------
CREATE TABLE dim_product (
    product_key     SERIAL PRIMARY KEY,
    product_id      VARCHAR(20) NOT NULL UNIQUE,   -- business/natural key
    product_name    VARCHAR(200) NOT NULL,
    category        VARCHAR(50) NOT NULL,
    sub_category    VARCHAR(50) NOT NULL,
    base_unit_cost  NUMERIC(12,2) NOT NULL,
    base_unit_price NUMERIC(12,2) NOT NULL,
    CONSTRAINT chk_category CHECK (category IN ('Technology', 'Furniture', 'Office Supplies')),
    CONSTRAINT chk_base_cost_positive CHECK (base_unit_cost > 0),
    CONSTRAINT chk_base_price_positive CHECK (base_unit_price > 0)
);

-- ----------------------------------------------------------------------------
-- 4. dim_region
-- ----------------------------------------------------------------------------
CREATE TABLE dim_region (
    region_key      SERIAL PRIMARY KEY,
    region          VARCHAR(30) NOT NULL,          -- former province grouping, e.g. 'Rift Valley'
    county          VARCHAR(50) NOT NULL,          -- Kenyan county, e.g. 'Uasin Gishu'
    city            VARCHAR(50) NOT NULL,
    country         VARCHAR(50) NOT NULL DEFAULT 'Kenya',
    CONSTRAINT uq_region_geo UNIQUE (region, county, city)
);

-- ----------------------------------------------------------------------------
-- 5. fact_sales
--    Grain: one row = one product line item within one order
-- ----------------------------------------------------------------------------
CREATE TABLE fact_sales (
    sales_key       BIGSERIAL PRIMARY KEY,
    order_id        VARCHAR(30) NOT NULL,
    order_date_key  INT NOT NULL REFERENCES dim_date(date_key),
    ship_date_key   INT NOT NULL REFERENCES dim_date(date_key),
    customer_key    INT NOT NULL REFERENCES dim_customer(customer_key),
    product_key     INT NOT NULL REFERENCES dim_product(product_key),
    region_key      INT NOT NULL REFERENCES dim_region(region_key),
    ship_mode       VARCHAR(20) NOT NULL,
    quantity        INT NOT NULL,
    unit_price      NUMERIC(12,2) NOT NULL,
    unit_cost       NUMERIC(12,2) NOT NULL,
    discount_pct    NUMERIC(5,4) NOT NULL,          -- stored as decimal fraction, e.g. 0.20 = 20%
    sales_amount    NUMERIC(14,2) NOT NULL,
    cost_amount     NUMERIC(14,2) NOT NULL,
    profit_amount   NUMERIC(14,2) NOT NULL,

    CONSTRAINT chk_quantity_positive CHECK (quantity > 0),
    CONSTRAINT chk_discount_range CHECK (discount_pct >= 0 AND discount_pct <= 0.80),
    CONSTRAINT chk_unit_price_positive CHECK (unit_price > 0),
    CONSTRAINT chk_unit_cost_positive CHECK (unit_cost > 0),
    CONSTRAINT chk_ship_after_order CHECK (ship_date_key >= order_date_key)
);

-- ----------------------------------------------------------------------------
-- 6. Indexes
--    Rationale documented in docs/data_model.md Section 4
-- ----------------------------------------------------------------------------
CREATE INDEX idx_fact_sales_order_date ON fact_sales(order_date_key);
CREATE INDEX idx_fact_sales_product ON fact_sales(product_key);
CREATE INDEX idx_fact_sales_region ON fact_sales(region_key);
CREATE INDEX idx_fact_sales_customer ON fact_sales(customer_key);
CREATE INDEX idx_fact_sales_date_product ON fact_sales(order_date_key, product_key);

-- ----------------------------------------------------------------------------
-- 7. Comments (self-documenting schema — visible in DBeaver/pgAdmin metadata)
-- ----------------------------------------------------------------------------
COMMENT ON TABLE fact_sales IS 'Grain: one row per product line item per order. Core fact table for all profitability analysis.';
COMMENT ON COLUMN fact_sales.discount_pct IS 'Stored as decimal fraction (0.20 = 20%), never as whole number, per KPI Framework Section 9 naming convention.';
COMMENT ON TABLE dim_date IS 'Role-playing dimension: joined twice from fact_sales (order_date_key, ship_date_key).';
COMMENT ON COLUMN dim_product.base_unit_cost IS 'Reference cost only. Actual transaction-level unit_cost lives in fact_sales and may differ over time.';

-- ============================================================================
-- End of schema DDL. Next step: run the Python data generation script
-- (scripts/generate_data.py) to populate these tables.
-- ============================================================================