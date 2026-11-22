---
layout: default
title: "クエリデザイナへのSQL貼り付け"
description: "サポートされるSQLサブセット、パーサ、および適用パス。"
lang: ja-JP
---

# MAD SQL Entry — SQLクエリをクエリデザイナに貼り付ける

このページはSQL入力機能を記録します。サポートされる`SELECT`サブセット、パーサとリゾルバ、およびステートメントをポータブルなクエリグラフに戻す適用パスです。Phase A〜Dは実装済みで、Phase Eは延期されています。

**スコープ:** `MAD/Source/sql/`の新しいパーサ／リゾルバ／コンパイラ、`MADocument`上の適用パス、`MADDesigner`のSQLポップオーバー、永続化されるソーステキスト（§8、ストアの最初のバージョニングステップを追加）、およびそれらすべてを固定するテスト。
**日付:** 2026-10-22、`cf0fe3acd`で読了。2026-10-22に永続化の決定（§8）で改訂。
**ステータス:** 実装済み——Phase A〜Dは2026-10-22に着地し、`c48a39fb7`としてmasterにマージされました（内部タスクキュー§16）。Phase E（§9）は延期されたままです。§8.1〜§8.2は実装どおりの修正を伝えます。

---

## 1. 目標

今日、クエリを構築する唯一の方法はビジュアルデザイナです。テーブルを選び、フィールドごとにリンクし、フィルタを追加し、グループ化を追加します——すべてタブ付きUIを通じて。ユーザーは2つ目の入口を望んでいます。

> 「……ユーザーがボタンを押すと画面が反転し、マルチラインのテキストビューが表示されてSQLを貼り付けられる……そのSQLが保存されると、バックエンドでレポートのクエリを手動で作成する……ユーザーがすべての詳細を選択するのと同じことをすべて行う……ソフトウェアはどのフィールドが使われ、どの結合が使われ、どのテーブルが使われたかを依然として認識し、ドキュメントを適切な方法で完全にセットアップし、その後ユーザーが望めば標準クエリで入力されたフィールドでクエリデザイナを使うことさえできる。」

つまり、貼り付けられたSQLは**ドキュメントのクエリモデル**（`Rptq`オブジェクトグラフ）に、ビジュアルデザイナが呼ぶのとまったく同じファクトリを通じて**コンパイルされます**。適用後、ビジュアルクエリデザイナ、ビジュアライゼーションキャンバス、レポートデザイナは、クエリが手で構築されたかのように見えます——そしてユーザーはそこで編集を続けられます。検証フェーズが必要です。

## 2. 今日存在するもの（直接読んだ）

### 2.1 正規クエリモデル — `Rptq`グラフ

ドキュメントのクエリはポータブルストアにプレーンな`Rptq*`オブジェクトとして存在し（`MAD/Source/rptq/`）、`MADModel*`レイヤーはそれらの上への読み取り専用ビューです（`MADModel_Layer.md`）。インポータは`Rptq`行だけを書き、それ以外は書きません。

* `RptqQuery`（`MAD/Source/rptq/autogen/RptqQuery.h:30-34`）: `hasQueryTables`、`hasQueryLinks`、`hasQueryPredicate`（単数形の名前に注意）、`hasQueryGroups`。
* `RptqQueryTable` — スキーマテーブル参照とエイリアス。エイリアスは*計算*されます。最初のコピーはスキーマテーブルの名前、以降は名前+ドロップインデックスです（`Customer`、`Customer0`、……——`MADModelQueryTable.m:119-129`）。
* `RptqQueryField` — 2つのID: `inQueryTable` + `databaseSchemaField`。すべてのクエリテーブルのすべてのフィールドが1行を得ます（add-tableフローがスキーマフィールドごとに1つ作成します、`MADQueryViewController.m:762-770`）。
* `RptqQueryLinks` — 1つの結合: `hasLeftField`/`hasRightField`（それぞれ`RptqQueryField`）、`type`（`MADLinkType`、`MADQueryLinkType.h`: inner / equi / natural / cross / left / right / full outer）。リンクごとに正確に1つのフィールド対で、ジェネレータは常に`ON l = r`を出力します（`MADQueryFull.m:366-380`）。
* `RptqQueryPredicate` — `comparson`（`MADPredicateOperator`: `=`, `<>`, `>`, `>=`, `<`, `<=`——`MADPredicateOperator.h`、`RptqQueryPredicate+Extras.m:245-265`）、および左／右辺は`RptqQueryField`か型付き値文字列（`leftFieldID`/`rigthFieldID`）。すべての述語はANDされ、それぞれ`(left op right)`と書かれます（`MADQueryPredicate.m:43-93`）。OR、LIKE、IN、関数はありません。
* `RptqQueryGroup` — `hasField`、`sort`（`MADSortOrder`）、`weight`、および`hasSection`。レポートのグループヘッダー／フッターセクションです（`RptqQueryGroup.h:24-29`）。

