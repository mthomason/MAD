---
layout: default
lang: ja-JP
---

# 半日で書けるMADドライバ作成チュートリアル

以下のすべての`file:line`参照は2026-10-25時点のものです。

## ドライバとは何か

ドライバは、2つの小さなクラスと1つの登録呼び出しだけで構成されます：

1. データソースのスキーマを参照し、それに対してクエリを実行する方法を知っている`MADDatabase`のサブクラス（`MADAPI/Source/MADDatabase.h`——ヘッダーには明快に`"This class is built for subclassing"`と記されています）。
2. コネクションクラス——`MADDatabaseDriver`プロトコル（`MADAPI/Source/MADDatabaseDriverRegistry.h`）に準拠し、`+load`内で自身を登録する`MADDatabaseConnection`のサブクラス。

それ以外のすべて——クエリデザイナーのグラフ、SQL生成、行キャッシュ、レンダーパイプライン、7種類のエクスポートフォーマット、CLI、Dockerイメージ——は、ドライバがプラグインとして接続する共通機構です。ドライバが満たすべき契約は*「スキーマと行をテーブル形式で返すこと」*（`docs/project/MAD_STRATEGY.md` §3.7）であり、だからこそSQLデータベース、Webサービス、ファイルなど、テーブルとして表現できるあらゆるもののフロントエンドとしてドライバを実装できます。

参考にできるサーバー型ドライバの実装例は、`MADPostgres`（6ファイル、`MADPostgres/Source/`、`libpq`上のサブクラス`MADDatabasePostgres`）、`MADMySQL`（18ファイル、`MADMySQL/Source/`、サブクラス`MADDatabaseMySQL`）、および`MADTdsClient`（FreeTDS上のSQL Server）の3つです。4つ目の同梱ドライバはSqlite3（`MADSqlite3`）であり、ファイルベースのケース（`+newDatabaseConnectionWithURL:`）はそのコネクションクラスが参考になります。

## ステップ1 — 型定数の定義

未使用の`MADDatabaseType`の値（`MADAPI/Source/MADDatabaseType.h`；現在出荷されている型は1–12）を選ぶか、enumを拡張します。この値はドキュメント内に保存されるため、フォーマット定数となります。その型を持つドキュメントが一度作成されると、その番号は永続的なものになります。

## ステップ2 — `MADDatabase`のサブクラス化

抽象インターフェース（seam）は`MADAPI/Source/MADDatabaseProtocol.h`（`MADDatabaseDataSource`）にあります。実装が必要なメソッド群は以下の通りです：

```objc
- (void)getTables:(void (^)(BOOL success, NSError *error,
                            NSArray <MADDatabaseTable *> *tables))completion;

- (NSArray <MADDatabaseTable *> *)getTablesFromConnection:(id)dbconn
                                                    error:(NSError **)error;
- (NSArray <MADDatabaseField *> *)fieldsForTable:(NSString *)tableName
                                     connection:(id)dbconn
                                          error:(NSError **)error;

- (id)connectWithConnection:(MADDatabaseConnection *)connection
                 credentals:(MADCredential *)credentals
            connectionError:(NSError **)error;

// The execution seam: the driver fills the table it is handed.  The
// destination is any <MADDataTableWriting>, which is what keeps the
// promise to "anything that returns a table" (MADDataTable.h).
- (BOOL)executeSQL:(NSString *)sql
         fieldKeys:(NSArray *)fieldKeys
      onConnection:(id)dbconn
  intoResultTable:(id <MADDataTableWriting>)dataTable
         withError:(NSError **)error;

- (BOOL)executeQuery:(MADQuery *)query withError:(NSError **)error;
- (BOOL)executeQuery:(MADQuery *)query
       withDataTable:(id <MADDataTableWriting>)dataTable
            andError:(NSError **)error;

// Optional: only file-backed drivers have nothing to dial.
- (void)closeConnection:(id)process;
```

スキーマ参照（`getTables…`、`fieldsForTable:…`）は、アプリのドキュメント作成フローがデータベースのスキーマを新しい`.mad`にインポートする際に呼び出します。実行インターフェース（`executeSQL:…`）は、`mad refresh`およびビューアが呼び出すメソッドです。更新チェーンが行う正確な呼び出しは`MADOperationRefresh.m:134`で確認できます。

