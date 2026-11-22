---
layout: default
lang: de-DE
title: "Satelliten-Repositories"
description: "Wie `mad-action` und das Container-Image aus diesem Repository veröffentlicht werden."
---

# Satelliten-Repositories

Diese Seite erklärt, wie die GitHub Action `mad-action` und das Container-Image aus diesem Repository veröffentlicht werden und welche Regel einen Satelliten aktuell hält.

Ein Satellit ist ein Repository außerhalb von `mthomason/MAD`, das etwas veröffentlicht, was aus MAD gebaut wird: heute die GitHub Action `mad-action`, daneben das Container-Image auf GHCR. Satelliten sind **Veröffentlichungsziele, keine Forks**. MAD ist die Quelle der Wahrheit; ein Satellit wird aus einem Verzeichnis hier erzeugt, und über die Grenze wandern nur das veröffentlichte Artefakt und die Dateien unter `satellites/<name>/`.

Das ist dasselbe Modell wie beim Image: `Linux/` ist die Quelle, `.github/workflows/publish-image.yml` veröffentlicht `ghcr.io/mthomason/mad` bei jedem Push auf `master`, und nichts kopiert den Quellcode der Engine irgendwohin sonst. Ein Nutzer der Action erhält eine neue Engine, weil der Image-Tag weitergeschoben wurde, nicht weil das Satelliten-Repository einen Commit erhalten hat.

## Register

