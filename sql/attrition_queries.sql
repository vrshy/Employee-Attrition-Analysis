-- ============================================================================
-- Employee Attrition Analysis (2006-2015): SQL queries
--
-- Two tables are used (loaded from the CSV files by run_sql.py):
--   employees   = Attrition_cleaned.csv  (one row per employee, 6,284 rows)
--   raw_records = Attrition_dataset.csv  (one row per employee per year, 49,653 rows)
--
-- Note: the column "left" is called has_left here, because LEFT is a SQL keyword.
-- Each query answers one business question. The numbers in the comments match
-- the findings in the README and the Python notebook.
-- Written for SQLite; it also works in PostgreSQL with small changes
-- (for example, EXTRACT(YEAR FROM term_date) instead of strftime).
-- ============================================================================


-- Q1. How many employees left, and what share is that?
-- Concepts: COUNT, SUM, ROUND, calculating a percentage
-- Expected: 6,284 employees, 1,485 left, 23.6% (cumulative over ten years,
--           not an annual rate)
SELECT
    COUNT(*)                                      AS employees,
    SUM(has_left)                                 AS employees_left,
    ROUND(100.0 * SUM(has_left) / COUNT(*), 1)    AS attrition_pct
FROM employees;


-- Q2. Why do people leave?
-- Concepts: GROUP BY, window function SUM() OVER () to get each row's share of the total
-- Expected: Retirement 59.6%, Resignation 25.9%, Layoff 14.5%
--           (Retirement + Resignation = 85.5% of exits are voluntary)
SELECT
    term_reason,
    term_type,
    COUNT(*)                                                AS exits,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)      AS pct_of_exits
FROM employees
WHERE has_left = 1
GROUP BY term_reason, term_type
ORDER BY exits DESC;


-- Q3. How many people left each year, and how does that compare with the year before?
-- Concepts: CTE (WITH), strftime to get the year from a date, LAG() window function
-- Expected: 2014 is the outlier with 253 exits (+148 vs 2013)
WITH exits_by_year AS (
    SELECT
        CAST(strftime('%Y', term_date) AS INTEGER) AS exit_year,
        COUNT(*)                                   AS exits
    FROM employees
    WHERE has_left = 1
    GROUP BY exit_year
)
SELECT
    exit_year,
    exits,
    exits - LAG(exits) OVER (ORDER BY exit_year)   AS change_vs_previous_year
FROM exits_by_year
ORDER BY exit_year;


-- Q4. What is the yearly turnover rate?
-- Concepts: two CTEs joined together, using both tables
-- Turnover rate = exits in the year / employees on the payroll that year
-- Expected: between 2.0% (2013) and 4.9% (2014)
WITH payroll AS (
    SELECT STATUS_YEAR AS year, COUNT(*) AS on_payroll
    FROM raw_records
    GROUP BY STATUS_YEAR
),
exits AS (
    SELECT CAST(strftime('%Y', term_date) AS INTEGER) AS year, COUNT(*) AS exits
    FROM employees
    WHERE has_left = 1
    GROUP BY year
)
SELECT
    p.year,
    p.on_payroll,
    e.exits,
    ROUND(100.0 * e.exits / p.on_payroll, 1) AS turnover_pct
FROM payroll AS p
JOIN exits   AS e ON e.year = p.year
ORDER BY p.year;


-- Q5. Which departments have the highest attrition?
-- Concepts: HAVING (ignore tiny departments), RANK() window function
-- Expected: Produce 33.3% and Meats 30.1% are highest, but mostly retirements
SELECT
    department,
    COUNT(*)                                       AS employees,
    SUM(has_left)                                  AS exits,
    ROUND(100.0 * SUM(has_left) / COUNT(*), 1)     AS attrition_pct,
    RANK() OVER (ORDER BY 1.0 * SUM(has_left) / COUNT(*) DESC) AS rank_by_rate
FROM employees
GROUP BY department
HAVING COUNT(*) >= 50
ORDER BY rank_by_rate;


-- Q6. Where do the resignations come from? (a Pareto view)
-- Concepts: CTE, running total with SUM() OVER (ORDER BY ...)
-- Expected: Customer Service has 179 of the 385 resignations (46.5%)
WITH resignations_by_dept AS (
    SELECT department, COUNT(*) AS resignations
    FROM employees
    WHERE term_reason = 'Resignation'
    GROUP BY department
)
SELECT
    department,
    resignations,
    ROUND(100.0 * resignations / SUM(resignations) OVER (), 1)  AS pct_of_resignations,
    ROUND(100.0 * SUM(resignations) OVER (ORDER BY resignations DESC, department
                                          ROWS UNBOUNDED PRECEDING)
          / SUM(resignations) OVER (), 1)                       AS cumulative_pct
FROM resignations_by_dept
ORDER BY resignations DESC, department;


