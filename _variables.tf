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
  description = "(Required) The arn of the secret where the Certbot values will be stored."
  type        = string
  default     = ""
}

variable "target_secret_kms_key_arn" {
  description = "(Required) The KMS key arn of the key used to decrypt Secrets Manager document where the Certbot values will be stored."
  type        = string
  default     = ""
}

variable "cron_expression" {
  description = "(Optional) Cron expression for the cloudwatch event rule to run lambda."
  type        = string
  default     = "cron(0 18 L * ? *)"

}

variable "vpc_id" {
  description = "(Required) The ID of the VPC where the Security Group will be created."
  type        = string
  default     = ""
}

variable "vpc_private_subnet_ids" {
  description = "(Required) A list of subnet IDs to associate with Lambda and EFS"
  type        = list(string)
  default     = []
}

variable "ssl_secret_keyname_certificate" {
  description = "(Required) Keyname certificate of the SSL secrets used to store in Certbot lambda."
  type        = string
  default     = "CERTIFICATE"
}

variable "ssl_secret_keyname_private_key" {
  description = "(Required) Keyname private key of the SSL secrets used to store in Certbot lambda."
  type        = string
  default     = "CERTIFICATE_PRIVATE_KEY"
}

variable "ssl_secret_keyname_certificate_chain" {
  description = "(Required) Keyname certificate chain of the SSL secrets used to store in Certbot lambda."
  type        = string
  default     = "CERTIFICATE_CHAIN"
}

variable "ssl_secret_keyname_certificate_signing_request" {
  description = "(Required) Keyname certificate signing request of the SSL secrets used to store in Certbot lambda."
  type        = string
  default     = "CERTIFICATE_SIGNING_REQUEST"
}

