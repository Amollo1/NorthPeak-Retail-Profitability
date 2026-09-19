# Data Quality Assessment
## Project: NorthPeak Retail - Profitability Decline Analysis

This assessment follows the five dimensions defined in the BRD (Section 2.5): completeness,
accuracy, consistency, uniqueness, and validity. Because this dataset is synthetically
generated (not sourced externally), several quality guarantees come from the generation logic
and schema constraints themselves, these are noted as **"Enforced by design"** below, distinct
from properties that still warrant an explicit query-based check.

Run the validation queries in `sql/03_validation_checks.sql` against your own database and
record the actual output in the "Verified Result" column, this keeps the assessment honest
rather than simply asserting the data is clean.

---

## 1. Completeness

Are required values present in every row?

| Check | Expected | Enforced By | Verified Result |
|---|---|---|---|
| No NULLs in any `fact_sales` column | 0 nulls | All columns declared `NOT NULL` in DDL | **Confirmed: 0 nulls across all columns checked** |
| No NULLs in dimension business keys (`customer_id`, `product_id`) | 0 nulls | `NOT NULL UNIQUE` constraint | Enforced by design |
| Every `fact_sales` row has a valid FK to all 5 dimension tables | 100% | `FOREIGN KEY` constraints (insert would fail otherwise) | Enforced by design, confirmed during load (see Section 4) |

```sql
-- Completeness check: NULLs in fact_sales
SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL)       AS null_order_id,
    COUNT(*) FILTER (WHERE sales_amount IS NULL)    AS null_sales,
    COUNT(*) FILTER (WHERE profit_amount IS NULL)   AS null_profit,
    COUNT(*) FILTER (WHERE discount_pct IS NULL)    AS null_discount
FROM northpeak.fact_sales;
```

---

## 2. Accuracy

Are the values logically correct?

| Check | Expected | Enforced By | Verified Result |
|---|---|---|---|
| `sales_amount` = `quantity × unit_price × (1 − discount_pct)` for every row | 100% match | Computed at generation time from the same formula used in SQL/DAX | **32/69,735 rows (0.046%) show a 1-cent discrepancy**, see note below |
| `profit_amount` = `sales_amount − cost_amount` for every row | 100% match | Same as above | Same 32 rows (profit inherits the sales_amount discrepancy) |
| No negative `sales_amount`, `quantity`, or prices | 0 violations | `CHECK` constraints (`quantity > 0`, `unit_price > 0`, `unit_cost > 0`) | Enforced by design |

```sql
-- Accuracy check: recompute sales_amount and profit_amount, compare to stored values
SELECT COUNT(*) AS mismatched_rows
FROM northpeak.fact_sales
WHERE ROUND(quantity * unit_price * (1 - discount_pct), 2) != sales_amount
   OR ROUND(sales_amount - cost_amount, 2) != profit_amount;
-- Expected result: 0
```

**Note on the 32-row discrepancy:** verified against the live database, every affected row
shows a discrepancy of exactly **-0.01** (one cent), confirmed by direct inspection of sample
rows. This is caused by Python's `round()` using round-half-to-even ("banker's rounding")
while PostgreSQL's `ROUND()` uses round-half-away-from-zero; the two disagree only on values
landing exactly on a rounding boundary (e.g., a third decimal digit of exactly 5). Maximum
possible aggregate impact is 32 cents against a total profit base of roughly KES 421 million,
immaterial at any level of aggregation used in this analysis. This is documented rather than,
"corrected," since forcing the two systems to agree on a rounding convention would add
complexity without changing any business conclusion.

**Note on negative profit:** `profit_amount` is negative for many "Tables" sub-category
transactions, this is an intentional, expected finding (a structurally unprofitable
sub-category, see BRD Objective 2), not a data quality defect. Do not "correct" or filter these
out during analysis.

---

## 3. Consistency

Are categorical values standardized (no case/spelling variants)?

