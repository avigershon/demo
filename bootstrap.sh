#!/bin/bash

./setup.sh

./setup.sh --chart cluster/cluster
#./setup.sh --chart cluster/nginx-ingress
helm install --name nginx-ingress stable/nginx-ingress

#elastic stack
git clone https://github.com/clockworksoul/helm-elasticsearch.git elasticsearch
helm install --name elasticsearch --set image.es.tag=6.2.3 --set kibana.image.tag=6.2.3 --set backend.es.host=elasticsearch-elasticsearch --set env.XPACK_GRAPH_ENABLED="true" --set env.XPACK_ML_ENABLED="true" --set env.XPACK_REPORTING_ENABLED="true" --set env.XPACK_SECURITY_ENABLED="true" elasticsearch

helm install --name fluent-bit stable/fluent-bit

#kafka
helm install --name kafka incubator/kafka

#node-red
./setup.sh --chart charts/node-red

