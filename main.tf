// Virtual Private Cloud

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

// Application Security Group

resource "aws_security_group" "application_sg" {
  name   = "application_sg"
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.source_cidr_block]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.source_cidr_block]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.source_cidr_block]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
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
    Name = "application_sg"
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
    security_groups = [aws_security_group.application_sg.id]
  }
  tags = {
    Name = "database_sg"
  }
}

// S3 Bucket

resource "random_string" "randomstring" {
  length  = 10
  special = false
  upper   = false
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = format("%s.%s.%s", random_string.randomstring.result, var.enviornment, var.domain_name)
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

// Relational Database

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
  allocated_storage    = var.rds_allocated_storage
  engine               = var.rds_engine
  engine_version       = var.rds_engine_version
  instance_class       = var.rds_db_instance_class
  multi_az             = var.rds_multi_az_allowance
  identifier           = var.rds_db_identifier
  username             = var.rds_db_username
  password             = var.rds_db_password
  db_subnet_group_name = aws_db_subnet_group.db_sg.id
  parameter_group_name = aws_db_parameter_group.db_pg.id
  publicly_accessible  = var.rds_db_public_accessibility
  name                 = var.rds_db_name
  skip_final_snapshot  = var.rds_db_skip_final_snapshot
  vpc_security_group_ids = [aws_security_group.database_sg.id]
}

// EC2 Instance

resource "aws_instance" "ec2" {
  ami                     = var.ec2_source_ami
  instance_type           = var.ec2_instance_type
  security_groups         = [aws_security_group.application_sg.id]
  depends_on              = [aws_db_instance.rds]
  subnet_id               = aws_subnet.subnet1.id
  // disable_api_termination = var.ec2_disable_api_termination_flag
  associate_public_ip_address = var.ec2_public_ipv4_association_flag
  key_name = var.ec2_ssh_key_name
  ebs_block_device {
    device_name           = var.ec2_device_name
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
echo "export AWS_BUCKET=${aws_s3_bucket.s3_bucket.id}" >> /etc/environment
echo "export S3_BUCKET_NAME=${aws_s3_bucket.s3_bucket.bucket}" >> /etc/enviornment
echo "export AWS_DEFAULT_REGION=${var.ec2_env_aws_region}" >> /etc/environment
echo "export AWS_ACCESS_KEY=${var.ec2_env_aws_access_key}" >> /etc/environment
echo "export AWS_SECRET_ACCESS_KEY=${var.ec2_env_aws_secret_access_key}" >> /etc/environment
chown -R ubuntu:www-data /var/www
usermod -a -G www-data ubuntu
              EOF

  tags = {
    "Name" = "ec2"
  }
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

// IAM role for S3 bucket
resource "aws_iam_role_policy" "s3_iam_role" {
  name       = "WebAppS3"
  role       = aws_iam_role.ec2_iam_role.id
  policy     = data.aws_iam_policy_document.s3_iam_policy_document.json
  depends_on = [aws_s3_bucket.s3_bucket]
}