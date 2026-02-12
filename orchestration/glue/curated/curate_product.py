import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.types import DecimalType, BooleanType
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
    .load("s3://mia-dwh-staging-raw-us-east-1/staging/oltp/mia_db/oltp/product/")

# Cast / enforce types and rename columns
df_curated = df.select(
    col("_c0").cast("bigint").alias("product_id"),
    col("_c1").cast("string").alias("product_name"),
    col("_c2").cast("string").alias("category"),
    col("_c3").cast(DecimalType(10, 2)).alias("price"),   # ✅ DecimalType object, not a string
    col("_c4").cast(BooleanType()).alias("active_flag"),  # ✅ BooleanType object
    col("_c5").cast("timestamp").alias("created_at")      # make sure column index is correct
)

# Write Parquet to curated S3
df_curated.write.mode("overwrite") \
    .parquet("s3://mia-dwh-staging-curated-us-east-1/curated/product/")

job.commit()
