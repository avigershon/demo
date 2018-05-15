FROM logstash:latest
MAINTAINER avigershon@gmail.com

RUN mkdir -p /opt/logstash/vendor/jar/jdbc/
RUN wget https://jdbc.postgresql.org/download/postgresql-9.4.1208.jre7.jar -O /opt/logstash/vendor/jar/jdbc/postgresql-9.4-1208-jdbc41.jar
RUN bin/plugin install logstash-input-jdbc
