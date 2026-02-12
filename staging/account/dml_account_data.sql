INSERT INTO oltp.account (customer_id, account_type, balance, opened_date, status)
SELECT
    c.customer_id,
    CASE WHEN c.customer_id % 2 = 0 THEN 'SAVINGS' ELSE 'CHECKING' END,
    (random() * 10000)::NUMERIC(15,2),
    CURRENT_DATE - (c.customer_id * 10),
    CASE WHEN c.customer_id % 10 = 0 THEN 'INACTIVE' ELSE 'ACTIVE' END
FROM oltp.customer c;
