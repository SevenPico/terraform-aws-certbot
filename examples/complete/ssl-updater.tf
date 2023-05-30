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
module "ssl_updater_context" {
  source  = "SevenPico/context/null"
  version = "2.0.0"
  context = module.context.self
  name    = "vpn"
}


#------------------------------------------------------------------------------
# OpenVPN
#------------------------------------------------------------------------------
module "ssl-update" {
  source     = "registry.terraform.io/SevenPico/ssl-update/aws"
  version    = "0.1.2"
  context    = module.ssl_updater_context.self
  depends_on = [module.certbot]

  sns_topic_arn                 = module.ssl_certificate.sns_topic_arn
  acm_certificate_arn           = module.ssl_certificate.acm_certificate_arn
  cloudwatch_log_retention_days = 30
  ecs_cluster_arn               = ""
  ecs_service_arns              = []
  keyname_certificate           = "CERTIFICATE"
  keyname_certificate_chain     = "CERTIFICATE_CHAIN"
  keyname_private_key           = "CERTIFICATE_PRIVATE_KEY"
  kms_key_arn                   = module.ssl_certificate.kms_key_arn
  secret_arn                    = module.ssl_certificate.secret_arn
  ssm_adhoc_command             = ""
  ssm_named_document            = module.openvpn.ssm_document_ssl_configure
  ssm_target_key                = "tag:Name"
  ssm_target_values             = [module.openvpn_context.id]
}
