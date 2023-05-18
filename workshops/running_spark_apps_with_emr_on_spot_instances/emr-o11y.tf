#####################################################################################
# Terraform examples are meant to show an _example_ on how to use a resource or module
# per use-case. The code below should not be copied directly but referenced in order
# to build your own terraform code.
#####################################################################################

module "s3-log-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"

  bucket_prefix = "emr-logging-"

  # Allow deletion of non-empty bucket
  # Example usage only - not recommended for production
  force_destroy = true

  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = local.tags
}

module "s3-code-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"

  bucket_prefix = "emr-code-"

  # Allow deletion of non-empty bucket
  # Example usage only - not recommended for production
  force_destroy = true

  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = local.tags
}

resource "aws_emr_cluster" "cluster-6x" {
  name          = local.emr-name 
  release_label = "emr-6.10.0"
  applications  = ["Hadoop","Spark", "Ganglia"]

  ec2_attributes {
    subnet_id                         = module.emr-vpc.public_subnets[0]
    additional_master_security_groups = aws_security_group.emr-allow-access.id
    additional_slave_security_groups  = aws_security_group.emr-allow-access.id
    instance_profile                  = aws_iam_instance_profile.emr_ec2_profile.arn
  }
  
master_instance_group {
    instance_type = "m5.xlarge"
  }

  core_instance_group {
    instance_type  = "m5.4xlarge"
    instance_count = 1
    bid_price = "4.00"
    
    ebs_config {
      size                 = "100"
      type                 = "gp2"
      volumes_per_instance = 1
    }
  }
  
  tags = {
    Name     = "emr-6.x"
    application = "hadoop"
  }

  ebs_root_volume_size = 50

  log_uri = "s3://${module.s3-log-bucket.s3_bucket_id}/elasticmapreduce/"

  # ... bootstrap action to set up jmx exporter for HDFS ...
  
  bootstrap_action {
    path = "s3://aws-bigdata-blog/artifacts/aws-blog-emr-prometheus-grafana/scripts/bootstrap_monitoring_6_series.sh"
    name = "Configure cluster"
  }

  configurations_json = <<EOF
  [
    {
      "Classification": "hadoop-env",
      "Configurations": [
        {
          "Classification": "export",
          "Properties": {
            "HADOOP_NAMENODE_OPTS": "\"-javaagent:/etc/prometheus/jmx_prometheus_javaagent-0.13.0.jar=7001:/etc/hadoop/conf/hdfs_jmx_config_namenode.yaml -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.port=50103\"",
            "HADOOP_DATANODE_OPTS": "\"-javaagent:/etc/prometheus/jmx_prometheus_javaagent-0.13.0.jar=7001:/etc/hadoop/conf/hdfs_jmx_config_datanode.yaml -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.port=50103\""
          }
        }
      ],
      "Properties": {}
    }
]
EOF


  # ... other configuration ...
  service_role = aws_iam_role.iam_emr_service_role.arn

  
  step {
    action_on_failure = "TERMINATE_CLUSTER"
    name              = "Setup Hadoop Debugging"

    hadoop_jar_step {
      jar  = "command-runner.jar"
      args = ["state-pusher-script"]
    }
  }
  
  step_concurrency_level = 5
  # Optional: ignore outside changes to running cluster steps
  lifecycle {
    ignore_changes = [step]
  }
}


resource "aws_s3_object" "upload-to-emr-code-bucket" {
  for_each = fileset("./scripts/", "**")
  bucket = module.s3-code-bucket.s3_bucket_id
  key = each.value
  source = "./scripts/${each.value}"
  etag = filemd5("./scripts/${each.value}")
}