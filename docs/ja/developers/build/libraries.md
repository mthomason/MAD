---
layout: default
title: "Compressor静的ライブラリビルド"
description: "サードパーティCライブラリ、それらがどのようにビルドされ、Xcodeがどのように到達するか。"
lang: ja-JP
---

# 静的ライブラリ: Compressorビルドシステム

このページでは、アプリケーションがリンクするサードパーティCライブラリと、それらを生成する`Compressor`ビルドシステムについて説明します。

*元の日付に書かれ、現状の事実は2026-11-22に整合。*

このドキュメントは、アプリケーションがリンクするサードパーティ静的ライブラリと、それらを生成するビルドシステムを、計画ではなく実装どおりに説明します。リワーク前の状態（2つの重複するスクリプト世代、コミットされたバイナリ、プラットフォームごとのディレクトリ）は末尾の付録に要約されています。

**継続的な制約:** このリワーク以前の`Compressor/library`内のものは、新しいシステムがすべての組み合わせをビルドし、アプリがビルドしてそのテストが新しい成果物に対して通るまで削除されません。剪定は最後に、項目ごとに1コミットで行われます。

---

## 1. システムとは何か

1つの宣言的マトリックス、1つのドライバ、ライブラリごとに1つのレシピ、ビルドごとに1つのマニフェスト。

```
Compressor/
  matrix.conf                  # the single place version/source/platforms/deps live
  build.sh                     # the driver: ensure (default) / --all / --rebuild /
                               #   --verify / --platforms ios,simulator,macosx
  sqlite3.xcconfig             # the single place SQLite compile options live
  lib/common.sh                # download cache, per-arch compile helpers, lipo,
                               #   xcframework creation, manifest writer, lock
  lib/recipes/<lib>.sh         # one recipe per library (configure/cmake + install)
  lib/verify/<lib>.sh          # optional per-library artifact checks
  patches/                     # local modifications to upstream sources, captured
                               #   as diffs (none current; zint's 2.4.2 patch retired)
  media/<sha256>-<archive>     # content-addressed download cache (gitignored)
  src/  build/                 # extracted sources and build trees (gitignored)
  library/
    <lib>.xcframework/         # the single artifact Xcode links (gitignored)
    <lib>/include/             # the canonical header dir consumers name (gitignored)
    manifests/<lib>.json       # version, source hash, flags, slice SHAs (gitignored)
```


### マトリックス（`matrix.conf`）

行指向でbashで解析可能:

```
lib        version  sha256  url   ios-archs  sim-archs  mac-archs  min-ios  min-mac  deps
```


`sha256`はダウンロードしたアーカイブのハッシュで、すべてのライブラリで固定されています。`deps`はドライバが先にビルドする他のマトリックス行を名指しします。ライブラリのビルドについて他のどこにも何もありません。ライブラリごとのフラグはレシピにあり、マニフェストにエコーされるため、「どのフラグがこれをビルドしたか?」はマニフェストだけで答えられます。

### ドライバ（`build.sh`）

* `build.sh <lib>…` — 各ライブラリを確実にビルドする（依存が先）。マニフェストがマトリックス行と一致し、すべてのスライスが存在するときは高速なノーオペレーション。
* `--all` — マトリックスのすべてのライブラリ。
* `--rebuild` — **指定された**ライブラリを強制再ビルドする。その依存は通常の鮮度チェックを保つため、1つのレシピの反復がそのチェーンを再ビルドしない。
* `--verify` — 成果物をマトリックス+マニフェストに対してチェックする。バージョンとソースハッシュ、スライスアーキテクチャ、ヘッダーの存在、各ライブラリの埋め込みバージョン文字列、加えて`lib/verify/`のライブラリごとのチェック。
* `--platforms ios,simulator,macosx` — ビルドするプラットフォームを制限する（デフォルト: 3つすべて）。

