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

# 1️⃣ Read raw CSV from S3
df = spark.read.format("csv") \
    .option("header", "false") \
    .option("inferSchema", "true") \
    .load("s3://mia-dwh-staging-raw-us-east-1/staging/oltp/mia_db/oltp/customer/")

# 2️⃣ Cast / enforce types
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

# 3️⃣ Write Parquet to curated S3
df_curated.write.mode("overwrite") \
    .parquet("s3://mia-dwh-staging-curated-us-east-1/curated/customer/")

job.commit()
