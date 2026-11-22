---
layout: default
title: "Linuxでのエンジンビルド"
description: "Dockerビルド、12のヘッドレスフレームワーク、およびそれらのスイート。"
lang: ja-JP
---

# LinuxでのMADエンジンのコンパイル — 技術評価

このページはLinuxビルドを記録します。Dockerイメージ、固定されたツールチェーン、12のヘッドレスフレームワーク、およびそれらが実行するスイートです。日常的なコマンドは`Linux/README.md`にあります。

*元の日付に書かれ、現状の事実は2026-11-22に整合。*

2026-10-04、`master`の`c807eeb4d`に対して書かれました。このドキュメントが依拠する依存監査（§4）とエコシステム調査（§5-6）はどちらも同じ日に作成されました。監査はすべてのフレームワークのソースディレクトリをgrepし、調査は一次資料（リリースノート、パッケージリポジトリ、プロジェクトのメーリングリスト）から行いました。証拠が薄い場合はそう述べています。このドキュメントは、プラットフォームマトリックスをスケッチした`MAD_FUTURE.md` §5.1の技術的コンパニオンです。これがその深掘りです。

---

## 1. 問いへの答え

これはLinuxでコンパイルできるか? **はい、条件付きで——両方の意味で。**

- コンパイルしなければならないコード——ヘッドレスエンジン——は、測定によれば、すでにApple依存をほぼ免れています。残る2つ（Core DataとUIKit/CoreGraphics）は移行中かファイル単位で列挙されており、どちらもリフレッシュパス上にありません。
- それをホストしなければならないエコシステム——Linux上のFoundation付きObjective-C——は存在し、すべての主要ディストリビューションでパッケージ化され、今日実際のグループウェアサーバー（SOGo、DebianがGNUstep Base 1.31.1に対してパッケージ）を運用しています。ニッチであり、モダンAPIのカバレッジは周辺で未検証であり、UIKitの話は存在しません——しかしこのコードベースはLinuxでUIKitを必要としません。エンジンを必要とします。

2つのアスタリスク: **GNUstepのFoundationは存在するが未検証**であり、このコードが最も強く依存するAPI（`NSPredicate`/`NSExpression`、キー付きアーカイブ、`NSURLSession`）についてそうです。そして**Linuxに現実的なUIKitは存在しません**——これは問題ありません。監査はコードがすでにUIKitを名指しされたファイルに閉じ込めており、レンダリング計画がとにかくUIKitから離れるからです。

---

## 2. 2製品の問い: 書き換えるか、コンパイルして呼ぶか

ユーザーが提起した選択: すべてをPythonで書き換えて2つの製品を維持するか、一度コンパイルしてPythonがエンジンを呼ぶか。監査がそれを決着させます。

**エンジンは大きい。** ヘッドレスフレームワーク集合——`MADFoundation`（65 h+mファイル）、`MADCocoaExtensions`（44）、`MADDataStructures`（36）、`MADFileManager`（30）、`MADAPI`（33）、`MAD`（403）、`MADSqlite3`（64）、`MADMySQL`（41）、`MADTds`（3）、`MADTdsClient`（8）——は約727ファイルです。Pythonの書き換えは量だけでなく、*テストで固定された苦労して得た振る舞い*を重複させます。SQLジェネレータ、`MADDataTableFast`の取り込みパス（200,000行を1.16秒、ベンチマーク済み）、ドライバの型マッピング（SQL Serverのモダンな日付／時刻処理はライブテストが2回捕捉したからこそ存在します）、nullセンチネルファミリ、ストアリーダー。その2つの実装はドリフトし、スイートは1つだけを固定します。それは「2つの製品」ではなく、1つの製品と1つの負債です。

**統合面はすでに存在する。** CLI*が*契約です。`mad inspect` → メタデータ、`mad query` → SQL、`mad refresh` → 行、`mad export` → フォーマット、終了コードが悪いドキュメント（2）と到達不能なサーバー（3）と失敗したクエリ（4）を区別します。Pythonサービスは`--format json`付きのサブプロセスとしてそれを呼び、レポートを得ます。サブプロセスのオーバーヘッドはリフレッシュのタイムスケールでは無関係です（サンプルは0.02〜1.2秒でリフレッシュし、プロセス起動は約10 ms）。インプロセス埋め込みが重要だと測定されたことがあれば、同じソースがctypes/CFFI用の小さなC ABIライブラリをビルドできます——しかしそれは任意であり、前提条件ではありません。

**Pythonを好むと述べられた理由——ドライバ接続——について。** Pythonのコネクタエコシステムが広いことは事実で、1回の`pip install`でこのプロジェクトにドライバがないデータベースに到達できます。しかし今日存在するソースについては、接続はすでに言語中立です。MADドライバはfreetdsとMariaDB Connector/Cに載っており——PythonやCプログラムがリンクするのと同じCライブラリ——両方ともLinuxでネイティブにビルドされます（§7）。エンジンをコンパイルすれば、その接続はそのままLinuxに移ります。Pythonが本当に優位なのは*新しい*ソース種別（Postgres、BigQuery、REST）であり、そこでの正しい答えはプロジェクトがすでに約束する拡張シームです。スキーマと行を返す`MADDatabase`サブクラス。HTTPを話すドライバはObjective-CでもPythonでも同じように振る舞います。Pythonが買うのはより多くの既製コネクタであり、より簡単なコアではありません。

**正直なトレードオフを率直に言うと:** これは*2つの実装*（Python + Objective-C）を恒久的なドリフトリスク付きで維持することと、*ニッチなツールチェーン*（clang + libobjc2 + GNUstep）上の*1つの実装*をエコシステムリスク付きで維持することの選択です。このドキュメントは後者を推奨し、再検討する測定可能なトリガーを持ちます。§9がチェックポイントを名指しします。推奨を拘束力あるものにする唯一のものは**JSONエクスポートの形**です——Python契約はそのスキーマの良さと同じであり、それを定義することが§10の決定1です。

そして書き換えが実際に起こるなら、正しい言語はLinux上のSwift——Pythonではなく——です。ポータブルSQLiteストア（Phase Cの作業）はすでに言語中立の契約だからです。どちらの側がストアを書いても、もう一方が読みます。

---

## 3. コンパイルしなければならないもの、してはならないもの

