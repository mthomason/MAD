---
layout: default
title: "Windowsでのエンジンビルド"
description: "固定されたClangとGNUstepのツールチェーン、およびネイティブWindowsエンジンビルド。"
lang: ja-JP
---

# WindowsでのMADエンジンのコンパイル — アーキテクチャと決定記録

このページはWindowsエンジンビルドを記録します。固定されたツールチェーン、フレームワークの移植とそのシム、および`Windows/Engine/build.ps1`エントリポイントです。アプリケーションガイドは`/windows.html`にあります。

*元の日付に書かれ、現状の事実は2026-11-22に整合。*

2026-11-18、Windows PoCのPhase 2である`windows-engine`ブランチのために`master`に対して書かれました。Windowsビルドは`Linux/`の兄弟です。ヘッドレスエンジンのObjective-Cフレームワークを、ClangでGNUstep Baseに対してWindows上でネイティブにコンパイルし、macOSアプリとLinux CLIを動かす同じエンジンがWindowsでも動くようにします。このドキュメントは`Linux/README.md` / `docs/project/MAD_LINUX.md`の技術的コンパニオンであり、ツールチェーンレシピ、各ピースを固定する理由、この増分が下した決定を記録します。

---

## 1. これが何であり、何でないか

ターゲットは、既存のヘッドレスObjective-CエンジンをWindows向けにネイティブにコンパイルして再利用する、ネイティブWindows MAD Designer（.NET 10 LTS上のWPF）です。エンジンビルドは`Windows/`の下に着地し、`Mac/`と`Linux/`の兄弟です。WPFアプリはPhase 5〜6f（`Windows/App`、§6e〜§6i）で続きました。

Phase 2bの増分はツールチェーンとフレームワークの移植を証明しました。Phase 2（最初の増分）は**MADDataStructures**と**MADFoundation**をビルドし、スモークテストを実行しました。Phase 2bは**MADAPI**（MADSqlite3が引き込む推移的依存）と**MADSqlite3**を追加し、固定されたSQLiteアマルガメーションを静的ライブラリにコンパイルし、MADDataStructures、MADFoundation、MADSqlite3のLinuxテストスイートをポーティングしました（GNUstep `Testing.h` + `MADTestSupport.h`）。残りのヘッドレスフレームワーク、CLI、アプリはまだビルドしていませんでした。

---

## 2. ツールチェーンレシピ、および各ピースを固定する理由

要約（このセクションは単独で成り立ちます）:

### 2.1 コンパイラ: Clang 20.1.8

Phase 1の起動クラッシュ（すべてのFoundationバイナリで`0xC0000005`）は、フローティングmasterのGNUstepコンポーネントにおけるランタイム回帰——§2.3の7つのピンがそれを修正します——であり、Clang 23のコード生成バグではありませんでした。Clang 20.1.8はCIでテストされたコンパイラであり、証明済みレシピの一部です。ピン付きのClang 22/23はテストされていません。これはピンであり、好みではありません。新しい実現可能性テストなしにLLVMをアップグレードしないでください。

### 2.2 STLゲートのオーバーライド

このマシンはVisual Studio 2026（18.12.0）を搭載し、そのMSVC STLは「Clang 22以降」をハード要求します（`_MSVC_STL_UPDATE 202609L`、`yvals_core.h:923`）。

```c
#elif defined(__clang__)
#if __clang_major__ < 22
_EMIT_STL_ERROR(STL1000, "Unexpected compiler version, expected Clang 22 or newer.");
```


オーバーライド`-D_ALLOW_COMPILER_AND_STL_VERSION_MISMATCH`はSTL自身のエスケープハッチです。無害であることが証明されています。`<map>`を使うC++プログラムはClang 20.1.8 +オーバーライドでコンパイル・実行でき、ツールチェーン全体とMADの`.mm`ファイル（`<map>`/`<vector>`を含む）も同様です。ツールチェーンビルド（`Engine/toolchain/stl-gate-override.patch`）と、フレームワークビルドのすべてのObjective-C++翻訳単位に適用されます。

### 2.3 7つの固定されたGNUstepリビジョン（フローティングmasterの回帰）

`gnustep/tools-windows-msvc`はすべてのコンポーネントの最新masterをクローンします（フェーズスクリプトで`TAG=`が空です）。そのCI（`.github/workflows/ci.yml`）はツールチェーンをビルドしてパッケージしますが、**バイナリを決して実行しない**ため、ランタイム回帰が見逃されました。A/Bテストがそれを分離しました。

| コンポーネント | 11-14（動作） | 11-17/18 master（クラッシュ） |
|---|---|---|
| libobjc2 | `a21ae931` | `762f9d7` |
| gnustep-base | `24654296` | `ff647838` |
| libdispatch | `22798930` | `20b4c8b2` |
| gnustep-make | `e7c0730d` | `8fa108c7` |
| libffi | v3.8.0 | v3.8.1 |
| libiconv | v1.19 (`a536e24a`) | v1.19.1 |

修正は、7つの既知の良好な11-14リビジョンを固定することです（`Engine/toolchain/revision-pins.patch`）。ドライバ自体もコミット`54d08e57`に固定されています（そのmasterはフローティングで、追跡してはなりません）。両方の事実は`Windows/Engine/toolchain.conf`に記録されています。

### 2.4 ビルドラッパーの3つの非自明な要件

ツールチェーンの`build.bat`は`vcvars64`開発者環境から、`BASH`をMSYS2のシェルに設定して、`build.bat`の**絶対**パスで、`PATH`を編集せずに実行しなければなりません（vcvars64の`PATH`は約2500文字で、cmdの裸名解決を壊します）。Git Bashからは`cmd //c`で`cmd`を呼びます（`cmd /c`ではなく）。PowerShellからは`cmd /c`が正しいです。`Engine/toolchain/bootstrap.ps1`が3つすべてをカプセル化します。

---

## 3. ビルドエントリポイント

`Windows/Engine/build.ps1`はリポジトリからレシピを再現します。

1. **前提条件チェック** — Clang 20.1.8、lld、CMake、Ninja、MSYS2、git、curl、tar、`llvm-lib`、VS 2026、Windows SDK、NASM。
2. **冪等なツールチェーンブートストラップ** — `Engine/toolchain/bootstrap.ps1`が固定ドライバをクローンし、2つのパッチファイルを適用し、GNUstepをソースから`C:\GNUstep`にビルドします（設定可能。初回実行で約20〜30分）。
3. **SQLiteライブラリビルド** — `Engine/libraries.conf`から3.53.3アマルガメーションをダウンロードし、sha256を検証し、展開し、`Compressor/sqlite3.xcconfig`のオプションリストで`sqlite3.c`をコンパイルし、`llvm-lib`でCOFF `sqlite3.lib`にアーカイブします。
4. **フレームワークビルド** — MADDataStructures、MADFoundation、MADAPI、MADSqlite3（および`Engine/Compat`シム）をコンパイルします。
5. **テストビルド** — ポーティングされたテストファイルごとに1つの実行ファイル（およびスモークテスト）をコンパイル・リンクします。
6. **テスト実行** — スモークテストとすべてのスイートを実行し、失敗があれば非ゼロで終了します。

フレームワークのコンパイルフラグはLinuxビルドのDebugプロファイルに一致します。`--enable-debug-by-default`下のGNUstepの`gnustep-config --objc-flags`（Linuxツールチェーンが使う）は`-DDEBUG`を運ぶため、`build.ps1`はすべての翻訳単位——ライブラリもテストも——に`-DDEBUG=1`を渡し、`NS_BLOCK_ASSERTIONS`を**定義しません**。Linuxとまったく同じように`NSAssert`をアクティブに保ちます。

**決定 — `build.ps1`はCMakeを通さずClangを直接駆動する。** Windows上のCMakeのObjective-C言語サポートは、このレシピが必要とする組み合わせ（GNUドライバの`clang`が`x86_64-pc-windows-msvc`をターゲット）で壊れています。そのObjective-CリンクプローブはGNU-ldフラグ（`--out-implib`、`-nostdlib`、`-nostartfiles`）を`lld-link`に渡し、`-l`ですでに接頭されたライブラリ名に`.lib`を追加するため、リンクが失敗します（`undefined symbol: $_OBJC_CLASS_NSObject`、およびObjCメタデータのセクションGCエラー）。証明済みレシピは直接の`clang`呼び出し——実現可能性フェーズの`compile-mad.sh` / `link-and-run.sh`——であり、`build.ps1`はそのレシピを掃除して冪等にしたものです。フレームワークごとのソースリストは依然として`Engine/cmake/<Name>Sources.cmake`（正規のCMake対応インベントリで、除外理由付き）にあり、`build.ps1`はそれを読み戻すため両者はドリフトできません。CMakeのWindows Objective-Cサポートが着地すれば、実際のCMakeビルドがそれらを変更なしで消費できます。

