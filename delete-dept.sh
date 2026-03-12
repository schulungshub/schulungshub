#!/bin/bash
# SchulungsHub – Abteilung loeschen
# ACHTUNG: Loescht die Abteilung und ALLE zugehoerigen Daten unwiderruflich!
#
# Usage:
#   ./delete-dept.sh <slug>
#
# Beispiel:
#   ./delete-dept.sh siebdruck
#
set -e

DEPT_SLUG="${1}"

if [[ -z "$DEPT_SLUG" ]]; then
  echo "Usage: $0 <slug>"
  echo "Beispiel: $0 siebdruck"
  exit 1
fi

# DB-Zugangsdaten aus .env laden
if [[ -f ".env" ]]; then
  DB_USER=$(grep '^DB_USER=' .env | cut -d'=' -f2-)
  DB_PASS=$(grep '^DB_PASS=' .env | cut -d'=' -f2-)
  DB_HOST=$(grep '^DB_HOST=' .env | cut -d'=' -f2-)
  DB_PORT=$(grep '^DB_PORT=' .env | cut -d'=' -f2-)
  DB_NAME=$(grep '^DB_NAME=' .env | cut -d'=' -f2-)
fi

DB_USER="${DB_USER:-root}"
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-3306}"
DB_NAME="${DB_NAME:-schulungshub}"

# Abteilung pruefen
DEPT=$(mysql -u "$DB_USER" -p"$DB_PASS" -h "$DB_HOST" -P "$DB_PORT" "$DB_NAME" -N -e \
  "SELECT CONCAT(id, ' ', name) FROM departments WHERE slug = '$DEPT_SLUG'" 2>/dev/null)

if [[ -z "$DEPT" ]]; then
  echo "Fehler: Abteilung '$DEPT_SLUG' nicht gefunden."
  exit 1
fi

DEPT_ID=$(echo "$DEPT" | awk '{print $1}')
DEPT_NAME=$(echo "$DEPT" | cut -d' ' -f2-)

echo ""
echo "Abteilung gefunden: $DEPT_NAME (ID: $DEPT_ID, Slug: $DEPT_SLUG)"
echo ""
echo "ACHTUNG: Alle Daten dieser Abteilung werden unwiderruflich geloescht:"
echo "  - Alle Benutzer, Bewertungen, Lerninhalte, Pruefungen, Anwesenheiten"
echo ""
read -p "Zum Bestaetigen '$DEPT_SLUG' eingeben: " CONFIRM

if [[ "$CONFIRM" != "$DEPT_SLUG" ]]; then
  echo "Abgebrochen."
  exit 1
fi

mysql -u "$DB_USER" -p"$DB_PASS" -h "$DB_HOST" -P "$DB_PORT" "$DB_NAME" -e \
  "DELETE FROM departments WHERE slug = '$DEPT_SLUG'" 2>/dev/null

echo "Abteilung '$DEPT_NAME' geloescht."
