# Manual MySQL Migration to CockroachDB with Regex

This is by no means perfect, but should be a good enough starter kit to get you started on doing a manual migration of MySQL to CockroachDB.

**High Level Steps**
- Load your mysqldump file into a local MySQL database
- Export out constraints out of MySQL
- Export out a schema only dump file out of MySQL
- Reformat the schema (schemaFormat.sh)
- Import the schema into CockroachDB
- Export tsv files out of MySQL
- Import the data into CockroachDB
- Apply constraints in CockroachDB

## Load your mysqldump file into a local MySQL database

Import a MySQL dump file

```
mysql -u root -p < [name of dump file].sql
```

## Export out constraints out of MySQL

In the **get_constraints.sh** file, add the name of the database and connection parameters you need to connect to the MySQL database.  Additionally then add the database name in the **get_constraint.sql** files as well.  Then run the following command in a shell:

```
get_constraints.sh
```

This will output a file called **apply_constraints.sql** that we will utilize later in the migration.


## Export out a schema only dump file out of MySQL

Export the schema only out of MySQL

```
mysqldump -d -u root -p [mydb] --no-data > mydb.sql
```

## Reformat the schema (schemaFormat.sh)

Run schema formatting script.  This should convert the mysqldump file into a Cockroach SQL script.  It does a fair amount of formating and there's a chance you may have to add your formatting sed commands.  It removes all references to constraints, special mysql syntax and hints and converts data types.

```
./schemaFormat.sh mydb.sql
```

This will output a file called **mydb.edit.sql**

Additionally, manually search and replace the following regex expressions below.  I couldn't follow how to do multi-line sed replacements so it's just easier doing this in a text editor.

***Find:***      ,$\n\);

***Replace:***   \n);


~~## Sort the schema file by Foreign Key Constraints~~

~~When importing the schema file as is, many errors will occur because there is no way to differ / skip FK constraints.  Instead, we need to sort the creation of table and FK constraints to make sure all tables and constraints get created in order without any failures.  To do this, we utilized the gawk script here:~~

~~https://gist.github.com/garex/3987864~~

~~Not this one:
https://thinkinginsoftware.blogspot.com/2012/03/sort-key-and-constraint-in-mysqldump.html?m=1~~

~~```~~
~~./mysqldump_sort.gawk < mydb.edit.sql > mydb.edit.sorted.sql~~
~~```~~

~~Other idea: Find out a way to disable FK constraints the way IMPORT does (i.e. --skip_foreign_keys)~~

## Import the schema into CockroachDB

Create a CockroachDB cluster and import the schema.  Once the cluster is created, log into the CockroachDB CLI.

```
cockroach sql --insecure
```

And import schema file.  Note, the example below assumes you started the Cockroach CLI in the same directory of the dump file.

```sql
set client_min_messages = error;
\i mydb.edit.sql
```

Most likely you will items that won't properly get created.  You can edit the mydb.edit.sql directly or go back into the **schemaFormat.sh** to add the right formatting changes.

## Export tsv files out of MySQL

Why a tab separated file?  Experience has told me something always goes sideways with commas because they're are everywhere in a dump file.  Tabs it is.

When we export the data out, we want to be explicit about field terminate, enclosure, escapes, etc.  We'll use the same setting on the Cockroach side when we import.  Here are the settings I like to use:

- Fields Terminated = \t
- Field Enclosed = "
- Fields Escaped = \
- Rows Terminated = \n

Run the export below.  This will output the tsv files in the path you have next to the `-T` argument.

```
mysqldump -u root -p -T /Users/chriscasano/Repos/mydb/data --fields-terminated-by '\t' --fields-enclosed-by '"' --fields-escaped-by '\' --no-create-info mydb
```

## Import the data into CockroachDB

To import the data, you can either copy the data locally to where the CockroachDB cluster is, or if using CockroachCloud, I would suggest using cloud storage like s3://.

For self hosted, copy the data to the /data/extern on one of the CockroachDB nodes:

```
cp data/*.txt /Users/chriscasano/local/1/data/extern/
```

Now let's create all of the import statements.  Run the following shell script to generate the `IMPORT` statements.

```
create_imports.sh
```

This will output a file called **run_imports.sql** that will contain all of the import commands.  Awesome, now let's run some imports.

Log into the Cockroach CLI and run the imports

```
cockroach sql --insecure
```

This again assumes your connecting to Cockroach from the directory where the **run_imports.sql** file is.

```
\i run_imports.sql
```

Most likely you will have a few data errors that you need to fix.  But hopefully this gets 90% or more of your data imported.

## Apply Constraints in CockroachDB

Log into the CockroachDB shell

```
cockroach sql --insecure
```

Now let's apply the constraints.

```
\i apply_constraints.sql
```

Most likely you'll get a few kickouts because the constraints are not ordered by dependency in the apply_constraints.sql file.  This would be a nice enhancement.  Therefore you may have to manually shift some of the constraints around to apply them in a specific order.  Feel free to edit the **apply_constraints.sql** file.

## TODOS

1) Foreign Keys - This is a two fold problem.  Exporting a dump file from mysql does not put the tables in order of FK constraints.  Additionally the **get_constraints.sql** doesn't but the FKs in the correct dependency order.  This would be a nice fix.

2) Create a regex to remove trailing commas when the schemaFormat.sh removes constraints.
