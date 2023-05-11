#------------------------------------------------------------------------------
# Certbot Context
#------------------------------------------------------------------------------
module "certbot_context" {
  source  = "SevenPico/context/null"
  version = "2.0.0"
  context = module.context.self
  name    = "certbot"
}



#------------------------------------------------------------------------------
# Certbot
#------------------------------------------------------------------------------
module "certbot" {
  source  = "../../"
  context = module.certbot_context.self
  target_secret_kms_key_arn = module.secret.kms_key_arn
  target_secret_arn = module.secret.arn
  vpc_id = module.vpc.vpc_id
  vpc_private_subnet_ids = module.vpc_subnets.private_subnet_ids
}