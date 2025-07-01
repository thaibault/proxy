#!/usr/bin/env bash
# -*- coding: utf-8 -*-
set -e

echo "Update certificate for \"$1\"."

# Ensure presence of needed acme challenge locations.
run-command mkdir --parents "${APPLICATION_PATH}certificates/acme-challenge"
run-command mkdir --parents "${2}letsEncrypt/.well-known"
# Avoid nested linking by first removing old one.
rm "${2}letsEncrypt/.well-known/acme-challenge" &>/dev/null || true
run-command ln \
    --force \
    --symbolic \
    "${APPLICATION_PATH}certificates/acme-challenge" \
    "${2}letsEncrypt/.well-known/acme-challenge"

certbot renew \
    --agree-tos \
    --cert-name "$1" \
    --config-dir "${2}letsEncrypt/configuration" \
    --disable-renew-updates \
    --email "$4" \
    --expand \
    --installer null \
    --keep-until-expiring \
    --logs-dir "/tmp/${1}/letsEncryptLog" \
    --non-interactive \
    --renew-with-new-domains \
    --verbose \
    --work-dir "${2}letsEncrypt"
# region modline
# vim: set tabstop=4 shiftwidth=4 expandtab filetype=dockerfile:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
