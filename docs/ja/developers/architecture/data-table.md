---
layout: default
title: "MADDataTableアーキテクチャ"
description: "フレームワーク横断のデータテーブルクラスクラスタとその分離計画。"
lang: ja-JP
---

# MADDataTable — アーキテクチャ＆分離レポート

このページは`MADDataTable`と、`MADFoundation`、`MAD`、`MADSqlite3`、`MADMySQL`、`MADTdsClient`にまたがるすべての実装のアーキテクチャレポートです。クラスクラスタと分離作業を記録します。

*元の日付に書かれ、現状の事実は2026-11-22に整合。*

**スコープ:** `MADDataTable`と、`MADFoundation`、`MAD`、`MADSqlite3`、`MADMySQL`、`MADTdsClient`にまたがるすべての実装、サブクラス、プロトコル、呼び出しサイト。
**ブランチ:** `refactor/mad-database-decouple`
**日付:** 2026-10-01
**検証:** `xcodebuild test` — 11スキームすべて、809テスト、0失敗。スコープ内のどのファイルからも警告なし（`MADDatabaseMySQL.m`の2つの`-Warc-repeated-use-of-weak`警告は既存で未変更）。（Revision 2で798、Revision 3で804、Revision 4で807。）

以下のすべての`file:line`参照はこの分析中に直接読まれたもので、推測ではありません。

> **Revision 5 — 2026-10-01。** Phase 3と5は閉じられ、Phase 1ステップ7は証明されました。
> `-dropTable`、`-dropTableName:`、`-deleteAll`、`-vacuumCacheDb`は今、`rowCounter`を
> ファイルを記述する状態で残します（§2.5）。それがステップ10/11のすべてでした。危険にさらされた
> 3つの定数は4つの新しいテストでカバーされています。裸の`<MADDataTableWriting>`準拠者で
> sqlite行ループを駆動すること——背後に`MADDataTable`なし、`.maddb`なし——がステップ7で、
> 今テストです（`MADWritePortRecorder`）。ステップ14は完了: `MADDataTableLocation`は削除されました。
> ステップ13と15は下のエントリで理由付きで評価され、実行はされていません。
>
> それらのテストを書くことで2つの生きた不具合が落ちてきて、どちらも今修正されています。`-deleteAll`は
> *文字列*を`-[MADQueryCacheDeleteAllFromTable initWithObject:]`に渡し、それは引数をパラメータ辞書として
> 添字アクセスし、最初の行でraiseしました——メソッドに呼び出し元がないため、誰もそれに当たったことが
> ありませんでした。今は`-initWithTableName:`を使います。そして`MTTableController`は失敗パスで
> `datatable.count`をページカーソルとして読み、テーブルはまだ前のページを保持していたため、失敗した
> フェッチが`hasMore = YES`を報告し永遠にリトライしました。
>
> カウンタのコメントが`MADDataTableFast.m`を`-deleteAll`以降で13行シフトさせたため、それ以降のすべての
> `file:line`参照は調整ではなく再導出されました。`MTTableController.m`も動き、その参照もそれとともに
> 再導出されました。
>
> **Revision 4 — 2026-10-01。** Revision 3のMySQL障害はなくなりました。`MADMySQLFetch+DataTable.m`が
> フェッチ中に読む列メタデータは今`<MADDataTableWriting>`自身が宣言するため、3つのドライバすべて——
> `MADDatabaseMySQL`、`MADDatabase.m`、`MADDatabaseDataSource`プロトコルを含む——が
> `id <MADDataTableWriting>`を取り、フェッチの出力パラメータは値渡しです（すべての呼び出しサイトで`&`が
> 落とされました）。Phase 2（「`urlFastCache`を保存し、キャッシュディレクトリを注入する」）とPhase 4
> ステップ12（書き込みパイプラインを直列化する）は完了し、Phase 3は再水和パスのみ完了です。§2.1と
> §2.3〜§2.5と§4.2がそれぞれをマークします。3つのテストが追加され、スイートは804 → 807になりました。
> 修正が`MADDataTableFast.m`を87行シフトさせたため、このレポートのそれへのすべての`file:line`参照は
> 調整ではなく再導出され、付録の行数もそれとともに更新されました。
>
> **Revision — 2026-09-30。** 最初のリビジョンが3点で間違っていると判明した後、§2.5、§3.3、§3.5、
> §4.2が書き換えられました。`-dataForRow:error:`の診断（2行のメソッドシグネチャが誤読された——メソッドは
> `MADDataTableFast`に*実装されています*）、`-allObjects`の「生きた不具合」（本番呼び出し元なし）、
> `rowCounter`ドリフトの枠組み（到達不能）。§4.5は新規です。修正されたテキストは**Corrected** /
> **Fixed**とマークされ、元の主張は示唆的だった場所に可視のまま残されています。このリビジョンで3つの
> コード修正が着地しました——§3.5参照。
>
> **Revision 3 — 2026-10-01。** Phase 1ステップ5が着地しました。`<MADDataTableWriting>`、
> `<MADDataTableReading>`、`<MADDataTableCursoring>`が`MADDataTable.h`で宣言され、クラスは3つすべてを
> 採用します。ステップ6は3つのドライバのうち2つで着地しました——`MADDatabaseSQLServer`と
> `MADDatabaseSqlite3`は今write-port型です。ステップ6は`MADDatabaseMySQL`では着地**できませんでした**。
> ステップ5の「今や冗長なスタブブロックを削除する」は却下されました。§4.2がそれぞれの理由を記録します。
> パス全体は追加的です。振る舞いは変わらず、11スキームすべてが通ります（804テスト）。
>
> **Revision 2 — 2026-09-30。** §4.5の8つの`sqlite3_mprintf`フォーマット文字列サイトは今修正され、
> Phase 0が着地しました。`MADDataTable.m`の未実装オペレーションは静かに失敗するのではなくアサートします
> （§3.2、§4.2）。§3.1の表と付録の行数は変更されたファイルに対して再導出されました。前のリビジョンの
> 2つの誤りも修正されました。ワークスペースのテスト総数は799と述べられていましたが798で、§3.6は
> `_database`サイトを4つ引用していましたが15あります。

---

## 1. 現在のアーキテクチャとクラス階層

### 1.1 クラスファミリ

`MADDataTable`は単一のクラスでは**ありません**。ストレージ軸に沿って3つのフレームワークに分割された小さなクラスクラスタに、別々の列挙子オブジェクトとして実装されたカーソル軸を加えたものです。

```
MADFoundation
└── MADDataTable                          NSObject <NSCoding, NSFastEnumeration>
        │                                 "abstract": declares the full surface,
        │                                 implements metadata + plist persistence
        │
        ├── MADDataTableVirtual            MADFoundation/Source/MADDataTableVirtual.m (240 ln)
        │       In-memory. Rows live in per-column MADDataColumn arrays plus a
        │       `sortIndex` NSMutableArray of row NSDictionaries.
        │
        └── MADDataTableFast               MADSqlite3/Source/MADDataTableFast.m (1368 ln)
                sqlite3-backed. Rows live in a `.maddb` file; the object holds two
                MADDatabaseSqlite3 handles (one for writes, one for reads).

MADSqlite3 (private — NOT exported from the framework)
├── MADDataTableObjectEnumerator          173 ln — wraps a live sqlite3_stmt, yields row dicts
└── MADDataTableSingleColumnEnumerator    149 ln — same, yields a single column (row-ids)

MAD
└── MADDataTable+Constructor              the ONLY place that maps type -> concrete class
                                            (`MADDataTableLocation`, the other class here at
                                            Revision 4, was deleted — see §3.7)
```


検証されたエクスポート表面（ビルドされた`.framework/Headers`から）:

| フレームワーク | 公開エクスポートされるデータテーブルヘッダー |
|---|---|
| `MADFoundation` | `MADDataTable.h`、`MADDataTableType.h`、`MADDataTableVirtual.h` |
| `MADSqlite3` | `MADDataTableFast.h`**のみ** |
| `MADMySQL` | なし |
| `MADTdsClient` | なし |

この分割は意図的で健全です。列挙子クラス名は決して漏れません。消費者は`NSEnumerator *`だけを見て、それが`MADDataTable.h`の返すものです。

### 1.2 2つの直交軸、1つのenum

`MADDataTableType`（`MADFoundation/Source/MADDataTableType.h`）は**ストレージ**軸のみをエンコードします。

```objc
typedef NS_ENUM(short, MADDataTableType) {
    MADDataTableTypeVirtual,    // -> MADDataTableVirtual
    MADDataTableTypePhysical,   // -> MADDataTableFast
};
```