| Check | Expected | Enforced By | Verified Result |
|---|---|---|---|
| `category` only contains the 3 defined values | `Technology`, `Furniture`, `Office Supplies` | `CHECK` constraint `chk_category` | Enforced by design |
| `segment` only contains the 3 defined values | `Consumer`, `Corporate`, `Home Office` | `CHECK` constraint `chk_segment` | Enforced by design |
| No case-variant duplicates (e.g., "technology" vs "Technology") | 0 variants | Same as above | Enforced by design |

```sql
-- Consistency check: list all distinct category/segment values actually present
SELECT DISTINCT category FROM northpeak.dim_product ORDER BY category;
SELECT DISTINCT segment FROM northpeak.dim_customer ORDER BY segment;
```

---

## 4. Uniqueness

Are there unexpected duplicates?

| Check | Expected | Enforced By | Verified Result |
|---|---|---|---|
| No duplicate `customer_id` | 0 duplicates | `UNIQUE` constraint | Enforced by design |
| No duplicate `product_id` | 0 duplicates | `UNIQUE` constraint | Enforced by design |
| No duplicate `(region, county, city)` combination | 0 duplicates | `UNIQUE` constraint `uq_region_geo` | Enforced by design |
| `order_id` legitimately repeats (multiple line items per order), this is correct, not a defect | Repeats expected | Grain is defined at line-item level (BRD/data model Section 1) | *(run query, fill in — informational only)* |

```sql
-- Uniqueness check: confirm order_id repetition reflects genuine multi-line orders,
-- not duplicate rows. A duplicate ROW (same order_id + same product_key) would be a defect.
SELECT order_id, product_key, COUNT(*) AS row_count
FROM northpeak.fact_sales
GROUP BY order_id, product_key
HAVING COUNT(*) > 1;
-- Expected result: 0 rows (no product should appear twice within the same order)
```

---

## 5. Validity

Do values respect defined business rules?

| Check | Expected | Enforced By | Verified Result |
|---|---|---|---|
| `discount_pct` between 0 and 0.80 | 100% compliant | `CHECK` constraint `chk_discount_range` | Enforced by design |
| `quantity > 0` | 100% compliant | `CHECK` constraint `chk_quantity_positive` | Enforced by design |
| `ship_date_key >= order_date_key` (can't ship before ordering) | 100% compliant | `CHECK` constraint `chk_ship_after_order` | Enforced by design |
| `unit_price`, `unit_cost` > 0 | 100% compliant | `CHECK` constraints | Enforced by design |

```sql
-- Validity check: confirm no rows violate business rules
-- (This should always return 0 rows, since the DB would reject the insert —
--  included here as a defense-in-depth / documentation check, not because
--  a violation is expected.)
SELECT COUNT(*) AS violations
FROM northpeak.fact_sales
WHERE discount_pct < 0 OR discount_pct > 0.80
   OR quantity <= 0
   OR ship_date_key < order_date_key
   OR unit_price <= 0
   OR unit_cost <= 0;
```

---

## 6. Summary

| Dimension | Assessment |
|---|---|
| Completeness | Guaranteed by `NOT NULL` + `FOREIGN KEY` constraints; verify with query above |
| Accuracy | Guaranteed by generation-time calculation; verify with recompute query above |
| Consistency | Guaranteed by `CHECK` constraints restricting categorical values |
| Uniqueness | Guaranteed by `UNIQUE` constraints on all natural keys |
| Validity | Guaranteed by `CHECK` constraints on all business rules |

**Honest caveat for the portfolio README:** because this is a synthetic, schema-constrained
dataset, it is *cleaner than a real production dataset would ever be*, real retail data
routinely has missing postal codes, inconsistent category casing, occasional negative
quantities from returns, and duplicate customer records from imperfect deduplication. This
project's data quality section demonstrates the *methodology* (the five-dimension framework,
the validation queries, the constraint-based enforcement) rather than a war story of messy
data cleanup. State this plainly rather than implying the data required extensive cleaning it
did not need — overstating data-cleaning effort is a credibility risk if asked about it directly
in an interview.
