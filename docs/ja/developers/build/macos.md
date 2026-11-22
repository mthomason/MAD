---
layout: default
title: "ポータビリティとネイティブmacOSアプリケーション"
description: "フレームワークのポータビリティ監査とAppKitアプリケーションアーキテクチャ。"
lang: ja-JP
---

# `MAD_MACOS.md` -- マルチプラットフォームフレームワークとネイティブmacOSアプリケーション

このページはマルチプラットフォームフレームワーク監査とネイティブmacOSアプリケーションアーキテクチャを記録します。ユーザー向けガイドは`/macos.html`にあります。

*元の日付に書かれ、現状の事実は2026-11-22に整合。*

このドキュメントは、MADフレームワークを真にマルチプラットフォーム（`iphoneos`、`iphonesimulator`、`macosx`、およびヘッドレスLinux）にし、**MAD Designer**のネイティブmacOS（`AppKit`）フロントエンドを構築するための、アーキテクチャ決定、フレームワークごとのポータビリティ監査、段階的な移行と実装計画を記録します。

---

## 1. 決定: ネイティブmacOS（`AppKit`）対Mac Catalyst

**決定:** 共有マルチプラットフォームフレームワーク（`MACOSX_DEPLOYMENT_TARGET = 12.0`、すべてのAppleシリコンMacとMonterey以降のIntel Macをサポート）の上に**ネイティブmacOSアプリケーション（`macosx` SDK、`AppKit`）**を構築します。**Mac Catalystは却下します。**

### なぜネイティブmacOSが勝つか

| 次元 | ネイティブmacOS（`macosx` / `AppKit`） | Mac Catalyst（`maccatalyst` / `UIKit`） |
|---|---|---|
| **静的Cライブラリ（`Compressor`）** | **すでにビルド済み。** `Compressor/library/`の10個の`.xcframework`バンドルすべてがユニバーサル`macosx`（`arm64` + `x86_64`、`-mmacosx-version-min=11.0`）スライスを運び、`./Compressor/build.sh --verify --all --platforms ios,simulator,macosx`で検証済み。 | **欠けている。** `maccatalyst`スライス（`-target <arch>-apple-ios15.0-macabi`）はゼロ。Mach-Oリンカは`MACOS`アーカイブを`MACCATALYST`バイナリにリンクすることを拒否する。Catalystは`Compressor`に4つ目のプラットフォームを追加し、10個のCライブラリ（`openssl`、`mariadb`、`postgres`、`freetds`、`libarchive`、`sqlite3`、`zint`、`libpng`、`bzip2`、`zlib`）をすべて再ビルドする必要がある。 |
| **コアエンジンのポータビリティ** | **90%完了。** Linuxヘッドレスポート（`MAD_LINUX.md`）はすでに`MAD.framework`からCore Dataを除去し、データベースドライバ（`MADDatabaseDriverRegistry`）とレポートエクスポーター（`MADReportExporterRegistry`）を分離し、`MADHeadlessDocument`、`MADSQLQueryCompiler`、`MADDesignerLayout`を導入した。 | 同じエンジンだが、`UIDocument`とiOSバックグラウンドタスクのライフサイクルに縛られる。 |
| **デスクトップの人間工学** | ネイティブ`NSDocument` / `NSDocumentController`（Finderダブルクリック、`Cmd+N`、`Cmd+O`、`Cmd+S`、`Cmd+Shift+S`、Recent Documents、ウィンドウ復元、`NSUndoManager`）、ネイティブスプリットビュー、ネイティブテーブル／アウトラインビュー、ネイティブ`PDFView` / `WKWebView`、標準macOSメニュー。 | ネストされたズーミング`UIScrollView` + `UICollectionView`セクション、iOSタブ／ナビゲーションバー、`UIPickerView`ホイール、iOSサンドボックスドキュメントブラウザ（`MADExplorer`）。AppleシリコンMacはすでに*Designed for iPad*でiPadビルドを実行する。 |
| **GitHub経由の配布** | クリーンなスタンドアロン`.app`バンドルを、GitHub Releases（`arm64` + `x86_64`）のダウンロード可能な`.dmg`と`.zip`としてパッケージ。 | Catalystプロビジョニングプロファイルとエンタイトルメントが必要で、App Store外配布の人間工学と合わない。 |

---

