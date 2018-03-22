#!/bin/bash

./setup.sh

./setup.sh --chart cluster/cluster
./setup.sh --chart cluster/nginx-ingress

#elastic stack
./setup.sh --chart cluster/elasticsearch
./setup.sh --chart cluster/filebeat
./setup.sh --chart cluster/kibana

#kafka
./setup.sh --chart cluster/zookeeper
./setup.sh --chart cluster/kafka

#node-red
./setup.sh --chart charts/node-red
