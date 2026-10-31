[English](README.md) | [简体中文](README_zh.md) | **日本語** | [Português (Brasil)](README_pt-BR.md)

# Linux — ヘッドレスエンジンのビルド

`docs/project/MAD_LINUX.md` §9：フェーズBではツールチェーン（clang + libobjc2 + GNUstep Baseをソースからビルドし、MADFoundationのサブセットをコンパイルするDockerfile）を実証しました。フェーズCは§4のシム（shim）一覧であり、このディレクトリがその実装場所です。
現在、このビルドは**11個すべてのヘッドレスフレームワーク**——`docs/project/MAD_LINUX.md` §3の表にあるすべてのフレームワークに`MADPostgres`を加え、UI専用のもの（`MADExplorer`、`MADBarcodes`、`MADFeedback`、`Scrimpter`、およびアプリ本体）を除いたもの——をコンパイルし、コンテナ内でそれらのテストスイートを実行します（テスト実行ファイル126個、テスト1,303件、記録された`NEED` 7件）。2026-10-10にmasterへマージされたテストカバレッジ（約100個のXcodeテストファイル）がスイート単位ですべて移植されています。ここにあるものはアプリ本体には同梱されません。フェーズDのチェックポイントであるCLIもここでビルド・実行され（後述の「CLIの実行 — フェーズD」を参照）、フェーズFのランタイムイメージが成果物としてそれを実行します（後述の「ランタイムイメージ — CLI成果物（フェーズF）」を参照）。

## 実行方法

	./Linux/build.sh              build the image, run the tests, exit with the result
	./Linux/build.sh --test       run the tests in the existing image
	./Linux/build.sh --runtime    build the runtime image (mad-cli:latest)
	./Linux/build.sh --verify     build the runtime image, then verify the CLI in it
	./Linux/build.sh --probe      run only the toolchain probe, with its report
	./Linux/build.sh --info       print clang and gnustep-config from the image
	./Linux/build.sh --shell      interactive shell in the build image
	./Linux/build.sh --toolchain  build only the toolchain image (the cache base)
	./Linux/build.sh --rebuild    rebuild without cache
	./Linux/build.sh --clean      remove both images

Docker DesktopのCLIはデフォルトでは`PATH`に含まれない場合がありますが、`build.sh`が`/Applications/Docker.app/Contents/Resources/bin`からそれを検出し、実行時に（隣接するcredential helperとともに）`PATH`へ追加します。初回ビルドには15〜25分（ツールチェーンステージ）かかり、約2.5 GBのイメージが生成されます。2回目以降はキャッシュされるため、ソースレイヤーのみが再ビルドされます。`--platform linux/amd64`によるクロスチェックは、カバレッジマージ直後（2026-10-11、フェーズD以前）にエンドツーエンドで実施されました。エミュレーション下でイメージ全体がビルドされ（amd64ツールチェーンステージとライブラリは以前のキャッシュを使用し、新規55スイートを含むサブセットを再ビルド）、ネイティブarm64と完全に一致する結果（当時の件数で実行ファイル114個、テスト1,098件、`NEED` 6件、レポート項目10件）が確認されています。現在ではCIビルドがこれを引き継いでおり、masterへのpushごとにamd64（ubuntu-latest）上でイメージをネイティブコンパイルして`--verify`を実行し、公開ワークフローが同プラットフォームのランタイムステージをプッシュします。ローカルでamd64ビルドを手動実行する場合は、ネイティブイメージを上書きしないよう独自タグ（`MAD_LINUX_IMAGE=mad-linux:phase-b-amd64 ./Linux/build.sh --platform linux/amd64`）を指定してください。

## バージョン固定（Pins）

`toolchain.conf`は、`Compressor/matrix.conf`と同じ形式でツールチェーンコンポーネントのバージョン、ソース、およびハッシュを一元管理するファイルです。Gitソースはリリースタグ*および*チェックアウト対象のコミットハッシュの両方を固定し、GNUstepのtarballは`ftp.gnustep.org`から計算したsha256値を保持します。

	libobjc2      2.3      v2.3                 (github.com/gnustep/libobjc2)
	libdispatch   6.1.3    swift-6.1.3-RELEASE  (github.com/apple/swift-corelibs-libdispatch)
	gnustep-make  2.9.3    ftp.gnustep.org tarball
	gnustep-base  1.31.1   ftp.gnustep.org tarball

ライブラリコンボは`ng-gnu-gnu`、ランタイムABIは`gnustep-2.2`であり、すべてのコードが`-fobjc-runtime=gnustep-2.2`およびARC有効でコンパイルされます。

## ライブラリレイヤー

