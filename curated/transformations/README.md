## Curated Layer (Transformations) – AWS Lakehouse Data Warehouse

### 1. Overview
---

The **Curated Layer** sits between the raw staging layer and the analytics layer.  
It is designed to transform raw OLTP data into **clean, consistent, and typed datasets** suitable for analytics, reporting, and further transformations.

**Goals:**
- Standardize data types
- Remove nulls or invalid entries
- Ensure consistent formatting across all tables
- Prepare data for dimensions, facts, and aggregates

---

## 2. Storage & Format

- **S3 Bucket:** `mia-dwh-staging-curated-us-east-1/curated/`
- **Format:** Parquet with Snappy compression
- **Structure Example:**
```
mia-dwh-staging-curated-us-east-1/
└── curated/
├── customer/
├── account/
├── product/
└── account_transaction/
```


- **Partitioning:** Typically by date or business-relevant fields in analytics tables (handled in analytics layer)

---

### 3. ETL / Transformation Strategy

- **Tool:** AWS Glue (serverless ETL)
- **Process:** 
  1. Read raw CSV files from staging layer
  2. Apply **type casting** (string → integer/decimal/date/timestamp)
  3. Replace empty strings with `NULL`
  4. Standardize column names
  5. Write transformed data as Parquet to S3 curated layer

---
**Example Glue CTAS Transformation (Athena Syntax):**
```sql
CREATE TABLE curated.customer
WITH (
    format = 'PARQUET',
    external_location = 's3://mia-dwh-staging-curated-us-east-1/curated/customer/',
    parquet_compression = 'SNAPPY'
) AS
SELECT
    CAST(customer_id AS INTEGER)          AS customer_id,
    NULLIF(first_name, '')                AS first_name,
    NULLIF(last_name, '')                 AS last_name,
    NULLIF(email, '')                     AS email,
    NULLIF(phone, '')                     AS phone,
    NULLIF(city, '')                      AS city,
    NULLIF(country, '')                   AS country,
    CAST(created_at AS TIMESTAMP)         AS created_at
FROM staging.customer;
```

Similar transformations are applied to account, product, and account_transaction tables.


### 4. Characteristics of the Curated Layer

| Feature Description       | Details                                               |
|---------------------------|-------------------------------------------------------|
| Data Type Casting         | Ensures proper types for analytics (INT, DECIMAL, DATE, TIMESTAMP) |
| Null Handling             | Replaces empty strings with NULL for consistency     |
| Standardized Schema       | Same column names and order across environments      |
| Storage Optimization      | Parquet + Snappy for storage and query efficiency    |
| Query-Ready               | Directly consumable by analytics layer and BI tools  |

---

### 5. S3 & Athena Integration

- S3 Location: Each table has its own folder in the curated bucket

- Athena: External tables can be created over Parquet files to query curated data without moving it
```sql
-- Example Athena Table
CREATE EXTERNAL TABLE curated.account (
    account_id INT,
    customer_id INT,
    account_type STRING,
    balance DECIMAL(15,2),
    opened_date DATE,
    status STRING
)
STORED AS PARQUET
LOCATION 's3://mia-dwh-staging-curated-us-east-1/curated/account/';
```

This approach ensures separation of storage and compute, leveraging serverless querying for exploration and analysis.

### 6. Best Practices

- Always preserve raw data; never overwrite staging layer files

- Use consistent naming conventions for columns and tables

- Partition only when necessary at the analytics layer to optimize queries

- Maintain audit logs of transformations in Glue for governance

---
---