---

## 4. 何がコンパイルされ、Windowsシムは何か

| フレームワーク | Windowsビルド | 除外、および理由 |
|---|---|---|
| MADFoundation | 27中26（+ `madlib.c`） | `MADKeyChain`（Security.framework。Linuxですでに除外）と`BDHost`（POSIXソケットの逆引きDNS——`sys/socket.h`/`netpacket/packet.h`/`ifaddrs.h`/`arpa/inet.h`。Winsock2ポートが必要）。アンブレラは`MADKeyChain`とともに除外 |
| MADDataStructures | 17すべて | （`madmap.cpp`はXcodeターゲットにもない） |
| MADAPI | 11中8 | 3つの接続ビューコントローラ（`MADConnectionViewController`、`MADConnectionSQLGenericViewController`）——UIKitで、ヘッドレスではない。Phase 2b独自の成果物ではなく、MADSqlite3の推移的依存 |
| MADSqlite3 | 26すべて | Xcodeターゲットにもない5つの孤立`.m`ファイル（`Engine/cmake/MADSqlite3Sources.cmake`に名指し） |

`Windows/Engine/Compat/`は`Linux/Compat`のコピーで、Windows向けに適応されています。

* **`syslog.h`** — `madlog`のApple以外分岐用のノーオペレーション`syslog()`と`LOG_*`定数（`madlog.h`は`__APPLE__`が定義されていないとき`<syslog.h>`をインクルードする）。
* **`pthread.h`** — `MADOperation.m`の状態ロック用の、Windows `CRITICAL_SECTION`上の`pthread_mutex_t`（再帰）。
* **`NSData+ReadingOptions`は落とされた** — 固定GNUstep masterはすでに`NSDataReadingOptions`と`-options:error:`を運ぶため、Linuxシム（gnustep-base 1.31.1用に再宣言する）はWindowsでは重複インターフェースになる。
* **`NSPropertyListSerialization+Stream.m`**が明示的な`#import <Foundation/NSData.h>`を得る——Windowsのヘッダーインクルード順の差異（LinuxのヘッダーはたまたまNSDataに先に到達し、Windowsはそうしない）。
* **`MADCompat.h`**（force-includeされるプレリュード）は`<endian.h>` + `htonll`/`ntohll`ブロックを落とす——MADFoundationもMADDataStructuresもそれを使わず（grep検証済み）、`<endian.h>`はWindowsに存在しません。ドライバレイヤー（`MAD`）は移植時にWindowsのバイトオーダーシムを必要とします。
* **`MADCompat.h`**はまた`static inline strlcat`を得る——Windows UCRTには`strlcat`/`strlcpy`がなく（BSD/Appleの綴り。glibc 2.38+は提供するのでLinuxにはシム不要）、`MADQueryCacheAddRow.m`がそれを求めます。
* **`NSURL+FileSystem.m`**は`-fileSystemRepresentation`に`self.path.UTF8String`で答え、GNUstepの`GSNativeChar*`の綴り（WindowsではUTF-16）を使いません。それは`const char *`として偽装されると`sqlite3_open_v2`のパスを壊しました。

他のLinuxシムは変更なしで引き継がれます。WindowsとLinuxのGNUstep-baseは同じ1.31.x系だからです。

---

## 5. 避けられない共有ソース変更

2つの共有ソース変更が必要で、どちらも最小かつポータブルでした（Linux CIとAppleスイートがゲートです）。

### 5.1 `madlib.c`の`itoa`/`ltoa`/`ultoa`名前変更

`MADFoundation/Source/madlib.c`は`itoa`/`ltoa`/`ultoa`を定義し、Windows UCRTの同じ綴りの3引数非標準名と衝突します。それらは`mad_itoa`/`mad_ltoa`/`mad_ultoa`に名前変更され、すべての呼び出し元が更新されました。

* `MADFoundation/Source/madlib.{c,h}` — 定義と宣言。未使用でWindowsに存在しない`#import <strings.h>`も落とす。
* `MADFoundation/MADFoundationTests/madlibTests.m`と`Linux/Tests/madlibTests.m` — テスト。
* `MAD/Source/model/MADModelQueryTable.m`、`MAD/Source/rptq/RptqQueryTable+Extras.m`（`ltoa`）、`MADSqlite3/Source/MADDataTableFast.m`、`MADSqlite3/Source/MADQueryCacheAddRow.m`（`ultoa`）。

これは純粋な機械的名前変更で、AppleとLinuxで振る舞い中立です。`uitoa`、`reverse`、`count_digits`、`count_digits_ul`は触れられません（UCRTと衝突しません）。`MADExplorer`の`itoa`参照はコメントアウトされたブロック内にあり、呼び出し元ではありません。

### 5.2 高速列挙のカーソルポインタ

`MTStack.m`、`MTQueue.m`、`MTLinkedList.m`は`countByEnumerating…`カーソルノードポインタを`NSFastEnumerationState.extra[0]`に`unsigned long`でキャストして保存します。それはWindows（LLP64）では32ビットですがLinux/Apple（LP64）では64ビットなので、ポインタが切り詰められ、マルチバッチ列挙（1つのスタックバッファ分を超える任意のコレクション）がクラッシュするかゴミを返しました。3つのファイルは今、ポインタを`memcpy`で`extra`にコピーし（LP64とLLP64の両方で正しい）、`__unsafe_unretained`ローカルに保持します。コレクションがノードチェーンを所有し、それが呼び出しより長く生きるため、借用ポインタがすべてのプラットフォームで正直な所有モデルです。変更はApple/Linuxで振る舞い中立です（同じポインタバイトが通ります）。

---

## 6. 既知のギャップと次の増分

> このセクションは当時のPhase 1/2のギャップを記録します。Phase 3a〜6eが受け入れ済みのものを除いてすべてを閉じました。§6b〜§6h、および現在の状態については`Windows/README.md`を参照してください。

* **`BDHost`**（逆引きDNS）と**`MADKeyChain`**（Security.framework）は除外されます。`BDHost`はWinsock2ポートが必要で、`MADKeyChain`にはまだWindowsのキーチェーン同等物がありません。`BDHostTests`も同じ理由でWindowsに登録されません（`BDHost.m`なしではリンクできない）——スキップではなく記録です。
* **残りのヘッドレスフレームワーク**（`MAD`、ドライバ、`MADFileManager`、`MADCocoaExtensions`、……）と**CLI**が次の増分です。
* **WPFアプリ**は後のフェーズです。

## 6b. Phase 3a — フレームワーク、アーカイブスタック、およびCLI

Phase 3aは残りのヘッドレスフレームワーク、`.mad`コンテナのCライブラリ、および`mad.exe`をビルドします。

* **フレームワーク。** `MADCocoaExtensions`（7ファイル）、`MADFileManager`（10）、`MAD`（168）がPhase 2/2bの集合に加わり、同じLinuxソースリストと同じ除外理由（UIテール、`MADocument`、キーチェーンオペレーション、`MADCloud`）でビルドされます。`MADDirectoryMonitor`は不活性な`sys/inotify.h`シムに対してコンパイルされます——CLIは単発で変更イベントを必要としません。
* **Cライブラリ。** `zlib` 1.3.2、`bzip2` 1.0.8、`libarchive` 3.8.9（Linuxのピン）が`build.ps1`でビルドされます。zlibとbzip2は直接clang + `llvm-lib`、libarchiveはCMake + clang-cl（zlib/bzip2はin、xml2/lzma/zstd/lz4/opensslとツールはout）で、`Linux/lib/libraries.sh` / Compressorに一致します。バーコードスタック——`libpng` 1.6.59と`zint` 2.16.0——も同じ方法（どちらもCMake + clang-cl）でビルドされ、`MADBarcodes`もここでコンパイル・レンダリングされます。
* **CLI。** `CLI/Source` → `mad.exe`、whole-link。`inspect`、`schema`、`query`、`refresh`（76行）が`London.portable.mad`で実行されます。6つのエクスポートダイジェストすべてがMac/Linuxのピンとバイト単位で一致し、`write --reproducible`はMacとLinuxが書くのと同じ16261バイトのドキュメント（`09815b24…`）を書きます。

### 6b.1 2つのWindows専用ランタイム修正（Phase 3a最終）