**アクセス**軸——行ごとかカーソルか——は直交し、型ではなく列挙子を返すことで表現されます。`MADDataTableTypeCursor`はありません。これはリファクタにとって重要です。カーソルシームはすでに存在し、正しく隠されています。

### 1.3 サブクラス選択の唯一の点

`MAD/Source/MADDataTable+Constructor.m:51-69`はコードベースで具体的なサブクラスを名指しする唯一の場所です。

```objc
+ (instancetype)newDataTableOfType:(MADDataTableType)type withObjectID:(NSUInteger)objectID {
	switch (type) {
		case MADDataTableTypeVirtual:  result = [[MADDataTableVirtual alloc] initWithId:objectID]; break;
		case MADDataTableTypePhysical: result = [[MADDataTableFast alloc] initWithId:objectID];    break;
		default: NSAssert(NO, @"Not implemented."); break;
	}
	return result;
}
```


コードベースのどこにもデータテーブルに対する`isKindOfClass:`、`NSClassFromString`、クラス名文字列比較、`respondsToSelector:`プローブは**ない**ことを確認しました。これがリファクタにとって最も価値ある性質です——クラスタはこの1つのメソッドの背後で再形成できます。

同じファイルの2つの注意点:

* `+newDataTableWithDefinition:`はオブジェクトIDがないとき`NSAssert(NO, @"Not implemented.")`を呼び`nil`を返します（`:44-46`）。`:31-32`のコメントの「デフォルトでvirtual」という意図は到達不能です——`objectIdSet`が唯一の戻りパスをゲートします。
* `+newDataTableForIdentifier:`（`:79-92`）は*事実上の*公開エントリポイントです。ほとんどの呼び出しサイト（`MTTableController.m:90`、`MADQuerySampleDataTable.m:68`、`MADQuerySampleDataTableRange.m:69`）は代わりに`newDataTableWithDefinition:`を直接通り、常に型をVirtualに固定します。

### 1.4 書き込み契約

すべてのデータベースドライバは**基底クラス**APIを通じてテーブルを充填し、サブクラス固有のAPIは決して使いません。`MADDatabaseSqlite3.m:474-540`が正規のループです。

```objc
[dataTable removeAllObjects];
// first row only:
[dataTable addColumn:dataColumn];       // per column, discovered from sqlite metadata
[dataTable beginBulkInsert];
// per row:
[dataTable addRowWithDataForFieldKeys:resultsForRow];
[dataTable endBulkInsert];
```


`MADDatabaseSQLServer.m:500 / :1367 / :1472`は同一の5呼び出し形状を使います。`MADMySQLFetch+DataTable.m:211 / :438 / :442`も同様です。

これは**狭く、よく定義された書き込みポート**です。5つのメソッド。ファミリで最も強い既存境界であり、リファクタはそのまま保存すべきです。

ドライバ間の差異:

| ドライバ | 構築するテーブル | 書き込みパス |
|---|---|---|
| `MADDatabaseSqlite3` | 渡されたもの（通常`MADDataTableFast`） | `executeSQL:...intoResultTable:` |
| `MADDatabaseMySQL` | **自身で`MADDataTableVirtual`を構築**（`MADDatabaseMySQL.m:83, 110, 137, 175, 196, 376`） | `MADMySQLFetch+DataTable.m` |
| `MADDatabaseSQLServer` | **決して構築しない**——呼び出し元供給のテーブルへの純粋な書き込み専用 | `MADDatabaseSQLServer.m` |

したがってMySQLは`MADDataTableFast`を生成できず、SQL Serverはどのテーブルも生成できません。「物理」（sqliteベース）ストレージはリモート結果ではなくローカルキャッシュにのみ存在します。

### 1.5 読み取り契約

3つの異なる読み取りスタイルが本番で使われています。

1. **ランダムアクセス** — `-objectAtRow:` / `-objectAtRow:column:`。
   `MADMySQL`はO(n)ループ内で`objectAtRow:i column:0`を使い（`MADDatabaseMySQL.m:88-92, 118-122, 150-154, 187-189`）、`SHOW TABLES`結果を読みます。`MADQuerySampleDataTable.m:126` / `MADQuerySampleDataTableRange.m:131`は幅行を読むために`objectAtRow:0`を一度呼びます。`MTTableController.m:281, 284, 393`はページングに`objectAtRow:`を使います。

2. **列挙** — `-enumeratorForKeyObjectsSorted`。
   `MADocument.m:865-867`がこれを`enumeratorForReportData`として返し、`MADReportFormatter.m:449-502`が消費します。

3. **カウント** — `-rowCounter` / `-count` / `-numberOfRows`。
   `MADocument.m:197`（`numberOfResults`）、`MTTableController.m:249`（テーブルサイズ）、`:377, :399, :449, :455`（ページカーソル演算）。

`MADReportFormatter`は最も寛容な消費者で、リファクタを最も制約しません。`MADReportFormatter.m:463-472`に注意:

```objc
if (!calculatedRowId) {
    if ([resultRow isKindOfClass:[NSDictionary class]]) { rowIdOnly = NO; }
    calculatedRowId = YES;
}
self.machineState.detailRowId = rowIdOnly
    ? ((NSNumber *)resultRow).unsignedIntegerValue
    : ((NSNumber *)resultRow[MADIdentifierROWID]).unsignedIntegerValue;
```


フォーマッタは**すでに裸の行ID `NSNumber`を返す列挙子**と完全な行辞書の両方を許容します。`enumeratorForAllObjectsSortedRowIdOnly`はまさにそのケースのために存在します。これは既製のシームです。行IDだけをストリームするカーソルはすでに受け入れられる入力です。

---

## 2. メモリモデル、ライフサイクル、状態

### 2.1 ARCと1つの生ivar

すべてのファイルはARCです（`#if !__has_feature(objc_arc) #warning ...`ガード）。状態はクラス拡張に存在します。`MADDataTableFast`は正確に1つの非オブジェクトivarを持ちます。

```objc
@implementation MADDataTableFast {
	sqlite3_stmt *_statementInsert;   // MADDataTableFast.m:103
}
```


それは`-dealloc`（`:163-165`）と`-endBulkInsert`（`:1334-1339`）でファイナライズされます。パターンは正しいですが*壊れやすかった*です。`-endBulkInsert`はバリアを取る**前に**ステートメントをnullにしていたため、ティアダウンが挿入が実行中でない唯一の窓の外にありました。

**修正（Revision 4）。** ティアダウンは今バリアの内側、`:1337-1338`で実行されます。

### 2.2 1つのファイル上の2つのsqlite接続

`-reopenDbConnection`（`:385-401`）は同じ`.maddb`ファイルを指す**2つの**独立した`MADDatabaseSqlite3`インスタンスを構築します。

```objc
// write handle
MADDatabaseConnection *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:urlFastCache];
MADDatabaseSqlite3 *database = [[MADDatabaseSqlite3 alloc] init];
database.delegate = (id <MADDatabaseResultsProtocol>)cacheDelegate;
database.databaseConnection = connection;
[(MADDatabaseSqlite3 *)database openDatabaseWithFlags:
     SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX];
self.databaseForInserts = database;

// read handle — same URL, separate connection, default flags
MADDatabaseConnection *connectionSelect = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:urlFastCache];
MADDatabaseSqlite3 *databaseSelect = [[MADDatabaseSqlite3 alloc] init];
[databaseSelect setDatabaseConnection:connectionSelect];
[databaseSelect openDatabase];
databaseSelect.delegate = (id <MADDatabaseResultsProtocol>)cacheDelegate;
self.databaseForSelects = databaseSelect;
```


読み取りハンドルは**`-openDatabase`（デフォルトフラグ）**で開かれ、書き込みハンドルは`SQLITE_OPEN_FULLMUTEX`で開かれます。`SQLITE_OPEN_FULLMUTEX`は**接続ごと**の直列化モードで、同じファイル上の2つの接続間を仲裁しません。§2.4と組み合わせると、これがファミリで最大の正確性の前提です。

### 2.3 ストレージ位置は周囲のグローバル状態から解決される

`-urlFastCache`は*計算された*プロパティで（このリビジョン前は`:299-311`）、保存されていませんでした。

