# Dimension Table: dim_customer

## 1. Overview

`dim_customer` is a **customer dimension** table designed for analytics.  
It converts raw customer data into a **clean, deduplicated, and enriched dimension table**, making it easier to join with fact tables like transactions, balances, and customer baseline metrics.

**Purpose:**  
- Provide a **single source of truth** for customer attributes  
- Remove duplicates and keep the **latest record per customer**  
- Enable reporting, segmentation, and customer analysis  

---

## 2. Table Structure

| Column          | Type    | Description |
|-----------------|---------|-------------|
| customer_sk      | BIGINT | Surrogate key for analytics (unique ID for joins) |
| customer_id      | STRING | Original customer ID from source |
| first_name       | STRING | Customer first name |
| last_name        | STRING | Customer last name |
| email            | STRING | Email address |
| phone            | STRING | Phone number |
| gender           | STRING | Customer gender |
| date_of_birth    | DATE   | Customer DOB |
| customer_status  | STRING | Status (active/inactive) |
| created_date     | DATE   | Record creation date |
| updated_date     | DATE   | Record last updated |

---

## 3. Transformation Query

```sql
INSERT INTO analytics.dim_customer
SELECT
    row_number() OVER (ORDER BY customer_id) AS customer_sk,
    customer_id,
    first_name,
    last_name,
    email,
    phone,
    gender,
    date_of_birth,
    customer_status,
    created_date,
    updated_date
FROM (
    SELECT *,
           row_number() OVER (
               PARTITION BY customer_id
               ORDER BY updated_date DESC
           ) AS rn
    FROM curated.customer
)
WHERE rn = 1;
```

### Explanation:

- Start from curated.customer

- This table contains cleaned customer data from the curated layer.

- Deduplicate using row_number()

- PARTITION BY customer_id groups rows by each customer

- ORDER BY updated_date DESC ensures the latest record comes first

- row_number() OVER (...) AS rn assigns a sequential number within each group

- WHERE rn = 1 keeps only the latest record per customer

- Create surrogate key

- row_number() OVER (ORDER BY customer_id) AS customer_sk

- Assigns a unique, sequential ID used for joining facts

Keep all other attributes

Customer details are passed through as-is to make the dimension analytics-ready

### 4. Example Rows

| customer_sk | customer_id | first_name | last_name | email             | phone       | gender | date_of_birth | customer_status | created_date | updated_date |
|-------------|------------|------------|-----------|-----------------|------------|--------|---------------|----------------|--------------|--------------|
| 1           | CUST001    | John       | Doe       | john@example.com | 1234567890 | M      | 1985-01-15    | Active         | 2015-02-12   | 2026-02-10   |
| 2           | CUST002    | Jane       | Smith     | jane@example.com | 9876543210 | F      | 1990-06-20    | Active         | 2016-07-05   | 2026-01-20   |
``
---

### 5. Best Practices
Always join fact tables using customer_sk

Re-run this dimension periodically to capture updates

Avoid using raw customer_id in joins, as it may change or duplicate

---
---