ビルドは`build/.ensure.lock.d`のロックで直列化されます（`mkdir`ロックで、古い所有者の回復付き——`flock`はmacOSにありません）。ワークスペースビルド中に複数のXcodeターゲットが並列でensureフェーズを実行できるからです。

ダウンロードはコンテンツアドレスの`media/`キャッシュに着地するため、固定されたソースは一度だけダウンロードされ、使用のたびにハッシュで検証されます。最初のビルドはネットワークアクセスを必要とし、失敗メッセージがそう述べ、tarballを名指しします。

### レシピ

各レシピは固定されたソースを`build/<lib>/source`に展開し、アーキごとにビルドし、プラットフォームごとにlipoし、`finish_library`を呼びます。それはxcframeworkを作成し、正規のincludeディレクトリをインストールし、マニフェストを書きます。xcframeworkスライス識別子ごとに1つのライブラリが`-create-xcframework`のハード制約なので、マルチコンポーネントライブラリはマージします。opensslはcrypto+sslを`libopenssl.a`にマージし、freetdsはct+sybdb+tdsを`libfreetds.a`にマージし、mariadbは単一の`libmariadbclient.a`です（Connector/Cの`libmariadb`ターゲットはUNIXで共有にハードコードされているため、レシピは`mariadbclient`静的ターゲットをビルドします）。スライスはライブラリのMach-Oロードコマンド（プラットフォームごとの`-m*-version-min`フラグ）から推測されるため、`-platform`ヒントは不要です。

レシピに触れるときに知る価値のある注記:

* **sqlite3**はホストでアマルガメーションを生成し、`sqlite3.xcconfig`から解析したオプションリストでスライスごとにコンパイルします。レシピはそのリストの*唯一の*消費者です（MADSqlite3ターゲットがかつて2番目で、それが`BUGS.md`の危険H7でした）。オプションは`.maddb`キャッシュフォーマットを固定します（ページサイズ8192、`DQS=0`、FTS5、STAT4、……）。変更はフォーマット決定として扱ってください。
* **mariadb**はスライスごとに`mariadbclient`静的ターゲットを、プラットフォームごとのopensslインストールに対して`WITH_SSL=OPENSSL`で、zlibインストールに対して`WITH_EXTERNAL_ZLIB=ON`でビルドし、`caching_sha2_password`と`sha256_password`認証プラグインを静的にコンパイルし、他のすべてのプラグインを無効にします（プラグイン`.so`は出荷されません）。DEFAULTインストールレイアウトはヘッダーを`include/mariadb`の下にネストしますが、レシピはそれらを平坦化して`mysql.h`が正規のincludeルートから解決されるようにし、そのクロスプリセットは1つの実行ベースcmakeプローブ（LibreSSLチェック）にOpenSSLの結果で答えます。
* **zint**はストックの2.16.0で、`lib/recipes/zint.sh`がcmakeでビルドします（`ZINT_SHARED=OFF`、`ZINT_STATIC=ON`、`ZINT_FRONTEND=OFF`、`ZINT_USE_PNG=ON`、レシピのlibpngとzlibにリンク）。出力は`library/zint.xcframework`です。2.4.2時代の直接コンパイルとそのローカルパッチ（`patches/zint-2.4.2-mad.patch`）は退役しました。パッチがバックポートした`ZBarcode_Encode_and_Buffer`は2.16では上流APIで、ラッパーの`BARCODE_*`名はエイリアスとして生き残ります。
* **freetds**はソースではなく*インストールされた*ヘッダーにパッチを当てます。`typedef int BOOL;`が各インストール後に`sybdb.h`からコメントアウトされます。Objective-Cがすでに`BOOL`をtypedefしているからです——しかしライブラリ自体はtypedefを保たなければなりません。dblibのCソースがそれを使うからです。
* **postgres**はクライアントインターフェースのみ（`src/common`、`src/port`、`src/interfaces/libpq`、`src/bin/pg_config`、`src/include`）を、プラットフォームごとの`openssl`インストールに対して（`--with-ssl=openssl`と明示的モジュールフラグoff）ビルドし、次に`libpq.a`、`libpgcommon.a`、`libpgport.a`を`postgres.xcframework`用の単一`libpostgres.a`にマージします。