* **`write --reproducible`（116バイトのストア読み取り）。** アーカイブライターの`open`/`read`は`Windows/Engine/Compat/unistd.h`を通り、その`open`はUCRT `_open`にマップされていました——それはデフォルトで*テキスト*モードです。SQLiteストアはオフセット116に`0x1A`（Ctrl-Z）バイトを含み、テキストモードの`_read`はそこでEOFとして止まるため、ライターは663552バイトのうち116バイトだけを見て518バイトのアーカイブを出力しました。シムは今`_O_BINARY`をフラグにORするので、`open`/`read`はPOSIXのバイト単位動作です。Windowsシムにガードされ、Apple/Linuxのバイトは変わりません。`MADArchiveManagerTests`で固定（5テスト、0ニーズ）。
* **1ユーザーでの繰り返し`export`（`.mdcache`名前変更）。** 行キャッシュ`.mdcache`は`NSInputStream`で読み、その後アトミックに書き換えられるplistです。`Compat/NSPropertyListSerialization+Stream.m`がすでに開いているストリームを2度目に開きました。GNUstepのwin32 `GSFileInputStream -open`は毎回`CreateFileW`（`FILE_SHARE_READ`）を呼び、`_loopID`を上書きして最初のハンドルをリークします。そのハンドルが後の`.mdcache`上の`MoveFileEx`をブロックし（`"being used by another process"`）、2回目のエクスポートが失敗しました。シムは今、開いているストリームを再オープンせずに読み（Appleの契約）、1ユーザーでの2回のエクスポートが両方成功します。

### 6b.2 テストインベントリ

コピーされたMAD/MADFileManager/MADCocoaExtensions/MADAPIスイートが`build.ps1`に配線されます（フィクスチャパスは`Windows/Engine/Tests`向けに適応）: **107のポーティング済みスイート + スモークテスト、966テスト、6ニーズ、5スキップ、0失敗**。6つのニーズはLinuxイメージのプラットフォームギャップに一致します。`MADDirectoryMonitorTests`（3——Windowsモニタは不活性）、`MADStoreTests`（1——Core Data + `MAD.momd`）、`RptqStoreContextTests`（2——コンバータ／ドキュメントパス）。Phase 3bドライバを必要とする4つのMADスイートは延期され、`build.ps1`に記録されます。`MADDatabaseDriverDispatchTests`、`MADQueryFullTests`、`MADSQLParserTests`、`MADQueryMaxFieldLengthTests`。5つのスキップはデフォルトスケールのSQLiteベンチマークです。

追加のWindows `Compat`シムは`unistd.h`、`dirent.h`、`libgen.h`、`sys/{unistd,fcntl,inotify}.h`、加えて`MADCompat.h`が`strlcpy`、`S_IS*`/`S_IR*`モードマクロ、`ssize_t`/`mode_t`、`M_PI`、`arc4random`、`gmtime_r`を得ます。追加の最小限の共有ソース変更（すべて`#if __APPLE__`セーフまたはLinuxでバイト中立。Linux CIとAppleスイートがゲート）:

* `MADReportSectionRepresentation.m`が空の`@finally`を落とす（clang 20.1.8のGNUstep-2.2 + ARCコード生成がそれでクラッシュした）。
* `madtar.m`が`_WIN32` mtime分岐を得る（UCRT `struct stat`は`st_mtime`を持ち、`st_mtim`はない）。
* `MADArchiveManager.m`、`MADStore.m`、`MADCLIInspect.m`が`-fileSystemRepresentation`を使っていたところで`NSString -UTF8String`を使う（GNUstepのNSStringの綴りはWindowsでUTF-16を返す）。
* `MADDatabaseConnection+Constructor.m`の`+Identifier:`が4つのドキュメントフォーマット定数を直接返すため、Sqlite3だけをリンクするプロセスでも保存された`driverID`を型にマップできます。（Phase 3bがこのガードを除去——§6c参照。）

## 6c. Phase 3b — ドライバ、BDHost、およびライブフィクスチャ

Phase 3bは4つのデータベースドライバと、それらがリンクするCライブラリを追加します。

* **Cライブラリ**（`Windows/Engine/libraries.conf`、`build.ps1` §3c）: OpenSSL 3.5.9（Strawberry Perl + `VC-WIN64A` + `nmake`、静的）、FreeTDS 1.4.27（CMake `db-lib`、`ENABLE_MSDBLIB`、`sybdb.h` BOOL編集）、MariaDB Connector/C 3.4.11（CMake `mariadbclient`、認証プラグイン静的）、libpq 17.11（**Meson + MSVC `cl.exe`**、`libpq_st` + `libpgcommon_shlib` + `libpgport_shlib`を1つのCOFF `libpq.lib`にマージ）。PostgreSQL 17はMSVCビルドを落としたため、MesonがそのWindowsパスです。`cl.exe`（`clang-cl`ではなく）を使うのは、PostgreSQLのMesonが`cc.get_id() == 'msvc'`をチェックし、`clang-cl`が`clang-cl`と報告するためで、`win32gettimeofday.c`/`dirent.c`と`win32_msvc`インクルードディレクトリが静かに落ちます。MesonとStrawberry Perlがドキュメント化された前提条件です。
* **BDHost** — `MADFoundation/Source/BDHost.m`が`winsock2.h`/`ws2tcpip.h`上の`#elif defined(_WIN32)`分岐を得ます（`WSAStartup`を一度、`getaddrinfo`/`getnameinfo`、IPv4のみ）。`+ipAddresses`/`+ethernetAddresses`はWindowsでコンパイルアウトされます。`BDHostTests`は3/3で通ります。
* **ドライバ** — 4つの`cmake/*Sources.cmake`リスト（18/1/3/4ファイル）と`<MADTds/sybdb.h>`、`<MADTdsClient/MADTdsClient.h>`、`<MADPostgres/libpq-fe.h>`などのヘッダーシム。`MADTdsDb.m`は通常どおりリンクされます（そのグローバル`err_handler`は`MADDatabaseSQLServer.m`のものと衝突します）。Phase 3aの`+Identifier:`ガードは除去され、4つのドライバすべてをリンクした状態でレジストリルックアップが機能し、`MADDatabaseDriverDispatchTests`（9/9）で固定されます。
* **テストインベントリ** — **129スイート + スモークテスト、1308テスト、6ニーズ、5スキップ（ライブコンテナが動いていないときは48）、0失敗**（バーコード増分が`MADBarcodesTests`と`MADBarcodeExportTests`を追加し、イメージクロージャが`MADImageElementTests`と`MADImageExportTests`を追加）。ローカル`127.0.0.1`コンテナに対するライブスイート: `MADMySQLLiveTests` 44/44、`MADTdsClientLiveTests` 29/29、`MADPostgresLiveTests` 14/14。CLIの`mad refresh`はMySQL 50行 / TDS 20行 / PostgreSQL 25行を返します。

## 6d. Phase 4 — stdio JSONプロセス契約

Phase 4は`mad serve`を追加します。WPFシェルが使う長命プロセス境界です。標準入力で改行区切りJSONを読み、リクエストごとに1つの改行区切りJSONレスポンスを標準出力に書きます。診断は標準エラーに留まるため、2つは決して混ざりません。ワイヤ形状は並行するものを発明するのではなく、プロジェクトの既存JSON契約を再利用します。

**リクエスト／レスポンス** — 行ごとに1つのJSON値、UTF-8、`\n`終端:

```text
request:   { "id": <int|string>, "method": "<name>", "params": { … } }
ok:        { "id": <id>, "ok": true,  "result": { … } }
error:     { "id": <id|null>, "ok": false, "error": { "code": <int>, "message": "…" } }
```


`id`はクライアントが選び、相関のためにエコーバックされます。不正なリクエストは`"id": null`で答えます。`error.code`はCLIの終了コード（MADCLI.h）です。1は使用法／プロトコル、2は悪いドキュメント、3はデータベース到達不能、4はクエリ失敗、5はエクスポート失敗。不正な行、不明なメソッド、欠けたパラメータ、予期しないエンジン例外はすべて`ok: false`とメッセージで答え——トレースバックは決して返さず——セッションは動き続けます。

**メソッド:**

