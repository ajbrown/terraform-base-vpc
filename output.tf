output "vpc" {
  value = {
    id        = "${aws_vpc.main.id}",
    cidr      = "${aws_vpc.main.cidr_block}",
    ipv6_cidr = "${aws_vpc.main.ipv6_cidr_block}"
  }
}

output "public_subnet_ids" {
  value = "${aws_subnet.public.*.id}"
}

output "private_subnet_ids" {
  value = "${aws_subnet.private.*.id}"
}

output "main_route_table" {
  value = {
    id = "${aws_route_table.main.id}"
  }
}

output "private_route_tables" {
  value = "${list(aws_route_table.private.*.id)}"
}

output "private_hosted_zone" {
  value = {
    id   = "${element(aws_route53_zone.internal.*.id,0)}",
    name = "${element(aws_route53_zone.internal.*.name,0)}"
  }
}

output "internet_gateway_id" {
  value = "${aws_internet_gateway.main.id}"
}

output "nat_gateway_ids" {
  value = "${zipmap(local.selected_azs_collated,list(aws_nat_gateway.main.*.id))}"
}

output "nat_gateway_public_ips" {
  value = "${zipmap(local.selected_azs_collated,list(aws_nat_gateway.main.*.public_ip))}"
}

output "nat_gateway_private_ips" {
  value = "${zipmap(local.selected_azs_collated,list(aws_nat_gateway.main.*.private_ip))}"
}

output "aws_internet_route_id" {
  value = {
    public = "${aws_route.internet_public.id}"
    private_ipv6 = "${element(aws_route.internet_private_ipv6.*.id,0)}"
    private_ipv4 = "${element(aws_route.internet_private_ipv4.*.id,0)}"
  }
}

output "vpc_endpoint_ids" {
  value = {
    s3 = "${element(aws_vpc_endpoint.s3.*.id,0)}",
    dynamodb = "${element(aws_vpc_endpoint.dynamodb.*.id,0)}"
  }
}

output "vpc_endpoint_dns" {
  value = {
    s3 = "${element(aws_vpc_endpoint.s3.*.dns_entry,0)}",
    dynamodb = "${element(aws_vpc_endpoint.dynamodb.*.dns_entry,0)}"
  }
}

