CREATE TABLE IF NOT EXISTS oltp.account_transaction (
    transaction_id   SERIAL PRIMARY KEY,
    account_id       INT REFERENCES oltp.account(account_id),
    product_id       INT REFERENCES oltp.product(product_id),
    amount           NUMERIC(15,2),
    transaction_ts   TIMESTAMP,
    transaction_type VARCHAR(20)
);
