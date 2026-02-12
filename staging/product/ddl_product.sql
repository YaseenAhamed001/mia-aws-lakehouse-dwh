CREATE TABLE IF NOT EXISTS oltp.product (
    product_id   SERIAL PRIMARY KEY,
    product_name VARCHAR(100),
    category     VARCHAR(50),
    price        NUMERIC(10,2),
    active_flag  BOOLEAN,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
