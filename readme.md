<!-- #!/usr/bin/env markdown
-*- coding: utf-8 -*-
region header
Copyright Torben Sickert (info["~at~"]tsickert.com) 16.12.2012

License
-------

This library written by Torben Sickert stands under a creative commons naming
4.0 international license.
See https://creativecommons.org/licenses/by/4.0/deed.de
endregion -->

<!--|deDE:Projektstatus-->
<!--|frFR:Statut du projet-->
Project status
--------------

[![build push image](https://img.shields.io/github/actions/workflow/status/thaibault/proxy/build-image-and-push-periodically-2.yaml?label=build%20push%20image&style=for-the-badge)](https://github.com/thaibault/proxy/actions/workflows/build-image-and-push-periodically-2.yaml)

[![lint](https://img.shields.io/github/actions/workflow/status/thaibault/proxy/lint.yaml?label=lint&style=for-the-badge)](https://github.com/thaibault/proxy/actions/workflows/lint.yaml)
[![test](https://img.shields.io/github/actions/workflow/status/thaibault/proxy/test.yaml?label=test&style=for-the-badge)](https://github.com/thaibault/proxy/actions/workflows/test.yaml)

[![deploy web documentation](https://img.shields.io/github/actions/workflow/status/thaibault/proxy/deploy-web-documentation.yaml?label=deploy%20web%20documentation&style=for-the-badge)](https://github.com/thaibault/proxy/actions/workflows/deploy-web-documentation.yaml)
[![web documentation](https://img.shields.io/website-up-down-green-red/https/tsickert.com/proxy.svg?label=web-documentation&style=for-the-badge)](https://tsickert.com/proxy)

<!--|deDE:Einsatzmöglichkeiten-->
<!--|frFR:Cas d'utilisation-->
Use case
--------

A docker based proxy server that is easy to configure. The image bundles an
[nginx](https://nginx.org) web server with a [certbot](https://certbot.eff.org)
service that retrieves and renews [Let's Encrypt](https://letsencrypt.org)
certificates for a configurable list of domains. Optionally the certificates
are uploaded to [Cloudflare](https://www.cloudflare.com), so that Cloudflare's
edge serves the same certificates and keeps them up to date.
<!--deDE:
    Ein einfach zu konfigurierender, Docker-basierter Proxy-Server. Das Image
    bündelt einen [nginx](https://nginx.org)-Webserver mit einem
    [certbot](https://certbot.eff.org)-Dienst, der
    [Let's Encrypt](https://letsencrypt.org)-Zertifikate für eine
    konfigurierbare Liste von Domains abruft und erneuert. Optional werden
    die Zertifikate zu [Cloudflare](https://www.cloudflare.com) hochgeladen,
    sodass Cloudflares Edge dieselben Zertifikate ausliefert und aktuell
    hält.
-->
<!--frFR:
    Un serveur proxy basé sur docker et facile à configurer. L'image réunit
    un serveur web [nginx](https://nginx.org) et un service
    [certbot](https://certbot.eff.org) qui obtient et renouvelle des
    certificats [Let's Encrypt](https://letsencrypt.org) pour une liste
    configurable de domaines. En option, les certificats sont envoyés à
    [Cloudflare](https://www.cloudflare.com), afin que le réseau de
    Cloudflare serve les mêmes certificats et les maintienne à jour.
-->

<div class="wd-table-of-contents">
    <h2 id="content">Content<!--deDE:Inhalt--><!--frFR:Contenu--></h2>
    <!--wd-table-of-contents-->
</div>

<!--|deDE:Funktionen-->
<!--|frFR:Fonctionnalités-->
Features
--------

- Nginx reverse proxy based on the Arch Linux
  [containerbase](https://tsickert.com/containerbase) image (runtime user
  handling, environment files and encrypted configuration included).<!--deDE:Nginx-Reverse-Proxy auf Basis des Arch-Linux-Images [containerbase](https://tsickert.com/containerbase) (inklusive Laufzeitbenutzer, Umgebungsdateien und verschlüsselter Konfiguration).--><!--frFR:Reverse proxy nginx basé sur l'image Arch Linux [containerbase](https://tsickert.com/containerbase) (gestion de l'utilisateur d'exécution, fichiers d'environnement et configuration chiffrée inclus).-->
- Plain nginx configuration: every "*.conf" file in "/etc/nginx/conf.d" is
  included into the "http" block.<!--deDE:Reine nginx-Konfiguration: Jede "*.conf"-Datei in "/etc/nginx/conf.d" wird in den "http"-Block eingebunden.--><!--frFR:Configuration nginx pure: chaque fichier "*.conf" de "/etc/nginx/conf.d" est inclus dans le bloc "http".-->
- Default server answering ACME challenges and redirecting every other HTTP
  request to HTTPS.<!--deDE:Standardserver, der ACME-Challenges beantwortet und jede andere HTTP-Anfrage auf HTTPS umleitet.--><!--frFR:Serveur par défaut qui répond aux challenges ACME et redirige toute autre requête HTTP vers HTTPS.-->
- Hardened TLS defaults (TLS 1.2 and 1.3, modern ciphers, HSTS, OCSP
  stapling) as reusable include files.<!--deDE:Gehärtete TLS-Voreinstellungen (TLS 1.2 und 1.3, moderne Cipher, HSTS, OCSP-Stapling) als wiederverwendbare Include-Dateien.--><!--frFR:Paramètres TLS renforcés (TLS 1.2 et 1.3, chiffrements modernes, HSTS, OCSP stapling) sous forme de fichiers à inclure réutilisables.-->
- Certificates are retrieved on startup and checked daily for renewal, any
  number of them, each covering multiple domains.<!--deDE:Zertifikate werden beim Start abgerufen und täglich auf Erneuerung geprüft, beliebig viele, jedes für mehrere Domains.--><!--frFR:Les certificats sont obtenus au démarrage et vérifiés chaque jour pour le renouvellement, en nombre quelconque, chacun couvrant plusieurs domaines.-->
- A certificate is retrieved again when its domain list changes.<!--deDE:Ein Zertifikat wird neu abgerufen, wenn sich seine Domainliste ändert.--><!--frFR:Un certificat est obtenu à nouveau lorsque sa liste de domaines change.-->
- Optional synchronization of every certificate into a Cloudflare zone as
  custom certificate.<!--deDE:Optionale Synchronisation jedes Zertifikats als benutzerdefiniertes Zertifikat in eine Cloudflare-Zone.--><!--frFR:Synchronisation optionnelle de chaque certificat dans une zone Cloudflare en tant que certificat personnalisé.-->
- Ready to use docker compose, podman (kubernetes) and systemd service files.<!--deDE:Einsatzbereite Dienstdateien für docker compose, podman (kubernetes) und systemd.--><!--frFR:Fichiers de service prêts à l'emploi pour docker compose, podman (kubernetes) et systemd.-->

Installation
------------

Pull the prebuilt image (built weekly for "x86-64" and "arm-64"):
<!--deDE:
    Laden Sie das vorgefertigte Image (wöchentlich für "x86-64" und
    "arm-64" gebaut):
-->
<!--frFR:
    Récupérez l'image précompilée (construite chaque semaine pour "x86-64"
    et "arm-64"):
-->

```bash
docker pull ghcr.io/thaibault/proxy:latest
```

The service files and the configuration skeleton live in this repository, so
clone it to the host:
<!--deDE:
    Die Dienstdateien und das Konfigurationsgerüst liegen in diesem
    Repository, klonen Sie es also auf den Host:
-->
<!--frFR:
    Les fichiers de service et le squelette de configuration se trouvent
    dans ce dépôt, clonez-le donc sur l'hôte:
-->

```bash
git clone https://github.com/thaibault/proxy.git
cd proxy
```

To build the image yourself run:
<!--deDE:Um das Image selbst zu bauen, führen Sie aus:-->
<!--frFR:Pour construire l'image vous-même, exécutez:-->

```bash
docker pull ghcr.io/thaibault/containerbase:latest
docker buildx build --no-cache --tag ghcr.io/thaibault/proxy:latest .
```

<!--|deDE:Verwendung-->
<!--|frFR:Utilisation-->
Usage
-----

<!--|deDE:Ordnerstruktur-->
<!--|frFR:Structure des dossiers-->
### Folder structure

The container expects three mounts (see "service/docker/mounts.yaml"):
<!--deDE:
    Der Container erwartet drei Einhängungen (siehe
    "service/docker/mounts.yaml"):
-->
<!--frFR:
    Le conteneur attend trois montages (voir "service/docker/mounts.yaml"):
-->

- "certificates/" → "/application/certificates": Retrieved certificates,
  certbot state, ACME challenges and log.<!--deDE:"certificates/" → "/application/certificates": Abgerufene Zertifikate, certbot-Zustand, ACME-Challenges und Protokoll.--><!--frFR:"certificates/" → "/application/certificates": Certificats obtenus, état de certbot, challenges ACME et journal.-->
- "etc/containerBase/" → "/etc/containerBase": "environment.sh" holding the
  configuration described below.<!--deDE:"etc/containerBase/" → "/etc/containerBase": "environment.sh" mit der unten beschriebenen Konfiguration.--><!--frFR:"etc/containerBase/" → "/etc/containerBase": "environment.sh" contenant la configuration décrite ci-dessous.-->
- "etc/nginx/" → "/etc/nginx/conf.d": Your nginx server configurations and
  helper includes.<!--deDE:"etc/nginx/" → "/etc/nginx/conf.d": Ihre nginx-Serverkonfigurationen und Hilfs-Includes.--><!--frFR:"etc/nginx/" → "/etc/nginx/conf.d": Vos configurations de serveur nginx et fichiers d'aide à inclure.-->

<!--|deDE:Starten-->
<!--|frFR:Démarrer-->
### Start

Locally (HTTP on port 8080, HTTPS on port 4443, local scripts mounted for
testing and no delay before the first certificate check):
<!--deDE:
    Lokal (HTTP auf Port 8080, HTTPS auf Port 4443, lokale Skripte zum Testen
    eingehängt und ohne Wartezeit vor der ersten Zertifikatsprüfung):
-->
<!--frFR:
    En local (HTTP sur le port 8080, HTTPS sur le port 4443, scripts locaux
    montés pour les tests et sans délai avant la première vérification des
    certificats):
-->

```bash
yarn start
```

which is a shortcut for:
<!--deDE:was eine Abkürzung ist für:-->
<!--frFR:ce qui est un raccourci pour:-->

```bash
docker compose \
    --file service/docker/base.yaml \
    --file service/docker/mounts.yaml \
    --file service/docker/local.yaml \
    up
```

In production use "service/docker/production.yaml" instead of
"service/docker/local.yaml". It binds the ports 80 and 443, restarts on
failure, limits log sizes and attaches the proxy to an external docker network
named "proxy". Attach your application containers to that network to reach
them by their container name from nginx:
<!--deDE:
    In Produktion verwenden Sie "service/docker/production.yaml" statt
    "service/docker/local.yaml". Es bindet die Ports 80 und 443, startet bei
    Fehlern neu, begrenzt die Protokollgröße und hängt den Proxy an ein
    externes Docker-Netzwerk namens "proxy". Hängen Sie Ihre
    Anwendungscontainer an dieses Netzwerk, um sie von nginx aus über ihren
    Containernamen zu erreichen:
-->
<!--frFR:
    En production, utilisez "service/docker/production.yaml" au lieu de
    "service/docker/local.yaml". Il lie les ports 80 et 443, redémarre en
    cas d'échec, limite la taille des journaux et rattache le proxy à un
    réseau docker externe nommé "proxy". Rattachez vos conteneurs
    d'application à ce réseau pour les joindre depuis nginx par leur nom de
    conteneur:
-->

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
<!--deDE:Mit podman verwenden Sie die Kubernetes-Manifeste:-->
<!--frFR:Avec podman, utilisez les manifestes kubernetes:-->

```bash
podman play kube service/kubernetes/production.yaml
```

The environment variable "IMAGE_TAG" selects the image tag when using docker
compose ("latest" by default).
<!--deDE:
    Die Umgebungsvariable "IMAGE_TAG" wählt bei docker compose das Image-Tag
    (standardmäßig "latest").
-->
<!--frFR:
    La variable d'environnement "IMAGE_TAG" choisit le tag de l'image avec
    docker compose ("latest" par défaut).
-->

<!--|deDE:Systemd-->
<!--|frFR:Systemd-->
### Systemd

"service/systemd" contains units to run the proxy on a host:
<!--deDE:
    "service/systemd" enthält Units, um den Proxy auf einem Host zu
    betreiben:
-->
<!--frFR:
    "service/systemd" contient des unités pour faire tourner le proxy sur
    un hôte:
-->

- "proxy.service" creates the "proxy" network and runs the production compose
  setup from "/srv/http/service/proxy" as user "service".<!--deDE:"proxy.service" legt das Netzwerk "proxy" an und startet das Produktions-Compose-Setup aus "/srv/http/service/proxy" als Benutzer "service".--><!--frFR:"proxy.service" crée le réseau "proxy" et lance la configuration compose de production depuis "/srv/http/service/proxy" en tant qu'utilisateur "service".-->
- "reload-proxy.service" reloads the nginx configuration (and with it all
  certificate files) of the running container.<!--deDE:"reload-proxy.service" lädt die nginx-Konfiguration (und damit alle Zertifikatsdateien) des laufenden Containers neu.--><!--frFR:"reload-proxy.service" recharge la configuration nginx (et avec elle tous les fichiers de certificats) du conteneur en cours d'exécution.-->
- "reload-proxy.timer" triggers "reload-proxy.service" five minutes after
  boot and once a week afterwards.<!--deDE:"reload-proxy.timer" löst "reload-proxy.service" fünf Minuten nach dem Start und danach einmal pro Woche aus.--><!--frFR:"reload-proxy.timer" déclenche "reload-proxy.service" cinq minutes après le démarrage puis une fois par semaine.-->

<!--|deDE:Nginx-Konfiguration-->
<!--|frFR:Configuration nginx-->
Nginx configuration
-------------------

All files matching "/etc/nginx/conf.d/*.conf" are included into the main
"http" block. The image itself only defines global settings (temporary paths,
gzip, websocket aware proxy headers and "resolver 8.8.8.8"). The included
files can be changed via
"PROXY_APPLICATION_SPECIFIC_NGINX_CONFIGURATION_FILE_PATH" at build time.
<!--deDE:
    Alle Dateien, die auf "/etc/nginx/conf.d/*.conf" passen, werden in den
    zentralen "http"-Block eingebunden. Das Image selbst definiert nur
    globale Einstellungen (temporäre Pfade, gzip, Websocket-fähige
    Proxy-Header und "resolver 8.8.8.8"). Die eingebundenen Dateien lassen
    sich beim Bauen über
    "PROXY_APPLICATION_SPECIFIC_NGINX_CONFIGURATION_FILE_PATH" ändern.
-->
<!--frFR:
    Tous les fichiers correspondant à "/etc/nginx/conf.d/*.conf" sont inclus
    dans le bloc "http" principal. L'image elle-même ne définit que des
    réglages globaux (chemins temporaires, gzip, en-têtes de proxy compatibles
    websocket et "resolver 8.8.8.8"). Les fichiers inclus peuvent être
    modifiés à la construction via
    "PROXY_APPLICATION_SPECIFIC_NGINX_CONFIGURATION_FILE_PATH".
-->

<!--|deDE:Standardserver-->
<!--|frFR:Serveur par défaut-->
### Default server

"etc/nginx/00_default.conf" defines the log formats and a default server on
port 80 that:
<!--deDE:
    "etc/nginx/00_default.conf" definiert die Protokollformate und einen
    Standardserver auf Port 80, der:
-->
<!--frFR:
    "etc/nginx/00_default.conf" définit les formats de journal et un
    serveur par défaut sur le port 80 qui:
-->

- serves "/.well-known/acme-challenge/" from
  "/application/certificates/acme-challenge/" (needed for certificate
  retrievals and renewals) and<!--deDE:"/.well-known/acme-challenge/" aus "/application/certificates/acme-challenge/" ausliefert (nötig für das Abrufen und Erneuern von Zertifikaten) und--><!--frFR:sert "/.well-known/acme-challenge/" depuis "/application/certificates/acme-challenge/" (nécessaire pour obtenir et renouveler les certificats) et-->
- redirects every other request permanently to HTTPS.<!--deDE:jede andere Anfrage dauerhaft auf HTTPS umleitet.--><!--frFR:redirige définitivement toute autre requête vers HTTPS.-->

<!--|deDE:Hilfs-Includes-->
<!--|frFR:Fichiers d'aide à inclure-->
### Helper includes

- "helper/ssl.include" contains the TLS protocol, cipher, session, HSTS and
  OCSP stapling settings.<!--deDE:"helper/ssl.include" enthält die Einstellungen für TLS-Protokolle, Cipher, Sitzungen, HSTS und OCSP-Stapling.--><!--frFR:"helper/ssl.include" contient les réglages de protocole TLS, de chiffrement, de session, de HSTS et d'OCSP stapling.-->
- "helper/certificate.include" includes "ssl.include" and points nginx to the
  files of a certificate named "web". Nginx does not support variables in
  these directives, so for certificates with other names copy the file and
  replace "web" accordingly.<!--deDE:"helper/certificate.include" bindet "ssl.include" ein und verweist nginx auf die Dateien eines Zertifikats namens "web". Nginx unterstützt in diesen Direktiven keine Variablen, kopieren Sie die Datei für Zertifikate mit anderen Namen also und ersetzen Sie "web" entsprechend.--><!--frFR:"helper/certificate.include" inclut "ssl.include" et indique à nginx les fichiers d'un certificat nommé "web". Nginx ne prend pas en charge les variables dans ces directives, copiez donc le fichier pour des certificats d'un autre nom et remplacez "web" en conséquence.-->

The include also expects a Diffie-Hellman parameter file, which has to be
created once:
<!--deDE:
    Das Include erwartet außerdem eine Diffie-Hellman-Parameterdatei, die
    einmalig erzeugt werden muss:
-->
<!--frFR:
    Le fichier attend aussi un fichier de paramètres Diffie-Hellman, à
    créer une seule fois:
-->

```bash
mkdir --parents certificates/web
openssl dhparam -out certificates/web/dhparam.pem 4096
```

A typical application server configuration (e.g.
"etc/nginx/application.conf") looks like this:
<!--deDE:
    Eine typische Serverkonfiguration einer Anwendung (z. B.
    "etc/nginx/application.conf") sieht so aus:
-->
<!--frFR:
    Une configuration de serveur d'application typique (par exemple
    "etc/nginx/application.conf") ressemble à ceci:
-->

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

<!--|deDE:Zertifikate-->
<!--|frFR:Certificats-->
Certificates
------------

<!--|deDE:Konfiguration-->
<!--|frFR:Configuration-->
### Configuration

Certificates are configured in "etc/containerBase/environment.sh", which is
sourced on container start. The lists are Bash arrays matched by their index:
<!--deDE:
    Zertifikate werden in "etc/containerBase/environment.sh" konfiguriert,
    das beim Containerstart eingelesen wird. Die Listen sind Bash-Arrays und
    werden über ihren Index einander zugeordnet:
-->
<!--frFR:
    Les certificats sont configurés dans "etc/containerBase/environment.sh",
    lu au démarrage du conteneur. Les listes sont des tableaux Bash associés
    par leur indice:
-->

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
Without "PROXY_CERTIFICATES" no certificates are managed and only nginx is
started.
<!--deDE:
    Ein einzelnes Zertifikat lässt sich auch über einfache
    Umgebungsvariablen konfigurieren (z. B. in einer Compose-Datei), da sich
    ein Skalar wie ein Array mit einem Element verhält. Ohne
    "PROXY_CERTIFICATES" werden keine Zertifikate verwaltet und nur nginx
    wird gestartet.
-->
<!--frFR:
    Un seul certificat peut aussi être configuré via de simples variables
    d'environnement (par exemple dans un fichier compose), car un scalaire
    se comporte comme un tableau à un élément. Sans "PROXY_CERTIFICATES",
    aucun certificat n'est géré et seul nginx est démarré.
-->

<!--|deDE:Ablauf-->
<!--|frFR:Déroulement-->
### Lifecycle

1. Startup: Every certificate that has not been retrieved yet, or whose
   domain list differs from the one it was retrieved for (stored in
   "certificates/&lt;name&gt;/domains.txt"), is retrieved via certbot's own
   web server before nginx starts.<!--deDE:Start: Jedes Zertifikat, das noch nicht abgerufen wurde oder dessen Domainliste von der beim Abruf verwendeten abweicht (gespeichert in "certificates/&lt;name&gt;/domains.txt"), wird vor dem Start von nginx über certbots eigenen Webserver abgerufen.--><!--frFR:Démarrage: Chaque certificat pas encore obtenu, ou dont la liste de domaines diffère de celle utilisée lors de son obtention (enregistrée dans "certificates/&lt;name&gt;/domains.txt"), est obtenu via le serveur web propre à certbot avant le démarrage de nginx.-->
2. Start delay: The certificate service waits
   "PROXY_CERTIFICATES_START_UPDATE_DELAY" before its first check, so that
   frequent container restarts do not run into Let's Encrypt rate limits.<!--deDE:Startverzögerung: Der Zertifikatsdienst wartet "PROXY_CERTIFICATES_START_UPDATE_DELAY" bis zur ersten Prüfung, damit häufige Containerneustarts nicht in die Ratenbegrenzung von Let's Encrypt laufen.--><!--frFR:Délai de démarrage: Le service de certificats attend "PROXY_CERTIFICATES_START_UPDATE_DELAY" avant sa première vérification, afin que des redémarrages fréquents du conteneur n'atteignent pas les limites de Let's Encrypt.-->
3. Daily checks: Every 24 hours each certificate is renewed through the
   running nginx when it is close to expiry. Certificates with a changed
   domain list are retrieved again.<!--deDE:Tägliche Prüfungen: Alle 24 Stunden wird jedes Zertifikat kurz vor Ablauf über das laufende nginx erneuert. Zertifikate mit geänderter Domainliste werden neu abgerufen.--><!--frFR:Vérifications quotidiennes: Toutes les 24 heures, chaque certificat proche de l'expiration est renouvelé via le nginx en cours d'exécution. Les certificats dont la liste de domaines a changé sont obtenus à nouveau.-->
4. Reload: Nginx is reloaded every seventh check to pick up renewed
   certificates. Use the systemd timer or
   `docker exec proxy nginx -s reload` for more frequent reloads.<!--deDE:Neuladen: Nginx wird bei jeder siebten Prüfung neu geladen, um erneuerte Zertifikate zu übernehmen. Für häufigeres Neuladen verwenden Sie den systemd-Timer oder `docker exec proxy nginx -s reload`.--><!--frFR:Rechargement: Nginx est rechargé toutes les sept vérifications pour prendre en compte les certificats renouvelés. Pour des rechargements plus fréquents, utilisez le timer systemd ou `docker exec proxy nginx -s reload`.-->

All certificate activity is logged to "certificates/log.txt" (configurable via
"CERTIFICATION_SERVICE_LOG"). Certbot's own logs are written to
"/tmp/&lt;name&gt;/letsEncryptLog" inside the container.
<!--deDE:
    Alle Zertifikatsaktivitäten werden in "certificates/log.txt"
    protokolliert (änderbar über "CERTIFICATION_SERVICE_LOG"). Certbots
    eigene Protokolle landen im Container unter
    "/tmp/&lt;name&gt;/letsEncryptLog".
-->
<!--frFR:
    Toute l'activité liée aux certificats est journalisée dans
    "certificates/log.txt" (modifiable via "CERTIFICATION_SERVICE_LOG"). Les
    journaux propres à certbot sont écrits dans le conteneur sous
    "/tmp/&lt;name&gt;/letsEncryptLog".
-->

<!--|deDE:Cloudflare-Synchronisation-->
<!--|frFR:Synchronisation avec Cloudflare-->
### Cloudflare synchronization

Each certificate can additionally be uploaded to a Cloudflare zone as
[custom certificate](https://developers.cloudflare.com/ssl/edge-certificates/custom-certificates/).
The proxy keeps it up to date: the first upload creates the custom
certificate, every renewal replaces it, and if it has been deleted on
Cloudflare a new one is created.
<!--deDE:
    Jedes Zertifikat kann zusätzlich als
    [benutzerdefiniertes Zertifikat](https://developers.cloudflare.com/ssl/edge-certificates/custom-certificates/)
    in eine Cloudflare-Zone hochgeladen werden. Der Proxy hält es aktuell:
    Das erste Hochladen legt das Zertifikat an, jede Erneuerung ersetzt es,
    und wurde es bei Cloudflare gelöscht, wird ein neues angelegt.
-->
<!--frFR:
    Chaque certificat peut en plus être envoyé dans une zone Cloudflare en
    tant que
    [certificat personnalisé](https://developers.cloudflare.com/ssl/edge-certificates/custom-certificates/).
    Le proxy le maintient à jour: le premier envoi crée le certificat
    personnalisé, chaque renouvellement le remplace, et s'il a été supprimé
    chez Cloudflare, un nouveau est créé.
-->

```bash
# Zone id per certificate (same order as "PROXY_CERTIFICATES"). An empty
# entry disables the synchronization for that certificate.
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

Synchronization runs on startup (so existing certificates are uploaded as soon
as a zone is configured) and after every daily check. An upload only happens
if the certificate or key changed since the last successful upload. The
Cloudflare certificate id and a fingerprint of the uploaded files are stored
in "certificates/&lt;name&gt;/cloudflareCertificateID.txt" and
"certificates/&lt;name&gt;/cloudflareCertificateFingerprint.txt". Delete them
to force a new upload. A failing upload is logged but neither prevents nginx
from starting nor stops the certificate service.
<!--deDE:
    Die Synchronisation läuft beim Start (so werden vorhandene Zertifikate
    hochgeladen, sobald eine Zone konfiguriert ist) und nach jeder täglichen
    Prüfung. Hochgeladen wird nur, wenn sich Zertifikat oder Schlüssel seit
    dem letzten erfolgreichen Hochladen geändert haben. Die
    Cloudflare-Zertifikats-ID und ein Fingerabdruck der hochgeladenen
    Dateien werden in "certificates/&lt;name&gt;/cloudflareCertificateID.txt"
    und "certificates/&lt;name&gt;/cloudflareCertificateFingerprint.txt"
    gespeichert. Löschen Sie diese, um ein erneutes Hochladen zu erzwingen.
    Ein fehlgeschlagenes Hochladen wird protokolliert, verhindert aber weder
    den Start von nginx noch stoppt es den Zertifikatsdienst.
-->
<!--frFR:
    La synchronisation s'exécute au démarrage (les certificats existants
    sont donc envoyés dès qu'une zone est configurée) et après chaque
    vérification quotidienne. Un envoi n'a lieu que si le certificat ou la
    clé a changé depuis le dernier envoi réussi. L'identifiant du certificat
    Cloudflare et une empreinte des fichiers envoyés sont enregistrés dans
    "certificates/&lt;name&gt;/cloudflareCertificateID.txt" et
    "certificates/&lt;name&gt;/cloudflareCertificateFingerprint.txt".
    Supprimez-les pour forcer un nouvel envoi. Un envoi en échec est
    journalisé mais n'empêche ni le démarrage de nginx ni le fonctionnement
    du service de certificats.
-->

- Custom certificates require a Cloudflare Business or Enterprise plan, or
  the Advanced Certificate Manager add-on for "sni_custom".<!--deDE:Benutzerdefinierte Zertifikate erfordern einen Cloudflare-Business- oder -Enterprise-Tarif oder für "sni_custom" das Add-on Advanced Certificate Manager.--><!--frFR:Les certificats personnalisés nécessitent une offre Cloudflare Business ou Enterprise, ou l'extension Advanced Certificate Manager pour "sni_custom".-->
- Let's Encrypt validates domains via HTTP. Cloudflare passes
  "/.well-known/acme-challenge/" requests through to the origin even with
  proxying and "Always Use HTTPS" enabled, so renewals keep working.<!--deDE:Let's Encrypt prüft Domains über HTTP. Cloudflare reicht Anfragen an "/.well-known/acme-challenge/" auch bei aktiviertem Proxying und "Always Use HTTPS" an den Ursprungsserver durch, Erneuerungen funktionieren also weiter.--><!--frFR:Let's Encrypt valide les domaines via HTTP. Cloudflare transmet les requêtes vers "/.well-known/acme-challenge/" au serveur d'origine même avec le proxy et "Always Use HTTPS" activés, les renouvellements continuent donc de fonctionner.-->
- Store the API token in an encrypted environment file (see containerbase)
  rather than in plain text.<!--deDE:Legen Sie das API-Token besser in einer verschlüsselten Umgebungsdatei ab (siehe containerbase) als im Klartext.--><!--frFR:Stockez le jeton d'API dans un fichier d'environnement chiffré (voir containerbase) plutôt qu'en clair.-->

<!--|deDE:Umgebungsvariablen-->
<!--|frFR:Variables d'environnement-->
Environment variables
---------------------

- "PROXY_CERTIFICATES": Certificate names (array).<!--deDE:"PROXY_CERTIFICATES": Zertifikatsnamen (Array).--><!--frFR:"PROXY_CERTIFICATES": Noms des certificats (tableau).-->
- "PROXY_CERTIFICATE_DOMAINS": Space separated domains per certificate
  (array).<!--deDE:"PROXY_CERTIFICATE_DOMAINS": Leerzeichengetrennte Domains je Zertifikat (Array).--><!--frFR:"PROXY_CERTIFICATE_DOMAINS": Domaines séparés par des espaces pour chaque certificat (tableau).-->
- "PROXY_CERTIFICATE_EMAIL_ADDRESSES": Let's Encrypt account e-mail address
  per certificate (array).<!--deDE:"PROXY_CERTIFICATE_EMAIL_ADDRESSES": E-Mail-Adresse des Let's-Encrypt-Kontos je Zertifikat (Array).--><!--frFR:"PROXY_CERTIFICATE_EMAIL_ADDRESSES": Adresse e-mail du compte Let's Encrypt pour chaque certificat (tableau).-->
- "PROXY_CERTIFICATES_START_UPDATE_DELAY": Delay before the first renewal
  check, "50m" by default.<!--deDE:"PROXY_CERTIFICATES_START_UPDATE_DELAY": Wartezeit bis zur ersten Erneuerungsprüfung, standardmäßig "50m".--><!--frFR:"PROXY_CERTIFICATES_START_UPDATE_DELAY": Délai avant la première vérification de renouvellement, "50m" par défaut.-->
- "PROXY_CERTIFICATE_CLOUDFLARE_ZONE_IDS": Cloudflare zone id per
  certificate (array).<!--deDE:"PROXY_CERTIFICATE_CLOUDFLARE_ZONE_IDS": Cloudflare-Zonen-ID je Zertifikat (Array).--><!--frFR:"PROXY_CERTIFICATE_CLOUDFLARE_ZONE_IDS": Identifiant de zone Cloudflare pour chaque certificat (tableau).-->
- "PROXY_CERTIFICATE_CLOUDFLARE_API_TOKENS": Cloudflare API token per
  certificate (array, optional).<!--deDE:"PROXY_CERTIFICATE_CLOUDFLARE_API_TOKENS": Cloudflare-API-Token je Zertifikat (Array, optional).--><!--frFR:"PROXY_CERTIFICATE_CLOUDFLARE_API_TOKENS": Jeton d'API Cloudflare pour chaque certificat (tableau, optionnel).-->
- "PROXY_CLOUDFLARE_API_TOKEN": Default Cloudflare API token.<!--deDE:"PROXY_CLOUDFLARE_API_TOKEN": Standard-Cloudflare-API-Token.--><!--frFR:"PROXY_CLOUDFLARE_API_TOKEN": Jeton d'API Cloudflare par défaut.-->
- "PROXY_CLOUDFLARE_API_URL": Cloudflare API base URL,
  "https://api.cloudflare.com/client/v4" by default.<!--deDE:"PROXY_CLOUDFLARE_API_URL": Basis-URL der Cloudflare-API, standardmäßig "https://api.cloudflare.com/client/v4".--><!--frFR:"PROXY_CLOUDFLARE_API_URL": URL de base de l'API Cloudflare, "https://api.cloudflare.com/client/v4" par défaut.-->
- "PROXY_CLOUDFLARE_BUNDLE_METHOD": Chain bundling of uploaded certificates,
  "ubiquitous" by default.<!--deDE:"PROXY_CLOUDFLARE_BUNDLE_METHOD": Kettenbündelung hochgeladener Zertifikate, standardmäßig "ubiquitous".--><!--frFR:"PROXY_CLOUDFLARE_BUNDLE_METHOD": Regroupement de la chaîne des certificats envoyés, "ubiquitous" par défaut.-->
- "PROXY_CLOUDFLARE_CERTIFICATE_TYPE": Type of uploaded custom certificates,
  "sni_custom" by default.<!--deDE:"PROXY_CLOUDFLARE_CERTIFICATE_TYPE": Typ hochgeladener benutzerdefinierter Zertifikate, standardmäßig "sni_custom".--><!--frFR:"PROXY_CLOUDFLARE_CERTIFICATE_TYPE": Type des certificats personnalisés envoyés, "sni_custom" par défaut.-->
- "PROXY_APPLICATION_SPECIFIC_NGINX_CONFIGURATION_FILE_PATH": Nginx
  configuration files to include at build time,
  "/etc/nginx/conf.d/*.conf" by default.<!--deDE:"PROXY_APPLICATION_SPECIFIC_NGINX_CONFIGURATION_FILE_PATH": Beim Bauen einzubindende nginx-Konfigurationsdateien, standardmäßig "/etc/nginx/conf.d/*.conf".--><!--frFR:"PROXY_APPLICATION_SPECIFIC_NGINX_CONFIGURATION_FILE_PATH": Fichiers de configuration nginx à inclure à la construction, "/etc/nginx/conf.d/*.conf" par défaut.-->
- "CERTIFICATION_SERVICE_LOG": Log file of the certificate service,
  "/application/certificates/log.txt" by default.<!--deDE:"CERTIFICATION_SERVICE_LOG": Protokolldatei des Zertifikatsdienstes, standardmäßig "/application/certificates/log.txt".--><!--frFR:"CERTIFICATION_SERVICE_LOG": Fichier journal du service de certificats, "/application/certificates/log.txt" par défaut.-->
- "COMMAND": Command started after initialization, "nginx" by default.<!--deDE:"COMMAND": Nach der Initialisierung gestarteter Befehl, standardmäßig "nginx".--><!--frFR:"COMMAND": Commande lancée après l'initialisation, "nginx" par défaut.-->

Variables of the [containerbase](https://tsickert.com/containerbase) image
are supported as well, e.g. to change the runtime user or to decrypt
encrypted configuration files ("DECRYPT", "ENCRYPTED_PATHS",
"DECRYPTED_PATHS").
<!--deDE:
    Variablen des Images [containerbase](https://tsickert.com/containerbase)
    werden ebenfalls unterstützt, z. B. um den Laufzeitbenutzer zu ändern
    oder verschlüsselte Konfigurationsdateien zu entschlüsseln ("DECRYPT",
    "ENCRYPTED_PATHS", "DECRYPTED_PATHS").
-->
<!--frFR:
    Les variables de l'image
    [containerbase](https://tsickert.com/containerbase) sont aussi prises en
    charge, par exemple pour changer l'utilisateur d'exécution ou déchiffrer
    des fichiers de configuration chiffrés ("DECRYPT", "ENCRYPTED_PATHS",
    "DECRYPTED_PATHS").
-->

<!--|deDE:Befehle im Container-->
<!--|frFR:Commandes dans le conteneur-->
Container commands
------------------

The following commands handle certificates manually inside the container
(e.g. via `docker exec proxy <command>`). "&lt;path&gt;" is the certificate
folder, e.g. "/application/certificates/web/" (the trailing slash is
required):
<!--deDE:
    Die folgenden Befehle verwalten Zertifikate von Hand im Container (z. B.
    über `docker exec proxy <command>`). "&lt;path&gt;" ist der
    Zertifikatsordner, z. B. "/application/certificates/web/" (der
    abschließende Schrägstrich ist erforderlich):
-->
<!--frFR:
    Les commandes suivantes gèrent les certificats à la main dans le
    conteneur (par exemple via `docker exec proxy <command>`).
    "&lt;path&gt;" est le dossier du certificat, par exemple
    "/application/certificates/web/" (la barre oblique finale est
    obligatoire):
-->

- "retrieve-certificate [--initialize] &lt;name&gt; &lt;path&gt;
  '&lt;domains&gt;' &lt;e-mail&gt;": Retrieves a certificate. "--initialize"
  uses certbot's own web server while nginx is not running.<!--deDE:"retrieve-certificate [--initialize] &lt;name&gt; &lt;path&gt; '&lt;domains&gt;' &lt;e-mail&gt;": Ruft ein Zertifikat ab. "--initialize" verwendet certbots eigenen Webserver, solange nginx nicht läuft.--><!--frFR:"retrieve-certificate [--initialize] &lt;name&gt; &lt;path&gt; '&lt;domains&gt;' &lt;e-mail&gt;": Obtient un certificat. "--initialize" utilise le serveur web propre à certbot tant que nginx ne tourne pas.-->
- "update-certificate &lt;name&gt; &lt;path&gt; '&lt;domains&gt;'
  &lt;e-mail&gt;": Renews a certificate if it is close to expiry.<!--deDE:"update-certificate &lt;name&gt; &lt;path&gt; '&lt;domains&gt;' &lt;e-mail&gt;": Erneuert ein Zertifikat, wenn es bald abläuft.--><!--frFR:"update-certificate &lt;name&gt; &lt;path&gt; '&lt;domains&gt;' &lt;e-mail&gt;": Renouvelle un certificat proche de l'expiration.-->
- "synchronize-cloudflare-certificate &lt;name&gt; &lt;path&gt;
  &lt;zone-id&gt;": Uploads a certificate to Cloudflare (needs
  "PROXY_CLOUDFLARE_API_TOKEN").<!--deDE:"synchronize-cloudflare-certificate &lt;name&gt; &lt;path&gt; &lt;zone-id&gt;": Lädt ein Zertifikat zu Cloudflare hoch (benötigt "PROXY_CLOUDFLARE_API_TOKEN").--><!--frFR:"synchronize-cloudflare-certificate &lt;name&gt; &lt;path&gt; &lt;zone-id&gt;": Envoie un certificat à Cloudflare (nécessite "PROXY_CLOUDFLARE_API_TOKEN").-->
- "initialize-certificates": Retrieves all configured certificates which are
  missing.<!--deDE:"initialize-certificates": Ruft alle konfigurierten, noch fehlenden Zertifikate ab.--><!--frFR:"initialize-certificates": Obtient tous les certificats configurés manquants.-->
- "certificate-service": Runs the periodic renewal loop.<!--deDE:"certificate-service": Führt die periodische Erneuerungsschleife aus.--><!--frFR:"certificate-service": Exécute la boucle de renouvellement périodique.-->

`docker exec proxy nginx -s reload` reloads the nginx configuration.
<!--deDE:
    `docker exec proxy nginx -s reload` lädt die nginx-Konfiguration neu.
-->
<!--frFR:
    `docker exec proxy nginx -s reload` recharge la configuration nginx.
-->

<!--|deDE:Entwicklung-->
<!--|frFR:Développement-->
Development
-----------

```bash
yarn install
# Lint all shell scripts via shellcheck.
yarn lint
# Run the scripts against recorded fake commands (needs "jq").
yarn test
# Start locally with the scripts of this working copy mounted.
yarn start
```

For testing against Let's Encrypt's staging environment add "--test-cert" to
the certbot call in "scripts/retrieve-certificate.sh".
<!--deDE:
    Zum Testen gegen die Staging-Umgebung von Let's Encrypt ergänzen Sie
    "--test-cert" im certbot-Aufruf in "scripts/retrieve-certificate.sh".
-->
<!--frFR:
    Pour tester avec l'environnement de staging de Let's Encrypt, ajoutez
    "--test-cert" à l'appel de certbot dans
    "scripts/retrieve-certificate.sh".
-->
