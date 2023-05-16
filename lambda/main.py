#!/usr/bin/env python3

import os
import shutil
import boto3
import certbot.main
import json

# Let’s Encrypt acme-v02 server that supports wildcard certificates
CERTBOT_SERVER = 'https://acme-v02.api.letsencrypt.org/directory'

# Temp dir of Lambda runtime
CERTBOT_DIR = '/tmp/certbot'

cert = "CERTIFICATE"
privkey = "CERTIFICATE_PRIVATE_KEY"
chain = "CERTIFICATE_CHAIN"
csr = "CERTIFICATE_SIGNING_REQUEST"


def rm_tmp_dir():
    if os.path.exists(CERTBOT_DIR):
        try:
            shutil.rmtree(CERTBOT_DIR)
        except NotADirectoryError:
            os.remove(CERTBOT_DIR)


def obtain_certs(domains):
    certbot_args = [
        # Override directory paths so script doesn't have to be run as root
        '--config-dir', CERTBOT_DIR,
        '--work-dir', CERTBOT_DIR,
        '--logs-dir', CERTBOT_DIR,

        # Obtain a cert but don't install it
        'certonly',

        # Run in non-interactive mode
        '--non-interactive',

        # Agree to the terms of service
        '--agree-tos',

        # Email of domain administrators
        '--register-unsafely-without-email',

        # Use dns challenge with dns plugin
        '--dns-route53',

        # Use this server instead of default acme-v01
        '--server', CERTBOT_SERVER,

        # Domains to provision certs for (comma separated)
        '--domains', domains,
    ]
    return certbot.main.main(certbot_args)


# /tmp/certbot
# ├── live
# │   └── [domain]
# │       ├── README
# │       ├── cert.pem
# │       ├── chain.pem
# │       ├── fullchain.pem
# │       └── privkey.pem
def upload_certs(secret_arn, kms_key_arn, domains):
    with open(f"{CERTBOT_DIR}/live/{domains}/cert.pem") as f:
        cert_value = f.read()
    with open(f"{CERTBOT_DIR}/live/{domains}/privkey.pem") as f:
        privkey_value = f.read()
    with open(f"{CERTBOT_DIR}/live/{domains}/chain.pem") as f:
        chain_value = f.read()
    with open(f"{CERTBOT_DIR}/csr/0000_csr-certbot.pem") as f:
        csr_value = f.read()

    secret_data = {
        cert: cert_value,
        privkey: privkey_value,
        chain: chain_value,
        csr: csr_value
    }
    client = boto3.client('secretsmanager')
    secret_value = json.dumps(secret_data)
    client.update_secret(SecretId=secret_arn, KmsKeyId=kms_key_arn, SecretString=secret_value)


def upload_into_efs():
    destination_dir = '/mnt/efs/certbot'
    if os.path.exists(destination_dir):
        shutil.rmtree(destination_dir)
        print(os.listdir('/mnt/efs'))

    shutil.copytree(CERTBOT_DIR, destination_dir)
    print(os.listdir('/mnt/efs'))
    print(os.listdir(destination_dir))


def guarded_handler(event, context):
    # Input parameters from environment variables
    domains = os.getenv('DOMAINS')
    secret_arn = os.getenv('SECRET_ARN')
    kms_key_arn = os.getenv('KMS_KEY_ARN')

    obtain_certs(domains)
    upload_certs(secret_arn, kms_key_arn, domains)
    upload_into_efs()

    return 'Certificates obtained and uploaded successfully.'


def lambda_handler(event, context):
    try:
        rm_tmp_dir()
        return guarded_handler(event, context)
    finally:
        rm_tmp_dir()
