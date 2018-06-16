provider "aws" {
  # Switch to the role that can manage resources in your account.  Note that this should be different than the central
  # sonatype-ops account that you call this module from.

  region = "${var.region}"

  assume_role {
    role_arn = "${var.assume_role}"
  }
}

locals {
  create_private_hostedzone = "${signum(length(var.private_dns_tld))}"

}


data "aws_availability_zones" "available" {
  # The list of AZs actually used are provided as input.  This lookup is simply so we can determine the appropriate
  # spacing for the subnets that are created to prevent CIDR collisions if AZs are added later.
}

resource "aws_vpc" "main" {
  cidr_block                       = "${var.vpc_cidr}"
  enable_dns_hostnames             = true
  enable_dns_support               = true
  assign_generated_ipv6_cidr_block = "${var.enable_ipv6}"

  tags {
    Name           = "${var.name}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name           = "${var.name}-main-gw"
  }
}

resource "aws_egress_only_internet_gateway" "main" {
  count   = "${signum(var.enable_ipv6)}"
  vpc_id  = "${aws_vpc.main.id}"
}

/**
 * Private Hostname Resolution
 */
resource "aws_route53_zone" "internal" {
  count  = "${local.create_private_hostedzone}"
  name   = "${var.private_dns_tld}"
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_route53_zone_association" "local_internal" {
  count   = "${local.create_private_hostedzone}"
  vpc_id  = "${aws_vpc.main.id}"
  zone_id = "${aws_route53_zone.internal.id}"
}
