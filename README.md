## AWS Lakehouse Data Warehouse – End-to-End Production Architecture

**Overview**
---
This project implements a production-grade AWS Lakehouse Data Warehouse using a layered architecture approach.

The platform ingests transactional OLTP data, processes it through governed data lake layers, and exposes analytics-ready datasets for BI and downstream systems.

The architecture follows modern data engineering best practices:

- Layered lakehouse design `(Raw → Curated → Analytics → Consumption)`

- Separation of storage by responsibility

- Columnar storage with Parquet + Snappy compression

- Explicit fact grain definition

- Star schema modeling

- Partitioned fact tables for scalable querying

- Observability and governance integration

This repository is structured as a real-world data platform project, not a tutorial.

---
**High-Level Architecture**
```
OLTP (PostgreSQL - Docker)
        │
        ▼
AWS DMS (CDC / Full Load)
        │
        ▼
S3 - Raw Layer (External Tables via Athena)
        │
        ▼
Curated Layer (Typed + Cleaned Parquet)
        │
        ▼
Analytics Layer (Dimensions + Facts + Aggregates)
        │
        ▼
Consumption Layer (Redshift / BI / APIs)
```

### End-to-End Data Flow
---
---
***1️⃣ Source System (OLTP)***

PostgreSQL running in Docker

Normalized schema

Transactional workload

Represents operational banking-style data:

- Customers

- Accounts

- Products

- Account transactions

This system is optimized for writes and integrity — not analytics.

---
***2️⃣ Ingestion (AWS DMS)***

AWS Database Migration Service performs:

- Full load extraction

- Optional CDC (Change Data Capture)

- Writes data into S3 Raw layer

- Data lands as a 1:1 structural copy of the source schema.

- No transformations occur here.

Purpose:

Preserve source fidelity.

---
***3️⃣ Raw (Staging) Layer – S3 + Athena***

Bucket:

mia-dwh-staging-raw-us-east-1


Characteristics:

- 1:1 copy of OLTP

- External tables in Athena

- CSV format

- No business logic

- No transformation

- Used for traceability and replayability

This layer ensures:

- Source auditing

- Reprocessing capability

- Data lineage clarity

---
***4️⃣ Curated Layer – Cleaned & Typed Data***

Bucket:

mia-dwh-staging-curated-us-east-1


Characteristics:

- Stored in Parquet

- Snappy compression

- Proper data types enforced

- Null handling

- Basic standardization

- Still 1:1 structurally with OLTP

- Transformations performed via CTAS (Create Table As Select).

**Purpose:**

Convert raw data into optimized analytical storage format.

---
***5️⃣ Analytics Layer – Star Schema Modeling***

Bucket:

mia-dwh-analytics-us-east-1


Contains:

- Dimensions

- Facts

- Aggregates

Dimensions

- dim_customer

- dim_account

- dim_product

- dim_customer_segment

- dim_date

- dim_baseline_period

Facts

- fact_account_transaction

- fact_account_daily_balance

- fact_customer_baseline

Aggregates

- monthly_customer_balance

- segment_level_kpis

Design principles:

- Explicit fact grain

- Surrogate keys (where applicable)

- Partitioning on time-based facts

- Separation of atomic facts and aggregates

Purpose:

Enable scalable analytical queries.

***6️⃣ Consumption Layer***

Bucket:

mia-dwh-consumption-us-east-1


Used for:

- BI extracts

- Departmental exports

- API feeds

- Redshift analytics schema

This layer is presentation-focused and downstream-oriented.

***7️⃣ Monitoring & Governance***

Bucket:

mia-dwh-logs-metadata-us-east-1


Contains:

- Glue job metadata

- Athena query logs

- Data quality checks

- Freshness tracking

- Load history

- Schema change tracking

This ensures:

- Observability

- Auditability

- Platform governance

**Data Modeling Strategy**

This warehouse follows a star schema design.

Fact Design

- Each fact table has a clearly defined grain.

Example:

fact_account_transaction

- One row per transaction event.

fact_account_daily_balance

- One row per account per day.

Grain definition is mandatory and documented in the analytics layer.

**Dimension Design**

Dimensions provide descriptive context:

Slowly changing attributes

Analytical grouping fields

Hierarchical attributes

Storage & Performance Decisions
| Decision                 | Reason                                      |
|--------------------------|---------------------------------------------|
| Parquet format           | Columnar storage for analytical efficiency  |
| Snappy compression       | Balanced compression + performance          |
| Partitioning on time     | Reduces scan cost in Athena                 |
| Layered buckets          | Clear separation of responsibility          |
| External tables          | Decouples compute from storage              |

Technology Stack
| Component               | Purpose                   |
|-------------------------|---------------------------|
| PostgreSQL (Docker)     | OLTP source               |
| AWS DMS                 | Ingestion                 |
| Amazon S3               | Storage                   |
| AWS Glue                | ETL orchestration         |
| Athena                  | Serverless querying       |
| Amazon Redshift         | Consumption analytics     |
| CloudWatch              | Monitoring                |
| Step Functions          | Workflow orchestration    |


