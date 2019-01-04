#!/bin/bash

docker rm -f $(docker ps -a -q); docker-compose up -d
sleep 20

echo "Connect slave 1 to master"
mysql -u root  -proot -h 127.0.0.1 -P33007 -Bse "SET GLOBAL binlog_format = 'ROW'"
mysql -u root  -proot -h 127.0.0.1 -P33007 -Bse 'set global gtid_slave_pos="0-1-7147";change master to master_host="mysql-master",  master_user="root", master_password="root", master_use_gtid=slave_pos'
SLAVE1POS=$(mysql -u root  -proot -h 127.0.0.1  -P33007 -Bse 'select @@gtid_slave_pos' -ss)
echo $SLAVE1POS
mysql -u root  -proot -h 127.0.0.1 -P33007 -Bse 'start slave'

echo "Connect slave 2 to slave-2"
mysql -u root  -proot -h 127.0.0.1 -P33008 -Bse "SET GLOBAL binlog_format = 'ROW'"
mysql -u root  -proot -h 127.0.0.1 -P33008 -Bse 'set global gtid_slave_pos="0-1-7147";change master to master_host="mysql-slave-1",  master_user="root", master_password="root", master_use_gtid=slave_pos;start slave'

echo "Create test table in Master"
mysql -u root  -proot -h 127.0.0.1 -P33006 -Bse "SET GLOBAL binlog_format = 'ROW'"
mysql -u root  -proot -h 127.0.0.1 -P33006 -Bse "use my_database; create table if not exists t(id int)"
mysql -u root  -proot -h 127.0.0.1 -P33006 -Bse "set global read_only=0"