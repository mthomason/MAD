[English](README.md) | [简体中文](README_zh.md) | [日本語](README_ja.md) | **Português (Brasil)**

## Detalhes sobre o iCloud

Atualmente o aplicativo solicita ao usuário que escolha um local do iCloud sempre que é aberto. É necessário verificar se o estado está sendo persistido corretamente.

Onde armazenar os documentos?
    Deixar o usuário decidir?
    Depois que escolher, continuar usando aquele local.

application:didFinishWithLaunchingWithOptions
    [[NSFileManager defaultManager] ubiquityIdentityToken]

Registrar para NSUbiquityIdentifierDidChangeNotification
