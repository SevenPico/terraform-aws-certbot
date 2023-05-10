#!/bin/bash

set -e

#readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR="/tmp/certbot"
#mkdir -p $SCRIPT_DIR
cp /var/task/requirements.txt /tmp/certbot/

ls -lrt /tmp/certbot/
readonly CERTBOT_VERSION=$( awk -F= '$1 == "certbot"{ print $NF; }' "${SCRIPT_DIR}/requirements.txt" )
readonly VENV="/certbot/venv"
readonly PYTHON="python3.9"
readonly CERTBOT_ZIP_FILE="certbot-${CERTBOT_VERSION}.zip"
readonly CERTBOT_SITE_PACKAGES=${VENV}/lib/${PYTHON}/site-packages
ls -lrt
pwd
cd "${SCRIPT_DIR}"
#echo "${BASH_SOURCE[0]}"
ls -lrt /tmp
${PYTHON} -m venv "/tmp/${VENV}"
source "/tmp/${VENV}/bin/activate"

pip3 install -r requirements.txt

pushd /tmp${CERTBOT_SITE_PACKAGES}
    zip -r -q ${SCRIPT_DIR}/certbot/${CERTBOT_ZIP_FILE} . -x "/*__pycache__/*"
popd

zip -g "certbot/${CERTBOT_ZIP_FILE}" *.py