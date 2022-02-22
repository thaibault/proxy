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
# - podman pull ghcr.io/thaibault/containerbase:latest && podman build --file https://raw.githubusercontent.com/thaibault/proxy/master/Dockerfile --no-cache --tag ghcr.io/thaibault/proxy .
# - podman push ghcr.io/thaibault/proxy:latest --creds "thaibault:$(cat "${ILU_GITHUB_BASE_CONFIGURATION_PATH}masterToken.txt")"

# - docker pull ghcr.io/thaibault/containerbase:latest && docker build --no-cache --tag ghcr.io/thaibault/proxy:latest https://raw.githubusercontent.com/thaibault/proxy/master/Dockerfile
# - cat "${ILU_GITHUB_BASE_CONFIGURATION_PATH}masterToken.txt" | docker login ghcr.io --username thaibault --password-stdin && docker push ghcr.io/thaibault/proxy:latest
# endregion
# region start container commands
# Run the following command in the directory where this file lives to start:
# - podman pod rm --force proxy_pod; podman play kube service/kubernetes/production.yaml
# - docker rm --force proxy; docker compose --file service/docker/base.yaml --file service/docker/local.yaml up
# endregion
            # region configuration
FROM        ghcr.io/thaibault/containerbase

LABEL       maintainer="Torben Sickert <info@torben.website>"
LABEL       Description="proxy" Vendor="thaibault products" Version="1.0"

EXPOSE      80 443

ENV         APPLICATION_USER_ID_INDICATOR_FILE_PATH /etc/nginx/conf.d

ENV         PROXY_APPLICATION_SPECIFIC_NGINX_CONFIGURATION_FILE_PATH '/etc/nginx/conf.d/*.conf'
ENV         PROXY_CERTIFICATES ''
ENV         PROXY_CERTIFICATE_DOMAINS ''
ENV         PROXY_CERTIFICATE_EMAIL_ADDRESSES ''

ENV         COMMAND nginx

ENV         TEMPORARY_NGINX_PATH /tmp/nginx/

WORKDIR     $APPLICATION_PATH
USER        root
            # endregion
            # region install needed packages
            # NOTE: "neovim" is only needed for debugging scenarios.
RUN         pacman \
                --needed \
                --noconfirm \
                --sync \
                certbot \
                gocryptfs \
                nginx \
                neovim \
                openssl && \
            # tidy up
            rm /var/cache/* --recursive --force
            # endregion
            # region preconfigure nginx to integrate application specifc options
RUN         configure-user && \
            # Set all file path options to application user writable locations
            # that will otherwise default to restricted locations accessible
            # only to root.
            echo -e "daemon               off;\nerror_log            /dev/stderr info;\npid                  ${TEMPORARY_NGINX_PATH}pid;\n# Not needed since process is already started as non-root user.\n#user                ${MAIN_USER_NAME} ${MAIN_USER_GROUP_NAME};\nworker_processes     auto;\nworker_rlimit_nofile 2048;\n\nevents {\n    worker_connections   1024;\n}\nhttp {\n    access_log              /dev/stdout;\n    charset                 utf8;\n    client_body_temp_path   ${TEMPORARY_NGINX_PATH}clientBody;\n    fastcgi_temp_path       ${TEMPORARY_NGINX_PATH}fastcgiTemp;\n    proxy_temp_path         ${TEMPORARY_NGINX_PATH}proxyTemp;\n    scgi_temp_path          ${TEMPORARY_NGINX_PATH}scgiTemp;\n    uwsgi_temp_path         ${TEMPORARY_NGINX_PATH}uwsgiTemp;\n    include                 mime.types;\n    default_type            application/octet-stream;\n    sendfile                on;\n    gzip                    on;\n    client_body_buffer_size 256k;\ntypes_hash_max_size    4096;\n    proxy_set_header        X-Forwarded-Proto \$scheme;\n    proxy_set_header        Upgrade \$http_upgrade;\n    proxy_set_header        Connection \"upgrade\";\n    keepalive_timeout       65;\n    resolver                8.8.8.8;\n    include                 ${PROXY_APPLICATION_SPECIFIC_NGINX_CONFIGURATION_FILE_PATH};\n}" \
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
USER        $MAIN_USER_NAME

RUN         mkdir --parents "${APPLICATION_PATH}certificates/acme-challenge"

COPY        ./certificate-service.sh "${APPLICATION_PATH}certificate-service.sh"
RUN         ln --symbolic \
                "${APPLICATION_PATH}certificate-service.sh" \
                /usr/bin/certificate-service

COPY        ./initialize-certificates.sh "${APPLICATION_PATH}initialize-certificates.sh"
RUN         ln --symbolic \
                "${APPLICATION_PATH}initialize-certificates.sh" \
                /usr/bin/initialize-certificates
COPY        ./retrieve-certificate.sh "${APPLICATION_PATH}retrieve-certificate.sh"
RUN         ln --symbolic \
                "${APPLICATION_PATH}initialize-certificates.sh" \
                /usr/bin/retrieve-certificate

COPY        ./update-certificate.sh "${APPLICATION_PATH}update-certificate.sh"
RUN         ln --symbolic \
                "${APPLICATION_PATH}update-certificate.sh" \
                /usr/bin/update-certificate

COPY        ./initialize.sh "${APPLICATION_PATH}initialize.sh"
RUN         ln --force --symbolic \
                "${APPLICATION_PATH}initialize.sh" \
                "$INITIALIZING_FILE_PATH"
# region modline
# vim: set tabstop=4 shiftwidth=4 expandtab filetype=dockerfile:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
