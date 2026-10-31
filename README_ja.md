[English](README.md) | [简体中文](README_zh.md) | **日本語**

# MAD (Mobile Analytics Document)

**リレーショナルレポーティングのためのオープンフォーマットおよび組み込み可能なエンジン——すべてのレポートは、ポータブルなクエリグラフ、マテリアライズドSQLiteテーブル、そしてパラメトリックレイアウトとして表現されます。**

MADは、アドホッククエリ、レポーティング、およびレポート設計のためにObjective-Cで一から構築されたリレーショナルレポーティングプラットフォームです。クエリとレイアウトを視覚的に、またはSQLから構築できるiOSおよびネイティブmacOS（`AppKit`）向けの**MAD Designer**アプリ、レポートの閲覧・更新を行う**MAD Viewer**アプリ、LinuxおよびmacOS上で動作するヘッドレスな**`mad` CLIおよびエンジン**、そしてオープンな**`.mad`仕様**で構成されています。

`.mad`ファイルは、データベースのスキーマスナップショット、リレーショナルクエリグラフ（テーブル、結合、述語、グループ化）、およびバンド型レイアウトツリーというレポート定義全体を、表示対象のデータから明確に分離したまま100 KB未満の単一ファイルに保持します。レポートはサーバーではなく実行可能なファイルです。`.mad`を解釈できるランタイムであれば、スキーマを検査し、対象データベース向けの決定論的SQLをコンパイルし、結果セットをローカルのSQLiteテーブルにマテリアライズ（実体化）したうえで、ネイティブのAppKit/UIKitビュー、ページ分割HTML、PDF、CSV、またはJSONとして描画・出力できます。

本リポジトリは自己完結した単一プロジェクトです。iPad/iPhoneアプリ、ネイティブmacOS（`AppKit`）デスクトップアプリ（`Mac/`）、14個のフレームワーク（うち12個はiOS、iOSシミュレータ、ネイティブmacOS対応のマルチプラットフォーム、11個はLinux上でヘッドレス動作）、ヘッドレスLinuxビルドおよびテストスイート（テスト実行ファイル126個、テスト1,303件）、`mad`コマンドラインツール、およびピン留めされたソースからサードパーティ製Cライブラリをコンパイルするビルドシステム（`Compressor`）を含んでいます。コードはMITライセンスの下で公開されており、`.mad`フォーマットはオープン仕様です（[`docs/`](docs/ja/)を参照）。ただし、プロジェクト名およびアプリのアートワークはライセンス供与の対象外です（[`NOTICE`](NOTICE)を参照）。