Repository Structure

Each layer has its own directory with colocated documentation:
```
oltp/
staging/
curated/
analytics/
consumption/
orchestration/
monitoring/
governance/
```

---
***Architecture Principles***

This platform was built using the following principles:

- Immutability in raw layer

- Separation of concerns

- Reprocessing capability

- Schema clarity

- Explicit grain definitions

- Scalable storage formats

- Observability first

- Cost-aware querying

---

## Project Structure & Data Lake Layout


### Repository Directory Structure
---
```
mia-aws-lakehouse-dwh/
│
├── README.md                        ← Executive / Portfolio overview
├── architecture/
│   └── architecture.md
├── oltp/
│   ├── ddl/
│   │   ├── create_tables.sql
│   │   └── README.md                ← OLTP design explained
│   └── docker/
├── ingestion/
│   ├── dms/
│   │   ├── task_config.json
│   │   └── README.md                ← DMS explained
├── staging/
│   ├── ddl/
│   │   ├── create_external_tables.sql
│   │   └── README.md                ← Raw layer explained
├── curated/
│   ├── transformations/
│   │   ├── curated_ctas.sql
│   │   └── README.md                ← Curated layer explained
├── analytics/
│   ├── dimensions/
│   │   ├── dim_customer.sql
│   │   ├── dim_account.sql
│   │   └── README.md
│   ├── facts/
│   │   ├── fact_account_transaction.sql
│   │   ├── fact_account_daily_balance.sql
│   │   └── README.md
│   ├── aggregates/
│   │   ├── monthly_customer_balance.sql
│   │   └── README.md
├── consumption/
│   ├── redshift/
│   │   ├── schema.sql
│   │   └── README.md
├── orchestration/
│   ├── glue/
│   ├── step_functions/
│   └── README.md
├── monitoring/
│   ├── cloudwatch/
│   └── README.md
└── governance/
    ├── naming_conventions.md
    ├── partitioning_strategy.md
    └── README.md
```

---

### AWS Lakehouse / S3 Structure
---

***Staging Layer (Raw)***
```
mia-dwh-staging-raw-us-east-1/
└── staging/oltp/mia_db/oltp/
   │   ├── customer/
   │   ├── account/
   │   ├── product/
   │   └── account_transaction/
   └── athena-results/Unsaved/2026/02/09/
```

***Curated Layer***
```
mia-dwh-staging-curated-us-east-1/
└── curated/
    ├── customer/
    ├── account/
    ├── product/
    └── account_transaction/
```

***Analytics Layer***
```
mia-dwh-analytics-us-east-1/
└── analytics/
    ├── dimensions/
    │   ├── dim_customer/
    │   ├── dim_account/
    │   ├── dim_product/
    │   ├── dim_customer_segment/
    │   ├── dim_baseline_period/
    │   └── dim_date/
    ├── facts/
    │   ├── fact_account_daily_balance/
    │   │     └── year=YYYY/
    │   │           └── month=MM/
    │   ├── fact_customer_baseline/
    │   └── fact_account_transaction/
    └── aggregates/
        ├── monthly_customer_balance/
        └── segment_level_kpis/
```

***Consumption Layer***
```
mia-dwh-consumption-us-east-1/
└── consumption/
    ├── bi_extracts/
    │   ├── powerbi/
    │   ├── tableau/
    │   └── quicksight/
    ├── data_exports/
    │   ├── finance/
    │   ├── marketing/
    │   └── risk/
    └── api_feeds/
        ├── realtime/
        └── batch/
```

***Logs & Metadata***
```
mia-dwh-logs-metadata-us-east-1/
└── platform/
    ├── glue/
    │   ├── crawlers/
    │   ├── jobs/
    │   └── bookmarks/
    ├── athena/
    │   ├── query_results/
    │   └── workgroups/
    ├── quality/
    │   ├── null_checks/
    │   ├── volume_checks/
    │   └── freshness_checks/
    └── audit/
        ├── schema_changes/
        └── load_history/
```

---

***Future Improvements***

- Apache Iceberg for ACID lake tables

- CI/CD for schema deployment

- Automated data quality rules

- Incremental fact loading

- Metadata catalog automation

- Data lineage integration

***Portfolio Positioning***

This project demonstrates:

- End-to-end data warehouse architecture

- AWS-native lakehouse implementation

- Data modeling expertise

- Storage optimization strategies

- Governance awareness

- Production-grade structuring

---
**Author**
---
***Yaseen Ahamed***
- Cloud Data Engineer | Lakehouse Architecture | AWS Analytics

This project reflects hands-on implementation of a production-style AWS lakehouse architecture, including ingestion, layered data modeling, orchestration, and governance.

---
🔗 LinkedIn: https://www.linkedin.com/in/ahamedyaseen0009/
---
---