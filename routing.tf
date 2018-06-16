
locals {
  num_route_tables = "${max(1,signum(var.nat_gateway_per_az) * length(var.availability_zones))}"
  egress_only_gateway = "${signum(var.enable_ipv6) * signum(var.create_private_subnets)}"
}

resource "aws_route_table" "main" {
  # Main route table, default for new subnets which don't specify their own
  # route table.  Routing to the internet will be provided.  If you create
  # a subnet which should _not_ have direct access to the internet,
  # you'll need to create another routing table an associate the subnet with it.
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name           = "${var.name}-main-routes"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_main_route_table_association" "main" {
  vpc_id         = "${aws_vpc.main.id}"
  route_table_id = "${aws_route_table.main.id}"
}

resource "aws_route_table" "private" {
  # Private route table, for subnets which should not be publicly addressable and routable.

  count  = "${local.num_route_tables}"
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name        = "${var.name}-private"
    Type        = "private"
    Environment = "${var.name}"
    AvailabilityZone = "${element(local.selected_azs_collated,count.index)})}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table_association" "private" {
  count          = "${local.num_private_subnets}"
  route_table_id = "${element(aws_route_table.private.*.id,index(local.selected_azs_collated,element(aws_subnet.private.*.availability_zone, count.index)))}"
  subnet_id      = "${element(aws_subnet.private.*.id,count.index)}"
}

resource "aws_route" "internet_public" {
  # Provides a route to the internet through the main gateway.
  route_table_id              = "${aws_route_table.main.id}"
  destination_cidr_block      = "0.0.0.0/0"
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = "${aws_internet_gateway.main.id}"
}

resource "aws_route" "internet_private_ipv4" {
  count                  = "${local.num_route_tables}"
  route_table_id         = "${element(aws_route_table.private.id,count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.main.*.id,max(1,signum(var.nat_gateway_per_az) * count.index))}"
}

resource "aws_route" "internet_private_ipv6" {
  count                       = "${local.egress_only_gateway * local.num_route_tables}"
  route_table_id              = "${element(aws_route_table.private.id,count.index)}"
  egress_only_gateway_id      = "${aws_egress_only_internet_gateway.main.id}"
  destination_ipv6_cidr_block = "::/0"
}


locals {

}
