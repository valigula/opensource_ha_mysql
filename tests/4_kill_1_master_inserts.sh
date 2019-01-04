#!/bin/bash 

SLEEPTIME=15
ERRORS=0

echo "docker down"
docker-compose down
echo "docker up"
docker-compose up -d
echo "bootstraping mrm"
sleep 30
docker exec -it mrm bash /docker-entrypoint-initdb.d/replication-bootstrap.sh
sleep $SLEEPTIME

nohup ./load_testing.sh &
echo $! > pid.txt

cd ../

echo "********************************"
echo "****** stop mysql-master  ******"
echo "********************************"
docker-compose stop mysql-master
sleep $SLEEPTIME
mysql -u root -proot -h 127.0.0.1  -P6032 -Bse "select hostname from monitor.mysql_server_read_only_log where read_only=0 order by time_start_us desc limit 1"  | grep mysql-slave-1 | wc -l
#if [ "$?"-ne 1 ]; then echo "command failed"; exit 1; fi
if [ $? = 0 ]; then ERRORS=$ERRORS+1; fi

echo "********************************"
echo "****** start mysql-master  ******"
echo "********************************"
docker-compose start mysql-master
sleep $SLEEPTIME
mysql -u root -proot -h 127.0.0.1  -P6032 -Bse "select hostname from monitor.mysql_server_read_only_log where read_only=0 order by time_start_us desc limit 1"  | grep mysql-slave-1 | wc -l
if [ $? = 0 ]; then ERRORS=$ERRORS+1; fi

echo "****************************************"
echo "****** mysql-slave-1 hostgroup=0  ******"
echo "****************************************"
mysql -u root -proot -h 127.0.0.1  -P6032  -Bse "select srv_host from stats_mysql_connection_pool where hostgroup=0" | grep mysql-slave-1 | wc -l
if [ $? = 0 ]; then ERRORS=$ERRORS+1; fi

echo "****************************************"
echo "****** mysql-master is slave.     ******"
echo "****************************************"
docker-compose exec -T mysql-master  mysql -u root -proot -Bse "SHOW STATUS LIKE 'Slave_running';" | grep "ON" | wc -l
if [ $? = 0 ]; then ERRORS=$ERRORS+1; fi

kill -9 `cat tests/pid.txt`
#rm tests/pid.txt

if [ $ERRORS > 0 ]; then echo "failed"; exit 1;fi

echo "Sucessfull"


