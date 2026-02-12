

CREATE EXTERNAL TABLE IF NOT EXISTS analytics.fact_customer_baseline (
    customer_sk             BIGINT,
    baseline_sk             BIGINT,

    baseline_start_date     DATE,
    baseline_end_date       DATE,

    txn_count               INT,
    total_txn_amount        DECIMAL(18,2),
    avg_txn_amount          DECIMAL(18,2),
    max_txn_amount          DECIMAL(18,2),

    prev_baseline_amount    DECIMAL(18,2),
    deviation_pct           DECIMAL(9,2),

    behavior_flag           STRING,
    alert_generated_flag    STRING,

    load_timestamp          TIMESTAMP
)
STORED AS PARQUET
LOCATION 's3://mia-dwh-analytics-us-east-1/analytics/facts/fact_customer_baseline/'
TBLPROPERTIES ('parquet.compress'='SNAPPY');
