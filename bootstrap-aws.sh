#!/bin/bash

./setup.sh

./setup.sh --chart charts/default

#./setup.sh --chart cluster/nginx-ingress
helm install --name nginx-ingress stable/nginx-ingress

#helm del filebeat --purge
#helm install --name filebeat stable/filebeat  
./setup.sh --chart cluster/filebeat
#helm upgrade filebeat stable/filebeat 

#elastic stack
rm -rf elasticsearch
git clone https://github.com/clockworksoul/helm-elasticsearch.git elasticsearch

# change cronJob apiVersion from v2alpha1 to v1beta1
# nano elasticsearch/templates/_helpers.tpl
#helm del elasticsearch --purge
helm install --name elasticsearch --set common.stateful.enabled=true --set image.es.tag=6.2.3 --set kibana.image.repository=docker.elastic.co/kibana/kibana-oss --set kibana.image.tag=6.2.3 --set kibana.env.ELASTICSEARCH_USERNAME=elastic --set kibana.env.ELASTICSEARCH_PASSWORD=changeme --set common.stateful.class=nifi-storage-class elasticsearch
#helm upgrade elasticsearch --set common.stateful.enabled=true --set image.es.tag=6.2.3 --set kibana.image.repository=docker.elastic.co/kibana/kibana-oss --set kibana.image.tag=6.2.3 --set kibana.env.ELASTICSEARCH_USERNAME=elastic --set kibana.env.ELASTICSEARCH_PASSWORD=changeme --set common.stateful.class=nifi-storage-class elasticsearch

#helm del logstash --purge
helm install --name logstash --set  persistence.storageClass=nifi-storage-class -f cluster/logstash/values-ashford.yaml incubator/logstash
#helm upgrade logstash --set  persistence.storageClass=nifi-storage-class -f cluster/logstash/values-ashford.yaml incubator/logstash

#kafka
#helm del kafka --purge
#helm upgrade kafka --set configurationOverrides."offsets.topic.replication.factor"=5 --set configurationOverrides."auto.offset.commit"=true --set persistence.storageClass="nifi-storage-class" incubator/kafka
helm install --name kafka --set configurationOverrides."offsets.topic.replication.factor"=5 --set configurationOverrides."auto.offset.commit"=true --set persistence.storageClass="nifi-storage-class" incubator/kafka

#schema-registry
#helm del schema-registry --purge
#helm upgrade schema-registry --set kafkaStore.overrideBootstrapServers="kafka-kafka.default.svc.cluster.local:9092" --set kafka.enabled=false incubator/schema-registry
helm install --name schema-registry --set kafkaStore.overrideBootstrapServers=PLAINTEXT://kafka:9092 --set kafka.enabled=false incubator/schema-registry

#nifi
rm -rf apache-nifi-helm
git clone https://github.com/avigershon/apache-nifi-helm.git

helm install --name nifi --set storageClass=nifi-storage-class --set storageProvisioner="kubernetes.io/aws-ebs" --set storageType=gp2 --set zookeeper.storageClass=nifi-storage-class   --set zookeeper.storageType=gp2 ./apache-nifi-helm
#helm upgrade nifi --set storageClass=nifi-storage-class --set storageProvisioner="kubernetes.io/aws-ebs" --set storageType=gp2 --set zookeeper.storageClass=nifi-storage-class   --set zookeeper.storageType=gp2 ./apache-nifi-helm
