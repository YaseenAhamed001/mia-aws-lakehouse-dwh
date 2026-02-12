# Dimension Table: dim_account

## 1. Overview

The `dim_account` table is the **account dimension** in our analytics layer.  
It stores all account-level information in a clean, standardized, and analytics-ready format.  

**Purpose:**  
- Provide a **single source of truth** for account attributes  
- Transform and enrich raw account data for analytics  
- Assign surrogate keys (`account_sk`) for joining with fact tables  
- Handle conditional logic for account closure and currency assignment  

---

## 2. Table Structure

| Column         | Type    | Description |
|----------------|---------|-------------|
| account_sk     | BIGINT  | Surrogate key for analytics (unique ID for joins) |
| account_id     | STRING  | Original account ID from source |
| customer_id    | STRING  | Reference to customer_id from dim_customer |
| account_type   | STRING  | Account type (STANDARDIZED to uppercase) |
| account_status | STRING  | Account status (ACTIVE / INACTIVE, uppercase) |
| open_date      | DATE    | Account opening date |
| close_date     | DATE    | Predicted account closure date (if inactive) |
| currency_code  | STRING  | Currency assigned to the account (USD/EUR/GBP/INR) |
| created_date   | DATE    | Analytics record creation date |
| updated_date   | DATE    | Analytics record last updated date |

---

## 3. Transformation Query (DML)

```sql
INSERT INTO analytics.dim_account
SELECT
    row_number() OVER (ORDER BY a.account_id)              AS account_sk,

    CAST(a.account_id AS VARCHAR)                          AS account_id,
    CAST(a.customer_id AS VARCHAR)                         AS customer_id,

    UPPER(a.account_type)                                  AS account_type,
    UPPER(a.status)                                        AS account_status,

    a.opened_date                                          AS open_date,

    CASE
        WHEN UPPER(a.status) = 'ACTIVE' THEN NULL
        ELSE date_add(
            'month',
            6 + (a.account_id % 24),
            a.opened_date
        )
    END                                                    AS close_date,

    CASE (a.account_id % 4)
        WHEN 0 THEN 'USD'
        WHEN 1 THEN 'EUR'
        WHEN 2 THEN 'GBP'
        ELSE 'INR'
    END                                                    AS currency_code,

    a.opened_date                                          AS created_date,
    current_date                                           AS updated_date
FROM curated.account a;
```

## 4. Query Explanation (Step-by-Step):

### 4.1 Surrogate Key
```sql 
row_number() OVER (ORDER BY a.account_id) AS account_sk
```
- Assigns a unique sequential number to each account

- Used as a primary key for analytics joins

- Ensures stability and avoids using raw account IDs directly

Example:

| account_id | account_sk |
|------------|------------|
| ACC001     | 1          |
| ACC002     | 2          |


### 4.2 Standardize Strings
```sql
UPPER(a.account_type) AS account_type,
UPPER(a.status) AS account_status
```

- Converts account type and status to uppercase for consistency

- Helps prevent mismatches in analytics due to inconsistent casing

Example:

| Original Type | Standardized Type |
|---------------|-----------------|
| savings       | SAVINGS         |
| Checking      | CHECKING        |


### 4.3 Account Dates
---
```sql
a.opened_date AS open_date,

CASE
    WHEN UPPER(a.status) = 'ACTIVE' THEN NULL
    ELSE date_add(
        'month',
        6 + (a.account_id % 24),
        a.opened_date
    )
END AS close_date
```

- open_date: taken directly from curated account table

- close_date: simulated predicted closure for inactive accounts

    - Active accounts remain open → close_date = NULL

    - Inactive accounts → close_date = opened_date + (6 + account_id % 24) months

    - account_id % 24 creates variability in closure months

Example:

| account_id | status   | open_date  | close_date |
|------------|----------|------------|------------|
| ACC001     | ACTIVE   | 2020-01-01 | NULL       |
| ACC002     | INACTIVE | 2020-03-01 | 2020-09-01 |


### 4.4 Assign Currency
---
```sql
CASE (a.account_id % 4)
    WHEN 0 THEN 'USD'
    WHEN 1 THEN 'EUR'
    WHEN 2 THEN 'GBP'
    ELSE 'INR'
END AS currency_code
```
Assigns currency based on account_id modulo 4

Ensures a mix of currencies for demonstration/testing

Real-life systems may fetch this from the source or business rules

Example:

| account_id | account_id % 4 | currency_code |
|------------|----------------|---------------|
| ACC001     | 1              | EUR           |
| ACC002     | 2              | GBP           |
| ACC003     | 3              | INR           |
| ACC004     | 0              | USD           |


### 4.5 Created and Updated Dates
---
a.opened_date AS created_date,
current_date AS updated_date
created_date: marks when the account was first recorded in analytics

updated_date: always set to current date when ETL runs

### 5. Example Rows

| account_sk | account_id | customer_id | account_type | account_status | open_date  | close_date | currency_code | created_date | updated_date |
|------------|------------|------------|--------------|----------------|------------|------------|---------------|--------------|--------------|
| 1          | ACC001     | CUST001    | SAVINGS      | ACTIVE         | 2020-01-01 | NULL       | USD           | 2020-01-01   | 2026-02-12   |
| 2          | ACC002     | CUST002    | CHECKING     | INACTIVE       | 2020-03-01 | 2020-09-01 | GBP           | 2020-03-01   | 2026-02-12   |


### 6. Best Practices

Always join fact tables using account_sk instead of raw account_id

Keep uppercase for account_type and account_status to avoid case-related mismatches

Update this dimension periodically to reflect account closures or new accounts

---
---
