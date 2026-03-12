-- SchulungsHub Server – Demo Seed Data
-- Generiert aus SQLite data.db

USE schulungshub;

-- Demo-Abteilung
INSERT INTO departments (id, name, slug, features) VALUES (1, 'Siebdruck', 'siebdruck', '{"feature_evaluations": true, "feature_exams": true, "feature_trainee_profiles": true, "feature_attendance": true, "feature_content_edit": true}');

-- Meta
INSERT INTO meta (dept_id, `key`, value) VALUES (1, 'schema_version', '3');
INSERT INTO meta (dept_id, `key`, value) VALUES (1, 'app_name', 'SchulungsHub');
INSERT INTO meta (dept_id, `key`, value) VALUES (1, 'updated_at', '2026-03-10 06:41:02');

-- Users
INSERT INTO users (id, dept_id, username, display_name, initials, role, active, password_hash, rfid_hash, created_at, created_by, must_change_password, theme, age, language_level, has_training, measure_start, motorik_level, birthdate) VALUES (1, 1, 'admin', 'Admin', 'AD', 'admin', 1, 'pbkdf2_sha256$120000$27b99916003a9b409e90072006b8425a$c23b6dca0201c738038bdb6d4bbee56d387a3b7f8e688076faa6204642ad788e', NULL, '2026-03-06 11:18:10', NULL, 0, NULL, NULL, 3, 0, NULL, 2, NULL);
INSERT INTO users (id, dept_id, username, display_name, initials, role, active, password_hash, rfid_hash, created_at, created_by, must_change_password, theme, age, language_level, has_training, measure_start, motorik_level, birthdate) VALUES (2, 1, 'trainer', 'Max Trainer', 'MT', 'trainer', 1, 'pbkdf2_sha256$120000$27b99916003a9b409e90072006b8425a$c23b6dca0201c738038bdb6d4bbee56d387a3b7f8e688076faa6204642ad788e', NULL, '2026-03-06 11:18:10', 1, 0, NULL, NULL, 3, 0, NULL, 2, NULL);
INSERT INTO users (id, dept_id, username, display_name, initials, role, active, password_hash, rfid_hash, created_at, created_by, must_change_password, theme, age, language_level, has_training, measure_start, motorik_level, birthdate) VALUES (3, 1, 'schueler-a', 'Anna Beispiel', 'AB', 'trainee', 1, 'pbkdf2_sha256$120000$27b99916003a9b409e90072006b8425a$c23b6dca0201c738038bdb6d4bbee56d387a3b7f8e688076faa6204642ad788e', NULL, '2026-03-06 11:18:10', 2, 0, NULL, 25, 3, 1, '2026-03-02 00:00:00', 1, NULL);

-- Machines
INSERT INTO machines (id, dept_id, label, position) VALUES ('aufrichter', 1, 'Aufrichter', 0);
INSERT INTO machines (id, dept_id, label, position) VALUES ('auftragskarte', 1, 'Auftragskarte', 1);
INSERT INTO machines (id, dept_id, label, position) VALUES ('bandanlage', 1, 'Bandanlage', 3);
INSERT INTO machines (id, dept_id, label, position) VALUES ('benutzungsanlage', 1, 'Benutzungsanlage', 4);
INSERT INTO machines (id, dept_id, label, position) VALUES ('decosystem', 1, 'Decosystem', 5);
INSERT INTO machines (id, dept_id, label, position) VALUES ('einrichten', 1, 'Einrichten', 6);
INSERT INTO machines (id, dept_id, label, position) VALUES ('k15', 1, 'K15', 7);
INSERT INTO machines (id, dept_id, label, position) VALUES ('karton-packautomat', 1, 'Karton-Packautomat', 8);
INSERT INTO machines (id, dept_id, label, position) VALUES ('produktionsablauf', 1, 'Produktionsablauf', 9);
INSERT INTO machines (id, dept_id, label, position) VALUES ('siebvorbereitung', 1, 'Siebvorbereitung', 10);
INSERT INTO machines (id, dept_id, label, position) VALUES ('umreifer', 1, 'Umreifer', 11);
INSERT INTO machines (id, dept_id, label, position) VALUES ('zm400', 1, 'ZM400 Etikettendrucker', 12);
INSERT INTO machines (id, dept_id, label, position) VALUES ('mes', 1, 'MES-System', 13);

