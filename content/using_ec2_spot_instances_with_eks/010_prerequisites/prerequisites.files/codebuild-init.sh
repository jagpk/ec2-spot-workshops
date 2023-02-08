#!/bin/bash

set -e

helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo add eks https://aws.github.io/eks-charts
helm repo add k8s-at-home https://k8s-at-home.com/charts/

helm repo update

# Metrics server
helm install metrics-server metrics-server/metrics-server --version 3.8.2 -n kube-system \
  --set nodeSelector.intent=control-apps

# AWS load balancer controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller --version 1.4.7 \
  -n kube-system \
  --set clusterName=$EKS_CLUSTER_NAME \
  --set nodeSelector.intent=control-apps \
  --set replicaCount=1 \
  --wait

# kube-ops-view
helm install kube-ops-view k8s-at-home/kube-ops-view -n kube-system --version 1.2.2 --wait

sleep 30

cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kube-ops-view-ingress
  namespace: kube-system
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kube-ops-view
            port:
               number: 8080
EOF

# kubecost
cat <<EOF > kubecost-values.yaml
nodeSelector:
  intent: control-apps
service:
  type: LoadBalancer
  port: 80
EOF

helm upgrade -i kubecost \
  oci://public.ecr.aws/kubecost/cost-analyzer --version 1.99.0 \
  --namespace kubecost --create-namespace \
  -f https://raw.githubusercontent.com/kubecost/cost-analyzer-helm-chart/develop/cost-analyzer/values-eks-cost-monitoring.yaml \
  -f kubecost-values.yaml

# karpenter
export CLUSTER_ENDPOINT="$(aws eks describe-cluster --name ${EKS_CLUSTER_NAME} --query "cluster.endpoint" --output text)"

TEMPOUT=$(mktemp)

curl -fsSL https://karpenter.sh/"${KARPENTER_VERSION}"/getting-started/getting-started-with-eksctl/cloudformation.yaml  > $TEMPOUT \
&& aws cloudformation deploy \
  --stack-name "Karpenter-${EKS_CLUSTER_NAME}" \
  --template-file "${TEMPOUT}" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides "ClusterName=${EKS_CLUSTER_NAME}"

eksctl create iamidentitymapping \
  --username system:node:{{EC2PrivateDNSName}} \
  --cluster "${EKS_CLUSTER_NAME}" \
  --arn "arn:aws:iam::${AWS_ACCOUNT_ID}:role/KarpenterNodeRole-${EKS_CLUSTER_NAME}" \
  --group system:bootstrappers \
  --group system:nodes

eksctl create iamserviceaccount \
  --cluster "${EKS_CLUSTER_NAME}" --name karpenter --namespace karpenter \
  --role-name "${EKS_CLUSTER_NAME}-karpenter" \
  --attach-policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/KarpenterControllerPolicy-${EKS_CLUSTER_NAME}" \
  --role-only \
  --approve

export KARPENTER_IAM_ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${EKS_CLUSTER_NAME}-karpenter"

helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter --version ${KARPENTER_VERSION} --namespace karpenter --create-namespace \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=${KARPENTER_IAM_ROLE_ARN} \
  --set settings.aws.clusterName=${EKS_CLUSTER_NAME} \
  --set settings.aws.clusterEndpoint=${CLUSTER_ENDPOINT} \
  --set settings.aws.defaultInstanceProfile=KarpenterNodeInstanceProfile-${EKS_CLUSTER_NAME} \
  --set settings.aws.interruptionQueueName=${EKS_CLUSTER_NAME} \
  --set replicas=1 \
  --wait

# baseline workloads
aws s3 cp s3://${ASSETS_BUCKET_NAME}/${ASSETS_BUCKET_PREFIX}baseline.yaml /tmp
kubectl apply -f /tmp/baseline.yaml