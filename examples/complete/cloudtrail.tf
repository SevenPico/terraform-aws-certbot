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
##  ./examples/complete/cloudtrail.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Cloudtrail
# ------------------------------------------------------------------------------
module "cloudtrail_context" {
  source     = "registry.terraform.io/SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["cloudtrail"]
}

module "cloudtrail" {
  source  = "registry.terraform.io/SevenPicoForks/cloudtrail/aws"
  version = "2.0.0"
  context = module.cloudtrail_context.self

  cloud_watch_logs_group_arn    = ""
  cloud_watch_logs_role_arn     = ""
  enable_log_file_validation    = true
  enable_logging                = true
  event_selector                = []
  include_global_service_events = true
  is_multi_region_trail         = true
  is_organization_trail         = false
  kms_key_arn                   = null
  s3_bucket_name                = module.cloudtrail_log_storage.bucket_id
  s3_key_prefix                 = null
  sns_topic_name                = null
}

module "cloudtrail_log_storage" {
  source  = "registry.terraform.io/SevenPico/s3-log-storage/aws//modules/cloudtrail"
  version = "2.0.5"
  context = module.cloudtrail_context.self

  access_log_bucket_name            = ""
  access_log_bucket_prefix_override = ""
  create_kms_key                    = true
  enable_mfa_delete                 = false
  enable_versioning                 = true
  force_destroy                     = true
  kms_key_deletion_window_in_days   = 30
  kms_key_enable_key_rotation       = false
  lifecycle_configuration_rules     = var.cloudtrail_log_storage_lifecycle_rules
  s3_object_ownership               = "BucketOwnerEnforced"
  s3_source_policy_documents        = []
  source_accounts                   = []
}
