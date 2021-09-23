# Import into Postgres using pgloader, Then Migrate to CockroachDB with Import PGDUMP

[MySQL -> Postgres -> Cockroach]

An interesting but not fully baked migration path is using pgloader to load a MySQL database into Postgres and then migrating from Postgres to CockroachDB.


## Known Limitations

- pgloader converts AUTO INCREMENT columns to triggers; and cockroachdb doesn't support triggers.

## Run pgloader (MySQL -> Postgres)

The steps to do this are rather simple, however I haven't seen this work perfectly.  Essentially you include both the source database (MySQL) and the target database (Postgres) in the pgloader command and it does the rest.

```
pgloader mysql://root@localhost/mydb postgresql:///mydb
```

## Export out of Postgres

You may a few things you have to correct on the MySQL side to get all of the correct schema objects and rows of data.  However, once the load process is completed, you can then export out the new Postgres database to import it into CockroachDB

```
pg_dump mydb > mydb.sql
````

## Import into CockroachDB (Postgres -> CockroachDB)

### [CockroachCloud](https://www.cockroachlabs.com/docs/cockroachcloud/run-bulk-operations.html)

Upload the dump file as a userfile

```
cockroach userfile upload ./mydb.sql  --url {pgurl}
```

Log into the CockroachDB cli

```
cockroach sql --url {pgurl}
```

Import the dump file into CockroachDB

```sql
IMPORT PGDUMP 'userfile://defaultdb.public.userfiles_{username}/mydb.sql';
```

### CockroachDB Self Hosted

Copy the dump file to the /data/extern directory on one of the nodes of your CockroachDB cluster.

```
cp mydb.sql ~/local/1/data/extern/
```

Import the dump file

```
IMPORT PGDUMP 'nodelocal://1/mysql.sql' ignore_unsupported_statements;
```
