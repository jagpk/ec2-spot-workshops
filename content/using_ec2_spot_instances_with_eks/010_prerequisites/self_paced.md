---
title: "...on your own"
chapter: false
weight: 10
---

{{% notice warning %}}
Only complete this section if you are **running the workshop on your own**. If you are at an AWS hosted event (such as re:Invent, Kubecon, Immersion Day, etc), go to [**at an AWS event**]({{< ref "/using_ec2_spot_instances_with_eks/010_prerequisites/aws_event.md" >}}) page.
{{% /notice %}}

### Do not have AWS Account?

1. If you do not have an AWS account, complete the steps provided in this link [Sign up for an AWS account](https://docs.aws.amazon.com/IAM/latest/UserGuide/getting-set-up.html#sign-up-for-aws).

1. After you sign up for an AWS account, create an administrative user so that you don't use the root user for regular tasks. Complete the steps provided in this link [Create an administrative user](https://docs.aws.amazon.com/IAM/latest/UserGuide/getting-set-up.html#create-an-admin).

### Deploying CloudFormation 

You start the workshop with an EKS cluster and a managed node group with On-Demand capacity. You use [AWS CloudFormation](https://aws.amazon.com/cloudformation/) templates to install these prerequisites. 

1. Download **[eks-spot-mng-quickstarter-cnf.yml](https://raw.githubusercontent.com/awslabs/ec2-spot-workshops/master/content/karpenter/010_prerequisites/prerequisites.files/eks-ng-workshop-quickstart-cnf.yml)** cloudformation template file locally.

1. Go into the CloudFormation console and select the creation of a new stack. Select **Template is ready**, and then **Upload a template file**, then select the file that you downloaded to your computer and click on **Next**.

1. Fill in the **Stack Name** using `eks-ng-workshop`, leave all the settings in the parameters section as default and click **Next**.

1. In the Configure Stack options just scroll to the bottom of the page and click **Next**.

1. Finally in the **Review eks-mng-workshop** go to the bottom of the page and tick the `Capabilities` section *I acknowledge that AWS CloudFormation might create IAM resources.* then click **Create stack**.

1. The template deploys resources such as:
    * An [AWS Cloud9](https://console.aws.amazon.com/cloud9) workspace with all the dependencies and IAM privileges to run the workshop 
    * An EKS Cluster with the name `eksworkshop-eksctl` 
    * a [EKS managed node group](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html)  with 2 on-demand instances. 


{{% notice warning %}}
The deployment of this stack may take up to 20minutes. You should wait until all the resources in the cloudformation stack have been completed before you start the rest of the workshop. 
{{% /notice %}}


### Checking the completion of the stack deployment

One way to check your stack has been fully deployed is to check that all the cloudformation dependencies are green and succeeded in the cloudformation dashboard; This should look similar to the state below.

![cnf_output](/images/using_ec2_spot_instances_with_eks/prerequisites/cfn_stak_completion.png)

### Getting access to Cloud9  

In this workshop, you need to AWS Cloud9 IDE to interact with your EKS Cluster. Follow below steps to access Cloud9 IDE:

1. On the [AWS CloudFormation console](https://console.aws.amazon.com/cloudformation), select the stack name that starts with **mod-** in the list.

2. In the stack details pane, click the **Outputs** tab.

![cnf_output](/images/using_ec2_spot_instances_with_eks/prerequisites/cnf_output.png)
{{% notice note %}}
Cloud9 normally manages IAM credentials dynamically. This isn't currently compatible with the EKS IAM authentication, so we will disable it and rely on the IAM role instead.
{{% /notice %}}

3. Return to your workspace and click the sprocket, or launch a new tab to open the Preferences tab
4. Select **AWS SETTINGS**
5. Turn off **AWS managed temporary credentials**
6. Close the Preferences tab
![c9disableiam](/images/using_ec2_spot_instances_with_eks/prerequisites/c9disableiam.png)

7. To ensure temporary credentials aren't already in place we will also remove
any existing credentials file:
```
rm -vf ${HOME}/.aws/credentials
```

You are now ready to **[Test the Cluster]({{<  relref "/karpenter/test.md"  >}})**