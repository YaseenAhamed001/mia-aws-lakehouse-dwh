
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

# Read raw CSV from S3
df = spark.read.format("csv") \
    .option("header", "false") \
    .option("inferSchema", "true") \
    .load("s3://mia-dwh-staging-raw-us-east-1/staging/oltp/mia_db/oltp/account/")

# Cast / enforce types and rename columns (_c0 etc depends on CSV columns order)
df_curated = df.select(
    col("_c0").cast("bigint").alias("account_id"),
    col("_c1").cast("bigint").alias("customer_id"),
    col("_c2").cast("string").alias("account_type"),
    col("_c3").cast("bigint").alias("balance"),
    col("_c4").cast("timestamp").alias("opened_date"),
	col("_c5").cast("string").alias("status")
)

# Write Parquet to curated S3
df_curated.write.mode("overwrite") \
    .parquet("s3://mia-dwh-staging-curated-us-east-1/curated/account/")

job.commit()
