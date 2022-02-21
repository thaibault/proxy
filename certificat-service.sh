#!/usr/bin/bash
# -*- coding: utf-8 -*-
set -e

# Example environment configuration:
# APPLICATION_PATH='./'
#
# PROXY_CERTIFICATES=(service service.staging)
# PROXY_CERTIFICATE_DOMAINS=(
#     'service.com service-variation.com'
#     'service.staging.com service-variation.staging.com'
# )
# PROXY_CERTIFICATE_EMAIL_ADDRESSES=(service@info.com)

declare domain_path

declare wait=true
declare index
for index in "${!PROXY_CERTIFICATES[@]}"; do
    domain_path="${APPLICATION_PATH}certificates/${PROXY_CERTIFICATES[index]}/domains.txt"
    if \
        [ ! -f "$domain_path" ] || \
        [[ "${PROXY_CERTIFICATE_DOMAINS[index]}" != "$(cat "$domain_path")" ]]
    then
        wait=false
        break
    fi
done
if $wait; then
    # NOTE: Wait if an old certificates matches configuration to avoid making
    # to many challenges when application restarts many times.
    sleep 50m
fi

declare command
declare email_address
while true; do
    for index in "${!PROXY_CERTIFICATES[@]}"; do
        mkdir --parents "/tmp/${PROXY_CERTIFICATES[index]}/letsEncryptLog"
        mkdir --parents "${APPLICATION_PATH}certificates/${PROXY_CERTIFICATES[index]}"

        domain_path="${APPLICATION_PATH}certificates/${PROXY_CERTIFICATES[index]}/domains.txt"
        if \
            [ -f "$domain_path" ] && \
            [ "${PROXY_CERTIFICATE_DOMAINS[index]}" = "$(cat "$domain_path")" ]
        then
            command=update-certificate
        else
            rm --force "$domain_path" &>/dev/null || true

            command=retrieve-certificate

            echo "${PROXY_CERTIFICATE_DOMAINS[index]}" >"$domain_path"
        fi

        if [ "${PROXY_CERTIFICATE_EMAIL_ADDRESSES[index]}" != '' ]; then
            email_address="${PROXY_CERTIFICATE_EMAIL_ADDRESSES[index]}"
        fi

        exec su \
            "$MAIN_USER_NAME" \
            --group "$MAIN_USER_GROUP_NAME" \
            -c "APPLICATION_PATH='${APPLICATION_PATH}' ${command} '${PROXY_CERTIFICATES[index]}' '${PROXY_CERTIFICATE_DOMAINS[index]}' '${email_address}'"
    done

    echo Wait for 24 hours for next certificate update check.
    sleep 24h
done
# region modline
# vim: set tabstop=4 shiftwidth=4 expandtab filetype=dockerfile:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
