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

A docker based proxy server easily configurable.

<div class="wd-table-of-contents">
    <h2 id="content">Content<!--deDE:Inhalt--><!--frFR:Contenu--></h2>
    <!--wd-table-of-contents-->
</div>

Installation
------------

You can install via package manager, simply download the compiled version as
zip file here and inject or request via CDN in HTML:
<!--deDE:
    Sie können das Paket über den Paketmanager installieren oder einfach die
    kompilierte Version als ZIP-Datei hier herunterladen und in HTML einbinden
    oder über ein CDN abrufen:
-->
<!--frFR:
    Vous pouvez installer le paquet via le gestionnaire de paquets ou
    simplement télécharger ici la version compilée sous forme de fichier ZIP,
    puis l'intégrer dans une page HTML ou la récupérer via un CDN:
-->

```bash
npm install proxy
```
