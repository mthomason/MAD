---
layout: default
title: "MADModelレイヤー"
description: "Rptqエンティティ上のドキュメント読み取りモデル、およびそれが最新に保たれる方法。"
lang: ja-JP
---

# MADModel — ドキュメント読み取りモデルレイヤー

このページでは`MADModel`について説明します。`Rptq`エンティティ上の読み取りモデルで、各クラスが何であり、どのように設定され最新に保たれ、誰が読むのかを扱います。

*元の日付に書かれ、現状の事実は2026-11-22に整合。*

**スコープ:** `MAD/Source/model/MADModel*.{h,m}`、`MAD/Source/model/MADTableFieldIdentifier.{h,m}`、および`MAD`と`MAD Designer`のレイヤーのすべての消費者。
**日付:** 2026-10-16、`d7faff320`で読了。
**ステータス:** リファレンス。ここにあるものはすべてそのコミットで直接読まれました。§7のリファクタリング候補は提案であり、適用されていません。

---

## 1. レイヤーとは何か

`MADModel*`は**ドキュメントスコープの読み取り専用ビュー**で、ドキュメントの定義——接続、スキーマ（テーブルとフィールド）、クエリグラフ（クエリが使うテーブル、フィールド、それらの間の結合）——を表します。デザイナのクエリUIがバインドするものです。

それは正規モデルでは*ありません*。正規モデルはポータブルストアの`Rptq*`オブジェクトグラフです。アプリが編集し、保存し、変換し、レンダリングするものです。`MADModel*`オブジェクトは**ストア行識別子（`int64_t`）+ `RptqStoreContext`への弱ポインタ + いくつかのコピーされた表示値**にすぎず、`objectsForEntity:identifier:`で行をフェッチして遅延解決されます。

コードが従う経験則:

> **`Rptq`を通じて書き、`MADModel`を通じて読み観察する。**

2つのレイヤーは1つの識別子空間を共有します。モデルオブジェクトの`identifier`は*まさに*ストア行の`identifier`です。それが接着剤のすべてです——§3参照。

```
MADModelDocument                       one per open .mad — MADocument.documentModel
 └ databases: [MADModelDatabase]       (today: exactly one)
    ├ driverID / driverType / schemaName   ← RptqDatabase + RptqDatabaseCredentals
    ├ tables / tableDictionary : {id → MADModelTable}      ← RptqDatabaseSchemaTable
    │   └ MADModelTable  (name, queryable)
    │      └ fields / fieldIDs : {id → MADModelField}      ← RptqDatabaseSchemaField
    │         └ MADModelField (name, dataType, decimals, width, primaryKey)
    └ queries: [MADModelQuery]         (today: exactly one; `firstQuery` everywhere)
       └ MADModelQuery
          ├ queryTableIDs / tables : {id → MADModelQueryTable}   ← RptqQueryTable
          │   └ MADModelQueryTable  (schemaTable id, dropIndex, alias)
          │      └ queryFields : {id → MADModelQueryField}       ← RptqQueryField
          │         └ MADModelQueryField (schemaTable + schemaField ids)
          └ queryLinkIDs / links : {id → MADModelQueryLink}      ← RptqQueryLinks
              └ MADModelQueryLink   (left/right table+field ids — one join)
```


## 2. クラス

### 2.1 `MADModel` — アイデンティティ（`MADModel.h`、`MADModel.m`）

基底クラスはアイデンティティのみです。`_uid`（`MADModel.m:32-64`）と、`hash`、`isEqual:`（同じクラスと同じ`_uid`）、`NSNumber`にボックス化されたIDを返す`-objectID`を持ちます。`+[MADModel newModelDocument:]`（`MADModel.m:35`）は名目上のファクトリですが、誰も呼びません。`MADocument`は`MADModelDocument`を直接割り当てます。`MADModelType.h`は`MADModelTypeUnknown/Document/Database/Queries`を定義しますが、ツリー内でこのenumを使うものはありません。

`objectID`という名前と、`_objectID.URIRepresentation`をフォーマットするコメントアウトされた`debugDescription`が、レイヤーの年齢を示す手がかりです。オブジェクトはかつて`NSManagedObjectID`をラップしていました（§5参照）。

### 2.2 `MADModelDocument` — ルート（`MADModelDocument.h`、`.m`）

