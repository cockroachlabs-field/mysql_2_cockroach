#!/bin/bash
if [ -z "$1" ]
then
    echo "Supply the name of the mysqldump file"
    exit 1
fi

export infile=`echo ${1}`
export outfile=`echo ${1/sql/edit.sql}`
echo "###################################################"
echo Source file: $infile
echo Source File Size: `wc -c $infile | awk '{print $1}'`
echo Source Number of rows: `wc -l $infile | awk '{print $1}'`
echo Target file: $outfile
echo "####################################################"

cp $infile $outfile

#echo "Add CREATE DB command to beginning of file"
#sed -i.bkp '1s/^/CREATE DATABASE IF NOT EXISTS gp_poslab_ctp;\nUSE gp_poslab_ctp;\n\n/' $outfile

echo "Remove all constraints"
sed -i.bkp '/CONSTRAINT /d' $outfile

echo "Remove all tableNameBackTicks and fieldNameBackTicks"
sed -i.bkp 's/`//g' $outfile

echo "Remove ENGINE=InnoDB DEFAULT CHARSET=latin1; from end of every CREATE TABLE statement"
sed -i.bkp 's/^.* ENGINE=.*$/\);/g' $outfile

echo "Replace int(11) or any number with int"
sed -i.bkp 's/ int(.[0-9]*) / int /g' $outfile

echo "Replace bigint(20) or any number with int"
sed -i.bkp 's/ bigint(.[0-9]*) / int /g' $outfile

echo "Replace mediumint(8) or any number with int"
sed -i.bkp 's/ mediumint(.[0-9]*) / int /g' $outfile

echo "Replace smallint(6) or any number with smallint"
sed -i.bkp 's/ smallint(.[0-9]*) / smallint /g' $outfile

echo "Replace tinyint(4) or any number with smallint (no tinyint in CRDB)"
sed -i.bkp 's/ tinyint(.[0-9]*) / smallint /g' $outfile

echo "Remove unsigned qualifier from integer types (they dont exists and arent needed in CRDB)"
sed -i.bkp 's/ unsigned//g' $outfile

echo "Remove using BTREE"
sed -i.bkp 's/ USING BTREE//g' $outfile

echo "Replace field_name int NOT NULL AUTO_INCREMENT with field_name SERIAL"
sed -i.bkp 's/^  \(.*\) .* .* .* AUTO_INCREMENT/  \1 SERIAL/' $outfile

echo "Replace mediumblob with bytes"
sed -i.bkp 's/ mediumblob/ bytes/g' $outfile

echo "Replace longblob with bytes"
sed -i.bkp 's/ longblob/ bytes/g' $outfile

echo "Replace blob with bytes"
sed -i.bkp 's/ blob/ bytes/g' $outfile

echo "Remove precision and scale from float & double"
sed -i.bkp 's/ float(.[0-9]*,[0-9]*) / float /g' $outfile
sed -i.bkp 's/ double(.[0-9]*,[0-9]*) / double precision /g' $outfile

echo "Comment out LOCK TABLES statements"
sed -i.bkp 's/LOCK TABLES /--LOCK TABLES /g' $outfile

echo "Comment out UNLOCK TABLES statements"
sed -i.bkp 's/UNLOCK TABLES;/--UNLOCK TABLES;/g' $outfile

echo "Remove CHARACTER SET latin1 COLLATE latin1_bin"
sed -i.bkp 's/ CHARACTER SET latin1 COLLATE latin1_bin//g' $outfile

echo "Convert MYSQL hex encoding to Postgres/CRDB hex encoding, i.e., 0xDD86A2A5C2 -> decode(DD86A2A5C2,hex)"
sed -i.bkp "s/,0x\([0-9A-F]*\)/,decode('\1','hex')/g" $outfile
sed -i.bkp "s/(0x\([0-9A-F]*\)/(decode('\1','hex')/g" $outfile

echo "Replace KEY with INDEX (but not PRIMARY KEY)"
sed -i.bkp 's/  KEY /  INDEX /g' $outfile

echo "Replace UNIQUE KEY with UNIQUE INDEX"
sed -i.bkp 's/  UNIQUE KEY/  UNIQUE INDEX/g' $outfile

echo "Replace datetime with timestamp"
sed -i.bkp 's/ datetime/ timestamp/g' $outfile