| フレームワーク | ヘッドレスで必要 | 理由／不要な理由 |
|---|---|---|
| `MADFoundation` | はい | ベース: オペレーション、URLファクトリ、キーチェーン（除外可能）、ロギング |
| `MADCocoaExtensions` | はい | どこでも使われるヘルパー（11のUIKitファイルだが、除外可能なもの） |
| `MADDataStructures` | はい | Appleインポート0。C++ファイル3（libc++が必要） |
| `MADFileManager` | はい | Appleインポート0。クラウドコーディネータは除外（iCloudはPhase Dで削除される） |
| `MADAPI` | はい | 接続レイヤー。3つのUIKitファイルはビューコントローラで、ヘッドレスではない |
| `MAD` | はい | 難しいもの: 403のうち29 UIKit、34 CoreData、15 CoreGraphics |
| `MADSqlite3` | はい | Appleインポート0。`MADArrayCaching`（`.madac`ストア）は100%クリーン |
| `MADMySQL` | はい | Appleインポート0 |
| `MADTds` / `MADTdsClient` | はい | Appleインポート0 |
| `MADExplorer` | いいえ | ファイルエクスプローラUI（32ファイル中19がUIKitをインポート） |
| `MADBarcodes` | はい | エンコード+PNGコアはポータブル（zint + libpng）。`MADBarcodeView`と`MADBarcodeCache`だけがApple側に残る |
| `MADFeedback` | いいえ | 未使用でメンテナンスされていない |
| `Scrimpter` | いいえ | Appleインポート0だが未使用 |
| `MADDesigner`（アプリ） | いいえ | 302のUIKitファイル。UIはAppleプラットフォームに残る |

依存の向き: すべてが`MADFoundation`の上にあり、ドライバは`MAD`の`MADDatabase`をサブクラス化し、`MAD`の`Constructor`ファイルはドライバをインポートします——既知の循環です（`ROADMAP.md` §3.4）。ドライバレジストリ（`ROADMAP.md` §5.1）はLinuxにとって二重に重要です。その循環を断ち切り、Linuxビルドがドライバをハードインポートの山ではなくプラグインとしてリンクできるようにするものです。

---

## 4. 測定された監査

フレームワークのソースディレクトリごとに、各Appleフレームワークをインポートするファイル（複数のUIKitヘッダーをインポートするファイルは1回と数える）:

| フレームワーク | 合計 | UIKit | CoreData | CoreGraphics | Security | os/log | CoreFoundation | dispatch |
|---|---|---|---|---|---|---|---|---|
| MADFoundation | 65 | 4 | 0 | 0 | 1 | 9 | 3 | 1 |
| MADCocoaExtensions | 44 | 11 | 0 | 3 | 0 | 1 | 0 | 0 |
| MADDataStructures | 36 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| MADFileManager | 30 | 0 | 0 | 0 | 0 | 2 | 0 | 5 |
| MADAPI | 33 | 3 | 0 | 0 | 0 | 4 | 0 | 2 |
| MAD | 403 | 29 | 34 | 15 | 1 | 15 | ~19 | 3 |
| MADSqlite3 | 64 | 0 | 0 | 0 | 0 | 4 | 3 | 5 |
| MADMySQL | 41 | 0 | 0 | 0 | 0 | 2 | 0 | 1 |
| MADTds | 3 | 0 | 0 | 0 | 0 | 1 | 0 | 0 |
| MADTdsClient | 8 | 0 | 0 | 0 | 0 | 0 | 0 | 3 |

柱の外側のロングテール、それぞれに処置:

| 項目 | サイト | 処置 |
|---|---|---|
| `os_log`（すべてが`madlog.h`に集約、2つのコピー） | 9+15+4+2+…ファイルがシムをインポート | syslog/printfに対する約20行のヘッダーを1つ書き換える。他の呼び出しサイトは変わらない |
| `asl.h`（非推奨のApple System Log） | `MADocument.m:107`、`RptqDocumentElement+Extras.m:60` | madlogシムに差し替える |
| `copyfile.h` | `MADArchiveManager.m:14`、`madtar.m:18` | POSIXのrename/link |
| `mach/machine/vm_param.h`（ページサイズ） | `MADocument.m:108` | `getpagesize()` |
| `CFNetwork`/`CFHost`逆引きDNS | `BDHost.m`（1ファイル） | `getaddrinfo` |
| `NSMetadataQuery`クラウドコーディネータ | `MADFileManager`（3ファイル） | 除外——iCloudはPhase Dで削除される |
| `Security.framework` / `SecItem` | `MADKeyChain.m`、`MADOperationKeyChainGet.m` + テスト | 除外——リフレッシュパスはオペレーション依存から認証情報を取り、キーチェーンは決して使わない。CLIはすでに`--credentials`で代替する |
| `MADApplication.m`の`AppKit`ガード | 1ファイル | `TARGET_OS_LINUX`分岐を追加 |
| `MADURLFactory.m:32`の`UIScreen`スケール | 1行 | 2.0を返す |
| `MADOperation.m:549-563`の`UIApplication`バックグラウンドタスク | 1つのガードされた機能 | `#if`で外す |
| CoreFoundation（`CFNumber`/`CFData`/`CFString`、トールフリーブリッジング） | MAD、MADFoundation、MADSqlite3にまたがる約25サイト | GNUstepの同等物／機械的書き換え。CoreBase（GNUstepのCFクローン）は未成熟で、頼らないこと |
| UIKit値トランスフォーマ（`MADColorTransformer`、`MADLocaleTransformer`、`MADPngImageTransformer`） | 3ファイル、現在CLIのターゲット境界を越えて引きずられている | **Phase Dで消える**——ストア移行がトランスフォーマブルをポータブルなスカラーに変換する |

SystemConfiguration: 出現ゼロ。CommonCrypto: フレームワークにゼロ（アプリのみ、レシート検証）。`@import`: ゼロ——すべて`#import`で、GNUstepが求めるものです。

---

## 5. 3つの柱

### 5.1 Core Data — 進行中の移行がレバー

34のMADファイルがCore Dataをインポートし、`MADocument`は`UIManagedDocument`で、ストアはコンパイルされた`MAD.momd`で、`MADAtomicStore`が下にあります。それらのどれもLinuxには存在せず、存在する必要もありません——プロジェクトがすでにそれを置き換えているからです。`MAD_STORE_MIGRATION.md` Phase Cは2026-10-03に着地し、`RptqStoreContext.h`は「ここにあるものはCore Dataをインポートしない」と宣言しています。Phase Dは`UIManagedDocument`、値トランスフォーマ、`.xcdatamodel`、iCloud機構を削除します——それは同時に§4のいくつかの項目（値トランスフォーマ、クラウドコーディネータ、CLIが現在アプリバンドルからコピーする`MAD.momd`）を殺します。

**Phase CとDを完了することがLinuxへの単一の最も高いレバレッジのステップ**であり、それはLinux固有の作業ではなく、プロジェクトがポータビリティのためにすでに所有する作業です。移行計画からの1つの注記: iCloud時代の古いドキュメントはユーザーがiOS Filesアプリを通じて取得し、オープン時に変換されます（`MADStoreConverter`）。iCloud機構はそれらを取得するのに不要なので、Phase Dの削除は何も取り残しません。

### 5.2 UIKit / CoreGraphics — 29ファイル、ほとんどは些細

29のMAD UIKitファイルの内訳:

