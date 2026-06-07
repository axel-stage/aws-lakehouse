locals {
  az_a = element(data.aws_availability_zones.available.names, 0)
  az_b = element(data.aws_availability_zones.available.names, 1)
}

###############################################################################
# vpc

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name                                     = "${var.project}-${var.environment}-vpc"
    for-use-with-amazon-emr-managed-policies = "true"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name                                     = "${var.project}-${var.environment}-igw"
    for-use-with-amazon-emr-managed-policies = "true"
  }
}

resource "aws_eip" "this" {
  domain = "vpc"
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.this.id
  subnet_id     = aws_subnet.public_az_a.id

  tags = {
    Name                                     = "${var.project}-${var.environment}-natgw"
    for-use-with-amazon-emr-managed-policies = "true"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.this]
}

###############################################################################
# subnet

resource "aws_subnet" "public_az_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = element(var.public_subnets, 0)
  availability_zone       = local.az_a
  map_public_ip_on_launch = true

  tags = {
    Name                                     = "${var.project}-${var.environment}-subnet-public-${local.az_a}"
    for-use-with-amazon-emr-managed-policies = "true"
  }
}

resource "aws_subnet" "private_az_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = element(var.private_subnets, 0)
  availability_zone       = local.az_a
  map_public_ip_on_launch = false

  tags = {
    Name                                     = "${var.project}-${var.environment}-subnet-private-${local.az_a}"
    for-use-with-amazon-emr-managed-policies = "true"
  }
}

resource "aws_subnet" "public_az_b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = element(var.public_subnets, 1)
  availability_zone       = local.az_b
  map_public_ip_on_launch = true

  tags = {
    Name                                     = "${var.project}-${var.environment}-subnet-public-${local.az_b}"
    for-use-with-amazon-emr-managed-policies = "true"
  }
}

resource "aws_subnet" "private_az_b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = element(var.private_subnets, 1)
  availability_zone       = local.az_b
  map_public_ip_on_launch = false

  tags = {
    Name                                     = "${var.project}-${var.environment}-subnet-private-${local.az_b}"
    for-use-with-amazon-emr-managed-policies = "true"
  }
}

###############################################################################
# routing

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project}-${var.environment}-public-rt"
  }
}
resource "aws_route_table_association" "public_az_a" {
  subnet_id      = aws_subnet.public_az_a.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_az_b" {
  subnet_id      = aws_subnet.public_az_b.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.this.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project}-${var.environment}-private-rt"
  }
}
resource "aws_route_table_association" "private_az_a" {
  subnet_id      = aws_subnet.private_az_a.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "private_az_b" {
  subnet_id      = aws_subnet.private_az_b.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  nat_gateway_id         = aws_nat_gateway.this.id
  destination_cidr_block = "0.0.0.0/0"
}

###############################################################################
# endpoints

# resource "aws_vpc_endpoint" "kinesis_streams" {
#   vpc_id       = aws_vpc.this.id
#   service_name = "com.amazonaws.${data.aws_region.current.region}.kinesis-streams"

#   vpc_endpoint_type   = "Interface"
#   private_dns_enabled = true
#   subnet_ids         = [aws_subnet.private_az_a.id, aws_subnet.private_az_b.id]
#   security_group_ids = [aws_default_security_group.default.id]

#   tags = {
#     Name = "databricks-kinesis-streams-vpc-endpoint"
#   }
# }

# resource "aws_vpc_endpoint" "glue" {
#   vpc_id            = aws_vpc.this.id
#   service_name      = "com.amazonaws.${data.aws_region.current.region}.glue"
#   vpc_endpoint_type = "Interface"

#   subnet_ids = [
#     aws_subnet.private_az_a.id,
#     aws_subnet.private_az_b.id
#   ]

#   security_group_ids = [
#     aws_security_group.glue_endpoint.id
#   ]
#   private_dns_enabled = true

#   tags = {
#     Name                                     = "${var.project}-${var.environment}-glue-vpc-endpoint"
#     for-use-with-amazon-emr-managed-policies = "true"
#   }
# }

# resource "aws_vpc_endpoint" "sts" {
#   vpc_id            = aws_vpc.this.id
#   service_name      = "com.amazonaws.${data.aws_region.current.region}.sts"
#   vpc_endpoint_type = "Interface"

#   subnet_ids = [
#     aws_subnet.private_az_a.id,
#     aws_subnet.private_az_b.id
#   ]

#   security_group_ids = [
#     aws_security_group.sts_endpoint.id
#   ]

#   private_dns_enabled = true

#   tags = {
#     Name                                     = "${var.project}-${var.environment}-sts-vpc-endpoint"
#     for-use-with-amazon-emr-managed-policies = "true"
#   }
# }

###############################################################################
# vpc endpoints

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  route_table_ids   = [aws_route_table.public.id, aws_route_table.private.id]
  #route_table_ids   = [aws_route_table.private.id]

  tags = {
    Name = "${var.project}-${var.environment}-s3-vpc-endpoint"
    for-use-with-amazon-emr-managed-policies = "true"
  }
}

