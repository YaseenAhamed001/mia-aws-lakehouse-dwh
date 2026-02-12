CREATE TABLE analytics.fact_customer_baseline_tmp
WITH (
    format = 'PARQUET',
    parquet_compression = 'SNAPPY',
    external_location = 's3://mia-dwh-analytics-us-east-1/analytics/facts/fact_customer_baseline/',
    partitioned_by = ARRAY['baseline_month']
) AS
SELECT
    f.customer_sk,

    row_number() OVER (
        PARTITION BY f.customer_sk
        ORDER BY MIN(d.full_date)
    )                                                     AS baseline_sk,

    MIN(d.full_date)                                     AS baseline_start_date,
    MAX(d.full_date)                                     AS baseline_end_date,

    COUNT(*)                                             AS txn_count,

    CAST(SUM(f.closing_balance) AS DECIMAL(18,2))        AS total_txn_amount,
    CAST(AVG(f.closing_balance) AS DECIMAL(18,2))        AS avg_txn_amount,
    CAST(MAX(f.closing_balance) AS DECIMAL(18,2))        AS max_txn_amount,

    CAST(
        LAG(AVG(f.closing_balance)) OVER (
            PARTITION BY f.customer_sk
            ORDER BY MIN(d.full_date)
        )
        AS DECIMAL(18,2)
    )                                                     AS prev_baseline_amount,

    CAST(
        (
            AVG(f.closing_balance)
            - LAG(AVG(f.closing_balance)) OVER (
                PARTITION BY f.customer_sk
                ORDER BY MIN(d.full_date)
            )
        )
        / NULLIF(
            LAG(AVG(f.closing_balance)) OVER (
                PARTITION BY f.customer_sk
                ORDER BY MIN(d.full_date)
            ),
            0
        ) * 100
        AS DECIMAL(9,2)
    )                                                     AS deviation_pct,

    CASE
        WHEN ABS(
            AVG(f.closing_balance)
            - LAG(AVG(f.closing_balance)) OVER (
                PARTITION BY f.customer_sk
                ORDER BY MIN(d.full_date)
            )
        ) > 0.25 * LAG(AVG(f.closing_balance)) OVER (
                PARTITION BY f.customer_sk
                ORDER BY MIN(d.full_date)
            )
        THEN 'DEVIATION'
        ELSE 'NORMAL'
    END                                                   AS behavior_flag,

    CASE
        WHEN ABS(
            AVG(f.closing_balance)
            - LAG(AVG(f.closing_balance)) OVER (
                PARTITION BY f.customer_sk
                ORDER BY MIN(d.full_date)
            )
        ) > 0.25 * LAG(AVG(f.closing_balance)) OVER (
                PARTITION BY f.customer_sk
                ORDER BY MIN(d.full_date)
            )
        THEN 'Y'
        ELSE 'N'
    END                                                   AS alert_generated_flag,

    CAST(current_timestamp AS TIMESTAMP)                  AS load_timestamp,

    date_format(MIN(d.full_date), '%Y-%m')                AS baseline_month

FROM analytics.fact_account_daily_balance f
JOIN analytics.dim_date d
    ON f.date_sk = d.date_sk

WHERE d.full_date BETWEEN DATE '2024-01-01' AND DATE '2024-03-31'

GROUP BY f.customer_sk;


---------------------------------------------
--Step 2:
CREATE TABLE analytics.fact_customer_baseline
WITH (
    format = 'PARQUET',
    parquet_compression = 'SNAPPY',
    external_location = 's3://mia-dwh-analytics-us-east-1/analytics/facts/fact_customer_baseline/',
    partitioned_by = ARRAY['baseline_month']
)
AS
SELECT *
FROM analytics.fact_customer_baseline_tmp;

