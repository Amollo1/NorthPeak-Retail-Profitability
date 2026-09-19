-- ============================================================================
-- NorthPeak Retail — Profitability Decline Analysis
-- 02_business_analysis.sql
--
-- Purpose: Answer the core business questions defined in docs/BRD.md Section 8,
-- using the KPI formulas defined in docs/kpi_framework.md. Every metric here
-- must match the equivalent Python and Power BI calculation exactly (per the
-- KPI Framework's "single formula rule").
-- ============================================================================

SET search_path TO northpeak;


-- ============================================================================
-- SECTION 1: EXECUTIVE OVERVIEW
-- Answers: "How is the business performing overall? Are sales and profits
-- increasing? Which areas are negatively affecting profitability?"
-- (BRD Objective 1)
-- ============================================================================

-- 1.1 Overall Sales, Profit, and Margin by Year
SELECT
    d.year,
    ROUND(SUM(f.sales_amount), 2)  AS total_sales,
    ROUND(SUM(f.profit_amount), 2) AS total_profit,
    ROUND(SUM(f.profit_amount) / SUM(f.sales_amount) * 100, 2) AS margin_pct,
    COUNT(DISTINCT f.order_id) AS total_orders,
    ROUND(SUM(f.sales_amount) / COUNT(DISTINCT f.order_id), 2) AS avg_order_value
FROM fact_sales f
JOIN dim_date d ON f.order_date_key = d.date_key
GROUP BY d.year
ORDER BY d.year;

-- 1.2 Margin Trend by Quarter (the core "18% -> 11%" decline evidence)
SELECT
    d.year,
    d.quarter,
    d.fiscal_quarter,
    ROUND(SUM(f.sales_amount), 2)  AS total_sales,
    ROUND(SUM(f.profit_amount), 2) AS total_profit,
    ROUND(SUM(f.profit_amount) / SUM(f.sales_amount) * 100, 2) AS margin_pct
FROM fact_sales f
JOIN dim_date d ON f.order_date_key = d.date_key
GROUP BY d.year, d.quarter, d.fiscal_quarter
ORDER BY d.year, d.quarter;

-- 1.3 Year-over-Year Sales and Margin Change (KPI Framework Section 3)
WITH yearly AS (
    SELECT
        d.year,
        SUM(f.sales_amount)  AS total_sales,
        SUM(f.profit_amount) AS total_profit,
        SUM(f.profit_amount) / SUM(f.sales_amount) * 100 AS margin_pct
    FROM fact_sales f
    JOIN dim_date d ON f.order_date_key = d.date_key
    GROUP BY d.year
)
SELECT
    year,
    ROUND(total_sales, 2) AS total_sales,
    ROUND(margin_pct, 2)  AS margin_pct,
    ROUND(
        (total_sales - LAG(total_sales) OVER (ORDER BY year))
        / LAG(total_sales) OVER (ORDER BY year) * 100, 2
    ) AS yoy_sales_growth_pct,
    ROUND(margin_pct - LAG(margin_pct) OVER (ORDER BY year), 2) AS yoy_margin_change_pp
FROM yearly
ORDER BY year;


-- ============================================================================
-- SECTION 2: PRODUCT & CATEGORY PROFITABILITY
-- Answers: "Which products generate the highest sales/profit? Which products
-- are making losses? Which categories are affecting profitability?"
-- (BRD Objective 2)
-- ============================================================================

-- 2.1 Profit Margin by Sub-Category (should surface "Tables" as negative)
SELECT
    p.category,
    p.sub_category,
    ROUND(SUM(f.sales_amount), 2)  AS total_sales,
    ROUND(SUM(f.profit_amount), 2) AS total_profit,
    ROUND(SUM(f.profit_amount) / SUM(f.sales_amount) * 100, 2) AS margin_pct
FROM fact_sales f
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY p.category, p.sub_category
ORDER BY margin_pct ASC;

-- 2.2 Loss-Making Products (individual product level)
SELECT
    p.product_name,
    p.category,
    p.sub_category,
    ROUND(SUM(f.sales_amount), 2)  AS total_sales,
    ROUND(SUM(f.profit_amount), 2) AS total_profit,
    ROUND(SUM(f.profit_amount) / SUM(f.sales_amount) * 100, 2) AS margin_pct
FROM fact_sales f
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY p.product_name, p.category, p.sub_category
HAVING SUM(f.profit_amount) < 0
ORDER BY total_profit ASC;

-- 2.3 Revenue-Profit Divergence Index (KPI Framework Section 4)
-- Products with high sales rank but disproportionately low profit rank —
-- surfaces "hidden" margin problems that raw profit ranking alone can hide.
WITH product_totals AS (
    SELECT
        p.product_name,
        p.category,
        p.sub_category,
        SUM(f.sales_amount)  AS total_sales,
        SUM(f.profit_amount) AS total_profit
    FROM fact_sales f
    JOIN dim_product p ON f.product_key = p.product_key
    GROUP BY p.product_name, p.category, p.sub_category
),
ranked AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_sales DESC)  AS sales_rank,
        RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
    FROM product_totals
)
SELECT
    product_name,
    category,
    sub_category,
    ROUND(total_sales, 2)  AS total_sales,
    ROUND(total_profit, 2) AS total_profit,
    sales_rank,
    profit_rank,
    (profit_rank - sales_rank) AS divergence_index
