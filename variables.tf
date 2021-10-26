// ############################################
//  Network Variables
// ############################################

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block for VPC"
}
variable "subnet_az_cidr_map" {
  type        = map(string)
  description = "Availability zone to CIDR map for subnet"
}
variable "rt_destination_cidr_block" {
  type        = string
  description = "Destination CIDR block for Route Table"
}
variable "source_cidr_block"{
  type = string
  description = "Source CIDR block for Application security group"
}
variable "enviornment" {
  type        = string
  description = "Enviornment in which we are working, dev or prod"
}
variable "domain_name" {
  type        = string
  description = "My domain name, eg. example.com"
}

// ############################################
//  Database Variables
// ############################################

variable "rds_family"{
  type = string
  description = "Database parameter group family"
}
variable "rds_allocated_storage" {
  type        = number
  description = "Allocated storage for database"
}
variable "rds_engine" {
  type        = string
  description = "Database engine"
}
variable "rds_engine_version" {
  type        = number
  description = "Database Engine version"
}
variable "rds_db_instance_class" {
  type        = string
  description = "Database Instance Class"
}
variable "rds_multi_az_allowance" {
  type        = bool
  description = "Allowance for multi az deployment"
}
variable "rds_db_identifier" {
  type        = string
  description = "Database Identifier"
}
variable "rds_db_username" {
  type        = string
  description = "Database Username"
}
variable "rds_db_password" {
  type        = string
  description = "Database password"
}
variable "rds_db_public_accessibility" {
  type        = bool
  description = "Allowance for database to be publicly accessible"
}
variable "rds_db_name" {
  type        = string
  description = "Database name"
}
variable "rds_db_skip_final_snapshot" {
  type        = bool
  description = "Allowance for skipping final snapshot creation"
}

// ############################################
//  Ec2 Instance Variables
// ############################################

variable "ec2_source_ami" {
  type        = string
  description = "Source Ami for EC2"
}
variable "ec2_instance_type" {
  type        = string
  description = "EC2 Instance type"
}
variable "ec2_disable_api_termination_flag"{
  type        = bool
  description = "Disable api termination flag"
}
variable "ec2_public_ipv4_association_flag"{
  type = bool
  description = "Associate public Ipv4 flag"
}
variable "ec2_ssh_key_name"{
  type = string
  description = "SSH key name to connect with Ec2 instance"
}
variable "ec2_device_name" {
  type        = string
  description = "EC2 Device name"
}
variable "ec2_delete_on_termination_flag"{
  type        = bool
  description = "EBS block delete on termination flag"
}
variable "ec2_volume_type"{
  type        = string
  description = "EBS block volume type"
}
variable "ec2_volume_size"{
  type        = number
  description = "EBS block volume size"
}

// ############################################
//  Ec2 Instance Enviornment Variables
// ############################################

variable "ec2_env_db_name"{
  type = string
  description = "Database name in AWS RDS"
}
variable "ec2_env_db_username"{
  type = string
  description = "Database username in AWS RDS"
}
variable "ec2_env_db_password"{
  type = string
  description = "Database password in AWS RDS"
}
variable "ec2_env_aws_region"{
  type = string
  description = "AWS Region"
}
variable "ec2_env_aws_access_key"{
  type = string
  description = "AWS access key"
}
variable "ec2_env_aws_secret_access_key"{
  type = string
  description = "AWS secret access key"
}

