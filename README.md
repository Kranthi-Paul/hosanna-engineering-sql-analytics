# Hosanna Engineering Works — Business Analytics System

> **A complete SQL business intelligence system built for a small-scale Hosanna Engineering Works.**  
> Demonstrates real-world data analysis using advanced SQL on a multi-table relational schema.

---

## Project Overview

Hosanna Engineering Works is a steel fabrication and welding shop serving customers across rural Andhra Pradesh, India. This project builds a complete analytics system to track revenue, costs, job profitability, customer behaviour, and debt health — turning raw business records into actionable insights.

**Dataset:** 12 months of synthetic business data (Jul 2024 – Jun 2025)  
**Database:** MySQL  
**Tables:** 12 tables | 1,000+ rows across transactions  
**Domain:** Small Business Analytics, Financial Reporting, Operations

---

## Business Context

| Metric | Value |
|---|---|
| Total Jobs | 113 across 12 months |
| Active Customers | 15 across 5 segments |
| Work Categories | Gates, Grills, Carts, Sheds, Staircase, Frames, Doors, Welding, Repair |
| Monthly EMI Burden | ₹62,000 across 5 lenders |
| Key Business Problem | Material costs at 63% of revenue; EMI eating 37% of revenue |

---

## Database Schema

```
customers ──────────────► jobs ◄──────────────── work_types
                           │
            ┌──────────────┼──────────────────┐
            │              │                  │
         materials    transportation       (month/year)
            │                                  │
         suppliers                    salaries ── workers
                                      overhead
                                      emi_payments ── loans_ref
```

**12 tables total:**

| Table | Rows | Purpose |
|---|---|---|
| jobs | 113 | Core order/job tracker |
| materials | 450 | Material purchases per job |
| salaries | 60 | Monthly worker payments |
| emi_payments | 60 | Loan repayment tracking |
| transportation | 196 | Material delivery costs |
| overhead | 24 | Rent and electricity |
| customers | 15 | Customer master data |
| suppliers | 5 | Supplier master data |
| workers | 5 | Worker master data |
| work_types | 15 | Job type catalogue |
| materials_ref | 15 | Material catalogue |
| loans_ref | 5 | Loan details |

---

## SQL Skills Demonstrated

| Concept | Where Used |
|---|---|
| **CTEs (chained)** | Monthly P&L, MoM analysis, job profitability |
| **Window Functions** | RANK, DENSE_RANK, NTILE, PERCENT_RANK, LAG, LEAD, SUM OVER |
| **Multi-table JOINs** | 4-5 tables joined for P&L and profitability queries |
| **LEFT JOIN + COALESCE** | Including jobs with no material records |
| **PIVOT (conditional aggregation)** | Revenue by work category per month |
| **Date Functions** | DATEDIFF, CURDATE for receivables and retention analysis |
| **NULLIF (safe division)** | Margin % calculations without division by zero |
| **CASE WHEN** | EMI health alerts, customer tiers, payment status |
| **Subqueries** | KPI dashboard summary |
| **UNION ALL** | Executive KPI report |

---

## Key Business Analyses

### 1. Monthly Revenue & MoM Growth
Tracks revenue collected each month with period-over-period growth percentage and trend classification.

```sql
WITH monthly_revenue AS (...),
mom_analysis AS (
    SELECT *, LAG(total_collected, 1) OVER (ORDER BY year, month) AS prev_month
    FROM monthly_revenue
)
SELECT
    period,
    total_collected,
    ROUND((total_collected - prev_month) / NULLIF(prev_month,0) * 100, 1) AS mom_growth_pct,
    CASE WHEN total_collected > prev_month THEN 'Growth' ELSE 'Decline' END AS trend
FROM mom_analysis;
```

### 2. Customer Value Segmentation
Ranks customers using NTILE(4) into VIP, Regular, Occasional, and Low Value tiers.

### 3. EMI Health Monitor
Flags months where EMI payments exceed 30% or 50% of revenue — identifying financial risk.

```sql
CASE
    WHEN emi_to_revenue_pct > 50 THEN 'CRITICAL — EMI > 50% Revenue'
    WHEN emi_to_revenue_pct > 30 THEN 'WARNING — EMI > 30% Revenue'
    ELSE 'Manageable'
END AS emi_health
```

### 4. Job Profitability Ranking
Calculates gross profit per completed job by subtracting material and transport costs from revenue.

### 5. Customer Retention Alert
Identifies customers who haven't returned in 90+ days — with a direct follow-up action flag.

### 6. Outstanding Receivables Tracker
Shows every job with uncollected balance — who owes money and how long it's been outstanding.

---

## Business Insights Discovered

- **November 2024** was the strongest month — construction season peak
- **Staircase and Grills** are the highest revenue work categories (₹3L+ each)
- **Material cost ratio** averages 83% of revenue — industry standard is 40-60%
- **Red Bank EMI** (₹31,404/month) accounts for 50% of total debt burden
- **3 customers** account for 60% of total revenue — concentration risk
- **21 jobs** have outstanding payments totalling significant uncollected revenue

---

## How to Run

```sql
-- Step 1: Create schema
source hosanna_01_schema_setup.sql

-- Step 2: Load data
source hosanna_02_data_load.sql

-- Step 3: Run analysis queries
source hosanna_03_analysis_queries.sql
```

---

## Files

| File | Description |
|---|---|
| `hosanna_01_schema_setup.sql` | CREATE TABLE statements for all 12 tables |
| `hosanna_02_data_load.sql` | INSERT statements with 12 months of data |
| `hosanna_03_analysis_queries.sql` | 15 business analysis queries |
| `data/` | CSV source files for all tables |

---

## Real-World Applicability

This project mirrors the analytics challenges faced by thousands of small manufacturing businesses in India:
- No formal ERP system — records kept in Excel or paper
- Multiple informal lenders creating complex debt structures
- Revenue collected in advance + balance — creating receivables gaps
- Seasonal demand patterns requiring cash flow planning
- Multiple work types with very different profit margins

---

## Connect

- **LinkedIn:** www.linkedin.com/in/kranthi-paul-536b25158
- **Email:** kranthipaul7@gmail.com

---

