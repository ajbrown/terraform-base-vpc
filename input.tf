variable "vpc_cidr" {}

variable "name" {}

variable "region" {
  default = "us-east-1"
}

variable "assume_role" {
  description = "A role to assume for creating/updating the resources defined in this module."
  default = ""
}

variable "private_dns_tld" {
  description = "A TLD to use for private DNS within this VPC."
  default = ""
}

variable "availability_zones" {
  type = "list"
  description = <<DESC
  Create subnets in the provided availiability zones.  If blank, no subnets or related resources (such as routes, gateways, etc)
  will be created.
DESC

  default = []
}

variable "subnet_cidr_bits" {
  default = 20
  description = <<DESC
    The number of bits to use in the CIDRs for subnets that will be created
DESC
}

variable "enable_ipv6" {
  description = "Enable IPv6 (and create related resources where necessary)"
  default = false
}

variable "subnets_per_az" {
  description = "The number of subnets per AZ.  If private subnets are enabled, this number will apply to both."
  default = 1
}

variable "create_private_subnets" {
  description = "Create private subnets with NAT gateway for internet access.  Only created if create_subnets is also true."
  default = false
}

variable "create_database_subnets" {
  default = false
  description = "Create database subnets for use with RDS.  Private subnets will be used if `create_private_subets` is set to true."
}

variable "nat_gateway_per_az" {
  default = false
  description = <<DESC
    When set to true, a NAT gateway will be created per availability zone.  Otherwise, only 1 NAT gateway will be created for
    private networks.  This option has no effect if `created_private_subnets` is false.

    It's recommended that this be set to true on production networks for high availablility.
DESC

}

variable "create_s3_vpc_endpoint" {
  description = "Set to true if an S3 VPC Endpoint should be created for this VPC."
  default = false
}

variable "create_dynamodb_vpc_endpoint" {
  description = "Set to true if an DynamoDb VPC Endpoint should be created for this VPC."
  default = false
}
