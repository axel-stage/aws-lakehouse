###############################################################################
# emr cluster

# Security group for the master node
resource "aws_security_group" "emr_master" {
  name        = "${var.project}-${var.environment}-emr-master-sg"
  description = "Security group for EMR master node"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.project}-${var.environment}-emr-master-sg"
    for-use-with-amazon-emr-managed-policies = "true"
  }
}

# Security group for core/task nodes
resource "aws_security_group" "emr_core" {
  name        = "${var.project}-${var.environment}-emr-core-sg"
  description = "Security group for EMR core and task nodes"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.project}-${var.environment}-emr-core-sg"
    for-use-with-amazon-emr-managed-policies = "true"
  }
}

# Service access security group required for EMR clusters in private subnets
resource "aws_security_group" "emr_service" {
  name        = "${var.project}-${var.environment}-emr-service-sg"
  description = "Security group for EMR service access"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.project}-${var.environment}-emr-service-sg"
    for-use-with-amazon-emr-managed-policies = "true"
  }
}

# Use standalone security group rule resources to avoid dependency cycles
# between groups that reference each other.
resource "aws_vpc_security_group_ingress_rule" "emr_master_self" {
  security_group_id            = aws_security_group.emr_master.id
  referenced_security_group_id = aws_security_group.emr_master.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "emr_master_from_core" {
  security_group_id            = aws_security_group.emr_master.id
  referenced_security_group_id = aws_security_group.emr_core.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "emr_master_from_service_access" {
  security_group_id            = aws_security_group.emr_master.id
  referenced_security_group_id = aws_security_group.emr_service.id
  from_port                    = 8443
  to_port                      = 8443
  ip_protocol                  = "tcp"
}

# resource "aws_vpc_security_group_ingress_rule" "emr_master_ssh" {
#   security_group_id = aws_security_group.emr_master.id
#   cidr_ipv4         = var.vpc_cidr_block
#   from_port         = 22
#   to_port           = 22
#   ip_protocol       = "tcp"
# }

resource "aws_vpc_security_group_ingress_rule" "emr_core_self" {
  security_group_id            = aws_security_group.emr_core.id
  referenced_security_group_id = aws_security_group.emr_core.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "emr_core_from_master" {
  security_group_id            = aws_security_group.emr_core.id
  referenced_security_group_id = aws_security_group.emr_master.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "emr_core_from_service_access" {
  security_group_id            = aws_security_group.emr_core.id
  referenced_security_group_id = aws_security_group.emr_service.id
  from_port                    = 8443
  to_port                      = 8443
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "emr_service_from_master" {
  security_group_id            = aws_security_group.emr_service.id
  referenced_security_group_id = aws_security_group.emr_master.id
  from_port                    = 9443
  to_port                      = 9443
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "emr_master_all" {
  security_group_id = aws_security_group.emr_master.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "emr_core_all" {
  security_group_id = aws_security_group.emr_core.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "emr_service_to_master" {
  security_group_id            = aws_security_group.emr_service.id
  referenced_security_group_id = aws_security_group.emr_master.id
  from_port                    = 8443
  to_port                      = 8443
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "emr_service_to_core" {
  security_group_id            = aws_security_group.emr_service.id
  referenced_security_group_id = aws_security_group.emr_core.id
  from_port                    = 8443
  to_port                      = 8443
  ip_protocol                  = "tcp"
}

###############################################################################
# emr studio

resource "aws_security_group" "workspace" {
  name        = "${var.project}-${var.environment}-studio-workspace-sg"
  description = "EMR Studio Workspace SG"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.project}-${var.environment}-studio-workspace-sg"
    for-use-with-amazon-emr-managed-policies = "true"
  }
}

resource "aws_security_group" "engine" {
  name        = "${var.project}-${var.environment}-studio-engine-sg"
  description = "EMR Studio Engine SG"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.project}-${var.environment}-studio-engine-sg",
    for-use-with-amazon-emr-managed-policies = "true"
  }
}

###############################################################################
# Workspace -> Engine
###############################################################################

resource "aws_security_group_rule" "workspace_to_engine_18888" {
  type                     = "egress"
  from_port                = 18888
  to_port                  = 18888
  protocol                 = "tcp"
  security_group_id        = aws_security_group.workspace.id
  source_security_group_id = aws_security_group.engine.id
}

###############################################################################
# Engine <- Workspace
###############################################################################

resource "aws_security_group_rule" "engine_from_workspace_18888" {
  type                     = "ingress"
  from_port                = 18888
  to_port                  = 18888
  protocol                 = "tcp"
  security_group_id        = aws_security_group.engine.id
  source_security_group_id = aws_security_group.workspace.id
}

resource "aws_security_group_rule" "engine_from_workspace_4040" {
  type                     = "ingress"
  from_port                = 4040
  to_port                  = 4040
  protocol                 = "tcp"
  security_group_id        = aws_security_group.engine.id
  source_security_group_id = aws_security_group.workspace.id
}

resource "aws_security_group_rule" "engine_from_workspace_18080" {
  type                     = "ingress"
  from_port                = 18080
  to_port                  = 18080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.engine.id
  source_security_group_id = aws_security_group.workspace.id
}

###############################################################################
# General outbound access
###############################################################################

resource "aws_security_group_rule" "workspace_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.workspace.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "engine_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.engine.id
  cidr_blocks       = ["0.0.0.0/0"]
}


###############################################################################
# glue endpoint

resource "aws_security_group" "glue_endpoint" {
  name        = "${var.project}-${var.environment}-glue-endpoint-sg"
  description = "Glue VPC endpoint"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.project}-${var.environment}-glue-endpoint-sg",
    for-use-with-amazon-emr-managed-policies = "true"
  }

}

resource "aws_security_group_rule" "glue_https_from_master" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"

  security_group_id        = aws_security_group.glue_endpoint.id
  source_security_group_id = aws_security_group.emr_master.id
}

resource "aws_security_group_rule" "glue_https_from_core" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"

  security_group_id        = aws_security_group.glue_endpoint.id
  source_security_group_id = aws_security_group.emr_core.id
}

###############################################################################
# sts endpoint

resource "aws_security_group" "sts_endpoint" {
  name        = "${var.project}-${var.environment}-sts-endpoint-sg"
  description = "sts VPC endpoint"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.project}-${var.environment}-sts-endpoint-sg",
    for-use-with-amazon-emr-managed-policies = "true"
  }
}

resource "aws_security_group_rule" "sts_https_from_master" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"

  security_group_id        = aws_security_group.sts_endpoint.id
  source_security_group_id = aws_security_group.emr_master.id
}

resource "aws_security_group_rule" "sts_https_from_core" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"

  security_group_id        = aws_security_group.sts_endpoint.id
  source_security_group_id = aws_security_group.emr_core.id
}