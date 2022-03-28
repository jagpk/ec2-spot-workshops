---
title: "Spot Fleet"
weight: 3
chapter: false
pre: "<b>3. </b>"
include_toc: false
---

Spot Fleet is an API ideal for workloads that have a start and end (example batch workloads), specially when the workload requires you to have control over which instances to terminate in your own code. You can benefit from integrations with other services such as Load Balancer. However, if you are thinking about using Load Balancers, Auto Scaling groups are a better option.

Spot Fleet allows you to diversify across different AZs and networks. Unlike Auto Scaling Group, Spot Fleet does not re-balance instances across AZs. Use Auto Scaling groups instead if AZ-rebalance is key for your workload. Spot Fleet supports types `maintain` and `request`. Similar to Auto Scaling groups, the `maintain` type preserves the number of instances by replacing un-healthy instances.

:::alert{type=info}
To support mix instances with different types and purchasing options, Spot Fleet must use **Launch Templates**. In this exercise, you  re-use the same Launch Template that you created before.
:::

#### Spot Fleet example: Using weighted mixed instances with Spot Fleet for batch workloads

In this part of the workshop, you work on a common scenario that uses weights and target capacity. This maps well with the concept of 'Compute Slots' in the batch workloads. Some batch workloads can have more than one worker process running within an instance. Larger instances with weights can be included to allow multiple worker processes running on the same instance. For example, if one worker consumes 1 vCPU & 2GB RAM, then you can run up to 4 workers on a c5.xlarge (4 vCPUs & 8GB RAM) by assigning a weight of 4.

By default, the **Target Capacity** attribute for Spot Fleet defines the number of instances that the Spot Fleet procures. When you use Spot Fleet weights, and associate a custom weight with an instance in the override section, the total target capacity is equivalent to the total target of weights that you give to the spot. Going back to the "Compute Slots" or vCPUs analogy, you can instruct Spot Fleet to provide a number of vCPUs or "Compute Slots" from many instances with different sizes.


:::alert{type=info}
EC2 Auto Scaling group also supports weights and priorities similar to Spot Fleet and EC2 Fleet, therefore you can consider Auto Scaling group to run this type of workload.
:::


To start with the hands on part, you first need to create a *json* file that sets a few relevant Spot parameters; One of the parameters is `IamFleetRole`. `IamFleetRole` must be set up to point to the ARN of an IAM role that grants the Spot Fleet the permission to request, launch, terminate, and tag instances on your behalf. For this purpose, you are going to first retrieve the ARN of the Service-Linked role named `AWSServiceRoleForEC2SpotFleet`. For more information read the [spot fleet prerequisites](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-fleet-requests.html#spot-fleet-prerequisites).

:::alert{type=warning}
If you have never launched a Spot Fleet, the AWSServiceRoleForEC2SpotFleet won't exist in your account. To create it run the following command in AWS CloudShell: `aws iam create-service-linked-role --aws-service-name spotfleet.amazonaws.com`
:::

Execute the following command to export the ARN of the Service-Linked role to an environment variable.

```
export EC2_SPOT_ROLE=$(aws iam get-role --role-name AWSServiceRoleForEC2SpotFleet | jq -r '.Role.Arn')
```

Copy and paste the following in AWS CloudShell to generate the configuration file:

```
cat <<EoF > ~/spot-fleet-request-config.json
{
   "AllocationStrategy": "capacityOptimized",
   "OnDemandAllocationStrategy": "prioritized",
   "SpotMaintenanceStrategies": {
      "CapacityRebalance": {
         "ReplacementStrategy": "launch"
      }
   },
   "LaunchTemplateConfigs": [
      {
         "LaunchTemplateSpecification": {
            "LaunchTemplateId": "${LAUNCH_TEMPLATE_ID}",
            "Version": "1"
         },
         "Overrides":[
            {
               "InstanceType":"c5.large",
               "WeightedCapacity": 2.0,
               "Priority": 3.0
            },
            {
               "InstanceType":"m5.large",
               "WeightedCapacity": 2.0,
               "Priority": 2.0
            },
            {
               "InstanceType":"r5.large",
               "WeightedCapacity": 2.0,
               "Priority": 1.0
            },
            {
               "InstanceType":"c5.xlarge",
               "WeightedCapacity": 4.0,
               "Priority": 6.0
            },
            {
               "InstanceType":"m5.xlarge",
               "WeightedCapacity": 4.0,
               "Priority": 5.0
            },
            {
               "InstanceType":"r5.xlarge",
               "WeightedCapacity": 4.0,
               "Priority": 4.0
            }
         ]
      }
   ],
   "IamFleetRole": "${EC2_SPOT_ROLE}",
   "TargetCapacity": 12,
   "OnDemandTargetCapacity": 4,
   "TerminateInstancesWithExpiration": true,
   "Type": "maintain",
   "ReplaceUnhealthyInstances": true
}
EoF
```

Note, request file specifies the `TargetCapacity` and `OnDemandTargetCapacity`. The difference between the two values is equal to requested Spot capacity. To request only Spot capacity, set the `OnDemandTargetCapacity` to 0.

When `AllocationStrategy` is set to `capacityOptimized`, Spot Fleet launches instances from optimal Spot pools for the target capacity that you requested.

Spot Fleet provides Capacity Rebalance in response of Rebalance Recommendation signal, that EC2 emits when a Spot instance is at an elevated risk of being interrupted.

By specifying `maintain` as the request type, Spot Fleet places requests to meet the target capacity over time and automatically replenish any interrupted instances.

If you want to learn more about the other configuration parameters, you can review the documentation [here](https://docs.aws.amazon.com/cli/latest/reference/ec2/request-spot-fleet.html).

Once that you have familiarized yourself with the configuration, copy and paste this command to submit the Spot Fleet request and export its identifier to an environment variable.

```bash
export SPOT_FLEET_REQUEST_ID=$(aws ec2 request-spot-fleet --spot-fleet-request-config file://spot-fleet-request-config.json | jq -r '.SpotFleetRequestId')
```

You have now created a Spot Fleet that uses weights and combines Spot and On-Demand Instances to meet the specified target capacity.

Given the configuration you used above. **Try to answer the following questions:**

1. How many Spot vs On-Demand Instances have been requested by the Spot Fleet?
2. For On-Demand Capacity, what does it mean the `Priority` section?
3. How can you check the state of the created Spot Fleet?

{{%expand "Show me the answers:" %}}

1.) **How many Spot vs On-Demand Instances have been requested by the Spot Fleet?**

This Spot Fleet maintains a weighted target capacity of 12, as specified in the value for `TargetCapacity`. Additionally, you are specifying an On-Demand target capacity of 4. Remember that Amazon EC2 calculates the difference between the total capacity and On-Demand capacity in order to launch Spot Instances. This would result in **1** On-Demand Instance being launched and in the case of Spot Instances, given that you are using `capacityOptimized` allocation strategy, a few things may happen; the most common is that out of the 18 pools, one is selected as optimal (has more capacity, etc). If the selected pool is one of the 9 pools defined as **large**, 4 Spot Instances are added. If the pool selected is one of the 9 **xlarge**, 2 Spot Instances are created.

2.) **For On-Demand Capacity, what does it mean the `Priority` section?**

