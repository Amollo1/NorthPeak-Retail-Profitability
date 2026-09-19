# Data Dictionary
## Project: NorthPeak Retail - Profitability Decline Analysis

This dictionary documents every column in the `northpeak` schema (PostgreSQL), as implemented
in `sql/00_schema_ddl.sql` and populated by `scripts/generate_data.py`. It is the reference
for every SQL query, Python calculation, and Power BI measure built on this data.

---

## dim_date

Role-playing dimension, joined twice from `fact_sales` (`order_date_key`, `ship_date_key`).

| Column | Type | Description | Example |
|---|---|---|---|
| `date_key` | INT (PK) | Surrogate key, format YYYYMMDD | `20250716` |
| `full_date` | DATE | Calendar date | `2025-07-16` |
| `day` | SMALLINT | Day of month | `16` |
| `month` | SMALLINT | Month number (1-12) | `7` |
| `month_name` | VARCHAR(10) | Full month name | `July` |
| `quarter` | SMALLINT | Calendar quarter (1-4) | `3` |
| `year` | SMALLINT | Calendar year | `2025` |
| `day_of_week` | VARCHAR(10) | Day name | `Wednesday` |
| `is_weekend` | BOOLEAN | True if Saturday/Sunday | `false` |
| `fiscal_quarter` | VARCHAR(7) | Fiscal-year-quarter label | `FY25-Q3` |

**Coverage:** 2023-01-01 through 2026-01-10 (1,106 rows). The range extends ~10 days past the
analysis window's end (2025-12-31) solely so that `ship_date_key` values on late December orders
have a valid row to reference, orders themselves are only ever placed within 2023-01-01 to
2025-12-31.

---

## dim_customer

| Column | Type | Description | Example |
|---|---|---|---|
| `customer_key` | SERIAL (PK) | Surrogate key | `978` |
| `customer_id` | VARCHAR(20) | Business key | `CUST-00978` |
| `customer_name` | VARCHAR(150) | Individual or company name | `Wanjiru Kariuki` / `Ochieng Enterprises` |
| `segment` | VARCHAR(20) | Customer segment | `Consumer`, `Corporate`, or `Home Office` |
| `join_date` | DATE | Date customer first recorded | `2022-08-14` |

**Row count:** 1,200. Segment split at generation: 55% Consumer, 30% Corporate, 15% Home Office
(this is the *customer roster* split, note the *order volume* mix shifts over time toward
Corporate; see `fact_sales` notes below).

---

## dim_product

| Column | Type | Description | Example |
|---|---|---|---|
| `product_key` | SERIAL (PK) | Surrogate key | `14` |
| `product_id` | VARCHAR(20) | Business key | `PRD-0014` |
| `product_name` | VARCHAR(200) | Product description | `Conference Table` |
| `category` | VARCHAR(50) | Top-level category | `Technology`, `Furniture`, or `Office Supplies` |
| `sub_category` | VARCHAR(50) | Product grouping | `Tables`, `Chairs`, `Phones`, etc. |
| `base_unit_cost` | NUMERIC(12,2) | Reference cost (KES) | `22800.00` |
| `base_unit_price` | NUMERIC(12,2) | Reference price (KES) | `24500.00` |

**Row count:** 21 products across 11 sub-categories. `base_unit_cost`/`base_unit_price` are
reference values only, actual transaction-level `unit_cost`/`unit_price` in `fact_sales` vary
slightly (±2–3%) to simulate realistic price/cost fluctuation over time.

---

## dim_region

Geography reflects Kenya's administrative structure: `region` uses the 8 former provinces as a
grouping level above the 47 counties.

| Column | Type | Description | Example |
|---|---|---|---|
| `region_key` | SERIAL (PK) | Surrogate key | `9` |
| `region` | VARCHAR(30) | Former province | `Coast` |
| `county` | VARCHAR(50) | Kenyan county | `Mombasa` |
| `city` | VARCHAR(50) | City / branch location | `Mombasa` |
| `country` | VARCHAR(50) | Country | `Kenya` |

**Row count:** 24 region/county/city combinations across all 8 regions.

---

## fact_sales

**Grain: one row = one product line item within one order.** An order containing 3 products
produces 3 rows sharing the same `order_id`.

| Column | Type | Description | Example |
|---|---|---|---|
| `sales_key` | BIGSERIAL (PK) | Surrogate key | `4999` |
| `order_id` | VARCHAR(30) | Order identifier (shared across line items) | `ORD-20250716-002674` |
| `order_date_key` | INT (FK → dim_date) | Date order placed | `20250716` |
| `ship_date_key` | INT (FK → dim_date) | Date order shipped | `20250720` |
| `customer_key` | INT (FK → dim_customer) | Customer who placed the order | `1172` |
| `product_key` | INT (FK → dim_product) | Product sold | `13` |
| `region_key` | INT (FK → dim_region) | Region/branch of sale | `15` |
| `ship_mode` | VARCHAR(20) | Shipping method | `Standard Class`, `Second Class`, `First Class`, `Same Day` |
| `quantity` | INT | Units sold | `1` |
| `unit_price` | NUMERIC(12,2) | Actual transaction unit price (KES) | `11265.61` |
| `unit_cost` | NUMERIC(12,2) | Actual transaction unit cost (KES) | `7925.86` |
| `discount_pct` | NUMERIC(5,4) | Discount as decimal fraction (0.20 = 20%) | `0.0735` |
| `sales_amount` | NUMERIC(14,2) | `quantity × unit_price × (1 − discount_pct)` | `10437.59` |
| `cost_amount` | NUMERIC(14,2) | `quantity × unit_cost` | `7925.86` |
| `profit_amount` | NUMERIC(14,2) | `sales_amount − cost_amount` | `2511.73` |

**Row count:** 69,735, spanning 2023-01-01 to 2025-12-31 (order dates only).

**Important formula note:** `sales_amount`, `cost_amount`, and `profit_amount` are pre-calculated
and stored at generation time (not computed on the fly), so SQL, Python, and Power BI all read
the identical stored figures rather than risking three different rounding/calculation paths —
per the KPI Framework's "single formula rule" (Section 9).

---

## Currency Note

All monetary values are denominated in Kenyan Shillings (KES), consistent with the Kenya-based
geography used throughout the dataset. This should be stated explicitly on the Power BI
dashboard and in the Executive Summary to avoid ambiguity.