```objc
- (NSURL *)urlFastCache {
	NSString *filename = [[self filenameCacheMadDB] copy];
	NSURL *cacheDirectory;
	if (self.cacheDelegate == nil) {
		id <UIApplicationDelegate, MADApplicationProtocol> appDelegate = [MADApplication AppDelegate];
		id groupIdentifier = [appDelegate groupIdentifier].copy;
		cacheDirectory = [MADURLFactory newURLForLocalCacheDirectoryForGroupIdentifier:groupIdentifier];
	} else {
		cacheDirectory = [self.cacheDelegate cachedFilesDirectory].copy;
	}
	return [cacheDirectory URLByAppendingPathComponent:filename isDirectory:NO];
}
```


帰結:

* `cacheDelegate`のないテーブルは、そのオンディスクアイデンティティを**グローバルなアプリデリゲートに静かに依存**します。それが、`MADDataTableFast`がデリゲートなしのホストレスロジックテストでインスタンス化できなかった理由で、回帰スイートは`MADCacheProtocol` + `MADDatabaseResultsProtocol`に準拠するスタブで回避しています。
* `-setCacheDelegate:`（`:377-383`）は`-reopenDbConnection`を呼びます。デリゲートの差し替えは`tag`/`rowCounter`/`columnKeys`をメモリに保ったままテーブルを**別のファイルに再ポイント**します。何も不一致を検出しません。
* `-copyPlist`は`urlFastCache != nil`をアサートします（`:243`）——そのためアーカイブされたテーブルの永続化URLはアーカイブ時の周囲状態に依存します。

**修正（Revision 4）。** `-urlFastCache`は今一度解決して答えを保持します（`_urlFastCache`、`:347-355`、ゲッターと`-setCacheDelegate:`（`:377-383`、再オープン前に落とす）が書く）。`-newUrlFastCache`（`:357-373`）が解決自体を保ち、新しい第一候補としてinitで供給されるキャッシュディレクトリを持ちます。`MADDataTableFast`は`-initWithId:cacheDirectory:`（`:173-181`）を得て、`+[MADDataTable newDataTableOfType:withObjectID:cacheDirectory:]`がそれを渡し（`nil`は古い振る舞いを保つ）、デリゲートもアプリもなしでテーブルが使えるように接続を即座に開きます。上のデリゲート差し替えによる再ポイントは依然として起こります——それが「URLはデリゲートから導出される」の意図された読み方です——しかしプロパティが最初に読まれた*時*に依存しなくなりました。

`tag`（`initWithId:fromCache:`、`:190`から設定）が唯一の安定したアイデンティティで、テーブル名（`t<tag>`、`:403-409`）とファイル名（`<tag>.maddb`、`:340-343`）の両方を生成します。

### 2.4 スレッド安全性: ロックなし、1つのキュー

ファミリ全体を`dispatch_sync`、`dispatch_async`、`@synchronized`、`NSLock`、`os_unfair_lock`、`pthread_mutex`でgrepしました。存在する**唯一**の並行性プリミティブは`queueBulkAdd`です。

* 3回別々に作成されます——`initWithId:fromCache:`（`:186`）、`initWithCoder:`（`:202`）、`beginBulkInsert`（`:1322`）——それぞれ`dispatch_queue_create(..., SERIAL)`。
* 正確に**2か所**で使われます。`-endBulkInsert`（`:1334`）が`dispatch_barrier_sync`でデリゲート呼び出しを包み、（Revision 4以降）`-addRow:error:`が`dispatch_sync`でそれに入ります。
* Revision 4以前は`-addRow:error:`の直列化に**決して**使われませんでした。

したがって`-addRow:`——変更エントリポイント——はキューによってまったく保護されていません*でした*。`_bulkInsertLoop`下で、`-addRow:`は呼び出し間で単一のキャッシュされた`_statementInsert`を再利用します（`:529-611`）: `sqlite3_bind_*` → `sqlite3_step` → `sqlite3_clear_bindings` → `sqlite3_reset`、相互排除なし。2つのスレッドが同時に`-addRow:`に入ると、`SQLITE_OPEN_FULLMUTEX`に関係なくその共有ステートメントで競合します。競合はbind/step/clear/resetの*シーケンス*にあり、個々のsqlite呼び出しの内側ではないからです。

回帰スイートは現在の並行動作を記録しますが、安全にはできません——直列化を追加しなければなりません。

**修正（Revision 4）。** `-addRow:error:`（`:504-528`）は今、挿入本体（`:529`の`-insertRow:error:`、旧メソッドの名前変更）を`dispatch_sync(queueBulkAdd)`の下で実行する薄いラッパーで、キューがnilのときだけ直接呼び出しにフォールバックします——それは初期化を完了しなかったテーブルにのみ起こります。`-endBulkInsert`の`sqlite3_finalize(_statementInsert)`はその`dispatch_barrier_sync`の*内側*に移りました。キャッシュされたステートメントは挿入が実行中でないときだけティアダウンされます。シリアルキューではバリアと`dispatch_sync`は相互排他的で、それがbind/step/clear/resetシーケンスに必要な相互排除のすべてです。2つのテストが固定します: `testFastTableConcurrentWritersLoseNoRows`（新規）は*並行*キューから4つのライターを駆動し、`testFastTableSerializedConcurrentWritesLoseNoRows`はアプリのシリアルキューパターンを保ち、その「テーブルは内部で直列化しない」契約ノートが修正されました。ステップ13（ファイルごとに1接続対）は未変更です。

### 2.5 `rowCounter`は派生値ではなく独立したカウンタ

`-insertRow:error:`は`rowCounter`をインクリメントし（`:532`）、**sqliteに決して問い合わせません**。`-numberOfRows` / `-count`はそれを直接返し（`:1222` / `:1216`）、`-removeAllObjects`はそれをゼロにします（`:683`）。しかし`-dropTable`（`:799`）、`-dropTableName:`（`:804`）、`-deleteAll`（`:818`）、`-vacuumCacheDb`（`:789`）はRevision 5までそれに触れ**ませんでした**。

したがって2つの真実の源は乖離できます。

* `rowCounter`がNと言い、`.maddb`ファイルが異なる数の行を保持する。
* `-loadFromCacheWithUrl:`ラウンドトリップで、カウンタはplistから来（`MADDataTable.m:305-306`）、行はsqliteファイルから来ます——2つの無関係な機構で再水和されます。

**修正（Revision 4）——リロード半分。** `-loadWithPlist:`は今`self.rowCounter = [self recountRows];`で終わります（`:313`）。`-recountRows`（`:317-338`）はキャッシュファイルに`SELECT COUNT(*)`を尋ね、テーブルがまだ存在しないときだけplistの値にフォールバックします。メモリ内パスで膨らんだカウンタはリロードを生き延びられなくなりました。`testFastTableReloadRecountsRowsFromCacheFile`が、カウンタが99と言うplistを3行のファイルの上にロードして固定します。

**修正（Revision 5）——メモリ内半分、ステップ10/11。** `-dropTable`（`:799`）と`-dropTableName:`（`:804`）は今カウンタをゼロにし、`-deleteAll`（`:818`）はゼロにし、`-vacuumCacheDb`（`:789`）は意図的にゼロにしません。VACUUMはすべての行を保つからです——ソースはそう述べるコメントを運びます。「なぜこれだけが*リセットしない*のか」は次の読者がまさに持つ問いだからです。`-dropTableName:`は任意の名前を取るため、消えたテーブルがこれであるときだけカウンタをゼロにします。外部テーブルのドロップはこのカウントに触れてはなりません。`-numberOfRows`（`:1222`）と`-count`（`:1216`）は依然としてファイルに問い合わせずivarを返します。それが要点です——`-recountRows`はリロードパスのチェックで、読み取りごとのコストではありません。

`-removeAllObjects`（`:674`）は危険全体を隠していましたし、今も隠しています。4つすべての唯一の呼び出し元で、自身がカウンタをゼロにします（`:683`）。それが、これを放置せず閉じる価値があったまさに理由です——危険は生きたものになるまで呼び出し元1つでした。`-count`はアプリへのページカーソルであり（§4.3）、4つのプライベートメソッドはどこか新しい場所から呼ばれるまで`git log -S`1つです。ここのRevision-4ノートはドリフトを「コードでは本物だが、今日それに到達できる呼び出し元はいない」と呼びました。呼び出し元監査は依然として成り立ちます——`-deleteAll`は**リポジトリのどこにも呼び出し元がなく**、`-dropTable`は`-removeAllObjects`からのみ到達されます——しかしカウンタは今すべてのパスで正しく、唯一の呼び出し元が後で片付けるからだけではありません。`MADDataTableRegressionTests.m`の4つのテストが4つそれぞれを直接駆動します。

