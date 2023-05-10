/*
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
  source  = "SevenPicoForks/efs/aws"
  version = "2.0.0"
  context = module.efs_context.self

  #required
  subnets = var.vpc_private_subnet_ids
  vpc_id  = var.vpc_id

  #optional
  access_points                        = {}
  additional_security_group_rules      = []
  allowed_cidr_blocks                  = []
  allowed_security_group_ids           = concat([module.ecs_sonarqube_service.security_group_id, var.openvpn_security_group_id])
  associated_security_group_ids        = []
  availability_zone_name               = null
  create_security_group                = true
  efs_backup_policy_enabled            = false
  encrypted                            = true
  kms_key_id                           = null
  mount_target_ip_address              = null
  performance_mode                     = "generalPurpose"
  provisioned_throughput_in_mibps      = 0
  region                               = var.region
  security_group_create_before_destroy = true
  security_group_create_timeout        = "10m"
  security_group_delete_timeout        = "15m"
  security_group_description           = "EFS Security Group"
  security_group_name                  = []
  security_groups                      = []
  throughput_mode                      = "bursting"
  transition_to_ia                     = ["AFTER_30_DAYS"]
  transition_to_primary_storage_class  = []
  zone_id                              = []
}

*/