#!/usr/bin/bash
# -*- coding: utf-8 -*-
set -e

echo Update certificate for \\"$1\\".

certbot renew \
    --config-dir "${2}letsEncrypt/configuration" \
    --email "$4" \
    --logs-dir "/tmp/$1/letsEncryptLog" \
    --work-dir "${2}letsEncrypt"
# region modline
# vim: set tabstop=4 shiftwidth=4 expandtab filetype=dockerfile:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