`libraries.conf` + `lib/libraries.sh`は、フレームワークがリンクするCライブラリ群をネイティブにビルドして`/usr/local`へインストールします（`docs/project/MAD_LINUX.md` §7）。隣接するCompressorのマトリクスと同じ構造・目的であり、ここの成果物がiOS/macOSアプリに同梱されることはありません。

	sqlite3      3.53.3   the released amalgamation; the option list still comes
	                      from Compressor/sqlite3.xcconfig, the one place it lives
	openssl      3.5.9    static, before freetds
	freetds      1.4.27   --enable-msdblib, apps/server/pool/odbc off, and the
	                      recipe's sybdb.h BOOL edit (spelled for GNU sed)
	zlib         1.3.2
	bzip2        1.0.8    CC=clang: its Makefile hardcodes gcc
	libarchive   3.8.9    the .mad container's tar/bzip2 path
	mariadb      3.4.11   the mariadbclient static target, openssl + external
	                       zlib, auth plugins static, others off (mirrors
	                       Compressor/lib/recipes/mariadb.sh)
	postgres     17.11    the libpq static client library + libpgcommon/libpgport,
	                       with openssl, without readline/icu/gssapi/ldap/pam/xml/
	                       xslt/lz4/zstd/zlib (mirrors Compressor/lib/recipes/postgres.sh)

廃止されたmysqlclientビルドの名残として2つの外部ビルド依存パッケージ（mysqlのcmakeが必要としていた`libncurses-dev`および`libtirpc-dev`）がイメージ内に残っていますが、mariadbのビルドでは使用していません。

## コンパイル対象と除外対象

| フレームワーク | Linuxビルド | 除外対象とその理由 |
|---|---|---|
| MADFoundation | 26 / 27 | `MADKeyChain`（Security.framework依存；§4 — 更新パスはキーチェーンを読み取らないため）。アンブレラヘッダーも除外 |
| MADDataStructures | 全17 | （Xcodeターゲットに含まれる全ファイル；`madmap.cpp`はXcodeターゲットにも含まれない） |
| MADFileManager | 10 / 11 | `MADCloudFileCoordinator`（NSMetadataQuery依存；§4 — iCloudはヘッドレス対象外） |
| MADCocoaExtensions | 7 / 17 | UIKit描画／表示系10ファイル（カラー、ラベル、テキストフィールド、アラート、ビューヘルパー、エラープレゼンタ、MessageUI） |
| MADAPI | 8 / 11 | 接続ビューコントローラ3ファイル（§3：ヘッドレス対象外） |
| MADSqlite3 | 全26 | （孤立した5つの`.m`ファイルはXcodeターゲットにも含まれない） |
| MADTds | 全1 | |
| MADTdsClient | 4 / 5 | 接続ビューコントローラ |
| MADMySQL | 18 / 19 | 接続ビューコントローラ |
| MADPostgres | 5 / 6 | 接続ビューコントローラ |
| MAD | 150 / 181 | UI関連ファイル群（§5.2）、`MADocument`およびそれを生成・クローズするオペレーション群、キーチェーンオペレーション、`MADBarcodes`依存の要素ファイル群。すべて`cmake/MADSources.cmake`に明記 |

各フレームワークのソースリストは`MADFoundationSources.cmake`と同じ形式で`cmake/<Name>Sources.cmake`に記述され、除外ファイル名とその理由が明記されています。`MADExplorer`、`MADBarcodes`、`MADFeedback`、および`Scrimpter`はLinuxビルドには一切含まれません（`docs/project/MAD_LINUX.md` §3）。

Linuxビルドは、フレームワークのソースコードを汚すことなくGNUstepに不足している機能を補います：

* `<Framework/…>`形式のセルフインポートを解決するためのフレームワークごとのインクルードシム（Xcodeターゲットがヘッダーを`<MAD/Foo.h>`としてフラット化するため、MAD用はシンボリックリンクのディレクトリとなっています）、および4つのライブラリヘッダーシム（`<MADSqlite3/sqlite3.h>`、`<MADTds/sybdb.h>`、MADTdsClientアンブレラ、`<MADPostgres/libpq-fe.h>`）。
* マクロやtypedefで対処できるプラットフォーム差分をまとめたプリリュードヘッダー（`Compat/MADCompat.h`）。
* whole-archiveリンク（Appleの`-ObjC`相当）。これがないと静的アーカイブからフレームワークのカテゴリが暗黙に脱落します。
* `libmad.a`に直接コンパイルされていた1つのカテゴリ（`Linux/CMakeLists.txt`の`target_sources`）：`MADQuery+Sqlite3`の`-whereClauseWithRowIds:` / `-whereClauseWithParameters:`はメッセージ送信で呼ばれるためリンカがアーカイブメンバを落とし、かといって当時各フレームワークアーカイブがcompatオブジェクトを内包していた状態では`libmadsqlite3.a`をwhole-archiveするとシンボル重複が起きていたため（後述の通り現在は解消）。
* リンク行における`-lobjc`より前の`-lgnustep-base`配置：libobjc2はabortするweakな`objc_enumerationMutation()`をエクスポートし、GNUstep Baseは例外を送出する本来の実装をエクスポートするため、リンク行で先に置かれた方が優先されます。

フレームワーク側には小さなプラットフォームガードが追加されていますが、すべて`#if __APPLE__`で分岐しているためApple側のコードパスはテキストレベルで不変です。macOSおよびシミュレータ上のテストスイート（MADFoundation、MADDataStructures、MADFileManager、MADCocoaExtensions、MADAPI、MADSqlite3、MADMySQL、MADTdsClient、MADPostgres、MAD）がすべてグリーンであり、`MAD Designer`ワークスペースがビルドできることが挙動不変の証明となっています。

