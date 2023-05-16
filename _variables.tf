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
  description = "Secret arn of the SSL module."
  type = string
}

variable "target_secret_kms_key_arn" {
  description = "Secret kms key arn of the SSL module."
  type = string
}

variable "cron_expression" {
  description = "Cron expression for the cloudwatch event rule to run lambda."
  type = string
  default = "0 18 L * ? *"
}

variable "dns_plugin" {
  description = "The dns plugin for certbot."
  type        = string
  default     = "dns-route53"
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

