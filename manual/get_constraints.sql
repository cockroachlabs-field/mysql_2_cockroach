select
  concat(
  'ALTER TABLE IF EXISTS ', fks.table_name ,
  ' ADD CONSTRAINT ' , fks.constraint_name ,
  ' FOREIGN KEY ' ,
  '(',
  group_concat( kcu.column_name order by position_in_unique_constraint separator ', ') ,
  ')',
  ' REFERENCES ' , kcu.REFERENCED_TABLE_NAME ,
  ' (' ,
  group_concat( kcu.REFERENCED_COLUMN_NAME order by position_in_unique_constraint separator ', ') ,
  ');'
  )
from information_schema.referential_constraints fks
join information_schema.key_column_usage kcu
  on fks.constraint_schema = kcu.table_schema
  and fks.table_name = kcu.table_name
  and fks.constraint_name = kcu.constraint_name
where fks.constraint_schema = '[database name]'
group by fks.constraint_schema,
  fks.table_name,
  fks.unique_constraint_schema,
  kcu.referenced_table_name,
  fks.constraint_name
order by fks.constraint_schema,
  fks.table_name
