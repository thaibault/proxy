# Run the following command in the directory where this file lives to build a
# new docker image: docker-compose --file base.yml build --no-cache

# Run the following command in the directory where this file lives to start:
# docker-compose --file base.yml up

           # region configuration
FROM       nginx:stable-alpine
MAINTAINER Torben Sickert <info@torben.website>
LABEL      Description="leaseRadCMS" Vendor="leaseRad Products" Version="1.0"
EXPOSE     80 443
ENV        APPLICATION_PATH /srv/http
ENV        APPLICATION_SPECIFIC_NGINX_CONFIGURATION_FILE_PATH '/etc/nginx/conf.d/*.conf'
ENV        APPLICATION_USER_ID_INDICATOR_FILE_PATH '/etc/nginx/conf.d'
ENV        COMMAND 'nginx'
ENV        DEFAULT_MAIN_USER_GROUP_ID 100
ENV        DEFAULT_MAIN_USER_ID 1000
ENV        INITIALIZING_FILE_PATH '/usr/bin/initialize'
ENV        MAIN_USER_GROUP_NAME users
ENV        MAIN_USER_NAME http
ENV        TEMPORARY_NGINX_PATH '/tmp/nginx/'
WORKDIR    peaceful_sammet$APPLICATION_PATH
USER       root
           # endregion
           # region install needed packages
           # NOTE: "neovim" is only needed for debugging scenarios.
RUN        apk add --no-cache bash libcap neovim openssl shadow
           # endregion
           # region preconfigure application user
           # Set proper default user and group id to avoid expendsive user id
           # mapping on application startup.
RUN        [[ "$MAIN_USER_NAME" != 'root' ]] && \
           groupadd --gid "$DEFAULT_MAIN_USER_GROUP_ID" \
               "$MAIN_USER_GROUP_NAME" &>/dev/null; \
           groupmod --gid "$DEFAULT_MAIN_USER_GROUP_ID" \
               "$MAIN_USER_GROUP_NAME" && \
           useradd --uid "$DEFAULT_MAIN_USER_ID" "$MAIN_USER_NAME" \
               &>/dev/null; \
           usermod --gid "$DEFAULT_MAIN_USER_GROUP_ID" --uid \
               "$DEFAULT_MAIN_USER_ID" "$MAIN_USER_NAME" &>/dev/null; \
           chown --recursive "${MAIN_USER_NAME}:${MAIN_USER_GROUP_NAME}" \
               "$(pwd)" && \
           echo /bin/bash>>/etc/shells && \
           chsh --shell /bin/bash "$MAIN_USER_NAME" && \
           usermod --home "$(pwd)" "$MAIN_USER_NAME" || \
           true
           # endregion
           # region preconfigure application location
           # NOTE: Alpine's "mkdir" only supports short options.
RUN        mkdir -p "$APPLICATION_PATH" \
               "$APPLICATION_USER_ID_INDICATOR_FILE_PATH" && \
           chown "$MAIN_USER_NAME:$MAIN_USER_GROUP_NAME" --recursive \
               "$APPLICATION_PATH" "$APPLICATION_USER_ID_INDICATOR_FILE_PATH"
           # endregion
           # region preconfigure nginx to integrate application specifc options
           # Set all file path options to application user writable locations
           # that will otherwise default to restricted locations accessible
           # only to root.