## 2. 静的ライブラリ監査（`Compressor`）

`Compressor`の10個のベンダーCライブラリすべてが、`-mmacosx-version-min=11.0`でユニバーサル`macosx`（`arm64` + `x86_64`）スライスをビルドします。

| ライブラリ | バージョン | `ios`（`arm64`） | `simulator`（`arm64` + `x86_64`） | `macosx`（`arm64` + `x86_64`） | 使用者 |
|---|---|:---:|:---:|:---:|---|
| `sqlite3` | 3.53.3 | はい | はい | はい | `MADSqlite3`、`MAD` |
| `zlib` | 1.3.2 | はい | はい | はい | `MAD`、`MADMySQL`、`MADPostgres`、`MADBarcodes` |
| `openssl` | 3.5.9 | はい | はい | はい | `MADTds`、`MADMySQL`、`MADPostgres` |
| `bzip2` | 1.0.8 | はい | はい | はい | `MAD` |
| `libpng` | 1.6.59 | はい | はい | はい | `MADBarcodes` |
| `libarchive` | 3.8.9 | はい | はい | はい | `MAD` |
| `freetds` | 1.4.27 | はい | はい | はい | `MADTds`、`MADTdsClient` |
| `mariadb` | 3.4.11 | はい | はい | はい | `MADMySQL` |
| `postgres` | 17.11 | はい | はい | はい | `MADPostgres` |
| `zint` | 2.16.0 | はい | はい | はい | `MADBarcodes` |

検証コマンド:

```sh
./Compressor/build.sh --verify --all --platforms ios,simulator,macosx
```


---

## 3. フレームワークごとのマルチプラットフォーム監査

12のフレームワークがマルチプラットフォームスタックを形成します（`iphoneos`、`iphonesimulator`、`macosx`、加えて12のヘッドレスフレームワークのためのLinux）。

1. **`MADFoundation`**（28の`.m`ファイル）:
   - `MADApplication.h`: `<UIKit/UIApplication.h>`を`#if __APPLE__`ではなく`#if TARGET_OS_IPHONE`でガードする（`MADApplication.m`はすでに`#elif TARGET_OS_OSX #import <AppKit/NSApplication.h>`を持つ）。
   - `MADURLFactory.m`: `<UIKit/UIScreen.h>`を`#if TARGET_OS_IPHONE`でガードし、`TARGET_OS_OSX`では`NSScreen.mainScreen.backingScaleFactor > 1.0`を使う。
   - `MADKeyChain.m`: `Security.framework`を使う。それはiOSとmacOSの両方でネイティブ。
2. **`MADDataStructures`**（17の`.m`ファイル）:
   - 純粋なFoundation + C++。ソース変更はゼロ。
3. **`MADFileManager`**（11の`.m`ファイル）:
   - `MADMetaDataLocal.m:16`の未使用`#import <MobileCoreServices/UTType.h>`を削除する（`<UniformTypeIdentifiers/UTType.h>`はすでに17行目でインポートされている）。
4. **`MADCocoaExtensions`**（17の`.m`ファイル）:
   - `CGGeometry+Extras.h`: `TARGET_OS_OSX`で`UIEdgeInsets`（`NSEdgeInsets`互換のレイアウト構造体 + `UIEdgeInsetsMake` / `UIEdgeInsetsZero` / `UIEdgeInsetsEqualToEdgeInsets`）、`NSStringFromCGPoint` / `NSStringFromCGSize` / `NSStringFromCGRect`、および`NSValue (MADCGGeometryExtensions)`（`valueWithCGPoint:`、`CGPointValue`、`valueWithCGRect:`、`CGRectValue`、`valueWithCGSize:`、`CGSizeValue`）を提供する。
   - `MADColor.h` / `MADColor.m`: `TARGET_OS_OSX`で`MADColor`を`NSColor`にブリッジし、`TARGET_OS_IPHONE`では`UIColor`を保つ。
   - iOS専用の`UIView`、`UIAlertController`、`UITextField`、`UIColor`カテゴリを`#if TARGET_OS_IPHONE`でガードする。
5. **`MADAPI`**（11の`.m`ファイル）:
   - 9つのコアデータベース、クエリ、ドライバレジストリファイルは純粋なFoundation。
   - `MADConnectionViewController`と`MADConnectionSQLGenericViewController`を`#if TARGET_OS_IPHONE`でガードする。
