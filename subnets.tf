locals {
  num_private_subnets = "${length(var.availability_zones) * signum(var.create_private_subnets) * var.subnets_per_az}"
  num_public_subnets  = "${length(var.availability_zones) * var.subnets_per_az}"
  num_nat_gateways    = "${signum(length(var.availability_zones)) * signum(var.create_private_subnets) * max(1,signum(var.nat_gateway_per_az) * length(var.availability_zones))}"
  num_azs             = "${length(var.availability_zones)}"

  # A sorted list of the availability zones, just in case.
  all_azs_collated = "${sort(data.aws_availability_zones.available.names)}"

  # A list of AZs that were selected
  selected_azs_collated = "${matchkeys(local.all_azs_collated, local.all_azs_collated, var.availability_zones)}"

  # Get an index number for the requested availability zones against the list of available AZs.  We use this to make
  # sure we leave room for subnets in the non-selected AZs incase they are added in later.
  az_index = "${matchkeys(keys(local.all_azs_collated), local.all_azs_collated, local.selected_azs_collated)}"

  # Determine the number of subnet bits in the provided CIDR.  This is used to determine the spacing for the subnets
  # we'll created.  We'll "balance" them amongs the available
  vpc_cidr_bits = "${element(split("/",var.vpc_cidr),1)}"

  # The number of NEW bits to add to the VPC CIDR to get the subnet CIDR. Needed for the function that calculates subnet
  # cidrs.
  subnet_cidr_new_bits = "${var.subnet_cidr_bits - local.vpc_cidr_bits}"

  # Determine the spacing we'll use for the subnet CIDRs we select, based on the number of AZs in this region and
  # the number of subnets available for the given CIDR
  possible_subnets = "${pow(2,var.subnet_cidr_bits)}"

  # How many of the possible subnets will be "reserved" for each possible availability zone.  This allows increasing the
  # number of subnets per AZ without clobbeering previously existing CIDRs
  subnet_az_spacing = "${floor(local.possible_subnets / min(3,length(data.aws_availability_zones.available.names)))}"

  # Private subnets will be created on the "back half" of the subnets reserved for each availability zone. This allows
  # enabling private subnets without clobbering previously created public subnets.
  private_subnet_offset = "${ceil(local.subnet_az_spacing / 2)}"
}

resource "aws_subnet" "public" {
  count                           = "${local.num_public_subnets}"
  cidr_block = "${cidrsubnet(aws_vpc.main.cidr_block, local.subnet_cidr_new_bits, (local.subnet_az_spacing * local.az_index[count.index % local.num_azs]) + (count.index % local.num_public_subnets))}"
  vpc_id                          = "${aws_vpc.main.id}"
  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = "${var.enable_ipv6}"
  availability_zone               = "${local.selected_azs_collated[var.subnets_per_az % count.index]}"

  tags {
    Name = "${var.name}-public-${local.selected_azs_collated[var.subnets_per_az % count.index]}"
    Type = "public"
  }
}

resource "aws_subnet" "private" {
  count                           = "${local.num_private_subnets}"
  cidr_block                      = "${cidrsubnet(aws_vpc.main.cidr_block, local.subnet_cidr_new_bits, (local.subnet_az_spacing * local.az_index[count.index % local.num_azs]) + (count.index % local.num_public_subnets) + local.private_subnet_offset)}"
  vpc_id                          = "${aws_vpc.main.id}"
  availability_zone               = "${local.selected_azs_collated[var.subnets_per_az % count.index]}"
  map_public_ip_on_launch         = false
  assign_ipv6_address_on_creation = "${var.enable_ipv6}"

  tags {
    Name = "${var.name}-private-${var.availability_zones[var.subnets_per_az % count.index]}"
    Type = "private"
  }
}

resource "aws_eip" "nat" {
  count = "${local.num_nat_gateways}"

  tags {
    Name        = "${var.name}-natgw-${local.selected_azs_collated[count.index]}"
    Environment = "${var.name}"
    Purpose     = "NAT Gateway"
  }
}

resource "aws_nat_gateway" "main" {
  count           = "${local.num_nat_gateways}"
  allocation_id   = "${element(aws_eip.nat.*.allocation_id, count.index)}"
  subnet_id       = "${element(aws_subnet.public.*.id, count.index * local.num_azs)}"

  tags {
    Name        = "${var.name} NAT Gateway"
    Environment = "${var.name}"
  }
}


locals {
  private_subnet_to_az = "${zipmap(aws_subnet.private.*.id,aws_subnet.private.*.availability_zone)}"
}
