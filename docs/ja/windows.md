---
layout: default
title: MAD Designer for Windows
description: >-
  SQLite、MySQL、MariaDB、PostgreSQL、SQL Server に対応する Windows（WPF）ネイティブのリレーショナルレポートデザイナー兼ビューア — ビジュアルクエリキャンバス、バンド型レポートデザイナー、ページ単位で正確なビューア、HTML/CSV/JSON へのエクスポートを、Linux と macOS と同じ headless エンジン上で提供します。
image: /assets/mad-designer-icon-512.png
lang: ja-JP
---

# <a href="https://raw.githubusercontent.com/mthomason/MAD/master/StaticResources/Images/icons/document/Designer%20Icon@3x.png"><img src="../assets/mad-designer-icon-512.png" alt="MAD Designer for Windows アイコン" width="48" height="48" style="vertical-align: middle; margin-right: 10px;" /></a>MAD Designer for Windows

**MAD Designer for Windows** は、Windows Presentation Foundation（WPF）と .NET 10 上で動作するネイティブなデスクトップアプリケーションで、Mobile Analytics Document（`.mad`）の作成、クエリ、レイアウト、更新、エクスポートを行います。macOS アプリケーションと Linux の headless `mad` CLI と同じ自社開発の Objective-C エンジン（`mad.exe`）を実行するため、書き出すドキュメントは iPad/iPhone アプリ、`mad` CLI、および GitHub Action [`mad-action`](https://github.com/mthomason/mad-action) と互換性があります。

> **この 0.7 ビルドは署名されていません。** 公開ソースからビルドして公開していますが、商用のコード署名証明書を持たないため、初回起動時に Windows SmartScreen が警告します。隠しているものはありません。ビルドを確認し（下記参照）、SHA-256 チェックサムを検証してから実行してください。

## ダウンロードとインストール

* **直接ダウンロード:** [**MAD-Designer-Windows-0.7.zip**](https://github.com/mthomason/MAD/releases/download/v0.7.0/MAD-Designer-Windows-0.7.zip)
* **バージョン:** アプリ 0.7 / エンジン 9.0 (r4433)。
* **要件:** Windows 10（1903 以降）または Windows 11、64 ビット。アーカイブは自己完結型のため、**.NET ランタイムのインストールは不要です**。ビューアは Microsoft Edge WebView2 Evergreen ランタイムを使用します。これは Windows 11 と最新の Edge に同梱されています。古い Windows 10 イメージでは [Evergreen ランタイム](https://developer.microsoft.com/microsoft-edge/webview2/)をインストールしてください。

1. `.zip` をダウンロードし、任意のフォルダーに展開します。アプリケーション、エンジン、ライセンスは一体なので、フォルダー構造はそのまま保持してください。
2. 展開したフォルダーの直下にある `Mad.Designer.Windows.exe` を実行します。
3. 初回起動時、Windows SmartScreen が*「Windows によって PC が保護されました」*と表示することがあります。**詳細情報**、次に **実行** を選択してください。このビルドは意図的に署名されていません（下記参照）。

### アーカイブの内容

```
MAD-Designer-Windows-0.7/
  Mad.Designer.Windows.exe    WPF アプリケーション（自己完結型）
  ...                         アプリケーション自身のファイル
  CLI/Fixtures/               London.portable.mad（サンプルレポート）と
                              chinook.sqlite3（更新に使うサンプルデータ）
  Windows/Engine/build/mad.exe       headless エンジン
  Windows/Engine/build/*.dll         エンジンの GNUstep/ObjC/VC ランタイム
  Windows/Engine/build/fonts/        PDF エクスポートで使う Liberation フォント
  ThirdParty/Licenses/       すべてのサードパーティライセンスと通知
  LICENSE, NOTICE, README-Windows.txt
```

**エンジンの場所:** `Windows/Engine/build/mad.exe` で、ランタイム DLL と `fonts` フォルダーの隣にあります。アプリケーションはソースツリーと同じリポジトリ相対の構造でエンジンを見つけます。システム全体の GNUstep インストールは使用しません。フォルダーはアーカイブが置いた場所から移動しないでください。

### ダウンロードの検証

リリースページにはアーカイブの SHA-256 チェックサムが公開されています。ダウンロード後に比較してください。

```powershell
Get-FileHash .\MAD-Designer-Windows-0.7.zip -Algorithm SHA256
```

展開した内容はファイル単位でも確認できます。アーカイブには、公開されたアプリケーション、`Windows/Engine/build.ps1` でビルドされたエンジン、サンプルドキュメント、ライセンス文書だけが含まれています。`mad.exe` は、[Linux ガイド](https://github.com/mthomason/MAD/blob/master/Linux/README.md)と [Windows ビルド記録](https://github.com/mthomason/MAD/blob/master/docs/project/MAD_WINDOWS.md)に記載されているコマンドラインエンジンと同じものです。

### このビルドの確認と自己署名

GUI を開かずに `mad.exe` を直接実行してドキュメントを検査できます。

```powershell
.\Windows\Engine\build\mad.exe inspect .\CLI\Fixtures\London.portable.mad
```

*自分の*コピーについて Windows の警告を止めたい場合は、ローカルのコード署名証明書を作成し、実行可能ファイルに自分で署名します。これはローカルな信頼の判断であり、公開ダウンロードが他の誰かにとって信頼できるようになるわけではありません。

```powershell
$cert = New-SelfSignedCertificate -Type CodeSigningCert `
    -Subject "CN=MAD Designer (local review)" `
    -CertStoreLocation Cert:\CurrentUser\My
Set-AuthenticodeSignature -FilePath .\Mad.Designer.Windows.exe -Certificate $cert
```

このマシンでその証明書を信頼するには、エクスポートして `certmgr.msc` または `Import-Certificate` で**信頼されたルート証明機関**にインポートします。自分で作成して管理している証明書に限って行ってください。

## ワークスペース

アプリケーションには、macOS アプリと同じ 3 つのレポート作成段階があります。

* **MAD Query** — ビジュアルクエリキャンバス（ドラッグ可能なテーブルカード、ベジェの結合コネクター、結合タイプのバッジ、フィルターとグループ化）と直接 SQL エディター。どちらもドキュメントのインポート済みスキーマに対して動作します。
* **MAD Designer** — バンドベースのレイアウトワークスペース。ページとセクションのミニマップ、レポートバンドのアウトライン、検索可能なクエリフィールド、ズームとルーラー付きのデザインキャンバス（整列ガイド、元に戻す/やり直し）、コンテンツ・タイポグラフィ・ジオメトリの要素インスペクターを備えます。
* **MAD Viewer** — クエリをローカルのマテリアライズ済みテーブルに更新し、ページサイズ（US Letter、US Legal、A4）を選択し、レンダリングされたページを移動して、エクスポートします。

ビューアは **PDF**、**HTML**、**HTML Flow**、**CSV**、**JSON**、**JSON Full Report**、**プレーンテキスト**を、macOS のビューアと同じ順序でエクスポートします。PDF はエンジン自身が書き出し（`mad export --format pdf` と同じエクスポーター）、大きなレポートでもウィンドウがブロックされません。ステータスバーには不確定の進行状況バーと「書き出し中…」の行が表示され、書き出しが終わるとサイズが示されます。

## ソースからのビルド

アプリケーションは [`Windows/global.json`](https://github.com/mthomason/MAD/blob/master/Windows/global.json) で固定された .NET SDK（10.0.404）でビルドします。

```powershell
dotnet publish Windows\App\Mad.Designer.Windows\Mad.Designer.Windows.csproj `
    -c Release -r win-x64 --self-contained true
```

エンジンのほうが難しい半分です。`Windows\Engine\build.ps1` はネイティブビルドを再現します（Clang 20.1.8、固定された Visual Studio の MSVC ツールチェーン、NASM、Strawberry Perl、Meson、Python、そして 7 つの固定リビジョンから `C:\GNUstep` にビルドする GNUstep）。管理者権限の PowerShell プロンプトから実行する必要があります。

```powershell
pwsh -File .\Windows\Engine\build.ps1                 # ツールチェーンの完全なブートストラップとビルド
pwsh -File .\Windows\Engine\build.ps1 -SkipToolchain  # ツールチェーンが既にある場合の再ビルド
```

2 つの .NET スイートはビルド済みのエンジンに対して実行します。

```powershell
dotnet test Windows\App\Mad.Designer.Windows.slnx
```

`Windows/Engine/build.ps1` は移植されたネイティブスイートも実行し、`Windows/package.ps1` はエンジンとアプリをビルドした後に、署名なしのリリースアーカイブと CI 用のエンジンアセットを組み立てます。完全なレシピ、Windows 固有のランタイム修正、ライセンス義務、対応 OS のマトリックスは [`docs/project/MAD_WINDOWS.md`](https://github.com/mthomason/MAD/blob/master/docs/project/MAD_WINDOWS.md) に記録されています。

## ライセンス

MAD は MIT ライセンスです（[`LICENSE`](https://github.com/mthomason/MAD/blob/master/LICENSE) を参照）。「MAD」「MAD Designer」「MAD Viewer」という名称とアプリのアートワークは対象外です（[`NOTICE`](https://github.com/mthomason/MAD/blob/master/NOTICE) を参照）。エンジンは GNUstep ランタイム（LGPL-2.1-or-later）と C ライブラリを追加します。各コンポーネント、そのライセンス、書面による再リンクの申し出は、アーカイブの `ThirdParty/Licenses/` フォルダーと [`docs/project/THIRD_PARTY_LICENSES.md`](https://github.com/mthomason/MAD/blob/master/docs/project/THIRD_PARTY_LICENSES.md) にあります。
