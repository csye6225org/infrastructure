resource "aws_vpc" "vpc_a2" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc_a2"
  }
}