#!/usr/bin/bash
# -*- coding: utf-8 -*-
set -e

rm --force --recursive "/tmp/$1/letsEncryptLog" &>/dev/null || true
mkdir --parents "/tmp/$1/letsEncryptLog"

declare domains=''
for name in $3; do
    domains+=" -d ${name}"
done

rm --force --recursive "${2}letsEncrypt" &>/dev/null || true

certbot certonly \
    --config-dir "${2}letsEncrypt/configuration" \
    --email "$4" \
    --logs-dir "/tmp/$1/letsEncryptLog" \
    --preferred-challenges http \
    --server https://acme-v02.api.letsencrypt.org/directory \
    --webroot -w "${2}letsEncrypt" \
    --work-dir "${2}letsEncrypt"\
    $domains
# region modline
# vim: set tabstop=4 shiftwidth=4 expandtab filetype=dockerfile:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
