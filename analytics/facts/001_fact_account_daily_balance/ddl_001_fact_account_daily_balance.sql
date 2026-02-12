CREATE EXTERNAL TABLE IF NOT EXISTS analytics.fact_account_daily_balance (
    account_sk              BIGINT,
    customer_sk             BIGINT,
    segment_sk              BIGINT,
    date_sk                 INT,

    opening_balance         DECIMAL(18,2),
    closing_balance         DECIMAL(18,2),

    avg_daily_balance       DECIMAL(18,2),
    min_balance             DECIMAL(18,2),
    max_balance             DECIMAL(18,2),

    overdraft_amount        DECIMAL(18,2),
    is_overdrawn            STRING,

    balance_change_pct      DECIMAL(9,2),
    load_date               DATE
)
PARTITIONED BY (
    year STRING,
    month STRING
)
STORED AS PARQUET
LOCATION 's3://mia-dwh-analytics-us-east-1/analytics/facts/fact_account_daily_balance/'
TBLPROPERTIES ('parquet.compress'='SNAPPY');




MSCK REPAIR TABLE analytics.fact_account_daily_balance;