you did specify `prioritized` as the allocation strategy for On-Demand Instances. Therefore, the order in which Spot Fleet  attempt to fulfill the On-Demand capacity is defined by the value of `Priority` in the list of overrides. It aims first to launch capacity from the `c5.xlarge` pools with the highest priority. If there are [Insufficient Capacity Errors](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/troubleshooting-launch.html#troubleshooting-launch-capacity), it goes into the pools with the next higher priority `m5.xlarge`, and so on.  

For Spot, the `priority` attribute has no effect in the example. you have specified `capacityOptimized` as allocation strategy to follow the best practices associated with Spot. This makes the Spot Fleet launch instances from Spot Instance pools with optimal capacity.


3.) **How can you check the state of the Spot Fleet created?**

Below command provides us the description of the Spot Fleet Request

```
aws ec2 describe-spot-fleet-requests --spot-fleet-request-ids=$SPOT_FLEET_REQUEST_ID
```

To get the description of the instances and what happened over time to the request you can use:

```
aws ec2 describe-spot-fleet-instances --spot-fleet-request-id=$SPOT_FLEET_REQUEST_ID
```

There is also a `describe-spot-fleet-request-history` that showcases the steps the fleet took to procure the capacity. You can request it using the following command.

```
aws ec2 describe-spot-fleet-request-history --spot-fleet-request-id=$SPOT_FLEET_REQUEST_ID --start-time=$(date '+%m-%d-%YT%H:%M:%S' -d '-1 hour')
```


:::alert{type=info}
There is an allocation Strategy named `capacityOptimizedPrioritized`. What would be the results if you repeat the same exercise with this allocation strategy?
:::

{{% /expand %}}

#### Brief Summary of Spot Fleet functionality

These are some of the features and characteristics that Spot Fleet provides, in addition to the ones covered in this section:

1. **Control Spending**: With Spot Fleet you have finer granularity on how you specify the maximum price you are willing to pay. You can specify separately the maximum price per unit hour that you are willing to pay for a Spot or On-Demand Instance. You can also specify they maximum that you are willing to pay per hour for the fleet. Read more about [Spot Fleet Control Spending here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/how-spot-fleet-works.html#spot-fleet-control-spending)
2. **Valid from - until**: Spot Fleet allows also to define the duration for which the request is valid by providing the *from* and *until* values.
4. **Replace unhealthy instances**: Like in the case of Auto Scaling groups, when running in maintain mode you can instruct Spot Fleet to detect and replace un-healthy instances.
5. **Multiple Launch Templates**: Spot Fleet does allow you to specify multiple Launch Templates in the `LaunchTemplateConfigs` section of the configuration file. By doing so, you can launch a Spot Fleet with instances that vary by instance type, AMI, Availability Zone or subnet.
6. **Support for Load Balancers**: With Spot Fleet you can specify one or more Classic Load Balancers and target groups that is attached to the Spot Fleet request. To learn more about Classic Load Balancer, visit this page: [Classic Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/introduction.html). Consider however using Auto Scaling groups when using Load balancers.

You can read more about [Spot Fleet here, in the AWS Spot Fleet documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-fleet.html).