[![Linux verification](https://github.com/mthomason/MAD/actions/workflows/linux.yml/badge.svg)](https://github.com/mthomason/MAD/actions/workflows/linux.yml)

## なぜMADなのか

今日では、どの開発者もLLMに頼めば10分で使い捨てのSQLスクリプトとReactテーブルを生成できます。しかし半年後には、40個の個別ミニアプリ、`customers`と`invoices`の`INNER JOIN`に対する40通りの非互換な定義、ハードコードされたデータベース認証情報、ハルシネーションによる誤った集計ロジックが乱立し、モバイル、デスクトップ、CIパイプライン、外部パートナー間の相互運用性はゼロになります。

MADはレポーティングの課題を**フォーマットとエンジンのレベル**で解決します：

* **共有された契約による相互運用性。** アドホックなSQLやUIグルーコードを個別スクリプトに散在させる代わりに、`.mad`ドキュメントはスキーマ契約、クエリAST、およびプレゼンテーションレイアウトを、検査可能・diff可能・バージョン管理可能な1つのアーティファクトにパッケージ化します。同じ80 KBのファイルをmacOSやiPadでネイティブに開き、Linux Dockerコンテナでヘッドレス実行し、GitHub Actionsで実行し、あるいは別のアプリケーションに組み込むことができ、AppleとLinuxの間でバイト単位で同一のSQLとエクスポート結果を生成します。
* **決定論的SQLと2パスのローカル集計計算。** エンドユーザーもAIモデルも、ダイアレクト固有のSQLを手書きしたりアプリケーションコード側で合計を計算したりする必要はありません。エンジンがドキュメントのスキーマスナップショットに対してクエリグラフを検証し、ワイヤドライバ向けの決定論的SQLをコンパイルし、結果セットを一度だけローカルSQLite行キャッシュ（`MADDataTableFast`）に取り込み、グループ化・ソートキー・ヘッダー／フッター集計をローカルの2パス処理で計算します。
* **寄せ集めではなく、一からの自社実装。** SQLジェネレータ、SQLパーサー、データテーブルエンジン、ポータブルストア、レイアウトモデル、およびページレンダラーは、14個のフレームワークにわたるファーストパーティのObjective-C実装です。サードパーティ製コードは通信層のワイヤライブラリ（MariaDB Connector/C、FreeTDS、`libpq`、SQLite）と、アーカイブ用の`libarchive`/`bzip2`およびバーコード用の`zint`のみに厳格に限定されています。プロプライエタリなレポーティングSDKの再販ではありません。
* **モバイルファースト＝メモリ予算を考慮した設計。** 結果セットはディスク上のインデックス付きSQLiteテーブルにマテリアライズされ、ページはジオメトリをキーとするキャッシュにフォーマットされるため、スマートフォンや小さなコンテナでもデータセット全体をRAMに保持することなく数十万行規模のレポートをページ分割・集計できます。

技術ドキュメントおよびフォーマット仕様書は<https://docs.everydayapps.com>でも公開されています。

## 実際の動作を見る

**[MAD Designer for macOS](docs/ja/macos.md)**——**MAD Query**のビジュアルリレーションシップキャンバスと**MAD Designer**のバンド型レイアウトワークスペースを備えたネイティブ`AppKit`デスクトップアプリケーション（`Mac/`）：

![ネイティブmacOSアプリケーションのMAD Queryワークスペース](docs/assets/macos-native-mad-query.png)

![ネイティブmacOSアプリケーションのMAD Designerワークスペース](docs/assets/macos-native-mad-designer.png)

**MAD Designer for iOS**——データソースの選択からMAD Viewerで完成したレポートを閲覧するまで（28秒、[動画](https://docs.everydayapps.com/assets/app-preview.mp4)）：

[![MAD Designerアプリプレビュー](docs/assets/app-preview-poster.png)](https://docs.everydayapps.com/assets/app-preview.mp4)

**Linux上でヘッドレス動作する同一エンジン**：レポーティングサーバーなしで、`mad` CLIから`inspect`、`schema`、`query`、`refresh`、`export`を実行：

![.madドキュメントの検査、クエリ確認、更新、エクスポートを行うmad CLI](docs/assets/mad-cli-demo.gif)

録画内で生成された[エクスポート済みレポート](https://docs.everydayapps.com/assets/london.html)はプレーンなHTMLであり、任意のブラウザで開くことができます。

## `.mad`フォーマットの内部構造

`.mad`ファイルはPDFのような静的な印刷物でもなければ、行データのダンプでもありません。データベース接続を型付きテーブルとフォーマット済みビューに変換する**宣言的プログラム**です。

このアーキテクチャでは、レポートを**ポータブルな定義**（`.mad`ファイル内部、通常15〜80 KB）と**派生コンパニオンキャッシュ**（更新時にローカルで生成され、いつでも破棄可能）に分離しています：

| レイヤー | ファイル／メンバ | フォーマット | 役割 |
|---|---|---|---|
| **1. コンテナ** | `<Name>.mad` | 16バイトの`MADFILE\0` v1ヘッダー + `pax restricted` bzip2 tarアーカイブ | コンテンツから識別可能な外装アーカイブ（v0は`tar xjf`互換、v1はヘッダー＋bzip2 tar）。 |
| **2. 定義ストア** | `StoreContent/analyitics` | ポータブルSQLite（`MADStoreSchema`、`PRAGMA user_version`でバージョン管理） | `Rptq*`オブジェクトグラフを保持：インポートされたデータベーススキーマスナップショット、クエリグラフ（テーブル、エイリアス、結合、述語、グループ化、および任意の`sqlSourceText`）、ならびにバンド型セクション／要素レイアウトツリー。Core DataやAppleへの依存はゼロ。 |
| **3. メタデータ＆プレビュー** | `meta.plist`, `AdditionalContent/` | XMLプロパティリスト + 任意の`thumbnail@2x.png` | ジェネレータのメタデータ、フォーマットバージョン、および任意のドキュメントプレビュー画像。 |
| **4. マテリアライズドテーブル** *(コンパニオン)* | `<hash>.maddb` + `<hash>.mdcache` | SQLite行データベース（`t<tag>`）+ カラムスキーマplist（`MADDataColumn`） | **データベーステーブルとしてのレポート出力。** 取得した行、グループキーインデックス、およびカラム型メタデータを保持し、2パス集計（`SUM`、`COUNT`、`AVG`、`MIN`、`MAX`）、ソート、再描画時にリモートデータベースへの再クエリを一切発生させません。 |
| **5. ページキャッシュ** *(コンパニオン)* | `<hash>{ih,lh}{w,h}.madac` | ページジオメトリをキーとするSQLiteインデックス（`ih`）およびレイアウト（`lh`）データベース | 対象ビューポート（例：US Letterの`{612, 792}`）向けに事前計算された改ページ位置と要素フレームを保持し、瞬時のスクロールとエクスポートを実現します。 |

コンテナレイアウト、ストアテーブル、コンパニオンスキーマ、既知の癖（後方互換性のために内部ストアファイル名が歴史的に`analyitics`と綴られている理由など）、およびクロスプラットフォームのダイジェスト検証を含む完全な仕様は、[`docs/`](docs/ja/)にて章ごとに文書化されています。

## MADの今後の方向性：ロードマップとビジョン

MADはすでに**クエリグラフ**、**マテリアライズドSQLite結果テーブル**、および**プレゼンテーションレイアウト**を分離しているため、このアーキテクチャによって次の4つの主要機能が実現可能となり、現在設計と実装キューが進められています（[`docs/vision.md`](docs/ja/vision.md)、[`docs/project/MAD_DATA_OBJECT.md`](docs/project/MAD_DATA_OBJECT.md)、および[`docs/project/TODO.md`](docs/project/TODO.md)を参照）：

1. **アドホックなデータベーステーブルとしての`.mad`レポート（コンポーザブルなデータオブジェクト）。**
   従来のデータベースでは、`employee`や`sales_data`のようなベーステーブルから`SELECT`します。`.mad`レポートは複数のテーブルを結合・フィルタリングし、その出力（`.maddb` + `.mdcache`）はすでに型付きスキーマ（`MADDataColumn`）を持つ物理的なSQLiteテーブルになっています。クエリデザイナー内でレポートの出力をテーブルソースとして指定可能にすることで、**`.mad`ファイル自体が仮想／マテリアライズドデータベーステーブルになります**。他のレポート、クエリ、またはツールから、データベース内の通常のテーブルとまったく同じように`.mad`レポートに対して`SELECT`や`JOIN`を行えるようになります。
2. **単一レポート内の複数データソース（サーバー不要のフェデレーション）。**
   各データベースドライバ（`MADMySQL`、`MADPostgres`、`MADTdsClient`、`MADSqlite3`）は、クエリ結果を同一のローカルSQLiteテーブル表現（`MADDataTableFast`）にマテリアライズします。1つのレポートが複数のクエリオブジェクトを保持し、それぞれのマテリアライズされた出力をローカルテーブルとして扱えるようになれば、単一の`.mad`レポート内でPostgreSQLの`customers`テーブル、SQL Serverの`orders`テーブル、およびローカルのSQLiteテーブルを結合できるようになります——中間に重厚なフェデレーションサーバーを置くことなく、SQLite上でローカルにフェデレーションが完結します。
3. **紙のパラダイムを超えて：ネイティブUIKit＆インタラクティブデータビュー。**
   バンド型ページレイアウト（Report Header、Page Header、Group Headers/Footers、Detail、Page/Report Footer）は紙への印刷から生まれました。MADにおいて、紙のページ分割はドキュメントのデータオブジェクトに対する**1つのビューパラダイム**へと進化します。印刷やページ再現エクスポートを行わない場面では、同じレイアウトとローカルの`.maddb`テーブルがリッチでインタラクティブなネイティブUIKitコンポーネントや生データ探索ビューを駆動します——一度設計すれば、ページ分割された紙面としてもネイティブのインタラクティブUIとしても描画できます。
4. **レガシーなCrystal Reports（`.rpt`）およびエンタープライズレポートファイルから`.mad`への変換。**
   何千もの企業が今なお何十年分ものCrystal Reports（`.rpt`）ファイルに縛られており、手作業で書き直したい人はおらず、最新のSaaSダッシュボードでもきれいにインポートできません。MADはCrystal Reportsと同じ伝統的な「バンド型セクション＋リレーショナルクエリグラフ」のDNAを共有しつつ、すべてをオープンで検査可能なSQLite-in-tar形式で保存するため、レガシーな`.rpt`定義をオープンな`.mad`ファイルへ直接変換するインポータの構築を進めています。

## 試してみる

ヘッドレスエンジンはDocker内で`mad` CLIを実行します。公開されているイメージをpullし、リポジトリにコミットされているサンプルドキュメントの1つを検査してみてください：

```sh
docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro ghcr.io/mthomason/mad \
    mad inspect /docs/London.portable.mad
```

すべてのサブコマンド（verb）が同じ方法で動作します——`schema`、`query`、`refresh`、`export`（ページ再現HTMLおよびリフロー可能な`html-flow`、プレーンテキスト、CSV、JSONデータ契約、および`json-report`に対応。PDFはApple上でネイティブ動作し、Linuxでは設計上対象外としています）：

```sh
docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro ghcr.io/mthomason/mad \
    mad refresh /docs/Music.portable.mad
docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro -v "$PWD/out":/out ghcr.io/mthomason/mad \
    mad export /docs/London.portable.mad --format html --out /out/london.html
```

公開されているタグは`latest`およびコミットの短縮SHAであり、`master`へのpushごとに公開ワークフローによって`linux/amd64`向けにビルドされます。Appleシリコン環境では`--platform linux/amd64`を追加してください（Docker Desktopがエミュレーション下でタグを実行します。フラグがない場合は`no matching manifest`でpullに失敗します）。ローカルでネイティブ`arm64`イメージ（`mad-cli:latest`）をビルドし、クロスプラットフォーム検証スイート全体を実行するには、次の1コマンドを実行します：

```sh
./Linux/build.sh --verify                 # build the toolchain and run the checks (~20 min first time)
```

サンプルドキュメントはイメージ内に同梱されているSqlite3サンプルデータベースに対して更新（リフレッシュ）されます。MySQL、SQL Server、およびPostgreSQLのフィクスチャは[`docs/project/DEVELOPER.md`](docs/project/DEVELOPER.md)に記載されているテストサーバーを前提としています。

## CIでの利用

[mad-action](https://github.com/mthomason/mad-action) GitHub Actionを使うと、リポジトリにコミットされた`.mad`をワークフロー内で実行し、そのエクスポート結果をアーティファクトとしてアップロードできます：

```yaml
- uses: mthomason/mad-action@v1
  with:
    command: export
    document: reports/sales.mad
```

このActionは公開イメージを実行するため、ActionとCLIは同一のエンジンです。Actionは本リポジトリの[`satellites/mad-action/`](satellites/mad-action/)から生成されており、[`docs/project/SATELLITE_REPOS.md`](docs/project/SATELLITE_REPOS.md)にサテライトリポジトリを最新に保つ仕組みが記録されています。

## データベースドライバ

MADは`MADDatabase`のサブクラスを介してデータベースと通信します。現在、4つのドライバが同梱されています：

* **MySQL / MariaDB** — `MADMySQL`（MariaDB Connector/Cベース）
* **SQL Server** — `MADTdsClient`（FreeTDSベース）
* **PostgreSQL** — `MADPostgres`（`libpq`ベース）
* **SQLite** — `MADSqlite3`（サンプルドキュメント、ローカルデータベース、および内部マテリアライズテーブル用）

ドライバは`MADDatabase`をサブクラス化し、`MADDatabaseDriverRegistry`に自身を登録するフレームワークです。クエリデザイナーやエンジンがワイヤプロトコルを直接意識することはありません。新しいドライバの作成は最初のコントリビューションとして推奨されています（[`docs/tutorials/driver-authoring.md`](docs/ja/tutorials/driver-authoring.md)のドライバ作成チュートリアルを参照）。この拡張ポイント（seam）は明確に分離されており、ユーザーが視覚的にクエリを構築するかSQLを貼り付ける（`MADSQLParser`）と、エンジンがダイアレクト固有のSQL文を生成し、ドライバはそれを実行して`id<MADDataTableWriting>`へ行をストリーム書き込みするだけで完結します。

## エンジンの組み込み

14個のフレームワークのうち11個はUIKitに依存せず、ヘッドレスでビルドできます。上記の`mad` CLIはそのエンジンにコマンドラインインターフェースを被せたものにすぎません。サブコマンド群——`inspect`、`schema`、`query`、`refresh`、`export`、`write`——がそのまま組み込み用のインターフェースに対応しており、`MAD`、ドライバフレームワーク、および`MADSqlite3`をリンクしたアプリケーションは、サーバーを一切介さずにリレーショナルレポーティング機能を利用できます。ドライバおよびエクスポートフォーマット（`<MADReportExporting>` / `MADReportExporterRegistry`）は自己登録方式であるため、データソースや出力フォーマットの追加はフォークではなくサブクラス化だけで行えます。

## ネイティブmacOSアプリケーション

ネイティブmacOSデスクトップアプリ（[`docs/macos.md`](docs/ja/macos.md)、[`Mac/`](Mac/)）は、12個のマルチプラットフォームMADフレームワークと`Compressor`でコンパイルされた10個のユニバーサル（`arm64` + `x86_64`）静的Cライブラリの上に、`AppKit`（`macosx` SDK、`MACOSX_DEPLOYMENT_TARGET = 12.0`）で直接構築されています：

* **ネイティブ`NSDocument`アーキテクチャ（`MADMacDocument` / `MADMacDocumentController`）：** Finderまたは標準のオープンパネル（統合された**New Document**ボタン付き）から`.mad`アーカイブをネイティブに開いて保存し、`MADStoreConverter`を介してレガシーなCore Data形式の`.mad`ファイルを自動移行し、`MADDesignerLayout`を`NSDocument.undoManager`（`Cmd+Z` / `Cmd+Shift+Z`）と直接統合します。
* **データベース接続＆スキーマインポートアシスタント（`MADMacConnectionWindowController`）：** **SQLite**、**MySQL / MariaDB**、**Microsoft SQL Server**、または**PostgreSQL**に接続して疎通を確認し、認証情報をmacOSキーチェーン（`MADKeyChain`）に保存し、テーブルおよびカラムスキーマを新しい`.mad`ドキュメントにインポートします。
* **3つの統合ワークスペース**（`Cmd+1`、`Cmd+2`、`Cmd+3`）：
  1. **MAD Query（`MADMacQueryViewController`）：** インタラクティブな**Query Designer**（ドラッグ可能なテーブルカード、クリック可能な結合タイプバッジ付きのベジェ結合コネクタ、`WHERE`フィルタおよび`GROUP BY`ポップオーバー）と、**SQL Query**エディタ（`MADSQLParser` + `MADSQLQueryCompiler`）を切り替えます。
  2. **MAD Designer（`MADMacDesignerViewController`）：** インタラクティブな**Page & Section Minimap**、**Report Bands**アウトライン、検索可能な**Query Fields**ドラッグソース、セクション間ドラッグ＆ドロップとスマート整列ガイドを備えたズーム・ルーラー付きデザインキャンバス（`MADMacDesignerCanvasView`）、および2カード構成の**Page & Element Inspector**を備えた3ペイン分割ビューです。
  3. **MAD Viewer（`MADMacViewerViewController`）：** ライブデータの更新（`Cmd+R`）、即座の**Page Size**再ページ分割（`US Letter`、`Legal`、`Tabloid`、`A3`、`A4`、`A5`、`B4`、`B5`、`JIS B4`、`JIS B5`）、フレーム付き`PDFView`プレビュー、ネイティブ`NSPrintOperation`印刷（`Cmd+P`）、および**PDF**、**HTML**、**HTML Flow**、**CSV**、**JSON**、**JSON Full Report**、**Plain Text**へのエクスポート（`Cmd+E`）を提供します。

完全なガイドは[`docs/macos.md`](docs/ja/macos.md)を、マルチプラットフォーム移植の監査記録は[`docs/project/MAD_MACOS.md`](docs/project/MAD_MACOS.md)を参照してください。

## ビルドとテスト

ワークスペース（`Reports.xcworkspace`）は、14個のフレームワーク、iOSアプリ、およびネイティブmacOSアプリ（`MAD Designer Mac`）をビルドします。

### ネイティブmacOS

リポジトリルートからビルド、エンドツーエンドのスモークテストスイート実行、および`.zip`／`.dmg`リリースアーティファクトのパッケージ化を行います：

```sh
./Mac/build.sh                     # build 12 macOS frameworks + Mac/build/MAD Designer.app
./Mac/build.sh --no-frameworks     # rebuild only MAD Designer.app (fast iteration)
./Mac/build.sh --smoke-test        # build and run the end-to-end macOS smoke suite
./Mac/build.sh --package           # create Mac/build/MAD-Designer-macOS.zip and .dmg
```

また、Xcodeで共有スキーム**`MAD Designer Mac`**を使ってインタラクティブにビルド・デバッグしたり、任意のフレームワークのユニットテストスイートをmacOS上でネイティブ実行したりすることもできます：

```sh
xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
	-destination 'platform=macOS,arch=arm64' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
```

### iOSシミュレータ

iOSシミュレータに対してフレームワークのテストスイートを実行します：

```sh
xcodebuild test -workspace Reports.xcworkspace -scheme MADFoundation \
	-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
```

（`MADMySQL`、`MADTdsClient`、および`MADPostgres`には実際のデータベースサーバーと通信するライブテストスイートも含まれており、サーバーに到達できない場合は自動的にスキップされます——[`docs/project/DEVELOPER.md`](docs/project/DEVELOPER.md)を参照してください。）

### Linux（ヘッドレスエンジン＆CLI）

ヘッドレスエンジンはLinux上でも同じ方法で検証されます。Dockerがインストールされた環境で、リポジトリルートから以下を実行します：

```sh
./Linux/build.sh       # build the toolchain image, compile the eleven frameworks, run the suites
```

これによりコンテナ内で126個のテスト実行ファイルと1,303件のテストが実行され、`--verify`を付けるとコミット済みフィクスチャとその固定ダイジェストに対するCLIのエンドツーエンド検証が追加実行されます。イメージ、ピン留めされたバージョン、および移植時に判明したGNUstepとの差異については[`Linux/README.md`](Linux/README_ja.md)を参照してください。

## サポート

MADはフリーソフトウェアであり、今後もフリーであり続けます。メンテナンスは1人のメンテナによって行われており、設計ドキュメント、2プラットフォームのテストマトリクス、およびエージェント駆動の開発にはすべて実時間とAPIトークンが費やされています。もしMADによってチームの時間が節約できたなら、以下のような形でご支援いただけると幸いです（もちろん、そのままお使いいただくだけでも感謝いたします）：

* **[メンテナをスポンサーする](https://github.com/sponsors/mthomason)** — GitHub Sponsorsでの1回限りまたは毎月のスポンサー。
* **APIクレジットの提供。** 本プロジェクトはAIエージェントを活用して開発されており、OpenAI、Anthropic、またはエージェントトークンのクレジットはそのまま開発作業に還元されます。スポンサーページまたはIssueからご連絡ください。
* **[コントリビュートする](CONTRIBUTING_ja.md)。** データベースドライバ、ドキュメント要素、エクスポートフォーマット、レガシーインポータ、またはバグ修正——拡張ポイント（seam）はそのために用意されています。

## ライセンス

MIT — [`LICENSE`](LICENSE)を参照してください。ライセンスはソフトウェアのコードをカバーしますが、「MAD」「MAD Designer」「MAD Viewer」という名称、アプリアイコンおよびその他の製品アートワーク、ならびにアプリプレビューメディアは著作者に帰属し、ライセンスの対象外です（[`NOTICE`](NOTICE)を参照）。すべてのサードパーティ製コンポーネント、そのライセンス、および同梱・配布に伴う義務については[`docs/project/THIRD_PARTY_LICENSES.md`](docs/project/THIRD_PARTY_LICENSES.md)に記録されています。

## 輸出コンプライアンス

MySQL、FreeTDS、およびPostgreSQLドライバはOpenSSL/TLSを使用しており、独自暗号は実装していません。Appleの輸出コンプライアンスガイドラインにおいてこれは免除対象の暗号化に該当するため、アプリでは`ITSAppUsesNonExemptEncryption = NO`を設定しています。
