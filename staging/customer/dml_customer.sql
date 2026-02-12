INSERT INTO oltp.customer (first_name, last_name, email, phone, city, country)
SELECT
    'First_' || g,
    'Last_' || g,
    CASE WHEN g % 7 = 0 THEN NULL ELSE 'user' || g || '@mail.com' END,
    CASE WHEN g % 5 = 0 THEN NULL ELSE '99999' || g END,
    CASE WHEN g % 6 = 0 THEN NULL ELSE 'City_' || (g % 10) END,
    CASE WHEN g % 8 = 0 THEN NULL ELSE 'Country_' || (g % 5) END
FROM generate_series(1, 50) g;
