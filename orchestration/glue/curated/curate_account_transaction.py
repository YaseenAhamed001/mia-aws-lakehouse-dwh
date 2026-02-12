import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.types import DecimalType, TimestampType, StringType
from pyspark.sql.functions import col

# Job parameters (JOB_NAME is always required)
args = getResolvedOptions(sys.argv, ['JOB_NAME'])

# Check if triggered_by is provided, default to None
triggered_by = None
if '--triggered_by' in sys.argv:
    triggered_by = sys.argv[sys.argv.index('--triggered_by') + 1]

# Fail if not triggered by EventBridge
if triggered_by != 'eventbridge':
    raise Exception("❌ This job must be triggered by EventBridge only.")

# Job initialization
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# 1️⃣ Read raw CSV from S3
df = spark.read.format("csv") \
    .option("header", "false") \
    .option("inferSchema", "true") \
    .load("s3://mia-dwh-staging-raw-us-east-1/staging/oltp/mia_db/oltp/account_transaction/")

# 2️⃣ Cast / enforce types and rename columns
df_curated = df.select(
    col("_c0").cast("bigint").alias("transaction_id"),                  # SERIAL PRIMARY KEY
    col("_c1").cast("bigint").alias("account_id"),                      # INT FK to account
    col("_c2").cast("bigint").alias("product_id"),                      # INT FK to product
    col("_c3").cast(DecimalType(15, 2)).alias("amount"),                # NUMERIC(15,2)
    col("_c4").cast(TimestampType()).alias("transaction_ts"),           # TIMESTAMP
    col("_c5").cast(StringType()).alias("transaction_type")             # VARCHAR(20)
)

# 3️⃣ Write Parquet to curated S3
df_curated.write.mode("overwrite") \
    .parquet("s3://mia-dwh-staging-curated-us-east-1/curated/account_transaction/")

# 4️⃣ Commit Glue job
job.commit()
