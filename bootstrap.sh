#!/bin/bash

./setup.sh

./setup.sh --chart cluster/cluster
./setup.sh --chart cluster/nginx-ingress

#elastic stack
#./setup.sh --chart cluster/elasticsearch
helm install --name elasticsearch incubator/elasticsearch --set image.repository=docker.elastic.co/elasticsearch/elasticsearch --set image.tag=6.2.3 --set rbac.create=true
./setup.sh --chart cluster/filebeat
#./setup.sh --chart cluster/kibana
helm install --name kibana --set image.repository=docker.elastic.co/kibana/kibana --set image.tag=6.2.3 --set ingress.enabled=true,ingress.hosts[0]=kibana.local,ingress.annotations[0]="kubernetes.io/ingress.class: nginx" --set env.ELASTICSEARCH_URL=http://elasticsearch-elasticsearch-client.default.svc.cluster.local:9200 stable/kibana

#kafka
./setup.sh --chart cluster/zookeeper
./setup.sh --chart cluster/kafka

#node-red
./setup.sh --chart charts/node-red

