#!/usr/bin/bash
# -*- coding: utf-8 -*-
set -e

echo Update certificate for \"$1\".

# Ensure presence of needed acme challenge locations.
mkdir --parents "${APPLIATION_PATH}/certificates/acme-challenge"
mkdir --parents "${2}letsEncrypt/.well-known"
ln \
    --force \
    --symbolic \
    "${APPLIATION_PATH}/certificates/acme-challenge" \
    "${2}letsEncrypt/.well-known/acme-challenge"

certbot renew \
    --config-dir "${2}letsEncrypt/configuration" \
    --email "$4" \
    --logs-dir "/tmp/$1/letsEncryptLog" \
    --non-interactive \
    --work-dir "${2}letsEncrypt"
# region modline
# vim: set tabstop=4 shiftwidth=4 expandtab filetype=dockerfile:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