| Satellit | Quelle | Veröffentlicht durch | Verweise | Versions-Tag |
|---|---|---|---|---|
| [mthomason/mad-action](https://github.com/mthomason/mad-action) | `satellites/mad-action/` | `.github/workflows/publish-mad-action.yml` | `ghcr.io/mthomason/mad:latest` | `v1` (wandernd; `satellites/mad-action/VERSION`) |
| `ghcr.io/mthomason/mad` (Image, kein Repository) | `Linux/` | `.github/workflows/publish-image.yml` | — | `latest`, `<short-sha>` |

`mthomason/mad-action` wird erzeugt. Bearbeiten Sie es nicht direkt: eine Änderung geht in `satellites/mad-action/` hier, durch das normale PR-Gate, und der Veröffentlichungs-Workflow trägt sie hinüber. Issues und Pull Requests für die Action gehören in `mthomason/MAD`.

## Was einen Satelliten-Commit erfordert

| Änderung in MAD | Aktualisierung des Satelliten |
|---|---|
| Engine- oder App-Code | Keine — der nächste Master-Push veröffentlicht `:latest` neu, und die Action führt es aus |
| Dokumentation | Keine — die README der Action verweist auf MAD |
| CLI-Verben, Flags, Eingabe von Zugangsdaten oder Exportformate | `satellites/mad-action/action.yml`, `README.md`, wenn sich die Eingabezuordnung oder die Dokumentation ändert |
| Image-Name oder Tag-Richtlinie | `satellites/mad-action/action.yml`, `README.md`, die Workflows |
| `CLI/Fixtures/London.portable.mad` | Automatisch: der Veröffentlichungs-Workflow kopiert sie nach `fixtures/` |
| `LICENSE` oder `NOTICE` | Automatisch: der Veröffentlichungs-Workflow kopiert beide |
| `satellites/mad-action/**` | Automatisch: der Veröffentlichungs-Workflow synchronisiert das Verzeichnis |

Der Veröffentlichungs-Workflow läuft auf `master`, wenn sich einer dieser Pfade ändert, und von Hand mit `workflow_dispatch`. Er testet die Quelle gegen das veröffentlichte Image, synchronisiert das Ziel, committet als `MAD release bot`, verschiebt das Haupt-Tag und lässt den eigenen Test-Workflow des Ziels auf dem Push laufen. Der Test-Workflow des Satelliten wird zudem täglich geplant — der Kanarienvogel, der eine Engine-Änderung erkennt, die den Wrapper bricht, obwohl sich der Quellcode des Wrappers nicht geändert hat.

GitHub deaktiviert geplante Workflows nach 60 Tagen ohne Repository-Aktivität. Der nächste Sync-Commit aktiviert ihn wieder; ein manueller `workflow_dispatch` führt den Test in der Zwischenzeit sofort aus. Das ist der einzige Teil der Vereinbarung, der still werden kann, ohne zu scheitern.

## Die Release-Checkliste

**Eine normale Quelländerung.**

1. Bearbeiten Sie `satellites/mad-action/` und/oder das Fixture hier.
2. Führen Sie den Wrapper lokal aus, wenn sich die Schnittstelle geändert hat (`./Linux/build.sh
   --verify` baut `mad-cli:latest`; die Action kann mit
   `image: mad-cli:latest` darauf gerichtet werden).
3. Öffnen Sie den PR. `Linux verification` führt den Wrapper gegen das eigene Laufzeit-Image des PRs aus (`linux.yml`), zusätzlich zum Test der Action im Ziel.
4. Mergen Sie. `Publish mad-action` testet und veröffentlicht; der eigene Testlauf des Satelliten im Ziel-Repository muss dann grün sein.

**Eine Änderung am CLI-Vertrag.** Derselbe PR aktualisiert die Eingaben von `action.yml` und die README. Die Veröffentlichung verschiebt `v1`; bestehende Nutzer erhalten den neuen Wrapper bei ihrem nächsten Lauf. Ist die Änderung brechend — eine Eingabe umbenannt oder entfernt, ein Standard inkompatibel geändert —, erhöhen Sie `satellites/mad-action/VERSION` im selben PR auf `v2` und aktualisieren Sie die `@v1`-Verweise in der README. Der Workflow verschiebt dann `v2` und lässt `v1` dort, wo es ist, sodass Nutzer von `mthomason/mad-action@v1` die alte Hauptversion behalten, bis sie wechseln.

**Eine Auffrischung des Fixtures.** Erzeugen Sie das Fixture in MAD neu (`CLI/Fixtures/README.md`); der Pfadfilter kopiert es. Bearbeiten Sie nicht die Kopie im Satelliten-Repository.

**Rotation des Deploy-Keys.** Erzeugen Sie einen neuen ed25519-Schlüssel, fügen Sie seine öffentliche Hälfte als Write-Deploy-Key zu `mthomason/mad-action` hinzu, legen Sie die private Hälfte als Secret `MAD_ACTION_DEPLOY_KEY` auf `mthomason/MAD` ab, lösen Sie `Publish mad-action` aus und löschen Sie dann den alten Deploy-Key. Der Schlüssel ist auf das eine Ziel-Repository beschränkt und kann nur schreiben.

## Einmalige Einrichtung, festgehalten

Das Ziel-Repository wurde leer und öffentlich erstellt. Der Standard-Branch von GitHub ist `main`, und die erste Veröffentlichung füllt ihn; der Workflow pusht auf `main`. Es wurde nicht mit einer README oder Lizenz initialisiert, weil der erste Sync beides liefert. Issues und das Wiki sind dort deaktiviert: die README verweist für beides auf MAD. Falls es jemals neu erstellt wird, wiederholen Sie dies:

1. `gh repo create mthomason/mad-action --public`
2. Issues und das Wiki deaktivieren.
3. Einen Write-Deploy-Key mit dem Titel `MAD publish workflow` hinzufügen.
4. Seine private Hälfte als Secret `MAD_ACTION_DEPLOY_KEY` auf `mthomason/MAD` ablegen.
5. `Publish mad-action` auslösen.

Der Satellit hat keine eigenen Abhängigkeiten von Drittanbietern: sein Inhalt ist `docker run` des veröffentlichten Images, und seine Lizenzdateien sind die von MAD (`LICENSE`, `NOTICE`).

## Einen weiteren Satelliten hinzufügen

Erstellen Sie `satellites/<name>/` hier, fügen Sie einen Veröffentlichungs-Workflow in der Form von `publish-mad-action.yml` hinzu und ergänzen Sie die Registerzeile oben. Die Regeln sind dieselben: MAD ist die Quelle der Wahrheit, der Satellit konsumiert ein veröffentlichtes Artefakt, und eine Versionsdatei (oder ein Äquivalent) benennt das wandernde Tag, das ein Nutzer pinnt. Spiegeln Sie den Quellcode der Engine nicht in einen Satelliten; er reist bereits im Image mit.
