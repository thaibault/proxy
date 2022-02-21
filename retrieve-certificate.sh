#!/usr/bin/bash
# -*- coding: utf-8 -*-
set -e

declare domains=''
for name in $2; do
    domains+=" -d ${name}"
done

certbot \
    certonly \
    --config-dir "${APPLICATION_PATH}certificates/$1/letsEncrypt/configuration" \
    --email "$3" \
    --logs-dir "/tmp/$1/letsEncryptLog" \
    --preferred-challenges http \
    --server https://acme-v02.api.letsencrypt.org/directory \
    --webroot -w "${APPLICATION_PATH}certificates/$1/letsEncrypt" \
    --work-dir "${APPLICATION_PATH}certificates/$1/letsEncrypt"\
    $domains
# region modline
# vim: set tabstop=4 shiftwidth=4 expandtab filetype=dockerfile:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
