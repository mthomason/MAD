[English](README.md) | [简体中文](README_zh.md) | [日本語](README_ja.md) | [Português (Brasil)](README_pt-BR.md) | **Deutsch**

## Details zu iCloud

Derzeit wird der Benutzer bei jedem Öffnen aufgefordert, einen iCloud-Ort
auszuwählen. Ob der Zustand gespeichert wird, ist unklar.

Wo sollen Dokumente gespeichert werden?
    Den Benutzer entscheiden lassen?
    Sobald er gewählt hat, einfach diesen Ort verwenden.

application:didFinishWithLaunchingWithOptions
    [[NSFileManager defaultManager] ubiquityIdentityToken]

Für NSUbiquityIdentifierDidChangeNotification registrieren
