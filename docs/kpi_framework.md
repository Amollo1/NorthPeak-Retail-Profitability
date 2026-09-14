# KPI Framework
## Project: NorthPeak Retail — Profitability Decline Analysis

---

## 1. Purpose

This document is the single source of truth for every metric used across SQL, Python, and Power BI. Each KPI is defined once here — name, formula, grain, target/threshold, owner, and dashboard placement — so that the same number is never calculated two different ways in two different tools. Every SQL query, DAX measure, and Python calculation must match the formula defined here exactly.

**Baseline reference (from BRD Section 3.1):** Profit margin declined from **18%** (historical baseline) to **11%** (current), while sales grew **22%** over six quarters. All targets/thresholds below are anchored to these BRD figures — not arbitrary.

---

## 2. Financial KPIs

| KPI | Formula | Grain | Target | Warning | Critical | Dashboard Page |
|---|---|---|---|---|---|---|
| **Total Sales** | `SUM(sales_amount)` | Any (day/month/quarter/year, by any dimension) | Growth ≥ prior period | Flat vs. prior period | Decline vs. prior period | Executive Overview |
| **Total Profit** | `SUM(profit_amount)` | Any | Growth ≥ prior period | Flat vs. prior period | Decline vs. prior period | Executive Overview |
| **Profit Margin %** | `SUM(profit_amount) / SUM(sales_amount)` | Any | **≥ 18%** (historical baseline) | 13%–17.9% | **< 13%** | Executive Overview (all pages as context) |
| **Average Order Value (AOV)** | `SUM(sales_amount) / COUNT(DISTINCT order_id)` | Any | Stable or growing vs. prior period | Declining 1 period | Declining 2+ consecutive periods | Executive Overview |
| **Average Discount %** | `AVERAGE(discount_pct)`, weighted by sales_amount | Any | **≤ 15%** | 15%–24.9% | **≥ 25%** | Discount Analysis |

---

## 3. Growth KPIs

| KPI | Formula | Grain | Target | Warning | Critical | Dashboard Page |
|---|---|---|---|---|---|---|
| **Sales Growth % (MoM)** | `(Current Month Sales − Prior Month Sales) / Prior Month Sales` | Monthly | > 0% | −5% to 0% | **< −5%** | Executive Overview |
| **Profit Growth % (MoM)** | `(Current Month Profit − Prior Month Profit) / Prior Month Profit` | Monthly | ≥ Sales Growth % (i.e., profit should not lag sales) | Below Sales Growth % | Negative while Sales Growth is positive (the core symptom of this project) | Executive Overview |
| **YoY Sales Growth %** | `(Current Year Sales − Prior Year Sales) / Prior Year Sales` | Yearly | ~22% (matches BRD baseline growth) | 10%–21.9% | **< 10%** | Executive Overview |
| **YoY Margin Change (pp)** | `Current Year Margin % − Prior Year Margin %` | Yearly | ≥ 0 percentage points | −1 to −6.9 pp | **≤ −7 pp** (matches the 18%→11% BRD decline) | Executive Overview |

---

## 4. Product & Category KPIs

| KPI | Formula | Grain | Target | Warning | Critical | Dashboard Page |
|---|---|---|---|---|---|---|
| **Profit Margin by Sub-Category** | `SUM(profit_amount) / SUM(sales_amount)`, grouped by sub_category | Sub-category | ≥ 18% | 5%–17.9% | **< 5% or negative** | Product Performance |
| **Loss-Making Product Flag** | `SUM(profit_amount) < 0`, grouped by product | Product | 0 loss-making products | 1–5 products | **6+ products** | Product Performance |
| **Revenue-Profit Divergence Index** | Rank by `SUM(sales_amount)` minus rank by `SUM(profit_amount)`, grouped by product | Product | Divergence ≤ 5 rank positions | 6–15 positions | **16+ positions** (high revenue, disproportionately low profit) | Product Performance |

---

## 5. Regional KPIs