## ドライバはインポートではなくレジストリ登録される

以前はコンストラクタが各ドライバを直接インポートしており、これが`MAD` ↔ ドライバ間の循環依存（`docs/project/ROADMAP.md` §5.1）を生んでいました。現在は`MADDatabaseDriverRegistry`（`MADAPI`）がその接点（seam）となっています。各ドライバのコネクションクラスは`MADDatabaseDriver`に準拠して`+load`内で自身を登録し、`MADDatabase+Constructor` / `MADDatabaseConnection+Constructor`は具象クラス名ではなく`MADDatabaseType`でドライバを検索します。したがって、プロセスがどのドライバを利用できるかは、何を*リンクしたか*によって決まります。

Appleプラットフォームでは、ホスト（アプリやCLI）がMADMySQL、MADTdsClient、MADPostgresの各ドライバフレームワークをリンクし、`MAD.framework`自体はそれらをリンクしません（そのため`MAD`のテストバンドルもそれらを個別にリンクします）。Linuxでは、ドライバの静的アーカイブは`mad`ターゲットから**whole-archive**指定（すべての利用側に伝播する`$<LINK_LIBRARY:WHOLE_ARCHIVE,…>`）でリンクされます。静的アーカイブはロードではなくシンボル検索されるため、どこからも直接シンボル参照されないメンバ（ドライバの`+load`やカテゴリ）は、こうしない限り脱落してしまいます。これは実際、`mad refresh`でMySQL接続を実行した際に修正前にabortを引き起こした原因そのものでした（次節参照）。レジストリの動作は`MADDatabaseDriverDispatchTests`で固定されており、`Linux/Tests/MADHeadlessDocumentTests.m`がチェーン全体を駆動します。

新しいドライバを追加する際は、`Linux/CMakeLists.txt`にリンクエントリを1つ追加するだけでよく、`MAD`側の変更は一切不要です。

## compatシムを独立したアーカイブに分離した理由

以前はすべてのフレームワークアーカイブが`Compat/*.m`を内包していました。そのため2つのアーカイブをwhole-archiveすると重複シンボルエラーが発生し、`MADQuery+Sqlite3`の1カテゴリだけを手動で`libmad.a`に組み込む回避策をとっていました。しかしCLIの実装時にその代償が判明しました。ライブMySQLに対する`mad refresh`が診断メッセージなしに**abort（SIGABRT）**したのです。原因は、プリペアドステートメントを実行するメソッド`MADMySQLFetch (DataTable)`がメッセージ送信で呼ばれるカテゴリであったため、リンカがそのオブジェクトファイルを一切取り込んでいなかったことでした。`nm`で確認すると、MySQLテストバイナリには存在していた`.objc_category_MADMySQLFetchDataTable`がCLIバイナリには欠落していました。

現在は`madcompat`を独立した静的ライブラリとし、すべての実行ファイル（`mad_add_test`、`ToolchainProbe`、`mad-cli`）がそれをwhole-archiveする構成に改めています。これにより各フレームワークアーカイブは純粋になり、ドライバアーカイブも他のコードと同様にwhole-archiveできるようになり、ファイル単位の`target_sources`ハックも不要になりました。ここから得られる一般原則は明快です——**フレームワークの静的アーカイブは、whole-archiveして初めて安全にリンクできる**（そうでなければ実行時にカテゴリが暗黙に欠落する）ということです。

## プローブとテストで判明したGNUstepの挙動差異

