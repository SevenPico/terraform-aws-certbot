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
##  ./examples/complete/terragrunt.hcl
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

locals {
  account_id  = get_aws_account_id()
  tenant      = "Brim"

  region = get_env("AWS_REGION")
  root_domain = "modules.thebrim.io"

  namespace   = "brim"
  project     = "eff-certbot" //replace(basename(get_repo_root()), "teraform-", "")
  environment = "eff-certbot"
  stage       = basename(get_terragrunt_dir()) //
  domain_name = "${local.stage}.${local.project}.${local.root_domain}"

  tags = { Source = "Managed by Terraform" }
  regex_replace_chars = "/[^-a-zA-Z0-9]/"
  delimiter           = "-"
  replacement         = ""
  id_length_limit     = 0
  id_hash_length      = 5
  label_key_case      = "title"
  label_value_case    = "lower"
  #label_order         =  ["namespace", "project", "environment", "stage", "name", "attributes"]
  label_order         = ["namespace", "environment", "stage", "name", "attributes"]
  dns_name_format     = "$${name}.$${domain_name}"
}

inputs = {
  root_domain = local.root_domain

  # Standard Context
  region              = local.region
  tenant              = local.tenant
  project             = local.project
  domain_name         = local.domain_name
  project             = local.project
  namespace           = local.namespace
  environment         = local.environment
  stage               = local.stage
  tags                = local.tags
  regex_replace_chars = local.regex_replace_chars
  delimiter           = local.delimiter
  replacement         = local.replacement
  id_length_limit     = local.id_length_limit
  id_hash_length      = local.id_hash_length
  label_key_case      = local.label_key_case
  label_value_case    = local.label_value_case
  label_order         = local.label_order
  dns_name_format     = local.dns_name_format

  # Module / Example Specific
  vpc_cidr_block     = "10.10.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  cloudtrail_log_storage_lifecycle_rules = [
    {
      enabled                                = true # bool
      id                                     = "temp-log-retention-policy-with-expiration"
      abort_incomplete_multipart_upload_days = 1 # number
      filter_and                             = null
      expiration                             = {
        days                         = 1 # integer > 0
        expired_object_delete_marker = false

      }
      noncurrent_version_expiration = {
        noncurrent_days = 1
      }
      transition                    = []
      noncurrent_version_transition = []
    }
  ]

}

remote_state {
  backend = "s3"
  disable_init = false
  config  = {
    bucket                = "brim-sandbox-tfstate"
    disable_bucket_update = true
    dynamodb_table        = "brim-sandbox-tfstate-lock"
    encrypt               = true
    key                   = "${local.account_id}/${local.project}/${local.stage}/terraform.tfstate"
    region                = local.region
  }
  generate = {
    path      = "generated-backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

generate "providers" {
  path      = "generated-providers.tf"
  if_exists = "overwrite"
  contents  = <<EOF
  terraform {
    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = "~> 4"
      }
      local = {
        source  = "hashicorp/local"
      }
      acme = {
        source  = "vancluever/acme"
        version = "~> 2.8.0"
      }
    }
  }

  provider "aws" {
    region  = "${local.region}"
  }

  provider "acme" {
    server_url = "https://acme-v02.api.letsencrypt.org/directory"
  }
  EOF
}