| メソッド | パラメータ | 結果 |
|---|---|---|
| `open` | `path`、任意の`host`/`port`/`database` | `handle`、`filename`、`driver` |
| `create` | `path`、`driver` + 接続フィールド、任意の`credentials` | `handle`、`filename`、`driver`（作成されたドキュメント） |
| `test-connection` | `driver` + 接続フィールド、任意の`credentials` | `tableCount` |
| `describe` | `handle` | `driver`、`columns`（key/name/table/type）、`tables`（名前+フィールド） |
| `connection` | `handle` | `driver` + `file`/`host`/`port`/`database`/`server` |
| `apply-connection` | `handle`、`driver` + 接続フィールド、任意の`credentials` | `{}` |
| `query` | `handle` | `sql` |
| `query-model` | `handle` | `driver`トークン、`sql`、`sqlSourceText`、`tables`/`links`/`predicates`/`groups`（ストア識別子付き） |
| `add-table` | `handle`、`table`（スキーマ名） | 完全な`query-model` |
| `remove-table` | `handle`、`table`（クエリテーブルID） | 完全な`query-model` |
| `add-link` | `handle`、`leftField`、`rightField`（フィールドID） | 完全な`query-model`（デフォルトはLeft Outer Join） |
| `set-link-type` | `handle`、`link`、`type` | 完全な`query-model` |
| `swap-link` | `handle`、`link` | 完全な`query-model` |
| `delete-link` | `handle`、`link` | 完全な`query-model` |
| `add-predicate` | `handle`、`leftField`、`operator`、`value` | 完全な`query-model` |
| `remove-predicate` | `handle`、`predicate` | 完全な`query-model` |
| `add-group` | `handle`、`field`、`sort` | 完全な`query-model` |
| `remove-group` | `handle`、`group` | 完全な`query-model` |
| `validate-sql` | `handle`、`sql` | `tables`、`links`、`predicates`、`groups`（プランのカウント） |
| `apply-sql` | `handle`、`sql` | `tables`、`links`、`predicates`、`groups` |
| `refresh` | `handle`、任意の`rows`/`credentials` | `rowCount`、`elapsed` |
| `export` | `handle`、`format`、任意の`path`/`deterministic` | `format` + `data`（エクスポーターのバイト）または`path` + `bytes` |
| `write` | `handle`、`out`、任意の`reproducible` | `path`、`bytes`——ライブドキュメントをシリアライズ |
| `shutdown` | — | `{}`、その後プロセスは0で終了 |

接続メソッド（`create`、`test-connection`、`connection`、`apply-connection`）は`driver`トークン——`sqlite3` | `mysql` | `sqlserver` | `postgres`——とドライバ固有フィールドを取ります。SQLiteは`file`を、サーバードライバは`host`/`port`/`database`（SQL Serverは任意の`server`インスタンスも）を取り、加えて既存の`credentials`（`user:password`）文字列を取ります。それらはエンジンの`createDocumentAtURL:`、`MADDatabase`（connect/getTables/close）、`applyDatabaseConnection:`を再利用します——Macの接続ウィンドウが呼ぶのと同じ呼び出しです。

`export`はエクスポートシーム（`MADReportExporting` / `MADReportExporterRegistry`）であり、新しいスキーマではありません。`format: "json"`は`mad export --format json`が書くのと正確に同じ`mad.report/1`バイト（`MADReportExporterJSON`——`columns`と`rows`）を返し、`format: "csv"`はRFC 4180バイトを返します。このビルドが生成できないフォーマット（例えばApple以外の`pdf`）はエクスポーターの理由とともに`error.code` 5で答えます。`describe`の`columns`は同じ`mad.report/1`列（`MADReportExportSource`）で、その`tables`は`mad schema`が出力する保存されたデータベーススキーマです。`open`は`host`/`port`/`database`を単発動詞と同じように適用するため、チェックインされたドキュメントをセッションのために別のサーバーに対して実行できます。`write`は今`sourceURL`を再オープンするのではなくライブセッションドキュメントをシリアライズするため、セッション内で適用された接続が永続化されます。標準入力のEOFはクリーンなシャットダウンで、`shutdown`も同様です。

`query-model`/`add-table`/…/`apply-sql`メソッドはPhase 6bのQueryワークスペース拡張です。元の`serve`契約はクエリを生成された`sql`としてのみ公開し、Macは`RptqQuery`オブジェクトをインプロセスで変更してそれを導出します。WPFアプリにはそのようなインプロセスのハンドルがないため、これらのメソッドがそのギャップを閉じます。`query-model`は完全なクエリモデル——テーブル／フィールド／リンク／述語／グループとそのストア識別子、入力された`sqlSourceText`、ドライバトークン——を読み、すべての変更メソッドが同じ形で答えるため、クライアントはスナップショットをアトミックに置き換えます。変更はMacの`MADMacQueryViewController`が使うのと同じファクトリと`MADSQLQueryDocument`ヘルパーを呼び（`newQueryTableForSchemaTable:`、`newQueryLinksWithLeftField:`、`addQueryGroupWithQueryField:`、`removeGroupWitObjectID:`、……）、`validate-sql`/`apply-sql`は既存の`MADSQLParser` → `MADSQLStatementResolver` → `MADSQLQueryCompiler`パスを変更なしで実行します。`query`は今、全フィールドSQLを先に返し、アクティブフィールド選択にフォールバックします。Macの`generatedSQLString:`に一致するため、レポート要素のない新しいドキュメントでもSQLを生成します。

**クライアントとテスト。** `Windows/Client/`は.NET 10コンソール受け入れクライアント（`Mad.Client`）とxunitスイート（`Mad.Client.Tests`）を保持し、どちらも`Windows/global.json`で固定されています。クライアントは`mad serve`を起動し、7つのメソッドをカバーします。テストは`CLI/Fixtures/London.portable.mad`上の成功パス（open → describe → query → refresh 76行 → export json/csv → shutdown、終了0、孤児プロセスなし）、不正なリクエスト、不明なメソッド、悪いドキュメント、利用不可のフォーマット、プロセスシャットダウンを行使します。

## 6e. Phase 5 — WPFシェルの証明

Phase 5はPhase 4のプロセス境界の上に最初のWPFアプリを追加します。`Windows/App/`の`net10.0-windows`シェルで、エンジンが実際のUIから動くことを証明します。`Mad.Client`を変更なしで再利用し、非同期`EngineService`（`SemaphoreSlim`がシングルスレッドのラインプロトコルを直列化し、すべてのブロッキング呼び出しがスレッドプールで実行）、手作りのMVVMレイヤー（`ObservableObject`、`RelayCommand`、`AsyncRelayCommand`）、および最初のスライスのためにMacの`MADMacDocument`をミラーする`DocumentViewModel`を追加します。open → describe → query → refresh → export。

シェルは3ワークスペースのフレーム（MAD Query / Designer / Viewer）を持ちます。Queryは保存されたスキーマと生成SQLを表示し、Viewerはリフレッシュされた行を`DataGrid`（`mad.report/1`を`DataTable`にパースして供給）で表示しCSV/JSONをエクスポートし、DesignerはPhase 6のプレースホルダです。起動時に`CLI/Fixtures/London.portable.mad`を自動オープンする（`MAD_DOCUMENT`で上書き）ため、ゼロクリックでデモできます。Aboutウィンドウ（Overview / License & Notice / Acknowledgements）は`ThirdParty/Licenses/Windows/`のWindows依存レジスタと再リンクの申し出をレンダリングします——Windowsのコンポーネント集合であり、Appleのものではありません。

受け入れは`Windows/App/Mad.Designer.Windows.Tests`（xunit）でヘッドレスに検証されます。open London → describe（21列 / 11テーブル / ドライバ"Sqlite 3"）→ refresh 76行 → export json（76行）/ csv（78行）→ 孤児なしのクリーンシャットダウン、加えて`mad.report/1`パーサとライセンスレジスタチェック。アプリとテストは`net10.0-windows`でビルド・実行されます（`Windows/global.json`で固定）。Linux CIは影響を受けません（.NETを決してビルドしない）。

## 6f. Phase 6c — レポートレイアウトモデル（Designer）

Phase 6cは`serve`をDesignerワークスペースが編集するレポートレイアウトモデルで拡張し、6bのクエリモデルメソッドと同じ粒度パターンを使います。`layout-model`は完全なスナップショットを読み、すべての変更メソッドが既存の`RptqDocumentSection`/`RptqDocumentElement`オブジェクトを変更して同じスナップショットで答えるため、クライアントは状態をアトミックに置き換えます。バーコードはモデルの一部です（バーコードクロージャ増分が要素種別、そのコンテンツ編集、シンボロジカタログ、エンジンレンダリングのプレビュー、WPFコンポーザを追加——§6j。画像クロージャはPNGコンテンツとWPFファイルピッカーで続いた——§6k）。色は延期されます（ヘッドレスモデルにポータブルな色型がない）。元に戻す／やり直しはクライアント側です。

