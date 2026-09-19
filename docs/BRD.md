# Business Requirements Document (BRD)
## Project: NorthPeak Retail - Profitability Decline Analysis

**Document Version:** 1.0
**Status:** Approved for Phase 2 (Data Modeling & Generation)
**Prepared by:** Benard Onyango Omoga, Business/Data Analyst
**Date:** September 2026

---

## 1. Executive Summary

NorthPeak Retail Group has experienced strong top-line sales growth over the past six quarters, but profit margins have declined significantly in the same period. This document defines the business problem, objectives, stakeholders, scope, and requirements for an analytics project to identify the root causes of margin erosion and produce actionable recommendations.

---

## 2. Company Background

**Company:** NorthPeak Retail Group
**Industry:** Multi-category retail (Technology, Furniture, Office Supplies)
**Channels:** Physical stores (multi-region) + Online
**Customer Segments:** Consumer, Corporate, Home Office

NorthPeak operates across multiple regions and sells through both retail and e-commerce channels. Reporting today is fragmented — regional sales reports and finance P&L statements exist independently, with no unified, product- and region-level profitability view.

---

## 3. Business Problem

### 3.1 Problem Statement

> NorthPeak's overall profit margin has declined from approximately **18% to 11%** over the past **six quarters**, despite sales growing **22%** in the same period. Management lacks visibility into which products, regions, customer segments, or discounting practices are driving this margin erosion, and has no data-driven basis for corrective action.

### 3.2 Business Impact if Unresolved

- Continued margin compression despite revenue growth erodes shareholder value and reduces reinvestment capacity.
- Discounting and product-mix decisions continue to be made without profitability visibility, risking further erosion.
- Regional and category-level underperformance may go unaddressed, compounding losses.

### 3.3 Core Business Question

**Why is revenue growing while profitability declines, and what specific, quantified actions would restore margin without materially sacrificing sales growth?**

---

## 4. Project Goal

Analyze NorthPeak's sales, cost, and discount data to identify the primary drivers of the margin decline across products, regions, and customer segments, and deliver prioritized, quantified recommendations to restore profitability.

---

## 5. Project Objectives

| # | Objective | Success Indicator |
|---|---|---|
| 1 | Quantify the margin decline and establish a trend baseline | Monthly/quarterly margin trend clearly visualized and explained |
| 2 | Identify product categories/sub-categories that are net-negative or margin-dilutive | Ranked list of loss-making or low-margin products with contribution to overall decline |
| 3 | Determine whether discounting is a statistically meaningful driver of margin decline | Identified discount threshold beyond which profit turns negative, by category |
| 4 | Identify regional and segment-level variance in profitability | Regions/segments ranked by margin, outliers flagged |
| 5 | Translate findings into prioritized, quantified recommendations | Each recommendation tied to an estimated profit impact |

---

## 6. Stakeholders

*(Full detail in `stakeholder_map.md` — summarized here for BRD completeness)*

| Stakeholder | Primary Interest |
|---|---|
| CEO / Executive Team | Overall profitability recovery, strategic direction |
| Finance Manager | Margin accuracy, root-cause validation |
| Sales Director | Understanding sales-vs-margin tradeoffs, discount policy impact |
| Regional Managers | Regional performance visibility, accountability |
| Product/Category Managers | Product-level profitability, category strategy |
| Marketing Team | Segment profitability, promotional discount effectiveness |
| Business/Data Analyst (project owner) | Delivering the analysis and dashboard |

---

## 7. Scope

### 7.1 In Scope
- Historical sales, cost, discount, and profit analysis (synthetic dataset, 3-year history)
- Product and sub-category profitability analysis
- Regional performance analysis
- Customer segment profitability analysis
- Discount-band profitability analysis
- Star-schema data model in PostgreSQL
- SQL-based business analysis
- Python-based exploratory and statistical analysis
- Power BI dashboard (executive + drill-down views)
- Executive summary and written business recommendations

### 7.2 Out of Scope (Future Enhancements)
- Predictive/forecasting models (e.g., future margin projection)
- Price elasticity modeling
- Inventory or supply chain optimization
- Real-time/streaming data integration
- Automated pricing engine

---

## 8. Business Requirements

The delivered solution must allow stakeholders to answer:

**Executive-level**
- What is the current profit margin trend, and how does it compare to the target/historical baseline?
- Which factors are most responsible for the margin decline?

**Product-level**
- Which products/sub-categories are profitable vs. loss-making?
- Which high-revenue products have disproportionately low margin?

**Regional-level**
- Which regions are underperforming on margin despite strong sales?

**Discount-level**
- At what discount level does profit begin to decline or turn negative, and does this vary by category?

**Segment-level**
- Which customer segments are most and least profitable, and is there a volume/margin tradeoff?

---

## 9. Constraints & Assumptions

- Data is synthetic, generated in Python with deliberately embedded profitability issues (documented separately in a "ground truth" reference for internal validation — not part of the public-facing analysis).
- Analysis covers a 3-year historical window at monthly granularity.
- PostgreSQL is the system of record; Power BI connects via live/import connection, not flat-file import.
- No real customer, financial, or proprietary data is used at any stage.

---

## 10. Technology Stack

| Layer | Tool |
|---|---|
| Data generation | Python (pandas, NumPy, Faker) |
| Database | PostgreSQL |
| SQL client | DBeaver |
| Analysis | SQL, Python (Jupyter, pandas, matplotlib/seaborn) |
| BI/Visualization | Power BI Desktop |
| Version control & documentation | GitHub |

---

## 11. Deliverables

1. Business Requirements Document (this document)
2. Stakeholder Map
3. Functional & Non-Functional Requirements
4. As-Is / To-Be Process Maps
5. KPI Framework
6. Data Model (star schema) + DDL scripts
7. Synthetic Data Generation script + methodology notes
8. Data Dictionary & Data Quality Assessment
9. SQL Analysis scripts
10. Python Analysis notebook
11. Power BI Dashboard (.pbix)
12. Executive Summary
13. Business Recommendations report
14. GitHub repository with full documentation

---

## 12. Success Criteria

The project is successful if a stakeholder reviewing the dashboard and reports can:

- Understand precisely why margin declined from 18% to 11%
- Identify the specific products, regions, and discount practices responsible
- See quantified, prioritized recommendations with estimated profit impact
- Trust that the analysis is methodologically sound and reproducible (SQL + Python + documented data model)

---

## 13. Approval

| Role | Name | Status |
|---|---|---|
| Project Owner / Analyst | Benard Onyango Omoga | Approved |
