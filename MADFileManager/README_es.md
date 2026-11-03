[English](README.md) | [简体中文](README_zh.md) | [日本語](README_ja.md) | [Português (Brasil)](README_pt-BR.md) | [Deutsch](README_de.md) | **Español**

## Detalles sobre iCloud

Actualmente se pide al usuario que elija una ubicación de iCloud cada vez que abre. No está claro si el estado se está guardando.

¿Dónde almacenar los documentos?
    ¿Dejar que decida el usuario?
    Una vez que elija, usar esa ubicación.

application:didFinishWithLaunchingWithOptions
    [[NSFileManager defaultManager] ubiquityIdentityToken]

Registrarse para NSUbiquityIdentifierDidChangeNotification
