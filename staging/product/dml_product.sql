INSERT INTO oltp.product (product_name, category, price, active_flag)
SELECT
    'Product_' || g,
    CASE WHEN g % 3 = 0 THEN 'LOAN'
         WHEN g % 3 = 1 THEN 'BANKING'
         ELSE 'CARD' END,
    (random() * 500)::NUMERIC(10,2),
    CASE WHEN g % 9 = 0 THEN false ELSE true END
FROM generate_series(1, 50) g;
