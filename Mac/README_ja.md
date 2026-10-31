[English](README.md) | [简体中文](README_zh.md) | **日本語**

# Mac — ネイティブmacOS（`AppKit`）アプリケーション

`Mac/`には、12個のマルチプラットフォームMADフレームワーク（`MADFoundation`、`MADDataStructures`、`MADCocoaExtensions`、`MADFileManager`、`MADAPI`、`MADSqlite3`、`MADTds`、`MADTdsClient`、`MADMySQL`、`MADPostgres`、`MADBarcodes`、および`MAD`）と`Compressor`がビルドする10個のユニバーサル（`arm64` + `x86_64`）静的Cライブラリの上に構築された、**MAD Designer**のネイティブmacOS（`AppKit`、`macosx` SDK、`MACOSX_DEPLOYMENT_TARGET = 12.0`）フロントエンドが格納されています。

ユーザー向けのワークスペース概要およびスクリーンショットについては[`docs/macos.md`](../docs/ja/macos.md)を参照してください。フレームワークごとのマルチプラットフォーム移植監査およびアーキテクチャ記録については[`docs/project/MAD_MACOS.md`](../docs/project/MAD_MACOS.md)を参照してください。

## 実行方法

```sh
./Mac/build.sh                     # build 12 macOS frameworks + Mac/build/MAD Designer.app
./Mac/build.sh --no-frameworks     # rebuild only MAD Designer.app (fast iteration)
./Mac/build.sh --smoke-test        # build and run the end-to-end macOS smoke suite
./Mac/build.sh --package           # create Mac/build/MAD-Designer-macOS.zip and .dmg
```

また、Xcodeで`Reports.xcworkspace`を開き、共有スキーム**`MAD Designer Mac`**とデスティネーション**My Mac**を選択して、直接アプリケーションをビルド・実行・デバッグすることもできます。

## ディレクトリ構成

* `Mac/Source/` — `AppKit`アプリケーション、`NSDocument`アーキテクチャ、および3つのワークスペース：
  * `MADMacAppDelegate.{h,m}` — アプリケーションライフサイクル、ドライバ／コンバータ登録、およびメインメニューバー（`MAD Designer`、`File`、`Edit`、`View`、`Report`、`Window`、`Help`）。
  * `MADMacAboutWindowController.{h,m}` — ネイティブの**About MAD Designer**ウィンドウ（`Overview`、`License & Notice`、およびコンポーネントサイドバーとバンドル済みサードパーティライセンス本文を備えた`Acknowledgements`）。
  * `MADMacDocumentController.{h,m}` — 標準のオープンパネルに`.mad` `UTType`フィルタ（`com.everydayapps.productivity.mad`および`com.thomason.report.mad`）とプライマリの**New Document**ボタンを構成する`NSDocumentController`サブクラス。
  * `MADMacDocument.{h,m}` — `MADHeadlessDocument`、`MADDesignerLayout`（`NSUndoManager`）、`MADSectionsLayout`、非同期更新（`MADOperationQueue`）、およびエクスポートをラップする`NSDocument`サブクラス。
  * `MADMacWindowController.{h,m}` — 中央に**Workspace**セグメントコントロール（`MAD Query`、`MAD Designer`、`MAD Viewer`）を備えたメインドキュメントウィンドウ。
  * `MADMacConnectionWindowController.{h,m}` — SQLite、MySQL、Microsoft SQL Server、およびPostgreSQLをサポートし、`MADKeyChain`による認証情報保存を備えたデータベース接続・スキーマインポートアシスタント。
  * `MADMacQueryViewController.{h,m}` — ビジュアルなテーブル／結合キャンバス（`MADMacQueryCanvasView`、`MADMacQueryTableCardView`、`MADMacQueryLinksOverlayView`）、フィルタ／グループ化ポップオーバー、および全幅のSQL Queryエディタ（`MADSQLParser` / `MADSQLQueryCompiler`）を備えた**MAD Query**ワークスペース。
  * `MADMacDesignerViewController.{h,m}` & `MADMacDesignerCanvasView.{h,m}` — エレメントパレット、インタラクティブなPage & Section Minimap（`MADMacDesignerMinimapView`）、Report Bandsアウトライン、Query Fieldsドラッグソース、ズーム・ルーラー付きデザインキャンバス、および2カード構成の右インスペクタを備えた**MAD Designer**ワークスペース。
  * `MADMacViewerViewController.{h,m}` — 用紙サイズ選択（`MTPaper`）、更新、ズーム／ページナビゲーション、フレーム付き`PDFView`描画、ステータスバー、`NSPrintOperation`印刷、および7フォーマットのエクスポート（`PDF`、`HTML`、`HTML Flow`、`CSV`、`JSON`、`JSON Report`、`Plain Text`）を備えた**MAD Viewer**ワークスペース。
* `Mac/Resources/Info.plist` — バンドルメタデータおよび`.mad`ドキュメントタイプ／UTI宣言。
* `Mac/Tests/MADMacSmokeTest.m` — バンドル構造、スキーマインポート、ビジュアルクエリ設計、SQL入力、デザイナキャンバス／ミニマップ／インスペクタ変更、Undo/Redo、データ更新、および全7種類のエクスポートフォーマットを検証するエンドツーエンド検証実行ファイル。
