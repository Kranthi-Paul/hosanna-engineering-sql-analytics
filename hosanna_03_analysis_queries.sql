-- ================================================================
-- HOSANNA ENGINEERING WORKS
-- Business Analysis Queries
-- Demonstrates: CTEs, Window Functions, JOINs, Aggregations,
--               Date Functions, PIVOT, NULL Handling
-- ================================================================

USE hosanna_engineering;

-- ================================================================
-- SECTION 1: REVENUE ANALYSIS
-- ================================================================

-- ----------------------------------------------------------------
-- 1.1 Monthly Revenue Summary with MoM Growth
-- Business Question: How is revenue trending month over month?
-- Concepts: CTE, LAG(), CASE WHEN, DATE functions
-- ----------------------------------------------------------------
WITH monthly_revenue AS (
    SELECT
        year,
        month,
        month_name,
        COUNT(job_id)                                       AS total_jobs,
        SUM(quoted_amount)                                  AS total_quoted,
        SUM(advance_received)                               AS total_advance,
        SUM(balance_collected)                              AS total_balance,
        SUM(total_revenue)                                  AS total_collected,
        SUM(quoted_amount) - SUM(total_revenue)             AS outstanding_amount
    FROM jobs
    GROUP BY year, month, month_name
),
mom_analysis AS (
    SELECT
        *,
        LAG(total_collected, 1) OVER (ORDER BY year, month) AS prev_month_revenue
    FROM monthly_revenue
)
SELECT
    CONCAT(month_name, ' ', year)                           AS period,
    total_jobs,
    total_quoted,
    total_collected,
    outstanding_amount,
    prev_month_revenue,
    ROUND((total_collected - prev_month_revenue)
          / NULLIF(prev_month_revenue, 0) * 100, 1)         AS mom_growth_pct,
    SUM(total_collected) OVER (ORDER BY year, month)        AS running_revenue,
    CASE
        WHEN prev_month_revenue IS NULL                     THEN 'Baseline'
        WHEN total_collected > prev_month_revenue           THEN 'Growth'
        WHEN total_collected < prev_month_revenue           THEN 'Decline'
        ELSE                                                     'Flat'
    END                                                     AS trend
FROM mom_analysis
ORDER BY year, month;


-- ----------------------------------------------------------------
-- 1.2 Revenue by Work Category — PIVOT style
-- Business Question: Which type of work generates the most money?
-- Concepts: Conditional aggregation, PIVOT pattern
-- ----------------------------------------------------------------
SELECT
    CONCAT(month_name, ' ', year)                           AS period,
    SUM(CASE WHEN category = 'Gates'     THEN total_revenue ELSE 0 END) AS gates,
    SUM(CASE WHEN category = 'Grills'    THEN total_revenue ELSE 0 END) AS grills,
    SUM(CASE WHEN category = 'Carts'     THEN total_revenue ELSE 0 END) AS carts,
    SUM(CASE WHEN category = 'Sheds'     THEN total_revenue ELSE 0 END) AS sheds,
    SUM(CASE WHEN category = 'Staircase' THEN total_revenue ELSE 0 END) AS staircase,
    SUM(CASE WHEN category = 'Doors'     THEN total_revenue ELSE 0 END) AS doors,
    SUM(CASE WHEN category = 'Frames'    THEN total_revenue ELSE 0 END) AS frames,
    SUM(CASE WHEN category = 'Welding'   THEN total_revenue ELSE 0 END) AS welding,
    SUM(CASE WHEN category = 'Repair'    THEN total_revenue ELSE 0 END) AS repair,
    SUM(total_revenue)                                      AS total_revenue
FROM jobs
GROUP BY year, month, month_name
ORDER BY year, month;


