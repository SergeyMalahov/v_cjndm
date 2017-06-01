FROM ubuntu:16.04

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server \
    && rm -rf /var/lib/mysql

ADD d_* /
RUN chmod +x /d_start.sh \
 && yes | cp -rf d_my.cnf my.cnf

EXPOSE

CMD [ "/d_start.sh" ]
