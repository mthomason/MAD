---
layout: default
title: MAD Designer for macOS
lang: ja-JP
---

# MAD Designer for macOS

**MAD Designer for macOS**は、Mobile Analytics Document（`.mad`）の作成、クエリ設計、レイアウト編集、データ更新、印刷、およびエクスポートを行うネイティブ`AppKit`デスクトップアプリケーション（`macosx` SDK、`MACOSX_DEPLOYMENT_TARGET = 12.0`）です。iOSアプリやヘッドレスエンジンを支えているものと同じファーストパーティのObjective-Cフレームワーク群およびユニバーサル静的Cライブラリ（`Compressor`）をリンクしています。

macOS上で作成または編集されたすべての`.mad`ファイルは、iPad/iPhoneアプリ、Linux上の`mad` CLI、および[`mad-action`](https://github.com/mthomason/mad-action) GitHub Actionとバイト単位で互換性があります。

---

## ワークスペース

開かれた各`.mad`ドキュメントはネイティブの`NSDocument`ウィンドウ（`MADMacDocument` / `MADMacWindowController`）で動作し、ウィンドウツールバー中央の**Workspace**セグメントコントロール（`Cmd+1`、`Cmd+2`、`Cmd+3`）によって3つのレポーティングステージを切り替えます：

### 1. MAD Query (`Cmd+1`)

![Database Tablesリスト、視覚的なテーブルカード、およびLEFT OUTER結合コネクタを表示するmacOS上のMAD Queryワークスペース](../assets/macos-native-mad-query.png)

**MAD Query**ワークスペース（`MADMacQueryViewController`）は、`RptqQuery`に保存されるリレーショナルクエリグラフを構築します。ワークスペースバーのトグルで、クエリの2つの排他的なビューを切り替えることができます：

* **Query Designer（ビジュアルグラフ）：**
  * **Database Tablesサイドバー：** ドキュメントのスキーマスナップショット（`RptqDatabaseSchemaTable`）にインポートされたすべてのテーブルをカラム数とともに表示し、現在クエリに参加しているテーブルにはチェックマークを付けます。任意のテーブルをダブルクリック（または**+ Add Table to Query**をクリック）するとキャンバスに追加されます。
  * **インタラクティブなリレーションシップキャンバス（`MADMacQueryCanvasView`）：** 各クエリテーブルを、ドットグリッドキャンバス上のドラッグおよびリサイズ可能なカード（`MADMacQueryTableCardView`）として描画します。ヘッダー色は`MTGraph`が計算したトポロジカルなルート／子関係に応じて色分けされます。
  * **ビジュアル結合コネクタ（`MADMacQueryLinksOverlayView`）：** あるテーブルカードのカラムから別のテーブルカードのカラムへドラッグすると結合（デフォルトは`LEFT OUTER`）が作成され、滑らかな3次ベジェ曲線、方向矢印、およびピル型バッジで描画されます。結合バッジをクリックまたは右クリックすると結合インスペクタポップオーバーまたはコンテキストメニューが開き、結合タイプ（`INNER`、`LEFT OUTER`、`RIGHT OUTER`、`FULL OUTER`、`CROSS`）の変更、結合方向の反転、またはリンクの削除が行えます。
  * **フィルタ、グループ化、自動レイアウト：** ヘッダーバーのポップオーバーから、**`WHERE`述語**（`Filters (WHERE)`）、**`GROUP BY`／ソート順**（`Groupings (GROUP BY)`——対応する`Group Header`および`Group Footer`レイアウトバンドを自動的に用意します）を編集でき、**Arrange Tables**でトポロジカルなカード自動配置を実行できます。
* **SQL Query（直接SQL入力と検査）：**
  * ビジュアルグラフから生成された決定論的なダイアレクト固有SQLを表示し、`SELECT`文を直接貼り付けたり編集したりできます。
  * 入力されたSQLを`MADSQLParser`、`MADSQLStatementResolver`、および`MADSQLQueryCompiler`を介して検証し、ポータブルな`RptqQuery`オブジェクトグラフへコンパイルするとともに、元のSQL文を`RptqQuery.sqlSourceText`に保持します。

---

### 2. MAD Designer (`Cmd+2`)

![Page & Section Minimap、Report Bands、Query Fields、バンド型デザインキャンバス、およびInspectorを表示するmacOS上のMAD Designerワークスペース](../assets/macos-native-mad-designer.png)

**MAD Designer**ワークスペース（`MADMacDesignerViewController`）は、ユーザーがリサイズ可能な3ペイン分割ビュー内でレポートのパラメトリックなバンドと要素をレイアウトします：

* **上部デザイナツールバー：**
  * **エレメントパレット：** 任意のセクションバンドへクリックまたはドラッグして、**Label**（ラベル）、**Data Field**（データフィールド）、**Aggregate**（集計）、**Barcode**（バーコード）、**Image**（画像）、または**Line**（線）を挿入します。
  * **整列とサイズ調整：** 複数要素の整列ボタン（`Align Left`、`Center`、`Right`、`Top`、`Middle`、`Bottom`）および**Size to Fit**。
  * **キャンバスコントロール：** **Grid**、**Snap**、**Rulers**の個別トグル、およびワンクリックで`100%`にリセットできる連続**Zoom**スライダー（`50%–250%`）。
* **左ナビゲータサイドバー：**
  * **Page & Section Minimap（`MADMacDesignerMinimapView`）：** すべてのレポートバンド、縮小表示された要素ブロック、および現在のスクロールビューポート矩形をリアルタイムの比率で俯瞰表示します。ミニマップ内をクリックまたはドラッグすると、任意のバンドへジャンプして選択できます。
  * **Report Bandsアウトライン：** `Report Header`、`Page Header`、任意の`Group Header` / `Group Footer`バンド、`Report Detail`、`Page Footer`、および`Report Footer`を、要素数、ポイント単位の高さ、改ページインジケータとともに一覧表示します。行をダブルクリックするとセクションの表示／非表示が切り替わります。
  * **Query Fieldsブラウザ：** クエリに含まれるすべての`RptqQueryField`カラムのフィルタリング可能なリストです。任意のフィールドをキャンバス上のセクションバンドへ直接ドラッグ（またはダブルクリック）すると、バインドされたデータフィールド要素（`RptqDocumentElementLabelDataField`）が作成されます。
* **中央インタラクティブキャンバス（`MADMacDesignerCanvasView`）：**
  * 水平・垂直のポイントルーラー、用紙マージンガイド、色分けされたセクションヘッダー（`RH`、`PH`、`GH`、`DTL`、`GF`、`PF`、`RF`）、およびセクションの高さをリサイズするための下部ドラッグハンドルを備えた、左上原点（flipped）でズーム可能な`NSView`キャンバスです。
  * マーキー選択（矩形範囲選択）、`Shift`クリックによる複数選択、8点リサイズハンドル、スマート整列ガイド、グリッドスナップ、ダブルクリックによるインラインテキスト編集、セクションをまたぐドラッグ＆ドロップ（`-moveElement:toSection:atOrigin:`）、および単一・一括プロパティ編集全体にわたる完全な`NSUndoManager`（`Cmd+Z` / `Cmd+Shift+Z`）のUndo/Redoをサポートしています。
* **右インスペクタサイドバー：**
  * **`1 · PAGE & SELECTED SECTION`：** 対象の**Paper**（用紙）サイズの設定、アクティブなバンドバッジの表示、**Fit Height**ボタン付きのセクション**Height (pt)**編集、ならびに**Section Visible**および**Page Break After**の切り替えを行います。
  * **`2 · SELECTED ELEMENT INSPECTOR`：** 要素が選択されているときに表示される4つのコンテキストカード：
    1. **Element & Band Assignment：** 要素を別のセクションバンドへ再割り当て、複製（`Cmd+D`）、または削除（`Delete`）します。
    2. **Content & Data Binding：** 静的テキスト、バインドするクエリカラム（`table.column`）、集計関数（`SUM`、`COUNT`、`AVG`、`MIN`、`MAX`、`STDDEV`、`VARIANCE`）とスコープ（`Report`または`Group`）、通貨フォーマット、またはバーコード体系（`zint`）を設定します。
    3. **Typography & Appearance：** フォントファミリー、ポイントサイズ、Bold / Italic / Underline / Strikethroughスタイル、水平・垂直テキスト整列、前景色、および背景の塗りつぶしを設定します。
    4. **Position, Size & Box Model：** 正確なポイント座標（`X`、`Y`、`W`、`H`）、枠線の幅／色、パディング、およびマージンを設定します。

---

### 3. MAD Viewer (`Cmd+3`)

**MAD Viewer**ワークスペース（`MADMacViewerViewController`）は、ライブデータソースに対してクエリを実行して更新し、結果セットをローカルのSQLiteテーブルキャッシュ（`MADDataTableFast`）にマテリアライズ（実体化）して、ページ分割されたレポートを描画します：

* **ビューアツールバー：**
  * **Page Sizeセレクタ（`MTPaper`）：** **US Letter**、**US Legal**、**US Tabloid**、**A3**、**A4**、**A5**、**B4**、**B5**、**JIS B4**、または**JIS B5**に合わせてレポートを即座に再ページ分割・再描画します。
  * **Refresh（`Cmd+R`）：** ドキュメントに登録されたデータベースドライバを介してクエリを実行し、`.maddb` / `.mdcache`コンパニオンSQLiteキャッシュを構築し、2パスのグループ化と集計を計算してページキャッシュを再構築します。
  * **ズームとページナビゲーション：** ズームアウト、`100%`へのリセット、ズームイン、およびページ送り（`Previous`、`Page N of M`、`Next`）。
  * **Print（`Cmd+P`）とExport（`Cmd+E`）：** `NSPrintOperation`によるネイティブ印刷、または登録されている全7種類のエクスポータを選択できるフォーマットピッカー付きの`NSSavePanel`を開きます：
    * **PDF Document (`.pdf`)** — `MADReportExporterPDF`によるネイティブCoreGraphics / AppKitベクターPDF
    * **HTML Page (`.html`)** — 絶対配置によるページ再現HTML（`MADReportExporterHTML`）
    * **HTML Flow (`.html`)** — レスポンシブでリフロー可能なセマンティックHTML（`MADReportExporterHTMLFlow`）
    * **CSV Spreadsheet (`.csv`)** — RFC 4180準拠の明細行エクスポート（`MADReportExporterCSV`）
    * **JSON Data (`.json`)** — スキーマ契約＋明細行データ（`MADReportExporterJSON`）
    * **JSON Full Report (`.json`)** — 階層化されたセクション、グループ、および評価済み要素（`MADReportExporterJSONReport`）
    * **Plain Text (`.txt`)** — 等幅テキストテーブル（`MADReportExporterText`）
* **フレーム付きページプレビューとステータスバー：** ネイティブ`PDFView`内にドロップシャドウ付きの鮮明なページを描画し、下部ステータスバーに描画済みページ数、キャッシュされた行数、および用紙寸法を表示します。

---

## ドキュメントのオープンと新規作成

* **起動とオープンパネル（`MADMacDocumentController`）：** ファイルを指定せずにアプリを起動すると、`.mad`ドキュメント（`com.everydayapps.productivity.mad`および`com.thomason.report.mad`）でフィルタリングされたmacOSの**Open Report**パネルが表示され、左下バーにはプライマリの**New Document**ボタンが配置されます。Finderで任意の`.mad`ファイルをダブルクリックすると、直接ワークスペースウィンドウで開きます。
* **レガシードキュメントの自動移行：** 古いCore Data形式の`.mad`アーカイブを開くと、`MADStoreConverter`によってストアがその場でポータブルSQLiteスキーマ（`MADStoreSchema`）へ自動変換されます。
* **データベース接続からの新規レポート作成（`Cmd+N`）：** **New Document**をクリック（またはメニューから**File → New Document…**を選択）すると、データベース接続アシスタント（`MADMacConnectionWindowController`）が開きます：
  * **SQLite**、**MySQL**、**Microsoft SQL Server**、または**PostgreSQL**を選択します。
  * ローカルの`.sqlite3` / `.db`データベースファイルを参照するか、サーバーのホスト、ポート、任意のSQL Serverインスタンス名、データベース名、ユーザー名、パスワードを入力します。
  * **Test Connection**をクリックして接続性を確認し、検出されたテーブル数を確認します。
  * **Create Document…**をクリックすると、データベースのテーブルおよびカラムスキーマが新しい`.mad`ファイルにインポートされ、**MAD Query**ワークスペースで開かれます。認証情報は`MADKeyChain`を介してmacOSキーチェーンに保存されます。

---

## アーキテクチャ：マルチプラットフォームフレームワーク上のネイティブ`AppKit`

iOSのUIをMac Catalystでラップするのではなく、MADは14個のフレームワークのうち12個を`macosx`向けにネイティブコンパイルし（`SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx"`、`MACOSX_DEPLOYMENT_TARGET = 12.0`）、その上に専用設計の`AppKit`ドキュメントアーキテクチャ（`Mac/Source/`）を構築しています：

| レイヤー | コンポーネント | macOSでの役割 |
|---|---|---|
| **静的Cライブラリ（`Compressor`）** | `sqlite3`, `zlib`, `openssl`, `bzip2`, `libpng`, `libarchive`, `freetds`, `mariadb`, `postgres`, `zint` | `.xcframework`バンドル内のユニバーサル（`arm64` + `x86_64`）`macosx`スライス。`./Compressor/build.sh --verify --all --platforms ios,simulator,macosx`で検証。 |
| **コア＆ドライバフレームワーク** | `MADFoundation`, `MADDataStructures`, `MADCocoaExtensions`, `MADFileManager`, `MADAPI`, `MADSqlite3`, `MADTds`, `MADTdsClient`, `MADMySQL`, `MADPostgres`, `MADBarcodes`, `MAD` | 共有Objective-Cモデル、ポータブルSQLiteストア（`Rptq*`）、SQLパーサー／コンパイラ、ワイヤデータベースドライバ、zintバーコードレンダラー、`MADDesignerLayout` Undo/Redoエンジン、および`MADPrintPageRenderer` / `MADReportExporterPDF`。 |
| **ネイティブ`AppKit`フロントエンド（`Mac/`）** | `MADMacAppDelegate`, `MADMacAboutWindowController`, `MADMacDocumentController`, `MADMacDocument`, `MADMacWindowController`, `MADMacConnectionWindowController`, `MADMacQueryViewController`, `MADMacDesignerViewController`, `MADMacDesignerCanvasView`, `MADMacViewerViewController` | ネイティブ`NSDocument`ライフサイクル、About / Overview / Acknowledgementsウィンドウ、ツールバー＆メニューバー、ビジュアルクエリキャンバス、ミニマップ＆インスペクタ付き3ペインレポートデザイナー、および`PDFView`レポートビューア。 |

マルチプラットフォーム移植におけるアーキテクチャ監査および不具合修正ログの詳細は、[`docs/project/MAD_MACOS.md`](https://github.com/mthomason/MAD/blob/master/docs/project/MAD_MACOS.md)に記録されています。

---

## ビルド、テスト、パッケージ化

### Xcodeでのビルド

`Reports.xcworkspace`を開き、共有スキーム**`MAD Designer Mac`**とデスティネーション**My Mac**を選択して**Run (`Cmd+R`)**を押すと、ネイティブmacOSアプリをインタラクティブにビルドしてデバッグできます。

任意のフレームワークのユニットテストスイートをmacOS上でネイティブ実行するには、以下を実行します：

```sh
xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
	-destination 'platform=macOS,arch=arm64' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
```

### コマンドラインビルド、スモークテストスイート、リリースパッケージ作成

スタンドアロンスクリプト`Mac/build.sh`は、macOS向け全12フレームワークのコンパイル、`Mac/build/MAD Designer.app`のアセンブルと署名、エンドツーエンドのヘッドレス＋AppKitスモークテストスイート（`Mac/Tests/MADMacSmokeTest.m`）の実行、および配布用`.zip`／`.dmg`アーカイブのパッケージ化を行います：

```sh
./Mac/build.sh                     # build 12 macOS frameworks + MAD Designer.app
./Mac/build.sh --no-frameworks     # rebuild only MAD Designer.app (fast iteration)
./Mac/build.sh --smoke-test        # build and run the end-to-end macOS smoke suite
./Mac/build.sh --package           # package MAD-Designer-macOS.zip and MAD-Designer-macOS.dmg
```