6. **`MADSqlite3`**（26の`.m`ファイル）:
   - 純粋なFoundation + `sqlite3.xcframework`。ソース変更はゼロ。
7. **`MADTds`**（1の`.m`ファイル）:
   - 純粋なFoundation + `freetds.xcframework` + `openssl.xcframework`。ソース変更はゼロ。
8. **`MADTdsClient`**（4の`.m`ファイル）:
   - `MADDatabaseSQLServer`、`MADTdsConnection`、`MADDataTypeSQLServer`は純粋なFoundation。`MADTdsConnectionViewController`を`#if TARGET_OS_IPHONE`でガードする。
9. **`MADMySQL`**（19の`.m`ファイル）:
   - 18のドライバファイルは純粋なFoundation + `mariadb.xcframework`。`MADMySQLConnectionViewController`を`#if TARGET_OS_IPHONE`でガードする。
10. **`MADPostgres`**（5の`.m`ファイル）:
    - 4のドライバファイルは純粋なFoundation + `postgres.xcframework`。`MADPostgresConnectionViewController`を`#if TARGET_OS_IPHONE`でガードする。
11. **`MADBarcodes`**（70の`.m`ファイル）:
    - 67のシンボロジクラスは純粋なFoundation + `zint.xcframework`。
    - `MADBarcode`、`MADBarcodeCache`、`MADBarcodeView`: 既存の`CGImageRef` `MADBarcodeImageFromZintBitmap`パイプライン上で、`TARGET_OS_OSX`で`UIImage` / `NSImage`と`UIView` / `NSView`をブリッジする。
12. **`MAD`**（199の`.m`ファイル）:
    - 9つの共有モデル／レンダリングファイル（`RptqObject.m`、`RptqDocumentElementImage+Extras.m`、`RptqDocument+Extras.m`、`RptqDocumentSection+Extras.m`、`RptqDocumentElement+Extras.m`、`MADPrintPageElement.m`、`MADElementStylizedText.m`、`MADFonts.m`、`MADReportExporterPDF.m`）にまたがる`#if __APPLE__`を`#if TARGET_OS_IPHONE`と`#elif TARGET_OS_OSX`のAppKitブリッジに置き換える。
    - `MADReportExporterPDF.m`では、`TARGET_OS_OSX`で`CGPDFContextCreateWithURL` / `CGPDFConsumerCreateWithCFData`と`NSGraphicsContext`（`+graphicsContextWithCGContext:flipped:YES`）を使ってページ分割PDFをレンダリングし、`MADPrintPageRenderer`と`MADPrintPageElement`がmacOSでネイティブに描画するようにする。
    - 22のiOS専用`UIDocument`（`MADocument`）、`UIView`、`UICollectionViewLayout`ファイルを`#if TARGET_OS_IPHONE`でガードする。

`MADExplorer`はiOS専用のままです（macOSは`NSDocumentController`、Finder、`NSOpenPanel`とプライマリの**New Document**ボタンを使います）。`MADFeedback`と`Scrimpter`は`AGENTS.md`により未使用のままです。

---

## 4. 段階的実装計画

### Phase 1: 不具合修正とマルチプラットフォームフレームワークの有効化（完了）

