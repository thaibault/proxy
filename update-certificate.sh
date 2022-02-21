#!/usr/bin/bash
# -*- coding: utf-8 -*-
set -e

certbot \
    renew \
    --config-dir "${APPLICATION_PATH}certificates/$1/letsEncrypt/configuration" \
    --email "$3" \
    --logs-dir "/tmp/$1/letsEncryptLog" \
    --work-dir "${APPLICATION_PATH}certificates/$1/letsEncrypt"
# region modline
# vim: set tabstop=4 shiftwidth=4 expandtab filetype=dockerfile:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
