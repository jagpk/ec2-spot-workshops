#####################################################################################
# Terraform module examples are meant to show an _example_ on how to use a module
# per use-case. The code below should not be copied directly but referenced in order
# to build your own root module that invokes this module
#####################################################################################
data "aws_ami" "al3-ami" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*-x86_64-gp2"]
    
  }
}

module "prometheus-asg" {
  source  = "terraform-aws-modules/autoscaling/aws"

  # Autoscaling group
  name = "prometheus-asg"

  min_size                  = 1 
  max_size                  = 1
  desired_capacity          = 1
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  vpc_zone_identifier       =  module.emr-vpc.public_subnets

  # Launch template
  security_groups             = [aws_security_group.prometheus-allow-access.id]
  launch_template_name        = "prometheus-asg"
  launch_template_description = "Launch template prometheus"
  update_default_version      = true
  iam_instance_profile_arn  = aws_iam_instance_profile.prometheus_ec2_profile.arn
  user_data = filebase64("prometheus.sh")
  
  image_id          = "${data.aws_ami.al3-ami.id}"
  instance_type     = "m6i.large"
  ebs_optimized     = true
  enable_monitoring = true

  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = 100
        volume_type           = "gp3"
      }
    }
  ]

  target_group_arns = module.grafana-alb.target_group_arns

  tags = local.tags
}



module "grafana-alb" {
  source  = "terraform-aws-modules/alb/aws"

  name = "grafana-alb"

  load_balancer_type = "application"

  vpc_id             = module.emr-vpc.vpc_id
  subnets            = module.emr-vpc.public_subnets
  security_groups    = [aws_security_group.alb-allow-access.id]

  
  target_groups = [
    {
      name_prefix      = "grf-"
      backend_protocol = "HTTP"
      backend_port     = 3000
      target_type      = "instance"
      health_check = {
        path = "/login"
      }
    }
  ]

  http_tcp_listeners = [
    # Forward action is default, either when defined or undefined
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "forward"
      forward = {
        target_groups = [
          {
            target_group_index = 0
            weight             = 100
          }
        ]
      }
    }
  ]
  tags = local.tags
}

