

INSERT INTO analytics.dim_account
SELECT
    row_number() OVER (ORDER BY a.account_id)              AS account_sk,

    CAST(a.account_id AS VARCHAR)                          AS account_id,
    CAST(a.customer_id AS VARCHAR)                         AS customer_id,

    UPPER(a.account_type)                                  AS account_type,
    UPPER(a.status)                                        AS account_status,

    a.opened_date                                          AS open_date,

    CASE
        WHEN UPPER(a.status) = 'ACTIVE' THEN NULL
        ELSE date_add(
            'month',
            6 + (a.account_id % 24),
            a.opened_date
        )
    END                                                    AS close_date,

    CASE (a.account_id % 4)
        WHEN 0 THEN 'USD'
        WHEN 1 THEN 'EUR'
        WHEN 2 THEN 'GBP'
        ELSE 'INR'
    END                                                    AS currency_code,

    a.opened_date                                          AS created_date,
    current_date                                           AS updated_date
FROM curated.account a;

