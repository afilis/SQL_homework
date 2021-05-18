select table_name,
	   constraint_name
from table_constraints
where table_schema = 'public'
	and constraint_type = 'PRIMARY KEY';