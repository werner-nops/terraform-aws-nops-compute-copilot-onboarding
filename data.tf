data "aws_caller_identity" "current" {}

data "aws_iam_policy" "lambda_basic_execution_role" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_role" "nops_integration_role" {
  name = var.role_name
}