| メソッド | パラメータ | 結果 |
|---|---|---|
| `layout-model` | `handle` | `paperSize`、`sections[]`、`elements[]`、`fields[]` |
| `add-element` | `handle`、`kind`（`label`\|`data-field`\|`aggregate`\|`image`\|`line`\|`barcode`）、`section`、`x`、`y`。画像の場合は`data`（base64 PNG） | 完全なスナップショット |
| `remove-elements` | `handle`、`elements: [id…]` | 完全なスナップショット |
| `duplicate-elements` | `handle`、`elements: [id…]` | 完全なスナップショット |
| `move-elements` | `handle`、`elements: [id…]`、`section` | 完全なスナップショット |
| `set-element-geometry` | `handle`、`elements: [{id,x,y,w,h}…]` | 完全なスナップショット |
| `set-element-content` | `handle`、`element`、`content{text,field,function,scope,group,barcodeType,humanReadable,borderStyle,data}`（`data`は画像のbase64 PNG。空はクリア） | 完全なスナップショット |
| `set-element-typography` | `handle`、`elements: [id…]`、`style{fontname,fontsize,bold,italic,underline,strikethrough,hAlign,vAlign}` | 完全なスナップショット |
| `set-element-box-model` | `handle`、`elements: [id…]`、`box{borderTop,borderBottom,borderLeft,borderRight,padding,margin}` | 完全なスナップショット |
| `set-section` | `handle`、`section`、`{height,visible,pageBreak}` | 完全なスナップショット |
| `set-paper-size` | `handle`、`paperSize`（`MTPaperType` int16: Letter 2 / Legal 7 / A4 19） | 完全なスナップショット |

スナップショットはセクションをデザイナの正規順（Report Header、Page Header、Group Headers、Detail、Group Footers、Page Footer、Report Footer）で運び、それぞれ`id`、`type`（`MADocumentSectionType`）、`title`、`height`（インターフェース高`layoutHeight`）、`visible`、`pageBreak`、`groupField`を持ちます。各要素は`id`、`type`（`MADPrintPageElementType`）、`section`、`x/y/w/h`、`text`、`field`（バインドされたクエリフィールドID）、`table`/`column`、`function`/`scope`/`group`（集計）、`fontname`/`fontsize`、`bold`/`italic`/`underline`/`strikethrough`、`hAlign`/`vAlign`、`borderTop`/`borderBottom`/`borderLeft`/`borderRight`、`padding`、`margin`を持ちます。バーコード要素はさらにネストされた`barcode`オブジェクト（§6j）を運び、画像要素は`image{data}`、保存されたピクチャをbase64 PNGとして運びます（持たない場合は空——§6k）。`fields[]`はサイドバーブラウザとバインディングポップオーバーのためにクエリフィールド（ストアID付き）を一覧します。

## 6g. Phase 6d — Viewerワークスペース（レンダリング、ページサイズ、エクスポート、印刷）

Phase 6dは6a〜6cのシェルの上にMAD Viewerを完成させます。Macビューアはページ分割PDFを`PDFView`でレンダリングしますが、WindowsにはPDFKitがないため、プレビューはエンジンのHTMLファクシミリをレンダリングし、PDF自体はエクスポート時にエンジン自身のエクスポーターが書きます（§6l）。

* **レンダリングアプローチ — エンジンのHTMLエクスポーター上のWebView2。** プレビューは正確な`export --format html`バイト（ページごとに1つの`<div class="page" data-index="N">`ボックス、PDFと他のすべてのエクスポーターが使うのと同じフォーマッタ）をWebView2でホストして表示します。ステータス行のページ数はそれらのページボックスの数なので、エンジンが唯一のページネータのままで、エクスポーターがC#で再実装されることはありません。プレビューは注入されたスタイルを通じてプレゼンテーション用のクローム（灰色のデスク、ページの間隔と影）だけを追加し、エクスポートされるバイトは変わりません。HTMLは一時ファイルに書かれ、URLでナビゲートされます。`NavigateToString`には2 MBの上限があり、大きなレポートがそれに当たるからです。ズームはWebView2の`ZoomFactor`、ページナビゲーションは要求されたページボックスをビューにスクロールします。**Print**は`CoreWebView2.ShowPrintUI`——暫定のHTML印刷パス——を使います。ブラウザはXAMLではなく`Loaded`で作成されるため、ワークスペースはテストのためにヘッドレスで構成できます。
* **`ViewerViewModel`**はページサイズ選択とそのレンダリングロック（US Letterデフォルト、US Legal、A4）、ズームステップ（0.25〜4.0、1.25×、100%リセット）、前後ナビゲーション、エクスポートフォーマットカタログ、ステータス行を所有します。ステータス行はMacのものです。`Rendered N pages from M cached rows.`とその単数／複数文法で、成功時は緑、失敗時は赤。用紙サイズを選んでも次のリフレッシュまでレンダリングされたレポートは変わらず（Macの`selectedPaperType`/`renderedPaperType`の分割）、選択はリフレッシュを生き延び、エクスポートはレンダリングされた用紙を使います。
* **エクスポート**はこのビルドが生成する7つのフォーマットをMacビューアの順序で提供します。PDF Document、HTML Page、HTML Flow、CSV、JSON Data、JSON Full Report、Plain Textで、それぞれ独自のファイル拡張子（`pdf`、`html`、`html`、`csv`、`json`、`json`、`txt`）を持ちます。ツールバーにフォーマットセレクタがあり、Exportは選択されたフォーマットでフィルタされた保存ダイアログを開きます。PDFは`serve`のパス形式（`path`付きの`export`）を通るため、エンジンがエクスポーターのバイトを選ばれたファイルに書き、レスポンスはバイト数のみを運びます。テキストフォーマットが使う`data`読み戻しはUTF-8で、バイナリPDFを破損するからです。リフレッシュ前のエクスポートはMacのExportと同様に先にリフレッシュし、エクスポート中はステータスバーが不確定プログレスバーと「Exporting…」行を表示します（コマンドは無効。`serve`は進捗をストリームせず、エクスポートは単一リクエストです）。
* **ドキュメント統合。** `DocumentViewModel.RefreshAsync`はクエリを実行し、次に`Viewer.RenderAsync`を呼びます。それは選択された用紙をドキュメントを通じて適用し（Designerのスナップショットが追従する）、HTMLプレビューをロードします。ViewerのRefresh、Export、Printボタンはすべて同じドキュメントパスを通ります。
* **エンジン修正。** `set-paper-size`は保存された`RptqDocument`を変更しましたがレンダードキュメントは変更しませんでした。その`MTPaper`は最初のレイアウト後にキャッシュされるため、2回目の用紙変更がエクスポートに届きませんでした。それは今、レンダードキュメントで`setPaperType:`も呼び（Macビューアがリフレッシュ前に呼ぶ呼び出し）、すでにレイアウトされたレポートを再フォーマットするため、新しいサイズが別のリフレッシュなしで続くエクスポートに届きます。

ViewerはPhase 5のプレースホルダ行グリッドを置き換えます。レンダリングされたレポートがワークスペースであり、Macと同じで、行はCSV/JSONエクスポートを通じて引き続き利用できます。

**テスト。** `ViewerViewModelTests`（ステータス文法、フォーマットカタログ、ページカウント、ズーム、ナビゲーション、印刷リクエスト）、`ViewerSurfaceTests`（STAスレッドで具現化されたワークスペース——ツールバー、7つのフォーマット、ページサイズセレクタ、ステータス色、ページラベル）、およびエンジンに対する`ViewerAcceptanceTests`（London → 5ページ / 76キャッシュ行、A4を通じたページサイズロックと永続化でエクスポートされたページボックスが595 × 842、各エクスポートフォーマットとその拡張子、PDFは`%PDF-`シグネチャでチェック、スペースと非ASCII文字を含むパスへのエクスポート、PDF書き込み中に設定され後にクリアされるexporting状態、A4 → Legal → Letterの用紙サイズ切り替えが各エクスポートに届く）。

## 6h. Phase 6e — About、ローカライゼーション、およびWPFスモークテスト

Phase 6eはエンジンを変えずにマージゲートを閉じます。Aboutウィンドウの依存レジスタを完成させ、WPFアプリをMacアプリの言語集合にローカライズし、`MADMacSmokeTest.m`のWPF対応物を追加し、この記録と`Windows/README.md`を最新にします。公開`docs/windows.md`とその翻訳は設計上延期されます。

**AboutとWebView2の通知。** Viewerプレビューは**Microsoft Edge WebView2**コントロール（NuGet `Microsoft.Web.WebView2` 1.0.4314.35）で実行されます。アプリに同梱されるSDKはBSD-3-ClauseでMicrosoftのサードパーティ通知を運び、Evergreen WebView2 RuntimeはMicrosoftの再頒布可能物でありオープンソースソフトウェアではありません。したがってAboutウィンドウは`Microsoft Edge WebView2`を両方の条項とランタイムの帰属とともに一覧し、すべて`ThirdParty/Licenses/Windows/WebView2-LICENSE.txt`にあります。レジスタは`docs/project/THIRD_PARTY_LICENSES.md` §10です。残りのコンポーネントリストは変わりません（GNUstep Base、gnustep-corebase、libiconv、libobjc2、libdispatch/BlocksRuntime、libffi、およびCライブラリ）で、LGPL再リンクの申し出は依然としてWindowsエンジンを名指しします。WPFアプリはAppleの集合を決して表示しません。