* **`NSOperationQueue`とKVO — ここで発見され、`MADOperation`で修正。** GNUstepの`NSOperationQueue`は通知を受け取るたびに`"isReady"`の監視（observation）を解除し、監視を登録した直後にもう一度`isReady`を確認します。以前の`MADOperation`は`-isReady`の内部から（`state`のKVO依存キー経由で）自身の状態マシンを進めていたため、1回目の準備確認でキューが待っていた通知が発火して監視が解除され、続く2回目の呼び出しですでに存在しない監視を解除しようとして`NSInvalidArgumentException`が発生し、オペレーションが一切実行されない問題がありました。現在の`MADOperation`は状態遷移を明示的に駆動し（`-willEnqueue`が条件評価を開始）、`isReady`、`isExecuting`、`isFinished`の各値が実際に変化したときにのみ`will`/`didChangeValueForKey:`を送出するため、Apple環境と同様に1回のエンキューにつき1回の`isReady`通知のみがキューに届きます。Linuxテストは両プラットフォームでこの挙動を明確にアサートしており、フェーズDの更新パスもこれによりブロックされなくなりました。
* **Secure Codingアーカイブの未実装。** GNUstepでは`archivedDataWithRootObject:requiringSecureCoding:YES`がエラーなしでnilを返すため、Apple以外でも動作しなければならないコードパス——`MADArrayCaching`の`.madac`レンダーキャッシュ、`MADDataTableFast`のグループキーセット、`MADFileUtilities`のアーカイブ——では`#if __APPLE__`の反対側で`requiringSecureCoding:NO`にフォールバックします（ハードニングがないだけで同じコーダ形式です）。アンアーカイブ側にはフォールバックは不要で、`unarchivedObjectOfClass:fromData:error:`およびその複数クラス版はGNUstepでも正常に動作します。一方、`+unarchiveTopLevelObjectWithData:error:`は存在しないため、`Compat/`内で`+unarchiveObjectWithData:`上にシムを実装しています。
* **GNUstepでは`-localizedCaseInsensitiveCompare:`が大文字・小文字を区別する** — 現在は影響なし（2026-10-25修正）。`MADDatabaseSqlite3`が登録するSQLite照合順序（`compare_string_utf8_localized_asc_collation`）、インメモリのソートセレクタ、およびレポートフォーマッタの文字列比較関数はすべて、ファーストパーティで定義された単一の順序（`NSString+Comparison.h`：ケースフォールド後にUTF-8コードポイント順で比較）を経由するようになりました。これによりロケール依存比較によるプラットフォーム差異は根本から解消され、両プラットフォームで同一の順序がテストでアサートされています。`docs/project/MAD_CLI.md`の`mad export`セクションを参照してください。
* **`BOOL`のランタイム型エンコーディングと`class_getProperty`の継承探索 — `MAD`のrptqテストスイートで発見され、`RptqObject`で修正。** ランタイムは動的に登録されたアクセサの型エンコーディングをコンパイル済みの呼び出し側と照合しますが、`BOOL`はAppleでは`signed char`（`'c'`）であるのに対しGNUstepでは`unsigned char`（`'C'`）です。そのため、`RptqObject`が動的に登録するboolアクセサはプラットフォーム別のエンコーディング（`MAD_RPTQ_BOOL_TYPE`）を使用するようになりました。また、Appleの`class_getProperty()`がスーパークラスチェーンを辿るのに対し、GNUstepは当該クラス自身しか調べないため、継承されたプロパティ（ラベルの`alignment`など）が汎用オブジェクト処理へフォールスルーしてしまう問題がありました。現在は`RptqPropertyNamed`が両プラットフォームでスーパークラスを探索します。クラッシュではなく暗黙に誤った値になる故障モードであったため、両方とも移植されたテストスイートで固定されています。
* **GNUstepのファイルAPIがスキームなしのURLを拒否する — `MADFileManager`の移植テストで発見され、`MADURLFactory`で修正。** GNUstepでは`file://`スキームを持たないURLに対して`-contentsOfDirectoryAtURL:`および`-writeToURL:`が何もせず黙って失敗します（2026-10-11実測）。`+newURLForLocalDocumentsDirectory`がパス文字列から`-initWithString:`でURLを構築していた（Appleでは許容されていた）のを、両プラットフォームで正しい`+fileURLWithPath:`に修正しました。これと後述のコーディネータシムにより、保留されていた5件の`NEED`が5件の合格テストに変わりました（`MADLocalFileCoordinatorTests`：12テスト、0 needs）。
* **dispatchオブジェクトがプレーンなCポインタである**（Darwin以外では`os/object.h`がObjCサポートを無効化し、`OS_OBJECT_USE_OBJC=1`を拒否するため）。したがってARCで所有することはできず、Apple以外ではすべての`strong`/`copy`なdispatchプロパティを`assign`とし、該当箇所にコメントを付しています。キューは一度生成されるとプロセス終了まで存続し、解放されません。
* **その他の小さな差異（シムまたはガードで対応済み）：** `NSOperation.name`、`NSOperation.cancelled`、および`NSOperation.asynchronous`（GNUstepは古い`-isConcurrent`のみを常にNOを返すスタブとして保持しており、内部管理でそれを参照するため、Compatカテゴリで`[self isAsynchronous]`を返さないと非同期オペレーション完了時の`-dealloc`で例外が発生する）、`NSFileManager`のUbiquityメソッド群（Apple以外ではiCloudがないためすべて空を返す）、`NSFileCoordinator`の`-initWithFilePresenter:`および`-coordinateAccessWithIntents:queue:byAccessor:`（GNUstep実装はアクセサ実行時にSIGSEGVを起こすため、Apple以外では協調対象がないことからCompatカテゴリで指定キュー上に直接アクセサを実行）、`NSURL`のセキュリティスコープアクセスと`-fileSystemRepresentation`、`NSData`の`-options:error:`リーダーと定数群、`NSCoder`の`-decodeTopLevelObjectOfClasses:forKey:error:`、`NSUndoManager`の`-registerUndoWithTarget:handler:`、`+propertyListWithStream:options:format:error:`（ストリームを読まずにnilを返すスタブだったため、Compatカテゴリでストリームを読んで`+propertyListWithData:`に委譲；これにより`MADDataTable`の`-loadFromCacheWithUrl:`がLinuxでも動作し両プラットフォームで検証済み）、`NSValue`の`CG*Value`群、`CF_ENUM`/`CFAvailability`マクロ、`CFNumber`抽出関数（互換`CoreFoundation/CFNumber.h`）、POSIXの`copyfile(3)`、`htonll`、MacTypesスカラ型（`Float64`、`SInt32`…`UInt64`、`Boolean`）、`NS_RETURNS_INNER_POINTER`、`__nullable`、`NSOperation.qualityOfService`、`NSDataWritingFileProtection*`、`containerURLForSecurityApplicationGroupIdentifier:`（未実装のため`MADURLFactory`のグループパスはユーザー別ディレクトリへフォールバック）、`<sys/qos.h>`の`QOS_CLASS_DEFAULT`。
* **正常動作を確認済み：** ARCとweak参照のゼロ化、Blocks、例外、`@synchronized`、KVO（手動および依存キー）、`NSOperation`状態マシンKVO、`NSPredicate predicateWithFormat:@"error != nil"`（MADが使用する正確な述語）、dispatch（once/queues/groups/semaphores）、プレーン実行ファイル下でのメインキュードレイン、JSON、UUID、日付、plist、ソートディスクリプタ、ストリーム、`NSDecimalNumber`、`NSCalendar`、および非厳格パスでのKeyed Archiving。完全なレポートは`--probe`で出力され、19個のコアチェックが終了コードをゲートし、12個のレポート項目は参考出力となります。