-- Content Sections
INSERT INTO content_sections (id, dept_id, title, position, content_md, parent_id, updated_at) VALUES ('intro', 1, 'Willkommen', 1, '# Willkommen zum SchulungsHub

Dies ist eine Demo-Installation. Inhalte können im Admin-Modus bearbeitet werden.', NULL, '2026-03-06 11:18:10');
INSERT INTO content_sections (id, dept_id, title, position, content_md, parent_id, updated_at) VALUES ('sicherheit-maschine', 1, 'Maschinensicherheit', 1, '> [!WARNING]
> Maschine nie ohne Einweisung bedienen.

- Schutztüren geschlossen halten
- Not-Aus-Schalter kennen', 'sicherheit', '2026-03-06 11:18:10');
INSERT INTO content_sections (id, dept_id, title, position, content_md, parent_id, updated_at) VALUES ('test-eintrag', 1, 'testeintrag_1.1.0', 1, NULL, 'test', '2026-03-06 11:23:02');
INSERT INTO content_sections (id, dept_id, title, position, content_md, parent_id, updated_at) VALUES ('testeintrag-3', 1, 'testeintrag_3', 1, NULL, 'testeintrag-2', '2026-03-06 11:23:35');
INSERT INTO content_sections (id, dept_id, title, position, content_md, parent_id, updated_at) VALUES ('testeintrag-2-0', 1, 'testeintrag_1.1.1', 1, NULL, 'test-eintrag', '2026-03-06 11:26:59');
INSERT INTO content_sections (id, dept_id, title, position, content_md, parent_id, updated_at) VALUES ('sicherheit', 1, 'Sicherheitshinweise', 2, '[pdf:Dokumentname](../dokumente/atlet.pdf)## Allgemeine Sicherheit

- Schutzbrille tragen
- Handschuhe bei Chemikalien
- Notausgänge kennen', NULL, '2026-03-09 06:09:28');
INSERT INTO content_sections (id, dept_id, title, position, content_md, parent_id, updated_at) VALUES ('testeintrag-2', 1, 'testeintrag_1.1.2', 2, NULL, 'test-eintrag', '2026-03-06 11:23:23');
INSERT INTO content_sections (id, dept_id, title, position, content_md, parent_id, updated_at) VALUES ('test', 1, 'testeintrag_1', 3, NULL, NULL, '2026-03-06 11:22:44');
INSERT INTO content_sections (id, dept_id, title, position, content_md, parent_id, updated_at) VALUES ('it-standalone', 1, 'IT-Standalone', 4, 'Das SchulungsHub ist eine rein clientseitige Webanwendung ohne Server-Komponente.
Es besteht aus statischen Dateien (HTML, CSS, JavaScript), die direkt vom NAS-Share
im Browser geöffnet werden. Es entsteht kein IT-Aufwand.

## Architektur

- Typ: Statische Webanwendung (Single-Page)
- Server: Keiner – läuft als file:// direkt vom NAS
- Datenbank: SQLite als einzelne .db-Datei (~50 KB) auf NAS
- DB-Engine: sql.js (WebAssembly im Browser, keine Installation)
- Netzwerk: Kein Netzwerk-Traffic – alles lokal
- Internet: Nicht erforderlich
- Gesamtgröße: < 5 MB

## Anforderungen an die Infrastruktur

Benötigt:
- Ein Ordner auf dem bestehenden NAS-Share (Lese-/Schreibzugriff für Anwender)
- Edge oder Chrome auf den ThinClients (bereits vorhanden)

Nicht benötigt:
- Kein Webserver (kein IIS, kein Apache, kein nginx)
- Kein Datenbank-Server (kein SQL Server, kein MySQL)
- Keine Installation auf Clients
- Keine Admin-Rechte auf Clients
- Keine Firewall-Regeln oder Portfreigaben
- Keine DNS-Einträge oder Zertifikate
- Kein Internet / keine externe Verbindung

## Sicherheit

- Netzwerk: Kein Traffic – keine Angriffsfläche
- Passwörter: PBKDF2-SHA256 gehasht (Web Crypto API, Standard)
- Externe Abhängigkeiten: Keine – alle Bibliotheken lokal eingebettet
- Daten: Bleiben auf dem NAS, verlassen nie das Netzwerk
- Code-Ausführung: Nur im Browser-Sandbox (kein Node.js, kein Skript)

## Wartung und Betrieb

- Updates: Dateien auf NAS ersetzen – kein Rollout nötig
- Backup: Optional – NAS-Ordner ins bestehende Backup aufnehmen
- Monitoring: Nicht erforderlich (kein Service, kein Prozess)
- Logs: Keine (kein Server = keine Server-Logs)
- Benutzerverwaltung: In der App selbst (Admin-Rolle)

## Datenhaltung

- Alle Daten liegen in einer einzigen SQLite-Datei (data.db) auf dem NAS
- Der Browser liest/schreibt diese Datei über die File System Access API
- Kein separater Datenbank-Prozess – die DB ist einfach eine Datei
- Bei Browser-Neustart: einmalige Bestätigung ("Zugriff erlauben") für die Datei
', NULL, '2026-03-06 11:38:42');
INSERT INTO content_sections (id, dept_id, title, position, content_md, parent_id, updated_at) VALUES ('it-server', 1, 'IT-Server', 5, 'Erweiterung des SchulungsHub um einen minimalen Webserver, der die Einschränkungen
des file://-Protokolls beseitigt. Die Anwendung läuft weiterhin vollständig im
Browser – der Server liefert nur Dateien aus und speichert die SQLite-Datenbank.

## Vergleich file:// vs. Server

file:// (aktuell):
- NAS-Ordner nötig
- Browser-Erlaubnis-Dialog bei jedem Neustart
- Mehrere Nutzer gleichzeitig problematisch (Dateisperren)
- Links nicht teilbar
- Nicht mobil nutzbar
- Kein IT-Aufwand

Server (Upgrade):
- Kein NAS-Ordner nötig
- Kein Erlaubnis-Dialog
- Mehrere Nutzer gleichzeitig kein Problem
- Links teilbar (http://schulungshub/...)
- Mobil / Tablet im WLAN nutzbar
- Minimaler einmaliger IT-Aufwand

## Architektur

- Typ: Statische Webanwendung + minimale API
- Webserver: Vorhandener Webserver (IIS, Apache, nginx)
- API-Backend: Kleines Skript (PHP, Python CGI, o.ä.) für DB-Zugriff
- Datenbank: SQLite – eine einzelne Datei, kein DB-Server
- Netzwerk: Nur lokales Netz (LAN/WLAN), kein Internet nötig
- Gesamtgröße: < 5 MB

Der Webserver macht nur zwei Dinge:
1. Statische Dateien ausliefern (HTML, CSS, JS) – Standardfunktion
2. Ein kleines API-Skript für Datenbank lesen/schreiben (2 Endpunkte)

## Anforderungen an die Infrastruktur

Benötigt:
- Vorhandener Webserver (IIS, Apache oder nginx – was bereits im Einsatz ist)
- Ein Verzeichnis auf dem Webserver für die App-Dateien
- Edge oder Chrome auf den ThinClients (bereits vorhanden)

Nicht benötigt:
- Kein zusätzlicher Webserver – nutzt den vorhandenen
- Kein Datenbank-Server (kein SQL Server, kein MySQL)
- Keine Installation auf Clients
- Keine Admin-Rechte auf Clients
- Kein Internet / keine externe Verbindung
- Keine Zertifikate (nur LAN, kein HTTPS nötig)
- Kein Domänen-Join oder AD-Integration

## Einmalige Einrichtung (IT)

Variante A – IIS (Windows Server):
1. Neues Verzeichnis unter inetpub anlegen (z.B. C:\inetpub\schulungshub)
2. App-Dateien hineinkopieren
3. Neue Website oder virtuelles Verzeichnis im IIS-Manager anlegen
4. Fertig – IIS liefert die statischen Dateien aus

Variante B – Apache:
1. Verzeichnis anlegen (z.B. /var/www/schulungshub)
2. App-Dateien hineinkopieren
3. VirtualHost oder Alias in Apache-Konfig eintragen
4. service apache2 reload

Variante C – nginx:
1. Verzeichnis anlegen (z.B. /var/www/schulungshub)
2. App-Dateien hineinkopieren
3. Server-Block in nginx-Konfig eintragen
4. nginx -s reload

Geschätzter Zeitaufwand: 10–20 Minuten, einmalig.
Nutzt den vorhandenen Webserver – keine neue Software nötig.

## Sicherheit

- Netzwerk: Nur LAN – nicht aus dem Internet erreichbar
- Angriffsfläche: Vorhandener Webserver, 2 API-Endpunkte
- Passwörter: PBKDF2-SHA256 gehasht (Web Crypto API, Standard)
- Externe Abhängigkeiten: Keine CDNs, kein Internet, alles lokal
- Daten: Bleiben auf dem Server, verlassen nie das LAN
- Code-Ausführung Client: Nur im Browser-Sandbox
- Code-Ausführung Server: Nur statische Dateien + SQLite lesen/schreiben

## Wartung und Betrieb

- Updates: Dateien im Webserver-Verzeichnis ersetzen
- Backup: Eine Datei (data.db) ins bestehende Backup
- Monitoring: Optional – prüfen ob Port erreichbar
- Logs: Minimal (Zugriffs-Log auf stdout)
- Benutzerverwaltung: In der App selbst (Admin-Rolle)

## Was sich für Anwender verbessert

- Kein "Zugriff erlauben"-Dialog mehr bei jedem Browser-Start
- Links auf Artikel teilbar (http://schulungshub/#sec-kartusche)
- Mehrere Trainer/Trainees können gleichzeitig arbeiten
- Zugriff von Tablets/Smartphones im WLAN möglich
- Stabilere Datenhaltung (kein Dateisperren-Problem auf NAS)', NULL, '2026-03-06 11:39:14');
INSERT INTO content_sections (id, dept_id, title, position, content_md, parent_id, updated_at) VALUES ('struktur', 1, 'Struktur', 6, 'SchulungsHub

Serverlose Schulungsplattform fuer die Einarbeitung in der Siebdruck-Produktion. Laeuft komplett im Browser – kein Server, keine Installation, kein Internet noetig.
Quickstart

    Ordner web-v4/ auf ein NAS-Share oder einen Webserver kopieren
    sample.db in data.db umbenennen (oder eigene DB mit build-db.js erstellen)
    index.html im Browser oeffnen
    Login: admin / changeme

Architektur

Browser (Edge/Chrome)
  |
  |  file:// oder http://
  |
  v
+---------------------------------------------------+
|  index.html                                        |
|  +-----------------------------------------------+ |
|  |  UIkit 3 (CSS + JS)     vendor/uikit.min.*    | |
|  |  marked.js               vendor/marked.min.js | |
|  |  sql.js (WASM SQLite)    vendor/sql-wasm.*    | |
|  +-----------------------------------------------+ |
|                                                     |
|  db-engine.js          Persistence Layer            |
|    - sql.js in-memory DB                            |
|    - File System Access API (NAS-Modus)             |
|    - localStorage Fallback                          |
|                                                     |
|  js/app.js             Orchestrierung               |
|    +-- js/state.js     Globaler State, DB-Queries   |
|    +-- js/auth.js      Login, Session, Passwort     |
|    +-- js/crypto.js    PBKDF2-SHA256 Hashing        |
|    +-- js/render.js    Seitenaufbau, Events          |
|    +-- js/sidebar.js   Navigation, TOC              |
|    +-- js/editor.js    Markdown-Editor, CRUD        |
|    +-- js/markdown.js  Markdown + Custom Blocks     |
|    +-- js/scoring.js   Bewertungs-UI                |
|    +-- js/eval.js      Fortschritt, Prognose        |
|    +-- js/exam.js      Pruefungsmodus               |
|    +-- js/search.js    Volltextsuche                |
|    +-- js/admin.js     Benutzerverwaltung           |
|    +-- js/export.js    Backup, Import, DB-Export    |
|    +-- js/prefs.js     Theme, Einstellungen         |
|    +-- js/trainee-profile.js  Trainee-Detailansicht |
|    +-- js/utils.js     Hilfsfunktionen              |
|                                                     |
+---------------------------------------------------+
        |
        v
  +------------+
  |  data.db   |  SQLite-Datei auf NAS oder lokal
  +------------+

Datenfluss

Erststart:
  data-seed.js (Base64) --> sql.js (RAM) --> localStorage
                                         --> data.db (NAS, optional)

Normaler Start:
  data.db (NAS) --> sql.js (RAM) --> Browser zeigt Inhalte
       ^                    |
       |                    v
       +--- persistDb() ---+  (Aenderungen zurueckschreiben)

Fallback (kein NAS):
  localStorage --> sql.js (RAM) --> localStorage

Datenbankschema

users              Benutzer (Admin, Trainer, Trainee)
machines           Maschinen / Prozessgruppen
content_sections   Lerninhalte (Baumstruktur, Markdown)
learning_goals     Lernziele pro Phase und Maschine
evaluations        Bewertungen (append-only, 0-100)
trainee_meta       Feedback, Fazit, naechste Schritte
exam_questions     Pruefungsfragen mit Optionen
exam_results       Pruefungsergebnisse

Projektstruktur

schulungshub/
|
+-- web-v4/                    Hauptanwendung
|   +-- index.html             Startseite (nach Login)
|   +-- login.html             Login-Seite
|   +-- login.js               Login-Logik
|   +-- style.css              Alle Styles
|   +-- db-engine.js           Persistence Layer
|   +-- sample.db              Demo-Datenbank
|   +-- data-seed.sample.js    Demo-Seed (Base64)
|   |
|   +-- js/                    Anwendungsmodule (17 Dateien)
|   |   +-- app.js             Einstiegspunkt
|   |   +-- state.js           State Management
|   |   +-- auth.js            Authentifizierung
|   |   +-- render.js          Seitenrendering
|   |   +-- editor.js          Content-Editor
|   |   +-- ...                (siehe Architektur oben)
|   |
|   +-- vendor/                Externe Bibliotheken (lokal)
|   |   +-- uikit.min.*       UIkit 3 Framework
|   |   +-- marked.min.js     Markdown Parser
|   |   +-- sql-wasm.*        SQLite im Browser (WASM)
|   |   +-- fonts/            Inter + JetBrains Mono
|   |
|   +-- it/                    IT-Dokumentation
|   |   +-- IT-Anforderungen.md          NAS-Variante
|   |   +-- IT-Anforderungen-Server.md   Server-Variante
|   |
|   +-- build-db.js            Node: data.js -> data.db
|   +-- build-seed.js          Node: data.db -> data-seed.js
|   +-- build-wasm-seed.js     Node: sql-wasm.wasm -> wasm-seed.js
|
+-- app/                       Server-Variante (optional)
|   +-- server.py              Minimaler Python-Server
|   +-- schema.sql             DB-Schema
|
+-- .gitignore
+-- README.md

Script-Ladereihenfolge

Die Module muessen in exakt dieser Reihenfolge geladen werden:

 1. wasm-seed.js           WASM-Binary als Base64
 2. vendor/sql-wasm.js     sql.js Library
 3. data-seed.js           Datenbank als Base64
 4. db-engine.js           Persistence Layer
 5. js/utils.js            Hilfsfunktionen
 6. js/crypto.js           Passwort-Hashing
 7. js/markdown.js         Markdown Rendering
 8. js/state.js            State Management
 9. js/eval.js             Fortschrittsberechnung
10. js/prefs.js            Einstellungen
11. js/auth.js             Login/Session
12. js/search.js           Suche
13. js/sidebar.js          Navigation
14. js/editor.js           Content-Editor
15. js/scoring.js          Bewertungs-UI
16. js/render.js           Seitenaufbau
17. js/exam.js             Pruefungen
18. js/trainee-profile.js  Trainee-Profil
19. js/admin.js            Benutzerverwaltung
20. js/export.js           Backup/Import
21. js/app.js              Orchestrierung (init)

Sicherheit

    Passwoerter: PBKDF2-SHA256 mit 100.000 Iterationen (Web Crypto API)
    Kein Netzwerk-Traffic im NAS-Modus
    Keine externen Abhaengigkeiten, kein CDN, kein Internet
    Alle Daten bleiben lokal auf dem NAS
', NULL, '2026-03-06 11:43:51');

-- Learning Goals
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-001', 1, 'aufrichter', 'P1', 'Allgemeine Einweisung', 1.0, 0);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('P1_produktionsablauf_1773052434193', 1, 'produktionsablauf', 'P1', 'Warnhinweise', 1.0, 0);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-002', 1, 'aufrichter', 'P1', 'Störungsbeseitigung', 1.0, 1);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-003', 1, 'auftragskarte', 'P1', 'Siebnummern und Index prüfen', 1.0, 3);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-004', 1, 'bandanlage', 'P1', 'Bunker', 1.0, 4);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-005', 1, 'decosystem', 'P1', 'Ausschleusen Gut / Schlecht', 1.0, 5);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-006', 1, 'karton-packautomat', 'P1', 'Funktion: Leer Fahren', 1.0, 6);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-007', 1, 'karton-packautomat', 'P1', 'Funktion: Reset & Allgemein Reset', 1.0, 7);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-008', 1, 'karton-packautomat', 'P1', 'Klebeband wechseln + M2 und M11', 1.0, 8);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-009', 1, 'karton-packautomat', 'P1', 'Störung: Karton bleibt stecken', 1.0, 9);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-010', 1, 'karton-packautomat', 'P1', 'Störung: Karton kein Klebeband', 1.0, 10);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-011', 1, 'karton-packautomat', 'P1', 'Störung: Karton wird nicht gezogen', 1.0, 11);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-012', 1, 'karton-packautomat', 'P1', 'Störung: Stapelt nicht', 1.0, 12);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-013', 1, 'produktionsablauf', 'P1', 'Kontrolle nachdem ohne Farbe gelaufen ist', 1.0, 13);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-014', 1, 'produktionsablauf', 'P1', 'Sauberkeit am Arbeitsplatz', 1.0, 14);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-015', 1, 'produktionsablauf', 'P1', 'Vermeidung von Chaos', 1.0, 15);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-016', 1, 'siebvorbereitung', 'P1', 'Defekte Stellen abdichten', 1.0, 16);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-017', 1, 'siebvorbereitung', 'P1', 'Fehler eigenständig erkennen', 1.0, 17);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-018', 1, 'siebvorbereitung', 'P1', 'Gewebe auf Beschädigung prüfen', 1.0, 18);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-019', 1, 'siebvorbereitung', 'P1', 'Klebeband prüfen, lose stellen beseitigen', 1.0, 19);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-020', 1, 'siebvorbereitung', 'P1', 'Siebe ab-kleben', 1.0, 20);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-021', 1, 'siebvorbereitung', 'P1', 'Siebschablone belichten', 1.0, 21);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-022', 1, 'zm400', 'P1', 'Etiketten wechseln', 1.0, 22);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-023', 1, 'zm400', 'P1', 'Farbband Wechseln', 1.0, 23);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-024', 1, 'zm400', 'P1', 'Störung Quitieren', 1.0, 24);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-025', 1, 'auftragskarte', 'P2', 'An- Abmelden und Etiketten prüfen', 1.0, 25);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-026', 1, 'auftragskarte', 'P2', 'Andruck überprüfen', 1.0, 26);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-027', 1, 'auftragskarte', 'P2', 'Fehler finden und Richtig handeln', 1.0, 27);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-028', 1, 'auftragskarte', 'P2', 'Freigabe einholen', 1.0, 28);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-029', 1, 'auftragskarte', 'P2', 'Kartuschen-Art prüfen', 1.0, 29);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-030', 1, 'auftragskarte', 'P2', 'Proof mit Filmkopien vergleichen', 1.0, 30);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-031', 1, 'auftragskarte', 'P2', 'Teilfertig am BDE Terminal holen', 1.0, 31);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-032', 1, 'bandanlage', 'P2', 'Artikelwechsel', 1.0, 32);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-033', 1, 'bandanlage', 'P2', 'Wahlschalter richtig einstellen', 1.0, 33);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-034', 1, 'benutzungsanlage', 'P2', 'Anlage einschalten', 1.0, 34);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-035', 1, 'benutzungsanlage', 'P2', 'Betrieb der Anlage', 1.0, 35);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-036', 1, 'benutzungsanlage', 'P2', 'Verhalten im Störungsfall', 1.0, 36);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-037', 1, 'decosystem', 'P2', 'Druckbild-Kontrolle in Betrieb nehmen', 1.0, 37);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-038', 1, 'decosystem', 'P2', 'Kontrollbereiche erstellen', 1.0, 38);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-039', 1, 'decosystem', 'P2', 'Parameter (Optional)', 1.0, 39);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-040', 1, 'einrichten', 'P2', 'Druckanfang und Druckende begradigen (z.B. Vollfläche)', 1.0, 40);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-041', 1, 'einrichten', 'P2', 'Farbhaftung Prüfen', 1.0, 41);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-042', 1, 'einrichten', 'P2', 'Farbton nach PMS, HKS, RAL prüfen', 1.0, 42);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-043', 1, 'einrichten', 'P2', 'Max. 2 Karton Ausschuss', 1.0, 43);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-044', 1, 'einrichten', 'P2', 'Rakel-Gummi austauschen', 1.0, 44);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-045', 1, 'einrichten', 'P2', 'Schlechtes Rakel-Gummi erkennen', 1.0, 45);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-046', 1, 'einrichten', 'P2', 'Standard-Einbaumaß', 1.0, 46);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-047', 1, 'einrichten', 'P2', 'Überlauf begradigen (RakelRotation)', 1.0, 47);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-048', 1, 'einrichten', 'P2', 'Überlauf verkleinern & Vergrößern', 1.0, 48);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-049', 1, 'einrichten', 'P2', 'Zusammenhang zwischen x-, x+ und der Größe des Überlaufs', 1.0, 49);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-050', 1, 'k15', 'P2', 'Farbhaftungsprobleme beheben und prüfen', 1.0, 50);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-051', 1, 'k15', 'P2', 'Farbpumpe Ein / Ausbauen und nutzen', 1.0, 51);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-052', 1, 'k15', 'P2', 'Inbetriebnahme – Referenzpunkte setzen – Deco Programm laden', 1.0, 52);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-053', 1, 'k15', 'P2', 'Markenleser einstellen und verwenden', 1.0, 53);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-054', 1, 'k15', 'P2', 'Markenleser Fehler erkennen und Handeln', 1.0, 54);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-055', 1, 'k15', 'P2', 'Nutzung der Benutzeroberfläche', 1.0, 55);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-056', 1, 'k15', 'P2', 'Gelbe, Rote und Orange Meldungen', 1.0, 56);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-057', 1, 'k15', 'P2', 'Schutzfunktionen und Funktionsweise / Türen / Gefahrenbereiche', 1.0, 57);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-058', 1, 'k15', 'P2', 'Sicherheitsunterweisung', 1.0, 58);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-059', 1, 'k15', 'P2', 'Siebdruckwerke manipulieren: X, YL, YR, Z, Siebabsprung', 1.0, 59);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-060', 1, 'k15', 'P2', 'Störung: Artikel nicht abgedornt', 1.0, 60);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-061', 1, 'k15', 'P2', 'Störung: Artikel nicht abgenommen', 1.0, 61);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-062', 1, 'k15', 'P2', 'Störung: Artikel nicht aufgedornt', 1.0, 62);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-063', 1, 'k15', 'P2', 'Störung: Artikel Zuführung kontrollieren', 1.0, 63);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-064', 1, 'k15', 'P2', 'Störung: Aufdornzylinder blockiert', 1.0, 64);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-065', 1, 'k15', 'P2', 'Störung: Brenner 1', 1.0, 65);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-066', 1, 'k15', 'P2', 'Störung: Momentgrenze überschritten, Extremer Nothalt', 1.0, 66);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-067', 1, 'k15', 'P2', 'Störung: Reduzierter Takt', 1.0, 67);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-068', 1, 'k15', 'P2', 'Trockenfahren', 1.0, 68);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-069', 1, 'k15', 'P2', 'UV-Trocknung Grundlagen', 1.0, 69);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-070', 1, 'k15', 'P2', 'Vorbehandlung: Brenner einschalten + Wassertest', 1.0, 70);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-071', 1, 'karton-packautomat', 'P2', 'Einschalten', 1.0, 71);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-072', 1, 'karton-packautomat', 'P2', 'Funktion: Sonderkartuschen', 1.0, 72);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-073', 1, 'produktionsablauf', 'P2', 'Erster Karton Kontrolle', 1.0, 73);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-074', 1, 'produktionsablauf', 'P2', 'Kontrolle nach Siebriss', 1.0, 74);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-075', 1, 'produktionsablauf', 'P2', 'Produktionsbericht schreiben', 1.0, 75);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-076', 1, 'produktionsablauf', 'P2', 'Regelmäßige Kontrollen, Farbe, Farbhaftung, Undichtigkeiten', 1.0, 76);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-077', 1, 'produktionsablauf', 'P2', 'Störungsdiagnose (welche Maschine verursacht die Störung)', 1.0, 77);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-078', 1, 'produktionsablauf', 'P2', 'Vorausschauendes Arbeiten', 1.0, 78);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-079', 1, 'siebvorbereitung', 'P2', 'Druckbild auf Vollständigkeit prüfen', 1.0, 79);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-080', 1, 'umreifer', 'P2', 'Einschalten und Grundstellung fahren', 1.0, 80);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-081', 1, 'umreifer', 'P2', 'Einstellen Druchlauf / Umreifung', 1.0, 81);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-082', 1, 'umreifer', 'P2', 'Fehler quittieren', 1.0, 82);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-083', 1, 'umreifer', 'P2', 'Störung: Einschub-Zylinder Endlage nicht erreicht', 1.0, 83);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-084', 1, 'umreifer', 'P2', 'Störung: Kein Gebinde auf Abschieber', 1.0, 84);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-085', 1, 'produktionsablauf', 'P2', 'Farben mischen', 1.0, 85);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-086', 1, 'produktionsablauf', 'P2', 'Grundfarbe abfüllen', 1.0, 86);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-087', 1, 'benutzungsanlage', 'P3', 'Reinigen (Optional)', 1.0, 87);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-088', 1, 'benutzungsanlage', 'P3', 'Temperaturen (Optional)', 1.0, 88);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-089', 1, 'einrichten', 'P3', 'Farbton gerastertes Bild einstellen', 1.0, 89);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-090', 1, 'einrichten', 'P3', 'Rakel-Position und Farbauftrag', 1.0, 90);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-091', 1, 'einrichten', 'P3', 'Rakel-Position, RakelRotation, Rakel-Endposition Einstellen und verstehen', 1.0, 91);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-092', 1, 'einrichten', 'P3', 'Siebabsprung Zusammenhang Rakel-Endposition verstehen', 1.0, 92);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-093', 1, 'einrichten', 'P3', 'Taktzahl und Farbton', 1.0, 93);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-094', 1, 'produktionsablauf', 'P3', 'Intern & Extern Umrüstvorgabe', 1.0, 94);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-095', 1, 'produktionsablauf', 'P3', 'Not-Aus Störung M1 + M8', 1.0, 95);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-096', 1, 'produktionsablauf', 'P3', 'Not-Aus Störung M2, M3, M4, M5, M7, M11', 1.0, 96);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-097', 1, 'umreifer', 'P3', 'Störung: Umreifungsband aufgebraucht', 1.0, 97);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-098', 1, 'aufrichter', 'P4', 'Kammern (Optional)', 1.0, 98);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-099', 1, 'aufrichter', 'P4', 'Drähte im Inneren (Optional)', 1.0, 99);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-100', 1, 'umreifer', 'P4', 'Band nicht richtig verschweißt (Optional)', 1.0, 100);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-101', 1, 'umreifer', 'P4', 'Störung: Rahmen nicht geschlossen (Optional)', 1.0, 101);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-102', 1, 'umreifer', 'P4', 'Störung: Umreifungsband nicht eingeschossen', 1.0, 102);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-103', 1, 'umreifer', 'P4', 'Umreifer zieht Band immer wieder nicht (Optional)', 1.0, 103);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-104', 1, 'zm400', 'P4', 'Druckbild nicht schön (Optional)', 1.0, 104);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-105', 1, 'zm400', 'P4', 'Ein- / Ausschalten', 1.0, 105);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-106', 1, 'zm400', 'P4', 'Etiketten werden nicht gestempelt (Optional)', 1.0, 106);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-107', 1, 'zm400', 'P4', 'Sensor-Position (Optional)', 1.0, 107);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-108', 1, 'mes', 'Mes', 'Artikelhistorie', 1.0, 108);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-109', 1, 'mes', 'Mes', 'Laufkarte öffnen', 1.0, 109);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-110', 1, 'mes', 'Mes', 'An- / Abmelden', 1.0, 110);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-111', 1, 'mes', 'Mes', 'Start / Stop', 1.0, 111);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-112', 1, 'mes', 'Mes', 'Unterbrechungen Buchen', 1.0, 112);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-113', 1, 'mes', 'Mes', 'Menge Melden', 1.0, 113);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-114', 1, 'mes', 'Mes', 'Softproof', 1.0, 114);
INSERT INTO learning_goals (id, dept_id, machine_id, phase, title, weight, position) VALUES ('lg-115', 1, 'mes', 'Mes', 'Ausschuss Buchen', 1.0, 115);