## ステップ3 — コネクションクラスとドライバ登録

```objc
@interface MyDriverConnection : MADDatabaseConnection <MADDatabaseDriver>
@end

@implementation MyDriverConnection
+ (void)load {
	[MADDatabaseDriverRegistry registerDriverClass: self];
}
+ (MADDatabaseType)databaseType { return MADDatabaseTypeMyDriver; }
+ (NSString *)Identifier { return @"MyDriver"; } // stored in documents
+ (instancetype)newDatabaseConnection:(NSObject <MADConnectionsPropertiesProtocol> *)credentials { … }
+ (Class)databaseClass { return [MyDatabase class]; }
+ (instancetype)newDatabaseConnectionWithHost:(NSString *)host
										 database:(NSString *)database
											 port:(NSInteger)port { … }
@end
```

`+Identifier`は`RptqDatabaseCredentals.driverID`が保持する値であるため、ドキュメントフォーマット定数となります。安定した文字列を選んでください（出荷されているものは`"MySQL"`、`"TDS"`、`"PostgreSQL"`、`"Sqlite 3"`です）。すでに使用されている型を別のクラスが宣言するとプログラミングエラーとなり、レジストリがアサートで検出します。

## ステップ4 — 登録が実行されるようにリンクする

ドライバ登録はプロセス単位であり、**リンクによって**行われます。ドライバをリンクしていないプロセスはそのデータベースを構築できません（後でnilによって暗黙に失敗するのではなく、コンストラクタが明確なメッセージとともにアサートします）。

* **Appleプラットフォーム：** ホストにフレームワークをリンクするか（CLIは`CLI/build.sh`の`FRAMEWORKS`リストでドライバを指定しています）、静的アーカイブをリンクする場合は`-ObjC`を使用します。これを行わないと、カテゴリや`+load`メソッドがリンカによって暗黙のうちに除去されてしまいます。
* **Linux：** `madsqlite3`、`madmysql`、`madtdsclient`、`madpostgres`と同様に、`Linux/CMakeLists.txt`の`mad`ターゲットに対してアーカイブを**whole-archive**指定で追加します：

  ```cmake
  target_link_libraries(mad PUBLIC
      "$<LINK_LIBRARY:WHOLE_ARCHIVE,my_driver>" …)
  ```

  これは単なるお作法ではありません。ドライバの処理はカテゴリ（シンボル参照ではなくメッセージ送信）経由で呼び出されるため、`WHOLE_ARCHIVE`を使わない静的リンクではそれらが脱落し、リンカ警告すら出ないまま最初のメッセージ送信時にクラッシュします（`Linux/README.md`の「The compat shims」／「The drivers are registered」を参照）。ドライバごとのソースリストは`MADFoundationSources.cmake`の形式にならって`cmake/MyDriverSources.cmake`に記述し、除外するすべてのファイルとその理由を明記します。

## ステップ5 — テスト規約（プロジェクトのハウススタイルに合わせる）

フレームワークのテストターゲットには次のスイートを用意します：

1. **オフラインテスト** — スキーマ構造、フィールドメタデータ、識別子のクォート処理、コネクションプロパティのラウンドトリップ。これらは常に実行されます。
2. **ライブテスト** — 実際のデータソースと通信し、到達できない場合は**決して失敗（fail）させずスキップ（skip）**します。`MADMySQL/MADMySQLTests/MADMySQLLiveTests.m`がテンプレートです。認証情報は文書化されたローカルサーバーをデフォルトとし、すべての項目を環境変数（`MAD_MYSQL_TEST_HOST`、`MAD_MYSQL_TEST_PORT`、`MAD_MYSQL_TEST_USER`、`MAD_MYSQL_TEST_PASSWORD`、`MAD_MYSQL_TEST_SCHEMA`）で上書きできるようにし、各ライブテストの先頭で`XCTSkipIf(![self serverIsAvailable], …)`を呼び出します。これにより、対象サーバーがないマシンでもテストスイート全体はグリーンになります。なお、MySQLテストファイルのコメントにある通り、iOSシミュレータ内では`localhost`ではなく`127.0.0.1`を使用してください。
3. **レジストリテスト** — `MADDatabaseDriverRegistryTests`がその形を示しています。テストドライバを登録し、ルックアップを検証し、重複した型の登録で例外が投げられることを検証します。構造上、新しいドライバでも同様のテストをすぐに追加できます。
4. ドライバをヘッドレスビルドに含める場合は、スイートを`Linux/Tests/`にも移植します（`cmake/`および`Linux/README.md`の「Adding the next framework」を参照）。Apple専用とする場合は、その理由をPRに明記してください。