| 種類 | 数 | 処置 |
|---|---|---|
| `CGGeometry`構造体（`CGRect`/`CGSize`/`CGPoint`） | 15ファイル | プレーンな構造体——定義を複製。描画ゼロ |
| フォーマッタの`UIEdgeInsets` | 約3ファイル | 構造体演算に置き換え |
| モデル／レイアウトコードの`UIFont`/`UIColor`/`UIImage` | いくつか | メトリクスと保存スタイルの軽量同等物 |
| `UIActivityItemProvider` / 共有シート | 2ファイル | ヘッドレスではない——除外 |
| `UIScreen`/`UIApplication` | 2ファイル | ワンライナー、§4 |
| `MADPrintPageRenderer` + `UIGraphics` PDFコンテキスト | エクスポートシーム | **本当の作業**——下記参照 |
| `MADocument`の`UIManagedDocument`ベース | ドキュメントクラス | Phase Dで消える |

注目すべき良いニュース: `MADReportFormatter.m`のUIKit使用は実質的に痕跡的で（1つの`UIEdgeInsetsMake`、1つの未使用`UIPrintInteractionController`インポート）、`MADArrayCaching`——`.madac`レンダリングページストア——はすでに100% UIKit/CoreDataフリーです。それは今日どのObjC Foundationでもコンパイルされます。

**レンダラーの決定。** CoreGraphics PDFコンテキストにLinuxの同等物はありません。最もコストの低い段階分け: データパス動詞を先にグリーンにし、次に`export --format json` / `--format csv`（純粋なFoundation——Python呼び出し元がとにかく望むフォーマット）、次にHTML/SVGページ（ネイティブ依存なし）、最後にPDF。同じ`MADPrintPageRenderer`描画ループの背後にcairoやlibharuのライターを置くか、Linuxがデータとページを提供する間PDFレンダリングをmacOSワーカーに残します。CLIがすでにPDFにバイトパッチする`--deterministic`フラグは、クロスプラットフォームレンダラーテストの種です。

### 5.3 GNUstep上のFoundation — 存在し、部分的に検証され、周辺でリスク

調査が一次資料から検証したこと:

- **GNUstep Base 1.31.1**（2025-02-28）が現行で、masterは活発です（注目すべきNSURLSession作業が2026-08にマージ）。リリースケイデンスは遅く、およそ年次です。
- 存在し機能する: `NSJSONSerialization`、`NSUUID`、`NSRegularExpression`（ICU）、`NSISO8601DateFormatter`、`NSDateFormatter`（ICUベース——`libicu-dev`は必須ビルド依存）、`NSOperationQueue`、プロパティリスト、`NSXML*`（libxml2）、Apple XML互換を目指すキー付きアーカイブ。
- **`NSURLSession`が弱点**: 1.31.0で「新しい実験的実装」として出荷され、明示的にサポート対象クラスではありません。2026年のデブロッキング作業（ブロックなしでビルド）はマージされましたが安定化は未完了です。Linux製品をそれの上に構築しないでください——直接のドライバ接続（リフレッシュがとにかく行うこと）かlibcurlを好んでください。
- **`libdispatch`はGNUstep自身の方針で任意**——ベースのメンテナは依存するには「ポータブル／信頼できる状態ではない」と呼びます。このコードベースはdispatchを広く使います（`dispatch_once`、`dispatch_sync`、セマフォ）。swift-corelibs-libdispatchはCでObjCから呼び出せ（`OS_OBJECT_HAVE_OBJC_SUPPORT=1`）、ここで使われる*コア*は安定部分です——しかしdispatchは所与ではなくシム可能なレイヤーとして扱ってください。
- **CoreBase**（GNUstepのCoreFoundationクローン）は未成熟で、ビルドガイドは頼らないよう述べています。約25のCFサイトは代わりにGNUstepの同等物を得ます。
- **周辺で未検証、ここでは負荷を支える**: `NSPredicate`/`NSExpression`（MADに13以上のインポートサイト）、`unarchivedObjectOfClass:`（iOS 11+ API——GNUstepのカバレッジは様々）、`NSOperation`+KVOの振る舞い。存在は証明され、振る舞いの同等性は証明されていません。これが正直なリスクであり、§8のフィクスチャがまさにテストするために存在するものです。

**存在証明:** SOGoはObjective-Cのグループウェアサーバーで、Debian sidで`gnustep-base-runtime (>= 1.31.1)`にハード依存して出荷されています——GNUstep Foundationが本番デーモンとして大規模に動作しています。Darlingはlibobjc2を駆動します。Linux上の非GUI ObjCツールは普通であり、異国ではありません。

---

## 6. ツールチェーンとエコシステム

- **ランタイム: libobjc2 2.3**（2025-09-16）——LinuxでモダンなObjective-Cを得る唯一の方法。ARC、ブロック、弱参照、`@synchronized`、非脆弱ivar、gnustep-2.0 ABI。**ARCはclang + libobjc2を必要とし**、主流ディストリビューションのパッケージはARCなしでGCCランタイムに対してGNUstepをビルドします——そのためビルド環境はソースから（またはFedoraのlibobjc2パッケージングから）組み立てられ、Debianのデフォルトからではありません。これは実際の運用上のコミットメントです。
- **ブロック**: libobjc2 2.3はswift-corelibs-libdispatchのBlocksRuntimeを消費できます。`libblocksruntime-dev`もパッケージ化されています。コードのブロックは標準です。
- **例外**: clang + libobjc2はネイティブのアンワインダーベース例外を与えます。GNUstepの2つの例外機構を1つの実行ファイルで混ぜてはなりません——すべてをネイティブパスでビルドしてください。
- **clangモジュール／`@import`サポートなし**——コードベースはすでにどこでも`#import`を使うため、コストはゼロです。
- **LinuxのUIKit: 存在しないことを確認。** ユーザーのMicrosoftの記憶はWinObjCです——Windows Bridge for iOS、Windows上の意図的に部分的なUIKitサブセットで、最後のプッシュは2022年、2025-05-28にアーカイブ。Chameleon（macOS上のUIKit）は2015年に死にました。`gnustep/libs-uikit`（2026年6月）は1スターの26コミットの実験です。Microsoftさえアイデアを放棄したことから学ぶ教訓: **UIKitを移植しない。** 監査はこのプロジェクトがそうする必要がない理由を示しています——UIKitはすでに名指しされたファイルに閉じ込められ、ヘッドレスなものはすべてビューではなくデータを通じてレンダリングされます。
- **テスト: Linux上のObjCにXCTestなし**（swift-corelibs-xctestはSwiftのみ）。GNUstep自身の`gnustep-tests` + `Testing.h`がゼロ依存ユニットランナーで、UnitKitはアーカイブされています。本当の受け入れレイヤーはユニットテストではなく§8のフィクスチャです。
- **暗号とシークレット**: CommonCryptoポートなし（GNUstepプロジェクト自身の助言はOpenSSLかGnuTLSへの`#ifdef`）。キーチェーンなし（機能的類似物はlibsecret/Secret Service、またはセッションシークレット用のkeyutils）——§4によりヘッドレスエンジンはどちらも必要としません。

---

## 7. Cライブラリ — 簡単な部分、1つのライセンスブロッカー付き

