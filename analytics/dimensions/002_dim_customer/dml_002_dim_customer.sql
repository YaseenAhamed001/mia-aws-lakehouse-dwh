INSERT INTO analytics.dim_customer
SELECT
    row_number() OVER (ORDER BY customer_id)      AS customer_sk,
    customer_id,
    first_name,
    last_name,
    email,
    phone,
    gender,
    date_of_birth,
    customer_status,
    created_date,
    updated_date
FROM (
    SELECT *,
           row_number() OVER (
               PARTITION BY customer_id
               ORDER BY updated_date DESC
           ) AS rn
    FROM curated.customer
)
WHERE rn = 1;

