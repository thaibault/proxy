#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# region header
# [Project page](https://tsickert.com/proxy)

# Copyright Torben Sickert (info["~at~"]tsickert.com) 16.12.2012

# License
# -------

# This library written by Torben Sickert stands under a creative commons naming
# 4.0 international license.
# See https://creativecommons.org/licenses/by/4.0/deed.de
# endregion
# Runs all scripts against fake external commands ("certbot", "curl", "nginx",
# containerbase helpers, ...) which record their calls. Runs without a
# container.
# shellcheck disable=SC2016
set -o errexit -o nounset -o pipefail

root_path="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work_path="$(mktemp --directory)"
# NOTE: "retrieve-certificate" writes its logs into "/tmp/<name>/".
name_prefix="proxy-test-$$-"
trap 'rm --force --recursive "$work_path" /tmp/"$name_prefix"*' EXIT

export CALL_LOG_FILE_PATH="${work_path}/calls.txt"

fail() {
    echo "FAILED: $*" 1>&2
    echo "Recorded calls:" 1>&2
    cat "$CALL_LOG_FILE_PATH" 1>&2 || true
    exit 1
}
reset_calls() {
    : >"$CALL_LOG_FILE_PATH"
}
# Each call is recorded as "NAME [ARGUMENT] [ARGUMENT] ...".
assert_called() {
    grep --fixed-strings --line-regexp --quiet -- "$1" "$CALL_LOG_FILE_PATH" ||
        fail "Expected call \"$1\"."
}
assert_not_called() {
    if grep --quiet -- "^$1\( \|$\)" "$CALL_LOG_FILE_PATH"; then
        fail "Unexpected call of \"$1\"."
    fi
}
count_calls() {
    grep --count -- "^$1\( \|$\)" "$CALL_LOG_FILE_PATH" || true
}
# Runs given script sourced (as "initialize.sh" does) after evaluating the
# configuration given via standard input (needed for arrays).
run_sourced() {
    local -r script_path="$1"
    shift
    cat >"${work_path}/configuration.sh"
    bash -c 'source "$1"; shift; source "$@"' \
        _ "${work_path}/configuration.sh" "$script_path" "$@"
}
# region provide fake environment
fake_path="${work_path}/bin"
mkdir "$fake_path"

cat >"${fake_path}/record-call" <<'EOF'
#!/usr/bin/env bash
# Records the call, fails if "FAIL_<NAME>" is set (dashes as underscores).
name="${RECORD_CALL_NAME:-$(basename "$0")}"
{
    printf '%s' "$name"
    printf ' [%s]' "$@"
    echo
} >>"$CALL_LOG_FILE_PATH"
variable_name="FAIL_${name//-/_}"
[ "${!variable_name:-}" = '' ]
EOF
chmod +x "${fake_path}/record-call"
for name in \
    chown \
    nginx \
    reload-nginx \
    retrieve-certificate \
    synchronize-cloudflare-certificate \
    update-certificate
do
    ln --symbolic record-call "${fake_path}/${name}"
done

# Sourced by the scripts under test.
cat >"${fake_path}/get-bashlink" <<'EOF'
bl.logging.error() { echo "error: $*" 1>&2; }
bl.logging.info() { echo "info: $*"; }
bl.logging.warn() { echo "warn: $*" 1>&2; }
EOF
for name in prepare-initializer decrypt configure-runtime-user; do
    echo "echo '${name}' \"\$@\" >>\"\$CALL_LOG_FILE_PATH\"" \
        >"${fake_path}/${name}"
done

cat >"${fake_path}/run-command" <<'EOF'
#!/usr/bin/env bash
eval "$*"
EOF

cat >"${fake_path}/certbot" <<'EOF'
#!/usr/bin/env bash
RECORD_CALL_NAME="$(basename "$0")" "$(dirname "$0")/record-call" "$@"
# Simulate a renewal configuration as created by a standalone retrieval.
if [ "$1" = certonly ]; then
    while (( $# > 0 )); do
        case "$1" in
            --cert-name) name="$2";;
            --config-dir) configuration_path="$2";;
        esac
        shift
    done
    mkdir --parents "${configuration_path}/renewal"
    printf 'version = 2\nauthenticator = standalone\n' \
        >"${configuration_path}/renewal/${name}.conf"
