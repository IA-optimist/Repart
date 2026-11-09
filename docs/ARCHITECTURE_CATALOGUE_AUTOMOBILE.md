# REPART V0.5 — Architecture du catalogue automobile

**Date : 28 octobre 2026**  
**Production Vercel :** https://repart-auto-demo.vercel.app/  
**Recherche automobile :** https://repart-auto-demo.vercel.app/catalogue-auto.html

## 1. Situation réelle

- Site : prototype public V0.5, annonces et commandes de démonstration.
- Recherche étendue : connexion navigateur à VehiclesDB v2026.10.3 (catalogue ouvert), avec liste de secours si le CDN est indisponible.
- Générations / phases : démonstration validée sur la Volkswagen Polo V 6R/6C ; pas de couverture globale garantie.
- Vues éclatées : interface pédagogique originale, **pas de plans constructeur OEM**.
- Données fournisseurs : navigateur local, pas encore synchronisées.
- Compte vendeur / base Supabase / paiements : **non connectés**.

## 2. Jeu de données gratuit

**VehiclesDB**, version 2026.10.3, CC BY 4.0. Le projet indique 15 068 modèles tous véhicules confondus, dont **5 541 modèles d'automobiles** et **315 marques de voitures**. Données établies à partir de registres de plusieurs pays, mais elles ne contiennent pas toutes les variantes de fabrication, générations, VIN, références OEM ou compatibilités de pièces.

Sources :
- https://github.com/vehiclesdb/vehiclesdb
- https://github.com/vehiclesdb/vehiclesdb/blob/main/ATTRIBUTION.md
- https://github.com/vehiclesdb/vehiclesdb/blob/main/SCHEMA.md

**Important** : pour une future exploitation commerciale, conserver les attributions CC BY et les éventuelles mentions complémentaires des registres publics. Pinner la version des fichiers, vérifier les mises à jour et ne pas confondre présence d'un modèle et compatibilité.

## 3. Sources complémentaires envisagées

| Fournisseur | Usage | Statut |
|---|---|---|
| VehiclesDB | Marques et modèles globaux | Ouvert, utilisé pour le nouveau sélecteur |
| RDW Open Data | Informations immatriculations et types néerlandais | Gratuit, analyse d'intégration à faire |
| NHTSA vPIC | Décodage VIN et nomenclature, surtout Amérique du Nord | API officielle, prudence sur couverture européenne |
| TecDoc / TecAlliance | Types véhicule, KTypes, OE, liens de compatibilité | Licence commerciale nécessaire |
| LexCom partslink24 | Catalogues OEM, recherche par VIN | Licence pour affichage / réutilisation non acquise |
| 7zap | Plans, ensembles, références | Pas de droit de scraping ou republication ; accord commercial nécessaire |
| mobile.de / AutoScout24 | Vocabulaire commercial de véhicules, pas base technique OEM | Ne pas recopier automatiquement les annonces ni créer une base dérivée sans licence |

## 4. Identification correcte

Hiérarchie retenue :

1. **Marque** (`make_id`, alias, code canonique)
2. **Modèle** (`model_id`, identifiant stable)
3. **Génération** (`generation_id`, codes constructeur, période)
4. **Phase** (`phase_id`, avant/après restylage, dates)
5. **Année ET date de fabrication**, non pas seulement date de première immatriculation
6. **Motorisation / boîte / traction** (codes moteur et boîte, carburant, puissance)
7. **Marché de fabrication / destination** (BE, NL, FR, MA, etc.)
8. **Option constructeur / code équipement** (PR-code VW, si pertinent)
9. **Référence OEM**, substituts et ruptures de référence
10. **Correspondances pièces ↔ véhicules** avec preuve, restrictions et provenance

Les données absentes sont **non vérifiées**, jamais inférées comme compatibles. Exemple Volkswagen officiel : Polo V 6R (avant 2014), restylage 6C en 2014 ; une Polo 2012 n'est pas une 6C. L'année 2014 peut demander une vérification de date exacte ou de VIN.

Référence : https://www.volkswagen-newsroom.com/en/polo-5-20092017-20044

## 5. Schéma de données recommandé (PostgreSQL)

Tables proposées :

- `vehicle_makes(id, slug, name, source, source_version)`
- `vehicle_models(id, make_id, slug, name, market_ids[], source, source_version)`
- `vehicle_generations(id, model_id, factory_code, year_from, year_to, provenance_id)`
- `vehicle_phases(id, generation_id, phase_code, produced_from, produced_to, provenance_id)`
- `engine_variants(id, phase_id, engine_code, fuel, displacement_cc, power_kw, transmission_code)`
- `vehicle_equipment(id, variant_id, option_code, option_kind)`
- `part_groups(id, parent_id, name, diagram_id)`
- `oem_parts(id, brand, oem_number, normalized_number, part_group_id)`
- `oem_supersessions(old_part_id, new_part_id, valid_from)`
- `part_fitments(id, part_id, variant_id, vin_from, vin_to, manufactured_from, manufactured_to, source_id, confidence)`
- `diagrams(id, provider, external_ref, license_scope, source_revision)`
- `diagram_hotspots(diagram_id, position, oem_part_id, bounds)`
- `seller_listings(id, seller_id, donor_variant_id, oem_part_id, quantity, condition, price, ship_from)`
- `data_provenance(id, provider, version, fetched_at, license, source_url, verified_at)`

**Règle de sécurité** : toute référence constructeur nécessite une provenance et ses restrictions de montage. Pas de compatibilité « confirmée » sans référence technique fiable.

## 6. Stratégie technique économique

1. Un **fichier statique versionné** pour marques/modèles, avec cache CDN.
2. PostgreSQL indexé pour variantes, références OEM et offres vendeurs.
3. Requêtes **à la demande** pour les données très détaillées (et cache à durée contrôlée selon la licence).
4. Photos vendeurs dans un stockage objet compressé, servi par CDN.
5. Diagrammes sous licence hébergés selon les autorisations contractuelles.
6. Éviter de télécharger toute la base OEM dans le navigateur ou sur chaque requête.

Le volume de marques/modèles ne justifie pas un gros serveur. Les vrais postes de coût seront **licences**, stockage de photos, trafic et traitement des images, intégration des catalogues techniques, litiges et paiements.

## 7. Vérifications avant vente réelle

- Taux d'identification des véhicules BE / NL / FR / MA sur un échantillon représentatif.
- `precision@1` et taux de compatibilité confirmée par une source indépendante.
- Contrôle VIN, code moteur, date et génération pour les modèles à restylage.
- Tests de recherche OEM avec espaces, tirets, supersessions.
- Taux d'erreurs de commande et retour pour pièce incompatible.
- Contrôle des clauses commerciales des données et diagrammes.
- RLS et isolation vendeur-vendeur avant toute mise en production de comptes.

## 8. Prochain jalon recommandé

Créer une base **REPART dédiée** (ne pas réutiliser `smartcontact-dev`), importer la nomenclature ouverte, puis définir une interface `VehicleProvider` remplaçable. Contacter TecAlliance pour obtenir un devis d'API couvrant précisément BE/NL/FR/MA et les pièces d'occasion. Pour les diagrammes OEM, négocier explicitement le droit d'affichage public dans une marketplace multivendeurs.

**Ne pas ouvrir les paiements** avant validation des flux KYC vendeurs, séquestre/versement différé, litiges et ventes transfrontalières.
