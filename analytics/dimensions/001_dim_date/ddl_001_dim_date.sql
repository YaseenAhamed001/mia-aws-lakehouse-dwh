CREATE EXTERNAL TABLE IF NOT EXISTS analytics.dim_date (
    date_sk              INT,
    full_date            DATE,
    day                  INT,
    month                INT,
    month_name           STRING,
    quarter              INT,
    year                 INT,
    week_of_year         INT,
    is_weekend           STRING
)
STORED AS PARQUET
LOCATION 's3://mia-dwh-analytics-us-east-1/analytics/dimensions/dim_date/'
TBLPROPERTIES (
    'parquet.compress'='SNAPPY'
);


