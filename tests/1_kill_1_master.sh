#!/bin/bash 

SLEEPTIME=14

echo "docker down"
docker-compose down
echo "docker up"
docker-compose up -d
echo "bootstraping mrm"
sleep 40
docker exec -it mrm bash /docker-entrypoint-initdb.d/replication-bootstrap.sh
sleep $SLEEPTIME

cd ../

echo "********************************"
echo "****** stop mysql-master  ******"
echo "********************************"
docker-compose stop mysql-master
sleep $SLEEPTIME
mysql -u root -proot -h 127.0.0.1  -P6032 -Bse "select hostname  from monitor.mysql_server_read_only_log where read_only=0 order by time_start_us desc limit 1"  | grep mysql-slave-1 | wc -l

echo "********************************"
echo "****** start mysql-master  ******"
echo "********************************"
docker-compose start mysql-master
sleep $SLEEPTIME
mysql -u root -proot -h 127.0.0.1  -P6032 -Bse "select hostname  from monitor.mysql_server_read_only_log where read_only=0 order by time_start_us desc limit 1"  | grep mysql-slave-1 | wc -l

echo "****************************************"
echo "****** mysql-slave-2 hostgroup=0  ******"
echo "****************************************"
mysql -u root -proot -h 127.0.0.1  -P6032  -Bse "select srv_host from stats_mysql_connection_pool where hostgroup=0" | grep mysql-slave-1 | wc -l

echo "****************************************"
echo "****** mysql-master is slave.     ******"
echo "****************************************"
docker-compose exec -T mysql-master  mysql -u root -proot -Bse "SHOW STATUS LIKE 'Slave_running';" | grep "ON" | wc -l