## ステップ6 — 正直な注意点：非SQLドライバが現時点でできること・できないこと

ここは現時点で未完成の部分であり、意図的に文書化されています（`docs/project/MAD_STRATEGY.md` §4.7）。**実行（execution）**レイヤーはドライバ主導の形になっており、`executeSQL:…intoResultTable:…`と出力先の`MADDataTableWriting`は「テーブルを返すあらゆるもの」という約束を忠実に守っています。しかし、**コンパイル（compilation）**レイヤーは共通化されており、`MADQueryFull`がクエリグラフをドライバごとの1つのSQLテキストにコンパイルします。つまり、ドライバが受け取るのはクエリグラフ（テーブル、フィールド、述語、グループ）ではなく**SQLテキスト**です。

したがって、現時点でREST／Webサービス用ドライバを実装する場合：

* **できること：** スキーマの参照（`getTables…`、`fieldsForTable:…`）、アプリ既存の接続フォームの利用、生成されたSQLの受け取りとAPIコールへの変換、書き込み可能な任意のテーブルへの行データの格納、および更新・レンダリング・エクスポートの全パイプラインの利用——すなわち、完全に動作するドライバを作ることができます。
* **ネイティブにはできないこと：** クエリグラフを直接受け取ることはできません。エンジンが*何を*要求しているかを知るには、渡された文字列からSQLテキストを再度パースする必要があります。実用的な回避策として、エンジン自身のSQLパーサー（SQL直接入力機能のために構築されたもの、`docs/project/MAD_SQL_ENTRY.md`）がサポート対象のサブセットをすでにパースでき、生成されるSQLは構造上そのサブセットに収まるため、ドライバ側でこのパーサーを再利用してグラフを復元できます。
* **本来の解決策：** ドライバごとのコンパイルフックを導入することです。これは2012年当時にSalesforce SFQL向けに構想されていたものと同じ形であり、「ドライバをインストールする」ことが「たまたま構文が合うSQLダイアレクト用」ではなく「あらゆるデータソース用」を意味するようになります。これはエンジン契約の作業（Stage 1）として順序付けられており、単なるドライバ作成よりも踏み込んだ最初のPRに挑戦したい方には大歓迎のテーマです。

最後に、ドライバそのものではなくサーバー運用に関する注意点をもう1つ挙げておきます。ユーザーがインストールしたドライバは**サーバープロセス内で実行される任意のコード**です。現在のレジストリは信頼されたファーストパーティ製ドライバを対象として機能しています。ドライバマーケットプレイスを実現するには、署名、サンドボックス化、またはワーカープロセス分離が前提となり、それは後から付け足すのではなくサーバーAPIの設計段階で組み込まれるべきものです。

## ステップ7 — PRの提出

ドライバ提案用のIssueテンプレートから提案を行い、[CONTRIBUTING.md](https://github.com/mthomason/MAD/blob/master/CONTRIBUTING.md)のテストファースト原則（まず失敗するテストを書き、次にグリーンになるよう実装する。期待値を新しいコードで生成するのではなくフィクスチャをスナップショットする）に従ってください。また、ドライバが新しいサードパーティライブラリをリンクする場合は、[docs/project/THIRD_PARTY_LICENSES.md](https://github.com/mthomason/MAD/blob/master/docs/project/THIRD_PARTY_LICENSES.md)およびライセンス上の義務に関する記述を必ず更新してください。本リポジトリではこのファイルを厳格に管理しています。
