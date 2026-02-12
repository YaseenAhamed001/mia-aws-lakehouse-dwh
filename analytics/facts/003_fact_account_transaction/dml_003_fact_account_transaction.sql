CREATE TABLE analytics.fact_account_transaction_tmp
WITH (
    format = 'PARQUET',
    parquet_compression = 'SNAPPY',
    external_location = 's3://mia-dwh-analytics-us-east-1/analytics/facts/fact_account_transaction/'
)
AS
SELECT
    row_number() OVER (ORDER BY t.transaction_id)              AS transaction_sk,

    a.account_sk,
    c.customer_sk,
    p.product_sk,
    d.date_sk,

    CAST(t.transaction_id AS VARCHAR)                          AS transaction_id,

    UPPER(t.transaction_type)                                  AS transaction_type,

    /* Simulated channel */
    CASE (t.transaction_id % 3)
        WHEN 0 THEN 'ONLINE'
        WHEN 1 THEN 'BRANCH'
        ELSE 'MOBILE'
    END                                                        AS transaction_channel,

    CAST(t.amount AS DECIMAL(18,2))                            AS transaction_amount,

    /* Simulated status */
    CASE
        WHEN t.amount < 0 THEN 'FAILED'
        ELSE 'SUCCESS'
    END                                                        AS transaction_status,

    /* Simulated merchant */
    CONCAT('MERCHANT_', CAST((t.transaction_id % 10) AS VARCHAR))
                                                               AS merchant_name,

    CASE (t.transaction_id % 4)
        WHEN 0 THEN 'RETAIL'
        WHEN 1 THEN 'FOOD'
        WHEN 2 THEN 'TRAVEL'
        ELSE 'UTILITY'
    END                                                        AS merchant_category,

    CAST(current_timestamp AS timestamp)                       AS load_timestamp

FROM curated.account_transaction t

JOIN analytics.dim_account a
    ON CAST(t.account_id AS VARCHAR) = a.account_id

JOIN analytics.dim_customer c
    ON a.customer_id = c.customer_id

JOIN analytics.dim_product p
    ON CAST(t.product_id AS VARCHAR) = p.product_id

JOIN analytics.dim_date d
    ON CAST(date(CAST(t.transaction_ts AS timestamp)) AS DATE) = d.full_date;

-----------------------------
-- Step 02:
drop table if exists analytics.fact_account_transaction_tmp;
