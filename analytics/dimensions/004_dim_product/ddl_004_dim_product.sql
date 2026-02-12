CREATE EXTERNAL TABLE IF NOT EXISTS analytics.dim_product (
    product_sk           BIGINT,
    product_id           STRING,
    product_name         STRING,
    product_category     STRING,
    product_type         STRING,
    product_status       STRING,
    launch_date          DATE,
    retire_date          DATE,
    created_date         DATE,
    updated_date         DATE
)
STORED AS PARQUET
LOCATION 's3://mia-dwh-analytics-us-east-1/analytics/dimensions/dim_product/'
TBLPROPERTIES (
    'parquet.compress'='SNAPPY'
);