**通貨フォーマット（2026-10-16発見、2026-10-17修正）。** GNUstepの2つの挙動により、描画される金額文字列がAppleと異なっていました。1つは`NSNumberFormatterCurrencyStyle`がどのロケールでも小数部桁数を0にしてしまうこと（`en_US`でAppleが`$0.99`となるところが`$1`になる）、もう1つはイメージのデフォルトロケールが`en_US_POSIX`であり通貨記号の後にスペースが入り桁区切りがないことです。フォーマッタ自体を置き換えることなく、レポートがロケールと小数部桁数をドキュメントの数値フォーマット設定から取得し（フォールバックはマシンのロケールではなく`en_US`）、通貨記号を明示的に設定しつつ円記号を正規化する（GNUstepは全角のU+FFE5を出力するため）ことで両方を解決しました。6ロケール×10値（負数および1e12を含む）の計60ケースの比較が両プラットフォーム間でバイト単位で完全一致するようになり、後述のレンダー系エクスポートもMacの出力バイト列に固定されています。

## `NEED`件数の内訳

フェーズBのイメージでは3件の`NEED`が報告され、完成したフェーズCのイメージではApple専用の機構に依存するテストスイートからさらに数件が報告されます。これらは意図的にスキップ（skip）ではなく`NEED`として分類されています。Linuxが持たないリソースなしには実行できないチェックであり、skipにして隠すのではなく明示的に可視化するためです。

* **以前から存在していた3件：** ツールチェーンプローブの厳格アーカイブチェック（上記の`requiringSecureCoding:YES`がnilを返す件）、App Groupチェック（`containerURLForSecurityApplicationGroupIdentifier:`が存在しない件）、および同じ厳格アーカイブのギャップに関する`MADCredentialTests`の条件付きチェック。
* **`MADStoreTests`** — モデル忠実性チェックにはCore Dataおよびコンパイル済み`MAD.momd`が必要であり、どちらもApple専用であるため。
* **`RptqStoreContextTests`（2件）** — 変換済みサンプルフィクスチャのチェックには`MADStoreConverter`、Core Data、および`London.mad`が必要であり、ドキュメントパスのチェックには`MADocument`および`MADStoreConverter`が必要であるため。

なお、ライブデータベーステストスイートはサーバーに到達できない場合は（Xcodeスキームと同じ契約に従い）決して失敗せずスキップ（skip）され、SQLiteベンチマークもデフォルトスケールではスキップされます。スキップは`NEED`とは別に集計されます。

## ライブデータベーステストスイートの実行

`MADMySQLLiveTests`、`MADTdsClientLiveTests`、および`MADPostgresLiveTests`は実際のサーバーと通信し、到達できない場合はスキップされます。サーバーは`docs/project/DEVELOPER.md`に記載されている3つのコンテナです。先にそれらを起動してください：

	MADMySQL/TestDatabase/mysql-test-db.sh up          # mad-mysql on :13306
	MADTdsClient/TestDatabase/sqlserver-test-db.sh up  # mad-mssql on :1433
	MADPostgres/TestDatabase/postgres-test-db.sh up    # mad-postgres on :5432

	docker run --rm \
		-e MAD_MYSQL_TEST_HOST=host.docker.internal \
		-e MAD_MYSQL_TEST_PORT=13306 \
		-e MAD_TDS_TEST_HOST=host.docker.internal \
		-e MAD_PG_TEST_HOST=host.docker.internal \
		--entrypoint bash mad-linux:phase-b -c \
		'/src/Linux/build/MADMySQLLiveTests && /src/Linux/build/MADTdsClientLiveTests && /src/Linux/build/MADPostgresLiveTests'

クリーンなセットアップでの実測結果：MySQLは44/44合格（チェック311件：プリペアドステートメント、型変換、スキーマ検出）、SQL Serverは29/29合格（チェック169件：freetdsワイヤパス、日付／時刻分解、decimal/blob/nvarchar、スキーマ検出）、PostgreSQLは14/14合格（2026-10-27実測、チェック132件：libpqフェッチ、OID型変換、publicおよび非publicスキーマにわたるスキーマ検出）——すなわち、3つのドライバすべてがLinux上でコンパイルできるだけでなく実際に動作します。`MADTdsClientTests`の2つの接続失敗テストはサーバーなしで実行されます。

