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

// 3. 
// This will take CIDR Block 
// For destination in route in route table 
variable "rt_destination_cidr_block" {
  type        = string
  description = "Destination CIDR block for Route Table"
}