INSERT INTO oltp.account_transaction (
    account_id,
    product_id,
    amount,
    transaction_ts,
    transaction_type
)
SELECT
    a.account_id,
    p.product_id,
    (random() * 2000)::NUMERIC(15,2),
    NOW() - (random() * INTERVAL '90 days'),
    CASE WHEN random() > 0.5 THEN 'DEBIT' ELSE 'CREDIT' END
FROM oltp.account a
LEFT JOIN oltp.product p
    ON p.product_id = (a.account_id % 50) + 1;