-- Evaluations
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (1, 1, 3, 'lg-003', 100, 0.0, NULL, '', 1, '2026-03-06 11:35:34');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (2, 1, 3, 'lg-004', 100, 0.0, NULL, '', 1, '2026-03-06 11:35:36');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (3, 1, 3, 'lg-005', 100, 0.0, NULL, '', 1, '2026-03-06 11:35:38');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (4, 1, 3, 'lg-006', 100, 0.0, NULL, '', 2, '2026-03-09 08:32:23');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (5, 1, 3, 'lg-007', 100, 0.0, NULL, '', 2, '2026-03-09 08:32:24');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (6, 1, 3, 'lg-008', 100, 0.0, NULL, '', 2, '2026-03-09 08:32:25');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (7, 1, 3, 'lg-009', 100, 0.0, NULL, '', 2, '2026-03-09 08:32:25');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (8, 1, 3, 'lg-010', 100, 0.0, NULL, '', 2, '2026-03-09 08:32:26');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (9, 1, 3, 'lg-011', 100, 0.0, NULL, '', 2, '2026-03-09 08:32:26');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (10, 1, 3, 'lg-012', 100, 0.0, NULL, '', 2, '2026-03-09 08:32:28');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (11, 1, 3, 'lg-013', 50, 0.0, NULL, '', 1, '2026-03-09 10:38:24');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (12, 1, 3, 'P1_produktionsablauf_1773052434193', 50, 0.0, NULL, '', 1, '2026-03-09 10:38:24');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (13, 1, 3, 'lg-014', 50, 0.0, NULL, '', 1, '2026-03-09 10:38:25');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (14, 1, 3, 'lg-015', 50, 0.0, NULL, '', 1, '2026-03-09 10:38:25');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (15, 1, 3, 'P1_produktionsablauf_1773052434193', 100, 0.0, NULL, '', 1, '2026-03-09 10:38:36');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (16, 1, 3, 'lg-016', 100, 0.0, NULL, '', 1, '2026-03-09 10:39:02');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (17, 1, 3, 'lg-017', 100, 0.0, NULL, '', 1, '2026-03-09 10:39:02');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (18, 1, 3, 'lg-018', 100, 0.0, NULL, '', 1, '2026-03-09 10:39:03');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (19, 1, 3, 'lg-019', 0, 0.0, NULL, '', 1, '2026-03-09 10:52:31');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (20, 1, 3, 'lg-019', 0, 0.0, NULL, '', 1, '2026-03-09 10:52:35');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (21, 1, 3, 'lg-019', 25, 0.0, NULL, '', 1, '2026-03-09 10:52:36');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (22, 1, 3, 'lg-019', 50, 0.0, NULL, '', 1, '2026-03-09 10:52:36');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (23, 1, 3, 'lg-019', 0, 0.0, NULL, '', 1, '2026-03-09 10:52:37');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (24, 1, 3, 'lg-019', 100, 0.0, NULL, '', 1, '2026-03-09 10:52:41');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (25, 1, 3, 'P1_produktionsablauf_1773052434193', 0, 0.0, NULL, '', 1, '2026-03-09 10:52:56');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (26, 1, 3, 'P1_produktionsablauf_1773052434193', 100, 0.0, NULL, '', 1, '2026-03-09 10:52:59');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (27, 1, 3, 'P1_produktionsablauf_1773052434193', 0, 0.0, NULL, '', 1, '2026-03-09 10:53:00');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (28, 1, 3, 'P1_produktionsablauf_1773052434193', 100, 0.0, NULL, '', 1, '2026-03-09 10:56:54');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (29, 1, 3, 'P1_produktionsablauf_1773052434193', 0, 0.0, NULL, '', 1, '2026-03-09 10:56:56');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (30, 1, 3, 'lg-013', 100, 0.0, NULL, '', 1, '2026-03-09 10:56:57');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (31, 1, 3, 'lg-013', 0, 0.0, NULL, '', 1, '2026-03-09 10:56:58');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (32, 1, 3, 'lg-020', 100, 0.0, NULL, '', 1, '2026-03-09 10:57:43');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (33, 1, 3, 'lg-020', 75, 0.0, NULL, '', 1, '2026-03-09 10:57:44');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (34, 1, 3, 'lg-006', 50, 0.0, NULL, '', 1, '2026-03-09 10:59:03');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (35, 1, 3, 'lg-006', 75, 0.0, NULL, '', 1, '2026-03-09 10:59:04');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (36, 1, 3, 'lg-006', 100, 0.0, NULL, '', 1, '2026-03-09 10:59:04');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (37, 1, 3, 'lg-006', 25, 0.0, NULL, '', 1, '2026-03-09 10:59:05');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (38, 1, 3, 'lg-006', 0, 0.0, NULL, '', 1, '2026-03-09 10:59:06');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (39, 1, 3, 'lg-006', 25, 0.0, NULL, '', 1, '2026-03-09 10:59:07');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (40, 1, 3, 'lg-006', 75, 0.0, NULL, '', 1, '2026-03-09 10:59:07');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (41, 1, 3, 'lg-006', 100, 0.0, NULL, '', 1, '2026-03-09 10:59:07');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (42, 1, 3, 'P1_produktionsablauf_1773052434193', 100, 0.0, NULL, '', 1, '2026-03-09 10:59:10');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (43, 1, 3, 'lg-013', 100, 0.0, NULL, '', 1, '2026-03-09 10:59:12');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (44, 1, 3, 'lg-014', 100, 0.0, NULL, '', 1, '2026-03-09 10:59:13');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (45, 1, 3, 'lg-015', 100, 0.0, NULL, '', 1, '2026-03-09 10:59:13');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (46, 1, 3, 'lg-008', 75, 0.0, NULL, '', 1, '2026-03-09 10:59:46');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (47, 1, 3, 'lg-008', 0, 0.0, NULL, '', 1, '2026-03-09 10:59:48');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (48, 1, 3, 'lg-008', 0, 0.0, NULL, '', 1, '2026-03-09 10:59:49');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (49, 1, 3, 'lg-007', 0, 0.0, NULL, '', 1, '2026-03-09 10:59:50');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (50, 1, 3, 'lg-006', 0, 0.0, NULL, '', 1, '2026-03-09 10:59:52');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (51, 1, 3, 'lg-008', 100, 0.0, NULL, '', 1, '2026-03-09 11:01:33');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (52, 1, 3, 'lg-007', 100, 0.0, NULL, '', 1, '2026-03-09 11:01:34');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (53, 1, 3, 'lg-006', 100, 0.0, NULL, '', 1, '2026-03-09 11:01:35');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (54, 1, 3, 'lg-009', 0, 0.0, NULL, '', 1, '2026-03-09 11:01:37');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (55, 1, 3, 'lg-010', 0, 0.0, NULL, '', 1, '2026-03-09 11:01:38');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (56, 1, 3, 'lg-011', 0, 0.0, NULL, '', 1, '2026-03-09 11:01:39');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (57, 1, 3, 'lg-011', 100, 0.0, NULL, '', 1, '2026-03-09 11:01:40');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (58, 1, 3, 'lg-009', 100, 0.0, NULL, '', 1, '2026-03-09 11:01:42');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (59, 1, 3, 'lg-010', 100, 0.0, NULL, '', 1, '2026-03-09 11:01:42');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (60, 1, 3, 'lg-007', 50, 0.0, NULL, '', 1, '2026-03-09 11:31:11');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (61, 1, 3, 'lg-008', 75, 0.0, NULL, '', 1, '2026-03-09 11:31:11');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (62, 1, 3, 'lg-008', 0, 0.0, NULL, '', 1, '2026-03-09 11:31:12');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (63, 1, 3, 'lg-007', 75, 0.0, NULL, '', 1, '2026-03-09 11:31:12');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (64, 1, 3, 'lg-008', 100, 0.0, NULL, '', 1, '2026-03-09 11:31:27');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (65, 1, 3, 'lg-007', 100, 0.0, NULL, '', 1, '2026-03-09 11:31:28');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (66, 1, 3, 'lg-009', 75, 0.0, NULL, '', 1, '2026-03-09 11:31:29');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (67, 1, 3, 'lg-012', 75, 0.0, NULL, '', 1, '2026-03-09 11:31:29');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (68, 1, 3, 'lg-013', 0, 0.0, NULL, '', 1, '2026-03-09 11:31:31');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (69, 1, 3, 'lg-013', 50, 0.0, NULL, '', 1, '2026-03-09 11:31:32');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (70, 1, 3, 'lg-013', 75, 0.0, NULL, '', 1, '2026-03-09 11:31:32');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (71, 1, 3, 'lg-013', 100, 0.0, NULL, '', 1, '2026-03-09 11:31:33');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (72, 1, 3, 'lg-013', 0, 0.0, NULL, '', 1, '2026-03-09 11:31:36');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (73, 1, 3, 'P1_produktionsablauf_1773052434193', 0, 0.0, NULL, '', 1, '2026-03-09 11:31:37');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (74, 1, 3, 'lg-014', 0, 0.0, NULL, '', 1, '2026-03-09 11:31:38');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (75, 1, 3, 'lg-015', 0, 0.0, NULL, '', 1, '2026-03-09 11:31:38');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (76, 1, 3, 'lg-015', 0, 0.0, NULL, '', 1, '2026-03-09 11:31:40');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (77, 1, 3, 'P1_produktionsablauf_1773052434193', 0, 0.0, NULL, '', 1, '2026-03-09 11:31:41');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (78, 1, 3, 'P1_produktionsablauf_1773052434193', 100, 0.0, NULL, '', 1, '2026-03-09 11:31:42');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (79, 1, 3, 'lg-013', 100, 0.0, NULL, '', 1, '2026-03-09 11:31:43');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (80, 1, 3, 'lg-014', 100, 0.0, NULL, '', 1, '2026-03-09 11:31:43');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (81, 1, 3, 'lg-015', 100, 0.0, NULL, '', 1, '2026-03-09 11:31:44');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (82, 1, 3, 'lg-012', 100, 0.0, NULL, '', 1, '2026-03-09 11:32:08');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (83, 1, 3, 'lg-012', 75, 0.0, NULL, '', 1, '2026-03-09 11:32:10');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (84, 1, 3, 'lg-012', 100, 0.0, NULL, '', 1, '2026-03-09 11:32:11');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (85, 1, 3, 'lg-012', 25, 0.0, NULL, '', 1, '2026-03-09 11:32:53');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (86, 1, 3, 'lg-011', 25, 0.0, NULL, '', 1, '2026-03-09 11:32:53');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (87, 1, 3, 'lg-010', 25, 0.0, NULL, '', 1, '2026-03-09 11:32:54');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (88, 1, 3, 'lg-009', 25, 0.0, NULL, '', 1, '2026-03-09 11:32:54');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (89, 1, 3, 'lg-008', 25, 0.0, NULL, '', 1, '2026-03-09 11:32:55');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (90, 1, 3, 'lg-007', 25, 0.0, NULL, '', 1, '2026-03-09 11:32:55');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (91, 1, 3, 'lg-006', 25, 0.0, NULL, '', 1, '2026-03-09 11:32:56');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (92, 1, 3, 'lg-005', 25, 0.0, NULL, '', 1, '2026-03-09 11:32:58');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (93, 1, 3, 'lg-004', 25, 0.0, NULL, '', 1, '2026-03-09 11:33:00');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (94, 1, 3, 'lg-003', 25, 0.0, NULL, '', 1, '2026-03-09 11:33:02');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (95, 1, 3, 'lg-015', 25, 0.0, NULL, '', 1, '2026-03-09 11:33:04');
INSERT INTO evaluations (id, dept_id, trainee_id, goal_id, score, error_rate, comment, action, evaluated_by, evaluated_at) VALUES (96, 1, 3, 'lg-014', 25, 0.0, NULL, '', 1, '2026-03-09 11:33:05');