## ライセンス

ビルドイメージ内のツール群はすべてビルドツールであり、iOS/macOSアプリには一切リンクされません。libobjc2はMIT、libdispatchはSwiftランタイム例外付きApache-2.0、GNUstep BaseはLGPL-2.1-or-later、gnustep-makeはGPL-3.0-or-laterであり、その`Testing.h`（GPL-3.0-or-later）はLinuxテストバイナリにコンパイルされますが、それらはビルドイメージ内にのみ存在します。各Cライブラリにはそれぞれのライセンスが適用されます（`docs/project/THIRD_PARTY_LICENSES.md`）。mysqlclientのGPL問題はMariaDB Connector/C（LGPL-2.0-or-later、LGPL-3.0を選択）への置き換えによって解決済みです（`docs/project/TASKS.md` §10）。ランタイムイメージは`ghcr.io/mthomason/mad`として公開されているため、そこに含まれるLGPLコンポーネントには再リンク提供の義務が生じます。`ThirdParty/Licenses/README.md`の書面による提供申し出（written offer）にはこのイメージが明記されており、台帳エントリは`THIRD_PARTY_LICENSES.md` §9に記載されています。なお、gnustep-makeはビルドツールでありランタイムイメージには含まれません。

## CLIの実行 — フェーズD

`mad`はこのCMakeListsによって`CLI/Source`（`CLI/build.sh`がiOSシミュレータ向けにビルドするのと同一のソース）からビルドされ、11個のフレームワークをwhole-archiveでリンクしてイメージ内で動作します：

	/build/mad inspect <document.mad>
	/build/mad schema  <document.mad>
	/build/mad query   <document.mad>
	/build/mad refresh --credentials user:pass <document.mad>

当初はPDFが`UIPrintPageRenderer`によるCore Graphicsコンテキスト描画であったため`export`のみが含まれていませんでしたが（`docs/project/MAD_LINUX.md` §5.2）、**フェーズE（2026-10-16）でFoundationおよびレンダー系の全エクスポートフォーマットが実装されました。** エクスポートインターフェース（`MADReportExporting` + `MADReportExporterRegistry`、`docs/project/MAD_CLI.md` §5.3）が`mad`に組み込まれ、`text`、`csv`、`json`、およびレンダー系の`html`、`html-flow`、`json-report`がイメージ内で動作し、Mac版ツールとバイト単位で同一の出力を生成します（`pdf`のみ、Linux上で実行できない理由を返して明示的に拒否します）。

Londonフィクスチャ（`CLI/Fixtures/London.portable.mad`、事前に更新を実行し両環境で`sha256sum`を計測）での比較結果：

| フォーマット | バイト数 | sha256（両プラットフォームで完全一致） |
|---|---|---|
| `json` | 64595 | `569c6ee25223c51ecffd15923dd897e75c8362d72f4ece72f8dbeee3e9c8cdbc` |
| `csv` | 12538 | `773f6215a5447f72d499282d337a5916b11f0f3b06cb4c5aec134db6f493cb21` |
| `text` | 40441 | `7dcee96c45951fac0e0057094a6a142c90a88d6d88a1c03278b273f5140c6e49` |

`Linux/Tests/MADReportExporterTests.m`はこの検証をテスト化したものです。フィクスチャを更新し、各エクスポート結果のFNV-1aチェックサムをMac側のバイト列と照合（構造と主要値も併せて検証）するため、GNUstepとAppleの間で1バイトでも差異が生じればテストが失敗します。また、同じFNV-1aチェックサムがMac側（`MAD/MADTests/MADReportExporterTests.m`）でも固定されているため、どちらのプラットフォームでも差異が見逃されることはありません。`pdf`については、暗黙にデータ部分だけを出力するのではなく確実にエラー終了することを`Linux/Tests/MADReportExporterTests.m`がアサートしています。

**ドキュメントクラスの設計判断。** `MADocument`は`UIDocument`のサブクラスであるためヘッドレス環境には持ち込めません。そこでドキュメントのデータ側をプロトコル`MADDocumentDataProtocol`として切り出し、`MADocument`がそれに準拠（既存の挙動は不変）するとともに、`MADHeadlessDocument`がそれを実装する形としました。`MADHeadlessDocument`は`MADDocumentStore`（`MADocument`と同じストアレイアウトを使用するため両者間で不整合が起きません）でコンテナとポータブルストアを開き、クエリをコンパイルし、レジストリ経由でドライバベースのデータベースを構築して行テーブルを保持します。更新チェーンはこのプロトコルを受け取るため、AppleとLinuxは*同一の*`MADOperationRefresh`を実行します。

**イメージ内でのチェックポイント検証結果**（Docker Desktop；ドキュメントは`CLI/Fixtures/`にあり、ホスト名`mac`はホスト側のMacに解決されます）：

