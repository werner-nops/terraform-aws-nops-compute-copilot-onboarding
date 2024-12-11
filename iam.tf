resource "aws_iam_role_policy" "nops_read_policy" {
  for_each = local.target_clusters
  name     = "container-cost-read-only-policy-${data.aws_eks_cluster.cluster[each.value].name}"
  role     = data.aws_iam_role.nops_integration_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          local.s3_bucket_name,
          "${local.s3_bucket_name}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "nops_cross_account_role" {
  name = "nops-cross-account-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.nops_account}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "nops_cross_account_policy" {
  name = "cross-account-role-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          local.s3_bucket_name,
          "${local.s3_bucket_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeRegions",
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "cloudwatch:PutMetricData"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole",
          "iam:CreateRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListRoles",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:DetachRolePolicy"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/nops-ccost-*",
          aws_iam_role.nops_cross_account_role.arn
        ]
      },
      {
        Effect   = "Allow"
        Action   = "sts:GetCallerIdentity"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage"
        ]
        Resource = "arn:aws:sqs:us-west-2:${data.aws_caller_identity.current.account_id}:nops-k8s-*"
      },
    ]
  })
  role = aws_iam_role.nops_cross_account_role.id
}
resource "aws_iam_user" "iam_user" {
  count = var.create_iam_user ? 1 : 0
  name  = "nops-container-cost-s3"
}

resource "aws_iam_user_policy" "attach_policy_to_user" {
  for_each = var.create_iam_user ? local.target_clusters : toset([])
  name     = "nops-container-cost-${data.aws_eks_cluster.cluster[each.value].name}-s3"
  user     = aws_iam_user.iam_user[0].name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::nops-container-cost-${data.aws_caller_identity.current.account_id}",
          "arn:aws:s3:::nops-container-cost-${data.aws_caller_identity.current.account_id}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "nops_ccost_role" {
  for_each = var.create_iam_user == false ? local.target_clusters : toset([])
  name     = "nops-ccost-${data.aws_eks_cluster.cluster[each.value].name}_${data.aws_region.current.id}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.provider[each.value].arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals : {
            "${trim(data.aws_eks_cluster.cluster[each.value].identity[0].oidc[0].issuer, "https://")}:sub" : "system:serviceaccount:nops:nops-container-insights"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "nops_ccost_policy" {
  for_each = var.create_iam_user == false ? local.target_clusters : toset([])
  name     = "container-ccost-policy-${data.aws_eks_cluster.cluster[each.value].name}"
  role     = aws_iam_role.nops_ccost_role[each.value].name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
        ]
        Resource = [
          local.s3_bucket_name,
          "${local.s3_bucket_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage"
        ]
        Resource = [
          "arn:aws:sqs:us-west-2:${local.nops_account}:nops-k8s-*",
        ]
      }
    ]
  })
}