-- Q7. Which cities account for the layoffs?
-- Concepts: ROW_NUMBER() to pick the top N, running total
-- Expected: three cities (Fort Nelson, New Westminster, Grand Forks) account for
--           100 of the 215 layoffs, which looks like store closures
WITH layoffs_by_city AS (
    SELECT city, COUNT(*) AS layoffs
    FROM employees
    WHERE term_reason = 'Layoff'
    GROUP BY city
),
ranked AS (
    SELECT
        city,
        layoffs,
        ROW_NUMBER() OVER (ORDER BY layoffs DESC, city)         AS rn,
        SUM(layoffs) OVER (ORDER BY layoffs DESC, city
                           ROWS UNBOUNDED PRECEDING)            AS running_total
    FROM layoffs_by_city
)
SELECT
    city,
    layoffs,
    running_total,
    ROUND(100.0 * running_total / (SELECT SUM(layoffs) FROM layoffs_by_city), 1) AS cumulative_pct
FROM ranked
WHERE rn <= 5
ORDER BY rn;


-- Q8. Do early-career employees leave more than everyone else?
-- Concepts: CASE WHEN to create groups, conditional counting
-- Expected: ages 19-25 leave at 27.0% (199 of 736) vs 9.0% (371 of 4,119) for 26-59,
--           and the gap is mostly resignations (22.3% vs 5.3%)
-- (Age is the employee's age at their last record. Ages 60+ are left out because
--  every retirement happens at 60 or 65.)
SELECT
    CASE WHEN age BETWEEN 19 AND 25 THEN '19-25' ELSE '26-59' END      AS age_band,
    COUNT(*)                                                           AS employees,
    SUM(has_left)                                                      AS exits,
    ROUND(100.0 * SUM(has_left) / COUNT(*), 1)                         AS attrition_pct,
    ROUND(100.0 * SUM(CASE WHEN term_reason = 'Resignation' THEN 1 ELSE 0 END)
          / COUNT(*), 1)                                               AS resignation_pct
FROM employees
WHERE age BETWEEN 19 AND 59
GROUP BY age_band
ORDER BY age_band;


-- Q9. Do women leave more often than men, and is retirement the reason?
-- Concepts: GROUP BY with several conditional columns
-- Expected: women 27.9% vs men 19.0%, but retirement alone is 18.0% vs 9.8%,
--           so the gap needs an age-adjusted look before drawing any conclusion
SELECT
    gender,
    COUNT(*)                                                           AS employees,
    ROUND(100.0 * SUM(has_left) / COUNT(*), 1)                         AS attrition_pct,
    ROUND(100.0 * SUM(CASE WHEN term_reason = 'Retirement'  THEN 1 ELSE 0 END)
          / COUNT(*), 1)                                               AS retirement_pct,
    ROUND(100.0 * SUM(CASE WHEN term_reason = 'Resignation' THEN 1 ELSE 0 END)
          / COUNT(*), 1)                                               AS resignation_pct,
    ROUND(100.0 * SUM(CASE WHEN term_reason = 'Layoff'      THEN 1 ELSE 0 END)
          / COUNT(*), 1)                                               AS layoff_pct
FROM employees
GROUP BY gender
ORDER BY attrition_pct DESC;


-- Q10. What does a typical resigner look like?
-- Concepts: AVG, HAVING, filtering before grouping
-- Expected: the average resigner is 30.1 years old with 4.6 years of service
--           (the README's "29 years, 4 years" are medians, see Q11).
--           Customer Service resigners are much younger (24.3) and newer (2.0 years).
SELECT
    department,
    COUNT(*)                          AS resignations,
    ROUND(AVG(age), 1)                AS avg_age,
    ROUND(AVG(tenure), 1)             AS avg_tenure_years
FROM employees
WHERE term_reason = 'Resignation'
GROUP BY department
HAVING COUNT(*) >= 10
UNION ALL
SELECT
    'ALL DEPARTMENTS',
    COUNT(*),
    ROUND(AVG(age), 1),
    ROUND(AVG(tenure), 1)
FROM employees
WHERE term_reason = 'Resignation'
ORDER BY resignations DESC;


-- Q11. What is the median age and tenure of a resigner?
-- Concepts: ROW_NUMBER() and COUNT() OVER () to find the middle row
--           (SQLite has no MEDIAN function)
-- Expected: median age 29, median tenure 4 years
WITH resigners AS (
    SELECT
        age,
        tenure,
        ROW_NUMBER() OVER (ORDER BY age)    AS age_rank,
        ROW_NUMBER() OVER (ORDER BY tenure) AS tenure_rank,
        COUNT(*)     OVER ()                AS n
    FROM employees
    WHERE term_reason = 'Resignation'
)
SELECT
    (SELECT AVG(age)    FROM resigners WHERE age_rank    IN ((n + 1) / 2, (n + 2) / 2)) AS median_age,
    (SELECT AVG(tenure) FROM resigners WHERE tenure_rank IN ((n + 1) / 2, (n + 2) / 2)) AS median_tenure_years
FROM resigners
LIMIT 1;