- `-MADocument.documentModel`（`MADocument.m:389-395`）が開いているドキュメントごとに一度、`self.storeContext`上で遅延作成します。本番でそれを構築するものは他になく、アプリデリゲートは関与しません。
- `databases`を保持し（`-updateDocumentDatabaseQuery`、`MADModelDocument.m:210-240`が構築: *`RptqQuery`行ごとに1つの*`MADModelDatabase`——ここでの「データベース」は接続+そのスキーマ+クエリ）、`firstDatabase` / `firstQuery`便利アクセサを持ちます。コードは複数形が芝居である理由を述べています。*「現在のバージョンのソフトウェアは1つのデータベースとクエリだけを使う」*（`MADModelDocument.m:207-208`）。
- **ストアの変更通知に登録します**（`RptqStoreContextObjectsDidChange`、`WillSave`、`DidSave`、`MADModelDocument.m:160-176`）。プライベートな`NSOperationQueue`（`MADModelDocument.m:83-87`、`_objectContextQueue`）上です。`RptqQueryTable`または`RptqQueryLinks`行の挿入／削除で変更を`firstQuery`にミラーします——§3.3参照。
- `-update`（`MADModelDocument.m:201-205`）はdocument→database→queryスキャンを再実行し、`_databases`を新しいオブジェクトで*置き換え*ます。

### 2.3 `MADModelDatabase` — 接続、スキーマ、クエリ（`MADModelDatabase.h`、`.m`）

- `RptqDatabase`行の識別子をキーにします。
- メタデータは*ストアを通じて、プロパティごとに*解決されます。`driverType`（`MADModelDatabase.m:157-164`）、`schemaName`（`:166-173`）、`driverID`（`:175-182`）はそれぞれ遅延して`RptqDatabase`をフェッチし、`RptqDatabaseCredentals`へ読み通します。`schemaName`と壊れた`driverName`（§6）はどちらも認証情報の`dbname`と答えます。
- `tables` / `tableDictionary`（`-updateTables`、`MADModelDatabase.m:221-247`）は`inDatabase`が一致するすべての`RptqDatabaseSchemaTable`を**名前順にソートして**一覧します——移行前のフェッチが適用したソートを復元し、BUGS.mdを指すコメント付きです。
- `queries`（`-updateQueries`、`:249-261`）は`RptqQuery`行に対して同じことをします。

### 2.4 `MADModelTable` / `MADModelField` — スキーマ（`MADModelTable.{h,m}`、`MADModelField.h`）

- `MADModelTable`は`name`をキャッシュし、`inTable`が一致する`RptqDatabaseSchemaField`行から`fields` / `fieldIDs`（`MADModelTable.m:120-146`）を名前順に遅延構築します。`MADModelField`はプレーンな値です。名前、主キーフラグ、データ型、ネイティブ型、小数桁、幅——ストアアクセスなし。

### 2.5 `MADModelQuery` — 1つのクエリ（`MADModelQuery.h`、`.m`）

最大のクラスで、実際にその価値を発揮するものです。所有するもの:

- `queryTableIDs` + `tables`（`MADModelQuery.m:213-283`）: `inQueryTable.inQuery`がこのクエリであるすべての`RptqQueryField`が辞書に射影され（`MADStoreProjectionForQueryField`、`:59-68`——古いCore Dataフェッチ射影が生成したのと正確な形）、`-insertTablesFromFetchRequestResults:`に供給されます。
- `queryLinkIDs` + `links`（`:302-344`）: `RptqQueryLinks`について同じ（`MADStoreProjectionForQueryLink`、`:70-78`）。
- トポロジヘルパー: `-tablesInLinks`（`:183`）と`-orphanedQueryTables`（`:196`、どのリンクも触れないテーブル、`NSExpression`の集合差）。
- **変更表面**: `-insertQueryTable:` / `-insertQueryLink:` / `-deleteQueryTableID:` / `-deleteQueryLinkID:`とIDベースの変種。それぞれがコレクションに変更を適用し、次に`MADNotificationQueryTableInsert/Delete`または`MADNotificationQueryLinkInsert/Delete`（名前は`MADModel.h:22-26`）を`[NSOperationQueue mainQueue] addOperationWithBlock:`経由で**メインキュー上で**再ポストし、影響を受けたモデルオブジェクトを`userInfo`に入れます。これらの通知がレイヤーの公開イベントストリームで、デザイナが購読します（§4）。

