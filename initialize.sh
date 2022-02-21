#!/usr/bin/bash
# -*- coding: utf-8 -*-
set -e
# 1. Checks if newer initializer is bind into container and exec into to if
# present.
# 2. Loads environment files if existing.
source prepare-initializer "$@"

# Remove indicator to load latest initializer file.
if [ "$1" = '--no-check-local-initializer' ]; then
    shift
fi

source decrypt "$@"

source configure-runtime-user

certbot_service() {
    local wait=true
    local index
    for index in "${!PROXY_CERTIFICATES[@]}"; do
        local domain_path="${APPLICATION_PATH}certificates/${CERTIFICATES[index]}/domains.txt"
        if \
            [ ! -f "$domain_path" ] || \
            [[ "${PROXY_CERTIFICATE_DOMAINS[index]}" != "$(cat "$domain_path)" ]]
        then
            wait=false
            break
        fi
    done
    if $wait; then
        # NOTE: Wait if an old certificates matches configuration to avoid
        # making to many challenges when application restarts many times.
        sleep 50m
    fi

    while true; do
        local email_address
        for index in "${!PROXY_CERTIFICATES[@]}"; do
            mkdir --parents "/tmp/${CERTIFICATES[index]}/letsEncryptLog"

            local command
            local domain_path="${APPLICATION_PATH}certificates/${CERTIFICATES[index]}/domains.txt"
            if \
                [ -f "$domain_path" ] && \
                [ "${PROXY_CERTIFICATE_DOMAINS[index]}" = "$(cat "$domain_path)" ]
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
                -c "APPLICATION_PATH='${APPLICATION_PATH}' ${command} '${CERTIFICATES[index]}' '${PROXY_CERTIFICATE_DOMAINS[index]}' '${PROXY_CERTIFICATE_EMAIL_ADDRESSES[index]}' '${email_address}'"
        done

        sleep 24h
    done
}
if [[ "$PROXY_CERTIFICATES" != '' ]]; then
    certbot_service &
fi

source run-command "$@"
# region modline
# vim: set tabstop=4 shiftwidth=4 expandtab filetype=dockerfile:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
