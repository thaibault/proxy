#!/usr/bin/env bash
# -*- coding: utf-8 -*-
set -e

source get-bashlink

# Uploads (or replaces) the current certbot managed certificate as custom
# certificate into a cloudflare zone. Nothing is done if the current
# certificate has already been synchronized.
#
# Usage:
# PROXY_CLOUDFLARE_API_TOKEN=TOKEN synchronize-cloudflare-certificate \
#     NAME CERTIFICATE_PATH ZONE_ID
#
# The api token needs the permission "Zone - SSL and Certificates - Edit" for
# the given zone.

declare -r name="$1"
declare -r certificate_path="$2"
declare -r zone_id="$3"

declare -r api_url="${PROXY_CLOUDFLARE_API_URL:-https://api.cloudflare.com/client/v4}/zones/${zone_id}/custom_certificates"
declare -r bundle_method="${PROXY_CLOUDFLARE_BUNDLE_METHOD:-ubiquitous}"
declare -r certificate_type="${PROXY_CLOUDFLARE_CERTIFICATE_TYPE:-sni_custom}"

declare -r live_path="${certificate_path}letsEncrypt/configuration/live/${name}/"
declare -r certificate_file_path="${live_path}fullchain.pem"
declare -r private_key_file_path="${live_path}privkey.pem"

# Holds the cloudflare certificate id and the fingerprint of the last
# synchronized certificate.
declare -r id_file_path="${certificate_path}cloudflareCertificateID.txt"
declare -r fingerprint_file_path="${certificate_path}cloudflareCertificateFingerprint.txt"

if [ "$PROXY_CLOUDFLARE_API_TOKEN" = '' ]; then
    bl.logging.error \
        "No cloudflare api token provided to synchronize certificate \"${name}\"."
    exit 1
fi

if ! [ -f "$certificate_file_path" ] || ! [ -f "$private_key_file_path" ]; then
    bl.logging.error \
        "Certificate \"${name}\" does not exist yet in \"${live_path}\"."
    exit 1
fi

declare fingerprint
fingerprint="$(
    cat "$certificate_file_path" "$private_key_file_path" | \
        sha256sum | \
        cut --delimiter ' ' --fields 1
)"
declare -r fingerprint

declare certificate_id=''
if [ -f "$id_file_path" ]; then
    certificate_id="$(cat "$id_file_path")"
fi

if \
    [ "$certificate_id" != '' ] && \
    [ -f "$fingerprint_file_path" ] && \
    [ "$fingerprint" = "$(cat "$fingerprint_file_path")" ]
then
    bl.logging.info \
        "Certificate \"${name}\" is already synchronized with cloudflare" \
        "zone \"${zone_id}\"."
    exit 0
fi

declare payload
payload="$(
    jq \
        --null-input \
        --arg bundle_method "$bundle_method" \
        --arg type "$certificate_type" \
        --rawfile certificate "$certificate_file_path" \
        --rawfile private_key "$private_key_file_path" \
        '{
            bundle_method: $bundle_method,
            certificate: $certificate,
            private_key: $private_key,
            type: $type
        }'
)"
declare -r payload

# Sends given payload with given http method to given url and prints the
# response body. Fails on transport errors only.
request() {
    curl \
        --connect-timeout 30 \
        --data-binary @- \
        --header "Authorization: Bearer ${PROXY_CLOUDFLARE_API_TOKEN}" \
        --header 'Content-Type: application/json' \
        --request "$1" \
        --retry 3 \
        --silent \
        --show-error \
        "$2" <<<"$payload"
}

declare response=''
if [ "$certificate_id" != '' ]; then
    bl.logging.info \
        "Replace custom certificate \"${certificate_id}\" for \"${name}\"" \
        "in cloudflare zone \"${zone_id}\"."

    response="$(request PATCH "${api_url}/${certificate_id}")"

    if [ "$(jq --raw-output '.success' <<<"$response")" != 'true' ]; then
        bl.logging.warn \
            "Replacing custom certificate \"${certificate_id}\" failed" \
            "(falling back to create a new one):" \
            "$(jq --compact-output '.errors' <<<"$response")"

        certificate_id=''
    fi
fi

if [ "$certificate_id" = '' ]; then
    bl.logging.info \
        "Create custom certificate for \"${name}\" in cloudflare zone" \
        "\"${zone_id}\"."

    response="$(request POST "$api_url")"

    if [ "$(jq --raw-output '.success' <<<"$response")" != 'true' ]; then
        bl.logging.error \
            "Creating custom certificate for \"${name}\" failed:" \
            "$(jq --compact-output '.errors' <<<"$response")"
        exit 1
    fi
fi

jq --raw-output '.result.id' <<<"$response" >"$id_file_path"
echo "$fingerprint" >"$fingerprint_file_path"

bl.logging.info \
    "Synchronized certificate \"${name}\" as custom certificate" \
    "\"$(cat "$id_file_path")\" (expires on" \
    "$(jq --raw-output '.result.expires_on' <<<"$response")) to cloudflare" \
    "zone \"${zone_id}\"."
# region modline
# vim: set tabstop=4 shiftwidth=4 expandtab filetype=dockerfile:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
