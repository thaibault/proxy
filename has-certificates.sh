#!/usr/bin/bash
# -*- coding: utf-8 -*-
set -e

declare domain_path
declare index
for index in "${!PROXY_CERTIFICATES[@]}"; do
    domain_path="${APPLICATION_PATH}certificates/${PROXY_CERTIFICATES[index]}/domains.txt"

    if \
        [ ! -f "$domain_path" ] || \
        [[ "${PROXY_CERTIFICATE_DOMAINS[index]}" != "$(cat "$domain_path")" ]]
    then
        exit 1
    fi
done
# region modline
# vim: set tabstop=4 shiftwidth=4 expandtab filetype=dockerfile:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
