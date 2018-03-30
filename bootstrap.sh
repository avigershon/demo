#!/bin/bash

./setup.sh

./setup.sh --chart cluster/cluster
#./setup.sh --chart cluster/nginx-ingress
helm install --name nginx-ingress stable/nginx-ingress

#elastic stack
rm -r elasticsearch
git clone https://github.com/clockworksoul/helm-elasticsearch.git elasticsearch

#helm del elasticsearch --purge
helm install --name elasticsearch --set common.stateful.enabled=true --set image.es.tag=6.2.3 --set kibana.image.repository=docker.elastic.co/kibana/kibana-oss --set kibana.image.tag=6.2.3 elasticsearch
#helm upgrade elasticsearch --set common.stateful.enabled=true --set image.es.tag=6.2.3 --set kibana.image.repository=docker.elastic.co/kibana/kibana-oss --set kibana.image.tag=6.2.3 elasticsearch

#helm del filebeat --purge
#helm install --name filebeat stable/filebeat  
./setup.sh --chart cluster/filebeat
#helm upgrade filebeat stable/filebeat 

#kafka
helm upgrade --name kafka --set configurationOverrides."offsets.topic.replication.factor"=5 --set configurationOverrides."auto.offset.commit"=true incubator/kafka

#redis
#helm del redis --purge
helm install --name redis stable/redis
#helm upgrade redis stable/redis

#node-red
./setup.sh --chart charts/node-red
<<<<<<< HEAD

#end script
=======
>>>>>>> eb00e52612391b4a134b39267128f697b68dc626
