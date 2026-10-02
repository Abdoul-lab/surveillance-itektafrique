#!/usr/bin/env bash
# Vérifie que le site et le portail ITEKTAFRIQUE répondent.
#
#   ./verifier.sh            → affiche le résultat, code de sortie 1 si une panne est détectée
#
# Chaque contrôle est retenté deux fois, à une minute d'intervalle, avant
# d'être déclaré en panne : une coupure de quelques secondes ne déclenche rien.

set -u

NAVIGATEUR='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0 Safari/537.36'
ESSAIS="${ESSAIS:-3}"
PAUSE="${PAUSE:-60}"

# nom | adresse | code HTTP attendu | texte attendu dans la réponse (vide = aucun)
CONTROLES=(
  "Site — accueil|https://www.itektafrique-ci.com/|200|<div id=\"root\">"
  "Site — page Services|https://www.itektafrique-ci.com/services|200|Nos services IT"
  "Site — envoi des formulaires (PHP)|https://www.itektafrique-ci.com/api/contact.php|405|\"ok\":false"
  "Portail — page de connexion|https://portail.itektafrique-ci.com/login|200|Portail ITEKTAFRIQUE"
  "Portail — API et base de données|https://portail.itektafrique-ci.com/backend/api/realisations_public.php|200|\"realisations\""
  "Landing|https://digital.itektafrique-ci.com/|200|"
)

# Test des alertes : SIMULER_PANNE=true ajoute un contrôle qui échoue forcément.
if [ "${SIMULER_PANNE:-false}" = "true" ]; then
  CONTROLES+=("Test d'alerte (simulation volontaire)|https://www.itektafrique-ci.com/simulation-de-panne|200|")
fi

# Renvoie 0 si le contrôle passe. Écrit le diagnostic dans $DIAGNOSTIC.
controler() {
  local adresse="$1" code_attendu="$2" texte="$3" corps code
  corps="$(mktemp)"
  code="$(curl -s -o "$corps" -w '%{http_code}' --max-time 30 -A "$NAVIGATEUR" "$adresse" 2>/dev/null)"
  [ -z "$code" ] && code="000"

  # L'hébergeur (LWS) répond parfois 403 avec une page « vérification en cours »
  # aux adresses de centres de données : le serveur est bien en ligne.
  if [ "$code" = "403" ] && grep -q 'LWS Protection' "$corps"; then
    DIAGNOSTIC="en ligne (vérification anti-robot de l'hébergeur)"
    rm -f "$corps"; return 0
  fi
  if [ "$code" != "$code_attendu" ]; then
    DIAGNOSTIC="code HTTP $code au lieu de $code_attendu"
    [ "$code" = "000" ] && DIAGNOSTIC="aucune réponse (délai dépassé ou connexion impossible)"
    rm -f "$corps"; return 1
  fi
  if [ -n "$texte" ] && ! grep -qF -- "$texte" "$corps"; then
    DIAGNOSTIC="répond $code mais le contenu attendu est absent"
    rm -f "$corps"; return 1
  fi
  DIAGNOSTIC="OK ($code)"
  rm -f "$corps"; return 0
}

PANNES=()
for ligne in "${CONTROLES[@]}"; do
  IFS='|' read -r nom adresse code texte <<< "$ligne"
  reussi=0
  for essai in $(seq 1 "$ESSAIS"); do
    if controler "$adresse" "$code" "$texte"; then reussi=1; break; fi
    [ "$essai" -lt "$ESSAIS" ] && sleep "$PAUSE"
  done
  if [ "$reussi" = 1 ]; then
    echo "✅ $nom — $DIAGNOSTIC"
  else
    echo "❌ $nom — $DIAGNOSTIC ($adresse)"
    PANNES+=("$nom — $DIAGNOSTIC")
  fi
done

if [ "${#PANNES[@]}" -gt 0 ]; then
  {
    echo "pannes<<FIN_PANNES"
    printf -- '- %s\n' "${PANNES[@]}"
    echo "FIN_PANNES"
  } >> "${GITHUB_OUTPUT:-/dev/null}"
  exit 1
fi