1. **macOS監査と移植で表面化した6つの不具合を修正**し、単体テストとともに`docs/project/BUGS.md`から`docs/project/BUGS_FIXED.md`へアーカイブしました。
   - `MADKeyChain`（`MADFoundation/Source/MADKeyChain.m`）: `+credentialsExist:`、`+saveToken:forKey:withDescription:`、`+deleteKey:`、`+deleteSavedPasswordForKey:error:`で`kSecReturnData : @YES`を要求すること（および返された`CFDataRef`をリークすること）を止めた。
   - `MADURLFactory`（`MADFoundation/Source/MADURLFactory.m`）: `[NSBundle mainBundle].bundleIdentifier`が`nil`のとき`+newURLForLocalApplicationSupportDirectory`をガードし（`[MADApplication groupIdentifier]`にフォールバック）、`containerURLForSecurityApplicationGroupIdentifier:`を`#if defined(__APPLE__) && TARGET_OS_IPHONE`でガードしたため、エンタイトルメントのないmacOSプロセスは`~/Library/Group Containers/`でTCCプロンプトをトリガーする代わりに標準のユーザーごとディレクトリを使う。
   - `MADDataTable`（`MADFoundation/Source/MADDataTable.m`）: `NSDataWritingFileProtectionCompleteUnlessOpen`を`#if defined(__APPLE__) && TARGET_OS_IPHONE`でガードし、エンタイトルメントのないmacOSキャッシュ書き込みが成功するようにした。
   - `MADDatabaseSqlite3`（`MADSqlite3/Source/MADDatabaseSqlite3.m`）: `[dataTable endBulkInsert]`を`if (rowCounter > 0)`でガードし、ゼロ行の`SELECT`クエリが`[dataTable beginBulkInsert]`が呼ばれていないのに`COMMIT TRANSACTION`を実行しないようにした。
   - `MADBarcode`（`MADBarcodes/MADBarcodes/MADBarcodes/MADBarcode.m`）: `self.center == YES`のとき`-drawInRect:`が`rect.origin`を二重化する不具合を修正した。
   - `MADDesignerLayout`（`MAD/Source/MADDesignerLayout.m`）: すべてのバルク更新メソッド（`setFontsize:`、`setFontname:`、`setVerticalAlignment:`、`setHorizontalAlignment:`、`setSizeWidth:`、`setSizeHeight:`、`setMargin*`、`setPadding*`、`setBorder*`）でundoアクションを登録するとき、各選択要素自身の以前の値を辞書に保存した。
2. **12のフレームワークXcodeプロジェクト全体で`macosx`を有効化:**
   - `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx"`と`MACOSX_DEPLOYMENT_TARGET = 12.0`を設定した。
   - `UIKit.framework`参照に`platformFilters = (ios, maccatalyst, );`を追加し、必要な場所で`AppKit.framework`を`platformFilters = (macos, );`でリンクした。
   - `Ensure Libraries`ビルドフェーズを`--platforms ios,simulator,macosx`を渡すように更新した。
3. **ネイティブmacOS（`-destination 'platform=macOS,arch=arm64'`）で12のフレームワークすべてを検証:**
   - `MADFoundation`: **199テスト合格、0失敗**
   - `MADDataStructures`: **72テスト合格、0失敗**
   - `MADCocoaExtensions`: **80テスト合格、0失敗**
   - `MADFileManager`: **85テスト合格、0失敗**
   - `MADAPI`: **106テスト合格、0失敗**
   - `MADSqlite3`: **118テスト合格（5ベンチマークスキップ）、0失敗**
   - `MADTds`: **`macosx`向けにクリーンにビルド**
   - `MADTdsClient`: **77テスト合格（ライブSQL Serverスイートを含む）、0失敗**
   - `MADMySQL`: **すべてのオフライン＆ライブMariaDB/MySQLテスト合格、0失敗**
   - `MADPostgres`: **31テスト合格（ライブPostgreSQLスイートを含む）、0失敗**
   - `MADBarcodes`: **30テスト合格、0失敗**
   - `MAD`: **650テスト合格、0失敗**

### Phase 2: マルチプラットフォームのスキーマインポートと`NSDocument`レイヤー（完了）

1. **マルチプラットフォームのドキュメント作成とスキーマインポート（`MADHeadlessDocument`）:**
   - `MADHeadlessDocument`（`MAD/Source/MADHeadlessDocument.h`、`.m`）に`+createDocumentAtURL:withDatabaseConnection:credentials:error:`を追加した。任意の登録ドライバ（`SQLite3`、`MySQL`、`SQL Server`、`PostgreSQL`）に接続し、すべてのデータベーステーブル（`-getTablesFromConnection:error:`）と列（`-fieldsForTable:connection:error:`）を`RptqDatabaseSchemaTable` / `RptqDatabaseSchemaField`にインポートし、標準レポートセクション（`Report Header`、`Page Header`、`Report Detail`、`Page Footer`、`Report Footer`）を初期化し、ポータブル`.mad`コンテナを書く。
