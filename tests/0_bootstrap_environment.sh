#!/bin/bash

SLEEPTIME=30

cd ../
echo "Stopping dockers..."
docker-compose down
if [[ $(docker ps -a -q) ]]; then
    echo "Removing containers..."
    docker rm -f $(docker ps -a -q)
fi
echo "Starting docker compose..."
docker-compose up -d
echo "Bootstraping MRM, waiting for MySQL instaces"
sleep ${SLEEPTIME}
docker exec -it mrm bash /docker-entrypoint-initdb.d/replication-bootstrap.sh

sleep ${SLEEPTIME}
mysql -u root  -proot -h 127.0.0.1  -P33006 -e "create database my_database; grant all privileges on *.* to 'app_user'@'%'"
mysql -u app_user  -proot -h 127.0.0.1  -P6033  -Bse "use my_database; create table if not exists t(id int)"
while true; do mysql -u app_user  -proot -h 127.0.0.1  -P6033  -Bse "use my_database; insert into t(id) values (current_timestamp(5))"; done
