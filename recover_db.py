import sqlite3
import json
import sys

db_path = r"C:\Users\mycom\Documents\AOJ-Server-main\backend\backups\aoj_command_os_backup_20260502_110318.db"

conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row
cursor = conn.cursor()

cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
tables = [row[0] for row in cursor.fetchall()]
print("Tables found:", tables)
print()

for t in tables:
    cursor.execute(f'SELECT COUNT(*) FROM "{t}"')
    count = cursor.fetchone()[0]
    print(f"  {t}: {count} rows")

print()

# Show sample of key tables
for t in tables:
    cursor.execute(f'SELECT * FROM "{t}" LIMIT 2')
    rows = cursor.fetchall()
    if rows:
        print(f"\n=== {t} (first 2 rows) ===")
        for row in rows:
            print(dict(row))

conn.close()
