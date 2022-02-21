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

if [[ "$PROXY_CERTIFICATES" != '' ]]; then
    certificate-service &
fi

source run-command "$@"
# region modline
# vim: set tabstop=4 shiftwidth=4 expandtab filetype=dockerfile:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