すべてのベンダーライブラリは上流のautoconf/cmakeビルドを持つポータブルなCです。

| ライブラリ | バージョン | ライセンス | Linuxビルド |
|---|---|---|---|
| sqlite3 | 3.53.3 | パブリックドメイン | ネイティブ。フォーマット固定フラグはすでに`Compressor/sqlite3.xcconfig`にある |
| zlib | 1.3.2 | Zlib | ネイティブ |
| openssl | 3.5.9 | Apache-2.0 | ネイティブ |
| bzip2 | 1.0.8 | BSD系 | ネイティブ |
| libpng | 1.6.59 | PNG Reference v2 | ネイティブ |
| libarchive | 3.8.9 | BSD-2 | ネイティブ |
| freetds | 1.4.27 | LGPL-2.0+ | ネイティブ（レシピに修正すべきBSD `sed -i ''`の些細な点あり） |
| mysqlclient | 8.4.10 | **GPL-2.0 + FOSS例外** | ネイティブ——**しかしGPLはプロプライエタリバイナリの出荷ブロッカー**。MariaDB Connector/C（LGPL-2.1）が`LICENSE_COMPLIANCE_PLAN.md`ですでに名指しされた代替 |
| zint | 2.16.0 | BSD-3 | ネイティブ。MADBarcodesのPNGコアがリンクするバーコードバックエンド（上記libpngと） |

加えてツリー内C（`miniz`、`madmath`、`madpng`、`madtar`、`madlib`——すべてポータブル、すべて寛容なライセンス）。Apple固有なのはCompressorの*パッケージング*レイヤーだけです（`xcrun`、`-isysroot`、`lipo`、`xcodebuild -create-xcframework`）。Linuxドライバはそれをすべて落とし、同じ上流ビルドをネイティブに実行し、プレーンな`ar` + includeインストールで終えます。iOS固有の複雑さ（mysqlclientの2段階ホストツールビルド、freetdsのプラットフォームごとの生成ヘッダー）はネイティブビルドで*消えます*。監査からの1つのフラグ: Karl Kraft MySQLコネクタは無ライセンスです——MariaDB移行で置き換え、出荷しないでください。

---

## 8. ビルドとテストの計画

- **ビルドシステム**: 12のヘッドレスフレームワークとCLIのためのCMake——1つのフラグ集合（`clang`、`-fobjc-arc`、`-fblocks`、GNUstepの`gnustep-config --objc-flags`）。`CLI/build.sh`の`.momd`コピーダンスはPhase Dで消え、`REFRESH_SOURCES`のターゲット境界を越える到達は`MADOperationRefresh`の移動（`ROADMAP.md` §3.4）で消えます。
- **受け入れレイヤー**: `MAD_CLI.md` §6のラウンドトリップフィクスチャをLinuxで実行し、macOS/シミュレータ実行とバイト比較します——コンテナ忠実性、v0可読性、キャッシュなしラウンドトリップ、終了コード。行キャッシュとJSON/CSV出力はバイト比較可能で、PDFは1つのレンダラーが存在するまで構造的にのみ比較可能です。これらのフィクスチャは*GNUstep Foundationのカバレッジテスト*でもあります。早く実行し、すべての失敗をトリアージすれば、§5.3の未知はAPIインデックスを読むのではなく経験的に解決します。
- **CI**: テストマトリックスのLinuxジョブがフィクスチャを実行します。スイートは今日のシミュレータスイートのままです。

### 8.1 デプロイパス: クロスコンパイルではなくコンテナ

これは実際にどのようにビルドされ出荷されるのか?

- **macOSからクロスコンパイルしない。** Objective-CランタイムとGNUstep Baseはホスト結合です——MacからLinux sysrootに対してクロスコンパイルするのは研究プロジェクトであり、ビルドステップではありません。iOSアプリはMac上のXcodeでビルドされ続け、Linuxエンジンは*Linux上でビルド*されます。
- **Dockerがビルド環境。** 1つのDockerfile、2つのステージ: clang + libobjc2 2.3 + GNUstep Baseをソースビルドするツールチェーンステージ（ARCに必要——§6）、そしてCライブラリのためにCompressor Linuxドライバを実行し（§7）、次に12のフレームワークとCLIのためにCMakeを実行するビルドステージ。同じイメージがCI環境とデプロイ成果物を兼ねます。
- **どのLinuxをサポートするか: 1つのベースラインをコンテナ内で。** 単一のベースライン——Debian stableかUbuntu LTS——を選び、そこでビルドします。本当の互換性制約はglibcだからです。リンクされるものはすべてlibcを除いてソースからビルドされるため、「サポートされるLinux」は「出荷するイメージのglibc」を意味します。受け入れる最も古いglibcでビルドするのがルールです。コンテナを出荷すれば、Docker対応の任意のホストがディストロマトリックスなしで製品を実行します。
- **ワークフローはすでに慣れているスクリプトとコンパイルを自動化したものです。** Linuxビルダーでの`git clone` → Compressorレシピがsqlite、zlib、openssl、bzip2、libpng、libarchive、freetds、MariaDBをソースからビルド → CMakeが1つのフラグ集合でフレームワークをコンパイル → `mad`をリンク → ラウンドトリップフィクスチャ（上記）を実行 → イメージをタグ付け。GitHub Actionsのubuntuランナーが、コミットごとにこれが起こる標準の場所です。
- **macOSの役割。** Macはアプリ、シミュレータCLI、参照フィクスチャ出力の開発ホストのままです。2つのプラットフォームはgitとフィクスチャのバイト比較で結ばれます。LinuxビルドはMacの出力に対して*チェックされ*、それが実行可能にされたポータビリティ保証です。

---

## 9. 工数とフェーズ

取るべき順序のバケット:

| フェーズ | 作業 | 性格 |
|---|---|---|
| A | ストア移行のPhase C + Dを完了する | すでに所有するポータビリティ作業。Core Data、iCloud、値トランスフォーマ、`.momd`を除去——単一の最大のLinuxレバー |
| B | ツールチェーンスパイク: clang + libobjc2 + GNUstep BaseをソースビルドするDockerfile。MADFoundationサブセットをコンパイル | 環境を証明し、ビルド／CIイメージになる。数日 |
| C | §4のシムリスト | 有界で列挙可能——madlog、asl、copyfile、vm_param、CFHost、MADApplication、UIScreen、バックグラウンドタスク、約25のCFサイト、除外 |
| D | **チェックポイント**: Linuxでデータパス動詞がグリーン——両サンプルに対する`inspect`、`schema`、`query`、`refresh`、フィクスチャのバイト比較 | Cの後でこれがグリーンでなければ、GNUstep Foundationのテールは見積もりより大きく、*その*瞬間に書き換えの問いを再検討します——それ以前ではない |
| E | エクスポート: JSON/CSV（Python契約）、次にHTML/SVGページ、次にPDFの決定（cairo/libharu対macOS側レンダリング） | まず純粋なFoundation。レンダラーは最後 |
| F | Compressor Linuxドライバ（ネイティブビルド、マトリックス列、MariaDBスワップ、freetds sed修正）+ CMake磨き + CI行 + デプロイ可能イメージ | 機械的、ライセンスでゲート |

