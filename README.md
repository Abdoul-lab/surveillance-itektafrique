# Surveillance ITEKTAFRIQUE

Vérifie toutes les 15 minutes que les sites d'ITEKTAFRIQUE répondent :

| Contrôle | Ce qui est vérifié |
|---|---|
| Site — accueil | `www.itektafrique-ci.com` répond 200 avec l'application |
| Site — page Services | `/services` répond 200 avec son titre |
| Site — envoi des formulaires | le script PHP d'envoi répond (405 attendu à une simple lecture) |
| Portail — page de connexion | `portail.itektafrique-ci.com/login` répond 200 |
| Portail — API et base de données | la liste publique des réalisations répond 200 (PHP et MySQL en marche) |
| Landing | `digital.itektafrique-ci.com` répond 200 |

## Alertes

- Un contrôle n'est déclaré en panne qu'après **3 essais à une minute d'intervalle** : une coupure de quelques secondes ne déclenche rien.
- En cas de panne, une alerte (ticket avec l'étiquette « panne ») est ouverte dans ce dépôt : **GitHub envoie un e-mail** au propriétaire.
- Quand tout répond de nouveau, l'alerte est commentée puis fermée automatiquement (nouvel e-mail).
- Une seule alerte reste ouverte à la fois, même si la panne dure.

## Fonctionnement

- `verifier.sh` : les contrôles (lancer `./verifier.sh` sur un poste pour vérifier à la main).
- `.github/workflows/surveillance.yml` : la planification et les alertes. Lancement manuel : onglet **Actions → Surveillance → Run workflow**. La case « Tester les alertes » simule une panne : une alerte s'ouvre (avec son e-mail), puis se ferme au passage suivant.
- Dépôt public : les exécutions de GitHub Actions y sont gratuites et illimitées. Il ne contient aucun code du site ni aucun secret, seulement des adresses déjà publiques.
- GitHub suspend les tâches planifiées d'un dépôt inactif depuis 60 jours : la surveillance fait un petit commit par semaine (`derniere-verification.txt`) pour rester active.
- L'heure de passage des tâches planifiées de GitHub peut glisser de quelques minutes aux heures chargées.
