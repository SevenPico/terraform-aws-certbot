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
##  ./letsencrypt.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Let's Encrypt Certificate
# ------------------------------------------------------------------------------
module "letsencrypt_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  enabled    = module.context.enabled && local.create_letsencrypt
  attributes = ["letsencrypt"]
}

resource "tls_private_key" "account_key" {
  count = module.letsencrypt_context.enabled ? 1 : 0

  algorithm = "RSA"
}

resource "acme_registration" "this" {
  count = module.letsencrypt_context.enabled ? 1 : 0

  account_key_pem = tls_private_key.account_key[0].private_key_pem
  email_address   = var.registration_email_address == "" ? "nobody@${module.context.domain_name}" : var.registration_email_address
}

resource "tls_private_key" "certificate_key" {
  count = module.letsencrypt_context.enabled ? 1 : 0

  algorithm = "RSA"
}

resource "tls_cert_request" "this" {
  count = module.letsencrypt_context.enabled ? 1 : 0

  private_key_pem = tls_private_key.certificate_key[0].private_key_pem
  dns_names       = var.create_wildcard ? ["*.${module.context.domain_name}"] : distinct(concat([module.context.domain_name], var.additional_dns_names))

  subject {
    common_name = var.create_wildcard ? "*.${module.context.domain_name}" : module.context.domain_name
  }
}

resource "acme_certificate" "this" {
  count = module.letsencrypt_context.enabled ? 1 : 0

  account_key_pem         = acme_registration.this[0].account_key_pem
  certificate_request_pem = tls_cert_request.this[0].cert_request_pem

  dns_challenge {
    provider = "route53"
  }
}