| KPI | Formula | Grain | Target | Warning | Critical | Dashboard Page |
|---|---|---|---|---|---|---|
| **Profit Margin by Region** | `SUM(profit_amount) / SUM(sales_amount)`, grouped by region | Region | ≥ 18% | 13%–17.9% | **< 13%** | Regional Performance |
| **Regional Margin Variance** | `Region Margin % − Company-Wide Margin %` | Region | ±3 pp of company average | ±3–7 pp | **> 7 pp deviation** (outlier region) | Regional Performance |

---

## 6. Discount KPIs

| KPI | Formula | Grain | Target | Warning | Critical | Dashboard Page |
|---|---|---|---|---|---|---|
| **Profit Margin by Discount Band** | `SUM(profit_amount) / SUM(sales_amount)`, grouped by discount band (0–10%, 10–20%, 20–30%, 30%+) | Discount band, by category | Positive margin in every band | Near-zero margin in 30%+ band | **Negative margin in any band** | Discount Analysis |
| **Discount Breakeven Threshold** | Discount % at which `SUM(profit_amount) = 0`, interpolated per category | Category | N/A (diagnostic metric, not a target) | — | — | Discount Analysis |

---

## 7. Customer Segment KPIs

| KPI | Formula | Grain | Target | Warning | Critical | Dashboard Page |
|---|---|---|---|---|---|---|
| **Profit Margin by Segment** | `SUM(profit_amount) / SUM(sales_amount)`, grouped by segment | Segment | ≥ 18% | 13%–17.9% | **< 13%** | Customer Segment |
| **Segment Revenue Share vs. Profit Share** | `Segment Sales / Total Sales` vs. `Segment Profit / Total Profit` | Segment | Shares roughly aligned (±5 pp) | 5–15 pp gap | **> 15 pp gap** (volume/margin dilution) | Customer Segment |

---

## 8. Operational KPIs

| KPI | Formula | Grain | Target | Warning | Critical | Dashboard Page |
|---|---|---|---|---|---|---|
| **Number of Orders** | `COUNT(DISTINCT order_id)` | Any | Growth ≥ prior period | Flat | Decline | Executive Overview |
| **Quantity Sold** | `SUM(quantity)` | Any | Growth ≥ prior period | Flat | Decline | Product Performance |
| **Sales per Customer** | `SUM(sales_amount) / COUNT(DISTINCT customer_id)` | Any | Stable or growing | Declining 1 period | Declining 2+ periods | Customer Segment |

---

## 9. KPI Governance Notes

- **Single formula rule:** Every KPI above must be implemented identically in SQL (`sql/03_business_analysis.sql`), Python (`notebooks/retail_analysis.ipynb`), and Power BI (DAX measures). Any discrepancy found during development must be resolved by correcting the deviation — not by treating small differences as acceptable.
- **Weighted averages:** `Average Discount %` and similar metrics must be **sales-weighted**, not a simple row-level average — a common analyst error that silently misrepresents impact when order sizes vary.
- **Thresholds are diagnostic, not decorative:** Every warning/critical threshold above is used later for conditional formatting in Power BI (red/amber/green), so the visual severity on the dashboard is derived from this table, not chosen arbitrarily during dashboard design.
- **Traceability:** Every KPI here maps to a Functional Requirement (Section 2 of `requirements.md`) and a BRD Objective — this framework is the bridge between "what we said we'd measure" and "what the dashboard actually shows."

---

## 10. KPI-to-Dashboard-Page Summary

| Dashboard Page | KPIs Featured |
|---|---|
| Executive Overview | Total Sales, Total Profit, Profit Margin %, AOV, Sales/Profit Growth %, YoY Margin Change |
| Product Performance | Margin by Sub-Category, Loss-Making Product Flag, Revenue-Profit Divergence Index, Quantity Sold |
| Discount Analysis | Average Discount %, Margin by Discount Band, Discount Breakeven Threshold |
| Regional Performance | Margin by Region, Regional Margin Variance |
| Customer Segment | Margin by Segment, Segment Revenue vs. Profit Share, Sales per Customer |
