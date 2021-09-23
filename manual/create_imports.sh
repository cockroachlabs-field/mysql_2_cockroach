cockroach sql --certs-dir=/Users/chriscasano/local/1/certs/ -e \
"select 'import into ' || \
 table_name || \
 ' ( ' || \
 array_to_string(array_agg(column_name),',') || \
 ' ) '  || \
 'delimited data (' || \
 '''' || \
 'nodelocal://1/' || \
 table_name || \
 '.txt' || \
 '''' || \
 ' ) WITH fields_escaped_by=' || '''\''' || \
 ', fields_enclosed_by=' || '''' || chr(34) || '''' || \
 ', nullif = ' || '''\N''' || ';' \
from information_schema.columns \
where table_catalog = 'defaultdb' \
  and table_schema = 'public' \
group by table_name \
;" | sed -e '/?column?/d' | sed -e 's/""/"/g' > run_imports.sql
