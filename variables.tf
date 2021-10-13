variable "vpc_cidr_block" {
  type        = string
  description = "CIDR for VPC"
}

// variable "subnet_cidr_block"{
//     type = "String"
//     description = "CIDR for Subnet"
// }

variable "subnet_az_cidr" {
  type        = map(string)
  description = "Availability zone to CIDR map for subnet"
}