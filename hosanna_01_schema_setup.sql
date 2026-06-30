-- ================================================================
-- HOSANNA ENGINEERING WORKS
-- Business Analytics Database
-- Project: SQL Business Intelligence System
-- Author: Kranthi Kiran
-- Period: July 2024 – June 2025
-- ================================================================

CREATE DATABASE IF NOT EXISTS hosanna_engineering;
USE hosanna_engineering;

-- ----------------------------------------------------------------
-- REFERENCE TABLES
-- ----------------------------------------------------------------

CREATE TABLE IF NOT EXISTS customers (
    customer_id     VARCHAR(5)   PRIMARY KEY,
    customer_name   VARCHAR(100) NOT NULL,
    location        VARCHAR(100),
    segment         VARCHAR(50)  -- Government, Contractor, Commercial, Individual, NGO
);

CREATE TABLE IF NOT EXISTS work_types (
    work_id         VARCHAR(5)   PRIMARY KEY,
    work_name       VARCHAR(100) NOT NULL,
    category        VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS materials_ref (
    material_id     VARCHAR(5)   PRIMARY KEY,
    material_name   VARCHAR(100) NOT NULL,
    category        VARCHAR(50)  -- Pipes, Rods, Sheets, Consumable, Paint, Hardware
);

CREATE TABLE IF NOT EXISTS suppliers (
    supplier_id     VARCHAR(5)   PRIMARY KEY,
    supplier_name   VARCHAR(100) NOT NULL,
    location        VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS workers (
    worker_id       VARCHAR(5)   PRIMARY KEY,
    worker_name     VARCHAR(50)  NOT NULL,
    role            VARCHAR(50),
    employment_type VARCHAR(20), -- Full-time, Part-time
    daily_rate      DECIMAL(8,2)
);

CREATE TABLE IF NOT EXISTS loans_ref (
    loan_id         VARCHAR(5)   PRIMARY KEY,
    lender_name     VARCHAR(100) NOT NULL,
    monthly_emi     DECIMAL(10,2),
    loan_type       VARCHAR(50), -- Bank Loan, Finance, Private Lender, Family Loan
    purpose         VARCHAR(100)
);

-- ----------------------------------------------------------------
-- TRANSACTION TABLES
-- ----------------------------------------------------------------

CREATE TABLE IF NOT EXISTS jobs (
    job_id              VARCHAR(10)  PRIMARY KEY,
    year                INT,
    month               INT,
    month_name          VARCHAR(20),
    date_started        DATE,
    date_completed      DATE,
    customer_id         VARCHAR(5),
    customer_name       VARCHAR(100),
    work_id             VARCHAR(5),
    work_type           VARCHAR(100),
    category            VARCHAR(50),
    quoted_amount       DECIMAL(12,2),
    advance_received    DECIMAL(12,2),
    balance_collected   DECIMAL(12,2),
    total_revenue       DECIMAL(12,2),
    status              VARCHAR(20), -- Completed, In Progress, Advance Only
    location            VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (work_id)     REFERENCES work_types(work_id)
);

CREATE TABLE IF NOT EXISTS materials (
    purchase_id     VARCHAR(10)  PRIMARY KEY,
    job_id          VARCHAR(10),
    year            INT,
    month           INT,
    month_name      VARCHAR(20),
    date            DATE,
    supplier_id     VARCHAR(5),
    supplier_name   VARCHAR(100),
    material_id     VARCHAR(5),
    material_name   VARCHAR(100),
    category        VARCHAR(50),
    quantity_kg     DECIMAL(10,2),
    price_per_kg    DECIMAL(10,2),
    total_cost      DECIMAL(12,2),
    FOREIGN KEY (job_id)      REFERENCES jobs(job_id),
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id),
    FOREIGN KEY (material_id) REFERENCES materials_ref(material_id)
);

CREATE TABLE IF NOT EXISTS salaries (
    salary_id       VARCHAR(10)  PRIMARY KEY,
    year            INT,
    month           INT,
    month_name      VARCHAR(20),
    payment_date    DATE,
    worker_id       VARCHAR(5),
    worker_name     VARCHAR(50),
    role            VARCHAR(50),
    employment_type VARCHAR(20),
    days_worked     INT,
    daily_rate      DECIMAL(8,2),
    amount_paid     DECIMAL(10,2),
    FOREIGN KEY (worker_id) REFERENCES workers(worker_id)
);

CREATE TABLE IF NOT EXISTS transportation (
    transport_id    VARCHAR(10)  PRIMARY KEY,
    year            INT,
    month           INT,
    month_name      VARCHAR(20),
    date            DATE,
    job_id          VARCHAR(10),
    supplier_name   VARCHAR(100),
    vehicle         VARCHAR(50),
    amount          DECIMAL(10,2),
    FOREIGN KEY (job_id) REFERENCES jobs(job_id)
);

CREATE TABLE IF NOT EXISTS emi_payments (
    emi_id          VARCHAR(10)  PRIMARY KEY,
    year            INT,
    month           INT,
    month_name      VARCHAR(20),
    payment_date    DATE,
    loan_id         VARCHAR(5),
    lender_name     VARCHAR(100),
    emi_amount      DECIMAL(12,2),
    amount_paid     DECIMAL(12,2),
    status          VARCHAR(20), -- Paid, Missed
    loan_type       VARCHAR(50),
    purpose         VARCHAR(100),
    FOREIGN KEY (loan_id) REFERENCES loans_ref(loan_id)
);

CREATE TABLE IF NOT EXISTS overhead (
    overhead_id     INT AUTO_INCREMENT PRIMARY KEY,
    year            INT,
    month           INT,
    month_name      VARCHAR(20),
    expense_type    VARCHAR(50), -- Rent, Electricity
    amount          DECIMAL(10,2)
);
-- ================================================================
-- END OF SCHEMA
-- ================================================================
