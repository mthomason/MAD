[English](README.md) | [简体中文](README_zh.md) | **日本語**

## iCloudに関する詳細メモ

現在、開くたびにiCloudの保存場所を選択するようユーザーに求めるプロンプトが表示される状態です。状態が正しく保存されているか確認が必要です。

ドキュメントの保存場所はどうすべきか？
    ユーザーに選択させるか？
    一度選択したら、以降は同じ場所を使用する。

application:didFinishWithLaunchingWithOptions
    [[NSFileManager defaultManager] ubiquityIdentityToken]

NSUbiquityIdentifierDidChangeNotificationを登録する
