#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# region header
# Copyright Torben Sickert (info["~at~"]tsickert.com) 16.12.2012

# License
# -------

# This library written by Torben Sickert stands under a creative commons naming
# 4.0 international license.
# See https://creativecommons.org/licenses/by/4.0/deed.de
# endregion
pkgname=proxy
pkgver=1.0.190
pkgrel=1
pkgdesc='generic dockerized proxy server'
arch=(any)
url=https://tsickert.com/proxy
license=(CC-BY-4.0)
depends=(bash docker docker-compose)
backup=(
    srv/http/service/proxy/etc/nginx/00_default.conf
    srv/http/service/proxy/etc/nginx/helper/certificate.include
    srv/http/service/proxy/etc/nginx/helper/ssl.include
)
# NOTE: Only the service files are needed, the image is pulled from the
# registry.
source=("https://github.com/thaibault/proxy/archive/refs/tags/v${pkgver}.tar.gz")
sha256sums=(21b0c9aa0b1082b679193bd49b96060fda8d4a5ba8ef47103d88e14caf3fea91)
copy_to_aur=true

package() {
    cd "${srcdir}/proxy-${pkgver}"
    # NOTE: "proxy.service" runs the compose files from here and they mount
    # the configuration and certificate folders relative to themselves.
    local -r target_path="${pkgdir}/srv/http/service/proxy/"
    local file_path
    for file_path in \
        etc/nginx/00_default.conf \
        etc/nginx/helper/certificate.include \
        etc/nginx/helper/ssl.include \
        service/docker/*.yaml \
        service/kubernetes/*.yaml
    do
        install -D --mode 644 "$file_path" "${target_path}${file_path}"
    done
    install -d \
        "${target_path}certificates/acme-challenge" \
        "${target_path}etc/containerBase"
    for file_path in service/systemd/*; do
        install \
            -D \
            --mode 644 \
            "$file_path" \
            "${pkgdir}/usr/lib/systemd/system/$(basename "$file_path")"
    done
}