### 2.6 `MADModelQueryTable` / `MADModelQueryField` — クエリのテーブルとフィールド

- `MADModelQueryTable`（`MADModelQueryTable.m`）は`dropIndex`と**スキーマ**テーブルIDをキャッシュし、`queryFields` / `queryFieldIDs`（`-addField:schemaField:`、`:92`が構築）を遅延保持します。`-alias`（`:119-129`）はSQL向けの名前です。最初のコピーはスキーマテーブルの名前、以降は名前+ドロップインデックス（`Customer`、`Customer0`、……）。
- `MADModelQueryField`（`MADModelQueryField.m`）は2つのIDです。スキーマテーブルとスキーマフィールド。`-schemaField`（`:52-57`）はdatabase → `tableDictionary[schemaTable]` → `fields[schemaField]`と歩いて実際のメタデータを解決します。このチェーン——リンク → クエリテーブル → スキーマテーブル → クエリフィールド → スキーマフィールド——がレイヤーの決定的パターンです。`MADQueryVisualizationViewController.m:1024-1048`がコネクタを配置するために手でそれを行います。

### 2.7 `MADModelQueryLink` / `MADTableFieldIdentifier`

- `MADTableFieldIdentifier`（`MADTableFieldIdentifier.{h,m}`）は小さな値の対（テーブルID + フィールドID）で、`NSNumber`アクセサを持ちます。
- `MADModelQueryLink`（`MADModelQueryLink.m`）は両端の`MADTableFieldIdentifier`を保持し、生IDか`RptqQueryLinks`行から構築されます（`-initWithRptqQueryLink:`、`:60-76`、`hasLeftField.inQueryTable.identifier` / `hasLeftField.identifier`を読む）。`-isAdjacentToQueryTable:`（`:78`）と`-tables`（`:82`）はビジュアライゼーションが尋ねるグラフの問いに答えます。

### 2.8 プロトコルと痕跡的な部分

- `MADModelIDProtocol` — 4行: `identifier`（`MADModelIDProtocol.h`）。
- `MADModelDataProtocol`（`MADModelDataProtocol.h`）— `managedObjectContext`、`-initWithIdentifier:managedObjectContext:`、`-update`。実際には`-update`は内部リフレッシュフックで、レイヤー自身の遅延ゲッターからのみ呼ばれます（`MADModelDocument.m:188`、`MADModelTable.m:99`、`:115`）。`MADModelDatabase -update`（`MADModelDatabase.m:148`）と`-MADModelQuery -update`（`MADModelQuery.m:354`、空のメソッド）には呼び出し元がまったくありません。

## 3. ライフサイクル

### 3.1 作成

`MADocument`は`MADModelDocument`を1つ遅延構築し（`MADocument.m:389-395`）、ドキュメントの寿命まで保持します。`RptqStoreContext`を**弱く**保持します（`MADModelDocument.m:42`）。コンテキストを保持するすべてのモデルオブジェクトと同様で、ストアコンテキストはドキュメントが所有します。

### 3.2 人口

ドキュメントより下のすべては**遅延かつキャッシュ**されます。`databases`、`tables`、`fields`、`queryTableIDs`、`queryFields`、`links`の最初の読み取りがフェッチ・アンド・フィルタパスをトリガーします（関連するRptqエンティティに対する`objectsForEntity:`、親の識別子でフィルタし、移行前のフェッチがソートした場所でソート）。キャッシュは`-update`を呼ぶか下の通知パスによってのみ無効化され、何も自然に期限切れになりません。

### 3.3 ライブ変更 — ラウンドトリップ

デザイナでテーブルやリンクを追加すると**Rptq行**が書かれます（例えば`MADQueryViewController.m:745-790`のadd-tableフローが`RptqQueryTable` + `RptqQueryField`行を作成してコンテキストを保存）。モデルはその後自身で追いつきます。

```
user adds a table / link
  → RptqQueryTable / RptqQueryLinks rows written + saved
    → RptqStoreContextObjectsDidChangeNotification
      → MADModelDocument's observer (on its private queue)     MADModelDocument.m:91-158
        → [firstQuery insertQueryTable:/insertQueryLink:]       MADModelQuery.m:361-410
          → MADNotification…Insert/Delete reposted on main      MADModelQuery.m:361-514
            → MADQueryVisualizationViewController, MADQueryBuilderAddTableViewController
```


