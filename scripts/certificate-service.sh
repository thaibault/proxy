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
declare delay="${PROXY_CERTIFICATES_START_UPDATE_DELAY:-'50m'}"
echo "Wait $delay until first certificate update check."
sleep $delay

declare certificate_path
declare command
declare domain_path
declare email_address
declare index
declare name

while true; do
    for index in "${!PROXY_CERTIFICATES[@]}"; do
        name="${PROXY_CERTIFICATES[index]}"

        echo "Start checking certificate \"${name}\"."

        certificate_path="${APPLICATION_PATH}certificates/${name}/"
        mkdir --parents "$certificate_path"

        if [ "${PROXY_CERTIFICATE_EMAIL_ADDRESSES[index]}" != '' ]; then
            email_address="${PROXY_CERTIFICATE_EMAIL_ADDRESSES[index]}"
        fi

        command_line_arguments="${name} '${certificate_path}' '${PROXY_CERTIFICATE_DOMAINS[index]}' '${email_address}'"
        domain_path="${certificate_path}domains.txt"

        # If certificates already exists as specified only update existing ones
        # and retrieve them initially otherwise.
        if \
            [ -f "$domain_path" ] && \
            [ "${PROXY_CERTIFICATE_DOMAINS[index]}" = "$(cat "$domain_path")" ]
        then
            # NOTE: Server configuration file updates have to be run as root to
            # be able to temporary manipulate nginx configuration files:

            eval "update-certificate ${command_line_arguments}"

            chown \
                --recursive \
                "${MAIN_USER_NAME}:${MAIN_USER_GROUP_NAME}" \
                "${APPLICATION_PATH}certificates" \
                "/tmp/${name}/letsEncryptLog"

            # If we do not use the nginx plugin installer "--installer null"
            # we can run the renewal as application user and have to reload
            # the server via an hook. But this is not working yet since the
            # pid file is always to be owened by root not matter who starts
            # nginx.

            #su \
            #    "$MAIN_USER_NAME" \
            #    --group "$MAIN_USER_GROUP_NAME" \
            #    -c "APPLICATION_PATH='${APPLICATION_PATH}' update-certificate ${command_line_arguments}"
        else
            rm --force "$domain_path" &>/dev/null || true

            run-command
                "APPLICATION_PATH='${APPLICATION_PATH}' retrieve-certificate ${command_line_arguments}"

            echo "${PROXY_CERTIFICATE_DOMAINS[index]}" >"$domain_path"
        fi

        echo "Stopped checking certificate \"${name}\"."
    done

    echo Wait 24 hours until next certificate update check.
    sleep 24h
done
# region modline
# vim: set tabstop=4 shiftwidth=4 expandtab filetype=dockerfile:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
