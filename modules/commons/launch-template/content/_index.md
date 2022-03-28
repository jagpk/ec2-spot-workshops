---
title: "Creating a Launch Template"
date: 2021-07-07T08:51:33Z
weight: 20
---

In this chapter you create a [launch template](https://docs.aws.amazon.com/autoscaling/ec2/userguide/LaunchTemplates.html) 
and use it to define launch parameters so that you do not have to specify them every time you launch an instance. A launch template includes the ID of the Amazon Machine Image (AMI), the instance type, a key pair, security groups, and other parameters used to launch EC2 instances. Launch template allows you to have multiple versions of a launch template. Every change to the launch template can be tracked and you can select which version to use as new changes are applied to the template. This can be used for governance as well as to manage approved upgrades to, for example, Auto Scaling groups. If you do not specify a version, the default version is used.

{{% notice info %}}
We recommend that you use launch templates instead of launch configurations to ensure that you're accessing the latest features and improvements. Not all Amazon EC2 Auto Scaling features are available when you use launch configurations. For example, you cannot create an Auto Scaling group that launches both Spot and On-Demand Instances or that specifies multiple instance types. You must use a launch template to configure these features. 
{{% /notice %}}

{{% notice warning %}}
During this workshop, you use your account's default VPC to create the instances. If your account does not have a default VPC you can create or nominate one following [this link](https://docs.aws.amazon.com/vpc/latest/userguide/default-vpc.html#create-default-vpc)
{{% /notice %}}

**Environment variables definition**

You start with creating environment variables, so you can reference them later and replace some of the parameters in the commands.

1. **Network parameters**: Run the following commands to retrieve your default VPC id and associated subnet ids.
    To learn more about these APIs, see [describe vpcs](https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-vpcs.html) and [describe subnets](https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-subnets.html).

    ```
    export VPC_ID=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true | jq -r '.Vpcs[0].VpcId')
    export SUBNETS=$(aws ec2 describe-subnets --filters Name=vpc-id,Values="${VPC_ID}")
    export SUBNET_1=$((echo $SUBNETS) | jq -r '.Subnets[0].SubnetId')
    export SUBNET_2=$((echo $SUBNETS) | jq -r '.Subnets[1].SubnetId')
    export SUBNET_3=$((echo $SUBNETS) | jq -r '.Subnets[2].SubnetId')
    ```

2. **AMI ID**: Run the following command to retrieve a AMI id.
    To learn more about the API, see [describe images](https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-images.html).

    ```
    export AMI_ID=$(aws ec2 describe-images --region "${AWS_REGION}" --filters Name=owner-alias,Values=amazon Name=architecture,Values=x86_64 Name=name,Values=amzn2-ami-hvm* | jq -r '.Images[0].ImageId')
    ```

3. **Instance type**: Run the following command to set instance type.
    For more information, see [instance
    types](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html).

    ```
    export INSTANCE_TYPE="c5.large"
    ```

**Create launch template**

Create a launch template from with sample launch parameters.
Check this [link](https://docs.aws.amazon.com/cli/latest/reference/ec2/create-launch-template.html) for additional launch parameters.

```bash
aws ec2 create-launch-template --launch-template-name TemplateForWebServer --version-description 1 --launch-template-data "{\"ImageId\":\"${AMI_ID}\",\"InstanceType\":\"${INSTANCE_TYPE}\"}"
```

**Example return**

```bash
{
    "LaunchTemplate": {
        "CreateTime": "2019-02-14T05:53:07.000Z",
        "LaunchTemplateName": "TemplateForWebServer",
        "DefaultVersionNumber": 1,
        "CreatedBy": "arn:aws:iam::123456789012:user/xxxxxxxx",
        "LatestVersionNumber": 1,
        "LaunchTemplateId": "lt-00ac79500cbd56d11"
    }
}
```

As the last step of this section, you retrieve the launch template id that was just created and store it in an environment variable. You use launch template id to create Auto Scaling group, EC2 Fleet, Spot Fleet and RunInstances.

```
export LAUNCH_TEMPLATE_ID=$(aws ec2 describe-launch-templates --filters Name=launch-template-name,Values=TemplateForWebServer | jq -r '.LaunchTemplates[0].LaunchTemplateId')
```

Well done! You have created a launch template and environment variables that you require in the next chapters.
