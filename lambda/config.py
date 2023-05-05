import os
import logging
from dataclasses import dataclass


def get_optional_var(name, default=None):
    try:
        return os.environ[name]
    except KeyError:
        logging.warn(f"Environment variable {name} not set. Using default: {default}")
        return default


def get_required_var(name):
    try:
        return os.environ[name]
    except KeyError:
        logging.critical(f"Environment variable {name} not set.")


@dataclass
class Config:
    secret_arn = get_optional_var('SECRET_ARN')
    emails = get_optional_var('EMAILS')
    domains = get_optional_var('DOMAINS')
    dns_plugin = get_optional_var('DNS_PLUGIN')

