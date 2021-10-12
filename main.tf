resource "aws_vpc" "vpc_a2" {
  cidr_block                       = "10.0.0.0/16"
  enable_dns_hostnames             = true
  enable_dns_support               = true
  enable_classiclink_dns_support   = true
  assign_generated_ipv6_cidr_block = true
  tags = {
    Name = "vpc_a2"
  }
}