-- Trainee Meta

-- Attendance
INSERT INTO attendance (id, dept_id, trainee_id, machine_id, date, hours) VALUES (1, 1, 3, NULL, '2026-03-06', 8.0);
INSERT INTO attendance (id, dept_id, trainee_id, machine_id, date, hours) VALUES (2, 1, 3, NULL, '2026-03-05', 8.0);
INSERT INTO attendance (id, dept_id, trainee_id, machine_id, date, hours) VALUES (3, 1, 3, NULL, '2026-03-04', 8.0);
INSERT INTO attendance (id, dept_id, trainee_id, machine_id, date, hours) VALUES (11, 1, 3, NULL, '2026-03-02', 8.0);
INSERT INTO attendance (id, dept_id, trainee_id, machine_id, date, hours) VALUES (12, 1, 3, NULL, '2026-03-03', 8.0);
INSERT INTO attendance (id, dept_id, trainee_id, machine_id, date, hours) VALUES (17, 1, 3, NULL, '2026-03-09', 8.0);

-- Exam Questions
INSERT INTO exam_questions (id, dept_id, section_id, machine_id, phase, type, question, options, explanation, question_image, difficulty, created_by, created_at) VALUES ('q1', 1, NULL, NULL, 'P1', 'single', 'Was muss vor dem Einschalten der Druckmaschine geprüft werden?', '[{"text":"Ob die Schutztüren geschlossen sind","correct":true},{"text":"Ob das Licht an ist","correct":false},{"text":"Ob die Kaffeemaschine läuft","correct":false},{"text":"Ob das Fenster offen ist","correct":false}]', 'Die Schutztüren müssen immer geschlossen sein bevor die Maschine gestartet wird.', NULL, 1, 1, '2026-03-06 11:26:30');
INSERT INTO exam_questions (id, dept_id, section_id, machine_id, phase, type, question, options, explanation, question_image, difficulty, created_by, created_at) VALUES ('q2', 1, NULL, NULL, 'P1', 'single', 'Wie wird das Druckmaterial korrekt eingelegt?', '[{"text":"Egal wie, Hauptsache es liegt drin","correct":false},{"text":"Bündig an den Anschlag anlegen und fixieren","correct":true},{"text":"Lose auf den Drucktisch legen","correct":false},{"text":"Mit Klebeband befestigen","correct":false}]', 'Das Material muss bündig am Anschlag liegen und fixiert werden für ein sauberes Druckbild.', NULL, 1, 1, '2026-03-06 11:26:30');
INSERT INTO exam_questions (id, dept_id, section_id, machine_id, phase, type, question, options, explanation, question_image, difficulty, created_by, created_at) VALUES ('q3', 1, NULL, NULL, 'P2', 'single', 'Woran erkennt man einen falschen Siebabsprung?', '[{"text":"Das Druckbild ist scharf und gleichmäßig","correct":false},{"text":"Die Farbe verschmiert oder das Bild ist unscharf","correct":true},{"text":"Die Maschine macht ein lautes Geräusch","correct":false},{"text":"Die Rakel bewegt sich schneller","correct":false}]', 'Ein falscher Siebabsprung führt zu unscharfem Druckbild oder Farbverschmierungen.', NULL, 2, 1, '2026-03-06 11:26:30');
INSERT INTO exam_questions (id, dept_id, section_id, machine_id, phase, type, question, options, explanation, question_image, difficulty, created_by, created_at) VALUES ('q4', 1, NULL, NULL, 'P1', 'single', 'Welche Temperatur ist beim Trockner für Standardfarben üblich?', '[{"text":"50-80°C","correct":false},{"text":"100-130°C","correct":false},{"text":"140-160°C","correct":true},{"text":"200-250°C","correct":false}]', 'Standardfarben werden typischerweise bei 140-160°C getrocknet.', NULL, 2, 1, '2026-03-06 11:26:30');
INSERT INTO exam_questions (id, dept_id, section_id, machine_id, phase, type, question, options, explanation, question_image, difficulty, created_by, created_at) VALUES ('q5', 1, NULL, NULL, 'P1', 'single', 'Was ist der Not-Aus-Schalter?', '[{"text":"Ein roter Pilzknopf zum sofortigen Stoppen der Maschine","correct":true},{"text":"Der Ein/Aus-Schalter am Hauptpanel","correct":false},{"text":"Die Pause-Taste am Display","correct":false},{"text":"Der Stecker an der Wand","correct":false}]', 'Der Not-Aus ist immer ein roter Pilzknopf der die Maschine sofort stoppt.', NULL, 1, 1, '2026-03-06 11:26:30');
INSERT INTO exam_questions (id, dept_id, section_id, machine_id, phase, type, question, options, explanation, question_image, difficulty, created_by, created_at) VALUES ('q6', 1, NULL, NULL, 'P2', 'single', 'Was tun bei Farbabweichung während des Drucks?', '[{"text":"Weiterlaufen lassen, wird schon","correct":false},{"text":"Maschine sofort ausschalten","correct":false},{"text":"Druckvorgang stoppen, Farbmischung und Rakel prüfen","correct":true},{"text":"Schneller drucken damit es nicht auffällt","correct":false}]', 'Bei Farbabweichungen muss der Druck gestoppt und Farbmischung sowie Rakeleinstellung geprüft werden.', NULL, 2, 1, '2026-03-06 11:26:30');
INSERT INTO exam_questions (id, dept_id, section_id, machine_id, phase, type, question, options, explanation, question_image, difficulty, created_by, created_at) VALUES ('eq-1773124860641-mz1a', 1, NULL, NULL, 'P1', 'single', 'Wofür steht dieses Symbol?', '[{"text":"Sammelstelle bei Gefahr","correct":true},{"text":"Zeichen für den Pausenraum","correct":false},{"text":"Wenn Sie hier stehen, weiß der Schichtleiter das Sie hilfe benötigen","correct":false}]', NULL, 'data:image/avif;base64,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', 1, 1, '2026-03-10 06:41:00');