-- ----------------------------------------------------------------
-- 1.3 Outstanding Payments — Who Owes Money?
-- Business Question: Which jobs are unpaid or partially paid?
-- Concepts: JOIN, DATEDIFF, CASE WHEN, NULL handling
-- ----------------------------------------------------------------
SELECT
    j.job_id,
    c.customer_name,
    c.segment,
    j.work_type,
    j.date_started,
    j.date_completed,
    DATEDIFF(CURDATE(), j.date_started)                     AS days_since_started,
    j.quoted_amount,
    j.total_revenue                                         AS amount_collected,
    j.quoted_amount - j.total_revenue                       AS amount_outstanding,
    ROUND((j.total_revenue / NULLIF(j.quoted_amount,0)) * 100, 1) AS collection_pct,
    j.status,
    CASE
        WHEN j.quoted_amount - j.total_revenue = 0         THEN 'Fully Paid'
        WHEN j.total_revenue = 0                           THEN 'Advance Only'
        ELSE                                                    'Partially Paid'
    END                                                     AS payment_status
FROM jobs j
JOIN customers c ON j.customer_id = c.customer_id
WHERE j.quoted_amount > j.total_revenue
ORDER BY (j.quoted_amount - j.total_revenue) DESC;


-- ================================================================
-- SECTION 2: CUSTOMER ANALYSIS
-- ================================================================

-- ----------------------------------------------------------------
-- 2.1 Customer Revenue Ranking + Segmentation
-- Business Question: Who are our best customers?
-- Concepts: Window functions, RANK, NTILE, DENSE_RANK
-- ----------------------------------------------------------------
WITH customer_summary AS (
    SELECT
        c.customer_id,
        c.customer_name,
        c.segment,
        c.location,
        COUNT(j.job_id)                                     AS total_jobs,
        SUM(j.quoted_amount)                                AS total_quoted,
        SUM(j.total_revenue)                                AS total_revenue,
        ROUND(AVG(j.quoted_amount), 0)                      AS avg_job_value,
        SUM(j.quoted_amount) - SUM(j.total_revenue)         AS total_outstanding,
        MIN(j.date_started)                                 AS first_job_date,
        MAX(j.date_started)                                 AS last_job_date
    FROM customers c
    LEFT JOIN jobs j ON c.customer_id = j.customer_id
    GROUP BY c.customer_id, c.customer_name, c.segment, c.location
)
SELECT
    customer_name,
    segment,
    location,
    total_jobs,
    total_revenue,
    avg_job_value,
    total_outstanding,
    RANK()       OVER (ORDER BY total_revenue DESC)         AS revenue_rank,
    DENSE_RANK() OVER (ORDER BY total_jobs DESC)            AS frequency_rank,
    NTILE(4)     OVER (ORDER BY total_revenue DESC)         AS revenue_quartile,
    CASE NTILE(4) OVER (ORDER BY total_revenue DESC)
        WHEN 1 THEN 'VIP Customer'
        WHEN 2 THEN 'Regular Customer'
        WHEN 3 THEN 'Occasional Customer'
        WHEN 4 THEN 'Low Value'
    END                                                     AS customer_tier,
    ROUND(PERCENT_RANK() OVER (ORDER BY total_revenue DESC) * 100, 1) AS percentile
FROM customer_summary
ORDER BY revenue_rank;


-- ----------------------------------------------------------------
-- 2.2 Repeat Customer Analysis
-- Business Question: Which customers come back for more work?
-- Concepts: CTE, LEAD(), LAG(), date calculations
-- ----------------------------------------------------------------
WITH customer_jobs AS (
    SELECT
        j.customer_id,
        c.customer_name,
        j.job_id,
        j.date_started,
        j.total_revenue,
        ROW_NUMBER() OVER (PARTITION BY j.customer_id
                           ORDER BY j.date_started)         AS job_sequence,
        LAG(j.date_started) OVER (PARTITION BY j.customer_id
                                  ORDER BY j.date_started)  AS previous_job_date,
        LEAD(j.date_started) OVER (PARTITION BY j.customer_id
                                   ORDER BY j.date_started) AS next_job_date
    FROM jobs j
    JOIN customers c ON j.customer_id = c.customer_id
)
SELECT
    customer_name,
    job_id,
    date_started,
    job_sequence,
    total_revenue,
    previous_job_date,
    DATEDIFF(date_started, previous_job_date)               AS days_since_last_job,
    next_job_date,
    CASE
        WHEN previous_job_date IS NULL                      THEN 'First Job'
        WHEN DATEDIFF(date_started, previous_job_date) <= 30 THEN 'Returned Quickly'
        WHEN DATEDIFF(date_started, previous_job_date) <= 90 THEN 'Regular Return'
        ELSE                                                    'Long Gap'
    END                                                     AS return_pattern