| 実行内容 | 結果 |
|---|---|
| `London.mad`（レガシーサンプル）に対する`mad inspect` | v0、6メンバ、store + WAL + SHMを報告 |
| `London.portable.mad`に対する`mad inspect` | v1、4メンバ、`StoreContent/store.sqlite (portable)`、41セクション／25要素 |
| 2つのポータブルフィクスチャに対する`mad schema` | Macの出力とバイト単位で完全一致 |
| 同じフィクスチャに対する`mad query` | Macと同一のフィールドセット（順序については下記参照） |
| `London.portable.mad`に対する`mad refresh` | 76行。行キャッシュはMacと同一（名前順で21カラム、76行、すべての値が一致） |
| `MySQL.employees.mad`に対する`mad refresh --rows 50 --credentials root:root` | ライブMySQL 8.4から50行取得（プリペアドステートメントフェッチ、データベース`employees`） |
| `TDS.AdventureWorksLT2022.mad`に対する`mad refresh --rows 20 --credentials sa:Root1@Root2` | ライブSQL Server 2022から20行取得（freetds、`AdventureWorksLT2022`） |
| `Postgres.chinook.mad`に対する`mad refresh --rows 25 --credentials mad:mad_test_pw` | ライブPostgreSQL 17から25行取得（libpq、`chinook`） |

**ここで発見され解決されたSELECTリスト順序の差異。** 以前、SELECTリストのカラム順序は`NSSet`の列挙順序（`MADQueryActiveQueryFields`が`NSSet`に蓄積していたため）になっており、同じドキュメントでもAppleとGNUstepでカラム順およびハッシュ由来の`c<hash>`カラム名が異なっていました。**2026-10-16に解決（`docs/project/MAD_LINUX.md` §10.1）：** 両方のSQLビルダにおいて、カラムエイリアスを`-compare:`でソートした順序として明確に定義したため、生成されるSQL、行キャッシュ、およびすべてのエクスポートが両プラットフォームで完全に一致するようになりました（`Linux/Tests/MADQuerySelectExpressionTests.m`でテスト固定済み）。

## ライターの動作とプラットフォーム間のバイト一致

フェーズEのもう一方の柱（`docs/project/MAD_LINUX.md` §9；2026-10-16の要件）として、`.mad`ライターがLinux上で動作し、同一ドキュメントに対してMac版と**同一のバイト列**を生成します。コマンドは`mad write <doc.mad> --out <copy.mad> [--reproducible]`であり、両プラットフォームともドキュメントをヘッドレスで開いて同一のライターを実行します。

Londonフィクスチャ（`CLI/Fixtures/London.portable.mad`）での実測結果：

	$ mad write London.portable.mad --out copy.mad --reproducible
	16261 bytes, sha256 09815b24e91e03b6e526008f7c2700074fed10679771b9e1ee4609e54a1192f5
	                                     (identical on the Mac and in this image)

`--reproducible`はuid/gid 0、固定時刻`2001-01-12T00:00:00Z`、およびソート済みメンバ走査を適用します。通常の書き込みではメンバの実際のファイルシステムメタデータが保持されるため、設計上、実行ごと・プラットフォームごとにバイト列は異なります。

Linux上でライターを動作させるにあたり修正した2つの不具合（いずれも`docs/project/BUGS.md`の`.mad`バイト同一性エントリに記録済み）：

* `-write_archive:`が列挙された各URLからアーカイブ対象ディレクトリまでを辿る際、GNUstepの`-enumeratorAtURL:`が親ディレクトリ部分を除去していたためループが到達しなかった問題。現在はCLIのメンバ一覧と同様に`-subpathsAtPath:`を使用しています。
* `backup_file`がパスバッファをそのまま`dirname(3)`/`basename(3)`に渡しており、glibc実装がバッファを書き換えるため、呼び出し元のアーカイブパスが最後のスラッシュ位置で切り詰められ、生成されたドキュメントが自身のディレクトリ上に上書きされようとして失敗（`Open (…) failed - Is a directory`）していた問題。Apple実装は入力バッファを変更しないためLinuxでのみ顕在化しました。

`Linux/Tests/MADArchiveManagerTests.m`がこれらをカバーしています（5テスト、0 needs）。

## レンダー層とHTMLフォーマットの実行

フェーズEの2つ目の決定（2026-10-16）により、レンダー層もApple依存から切り離されました：

* `MADReportFormatter`は`id <MADDocumentRenderProtocol>`を受け取り、`MADHeadlessDocument`がこれに準拠します。
* `MADReportPageBuilder`が`MADPrintPageRenderer`からページ構築ウォークを切り出し、レンダー側のジオメトリ（US Letter、1ptトリム）と準備シーケンスを管理するため、PDF、`json-report`、およびHTMLフォーマット間でページ計算が食い違うことはありません。
* `MADDocumentRenderDataSource`がレンダー側の読み取り処理を単一実装として提供し、`MADocument`と`MADHeadlessDocument`の双方で共有されます。

LondonフィクスチャにおけるMacとの比較実測値：

| フォーマット | バイト数 | sha256（両プラットフォームで完全一致） |
|---|---|---|
| `json-report` | 118,109 | `9d01d0daabbb5e38921c0bfbed083b288031c9340e9a4af81679d03b691ce94c` |
| `html` | 62,007 | `285541ed59333e0e55b8c7fe5619e4b64dde7aaf8e93a24ba881b40111ab2327` |
| `html-flow` | 54,766 | `0565204a55d02f925602b5c0bf298bb0e41c9cbe56bea6df770e828a35782382` |
| `pdf` | — | Linuxでは生成せず、`+isAvailable`が理由とともにNOを返す |

