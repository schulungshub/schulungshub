#!/bin/bash
# SchulungsHub – Neue Abteilung anlegen
# Direkt auf dem Server ausführen (per SSH).
#
# Usage:
#   ./create-dept.sh <dept-name> <slug> <admin-user> <admin-passwort> [admin-anzeigename]
#
# Beispiel:
#   ./create-dept.sh "Siebdruck" siebdruck admin "Passwort123!" "Admin"
#
# Voraussetzung: SETUP_KEY muss in .env gesetzt sein
#
set -e

DEPT_NAME="${1}"
DEPT_SLUG="${2}"
ADMIN_USER="${3}"
ADMIN_PASS="${4}"
ADMIN_NAME="${5:-$ADMIN_USER}"
# Port aus .env laden falls vorhanden
if [[ -f ".env" ]]; then
  PORT=$(grep '^PORT=' .env | cut -d'=' -f2-)
fi
PORT="${PORT:-8080}"
SERVER="http://localhost:$PORT"

if [[ -z "$DEPT_NAME" || -z "$DEPT_SLUG" || -z "$ADMIN_USER" || -z "$ADMIN_PASS" ]]; then
  echo "Fehler: Pflichtfelder fehlen."
  echo "Usage: $0 \"Abt.-Name\" slug admin-user passwort [anzeigename]"
  echo "Beispiel: $0 \"Siebdruck\" siebdruck admin Passwort123"
  exit 1
fi

# SETUP_KEY aus .env laden falls nicht bereits gesetzt
if [[ -z "$SETUP_KEY" && -f ".env" ]]; then
  SETUP_KEY=$(grep '^SETUP_KEY=' .env | cut -d'=' -f2-)
fi

if [[ -z "$SETUP_KEY" ]]; then
  echo "Fehler: SETUP_KEY nicht gesetzt. In .env eintragen: SETUP_KEY=dein-geheimschluessel"
  exit 1
fi

PAYLOAD=$(cat <<JSON
{
  "dept_name":  "$DEPT_NAME",
  "dept_slug":  "$DEPT_SLUG",
  "admin_user": "$ADMIN_USER",
  "admin_name": "$ADMIN_NAME",
  "admin_pass": "$ADMIN_PASS"
}
JSON
)

echo "Erstelle Abteilung '$DEPT_NAME' (Slug: $DEPT_SLUG) auf $SERVER ..."

RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST "$SERVER/api/setup/department" \
  -H "Content-Type: application/json" \
  -H "X-Setup-Key: $SETUP_KEY" \
  -d "$PAYLOAD")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [[ "$HTTP_CODE" == "200" ]]; then
  echo "Erfolgreich!"
  echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
  echo ""
  echo "Login: $SERVER → Abteilung '$DEPT_NAME' → Benutzer '$ADMIN_USER'"
else
  echo "Fehler (HTTP $HTTP_CODE): $BODY"
  exit 1
fi