2. **`MADMacDocument`（`Mac/Source/MADMacDocument.m`の`NSDocument`サブクラス）:**
   - `MADHeadlessDocument`をラップし（必要に応じて`MADStoreConverter`による自動レガシーCore Data `.mad`変換付き）、`MADocumentDesignerProtocol`に準拠して`MADDesignerLayout`がundo/redoを`NSDocument.undoManager`に直接記録できるようにし、`readFromURL:ofType:error:`、`writeToURL:ofType:forSaveOperation:originalContentsURL:error:`、非同期`refreshWithCredentials:maxRows:completion:`をサポートする。

### Phase 3: ネイティブmacOSアプリケーション（`Mac/`）（完了）

`Mac/`（`Mac/Source/`、`Mac/Resources/`、`Mac/Tests/`、`Mac/build.sh`）の下に構築され、**`MAD Designer Mac`**ターゲットと共有スキームを通じて`MAD Designer.xcodeproj`に統合されました。

1. **アプリケーションライフサイクル、Aboutウィンドウ、ドキュメントコントローラ（`MADMacAppDelegate`、`MADMacAboutWindowController`、`MADMacDocumentController`）:**
   - 4つのデータベースドライバすべてと`MADStoreLegacyConverter`を登録し、ネイティブmacOSメインメニュー（`MAD Designer`、`File`、`Undo`/`Redo`付き`Edit`、ワークスペースを`Cmd+1`/`Cmd+2`/`Cmd+3`で切り替える`View`、`Cmd+R`でリフレッシュする`Report`、`Window`、`Help`）を構築し、ドキュメントが開いていない状態で起動すると標準`NSOpenPanel`を提示する。
   - `MADMacAboutWindowController`はネイティブの**About MAD Designer**ウィンドウ（`MAD Designer → About MAD Designer`と`Help`メニュー項目）を提示し、エンジンのバージョン／ビルド（`MADMeta.plist`）とmacOSアプリケーションのバージョン（`CFBundleShortVersionString`）を別個の値として示し、著作権と予約済みブランド／アートワーク通知、**Source Code on GitHub**アクション、および3つのタブ付きセクションを持ちます。**Overview**（MADとは何か、4ステップのレポーティングワークフロー、サポートされるドライバ／バンド／エクスポーター）、**License & Notice**（MIT License、`NOTICE`、FreeTDSとMariaDB Connector/CのLGPL-3.0書面による再リンクの申し出）、**Acknowledgements**（16のサードパーティオープンソースコンポーネントすべての帰属と`Contents/Resources/Licenses/`にバンドルされた12の完全なライセンステキストを対にしたインタラクティブなサイドバー）。
   - `MADMacDocumentController`は`NSOpenPanel`をすべての`.mad` `UTType`識別子（`com.everydayapps.productivity.mad`と`com.thomason.report.mad`）で設定し、既存の`.mad`ファイルが決して暗く表示されないようにし、Openパネルの左下バーにプライマリの**New Document**ボタンを直接置く。
2. **データベース接続とスキーマインポートアシスタント（`MADMacConnectionWindowController`）:**
   - **SQLite**（`NSOpenPanel`経由のカスタム`.sqlite3`/`.db`ファイル）、**MySQL**、**Microsoft SQL Server**、**PostgreSQL**をサポートし、**Test Connection**、`MADKeyChain`のパスワード保存、**Create Document…**（`NSSavePanel`）を持つ。
3. **メインドキュメントウィンドウ（`MADMacWindowController`）:**
   - **Workspace**セグメントコントロール（**MAD Query**、**MAD Designer**、**MAD Viewer**）をウィンドウツールバーの中央に置く。