2つのキューが関与します。モデルは`_objectContextQueue`（プライベート`NSOperationQueue`、`MADModelDocument.m:83-87`）で*変更*し、通知はメインキューで*到着*します。コレクション自体は同期されません。

### 3.4 陳腐化

`-update`（ドキュメントまたはデータベース）は**新しい**モデルオブジェクトでコレクションを再構築します。以前に渡されたモデルオブジェクトはキャッシュしたものについては動作し続けますが、`firstQuery.tables`にあるものではなくなります。ツリー内で今日モデルオブジェクトの`-update`を呼ぶものはなく（通知パスがライブのもの）、`-update`をまたいでモデルオブジェクトを保存するコードは古いエントリを読むことになります。

## 4. 消費者

### 4.1 Queryタブ（アドホッククエリビルダ）

- `MADQueryViewDataSource.m:365` — データソースヘッダーセル: `firstDatabase`からの「You are connecting to *driverID* datasource named *schemaName*」。
- `MADQueryViewDataSource.m:533-546` — クエリテーブルリストは`firstQuery`を取り、`query.identifier`を使って`RptqQueryTable`行をフィルタします。パターンに注意: **モデルがアイデンティティとメタデータを供給し、行自体はRptqオブジェクト**です。
- `MADQueryTableViewController.m:163-174` — クエリテーブルのボックスタイトルは`firstQuery.tables[id].alias`から来ます。`:186-200`と`:239-266`は`firstDatabase.tableDictionary[schemaTableID]` → `fieldIDs` / `fields`からスキーマフィールドリストをレンダリングします。これがスキーマブラウザのコンテンツモデル全体です。
- `MADQueryBuilderAddTableViewController.m:29-33` — モデルの挿入／削除通知を監視してテーブルパネルを最新に保ちます。

### 4.2 Query Visualizationタブ（ボックスとコネクタ）

- `MADQueryVisualizationModel`（`MADQueryVisualizationModel.m:40-77`）は`-[MTGraph initWtthQueryID:]`（`MTGraph+RptqQuery.m:39-67`）経由で`MTGraph`を構築し、それは**完全にモデル上で**書かれます。`query.queryTableIDs`が頂点になり、`query.links`がエッジになります。次にトポロジカルソートし、`startingPoints`（どのリンクも*入ってこない*テーブル）を計算し、DAGフラグを保存します。（同じカテゴリにはストアベースのイニシャライザもあり、`:69-93`、モデルパスより前のもの。ビジュアライゼーションはモデルのものを使います。）
- `MADQueryVisualizationViewController`（`MADQueryVisualizationViewController.m`）は通知ストリームの主な消費者です。4つのモデル通知すべてを購読し（`:314-335`）、到着するたびにボックスとコネクタを追加／削除し、リンク削除後に`-orphanedQueryTables`を使ってルートテーブルを再マークし（`:936`）、テーブルごとに`-linksForQueryTable:`を尋ね（`:644`）、識別子チェーンを歩いて各コネクタをレイアウトします（`:1024-1048`、§2.6）。
- `MADQueryVisualizationCacheManager`はモデル識別子をキーにキャンバスレイアウトを永続化します（`updateCacheWithQuery:…`、`MADQueryVisualizationCacheManager.h:20`）。

### 4.3 ドキュメントとテスト

`MADocument.documentModel`が唯一の本番エントリポイントです。テスト: `MADDocumentTests.m:263-265`（再オープンしたドキュメントの`databases`/`queries`）、`MADDocumentTests.m:399-404`（`MADModelDatabase`のテーブル／フィールド順）、加えて専用スイート`MADModelQueryTableTests`、`MADModelQueryFieldTests`、`MADModelValueTypesTests`の`MADModelField` / `MADModelQueryLink`カバレッジ。

### 4.4 使わ*ない*もの

