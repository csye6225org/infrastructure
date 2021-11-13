//############################################
// Virtual Private Cloud
//############################################

// Virtual private cloud
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = "vpc"
  }
}

// Subnet
// There are 3 subnets, each in a seperate availability zone

resource "aws_subnet" "subnet1" {
  depends_on        = [aws_vpc.vpc]
  vpc_id            = aws_vpc.vpc.id
  availability_zone = keys(var.subnet_az_cidr_map)[0]
  cidr_block        = values(var.subnet_az_cidr_map)[0]
  tags = {
    Name = "subnet1"
  }
}
resource "aws_subnet" "subnet2" {
  depends_on        = [aws_vpc.vpc]
  vpc_id            = aws_vpc.vpc.id
  availability_zone = keys(var.subnet_az_cidr_map)[1]
  cidr_block        = values(var.subnet_az_cidr_map)[1]
  tags = {
    Name = "subnet2"
  }
}
resource "aws_subnet" "subnet3" {
  depends_on        = [aws_vpc.vpc]
  vpc_id            = aws_vpc.vpc.id
  availability_zone = keys(var.subnet_az_cidr_map)[2]
  cidr_block        = values(var.subnet_az_cidr_map)[2]
  tags = {
    Name = "subne3"
  }
}


// Internet Gateway
// For the Vpc

resource "aws_internet_gateway" "igw" {
  depends_on = [aws_vpc.vpc]
  vpc_id     = aws_vpc.vpc.id
  tags = {
    Name = "igw"
  }
}

// Route table
// This is a custom route table

resource "aws_route_table" "public_rt" {
  depends_on = [aws_vpc.vpc, aws_internet_gateway.igw]
  vpc_id     = aws_vpc.vpc.id
  route {
    cidr_block = var.rt_destination_cidr_block
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public_rt"
  }
}

// Route table association 
// Shows association in between subnets and public route table

resource "aws_route_table_association" "rta1" {
  depends_on     = [aws_subnet.subnet1, aws_route_table.public_rt]
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "rta2" {
  depends_on     = [aws_subnet.subnet2, aws_route_table.public_rt]
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "rta3" {
  depends_on     = [aws_subnet.subnet3, aws_route_table.public_rt]
  subnet_id      = aws_subnet.subnet3.id
  route_table_id = aws_route_table.public_rt.id
}

//############################################
// Security Groups
//############################################

// Load balancer security group

resource "aws_security_group" "alb_sg" {
  name   = "alb_sg"
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.source_cidr_block]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.source_cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "alb_sg"
  }
}


// Database Security Group

resource "aws_security_group" "database_sg" {
  name   = "database_sg"
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  tags = {
    Name = "database_sg"
  }
}

//############################################
// S3 Bucket
//############################################

// Random string for bucket name
resource "random_string" "randomstring" {
  length  = 10
  special = false
  upper   = false
}

// S3 Bucket
resource "aws_s3_bucket" "s3_bucket" {
  bucket        = format("%s.%s.%s", random_string.randomstring.result, var.enviornment, var.domain_name)
  force_destroy = true
  lifecycle_rule {
    enabled = true
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

// IAM role for S3 bucket
resource "aws_iam_role_policy" "s3_iam_role" {
  name       = "WebAppS3"
  role       = aws_iam_role.ec2_iam_role.id
  policy     = data.aws_iam_policy_document.s3_iam_policy_document.json
  depends_on = [aws_s3_bucket.s3_bucket]
}

// S3 IAM policy document
data "aws_iam_policy_document" "s3_iam_policy_document" {
  version = "2012-10-17"
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      "${aws_s3_bucket.s3_bucket.arn}",
      "${aws_s3_bucket.s3_bucket.arn}/*"
    ]
  }
  depends_on = [aws_s3_bucket.s3_bucket]
}


//############################################
// Relational Database
//############################################

resource "aws_db_parameter_group" "db_pg" {
  family = var.rds_family
}

resource "aws_db_subnet_group" "db_sg" {
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id, aws_subnet.subnet3.id]
  tags = {
    Name = "db_subnet_group"
  }
}

resource "aws_db_instance" "rds" {
  allocated_storage      = var.rds_allocated_storage
  engine                 = var.rds_engine
  engine_version         = var.rds_engine_version
  instance_class         = var.rds_db_instance_class
  multi_az               = var.rds_multi_az_allowance
  identifier             = var.rds_db_identifier
  username               = var.rds_db_username
  password               = var.rds_db_password
  db_subnet_group_name   = aws_db_subnet_group.db_sg.id
  parameter_group_name   = aws_db_parameter_group.db_pg.id
  publicly_accessible    = var.rds_db_public_accessibility
  name                   = var.rds_db_name
  skip_final_snapshot    = var.rds_db_skip_final_snapshot
  vpc_security_group_ids = [aws_security_group.database_sg.id]
}

//############################################
// EC2 Instance Ami, Role, Policy
//############################################

data "aws_ami" "shared_ami" {
  most_recent = true
  owners      = [var.dev_account_id]
}

resource "aws_iam_instance_profile" "ec2_iam_profile" {
  role = aws_iam_role.ec2_iam_role.name
}

// IAM role for EC2 Instance
resource "aws_iam_role" "ec2_iam_role" {
  name               = "EC2-CSYE6225"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17", 
  "Statement": [
    {
      "Action": "sts:AssumeRole", 
      "Effect": "Allow", 
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
    }
  ]
}
EOF
  tags = {
    "Name" = "EC2-CSYE6225"
  }
}