### マニフェスト（`library/manifests/<lib>.json`）

```json
{
  "library": "openssl", "version": "3.5.0",
  "source": { "url": "…", "sha256": "…" },
  "toolchain": { "xcode": "…", "clang": "…" },
  "headers": "ios",
  "flags": "configure: no-shared no-asm no-async; opt: -O3",
  "built": "…",
  "slices": { "ios": { "archs": "…", "sha256": "…" }, … }
}
```


`headers`は正規のincludeディレクトリがどのプラットフォームの生成ヘッダーを取ったかを記録します（freetdsはプラットフォームごとに`tds_sysdep_public.h`を生成し、レガシーレイアウトが選んだようにiosコピーが正規です）。

---

## 2. Xcodeがライブラリを消費する方法

すべての消費ターゲットは1つ以上のxcframeworkをファイル参照でリンクし、ヘッダー検索パスに正規の`Compressor/library/<lib>/include`を名指しし、ビルドフェーズの最初に**Ensure Libraries**シェルフェーズを実行します。

```sh
set -euo pipefail
"${SRCROOT}/../Compressor/build.sh" --platforms ios,simulator <lib>
```


フェーズはマニフェストが新鮮なときはミリ秒でノーオペレーションし、そうでなければ欠けているものだけをビルドします。`ENABLE_USER_SCRIPT_SANDBOXING = NO`がそれを持つすべてのターゲットで固定されています。プラットフォームは`ios,simulator`に固定されます。まだmacOS向けにビルドするターゲットがないからです——マトリックスのmacOSスライスはUIKit分離が着地したときの準備ができています（`ROADMAP.md` Track 2参照）。

| ターゲット | リンク | Ensureフェーズ |
|---|---|---|
| MADSqlite3 | `sqlite3.xcframework` | `sqlite3` |
| MAD | `libarchive.xcframework`、`bzip2.xcframework`、`zlib.xcframework` | `libarchive` |
| MADMySQL | `mariadb.xcframework`、`openssl.xcframework`、`zlib.xcframework` | `mariadb` |
| MADPostgres | `postgres.xcframework`、`openssl.xcframework` | `postgres` |
| MADTds | `freetds.xcframework`、`openssl.xcframework` | `freetds` |
| MADTdsClient | Compressorから何もなし（tdsシンボルはMADTds経由） | — |
| MADBarcodes | `libpng.xcframework`、`zlib.xcframework`、`zint.xcframework` | `zint` |
| MAD Designerアプリ | `openssl.xcframework` | `openssl` |

覚えておく価値のあるヘッダーの事実: 静的ライブラリxcframeworkはヘッダーを確実に公開**しません**。そのためすべての消費者が正規のincludeディレクトリを明示的に名指しします（ヘッダーはアーカイブの完全性のためにxcframeworkにもバンドルされます）。`zint.h`、`sqlite3.h`、`libpq-fe.h`（そのコンパニオンヘッダー付き）はPublicフレームワークヘッダーで、そのファイル参照は正規のincludeディレクトリを指します。public MADヘッダーが`<MADBarcodes/zint.h>`をインポートし、`MADSqlite3`が`sqlite3.h`をエクスポートし、`MADPostgres`が`libpq-fe.h`をエクスポートするからです。

MAD Viewerターゲットのレガシー`LIBRARY_SEARCH_PATHS`リストとScrimpter（ワークスペース外）は意図的に触れられません。ビューアのリンク失敗は製品決定（`BUGS.md`参照）であり、ビルド配線ではありません。

---

