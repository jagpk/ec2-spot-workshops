#!/bin/bash

set -e

curl --silent --location "https://get.helm.sh/helm-$HELM_VERSION-linux-amd64.tar.gz" | tar xz -C /tmp
mv /tmp/linux-amd64/helm /usr/local/bin
chmod +x /usr/local/bin/helm

helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo add eks https://aws.github.io/eks-charts
helm repo add k8s-at-home https://k8s-at-home.com/charts/

helm repo update

# Metrics server
helm install metrics-server metrics-server/metrics-server --version $METRIC_SERVER_VERSION -n kube-system \
  --set nodeSelector.intent=control-apps

# AWS load balancer controller $ALB_VERSION
helm install aws-load-balancer-controller eks/aws-load-balancer-controller --version $ALB_VERSION \
  -n kube-system \
  --set clusterName=$EKS_CLUSTER_NAME \
  --set nodeSelector.intent=control-apps \
  --set replicaCount=1 \
  --wait


# kubecost
cat <<EOF > kubecost-values.yaml
nodeSelector:
  intent: control-apps
service:
  type: LoadBalancer
  port: 80
EOF

helm upgrade -i kubecost \
  oci://public.ecr.aws/kubecost/cost-analyzer --version $KUBECOST_VERSION \
  --namespace kubecost --create-namespace \
  -f https://raw.githubusercontent.com/kubecost/cost-analyzer-helm-chart/develop/cost-analyzer/values-eks-cost-monitoring.yaml \
  -f kubecost-values.yaml