echo "Comment out field-level COMMENTs"
sed -i.bkp 's/ COMMENT /,-- COMMENT /g' $outfile

echo "Replace 0 default for int fields with 0 (various versions)"
sed -i.bkp "s/ int NOT NULL DEFAULT '0',/ int NOT NULL DEFAULT 0,/g" $outfile
sed -i.bkp "s/ smallint NOT NULL DEFAULT '0',/ smallint NOT NULL DEFAULT 0,/g" $outfile
sed -i.bkp "s/ int DEFAULT '0',/ int DEFAULT 0,/g" $outfile
sed -i.bkp "s/ int NOT NULL DEFAULT '1',/ int NOT NULL DEFAULT 1,/g" $outfile
sed -i.bkp "s/ smallint NOT NULL DEFAULT '1',/ smallint NOT NULL DEFAULT 1,/g" $outfile
sed -i.bkp "s/ int DEFAULT '1',/ int DEFAULT 1,/g" $outfile
sed -i.bkp "s/ int NOT NULL DEFAULT '2',/ int NOT NULL DEFAULT 2,/g" $outfile
sed -i.bkp "s/ smallint NOT NULL DEFAULT '2',/ smallint NOT NULL DEFAULT 2,/g" $outfile
sed -i.bkp "s/ int DEFAULT '2',/ int DEFAULT 2,/g" $outfile

echo "Replace 0000-00-00 00:00:00 which is a MySQL zero date with -4713-11-24 00:00:00+00:00 which is the value of -infinity"
sed -i.bkp "s/'0000-00-00 00:00:00'/'-4713-11-24 00:00:00+00:00'/g" $outfile
sed -i.bkp "s/'0000-00-00'/'-4713-11-24'/g" $outfile

echo "Table called 'user' needs to be in double quotes since it's a reserved word"
sed -i.bkp 's/DROP TABLE IF EXISTS user;/DROP TABLE IF EXISTS "user";/g' $outfile
sed -i.bkp 's/CREATE TABLE user (/CREATE TABLE "user" (/g' $outfile
sed -i.bkp 's/INSERT INTO user VALUES/INSERT INTO "user" VALUES/g' $outfile
sed -i.bkp 's/  user varchar/  "user" varchar/g' $outfile
sed -i.bkp 's/PRIMARY KEY (domain,user)/PRIMARY KEY (domain,"user")/g' $outfile
sed -i.bkp 's/ user / "user" /g' $outfile

echo "Fix issues with escaping of single quotes in INSERT statements -- MySQL does \' whereas CRDB does ''"
# examples, separated by commas:  Fishermen\'s, Menchie\'s, client\'s, LIL\' TURK, ts \'2010-05-06 14:24:04\'}, Unreg\'d
sed -i.bkp "s/\\\'/''/g" $outfile

echo "Remove on update CURRENT_TIMESTAMP"
sed -i.bkp 's/ON UPDATE CURRENT_TIMESTAMP//g' $outfile

echo "Switch longtext to text"
sed -i.bkp 's/longtext/text/g' $outfile
sed -i.bkp 's/mediumtext/text/g' $outfile

echo "*** CUSTOM EDITS ***"
echo "3rdPartyResourceId"
sed -i.bkp 's/3rdPartyResourceId/\"3rdPartyResourceId\"/g' $outfile
#sed -i.bkp "s/active bit(1) DEFAULT b'1'/active bit(1) DEFAULT B'1'/g" $outfile
sed -i.bkp "s/DEFAULT b'[0-1]'/DEFAULT B'1'/g" $outfile

echo "Remove any dangling commas"
#sed -i.bkp 's/,$\n\\);/\n\\);/g' $outfile


#remove the backup file created by sed (you have to do this to do inline editing on MacOS)
rm $outfile.bkp

#cockroach demo --nodes 3 < $outfile
#cockroach sql --certs-dir /Users/jeffcarlson/se-workspace/Environments/Cockroach/crdb_local/certs < $outfile

echo "###################################################"
echo Source file: $infile
echo Source File Size: `wc -c $infile | awk '{print $1}'`
echo Source Number of rows: `wc -l $infile | awk '{print $1}'`
echo Target file: $outfile
echo Target File Size: `wc -c $outfile | awk '{print $1}'`
echo Target Number of rows: `wc -l $outfile | awk '{print $1}'`
echo "####################################################"