FROM ranked
ORDER BY divergence_index DESC
LIMIT 10;


-- ============================================================================
-- SECTION 3: DISCOUNT ANALYSIS
-- Answers: "How do discounts affect profitability? At what discount level
-- does profit begin to decline?" (BRD Objective 3)
-- ============================================================================

-- 3.1 Sales-Weighted Average Discount by Year
-- NOTE: this is deliberately SUM(discount*sales)/SUM(sales), NOT a naive
-- AVG(discount_pct) — per KPI Framework Section 9 governance rule, since a
-- simple average would misrepresent impact when order sizes vary.
SELECT
    d.year,
    ROUND(
        SUM(f.discount_pct * f.sales_amount) / SUM(f.sales_amount) * 100, 2
    ) AS weighted_avg_discount_pct
FROM fact_sales f
JOIN dim_date d ON f.order_date_key = d.date_key
GROUP BY d.year
ORDER BY d.year;

-- 3.2 Profit Margin by Discount Band, overall
SELECT
    CASE
        WHEN f.discount_pct < 0.10 THEN '0-10%'
        WHEN f.discount_pct < 0.20 THEN '10-20%'
        WHEN f.discount_pct < 0.30 THEN '20-30%'
        ELSE '30%+'
    END AS discount_band,
    ROUND(SUM(f.sales_amount), 2)  AS total_sales,
    ROUND(SUM(f.profit_amount), 2) AS total_profit,
    ROUND(SUM(f.profit_amount) / SUM(f.sales_amount) * 100, 2) AS margin_pct
FROM fact_sales f
GROUP BY discount_band
ORDER BY discount_band;

-- 3.3 Profit Margin by Discount Band, Furniture only, Nairobi only
-- This isolates the specific region/category combination suspected of
-- discount creep — compare against 3.2's overall pattern.
SELECT
    CASE
        WHEN f.discount_pct < 0.10 THEN '0-10%'
        WHEN f.discount_pct < 0.20 THEN '10-20%'
        WHEN f.discount_pct < 0.30 THEN '20-30%'
        ELSE '30%+'
    END AS discount_band,
    ROUND(SUM(f.sales_amount), 2)  AS total_sales,
    ROUND(SUM(f.profit_amount), 2) AS total_profit,
    ROUND(SUM(f.profit_amount) / SUM(f.sales_amount) * 100, 2) AS margin_pct
FROM fact_sales f
JOIN dim_product p ON f.product_key = p.product_key
JOIN dim_region r ON f.region_key = r.region_key
WHERE p.category = 'Furniture' AND r.region = 'Nairobi'
GROUP BY discount_band
ORDER BY discount_band;

-- 3.4 Nairobi + Furniture Discount Trend Over Time (proves "discount creep")
-- Compare this trend line against the same category in ALL OTHER regions
-- (query 3.5) — Nairobi should show a rising trend that others do not.
SELECT
    d.year,
    d.quarter,
    ROUND(
        SUM(f.discount_pct * f.sales_amount) / SUM(f.sales_amount) * 100, 2
    ) AS weighted_avg_discount_pct
