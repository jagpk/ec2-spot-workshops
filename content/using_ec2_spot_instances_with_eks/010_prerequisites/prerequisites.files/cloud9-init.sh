#!/bin/bash

set -e

sudo yum install -y bash-completion moreutils jq

curl --silent --location -o /usr/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl
chmod +x /usr/bin/kubectl
sudo -H -u ec2-user bash -c "kubectl completion bash >>  ~/.bash_completion"
sudo -H -u ec2-user bash -c ". /etc/profile.d/bash_completion.sh"
sudo -H -u ec2-user bash -c ". ~/.bash_completion"

curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/${EKSCTL_VERSION}/eksctl_Linux_amd64.tar.gz" | tar xz -C /tmp
mv /tmp/eksctl /usr/bin
sudo -H -u ec2-user bash -c "eksctl completion bash >> ~/.bash_completion"

curl --silent --location "https://get.helm.sh/helm-${EKSCTL_VERSION}-linux-amd64.tar.gz" | tar xz -C /tmp
mv /tmp/linux-amd64/helm /usr/bin
chmod +x /usr/bin/helm

cat << EOF > /home/ec2-user/.bashrc.d/env.bash
export EKS_CLUSTER_NAME=${EKS_CLUSTER_NAME}
export ACCOUNTID=${ACCOUNTID}
export AWS_DEFAULT_REGION=${REGION}

aws eks update-kubeconfig --name ${EKS_CLUSTER_NAME}
EOF