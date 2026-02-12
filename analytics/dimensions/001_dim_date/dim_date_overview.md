# Dimension Table: dim_date

## 1. Overview

The `dim_date` table is a **date dimension** used for analytics.  
It provides a calendar reference for all fact tables, enabling time-based analysis such as daily, weekly, monthly, quarterly, or yearly aggregation.

**Purpose:**  
- Simplify joins with fact tables using a **surrogate key (`date_sk`)**  
- Support reporting and analysis by day, week, month, quarter, and year  
- Identify weekends for business metrics  

---

## 2. Table Structure

| Column        | Type    | Description |
|---------------|---------|-------------|
| date_sk       | INT     | Surrogate key in `YYYYMMDD` format (e.g., 20260212) |
| full_date     | DATE    | Actual date (e.g., 2026-02-12) |
| day           | INT     | Day of the month (1–31) |
| month         | INT     | Month number (1–12) |
| month_name    | STRING  | Month name (e.g., February) |
| quarter       | INT     | Quarter of the year (1–4) |
| year          | INT     | Year (e.g., 2026) |
| week_of_year  | INT     | Week number of the year (1–52/53) |
| is_weekend    | STRING  | `'Y'` if Saturday/Sunday, `'N'` otherwise |

---

## 3. Data Generation Query

```sql
INSERT INTO analytics.dim_date
SELECT
    CAST(date_format(d, '%Y%m%d') AS INT) AS date_sk,
    d AS full_date,
    day(d) AS day,
    month(d) AS month,
    date_format(d, '%M') AS month_name,
    quarter(d) AS quarter,
    year(d) AS year,
    week_of_year(d) AS week_of_year,
    CASE 
        WHEN day_of_week(d) IN (1,7) THEN 'Y' 
        ELSE 'N' 
    END AS is_weekend
FROM (
    SELECT date_add('day', seq, DATE '2015-01-01') AS d
    FROM (
        SELECT sequence(0, date_diff('day', DATE '2015-01-01', DATE '2035-12-31')) AS seq_array
    )
    CROSS JOIN UNNEST(seq_array) AS t(seq)
);
```

## Explanation:
Generate date sequence
```sql
sequence(0, date_diff('day', DATE '2015-01-01', DATE '2035-12-31')) generates numbers for each day between 2015 and 2035.

date_add('day', seq, DATE '2015-01-01') converts these numbers into actual dates.
```

Enrich date with attributes

day(d), month(d), year(d), quarter(d) extract numeric components

date_format(d, '%M') gives the month name

week_of_year(d) provides week number


CASE WHEN day_of_week(d) IN (1,7) flags weekends as 'Y' and weekdays as 'N'.

Surrogate key (date_sk)

Format: YYYYMMDD (e.g., 20260212)

Used for joining fact tables instead of raw dates.

### 4. Example Rows
| date_sk  | full_date   | day | month | month_name | quarter | year | week_of_year | is_weekend |
|----------|------------|-----|-------|------------|---------|------|--------------|------------|
| 20260212 | 2026-02-12 | 12  | 2     | February   | 1       | 2026 | 7            | N          |
| 20260214 | 2026-02-14 | 14  | 2     | February   | 1       | 2026 | 7            | Y          |

### 5. Best Practices
Always join fact tables on dim_date.date_sk for consistency

Regenerate the table yearly or extend the date range as needed

Avoid storing multiple date formats in facts; rely on this standardized dimension

---