**ローカライゼーション。** すべてのユーザー向け文字列は`Windows/App/Mad.Designer.Windows/Resources/`のWPF `ResourceDictionary`に存在します。`Strings-en.xaml`が権威あるソースで、`Strings-de.xaml`、`Strings-es.xaml`、`Strings-ja.xaml`、`Strings-pt-BR.xaml`、`Strings-zh-Hans.xaml`がMacアプリの言語集合をミラーします（`MAD_APP_LOCALIZATION.md` D1/D9）。辞書はメインアセンブリに埋め込まれ（コンパイルされた`Page`項目でもサテライトアセンブリでもない——`Strings-de.xaml`のハイフンがMSBuildに言語コードをカルチャサフィックスとして読ませないようにします）、`Infrastructure/Localizer.cs`が`XamlReader`でそれらをロードし`Get`/`Format`を提供します。XAMLはロード時に解決される`{infra:Loc Key}`マークアップ拡張を通じてそれらを消費し、コードビハインドとビューモデルは`Localizer`を呼びます。言語は起動時にOS UIカルチャに従い（`de`、`es`、`ja`、`pt-BR`、`zh-Hans`。それ以外は英語）、検査のために`MAD_LANGUAGE`が上書きします。

```powershell
$env:MAD_LANGUAGE = "de"
dotnet run --project .\Windows\App\Mad.Designer.Windows\Mad.Designer.Windows.csproj
```


翻訳は英語ソースが一致する場合Macの`Localizable.xcstrings`を再利用し、その後機械支援ポリシー（MAD_APP_LOCALIZATION.md D14）に従います。About Overviewは各言語で翻訳が機械支援であり誤りを含む可能性があるという通知で終わります。Aboutのクローム、接続アシスタント、クエリ／デザイナ／ビューアのツールバーとステータス行、ダイアログ、バンド名は翻訳され、ライセンス本体、コンポーネント通知、LGPL再リンクの申し出、著作権、ブランド名は逐語的な英語のままです（D6/§8）。ライセンステキストが元の英語で再現されていることを述べるローカライズされた文が付きます。SQLキーワード、データ型名、フィールド／テーブル識別子は翻訳されず、エンジン自身が返すエラーテキスト（ドライバ失敗、SQLパーサメッセージ）はMacのドライバメッセージと同じく英語のままです。

**スモークテスト。** `Windows/App/Mad.Designer.Windows.Tests/SmokeTests.cs`は`MADMacSmokeTest.m`のビューモデル／サービスレベルの対応物で、ピクセルテストではありません。

1. **London。** `CLI/Fixtures/London.portable.mad`を開き、76行（5ページ）をリフレッシュし、Viewer自身のパスを通じてHTML Page、HTML Flow、CSV、JSON Data、JSON Full Report、Plain Textをエクスポートします。各ファイルのバイト数とSHA-256は`Linux/README.md`のMac/Linuxピン（`html` `285541ed…`、`html-flow` `0565204a…`、`csv` `773f6215…`、`json` `569c6ee2…`、`json-report` `9d01d0da…`、`text` `7dcee96c…`）に対してアサートされます。
2. **新しいドキュメント。** `chinook.sqlite3`から`.mad`を作成し、MacのSQLステートメント（`SELECT Customer.FirstName, Customer.LastName, Customer.City FROM Customer WHERE Customer.Country = 'United Kingdom';`）を適用し、静的ラベル、`LastName`にバインドされたデータフィールド、レポートスコープのCOUNT集計を追加し、リフレッシュし、利用可能なすべてのフォーマットをエクスポートしてJSON行数とHTMLページ数をチェックします。

Viewerは両方のテストでエンジンのパスエクスポートを通じてPDFをエクスポートし、スモークテストはテキストとして読むのではなく`%PDF-`シグネチャをチェックします。スイートはアプリの他のテストとともにヘッドレスで実行されます。`Windows/README.md`を参照してください。

## 6i. Phase 6f — テーマ、シェル、およびユーザビリティパス

Phase 6fはプレゼンテーションのみです。エンジン、プロトコル、ドキュメント、ワークフローの変更はありません。デザインレビューが報告した2つの機能的不具合を修正し、既存の3ワークスペースアーキテクチャ全体に1つのFluentにインスパイアされたデザインシステムとシェルを適用します。（テーマパスはマージゲートの一部ではなく、それに続きます。）

**修正された不具合。** Help ▸ Aboutがプロセスを終了しました。Aboutウィンドウの読み取り専用`Overview`、`LicenseNotice`、`SelectedAcknowledgement`が`TextBox.Text`にバインドされ、そのデフォルトバインディングモードがTwoWayで、バインディングがウィンドウの最初のレイアウト中に`InvalidOperationException`を投げました。バインディングは今OneWayで、`AboutWindowTests`がウィンドウを表示して固定します。Designerのドラッグ不具合はZオーダーでした。各バンドの不透明な背景がその要素とともに追加されたため、後のバンドにドラッグされた要素がそのバンドの下に描画され、ドロップがキャンバスを再構築するまで消えました。リサイズハンドルも古い位置に留まりました。ドラッグされた要素は今すべてのバンドの上に描画され、ドラッグ中はハンドルが隠れ、選択クロームは再構築ではなくその場で更新され、ScrollViewerのオフセットは再構築をまたいで保たれ、ドラッグの計算はズーム2でビューをスクロールした状態で固定されます。

**デザインシステム。** `Themes/Theme.xaml`が単一のリソースセットです。タイポグラフィ（Segoe UI Variable Text/Display、Fluentサイズ）、スペーシング、コーナー半径、サーフェス、コマンドとナビゲーションのスタイル、プライマリ／セカンダリボタン、セグメント化トグル、フォームとカードのスタイル、セマンティックステータス色。クロームブラシはFluentの動的リソースキーなので、ライト／ダーク、ユーザーのアクセント、ハイコントラストがシステムに従います。`App.xaml`は`ThemeMode="System"`でネイティブFluentテーマにオプトインします（実験的APIの`WPF0001`は抑制されます）。レポートドキュメントは独自の固定パレットを保ちます。`Infrastructure/DesignPalette.cs`は紙、要素の色合い、選択アクセント、結合、ミニマップの単一の凍結されたソースです。`MAD_THEME=Light|Dark`は`MAD_LANGUAGE`と同様の検査用上書きで、ViewerのWebView2デスクがそれに従います（またはWindowsのAppsUseLightTheme設定）。

**シェル。** アプリケーションアイコンは既存のMADアートワーク（`Assets/AppIcon.png`とマルチサイズ`AppIcon.ico`）から生成され、ウィンドウ、タスクバー、Aboutのアイデンティティです。レポートなしで起動すると、空のViewerではなくWelcome/Home画面（New report、Open report、最近のレポート、短い紹介）を表示します。3つのワークスペースはアイコン+ラベル、明確な選択状態、Ctrl+1/Ctrl+2/Ctrl+3を持つNavigationViewスタイルの左レールで、Welcome表示中は無効です。新しく作成されたレポートはDesignerで開き、既存のレポートはViewerで開きます。Homeの目的地はありません。3つのワークスペースが第一級のピア集合のままです。FileメニューはNew/Open/Save/Save As/Recent/Connection/Exitを保ち、コマンドバーはNewとOpenを保ちます（AboutはHelpに残ります）。

**ワークスペース構成。** 接続アシスタントは固定の640 × 660ウィンドウ（リサイズ可能、本体はスクロール）で、グループ化されたカードがドライバ固有のフォームを同じフレーム内に保ちます。SQLite → MySQL/SQL Server/PostgreSQLの切り替えでリサイズされません。Queryはセグメント化されたDesigner/SQLスイッチ、グループ化されたコマンド、テーブルパネルのヘッダーにある通常サイズのAdd tableコマンド、イン／アウト、パーセンテージ、Fitを持つ下部ズームバーを持ちます。Designerは挿入と編集コマンドをグループ化し、ミニマップを左上隅からインスペクタ上部の折りたたまれたExpanderに移し、ズーム／グリッド／スナップ／ルーラーを下部ビューバーに置きます。Viewerはドキュメント／ページ／出力コマンドを上部に、ズーム、ページナビゲーション、ステータス／用紙行を下部に置き、レポートに最大の領域を与えます。

**About。** ウィンドウは今2つの異なるアイデンティティを報告します。エンジン（`v9.0 (r4433)`）とWindowsアプリケーション（`v0.7`）。確定した決定は、エンジンが成熟している一方でWindowsアプリケーションは1.0前であるということです。

