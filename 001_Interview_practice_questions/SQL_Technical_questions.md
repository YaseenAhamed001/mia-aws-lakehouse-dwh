## BATCH 1 (ETL Validation + Aggregation Logic)

## Question 1 – Data Quality Check (Null Analysis)
✅ Question 1 – Count Missing Values
🟢 Easy Version:

In the staging.customer table:

Some customers may not have email, phone, city, or country.

Write a query to:

Count total customers

Count how many customers have:

email missing

phone missing

city missing

country missing

You should get all counts in one single row output.

✅ Answer:
```sql
SELECT
    COUNT(*) AS total_customers,
    COUNT(CASE WHEN email IS NULL THEN 1 END) AS missing_email,
    COUNT(CASE WHEN phone IS NULL THEN 1 END) AS missing_phone,
    COUNT(CASE WHEN city IS NULL THEN 1 END) AS missing_city,
    COUNT(CASE WHEN country IS NULL THEN 1 END) AS missing_country
FROM staging.customer;
```

🧠 Explanation:

COUNT(*) → total rows

COUNT(expression) counts only non-null values

We use CASE WHEN ... THEN 1 END

If condition fails → NULL → not counted

This is called conditional aggregation.

🎯 Interview Follow-up:

Why not use SUM(CASE WHEN email IS NULL THEN 1 ELSE 0 END)?

👉 You can. Both are valid.
SUM is often clearer in production.

---

***✅ Question 2 – Total Balance per Account Type***
🟢 Easy Version:

In the staging.account table:

We have two account types (SAVINGS, CHECKING).

Write a query to show:

For each account_type:

How many accounts exist

What is the total balance

What is the average balance

Only show account types where total balance is greater than 0.

Sort results by highest total balance first.

✅ Query:
```sql
SELECT
    account_type,
    COUNT(account_id) AS total_accounts,
    SUM(balance) AS total_balance,
    ROUND(AVG(balance), 2) AS avg_balance
FROM staging.account
GROUP BY account_type
HAVING SUM(balance) > 0
ORDER BY total_balance DESC;
```
🧠 Explanation:

GROUP BY groups per account type

HAVING filters after aggregation

ORDER BY applied last

ROUND improves readability

Interview Tip:
Execution order:
FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY
---

***✅ Question 3 – Customers With More Than One Account***

In the staging.account table:

Some customers may have:

1 account

2 accounts

3 accounts

Write a query to show:

customer_id

number of accounts

But only show customers who have more than 1 account.

Sort by highest number of accounts first.

✅ Query:
```sql
SELECT
    customer_id,
    COUNT(account_id) AS account_count
FROM staging.account
GROUP BY customer_id
HAVING COUNT(account_id) > 1
ORDER BY account_count DESC;
```
🧠 Explanation:

We group by customer

HAVING filters aggregated result

Useful for dedup and migration checks

🎯 Follow-up:

How to get customer full name also?

👉 Use JOIN:
```sql
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(a.account_id) AS account_count
FROM staging.customer c
JOIN staging.account a
    ON c.customer_id = a.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(a.account_id) > 1;
```
Notice:
All non-aggregated columns must be in GROUP BY.

---

***✅ Question 4 – Rule Check (Business Logic Validation)***

Business rule says:

👉 If an account is INACTIVE,
👉 Its balance should NOT be greater than 5000.

Write a query to find accounts that break this rule.

Show:

account_id

customer_id

account_type

balance

status

Sort by highest balance first.

✅ Query:
```sql
SELECT
    account_id,
    customer_id,
    account_type,
    balance,
    status
FROM staging.account
WHERE status = 'INACTIVE'
  AND balance > 5000
ORDER BY balance DESC;
```

🧠 Explanation:

Simple filtering but important for ETL validation.

Migration interviews LOVE this type.

---

***✅ Question 5 – Top 3 Expensive Active Products***

In staging.product:

Some products are active (active_flag = true).

Write a query to:

Show only ACTIVE products

Sort them by price (highest first)

Return only the top 3 products

Show:

product_id

product_name

category

price

✅ Query:
```sql
SELECT
    product_id,
    product_name,
    category,
    price
FROM staging.product
WHERE active_flag = true
ORDER BY price DESC
LIMIT 3;
```
🧠 Explanation:

WHERE filters first

ORDER BY sorts

LIMIT restricts output

LIMIT happens after ORDER BY

---


