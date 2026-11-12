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
pkgver=1.0.15
pkgrel=13
pkgdesc='generic proxy server'
arch=(any)
url=https://tsickert.com/proxy
license=(CC-BY-4.0)
depends=(bash docker)
source=(base.yaml Dockerfile proxy.service)
md5sums=(SKIP SKIP SKIP)
copy_to_aur=true

package() {
    install -D --mode 755 "${srcdir}/service/docker" \
        "${pkgdir}/srv/http/proxy/docker"

    install -D --mode 655 "${srcdir}/service/systemd/proxy.service" \
        "${pkgdir}/etc/systemd/system/proxy.service"
    install -D --mode 655 "${srcdir}/service/systemd/reload-proxy.service" \
        "${pkgdir}/etc/systemd/system/reload-proxy.service"
    install -D --mode 655 "${srcdir}/service/systemd/reload-proxy.timer" \
        "${pkgdir}/etc/systemd/system/reload-proxy.timer"
}