**アクセシビリティとローカライゼーション。** ナビゲーションとコマンドの表面はツールチップ、アイコンが曖昧な場所のテキストラベル、UI Automation名（アイコンのみのズームとページボタンを含む）、キーボードショートカット、Fluentのフォーカスと無効状態を持ちます。新規または名前変更されたすべての文字列は6つの辞書すべてにあります（`LocalizerTests`が完全性とプレースホルダをチェック。英語が権威あるソースのまま）。ライセンス本体、通知、著作権、ブランド名は逐語的な英語のままです。スイートは110テストで、Welcome／ナビゲーション／最初のワークスペースのテスト、Aboutウィンドウ表示テスト、テーマ辞書テスト、クエリズーム／フィットテストを含みます。

**リボンの評価。** リボンは導入されませんでした。Designerのコマンド表面は2つのグループ（挿入パレット、編集）とビューバーです。リボンはクロームを追加し、このコマンド数では発見性の向上なしにキャンバス領域を奪います。Designer専用リボンは、要素／コマンド集合が大幅に増えた場合（例えば完全なタイポグラフィ、配置、テーブルレイアウトグループ）にのみ再検討する価値があります。3つのワークスペースは実質的に異なるコマンドを持つため、アプリ全体のリボンはより複雑になり、より単純にはなりません。

**未完了（記録、不具合ではない）。** 4つ目のHome目的地なし、アプリ内のWelcomeへのクローズなし。ViewerのWebView2デスク色はブラウザ作成時に読まれるため、セッション途中のテーマ切り替えには再起動が必要です。ブリーフで名指しされた参照WPFアプリケーションはワークステーションに存在しませんでした。方向性はMicrosoftのWindows 11デザインガイダンス、ネイティブFluentテーマ、既存のMADアートワークに従い、パレットとスペーシングは簡単な再調整のために一元化されています。公開`docs/windows.md`とその翻訳は延期されたままです。

## 6j. バーコードクロージャ（2026-11-20）

バーコード要素はもはや境界のどちら側のギャップでもありません。

**エンジン。** `MADBarcodes`はここでコンパイルされます（すべてのシンボロジサブクラス。`MADBarcodeView`と`MADBarcodeCache`はApple専用のまま）。`libraries.conf`からlibpng 1.6.59とzint 2.16.0をリンクします。`MADBarcode`のエンコードパスは共有され、`-renderedPNGData`はCore GraphicsなしでzintのRGBビットマップをlibpng経由で書くため、ヘッドレスエンジンは同じシンボルを生成します。`MADPrintPageElementBarcode`、`RptqDocumentElementBarcode+Extras`、`MADDocumentObjectDataReferenceBarcode`はヘッドレスビルドにあり、ページウォークはPNGを`MADReportLineRepresentation.imageData`に置き、HTMLファクシミリはそれをデータURIとして埋め込み（入力は`alt`テキスト）、JSONレポートは`"image": true`で名指しします。`useStaticInput1`/`inputStatic1`を持つバーコードはその文字列をレンダリングし、バインドされたものはクエリフィールドを読みます。

**serve。** `add-element`は`"kind": "barcode"`を受け入れ（Code 128、人間可読、静的`MAD-2026`、160×48、Macのデフォルト）、`layout-model`はネストされた`"barcode"`オブジェクト（シンボロジIDと名前、オプション、入力バインディング、同じレンダーコアからのbase64 PNG `preview`）を運び、`set-element-content`はシンボロジ、人間可読フラグ、ボーダースタイル、静的かフィールドかのバインディングを編集し、`duplicate-elements`はバーコード列をコピーし、`barcode-types`はMADBarcodeの名前テーブルを名前順の`{id, name}`として返します。

**WPF。** パレットのBarcodeボタンが1つを挿入し、キャンバスはエンジンのプレビューを描画し（zintが拒否した場合はテキストフォールバック）、インスペクタはシンボロジピッカー、Show text、ボーダーピッカー、入力ピッカー（静的——Textボックスが編集する——またはクエリフィールド）を表示します。`DesignerAcceptanceTests.Barcode_InsertEditBindAndUnbind`と作成ドキュメントのスモークテストがそれを固定し（HTML/JSONエクスポートがシンボルとそのテキストを運ぶ）、バーコードのないドキュメントのバイトは動かなかったためLondonのバイトピンは変わりません。

**ライセンス。** zint（BSD-3-Clause）とlibpng（PNG Reference Library v2）は§10、Aboutウィンドウのコンポーネントリスト、`ThirdParty/Licenses/`にあります（両方のテキストはすでに存在しました）。

## 6k. 画像クロージャ（2026-11-20）

画像要素はプレースホルダであることをやめます。ライブラリは追加されませんでした。ストアの画像列はすでにPNGバイトを保持しています。

**エンジン。** Apple以外では`MADReferenceImage`と`MADElementImage`は`NSData`——ストアのワイヤフォーマットそのもの——であるため、モデルはヘッドレス対応で、`RptqDocumentElementImage (Extras)`はポータブルな`-pngData` / `-setPngData:`を得ました。それはすべての場所でバイトをそのまま保存します（Appleの`-image`アクセサはUIKit/AppKitが存在する場所で依然としてピクチャをコード／デコードします）。`MADPrintPageElementImage -renderedImageData`は保存されたPNGを返すため、`MADReportLineRepresentation.imageData`——バーコードクロージャのシーム——はピクチャも運びます。HTMLファクシミリはそれを`data:image/png;base64,…` URIとして埋め込み、JSONレポートはテキストなしで`"image": true`と名指しします。AppleではPDFパスが依然として要素を描画し、`-renderedImageData`はnilを返します。それは既存のMacエクスポート振る舞いです。

**serve。** `add-element`は任意のbase64 `"data"`付きで`"kind": "image"`を受け入れ（要素が挿入される前にデコードされるため、不正なリクエストは何も残しません）、`layout-model`はネストされた`"image"`オブジェクト`{data}`を運び、`set-element-content`は`"data"`（base64 PNG。空はクリア）を受け入れ、`duplicate-elements`はピクチャをコピーします。

**WPF。** パレットのImageボタンが要素を挿入し、インスペクタは選択された画像にローカライズされた「Choose Image…」ボタンを表示します（Macインスペクタの行）。ピッカーはWICを通じて任意のPNG/JPEGをデコードし、送信前にPNGとして再エンコードします（`ImageFileEncoder`）。列は常にPNGなので、HTMLデータURIは正直です。キャンバスは保存されたピクチャを描画し、要素にない場合は`[Image]`プレースホルダにフォールバックします。`ImageElementTests`がプロトコル、ピッカーの再エンコード、キャンバスを固定し、作成ドキュメントのスモークテストがエクスポートされたドキュメントに1つを追加します。

## 6l. PDFクロージャ（2026-11-20）

`mad export --format pdf`と`mad serve`の`export`が今WindowsでPDFを書き、Windows半分はビルドが運ぶ3つ目のヘッドレスライブラリスタックです。

**ライブラリ。** `Windows/Engine/libraries.conf`はLinuxのピンを正確に固定します。pixman 0.46.4とcairo 1.18.6（gitタグ、コミット固定）、FreeType 2.15.0（tarball）、加えてLiberation 2.1.5フォントtarball。`build.ps1`はFreeTypeを自身のCMake（clang-cl、静的、コアのみ）でビルドし、次にpixmanとcairoをMSVC環境（`cl`）下でMesonで、静的かつPDFサーフェスのみでビルドします。Mesonビルドは生成された`.pc`ファイルと、libpqビルドが導入したのと同じWindowsネイティブpkg-configシム（`Ensure-PkgConfigShim`、今は関数で両ビルドが共有）を通じてローカル依存を見つけます。3つのアーカイブがリンクに加わります。`cairo.lib`、`freetype.lib`、`pixman-1.lib`。`msimg32`がcairoのwin32サーフェスのためにシステムリストに加わります。

**フォント。** Liberationフェイスは`Engine/build/fonts`にコピーされ、`MADReportExporterPDFCairo`は`<exe>/fonts`を最初に検索し（`mad.exe`が`build/fonts`を見つけ、`build/tests`のテストが`<exe>/../fonts`を通じて`build/fonts`を見つける）、次にインストール済みレイアウトと`MAD_FONTS_DIR`を検索します。

**ライター。** `MAD/Source`の`MADReportExporterPDFCairo`は`MADReportExporterPDF`の非Apple本体です。Apple本体は変更なしでCairoをリンクしません。構造目標、フォントマッピング、決定論は`docs/project/MAD_PDF_LINUX.md`のものです。`MADPDFExportTests`は両エンジンでの受け入れテストで、PDFを読み戻し、ページ数、MediaBox、すべてのフレーム、すべてのラインのテキストを`json-report`オラクルと比較し、バーコードとピクチャを画像XObjectとしてチェックし、決定論的バイト同等性をチェックします。