FROM customer_jobs
ORDER BY customer_name, job_sequence;


-- ----------------------------------------------------------------
-- 2.3 Customer Segment Revenue Analysis
-- Business Question: Which customer segment (Government/Commercial/etc) is most valuable?
-- Concepts: GROUP BY, aggregation, window functions
-- ----------------------------------------------------------------
WITH segment_summary AS (
    SELECT
        c.segment,
        COUNT(DISTINCT c.customer_id)                       AS total_customers,
        COUNT(j.job_id)                                     AS total_jobs,
        SUM(j.total_revenue)                                AS total_revenue,
        ROUND(AVG(j.quoted_amount), 0)                      AS avg_job_value,
        SUM(j.quoted_amount - j.total_revenue)              AS total_outstanding
    FROM customers c
    LEFT JOIN jobs j ON c.customer_id = j.customer_id
    GROUP BY c.segment
)
SELECT
    segment,
    total_customers,
    total_jobs,
    total_revenue,
    avg_job_value,
    total_outstanding,
    ROUND(total_revenue / SUM(total_revenue) OVER () * 100, 1) AS revenue_share_pct,
    RANK() OVER (ORDER BY total_revenue DESC)               AS segment_rank
FROM segment_summary
ORDER BY segment_rank;


-- ================================================================
-- SECTION 3: COST ANALYSIS
-- ================================================================

-- ----------------------------------------------------------------
-- 3.1 Monthly Cost Breakdown — Full P&L
-- Business Question: Where is the money going each month?
-- Concepts: Multiple CTEs, UNION-style aggregation, COALESCE
-- ----------------------------------------------------------------
WITH revenue AS (
    SELECT year, month, month_name,
           SUM(total_revenue) AS total_revenue
    FROM jobs GROUP BY year, month, month_name
),
mat_cost AS (
    SELECT year, month, month_name,
           SUM(total_cost) AS materials
    FROM materials GROUP BY year, month, month_name
),
sal_cost AS (
    SELECT year, month, month_name,
           SUM(amount_paid) AS salaries
    FROM salaries GROUP BY year, month, month_name
),
emi_cost AS (
    SELECT year, month, month_name,
           SUM(amount_paid) AS emi_payments
    FROM emi_payments GROUP BY year, month, month_name
),
trn_cost AS (
    SELECT year, month, month_name,
           SUM(amount) AS transportation
    FROM transportation GROUP BY year, month, month_name
),
ovh_cost AS (
    SELECT year, month,
           SUM(CASE WHEN expense_type = 'Rent'        THEN amount ELSE 0 END) AS rent,
           SUM(CASE WHEN expense_type = 'Electricity'  THEN amount ELSE 0 END) AS electricity
    FROM overhead GROUP BY year, month
)
SELECT
    CONCAT(r.month_name, ' ', r.year)                       AS period,
    r.total_revenue,
    COALESCE(m.materials, 0)                                AS materials,
    COALESCE(s.salaries, 0)                                 AS salaries,
    COALESCE(e.emi_payments, 0)                             AS emi_payments,
    COALESCE(t.transportation, 0)                           AS transportation,
    COALESCE(o.rent, 0)                                     AS rent,
    COALESCE(o.electricity, 0)                              AS electricity,
    COALESCE(m.materials,0) + COALESCE(s.salaries,0) +
    COALESCE(e.emi_payments,0) + COALESCE(t.transportation,0) +
    COALESCE(o.rent,0) + COALESCE(o.electricity,0)          AS total_costs,
    r.total_revenue - (
        COALESCE(m.materials,0) + COALESCE(s.salaries,0) +
        COALESCE(e.emi_payments,0) + COALESCE(t.transportation,0) +
        COALESCE(o.rent,0) + COALESCE(o.electricity,0))     AS net_profit_loss,
    ROUND(COALESCE(m.materials,0) / NULLIF(r.total_revenue,0) * 100, 1) AS material_cost_ratio_pct
