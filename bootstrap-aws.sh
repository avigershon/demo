#!/bin/bash

./setup.sh

./setup.sh --chart charts/default

#./setup.sh --chart cluster/nginx-ingress
helm install --name nginx-ingress stable/nginx-ingress

#elastic stack
rm -rf elasticsearch
git clone https://github.com/clockworksoul/helm-elasticsearch.git elasticsearch

#helm del elasticsearch --purge
helm install --name elasticsearch --set common.stateful.enabled=true --set image.es.tag=6.2.3 --set kibana.image.repository=docker.elastic.co/kibana/kibana-oss --set kibana.image.tag=6.2.3 --set kibana.env.ELASTICSEARCH_USERNAME=elastic --set kibana.env.ELASTICSEARCH_PASSWORD=changeme elasticsearch
#helm upgrade elasticsearch --set common.stateful.enabled=true --set image.es.tag=6.2.3 --set kibana.image.repository=docker.elastic.co/kibana/kibana-oss --set kibana.image.tag=6.2.3 --set kibana.env.ELASTICSEARCH_USERNAME=elastic --set kibana.env.ELASTICSEARCH_PASSWORD=changeme elasticsearch

#helm del logstash --purge
#helm install --name logstash -f cluster/logstash/values.yaml incubator/logstash
#helm upgrade logstash -f cluster/logstash/values.yaml incubator/logstash

#helm del filebeat --purge
#helm install --name filebeat stable/filebeat  
./setup.sh --chart cluster/filebeat
#helm upgrade filebeat stable/filebeat 

#kafka
#helm del kafka --purge
#helm upgrade kafka --set configurationOverrides."offsets.topic.replication.factor"=5 --set configurationOverrides."auto.offset.commit"=true incubator/kafka
helm install --name kafka --set configurationOverrides."offsets.topic.replication.factor"=5 --set configurationOverrides."auto.offset.commit"=true incubator/kafka

#schema-registry
#helm del schema-registry --purge
#helm upgrade schema-registry --set kafkaStore.overrideBootstrapServers="kafka-kafka.default.svc.cluster.local:9092" --set kafka.enabled=false incubator/schema-registry
#helm install --name schema-registry --set kafkaStore.overrideBootstrapServers=PLAINTEXT://kafka:9092 --set kafka.enabled=false incubator/schema-registry