**ライセンス。** cairo（MPL-1.1）、pixman（MIT）、FreeType（FTL）、Liberationフォント（SIL OFL 1.1）は`THIRD_PARTY_LICENSES.md` §3.5と§10に登録され、テキストは`ThirdParty/Licenses/`にあり、`WindowsLicenseRegistry`がAboutウィンドウのために4つすべてを一覧します。どれも再リンク義務を追加しません。

**Viewer。** WPF ViewerのフォーマットピッカーはMacと同じくPDFを最初に一覧し、`serve`のパス形式（`path`付きの`export`）を通じてエクスポートするため、エンジンがエクスポーターのバイトを書き、レスポンスがバイト数を運びます。テキストフォーマットは`data`読み戻しを保ち、そのUTF-8デコードはそれらにとってロスレスです。不確定プログレスバーと「Exporting…」ステータス行が呼び出しを覆い、`Format.Pdf`と`Viewer.Exporting`文字列は6つの辞書すべてで出荷されます。

## 7. 対応Windowsバージョン

.NET 10の対応OSマトリックス（Windows 10 Enterprise 21H2/1809/1607、Windows 11）とGNUstepのWindows 10 1903+ベースライン。Windows 11 Enterprise 26H2（ビルド26300）でテスト済み。Windows 7/8は.NET 10でサポートされません。

## 8. サードパーティライセンスとWindows Aboutページ

Windowsエンジンは第3の配布面であり、`docs/project/THIRD_PARTY_LICENSES.md` §10に登録されています。コンプライアンス面にGNUstepランタイムを追加します。

* **GNUstep Base、gnustep-corebase、libiconvライブラリ**はLGPL-2.1-or-laterです。Windows配布はLGPL-2.1テキスト、通知、`ThirdParty/Licenses/README.md`の書面による再リンクの申し出を運ばなければなりません。
* **libobjc2（libBlocksRuntimeを含む）とlibffi**はMITです。通知を保持してください。
* **libdispatch**はApache-2.0でSwiftランタイム例外付きです。完全なテキストを同梱してください。
* **FreeTDSとMariaDB Connector/C**は既存のLGPL-3.0選択の下で静的にリンクされます。FreeTDSの`sybdb.h`編集はマークされ、既存の再リンクの申し出は今Windowsエンジンを名指しします。
* **Cライブラリ**（SQLite、zlib、bzip2、libarchive、libpng、zint、OpenSSL、libpq）は`ThirdParty/Licenses/`の既存エントリとテキストを使います。
* **Microsoft Edge WebView2**（WPF Viewerのプレビューコントロール、NuGet `Microsoft.Web.WebView2` 1.0.4314.35）はMicrosoft製品でオープンソースソフトウェアではありません。Evergreen WebView2 RuntimeはWindows 11とEdgeとともにインストールされ、このプロジェクトによって変更も再頒布もされません。SDKのBSD-3-ClauseライセンスとMicrosoftのサードパーティ通知、ランタイムのMicrosoft Software License Terms、このプロジェクトの帰属とともに登録され、すべて`ThirdParty/Licenses/Windows/WebView2-LICENSE.txt`にあります。
* **gnustep-make**はGPL-3.0-or-laterのビルドツールで、配布されません。その`Testing.h`はテストバイナリにのみコンパイルされ、出荷されません。libiconvの`iconv`ツールとgnustep-corebaseのテストプログラムも同様に配布されません。GNUstep Baseのコマンドラインツール（`gdomap`、`gdnc`、`defaults`、`plutil`、`gspath`）はGPL-3.0-or-laterで、`mad.exe`の一部ではありません。GPLテキストと対応ソースの申し出なしにパッケージ化しないでください。

正確なDLL／静的の分割は、ビルドされた`mad.exe`から`dumpbin /dependents`（または`llvm-objdump -p`）で測定され、Phase 3bレポートに記録されます。ツールチェーンレイアウトから推測されません。ビルドと任意のパッケージは`ThirdParty/Licenses/`と`NOTICE`をコピーしなければなりません。

WPFの**About**ウィンドウ（Phase 5シェル証明、Phase 6eで完成。エンジン／アプリケーションバージョンの分割はPhase 6fで到来）はMacの3つのタブ——Overview、License & Notice、Acknowledgements——をミラーし、上記のすべてのコンポーネントをWebView2を含めて一覧し、`ThirdParty/Licenses/Windows/`のテキスト、共有ルートテキスト、LGPL書面による申し出を表示します。AcknowledgementsリストはWindowsのコンポーネントリストであり、Appleアプリのものではありません。License & NoticeタブはMIT／ブランド通知とWindows再リンクの申し出を運び、Overviewは機械支援翻訳の通知を運びます。そのクロームはローカライズされますが、すべてのライセンス本体、コンポーネント通知、ライセンス名、著作権行は逐語的な英語のままです（`MAD_APP_LOCALIZATION.md`のD6/§8）。既存のiOSとmacOSのAbout画面はApple専用のままです。それらはAppleアプリがリンクするCライブラリを一覧し、AppleアプリがGNUstepランタイムをリンクすると主張してはなりません。公開`docs/windows.md`と`README.md`のWindowsエントリは0.7の未署名リリース（2026-11-21）とともに着地しました。ページはドキュメント契約（`docs/project/LOCALIZATION.md`）の下で6言語すべてに存在します。Windows検証ワークフロー（`.github/workflows/windows.yml`）は`v0.7.0`に添付された`mad-windows-x64.zip`エンジンアセットに対して.NETスイートをテストし、`Windows/package.ps1`はそのアセットとアプリのリリースzipの両方を組み立てます。

## テストデータベース

3つのライブドライバスイート（Phase 3b）は、Apple/Linuxビルドが使うのと同じ固定Dockerテストサーバーに対して行使され、**`127.0.0.1`にバインドされたローカルWindowsコンテナ**として実行されます（Macは全インターフェース公開を保ち、LinuxイメージとCLIフィクスチャが名前でそのコンテナに到達します）。クロスプラットフォームのエントリポイントは`TestDatabase/test-databases.sh`（Git Bash）と`TestDatabase/test-databases.ps1`（PowerShell）で、3つのフレームワークごとのスクリプトに委譲します。`TestDatabase/README.md`がリファレンスです。

```powershell
.\TestDatabase\test-databases.ps1 -Action download   # fetch datasets, no Docker
.\TestDatabase\test-databases.ps1 -Action up         # create/start all three
.\TestDatabase\test-databases.ps1 -Action status     # -Service mysql|tds|postgres
.\TestDatabase\test-databases.ps1 -Action verify
.\TestDatabase\test-databases.ps1 -Action env        # print the env block
```


`env`ブロックはPhase 3bのライブスイートが読む契約で、`build.ps1`と同じセッションで適用します。

```powershell
$env:MAD_MYSQL_TEST_HOST = "127.0.0.1"; $env:MAD_MYSQL_TEST_PORT = "13306"
$env:MAD_MYSQL_TEST_USER = "root"; $env:MAD_MYSQL_TEST_PASSWORD = "root"
$env:MAD_MYSQL_TEST_SCHEMA = "employees"
$env:MAD_TDS_TEST_HOST = "127.0.0.1"; $env:MAD_TDS_TEST_USER = "sa"
$env:MAD_TDS_TEST_PASSWORD = "Root1@Root2"; $env:MAD_TDS_TEST_DATABASE = "AdventureWorksLT2022"
$env:MAD_PG_TEST_HOST = "127.0.0.1"; $env:MAD_PG_TEST_PORT = "5432"
$env:MAD_PG_TEST_USER = "mad"; $env:MAD_PG_TEST_PASSWORD = "mad_test_pw"
$env:MAD_PG_TEST_DATABASE = "chinook"
```


`MAD_TDS_TEST_PORT`はありません——TDSスイートは1433をハードコードします。ドライバのビルド結果はここではなくPhase 3bレポートに記録されます。

## 関連ドキュメント

* `docs/project/MAD_LINUX.md`と`Linux/README.md` — このWindowsビルドがミラーするLinuxビルド。
* `docs/project/MAD_MACOS.md`と`Mac/README.md` — WPFアプリが振る舞いをミラーするネイティブmacOSアプリケーション。
* `docs/project/THIRD_PARTY_LICENSES.md` §10 — Windowsエンジンのライセンスレジストリ。`ThirdParty/Licenses/`と`ThirdParty/Licenses/Windows/` — テキストと書面による再リンクの申し出。