4. **MAD Queryワークスペース（`MADMacQueryViewController`）:**
   - 相互排他的な**Query Designer**と**SQL Query**ワークスペースモード（ワークスペースヘッダーバーで切り替え、ビジュアルクエリ設計と手動SQL入力が同時に表示されないようにする）。
   - **Query Designerモード**: `200px`の左側**Database Tables**リスト（`NSSplitViewDelegate`でスナップバックせずにユーザーがリサイズ可能で、ウィンドウリサイズ時は固定幅に保たれビジュアルキャンバスが代わりにリサイズされる）と、インタラクティブな右側ビジュアルキャンバス（`MADMacQueryCanvasView`）を対にする。スキーマテーブルをダブルクリックするとクエリに追加され（すべての`RptqQueryField`行を設定する）、ドラッグ・リサイズ可能なフローティングAppKitテーブルカード（`MADMacQueryTableCardView` + `MADMacQueryFieldTableView`）として表示され、トポロジカルなルート／子ヘッダー（`MTGraph`）でスタイルされ、あるテーブルカードのフィールドから別のカードのフィールドへドラッグするとデフォルトの**Left Outer Join**（`MADLinkTypeLeftOuterJoin`）が作成され、Bezierコネクタと結合型バッジ（`MADMacQueryLinksOverlayView`、iPadの`MADConnectorView`に一致）で描画される。ビジュアル結合コネクタをクリックまたは右クリックすると結合インスペクタポップオーバーまたはコンテキストメニューが開き、リンク型の変更、方向の入れ替え、リンクの削除ができる。ヘッダーポップオーバーは**Filters (WHERE)**、**Groupings (GROUP BY)**、**Arrange Tables**を提供する。
   - **SQL Queryモード**: 全幅のSQLステートメントエディタで、生成または入力されたSQLを表示し、検証、コンパイル、適用をサポートする（`MADSQLParser` + `MADSQLStatementResolver` + `MADSQLQueryCompiler`）。
5. **MAD Designerワークスペース（`MADMacDesignerViewController` + `MADMacDesignerCanvasView` + `MADMacDesignerMinimapView`）:**
   - **上部ワークスペースバー（高さ`38pt`）**: クリック可能でドラッグ可能なSF Symbol要素パレット項目（**Label**、**Data Field**、**Aggregate**、**Barcode**、**Image**、**Line**）、複数要素のクイック整列コントロール（`Left`、`Center`、`Right`、`Top`、`Middle`、`Bottom`）、**Size to Fit**、**Grid** / **Snap** / **Rulers**トグル、ワンクリック`100%`リセット付きの**Zoom**スライダーを提供する。
   - **ユーザーリサイズ可能な3ペインスプリットビュー（`NSSplitViewDelegate`）**: 左ナビゲータサイドバーはデフォルト`220pt`（`180–340pt`）、右インスペクタはデフォルト`260pt`（`220–380pt`）で、両サイドバーはユーザーのディバイダ調整を保ちながらウィンドウリサイズをまたいで幅を保つ。
   - **左サイドバー（ミニマップ + バンド + クエリフィールドブラウザ）:**
     - **インタラクティブなページ＆セクションミニマップ（`MADMacDesignerMinimapView`）**: 比例したレポートバンドを色分けストライプ、ライブのミニチュア要素ブロック、青いビューポート矩形で描画する。クリックまたはドラッグでバンドにジャンプして選択する。
     - **レポートバンドアウトライン**: すべてのレポートとグループセクションを要素数、高さ、ページブレークインジケータ付きで一覧する。ダブルクリックでバンドの可視性を切り替える。
     - **クエリフィールドブラウザ**: すべての`RptqQueryField`列のフィルタ可能なリスト（`NSSearchField`）。フィールドをキャンバスの任意のセクションバンドにドラッグ（またはダブルクリック）すると、バインドされた`RptqDocumentElementLabelDataField`を挿入する。
   - **中央のインタラクティブキャンバス（`MADMacDesignerCanvasView`）**: フリップされズーム可能な`NSView`キャンバスで、水平／垂直ルーラー、紙マージン、色分けセクションバンド、セクション高さドラッグハンドル、スマート整列ガイド、グリッドスナップ、マーキー選択、`Shift`クリック複数選択、8点リサイズハンドル、インラインのダブルクリックラベル編集、スマートな非重複要素配置（`-nextAvailableOriginInSection:forElementSize:`）、クロスセクションドラッグ＆ドロップ（`-moveElement:toSection:atOrigin:`）とライブのターゲットバンドハイライト、完全な`NSUndoManager`統合を持つ。
   - **右インスペクタサイドバー（明確に分割されスクロール可能）:**
     - **カード1（`1 · PAGE & SELECTED SECTION`）**: 用紙サイズ、選択バンドバッジ、バンド高（`pt`）と**Fit Height**ボタン、**Section Visible**、**Page Break After**。
     - **目立つビジュアルディバイダ + セクション2（`2 · SELECTED ELEMENT INSPECTOR`）**: 4つのグループ化されたインスペクタカード（クロスセクション移動ポップアップ、**Duplicate**、**Delete**付きの**Element & Band Assignment**、静的テキスト、クエリフィールドバインディング、集計関数とスコープ、通貨フォーマット、バーコードオプション付きの**Content & Data Binding**、フォントファミリ／サイズ、太字／斜体／下線／取り消し線、水平／垂直配置、テキスト／背景色付きの**Typography & Appearance**、`X`、`Y`、`W`、`H`が`rect.origin`と`dropPoint`の両方で同期され、ボーダー、パディング、マージン付きの**Position, Size & Box Model**）。