-- Exam Results
INSERT INTO exam_results (id, dept_id, trainee_id, score, total, passed, answers, started_at, finished_at) VALUES (1, 1, 3, 1, 6, 0, '[{"question_id":"q1","chosen":0,"correct":true},{"question_id":"q4","chosen":3,"correct":false},{"question_id":"q6","chosen":3,"correct":false},{"question_id":"q3","chosen":1,"correct":false},{"question_id":"q5","chosen":2,"correct":false},{"question_id":"q2","chosen":1,"correct":false}]', '2026-03-06 11:29:56', '2026-03-06 11:30:25');
INSERT INTO exam_results (id, dept_id, trainee_id, score, total, passed, answers, started_at, finished_at) VALUES (2, 1, 3, 0, 6, 0, '[{"question_id":"q6","chosen":0,"correct":false},{"question_id":"q2","chosen":1,"correct":false},{"question_id":"q3","chosen":1,"correct":false},{"question_id":"q4","chosen":2,"correct":false},{"question_id":"q1","chosen":0,"correct":false},{"question_id":"q5","chosen":2,"correct":false}]', '2026-03-06 11:32:06', '2026-03-06 11:32:18');
INSERT INTO exam_results (id, dept_id, trainee_id, score, total, passed, answers, started_at, finished_at) VALUES (3, 1, 3, 6, 6, 1, '[{"question_id":"q3","chosen":2,"correct":true},{"question_id":"q1","chosen":3,"correct":true},{"question_id":"q2","chosen":0,"correct":true},{"question_id":"q6","chosen":3,"correct":true},{"question_id":"q4","chosen":2,"correct":true},{"question_id":"q5","chosen":1,"correct":true}]', '2026-03-06 11:32:25', '2026-03-06 11:33:25');