FROM fact_sales f
JOIN dim_date d ON f.order_date_key = d.date_key
JOIN dim_product p ON f.product_key = p.product_key
JOIN dim_region r ON f.region_key = r.region_key
WHERE p.category = 'Furniture' AND r.region = 'Nairobi'
GROUP BY d.year, d.quarter
ORDER BY d.year, d.quarter;

-- 3.5 Furniture Discount Trend, All Other Regions (comparison baseline)
SELECT
    d.year,
    d.quarter,
    ROUND(
        SUM(f.discount_pct * f.sales_amount) / SUM(f.sales_amount) * 100, 2
    ) AS weighted_avg_discount_pct
FROM fact_sales f
JOIN dim_date d ON f.order_date_key = d.date_key
JOIN dim_product p ON f.product_key = p.product_key
JOIN dim_region r ON f.region_key = r.region_key
WHERE p.category = 'Furniture' AND r.region != 'Nairobi'
GROUP BY d.year, d.quarter
ORDER BY d.year, d.quarter;

-- 3.6 Discount Breakeven Threshold, by Category
-- Approximates the discount % at which each category's margin crosses zero,
-- using discount-band midpoints. Diagnostic metric — no target/threshold,
-- per KPI Framework Section 6.
WITH band_margins AS (
    SELECT
        p.category,
        CASE
            WHEN f.discount_pct < 0.10 THEN 0.05
            WHEN f.discount_pct < 0.20 THEN 0.15
            WHEN f.discount_pct < 0.30 THEN 0.25
            WHEN f.discount_pct < 0.40 THEN 0.35
            ELSE 0.45
        END AS band_midpoint,
        f.sales_amount,
        f.profit_amount
    FROM fact_sales f
    JOIN dim_product p ON f.product_key = p.product_key
)
SELECT
    category,
    band_midpoint AS discount_band_midpoint,
    ROUND(SUM(sales_amount), 2) AS total_sales,
    ROUND(SUM(profit_amount) / SUM(sales_amount) * 100, 2) AS margin_pct
FROM band_margins
GROUP BY category, band_midpoint
ORDER BY category, band_midpoint;


-- ============================================================================
-- SECTION 4: REGIONAL PERFORMANCE
-- Answers: "Which regions perform best? Which regions generate high sales
-- but low profit?" (BRD Objective 4)
-- ============================================================================

-- 4.1 Profit Margin by Region, Most Recent Year (2025)
WITH company_avg AS (
    SELECT SUM(f.profit_amount) / SUM(f.sales_amount) * 100 AS company_margin_pct
    FROM fact_sales f
    JOIN dim_date d ON f.order_date_key = d.date_key
    WHERE d.year = 2025
)
SELECT
    r.region,
    ROUND(SUM(f.sales_amount), 2)  AS total_sales,
    ROUND(SUM(f.profit_amount), 2) AS total_profit,
    ROUND(SUM(f.profit_amount) / SUM(f.sales_amount) * 100, 2) AS margin_pct,
    ROUND(
        SUM(f.profit_amount) / SUM(f.sales_amount) * 100
        - (SELECT company_margin_pct FROM company_avg), 2
    ) AS variance_from_company_avg_pp
FROM fact_sales f
JOIN dim_date d ON f.order_date_key = d.date_key
JOIN dim_region r ON f.region_key = r.region_key
WHERE d.year = 2025
GROUP BY r.region
ORDER BY margin_pct ASC;

-- 4.2 Regional Margin Trend Over Time (all years, all regions)
SELECT
    r.region,
    d.year,
    ROUND(SUM(f.sales_amount), 2)  AS total_sales,
    ROUND(SUM(f.profit_amount) / SUM(f.sales_amount) * 100, 2) AS margin_pct
FROM fact_sales f
JOIN dim_date d ON f.order_date_key = d.date_key
JOIN dim_region r ON f.region_key = r.region_key
GROUP BY r.region, d.year
ORDER BY r.region, d.year;


-- ============================================================================
-- SECTION 5: CUSTOMER SEGMENT ANALYSIS
-- Answers: "Which customer segments are most valuable? Which segments
-- contribute most to revenue and profit?" (BRD Objective 4/5)
-- ============================================================================