RUN        echo -e "daemon    off;\nerror_log ${TEMPORARY_NGINX_PATH}errorLog;\npid       ${TEMPORARY_NGINX_PATH}pid;\n#user      ${MAIN_USER_NAME} ${MAIN_USER_GROUP_NAME};\nworker_processes  4;\nevents {\n    worker_connections  1024;\n}\nhttp {\n    access_log              ${TEMPORARY_NGINX_PATH}accessLog;\n    client_body_temp_path   ${TEMPORARY_NGINX_PATH}clientBody;\n    fastcgi_temp_path       ${TEMPORARY_NGINX_PATH}fastcgiTemp;\n    proxy_temp_path         ${TEMPORARY_NGINX_PATH}proxyTemp;\n    scgi_temp_path          ${TEMPORARY_NGINX_PATH}scgiTemp;\n    uwsgi_temp_path         ${TEMPORARY_NGINX_PATH}uwsgiTemp;\n    include                 mime.types;\n    default_type            application/octet-stream;\n    sendfile                on;\n    gzip                    on;\n    client_body_buffer_size 256k;\n    proxy_set_header        X-Forwarded-Proto $scheme;\n    proxy_set_header        Upgrade $http_upgrade;\n    proxy_set_header        Connection \"upgrade\";\n    keepalive_timeout       65;\n    resolver                8.8.8.8;\n    include                 $(pwd)/$APPLICATION_SPECIFIC_NGINX_CONFIGURATION_FILE_PATH;\n}" \
               1>/etc/nginx/nginx.conf && \
           # NOTE: Alpine's "mkdir" only supports short options.
           mkdir -p /etc/nginx/html && \
           echo ''>/etc/nginx/html/index.html && \
           # NOTE: Alpine's "mkdir" only supports short options.
           mkdir -p "$TEMPORARY_NGINX_PATH" && \
           chown --recursive "${MAIN_USER_NAME}:${MAIN_USER_GROUP_NAME}" \
               "$TEMPORARY_NGINX_PATH" && \
           # NOTE: Allow none root user to bind to ports lower than 1024 with
           # nginx.
           setcap cap_net_bind_service=ep /usr/sbin/nginx
           # endregion
           # region set proper user ids and bootstrap application
           # NOTE: "id" and "stat" only supports short options.
           # NOTE: "su" doesn't support "--group"
RUN        echo -e "#!/bin/bash\n\nset -e\nOLD_GROUP_ID=\$(id -g \"\$MAIN_USER_NAME\")\nOLD_USER_ID=\$(id -u \"\$MAIN_USER_NAME\")\nGROUP_ID_CHANGED=false\nif [[ \"\$HOST_GID\" == '' ]]; then\n    HOST_GID=\"\$(stat -c '%g' \"\$APPLICATION_USER_ID_INDICATOR_FILE_PATH\")\"\nfi\nif [[ \$OLD_GROUP_ID != \$HOST_GID ]]; then\n    echo \"Map group id \$OLD_GROUP_ID from application user \$MAIN_USER_NAME to host group id \$HOST_GID from \$(stat -c '%G' \"\$APPLICATION_USER_ID_INDICATOR_FILE_PATH\").\"\n    usermod --gid \"\$HOST_GID\" \"\$MAIN_USER_NAME\"\n    GROUP_ID_CHANGED=true\nfi\nif [[ \"\$HOST_UID\" == '' ]]; then\n    HOST_UID=\"\$(stat -c '%u' \"\$APPLICATION_USER_ID_INDICATOR_FILE_PATH\")\"\nfi\nUSER_ID_CHANGED=false\nif [[ \$OLD_USER_ID != \$HOST_UID ]]; then\n    echo \"Map user id \$OLD_USER_ID from application user \$MAIN_USER_NAME to host user id \$HOST_UID from \$(stat -c '%U' \"\$APPLICATION_USER_ID_INDICATOR_FILE_PATH\").\"\n    usermod --uid \"\$HOST_UID\" \"\$MAIN_USER_NAME\"\n    USER_ID_CHANGED=true\nfi\nif \$GROUP_ID_CHANGED; then\n    find ./ -xdev -group \$OLD_GROUP_ID -exec chgrp --no-dereference \$MAIN_USER_GROUP_NAME {} \\;\nfi\nif \$USER_ID_CHANGED; then\n    find ./ -xdev -user \$OLD_USER_ID -exec chown --no-dereference \$MAIN_USER_NAME {} \\;\nfi\nchmod +x /dev/\nchown \$MAIN_USER_NAME:\$MAIN_USER_GROUP_NAME /proc/self/fd/0 /proc/self/fd/1 /proc/self/fd/2\nset +x\nexec su \$MAIN_USER_NAME -c \"\$COMMAND\"" \
               >"$INITIALIZING_FILE_PATH" && \
           chmod +x "$INITIALIZING_FILE_PATH"
CMD        ["/usr/bin/initialize"]
           # endregion
# region modline
# vim: set tabstop=4 shiftwidth=4 expandtab filetype=dockerfile:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
