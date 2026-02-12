

INSERT INTO analytics.dim_customer_segment
SELECT
    row_number() OVER (ORDER BY segment_code)    AS segment_sk,
    segment_code,
    segment_desc,
    min_avg_balance,
    max_avg_balance,
    risk_level,
    marketing_flag,
    DATE '2020-01-01'                             AS effective_start_date,
    DATE '9999-12-31'                             AS effective_end_date,
    'Y'                                          AS is_active
FROM (
    SELECT 'GOLD'   AS segment_code,
           'High value customers' AS segment_desc,
           100000   AS min_avg_balance,
           99999999 AS max_avg_balance,
           'LOW'    AS risk_level,
           'Y'      AS marketing_flag
    UNION ALL
    SELECT 'SILVER','Mid value customers',25000,99999,'MEDIUM','Y'
    UNION ALL
    SELECT 'BRONZE','Low value customers',0,24999,'HIGH','N'
);
