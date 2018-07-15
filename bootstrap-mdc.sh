#!/bin/bash

./setup.sh

./setup.sh --chart charts/default

#./setup.sh --chart cluster/nginx-ingress
helm install --name nginx-ingress stable/nginx-ingress

#helm del filebeat --purge
#helm install --name filebeat stable/filebeat  
./setup.sh --chart cluster/filebeat
#helm upgrade filebeat stable/filebeat 
