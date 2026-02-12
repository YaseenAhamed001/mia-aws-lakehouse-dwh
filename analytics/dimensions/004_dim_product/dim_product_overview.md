# Dimension Table: dim_product

## 1. Overview

The `dim_product` table is the **product dimension** in our analytics layer.  
It provides a **clean, enriched view of all products** for analytics, reporting, and fact table joins.

**Purpose:**  
- Standardize product information from the curated layer  
- Classify products into meaningful categories and types  
- Track product lifecycle (launch and retirement)  
- Assign surrogate keys (`product_sk`) for analytics joins  

---

## 2. Table Structure

| Column           | Type    | Description |
|-----------------|---------|-------------|
| product_sk       | BIGINT  | Surrogate key (unique for analytics joins) |
| product_id       | STRING  | Original product ID from source |
| product_name     | STRING  | Product name |
| product_category | STRING  | Product category (uppercase) |
| product_type     | STRING  | Product type: FINANCIAL, PROTECTION, INVESTMENT, SERVICE |
| product_status   | STRING  | ACTIVE or RETIRED |
| launch_date      | DATE    | Date when the product was launched |
| retire_date      | DATE    | Predicted retirement date (if inactive) |
| created_date     | DATE    | Analytics record creation date |
| updated_date     | DATE    | Analytics record last updated date |

---

## 3. Transformation Query (DML)

```sql
INSERT INTO analytics.dim_product
SELECT
    row_number() OVER (ORDER BY p.product_id)              AS product_sk,

    CAST(p.product_id AS VARCHAR)                          AS product_id,
    p.product_name                                         AS product_name,
    UPPER(p.category)                                      AS product_category,

    /* Product Type */
    CASE
        WHEN lower(p.category) LIKE '%loan%'
          OR lower(p.category) LIKE '%credit%' THEN 'FINANCIAL'
        WHEN lower(p.category) LIKE '%insurance%'          THEN 'PROTECTION'
        WHEN lower(p.category) LIKE '%invest%'             THEN 'INVESTMENT'
        ELSE 'SERVICE'
    END                                                    AS product_type,

    /* Product Status */
    CASE
        WHEN p.active_flag = true THEN 'ACTIVE'
        ELSE 'RETIRED'
    END                                                    AS product_status,

    CAST(p.created_at AS DATE)                             AS launch_date,

    CASE
        WHEN p.active_flag = true THEN NULL
        ELSE date_add(
            'month',
            12 + (p.product_id % 36),
            CAST(p.created_at AS DATE)
        )
    END                                                    AS retire_date,

    CAST(p.created_at AS DATE)                             AS created_date,
    current_date                                           AS updated_date
FROM curated.product p;
```

## 4. Query Explanation (Step-by-Step)

### 4.1 Surrogate Key

```sql
row_number() OVER (ORDER BY p.product_id) AS product_sk
```

- Generates a unique sequential ID for each product

- Used as a primary key for analytics joins

- Ensures consistency, instead of relying on raw product IDs

Example:

| product_id | product_sk |
|------------|------------|
| PRD001     | 1          |
| PRD002     | 2          |


### 4.2 Standardize Category

```sql
UPPER(p.category) AS product_category
```

Converts category to uppercase for consistency

Ensures analytics queries aren’t affected by case mismatches

Example:

| Original Category | Standardized   |
|------------------|---------------|
| loan             | LOAN          |
| Investment       | INVESTMENT    |


### 4.3 Product Type Classification

```sql
CASE
    WHEN lower(p.category) LIKE '%loan%'
      OR lower(p.category) LIKE '%credit%' THEN 'FINANCIAL'
    WHEN lower(p.category) LIKE '%insurance%' THEN 'PROTECTION'
    WHEN lower(p.category) LIKE '%invest%' THEN 'INVESTMENT'
    ELSE 'SERVICE'
END AS product_type
```

Categorizes products into broader types for reporting:

- FINANCIAL → loans, credit cards

- PROTECTION → insurance products

- INVESTMENT → investment-related products

- SERVICE → all other products

Example:

| category        | product_type  |
|-----------------|---------------|
| personal loan   | FINANCIAL     |
| car insurance   | PROTECTION    |
| mutual invest   | INVESTMENT    |
| mobile plan     | SERVICE       |


### 4.4 Product Status

```sql
CASE
    WHEN p.active_flag = true THEN 'ACTIVE'
    ELSE 'RETIRED'
END AS product_status
```

Determines if a product is currently active or retired

Based on the boolean active_flag in the curated table

Example:

| active_flag | product_status |
|-------------|----------------|
| true        | ACTIVE         |
| false       | RETIRED        |


### 4.5 Launch and Retirement Dates

```sql
CAST(p.created_at AS DATE) AS launch_date,

CASE
    WHEN p.active_flag = true THEN NULL
    ELSE date_add(
        'month',
        12 + (p.product_id % 36),
        CAST(p.created_at AS DATE)
    )
END AS retire_date
```

- launch_date: original creation date from the curated table

- retire_date: simulated for retired products using product_id modulo logic

    - Active products → NULL

    - Retired products → launch_date + (12 + product_id % 36) months

Example:

| product_id | active_flag | launch_date | retire_date |
|------------|------------|------------|------------|
| PRD001     | true       | 2020-01-01 | NULL       |
| PRD002     | false      | 2019-06-01 | 2020-08-01 |

### 4.6 Created and Updated Dates

```sql
CAST(p.created_at AS DATE) AS created_date,
current_date AS updated_date
```
created_date: keeps the original creation date from the curated layer

updated_date: set to current ETL run date

5. Example Rows

| product_sk | product_id | product_name    | product_category | product_type  | product_status | launch_date | retire_date | created_date | updated_date |
|------------|------------|----------------|-----------------|---------------|----------------|-------------|-------------|--------------|--------------|
| 1          | PRD001     | Personal Loan  | LOAN            | FINANCIAL     | ACTIVE         | 2020-01-01  | NULL        | 2020-01-01   | 2026-02-12   |
| 2          | PRD002     | Car Insurance  | INSURANCE       | PROTECTION    | RETIRED        | 2019-06-01  | 2020-08-01  | 2019-06-01   | 2026-02-12   |
| 3          | PRD003     | Mobile Invest  | INVESTMENT      | INVESTMENT    | ACTIVE         | 2021-03-01  | NULL        | 2021-03-01   | 2026-02-12   |


### 6. Best Practices

- Use product_sk for joins with fact tables

- Ensure product categories remain uppercase to avoid case mismatches

- Periodically refresh this dimension to capture new launches or retired products

- Adjust product type rules as new categories are introduced

---
---
