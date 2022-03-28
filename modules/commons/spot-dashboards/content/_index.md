---
title = "Spot Dashboards"
weight = 80
---

## Savings Summary
In previous chapters, you launched a number of Spot instances and now must be curious to find out the how much you really saved. 

You can check the Spot savings by going to the [Savings Summary](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-savings.html) dashboard, to view your savings:

1. Open the Amazon EC2 console at <https://console.aws.amazon.com/ec2/>.
2. In the navigation pane, choose **Spot Requests**.
3. In the top right corner of the screen, select **Savings summary**

![Savings summary](/images/spot-savings.png)

## Pricing history 

Pricing history helps you to understand how the Spot price changes over time, to view the Spot price history (console):

1. Open the Amazon EC2 console at <https://console.aws.amazon.com/ec2/>.
2. In the navigation pane, choose **Spot Requests**.
3. Choose **Pricing history** in the top right corner.

![Pricing history](/images/spot-instance-pricing-history.png)

If you are interested in how to use the Spot API programmatically, You can use the **[describe-spot-price-history](https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-spot-price-history.html)** API to retrieve the information you need.

## Spot Instance interruptions dashboard

[ec2-spot-interruption-dashboard](https://github.com/aws-samples/ec2-spot-interruption-dashboard) can be used as the initial point to understand which Spot Instances are being terminated and adjust your configuration by increasing instance diversification.