- **SQL生成** — `MADQueryFull`と`Rptq*+Extras`クラスはRptqレイヤーで動作します（例えば`RptqQueryField+Extras.m:137`は`RptqQueryTable.alias`から`table.field`名を構築）。
- **レイアウトとレンダリング** — `MADDesignerLayout`とレポートパスは`RptqDocumentElement`で動作します。`MADReportFormatter`はレイヤーをまったく使わず（`MADReportFormatter.m:18-20`の3つの`MADModel*`インポートは古い）、
- **行データ** — どれも`.maddb`キャッシュに触れません。それは`MADDataTableFast` / `MADReportFormatter`の領域です。

したがってレイヤーの今日の本当のスコープは**デザイナのクエリ側だけ**です。

## 5. なぜ存在するのか

レイヤーは2017年初頭のもので（ファイルヘッダー`1/22/17`〜`6/3/17`）、Core Data時代に**クエリUIのための手作りのビューモデル**として構築されました。デザイナのテーブルビューとビジュアライゼーションキャンバスがバインドできる軽量オブジェクトで、`NSManagedObject`や`NSFetchedResultsController`の代わりです。証拠はファイルにあります。`-objectID`、`MADModel.m:66-80`のコメントアウトされた`NSManagedObjectID`デバッグ記述、そして「was an `NSFetchedResultsController`」と述べる3つの生き残ったコメント（`MADQueryChooseFieldController.m:149`、`MTGroupByViewController.m:53`、`MADTableViewControllerCoreDataResults.h:14`）。

ストア移行（`MAD_STORE_MIGRATION.md`のPhase C/D）はすべてのフェッチをCore Dataから`RptqStoreContext` + `objectsForEntity:`へ再配線し、**このレイヤーの表面を変えませんでした**——`MIGRATION_KICKOFF.md` §Findingsがそれを「[a] clean `MADModel*` domain layer [that] already wraps the `Rptq` entities; it is the seam to keep.」と呼ぶ理由です。

つまりある種のMVCですが、「アプリのモデル」ではありません。**ドキュメントごとの読み取りモデル**（コントローラから見たMVCの「モデル」）で、正規ドメインオブジェクトはRptqグラフです。この抽象は3つのものを買い、それ以外では薄いものです。(1) 関係走査なしの表示形状のクエリグラフ（エイリアス、隣接性、IDからメタデータへのルックアップ）、(2) ストア変更通知をクエリグラフイベントに変換する唯一の場所、(3) 下のストアが完全に変わってもUIを変更せずに保てるインターフェース——まさに起こったことです。

## 6. 既知の粗いエッジ

直接読了。今日これらに消費者はないため、すべて潜在的です。

1. `MADModelField.inTable`（`MADModelField.h:20`）は`weak MADModelField *`と宣言されています——型が間違っており（`MADModelTable *`であるべき）——何も代入しません。
2. 他の親バックポインタも同様に未使用です。`MADModelTable.inDatabase`、`MADModelQueryTable.inQuery`、`MADModelQueryField.inQueryTable`はツリー内のどのコードパスにも代入されません。`MADModelQuery.inDatabase`だけが設定されます（`MADModelQuery.m:108-114`）。（`-addField:schemaField:`がフィールドのバックポインタを配線しないことはすでにBUGS.mdに記録されています。）
3. `MADModelDatabase -driverName`（`MADModelDatabase.m:184-215`）は`return @"";`で終わるため、実際の名前をキャッシュした後でも空文字列と答えます。`-schemaName`はすでに同じ場所から同じ文字列を返します。読み手は存在しません。
4. `MADModelDocument.m:228-234`はドキュメントID（`docID`）をデコードし、決して使いません。
5. `MADModelQuery -update`（`MADModelQuery.m:354`）は空で、`MADModelDatabase -update`には呼び出し元がなく、`+[MADModel newModelDocument:]`にも呼び出し元がありません。
6. `MADModelType`は未使用です。
7. モデルを変更するプライベートキューとメインスレッドの読み手の間に同期がなく、`MADModelDocument`はストアコンテキストを弱く保持するため、ドキュメントより長く生きるモデルには何も解決するコンテキストがありません。
8. 命名: `MADModelDocument`は`databases`を持ち、`MADModelDatabase`は`queries`を持ちますが、ドキュメントは*クエリごとに*1つの「データベース」を構築し、今日それぞれ正確に1つです。構造は単一データベース／単一クエリの簡素化より前の将来対応です。

## 7. リファクタリング候補（提案——適用なし）

リスクに対する価値の順。AとBは純粋な整理、Cは公開ヘッダーが約束するものを変え、Dは決定です。