`MADDataTableVirtual`は同じ形状（`:179`、`:193`、`:225`）ですが、カウンタと`sortIndex`は一緒に変更されるため、構築上一貫しています。

これはクラスクラスタリファクタで最もリスクのある状態です。`MTTableController.m`は`:377`と`:399`で`datatable.count`を読み、`:455`でそれから`hasMore = (count == limit)`を導出するため、現実からドリフトしたカウンタはページングを破壊します。Revision 5はその導出も完全にします——空のページは`offset + count - 1`を`NSUIntegerMax`にラップせず（`:380`、`:402`）、失敗パスは*前の*ページを依然として記述するカウントを読む代わりに`completion(NO)`を返します（`:449`）。

それらのテストを書くことで、カウンタとは無関係な`-deleteAll`の不具合が浮かびました。それは`NSString`を`-[MADQueryCacheDeleteAllFromTable initWithObject:]`に渡し、それは引数をパラメータ辞書として添字アクセスするため、最初の行で`unrecognized selector`をraiseしました。`-initWithTableName:`が名前を取るイニシャライザで、`MADDatabaseSqlite3 -beginBulkInsert`がすでに使っていたものです。呼び出し元がないため、誰もそれに当たりませんでした。

### 2.6 2つの無関係な永続化機構

| 機構 | 場所 | 保存するもの |
|---|---|---|
| Plist、`NSPropertyListBinaryFormat_v1_0` | `MADDataTable.m:193-220`、`:135-191` | `name`、`columnKeys`、`columns`（メタデータ）、`rowCounter`。**行はなし。** |
| sqlite `.maddb`ファイル | `MADDataTableFast.m` | 実際の行データ、加えて`MADDataTableFast`固有キー（`urlFastCache`、`tag`、`bulkInsertLoop`、`sortDescriptorsSet`、`groupKeyIndexes`） |

基底クラスの`-cacheWithUrl:error:`は汎用キャッシュとして文書化されていますが、実際には*形状*だけをシリアライズし、*内容*はシリアライズしません。`MADocument.m:413-414`は`[self.dataTable newFilenameMDCache]`（`<tag>.mdcache`）から`urlDataTableCache`を導出し、`MADDataTableFast`は`<tag>.maddb`を読み書きします（`:340-343`）。2つのファイル拡張子、2つのフォーマット、2つの所有者、1つの論理テーブル。

**評価（Revision 5）——ステップ15、調整を求めたもの。枠組みが間違っており、それが発見です。** 「基底plistはメタデータのみ」は基底クラスには真で、ファミリには偽です。各サブクラスは`-copyPlist` / `-loadWithPlist:`を正確に1つの追加キーで拡張し、そのキー*が*そのストレージです。

| クラス | ストレージ | それを運ぶplistキー |
|---|---|---|
| `MADDataTable` | なし（抽象） | `name`、`columnKeys`、`columns`、`rowCounter` |
| `MADDataTableVirtual` | `sortIndex`、行辞書の配列（`MADDataTableVirtual.m:106-109`、`:89-104`） | `keySortIndex`——行自体 |
| `MADDataTableFast` | `.maddb`ファイル | `keyUrlFastCache`、`keyTag`、……——行の*ロケータ* |

したがって行はplistがストレージである場所ではすでにplistを通じてラウンドトリップし、ストレージがsqliteファイルである場所ではできません。ファミリ全体にとって、どちらの名前変更（「メタデータと呼ぶ」）も代替（「行を入れる」）も正しくありません。基底クラスは*両方の*サブクラスが共有するメタデータで、機構は設計上サブクラスごとです。2つの拡張は競合でもありません。`MADocument`は`<tag>.mdcache`（plist）を`<tag>.maddb`（行）の隣に書き、`-loadFromCacheWithUrl:`は前者を読んで後者を見つけます——タグが一致する限り。それは一致します。`-filename`（`MADocument.m:1397-1399`）は`fileURL.lastPathComponent`の`stringByDeletingPathExtension`で、initがタグのためにハッシュするのと同じ文字列だからです。

価値があり、ここでは行われていないことは、再構築ではなく文書化です。`MADocument`のキャッシュディレクトリの2つのファイルをそのまま名指しし、`MADDataTable.h`で`-copyPlist`が共有メタデータを返し、独自ストレージを持つサブクラスはそれを拡張しなければならないと述べることです。それは保つべき振る舞いのないコメント変更なので、ここではなくドキュメントパスに属します。

### 2.7 列挙子の寿命

`MADDataTableObjectEnumerator`は自身の`MADDatabaseSqlite3` + 接続 + プリペアドステートメントを保持し、すべて`-initWith...`（`:60-72`）で構築され、`-dealloc`（`:45-49`）で解放されます。したがって:

* 列挙子は保持されている限りデータベースハンドルとファイル記述子を生かし続けます——そして`MADReportFormatter.m:449-502`はレポートレンダリングの全期間それを持ちます。
* テーブルをドロップまたは再構築する変更（`-removeAllObjects`、`-dropTable`）は未処理の列挙子の生きたステートメントを無効化します。何もこれをガードしません。
* 各`-objectEnumerator` / `-enumeratorFor...`呼び出しは同じファイルへの**新しい接続**を割り当てます（`:1139`、`:1158`、`:1186`、`:1202`）。2回列挙するとsqliteを2回開きます。

**評価（Revision 5）——ステップ13、ファイルごとに1つの共有接続対を求めたもの。実行されず、理由は数ではなく寿命にあります。** 挿入接続はまったく共有できません。`MADDatabaseSqlite3 -endBulkInsert`は最後にそれを閉じて`_database`をnullにするため（`:794-795`）、`MADDataTableFast -removeAllObjects`は何かをドロップする前に再オープンし、4つのプライベート変更は直接駆動されるとアサートします（直接駆動するのは間違いです——まさにこの理由で先に再オープンするRevision 5のテスト参照）。共有の「対」はしたがって共有*読み取り*接続とサイクルごとの書き込み接続でなければならず、1つではなく1つのハンドルを節約するだけです。

そして節約は見た目より小さいです。ここのすべての接続は`SQLITE_OPEN_SHAREDCACHE`を開き（`MADDatabaseSqlite3.m:220`）、列挙子はすでにファイル全体で1つのページキャッシュと1つのロック集合を共有します。各列挙が実際にコストするのは`sqlite3*`とファイル記述子で、現実ですが、ステップが示唆する重複キャッシュコストではありません。

それに対して、読み取り接続を共有すると何かを*失います*。列挙子はレポートレンダリングの長さだけ保持され（`MADReportFormatter.m:449-502`）、`-removeAllObjects`はそれらの下でテーブルをドロップして再構築します。今日、未処理の列挙子は自身のステートメントとハンドルを所有するため、2つはファイルを通じてのみ干渉します。それらに1つの共有ハンドルを渡すと、その相互作用が単一接続の内側に入り、読み取りが独自のロックを持たないクラス上で起こります。設計すべきシナリオは§2.7がすでにフラグするものです——テーブル再構築をまたぐ生きた列挙子——そして接続の共有はそれを悪化させ、改善しません。意図的にそのままにされています。

---

## 3. 公開API対漏れのある抽象

### 3.1 宣言された表面対実際の実装

`MADDataTable.h`は30のメソッドを宣言します（加えて`name` / `columnKeys` / `sortDescriptors` / `columns` / `rowCounter` / `tag`プロパティ、そのうち2つは書き込みプロトコルが再宣言——§4.2参照）。基底クラスは18を実装し12をスタブします。