すべてのフレーム、フォント、フォントサイズ、スタイル特性、整列、テキストラン、ページボックス、および通貨フォーマットに至るまで、プラットフォーム間でバイト単位で完全に一致します。`Linux/Tests/MADReportExporterTests.m`がこれら3つのチェックサムを固定しています。

## ランタイムイメージ — CLI成果物（フェーズF）

フェーズFの成果物は、開発者がビルドツリーのパスを覚えておく必要のない、CLIを直接実行できるコンテナイメージです。`./Linux/build.sh --runtime`が同じDockerfile（`build`の下流にある`runtime`ステージ）からこれをビルドし、`mad-cli:latest`タグを付けます：

	docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro mad-cli:latest \
		mad inspect /docs/London.portable.mad

このイメージは`ghcr.io/mthomason/mad`として公開されており（2026-10-26）、`latest`およびコミットの短縮SHAでタグ付けされます。公開タグはCI（`.github/workflows/publish-image.yml`）によってubuntu-latest上でビルドされるため**linux/amd64**です（Macのローカルビルド`mad-cli:latest`はarm64）。Appleシリコン上で公開イメージをそのまま実行する場合は`--platform linux/amd64`を付けてください：

	docker run --rm --platform linux/amd64 -v "$PWD/CLI/Fixtures":/docs:ro \
		ghcr.io/mthomason/mad mad inspect /docs/London.portable.mad

イメージに含まれるもの：

* `/usr/local/bin/mad`（CMakeのインストールルールによる固定パス）
* バイナリがリンクする共有オブジェクト（GNUstep Base、libobjc2、libdispatch、libBlocksRuntime）およびGNUstepのランタイムディレクトリと設定ファイル。その他のCライブラリ（sqlite3、freetds、openssl、zlib、bzip2、libarchive、mariadb、postgres）は静的リンクされバイナリ内に組み込まれています。
* `/root/GNUstep/Library/ApplicationSupport/`配下の`chinook.sqlite3`。Sqlite3ドキュメントのベース名のみのデータベース参照がここで解決されるため、コミット済みのLondonおよびMusicフィクスチャを追加設定なしで更新できます。

コンパイラ、cmake、git、ソースコード、126個のテストバイナリ、および静的アーカイブとヘッダーはすべて除外されており、最終ステージは`ubuntu:24.04`とaptのランタイムライブラリのみで構成されます。サイズは**ディスク上で283 MB（圧縮時66.5 MB）**です（ビルドイメージは6.65 GB）。

すべてのサブコマンドが同じ方法で実行できます：

	docker run --rm -v "$PWD/docs":/docs mad-cli:latest mad schema /docs/x.mad
	docker run --rm -v "$PWD/docs":/docs -v "$PWD/out":/out mad-cli:latest \
		mad export /docs/x.mad --format html --out /out/x.html
	docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro mad-cli:latest \
		mad refresh /docs/MySQL.employees.mad --credentials root:root --rows 50

**`--verify`による反復検証。** ランタイムイメージを再ビルドし、リポジトリを読み取り専用マウントして`Linux/verify-cli.sh`を実行します。6つのサブコマンド、固定ダイジェストに対する全エクスポートフォーマット、`pdf`の拒否動作、`--reproducible`ライターの出力バイト列、終了コード、およびイメージ自体の構成（clang、cmake、git、ビルドツリーが含まれていないこと）の計41項目をチェックし、1つでも失敗すれば非ゼロで終了します：

	./Linux/build.sh --verify
	...
	MADVERIFY 41 passed, 0 failed

`--live`を付けるとMySQL、TDS、PostgreSQLの更新チェック（50行、20行、25行）が追加されます（先に`docs/project/DEVELOPER.md`の3つのテストコンテナを起動してください）：

	MADMySQL/TestDatabase/mysql-test-db.sh up
	MADTdsClient/TestDatabase/sqlserver-test-db.sh up
	MADPostgres/TestDatabase/postgres-test-db.sh up
	docker run --rm -v "$PWD":/repo:ro mad-cli:latest \
		bash /repo/Linux/verify-cli.sh --live

**Dockerfileの注意点。** `runtime`ステージがDockerfileの最終ステージであるため、`--target`を指定せずに`docker build`を実行するとランタイムイメージが生成されます。`build.sh`はビルドイメージ用に`--target build`、ツールチェーンキャッシュ用に`--target toolchain`を渡しています。手動でビルドする場合も同様にしてください。

## 現時点で未実装のもの

Linux版PDFライター — **2026-10-17より保留中（ユーザーのリサーチおよび判断待ちのため、指示なしに着手しないでください）。** 引き継ぎ事項（既存資産、不足要素、候補スタックとライセンス、未解決の論点、受け入れテスト）は`docs/project/MAD_PDF_LINUX.md`に、判断の経緯は`docs/project/MAD_LINUX.md` §10.2に記録されています。これが実装されるまでは、Linux上でのPDF生成には`--format html`の出力をブラウザで印刷する方法を用います。
