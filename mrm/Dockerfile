FROM amazonlinux:latest
MAINTAINER Letgo <sysops@letgo.com>

USER root

RUN yum clean all && rm -fr /var/cache/*
 
RUN yum install -y http://ci.signal18.io/mrm/builds/1.1/replication-manager-1.1.3_1_g8385-1.x86_64.rpm 
COPY config.toml /etc/replication-manager/config.toml
ADD replication-bootstrap.sh /docker-entrypoint-initdb.d/
RUN chmod +x /docker-entrypoint-initdb.d/replication-bootstrap.sh
ENTRYPOINT ["/docker-entrypoint-initdb.d/replication-bootstrap.sh"]

EXPOSE 10001 

ENTRYPOINT ["/usr/bin/replication-manager", "monitor", "--daemon"]

