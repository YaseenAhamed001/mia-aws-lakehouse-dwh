INSERT INTO analytics.dim_date
SELECT
    CAST(date_format(d, '%Y%m%d') AS INT)        AS date_sk,
    d                                            AS full_date,
    day(d)                                       AS day,
    month(d)                                     AS month,
    date_format(d, '%M')                         AS month_name,
    quarter(d)                                   AS quarter,
    year(d)                                      AS year,
    week_of_year(d)                              AS week_of_year,
    CASE 
        WHEN day_of_week(d) IN (1,7) THEN 'Y' 
        ELSE 'N' 
    END                                          AS is_weekend
FROM (
    SELECT date_add('day', seq, DATE '2015-01-01') AS d
    FROM (
        SELECT sequence(0, date_diff('day', DATE '2015-01-01', DATE '2035-12-31')) AS seq_array
    )
    CROSS JOIN UNNEST(seq_array) AS t(seq)
);
