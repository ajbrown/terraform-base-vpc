
/**
 * PrivateLink VPC Endpoints
 *
 * If enabled, create VPC endpoints which allow private communication with AWS
 * services.  Currently only S3 and DynamoDb are supported by this module.
 */

resource "aws_vpc_endpoint" "s3" {
  count        = "${signum(var.create_s3_vpc_endpoint)}"
  vpc_id       = "${aws_vpc.main.id}"
  service_name = "com.amazonaws.${var.region}.s3"
}

resource "aws_vpc_endpoint_route_table_association" "s3_public" {
  count           = "${signum(var.create_s3_vpc_endpoint)}"
  route_table_id  = "${aws_route_table.main.id}"
  vpc_endpoint_id = "${aws_vpc_endpoint.s3.id}"
}

resource "aws_vpc_endpoint_route_table_association" "s3_private" {
  count           = "${signum(var.create_s3_vpc_endpoint) * local.num_route_tables}"
  route_table_id  = "${element(aws_route_table.private.id,count.index)}"
  vpc_endpoint_id = "${aws_vpc_endpoint.s3.id}"
}

resource "aws_vpc_endpoint" "dynamodb" {
  count        = "${signum(var.create_dynamodb_vpc_endpoint)}"
  vpc_id       = "${aws_vpc.main.id}"
  service_name = "com.amazonaws.${var.region}.dynamodb"
}

resource "aws_vpc_endpoint_route_table_association" "dynamodb_public" {
  count           = "${signum(var.create_dynamodb_vpc_endpoint)}"
  route_table_id  = "${aws_route_table.main.id}"
  vpc_endpoint_id = "${aws_vpc_endpoint.dynamodb.id}"
}

resource "aws_vpc_endpoint_route_table_association" "dynamodb_private" {
  count           = "${signum(var.create_dynamodb_vpc_endpoint) * local.num_route_tables}"
  route_table_id  = "${element(aws_route_table.private.id,count.index)}"
  vpc_endpoint_id = "${aws_vpc_endpoint.dynamodb.id}"
}
