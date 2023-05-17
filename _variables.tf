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
##  This file contains code written only by SevenPico, Inc.
## ----------------------------------------------------------------------------
variable "target_secret_arn" {
  type = string
  description = "Secret arn of the SSL module."
}

variable "target_secret_kms_key_arn" {
  description = "(Required) The KMS key arn of the key used to decrypt Secrets Manager document where the Certbot values will be stored."
  type = string
}

variable "cron_expression" {
  type = string
  default = "cron(0 18 L * ? *)"
  description = "(Optional) Cron expression for the cloudwatch event rule to run lambda."
}

variable "certbot_version" {
  type = string
  default = "1.17.0"
}

variable "vpc_id" {
  type = string
}

variable "vpc_private_subnet_ids" {
  type = list(string)
}

variable "keyname_certificate" {
  type        = string
  default     = ""
}

variable "keyname_private_key" {
  type        = string
  default     = ""
}

variable "keyname_certificate_chain" {
  type        = string
  default     = ""
}

variable "keyname_certificate_signing_request" {
  type        = string
  default     = ""
}