モデルが**保持しない**もの——インポータが尊重しなければならない境界:

* **SELECTリストがない。** SELECTはSQL構築時に、どのクエリフィールドがデザイナ要素（データラベル、集計、バーコード）、リンク、グループに参照されるかから導出されます（`MADQueryActiveQueryFields.m:37-97`、`MADQuerySelectExpressionActiveFields.m`）。
* **自由なORDER BYがない。** ソート順はグループごとにのみ存在します（`RptqQueryGroup.sort`）。
* **OR / IN / LIKE / 関数 / サブクエリ / UNIONがない**——どれも表現できません。
* **保存されたSQLテキストがない**、また列を追加するためのストアバージョニングもありません（以下、§8）。

### 2.2 SQL生成 — ラウンドトリップ契約

`MADQueryFull`はモデルから実行SQLを構築します（`SQLOnlyActiveFields:managedObjectContext:error:`、`MADQueryFull.m:143-273`）。

* `SELECT`部分はドライバから、次にアクティブフィールドを列エイリアスでソートし、**`AS`なしで**書きます: `"Table0"."Field"`（`MADQuerySelectExpressionActiveFields.m:32-38, 46-53`）。
* `FROM` — 結合グラフ上のDFS: `tableName <connector> queryAlias`、次にリンクごとに`LEFT OUTER JOIN tableName <connector> queryAlias ON l.field = r.field`（`MADQueryFull.m:275-426`、結合テキストは`RptqQueryLinks SqlForLinkType:`から、`RptqQueryLinks+Extras.m:76-86`）。
* `WHERE` — ANDされた述語の三つ組（`MADQueryPredicate.m`）。
* SQLに`GROUP BY`/`ORDER BY`はありません——グループ化とソートは`.maddb`キャッシュ上で適用されます（`MADParameters+QueryCacheAggregate`、`MADQueryCacheSelectGroupKeys`）。
* ドライバが供給する`LIMIT`句。

したがってインポータの契約は次のとおりです。**貼り付けられたステートメントは、あるモデルに対して`MADQueryFull`の出力であり得る場合に正確に受け入れ可能です。** これがラウンドトリップを正直にします。SQLポップオーバーのView側はインポートされたモデルから再生成されたSQLを表示し、それはユーザーが貼り付けたもののように読めます。

### 2.3 リフレッシュパイプライン — 検証が再利用するパターン

`MADOperationRefresh.m:60-172`: オペレーション依存から供給される認証情報で接続し、**メインキュー上で**SQLを構築し（ストアコンテキストはメインキュー所有——BUGS.md）、次に`[database executeSQL:fieldKeys:onConnection:intoResultTable:withError:]`（`MADDatabaseProtocol.h:33`）と`dataTableMakeCache`。検証プローブはキャッシュ構築を除いた同じオペレーション形状です。

### 2.4 UIがすでに呼ぶバックエンド — コンパイラが再利用するシーム

`Rptq`行を書いて保存するだけで十分です。`MADModel*`レイヤーはストア通知を通じて変更をUIにミラーします（`MADModel_Layer.md` §3.3）。今日のUIコードからそのまま呼ぶファクトリ:

* **テーブル追加** — `[RptqQueryTable newQueryTableForSchemaTable:database:forManagedObjectContext:]`、次にスキーマフィールドごとに`[RptqQueryField newQueryField:context]`を1つ、テーブルに配線し、テーブルを`query.hasQueryTables`に追加し、保存（`MADQueryViewController.m:744-799`）。
* **リンク追加** — `[RptqQueryLinks newQueryLinksWithLeftField:rightField:joinType:managedObjectContext:]`、次に`[document.activeDocumentModel addQueryLink:link]`、保存（`MADQueryLinkBuilderController.m:112-122`）。
* **述語追加** — `[RptqQueryPredicate newQueryPredicateFactoryWithLeftFieldID:…]` / `…WithLeftValue:…`の変種（`MADQueryAddPredicateController.m:142-162`、`RptqQueryPredicate+Extras.h:20-39`）。
* **グループ追加** — `[document addQueryGroupWithQueryField:andSortOrder:]`（`MADocument.m:728-792`）。この1回の呼び出しがグループ行*と*レポートのグループヘッダー／フッターセクション*と*それらのセクションレイアウトマネージャを作成します——`GROUP BY`のために「ドキュメントを完全にセットアップ」を無料で行います。
* **置換パスのための削除** — `removeGroupWitObjectID:fromManagedObjectContext:`（`MADocument.m:1130`）、`deleteDatafieldsRelatedToTable:inContent:`と`deleteAggregateFieldRelatedToTable:inContent:`（`MADocument.h:91-95`）、およびクエリUIの既存のリンク／述語削除パス。Phase Bがこれらを棚卸しし、リンク／述語の対称ヘルパーで欠けているものはそこで追加されます。

