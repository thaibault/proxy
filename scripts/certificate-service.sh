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

# NOTE: Wait a bit before starting to avoid making too many challenges when
# application restarts many times in short period.
sleep 50m

declare certificate_path
declare command
declare domain_path
declare email_address
declare index

while true; do
    for index in "${!PROXY_CERTIFICATES[@]}"; do
        certificate_path="${APPLICATION_PATH}certificates/${PROXY_CERTIFICATES[index]}/"
        mkdir --parents "$certificate_path"

        if [ "${PROXY_CERTIFICATE_EMAIL_ADDRESSES[index]}" != '' ]; then
            email_address="${PROXY_CERTIFICATE_EMAIL_ADDRESSES[index]}"
        fi

        domain_path="${certificate_path}domains.txt"
        # If certificates already exists as specified only update and retrieve
        # otherwise.
        if \
            [ -f "$domain_path" ] && \
            [ "${PROXY_CERTIFICATE_DOMAINS[index]}" = "$(cat "$domain_path")" ]
        then
            command=update-certificate
        else
            rm --force "$domain_path" &>/dev/null || true

            command=retrieve-certificate
        fi

        su \
            "$MAIN_USER_NAME" \
            --group "$MAIN_USER_GROUP_NAME" \
            -c "APPLICATION_PATH='${APPLICATION_PATH}' ${command} ${PROXY_CERTIFICATES[index]} '${certificate_path}' '${PROXY_CERTIFICATE_DOMAINS[index]}' '${email_address}'"

        if [ "$command" = 'retrieve-certificate' ]; then
            echo "${PROXY_CERTIFICATE_DOMAINS[index]}" >"$domain_path"
        fi
    done

    echo Wait 24 hours until next certificate update check.
    sleep 24h
done
# region modline
# vim: set tabstop=4 shiftwidth=4 expandtab filetype=dockerfile:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
