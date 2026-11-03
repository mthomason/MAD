[English](README.md) | [简体中文](README_zh.md) | [日本語](README_ja.md) | [Português (Brasil)](README_pt-BR.md) | **Deutsch** | [Español](README_es.md)

# MADTds-Framework

**MADTds** ist ein Framework für iOS, das `sybdb.h` aus der FreeTDS-Bibliothek
umhüllt. Es vereinfacht die Integration und Nutzung von Sybase-Datenbanken in
iOS-Projekten. Das Framework bietet eine native Objective-C-API, die die
Interaktion mit Sybase-Datenbanken in iOS-Anwendungen erleichtert.

## Funktionen

- Vereinfachte Datenbankoperationen über die Schnittstelle `MADTdsDb`.
- Enthält die FreeTDS-Bibliothek für eine robuste Unterstützung der
  Sybase-Datenbankfunktionalität.
- Vollständig kompatibel mit iOS und für die Arbeit innerhalb der
  Xcode-Umgebung ausgelegt.
- Eigenes Build-Skript zur Verwaltung der FreeTDS-Abhängigkeiten.

---

## Installation

### Voraussetzungen

- Xcode 13 oder neuer
- iOS 12.0 oder neuer
- Vorkompilierte FreeTDS-Binaries (im Framework enthalten)

### Schritte

1. Klonen oder laden Sie das Repository herunter.
2. Fügen Sie `MADTds.xcodeproj` zu Ihrem Xcode-Workspace hinzu.
3. Linken Sie `MADTds.framework` in Ihrem Target unter **General > Frameworks,
   Libraries, and Embedded Content**.
4. Fügen Sie die erforderlichen Header aus dem Verzeichnis `freetds/lib/include`
   den Suchpfaden Ihres Projekts hinzu:
   - Gehen Sie zu den **Build Settings** Ihres Targets.
   - Setzen Sie die **Header Search Paths** so, dass sie
     `MADTds/freetds/lib/include` enthalten.

---

## Verwendung

### Das Framework importieren

Fügen Sie die folgende Import-Anweisung in der Datei hinzu, in der Sie MADTds
verwenden möchten:

```objc
#import <MADTds/MADTds.h>
#import <MADTds/MADTdsDb.h>
```

### Verbindung zu einer Datenbank herstellen

Hier ist ein Beispiel, wie man eine Verbindung zu einer Sybase-Datenbank
herstellt und eine Abfrage ausführt:

```objc
MADTdsDb *db = [[MADTdsDb alloc] init];

// Configure the connection
db.server = @"your-server";
db.database = @"your-database";
db.username = @"your-username";
db.password = @"your-password";

if ([db connect]) {
    NSLog(@"Connected to database successfully.");
    NSArray *results = [db executeQuery:@"SELECT * FROM your_table"];
    NSLog(@"Query Results: %@", results);
} else {
    NSLog(@"Failed to connect to database.");
}
```

---

## Verzeichnisstruktur

```
MADTds.xcodeproj/              - Xcode project configuration
MADTds/                        - Core framework source
├── MADTds.h                   - Framework entry point
├── MADTdsDb.h                 - Database connection interface
├── MADTdsDb.m                 - Database connection implementation
madtds/MADTds.docc/            - Documentation for the framework
freetds/                       - Bundled FreeTDS library
├── lib/include/               - Header files for FreeTDS
├── lib/libct.a                - FreeTDS Client Library
├── lib/libsybdb.a             - FreeTDS Database Library
build_tds.sh                   - Script to manage FreeTDS builds
README.md                      - Project documentation
```

---

## Das Framework bauen

1. Stellen Sie sicher, dass das Skript `build_tds.sh` Ausführungsrechte hat:
   ```bash
   chmod +x build_tds.sh
   ```
2. Führen Sie das Skript aus, um die FreeTDS-Bibliothek zu bauen:
   ```bash
   ./build_tds.sh
   ```
3. Öffnen Sie `MADTds.xcodeproj` in Xcode und bauen Sie das Framework.

---

## Dokumentation

Die Dokumentation ist im Ordner `madtds/MADTds.docc` verfügbar. So zeigen Sie die
Dokumentation an:
1. Öffnen Sie `MADTds.xcodeproj` in Xcode.
2. Gehen Sie zum Menü **Product > Build Documentation**.

---

## Mitwirken

Beiträge sind willkommen! Bitte folgen Sie diesen Schritten:

1. Forken Sie das Repository.
2. Erstellen Sie einen neuen Branch für Ihr Feature oder Ihre Fehlerbehebung.
3. Committen Sie Ihre Änderungen und pushen Sie sie in Ihren Fork.
4. Reichen Sie einen Pull Request ein, der Ihre Änderungen beschreibt.

---

## Lizenz

Dieses Projekt verwendet die **MIT-Lizenz**. Weitere Einzelheiten finden Sie in der
Datei `LICENSE`.

---

## Danksagungen

- [FreeTDS](http://www.freetds.org) für die Bereitstellung der
  Sybase-Datenbankbibliothek.
- Die iOS-Entwicklergemeinschaft für Inspiration und Unterstützung.

---