FROM revenue r
LEFT JOIN mat_cost m  ON r.year = m.year AND r.month = m.month
LEFT JOIN sal_cost s  ON r.year = s.year AND r.month = s.month
LEFT JOIN emi_cost e  ON r.year = e.year AND r.month = e.month
LEFT JOIN trn_cost t  ON r.year = t.year AND r.month = t.month
LEFT JOIN ovh_cost o  ON r.year = o.year AND r.month = o.month
ORDER BY r.year, r.month;


-- ----------------------------------------------------------------
-- 3.2 Material Cost by Supplier — Who do we buy most from?
-- Business Question: Which supplier takes the most money?
-- Concepts: GROUP BY, RANK, percentage contribution
-- ----------------------------------------------------------------
SELECT
    supplier_name,
    COUNT(DISTINCT purchase_id)                             AS total_purchases,
    COUNT(DISTINCT job_id)                                  AS jobs_supplied,
    ROUND(SUM(total_cost), 0)                               AS total_spend,
    ROUND(AVG(total_cost), 0)                               AS avg_purchase_value,
    ROUND(SUM(total_cost) / SUM(SUM(total_cost)) OVER () * 100, 1) AS spend_share_pct,
    RANK() OVER (ORDER BY SUM(total_cost) DESC)             AS supplier_rank
FROM materials
GROUP BY supplier_name
ORDER BY supplier_rank;


-- ----------------------------------------------------------------
-- 3.3 EMI Burden Analysis — Loan vs Revenue Ratio
-- Business Question: How crushing is the debt load each month?
-- Concepts: CTE, COALESCE, ratio calculation, CASE WHEN
-- ----------------------------------------------------------------
WITH monthly_emi AS (
    SELECT year, month, month_name,
           SUM(amount_paid) AS total_emi,
           COUNT(CASE WHEN status = 'Missed' THEN 1 END) AS missed_payments
    FROM emi_payments
    GROUP BY year, month, month_name
),
monthly_rev AS (
    SELECT year, month, SUM(total_revenue) AS revenue
    FROM jobs GROUP BY year, month
)
SELECT
    CONCAT(e.month_name, ' ', e.year)                       AS period,
    e.total_emi,
    e.missed_payments,
    COALESCE(r.revenue, 0)                                  AS revenue,
    ROUND(e.total_emi / NULLIF(r.revenue, 0) * 100, 1)     AS emi_to_revenue_pct,
    CASE
        WHEN e.total_emi / NULLIF(r.revenue,0) > 0.5       THEN 'CRITICAL — EMI > 50% Revenue'
        WHEN e.total_emi / NULLIF(r.revenue,0) > 0.3       THEN 'WARNING — EMI > 30% Revenue'
        ELSE                                                    'Manageable'
    END                                                     AS emi_health
FROM monthly_emi e
LEFT JOIN monthly_rev r ON e.year = r.year AND e.month = r.month
ORDER BY e.year, e.month;


-- ================================================================
-- SECTION 4: JOB PROFITABILITY ANALYSIS
-- ================================================================

