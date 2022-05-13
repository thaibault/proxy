#!/usr/bin/bash
# -*- coding: utf-8 -*-
set -e

declare certificate_path
declare domain_path
declare email_address
declare index

for index in "${!PROXY_CERTIFICATES[@]}"; do
    certificate_path="${APPLICATION_PATH}certificates/${PROXY_CERTIFICATES[index]}/"
    su \
        "$MAIN_USER_NAME" \
        --group "$MAIN_USER_GROUP_NAME" \
        -c "mkdir --parents '$certificate_path'"

    if [ "${PROXY_CERTIFICATE_EMAIL_ADDRESSES[index]}" != '' ]; then
        email_address="${PROXY_CERTIFICATE_EMAIL_ADDRESSES[index]}"
    fi

    domain_path="${certificate_path}domains.txt"
    # If certificates already exists as specified only update and retrieve
    # otherwise.
    if \
        [ ! -f "$domain_path" ] || \
        [[ "${PROXY_CERTIFICATE_DOMAINS[index]}" != "$(cat "$domain_path")" ]]
    then
        rm --force "$domain_path" &>/dev/null || true

        su \
            "$MAIN_USER_NAME" \
            --group "$MAIN_USER_GROUP_NAME" \
            -c "APPLICATION_PATH='${APPLICATION_PATH}' retrieve-certificate --initialize ${PROXY_CERTIFICATES[index]} '${certificate_path}' '${PROXY_CERTIFICATE_DOMAINS[index]}' '${email_address}'"

        su \
            "$MAIN_USER_NAME" \
            --group "$MAIN_USER_GROUP_NAME" \
            -c "echo '${PROXY_CERTIFICATE_DOMAINS[index]}' >'${domain_path}'"
    fi
done
# region modline
# vim: set tabstop=4 shiftwidth=4 expandtab filetype=dockerfile:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
