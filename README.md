# Employee Attrition Analysis (2006–2015)

**Business question:** Who leaves the company, when do they leave, and why?

A Python / Pandas analysis and Power BI dashboard of 10 years of HR data from a retail company (stores with Produce, Meats, Dairy, Customer Service and other departments). The raw file has one row per employee per year (49,653 rows); after cleaning it covers **6,284 employees**, of whom **1,485 left**.

## Key findings

| # | Finding |
|---|---|
| 1 | **1,485 of 6,284 employees (23.6%) left in 2006–2015**, but the yearly turnover rate is only **2.0–4.9%**. The 23.6% is ten years added together. |
| 2 | **Retirement is the biggest reason (59.6%)**, then resignation (25.9%) and layoff (14.5%). 85.5% of exits are voluntary. |
| 3 | **2014 was an outlier year** (4.9% turnover, 253 exits). Layoffs start in 2014 (142, then 73 in 2015) and no hires appear after 2013, so year-end headcount fell 8.0% (5,214 to 4,799). |
| 4 | **100 of the 215 layoffs came from three locations** (Fort Nelson, New Westminister, Grand Forks), where everyone still working in 2014 was let go. This looks like store closures. |
| 5 | **Customer Service has the real retention problem:** 179 resignations (46.5% of all resignations) plus 70 layoffs. |
| 6 | **Produce (33.3%) and Meats (30.1%) have the highest attrition**, but it is mostly retirements (623 of 885). |
| 7 | **Early-career staff leave more:** 27.0% of ages 19–25 vs 9.0% of ages 26–59. The typical resigner is 29 years old with 4 years of service. |
| 8 | Women left more often than men (27.9% vs 19.0%), but the gap is almost entirely retirement (18.0% vs 9.8%), so it needs an age-adjusted look before any conclusion. |

![Turnover and headcount](images/turnover_and_headcount.png)

![Exits by year and reason](images/exits_by_year_and_reason.png)

![Why people leave each department](images/why_people_leave_by_department.png)

## Power BI dashboard

Interactive 3-page dashboard built from `Attrition_cleaned.csv` and `yearly_summary.csv`. Open `powerbi/Attrition_Analysis.pbix` in Power BI Desktop.

| Page | What it shows |
|---|---|
| Overview | KPI cards (employees, left, attrition rate, voluntary %), why employees left, exits by year and reason, yearly turnover rate |
| Departments | Attrition rate by department, mix of exit reasons, full department table, reason cards that respond to clicks |
| People | Attrition by age and tenure group, gender split by reason, layoffs by city, resigner profile cards |

**DAX measures:** Total Employees, Employees Left, Attrition Rate %, Voluntary %, Retirements, Resignations, Layoffs, Avg Age of Resigners, Avg Tenure of Resigners, Layoffs in 2014.

![Overview](powerbi/1_overview.png)

![Departments](powerbi/2_departments.png)

![People](powerbi/3_people.png)

## Recommendations

1. Investigate Customer Service retention (pay, workload, career path in the first 5 years).
2. Plan for retirements in Meats and Produce with succession planning.
3. Review the 2014–15 layoff decisions and why no hiring is recorded after 2013.
4. Look into the 2011–12 jump in resignations.

## What I did

1. **Loaded and inspected** the data (`head`, `info`, missing values, duplicates).
2. **Cleaned it:**
   - kept each employee's latest record with `drop_duplicates(subset='EmployeeID', keep='last')`
   - converted dates with `to_datetime`
   - fixed typos and text casing
   - replaced the `1900-01-01` placeholder date with an empty value
   - simplified job titles with `apply`
   - created age and tenure groups with `cut`
   - created a `left` flag (1 = left)
3. **Analysed attrition** by reason, year, department, age, tenure, gender and city, using attrition *rates* (not just counts).
4. **Checked for outliers** with the IQR rule.
5. Wrote the conclusion, recommendations and limitations.
6. Built a 3-page interactive Power BI dashboard (Overview, Departments, People) with DAX measures.

## Limitations

- Data covers 2006–2015 only; people who left before 2006 are not included and no hires appear after 2013.
- Small groups (head-office teams, small cities) give unreliable rates.
- No salary, performance or satisfaction data, so the analysis shows *who* and *when*, not *why* people resign.
- Correlation is not causation.

## Files

| File | Description |
|---|---|
| `Attrition_Analysis.ipynb` | Full notebook with explanations, code and charts |
| `Attrition_dataset.csv` | Original data (49,653 rows, 18 columns) |
| `Attrition_cleaned.csv` | Cleaned data, one row per employee (6,284 rows) |
| `yearly_summary.csv` | Hires, exits, headcount and turnover rate per year |
| `images/` | Charts used in this README |
| `powerbi/` | Power BI file (`Attrition_Analysis.pbix`) and dashboard screenshots |

## How to run

```
pip install pandas numpy matplotlib seaborn jupyter
jupyter notebook Attrition_Analysis.ipynb
```

Keep `Attrition_dataset.csv` in the same folder as the notebook.

## Tools

Python, Pandas, NumPy, Matplotlib, Seaborn, Jupyter Notebook, Power BI, DAX

## Next steps

- Prediction model for resignation (logistic regression)

## Author

**Varshini Ganesan**: [GitHub](https://github.com/vrshy) | [LinkedIn](https://www.linkedin.com/in/varshiganesan)