## 3. 初回実行、日々の作業、およびバージョンアップ

**新しいチェックアウトでの初回実行**（または`Compressor/library/`を消した後）: 最初のXcodeビルドの前か最中に、ライブラリを一度ビルドします。

```
Compressor/build.sh --all --platforms ios,simulator
```


ダウンロードにネットワークアクセスが必要で、初回ビルドは30〜90分、そのほとんどが大きなソースtarballです。その後、Xcodeのensureフェーズはノーオペレーションになり、通常のビルドが進みます。

**成果物の検証:**

```
Compressor/build.sh --verify --all --platforms ios,simulator
```


**ライブラリのバージョンアップ:** その`matrix.conf`行（バージョン、URL、新しいアーカイブのsha256）を編集し、次に`Compressor/build.sh --rebuild <lib>`を実行し、消費フレームワークのテストスイートと`--verify`を実行します。1コミットに1ライブラリ。新しいバージョンがcmakeの実行プローブを追加する場合、mariadbプリセットは大声で失敗してそれを名指しします——推測せず明示的に答えてください。

**zint/freetds/mariadb/postgresレシピはバージョンごとの知識を運びます**（パッチ、インストール済みヘッダー編集、プローブの答え、プラグイン型名、インストールレイアウト、クライアント専用サブツリーリスト）。バージョンが上がるとき、それらが見直すべき場所です。

---

## 4. 検証コマンド

```sh
# slice inventory
for f in Compressor/library/*.xcframework/*/lib*.a; do lipo -archs "$f"; done

# version strings (each library embeds its matrix version)
strings Compressor/library/openssl.xcframework/*/libopenssl.a | grep -m1 "OpenSSL 3.5.0"

# sqlite correctness, against the BUILT framework (the H7 gate)
nm MADSqlite3.framework/MADSqlite3 | grep -c sqlite3Fts5Init     # present
strings MADSqlite3.framework/MADSqlite3 | grep -x 'DEFAULT_PAGE_SIZE=8192\|DQS=0'

# wiring cleanliness -- expect "" bases plus the MAD Viewer legacy list only
grep -rn 'LIBRARY_SEARCH_PATHS' --include='*.pbxproj' .

# the fresh-clone simulation (proves portability + on-demand building)
git archive HEAD | tar -x -C /tmp/fresh
cd /tmp/fresh
Compressor/build.sh --all --platforms ios,simulator     # bootstrap path (a)
xcodebuild build -workspace Reports.xcworkspace -scheme "MAD Designer" -destination …
Compressor/build.sh --verify --all --platforms ios,simulator
# path (b): wipe library/ xcframeworks and build in Xcode only -- the ensure
# phases rebuild everything
```


---

## 付録: リワーク前の状態（参照用）

2026-10-04以前、ライブラリは2つの重複するツーリング世代でビルドされていました。ライブラリごとの`Compressor/build_*.sh`スクリプトと1,293行の`compressor.sh`ドライバ（実行不能: 未定義変数が`set -e`下で404ダウンロードを引き起こし、宣言されたバージョンは何年も古かった）です。そして結果は**コミット**されていました。`Compressor/library/`の下に99の`.a`ファイル（約350 MB）、すべてのヘッダー、9.2 MBの`sqlite3.c`アマルガメーション、加えてMADBarcodes内の53のベンダーZintソースファイル。Xcodeはそれらをファイル参照とSDK条件付き検索パスだけで消費していたため、macOSは決して配線できませんでした（`PBXFileReference.path`はSDK条件付きではない——`BUGS.md`のエントリはxcframework再配線で閉じられます）。古いスクリプトとコミットされたツリーは、新しいシステムがすべての組み合わせをビルドし、アプリがビルドしてそのテストが新しい成果物に対して通った後にのみ、剪定フェーズで削除されます。

マトリックスが始まったベースラインバージョンとその目標更新は`TASKS.md` §6で追跡されています。
