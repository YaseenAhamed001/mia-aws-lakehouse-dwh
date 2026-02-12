## Staging Layer – Raw Data (S3 + Athena)

### Overview
---

The Staging Layer (also called Raw or Landing layer) is the first storage stop for data arriving from the source system.

It contains a 1:1 copy of the OLTP schema with no transformations applied. This ensures:

Traceability: Can always trace analytics data back to the source.

Reprocessing: If a transformation fails, raw data can be reprocessed.

Auditability: Maintains original source fidelity for governance and debugging.

**Data Flow**
```
OLTP PostgreSQL (Docker)
        │
        ▼
AWS DMS
        │
        ▼
S3 Raw Layer (staging/oltp/mia_db/oltp/)
        │
        ▼
Athena External Tables (staging schema)
```

- AWS DMS performs full load + optional CDC.

- Data lands in CSV files in S3.

- Athena external tables are used to query the data without moving it.

---

**Layer Design**

***S3 Bucket***
```
mia-dwh-staging-raw-us-east-1
└── staging/oltp/mia_db/oltp/
    ├── customer/
    ├── account/
    ├── product/
    └── account_transaction/
```

- Organized by database → schema → table.

- Athena results stored under athena-results/.

File Format

- CSV: Chosen for DMS compatibility and source fidelity.

- Raw: No type coercion or transformations.

---

### Athena External Tables – Queries & Explanation
---

***1️⃣ staging.account***
```sql
DROP TABLE IF EXISTS staging.account;

CREATE EXTERNAL TABLE staging.account (
    account_id     INT,
    customer_id    INT,
    account_type   STRING,
    balance        DECIMAL(15,2),
    opened_date    DATE,
    status         STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe'
WITH SERDEPROPERTIES (
  'field.delim' = ',',
  'serialization.format' = ','
)
LOCATION 's3://mia-dwh-staging-raw-us-east-1/staging/oltp/mia_db/oltp/account/';
```

Explanation:

- account_id → Primary identifier for the account.

- customer_id → Links account to customer.

- account_type → Savings, Checking, etc.

- balance → Current account balance.

- opened_date → When account was created.

- status → Active, Closed, Suspended.

This query registers the S3 CSV folder as an external table so Athena can query it.

---

***2️⃣ staging.customer***
```sql
DROP TABLE IF EXISTS staging.customer;

CREATE EXTERNAL TABLE staging.customer (
    customer_id  INT,
    first_name   STRING,
    last_name    STRING,
    email        STRING,
    phone        STRING,
    city         STRING,
    country      STRING,
    created_at   TIMESTAMP
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe'
WITH SERDEPROPERTIES (
  'field.delim' = ',',
  'serialization.format' = ','
)
LOCATION 's3://mia-dwh-staging-raw-us-east-1/staging/oltp/mia_db/oltp/customer/';
```

Explanation:

- customer_id → Unique identifier for each customer.

- first_name, last_name → Customer names.

- email, phone → Contact information.

- city, country → Location details.

- created_at → Timestamp when the customer record was created in OLTP.

---

***3️⃣ staging.product***
```sql
DROP TABLE IF EXISTS staging.product;

CREATE EXTERNAL TABLE staging.product (
    product_id    INT,
    product_name  STRING,
    category      STRING,
    price         DECIMAL(10,2),
    active_flag   BOOLEAN,
    created_at    TIMESTAMP
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe'
WITH SERDEPROPERTIES (
  'field.delim' = ',',
  'serialization.format' = ','
)
LOCATION 's3://mia-dwh-staging-raw-us-east-1/staging/oltp/mia_db/oltp/product/';
```

Explanation:

- product_id → Unique product identifier.

- product_name → Name of product.

- category → Product category (e.g., Loans, Savings).

- price → Price of the product.

- active_flag → TRUE if product is currently active.

- created_at → Timestamp when product was added.

---

***4️⃣ staging.account_transaction***
```sql
DROP TABLE IF EXISTS staging.account_transaction;

CREATE EXTERNAL TABLE staging.account_transaction (
    transaction_id    INT,
    account_id        INT,
    product_id        INT,
    amount            DECIMAL(15,2),
    transaction_ts    TIMESTAMP,
    transaction_type  STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe'
WITH SERDEPROPERTIES (
  'field.delim' = ',',
  'serialization.format' = ','
)
LOCATION 's3://mia-dwh-staging-raw-us-east-1/staging/oltp/mia_db/oltp/account_transaction/';
```

Explanation:

- transaction_id → Unique transaction identifier.

- account_id → Links transaction to account.

- product_id → Product associated with transaction.

- amount → Transaction amount.

- transaction_ts → Transaction timestamp.

- transaction_type → Credit, Debit, Fee, etc.

Best Practices

- ***Immutability:*** Never overwrite raw S3 files.

- ***Consistency:*** Folder/table naming matches OLTP schema.

- ***Quality Checks:*** Null checks, volume checks, freshness checks.

- ***Separation of Concerns:*** Raw layer has no transformations.

Trade-Offs
| Decision         | Reason                        | Alternative                |
|-----------------|-------------------------------|----------------------------|
| CSV format       | Compatible with DMS           | Parquet (used later)       |
| No partitioning  | Simplifies ingestion          | Partition by date (optional) |
| External tables  | Query without moving          | Load into Redshift         |


---

**Pitfalls to Avoid**

- Heavy analytics on raw CSV → slow queries

- Overwriting raw files → breaks reproducibility

- Applying transformations here → violates separation of layers

---

***How to Reproduce***

1. Configure DMS to replicate OLTP → S3.

2. Run staging/ddl/create_external_tables.sql (all 4 tables).

3. Validate:
```sql
SELECT COUNT(*) FROM staging.account;
SELECT * FROM staging.customer LIMIT 5;
SELECT * FROM staging.product LIMIT 5;
SELECT * FROM staging.account_transaction LIMIT 10;
```

---
