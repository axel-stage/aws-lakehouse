# EMR Service Role ->	EMR control plane
# EMR EC2 Role	-> Node bootstrap and system access
# Studio Service Role ->	EMR Studio infrastructure
# Studio User Role ->	Interactive notebook users

###############################################################################
# emr service role

resource "aws_iam_role" "emr_service" {
  name        = "${var.project}-${var.environment}-emr-service-role"
  description = "IAM role for EMR service"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "elasticmapreduce.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    "for-use-with-amazon-emr-managed-policies" = "true"
  }
}

resource "aws_iam_role_policy" "emr_pass_role" {
  name = "${var.project}-${var.environment}-allow-pass-emr-ec2-role"
  role = aws_iam_role.emr_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "iam:PassRole"
      ]
      Resource = aws_iam_role.emr_ec2.arn
      Condition = {
        StringEquals = {
          "iam:PassedToService" = "ec2.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "emr_service" {
  role       = aws_iam_role.emr_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEMRServicePolicy_v2"
}

resource "aws_iam_role_policy" "emr_s3" {
  name = "${var.project}-${var.environment}-emr-service_s3-policy"
  role = aws_iam_role.emr_service.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = [
          aws_s3_bucket.lakehouse.arn,
          "${aws_s3_bucket.lakehouse.arn}/*"
        ]
      }
    ]
  })
}


###############################################################################
# emr ec2 role

resource "aws_iam_role" "emr_ec2" {
  name        = "${var.project}-${var.environment}-emr-ec2-role"
  description = "IAM role for EMR EC2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    "for-use-with-amazon-emr-managed-policies" = "true"
  }
}

resource "aws_iam_role_policy_attachment" "emr_ec2" {
  role       = aws_iam_role.emr_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceforEC2Role"
}

resource "aws_iam_instance_profile" "emr_ec2" {
  name = "${var.project}-${var.environment}-emr-ec2-instance-profile"
  role = aws_iam_role.emr_ec2.name

  tags = {
    "for-use-with-amazon-emr-managed-policies" = "true"
  }
}

###############################################################################
# emr studio service

resource "aws_iam_role" "emr_studio_service" {
  name = "${var.project}-${var.environment}-emr-studio-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "elasticmapreduce.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

}