### 2.5 UIシーム

クエリビルダのスプリットビューコントローラはすでに`barButtonItemSQL`ツールバー項目を持ち、**読み取り専用**の`MADViewControllerSQL`ポップオーバーを提示します（`MADQueryBuilderSplitViewController.m:31, 106-111`、`MADQuery.storyboard`、`MADViewControllerSQL.m:27-56`は`[doc.mainQuery SQLOnlyActiveFields:…]`を表示）。機能はこの同じ画面のモードであるため、ボタン、ポップオーバー、ナビゲーションはすべて存在します。

## 3. ユーザーが見る機能

1. クエリタブで既存のSQLボタンをタップします。ポップオーバーは**View / Edit**モードを持ちます。
2. **View**はクエリのSQLの両方の表現をセグメントコントロールとして表示します。
   * **Generated** — `MADQueryFull`が今モデルから構築するSQL（今日のポップオーバー内容をデフォルトタブとして保持）。
   * **As entered** — ユーザーが最後に適用したステートメントそのまま（`RptqQuery.sqlSourceText`、§8）。クエリが貼り付けSQLから構築されたことがない場合は非表示か空です。
   両方のタブは読み取り専用です——「貼り付けたものと、それが何になったかを見る」画面。
3. **Edit** — 等幅のマルチラインテキストビュー。`sqlSourceText`がある場合はそこからシードされ（ユーザーは*自分の*テキストを、書式とコメントを保ったまま再編集します）、そうでなければ生成SQLからシードされます。**Revert to generated**ボタンが生成形式から再シードします。
4. **Validate** — 構造チェックと、ドキュメントのデータベースに到達できる場合のゼロ行サーバープローブ（§7）。エラーは行と列付きで返ります。
5. **Apply** — ステートメントがドキュメントにコンパイルされ（アトミック——§6.5）、貼り付けたテキストそのものが`sqlSourceText`として永続化されます（§8）。ポップオーバーが閉じ、クエリテーブルリスト、ビジュアライゼーションキャンバス、レポートデザイナがすべてインポートされた構造を表示します。デザイナのフィールドピッカーは通常どおり動作します。
6. 失敗または競合した適用は何も永続化しません——テキストも、行も。以前のクエリと以前の入力テキストはまったくそのまま残ります。
7. ユーザーはいつでも戻れます。ビジュアルデザイナはインポートされたクエリで動作し続け、Viewは両方の形式を表示し、Editはユーザー自身の言葉を再び開きます。

## 4. アーキテクチャ

```
pasted SQL
  → MADSQLTokenizer        dialect-aware lexer; quotes per driver; tracks line:column
  → MADSQLParser           recursive descent; produces a MADSQLStatement parse tree
  → MADSQLStatementResolver  binds names to RptqDatabaseSchemaTable / RptqDatabaseSchemaField
  → [MADOperationValidateSQL]  server probe, when connected (§7); never writes
  → MADSQLQueryCompiler    the write plan: deletes + creates Rptq rows via the §2.4 factories
  → store save → model notifications → query UI / visualization / designer update
```


**配置。** プローブオペレーションとエディタUIを除くすべてが`MAD`フレームワークにあり、純粋なFoundationでUIKitなしです。そのため`MAD`テストスイートとLinuxイメージで実行されます。新しいファイルは`Linux/cmake/MADSources.cmake`に載り、`./Linux/build.sh`はグリーンを保ちます。プローブオペレーション（ドライバ、認証情報、UIKitアラートが必要）とポップオーバーUIは`MADDesigner/Source`にあります。

**新しいファイル。** `MAD/Source/sql/MADSQLTokenizer.{h,m}`、`MADSQLParser.{h,m}`、`MADSQLStatement.{h,m}`（ツリーとその値型: `MADSQLColumnReference`、`MADSQLPredicateTerm`、……）、`MADSQLStatementResolver.{h,m}`、`MADSQLQueryCompiler.{h,m}`、`MADSQLCompileError.{h,m}`。アプリ: `MADOperationValidateSQL.{h,m}`（`MADOperationRefresh`をミラー）、および同じストーリーボードシーム内の`MADViewControllerSQL`または兄弟エディタコントローラのエディタ変更。

