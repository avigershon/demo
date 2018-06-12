FROM logstash:latest
MAINTAINER avigershon@gmail.com

RUN /usr/share/logstash/bin/logstash-plugin install logstash-output-google_bigquery

USER logstash
WORKDIR /opt/logstash