resource "aws_iam_role_policy" "emr_studio_service" {
  name = "${var.project}-${var.environment}-emr-studio-service-policy"
  role = aws_iam_role.emr_studio_service.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowEMRReadOnlyActions"
        Effect = "Allow"

        Action = [
          "elasticmapreduce:ListInstances",
          "elasticmapreduce:DescribeCluster",
          "elasticmapreduce:ListSteps",
        ]

        Resource = "*"
      },

      {
        Sid    = "AllowEC2ENIActionsWithEMRTags"
        Effect = "Allow"

        Action = [
          "ec2:CreateNetworkInterfacePermission",
          "ec2:DeleteNetworkInterface",
        ]

        Resource = [
          "arn:aws:ec2:*:*:network-interface/*",
        ]

        Condition = {
          StringEquals = {
            "aws:ResourceTag/for-use-with-amazon-emr-managed-policies" = "true"
          }
        }
      },

      {
        Sid    = "AllowEC2ENIAttributeAction"
        Effect = "Allow"

        Action = [
          "ec2:ModifyNetworkInterfaceAttribute",
        ]

        Resource = [
          "arn:aws:ec2:*:*:instance/*",
          "arn:aws:ec2:*:*:network-interface/*",
          "arn:aws:ec2:*:*:security-group/*",
        ]
      },

      {
        Sid    = "AllowEC2SecurityGroupActionsWithEMRTags"
        Effect = "Allow"

        Action = [
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DeleteNetworkInterfacePermission",
        ]

        Resource = "*"

        Condition = {
          StringEquals = {
            "aws:ResourceTag/for-use-with-amazon-emr-managed-policies" = "true"
          }
        }
      },

      {
        Sid    = "AllowDefaultEC2SecurityGroupsCreationWithEMRTags"
        Effect = "Allow"

        Action = [
          "ec2:CreateSecurityGroup",
        ]

        Resource = [
          "arn:aws:ec2:*:*:security-group/*",
        ]

        Condition = {
          StringEquals = {
            "aws:RequestTag/for-use-with-amazon-emr-managed-policies" = "true"
          }
        }
      },

      {
        Sid    = "AllowDefaultEC2SecurityGroupsCreationInVPCWithEMRTags"
        Effect = "Allow"

        Action = [
          "ec2:CreateSecurityGroup",
        ]

        Resource = [
          "arn:aws:ec2:*:*:vpc/*",
        ]

        Condition = {
          StringEquals = {
            "aws:ResourceTag/for-use-with-amazon-emr-managed-policies" = "true"
          }
        }
      },

      {
        Sid    = "AllowAddingEMRTagsDuringDefaultSecurityGroupCreation"
        Effect = "Allow"

        Action = [
          "ec2:CreateTags",
        ]

        Resource = "arn:aws:ec2:*:*:security-group/*"

        Condition = {
          StringEquals = {
            "aws:RequestTag/for-use-with-amazon-emr-managed-policies" = "true"
            "ec2:CreateAction"                                        = "CreateSecurityGroup"
          }
        }
      },

      {
        Sid    = "AllowEC2ENICreationWithEMRTags"
        Effect = "Allow"

        Action = [
          "ec2:CreateNetworkInterface",
        ]

        Resource = [
          "arn:aws:ec2:*:*:network-interface/*",
        ]

        Condition = {
          StringEquals = {
            "aws:RequestTag/for-use-with-amazon-emr-managed-policies" = "true"
          }
        }
      },

      {
        Sid    = "AllowEC2ENICreationInSubnetAndSecurityGroupWithEMRTags"
        Effect = "Allow"

        Action = [
          "ec2:CreateNetworkInterface",
        ]

        Resource = [
          "arn:aws:ec2:*:*:subnet/*",
          "arn:aws:ec2:*:*:security-group/*",
        ]

        Condition = {
          StringEquals = {
            "aws:ResourceTag/for-use-with-amazon-emr-managed-policies" = "true"
          }
        }
      },

      {
        Sid    = "AllowAddingTagsDuringEC2ENICreation"
        Effect = "Allow"

        Action = [
          "ec2:CreateTags",
        ]

        Resource = "arn:aws:ec2:*:*:network-interface/*"

        Condition = {
          StringEquals = {
            "ec2:CreateAction" = "CreateNetworkInterface"
          }
        }
      },

      {
        Sid    = "AllowEC2ReadOnlyActions"
        Effect = "Allow"

        Action = [
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:DescribeInstances",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
        ]

        Resource = "*"
      },

      {
        Sid    = "AllowSecretsManagerReadOnlyActionsWithEMRTags"
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue",
        ]

        Resource = "arn:aws:secretsmanager:*:*:secret:*"

        Condition = {
          StringEquals = {
            "aws:ResourceTag/for-use-with-amazon-emr-managed-policies" = "true"
          }
        }
      },

      {
        Sid    = "AllowWorkspaceCollaboration"
        Effect = "Allow"

        Action = [
          "iam:GetUser",
          "iam:GetRole",
          "iam:ListUsers",
          "iam:ListRoles",
          "sso:GetManagedApplicationInstance",
          "sso-directory:SearchUsers",
        ]

        Resource = "*"
      },
      {
        Sid    = "S3Access"
        Effect = "Allow"

        Action = [
          "s3:*"
        ]

        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.lakehouse.id}",
          "arn:aws:s3:::${aws_s3_bucket.lakehouse.id}/*",
        ]
      }
    ]
  })
}

###############################################################################
# glue service role

resource "aws_iam_role" "glue_service" {
  name = "${var.project}-${var.environment}-glue-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "glue.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}



# resource "aws_iam_role" "emr_studio_service" {
#   name               = "${var.project}-${var.environment}-emr-studio-service-role"
#   description        = "EMR Studio Service Role"
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "elasticmapreduce.amazonaws.com"
#       },
#       "Effect": "Allow"
#     }
#   ]
# }
# EOF
# }

# resource "aws_iam_role_policy_attachment" "emr_studio_service" {
#   role       = aws_iam_role.emr_studio_service.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEMRServicePolicy_v2"
# }

###############################################################################
# emr studio user

# resource "aws_iam_role" "studio_user" {
#   name               = "${var.project}-${var.environment}-emr-studio-user-role"
#   description        = "Role assumed by EMR Studio users"
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": [
#         "sts:AssumeRole",
#         "sts:SetContext"
#       ],
#       "Principal": {
#         "Service": "elasticmapreduce.amazonaws.com"
#       },
#       "Effect": "Allow"
#     }
#   ]
# }
# EOF
# }


# resource "aws_iam_role_policy" "studio_workspace" {
#   name = "${var.project}-${var.environment}-studio-workspace-policy"
#   role = aws_iam_role.studio_user.name

#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": [
#         "s3:GetObject",
#         "s3:PutObject",
#         "s3:DeleteObject",
#         "s3:ListBucket"
#       ],
#       "Resource": [
#         "${aws_s3_bucket.lakehouse.arn}/workspaces",
#         "${aws_s3_bucket.lakehouse.arn}/workspaces/*"
#       ],
#       "Effect": "Allow"
#     }
#   ]
# }
# EOF
# }

# resource "aws_iam_role_policy" "studio_runtime_assume" {
#   name = "${var.project}-${var.environment}-studio-runtime-assume-policy"
#   role = aws_iam_role.studio_user.name

