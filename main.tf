resource "aws_vpc" "vpc_a2" {
  cidr_block                       = var.vpc_cidr_block
  enable_dns_hostnames             = true
  enable_dns_support               = true
  enable_classiclink_dns_support   = true
  assign_generated_ipv6_cidr_block = false

  tags = {
    Name = "vpc_a2"
  }
}

resource "aws_subnet" "subnet_a2" {

  // Specifying an explicit dependency of this subnet on vpc 
  depends_on = [aws_vpc.vpc_a2]

  vpc_id = aws_vpc.vpc_a2.id

  for_each          = var.subnet_az_cidr
  availability_zone = each.key
  cidr_block        = each.value

  tags = {
    Name = "subnet_a2"
  }
}

resource "aws_internet_gateway" "igw_a2" {
  vpc_id = aws_vpc.vpc_a2.id

  tags = {
    Name = "igw_a2"
  }
}