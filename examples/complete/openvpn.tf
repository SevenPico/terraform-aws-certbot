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
##  ./examples/default/openvpn.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

#------------------------------------------------------------------------------
# OpenVPN Labels
#------------------------------------------------------------------------------
module "openvpn_context" {
  source  = "SevenPico/context/null"
  version = "2.0.0"
  context = module.context.self
  name    = "vpn"
}


# ------------------------------------------------------------------------------
# Openvpn IAM Role Policy Doc
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "openvpn_ec2_policy_doc" {
  count = module.ssl_updater_context.enabled ? 1 : 0

  statement {
    sid       = "GetSslSecrets"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [module.ssl_certificate.secret_arn]
  }

  statement {
    sid       = "DecryptSslKmsKey"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [module.ssl_certificate.kms_key_arn]
  }
}

#------------------------------------------------------------------------------
# OpenVPN
#------------------------------------------------------------------------------
module "openvpn" {
  source  = "registry.terraform.io/SevenPico/openvpn/aws"
  version = "5.0.11"
  context = module.ssl_updater_context.self

  # REQUIRED
  openvpn_dhcp_option_domain = module.context.domain_name
  openvpn_hostname           = module.ssl_updater_context.dns_name
  subnet_ids                 = module.vpc_subnets.public_subnet_ids
  vpc_cidr_blocks = [
    module.vpc.vpc_cidr_block
  ]
  vpc_id = module.vpc.vpc_id

  # Create Options
  create_ec2_autoscale_sns_topic = true
  create_nlb                     = true
  create_openvpn_secret          = true

  # Enablements
  enable_efs                 = false
  enable_nat                 = true
  enable_custom_ssl          = true
  enable_licensing           = true
  enable_openvpn_backups     = true
  enable_ec2_cloudwatch_logs = true


  # Logging
  cloudwatch_logs_expiration_days = 30

  # SSL
  ssl_secret_arn                             = module.ssl_certificate.secret_arn
  ssl_secret_kms_key_arn                     = module.ssl_certificate.kms_key_arn
  ssl_sns_topic_arn                          = module.ssl_certificate.sns_topic_arn
  ssl_secret_certificate_bundle_keyname      = "CERTIFICATE_CHAIN"
  ssl_secret_certificate_keyname             = "CERTIFICATE"
  ssl_secret_certificate_private_key_keyname = "CERTIFICATE_PRIVATE_KEY"
  ssl_license_key_keyname                    = "OPENVPN_LICENSE"



  # EC2
  ec2_associate_public_ip_address           = true
  ec2_ami_id                                = "ami-0574da719dca65348"
  ec2_autoscale_desired_count               = 1
  ec2_autoscale_instance_type               = "t3.micro"
  ec2_autoscale_max_count                   = 1
  ec2_autoscale_min_count                   = 1
  ec2_autoscale_sns_topic_default_result    = "CONTINUE"
  ec2_autoscale_sns_topic_heartbeat_timeout = 180
  ec2_additional_security_group_ids         = []
  ec2_block_device_mappings                 = []
  ec2_disable_api_termination               = false
  ec2_role_source_policy_documents          = try(data.aws_iam_policy_document.openvpn_ec2_policy_doc[*].json, [])
  ec2_upgrade_schedule_expression           = "cron(15 13 ? * SUN *)"
  ec2_security_group_allow_all_egress       = true
  ec2_security_group_rules                  = []

  # NLB
  nlb_access_logs_prefix_override = null
  nlb_access_logs_s3_bucket_id    = null
  nlb_acm_certificate_arn         = module.ssl_certificate.acm_certificate_arn
  nlb_deletion_protection_enabled = false
  nlb_subnet_ids                  = module.vpc_subnets.public_subnet_ids
  nlb_tls_ssl_policy              = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  # S3
  s3_source_policy_documents       = []
  s3_access_logs_prefix_override   = null
  s3_access_logs_s3_bucket_id      = null
  s3_force_destroy                 = true
  s3_lifecycle_configuration_rules = []
  s3_object_ownership              = "BucketOwnerEnforced"
  s3_versioning_enabled            = true

  # OpenVPN
  openvpn_backup_schedule_expression      = "cron(0 00 00 ? * * *)"
  openvpn_client_cidr_blocks              = ["172.27.0.0/16"]
  openvpn_client_dhcp_network             = "172.27.32.0"
  openvpn_client_dhcp_network_mask        = 20
  openvpn_client_static_addresses_enabled = true
  openvpn_client_static_network           = "172.27.64.0"
  openvpn_client_static_network_mask      = "20"
  openvpn_daemon_ingress_blocks           = ["0.0.0.0/0"]
  openvpn_daemon_tcp_port                 = null
  openvpn_daemon_udp_port                 = 1194
  openvpn_secret_admin_password_key       = "ADMIN_PASSWORD"
  openvpn_secret_arn                      = ""
  openvpn_secret_enable_kms_key_rotation  = false
  openvpn_secret_kms_key_arn              = null
  openvpn_time_zone                       = "America/Chicago"
  openvpn_ui_https_port                   = 443
  openvpn_ui_ingress_blocks               = ["0.0.0.0/0"]
  openvpn_web_server_name                 = "OpenVPN Server"
  openvpn_tls_version_min                 = "1.2"
  openvpn_version                         = "2.11.1-f4027f58-Ubuntu22"
}

# Delays VPN initialization until all resources are in place
resource "null_resource" "openvpn_set_autoscale_counts" {
  count = module.ssl_updater_context.enabled ? 1 : 0
  depends_on = [
  module.openvpn]

  provisioner "local-exec" {
    command = join(" ", [
      "aws",
      "autoscaling",
      "update-auto-scaling-group",
      "--auto-scaling-group-name",
      module.openvpn.autoscale_group_name,
      "--desired-capacity",
      1
    ])
  }
}
