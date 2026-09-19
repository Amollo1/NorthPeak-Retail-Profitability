# Business Recommendations
## NorthPeak Retail - Profitability Decline Analysis

**Prepared for:** Executive Leadership, Finance, Sales, Regional Management, Product Management
**Prepared by:** Benard Onyango Omoga, Business/Data Analyst
**Date:** September 2026

---

## Methodology Note

Each recommendation below traces directly to a specific, statistically validated finding (see `notebooks/retail_analysis.ipynb` and `sql/02_business_analysis.sql`). Quantified impact estimates are calculated by re-running the 2025 transaction data under an alternative discount/pricing scenario and comparing hypothetical profit to actual profit.

**Important caveat on all estimates below:** these figures assume sales *volume* would be unchanged if discounting were reduced, i.e., they show the profit that was *given away* at current volume, not a guaranteed forecast. In practice, some customers may reduce order volume if discounts are tightened, meaning actual recovery would likely be somewhat lower than the figures shown. These estimates should be treated as an **upper-bound directional signal**, not a committed forecast, and should be validated with a controlled pilot before company-wide rollout (see Recommendation 4).

---

## Recommendation 1: Cap Corporate Segment Discounting

### Finding
Corporate segment margin collapsed from 12.6% (2023) to 4.6% (2025), even as Corporate's share of total sales grew from 27.5% to 33.0%. The current sales-weighted average discount for Corporate customers in 2025 is **23.2%**, more than double the 2023 level, and far above the 8-12% range typical of other segments.

### Recommendation
Introduce a formal discount approval threshold for Corporate accounts: deals above **20% discount** require Regional Manager or Finance sign-off, rather than being approved unilaterally by the sales representative. This does not eliminate Corporate discounting — it restores governance over deals that currently erode margin without review.

### Quantified Impact (2025 basis)
| Metric | Value |
|---|---|
| Actual Corporate profit, 2025 | KES 13,063,860 |
| Hypothetical profit if discount capped at 20% | KES 28,104,872 |
| **Estimated annual profit recovery** | **≈ KES 15,041,012** |

### Priority: **High**; largest single-line impact of the three product/pricing recommendations.
### Owner: Sales Director (policy), Finance Manager (approval workflow)

---

## Recommendation 2: Cap Furniture Discounting in the Nairobi Region

### Finding
Nairobi's Furniture-category discount rose from ~9% (early 2023) to over **28%** by Q4 2025, a trend not observed in any other region for the same category (other regions plateaued around 13%). As a direct result, Nairobi Furniture sales operated at a **net loss (-3.3%)** in 2025, and Nairobi is the lowest-margin region in the company. Note: Nairobi's overall *blended* regional margin variance (-2.1pp vs. company average) is modest on its own, the severity of this finding rests specifically on the Furniture-category discount trend, not on the region's aggregate performance.

### Recommendation
Apply a **15% discount ceiling specifically on Furniture-category sales in the Nairobi region**, reviewed quarterly. Investigate the root cause of the original discount escalation (competitive pressure, sales incentive structure, or informal customer expectation) before deciding whether the ceiling should be permanent or phased in.

### Quantified Impact (2025 basis)
| Metric | Value |
|---|---|
| Actual Nairobi Furniture profit, 2025 | KES -3,262,975 (loss) |
| Hypothetical profit if discount capped at 15% | KES 7,661,118 |
| **Estimated annual profit recovery** | **≈ KES 10,924,092** |

### Priority: **High**, converts an active loss-making segment into a profitable one.
### Owner: Regional Manager (Nairobi), Sales Director (oversight)

---

## Recommendation 3: Re-price or Re-engineer the "Tables" Product Line

### Finding
The "Tables" sub-category (Conference Table, Study Table, Office Pantry Table) has operated at a **negative margin every year since 2023**,  this is a structural cost/price problem, not a discounting problem, and is unrelated to the recent decline. The loss has grown each year: KES -3.0M (2023) → KES -4.4M (2024) → **KES -13.0M (2025)**.

### Recommendation
Two viable paths, in order of preference:
1. **Re-price**: increase list price or renegotiate supplier cost to restore a sustainable gross margin (target: bring Tables in line with the ~20% margin achieved by other Furniture sub-categories).
2. **Re-engineer or discontinue**: if repricing is not commercially viable (e.g., competitive price ceiling in the market), evaluate discontinuing the three underperforming Tables products and reallocating shelf/catalog space to higher-margin Furniture items (Chairs, Desks, Bookcases all run ~20% margin).

### Quantified Impact (2025 basis, repricing scenario)
| Metric | Value |
|---|---|
| Actual Tables profit, 2025 | KES -13,041,685 (loss) |
| Hypothetical profit if margin matched category average (21%) | KES 21,737,686 |
| **Estimated annual profit recovery** | **≈ KES 34,779,370** |

### Priority: **Highest**, largest single quantified opportunity, and addresses a problem that predates and is independent of the recent margin decline.
### Owner: Product/Category Manager, with Finance Manager validation on any price change

---

## Recommendation 4: Build the Profitability Monitoring Dashboard Into Standard Practice

### Finding
The As-Is process (see `docs/process_maps.md`) shows discount and pricing decisions are currently made without profitability visibility at the point of decision, issues are only discovered at month-end financial close, by which point the damage is already done for that period.

### Recommendation
Adopt the Power BI dashboard (in development, see `powerbi/`) as a required check **before** finalizing any discount above the thresholds set in Recommendations 1 and 2, not just as a retrospective reporting tool. Establish a monthly review cadence where Finance and Regional Managers jointly review the dashboard's discount and margin pages.

### Quantified Impact
Not independently quantifiable; this is an enabling/governance recommendation rather than a standalone profit driver. Its value is in **preventing recurrence** of Recommendations 1-3's root causes, and in surfacing the *next* emerging issue earlier than the current 6-quarter lag.

### Priority: **Medium** (foundational, but impact is indirect and long-term)
### Owner: Business/Data Analyst (build & maintain), Finance Manager (adoption into review cadence)

---

## Summary: Combined Estimated Impact

| Recommendation | Estimated Annual Recovery (KES) |
|---|---|
| 1. Cap Corporate discount at 20% | 15,041,012 |
| 2. Cap Nairobi Furniture discount at 15% | 10,924,092 |
| 3. Re-price Tables to category-average margin | 34,779,370 |
| **Total (directional, upper-bound)** | **≈ 60,744,474** |

Applied to 2025's actual profit of KES 128,244,342, this would represent a **~47% increase in annual profit** — moving overall margin from 14.92% toward approximately **22%**, which would exceed even the pre-decline 2023 baseline of 19.36%.

**Reiterating the caveat above:** this combined figure assumes no volume response to the pricing changes and should not be presented as a guaranteed outcome. It is best used as a prioritization signal — Recommendation 3 (Tables) offers the single largest, most defensible opportunity and carries the least commercial risk, since it addresses a structural loss rather than a customer-facing discount change.

---

## Suggested Implementation Sequence

1. **Immediate**: Begin Tables re-pricing analysis (Recommendation 3), lowest customer-relationship risk, highest quantified impact.
2. **Next 1 quarter**: Pilot the Nairobi Furniture discount cap (Recommendation 2) in a single branch before company-wide rollout, to observe any volume impact directly.
3. **Next 1-2 quarters**: Roll out the Corporate discount approval threshold (Recommendation 1), paired with sales team communication to manage the transition.
4. **Ongoing, in parallel**: Complete and adopt the profitability dashboard (Recommendation 4) so all three changes above can be monitored monthly rather than discovered at year-end.