順序の根拠: Aは所有作業、Bは安価で全体をデリスクし、Cは列挙可能、Dが正直なgo/no-goです。EとFの何も問いに*答える*ためには必要なく、*出荷する*ためだけに必要です。

**Phase Aステータス（2026-10-06）。** Core DataはMADフレームワークから外れました。`MADocument`は`UIDocument`で、レガシーコンバータとコンパイル済みモデルは`MADLegacyStoreConversion`の背後でアプリケーションターゲットにあり、変換されたドキュメントはCore Dataファイルを剪定し、フレームワーク／MADDesignerの掃除が残りのインポート、型、死んだコードを除去しました。値トランスフォーマ、エクスプローラのクラウドペイン、iCloudエンタイトルメントはユーザーの決定で保持されます——アプリ側なので、ヘッドレスビルドをブロックしません。ファイルマネージャのクラウドコードは未使用のままそこに残ります（ユーザーによれば、ヘッドレスモードには不要）。Bの前に残るのは、ツールチェーンスパイクが必要と証明する§4のファイルレベル除外だけです。

**Phase Bステータス（2026-10-06）。** ツールチェーンスパイクは`linux-port`ブランチでグリーンで、2026-10-16に`master`へマージされました（`524e0d86e`）。`Linux/`は1つのDockerイメージをビルドします——Ubuntu 24.04とディストロのclang 18（§6の「ソースから」要件はGNUstepがlibobjc2に対してビルドされることであり、LLVMのことではない）、加えてソースビルドのlibobjc2 2.3、libdispatch 6.1.3、gnustep-make 2.9.3、gnustep-base 1.31.1を`Linux/toolchain.conf`に固定——MADFoundationの27実装ファイルのうち23と`madlib.c`をGNUstepに対してコンパイルし、その中で15のテスト実行ファイル（14のポーティング済みスイートとツールチェーンプローブ）を実行します。すべて通り、5つの記録されたニーズと10のプローブレポート項目があります。`./Linux/build.sh`がエントリポイントです。iOSスイートはグリーン（118テスト）を保ち、作業が必要とした6つの小さなプラットフォームガードがAppleで振る舞い中立であることの証明となりました。

プローブは§5.3のリスクリストのほとんどを、エンジンが実際に使うFoundationについて退役させます。ARCと弱参照ゼロ化、ブロック、例外、`@synchronized`、KVO（手動と依存キー）、`NSOperation`ステートマシンKVO、`NSPredicate predicateWithFormat:@"error != nil"`（MADの正確な述語）、プレーンな実行ファイル下でのメインキュー排出を含むdispatch、JSON、日付、plist、ソート記述子、ストリーム、許容パス上のキー付きアーカイブがすべて通ります。2つのギャップが記録され、隠されません。GNUstepのアーカイバはセキュアコーディングをサポートせず（`requiringSecureCoding:YES`はnilを返す。許容パスはラウンドトリップする）、GNUstepの`NSOperationQueue`はすべての通知で`isReady`観測を削除しますが、MADOperationのステートマシンはエンキューごとに`isReady`を複数回通知していました——2回目の削除がraiseし、MADOperationはLinuxでエンキューできませんでした。それは解決済みです（2026-10-06、`linux-port`、現在`master`）。MADOperationは`-willEnqueue`から状態前進を明示的に駆動し、`isReady`/`isExecuting`/`isFinished`のKVOを実際の値変更時のみ送るため、キューはAppleと同じく1つの通知を見ます。Linuxテストは両プラットフォームでそれを明白にアサートし、ニーズは3に減りました。機構は`Linux/README.md`に、除外ファイルとより小さなシム（`NSOperation.name`、`qualityOfService`、`NSDataWritingFileProtection*`、`QOS_CLASS_DEFAULT`、アプリグループコンテナ）とともに書かれています。Phase Aが予期したファイルレベル除外は、まさに§4の4ファイル（`BDHost`、`MADApplication`、`MADKeyChain`、`MADURLFactory`）であることが判明しました。プレリュードが覆い隠していた自己完結ヘッダーの掃除は完了しました（2026-10-06）。Linuxビルドのすべてのヘッダーとソースが使うものをインポートし、`Linux/Compat/MADCompat.h`は1つの実際のプラットフォームギャップ、`NSOperation`の`name`プロパティまで縮みました。

**Phase Cステータス（2026-10-06）。** §4のシムリストはクリアされ、ビルドはもはやスパイクではありません。§3の表の12のヘッドレスフレームワークすべてがイメージ内でコンパイル・リンクします——MADFoundation 27中26、MADDataStructures 17、MADFileManager 11中10、MADCocoaExtensions 17中7、MADAPI 11中8、MADSqlite3 26、MADTds 1、MADTdsClient 5中4、MADMySQL 19中18、MAD 181中150——そしてそれらのスイートがctest下で実行されます。114の実行ファイル（1098テスト）、すべてグリーン、6つの記録されたニーズがあり、それぞれApple専用機構（Core Data、コンパイル済みモデル、`MADocument`、コンバータ）で`Linux/README.md`に名指しされています。2026-10-10にマージされたカバレッジマスター（約100のXcodeテストファイル）は完全にポーティングされ——55の新しい実行ファイル、スイートごとに——マージは2つのApple側不具合を発見し、どちらも修正されて`BUGS.md`にあります。フレームワークターゲットがプリプロセッサ定義から`$(inherited)`を落としていた（すべてのフレームワークDebugビルドでDEBUGが死んでいた）、そしてMADのドキュメントフィクスチャが実行間で1つのストアを共有していた。ライブラリレイヤー（`Linux/libraries.conf`、`Linux/lib/libraries.sh`）がsqlite3、openssl、freetds、zlib、bzip2、libarchive、libpng、zint、mysqlclientをネイティブにイメージへビルドします（§7のCライブラリ。何も出荷されません）。ロングテール項目は§4が予測したとおりに進みました——`asl.h`/`vm_param.h`インポートは痕跡的で、`copyfile(3)`はPOSIXになり、`CFHost`は`getaddrinfo`になり、CFサイトは`CFNumberGetValue`シムになりました——UIKit/CoreGraphicsテールは理由付きでファイルごとに除外され、ポーティングされません（§5.2の処置。`MADocument`（UIDocument）と`MADReportFormatter`はPhase Dを待ち、それはプラットフォームと同じくらいCLIの問題です）。MADのスイートはさらに3つの差異を発見し、すべて修正またはシムされ`Linux/README.md`に書かれています。ランタイムのBOOLエンコーディング（Apple以外では`'C'`）、`class_getProperty()`のスーパークラスウォーク欠如（どちらも`RptqObject`で修正）、スタブ`+propertyListWithStream:`（シム）。テストカバレッジのポーティングはさらに3つを追加し、同様に修正またはシムされました。`NSOperation.asynchronous`/`-isConcurrent`（Compatカテゴリ——なければ終了する非同期オペレーションが`-dealloc`からraiseした）、`-coordinateAccessWithIntents:`（GNUstep実装がフォールトする。Compatカテゴリがキューでアクセサを呼ぶ）、`MADURLFactory`からのスキームなしURL（今は`+fileURLWithPath:`で、5つのコーディネータテストをアンパークした）。最も長く固定されたままだった差異——GNUstepの`-localizedCaseInsensitiveCompare:`は大文字小文字を区別するため、MADSqlite3の登録済み照合順序がAppleと異なる順序でテキストを並べた——は今修正されています（2026-10-25）。照合順序、メモリ内ソートセレクタ、フォーマッタのコンパレータはすべて1つのファーストパーティ定義順（`NSString+Comparison.h`）を通り、ピンは両プラットフォームで同一に成り立つ定義順テストになりました。ライブの`MADTdsClientLiveTests`スイートはイメージ内からSQL Serverコンテナに対してグリーンで実行され（29/29）、ドライバパスがコンパイルされるだけでなくLinuxで行使されます。Phase D——CLIとデータパス動詞——が次のステップでありgo/no-goです。

