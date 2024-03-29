"""
-------------------------------------------------------------------------------
Copyright 2023 SevenPico, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
./lambda/main.py
This file contains code written only by SevenPico, Inc.
-------------------------------------------------------------------------------
"""

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

cert = os.getenv('KEYNAME_CERTIFICATE')
privkey = os.getenv('KEYNAME_PRIVATE_KEY')
chain = os.getenv('KEYNAME_CERTIFICATE_CHAIN')
csr = os.getenv('KEYNAME_CERTIFICATE_SIGNING_REQUEST')


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
def upload_certs(secret_arn, kms_key_arn, domain_for_directory):
    with open(f"{CERTBOT_DIR}/live/{domain_for_directory}/cert.pem") as f:
        cert_value = f.read()
    with open(f"{CERTBOT_DIR}/live/{domain_for_directory}/privkey.pem") as f:
        privkey_value = f.read()
    with open(f"{CERTBOT_DIR}/live/{domain_for_directory}/chain.pem") as f:
        chain_value = f.read()
    with open(f"{CERTBOT_DIR}/csr/0000_csr-certbot.pem") as f:
        csr_value = f.read()

    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId=secret_arn)
    secret_data = json.loads(response['SecretString'])

    secret_data[cert] = cert_value
    secret_data[privkey] = privkey_value
    secret_data[chain] = chain_value
    secret_data[csr] = csr_value

    updated_secret_value = json.dumps(secret_data)
    client.put_secret_value(SecretId=secret_arn, SecretString=updated_secret_value)


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
    domain_for_directory = os.getenv('DOMAIN_FOR_DIRECTORY')
    secret_arn = os.getenv('SECRET_ARN')
    kms_key_arn = os.getenv('KMS_KEY_ARN')

    obtain_certs(domains)
    upload_certs(secret_arn, kms_key_arn, domain_for_directory)
    upload_into_efs()

    return 'Certificates obtained and uploaded successfully.'


def lambda_handler(event, context):
    try:
        rm_tmp_dir()
        return guarded_handler(event, context)
    finally:
        rm_tmp_dir()
