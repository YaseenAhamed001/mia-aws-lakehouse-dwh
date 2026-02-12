# Data Lake & ETL Pipeline: Glue Curated Jobs

This repository contains the AWS Glue ETL scripts and setup for processing OLTP CSV data from the S3 staging layer to the curated Parquet layer. The architecture follows a **Clean Hybrid Approach**:

- **Domain 1 – Lake Processing (AWS Native)**: Raw → Curated (Glue + S3 + Step Functions)
- **Domain 2 – Warehouse Processing (Prefect Controlled)**: Curated → Redshift → Analytics  

This README explains all Glue jobs, triggers, purpose, data types, and scripts in detail.

---

## Table of Contents

- [Data Lake \& ETL Pipeline: Glue Curated Jobs](#data-lake--etl-pipeline-glue-curated-jobs)
  - [Table of Contents](#table-of-contents)
  - [Architecture Overview](#architecture-overview)
  - [Glue Jobs Overview](#glue-jobs-overview)
  - [Trigger Mechanism](#trigger-mechanism)
    - [File-Place Trigger (account\_transaction)](#file-place-trigger-account_transaction)
  - [Detailed Glue Scripts](#detailed-glue-scripts)
    - [**1️⃣ curate\_customer**](#1️⃣-curate_customer)
    - [**2️⃣ curate\_account**](#2️⃣-curate_account)
    - [**3️⃣ curate\_product**](#3️⃣-curate_product)
    - [**4️⃣ curate\_account\_transaction**](#4️⃣-curate_account_transaction)
  - [Setup \& Execution](#setup--execution)
  - [Monitoring](#monitoring)
  - [Notes](#notes)
  - [**Glue Script Detailed Explanation**](#glue-script-detailed-explanation)
  - [**1️⃣ Import Libraries**](#1️⃣-import-libraries)
  - [**2️⃣ Glue Job Parameters**](#2️⃣-glue-job-parameters)
  - [**3️⃣ Initialize Spark and Glue Context**](#3️⃣-initialize-spark-and-glue-context)
  - [**4️⃣ Read CSV from S3**](#4️⃣-read-csv-from-s3)
  - [**5️⃣ Cast / Rename Columns**](#5️⃣-cast--rename-columns)
    - [**Data type mapping**:](#data-type-mapping)
  - [**6️⃣ Write Data to Curated S3 Layer**](#6️⃣-write-data-to-curated-s3-layer)
  - [**7️⃣ Commit Glue Job**](#7️⃣-commit-glue-job)
  - [**8️⃣ File-Triggered Automation (for `account_transaction`)**](#8️⃣-file-triggered-automation-for-account_transaction)
  - [**9️⃣ Why Use Glue + Spark + Parquet**](#9️⃣-why-use-glue--spark--parquet)
    - [**Summary of Job Design**](#summary-of-job-design)

---

## Architecture Overview

```

Raw S3 (Staging CSV)
|
v
AWS Glue Jobs
|
v
Curated S3 (Parquet, optimized)
|
v
Redshift / Analytics (Prefect orchestrated)

````

- **Step Functions** orchestrates Lake Processing jobs.  
- **Prefect** orchestrates Warehouse Processing (curated → Redshift → consumption).  
- **EventBridge file triggers** enforce automated ETL for account transactions.

---

## Glue Jobs Overview

| Glue Job | Input | Output | Trigger | Purpose |
|----------|-------|--------|---------|---------|
| curate_customer | `customer` CSV | Parquet in S3 curated layer | Manual / Step Functions | Standardize and prepare customer data |
| curate_account | `account` CSV | Parquet in S3 curated layer | Manual / Step Functions | Standardize accounts, link with customer IDs |
| curate_product | `product` CSV | Parquet in S3 curated layer | Manual / Step Functions | Standardize product data, enforce decimal & boolean types |
| curate_account_transaction | `account_transaction` CSV | Parquet in S3 curated layer | EventBridge file-placed only | Load transactional data automatically, block manual runs for integrity |

---

## Trigger Mechanism

### File-Place Trigger (account_transaction)

- S3 Path: `s3://mia-dwh-staging-raw-us-east-1/triggers/account_transaction/trigger.trg`
- EventBridge monitors S3 for object creation events.
- Event triggers Step Functions which starts the Glue job `curate_account_transaction`.
- **Manual runs are blocked** using the `--triggered_by` argument in the Glue script:

```python
if triggered_by != 'eventbridge':
    raise Exception("❌ This job must be triggered by EventBridge only.")
````

---

## Detailed Glue Scripts

### **1️⃣ curate_customer**

```python
import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import col

# Job parameters
args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Read raw CSV
df = spark.read.format("csv") \
    .option("header", "false") \
    .option("inferSchema", "true") \
    .load("s3://mia-dwh-staging-raw-us-east-1/staging/oltp/mia_db/oltp/customer/")

# Cast & rename columns
df_curated = df.select(
    col("_c0").cast("bigint").alias("customer_id"),
    col("_c1").cast("string").alias("first_name"),
    col("_c2").cast("string").alias("last_name"),
    col("_c3").cast("string").alias("email"),
    col("_c4").cast("string").alias("phone"),
    col("_c5").cast("string").alias("city"),
    col("_c6").cast("string").alias("country"),
    col("_c7").cast("timestamp").alias("created_at")
)

# Write to Parquet
df_curated.write.mode("overwrite") \
    .parquet("s3://mia-dwh-staging-curated-us-east-1/curated/customer/")

job.commit()
```

**Notes**:

* Reads raw CSV without headers.
* `_c0, _c1...` correspond to column positions.
* Writes Parquet to the curated S3 layer.

---

### **2️⃣ curate_account**

```python
import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import col

args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

df = spark.read.format("csv") \
    .option("header", "false") \
    .option("inferSchema", "true") \
    .load("s3://mia-dwh-staging-raw-us-east-1/staging/oltp/mia_db/oltp/account/")

df_curated = df.select(
    col("_c0").cast("bigint").alias("account_id"),
    col("_c1").cast("bigint").alias("customer_id"),
    col("_c2").cast("string").alias("account_type"),
    col("_c3").cast("bigint").alias("balance"),
    col("_c4").cast("timestamp").alias("opened_date"),
    col("_c5").cast("string").alias("status")
)

df_curated.write.mode("overwrite") \
    .parquet("s3://mia-dwh-staging-curated-us-east-1/curated/account/")

job.commit()
```

**Notes**:

* Links accounts to customers via `customer_id`.
* Ensures proper types for balances and dates.

---

### **3️⃣ curate_product**

```python
import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.types import DecimalType, BooleanType
from pyspark.sql.functions import col

args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

df = spark.read.format("csv") \
    .option("header", "false") \
    .option("inferSchema", "true") \
    .load("s3://mia-dwh-staging-raw-us-east-1/staging/oltp/mia_db/oltp/product/")

df_curated = df.select(
    col("_c0").cast("bigint").alias("product_id"),
    col("_c1").cast("string").alias("product_name"),
    col("_c2").cast("string").alias("category"),
    col("_c3").cast(DecimalType(10, 2)).alias("price"),
    col("_c4").cast(BooleanType()).alias("active_flag"),
    col("_c5").cast("timestamp").alias("created_at")
)

df_curated.write.mode("overwrite") \
    .parquet("s3://mia-dwh-staging-curated-us-east-1/curated/product/")

job.commit()
```

**Notes**:

* Uses `DecimalType(10,2)` for accurate prices.
* Boolean flag ensures active/inactive products are represented correctly.

---

### **4️⃣ curate_account_transaction**

```python
import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.types import DecimalType, TimestampType, StringType
from pyspark.sql.functions import col

args = getResolvedOptions(sys.argv, ['JOB_NAME'])

# Ensure job is triggered by EventBridge only
triggered_by = None
if '--triggered_by' in sys.argv:
    triggered_by = sys.argv[sys.argv.index('--triggered_by') + 1]

if triggered_by != 'eventbridge':
    raise Exception("❌ This job must be triggered by EventBridge only.")

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

df = spark.read.format("csv") \
    .option("header", "false") \
    .option("inferSchema", "true") \
    .load("s3://mia-dwh-staging-raw-us-east-1/staging/oltp/mia_db/oltp/account_transaction/")

df_curated = df.select(
    col("_c0").cast("bigint").alias("transaction_id"),
    col("_c1").cast("bigint").alias("account_id"),
    col("_c2").cast("bigint").alias("product_id"),
    col("_c3").cast(DecimalType(15, 2)).alias("amount"),
    col("_c4").cast(TimestampType()).alias("transaction_ts"),
    col("_c5").cast(StringType()).alias("transaction_type")
)

df_curated.write.mode("overwrite") \
    .parquet("s3://mia-dwh-staging-curated-us-east-1/curated/account_transaction/")

job.commit()
```

**Notes**:

* Only runs if triggered by EventBridge.
* Processes transactional data with **high precision** amounts (`DecimalType(15,2)`).
* Maintains referential integrity with `account_id` and `product_id`.

---

## Setup & Execution

1. **Upload CSV files** to S3 staging layer.
2. **Create Glue Jobs** using the scripts above.
3. **Create Step Functions / EventBridge** triggers for automation:

   * All jobs can run manually except `curate_account_transaction`.
   * `curate_account_transaction` runs **only** when the file `trigger.trg` is placed in S3.
4. **Verify Curated Output** in S3:

   ```text
   s3://mia-dwh-staging-curated-us-east-1/curated/<table>/
   ```

---

## Monitoring

* Glue Job Run Logs: AWS Glue → Jobs → Job Runs → Logs in CloudWatch.
* Step Functions History: Monitor execution, success, failures.
* Athena: Query curated Parquet tables to validate data.

---

## Notes

* Column positions in CSV (`_c0`, `_c1`, …) must match the schema.
* Decimal and Boolean types are strictly enforced for `product` and `account_transaction`.
* Manual runs of `curate_account_transaction` **will fail** to maintain automation integrity.

---

## **Glue Script Detailed Explanation**

The following explanation applies to all four Glue scripts (`curate_customer`, `curate_account`, `curate_product`, `curate_account_transaction`), with notes where things differ.

---

## **1️⃣ Import Libraries**

```python
import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.types import DecimalType, TimestampType, BooleanType, StringType
from pyspark.sql.functions import col
```

**Explanation**:

* `sys`: Required to access command-line arguments passed to the Glue job.
* `awsglue.transforms` and `awsglue.utils`: AWS Glue helper modules for ETL transformations and argument parsing.
* `SparkContext` and `GlueContext`: Glue runs on **Apache Spark**, so SparkContext initializes Spark, and GlueContext provides Glue-specific functionality on top of Spark.
* `Job`: Glue job object used to **initialize, commit, and manage job state**.
* `pyspark.sql.types`: For defining column types explicitly (`DecimalType`, `TimestampType`, `BooleanType`, `StringType`).
* `pyspark.sql.functions.col`: Used to reference columns in DataFrames for selection, casting, and renaming.

---

## **2️⃣ Glue Job Parameters**

```python
args = getResolvedOptions(sys.argv, ['JOB_NAME'])
```

* Glue jobs **require the `JOB_NAME` argument** to initialize and log execution.
* For `curate_account_transaction`, an additional optional parameter is used:

```python
triggered_by = None
if '--triggered_by' in sys.argv:
    triggered_by = sys.argv[sys.argv.index('--triggered_by') + 1]
```

* This ensures **manual runs can be blocked**. Only jobs triggered by EventBridge pass the `"eventbridge"` value.
* If the job is run manually, it raises:

```python
if triggered_by != 'eventbridge':
    raise Exception("❌ This job must be triggered by EventBridge only.")
```

---

## **3️⃣ Initialize Spark and Glue Context**

```python
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)
```

* `SparkContext()` initializes a Spark session for distributed computation.
* `GlueContext(sc)` wraps SparkContext with Glue-specific features (e.g., DynamicFrames, job bookmarking, S3 integration).
* `spark = glueContext.spark_session` is the standard SparkSession for reading/writing DataFrames.
* `job.init()` sets up job state in Glue and prepares it for logging and commit.

---

## **4️⃣ Read CSV from S3**

```python
df = spark.read.format("csv") \
    .option("header", "false") \
    .option("inferSchema", "true") \
    .load("<S3_RAW_PATH>")
```

* Reads the raw CSV data from the **staging S3 bucket**.
* `.option("header", "false")`: Indicates the CSV has **no header row**, so columns are `_c0`, `_c1`, `_c2`, etc.
* `.option("inferSchema", "true")`: Spark attempts to **infer data types automatically**.
* `.load("<S3_RAW_PATH>")`: Path is job-specific, e.g., customer, account, product, or account_transaction.

---

## **5️⃣ Cast / Rename Columns**

```python
df_curated = df.select(
    col("_c0").cast("bigint").alias("customer_id"),
    col("_c1").cast("string").alias("first_name"),
    ...
)
```

**Explanation**:

1. **`col("_c0")`**: References the first column in the CSV.
2. **`.cast("bigint")`**: Converts data to the appropriate type for analytics/joins.
3. **`.alias("customer_id")`**: Renames the column to a meaningful name.

### **Data type mapping**:

| Source SQL Type       | Spark Type          |
| --------------------- | ------------------- |
| SERIAL / INT / BIGINT | `bigint`            |
| VARCHAR(n)            | `string`            |
| NUMERIC(p, s)         | `DecimalType(p, s)` |
| BOOLEAN               | `BooleanType()`     |
| TIMESTAMP             | `TimestampType()`   |

**Notes**:

* For `curate_product`, the **price** column is cast as `DecimalType(10,2)`.
* For `curate_account_transaction`, the **amount** column is `DecimalType(15,2)`.
* Boolean columns like `active_flag` use `BooleanType()` for proper Spark schema compatibility.

---

## **6️⃣ Write Data to Curated S3 Layer**

```python
df_curated.write.mode("overwrite") \
    .parquet("<S3_CURATED_PATH>")
```

* `.mode("overwrite")`: Replaces existing data in the curated bucket.
* `.parquet()`: Stores data in **columnar Parquet format** for:

  * Faster queries
  * Schema enforcement
  * Compression with snappy
* Path is job-specific.

**Example**:

```text
s3://mia-dwh-staging-curated-us-east-1/curated/customer/
```

---

## **7️⃣ Commit Glue Job**

```python
job.commit()
```

* Signals Glue that the job is finished.
* Updates job bookmarks and logs for future runs.
* Essential for job monitoring and failure handling.

---

## **8️⃣ File-Triggered Automation (for `account_transaction`)**

* **Trigger Mechanism**: EventBridge + Step Functions
* EventBridge monitors S3 for the presence of:

```text
s3://mia-dwh-staging-raw-us-east-1/triggers/account_transaction/trigger.trg
```

* Step Functions execute the Glue job **automatically**.
* Manual runs fail because of the `triggered_by` check:

```python
if triggered_by != 'eventbridge':
    raise Exception("❌ This job must be triggered by EventBridge only.")
```

**Benefit**: Ensures transactional integrity, only loads **new transactions** when triggered by the designated file.

---

## **9️⃣ Why Use Glue + Spark + Parquet**

* **Glue**: Managed ETL service; handles scaling, job scheduling, and S3 integration.
* **Spark DataFrames**: Provides schema enforcement, type casting, and efficient transformations.
* **Parquet**: Columnar storage optimized for analytics (e.g., Athena, Redshift Spectrum).

---

### **Summary of Job Design**

| Glue Job                   | Input           | Output              | Trigger                      | Notes                             |
| -------------------------- | --------------- | ------------------- | ---------------------------- | --------------------------------- |
| curate_customer            | customer CSV    | customer Parquet    | Manual or automated          | Simple CSV → Parquet              |
| curate_account             | account CSV     | account Parquet     | Manual or automated          | Ensures joins with customer data  |
| curate_product             | product CSV     | product Parquet     | Manual or automated          | Handles decimal and boolean types |
| curate_account_transaction | transaction CSV | transaction Parquet | EventBridge file-placed only | Manual runs blocked for integrity |

---
---