**Phase Dステータス（2026-10-16）。** チェックポイントは達成されました。`mad`は`CLI/Source`（iOS-Simulatorツールがビルドされるのと同じソース）からイメージ内でビルドされ、12のフレームワークをリンクし、そこでデータパスを実行します。`inspect`はレガシーv0サンプルとポータブルv1フィクスチャの両方を報告します。`schema`と`query`はMacのツールと同じ答えを生成します（`schema`はバイト同一）。`refresh`はSqlite3サンプルで行キャッシュを埋め、フィールド名で比較するとMacのキャッシュとバイト同一です（76行、21列）。そしてイメージ内からライブサーバーに対して、`mad refresh`はMySQL 8.4から50行（`employees`、プリペアドステートメントフェッチ）を、SQL Server 2022から20行（`AdventureWorksLT2022`、freetds経由）を取得しました。ライブスイートも一致します——同じイメージで`MADMySQLLiveTests` 44/44と`MADTdsClientLiveTests` 29/29——ctest実行は117の実行ファイル、1153テスト、6ニーズ、すべてグリーンです。

そこへ到達するために2つのことが解決され、どちらも`Linux/README.md`に記録されています。

1. **ドキュメントの問い（§5.1、§9 Phase D）。** `MADocument`は`UIDocument`なので、そのまま持ってこられません。ユーザーの選択（2026-10-16）はヘッドレスドキュメントパスであり、`Compat`の`UIDocument`シムでも`MADocument`の分割でもありませんでした。ドキュメントのデータ半分は今やプロトコル`MADDocumentDataProtocol`で、`MADocument`がそれに準拠し（すべてのメンバーはすでにそのアクセサの1つでした）、`MADHeadlessDocument`がアプリのドキュメントが使うのと同じ`MADDocumentStore`上で実装します。リフレッシュチェーン——ドライバレジストリとともに`MAD`へ移動（`ROADMAP.md` §3.4、§5.1）——はプロトコルを取り、両プラットフォームが同じ`MADOperationRefresh`を実行します。その1つのレンダー側分岐は`#if __APPLE__`で、`mad export`（PDF、Core Graphics）はApple側に残ります。これは§5.2の段階分けです。
2. **ドライバレジストリ（§3、§5.1）。** コンストラクタはもはやMySQLとTDSをインポートしません。各ドライバは`+load`で自身を登録し、コンストラクタが型でルックアップします。Linuxではドライバアーカイブがwhole-archiveされます。ドライバの仕事は*カテゴリ*を通じて到達され、カテゴリはリンカが見えないメッセージ送信だからです——それが修正されるまでCLIはMySQLで中止しました（`Linux/README.md`のcompat-archive注記参照）。

CLIが追加したGNUstepの差異: ディレクトリ列挙子（`-enumeratorAtURL:…`は含むディレクトリを剥がしたURLを返す——測定済みで、CLIのメンバーリストは代わりに`-subpathsAtPath:`を使う）、およびSELECTリストの列順。これは集合順で設定されていたためAppleと異なりました（同じフィールド、同じ行。`Linux/README.md`に注記）。**2026-10-16に解決**、JSONエクスポート形状の決定（下の§10.1）とともに: 順序は両方のSQLビルダーで列エイリアスと定義され、生成SQL、行キャッシュ、すべてのエクスポートが両プラットフォームで一致します（docs/project/BUGS.md、SELECTリストのエントリ。`Linux/Tests/MADQuerySelectExpressionTests.m`の順序テスト）。

**Phase Eステータス（2026-10-16、前半）。** エクスポートシームは実在し、Foundation系フォーマットがここで実行されます。`MADReportExporting` + `MADReportExporterRegistry`はドライバレジストリの形（実装プロトコル、`+load`登録、名前によるルックアップ）で、`mad export`はそれらを通じてフォーマットを選ぶため、新しいフォーマットは新しいクラスです（`MAD_CLI.md` §5.3、ROADMAP.md §5.2）。`text`、`csv`、`json`は純粋なFoundationで、Londonフィクスチャに対して**LinuxとAppleでバイト同一の出力**を生成します——Macのツールとイメージのもので`sha256sum`で測定（`Linux/README.md`のCLIセクション。`Linux/Tests/MADReportExporterTests.m`がFNV-1aチェックサムで同じバイトを固定）。JSON形状は決定済み（§10.1）。`json`はデータ契約——クエリの列をエイリアス順で、行、SQL、ドライバ——であり、`json-report`は同じドキュメントにレンダリングされたレポートのセクションを追加メンバーとして加えたもので、2026-10-16のユーザーの選択です。ページ、描画順のセクション、各ラインの種類、フレーム、解決済みテキストを、何も描画しないレンダラー自身のページウォークから構築するため、PDFが示すものからドリフトできません。レンダー半分を必要とするため、どこでも登録され、ここで実行できない理由を報告します。そのウォークは`MADPrintPageRenderer -buildPageAtIndex:context:inPageRect:`で、NULL可能なコンテキストを取ります。PDFパスは自身のものを渡して以前のように描画し、json-reportはNULLを渡します。レンダー半分の最初のプロトコル`MADDocumentRenderProtocol`が、フォーマットがドキュメントに求めるものです。Phase Eの残り半分——Linux上のレポートメンバーとHTML/SVG——はレンダー半分のLinuxへの移動であり、ユーザーのレンダラー決定（HTML/SVGが次、PDFが最後、§10.2）がそれをHTMLステップに置きます。`pdf`は依然としてCLI自身の腕で、その同じステップでエクスポーターになります。

---