-- 5.1 Profit Margin by Segment, by Year (proves Corporate margin collapse)
SELECT
    c.segment,
    d.year,
    ROUND(SUM(f.sales_amount), 2)  AS total_sales,
    ROUND(SUM(f.profit_amount), 2) AS total_profit,
    ROUND(SUM(f.profit_amount) / SUM(f.sales_amount) * 100, 2) AS margin_pct
FROM fact_sales f
JOIN dim_date d ON f.order_date_key = d.date_key
JOIN dim_customer c ON f.customer_key = c.customer_key
GROUP BY c.segment, d.year
ORDER BY c.segment, d.year;

-- 5.2 Segment Revenue Share vs. Profit Share, by Year (proves dilution)
-- The "volume growing, margin shrinking" signature: Corporate's sales_share
-- should rise over time while its profit_share stagnates or falls behind it.
WITH segment_yearly AS (
    SELECT
        d.year,
        c.segment,
        SUM(f.sales_amount)  AS segment_sales,
        SUM(f.profit_amount) AS segment_profit
    FROM fact_sales f
    JOIN dim_date d ON f.order_date_key = d.date_key
    JOIN dim_customer c ON f.customer_key = c.customer_key
    GROUP BY d.year, c.segment
),
year_totals AS (
    SELECT
        year,
        SUM(segment_sales)  AS total_sales,
        SUM(segment_profit) AS total_profit
    FROM segment_yearly
    GROUP BY year
)
SELECT
    sy.year,
    sy.segment,
    ROUND(sy.segment_sales / yt.total_sales * 100, 1)   AS sales_share_pct,
    ROUND(sy.segment_profit / yt.total_profit * 100, 1) AS profit_share_pct,
    ROUND(
        (sy.segment_sales / yt.total_sales * 100)
        - (sy.segment_profit / yt.total_profit * 100), 1
    ) AS share_gap_pp
FROM segment_yearly sy
JOIN year_totals yt ON sy.year = yt.year
ORDER BY sy.segment, sy.year;

-- 5.3 Sales per Customer, by Segment
SELECT
    c.segment,
    ROUND(SUM(f.sales_amount) / COUNT(DISTINCT f.customer_key), 2) AS sales_per_customer
FROM fact_sales f
JOIN dim_customer c ON f.customer_key = c.customer_key
GROUP BY c.segment
ORDER BY sales_per_customer DESC;


-- ============================================================================
-- SECTION 6: COMBINED ROOT-CAUSE VIEW
-- Ties Sections 3, 4, and 5 together to directly answer the BRD's core
-- question: decomposing the overall margin decline into its contributing
-- factors, rather than only showing that a decline occurred.
-- ============================================================================

-- 6.1 Margin Decline Decomposition — Corporate segment vs. All Other Segments
-- If Corporate dilution is the primary driver, "All Other Segments" margin
-- should decline far less (or not at all) compared to the Corporate line.
SELECT
    d.year,
    d.quarter,
    CASE WHEN c.segment = 'Corporate' THEN 'Corporate' ELSE 'All Other Segments' END AS segment_group,
    ROUND(SUM(f.sales_amount), 2)  AS total_sales,
    ROUND(SUM(f.profit_amount) / SUM(f.sales_amount) * 100, 2) AS margin_pct
FROM fact_sales f
JOIN dim_date d ON f.order_date_key = d.date_key
JOIN dim_customer c ON f.customer_key = c.customer_key
GROUP BY d.year, d.quarter, segment_group
ORDER BY d.year, d.quarter, segment_group;

-- 6.2 Margin Decline Decomposition — Excluding Tables Sub-Category
-- Removing the permanent "Tables" drag shows how much of the baseline
-- (pre-decline) margin gap vs. a "clean" 20%+ margin was already explained
-- by Tables alone, independent of the recent decline.
SELECT
    d.year,
    ROUND(SUM(f.sales_amount), 2)  AS total_sales,
    ROUND(SUM(f.profit_amount) / SUM(f.sales_amount) * 100, 2) AS margin_pct_excl_tables
FROM fact_sales f
JOIN dim_date d ON f.order_date_key = d.date_key
JOIN dim_product p ON f.product_key = p.product_key
WHERE p.sub_category != 'Tables'
GROUP BY d.year
ORDER BY d.year;