**小さなAPI追加。** レキサは接続が存在する前に各方言の識別子引用（MySQLのバッククォート、T-SQLのブラケット、二重引用符）を必要とします。`MADDatabase`に`+ (NSString *)identifierQuoteCharacters`を追加し（デフォルト: 二重引用符）、`MADMySQL`/`MADTdsClient`でドライバごとに上書きします（`MADPostgres`はデフォルトの二重引用符を使います）——または好みなら、`MADDatabaseDriverRegistry`を通じて解決されるドライバプロトコルのクラスメソッド。いずれにせよ3メソッドの追加です。

## 5. サポートされるサブセット

インポータは**モデルが保持できる言語を正確に**受け入れます——1つの`SELECT`、どこにもサブクエリなし、各句は§2.1の制限内です。

* **SELECTリスト** — 列参照のみ: `col`、`tbl.col`、`schema.tbl.col`、`alias.col`、引用または裸、および`alias.*` / `schema.tbl.*`。リストは*検証され、テーブル／列の発見に使われ*、保存されません（モデルにSELECTリストはない——§2.1）。すべての列が解決されなければならず、修飾された列は`FROM`に現れるテーブルを名指ししなければなりません。式、集計、エイリアス（`AS x`）、`DISTINCT`はPhase E（§9）へのポインタとともに拒否されます。Phase Eは貼り付けられた列リストをデザイナ要素の合成によって実体化するフェーズです。入力テキスト自体は`sqlSourceText`（§8）にそのまま保存されます——検証形状と入力テキストは別物です。
* **FROM** — 1つのテーブル参照`[schema.]name [AS alias]`、次に`[INNER] JOIN`、`LEFT [OUTER] JOIN`、`RIGHT [OUTER] JOIN`、`FULL [OUTER] JOIN`のチェーン／ツリー。それぞれ正確に1つの等結合条件`l.col = r.col`を持ちます（裸、2部、または3部の`schema.tbl.col`列。曖昧でなければ裸も許可）。
  * エイリアスはスキーマテーブル自身の名前（またはそのドット除去形式）、または同じテーブルの2つ目のコピーのためのドロップインデックス形式（`name0`、`name1`、`schema.name0`、または`RptqQueryTable -queryAlias`に一致するドット除去`schemaname0`）でなければなりません——モデルはエイリアスを自身で計算し、名前変更を保持できません（`Customer AS c`は拒否: 「デザイナがテーブル自身に名前を付ける」）。
  * 与えられたテーブル対の間の結合は最大1つ（ジェネレータはテーブル対ごとに1つの`JOIN`を出力し、同じ対の2つのリンクはエイリアスを二重にします）。
  * カンマ結合なし、`NATURAL`/`CROSS`結合なし（リンクモデルは正確に1つのフィールド対を保持し、ジェネレータは常に`ON …`を書きます）、`FROM`/`ON`にサブクエリなし。
* **WHERE** — 比較`left op right`の論理積（AND）、`op` ∈ `{ =, <>, >, >=, <, <= }`（`MADPredicateOperator`集合）、各辺は列参照かリテラル。括弧はフラットなAND形状を変えない場所でのみ受け入れられます。それ以外——`OR`、`IN`、`BETWEEN`、`LIKE`、`NOT`、関数、サブクエリ——は拒否されます。述語モデルはフラットな三つ組をANDするだけです。
* **GROUP BY** — 列参照を順序（weight）でインポートし、それぞれが`MADocument`ヘルパーを通じてグループになり、レポートのグループセクションも作成します。
* **ORDER BY** — **すべての列がGROUP BY列である場合にのみ**受け入れられ、asc/descはグループのソート順にマップされます。それ以外は拒否されます（モデルに自由なソートはない）。
* **LIMIT** — 拒否されます。アプリは自身のデザイナ／レポーティングモードのリミットを適用します（`MADDocument.limitResultsDesignMode`、`MADQueryFull.limitResults`）。

リテラルは生成時に方言ごとに処理されます（`newSafeLiteral:`、`MADDatabaseSQLProtocol.h`）。インポータは述語UIとまったく同じように、値文字列とフィールドのデータ型だけを記録します（`MADQueryPredicate.m:74-88`）。

拒否は決して静かではありません。すべてが構文、句、理由（どのモデル制限に当たるか）、および行:列を名指しします。

## 6. 解決とコンパイル

### 6.1 リゾルバ

* エイリアス（または裸のテーブル名）→ 名前で`RptqDatabaseSchemaTable`、大文字小文字を区別しない。不明 → エラー「unknown table」。
* 列 → `RptqDatabaseSchemaField`: 修飾されたものはそのテーブルに存在しなければならず、裸のものは`FROM`集合全体で一意でなければならず、そうでなければ「ambiguous column」。

### 6.2 書き込みプラン

