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

source configure-runtime-user "${APPLICATION_PATH}certificates"

if [[ "$PROXY_CERTIFICATES" != '' ]]; then
    source initialize-certificates

    source certificate-service &
fi

# Run as root to let nginx fork process under configured user and group name.
exec "$COMMAND $*"
# region modline
# vim: set tabstop=4 shiftwidth=4 expandtab filetype=dockerfile:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