resource "aws_iam_policy" "CodeDeploy-EC2-S3" {
  name        = "CodeDeploy-EC2-S3"
  description = "Github actions application policy"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${var.ec2_env_code_deploy_bucket}",
        "arn:aws:s3:::${var.ec2_env_code_deploy_bucket}/*"
      ]
    }
  ]
}
EOF
  tags = {
    "Name" = "CodeDeploy-EC2-S3"
  }
}

resource "aws_iam_role_policy_attachment" "ec2_role_policy_attachment" {
  role       = aws_iam_role.ec2_iam_role.name
  policy_arn = aws_iam_policy.CodeDeploy-EC2-S3.arn
}


//############################################
// CodeDeploy Application
//############################################

resource "aws_codedeploy_app" "app" {
  name = "csye6225-webapp"
}
resource "aws_codedeploy_deployment_group" "example" {
  depends_on = [aws_codedeploy_app.app]

  app_name               = "csye6225-webapp"
  deployment_group_name  = "csye6225-webapp-deployment"
  service_role_arn       = aws_iam_role.CodeDeployServiceRole.arn
  deployment_config_name = "CodeDeployDefault.AllAtOnce"
  deployment_style {
    deployment_type   = "IN_PLACE"
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  ec2_tag_set {
    ec2_tag_filter {
      key  = "Name"
      type = "KEY_AND_VALUE"
      // value = "ec2"
      value = "asg"
    }
  }

  alarm_configuration {
    alarms  = ["my-alarm-name"]
    enabled = true
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = ["${aws_lb_listener.alb_listener.arn}"]
      }
      target_group {
        name = "${aws_lb_target_group.alb_tg.name}"
      }

    }
  }
  autoscaling_groups = ["${aws_autoscaling_group.asg.name}"]
}


resource "aws_iam_role" "CodeDeployServiceRole" {
  name        = "CodeDeployServiceRole"
  description = "Allows CodeDeploy to call AWS services on your behalf"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "codedeploy.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "codedeploy_role_policy_attachment" {
  role       = aws_iam_role.CodeDeployServiceRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}


//############################################
// Route 53
//############################################

data "aws_route53_zone" "primary" {
  name         = "${var.enviornment}.${var.domain_name}"
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "${var.enviornment}.${var.domain_name}"
  type    = "A"
  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = false
  }
}

//############################################
// Auto Scaling
//############################################

resource "aws_launch_configuration" "asg_launch_config" {
  name     = "asg_launch_config"
  image_id = data.aws_ami.shared_ami.id

  instance_type               = var.ec2_instance_type
  key_name                    = var.ec2_ssh_key_name
  associate_public_ip_address = var.ec2_public_ipv4_association_flag
  security_groups             = [aws_security_group.alb_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_iam_profile.id
  root_block_device {
    // device_name           = var.ec2_device_name
    delete_on_termination = var.ec2_delete_on_termination_flag
    volume_type           = var.ec2_volume_type
    volume_size           = var.ec2_volume_size
  }
  user_data = <<EOF
#!/bin/bash
echo "# App Environment Variables"
echo "export DB_HOST=${aws_db_instance.rds.address}" >> /etc/environment
echo "export DB_PORT=${aws_db_instance.rds.port}" >> /etc/environment
echo "export DB_DATABASE=${var.ec2_env_db_name}" >> /etc/environment
echo "export DB_USERNAME=${var.ec2_env_db_username}" >> /etc/environment
echo "export DB_PASSWORD=${var.ec2_env_db_password}" >> /etc/environment
echo "export FILESYSTEM_DRIVER=s3" >> /etc/environment
echo "export AWS_BUCKET_NAME=${aws_s3_bucket.s3_bucket.id}" >> /etc/environment
echo "export AWS_DEFAULT_REGION=${var.ec2_env_aws_region}" >> /etc/environment
echo "export CODE_DEPLOY_BUCKET=${var.ec2_env_code_deploy_bucket}" >> /etc/environment
chown -R ubuntu:www-data /var/www
usermod -a -G www-data ubuntu
              EOF
}

resource "aws_autoscaling_group" "asg" {
  desired_capacity     = 3
  max_size             = 5
  min_size             = 2
  default_cooldown     = 60
  launch_configuration = aws_launch_configuration.asg_launch_config.name
  target_group_arns    = ["${aws_lb_target_group.alb_tg.arn}"]
  vpc_zone_identifier  = [aws_subnet.subnet1.id, aws_subnet.subnet2.id, aws_subnet.subnet3.id]
  tag {
    key                 = "Name"
    value               = "asg"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "scale_up_policy" {
  name                   = "scale_up_policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_autoscaling_policy" "scale_down_policy" {
  name                   = "scale_down_policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_cloudwatch_metric_alarm" "cwm_scale_up" {
  alarm_name          = "cwm_scale_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "5"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
  alarm_description = "Apply scale_up_policy when CPUUtilization is >= 5%"
  alarm_actions     = [aws_autoscaling_policy.scale_up_policy.arn]
}

resource "aws_cloudwatch_metric_alarm" "cwm_scale_down" {
  alarm_name          = "cwm_down_up"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "3"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
  alarm_description = "Apply scale_down_policy when CPUUtilization is <= 3%"
  alarm_actions     = [aws_autoscaling_policy.scale_down_policy.arn]
}

//############################################
// Load Balancer
//############################################

resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id, aws_subnet.subnet3.id]
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.alb_tg.id
    type             = "forward"
  }
}

resource "aws_lb_target_group" "alb_tg" {
  name     = "alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 10
    timeout             = 3
    path                = "/"
  }
}
