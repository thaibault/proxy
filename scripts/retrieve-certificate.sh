#!/usr/bin/bash
# -*- coding: utf-8 -*-
set -e

declare mode="--webroot -w '${2}letsEncrypt'"
if [ "$1" = '--initialize' ]; then
    # NOTE: In this case no server has started yet.
    mode='--standalone'

    shift
fi

rm --force --recursive "/tmp/${1}/letsEncryptLog" &>/dev/null || true
mkdir --parents "/tmp/${1}/letsEncryptLog"

# Refresh presence of needed acme challenge locations.
mkdir --parents "${APPLICATION_PATH}certificates/acme-challenge"
rm --force --recursive "${2}letsEncrypt" &>/dev/null || true
mkdir --parents "${2}letsEncrypt/.well-known"
ln \
    --force \
    --symbolic \
    "${APPLICATION_PATH}certificates/acme-challenge" \
    "${2}letsEncrypt/.well-known/acme-challenge"

declare domains=''
declare domain_descriptions=''
for name in $3; do
    domains+=" -d ${name}"

    if [ "$domain_descriptions" = '' ]; then
        domain_descriptions+="\"${name}\""
    else
        domain_descriptions+=", \"${name}\""
    fi
done

echo Retrieve certificate for \"$1\" \(${domain_descriptions[@]}\).

# NOTE: For testing use "--test-cert".
certbot certonly \
    --agree-tos \
    --cert-name "$1" \
    --config-dir "${2}letsEncrypt/configuration" \
    --email "$4" \
    --expand \
    --logs-dir "/tmp/${1}/letsEncryptLog" \
    --non-interactive \
    --renew-with-new-domains \
    --preferred-challenges http \
    --verbose \
    $mode \
    --work-dir "${2}letsEncrypt"\
    $domains

# Prepare configuration to be able to update certificate by using the nginx web
# server.
sed \
    --in-place \
    --regexp-extended 's/^(authenticator += +)standalone$/\1nginx/' \
    "${2}letsEncrypt/configuration/renewal/${1}.conf"
# region modline
# vim: set tabstop=4 shiftwidth=4 expandtab filetype=dockerfile:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
