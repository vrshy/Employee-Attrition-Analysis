## SQL analysis

I re-answered the key questions with SQL (SQLite) to check the Python results. All 11 queries are in `sql/attrition_queries.sql`, and every number matches the findings above.

| Question | SQL used |
|---|---|
| How many left, and what share? | `COUNT`, `SUM`, percentages |
| Why do people leave? | `GROUP BY`, `SUM() OVER ()` for share of total |
| Exits per year vs the year before | CTE, `LAG()` |
| Yearly turnover rate | two CTEs, `JOIN` across both tables |
| Highest-attrition departments | `HAVING`, `RANK()` |
| Where resignations come from | running total with `SUM() OVER (ORDER BY ...)` |
| Cities behind the layoffs | `ROW_NUMBER()`, cumulative % |
| Early-career vs other staff | `CASE WHEN`, conditional counts |
| Gender and exit reason | conditional aggregation |
| Typical resigner (mean and median) | `AVG`, median with window functions |

To run them (needs `pandas`):

```
python sql/run_sql.py        # all queries
python sql/run_sql.py 5      # only Q5
```