-- ================================================================
-- System-Dokumentation (eingebaut als Lerninhalte)
-- ================================================================

INSERT INTO content_sections (id, dept_id, title, position, content_md, parent_id, updated_at) VALUES ('system-doku', 1, 'System-Dokumentation', 99, '# System-Dokumentation

Technische Dokumentation für Administratoren und IT.
Enthält Architektur, Konfiguration, Deployment und Benutzerverwaltung.

> [!INFO]
> Diese Sektion ist nur für Admins sichtbar und kann im Editor bearbeitet werden.', NULL, NOW());

INSERT INTO content_sections (id, dept_id, title, position, content_md, parent_id, updated_at) VALUES ('system-doku-ueberblick', 1, 'Überblick & Einsatzzweck', 1, '# Überblick & Einsatzzweck

SchulungsHub digitalisiert den Einarbeitungsprozess in der Produktion. Neue Mitarbeiter durchlaufen ein strukturiertes Schulungsprogramm – von der Maschinenbedienung bis zur Sicherheitsunterweisung.

## Rollen

| Rolle | Beschreibung |
|---|---|
| **Admin** | Inhalte pflegen, Benutzer verwalten, Export, alle Einsichten |
| **Trainer** | Trainees bewerten, Abschnitte freigeben, Anwesenheit erfassen |
| **Trainee** | Schulungsinhalte lesen, Prüfungen ablegen, Abschnitte quittieren |

## Kernfunktionen

- **Lerninhalte** – Markdown-Schulungsunterlagen als Inhaltsbaum
- **Lernziele** – Je Maschine definierbar, gewichtet, mit Fortschrittsbalken
- **Trainer-Workflow** – Bewertung 25/50/75/100/NIO, Abschnitte freigeben
- **Trainee-Quittierung** – Digitale Bestätigung durch den Trainee
- **Anwesenheitserfassung** – Stunden pro Tag und Maschine
- **Prüfungsmodus** – Single-Choice, Wahr/Falsch, Bildaufgaben
- **RFID-Login** – Schnell-Login per Chip am Arbeitsplatz
- **Export** – Vollständiger JSON-Dump der Abteilung
- **Multi-Mandant** – Datenisolierung zwischen Abteilungen via dept_id

## Einsatz im Siebdruck

Konzipiert für:
- Maschineneinweisung (Flachbett, Karussell, Textildruck)
- Farbmischung & Rakelführung
- Sicherheitsunterweisung (GHS, Lösemittel, PSA)
- Qualitätskontrolle (Passer, Farbabnahme, Ausschuss)
- Einarbeitungsphasen Wochen 1–4 je Maschine', 'system-doku', NOW());

INSERT INTO content_sections (id, dept_id, title, position, content_md, parent_id, updated_at) VALUES ('system-doku-architektur', 1, 'Architektur', 2, '# Architektur

## Stack

| Komponente | Technologie |
|---|---|
| Backend | Go 1.25, stdlib net/http |
| Datenbank | MySQL 8.0, InnoDB, utf8mb4 |
| Passwort-Hash | PBKDF2-SHA256, 120.000 Iterationen |
| Sessions | Server-seitig in MySQL, HttpOnly Cookie |
| Frontend | Vanilla JS (IIFE-Module), kein Build-Step |
| UI-Framework | UIkit 3 (lokal, kein CDN) |

## Request-Flow

1. Browser sendet HTTP-Request mit Session-Cookie
2. Go-Server prüft Cookie → sessions-Tabelle → User / Role / dept_id
3. Handler filtert **alle** Queries per dept_id (Mandantentrennung)
4. Response als JSON oder HTTP-Statuscode

## Kein lokaler Cache

Jeder Lese- und Schreibvorgang ist ein API-Call.
Kein State wird im Browser persistiert – Daten kommen immer frisch vom Server.

## Netzwerk

```
Browser
  → HTTPS → Apache Reverse Proxy (example.local)
  → HTTP  → Go Server :8090 (server.local)
  → TCP   → MySQL :3306
```', 'system-doku', NOW());

INSERT INTO content_sections (id, dept_id, title, position, content_md, parent_id, updated_at) VALUES ('system-doku-config', 1, 'Konfiguration (.env)', 3, '# Konfiguration

Konfiguration via `.env`-Datei im App-Verzeichnis oder Umgebungsvariablen.
Umgebungsvariablen überschreiben `.env`.

## Variablen

| Variable | Standard | Beschreibung |
|---|---|---|
| DB_HOST | 127.0.0.1 | MySQL-Host |
| DB_PORT | 3306 | MySQL-Port |
| DB_USER | root | MySQL-Benutzer |
| DB_PASS | *(leer)* | MySQL-Passwort |
| DB_NAME | schulungshub | Datenbankname |
| PORT | 8080 | HTTP-Port des Servers |
| SECURE_COOKIES | true | Secure-Flag am Session-Cookie |
| SETUP_KEY | *(leer)* | Schlüssel für /api/setup/department |

## SETUP_KEY generieren

```bash
openssl rand -hex 12
# Beispiel: sh-setup-761555663a4c08c1368240ec
```

## Lokal entwickeln

```
SECURE_COOKIES=false
PORT=8080
```

> [!WARNING]
> SETUP_KEY muss gesetzt sein bevor Abteilungen per Skript angelegt werden können.', 'system-doku', NOW());

INSERT INTO content_sections (id, dept_id, title, position, content_md, parent_id, updated_at) VALUES ('system-doku-abteilungen', 1, 'Abteilungen verwalten', 4, '# Abteilungen verwalten

Jede Abteilung ist ein vollständig isolierter Mandant mit eigenen Inhalten, Benutzern, Lernzielen und Prüfungen.

## Neue Abteilung anlegen

Per SSH auf dem Server:

```bash
ssh -i ~/.ssh/your_ssh_key -p 22 root@server.local
cd /opt/schulungshub
./create-dept.sh "Spritzguss" spritzguss admin MeinPasswort "Admin Spritzguss"
```

**Parameter:**
```
./create-dept.sh <Name> <Slug> <Admin-User> <Passwort> [Anzeigename]
```

## Passwörter mit Sonderzeichen

Passwörter mit `!` können in SSH-Sessions Bash-Probleme verursachen.
Dann direkt per curl:

```bash
curl -s -X POST http://localhost:8090/api/setup/department \
  -H '"'"'Content-Type: application/json'"'"' \
  -H '"'"'X-Setup-Key: DEIN_SETUP_KEY'"'"' \
  -d '"'"'{"dept_name":"Lackierung","dept_slug":"lackierung","admin_user":"admin","admin_name":"Admin","admin_pass":"Pass123!"}'"'"'
```

## Nach dem Anlegen

1. Browser → Login → Abteilung im Dropdown wählen
2. Als Admin: Maschinen anlegen
3. Lerninhalte und Lernziele per Export/Import einer anderen Abteilung übernehmen
4. Trainer und Trainees anlegen

## Vorhandene Abteilungen

| Slug | Name | Status |
|---|---|---|
| siebdruck | Siebdruck | Produktiv |
| spritzguss | Spritzguss | Demo |', 'system-doku', NOW());

INSERT INTO content_sections (id, dept_id, title, position, content_md, parent_id, updated_at) VALUES ('system-doku-build', 1, 'Build & Deployment', 5, '# Build & Deployment

## Voraussetzungen

- Go 1.25+
- MySQL 8.0
- SSH-Zugang: `ssh -i ~/.ssh/your_ssh_key -p 22 root@server.local`

## Lokal starten

```bash
mysql -u root < db/schema.sql
mysql -u root schulungshub < db/seed.sql
go run .
# Browser: http://localhost:8080
```

## Build

```bash
./build.sh
```

- Inkrementiert `.build_number` automatisch
- Cross-kompiliert Linux (Server) + macOS (M-Series)
- Strips Debug-Symbole

## Deploy

```bash
./deploy.sh
```

1. Build
2. Stop `schulungshub.service`
3. SCP Binary nach `/opt/schulungshub/`
4. Start Service
5. rsync `web-v4/` auf Server

## Server-Info

| | |
|---|---|
| Host | server.local (Server) |
| SSH-Port | 22 |
| App-Pfad | /opt/schulungshub/ |
| Service | schulungshub.service (systemd) |
| Port | 8090 |
| URL | https://example.local |

## Versionierung

```
0.1.BUILD   z.B. 0.1.15
```

Commit-Format: `v0.1.15: kurze Beschreibung`

## Manueller Deploy-Ablauf

```bash
./build.sh
ssh -i ~/.ssh/your_ssh_key -p 22 root@server.local \
  "systemctl stop schulungshub"
scp -P 22 -i ~/.ssh/your_ssh_key \
  schulungshub-server root@server.local:/opt/schulungshub/
ssh -i ~/.ssh/your_ssh_key -p 22 root@server.local \
  "systemctl start schulungshub"
rsync -avz -e "ssh -i ~/.ssh/your_ssh_key -p 22" \
  web-v4/ root@server.local:/opt/schulungshub/web-v4/
```', 'system-doku', NOW());

INSERT INTO content_sections (id, dept_id, title, position, content_md, parent_id, updated_at) VALUES ('system-doku-auth', 1, 'Authentifizierung & Sicherheit', 6, '# Authentifizierung & Sicherheit

## Passwort-Hashing

- Algorithmus: PBKDF2-SHA256, 120.000 Iterationen, 16 Byte Salt
- Format: `pbkdf2_sha256$120000$<salt_hex>$<hash_hex>`
- Vergleich: ConstantTimeCompare (timing-sicher)

## Sessions

- Token: 32 Byte kryptografisch zufällig (64 Hex-Zeichen)
- Ablauf: 12 Stunden
- Cookie: `schulungshub_session`, HttpOnly, Secure, SameSite=Lax
- Cleanup: alle 10 Minuten

## Rate Limiting (Login)

- 5 Fehlversuche in 5 Minuten → 5 Minuten Sperre
- Pro IP-Adresse, respektiert X-Forwarded-For
- Reset nach erfolgreichem Login

## RBAC

| Rolle | Rechte |
|---|---|
| admin | Vollzugriff: Inhalte, Benutzer, Lernziele, Prüfungen, Export |
| trainer | Lesen, Bewertungen eintragen, Abschnitte freigeben |
| trainee | Eigene Daten, Prüfungen ablegen, Abschnitte quittieren |

## RFID

- Tag-ID wird SHA-256-gehasht, kein Klartext gespeichert
- Schnell-Login am Maschinenarbeitsplatz

## Sonstiges

- Body-Limit: 2 MB pro Request
- Setup-Endpunkt: nur mit X-Setup-Key Header (HTTP 403 sonst)
- Fehlerausgabe: kein Stack-Trace, keine DB-Details an den Client', 'system-doku', NOW());

INSERT INTO content_sections (id, dept_id, title, position, content_md, parent_id, updated_at) VALUES ('system-doku-api', 1, 'API-Referenz', 7, '# API-Referenz

## Authentifizierung (öffentlich)

| Methode | Pfad | Beschreibung |
|---|---|---|
| POST | /api/auth/login | Login via Username + Passwort |
| POST | /api/auth/logout | Session löschen |
| GET | /api/auth/me | Aktuell eingeloggter User |
| GET | /api/auth/departments | Alle Abteilungen |
| GET | /api/auth/login-users | Benutzer einer Abteilung |
| POST | /api/auth/rfid-login | Login via RFID-Hash |
| POST | /api/setup/department | Neue Abteilung (X-Setup-Key) |

## Benutzer

| Methode | Pfad | Beschreibung |
|---|---|---|
| GET | /api/users | Benutzerliste |
| POST | /api/users | Benutzer anlegen (admin) |
| PUT | /api/users/:id | Stammdaten ändern |
| PUT | /api/users/:id/password | Passwort ändern |
| PUT | /api/users/:id/rfid | RFID-Hash setzen (admin) |
| DELETE | /api/users/:id | Soft-Delete (admin) |

## Inhalte & Ziele

| Methode | Pfad | Beschreibung |
|---|---|---|
| GET/POST | /api/content | Abschnitte lesen / anlegen |
| PUT/DELETE | /api/content/:id | Bearbeiten / Löschen |
| GET/POST | /api/goals | Lernziele lesen / anlegen |
| PUT/DELETE | /api/goals/:id | Bearbeiten / Löschen |

## Bewertung & Anwesenheit

| Methode | Pfad | Beschreibung |
|---|---|---|
| GET/POST | /api/evaluations | Bewertungen |
| GET/POST | /api/attendance | Anwesenheit |
| DELETE | /api/attendance/:id | Eintrag löschen |
| GET/PUT | /api/trainee-meta/:id | Trainee-Notizen |
| GET/POST | /api/confirmations | Abschnitts-Bestätigungen |

## Suche, Prüfung, Export

| Methode | Pfad | Beschreibung |
|---|---|---|
| GET | /api/search?q=... | Volltextsuche |
| GET/POST | /api/exam/questions | Prüfungsfragen |
| GET/POST | /api/exam/results | Prüfungsergebnisse |
| GET | /api/export | JSON-Dump der Abteilung |
| GET | /api/version | Serverversion |', 'system-doku', NOW());