**Phase Eステータス（2026-10-16、後半: ライター）。** `.mad`ライターはLinuxで実行され、両プラットフォームが同じバイトを書きます。`MADArchiveManager.reproducible`はユーザーが選んだオプトインモード（固定時刻2001-01-12T00:00:00Z、uid/gid 0、ソートされたメンバーウォーク。通常の保存はファイルシステムのメタデータを保つ）で、`MADHeadlessDocument`が`-writeToURL:reproducible:error:`を獲得し（UIDocument部分なしのアプリの保存）、`mad write`が両プラットフォームでそれに到達する動詞です。測定: Macで書かれたLondonフィクスチャとイメージ内のそれは同じ16,261バイトのファイルで、sha256は`09815b24…`（SQL entry Phase Aのストア移行が書かれたバイトを変えました。フィクスチャ自体はバージョン1ストアのまま）。`Linux/Tests/MADArchiveManagerTests.m`がバイト、ラウンドトリップ、モードを固定します。2つのLinux専用不具合が邪魔をし、修正されました（`BUGS.md`、バイト同一性のエントリ）。終わらないウォークと、glibc上で呼び出し元のアーカイブパスを切り詰める`dirname(3)`/`basename(3)`。比較がカバーするのはコンテナです。メンバーはフィクスチャ自身のバイトです。ストアを*作成する*Linuxライターはそれをストアレイヤーに拡張します。

**Phase Eステータス（2026-10-16、第3部: レンダー半分とHTML）。** レンダー半分はLinuxへ移動し、フォークではなく準拠として移動しました。形状についてのユーザーの答えは「1つのフォーマッタ、2つのパスではなく、同じものをレンダリングすべき」でした。したがって:

* `MADReportFormatter`は`id <MADDocumentRenderProtocol>`を取ります。プロトコルはフォーマッタが読む4つのメンバー（`filename`、`storeContext`——以前はMADocumentの`-managedObjectContext`を尋ねていた——`database`、`resetSectionLayoutManagers`）を獲得し、フォーマッタがドキュメントから割り当てるデータ、キャッシュ、レポートデータソースの各プロトコルを継承します。
* ページウォークは`MADPrintPageRenderer`から`MADReportPageBuilder`へ移りました。プレーンなFoundationクラスです。ページごとに同じ読み取りトランザクション、同じ要素参照、要素ごとに同じ1つのライン表現で、描画は呼び出し元が渡すブロックになりました（レンダラーは描画するものを渡し、フォーマットは何も渡さない）。ビルダーはレンダー側のジオメトリ（US Letter、1ptトリム）と準備シーケンス（行のソート、フォーマッタのサイズ設定、フォーマット）も所有し、それらはCLIのPDF腕とjson-reportでコピーされていました。
* `MADDocumentRenderDataSource`はレンダー半分の読み取りの唯一の実装——ドキュメント上の`MADPrintPageRendererDataSourceProtocol`と`MADReportFormatterDataSource`——で、`MADocument`と`MADHeadlessDocument`の両方がそれを尋ねて答えます。本体はMADocumentのもので、移動されました。アプリのページは以前とまったく同じものを読みます。
* `MADHeadlessDocument`は`MADDocumentRenderProtocol`に準拠するため、ウィンドウのないドキュメントもフォーマットしてウォークできます。`MADOperationRefreshInitialize`のレンダー分岐は`[doc isKindOfClass: [MADocument class]]`ではなくプロトコルをキーにします。
* 要素ファミリはヘッドレスでコンパイルされます。`MADPrintPageElement`のイニシャライザはFoundation（テキストはそこで解決されます）で、`-drawInRect:`本体だけが`#if __APPLE__`です。Apple以外では画像要素のピクチャはストアのPNGバイト（`MADElementImage`は`NSData`）で、`-renderedImageData`がそれらをエクスポーターが読むライン表現に渡します。`MADElementStylizedText`はAppleのままです——それは描画であり、レイアウトではありません。

**ページネーションはテキストエンジンを必要としません**、仮定ではなく測定: セクションの表示高は`MADSectionLayout`（保存された矩形+マージン+パディング+ボーダー）から来て、それはLinuxビルドにありPhase C以降ずっとそうなので、ページブレークはどこでも同じです。テキストメトリクスは要素が*描画される*ときにのみ入り、レンダラーは`NSLineBreakByTruncatingTail`——1行、クリップ——で描画し、CSSでは`white-space: pre; overflow: hidden; text-overflow: ellipsis`と綴ります。何も折り返さないため、移植する折り返しモデルはなく、フォントエンジンも追加されませんでした。

**`mad export --format json-report`はここで実行され**、同じウォーク上で、報告するフレームは今や*ページ*座標（要素のフレームをそのセクションでオフセットしたもの）であり、レンダラーやブラウザが必要とするものです。

**2つの新しいフォーマット、どちらも両プラットフォーム**（ユーザーが両方を選択）: `html`はファクシミリで、ウォークされたページごとに1つのCSSページボックス、各要素はそのフレームに絶対配置され、解決済みテキストと保存されたフォント、サイズ、特性、配置を持ちます。ブラウザがPDFと同じページに印刷します。`html-flow`は同じレポートをリフロー可能にしたもので、`<section>`、セクションごとに`<table>`、要素ごとに`<td>`、ページ家具は一度だけ出力します。読むためのビューであり、`--format json`がデータ契約のままです。どちらも埋め込み`<style>`を持ちスクリプトを持たない1つのUTF-8ファイルで、ファクシミリのCSSは上記20行に配置ルールを加えたもの、フローファイルのスタイルは生成されたクラステーブル（Londonフィクスチャで9クラス）です。

**`pdf`はシーム上にあります**: `MADReportExporterPDF`はどこでも登録されます。Appleでは本体はCore Graphics + `MADPrintPageRenderer`で変更なし、Apple以外では同じウォーク済みページを`MADReportExporterPDFCairo`に渡し、バンドルされたLiberationフェイスからのFreeTypeグリフでCairo PDFサーフェスに描画します（docs/project/MAD_PDF_LINUX.md）。CLIにはローカルの腕が残っていません。Appleの移動はバイト中立でした。Londonサンプルの決定論的エクスポートは前後で同じ43,177バイト、5ページのPDFです（両方で`sha256 3eb2f1c4…`）。前のコミットのCLIをビルドして比較して測定しました。ヘッドレスライターはバイト同等性ではなく構造同等性を目標とします。

**クロスプラットフォーム比較が言うこと。** すべてのラインのテキスト、すべてのフレーム、すべてのフォント、ページ数、ファイル構造はLondonフィクスチャでAppleとLinuxで同一で、バイトも同様です。`html`、`html-flow`、`json-report`は両プラットフォームで同じsha256を持ちます（`Linux/README.md`にダイジェスト）。そこへ到達するのに1つの発見とその修正がかかりました。レンダリングされた通貨がマシンに依存していました。レポートは今、ロケール*と*小数桁数をドキュメントの数値フォーマットから取ります（ストアは両方を保ち、述べないドキュメントはマシンのロケールではなく`en_US`にフォールバックします）。要素ファクトリは新しい要素に設計ロケールを記録し、通貨記号は円記号を正規化して明示的に書かれます（GNUstepは全角で綴ります）。6ロケールにわたる60ケースの比較はバイト同一です。完全なエントリは`BUGS.md`のアーカイブにあります。

