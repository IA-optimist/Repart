# REPART — Marketplace internationale de pièces automobiles d'occasion

**Statut : démonstration V0.6, pas de transactions réelles.** REPART est actuellement un prototype de recherche de pièces automobiles, avec navigation FR / NL / EN / AR, comparateur, catalogue voitures étendu (source VehiclesDB) et simulation des parcours vendeurs / commandes.

## Démonstration publique

- [Page d'accueil](https://repart-auto-demo.vercel.app/)
- [Explorateur de véhicules](https://repart-auto-demo.vercel.app/catalogue-auto.html)

> Les annonces, comptes vendeurs, commandes, données de paiement et correspondances véhicule/pièce ne sont **pas** des données commerciales réelles. Les annonces sauvegardées dans le navigateur ne sont pas partagées entre appareils.

## Stack technique (V0.6)

- **Frontend** : HTML, CSS et JavaScript, sans build ni secret serveur.
- **Hébergement** : Vercel Static Hosting, contenu de `public/`.
- **Données automobiles** : VehiclesDB `v2026.10.3` sous CC BY 4.0 chargé depuis un CDN public, avec mode dégradé ; ni compatibilités OEM validées, ni catalogue constructeur sous licence.
- **Backend futur** : PostgreSQL / Supabase dédié, schéma préparatoire dans `backend/` (**non déployé**).

## Démarrage local

```bash
python -m http.server 8000 --directory public
```

Ouvrir http://localhost:8000/ puis http://localhost:8000/catalogue-auto.html.

## Contrôles rapides

```bash
python tests/check_security.py
python tests/check_site.py
```

`tests/smoke.py` contient des tests navigateur complémentaires utilisant Playwright et Chromium. Il faut installer Playwright et Chromium séparément pour les exécuter ; ces tests utilisent **des modèles de voitures synthétiques**. Les validations statiques ne remplacent pas un audit RLS sur une vraie base de test.

## Déploiement sur Vercel

Le projet Vercel public `repart-marketplace-demo` existe déjà. Lier **ce nouveau dépôt** au projet existant dans les paramètres Git, au lieu de créer un second site. La configuration `vercel.json` sert `public/` comme sortie statique.

**Important** : tant que le dépôt n'est pas effectivement connecté à Vercel, les changements GitHub ne sont pas automatiquement déployés. Tester sur une Preview avant toute mise à jour de Production. Ne pas activer de paiement réel ni de backend sans contrôle des permissions et de conformité.

Voir `docs/DEPLOIEMENT.md` pour la procédure.

## Feuille de route

1. Importer les marques et modèles dans un référentiel versionné avec attributions.
2. Préciser générations, phases, codes moteurs, provenance et correspondances OEM — données non garanties par VehiclesDB.
3. Ouvrir un **projet Supabase indépendant** (pas `smartcontact-dev`), vérifier le RLS avec plusieurs comptes de test.
4. Développer authentification, publication validée, photos et commandes réelles.
5. Négocier les licences de catalogues constructeurs et les droits d'affichage des vues éclatées.
6. Choisir un PSP marketplace compatible Europe / Maroc, KYC, litiges et versements différés.

## Licences et droits

- Catalogue externe : [VehiclesDB](https://github.com/vehiclesdb/vehiclesdb) — vérifier ses conditions d'attribution, dont les notices des sources nationales.
- Illustrations techniques : schémas de démonstration, non issus de catalogues OEM sous licence.
- Le code de ce dépôt n'a **pas** de licence open source attribuée pour le moment. Ne pas supposer qu'il peut être réutilisé librement.

**Hébergement et coûts** : le plan Hobby de Vercel est destiné à un usage non commercial ; basculer vers un hébergement adapté avant une mise en exploitation commerciale.
