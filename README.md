# Prévision de l'Inflation avec le Modèle P-Star (SAS)

**Projet académique (Master 1 Économétrie, Statistiques)**

Ce dépôt contient le code SAS et le rapport de mon projet d'analyse économétrique sur la validité du modèle P-Star pour la prévision de l'inflation.

## 1. Objectif

Ce projet vise à tester empiriquement la validité du **modèle économétrique $P^{*}$ (P-Star)**, basé sur la théorie quantitative de la monnaie, pour la prévision de l'inflation à long terme. L'analyse est menée sur les données des États-Unis, du Japon et du Royaume-Uni.

## 2. Méthodologie Économétrique

* Tests de Stationnarité (ADF)
* Tests de Cointégradation (Engle-Granger)
* Modélisation à Correction d'Erreur (ECM)
* Tests de performance prédictive (Diebold-Mariano)

## 3. Résultats Clés

* Validation du modèle P-Star pour les États-Unis (période 1960-1990), avec un **R² de 0.82**.
* Le test de Diebold-Mariano a confirmé la supériorité prédictive du modèle ECM par rapport à une marche aléatoire.
* L'analyse a révélé des performances moindres sur les périodes plus récentes et pour les autres pays (Japon, UK).

## 4. Structure du Dépôt

* **[<code>MemoireS2_Martinez_Linale_Johnson_Beuzeval.pdf</code>](./MemoireS2_Martinez_Linale_Johnson_Beuzeval.pdf) :** Le rapport académique complet, détaillant la théorie, la méthodologie et les conclusions.
* **[<code>Prev_Inf_USA_1960_1990.sas</code>](./Prev_Inf_USA_1960_1990.sas) :** Code SAS pour l'analyse sur les données US (période de validation du modèle).
* **[<code>Prev_Inf_USA_1990_2015.sas</code>](./Prev_Inf_USA_1990_2015.sas) :** Code SAS pour l'analyse sur les données US (période post-1990).
* **[<code>Prev_Inf_UK.sas</code>](./Prev_Inf_UK.sas) :** Code SAS pour l'application du modèle au Royaume-Uni.
* **[<code>Prev_Inf_JAP.sas</code>](./Prev_Inf_JAP.sas) :** Code SAS pour l'application du modèle au Japon.

## 5. Technologie

* L'ensemble de l'analyse a été implémenté en **SAS 9.4**.
