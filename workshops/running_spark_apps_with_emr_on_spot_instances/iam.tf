#####################################################################################
# Terraform module examples are meant to show an _example_ on how to use a module
# per use-case. The code below should not be copied directly but referenced in order
# to build your own root module that invokes this module
#####################################################################################
#### IAM Role setups


# IAM role for EMR Service
resource "aws_iam_role" "iam_emr_service_role" {
  name = "iam_emr_service_role"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "elasticmapreduce.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "emr-service-attach-v1" {
  name       = "emr-service-attach"
  roles      = [aws_iam_role.iam_emr_service_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceRole"
}

resource "aws_iam_policy_attachment" "emr-service-attach-v2" {
  name       = "emr-service-attach"
  roles      = [aws_iam_role.iam_emr_service_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEMRServicePolicy_v2"
}

resource "aws_iam_role_policy" "iam_emr_ec2_service_policy" {
  name = "iam_emr_profile_policy"
  role = aws_iam_role.iam_emr_service_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Resource": "*",
        "Action": [
            "ec2:*"
        ]
    }]
}
EOF
}

# IAM Role for EC2 Instance Profile
resource "aws_iam_role" "iam_emr_ec2_role" {
  name = "iam_emr_ec2_role"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


resource "aws_iam_policy_attachment" "emr-ec2-attach" {
  name       = "emr-ec2-attach"
  roles      = [aws_iam_role.iam_emr_ec2_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceforEC2Role"
}

resource "aws_iam_role_policy" "iam_emr_ec2_policy" {
  name = "iam_emr_profile_policy"
  role = aws_iam_role.iam_emr_ec2_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Resource": "*",
        "Action": [
            "elasticmapreduce:List*"
        ]
    }]
}
EOF
}

resource "aws_iam_instance_profile" "emr_ec2_profile" {
  name = "emr_profile"
  role = aws_iam_role.iam_emr_ec2_role.name
}


# IAM Role for EC2 Instance Profile Prometheus
resource "aws_iam_role" "prometheus_ec2_role" {
  name = "prometheus_ec2_role"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "prometheus_ec2_policy" {
  name = "prometheus_ec2_policy"
  role = aws_iam_role.prometheus_ec2_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Resource": "*",
        "Action": [
            "ec2:Describe*",
            "sts:Get*",
            "s3:*"
        ]
    }]
}
EOF
}

resource "aws_iam_instance_profile" "prometheus_ec2_profile" {
  name = "prometheus_ec2_profile"
  role = aws_iam_role.prometheus_ec2_role.name
}