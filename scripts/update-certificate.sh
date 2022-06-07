#!/usr/bin/bash
# -*- coding: utf-8 -*-
set -e

echo Update certificate for \"$1\".

# Ensure presence of needed acme challenge locations.
mkdir --parents "${APPLIATION_PATH}certificates/acme-challenge"
mkdir --parents "${2}letsEncrypt/.well-known"
ln \
    --force \
    --symbolic \
    "${APPLIATION_PATH}certificates/acme-challenge" \
    "${2}letsEncrypt/.well-known/acme-challenge"

certbot renew \
    --agree-tos \
    --cert-name "$1" \
    --config-dir "${2}letsEncrypt/configuration" \
    --email "$4" \
    --expand \
    --keep-until-expiring \
    --logs-dir "/tmp/${1}/letsEncryptLog" \
    --nginx \
    --non-interactive \
    --renew-with-new-domains \
    --verbose \
    --work-dir "${2}letsEncrypt"
# region modline
# vim: set tabstop=4 shiftwidth=4 expandtab filetype=dockerfile:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
