# Analytics Layer – Dimensions & Facts

## 1. Overview

The **Analytics Layer** is designed to provide **business-ready datasets** for reporting, BI tools, and advanced analytics.  
It sits on top of the **Curated Layer** and transforms cleaned tables into **dimensional models** (dimensions and facts).

**Key Concepts:**

- **Dimensions:** Descriptive entities that provide context to business processes. Examples: `dim_customer`, `dim_product`, `dim_date`.
- **Facts:** Quantitative measurements or events linked to dimensions. Examples: `fact_account_transaction`, `fact_account_daily_balance`.

This layer is structured to follow the **star schema** pattern for analytics:
```
      +-----------------+
      |   Dimensions    |
      +-----------------+
        /      |       \
       /       |        \
+-------------------+ +-------------------+
| Fact Tables | | Fact Tables |
+-------------------+ +-------------------+
```

---

## 2. Dimensions Overview

| Dimension Table         | Purpose |
|-------------------------|---------|
| dim_customer            | Stores enriched customer details for segmentation and reporting |
| dim_account             | Contains account metadata for linking transactions and balances |
| dim_product             | Product catalog with categories and attributes |
| dim_customer_segment    | Defines customer segments for analytics and marketing insights |
| dim_baseline_period     | Stores baseline period definitions for reference calculations |
| dim_date                | Standardized calendar table for time-based analytics |

---

## 3. Facts Overview

| Fact Table                     | Purpose |
|--------------------------------|---------|
| fact_account_transaction        | Captures all account-level transactions, linked to dimensions |
| fact_account_daily_balance      | Tracks account balances per day (partitioned by year/month) |
| fact_customer_baseline          | Stores baseline metrics for customers (partitioned by year/month) |

---

## 4. Data Flow

Curated Layer (Parquet)
│
▼
Analytics Layer (Dimensions & Facts)
│
▼
Aggregates / BI / Consumption Layer


- Dimensions are derived **directly from curated tables**  
- Facts are derived by **joining curated tables with dimensions**  
- Aggregates or KPIs are computed on top of facts for fast reporting  

---

## 5. Best Practices

- Keep **dimension tables slowly changing** (SCD type 2 if needed)  
- Partition **facts by date or relevant business key** for query efficiency  
- Always maintain **audit logs** and track provenance from curated layer  
- Use **consistent naming conventions** across all tables

---