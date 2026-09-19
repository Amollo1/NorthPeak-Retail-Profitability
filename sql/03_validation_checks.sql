-- ============================================================================
-- NorthPeak Retail — Profitability Decline Analysis
-- 03_validation_checks.sql
--
-- Purpose: Run the data quality checks documented in docs/data_quality_assessment.md.
-- All queries should return 0 rows / 0 counts unless explicitly noted otherwise.
-- ============================================================================

SET search_path TO northpeak;

-- ----------------------------------------------------------------------------
-- 1. COMPLETENESS — NULL checks on fact_sales
-- ----------------------------------------------------------------------------
SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL)       AS null_order_id,
    COUNT(*) FILTER (WHERE order_date_key IS NULL) AS null_order_date,
    COUNT(*) FILTER (WHERE ship_date_key IS NULL)  AS null_ship_date,
    COUNT(*) FILTER (WHERE customer_key IS NULL)   AS null_customer,
    COUNT(*) FILTER (WHERE product_key IS NULL)    AS null_product,
    COUNT(*) FILTER (WHERE region_key IS NULL)     AS null_region,
    COUNT(*) FILTER (WHERE sales_amount IS NULL)   AS null_sales,
    COUNT(*) FILTER (WHERE profit_amount IS NULL)  AS null_profit,
    COUNT(*) FILTER (WHERE discount_pct IS NULL)   AS null_discount
FROM fact_sales;
-- Expected: all zero (columns are NOT NULL, this confirms the constraint held)


-- ----------------------------------------------------------------------------
-- 2. ACCURACY — recompute sales_amount and profit_amount, compare to stored values
-- ----------------------------------------------------------------------------
SELECT COUNT(*) AS mismatched_rows
FROM fact_sales
WHERE ROUND(quantity * unit_price * (1 - discount_pct), 2) != sales_amount
   OR ROUND(sales_amount - cost_amount, 2) != profit_amount;
-- Expected: 0


-- ----------------------------------------------------------------------------
-- 3. CONSISTENCY — confirm categorical values are standardized
-- ----------------------------------------------------------------------------
SELECT DISTINCT category FROM dim_product ORDER BY category;
-- Expected: exactly 3 rows — Furniture, Office Supplies, Technology

SELECT DISTINCT segment FROM dim_customer ORDER BY segment;
-- Expected: exactly 3 rows — Consumer, Corporate, Home Office


-- ----------------------------------------------------------------------------
-- 4. UNIQUENESS — confirm no duplicate line items within an order
-- ----------------------------------------------------------------------------
SELECT order_id, product_key, COUNT(*) AS row_count
FROM fact_sales
GROUP BY order_id, product_key
HAVING COUNT(*) > 1;
-- Expected: 0 rows returned

-- Confirm order_id DOES repeat across multiple products (expected, by design —
-- grain is one row per product line item per order)
SELECT order_id, COUNT(*) AS line_items
FROM fact_sales
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY line_items DESC
LIMIT 10;
-- Expected: many orders with 2-4 line items — this is correct, not a defect


-- ----------------------------------------------------------------------------
-- 5. VALIDITY — confirm business rules were respected
-- ----------------------------------------------------------------------------
SELECT COUNT(*) AS violations
FROM fact_sales
WHERE discount_pct < 0 OR discount_pct > 0.80
   OR quantity <= 0
   OR ship_date_key < order_date_key
   OR unit_price <= 0
   OR unit_cost <= 0;
-- Expected: 0


-- ----------------------------------------------------------------------------
-- 6. REFERENTIAL INTEGRITY — orphan check (should be structurally impossible,
--    included as a defense-in-depth confirmation)
-- ----------------------------------------------------------------------------
SELECT COUNT(*) AS orphaned_rows
FROM fact_sales f
LEFT JOIN dim_date d1 ON f.order_date_key = d1.date_key
LEFT JOIN dim_date d2 ON f.ship_date_key = d2.date_key
LEFT JOIN dim_customer c ON f.customer_key = c.customer_key
LEFT JOIN dim_product p ON f.product_key = p.product_key
LEFT JOIN dim_region r ON f.region_key = r.region_key
WHERE d1.date_key IS NULL
   OR d2.date_key IS NULL
   OR c.customer_key IS NULL
   OR p.product_key IS NULL
   OR r.region_key IS NULL;
-- Expected: 0


-- ----------------------------------------------------------------------------
-- 7. ROW COUNT SUMMARY — quick sanity check against expected volumes
-- ----------------------------------------------------------------------------
SELECT 'dim_date' AS table_name, COUNT(*) FROM dim_date
UNION ALL
SELECT 'dim_customer', COUNT(*) FROM dim_customer
UNION ALL
SELECT 'dim_product', COUNT(*) FROM dim_product
UNION ALL
SELECT 'dim_region', COUNT(*) FROM dim_region
UNION ALL
SELECT 'fact_sales', COUNT(*) FROM fact_sales;
-- Expected: dim_date ~1106, dim_customer 1200, dim_product 21, dim_region 24, fact_sales ~69735
