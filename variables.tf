// 1.
// This will take String of
// CIDR block for the VPC
variable "vpc_cidr_block" {
  type        = string
  description = "CIDR for VPC"
}

// 2.
// This will take Map of 
// Availability Zones as Key
// CIDR block for Subnet as Value
variable "subnet_az_cidr" {
  type        = map(string)
  description = "Availability zone to CIDR map for subnet"
}