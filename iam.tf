resource "aws_iam_role_policy" "nops_read_policy" {
  name = "container-cost-read-only-policy-${random_string.random.result}"
  role = data.aws_iam_role.nops_integration_role.name
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
          aws_s3_bucket.nops_container_cost.arn,
          "${aws_s3_bucket.nops_container_cost.arn}/*"
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
          AWS = var.environment == "PROD" ? "arn:aws:iam::202279780353:root" : "arn:aws:iam::844856862745:root"
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
          aws_s3_bucket.nops_container_cost.id,
          "${aws_s3_bucket.nops_container_cost.id}/*"
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
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/nops-container-cost-lambda",
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
        Resource = "arn:aws:sqs:${var.include_regions}:${data.aws_caller_identity.current.account_id}:nops-k8s-*"
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction",
          "lambda:UpdateFunctionConfiguration"
        ]
        Resource = [
          "arn:aws:lambda:${var.include_regions}:${data.aws_caller_identity.current.account_id}:function:nops-container-cost-agent-role-creation",
          "arn:aws:lambda:${var.include_regions}:${data.aws_caller_identity.current.account_id}:function:nops-container-cost-agent-role-management"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "events:DeleteRule",
          "events:DescribeRule",
          "events:PutRule",
          "events:PutTargets",
          "events:RemoveTargets"
        ]
        Resource = "arn:aws:events:${var.include_regions}:${data.aws_caller_identity.current.account_id}:rule/nops-container-cost-scheduled-check-event-rule"
      }
    ]
  })
  role = aws_iam_role.nops_cross_account_role.id
}

resource "aws_iam_role" "nops_container_cost_lambda_role" {
  count = var.create_iam_user == false ? 1 : 0
  name  = "nops-container-cost-lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "nops_container_cost_lambda_execution_policy_attachment" {
  count      = var.create_iam_user == false ? 1 : 0
  role       = aws_iam_role.nops_container_cost_lambda_role[0].name
  policy_arn = data.aws_iam_policy.lambda_basic_execution_role.arn
}

resource "aws_iam_policy" "nops_container_cost_lambda_policy" {
  count       = var.create_iam_user == false ? 1 : 0
  name        = "nops-container-cost-lambda-policy"
  description = "Lambda role policy for container cost management"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:CreateRole",
          "iam:PutRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DeleteRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:ListRoles",
          "iam:DeleteRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListRolePolicies",
          "eks:DescribeCluster",
          "eks:ListClusters",
          "sts:GetCallerIdentity",
          "events:PutEvents",
          "ec2:DescribeRegions"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "nops_container_cost_lambda_policy_attachment" {
  name       = "nops_container_cost_lambda_policy_attachment"
  policy_arn = aws_iam_policy.nops_container_cost_lambda_policy[0].arn
  roles      = [aws_iam_role.nops_container_cost_lambda_role[0].name]
}

resource "aws_iam_user" "iam_user" {
  count = var.create_iam_user ? 1 : 0
  name  = "nops-container-cost-s3"
}

resource "aws_iam_user_policy" "attach_policy_to_user" {
  count = var.create_iam_user ? 1 : 0
  name  = "nops-container-cost-${random_string.random.result}-s3"
  user  = aws_iam_user.iam_user[0].name
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
