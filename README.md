# GDO-MT Mobile

Application Android hors ligne de gestion des ouvrages Moyenne Tension, basée sur les données et les fonctionnalités du dépôt [GDO](https://github.com/redatest/GDO).

## Téléchargement

[**Télécharger l'APK Android — GDO-MT (build 3)**](https://github.com/redatest/GDO-mobile-ap/releases/download/mobile-build-3/GDO-MT.apk)

> Version publiée : build 3. Ce lien est automatiquement actualisé après chaque nouvelle compilation réussie.

## Fonctionnement

- Application Android empaquetée avec Flutter.
- Interface GDO-MT et modules JavaScript embarqués dans l'APK.
- Référentiels topologiques et tables réseau intégrés à la compilation depuis le dépôt source.
- Exécution locale via une adresse loopback ; aucun serveur distant n'est requis.
- Les préférences, visites et inspections thermographiques sont conservées localement sur l'appareil.
- Aucune synchronisation avec GDO en ligne : les données de référence correspondent à la version intégrée lors de la compilation.

## Compilation

Le workflow GitHub Actions récupère le dépôt source `redatest/GDO`, embarque les fichiers nécessaires, compile l'APK Android en mode release et publie l'artefact dans une release GitHub. Après publication, il met automatiquement à jour le lien de téléchargement et le numéro de build dans ce README.

Pour lancer manuellement le workflow : **Actions → Build Android APK → Run workflow**.

## Dépôts

- Application Android : https://github.com/redatest/GDO-mobile-ap
- Application source : https://github.com/redatest/GDO

## Licence et données

Les données et la logique métier proviennent du dépôt GDO source. L'APK est un instantané local de ces données au moment du build.