| `MADDataTable.h`で宣言 | 基底実装（`MADDataTable.m`） | Virtual | Fast |
|---|---|---|---|
| `-addColumn:` | **アサート** `:365` | 上書き `:112` | 上書き `:431` |
| `-addRow:error:` | **アサート** `:369` | 上書き `:179` | 上書き `:504` |
| `-addRowWithDataForFieldKeys:` | **アサート** `:374` | 上書き `:197` | 上書き `:614` |
| `-sortUsingDescriptors:` | **アサート** `:378` | 上書き `:208` | 上書き `:634` |
| `-removeAllObjects` | **アサート** `:382` | 上書き `:225` | 上書き `:674` |
| `-objectAtRow:column:` | **アサート** `:386` | 上書き `:159` | 上書き `:834` |
| `-objectAtRow:` | **アサート** `:391` | 上書き `:151` | 上書き `:848` |
| `-columnsEnumerator` | **アサート** `:396` | 上書き `:149` | 上書き `:1123` |
| `-objectEnumerator` | **アサート** `:401` | 上書き `:148` | 上書き `:1127` |
| `-beginBulkInsert` / `-endBulkInsert` | ノーオペレーション `:408-409` | ノーオペレーション `:236-238` | 上書き `:1311`/`:1330` |
| `-allObjects` | `return @[]` `:414-417` | 上書き `:118` | 上書き `:1209` |
| `-objectAtRow:limit:` | `return @[]` `:419` | 上書き `:220` | 上書き `:1086` |
| `-count` / `-numberOfColumns` / `-numberOfRows` | `0` `:420-422` | 上書き `:122`、`:214`、`:216` | 上書き `:1216`、`:1220`、`:1222` |
| `-countByEnumeratingWithState:...` | `0` `:423-427` | 上書き `:140` | 継承（0） |
| `-enumeratorForAllObjectsSorted*`、`-objectsForGroupKeys:`、`-dataForRow:error:`、`-enumeratorForKeyObjectsSorted` | `NSAssert(NO, @"Not implemented")` `:327-350` | **同様に** `NSAssert(NO)` `:31-54` | 実装 `:1034`、`:1148`、`:1172`、`:1193`。`-dataForRow:error:` `:941` |

### 3.2 漏れ1 — 基底クラスは「抽象」を表現できない

Objective-Cに`abstract`はありません。そのため基底はかつて**`-addRow:error:`から`YES`を返し**、**すべてのリーダーから`nil`を返して**いました。部分的に実装されたサブクラスや直接の`MADDataTable`インスタンスは、静かに書き込みを受け入れて成功を報告し、その後何も読み戻しません。

**修正（Phase 0）。** ストレージサブクラスが上書きしなければならない9つの書き込み／読み取りオペレーションは今、`NSAssert(NO, @"%s must be overridden", __PRETTY_FUNCTION__)`で始まります（`MADDataTable.m:365`、`:369`、`:374`、`:378`、`:382`、`:386`、`:391`、`:396`、`:401`）。`:327-350`グループに一致します。`-addRow:error:`はReleaseで`true`ではなく`false`を返すため、アサーションがコンパイルアウトされても行が保存されたと主張しません。

2つのグループは静かなデフォルトとして意図的に**残され**ました。それらについては沈黙が正しいからです。

* `-beginBulkInsert` / `-endBulkInsert`（`:408-409`）——任意のフック。バルクモードを必要としないサブクラスはノーオペレーションを正当に継承できます。
* `-allObjects`（`:414-417`）、`-objectAtRow:limit:`（`:419`）、`-count` / `-numberOfColumns` / `-numberOfRows`（`:420-422`）、`-countByEnumeratingWithState:...`（`:423-427`）——これらは`@[]` / `0`を返し、行のないテーブルにとって*真実の*答えで、`MADDataTableVirtual`が返すものに一致します。`-count`でアサートすると正しい答えがクラッシュになります。

この漏れの残り半分——型システムでアサーションではなく分割を表現すること——はPhase 1です（§4.2）。

### 3.3 漏れ2 — すでに壊れているnullability契約

`MADDataTable.h:65`は宣言します（`@protocol MADDataTableCursoring`内）。

```objc
- (nonnull NSArray *)allObjects;
```


`MADDataTableFast.m`はかつてこう答えていました（このリビジョン前の`:1093-1096`）。

```objc
- (NSArray *)allObjects {
	// FIXME: Implement this.
	return nil;
}
```


宣言された`nonnull`メソッドが1つのサブクラスで`nil`を、他で`@[]` / `[self.sortIndex copy]`を返す。アノテーションを信頼した呼び出し元はクラッシュします——それはヘッダー契約に矛盾するファミリで唯一の`FIXME`でした。

**Corrected:** 本番呼び出し元はありません。データテーブルの`-allObjects`への送信はこの回帰スイートにのみあり、`MADDataTableRegressionTests.m`は`testFastTableBulkInsertAllObjectsIsUnimplemented`で`nil`を意図的に固定していました。したがってアノテーションは将来の呼び出し元のために仕掛けられた罠で、生きたクラッシュではありませんでした。

**Fixed:** `MADDataTableFast -allObjects`（`:1209-1214`）は今、`-objectAtRow:0 limit:numberOfRows`で毎行を返し、列のないテーブルには`@[]`を返し、`nonnull`宣言と`MADDataTableVirtual`の既存振る舞い（`:118-120`）に一致します。`nil`を固定したテストは本当の契約をアサートする2つに置き換えられました。

### 3.4 漏れ3 — `-objectAtRow:column:`がサブクラスごとに異なる意味

2つの実装は`row`の意味と参照するストレージの両方で不一致です。

```objc
// MADDataTableVirtual.m:159-163 — reads the per-column store, applies the sort index
- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column {
	NSString *fieldKey = self.columnKeys[column];
	MADDataColumn *dataInColumn = self.columns[fieldKey];
	return [dataInColumn objectAtIndex:[self sortedIndexForIndex:row]];   // LOGICAL row
}
```


```objc
// MADDataTableFast.m:834-846 — reads the row dictionary, physical order
- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column {
	NSDictionary *objForRow = [self objectAtRow:row];
	if (objForRow == nil || column >= self.columnKeys.count) return nil;
	NSString *key = self.columnKeys[column];
	MADDataColumn *columnMetaData = self.columns[key];
	if (columnMetaData == nil) return nil;
	return objForRow[columnMetaData.identifier];      // PHYSICAL (sqlite) order
}
```


境界の規律も異なることに注意: Virtualは`column`に境界チェックを**せず**（`self.columnKeys[column]`は範囲外で`NSRangeException`を投げ、`-objectAtRow:`の`@try`だけが捕捉し、ここでは捕捉しない）、`dataInColumn`のnilチェックもしません。Fastは両方を行います。

同じセレクタ、2つの意味論の集合。`MADMySQL`はこれをタイトループで呼ぶため（`MADDatabaseMySQL.m:88-92`ともう3サイト）、意味論を統一するリファクタは最初にMySQLで感じられます。

### 3.5 漏れ4 — `-dataForRow:error:`が一方のサブクラスに実装され、他方で欠けている

**このセクションはこのレポートの最初のリビジョンで間違っていました。** `MADDataTableFast`が`-dataForRow:error:`を実装しておらず、バーコード／印刷パスが基底クラスの`NSAssert(NO)`に当たると主張していました。それは偽で、読者を偽の道に送りました。修正された分析は次のとおりです。

`MADDataTable.h:67`は`- (nullable NSDictionary<NSString *, id> *)dataForRow:(NSUInteger)rowID error:(NSError **)error;`を宣言し、基底は`NSAssert(NO, @"Not implemented: %s")` + `return nil`で実装します（`MADDataTable.m:342-345`）。

* **`MADDataTableFast`は実装しています**、`MADDataTableFast.m:941-1015`:

  ```objc
  - (NSDictionary <NSString *, MADResult *> *)dataForRow:(NSUInteger)cacheId
                                                   error:(NSError * __autoreleasing *)outError {
  ```


  それは2行のシグネチャで、以前のリビジョンが誤読したものです。セレクタが2行目に折り返し、2行目が別の`-dataForRow:column:`オーバーロードと取られました。（本当の`-dataForRow:column:error:`は`:866-932`の別メソッドです。）実装は本物で、回帰スイートはすでにそれをカバーしています——`MADDataTableRegressionTests.m`の`testFastTableDataForRowReturnsValues`と`testFastTableDataForRowCachesLastRow`はどちらも2引数セレクタを生きた`MADDataTableFast`に送り、通ります。

* **`MADDataTableVirtual`はどちらの形も実装していません。** `:41-44`に`-dataForRow:`スタブがありますが、そのスタブは`NSAssert(NO, @"Not implemented: %s")` + `return nil`で、機能するオーバーロードではなく、`MADDataTableVirtual.h`で宣言されていません。2引数形はアサートする基底に落ちます。したがってメモリ内サブクラスには行IDアクセスがまったくありません。

呼び出しサイトはしたがって危険ではありません。`MADocument.m:875/880/919`は`MADocument.dataTable`にディスパッチし、それは静的にも実際にも`MADDataTableFast`です（`MADocument.m:159`、`:230`と`:288`で割り当て）。`MADPrintPageElement.m:80`と`MADPrintPageElementBarcode.m:30`のパスは同じオブジェクトに到達します。生きたパスでアサートするものはありません。

