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
##  ./examples/complete/certbot.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Certbot Context
#------------------------------------------------------------------------------
module "certbot_context" {
  source  = "registry.terraform.io/SevenPico/context/null"
  version = "2.0.0"
  context = module.context.self
  name    = "certbot"
}


#------------------------------------------------------------------------------
# Certbot
#------------------------------------------------------------------------------
module "certbot" {
  source     = "../../"
  context    = module.certbot_context.self
  depends_on = [module.ssl_certificate]

  acm_certificate_arn                            = module.ssl_certificate.acm_certificate_arn
  ssl_secret_keyname_certificate                 = "CERTIFICATE"
  ssl_secret_keyname_certificate_chain           = "CERTIFICATE_CHAIN"
  ssl_secret_keyname_certificate_signing_request = "CERTIFICATE_SIGNING_REQUEST"
  ssl_secret_keyname_private_key                 = "CERTIFICATE_PRIVATE_KEY"
  target_secret_kms_key_arn                      = module.ssl_certificate.kms_key_arn
  target_secret_arn                              = module.ssl_certificate.secret_arn
  vpc_id                                         = module.vpc.vpc_id
  vpc_private_subnet_ids                         = module.vpc_subnets.private_subnet_ids
}