#!/bin/bash -xe
cd /tmp
#Copy installation scripts from s3 to /tmp
wget https://aws-bigdata-blog.s3.amazonaws.com/artifacts/aws-blog-emr-prometheus-grafana/scripts/setup-grafana.sh
wget https://aws-bigdata-blog.s3.amazonaws.com/artifacts/aws-blog-emr-prometheus-grafana/scripts/setup-prometheus.sh

##install prometheus
sudo chmod +x setup-prometheus.sh
/tmp/setup-prometheus.sh

##install grafana
sudo chmod +x setup-grafana.sh
/tmp/setup-grafana.sh