本当の不具合はより狭く、今修正されています。`MADDataTableVirtual`がセレクタを実装しなかったため、`MADDataTable *`を保持する将来の呼び出し元がたまたまVirtualテーブルだと、Debugではアサートし、Releaseでは静かに`nil`を受け取っていました。`MADDataTableVirtual`は今`-dataForRow:error:`を`-objectAtRow:`に委譲して実装し、範囲外ケースをエラーポインタで報告します。

`MADDataTableFast`実装にも本物の不具合があり、今修正されています。その`if (sqlite3_prepare == SQLITE_OK)`には**`else`がなく**、prepare失敗が`*outError`を設定せずに`nil`を返し、`-getSql:`エラーが破棄されていました。兄弟の`-dataForRow:column:error:`（`:905-932`）は両方を正しく扱います。SQLはまた`sqlite3_mprintf`に*フォーマット*文字列として渡され（`sqlite3_mprintf((char *) sql.UTF8String)`）、`%`を含むSQLを壊すかクラッシュさせました。今は`sqlite3_mprintf("%s", ...)`で、`:901`の兄弟に一致します。`MADSqlite3`のさらに8サイトが同じ不具合を持ち、すべて今修正されています——§4.5参照。

### 3.6 漏れ5 — `MADDataTableFast`が別クラスのプライベートivarに手を伸ばす

`MADDataTableFast.m`は`MADDatabaseSqlite3`のプライベートivar `_database`に15サイトで直接アクセスします——`:488`、`:538`、`:784`、`:793`、`:810`、`:829`（`_databaseForInserts`経由）と`:905`、`:976`、`:1065`、`:1078`、`:1106`、`:1108`、`:1248`、`:1251`、`:1261`（`databaseForSelects`経由）:

```objc
sqlite3 *sqlite_database = _databaseForInserts->_database;                       // :451
NSAssert(prepareResult == SQLITE_OK, @"%s", sqlite3_errmsg(databaseForSelects->_database)); // :1008
```


これは`MADDatabaseSqlite3`のAPIを完全に迂回し、`MADDataTableFast`が何かをするために本物のsqliteファイルを必要とする理由です。また、テストターゲットが`MADDataTable+Constructor`モジュールインポート作業を必要とした理由でもあります。クラスファミリは両方のフレームワークを一緒にリンクするコードからのみ使えます。

### 3.7 漏れ6 — 死んだ公開API — **削除（Revision 5）**

`MADDataTableLocation`（`MAD/Source/MADDataTableLocation.{h,m}`、67行）は`NSCoding`と`+newDataTableLocationForRow:inColumn:`ファクトリを持つ`(row, column)`値オブジェクトでした。独自の実装を除いてコードベース全体をgrepしました。**その唯一の参照は回帰テストファイルにありました。** 本番では死んでいました。また`NSCoding`を採用しましたが`NSSecureCoding`は採用せず、回帰スイートがそれを契約として記録していました。

Phase 5ステップ14は選択を提供しました——機能に配線するか削除するか。削除されました。待っていた機能がなかったからです。その全歴史で1コミット（`e702bb062`、`MAD`フレームワーク再編成）、呼び出し元なし、それが何のためかを記述するのは自身の3つのテストだけ。テストだけで生かされるクラスは、テストが二重に支払っているクラスです。ファイル、2つの`.pbxproj`ビルドエントリ、3つのテストはそれとともに消えました。§3.7は再番号付けされず漏れ6として残り、レポートの残りが引用する番号付けが保たれます。

### 3.8 漏れ7 — テーブルが書き込みクエリに*逆*に手を伸ばす

`MADDataTableFast`は4つのプロトコルにプライベートに準拠します（`:71`）。

```objc
@interface MADDataTableFast () <MADQueryParametersStandardProtocol,
                                MADQueryParametersColumnKeysProtocol,
                                MADQueryParametersColumnMetaProtocol,
                                MADQueryParametersColumnDataProtocol>
```


そして`-queryTableName` / `-queryColumnKeys` / `-queryColumns` / `-queryRowData`（`:419-430`）を、`MADQueryCacheAddRow`が書き込み先のテーブルから状態を引き出せるようにするためだけに実装します。したがって挿入パスは循環です。テーブル → クエリオブジェクト → テーブルへ戻る。名前衝突リスクに注意——`-queryRowData`（`:428`）とプライベート`_rowDataLastInserted`プロパティは公開の`-dataForRow:`ファミリとは無関係です。

### 3.9 漏れの*ない*もの（これらを保存する）

* すべてのサブクラス選択は`MADDataTable+Constructor.m:51-69`にある。
* 書き込みポートは5つの基底クラスメソッド（§1.4）。
* 列挙子クラスは`MADSqlite3`にプライベートで、`NSEnumerator *`としてのみ表面化する。
* `MADReportFormatter.m:463-472`はすでに行IDのみの列挙を許容する。
* `MADArrayCaching`（`MADSqlite3`）は、より狭いプロトコル形状の表面を持つキャッシュ抽象の、このコードベースの先行事例です。
* どこにもテーブルに対する実行時クラススニッフィングはない。

---

## 4. 分離とリファクタリング戦略

目標は、5つのドライバと4つの消費者がすでに依存する振る舞いを変えずに、`MADDataTable`を交換可能なストレージとアクセス戦略の上の*安定したインターフェース*にすることです。

### 4.1 目標形状

クラス名を保ち（`NSCoding`アーカイブとCore Dataに焼き込まれている）、変動をコンストラクタが返す2つのプロトコルの背後に移します。

```
                    ┌─────────────────────────────────────┐
                    │  MADDataTable        (concrete base) │
                    │  metadata, plist persistence,        │
                    │  NSCoding, — no-op defaults removed   │
                    └──────────────┬──────────────────────┘
                                   │
        ┌──────────────────────────┴───────────────────────────┐
        │                                                       │
  MADDataTableVirtual                                   MADDataTableFast
  (unchanged semantics)                          (sqlite; owns a connection pair)

  Both conform to:
     <MADDataTableWriting>   removeAllObjects / addColumn: /
                             begin|endBulkInsert /
                             addRowWithDataForFieldKeys:
     <MADDataTableReading>   objectAtRow: / objectAtRow:column: /
                             count / numberOfRows
     <MADDataTableCursoring> enumeratorForKeyObjectsSorted /
                             enumeratorForAllObjectsSorted /
                             enumeratorForAllObjectsSortedRowIdOnly
```


`MADDatabaseSqlite3.m:474-540`と`MADDatabaseSQLServer.m:500-1472`は`MADDataTable *`ではなく`id <MADDataTableWriting>`を取るべきです。それだけで「基底クラスが破棄した書き込みからYESを返す」危険がすべてのドライバから消えます。

### 4.2 順序付けられた計画

**Phase 0 — 失敗モードを大声にする（振る舞い変更なし）。**
1. **完了**、最初の提案より狭いスコープ。ストレージサブクラスが上書きしなければならない9つのオペレーションは今アサートします（`MADDataTable.m:365-403`）。正直な空テーブルの答えと任意のバルクフックはデフォルトとして残されました。それらについては沈黙の値が*正しい*からです。分割と理由は§3.2、契約は`MADDataTableRegressionTests.m`の`testBaseTableAbstractOperationsAssert`参照。
2. **不要——§3.5参照。** ここの元のテキストは`MADDataTableFast -dataForRow:error:`を「現在アサートする」ため実装するよう述べていました。そうではありません。メソッドは`:941-1015`に実装され、以前の読みは2行のシグネチャを`column:`オーバーロードと誤解しました。セレクタが本当に欠けていたサブクラスは`MADDataTableVirtual`で、今は`-objectAtRow:`に委譲して実装します。
3. **完了。** `-allObjects`（§3.3）は`MADDataTableFast`で`nil`を返す`nonnull`メソッドでしたが、今は行を返します。同じパスで`MADDataTableFast -dataForRow:error:`はprepareチェックに欠けていた`else`を得て、`-getSql:`エラーを破棄せず、SQLをフォーマット文字列として`sqlite3_mprintf`に渡さなくなりました。
4. 既存の回帰スイート（`MADDataTableRegressionTests.m`）に対して再検証します——インスタンス化、列挙、並行性をすでに固定しているため、ここの誤りを検出します。（Revision 5がクラスを削除するまで`MADDataTableLocation`契約も固定していました。）

**Phase 1 — プロトコルを宣言する。**