リゾルバの出力は値オブジェクトのプランです。順序付きテーブルリスト、結合リスト（結合ごとの`MADLinkType`）、述語リスト（`MADPredicateOperator` + 左／右項）、ソート順付きグループリスト。プランは何かが書かれる前に全体として検証されます。

### 6.3 競合チェック — 適用はアトミック

適用はクエリを**置き換えます**（貼り付けられたSQL*が*クエリです——それが機能です）。書く前に、新しいプランが**含まない**すべてのテーブルについて、デザイナ要素からの参照をチェックします——`MADQueryActiveQueryFields`が知る3つの形状（`MADQueryActiveQueryFields.m:37-68`: ラベルデータ、集計、バーコード参照）と、削除されるグループセクション。削除されたテーブルのフィールドが参照されている場合、要素を名指しするエラーで中止します（「このフィールドはデザイナの……で使われています」）。何も削除されず、何も書かれず、古いクエリは依然として実行されます。これはインポートがアトミックかつ静かであり得ない唯一のケースであり、そのため大声で失敗します。

### 6.4 書き込み

逆依存順で§2.4のヘルパーを使って: リンクと述語を削除し、グループを削除し（既存のグループ削除パス経由で、セクションとレイアウトマネージャを切り離します）、プランにないテーブルを削除し（既存の`deleteDatafieldsRelatedToTable:`ファミリ経由）、次にUIが呼ぶのと同じファクトリを通じてテーブル → リンク → 述語 → グループを作成します。1回の保存。呼び出し元はその後ドキュメントをダーティにし、add-tableフローがするように自動保存します（`MADQueryViewController.m:796-799`）。

### 6.5 書き込みの後

UIを突つきません。ストア通知パスがモデルレイヤーと両方のクエリ画面を更新します（`MADModel_Layer.md` §3.3）。コンパイラはポップオーバーのためにサマリ（テーブル／リンク／述語／グループの数）を返します。

## 7. 検証 — 2つのレベル

**構造的（常に、オフライン）。** パース+解決、§5〜§6。エラーは`MADSQLCompileError`ドメインの`NSError`で、コード、行、列、メッセージを持ちます。ドキュメントのデータベースに到達できない場合、これが機能のすべてです。

**サーバープローブ（接続できる場合）。** ステートメントをラップします。

```sql
SELECT * FROM (<user sql>) AS _mad_probe WHERE 1=0
```


派生テーブルのエイリアスはMySQLで必須でT-SQLで有効です。`WHERE 1=0`は折り畳まれるため、プローブはクエリをコンパイルし、行を読まずに列メタデータを返します。`MADOperationRefresh`の形状（`MADOperationRefresh.m:104-162`）で実行します。オペレーション依存からの認証情報で接続し、ストア読み取りをメインキューにマーシャルし、結果はドライバの`executeSQL:…intoResultTable:…`経由で得て、`MADDataColumn`が名前と型を与えます。プローブは静止解析ができないものを捕捉します。サーバーサイドの名前解決（大文字小文字の区別、ビュー、予約語）、方言差、サーバー自身の構文エラーで、サーバーのメッセージとともに表面化されます。列名／型は解決されたスキーマフィールドと比較され、不一致は失敗ではなく警告として報告されます。

オフライン、または認証情報が利用できない場合、プローブはスキップされ、UIは「構造によってのみ検証済み」と表示します。

## 8. 永続化されるソーステキスト — `RptqQuery.sqlSourceText`

コンパイルされたモデルは実行のための真実の源のままですが、**ユーザーが貼り付けたテキストはドキュメントの一部です**。`RptqQuery`の新しいNULL可能テキスト属性`sqlSourceText`が、最後に正常に適用されたステートメントをそのまま保持します。ユーザーの言葉を削除することは決して選択肢ではありませんでした——ドキュメントは入力とそのコンパイルの両方を保ちます。ユーザーは履歴配列ではなく単一プロパティを選びました（2026-10-22）。リビジョン履歴は後で順序付きto-manyとして追加し、現在のテキストからデータ損失なしでバックフィルできます。

永続化ルール:

* 成功したApplyだけが書き、丸ごと置き換えます。失敗または競合した適用はストア行にもこのテキストにも触れません（§3.6）。
* Editビューは存在する場合そこからシードし、Viewタブはそれを**As entered**として**Generated**の隣に表示します（§3.2-3.3）。

### 8.1 ストア変更

属性はスキーマのクロスチェックの両側に着地します。コンパイルされたモデルと手で維持される`MADStoreSchema`記述子、および`RptqQuery`のautogenプロパティ（`MAD/Source/rptq/autogen/`）。`MAD_FORMAT.md`はそのフィールドリストに列を獲得します。

