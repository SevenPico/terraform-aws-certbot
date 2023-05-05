import os
import shutil
import boto3
import certbot.main
import json

import config

config = config.Config()

# Let’s Encrypt acme-v02 server that supports wildcard certificates
CERTBOT_SERVER = 'https://acme-v02.api.letsencrypt.org/directory'

# Temp dir of Lambda runtime
CERTBOT_DIR = '/tmp/certbot'


def rm_tmp_dir():
    if os.path.exists(CERTBOT_DIR):
        try:
            shutil.rmtree(CERTBOT_DIR)
        except NotADirectoryError:
            os.remove(CERTBOT_DIR)


def obtain_certs(emails, domains, dns_plugin):
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
        '--email', emails,

        # Use dns challenge with dns plugin
        '--authenticator', dns_plugin,
        '--preferred-challenges', 'dns-01',

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
def upload_certs():
    with open("/tmp/cert.pem") as f:
        cert = f.read()
    with open("/tmp/privkey.pem") as f:
        privkey = f.read()
    with open("/tmp/chain.pem") as f:
        chain = f.read()

    secret_data = {
        "cert": cert,
        "privkey": privkey,
        "chain": chain,
    }
    client = boto3.client('secretsmanager')
    secret_value = json.dumps(secret_data)
    client.update_secret(SecretId=config.secret_arn, SecretString=secret_value)

