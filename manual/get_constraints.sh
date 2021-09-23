mysql -u root -p [mydatabase] < get_constraints.sql | sed -n -e '/^ALTER/p' > apply_constraints.sql