**修正（Phase A、2026-10-22）。** モデル変更は**新しい`MAD 4.xcdatamodel`バージョン**であり、その場での`MAD 3`編集ではありません。出荷済みモデルバージョンのハッシュはすべての野生のドキュメントのストアメタデータを固定し、それを編集するとそれらを孤児にします。`MAD 4`はまた、`RptqDocumentElementBarcode.barcodeBorderType`の死んだ`elementID="type"`を落とします（`MAD 3`以前のバージョンにバーコードエンティティはありません。BUGS.md）。

### 8.2 ストアバージョニング — 新しく、小さく、今や必須

ポータブルストアには今日バージョニングがありません（`MADStore.m`は`user_version`プラグマを持ちません）。このフェーズは機構を追加し、意図的に最小限にします。

* `MADStoreSchema`がバージョン定数とマイグレーションステップの順序付きリストを得ます。今日そのリストは1つのエントリを持ちます。バージョン1（野生のスキーマ——`user_version`なしまたは0）→ バージョン2（`sqlSourceText`を追加する`ALTER TABLE`）。
* オープン時に`MADStore`が`PRAGMA user_version`を読み、欠けているステップをトランザクションで適用し、新しいバージョンを書きます。新しいストアは現在のバージョンで作成されます（`createSchemaSQL`はすでにスキーマ全体を生成します）。
* `MADLegacyStoreConversion`はフローで影響を受けません——変換されたCore Dataドキュメントは同じ`MADStore`オープンパスを通じて現在のバージョンで作成されます。
* Linuxヘッドレスエンジンは同じ`MADStore`コードをコンパイルするため、既存ドキュメントはイメージ内で同じように開きます。マイグレーションテストもそこで実行されます。

**修正（Phase A、2026-10-22）。** `MADStoreConverter`は各レガシーストアをそのメタデータに一致するmomdバージョンで開くようになり、自動マイグレーションは決して使いません。Core Dataはこのモデルファミリのマッピングを推測できず（バーコードの`elementID`衝突、BUGS.md）、momd-currentモデルはもはや野生のストアが書かれたバージョンではないからです。

### 8.3 検討して却下: gutsメタデータplist

gutsディレクトリでストアの隣に乗るメタデータplistは、スキーマ変更なしでテキストを保持できました。却下: クエリデータはストアのクエリ部分に属し（`MADStorePartQuery`——ストアの契約は「3つの部分とそれ以外何もない」、`MADStoreSchema.h:12-13`）、ヘッドレスエンジンはplistではなくストアを読みます。

### 8.4 これがアンブロックする未来

保存された入力テキストは、製品の地平線にあるエージェント駆動のクエリ設計（`MAD_FUTURE.md`）の自然な入力表面です。エージェント——または人——がステートメントを書き、下のコンパイラがそれをドキュメントに変え、`sqlSourceText`が記録のプロンプトを保ちます。厳格なコンパイル済みモデルアーキテクチャがそのステップワイズを可能にします。書き手がエージェントになってもコンパイラについて何も変わりません。

## 9. フェーズ

**Phase A — 永続化されるソーステキスト: ストアバージョニング（MADのみ。Linuxグリーン）。**
1. `RptqQuery`の`sqlSourceText`: コンパイル済みモデル+`MADStoreSchema`記述子+autogenプロパティを1つの変更で（さもなければクロスチェックテストが失敗します）。
2. §8.2のバージョニング機構——バージョン定数、マイグレーションリスト、オープン時の`user_version`読み取り／適用／書き込み、現在のバージョンでの新規ストア。
3. テスト: `MADStoreSchemaTests`が両側でグリーンを保つ。新しいマイグレーションテスト（§10.2）。`MAD_FORMAT.md`更新。

受け入れ: このフェーズ以前に作成されたドキュメントがきれいに開き、列を得て、データを保ち、Linuxを通じてラウンドトリップする。新しいドキュメントは現在のバージョンで生まれる。このフェーズは自己完結しており、パーサより先に、独立して着地します。

**Phase B — ゴールデンテスト、次にパーサ（MADのみ。Linuxグリーン）。**
4. `MADQueryFull`の方言ごとの正確な出力を固定するゴールデンSQLテスト（§10.1）——先に書き、パーサが実際のジェネレータに対して構築されるようにする。
5. `MADSQLTokenizer`/`MADSQLParser`/`MADSQLStatement` + 識別子引用API（§4）。
6. `MADSQLParserTests` — §5の受け入れ／拒否マトリックス、エラーコード、行:列。

受け入れ: `MADQueryFull`が出力できるすべてのサポート構文がパースされる。拒否されたすべての構文がコード付きの位置エラーで失敗する。MADスイートと`./Linux/build.sh`がグリーン。