**Phase Fステータス（2026-10-17、一部）。** CLIはビルドツリー内のバイナリではなく、ランタイムイメージとしての成果物です。`Linux/Dockerfile`は`ubuntu:24.04`上の`runtime`ステージを獲得し、`/usr/local/bin/mad`（CMakeのインストールルール）、CLIがリンクする共有オブジェクト（GNUstep Base、libobjc2、libdispatch、libBlocksRuntime、mysqlclient）、GNUstepのランタイムディレクトリ、mysqlclientのメッセージと文字セットファイル、アプリサポートパスの`chinook.sqlite3`を運びます。コンパイラ、ソース、テスト、ヘッダー、静的アーカイブは残します。ディスク上283 MB（圧縮66.5 MB）で、6.65 GBのビルドイメージに対してです。`./Linux/build.sh --runtime`がそれをビルドし、`--verify`がその中で`Linux/verify-cli.sh`を実行します。30のチェック——6つの動詞、各オフラインフォーマットの固定ダイジェスト、`pdf`の拒否、再現可能ライターのバイト、終了コード、イメージ自身の形状（clang、cmake、git、ビルドツリーなし）。2026-10-17にグリーン。`--live`はMySQLとTDSのリフレッシュを追加します（32/32）。スイートはまた、Londonフィクスチャとサンプルデータベースを共有する2つのテストバイナリ間に`RESOURCE_LOCK`を得ました——ctestの並列性がそのペアを断続的に失敗させていました（ロック後35回連続グリーンの並列実行）。

同日のユーザーの決定: **CIなし**（Linuxポートは概念実証と反復可能なテストであり、リリースではない。`./Linux/build.sh --verify`がチェック）と**公開なし**（レジストリから何もプルされないため、GPLの問いは§10.3が残した場所に留まる）。Compressor LinuxドライバはPhase Fで唯一未完了の部分で、CLIには不要です。イメージはCライブラリをネイティブにビルドするからです。

## 10. ユーザーのための決定

1. **JSONエクスポートの形**（`MAD_CLI.md` §8.3、`MAD_FUTURE.md` §10.5）——これがPython契約です。最初に決めてください。§2のすべてがそれに依存します。**2026-10-16に決定: 両方、レポート半分は独自のフォーマットとして。** `--format json`はデータ契約——エンベロープ（フォーマットID、ドキュメント／ドライバ、SQL、行数）、`columns`（キー、名前、テーブル、型）、および`rows`を行ごとに1オブジェクト、JSON型の値で——であり、`--format json-report`はそのドキュメントに`report`メンバー（レンダリングされたセクション）を加えたものです。それによりSELECTリストの順序は列エイリアスをソートしたものと定義され、生成SQL、行キャッシュ、すべてのエクスポートが両プラットフォームで一致します（docs/project/BUGS.md、SELECTリストのエントリ——以前は集合順）。データ半分は構築済み（`MADReportExporterJSON`、両プラットフォーム）。レポートメンバーはレンダー半分を待ちます。
2. **レンダラーの段階分け** — HTML/SVGが先、PDFが最後、それともmacOS側PDFワーカー? **2026-10-16に決定: HTML/SVGが次、PDFが最後。** Linux PDFレンダラーなし、macOS側ワーカーなし。HTMLステップはレンダー半分（`MADReportFormatter`）がLinuxへ移動する場所でもあり、`json-report`とテストもそれを望みます。`pdf`はそれまでCLIのApple側の腕のままです。**2026-10-16に完了（HTMLステップ）。** レンダー半分はLinux上にあり、`mad export`にはローカルの腕がありません。`pdf`は登録されたエクスポーターで本体はAppleのもので、Apple以外では理由を述べます。同日のユーザーのさらなる決定: Linux PDFライターは*次の*ステップであり、この一部ではありません。HTMLファクシミリのページボックスはLinuxライターが再現してテストにしなければならないジオメトリだからです。ライターの形はそのステップのためにここに記録されます。**Cairo（描画、PDFサーフェス）+ Pango（レイアウト、折り返し）+ FreeType/HarfBuzz**、GTK/WebKit/Firefoxが使うスタックで、LinuxがCore Graphics + Core Textに最も近いもの——Objective-Cから呼ばれるC APIで、freetdsやsqlite3がすでにそうであるように、Implラッパーは不要です。ライセンス: CairoはLGPL-2.1/MPL-1.1デュアル、PangoはLGPL-2.1、HarfBuzzはMIT、FreeTypeはFTL/GPLv2デュアル。プロジェクトはすでにLGPL（FreeTDS、`LICENSE_COMPLIANCE_PLAN.md` §4）を出荷し、Linuxイメージはサーバービルドなので、既知の種類の義務です。`libharu`は寛容な代替だがレイアウトエンジンがなく、Skiaは能力が最も近いが重いC++ビルドです。**達成不可能: プラットフォーム間でバイト同一のPDF**——Core Graphicsのライターは再現できません——そのため目標は同じページ、ボックス、テキスト、フォントで、Appleのフォントにはメトリクス互換の代替を使います（`MADFont`のデフォルトファミリはHelvetica Neueで、Linuxにはありません）。**2026-11-20に完了（PDFクロージャ）。** スタックはCairo（PDFサーフェス）+ FreeTypeで、Pangoなしです。ウォークが各ラインにフレーム、テキスト、フォント、サイズ、特性、配置を渡すため、レイアウトは不要で、必要なのはグリフのアドバンスとフェイス自身の`kern`テーブルだけで、FreeTypeが供給します。Cairo 1.18.6（MPL-1.1）とpixman 0.46.4（MIT）は静的ビルドされ、Liberationフェイス（SIL OFL 1.1）がAppleフォントの代替です。`MAD_PDF_LINUX.md`が着地したもの、フォントマッピングポリシー、測定された残差を記録します。目標は構造的なままです。Core Graphicsのバイトは再現できません。
3. **mysqlclient → MariaDB Connector/Cのタイミング** — GPLブロッカーは出荷されるあらゆるバイナリをゲートします。代替は`LICENSE_COMPLIANCE_PLAN.md`ですでに名指しされています。
4. **ツールチェーンポリシー** — ソースビルドのclang/libobjc2/GNUstep（ARCに必要）はメンテナンスコミットメントです。受け入れるか、macOSホストに留まってください。
5. **書き換えトリガー** — §9のPhase Dが測定可能なチェックポイントです。それが失敗するまで推奨は維持されます。1つのObjective-Cエンジンを、CLI境界を越えてPythonから呼びます。
6. **ビルドベースライン** — Debian-stableかUbuntu-LTSベースのDockerで、macOSからクロスコンパイルするのではなくLinux上でビルドします（§8.1）。選択がサポートされるglibcの下限を設定するため、一度だけ意図的に決めてください。