#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": [
#         "sts:AssumeRole"
#       ],
#       "Resource": [
#         "${aws_iam_role.emr_runtime.arn}"
#       ],
#       "Effect": "Allow"
#     }
#   ]
# }
# EOF
# }

###############################################################################
# emr runtime role

# data "aws_iam_policy_document" "emr_runtime_assume_role" {
#   statement {
#     effect = "Allow"

#     actions = [
#       "sts:AssumeRole"
#     ]

#     principals {
#       type = "AWS"

#       identifiers = [
#         aws_iam_role.emr_ec2.arn
#       ]
#     }
#   }
# }

# resource "aws_iam_role" "emr_runtime" {
#   name        = "${var.project}-${var.environment}-emr-runtime-role"
#   description = "Runtime role for Spark and EMR Studio workloads"

#   assume_role_policy = data.aws_iam_policy_document.emr_runtime_assume_role.json
# }

# ###############################################################################
# # S3 ACCESS
# ###############################################################################

# data "aws_iam_policy_document" "runtime_s3" {

#   statement {
#     sid = "BucketList"

#     effect = "Allow"

#     actions = [
#       "s3:ListBucket"
#     ]

#     resources = [
#       aws_s3_bucket.lakehouse.arn
#     ]
#   }

#   statement {
#     sid = "WarehouseAccess"

#     effect = "Allow"

#     actions = [
#       "s3:GetObject",
#       "s3:PutObject",
#       "s3:DeleteObject"
#     ]

#     resources = [
#       "${aws_s3_bucket.lakehouse.arn}/warehouse/*"
#     ]
#   }

#   statement {
#     sid = "TmpAccess"

#     effect = "Allow"

#     actions = [
#       "s3:GetObject",
#       "s3:PutObject",
#       "s3:DeleteObject"
#     ]

#     resources = [
#       "${aws_s3_bucket.lakehouse.arn}/tmp/*"
#     ]
#   }
# }

# ###############################################################################
# # GLUE ACCESS
# ###############################################################################

# data "aws_iam_policy_document" "runtime_glue" {
#   statement {
#     effect = "Allow"

#     actions = [
#       "glue:GetDatabase",
#       "glue:GetDatabases",
#       "glue:CreateDatabase",

#       "glue:GetTable",
#       "glue:GetTables",
#       "glue:CreateTable",
#       "glue:UpdateTable",
#       "glue:DeleteTable",

#       "glue:GetPartition",
#       "glue:GetPartitions",
#       "glue:CreatePartition",
#       "glue:UpdatePartition",
#       "glue:DeletePartition",

#       "glue:BatchCreatePartition",
#       "glue:BatchDeletePartition"
#     ]

#     resources = ["*"]
#   }
# }

# ###############################################################################
# # KMS ACCESS
# ###############################################################################

# data "aws_iam_policy_document" "runtime_kms" {
#   statement {
#     effect = "Allow"

#     actions = [
#       "kms:Decrypt",
#       "kms:Encrypt",
#       "kms:GenerateDataKey",
#       "kms:DescribeKey"
#     ]

#     resources = ["*"]
#   }
# }

# ###############################################################################
# # CLOUDWATCH LOGS
# ###############################################################################

# data "aws_iam_policy_document" "runtime_logs" {
#   statement {
#     effect = "Allow"

#     actions = [
#       "logs:CreateLogGroup",
#       "logs:CreateLogStream",
#       "logs:PutLogEvents"
#     ]

#     resources = ["*"]
#   }
# }

# ###############################################################################
# # COMBINED RUNTIME POLICY
# ###############################################################################

# data "aws_iam_policy_document" "runtime" {
#   source_policy_documents = [
#     data.aws_iam_policy_document.runtime_s3.json,
#     data.aws_iam_policy_document.runtime_glue.json,
#     data.aws_iam_policy_document.runtime_kms.json,
#     data.aws_iam_policy_document.runtime_logs.json
#   ]
# }

# resource "aws_iam_policy" "runtime" {
#   name = "${var.project}-${var.environment}-emr-runtime-policy"

#   policy = data.aws_iam_policy_document.runtime.json
# }

# resource "aws_iam_role_policy_attachment" "runtime" {
#   role       = aws_iam_role.emr_runtime.name
#   policy_arn = aws_iam_policy.runtime.arn
# }

# ###############################################################################
# # ALLOW EC2 ROLE TO ASSUME RUNTIME ROLE
# ###############################################################################

# data "aws_iam_policy_document" "allow_runtime_assume" {
#   statement {
#     effect = "Allow"

#     actions = [
#       "sts:AssumeRole"
#     ]

#     resources = [
#       aws_iam_role.emr_runtime.arn
#     ]
#   }
# }

# resource "aws_iam_role_policy" "emr_assume_runtime" {
#   name = "assume-runtime-role"

#   role = aws_iam_role.emr_ec2.id

#   policy = data.aws_iam_policy_document.allow_runtime_assume.json
# }
