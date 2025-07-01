#!/usr/bin/env bash
# -*- coding: utf-8 -*-
set -e
# 1. Checks if newer initializer is bind into container and exec into to if
# present.
# 2. Loads environment files if existing.
# shellcheck disable=SC1091
source prepare-initializer "$@"

# Remove cli indicator to load latest initializer file.
if [ "$1" = '--no-check-local-initializer' ]; then
    shift
fi

# shellcheck disable=SC1091
source decrypt "$@"

# shellcheck disable=SC1091
source configure-runtime-user "${APPLICATION_PATH}certificates"

if [[ "$PROXY_CERTIFICATES" != '' ]]; then
    # shellcheck disable=SC1091
    source initialize-certificates

    # shellcheck disable=SC1091
    source certificate-service &
fi

# Run as root to let nginx fork process under configured user and group name.
eval "$COMMAND $*"
# region modline
# vim: set tabstop=4 shiftwidth=4 expandtab filetype=dockerfile:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
