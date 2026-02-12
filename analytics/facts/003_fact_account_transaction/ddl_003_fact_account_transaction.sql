

CREATE EXTERNAL TABLE IF NOT EXISTS analytics.fact_account_transaction (
    transaction_sk          BIGINT,
    account_sk              BIGINT,
    customer_sk             BIGINT,
    product_sk              BIGINT,
    date_sk                 INT,

    transaction_id          STRING,
    transaction_type        STRING,
    transaction_channel     STRING,

    transaction_amount      DECIMAL(18,2),
    transaction_status      STRING,

    merchant_name           STRING,
    merchant_category       STRING,

    load_timestamp          TIMESTAMP
)
STORED AS PARQUET
LOCATION 's3://mia-dwh-analytics-us-east-1/analytics/facts/fact_account_transaction/'
TBLPROPERTIES ('parquet.compress'='SNAPPY');

