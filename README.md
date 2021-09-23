# Migrating MySQL to CockroachDB

Well...database migrations are not always straightforward.  Hopefully this repo can alleviate some of the stress in getting your MySQL database working on CockroachDB.  Although both databases are relational, the SQL dialect, feature set and overall execution are fairly different.  This is a working guide on how you may go about your migration.  Having worked on about ~3 migrations from MySQL to CockroachDB, here are the notes I compiled so you can make and educated decision on which path you want to choose.

## MySQL Migration Options

Below is an analysis of the various migration paths.

### [(1) Converting MySQL dump to CockroachDB SQL with Regex](./manual/README.md)<br>
**[MySQL -> Cockroach]**

For almost all migrations I have done, this path seems to work out the best.  It provides the most flexibility although it takes a fair amount of scripting with sed, regex and understanding SQL.  If you have the time and patience, this is probably the most accurate way of conducting a MySQL to Cockroach migration.

- **Pro**:
  - Most flexibility
  - Scripts have been maturing from additional migrations

- **Con**:
  - Can be time consuming and gritty
  - Not well documented

### [(2) Import via Cockroach Import MYSQLDUMP](https://www.cockroachlabs.com/docs/v21.1/migrate-from-mysql.html)<br>
**[MySQL -> Cockroach]**

This should be the best option but unfortunately there are too many edges for in how `IMPORT MYSQLDUMP` works on CockroachDB.  If you have a very small database and simple schema, this option could work rather easily for you.  For larger databases and complicated schemas, this will be difficult.  The one thing I do like is that you can import a mysqldump and skip the FK constraints.

- **Pro**:
  - Documented: https://www.cockroachlabs.com/docs/v21.1/migrate-from-mysql.html
  - Easier with smaller databases
  - Can skip FK constraints

- **Con**:
 - Struggles on parsing and converting data types
  - Many edge cases and open issues: https://github.com/cockroachdb/cockroach/issues?q=is%3Aissue+is%3Aopen+mysqldump

### [(3) Import into Postgres using pgloader, then migrate to Cockroach with Import pgdump](./pgloader/README.md)<br>
**[MySQL -> Postgres -> Cockroach]**

This path should be viable one day.  Using pgloader to get MySQL into Postgres is rather straightforward, robust and verbose.  However, the path of Postgres to CockroachDB still takes a fair amount of work.  Additionally, there are items from MySQL that get converted into objects in Postgres that are not supported by CockroachDB.  An example of this is 'ON UPDATE' on a column.  This gets converted into a trigger in CockroachDB which isn't supported today.  I think in time, this could be a viable path once CockroachDB and Postgres compatability converge more, or the `IMPORT PGDUMP` feature in CockroachDB matures.

- **Pro**:
  - PGLoader is rather robust for getting MySQL into Postgres

- **Con**:
  - The migration from Postgres to Cockroach is still not simple
  - PGLoader creates triggers for ON UPDATE columns which CockroachDB doesn't support yet
  - PGLoader create sequences for AUTO INCREMENT which `IMPORT PGDUMP` struggles to import


## Setup

I typically always ask a customer for a `mysqldump` that has scrubbed data if they're willing to share.  If not, just the schema will do.  I'll typically import this in my MySQL database so I can access the catalog, adjust scripts and pgloader typically works better from a live database than a dump file (I don't know why).

Depending what path you choose above, I typically find myself needing to install mysql, postgres, pgloader, cockroachdb and then working with sed, grep, bash and SQL.

### Install CockroachDB or use CockroachCloud (Mac Setup) (Required)

- [CockroachCloud](https://www.cockroachlabs.com/docs/cockroachcloud/create-an-account.html)
- [CockroachDB Self Hosted Setup](https://www.cockroachlabs.com/docs/stable/install-cockroachdb-mac.html)

### Install MySql (Mac Setup) (Required)

```
brew install mysql@5.7
```

Add mysql to your path

___
If you need to have mysql@5.7 first in your PATH run:
  echo 'export PATH="/usr/local/opt/mysql@5.7/bin:$PATH"' >> /Users/chriscasano/.bash_profile

For compilers to find mysql@5.7 you may need to set:
  export LDFLAGS="-L/usr/local/opt/mysql@5.7/lib"
  export CPPFLAGS="-I/usr/local/opt/mysql@5.7/include"

For pkg-config to find mysql@5.7 you may need to set:
  export PKG_CONFIG_PATH="/usr/local/opt/mysql@5.7/lib/pkgconfig"

To have launchd start mysql@5.7 now and restart at login:
  brew services start mysql@5.7
___

Run a secure installation

```
mysql_secure_installation
```

Follow prompts to create a secure setup  


#### Enable MySql to export data

Create the file: ~/.my.cnf

Add the following contents to the file

```
[mysqld]
secure_file_priv = ''
```

Restart your mysql service

`brew services start mysql@5.7`

If you'd like check that the secure_file_priv is set by running the command below in the mysql cli:

```
SHOW VARIABLES LIKE "secure_file_priv"
```


#### Import dump file into MySQL from your customer

```
brew services start mysql@5.7
mysql -u root -p < [name of dump file].sql
```

### Install Postgres (Mac Setup) (Optional)

https://wiki.postgresql.org/wiki/Homebrew

```
$ brew install postgresql

```

This install the command line console (psql) as well as the server, if you'd like to create your own databases locally. Run the following to start the server and login to it (it basically sets up a single "admin" user with your username, so that's who you'll be logged in as.

```
$ brew services start postgresql@12
$ export PATH="/usr/local/opt/postgresql@12/bin:$PATH"
$ psql postgres

```

You can see what other versions are available   by running

```
$ brew search postgres
```

You can see which version the current latest will be by running

```
$ brew edit postgresql
```

### Install pgloader (Mac Setup) (Optional)

```
brew install pgloader
```

## References

The following references were used:
- https://github.com/cockroachdb/docs/issues/2403
- https://wiki.postgresql.org/wiki/Converting_from_other_Databases_to_PostgreSQL

#### Special Thanks..

There have been many others that help contributed ideas and sweat into this effort including Robert Lee, Jim Hatcher, Jeff Carlson, John Schaeffer and Andrew Deally.
