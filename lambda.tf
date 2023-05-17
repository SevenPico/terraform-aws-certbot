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
module "lambda" {
  #source     = "SevenPicoForks/lambda-function/aws"
  #version    = "2.0.1"
  source     = "git::https://github.com/SevenPicoForks/terraform-aws-lambda-function.git?ref=hotfix/add_file_system"
  context    = module.context.self
  attributes = ["lambda"]

  architectures                       = null
  cloudwatch_event_rules              = {}
  cloudwatch_lambda_insights_enabled  = false
  cloudwatch_logs_kms_key_arn         = ""
  cloudwatch_logs_retention_in_days   = 90
  cloudwatch_log_subscription_filters = {}
  description                         = "Lambda function to get certificate using Certbot and store it in SSL secrets"
  event_source_mappings               = {}
  filename                            = "${path.module}/lambda/certbot-1.17.0.zip"
  source_code_hash                    = filebase64sha256("${path.module}/lambda/certbot-1.17.0.zip")
  file_system_config = {
    local_mount_path = "/mnt/efs"
    arn              = aws_efs_access_point.default.arn
  }
  function_name                    = module.context.id
  handler                          = "main.lambda_handler"
  ignore_external_function_updates = false
  image_config                     = {}
  image_uri                        = null
  kms_key_arn                      = ""
  lambda_at_edge                   = false
  lambda_environment = {
    variables = merge({
      SECRET_ARN : var.target_secret_arn
      KMS_KEY_ARN : var.target_secret_kms_key_arn
      DOMAINS : module.context.domain_name
      KEYNAME_CERTIFICATE : var.keyname_certificate
      KEYNAME_PRIVATE_KEY : var.keyname_private_key
      KEYNAME_CERTIFICATE_CHAIN : var.keyname_certificate_chain
      KEYNAME_CERTIFICATE_SIGNING_REQUEST : var.keyname_certificate_signing_request
    })
  }
  lambda_role_source_policy_documents = []
  layers                              = []
  memory_size                         = 512
  package_type                        = "Zip"
  publish                             = false
  reserved_concurrent_executions      = 10
  role_name                           = "${module.context.id}-lambda-role"
  runtime                             = "python3.9"
  s3_bucket                           = null
  s3_key                              = null
  s3_object_version                   = null
  sns_subscriptions                   = {}
  ssm_parameter_names                 = null
  timeout                             = 300
  tracing_config_mode                 = null
  vpc_config = {
    security_group_ids = [aws_security_group.lambda.id]
    subnet_ids         = var.vpc_private_subnet_ids
  }
}

resource "aws_security_group" "lambda" {
  name        = "${module.context.id}-lambda-security-group"
  description = "Security group for lambda."
  vpc_id      = var.vpc_id
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow egress to 443"
  }
}

#module "lambda-security-group" {
#  source  = "SevenPicoForks/security-group/aws"
#  version = "3.0.0"
#  context = module.context.self
#  count   = module.context.enabled ? 1 : 0
#
#  vpc_id                     = var.vpc_id
#  allow_all_egress           = false
#  create_before_destroy      = true
#  inline_rules_enabled       = false
#  preserve_security_group_id = false
#  rules = [
#    {
#      type        = "egress"
#      from_port   = 443
#      to_port     = 443
#      protocol    = "tcp"
#      cidr_blocks = ["0.0.0.0/0"]
#      description = "Allow egress to 443"
#    }
#  ]
#}


# ------------------------------------------------------------------------------
# Lambda IAM
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "lambda" {
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
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:PutSecretValue",
        "secretsmanager:UpdateSecret"
      ]
      resources = [var.target_secret_arn]
    }
    AllowSslSecretKeyAccess = {
      effect = "Allow"
      actions = [
        "kms:GenerateDataKey",
        "kms:Decrypt"
      ]
      resources = [var.target_secret_kms_key_arn]
    }
    AllowRoute53Access = {
      effect = "Allow"
      actions = [
        "route53:ListHostedZones",
        "route53:GetChange",
        "route53:ChangeResourceRecordSets"
      ]
      resources = ["*"]
    }
    AllowVpcAccess = {
      effect = "Allow"
      actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:AssignPrivateIpAddresses",
        "ec2:UnassignPrivateIpAddresses"
      ]
      resources = ["*"]
    }
    AllowEfsAccess = {
      effect = "Allow"
      actions = [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientRootAccess",
        "elasticfilesystem:ClientWrite",
        "elasticfilesystem:DescribeMountTargets"
      ]
      resources = ["*"]
    }
  }
}


# ---------------------------------------------------------------------------------------------------------------------
# Cloudwatch Event Rule
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "default" {
  name_prefix         = "Certbot"
  description         = "Triggers lambda function ${module.lambda.function_name} on a regular schedule."
  schedule_expression = "cron(${var.cron_expression})"
}

resource "aws_cloudwatch_event_target" "default" {
  rule  = aws_cloudwatch_event_rule.default.name
  arn   = module.lambda.arn
  input = "{}"
}

resource "aws_lambda_permission" "default" {
  source_arn    = aws_cloudwatch_event_rule.default.arn
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_name
  principal     = "events.amazonaws.com"
}
