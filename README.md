# Olist E-Commerce SQL Analysis

**Author:** Sheikh Md Ashiqur Rahman Titas

## Goal
Use SQL to answer business questions about sales, customers, and delivery performance for a Brazilian e-commerce marketplace, and to find what is hurting customer satisfaction.

## Dataset
[Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle): about 99,000 orders from 2016 to 2018 across 7 related tables (customers, orders, order items, reviews, products, sellers, category translation). Amounts are in Brazilian reais (R$).

## Tools
PostgreSQL 18, pgAdmin 4. Techniques used: multi-table JOINs, GROUP BY / HAVING, CTEs, window functions (RANK, LAG, running SUM), date functions, CASE.

## Data Quality Checks

**1. Row counts after import**
| Table | Rows |
|---|---|
| orders | 99,441 |
| customers | 99,441 |
| order_items | 112,650 |

**2. Order status breakdown**
| Status | Orders |
|---|---|
| delivered | 96,478 |
| shipped | 1,107 |
| canceled | 625 |
| unavailable | 609 |
| invoiced | 314 |
| processing | 301 |
| created | 5 |
| approved | 2 |

**3. Missing delivery dates**
2,965 orders (about 3.0%) have no delivery date. That is almost the same as the 2,963 orders that never reached "delivered" status, so the gaps look like unfinished or canceled orders, not data errors.

**Decision:** revenue-trend queries (Q1, Q5, Q8) use `order_status = 'delivered'` only, so unfinished orders do not distort the totals. Delivery-vs-review analysis (Q10) uses only orders that have a delivery date.

## Key Findings

1. **Late deliveries cut review scores sharply.** Orders delivered on time average a 4.29 review score, versus 2.57 for late orders, a gap of 1.72 points. About 8% of delivered-and-reviewed orders (7,701 of 96,359) arrived late.
2. **Sales are concentrated in a few places.** Delivered orders generated R$13.22M in revenue at an average order value of R$137.04. Three states (São Paulo, Rio de Janeiro, Minas Gerais) account for about 63% of all item revenue, and São Paulo alone for about 38%. The top categories are health_beauty (R$1.26M), watches_gifts (R$1.21M), and bed_bath_table (R$1.04M).
3. **Almost nobody comes back.** 96.88% of customers (93,099) bought only once; just 3.12% (2,997) are repeat buyers.

**Also noted:**
- Monthly delivered revenue grew from R$111,798 (Jan 2017) to a peak of R$987,765 (Nov 2017), then stayed between roughly R$826K and R$978K through Aug 2018.
- The sellers with the most late deliveries (97 to 195 late orders each) include the two top-revenue sellers in São Paulo.
- The very large month-over-month growth figures in early 2017 come from tiny starting months, not real 1,000,000% growth.

## Recommendation
Late delivery is the clearest fixable problem: it is common enough to matter and its effect on reviews is large. Start with the highest-volume sellers, since they appear on the late-delivery list too, and set delivery-time targets for them. Better reviews and a smoother first experience are also the most direct route to improving the 3% repeat-purchase rate.

## Limitations
- Late-order counts per seller are absolute numbers, not rates, so high-volume sellers naturally rank higher. A follow-up query should compute each seller's late-delivery percentage.
- The data shows correlation between late delivery and low reviews, not proof of cause.
- Q2, Q3, Q4, Q6, Q7, and Q9 include all order statuses.

## Files
- `schema.sql`: table definitions
- `queries.sql`: data-quality checks and the 10 analysis queries, each with its business question
