
// Virtual Private Cloud
resource "aws_vpc" "vpc" {
  cidr_block                       = var.vpc_cidr_block
  enable_dns_hostnames             = true
  enable_dns_support               = true
  enable_classiclink_dns_support   = true
  assign_generated_ipv6_cidr_block = false

  tags = {
    Name = "vpc"
  }
}

// Subnet
// There are 3 subnets, each in a seperate availability zone
// The depends on specifies an explicit dependency of these subnets on vpc
resource "aws_subnet" "subnet" {

  depends_on = [aws_vpc.vpc]

  vpc_id = aws_vpc.vpc.id

  for_each          = var.subnet_az_cidr
  availability_zone = each.key
  cidr_block        = each.value

  tags = {
    Name = "subnet"
  }
}

// Internet Gateway
// For the Vpc
resource "aws_internet_gateway" "igw" {

  depends_on = [aws_vpc.vpc]

  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "igw"
  }
}

// Route table
// This is a custom route table
// Has  route in between every IPv4 addresses and 
// Internet gateway
resource "aws_route_table" "public_rt" {

  depends_on = [aws_vpc.vpc, aws_internet_gateway.igw]

  vpc_id = aws_vpc.vpc.id

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
// Destination: Subnet
// Target: Route table
resource "aws_route_table_association" "rta" {

  for_each = var.subnet_az_cidr

  subnet_id      = aws_subnet.subnet[each.key].id
  route_table_id = aws_route_table.public_rt.id

  depends_on = [aws_subnet.subnet, aws_route_table.public_rt]

}