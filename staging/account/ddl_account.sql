CREATE TABLE IF NOT EXISTS oltp.account (
    account_id   SERIAL PRIMARY KEY,
    customer_id  INT REFERENCES oltp.customer(customer_id),
    account_type VARCHAR(30),
    balance      NUMERIC(15,2),
    opened_date  DATE,
    status       VARCHAR(20)
);

