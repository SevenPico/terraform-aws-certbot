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
  source     = "../../"
  context    = module.certbot_context.self
  depends_on = [module.ssl_certificate]

  keyname_certificate                 = "CERTIFICATE"
  keyname_certificate_chain           = "CERTIFICATE_CHAIN"
  keyname_certificate_signing_request = "CERTIFICATE_SIGNING_REQUEST"
  keyname_private_key                 = "CERTIFICATE_PRIVATE_KEY"
  target_secret_kms_key_arn           = module.ssl_certificate.kms_key_arn
  target_secret_arn                   = module.ssl_certificate.secret_arn
  vpc_id                              = module.vpc.vpc_id
  vpc_private_subnet_ids              = module.vpc_subnets.private_subnet_ids
}