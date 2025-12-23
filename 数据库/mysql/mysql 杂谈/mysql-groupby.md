# group by 优化

status：
show global status like '%tmp%'
create_tmp_disk_tables 
create_tmp_files
create_tmp_tables


参数：
sort_buffer_size = 32m
tmp_table_size = 32m

group_concat([column] order by name desc  separator ':' ) -- 可以使用substring_index()  来切分
