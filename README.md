# SchulungsHub

Digitale Einarbeitungsplattform für die Produktion. Entwickelt für den Einsatz in der **Siebdruck-Fertigung** – nutzbar für alle Produktionsabteilungen (z. B. Siebdruck, Spritzguss, Finishing).

Serverbasiert, multi-mandant-fähig, vollständig offline-tauglich im Intranet.

---

## Inhaltsverzeichnis

1. [Überblick & Einsatzzweck](#überblick--einsatzzweck)
2. [Installation](#installation)
3. [Abteilungen verwalten](#abteilungen-verwalten)
4. [Architektur & Aufbau](#architektur--aufbau)
5. [Konfiguration](#konfiguration)
6. [Sicherheit](#sicherheit)
7. [API-Referenz](#api-referenz)
8. [Datenbankschema](#datenbankschema)

---

## Überblick & Einsatzzweck

SchulungsHub digitalisiert den Einarbeitungsprozess in der Produktion. Neue Mitarbeiter durchlaufen ein strukturiertes Schulungsprogramm – von der Maschinenbedienung bis zur Sicherheitsunterweisung.

### Kernfunktionen

- **Lerninhalte** – Markdown-basierte Schulungsunterlagen, strukturiert als Inhaltsbaum (Kapitel, Abschnitte, Unterabschnitte)
- **Lernziele** – Je Maschine/Prozessgruppe definierbare Ziele, gewichtet und mit Fortschrittsbalken (0–100 %)
- **Trainer-Workflow** – Trainer bewertet Lernziele mit 25/50/75/100/NIO, bestätigt Abschnitte als „Freigegeben"
- **Trainee-Quittierung** – Trainee bestätigt Abschnitte als „Empfangen" (digitale Unterschrift-Ersatz)
- **Anwesenheitserfassung** – Stunden pro Tag und Maschine, Fortschrittsanzeige
- **Prüfungsmodus** – Single-Choice, Wahr/Falsch, Bildaufgaben; automatische Auswertung
- **RFID-Login** – Schnell-Login per RFID-Karte/Chip am Maschinenarbeitsplatz
- **Export** – Vollständiger JSON-Dump der Abteilung (per API, für Archivierung oder Migration)
- **Multi-Mandant** – Vollständige Datenisolierung zwischen Abteilungen via `dept_id`
- **Auto-Migrate** – Server erstellt Datenbank und Schema beim Start automatisch

### Rollen

| Rolle     | Beschreibung                                                     |
|-----------|------------------------------------------------------------------|
| `admin`   | Inhalte pflegen, Benutzer verwalten, Export, alle Einsichten     |
| `trainer` | Trainees bewerten, Abschnitte freigeben, Anwesenheit erfassen    |
| `trainee` | Eigene Schulungsinhalte lesen, Prüfungen ablegen, quittieren     |

---

## Installation

### Voraussetzungen

- Linux-Server (x86_64)
- MySQL 8.0
- Ein freier Port (Standard: 8080)

### Schritt für Schritt

```bash
# 1. Dateien auf den Server kopieren
#    Binary + web-v4/ + create-dept.sh + delete-dept.sh + .env.example

# 2. Konfiguration anlegen
cp .env.example .env
nano .env          # DB-Zugangsdaten + SETUP_KEY eintragen

# 3. Server starten (erstellt Datenbank + Tabellen automatisch)
./schulungshub-linux-amd64

# 4. Erste Abteilung anlegen
./create-dept.sh "Siebdruck" siebdruck admin "MeinPasswort123!"

# 5. Browser öffnen
#    http://<server-ip>:8080
```

### Was passiert beim ersten Start?

Der Server verbindet sich mit MySQL, erstellt die Datenbank (falls nicht vorhanden) und legt alle Tabellen + Indizes automatisch an. Kein manuelles SQL nötig.

### Dateien im Paket

```
schulungshub/
├── schulungshub-linux-amd64    Binary (direkt ausführbar)
├── .env.example                Konfigurations-Vorlage
├── create-dept.sh              Neue Abteilung anlegen
├── delete-dept.sh              Abteilung + alle Daten löschen
└── web-v4/                     Frontend (wird vom Server ausgeliefert)
    ├── index.html
    ├── login.html
    ├── style.css
    ├── js/                     Anwendungsmodule
    └── vendor/                 UIkit, marked.js, Fonts (alles lokal)
```

### Als systemd-Service einrichten (optional)

```ini
# /etc/systemd/system/schulungshub.service
[Unit]
Description=SchulungsHub
After=mysql.service

[Service]
WorkingDirectory=/opt/schulungshub
ExecStart=/opt/schulungshub/schulungshub-linux-amd64
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
systemctl daemon-reload
systemctl enable --now schulungshub
```

---

## Abteilungen verwalten

Jede Abteilung ist ein vollständig isolierter Mandant mit eigenen Inhalten, Benutzern, Lernzielen und Prüfungen.

### Neue Abteilung anlegen

```bash
./create-dept.sh "Siebdruck" siebdruck admin "MeinPasswort123!"
./create-dept.sh "Spritzguss" spritzguss admin "AnderesPasswort!"
```

**Parameter:**
```
./create-dept.sh <Name> <Slug> <Admin-User> <Passwort> [Anzeigename]
```

- **Name** – Anzeigename im Login-Dropdown (z. B. „Siebdruck")
- **Slug** – Eindeutiger Kurzname, keine Leerzeichen (z. B. `siebdruck`)
- **Admin-User** – Benutzername des ersten Admins
- **Passwort** – Passwort für den Admin
- Der SETUP_KEY wird automatisch aus `.env` gelesen
- Doppelte Slugs werden abgelehnt (HTTP 409)

### Abteilung löschen

```bash
./delete-dept.sh siebdruck
```

Löscht die Abteilung und **alle** zugehörigen Daten (Benutzer, Bewertungen, Inhalte, Prüfungen). Erfordert Bestätigung durch erneute Eingabe des Slugs.

### Nach dem Anlegen

1. Im Browser einloggen → Abteilung im Dropdown auswählen
2. Als Admin: Maschinen anlegen
3. Lerninhalte und Lernziele erstellen
4. Benutzer anlegen (Trainer + Trainees)

---

## Architektur & Aufbau

### Systemübersicht

```
Browser (Chrome/Edge)
       |
       | HTTP(S)
       v
+---------------------------+
|  SchulungsHub Server      |  Ein einzelner Prozess, kein Framework
|                           |
|  Go Binary                |  REST-API (JSON) + statische Dateien
|  web-v4/ (Frontend)       |  HTML + JS + CSS, vom Server ausgeliefert
+---------------------------+
       |
       v
+---------------------------+
|  MySQL 8.0                |  schulungshub DB, utf8mb4
+---------------------------+
```

Die gesamte Anwendung besteht aus **einem Binary + einem Ordner**. Der Go-Server liefert sowohl die API als auch das Frontend aus. Es gibt keinen separaten Webserver, keinen Node.js-Prozess, kein npm.

### Wie hängt alles zusammen?

```
schulungshub-linux-amd64          ← Der Server (ein Prozess)
  │
  ├── liest .env                  ← DB-Zugangsdaten, Port, Setup-Key
  │
  ├── verbindet sich mit MySQL    ← erstellt DB + Tabellen beim Start
  │
  ├── liefert web-v4/ aus         ← Frontend (HTML/JS/CSS) als statische Dateien
  │   │
  │   ├── login.html              ← Login-Seite: Abteilung wählen → User wählen → Passwort
  │   ├── index.html              ← Hauptanwendung (Single Page App)
  │   ├── js/                     ← 24 Module: Sidebar, Editor, Bewertung, Prüfung, Admin...
  │   ├── vendor/                 ← UIkit (UI-Framework), marked.js (Markdown), Fonts
  │   └── img/                    ← Gefahrensymbole, Icons
  │
  └── stellt REST-API bereit      ← /api/auth/*, /api/users/*, /api/content/*, ...
      │
      ├── auth/                   ← Login, Sessions, RFID, Rate Limiting
      ├── api/                    ← Daten-Handler: Benutzer, Inhalte, Ziele, Bewertungen, Prüfung
      └── config/                 ← .env einlesen
```

### Datenfluss

1. Browser öffnet `login.html` → wählt Abteilung → wählt Benutzer → gibt Passwort ein
2. `POST /api/auth/login` → Server prüft Passwort (PBKDF2) → erstellt Session in MySQL → setzt Cookie
3. Browser wird auf `index.html` weitergeleitet → lädt alle JS-Module
4. Jede Aktion (Inhalt laden, Bewertung speichern, Benutzer anlegen) = ein API-Call
5. Server prüft bei jedem Request: Cookie gültig? → Rolle? → `dept_id` filtern → Antwort

**Kein lokaler Cache:** Kein State im Browser (kein LocalStorage, kein IndexedDB). Daten kommen immer frisch vom Server.

### Frontend-Module (web-v4/js/)

| Modul              | Aufgabe                                              |
|--------------------|------------------------------------------------------|
| `state.js`         | Globaler State, lädt alle Daten per API              |
| `sidebar.js`       | Navigation, Inhaltsbaum                              |
| `editor.js`        | Markdown-Editor für Lerninhalte (Admin)               |
| `scoring.js`       | Bewertungs-Buttons (25/50/75/100/NIO)                |
| `render.js`        | Seitenaufbau, Abschnitte darstellen                  |
| `admin.js`         | Benutzerverwaltung, Rollenzuweisung                  |
| `exam.js`          | Prüfungsmodus (Fragen, Timer, Auswertung)            |
| `eval.js`          | Fortschrittsberechnung, KPI-Anzeige                  |
| `auth.js`          | Session-Prüfung, Logout                              |
| `search.js`        | Volltextsuche                                        |
| `goal-editor.js`   | Lernziele verwalten (Admin)                          |
| `export.js`        | JSON-Export                                          |
| `app.js`           | Orchestrierung – startet alle Module in der richtigen Reihenfolge |

Alle Module kommunizieren über `api-client.js` – einen zentralen HTTP-Wrapper. Kein Modul macht eigene `fetch()`-Aufrufe.

### Backend-Struktur (Go-Quellcode)

| Verzeichnis   | Aufgabe                                              |
|---------------|------------------------------------------------------|
| `main.go`     | Einstiegspunkt, Router, Auto-Migrate                 |
| `api/`        | REST-Handler für alle Daten-Endpoints                |
| `auth/`       | Login, Sessions, Passwort-Hashing, Rate Limiting     |
| `config/`     | `.env` einlesen, Konfiguration bereitstellen         |

### Tech-Stack

| Komponente       | Technologie                          |
|------------------|--------------------------------------|
| Backend          | Go (stdlib `net/http`, kein Framework)|
| Datenbank        | MySQL 8.0, InnoDB, utf8mb4           |
| Passwort-Hash    | PBKDF2-SHA256 (120.000 Iterationen)  |
| Sessions         | Server-seitig in MySQL, HttpOnly Cookie |
| Frontend         | Vanilla JS, kein Build-Step          |
| UI-Framework     | UIkit 3 (lokal gebündelt)            |
| Markdown         | marked.js (lokal gebündelt)          |
| Externe Abhängigkeiten | Keine – alles lokal, kein CDN, kein npm |

---

## Konfiguration

Konfiguration via `.env`-Datei im selben Verzeichnis wie die Binary.

| Variable         | Standard        | Beschreibung                                    |
|------------------|-----------------|-------------------------------------------------|
| `DB_HOST`        | `127.0.0.1`     | MySQL-Host                                      |
| `DB_PORT`        | `3306`          | MySQL-Port                                      |
| `DB_USER`        | `root`          | MySQL-Benutzer                                  |
| `DB_PASS`        | *(leer)*        | MySQL-Passwort                                  |
| `DB_NAME`        | `schulungshub`  | Datenbankname (wird automatisch erstellt)        |
| `PORT`           | `8080`          | HTTP-Port des Servers                           |
| `SECURE_COOKIES` | `true`          | `true` = nur mit HTTPS, `false` = auch ohne     |
| `SETUP_KEY`      | *(leer)*        | Geheimschlüssel für Abteilungs-Verwaltung       |

**Ohne HTTPS:** `SECURE_COOKIES=false` setzen, sonst funktioniert der Login nicht.

**SETUP_KEY:** Frei wählbar, z. B. `mein-geheimer-schluessel`. Wird nur beim Anlegen/Löschen von Abteilungen gebraucht.

---

## Sicherheit

- **Passwörter:** PBKDF2-SHA256, 120.000 Iterationen, kryptografischer Salt. Kein Klartext.
- **Sessions:** 32 Byte Token, HttpOnly + Secure Cookie, 12 h Ablauf, in MySQL gespeichert
- **Rate Limiting:** 5 Fehlversuche in 5 Minuten → 5 Minuten Sperre (pro IP)
- **Body-Limit:** 2 MB Maximum pro Request
- **Fehlerausgabe:** Interne Fehler werden nur server-seitig geloggt, dem Client wird nur `"internal server error"` zurückgegeben
- **Mandantentrennung:** Jede DB-Query filtert nach `dept_id`, keine Datenleckage zwischen Abteilungen
- **RFID:** Tag-ID wird SHA-256-gehasht, kein Klartext gespeichert

---

## API-Referenz

### Authentifizierung (öffentlich)

| Methode | Pfad                        | Beschreibung                              |
|---------|-----------------------------|-------------------------------------------|
| POST    | `/api/auth/login`           | Login via Username + Passwort             |
| POST    | `/api/auth/logout`          | Session löschen, Cookie leeren            |
| GET     | `/api/auth/me`              | Aktuell eingeloggter Benutzer + Rolle     |
| GET     | `/api/auth/departments`     | Alle Abteilungen (für Login-Dropdown)     |
| GET     | `/api/auth/login-users`     | Benutzer einer Abteilung (für Dropdown)   |
| POST    | `/api/auth/rfid-login`      | Login via RFID-Tag (SHA-256-Hash)         |

### Setup (geschützt via `X-Setup-Key` Header)

| Methode | Pfad                        | Beschreibung                              |
|---------|-----------------------------|-------------------------------------------|
| POST    | `/api/setup/department`     | Neue Abteilung + Admin-User anlegen       |

### Benutzer (geschützt)

| Methode | Pfad                        | Rolle          | Beschreibung              |
|---------|-----------------------------|----------------|---------------------------|
| GET     | `/api/users`                | alle           | Benutzerliste             |
| POST    | `/api/users`                | admin          | Benutzer anlegen          |
| PUT     | `/api/users/:id`            | admin / selbst | Stammdaten ändern         |
| PUT     | `/api/users/:id/password`   | admin / selbst | Passwort ändern           |
| PUT     | `/api/users/:id/rfid`       | admin          | RFID-Hash setzen          |
| PUT     | `/api/users/:id/theme`      | admin / selbst | Theme speichern           |
| DELETE  | `/api/users/:id`            | admin          | Soft-Delete               |

### Daten (geschützt)

| Methode | Pfad                          | Beschreibung                              |
|---------|-------------------------------|-------------------------------------------|
| GET     | `/api/machines`               | Maschinen/Prozessgruppen                  |
| GET/PUT | `/api/meta`                   | Key-Value-Konfiguration                   |
| GET/POST| `/api/content`                | Lerninhalte (Abschnitte)                  |
| PUT/DEL | `/api/content/:id`            | Abschnitt bearbeiten/löschen              |
| GET/POST| `/api/goals`                  | Lernziele                                 |
| PUT/DEL | `/api/goals/:id`              | Lernziel bearbeiten/löschen               |
| GET/POST| `/api/evaluations`            | Bewertungen                               |
| GET/POST| `/api/attendance`             | Anwesenheit                               |
| GET/PUT | `/api/trainee-meta/:id`       | Trainee-Notizen                           |
| GET/POST| `/api/confirmations`          | Abschnitts-Bestätigungen                  |
| GET     | `/api/search?q=...`           | Volltextsuche                             |

### Prüfung (geschützt)

| Methode | Pfad                          | Beschreibung                              |
|---------|-------------------------------|-------------------------------------------|
| GET/POST| `/api/exam/questions`         | Prüfungsfragen                            |
| PUT/DEL | `/api/exam/questions/:id`     | Frage bearbeiten/löschen                  |
| GET     | `/api/exam/questions/count`   | Anzahl verfügbarer Fragen                 |
| GET/POST| `/api/exam/results`           | Prüfungsergebnisse                        |
| DELETE  | `/api/exam/results/:id`       | Ergebnis löschen (Admin)                  |

### Export (geschützt, Admin)

| Methode | Pfad           | Beschreibung                              |
|---------|----------------|-------------------------------------------|
| GET     | `/api/export`  | Vollständiger JSON-Dump der Abteilung     |

---

## Datenbankschema

Wird beim ersten Start automatisch erstellt (Auto-Migrate).

| Tabelle                | Beschreibung                                          |
|------------------------|-------------------------------------------------------|
| `departments`          | Mandanten (Abteilungen) mit Feature-Flags             |
| `users`                | Benutzer (Admin / Trainer / Trainee), soft-deletable  |
| `sessions`             | Server-seitige Sessions, 12 h Ablauf                  |
| `machines`             | Maschinen / Prozessgruppen                            |
| `content_sections`     | Lerninhalte (Markdown), Baumstruktur via `parent_id`  |
| `section_confirmations`| Trainer-Freigabe + Trainee-Quittierung pro Abschnitt  |
| `learning_goals`       | Lernziele je Maschine/Phase, gewichtet (0–100)        |
| `evaluations`          | Bewertungshistorie (append-only)                      |
| `trainee_meta`         | Freitext-Notizen pro Trainee                          |
| `attendance`           | Anwesenheitsstunden pro Tag und Maschine              |
| `meta`                 | Key-Value-Konfiguration pro Abteilung                 |
| `exam_questions`       | Prüfungsfragen (Single-Choice, Wahr/Falsch, Bild)     |
| `exam_results`         | Prüfungsergebnisse mit Einzelantworten (JSON)         |

---

## Lizenz

Proprietär – Alle Rechte vorbehalten.
