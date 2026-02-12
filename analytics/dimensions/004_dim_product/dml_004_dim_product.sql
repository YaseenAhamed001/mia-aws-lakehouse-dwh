INSERT INTO analytics.dim_product
SELECT
    row_number() OVER (ORDER BY p.product_id)              AS product_sk,

    CAST(p.product_id AS VARCHAR)                          AS product_id,
    p.product_name                                         AS product_name,
    UPPER(p.category)                                      AS product_category,

    /* Product Type */
    CASE
        WHEN lower(p.category) LIKE '%loan%'
          OR lower(p.category) LIKE '%credit%' THEN 'FINANCIAL'
        WHEN lower(p.category) LIKE '%insurance%'          THEN 'PROTECTION'
        WHEN lower(p.category) LIKE '%invest%'             THEN 'INVESTMENT'
        ELSE 'SERVICE'
    END                                                    AS product_type,

    /* Product Status */
    CASE
        WHEN p.active_flag = true THEN 'ACTIVE'
        ELSE 'RETIRED'
    END                                                    AS product_status,

    CAST(p.created_at AS DATE)                             AS launch_date,

    CASE
        WHEN p.active_flag = true THEN NULL
        ELSE date_add(
            'month',
            12 + (p.product_id % 36),
            CAST(p.created_at AS DATE)
        )
    END                                                    AS retire_date,

    CAST(p.created_at AS DATE)                             AS created_date,
    current_date                                           AS updated_date
FROM curated.product p;

