#!/bin/bash

./setup.sh

./setup.sh --chart charts/global

#./setup.sh --chart cluster/nginx-ingress
helm install --name nginx-ingress stable/nginx-ingress

#postgres (for sippycup)
#helm install --name sippycup --set postgresPassword=lioran020 --set postgresDatabase=sippycup stable/postgresql

#elastic stack
#rm -r elasticsearch
#git clone https://github.com/clockworksoul/helm-elasticsearch.git elasticsearch

#helm del elasticsearch --purge
helm install --name elasticsearch --set common.stateful.enabled=true --set image.es.tag=6.2.3 --set kibana.image.repository=docker.elastic.co/kibana/kibana-oss --set kibana.image.tag=6.2.3 --set kibana.env.ELASTICSEARCH_USERNAME=elastic --set kibana.env.ELASTICSEARCH_PASSWORD=changeme elasticsearch
#helm upgrade elasticsearch --set common.stateful.enabled=true --set image.es.tag=6.2.3 --set kibana.image.repository=docker.elastic.co/kibana/kibana-oss --set kibana.image.tag=6.2.3 --set kibana.env.ELASTICSEARCH_USERNAME=elastic --set kibana.env.ELASTICSEARCH_PASSWORD=changeme elasticsearch

#helm del logstash --purge
helm install --name logstash -f cluster/logstash/values.yaml incubator/logstash
#helm upgrade logstash -f cluster/logstash/values.yaml incubator/logstash

#helm del filebeat --purge
#helm install --name filebeat stable/filebeat  
./setup.sh --chart cluster/filebeat
#helm upgrade filebeat stable/filebeat 

#kafka
#helm upgrade kafka --set configurationOverrides."offsets.topic.replication.factor"=5 --set configurationOverrides."auto.offset.commit"=true incubator/kafka
helm install --name kafka --set configurationOverrides."offsets.topic.replication.factor"=5 --set configurationOverrides."auto.offset.commit"=true incubator/kafka

#redis
#helm del redis --purge
#helm install --name redis --set redisDisableCommands="" stable/redis
#helm upgrade redis --set redisDisableCommands="" stable/redis

#tor
#./setup.sh --chart cluster/tor

#node-red
#./setup.sh --chart charts/node-red

#blackbird

#rm -rf projects/blackbird
#mkdir projects/blackbird
#cd projects/blackbird
#git clone --recursive https://github.com/avigershon/blackbird.git .
#docker build -t blackbird .
#docker tag blackbird gcr.io/datagram-195019/blackbird:latest
#docker push gcr.io/datagram-195019/blackbird:latest
./setup.sh --chart charts/blackbird
