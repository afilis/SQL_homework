select kcu.table_name,
	tco.constraint_name,
    kcu.column_name,
    cols.data_type
from information_schema.table_constraints tco
join information_schema.key_column_usage kcu 
    on kcu.constraint_name = tco.constraint_name
    and kcu.table_name = tco.table_name 
join information_schema.columns cols
    on cols.column_name = kcu.column_name
    and cols.table_name = kcu.table_name 
where tco.table_schema = 'public'
	and tco.constraint_type = 'PRIMARY KEY'
order by table_name, constraint_name, column_name;
