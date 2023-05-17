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
##  ./_variables.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

locals {
  create_acm_only    = var.create_mode == "ACM_Only" && module.context.enabled
  create_letsencrypt = var.create_mode == "LetsEncrypt" && module.context.enabled
  create_from_file   = var.create_mode == "From_File" && module.context.enabled
  create_from_secret = var.create_mode == "From_Secret" && module.context.enabled
  create_secret_only = var.create_mode == "Create_Secret_Only" && module.context.enabled

  ignore_secret_changes = local.create_from_file
}

variable "create_mode" {
  type        = string
  description = "Set the operational mode of this module."
  default     = "LetsEncrypt"

  validation {
    condition     = contains(["ACM_Only", "LetsEncrypt", "From_Secret", "From_File", "Create_Secret_Only"], var.create_mode)
    error_message = "The 'mode' must be one of [ACM_Only, LetsEncrypt, From_Secret, From_File]."
  }
}

variable "create_secret_update_sns" {
  type    = bool
  default = false
}

variable "import_secret_arn" {
  description = "ARN of exisiting SecretsManager secret containing certificate, private key and chain"
  type        = string
  default     = ""
}

variable "additional_dns_names" {
  description = "Additional domain names that the certificate will be created for."
  type        = list(string)
  default     = []
}

variable "additional_secrets" {
  description = "Additonal key-value pairs to add to the created SecretsManager secret"
  type        = map(any)
  default     = {}
}

variable "keyname_certificate" {
  type    = string
  default = "CERTIFICATE"
}

variable "keyname_private_key" {
  type    = string
  default = "CERTIFICATE_PRIVATE_KEY"
}

variable "keyname_certificate_chain" {
  type    = string
  default = "CERTIFICATE_CHAIN"
}

variable "keyname_certificate_signing_request" {
  type    = string
  default = "CERTIFICATE_SIGNING_REQUEST"
}

variable "import_filepath_certificate" {
  default = ""
}

variable "import_filepath_certificate_chain" {
  default = ""
}

variable "import_filepath_private_key" {
  default = ""
}

variable "import_filepath_csr" {
  default = ""
}

variable "secret_read_principals" {
  type    = map(any)
  default = {}
}

variable "secret_update_sns_pub_principals" {
  type    = map(any)
  default = {}
}

variable "secret_update_sns_sub_principals" {
  type    = map(any)
  default = {}
}

variable "zone_id" {
  description = "When using ACM_Only, the Route53 Zone ID is required."
  type        = string
  default     = null
}

variable "kms_key_deletion_window_in_days" {
  description = "Deletion window for KMS Keys created in this module."
  type        = number
  default     = 30
}

variable "kms_key_enable_key_rotation" {
  description = "Turn on KMS Key rotation for KMS Keys created in this module."
  type        = bool
  default     = true
}

variable "create_wildcard" {
   type        = bool
   default     = true
 }

variable "registration_email_address" {
  type = string
  default = ""
}

variable "kms_key_multi_region" {
  type        = bool
  default     = false
  description = "Indicates whether the KMS key is a multi-Region (true) or regional (false) key."
}

variable "save_csr" {
  type        = bool
  default     = false
}
