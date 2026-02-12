CREATE EXTERNAL TABLE IF NOT EXISTS analytics.dim_customer_segment (
    segment_sk              BIGINT,
    segment_code            STRING,
    segment_desc            STRING,
    min_avg_balance         DECIMAL(15,2),
    max_avg_balance         DECIMAL(15,2),
    risk_level              STRING,
    marketing_flag          STRING,
    effective_start_date    DATE,
    effective_end_date      DATE,
    is_active               STRING
)
STORED AS PARQUET
LOCATION 's3://mia-dwh-analytics-us-east-1/analytics/dimensions/dim_customer_segment/'
TBLPROPERTIES ('parquet.compress'='SNAPPY');

