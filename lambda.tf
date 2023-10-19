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
  source     = "registry.terraform.io/SevenPicoForks/lambda-function/aws"
  version    = "2.0.3"
  context    = module.context.self
  attributes = ["lambda"]
  depends_on = [module.efs]

  architectures                       = null
  cloudwatch_event_rules              = {}
  cloudwatch_lambda_insights_enabled  = false
  cloudwatch_logs_kms_key_arn         = ""
  cloudwatch_logs_retention_in_days   = 90
  cloudwatch_log_subscription_filters = {}
  description                         = "Lambda function to get certificate using Certbot and store it in SSL secrets."
  event_source_mappings               = {}
  filename                            = "${path.module}/lambda/certbot-1.17.0.zip"
  source_code_hash                    = filebase64sha256("${path.module}/lambda/certbot-1.17.0.zip")
  file_system_config = {
    local_mount_path = "/mnt/efs"
    arn              = try(aws_efs_access_point.default[0].arn, "")
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
      DOMAINS : var.create_wildcard ? "*.${module.context.domain_name}" : module.context.domain_name
      DOMAIN_FOR_DIRECTORY : module.context.domain_name
      KEYNAME_CERTIFICATE : var.ssl_secret_keyname_certificate
      KEYNAME_PRIVATE_KEY : var.ssl_secret_keyname_private_key
      KEYNAME_CERTIFICATE_CHAIN : var.ssl_secret_keyname_certificate_chain
      KEYNAME_CERTIFICATE_SIGNING_REQUEST : var.ssl_secret_keyname_certificate_signing_request
    })
  }
  lambda_role_source_policy_documents = try([data.aws_iam_policy_document.default[0].json], [])
  layers                              = []
  memory_size                         = 512
  package_type                        = "Zip"
  publish                             = false
  reserved_concurrent_executions      = var.reserved_concurrent_executions
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
    security_group_ids = try([module.lambda_security_group[0].id], [])
    subnet_ids         = var.vpc_private_subnet_ids
  }
}

module "lambda_security_group" {
  count      = module.context.enabled ? 1 : 0
  source     = "registry.terraform.io/SevenPicoForks/security-group/aws"
  version    = "3.0.0"
  context    = module.context.self
  attributes = ["lambda"]

  vpc_id                     = var.vpc_id
  allow_all_egress           = false
  create_before_destroy      = true
  inline_rules_enabled       = false
  preserve_security_group_id = false
  rules_map = merge({ egress-to-443 = [
    {
      type        = "egress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow egress to 443"
    }] }, {
    egress-to-efs = [{
      type                     = "egress"
      from_port                = 2049
      to_port                  = 2049
      protocol                 = "tcp"
      source_security_group_id = module.efs.security_group_id
      description              = "Allow egress to EFS"
    }],
  })
  security_group_description = "Security group for ${module.context.id}-lambda."
}


# ------------------------------------------------------------------------------
# Lambda IAM
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "default" {
  #checkov:skip=CKV_AWS_356:skipping 'Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions'
  #checkov:skip=CKV_AWS_111:skipping 'Ensure IAM policies does not allow write access without constraints'
  count = module.context.enabled ? 1 : 0
  statement {
    sid = "AllowSslSecretRead"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecret"
    ]
    resources = [
      var.target_secret_arn
    ]
  }
  statement {
    sid = "AllowSslSecretKeyAccess"
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]
    resources = [
      var.target_secret_kms_key_arn
    ]
  }
  statement {
    sid = "AllowRoute53Access"
    actions = [
      "route53:ListHostedZones",
      "route53:GetChange",
      "route53:ChangeResourceRecordSets"
    ]
    resources = ["*"]
  }
  statement {
    sid = "AllowVpcAccess"
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
  statement {
    sid = "AllowEfsAccess"
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientRootAccess",
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:DescribeMountTargets"
    ]
    resources = ["*"]
  }
}


# ---------------------------------------------------------------------------------------------------------------------
# Cloudwatch Alarm
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "ssl_certificate_expiry" {
  count               = module.context.enabled ? 1 : 0
  alarm_name          = "${module.context.id}-ssl-cert-expiration"
  comparison_operator = "LessThanOrEqualToThreshold"
  period              = "86400" #1 day in seconds
  evaluation_periods  = "1"
  threshold           = "7"
  namespace           = "AWS/CertificateManager"
  metric_name         = "DaysToExpiry"
  statistic           = "Minimum"
  alarm_description   = "This metric monitors certificate expiration"
  actions_enabled     = "true"
  alarm_actions       = try([module.sns[0].topic_arn], [])
  dimensions = {
    CertificateArn = var.acm_certificate_arn
  }
}


# ------------------------------------------------------------------------------
# Lambda SNS Subscription
# ------------------------------------------------------------------------------
module "sns" {
  source  = "SevenPico/sns/aws"
  version = "2.0.2"
  context = module.context.self
  count   = module.context.enabled ? 1 : 0
}

resource "aws_sns_topic_subscription" "lambda" {
  count     = module.context.enabled ? 1 : 0
  endpoint  = module.lambda.arn
  protocol  = "lambda"
  topic_arn = try(module.sns[0].topic_arn, "")
}

resource "aws_lambda_permission" "sns" {
  count         = module.context.enabled ? 1 : 0
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = try(module.sns[0].topic_arn, "")
  statement_id  = "AllowExecutionFromSNS"
}