-- ----------------------------------------------------------------
-- 4.1 Job-Level Profitability — Which jobs made money?
-- Business Question: After material costs, which jobs were profitable?
-- Concepts: JOIN, aggregation, profitability calculation
-- ----------------------------------------------------------------
WITH job_material_cost AS (
    SELECT job_id, SUM(total_cost) AS total_material_cost
    FROM materials
    GROUP BY job_id
),
job_transport_cost AS (
    SELECT job_id, SUM(amount) AS total_transport_cost
    FROM transportation
    GROUP BY job_id
)
SELECT
    j.job_id,
    c.customer_name,
    j.work_type,
    j.category,
    j.date_started,
    j.quoted_amount,
    j.total_revenue,
    COALESCE(m.total_material_cost, 0)                      AS material_cost,
    COALESCE(t.total_transport_cost, 0)                     AS transport_cost,
    j.total_revenue
        - COALESCE(m.total_material_cost, 0)
        - COALESCE(t.total_transport_cost, 0)               AS gross_profit,
    ROUND((j.total_revenue
        - COALESCE(m.total_material_cost, 0)
        - COALESCE(t.total_transport_cost, 0))
        / NULLIF(j.total_revenue, 0) * 100, 1)              AS gross_margin_pct,
    RANK() OVER (ORDER BY
        j.total_revenue
        - COALESCE(m.total_material_cost, 0)
        - COALESCE(t.total_transport_cost, 0) DESC)         AS profitability_rank
FROM jobs j
JOIN customers c              ON j.customer_id = c.customer_id
LEFT JOIN job_material_cost m ON j.job_id = m.job_id
LEFT JOIN job_transport_cost t ON j.job_id = t.job_id
WHERE j.status = 'Completed'
ORDER BY profitability_rank;


-- ----------------------------------------------------------------
-- 4.2 Work Category Profitability
-- Business Question: Which types of work have the best margins?
-- Concepts: CTE, JOIN, aggregation, margin calculation
-- ----------------------------------------------------------------
WITH category_financials AS (
    SELECT
        j.category,
        COUNT(j.job_id)                                     AS total_jobs,
        SUM(j.total_revenue)                                AS total_revenue,
        SUM(m.total_cost)                                   AS total_material_cost,
        SUM(j.total_revenue) - SUM(m.total_cost)           AS gross_profit
    FROM jobs j
    LEFT JOIN materials m ON j.job_id = m.job_id
    WHERE j.status = 'Completed'
    GROUP BY j.category
)
SELECT
    category,
    total_jobs,
    total_revenue,
    ROUND(total_material_cost, 0)                           AS total_material_cost,
    ROUND(gross_profit, 0)                                  AS gross_profit,
    ROUND(gross_profit / NULLIF(total_revenue, 0) * 100, 1) AS gross_margin_pct,
    RANK() OVER (ORDER BY gross_profit / NULLIF(total_revenue,0) DESC) AS margin_rank
FROM category_financials
ORDER BY margin_rank;


-- ================================================================
-- SECTION 5: WORKER PRODUCTIVITY ANALYSIS
-- ================================================================

-- ----------------------------------------------------------------
-- 5.1 Monthly Salary Summary per Worker
-- Business Question: How much are we spending on each worker?
-- Concepts: GROUP BY, window functions, running totals
-- ----------------------------------------------------------------
SELECT
    worker_name,
    role,
    employment_type,
    SUM(days_worked)                                        AS total_days_worked,
    SUM(amount_paid)                                        AS total_salary_paid,
    ROUND(AVG(days_worked), 1)                              AS avg_days_per_month,
    ROUND(AVG(amount_paid), 0)                              AS avg_monthly_salary,
    ROUND(SUM(amount_paid) / SUM(SUM(amount_paid)) OVER () * 100, 1) AS salary_share_pct,
    RANK() OVER (ORDER BY SUM(amount_paid) DESC)            AS cost_rank
FROM salaries
GROUP BY worker_name, role, employment_type
ORDER BY cost_rank;


-- ================================================================
-- SECTION 6: BUSINESS HEALTH DASHBOARD
-- ================================================================

-- ----------------------------------------------------------------
-- 6.1 Executive KPI Summary — Full Year
-- Business Question: What is the overall health of the business?
-- Concepts: Subqueries, aggregation, business metrics
-- ----------------------------------------------------------------
SELECT
    'Total Revenue (12M)'                                   AS kpi,
    CONCAT('₹', FORMAT(SUM(total_revenue), 0))             AS value
