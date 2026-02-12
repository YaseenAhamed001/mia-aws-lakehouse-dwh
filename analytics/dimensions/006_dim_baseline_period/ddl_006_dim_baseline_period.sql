CREATE EXTERNAL TABLE IF NOT EXISTS analytics.dim_baseline_period (
    baseline_sk             BIGINT,
    baseline_name           STRING,
    start_offset_days       INT,
    end_offset_days         INT,
    comparison_type         STRING,
    alert_threshold_pct     DECIMAL(5,2),
    is_default              STRING
)
STORED AS PARQUET
LOCATION 's3://mia-dwh-analytics-us-east-1/analytics/dimensions/dim_baseline_period/'
TBLPROPERTIES ('parquet.compress'='SNAPPY');