**A. 統合ではなく文書化。** 最も安い明確化の勝利は、クラスごとのヘッダーコメント（2〜4行: クラスが何か、何をキーにするか、誰が読むか）とこのドキュメントです。クラスの*ファイル*をマージするのは安い選択ではなく高価な選択です。16以上のファイルがクラスごとのヘッダーをインポートし（`#import <MAD/MADModelQueryField.h>`など）、各ヘッダーはXcodeターゲットの別ファイルで、Linuxビルドのincludeシムはヘッダーごとのシンボリックリンクのディレクトリです（`Linux/README.md`、MADのシム）。統合は見た目上の利益のためにpbxproj、Linuxソースリスト、すべてのインポートサイトに触れます。マージが望まれるなら、安全な方向は逆です。1クラス1ファイルを保ち、**エントリポイント**を明白にします（`MADModel.h`の先頭にドキュメント、「`MADModelDocument`から始める」）。

**B. 痕跡的な表面を削除または完成させる。** どれも振る舞い安全（何も読まない）ですがヘッダーに触れるため、API決定として扱ってください:
- `MADModelField.inTable`: 型を修正し`MADModelTable -update`で設定する（1行、他の親と対称）、またはプロパティを削除する。
- `MADModelDatabase -driverName`: 兄弟のようにキャッシュ値を返すか、削除する。
- `MADModelType`: ヘッダーを削除する。（プロジェクトファイルの削除が必要。1コミットで行う。）
- `+[MADModel newModelDocument:]`: `MADocument -documentModel`がそれを使うようにする（ファクトリの目的を復元）か、削除する。
- `MADModelDocument.m:228-234`の未使用`docID`デコード。

**C. 宣言されたバックポインタを配線する。** `inDatabase`、`inQuery`、`inQueryTable`はグラフを上向きに歩けるように存在しますが、今日は下向きルックアップだけが機能します。構築時に代入すること（`MADModelDatabase -updateTables`はすでに`self`を持ち、`insertTableRptqQueryTable:`はモデルクエリを持ち、`-addField:schemaField:`はテーブルを持つ）はオブジェクトグラフをヘッダーに一致させ、まだ何も読まないからこそ安全です。心に留める意味論: それらは`weak`と宣言されており、下向きに所有される親には正しい。

**D. リフレッシュをまたぐアイデンティティ（整理ではなく決定）。** `-update`はオブジェクトを置き換えます。更新をまたぐ安定したアイデンティティが望まれるなら、更新メソッドは再構築ではなくその場で変更する（識別子に対してオブジェクトを再利用し、差分を追加／削除する）必要があります。それは渡されたオブジェクトの観測可能なアイデンティティを変えるため、意図的な選択が必要です。

**E. 機械的重複排除。** `MADModelTable.fields`と`-fieldIDs`（`MADModelTable.m:88-118`）は同じ初期化ブロックを2回含み、`MADModelQuery`の3つのゲッターは同じ「コレクションを確実にし、次に更新する」ダンスを繰り返します（`MADModelQuery.m:116-181`）。どちらも振る舞い変更なしで各1つのプライベートヘルパーに折り畳めます。ファイルが他の理由で開かれたときにのみ行う価値があります。

**F. 推奨しない: 名前変更。** `MADModelDatabase` → `MADModelConnection`のような名前はより良く読めますが、ここでの名前変更はXcode/Linuxプロジェクトファイル全体の無駄な変更で、機能的な見返りがありません。

## 8. このレイヤーを変更するなら

- 識別子のみの契約を保ってください。モデルオブジェクトはIDだけで構築可能でなければなりません（通知パスとテストがそれに依存します）。
- `RptqQueryTable` / `RptqQueryLinks`行を作成または削除するものは、`MADModelDocument`のオブザーバが自動的に拾います——ただし`firstQuery`を通じて到達される行だけです。ドキュメントの2つ目のクエリはミラーされません。
- 4つの`MADNotification…`名はUIのためのレイヤーの公開APIです。`MADQueryVisualizationViewController`がするように、`firstQuery`オブジェクトに対してそれらを観察してください。
- iOSスイート（`MAD`スキーム）と`./Linux/build.sh`の両方がこれらのファイルをコンパイルします。`Linux/cmake/MADSources.cmake`参照。