5. **完了——スタブブロックは意図的に保たれた。** 3つのプロトコルは`MADFoundation/Source/MADDataTable.h`の`@interface`の上で宣言され、それは今`MADDataTable : NSObject <NSCoding, NSFastEnumeration, MADDataTableWriting, MADDataTableReading, MADDataTableCursoring>`を読み、`@interface`本体にあった30のフラットなメソッド宣言はそこから消えました。分割は軸ごとです。**Writing**は変更可能な表面（`removeAllObjects`、`addColumn:`、`addRow:error:`、`addRowWithDataForFieldKeys:`、`sortUsingDescriptors:`、加えて`@optional`の`beginBulkInsert`/`endBulkInsert`）、**Reading**はランダムアクセスとカウント、**Cursoring**は列挙で、3つのソート済み列挙子と`objectsForGroupKeys:`は`@optional`です。`MADDataTableVirtual`がそれらを提供できないからです。

   計画の「今や冗長なスタブブロックを削除する」は**実行されませんでした**。両方のスタブブロックは固定された契約で、冗長ではないからです。`testBaseTableAbstractOperationsAssert`は9つの基底クラスアサートスタブが存在して投げることを要求し、`testVirtualTableDoesNotImplementSortedEnumerators`は`MADDataTableVirtual`の4つのsqlite専用セレクタに対して`-respondsToSelector:`が**YES**であることをアサートします。どちらかを削除すると、捕捉された不具合がunrecognized-selectorクラッシュになり、まさにそれを防ぐために存在するテストを壊します。`MADDataTable`はアサートすることでプロトコルの`@required`メンバーを満たし、それがPhase 0がそこに置いたものです。

6. **完了（Revision 4）——3つのドライバすべてとプロトコル。** 下のブロックはこれがなぜブロックされたかについてのRevision 3の説明で、記録のために保たれています。それが特定したアンブロックは取られました。`MADMySQLFetch+DataTable.m`が必要とする列メタデータ（`columns`、`columnKeys`）は今`<MADDataTableWriting>`自身が宣言するため、書き込みポートはMySQLにも十分です。`MADMySQLFetch`の2つの`fetchWithCommand:dataTable:...`メソッドとプライベート`-fetchResultsFromConnection:intoDataTable:...`は`id <MADDataTableWriting>`を値で取り、同じテーブルを返します（`(MADDataTable *)dataTable`）。`MADDatabaseMySQL.m`の11呼び出しサイトと`MADMySQLLiveTests.m`の7つすべてが`&`を落としました。メタデータは4つ目のプロトコルではなく書き込みプロトコルに置かれました。MySQLが*書き込みながら*それを読み（最初の行で列の型を修正する）、すべての準拠者が基底クラスから無料で得るからです。§2.5の`// FIXME: This is a hack.`は未変更です。

   *記録のためのRevision 3テキスト:* **部分的に完了——3つのドライバのうち2つ、プロトコル宣言は意図的に狭められていない。** `MADDatabaseSqlite3`（`executeSQL:...intoResultTable:`、`executeQuery:withDataTable:andError:`、`executeQuery:withError:`）と`MADDatabaseSQLServer`（同じ2つ、加えてプライベート`-runQuery:onProcess:withDataTable:`と`-runSQL:onDataTable:fieldKeys:process:`）は今`id <MADDataTableWriting>`を取ります。どちらも真に書き込み専用です。テーブルに送るものを`grep`すると、正確に5呼び出しポート以外何も返りません。

   **`MADDatabaseMySQL`はまだ狭められず**、`MADAPI/Source/MADDatabaseProtocol.h:28-31`も同様です。障害はドライバにありません——`MADMySQLFetch+DataTable.m`にあり、テーブルを*充填しながら*`(*dataTable).columns`と`.columnKeys`を読み、最初の行を見たときに列の型を修正します（`:301`と`:321`、`:297`の既存`// FIXME: This is a hack.`の下）。したがって列メタデータを公開しない書き込みポートはそのパスに不十分です。`MADDatabaseMySQL`は`MADDatabaseDataSource`に準拠し続けなければならないため、プロトコルを狭めると自身の実装が果たせないものを約束することになります——コンパイルエラーではなく、次の呼び出し元へのリモートクラッシュ。両方の宣言がここを指すコメントを運びます。

   **これを確認中に見つかった具体的なアンブロック:** `MADMySQLFetch+DataTable.m`はその`MADDataTable * __autoreleasing *`出力パラメータを通じて決して代入しません——`grep -n '\*dataTable *=' MADMySQL/Source/MADMySQLFetch+DataTable.m`は何も返しません。ポインタは呼び出し元が決して知らされなかった入力パラメータです。値を渡す形（`dataTable:(id <MADDataTableWriting>)dataTable`）にするとポインタ型の問題が完全に消え、`MADDatabaseMySQL.m`の11呼び出しサイトが`&`を落とせます。それと、列メタデータアクセサを`<MADDataTableWriting>`か4つ目のプロトコルに追加することが、MySQLに残るすべてです。§4.3がすでにMySQLを最高リスクの消費者とランク付けし、変更は単独でレビューできるほど機械的なため、バンドルではなく延期されます。

7. **sqliteには今可能、MySQLには未証明。** `MADDatabaseSqlite3`の行ループは、`<MADDataTableWriting>`に準拠する任意のオブジェクトで、`.maddb`ファイルもアプリデリゲートもなしで駆動できます。パラメータがもはや`MADDataTable`クラスを意味せず、それを通じた§2.3の`[MADApplication AppDelegate]`への`-urlFastCache`依存も意味しないからです。そのようなモックテストはまだ書かれていません。自然な次のステップで、Phase 2の注入キャッシュディレクトリが安くする最初のものです。
   **Revision 4:** ホストレス半分は証明されました——`testFastTableInitWithCacheDirectoryNeedsNoDelegate`がディレクトリとデリゲートなしで機能する物理テーブルを構築します。
   **Revision 5: 完了、両半分。** `testDriverFillsAWritePortWithNoDataTableBehindIt`（`MADSqlite3Tests/MADDatabaseSqlite3DatabaseTests.m`）が行ループに`MADWritePortRecorder`——`<MADDataTableWriting>`にのみ準拠する`NSObject`——を渡すため、`MADDataTable`も`MADDataTableFast`もキャッシュデリゲートも`.maddb`もなく、5つの呼び出しが約束された順序で両方の行を無傷で到着することをアサートし、`.maddb`ファイルが現れたら失敗します。モックが表現できるのはパラメータがプロトコルだからです。

**Phase 2 — ストレージ位置の曖昧さを取り除く。完了（Revision 4）。**
8. ✅ `urlFastCache`を計算ではなく保存にする（§2.3）。一度`_urlFastCache`に解決され、デリゲート差し替えが再オープン前に`-setCacheDelegate:`でそれを落とすため、解決は常に現在のデリゲートに対して行われます。
9. ✅ プロパティ内で`[MADApplication AppDelegate]`に手を伸ばすのではなく、キャッシュディレクトリを注入する。`-initWithId:cacheDirectory:`と`+newDataTableOfType:withObjectID:cacheDirectory:`がそれを運び、`nil`は古いチェーンを保ちます。`testFastTableInitWithCacheDirectoryNeedsNoDelegate`がデリゲートなしで物理テーブルを構築、充填、読み取りします。

**Phase 3 — `rowCounter`を派生にする。**
10. ✅ `SELECT COUNT(*)`に裏付けられたプライベート`-recountRows`を追加し、`MADDataTableFast`で`-numberOfRows`/`-count`がそれを使う（またはそれに対して無効化する）ようにする。アーカイブ互換のために`rowCounter`プロパティを保つが、真実の源として扱うのをやめる（§2.5）。**Revision 4:** `-recountRows`が存在し、`-loadWithPlist:`の最後に実行されるため、リロードされたテーブルはファイルと不一致のカウンタを運べなくなりました。**Revision 5:** メモリ内半分が閉じられました——カウンタに触れなかった4つの変更が今それをファイルを記述する状態で残します（§2.5）。`-numberOfRows`/`-count`は設計上ivarを返し続けます。それが今唯一の読み手で、`-recountRows`がリロードをガードします。4つのテストが4つのメソッドをカバーします。
11. ✅ `MTTableController.m`（以前は`:375/395/440/445`）を監査する——ページングはファイルからドリフトし得るカウンタを読んではなりません。**完了（Revision 5）**、カウンタが正直になればできません。すべてのフェッチは`-removeAllObjects`で始まり、それはテーブルをクリアしてカウンタをゼロにするため、完了時のカウントは今書かれたページだけを測ります。それでもまさにそれらの行で2つの不具合が見つかり修正されました。`:380`/`:402`で空ページの`offset + count - 1`が`NSUIntegerMax`にラップし、`:449`の失敗パスがドライバが*クリアしていない*テーブル（成功時のみクリアする）からカウントを読み、前のページを測り、失敗したフェッチが`hasMore = YES`を報告して自身を再発行しました。失敗したページは今、これ以上なしを報告します。

