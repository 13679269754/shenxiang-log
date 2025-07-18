"""
csv_test.py

author: shen
date : 2023/8/15
comment :
"""

import csv
import re

data1 = [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9']]
data2 = [['10', '11', '12'], ['13', '14', '15'], ['16', '17', '18']]

select_regex = r"^select"
select_columns = r"(?<=^select) .* (?=from)"
insert_regex = r"^insert"


with open('output.csv', 'a', newline='') as outfile:
    writer = csv.writer(outfile)
    for i, data in enumerate([data1, data2]):
        sheet_name = f'sheet{i+1}'
        writer.writerow([])
        writer.writerow([sheet_name])
        writer.writerow([])
        for row in data:
            writer.writerow(row)

print(re.match(select_regex, f'select 123123,1234123 from new_db.dept_emp'))

#print(itm=[i for i in re.match(select_columns, f'select 123123,1234123 from new_db.dept_emp')])

# 定义一个字符串
string = f'select 123123,1234123 from new_db.dept_emp where 1231412'




# 使用正则表达式匹配select和from
pattern = r"select\s+(.+?)\s+from\s+(.+?)\s"
match = re.search(pattern, string)
if match:
    select_part = match.group(1)
    from_part = match.group(2)
    print("select部分：", select_part)
    print("from部分：", from_part)
else:
    print("没有匹配的结果")