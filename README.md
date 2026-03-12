# SchulungsHub – Technische Dokumentation

Digitale Einarbeitungsplattform für die Produktion. Entwickelt für den Einsatz in der **Siebdruck-Fertigung** – nutzbar für alle Produktionsabteilungen (z. B. Siebdruck, Spritzguss, Finishing).

Serverbasiert, multi-mandant-fähig, vollständig offline-tauglich im Intranet.

---

## Überblick & Einsatzzweck

SchulungsHub digitalisiert den Einarbeitungsprozess in der Produktion. Neue Mitarbeiter durchlaufen ein strukturiertes Schulungsprogramm – von der Maschinenbedienung bis zur Sicherheitsunterweisung.

### Kernfunktionen

- **Lerninhalte** – Markdown-basierte Schulungsunterlagen, strukturiert als Inhaltsbaum
- **Lernziele** – Je Maschine/Prozessgruppe definierbare Ziele, gewichtet (0–100 %)
- **Trainer-Workflow** – Bewertung mit 25/50/75/100/NIO, Abschnitte freigeben
- **Trainee-Quittierung** – Digitale Bestätigung durch den Trainee
- **Anwesenheitserfassung** – Stunden pro Tag und Maschine
- **Prüfungsmodus** – Single-Choice, Wahr/Falsch, Bildaufgaben; automatische Auswertung
- **RFID-Login** – Schnell-Login per RFID-Karte/Chip
- **Export** – Vollständiger JSON-Dump der Abteilung
- **Multi-Mandant** – Datenisolierung zwischen Abteilungen via `dept_id`

### Rollen

| Rolle     | Beschreibung                                                     |
|-----------|------------------------------------------------------------------|
| `admin`   | Inhalte pflegen, Benutzer verwalten, Export, alle Einsichten     |
| `trainer` | Trainees bewerten, Abschnitte freigeben, Anwesenheit erfassen    |
| `trainee` | Eigene Schulungsinhalte lesen, Prüfungen ablegen, quittieren     |

---

## Architektur

```
Browser (Chrome/Edge)
       |
       | HTTPS (Reverse Proxy)
       v
+---------------------------+
|  Go HTTP Server           |
|  main.go    Router, Middleware
|  api/       REST-Handler
|  auth/      Login, Sessions, Rate Limiting
|  config/    .env Loader
|  web-v4/    Statisches Frontend
+---------------------------+
       |
       v
+---------------------------+
|  MySQL 8.0  (utf8mb4)     |
+---------------------------+
```

---

## Tech-Stack

| Komponente       | Technologie                          |
|------------------|--------------------------------------|
| Backend          | Go stdlib `net/http`                 |
| Datenbank        | MySQL 8.0, InnoDB, utf8mb4           |
| Queries          | `database/sql`, raw SQL (kein ORM)   |
| Passwort-Hash    | PBKDF2-SHA256 (120.000 Iterationen)  |
| Sessions         | Server-seitig in MySQL, HttpOnly Cookie |
| Frontend         | Vanilla JS (IIFE-Module), kein Build |
| UI-Framework     | UIkit 3 (lokal, kein CDN)            |
| Markdown         | marked.js (lokal)                    |

---

## Sicherheit

- **Passwort-Hashing:** PBKDF2-SHA256, 120.000 Iterationen, 16 Byte Salt, `crypto/subtle.ConstantTimeCompare`
- **Sessions:** 32 Byte Token, 12h Ablauf, HttpOnly + Secure Cookie, SameSite=Lax
- **Rate Limiting:** 5 Fehlversuche / 5 min → 5 min Sperre (pro IP)
- **Body-Limit:** 2 MB (`http.MaxBytesReader`)
- **Fehlerausgabe:** Interne Fehler nur serverseitig geloggt, Client bekommt generisches 500
- **Mandantentrennung:** `dept_id` in jeder Query
- **Panic-Recovery:** Middleware fängt Runtime-Panics ab

---

## Konfiguration (.env)

| Variable         | Standard        | Beschreibung                                    |
|------------------|-----------------|-------------------------------------------------|
| `DB_HOST`        | `127.0.0.1`     | MySQL-Host                                      |
| `DB_PORT`        | `3306`          | MySQL-Port                                      |
| `DB_USER`        | `root`          | MySQL-Benutzer                                  |
| `DB_PASS`        | *(leer)*        | MySQL-Passwort                                  |
| `DB_NAME`        | `schulungshub`  | Datenbankname                                   |
| `PORT`           | `8080`          | HTTP-Port des Servers                           |
| `SECURE_COOKIES` | `true`          | Secure-Flag (false für lokale Entwicklung)      |
| `SETUP_KEY`      | *(leer)*        | Geheimschlüssel für Department-Setup            |

---

## Lokal starten

```bash
mysql -u root < db/schema.sql
mysql -u root schulungshub < db/seed.sql
# .env anlegen (siehe Konfiguration), SECURE_COOKIES=false
go run .
# http://localhost:8080
```

---

## Lizenz

Proprietär – Alle Rechte vorbehalten.
