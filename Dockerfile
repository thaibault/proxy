# Run the following command in the directory where this file lives to build a
# new docker image: docker-compose --file base.yml build --no-cache

# Run the following command in the directory where this file lives to start a:
# - development environment: docker-compose --file local.yml up
# - production environment: docker-compose --file remote.yml up

           # region configuration
FROM       nginx:stable-alpine
MAINTAINER Torben Sickert <info@torben.website>
LABEL      Description="leaseRadCMS" Vendor="leaseRad Products" Version="1.0"
EXPOSE     80 443
ENV        APPLICATION_PATH /srv/http
ENV        APPLICATION_SPECIFIC_NGINX_CONFIGURATION_FILE_PATH '/etc/nginx/conf.d/*.conf'
ENV        COMMAND 'nginx'
ENV        DEFAULT_MAIN_USER_GROUP_ID 100
ENV        DEFAULT_MAIN_USER_ID 1000
ENV        INITIALIZING_FILE_PATH '/usr/bin/initialize'
ENV        MAIN_USER_GROUP_NAME users
ENV        MAIN_USER_NAME http
ENV        TEMPORARY_NGINX_PATH '/tmp/nginx/'
WORKDIR    $APPLICATION_PATH
USER       root
           # endregion
           # region install needed packages
           # NOTE: "neovim" is only needed for debugging scenarios.
RUN        apk add --no-cache bash neovim openssl shadow && \
           # NOTE: Alpine's "mkdir" only supports short options.
           mkdir -p /srv/http /etc/nginx/conf.d && \
           chown nobody:nobody --recursive /srv/http
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
           # region preconfigure nginx to integrate application specifc options
           # Set all file path options to application user writable locations
           # that will otherwise default to restricted locations accessible
           # only to root.
RUN        echo -e "daemon    off;\nerror_log ${TEMPORARY_NGINX_PATH}errorLog;\npid       ${TEMPORARY_NGINX_PATH}pid;\n#user      ${MAIN_USER_NAME} ${MAIN_USER_GROUP_NAME};\nworker_processes  4;\nevents {\n    worker_connections  1024;\n}\nhttp {\n    access_log            ${TEMPORARY_NGINX_PATH}accessLog;\n    client_body_temp_path ${TEMPORARY_NGINX_PATH}clientBody;\n    fastcgi_temp_path     ${TEMPORARY_NGINX_PATH}fastcgiTemp;\n    proxy_temp_path       ${TEMPORARY_NGINX_PATH}proxyTemp;\n    scgi_temp_path        ${TEMPORARY_NGINX_PATH}scgiTemp;\n    uwsgi_temp_path       ${TEMPORARY_NGINX_PATH}uwsgiTemp;\n    include               mime.types;\n    default_type          application/octet-stream;\n    keepalive_timeout     65;\n    resolver              8.8.8.8;\n    include               $(pwd)/$APPLICATION_SPECIFIC_NGINX_CONFIGURATION_FILE_PATH;\n}" \
               1>/etc/nginx/nginx.conf && \
           mkdir --parents /etc/nginx/html && \
           echo ''>/etc/nginx/html/index.html && \
           mkdir --parents "$TEMPORARY_NGINX_PATH" && \
           chown --recursive "${MAIN_USER_NAME}:${MAIN_USER_GROUP_NAME}" \
               "$TEMPORARY_NGINX_PATH" && \
           # NOTE: Allow none root user to bind to ports lower than 1024 with
           # nginx.
           setcap cap_net_bind_service=ep /usr/bin/nginx
           # endregion
           # region set proper user ids and bootstrap application
RUN        echo -e "#!/usr/bin/bash\n\nset -e\nOLD_GROUP_ID=\$(id --group \"\$MAIN_USER_NAME\")\nOLD_USER_ID=\$(id --user \"\$MAIN_USER_NAME\")\nGROUP_ID_CHANGED=false\nif [[ \"\$HOST_GID\" == '' ]]; then\n    HOST_GID=\"\$(stat --format '%g' \"\$APPLICATION_USER_ID_INDICATOR_FILE_PATH\")\"\nfi\nif [[ \$OLD_GROUP_ID != \$HOST_GID ]]; then\n    echo \"Map group id \$OLD_GROUP_ID from application user \$MAIN_USER_NAME to host group id \$HOST_GID from \$(stat --format '%G' \"\$APPLICATION_USER_ID_INDICATOR_FILE_PATH\").\"\n    usermod --gid \"\$HOST_GID\" \"\$MAIN_USER_NAME\"\n    GROUP_ID_CHANGED=true\nfi\nif [[ \"\$HOST_UID\" == '' ]]; then\n    HOST_UID=\"\$(stat --format '%u' \"\$APPLICATION_USER_ID_INDICATOR_FILE_PATH\")\"\nfi\nUSER_ID_CHANGED=false\nif [[ \$OLD_USER_ID != \$HOST_UID ]]; then\n    echo \"Map user id \$OLD_USER_ID from application user \$MAIN_USER_NAME to host user id \$HOST_UID from \$(stat --format '%U' \"\$APPLICATION_USER_ID_INDICATOR_FILE_PATH\").\"\n    usermod --uid \"\$HOST_UID\" \"\$MAIN_USER_NAME\"\n    USER_ID_CHANGED=true\nfi\nif \$GROUP_ID_CHANGED; then\n    find ./ -xdev -group \$OLD_GROUP_ID -exec chgrp --no-dereference \$MAIN_USER_GROUP_NAME {} \\;\nfi\nif \$USER_ID_CHANGED; then\n    find ./ -xdev -user \$OLD_USER_ID -exec chown --no-dereference \$MAIN_USER_NAME {} \\;\nfi\nchmod +x /dev/\nchown \$MAIN_USER_NAME:\$MAIN_USER_GROUP_NAME /proc/self/fd/0 /proc/self/fd/1 /proc/self/fd/2\nset +x\nexec su \$MAIN_USER_NAME --group \$MAIN_USER_GROUP_NAME -c \"\$COMMAND\"" \
               >"$INITIALIZING_FILE_PATH" && \
           chmod +x "$INITIALIZING_FILE_PATH"
CMD        ["/usr/bin/initialize"]
           # endregion
# region modline
# vim: set tabstop=4 shiftwidth=4 expandtab filetype=dockerfile:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
