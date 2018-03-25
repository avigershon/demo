#!/bin/bash

./setup.sh

./setup.sh --chart cluster/cluster
#./setup.sh --chart cluster/nginx-ingress
helm install --name nginx-ingress stable/nginx-ingress

#elastic stack
#./setup.sh --chart cluster/elasticsearch
helm install --name elasticsearch incubator/elasticsearch --set rbac.create=true
./setup.sh --chart cluster/filebeat
#./setup.sh --chart cluster/kibana
helm upgrade kibana --set image.repository=docker.elastic.co/kibana/kibana --set image.tag=5.4.3 --set service.type=LoadBalancer --set service.externalPort=80 --set ingress.enabled=true --set ingress.hosts[0]=kibana.local --set ingress.annotations."kubernetes\.io/ingress\.class"=nginx --set ingress.annotations."kubernetes\.io/tls-acme"=true --set env.ELASTICSEARCH_URL=http://elasticsearch-elasticsearch-client.default.svc.cluster.local:9200 stable/kibana

#kafka
helm install --name kafka incubator/kafka

#node-red
./setup.sh --chart charts/node-red

