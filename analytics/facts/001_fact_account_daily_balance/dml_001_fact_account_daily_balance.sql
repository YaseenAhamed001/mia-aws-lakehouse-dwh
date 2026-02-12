

--Step 1
-----------------------------------------------
CREATE TABLE analytics.fact_account_daily_balance_tmp
WITH (
    format = 'PARQUET',
    parquet_compression = 'SNAPPY',
    external_location = 's3://mia-dwh-analytics-us-east-1/analytics/facts/fact_account_daily_balance/',
    partitioned_by = ARRAY['year','month']
) AS
SELECT
    a.account_sk,
    c.customer_sk,
    s.segment_sk,
    d.date_sk,

    CAST(opening_balance AS DECIMAL(18,2))              AS opening_balance,
    CAST(closing_balance AS DECIMAL(18,2))              AS closing_balance,

    CAST(
        ROUND((opening_balance + closing_balance) / 2, 2)
        AS DECIMAL(18,2)
    )                                                    AS avg_daily_balance,

    CAST(LEAST(opening_balance, closing_balance)
        AS DECIMAL(18,2)
    )                                                    AS min_balance,

    CAST(GREATEST(opening_balance, closing_balance)
        AS DECIMAL(18,2)
    )                                                    AS max_balance,

    CAST(
        CASE
            WHEN closing_balance < 0 THEN ABS(closing_balance)
            ELSE 0
        END
        AS DECIMAL(18,2)
    )                                                    AS overdraft_amount,

    CASE
        WHEN closing_balance < 0 THEN 'Y'
        ELSE 'N'
    END                                                  AS is_overdrawn,

    CAST(
        ROUND(
            (closing_balance - opening_balance)
            / NULLIF(opening_balance, 0) * 100, 2
        )
        AS DECIMAL(9,2)
    )                                                    AS balance_change_pct,

    current_date                                         AS load_date,

    CAST(year(d.full_date) AS VARCHAR)                   AS year,
    lpad(CAST(month(d.full_date) AS VARCHAR), 2, '0')   AS month

FROM analytics.dim_account a
JOIN analytics.dim_customer c
    ON a.customer_id = c.customer_id

CROSS JOIN analytics.dim_date d

CROSS JOIN (
    SELECT
        CAST(ROUND(random() * 50000 + 5000, 2) AS DECIMAL(18,2)) AS opening_balance,
        CAST(ROUND(random() * 50000 - 20000, 2) AS DECIMAL(18,2)) AS closing_balance
) r

JOIN analytics.dim_customer_segment s
    ON CAST(
        ROUND((opening_balance + closing_balance) / 2, 2)
        AS DECIMAL(18,2)
    )
    BETWEEN s.min_avg_balance AND s.max_avg_balance
   AND s.is_active = 'Y'

WHERE d.full_date BETWEEN DATE '2024-01-01' AND DATE '2024-01-31';


-----------------------------------------------

--Step 2: Drop temp metadata
DROP TABLE analytics.fact_account_daily_balance_tmp;

--------------------------------------------
--Step 3: Repair partitions
MSCK REPAIR TABLE analytics.fact_account_daily_balance;

-------------------------------------------

--Final Validation (this WILL work)
SELECT *
FROM analytics.fact_account_daily_balance
WHERE year = '2024'
  AND month = '01'
LIMIT 10;

-------------------------------------------