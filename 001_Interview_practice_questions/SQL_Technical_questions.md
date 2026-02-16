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
``

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

