<!-- #!/usr/bin/env markdown
-*- coding: utf-8 -*-
region header
Copyright Torben Sickert (info["~at~"]tsickert.com) 16.12.2012

License
-------

This library written by Torben Sickert stands under a creative commons naming
3.0 unported license. See https://creativecommons.org/licenses/by/3.0/deed.de
endregion -->

<!--|deDE:Projektstatus-->
Project Status
--------------

[![build push image](https://img.shields.io/github/actions/workflow/status/thaibault/proxy/build-image-and-push-periodically-2.yaml?label=build%20push%20image&style=for-the-badge)](https://github.com/thaibault/proxy/actions/workflows/build-image-and-push-periodically-2.yaml)

[![deploy web documentation](https://img.shields.io/github/actions/workflow/status/thaibault/proxy/deploy-web-documentation.yaml?label=deploy%20web%20documentation&style=for-the-badge)](https://github.com/thaibault/proxy/actions/workflows/deploy-web-documentation.yaml)
[![web documentation](https://img.shields.io/website-up-down-green-red/https/tsickert.com/proxy.svg?label=web-documentation&style=for-the-badge)](https://tsickert.com/proxy)

<!--|deDE:Verwendung-->
Use case
--------

A docker based proxy server that is easy to configure. The image bundles an
[nginx](https://nginx.org) web server with a [certbot](https://certbot.eff.org)
service that retrieves and renews
[Let's Encrypt](https://letsencrypt.org) certificates for a configurable list
of domains. Optionally the certificates can be uploaded to
[Cloudflare](https://www.cloudflare.com), so that Cloudflare's edge serves the
same certificates and keeps them up to date.

<div class="wd-table-of-contents">
    <h2 id="content">Content<!--deDE:Inhalt--><!--frFR:Contenu--></h2>
    <!--wd-table-of-contents-->
</div>

Features
--------

- Nginx reverse proxy based on the arch linux
  [containerbase](https://github.com/thaibault/containerbase) image (runtime
  user handling, environment files and encrypted configuration included).
- Plain nginx configuration: every `*.conf` file in `/etc/nginx/conf.d` is
  included into the `http` block.
- Default server answering http-01 acme challenges and redirecting every other
  http request to https.
- Hardened ssl defaults (TLS 1.2/1.3, modern ciphers, HSTS, OCSP stapling) as
  reusable include files.
- Automatic certificate retrieval on startup and daily renewal checks for any
  number of certificates, each covering multiple domains.
- Re-retrieval when the configured domain list of a certificate changes.
- Periodic nginx reloads to activate renewed certificates.
- Optional synchronisation of every certificate into a Cloudflare zone as
  custom certificate.
- Ready to use docker compose, podman (kubernetes) and systemd service files.

Installation
------------

Pull the prebuilt image (built for `x86-64` and `arm-64`):

```bash
docker pull ghcr.io/thaibault/proxy:latest
```

or build it yourself in this repository:

```bash
docker pull ghcr.io/thaibault/containerbase:latest
docker buildx build --no-cache --tag ghcr.io/thaibault/proxy:latest .
```

The service files (compose files, kubernetes manifests and systemd units) are
also available as npm package:

```bash
npm install proxy
```

Usage
-----

### Directory layout

The container expects three mounts (see `service/docker/mounts.yaml`):

| Host path (repository) | Container path               | Content                                                        |
|------------------------|------------------------------|----------------------------------------------------------------|
| `certificates/`        | `/application/certificates`  | Retrieved certificates, certbot state, acme challenges and log. |
| `etc/containerBase/`   | `/etc/containerBase`         | `environment.sh` holding the configuration described below.    |
| `etc/nginx/`           | `/etc/nginx/conf.d`          | Your nginx server configurations and helper includes.          |

### Start

Locally (http on port `8080`, https on port `4443`, local scripts mounted for
testing and no delay before the first certificate check):

```bash
yarn start
```

which is a shortcut for:

```bash
docker compose \
    --file service/docker/base.yaml \
    --file service/docker/mounts.yaml \
    --file service/docker/local.yaml \
    up
```

In production use `service/docker/production.yaml` instead of
`service/docker/local.yaml`. It binds ports `80` and `443`, restarts on
failure, limits log sizes and attaches the proxy to an external docker network
named `proxy`. Attach your application containers to that network to be able
to reach them by their container name from nginx:

```bash
docker network create proxy
docker compose \
    --file service/docker/base.yaml \
    --file service/docker/mounts.yaml \
    --file service/docker/production.yaml \
    --project-name proxy \
    up
```

With podman use the kubernetes manifests:

```bash
podman play kube service/kubernetes/production.yaml
```

The image tag can be selected via the `IMAGE_TAG` environment variable when
using docker compose (defaults to `latest`).

### Systemd

`service/systemd` contains units to run the proxy on a host:

- `proxy.service` creates the `proxy` network and runs the production compose
  setup from `/srv/http/service/proxy`.
- `reload-proxy.service` reloads the nginx configuration (and with it all
  certificate files) of the running container.
- `reload-proxy.timer` triggers `reload-proxy.service` five minutes after boot
  and once a week afterwards.

Nginx configuration
-------------------

All files matching `/etc/nginx/conf.d/*.conf` are included into the main
`http` block. The image itself only defines global settings (logging, temp
paths, gzip, websocket aware proxy headers and `resolver 8.8.8.8`). The
configured value can be changed via
`PROXY_APPLICATION_SPECIFIC_NGINX_CONFIGURATION_FILE_PATH` at build time.

### Default server

`etc/nginx/00_default.conf` defines the log formats and a default server on
port 80 that:

- serves `/.well-known/acme-challenge/` from
  `/application/certificates/acme-challenge/` (needed for certificate
  renewals) and
- redirects every other request permanently to https.

### Helper includes

- `helper/ssl.include` contains the ssl protocol, cipher, session, HSTS and
  OCSP stapling settings.
- `helper/certificate.include` includes `ssl.include` and points nginx to the
  certificate files of a certificate named `web`. Nginx does not support
  variables in these directives, so for certificates with other names copy the
  file and replace `web` accordingly.

The include also expects a diffie hellman parameter file which has to be
created once:

```bash
openssl dhparam -out certificates/web/dhparam.pem 4096
```

A typical application server configuration (e.g. `etc/nginx/application.conf`)
looks like this:

```nginx
server {
    listen      443 ssl;
    listen [::]:443 ssl;
    http2       on;

    server_name example.com www.example.com;

    include     conf.d/helper/certificate.include;

    location / {
        proxy_pass http://application:8080;
    }
}
```

Certificates
------------

### Configuration

Certificates are configured in `etc/containerBase/environment.sh`, which is
sourced on container start. The lists are bash arrays and are matched by their
index:

```bash
# Name of each certificate. Files will be stored under
# "certificates/<name>/letsEncrypt/configuration/live/<name>/".
PROXY_CERTIFICATES=(web web.staging)
# Space separated domains each certificate should cover.
PROXY_CERTIFICATE_DOMAINS=(
    'example.com www.example.com'
    'staging.example.com www.staging.example.com'
)
# Let's Encrypt account e-mail address per certificate. An empty or missing
# entry reuses the address of the previous certificate.
PROXY_CERTIFICATE_EMAIL_ADDRESSES=(admin@example.com)
# Delay before the first renewal check after startup (any "sleep" duration).
PROXY_CERTIFICATES_START_UPDATE_DELAY=50m
```

A single certificate can also be configured via plain environment variables
(e.g. in a compose file), since a scalar acts like a one element array.

If `PROXY_CERTIFICATES` is empty no certificates are managed and only nginx is
started.

### Lifecycle

1. **Startup**: Every certificate that has not been retrieved yet, or whose
   domain list differs from the one it was retrieved for (stored in
   `certificates/<name>/domains.txt`), is retrieved via certbot in standalone
   mode before nginx starts.
2. **Start delay**: The certificate service waits
   `PROXY_CERTIFICATES_START_UPDATE_DELAY` before its first check, so that
   frequent container restarts do not run into Let's Encrypt rate limits.
3. **Daily checks**: Every 24 hours each certificate is renewed via the
   running nginx (webroot mode) if it is close to expiry. Certificates with a
   changed domain list are retrieved again.
4. **Reload**: Nginx is reloaded on the seventh check to pick up renewed
   certificates. Use the systemd timer (or `docker exec proxy nginx -s
   reload`) if you need more frequent reloads.

All certificate activity is logged to `certificates/log.txt` (configurable via
`CERTIFICATION_SERVICE_LOG`). Certbot's own logs are written to
`/tmp/<name>/letsEncryptLog` inside the container.

### Cloudflare synchronisation

Each certificate can additionally be uploaded to a Cloudflare zone as
[custom certificate](https://developers.cloudflare.com/ssl/edge-certificates/custom-certificates/).
The proxy keeps it up to date: the first upload creates the custom
certificate, every renewal replaces it, and if it has been deleted on
Cloudflare a new one is created.

```bash
# Zone id per certificate (same order as "PROXY_CERTIFICATES"). An empty
# entry disables the synchronisation for that certificate.
PROXY_CERTIFICATE_CLOUDFLARE_ZONE_IDS=(023e105f4ecef8ad9ca31a8372d0c353 '')
# API token with the permission "Zone - SSL and Certificates - Edit".
PROXY_CLOUDFLARE_API_TOKEN=YOUR_TOKEN
# Optional per certificate tokens overwriting "PROXY_CLOUDFLARE_API_TOKEN".
PROXY_CERTIFICATE_CLOUDFLARE_API_TOKENS=('' '')
# Optional: "ubiquitous" (default), "optimal" or "force".
PROXY_CLOUDFLARE_BUNDLE_METHOD=ubiquitous
# Optional: "sni_custom" (default) or "legacy_custom".
PROXY_CLOUDFLARE_CERTIFICATE_TYPE=sni_custom
```

Synchronisation runs on startup (so existing certificates are uploaded as soon
as a zone is configured) and after every daily check. An upload only happens
if the certificate or key changed since the last successful upload. The
Cloudflare certificate id and a fingerprint of the uploaded files are stored
in `certificates/<name>/cloudflareCertificateID.txt` and
`certificates/<name>/cloudflareCertificateFingerprint.txt`. Delete them to
force a new upload. A failing upload is logged but neither prevents nginx
from starting nor stops the certificate service.

Notes:

- Custom certificates require a Cloudflare Business or Enterprise plan, or
  the Advanced Certificate Manager add-on for `sni_custom`.
- Let's Encrypt validates domains via http. Cloudflare passes
  `/.well-known/acme-challenge/` requests through to the origin even with
  proxying and "Always Use HTTPS" enabled, so renewals keep working.
- Store the api token in an encrypted environment file (see below) rather
  than in plain text.

Environment variables
---------------------

| Name | Default | Description |
|------|---------|-------------|
| `PROXY_CERTIFICATES` | `''` | Certificate names (array). |
| `PROXY_CERTIFICATE_DOMAINS` | `''` | Space separated domains per certificate (array). |
| `PROXY_CERTIFICATE_EMAIL_ADDRESSES` | `''` | Let's Encrypt account e-mail address per certificate (array). |
| `PROXY_CERTIFICATES_START_UPDATE_DELAY` | `50m` | Delay before the first renewal check. |
| `PROXY_CERTIFICATE_CLOUDFLARE_ZONE_IDS` | `''` | Cloudflare zone id per certificate (array). |
| `PROXY_CERTIFICATE_CLOUDFLARE_API_TOKENS` | `''` | Cloudflare api token per certificate (array, optional). |
| `PROXY_CLOUDFLARE_API_TOKEN` | `''` | Default Cloudflare api token. |
| `PROXY_CLOUDFLARE_API_URL` | `https://api.cloudflare.com/client/v4` | Cloudflare api base url. |
| `PROXY_CLOUDFLARE_BUNDLE_METHOD` | `ubiquitous` | Chain bundling of uploaded certificates. |
| `PROXY_CLOUDFLARE_CERTIFICATE_TYPE` | `sni_custom` | Type of uploaded custom certificates. |
| `PROXY_APPLICATION_SPECIFIC_NGINX_CONFIGURATION_FILE_PATH` | `/etc/nginx/conf.d/*.conf` | Nginx configuration files to include (build time). |
| `CERTIFICATION_SERVICE_LOG` | `/application/certificates/log.txt` | Log file of the certificate service. |
| `COMMAND` | `nginx` | Command started after initialisation. |

Variables of the
[containerbase](https://github.com/thaibault/containerbase) image are
supported as well, e.g. to change the runtime user or to decrypt encrypted
configuration files (`DECRYPT`, `ENCRYPTED_PATHS`, `DECRYPTED_PATHS`).

Container commands
------------------

The following commands are available inside the container (e.g. via
`docker exec proxy <command>`) to handle certificates manually:

| Command | Arguments | Description |
|---------|-----------|-------------|
| `retrieve-certificate` | `[--initialize] NAME PATH 'DOMAINS' EMAIL` | Retrieve a certificate (`--initialize` uses certbot standalone mode while nginx is not running). |
| `update-certificate` | `NAME PATH 'DOMAINS' EMAIL` | Renew a certificate if it is close to expiry. |
| `synchronize-cloudflare-certificate` | `NAME PATH ZONE_ID` | Upload a certificate to Cloudflare (needs `PROXY_CLOUDFLARE_API_TOKEN`). |
| `reload-nginx` | | Reload the nginx configuration. |
| `initialize-certificates` | | Retrieve all configured certificates which are missing. |
| `certificate-service` | | Run the periodic renewal loop. |

`PATH` is the certificate directory, e.g. `/application/certificates/web/`
(the trailing slash is required).

Development
-----------

```bash
yarn install
# Lint all shell scripts via shellcheck.
yarn lint
# Start locally with the scripts of this working copy mounted.
yarn start
```

For testing against Let's Encrypt's staging environment add `--test-cert` to
the certbot calls in `scripts/retrieve-certificate.sh`.