**Phase 4 — 並行性を修正する。**
12. ✅ `-addRow:error:`を`queueBulkAdd`で直列化する（§2.4）。キューはすでに存在し、`-endBulkInsert`にすでに使われており、変更パスへ拡張するのは小さく閉じた変更です。`-endBulkInsert`の`sqlite3_finalize(_statementInsert)`をバリアの*内側*に移し、キャッシュされたステートメントが`-addRow:`の実行中でないときだけティアダウンされるようにする。**完了（Revision 4）**——ティアダウンは今`:1334`の`dispatch_barrier_sync`の内側の最初のものです。
13. **評価して却下（Revision 5）**——テーブルインスタンスごとではなくファイルごとに1つの共有接続対。`-objectEnumerator`が現在呼び出しごとに新しい接続を開くからです（§2.7）。書き込み半分には共有が使えず（`-endBulkInsert`がそのハンドルを閉じる）、読み取り半分にはほとんど何も買わず（`SQLITE_OPEN_SHAREDCACHE`がすでにキャッシュを共有する）、テーブル再構築をまたぐ生きた列挙子ケースを改善ではなく悪化させます。§2.7に完全な議論があります。

**Phase 5 — 死んだ表面を退役させる。**
14. ✅ `MADDataTableLocation`（§3.7）とその3つのテストを削除するか、実際の機能に配線する。現在、本番呼び出し元のない公開APIです。**Revision 5で削除**——配線ではなく削除されました。歴史に1コミットしかなく、それを記述する自身のテスト以外何もないからです。MADターゲットのHeadersとSourcesフェーズが2つのファイルをそれとともに落とします。
15. **評価（Revision 5）**——2つの永続化機構を調整する（§2.6）。前提はファミリに成り立ちません。行はplistがストレージである場所ではplistを通じて*ラウンドトリップし*（`MADDataTableVirtual`の`keySortIndex`）、sqliteファイルである場所ではできません（`MADDataTableFast`の`keyUrlFastCache`）。したがって名前変更も代替も正しくありません。§2.6がサブクラスごとの表と残された文書変更を記録します。

### 4.3 現在の消費者の破損ランキング

| 消費者 | サイト | リファクタ下のリスク |
|---|---|---|
| `MTTableController` | `:249, :281, :284, :377, :393, :399, :449, :455` | **高**——`count`をページカーソルとして扱う。`rowCounter`意味論の変更はページングを壊す。Revision 5は導出を完全にした——空ページはもはやアンダーフローせず、失敗したフェッチはもはや前のページのカウントを読まない（§2.5）——が、結合は変わらない |
| `MADDatabaseMySQL` | `:88-92, :118-122, :150-154, :187-189` | **高**——O(n)の`objectAtRow:i column:0`。サブクラスごとの`row`意味論を先に統一しなければならない |
| `MADocument` | `:197`（`rowCounter`）、`:865-867`（列挙子）、`:874-919`（`dataForRow:error:`）、`:1053-1072` | **高**——ただし列挙子と`rowCounter`のみ。その`-dataForRow:error:`送信はセレクタを実装する`MADDataTableFast`に解決されるため、印刷／バーコードパスは健全（§3.5参照） |
| `MADMySQLFetch+DataTable` | `:301, :321` | **中**——`// FIXME: This is a hack.`（`:297`）の背後でフェッチ中に`column.type`を変更する。列辞書は公開で変更可能なままでなければならない |
| `MADQuerySampleDataTable(Range)` | `:118, :126` / `:123, :131` | **低**——単一の`objectAtRow:0`幅プローブ |
| `MADReportFormatter` | `:449-502` | **低**——行IDと辞書列挙の両方を許容 |
| `MADDatabaseSQLServer` | `:500, :1367, :1472` | **低**——5メソッドポートを通じた書き込み専用 |

### 4.4 尊重すべき制約

* **`MADDataTableType`の生値を変えない。** `MADDataTableParametersType`は定義辞書にエンコードされ（`MTTableController.m:91`、`MTTableViewControllerBarcodeExtraMaxicode.m:104`）、enumは`initWithShort:`でシリアライズされます。
* **クラス名を変えない。** `MADDataTableFast`アーカイブは`[MADDataTableFast keyTag]`形式のキーを運び（`:114-119`）、`MADDataTableVirtual`は`keySortIndex`（`:202`）を既存の`.mdcache`/`.maddb`ファイルに運びます。
* **5メソッド書き込みポートを保つ。** 3つのドライバすべてが正確なシーケンス`removeAllObjects → addColumn: → beginBulkInsert → addRowWithDataForFieldKeys: → endBulkInsert`に依存します。
* **クラス名スニッフィングは導入されていない。** それを保ってください。新しい分岐はプロトコルかenumに対して行い、クラスに対しては決して行わない。

### 4.5 SQLをフォーマット文字列として`sqlite3_mprintf`に渡す

§3.5の修正中に見つかりました。他の8つの呼び出しサイトが変数を*引数*ではなく*フォーマット*文字列として`sqlite3_mprintf`に渡していました。SQL内の任意の`%`が変換として読まれ、それを含むクエリが壊れるか、引数リストを読み越えてクラッシュします。

**修正済み。** 8つすべてが今、リテラル`"%s"`とSQLを引数として渡し、すでに正しかったサイトに一致します。

| ファイル | サイト |
|---|---|
| `MADSqlite3/Source/MADDataTableFast.m` | `:1062`、`:1102`、`:1245` |
| `MADSqlite3/Source/MADDatabaseSqlite3.m` | `:301`、`:397`、`:875` |
| `MADSqlite3/Source/MADDataTableObjectEnumerator.m` | `:69` |
| `MADSqlite3/Source/MADDataTableSingleColumnEnumerator.m` | `:64` |

すでに正しかった参照サイトは`MADDataTableFast.m:548`、`:901`、`:973`と`MADDatabaseSqlite3.m:459`でした。`MADSqlite3`のすべての`sqlite3_mprintf`呼び出しは今、リテラル`"%s"`か変換を含まないリテラルフォーマット文字列を使います——`grep -n sqlite3_mprintf MADSqlite3/Source/*.m`は14の呼び出しを返し、変数フォーマット文字列はありません。

到達可能性は低かったです。SQLは生成されたクエリビルダーから来て、リポジトリ全体の検索で`%`を導入する`LIKE`パターンは見つかりませんでした。しかし識別子は接続されたデータベースのスキーマから来るため、列名やテーブル名の`%`はこれに当たっていたでしょう。生きた不具合ではなく潜在的な正確性の不具合でした——変更が機械的で、間違えた結果が静かな破損だから修正されました。

---

## 付録 — 調査したファイル

| ファイル | 行数 |
|---|---|
| `MADFoundation/Source/MADDataTable.h` / `.m` | 123 / 435 |
| `MADFoundation/Source/MADDataTableVirtual.h` / `.m` | 21 / 240 |
| `MADFoundation/Source/MADDataTableType.h` | 17 |
| `MADFoundation/Source/MADDataColumn.h`、`MADDataProtocol.h`、`MADCacheProtocol.h` | — |
| `MADSqlite3/Source/MADDataTableFast.h` / `.m` | 47 / 1355 |
| `MADSqlite3/Source/MADDataTableObjectEnumerator.m` | 173 |
| `MADSqlite3/Source/MADDataTableSingleColumnEnumerator.m` | 149 |
| `MADSqlite3/Source/MADQueryCacheAddRow.m` | 152 |
| `MADSqlite3/Source/MADDatabaseSqlite3.m` | 1346 |
| `MAD/Source/MADDataTable+Constructor.h` / `.m` | 30 / 94 |
| `MAD/Source/MADocument.m`、`MADReportFormatter.m` | — |
| `MADMySQL/Source/MADDatabaseMySQL.m`、`MADMySQLFetch+DataTable.{h,m}` | — |
| `MADTdsClient/Source/MADDatabaseSQLServer.m` | — |
| `MADAPI/Source/MADDatabaseProtocol.h`、`MADQuery.h`、`MADDatabaseResultsProtocol.h` | — |
| `MADDesigner/Source/MTTableController.m` | — |
| `MAD/MADTests/MADDataTableRegressionTests.m` | 69テスト |
