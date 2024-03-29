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
##  ./efs.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

#------------------------------------------------------------------------------
# EFS Module context
#------------------------------------------------------------------------------
module "efs_context" {
  source     = "registry.terraform.io/SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["efs"]
}


#------------------------------------------------------------------------------
# EFS Module
#------------------------------------------------------------------------------
module "efs" {
  source  = "registry.terraform.io/SevenPicoForks/efs/aws"
  version = "2.0.1"
  context = module.efs_context.self

  #required
  subnets = var.vpc_private_subnet_ids
  vpc_id  = var.vpc_id

  #optional
  access_points                        = {}
  additional_security_group_rules      = []
  allowed_cidr_blocks                  = []
  allowed_security_group_ids           = []
  associated_security_group_ids        = []
  availability_zone_name               = null
  create_security_group                = true
  efs_backup_policy_enabled            = false
  encrypted                            = true
  kms_key_id                           = null
  mount_target_ip_address              = null
  performance_mode                     = "generalPurpose"
  provisioned_throughput_in_mibps      = 0
  region                               = "us-east-1"
  security_group_create_before_destroy = true
  security_group_create_timeout        = "10m"
  security_group_delete_timeout        = "15m"
  security_group_description           = "EFS Security Group for ${module.efs_context.id}"
  security_group_name                  = []
  security_groups                      = []
  throughput_mode                      = "bursting"
  transition_to_ia                     = ["AFTER_30_DAYS"]
  transition_to_primary_storage_class  = []
  zone_id                              = []
}

resource "aws_security_group_rule" "default" {
  count                    = module.context.enabled ? 1 : 0
  description              = "Security group rule to allow lambda function to access EFS."
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = try(module.lambda_security_group[0].id, "")
  security_group_id        = module.efs.security_group_id
}

resource "aws_efs_access_point" "default" {
  count          = module.context.enabled ? 1 : 0
  file_system_id = module.efs.id
  root_directory {
    path = "/lambda"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "777"
    }
  }
  posix_user {
    gid = 1000
    uid = 1000
  }
}
