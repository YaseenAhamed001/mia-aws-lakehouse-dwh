CREATE EXTERNAL TABLE IF NOT EXISTS analytics.dim_account (
    account_sk           BIGINT,
    account_id           STRING,
    customer_id          STRING,
    account_type         STRING,
    account_status       STRING,
    open_date            DATE,
    close_date           DATE,
    currency_code        STRING,
    created_date         DATE,
    updated_date         DATE
)
STORED AS PARQUET
LOCATION 's3://mia-dwh-analytics-us-east-1/analytics/dimensions/dim_account/'
TBLPROPERTIES (
    'parquet.compress'='SNAPPY'
);