resource "aws_vpc_endpoint" "glue" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.glue"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private_az_a.id,
    aws_subnet.private_az_b.id
  ]

  security_group_ids = [
    aws_security_group.vpc_endpoint.id
  ]

  tags = {
    Name = "${var.project}-${var.environment}-glue-vpc-endpoint"
    for-use-with-amazon-emr-managed-policies = "true"
  }
}


resource "aws_vpc_endpoint" "sts" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.sts"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private_az_a.id,
    aws_subnet.private_az_b.id
  ]

  security_group_ids = [
    aws_security_group.vpc_endpoint.id
  ]

  tags = {
    Name = "${var.project}-${var.environment}-sts-vpc-endpoint"
    for-use-with-amazon-emr-managed-policies = "true"
  }
}

resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.logs"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private_az_a.id,
    aws_subnet.private_az_b.id
  ]

  security_group_ids = [
    aws_security_group.vpc_endpoint.id
  ]

  tags = {
    Name = "${var.project}-${var.environment}-cloudwatch-logs-vpc-endpoint"
    #for-use-with-amazon-emr-managed-policies = "true"
  }
}

resource "aws_vpc_endpoint" "cloudwatch_monitoring" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.monitoring"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private_az_a.id,
    aws_subnet.private_az_b.id
  ]

  security_group_ids = [
    aws_security_group.vpc_endpoint.id
  ]

  tags = {
    Name = "${var.project}-${var.environment}-cloudwatch-monitoring-vpc-endpoint"
    # for-use-with-amazon-emr-managed-policies = "true"
  }
}

resource "aws_vpc_endpoint" "kms" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.kms"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private_az_a.id,
    aws_subnet.private_az_b.id
  ]

  security_group_ids = [
    aws_security_group.vpc_endpoint.id
  ]

  tags = {
    Name = "${var.project}-${var.environment}-kms-vpc-endpoint"
    # for-use-with-amazon-emr-managed-policies = "true"
  }
}

resource "aws_vpc_endpoint" "sqs" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.sqs"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private_az_a.id,
    aws_subnet.private_az_b.id
  ]

  security_group_ids = [
    aws_security_group.vpc_endpoint.id
  ]

  tags = {
    Name = "${var.project}-${var.environment}-sqs-vpc-endpoint"
    # for-use-with-amazon-emr-managed-policies = "true"
  }
}


###############################################################################
# logs

resource "aws_cloudwatch_log_group" "vpc" {
  name = "${var.project}-${var.environment}-vpc-lg"
}

# resource "aws_flow_log" "main" {
#   vpc_id          = aws_vpc.this.id
#   log_destination = aws_cloudwatch_log_group.vpc.arn
#   iam_role_arn    = var.network_role
#   traffic_type    = "ALL"
# }