**Phase C — リゾルバ+コンパイラ（MADのみ。Linuxグリーン）。**
7. `MADSQLStatementResolver`、アトミック適用（§6）と成功時の`sqlSourceText`書き込み（§8）を持つ`MADSQLQueryCompiler`。
8. 削除ヘルパーの棚卸し。欠けているリンク／述語削除ヘルパーを追加。
9. `MADSQLQueryCompilerTests` + 不動点ラウンドトリップテスト（§10.4）。

受け入れ: ステートメントを適用すると、ビジュアルデザイナが作ったであろうRptq行を正確に生成し、テキストをそのまま保存する。既存クエリの上に適用しても孤児が残らない。競合ケースはストア——および以前のテキスト——に触れずに中止する。不動点テストが通る。

**Phase D — アプリ（MADDesigner）。**
10. §3のView/Editポップオーバー、`MADOperationValidateSQL`プローブ、サマリビュー。
11. サンプルドキュメント（sqlite3ドライバ——サーバー不要）を使うUIテスト（§10.6）。

受け入れ: 貼り付け → 検証 → 適用で、クエリデザイナとビジュアライゼーションにテーブル／結合／述語が、レポートデザイナにグループセクションが表示され、リフレッシュがクエリを実行する。Viewは生成SQLと入力テキストの両方を表示する。ドキュメントを閉じて再度開いても入力テキストが保たれる。

**Phase E — 延期、独自の決定。**
* SELECTリストのマテリアライゼーション: デザイナ要素（データラベル、集計）を合成し、リフレッシュが貼り付けた列を正確に返すようにする。それまではインポートされたクエリは新しいドキュメントと同じように振る舞います——SELECTは要素、リンク、グループから導出されます（§2.1）。
* 適用されたステートメントの履歴をいつか望むなら: 現在の`sqlSourceText`からバックフィルされた順序付きto-many（§8）——§8.4のエージェント駆動クエリ設計の自然なコンパニオン。

## 10. テスト

### 10.1 既存機能の固定（先に書く）

* `MAD/MADTests`の**ゴールデンSQLテスト**（今日は断片だけをアサートする`MADQueryFullTests.m`を拡張、`MADQueryFullTests.m:140-162`）: 固定ストアフィクスチャ → ドライバ方言ごとの正確な期待SQL文字列（MySQL、TDS、PostgreSQL構成）。エイリアス命名とドロップインデックス形式、すべての結合型、リテラル引用付きのすべての述語演算子、アクティブフィールドの順序をカバー。これらはパーサがラウンドトリップしなければならないジェネレータを固定し、Linuxイメージでも実行されます。
* **ラウンドトリップ契約** — 下の不動点テスト参照。ジェネレータ∪インポータを1つのシステムとして固定します。

### 10.2 ストア永続化とマイグレーションのテスト

* `MADStoreSchemaTests` — 既存のクロスチェックが、記述子とコンパイル済みモデルが`sqlSourceText`で一致することをアサートするようになります（§8.1の両側を一緒に着地させるテストです）。
* 新しい`MADStoreMigrationTests`（MAD）: バージョン1（今日のスキーマ、`user_version`なし）のオンディスクストアを行付きで構築 → 新しい`MADStore`で開く → 列が存在し、`user_version`が現在のバージョンを読み、既存のすべての行と関係が生き残る。新しいストアは現在のバージョンで作成される。2回開くのは冪等。ヘッドレスエンジンがマイグレーションコードを共有するため、これらもLinuxイメージで実行されます。
* コンパイラレベルのアサーション（§10.4）: 成功した適用はテキストを**そのまま**（コメント、空白、大文字小文字）保存し、競合した適用は以前のテキストに触れない。

### 10.3 パーサテスト — `MADSQLParserTests`（MAD）

* レキサ: 方言ごとの引用識別子、エスケープ引用付き文字列リテラル、コメント（`--`、`/* */`）、数値、演算子、大文字小文字を区別しないキーワード、エラー時の位置。
* パーサ: §5の完全な受け入れマトリックス（単一テーブル、各結合型、結合チェーン、ドロップインデックスを含むエイリアス、裸と修飾列、WHERE論理積、GROUP BY、ORDER BY ⊆ GROUP BY）と拒否表（OR、IN、LIKE、サブクエリ、UNION、DISTINCT、SELECT内の式、複数条件ON、エイリアス名前変更、カンマ結合、NATURAL/CROSS、LIMIT、不明テーブル／列、曖昧な列、GROUP BY外のORDER BY）——それぞれがエラー**コード**と行:列をアサートし、メッセージだけをアサートしない。

