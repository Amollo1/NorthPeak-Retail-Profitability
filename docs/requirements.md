# Functional & Non-Functional Requirements
## Project: NorthPeak Retail - Profitability Decline Analysis

---

## 1. Purpose

This document translates the objectives defined in the BRD into specific, testable requirements. Each functional requirement (FR) traces back to a BRD objective, and each is written so it can be verified against the final deliverables (SQL scripts, Python notebook, Power BI dashboard).

---

## 2. Functional Requirements

### 2.1 Data & Data Model

| ID | Requirement | Traces to (BRD Objective) | Acceptance Criteria |
|---|---|---|---|
| FR-01 | The system shall store sales transactions in a normalized star schema (fact + dimension tables) in PostgreSQL. | Foundation for all objectives | Schema includes `fact_sales` and dimensions for date, customer, product, region |
| FR-02 | The dataset shall cover a minimum 3-year historical period at daily transaction grain, aggregable to monthly/quarterly. | Obj. 1 | `dim_date` supports day/month/quarter/year rollups |
| FR-03 | The dataset shall include cost, discount, and profit fields sufficient to calculate margin at the transaction level. | Obj. 1–4 | `fact_sales` includes `unit_cost`, `unit_price`, `discount_pct`, `sales_amount`, `profit_amount` |
| FR-04 | Data quality shall be documented, including completeness, validity, and consistency checks. | Data trustworthiness | `data_dictionary.md` and quality assessment completed pre-analysis |

### 2.2 Analysis

| ID | Requirement | Traces to | Acceptance Criteria |
|---|---|---|---|
| FR-05 | The solution shall calculate and trend overall profit margin by month and quarter. | Obj. 1 | SQL/Python output shows margin trend from baseline (~18%) to current (~11%) |
| FR-06 | The solution shall rank products/sub-categories by total profit and by profit margin, separately. | Obj. 2 | Query/notebook output identifies top and bottom performers on both dimensions |
| FR-07 | The solution shall identify products or categories with negative or near-zero margin. | Obj. 2 | Explicit list of loss-making products with revenue and profit figures |
| FR-08 | The solution shall analyze profit and margin across discount bands (e.g., 0–10%, 10–20%, 20–30%, 30%+). | Obj. 3 | Output shows margin trend across discount bands, by category |
| FR-09 | The solution shall identify the approximate discount threshold at which profit turns negative, where applicable. | Obj. 3 | Threshold identified and quantified per affected category |
| FR-10 | The solution shall compare profitability across regions and flag statistically or materially significant underperformers. | Obj. 4 | Region-level margin comparison with outliers identified |
| FR-11 | The solution shall compare profitability across customer segments (Consumer, Corporate, Home Office). | Obj. 4 | Segment-level revenue, profit, and margin comparison |
| FR-12 | The solution shall quantify the estimated profit impact of each major recommendation. | Obj. 5 | Recommendations report includes estimated $ or % impact per recommendation |

### 2.3 Dashboard (Power BI)

| ID | Requirement | Traces to | Acceptance Criteria |
|---|---|---|---|
| FR-13 | The dashboard shall provide an Executive Overview page showing total sales, total profit, margin %, and margin trend. | Obj. 1 | Page exists with KPI cards + trend visual |
| FR-14 | The dashboard shall provide a Product Performance page with category/sub-category profitability drill-down. | Obj. 2 | Page exists with ranked visuals + drill-through |
| FR-15 | The dashboard shall provide a Discount Analysis page showing profit/margin by discount band. | Obj. 3 | Page exists with discount-band visual |
| FR-16 | The dashboard shall provide a Regional Performance page with geographic and comparative visuals. | Obj. 4 | Page exists with map or regional comparison visual |
| FR-17 | The dashboard shall provide a Customer Segment page comparing segment profitability. | Obj. 4 | Page exists with segment comparison visual |
| FR-18 | All dashboard KPIs shall be calculated via DAX measures (not pre-aggregated in Power Query), to reflect production BI practice. | Maintainability | Measures visible and documented in the model |
| FR-19 | The dashboard shall allow filtering by date range, region, category, and segment across all pages. | Usability | Slicers present and synced appropriately |

### 2.4 Documentation & Reporting

| ID | Requirement | Traces to | Acceptance Criteria |
|---|---|---|---|
| FR-20 | An executive summary shall be produced, written for a non-technical audience, under 1–2 pages. | Communication | Document exists, free of technical jargon |
| FR-21 | A business recommendations report shall list prioritized actions, each tied to a specific finding and quantified impact. | Obj. 5 | Report exists with traceable finding → recommendation → impact structure |

---

## 3. Non-Functional Requirements

Kept lightweight and proportional to a solo portfolio project, but realistic enough to demonstrate awareness of production concerns.

| ID | Category | Requirement |
|---|---|---|
| NFR-01 | **Performance** | Power BI dashboard pages shall render within ~3–5 seconds on standard hardware, using DirectQuery or a well-optimized import model (aggregations/star schema, not flat wide tables). |
| NFR-02 | **Scalability** | The data model shall support scaling from the current ~50–100K synthetic transactions to 1M+ rows without structural redesign (i.e., star schema, indexed keys). |
| NFR-03 | **Maintainability** | All SQL scripts, Python code, and DAX measures shall be version-controlled in GitHub with clear naming conventions and inline comments. |
| NFR-04 | **Data Quality** | Referential integrity shall be enforced between fact and dimension tables (foreign key constraints in PostgreSQL). |
| NFR-05 | **Security (simulated)** | Documentation shall describe how row-level security *would* be applied in Power BI (e.g., regional managers restricted to their own region) even though not enforced in this single-user portfolio context. |
| NFR-06 | **Reproducibility** | The synthetic dataset shall be generated with a fixed random seed so results are reproducible on re-run. |
| NFR-07 | **Documentation** | Every deliverable (schema, scripts, dashboard, reports) shall be accompanied by a README or inline documentation sufficient for a third party to understand and reproduce the work. |
| NFR-08 | **Refresh Frequency (simulated)** | Documentation shall specify an assumed production refresh cadence (e.g., "daily incremental load, monthly full refresh") even though this portfolio version is a static dataset. |
| NFR-09 | **Portability** | The PostgreSQL schema and Python scripts shall not depend on proprietary or paid tooling, ensuring the project can be reproduced by anyone reviewing the portfolio. |

---

## 4. Traceability Note

Every FR above maps to a BRD objective, and every dashboard page (FR-13 to FR-17) maps to a specific analytical requirement rather than existing decoratively. This traceability will be referenced again in the **Executive Summary** to demonstrate that the delivered solution fully satisfies the original business requirements, a detail hiring managers and technical reviewers specifically look for, since most portfolio dashboards are built without ever re-checking them against stated objectives.
