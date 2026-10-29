"""
Run the SQL queries in attrition_queries.sql against the project's CSV files.

It builds a temporary SQLite database in memory (nothing is installed or saved),
runs every query and prints the results as tables.

Usage (from the project folder):
    python sql/run_sql.py            # run all queries
    python sql/run_sql.py 5          # run only Q5
    python sql/run_sql.py --save     # also save sql/attrition.db (open it in DB Browser for SQLite)

Needs: pandas  (pip install pandas)
"""

import re
import sqlite3
import sys
from pathlib import Path

import pandas  as pd

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent

# ---------- 1. Load the CSVs into SQL tables ----------
employees = pd.read_csv(ROOT / "Attrition_cleaned.csv")
# LEFT is a SQL keyword, so the "left" column gets a safer name
employees = employees.rename(columns={"left": "has_left"})
raw_records = pd.read_csv(ROOT / "Attrition_dataset.csv")

save = "--save" in sys.argv
con = sqlite3.connect(HERE / "attrition.db" if save else ":memory:")
employees.to_sql("employees", con, index=False, if_exists="replace")
raw_records.to_sql("raw_records", con, index=False, if_exists="replace")

print(f"employees:   {len(employees):,} rows")
print(f"raw_records: {len(raw_records):,} rows")

# ---------- 2. Split the .sql file into questions ----------
text = (HERE / "attrition_queries.sql").read_text(encoding="utf-8")
blocks = re.split(r"(?m)^-- (?=Q\d+\.)", text)[1:]  # one block per question

wanted = {a for a in sys.argv[1:] if a.isdigit()}

# ---------- 3. Run each question ----------
for block in blocks:
    number = re.match(r"Q(\d+)\.", block).group(1)
    if wanted and number not in wanted:
        continue
    title = block.splitlines()[0]
    sql = "\n".join(line for line in block.splitlines()[1:])
    result = pd.read_sql_query(sql, con)
    print("\n" + "=" * 78)
    print("Q" + title[len("Q" + number):])
    print("=" * 78)
    print(result.to_string(index=False))

con.close()
