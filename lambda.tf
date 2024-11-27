data "archive_file" "nops_container_cost_role_creation" {
  count       = var.create_iam_user == false ? 1 : 0
  type        = "zip"
  source_file = "${path.module}/lambda/nops-container-cost-role-creation/index.py"
  output_path = "container_cost_role_creation.zip"
}

resource "aws_lambda_function" "nops_container_cost_role_creation" {
  count         = var.create_iam_user == false ? 1 : 0
  filename      = "container_cost_role_creation.zip"
  function_name = "nops-container-cost-agent-role-creation"
  role          = aws_iam_role.nops_container_cost_lambda_role[0].arn
  handler       = "index.lambda_handler"

  source_code_hash = data.archive_file.nops_container_cost_role_creation[0].output_base64sha256

  runtime = "python3.10"
  timeout = 60

  environment {
    variables = {
      IncludeRegions = var.include_regions
      Env            = var.environment
      Token          = var.token
      STACK_NAME     = ""
      STACK_ID       = ""
    }
  }
}

resource "aws_cloudwatch_event_rule" "nops_container_cost_role_creation_lambda_trigger" {
  count       = var.create_iam_user == false ? 1 : 0
  name        = "nops-container-cost-lambda-trigger"
  description = "Trigger Lambda on Terraform apply"
  event_pattern = jsonencode({
    source      = ["aws.terraform"],
    detail_type = ["Terraform Apply"],
    RequestType = "Create"
  })
}

resource "aws_cloudwatch_event_target" "nops_container_cost_lambda_target" {
  count     = var.create_iam_user == false ? 1 : 0
  rule      = aws_cloudwatch_event_rule.nops_container_cost_role_creation_lambda_trigger[0].name
  arn       = aws_lambda_function.nops_container_cost_role_creation[0].arn
  target_id = "nops-container-cost-lambda-target"
}

data "archive_file" "nops_container_cost_agent_role_management" {
  count       = var.create_iam_user == false ? 1 : 0
  type        = "zip"
  source_file = "${path.module}/lambda/nops-container-cost-role-management/index.py"
  output_path = "container_cost_role_management.zip"
}

resource "aws_lambda_function" "nops_container_cost_agent_role_management" {
  count         = var.create_iam_user == false ? 1 : 0
  filename      = "container_cost_role_management.zip"
  function_name = "nops-container-cost-agent-role-management"
  role          = aws_iam_role.nops_container_cost_lambda_role[0].arn
  handler       = "index.lambda_handler"

  source_code_hash = data.archive_file.nops_container_cost_agent_role_management[0].output_base64sha256

  runtime = "python3.10"
  timeout = 60

  environment {
    variables = {
      IncludeRegions = var.include_regions
      AccountId      = data.aws_caller_identity.current.account_id
      Env            = var.environment
      Token          = var.token
      STACK_NAME     = ""
      STACK_ID       = ""
    }
  }
}

resource "aws_cloudwatch_event_rule" "nops_container_cost_scheduled_check_event_rule" {
  count               = var.create_iam_user == false ? 1 : 0
  name                = "nops-container-cost-agent-role-management-scheduled-check"
  schedule_expression = "rate(2 hours)"
  event_bus_name      = "default"
  state               = "ENABLED"
  event_pattern = jsonencode({
    # TODO Change to CF event pattern
    source      = ["aws.terraform"],
    detail_type = ["Terraform Apply"]
  })
}

resource "aws_lambda_permission" "nops_container_cost_role_management_scheduled_check_event_rule_permission" {
  count         = var.create_iam_user == false ? 1 : 0
  function_name = aws_lambda_function.nops_container_cost_agent_role_management[0].function_name
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.nops_container_cost_scheduled_check_event_rule[0].arn
}
