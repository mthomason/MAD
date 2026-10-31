[English](README.md) | [简体中文](README_zh.md) | **日本語** | [Português (Brasil)](README_pt-BR.md)

# MADTds フレームワーク

**MADTds**は、FreeTDSライブラリの`sybdb.h`をラップするiOS（およびmacOS）向けフレームワークです。iOSプロジェクトにおけるSybase / SQL Server（TDS）データベースの統合と利用を簡素化し、ネイティブなObjective-C APIを介してデータベースと容易に対話できるようにします。

## 特徴

- `MADTdsDb`インターフェースによる簡潔なデータベース操作。
- 堅牢なTDSデータベース通信をサポートするFreeTDSライブラリを内包。
- iOSと完全な互換性を持ち、Xcode環境内で動作するよう構築。
- FreeTDSの依存関係を管理するカスタムビルドスクリプトを同梱。

---

## インストール

### 前提条件

- Xcode 13以降
- iOS 12.0以降
- プリコンパイル済みFreeTDSバイナリ（フレームワークに同梱）

### 手順

1. リポジトリをクローンまたはダウンロードします。
2. `MADTds.xcodeproj`をXcodeワークスペースに追加します。
3. ターゲットの**General > Frameworks, Libraries, and Embedded Content**で`MADTds.framework`をリンクします。
4. `freetds/lib/include`ディレクトリの必要なヘッダーをプロジェクトの検索パスに追加します：
   - ターゲットの**Build Settings**を開きます。
   - **Header Search Paths**に`MADTds/freetds/lib/include`を追加します。

---

## 使い方

### フレームワークのインポート

MADTdsを使用するファイルに次のインポート文を追加します：

```objc
#import <MADTds/MADTds.h>
#import <MADTds/MADTdsDb.h>
```

### データベースへの接続

データベースに接続してクエリを実行する例は以下の通りです：

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

## ディレクトリ構成

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

## フレームワークのビルド

1. `build_tds.sh`スクリプトに実行権限があることを確認します：
   ```bash
   chmod +x build_tds.sh
   ```
2. スクリプトを実行してFreeTDSライブラリをビルドします：
   ```bash
   ./build_tds.sh
   ```
3. Xcodeで`MADTds.xcodeproj`を開き、フレームワークをビルドします。

---

## ドキュメント

ドキュメントは`madtds/MADTds.docc`フォルダにあります。閲覧するには：
1. Xcodeで`MADTds.xcodeproj`を開きます。
2. メニューから**Product > Build Documentation**を選択します。

---

## コントリビューション

コントリビューションを歓迎します。以下の手順に従ってください：

1. リポジトリをフォークします。
2. 新機能またはバグ修正用の新しいブランチを作成します。
3. 変更をコミットし、自分のフォークへプッシュします。
4. 変更内容を説明したプルリクエストを提出します。

---

## ライセンス

本プロジェクトは**MIT License**を採用しています。詳細は`LICENSE`ファイルを参照してください。

---

## 謝辞

- Sybase/TDSデータベースライブラリを提供している[FreeTDS](http://www.freetds.org)。
- インスピレーションとサポートを提供してくれるiOS開発者コミュニティ。

---
