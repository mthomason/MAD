[English](README.md) | **简体中文** | [日本語](README_ja.md) | [Português (Brasil)](README_pt-BR.md)

## 关于 iCloud 的细节

目前每次打开时都会提示用户选择 iCloud 位置。不确定该状态是否会被保存。

文档存放在哪里？
    让用户决定？
    选定后就使用该位置。

application:didFinishWithLaunchingWithOptions
    [[NSFileManager defaultManager] ubiquityIdentityToken]

为 NSUbiquityIdentifierDidChangeNotification 注册通知
