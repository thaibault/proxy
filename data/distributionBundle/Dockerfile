# syntax=docker/dockerfile-upstream:master-labs
# region header
# [Project page](https://torben.website/proxy)

# Copyright Torben Sickert (info["~at~"]torben.website) 16.12.2012

# License
# -------

# This library written by Torben Sickert stand under a creative commons naming
# 3.0 unported license.
# See https://creativecommons.org/licenses/by/3.0/deed.de
# endregion
# region create image commands
# Run the following command in the directory where this file lives to build a
# new docker image:

# - docker pull ghcr.io/thaibault/containerbase:latest && docker buildx build --no-cache --tag ghcr.io/thaibault/proxy:latest .
# endregion
# region start container commands
# Run the following command in the directory where this file lives to start:
# - podman pod rm --force proxy_pod; podman play kube service/kubernetes/production.yaml
# - docker rm --force proxy; docker compose --file service/docker/base.yaml --file service/docker/local.yaml up
# endregion
           # region configuration
ARG        BASE_IMAGE

FROM       ${BASE_IMAGE:-'ghcr.io/thaibault/containerbase:latest'}

LABEL      maintainer="Torben Sickert <info@torben.website>"
LABEL      Description="proxy" Vendor="thaibault products" Version="1.0"

EXPOSE     80 443

ENV        APPLICATION_USER_ID_INDICATOR_FILE_PATH /etc/nginx/conf.d

ENV        MAIN_USER_NAME http

ENV        PROXY_APPLICATION_SPECIFIC_NGINX_CONFIGURATION_FILE_PATH '/etc/nginx/conf.d/*.conf'
ENV        PROXY_CERTIFICATES ''
ENV        PROXY_CERTIFICATE_DOMAINS ''
ENV        PROXY_CERTIFICATE_EMAIL_ADDRESSES ''
ENV        PROXY_CERTIFICATES_START_UPDATE_DELAY 50m

ENV        ACCESS_LOG '/dev/stdout'
ENV        CERTIFICATION_SERVICE_LOG="${APPLICATION_PATH}certificates/log.txt"
ENV        ERROR_LOG  '/dev/stderr info'

ENV        COMMAND nginx

ENV        TEMPORARY_NGINX_PATH /tmp/nginx/

WORKDIR    $APPLICATION_PATH
ENV        SCRIPTS_PATH "${APPLICATION_PATH}scripts/"
USER       root
           # endregion
           # region install needed packages
           # NOTE: "neovim" is only needed for debugging scenarios.
RUN        yay \
               --needed \
               --noconfirm \
               --sync \
               certbot \
               certbot-nginx \
               nginx \
               openssl && \
           clean-up
           # endregion
           # region preconfigure nginx to integrate application specifc options
RUN        configure-user && \
           # Set all file path options to application user writable locations
           # that will otherwise default to restricted locations accessible
           # only to root.
           echo -e "daemon               off;\nerror_log            ${ERROR_LOG};\npid                  ${TEMPORARY_NGINX_PATH}pid;\n\nuser                 ${MAIN_USER_NAME} ${MAIN_USER_GROUP_NAME};\n\nworker_processes     auto;\nworker_rlimit_nofile 2048;\n\nevents {\n    worker_connections   1024;\n}\n\nhttp {\n    access_log              ${ACCESS_LOG};\n    charset                 utf8;\n\n    client_body_temp_path   ${TEMPORARY_NGINX_PATH}clientBody;\n    fastcgi_temp_path       ${TEMPORARY_NGINX_PATH}fastcgiTemp;\n    proxy_temp_path         ${TEMPORARY_NGINX_PATH}proxyTemp;\n    scgi_temp_path          ${TEMPORARY_NGINX_PATH}scgiTemp;\n    uwsgi_temp_path         ${TEMPORARY_NGINX_PATH}uwsgiTemp;\n\n    default_type            application/octet-stream;\n    gzip                    on;\n\n    sendfile                on;\n\n    client_body_buffer_size 256k;\n    types_hash_max_size     4096;\n\n    proxy_set_header        X-Forwarded-Proto \$scheme;\n    proxy_set_header        Upgrade \$http_upgrade;\n    proxy_set_header        Connection \"upgrade\";\n\n    keepalive_timeout       65;\n\n    resolver                8.8.8.8;\n\n    include                 mime.types;\n    include                 ${PROXY_APPLICATION_SPECIFIC_NGINX_CONFIGURATION_FILE_PATH};\n}" \
               1>/etc/nginx/nginx.conf && \
           mkdir --parents /etc/nginx/html && \
           echo ''>/etc/nginx/html/index.html && \
           mkdir --parents "$TEMPORARY_NGINX_PATH" && \
           chown \
               --dereference \
               -L \
               --recursive \
               "${MAIN_USER_NAME}:${MAIN_USER_GROUP_NAME}" \
               "$TEMPORARY_NGINX_PATH" && \
           # NOTE: Allow none root user to bind to ports lower than 1024 with
           # nginx.
           setcap cap_net_bind_service=ep "$(which nginx)"
           # endregion
           # region build file structure
RUN        mkdir --parents "${APPLICATION_PATH}certificates/acme-challenge"

COPY       --link ./scripts "${SCRIPTS_PATH}"

RUN        chown \
               --dereference \
               -L \
               --recursive \
               "${MAIN_USER_NAME}:${MAIN_USER_GROUP_NAME}" \
               "$APPLICATION_PATH"

RUN        ln --symbolic \
               "${SCRIPTS_PATH}certificate-service.sh" \
               /usr/bin/certificate-service
RUN        ln --force --symbolic \
               "${SCRIPTS_PATH}initialize.sh" \
               "$INITIALIZING_FILE_PATH"
RUN        ln --symbolic \
               "${SCRIPTS_PATH}initialize-certificates.sh" \
               /usr/bin/initialize-certificates
RUN        mkdir --parents /etc/letsencrypt/renewal-hooks/post
RUN        ln --symbolic \
               "${SCRIPTS_PATH}reload-nginx.sh" \
               /etc/letsencrypt/renewal-hooks/post/50-reload-nginx.sh
RUN        ln --symbolic \
               "${SCRIPTS_PATH}retrieve-certificate.sh" \
               /usr/bin/retrieve-certificate
RUN        ln --symbolic \
               "${SCRIPTS_PATH}update-certificate.sh" \
               /usr/bin/update-certificate
           # endregion
#ENTRYPOINT ...
# region modline
# vim: set tabstop=4 shiftwidth=4 expandtab filetype=dockerfile:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
