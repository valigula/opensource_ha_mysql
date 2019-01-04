#!/bin/bash 

SLEEPTIME=14

echo "docker down"
docker-compose down
echo "docker up"
docker-compose up -d
echo "bootstraping mrm"
sleep 30
docker exec -it mrm bash /docker-entrypoint-initdb.d/replication-bootstrap.sh

cd ../

echo "***************************************"
echo "****** kill mysqladmin shutdown  ******"
echo "***************************************"
docker-compose pause mysql-master

echo "********************************"
echo "**** check mysql-master  ******"
echo "********************************"
sleep $SLEEPTIME
#proxysql detect the slave is down and stop sending traffic to it
mysql -s -u root -proot -h 127.0.0.1 -P6032 -Bse "select srv_host from stats_mysql_connection_pool where srv_host = 'mysql-master' and status != 'ONLINE'" | wc -l

echo "****************************************"
echo "****** mysql-slave-1 hostgroup=0  ******"
echo "****************************************"
mysql -u root -proot -h 127.0.0.1  -P6032  -Bse "select srv_host from stats_mysql_connection_pool where hostgroup=0" | grep mysql-slave-1 | wc -l