### 10.4 コンパイラテスト — `MADSQLQueryCompilerTests`（MAD）

スキーマフィクスチャ付きインメモリストア（`MADModelQueryTableTests`が使うパターン）:

* ハッピーパス: 適用 → 結果のRptq行をアサート——正しいスキーマ参照とフィールドごとの行を持つテーブル、正しい`MADLinkType`と左右フィールドを持つリンク、正しい`comparson`と値文字列を持つ述語、ソート／weight**および**作成されたグループヘッダー／フッターセクションとレイアウトマネージャを持つグループ。1回保存。`sqlSourceText`が入力ステートメントと正確に等しい（コメントと空白を含む）。
* 置換パス: データが入ったクエリの上に適用 → 古いテーブル／リンク／述語／グループが消え、孤児行なし（エンティティごとにカウント）、新しい構造が存在し、`sqlSourceText`が置き換えられる。
* 競合パス: デザイナ要素が削除されたテーブルのフィールドを参照 → エラー、および前後スナップショットがストアの変化なし——以前の`sqlSourceText`を含む——を示す。
* **不動点ラウンドトリップ**: ファクトリを通じてモデルを構築 → `MADQueryFull`でSQLを生成 → パース → 新しいストアにコンパイル → 再びSQLを生成 → 2つのSQL文字列が等しい。これが「ソフトウェアが貼り付けられたものを認識する」を*定義*するテストです。

### 10.5 検証テスト

* ドライバごとのプローブSQL構築（ユニット、アプリのテストターゲット内）: ラッパー、エイリアス、`WHERE 1=0`の折り畳み——偽のデータベースで、サーバーなし。
* `MADMySQLLiveTests.m`スタイルの**ライブテスト**（サーバーがなければスキップ）: 有効な貼り付けSQLは期待される列名／型でクリーンにプローブされる。悪い列はサーバーのエラーを返す。ゼロ行が読まれる。

### 10.6 UIテスト — `MADDesignerUITests`

サンプル`.mad`（sqlite3ドライバ）で: SQLポップオーバーを開き、Editに切り替え、フィルタとグループ付きの2テーブル結合を貼り付け、Applyし、クエリテーブルリストが両方のテーブルを表示し、ビジュアライゼーションキャンバスが2つのボックスとコネクタを表示し、デザイナがグループセクションを表示し、Viewモードが再生成SQLを表示することをアサート。次にドキュメントを閉じて再度開く。**As entered**タブは依然として貼り付けたテキストを正確に表示し、**Generated**タブは依然としてコンパイルされたクエリのSQLを表示する——ドキュメントは両方を保った。

### 10.7 テストのための設計制約（実装者に拘束力）

* パーサ／リゾルバ／コンパイラ: 純粋なFoundation、UIKitなし、アプリインポートなし——MADスイートとLinuxイメージがそれらをコンパイルする。
* すべての公開失敗はコード付き`NSError`（`MADSQLCompileError`）。テストはコードをアサートする。
* プローブは小さなプロトコルの背後に置き、ユニットテストがデータベースを偽装できるようにする。ライブカバレッジはライブスイートのみ（既存パターン）。
* コンパイラはドキュメント／コンテキストを取り、ビューコントローラを取らない。アプリはUI形状のものを何も渡さない。
* 新しいMADファイルは`Linux/cmake/MADSources.cmake`に追加され、`./Linux/build.sh`はグリーンを保つ。
* マイグレーション機構はバージョン定数をテストが参照できる共有`MADStore`コードにあり、Apple専用パスにはない——Linuxスイートがそれを行使できるように。

## 11. 決定 — ユーザーと解決済み（2026-10-22）

1. **厳格なサブセット。** 確認済み: モデルが保持できないものは理由とともに拒否されます（§5）。不透明SQLのフォールバックはありません。
2. **適用はクエリを置き換える**（アトミック、§6.3）。確認済み。
3. **GROUP BYのインポートはレポートのグループセクションを自動的に作成する**——既存の`MADocument`ヘルパーがこれを行い、まったくそのまま残ります。確認済み。
4. **SELECTリストはPhase Eまで検証されるが保存されない**——要素合成が存在するまで、インポートされたクエリはユーザーが要素を追加するまで結合／グループ列をリフレッシュで返し、新しいドキュメントとまったく同じです。段階的として確認済み。
5. **貼り付けられたテキストは永続化される。** 確認済み——`RptqQuery`の`sqlSourceText`、最後に正常に適用されたステートメントを保持する単一プロパティ（§8）、**Generated**の隣に**As entered**として表示。生成形式はリフレッシュが実行するもののままで、テキストが保存されることは実行を変えません。履歴配列は検討され、脇に置かれました（§8、Phase E）。