FROM jobs
UNION ALL
SELECT 'Total Jobs Completed',
    COUNT(*) FROM jobs WHERE status = 'Completed'
UNION ALL
SELECT 'Active Customers',
    COUNT(DISTINCT customer_id) FROM jobs
UNION ALL
SELECT 'Avg Job Value',
    CONCAT('₹', FORMAT(AVG(quoted_amount), 0)) FROM jobs
UNION ALL
SELECT 'Outstanding Receivables',
    CONCAT('₹', FORMAT(SUM(quoted_amount - total_revenue), 0))
    FROM jobs WHERE quoted_amount > total_revenue
UNION ALL
SELECT 'Total Material Cost',
    CONCAT('₹', FORMAT(SUM(total_cost), 0)) FROM materials
UNION ALL
SELECT 'Total EMI Burden (12M)',
    CONCAT('₹', FORMAT(SUM(amount_paid), 0)) FROM emi_payments
UNION ALL
SELECT 'Missed EMI Payments',
    COUNT(*) FROM emi_payments WHERE status = 'Missed'
UNION ALL
SELECT 'Best Revenue Month',
    month_name FROM (
        SELECT month_name, SUM(total_revenue) AS rev
        FROM jobs GROUP BY year, month, month_name
        ORDER BY rev DESC LIMIT 1
    ) AS best
UNION ALL
SELECT 'Most Valuable Customer',
    customer_name FROM (
        SELECT customer_name, SUM(total_revenue) AS rev
        FROM jobs GROUP BY customer_name
        ORDER BY rev DESC LIMIT 1
    ) AS top_cust;


-- ----------------------------------------------------------------
-- 6.2 Top 5 Most Profitable Jobs Ever
-- Concepts: CTE, JOIN, ORDER BY, LIMIT
-- ----------------------------------------------------------------
WITH job_costs AS (
    SELECT job_id, SUM(total_cost) AS material_cost
    FROM materials GROUP BY job_id
)
SELECT
    j.job_id,
    c.customer_name,
    j.work_type,
    j.month_name,
    j.year,
    j.total_revenue,
    COALESCE(jc.material_cost, 0)                          AS material_cost,
    j.total_revenue - COALESCE(jc.material_cost, 0)        AS gross_profit
FROM jobs j
JOIN customers c ON j.customer_id = c.customer_id
LEFT JOIN job_costs jc ON j.job_id = jc.job_id
WHERE j.status = 'Completed'
ORDER BY gross_profit DESC
LIMIT 5;


-- ----------------------------------------------------------------
-- 6.3 Customers Who Haven't Returned in 90+ Days
-- Business Question: Who should we follow up with?
-- Concepts: MAX date, DATEDIFF, HAVING, customer retention
-- ----------------------------------------------------------------
SELECT
    c.customer_name,
    c.segment,
    c.location,
    COUNT(j.job_id)                                         AS lifetime_jobs,
    SUM(j.total_revenue)                                    AS lifetime_revenue,
    MAX(j.date_started)                                     AS last_job_date,
    DATEDIFF(CURDATE(), MAX(j.date_started))                AS days_since_last_job,
    CASE
        WHEN DATEDIFF(CURDATE(), MAX(j.date_started)) > 180 THEN 'At Risk — Call Now'
        WHEN DATEDIFF(CURDATE(), MAX(j.date_started)) > 90  THEN 'Follow Up Needed'
        ELSE                                                    'Active'
    END                                                     AS retention_status
FROM customers c
JOIN jobs j ON c.customer_id = j.customer_id
GROUP BY c.customer_id, c.customer_name, c.segment, c.location
HAVING DATEDIFF(CURDATE(), MAX(j.date_started)) > 60
ORDER BY days_since_last_job DESC;

-- ================================================================
-- END OF ANALYSIS QUERIES
-- ================================================================
