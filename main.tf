## ----------------------------------------------------------------------------
##  Copyright 2023 SevenPico, Inc.
##
##  Licensed under the Apache License, Version 2.0 (the "License");
##  you may not use this file except in compliance with the License.
##  You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
##  Unless required by applicable law or agreed to in writing, software
##  distributed under the License is distributed on an "AS IS" BASIS,
##  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
##  See the License for the specific language governing permissions and
##  limitations under the License.
## ----------------------------------------------------------------------------

## ----------------------------------------------------------------------------
##  ./main.tf
##  This file contains code written only by SevenPico, Inc.
## ----------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# Certbot Lambda
# ---------------------------------------------------------------------------------------------------------------------
module "certbot_lambda" {
  source     = "SevenPicoForks/lambda-function/aws"
  version    = "2.0.1"
  context    = module.context.self
  attributes = ["lambda"]

  architectures                       = null
  cloudwatch_event_rules              = {}
  cloudwatch_lambda_insights_enabled  = false
  cloudwatch_logs_kms_key_arn         = ""
  cloudwatch_logs_retention_in_days   = 90
  cloudwatch_log_subscription_filters = {}
  description                         = "Certbot Lambda"
  event_source_mappings               = {}
  filename                            = try(data.archive_file.lambda[0].output_path, "")
  source_code_hash                    = try(data.archive_file.lambda[0].output_base64sha256, "")
  function_name                       = module.context.id
  handler                             = "lambda"
  ignore_external_function_updates    = false
  image_config                        = {}
  image_uri                           = null
  kms_key_arn                         = ""
  lambda_at_edge                      = false
  lambda_environment                  = {
    variables = merge({
      SECRET_ARN : var.secret_arn
      KMS_KEY_ARN : var.kms_key_arn
      DOMAINS : var.create_wildcard ? "*.${module.context.domain_name}" : module.context.domain_name
      DNS_PLUGIN : var.dns_plugin
    })
  }
  lambda_role_source_policy_documents = []
  layers                              = []
  memory_size                         = 512
  package_type                        = "Zip"
  publish                             = false
  reserved_concurrent_executions      = 10
  role_name                           = "${module.context.id}-lambda-role"
  runtime                             = "go1.x" #need to check
  s3_bucket                           = null
  s3_key                              = null
  s3_object_version                   = null
  sns_subscriptions                   = {}
  ssm_parameter_names                 = null
  timeout                             = 60
  tracing_config_mode                 = null
}

data "archive_file" "lambda" {
  count       = module.context.enabled ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/.build/lambda.zip"
}


# ------------------------------------------------------------------------------
# Lambda IAM
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "health_lambda" {
  count      = module.context.enabled ? 1 : 0
  role       = "${module.context.id}-lambda-role"
  policy_arn = module.certbot_lambda_policy.policy_arn
}

module "certbot_lambda_policy" {
  source     = "SevenPicoForks/iam-policy/aws"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["lambda", "policy"]

  description                   = "Lambda Access Policy"
  iam_override_policy_documents = null
  iam_policy_enabled            = true
  iam_policy_id                 = null
  iam_source_json_url           = null
  iam_source_policy_documents   = null

  iam_policy_statements = {
    AllowSslSecretRead = {
      effect    = "Allow"
      actions   = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:PutSecretValue"
      ]
      resources = [var.secret_arn]
    }
    AllowSslSecretKeyAccess = {
      effect    = "Allow"
      actions   = [
        "kms:Decrypt"
      ]
      resources = [var.kms_key_arn]
    }
  }
}


# ---------------------------------------------------------------------------------------------------------------------
# Cloudwatch Event Rule
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "default" {
  name_prefix         = "Certbot"
  description         = "Triggers lambda function ${module.certbot_lambda.function_name} on a regular schedule."
  schedule_expression = "cron(${var.cron_expression})"   #need to check
}

resource "aws_cloudwatch_event_target" "default" {
  rule = aws_cloudwatch_event_rule.default.name
  arn  = module.certbot_lambda.arn
  input = "{}"
}

resource "aws_lambda_permission" "default" {
  source_arn    = aws_cloudwatch_event_rule.default.arn
  action        = "lambda:InvokeFunction"
  function_name = module.certbot_lambda.function_name
  principal = "events.amazonaws.com"
}
