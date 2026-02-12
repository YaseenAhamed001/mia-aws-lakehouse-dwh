CREATE EXTERNAL TABLE IF NOT EXISTS analytics.dim_customer (
    customer_sk          BIGINT,
    customer_id          STRING,
    first_name           STRING,
    last_name            STRING,
    email                STRING,
    phone                STRING,
    gender               STRING,
    date_of_birth        DATE,
    customer_status      STRING,
    created_date         DATE,
    updated_date         DATE
)
STORED AS PARQUET
LOCATION 's3://mia-dwh-analytics-us-east-1/analytics/dimensions/dim_customer/'
TBLPROPERTIES (
    'parquet.compress'='SNAPPY'
);
