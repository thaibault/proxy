#!/usr/bin/env bash
# -*- coding: utf-8 -*-
set -e

declare certificate_path
declare domains
declare domain_path
declare email_address
declare index
declare name

for index in "${!PROXY_CERTIFICATES[@]}"; do
    domains=${PROXY_CERTIFICATE_DOMAINS[index]}
    name="${PROXY_CERTIFICATES[index]}"
    certificate_path="${APPLICATION_PATH}certificates/${name}/"
    run-command "mkdir --parents '$certificate_path'"

    if [ "${PROXY_CERTIFICATE_EMAIL_ADDRESSES[index]}" != '' ]; then
        email_address="${PROXY_CERTIFICATE_EMAIL_ADDRESSES[index]}"
    fi

    domain_path="${certificate_path}domains.txt"
    # If certificates already exists as specified in manifest file do nothing.
    if \
        [ ! -f "$domain_path" ] || \
        [[ "${domains}" != "$(cat "$domain_path")" ]]
    then
        rm --force "$domain_path" &>/dev/null || true

        # NOTE: Certbot retrieving have to be run as root to be able to open
        # tcp ports.
        # shellcheck disable=SC2154
        eval "retrieve-certificate ${command_line_arguments}  --initialize ${name} '${certificate_path}' '${domains}' '${email_address}'"
        chown \
            --recursive \
            "${MAIN_USER_NAME}:${MAIN_USER_GROUP_NAME}" \
            "${APPLICATION_PATH}certificates" \
            "/tmp/${name}/letsEncryptLog"
        #run-command \
        #    "APPLICATION_PATH='${APPLICATION_PATH}' retrieve-certificate --initialize ${name} '${certificate_path}' '${domains}' '${email_address}'"

        run-command "echo '${domains}' >'${domain_path}'"
    fi

    # NOTE: Synchronize already existing certificates as well to bring a newly
    # connected cloudflare zone up to date on startup. A failing upload should
    # not prevent the proxy from starting.
    if [ "${PROXY_CERTIFICATE_CLOUDFLARE_ZONE_IDS[index]}" != '' ]; then
        PROXY_CLOUDFLARE_API_TOKEN="${PROXY_CERTIFICATE_CLOUDFLARE_API_TOKENS[index]:-$PROXY_CLOUDFLARE_API_TOKEN}" \
        PROXY_CLOUDFLARE_API_URL="$PROXY_CLOUDFLARE_API_URL" \
        PROXY_CLOUDFLARE_BUNDLE_METHOD="$PROXY_CLOUDFLARE_BUNDLE_METHOD" \
        PROXY_CLOUDFLARE_CERTIFICATE_TYPE="$PROXY_CLOUDFLARE_CERTIFICATE_TYPE" \
            synchronize-cloudflare-certificate \
                "$name" \
                "$certificate_path" \
                "${PROXY_CERTIFICATE_CLOUDFLARE_ZONE_IDS[index]}" || \
            echo "Synchronizing certificate \"${name}\" to cloudflare failed." \
                >&2
    fi
done
# region modline
# vim: set tabstop=4 shiftwidth=4 expandtab filetype=dockerfile:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