fi
EOF

# Prints the next file from "FAKE_CURL_RESPONSES_PATH" and stores each request
# body next to it.
cat >"${fake_path}/curl" <<'EOF'
#!/usr/bin/env bash
RECORD_CALL_NAME="$(basename "$0")" "$(dirname "$0")/record-call" "$@"
number="$(( $(ls "$FAKE_CURL_RESPONSES_PATH" | grep --count '^request-') + 1 ))"
cat >"${FAKE_CURL_RESPONSES_PATH}/request-${number}.json"
cat "${FAKE_CURL_RESPONSES_PATH}/response-${number}.json"
EOF

# Terminates the calling endless loop after "FAKE_SLEEP_LIMIT" daily waits.
cat >"${fake_path}/sleep" <<'EOF'
#!/usr/bin/env bash
RECORD_CALL_NAME="$(basename "$0")" "$(dirname "$0")/record-call" "$@"
if [ "$1" = 24h ] && (( $(grep --count '^sleep \[24h\]$' "$CALL_LOG_FILE_PATH") >= ${FAKE_SLEEP_LIMIT:-1} )); then
    kill "$PPID"
fi
EOF

chmod +x "$fake_path"/*
export PATH="${fake_path}:${PATH}"
# endregion
scripts_path="${root_path}/scripts/"
# region synchronize-cloudflare-certificate
synchronize="${scripts_path}synchronize-cloudflare-certificate.sh"
name="${name_prefix}cloudflare"
certificate_path="${work_path}/${name}/"
live_path="${certificate_path}letsEncrypt/configuration/live/${name}/"
export FAKE_CURL_RESPONSES_PATH="${work_path}/responses"
mkdir "$FAKE_CURL_RESPONSES_PATH"
set_responses() {
    rm --force "$FAKE_CURL_RESPONSES_PATH"/*
    local number=1
    local response
    for response in "$@"; do
        echo "$response" >"${FAKE_CURL_RESPONSES_PATH}/response-${number}.json"
        number=$((number + 1))
    done
}
success_response() {
    echo "{\"success\": true, \"errors\": [], \"result\": {\"id\": \"$1\", \"expires_on\": \"2027-01-01\"}}"
}
failure_response='{"success": false, "errors": [{"code": 1000, "message": "broken"}], "result": null}'
synchronize() {
    PROXY_CLOUDFLARE_API_TOKEN="${token-TOKEN}" \
    PROXY_CLOUDFLARE_API_URL=https://api.test \
        "$synchronize" "$name" "$certificate_path" ZONE &>"${work_path}/output.txt"
}

reset_calls
token='' synchronize && \
    fail Synchronizing without an api token should fail.
grep --quiet 'No cloudflare api token' "${work_path}/output.txt" || \
    fail Missing api token was not reported.

synchronize && \
    fail Synchronizing a missing certificate should fail.
grep --quiet 'does not exist yet' "${work_path}/output.txt" || \
    fail Missing certificate was not reported.
assert_not_called curl

mkdir --parents "$live_path"
printf -- '-----BEGIN CERTIFICATE-----\nfirst\n-----END CERTIFICATE-----\n' \
    >"${live_path}fullchain.pem"
printf -- '-----BEGIN PRIVATE KEY-----\nkey\n-----END PRIVATE KEY-----\n' \
    >"${live_path}privkey.pem"

# Creates a new custom certificate.
set_responses "$(success_response FIRST_ID)"
synchronize || fail Creating a custom certificate failed.
[ "$(count_calls curl)" = 1 ] || fail Expected exactly one request.
grep --quiet -- '\[--request\] \[POST\] .*\[https://api.test/zones/ZONE/custom_certificates\]$' \
    "$CALL_LOG_FILE_PATH" || \
    fail Custom certificate was not created via POST.
grep --quiet -- '\[Authorization: Bearer TOKEN\]' "$CALL_LOG_FILE_PATH" || \
    fail Api token was not sent.
[ "$(jq --raw-output .certificate "${FAKE_CURL_RESPONSES_PATH}/request-1.json")" = \
  "$(cat "${live_path}fullchain.pem")" ] || \
    fail Request does not contain the certificate.
[ "$(jq --raw-output .private_key "${FAKE_CURL_RESPONSES_PATH}/request-1.json")" = \
  "$(cat "${live_path}privkey.pem")" ] || \
    fail Request does not contain the private key.
[ "$(jq --raw-output '.bundle_method + " " + .type' "${FAKE_CURL_RESPONSES_PATH}/request-1.json")" = \
  'ubiquitous sni_custom' ] || \
    fail Request does not contain default bundle method and type.
[ "$(cat "${certificate_path}cloudflareCertificateID.txt")" = FIRST_ID ] || \
    fail Certificate id was not stored.
[ -s "${certificate_path}cloudflareCertificateFingerprint.txt" ] || \
    fail Certificate fingerprint was not stored.

# Does nothing if the certificate has not changed.
reset_calls
synchronize || fail Synchronizing an unchanged certificate failed.
assert_not_called curl
grep --quiet 'already synchronized' "${work_path}/output.txt" || \
    fail Unchanged certificate was not reported.

# Replaces the existing custom certificate after renewal.
reset_calls
echo renewed >>"${live_path}fullchain.pem"
set_responses "$(success_response FIRST_ID)"
synchronize || fail Replacing a custom certificate failed.
[ "$(count_calls curl)" = 1 ] || fail Expected exactly one request.
grep --quiet -- '\[--request\] \[PATCH\] .*\[https://api.test/zones/ZONE/custom_certificates/FIRST_ID\]$' \
    "$CALL_LOG_FILE_PATH" || \
    fail Custom certificate was not replaced via PATCH.

# Falls back to create a new one if replacing fails.
reset_calls
echo renewed >>"${live_path}fullchain.pem"
set_responses "$failure_response" "$(success_response SECOND_ID)"
synchronize || fail Falling back to create a custom certificate failed.
[ "$(count_calls curl)" = 2 ] || fail Expected a replace and a create request.
grep --quiet -- '\[POST\]' "$CALL_LOG_FILE_PATH" || \
    fail Fallback did not create a new custom certificate.
grep --quiet 'falling back to create a new one' "${work_path}/output.txt" || \
    fail Failed replacement was not reported.
[ "$(cat "${certificate_path}cloudflareCertificateID.txt")" = SECOND_ID ] || \
    fail New certificate id was not stored.

# Fails if creating fails and keeps the last synchronized state.
reset_calls
rm "${certificate_path}cloudflareCertificateID.txt"
fingerprint="$(cat "${certificate_path}cloudflareCertificateFingerprint.txt")"
echo renewed >>"${live_path}fullchain.pem"
set_responses "$failure_response"
synchronize && fail Failing creation should fail.
grep --quiet 'broken' "${work_path}/output.txt" || \
    fail Api errors were not reported.
[ "$(cat "${certificate_path}cloudflareCertificateFingerprint.txt")" = \
  "$fingerprint" ] || \
    fail Fingerprint was updated although synchronizing failed.
# endregion
# region retrieve-certificate
export APPLICATION_PATH="${work_path}/application/"
name="${name_prefix}retrieve"
certificate_path="${APPLICATION_PATH}certificates/${name}/"
configuration_file_path="${certificate_path}letsEncrypt/configuration/renewal/${name}.conf"

reset_calls
"${scripts_path}retrieve-certificate.sh" \
    --initialize "$name" "$certificate_path" 'a.test b.test' mail@a.test \
    >/dev/null || \
    fail Retrieving initially failed.
assert_called "certbot [certonly] [--agree-tos] [--cert-name] [${name}] [--config-dir] [${certificate_path}letsEncrypt/configuration] [--email] [mail@a.test] [--expand] [--logs-dir] [/tmp/${name}/letsEncryptLog] [--non-interactive] [--renew-with-new-domains] [--preferred-challenges] [http] [--verbose] [--standalone] [--work-dir] [${certificate_path}letsEncrypt] [-d] [a.test] [-d] [b.test]"
grep --quiet --line-regexp 'authenticator = nginx' "$configuration_file_path" || \
    fail Renewal configuration was not switched to nginx.
[ "$(readlink "${certificate_path}letsEncrypt/.well-known/acme-challenge")" = \
  "${APPLICATION_PATH}certificates/acme-challenge" ] || \
    fail Acme challenge location was not linked.
[ -d "/tmp/${name}/letsEncryptLog" ] || fail Log directory was not created.

reset_calls
"${scripts_path}retrieve-certificate.sh" \
    "$name" "$certificate_path" a.test mail@a.test >/dev/null || \
    fail Retrieving via webroot failed.
grep --quiet --fixed-strings -- \
    "[--verbose] [--webroot] [-w] [${certificate_path}letsEncrypt] [--work-dir]" \
    "$CALL_LOG_FILE_PATH" || \
    fail Webroot mode was not passed as separate arguments.
# endregion
# region update-certificate
name="${name_prefix}update"
certificate_path="${APPLICATION_PATH}certificates/${name}/"
# NOTE: An existing link has to be replaced instead of linking into its target.
mkdir --parents "${certificate_path}letsEncrypt/.well-known" "${work_path}/old"
ln --symbolic "${work_path}/old" \
    "${certificate_path}letsEncrypt/.well-known/acme-challenge"

reset_calls
"${scripts_path}update-certificate.sh" \
    "$name" "$certificate_path" a.test mail@a.test >/dev/null || \
    fail Updating failed.
assert_called "certbot [renew] [--agree-tos] [--cert-name] [${name}] [--config-dir] [${certificate_path}letsEncrypt/configuration] [--disable-renew-updates] [--email] [mail@a.test] [--expand] [--installer] [null] [--keep-until-expiring] [--logs-dir] [/tmp/${name}/letsEncryptLog] [--non-interactive] [--renew-with-new-domains] [--verbose] [--work-dir] [${certificate_path}letsEncrypt]"
[ "$(readlink "${certificate_path}letsEncrypt/.well-known/acme-challenge")" = \
  "${APPLICATION_PATH}certificates/acme-challenge" ] || \
    fail Acme challenge location was not linked.
[ -z "$(ls --almost-all "${work_path}/old")" ] || \
    fail Acme challenge location was linked into the old target.
# endregion
# region initialize-certificates
initialize_certificates_configuration='
    MAIN_USER_NAME=user
    MAIN_USER_GROUP_NAME=group
    PROXY_CERTIFICATES=(alpha beta)
    PROXY_CERTIFICATE_DOMAINS=("alpha.test www.alpha.test" beta.test)
    PROXY_CERTIFICATE_EMAIL_ADDRESSES=(mail@alpha.test)
    PROXY_CERTIFICATE_CLOUDFLARE_ZONE_IDS=("" ZONE)
    PROXY_CERTIFICATE_CLOUDFLARE_API_TOKENS=("" BETA_TOKEN)
    PROXY_CLOUDFLARE_API_TOKEN=GLOBAL_TOKEN
'
mkdir --parents "${APPLICATION_PATH}certificates/alpha"
echo 'alpha.test www.alpha.test' \
    >"${APPLICATION_PATH}certificates/alpha/domains.txt"

reset_calls
run_sourced "${scripts_path}initialize-certificates.sh" \
    <<<"$initialize_certificates_configuration" || \
    fail Initializing certificates failed.
[ "$(count_calls retrieve-certificate)" = 1 ] || \
    fail Only the certificate with changed domains should be retrieved.
# NOTE: The email address falls back to the last given one.
assert_called "retrieve-certificate [--initialize] [beta] [${APPLICATION_PATH}certificates/beta/] [beta.test] [mail@alpha.test]"
assert_called "chown [--recursive] [user:group] [${APPLICATION_PATH}certificates] [/tmp/beta/letsEncryptLog]"
[ "$(cat "${APPLICATION_PATH}certificates/beta/domains.txt")" = beta.test ] || \
    fail Domains were not stored.
assert_called "synchronize-cloudflare-certificate [beta] [${APPLICATION_PATH}certificates/beta/] [ZONE]"
[ "$(count_calls synchronize-cloudflare-certificate)" = 1 ] || \
    fail Certificates without a zone should not be synchronized.

# A failing synchronization should not prevent the proxy from starting.
reset_calls
FAIL_synchronize_cloudflare_certificate=true \
    run_sourced "${scripts_path}initialize-certificates.sh" \
        <<<"$initialize_certificates_configuration" \
        2>"${work_path}/output.txt" || \
    fail Failing synchronization stopped initialization.
assert_not_called retrieve-certificate
grep --quiet 'to cloudflare failed' "${work_path}/output.txt" || \
    fail Failing synchronization was not reported.
# endregion
# region certificate-service
# NOTE: Standard error is suppressed to hide the report of the terminated loop.
export CERTIFICATION_SERVICE_LOG="${work_path}/service.log"
rm --force --recursive "${APPLICATION_PATH}certificates/beta"

reset_calls
FAIL_synchronize_cloudflare_certificate=true \
    run_sourced "${scripts_path}certificate-service.sh" \
        <<<"$initialize_certificates_configuration" 2>/dev/null && \
    fail Service loop should only be stopped by the fake sleep.
assert_called 'sleep [50m]'
assert_called "update-certificate [alpha] [${APPLICATION_PATH}certificates/alpha/] [alpha.test www.alpha.test] [mail@alpha.test]"
assert_called "retrieve-certificate [beta] [${APPLICATION_PATH}certificates/beta/] [beta.test] [mail@alpha.test]"
[ "$(cat "${APPLICATION_PATH}certificates/beta/domains.txt")" = beta.test ] || \
    fail Domains were not stored.
grep --quiet 'Synchronizing certificate "beta" to cloudflare failed.' \
    "$CERTIFICATION_SERVICE_LOG" || \
    fail Failing synchronization was not logged.
assert_not_called reload-nginx

# Reloads nginx every 7th day.
reset_calls
FAKE_SLEEP_LIMIT=15 \
PROXY_CERTIFICATES_START_UPDATE_DELAY=1s \
    run_sourced "${scripts_path}certificate-service.sh" <<<'' 2>/dev/null && \
    fail Service loop should only be stopped by the fake sleep.
assert_called 'sleep [1s]'
[ "$(count_calls reload-nginx)" = 2 ] || \
    fail "Expected two nginx reloads in 15 days, got $(count_calls reload-nginx)."
# endregion
# region initialize
reset_calls
COMMAND=nginx PROXY_CERTIFICATES='' \
    "${scripts_path}initialize.sh" --no-check-local-initializer -t -q || \
    fail Initializing failed.
# NOTE: Given arguments are evaluated as shell code.
assert_called "nginx [-t] [-q]"
assert_called "configure-runtime-user ${APPLICATION_PATH}certificates"
assert_not_called retrieve-certificate

reset_calls
for name in initialize-certificates certificate-service; do
    echo "echo '${name}' >>\"\$CALL_LOG_FILE_PATH\"" >"${fake_path}/${name}"
done
# NOTE: "wait" lets us wait for the started background service.
COMMAND=wait PROXY_CERTIFICATES=alpha "${scripts_path}initialize.sh" || \
    fail Initializing with certificates failed.
assert_called initialize-certificates
assert_called certificate-service
# endregion
# region reload-nginx
reset_calls
"${scripts_path}reload-nginx.sh" || fail Reloading nginx failed.
assert_called 'nginx [-s] [reload]'
# endregion
echo All tests passed.
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
