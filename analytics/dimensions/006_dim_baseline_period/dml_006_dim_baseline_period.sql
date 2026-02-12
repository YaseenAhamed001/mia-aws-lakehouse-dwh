
INSERT INTO analytics.dim_baseline_period
SELECT
    row_number() OVER (ORDER BY baseline_name) AS baseline_sk,
    baseline_name,
    start_offset_days,
    end_offset_days,
    comparison_type,
    alert_threshold_pct,
    is_default
FROM (
    SELECT 'LAST_30_DAYS' AS baseline_name,
           -30 AS start_offset_days,
           -1  AS end_offset_days,
           'MoM' AS comparison_type,
           20  AS alert_threshold_pct,
           'Y' AS is_default
    UNION ALL
    SELECT 'LAST_90_DAYS', -90, -1, 'QoQ', 30, 'N'
);