6. **MAD Viewerワークスペース（`MADMacViewerViewController`）:**
   - **上部ビューアツールバー（高さ`40pt`）**: **Page Size**ポップアップ（`MTPaper`標準用紙タイプ: `US Letter`、`US Legal`、`US Tabloid`、`A3`、`A4`、`A5`、`B4`、`B5`、`JIS B4`、`JIS B5`）、**Refresh**（`Cmd+R`）、**Zoom**コントロール（`-`、`100%`、`+`）、**Page Navigation**（`Previous`、`Page N of M`、`Next`）、**Print…**（`NSPrintOperation`経由の`Cmd+P`）、**Export…**（`Cmd+E`）。
   - **フレーム付きページ分割プレビュー（`PDFView`）**: ローカルSQLiteテーブルキャッシュ（`MADDataTableFast`）から選択された用紙サイズでページ分割PDFページをレンダリングし、ページシャドウと下部ステータスバー（`statusBarView`）でレンダリングページ数、キャッシュ行数、用紙寸法を表示する。
   - **マルチフォーマットエクスポート（`NSSavePanel`）**: 登録された7つのエクスポーターすべて（`PDF`、`HTML`、`HTML Flow`、`CSV`、`JSON`、`JSON Report`、`Plain Text`）をサポートするアクセサリフォーマットポップアップを設定し、保存パネルの許可ファイル拡張子を動的に更新する。

### Phase 4: ビルド、スモーク検証、GitHubリリースパッケージング（完了）

```sh
./Mac/build.sh --smoke-test --package
```


生成物:
- `Mac/build/MAD Designer.app`（12のフレームワークすべてとレガシーCore Data `.momd`モデルを埋め込み署名した、スタンドアロンのネイティブmacOSアプリバンドル）
- `Mac/build/MAD-Designer-macOS.zip`
- `Mac/build/MAD-Designer-macOS.dmg`

ネイティブmacOSアプリケーションの公開ユーザーおよび開発者ドキュメントは[`docs/macos.md`](../../macos.md)（スクリーンショットは`docs/assets/macos-native-mad-query.png`と`docs/assets/macos-native-mad-designer.png`）と[`Mac/README.md`](../../../../Mac/README.md)に公開されています。

### 継続的インテグレーション（完了）

`.github/workflows/macos.yml`はすべてのプルリクエストと`master`へのプッシュで実行されます。Compressor静的ライブラリをビルド（およびキャッシュ）し、ランナーから発見されたiPhoneシミュレータで`MADBarcodes`と`MAD`スイートを実行し、iOS `MAD Designer`スキームをビルドし、`./Mac/build.sh --smoke-test`を実行します。Aboutウィンドウはエンジンバージョン（`MADMeta.plist`、`v9.0 (r4433)`）とmacOSアプリケーションバージョン（`CFBundleShortVersionString`、`v0.7`）を別個の値として報告し、Windows AboutウィンドウのPhase 6f後の提示に一致します。

`macos-latest`はarm64ランナーで、`Mac/build.sh`は`platform=macOS,arch=arm64`向けにフレームワークをビルドします。最初の実行は3プラットフォーム向けのすべての固定サードパーティソースをダウンロードしてコンパイルします（およそ15〜40分）。後の実行はActionsキャッシュから`Compressor/library`を復元し、ensureステップはノーオペレーションです。freetdsレシピは`config.guess`/`config.sub`をSavannahから一度だけリトライなしで取得するため、ワークフローは最初に`Compressor/media`をシードします（ワークフローのコメント参照）。ビルド失敗ではない残差: libarchiveのconfigureステップがCompressorのbzip2インストールではなくSDKの`libbz2.tbd`を見つけました。`BZIP2_LIBRARY`は現代のCMakeの`FindBZIP2`が読むヒントではないからです。SDKライブラリは存在し、アプリはbzip2 xcframeworkを処理します。
