#!/bin/bash

./setup.sh

./setup.sh --chart cluster/cluster
#./setup.sh --chart cluster/nginx-ingress
helm install --name nginx-ingress stable/nginx-ingress

#elastic stack
rm -r elasticsearch
git clone https://github.com/clockworksoul/helm-elasticsearch.git elasticsearch
helm install --name elasticsearch  --set image.es.tag=6.2.3 --set image.repository=docker.elastic.co/kibana/kibana --set kibana.image.tag=6.2.3 --set kibana.env.XPACK_GRAPH_ENABLED="true" --set kibana.env.XPACK_ML_ENABLED="true" --set kibana.env.XPACK_REPORTING_ENABLED="true" --set kibana.env.XPACK_SECURITY_ENABLED="true" elasticsearch
#helm upgrade elasticsearch --set image.es.tag=6.2.3 --set image.repository=docker.elastic.co/kibana/kibana --set kibana.image.tag=6.2.3 --set kibana.env.XPACK_GRAPH_ENABLED="true" --set kibana.env.XPACK_ML_ENABLED="true" --set kibana.env.XPACK_REPORTING_ENABLED="true" --set kibana.env.XPACK_SECURITY_ENABLED="true" elasticsearch

#helm install --name fluent-bit --set backend.es.host=elasticsearch-elasticsearch --set rbac.create=true stable/fluent-bit

#kafka
helm upgrade --name kafka --set configurationOverrides."offsets.topic.replication.factor"=5 --set configurationOverrides."auto.offset.commit"=true incubator/kafka

#node-red
./setup.sh --chart charts/node-red

