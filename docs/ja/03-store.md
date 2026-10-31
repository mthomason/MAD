---
layout: default
lang: ja-JP
---

## 3. ストア

`StoreContent/analyitics`は通常のSQLiteデータベースです：

```
StoreContent/analyitics: SQLite 3.x database, last written using SQLite version 3043002,
  writer version 2, read version 2, file counter 52, database pages 126, cookie 0x6e,
  schema 4, largest root page 113, UTF-8, vacuum mode 1, version-valid-for 52
```

ここには**ドキュメント定義**——クエリ、そのテーブルと結合、レポートのセクションと要素、およびデータベースのスキーマスナップショット——が格納されます。Core Dataモデルは`MAD/MAD.xcdatamodel`であり、そのエンティティにはすべて`Rptq`プレフィックスが付いています（`RptqDocument`、`RptqQuery`、`RptqDocumentElement`、`RptqDocumentSection`など）。

このストアには、ポータビリティ上極めて重要な2つの性質があります：

1. **WALモードで書き込まれていること。** メインのデータベースと並んで`-wal`および`-shm`ファイルがアーカイブ内に同梱されています。`analyitics`のみを展開してWALを無視するリーダーは、最大で1チェックポイント分古いデータベースを読むことになります。`Music`サンプルでは、**516 KBのメインファイルに対してWALが313 KB**を占めており、これは理論上のリスクではなく現実の問題です。
2. **レガシーサンプルではCore Dataストアであること。** そのため、スキーマは独自のものではなくCore Dataのものになっていました。Core Dataを使わずに読み取るにはCore Data自身のテーブルを読む必要があります。SQLiteでありマッピングも安定しているため読み取り自体は可能ですが、この部分がリーダーをCore Dataに縛り付けていた要因であり、Core Dataからの移行が他のどこよりもここで重要となった理由です。

### 3.1 ポータブルストア（ストア移行後）

ストア移行（`docs/project/MAD_STORE_MIGRATION.md`）以降、ドキュメントの定義は独自設計のポータブルSQLiteストアに格納されています。そのスキーマは手動管理される`MADStoreSchema`ディスクリプタ（`MAD/Source/rptq/store/`）によって記述され、`-createSchemaSQL`によって生成され、`MADStoreTests`によってコンパイル済みモデルと照合検証されます。ストアは`PRAGMA user_version`にスキーマバージョンを記録します。バージョン1は初期出荷時のスキーマ（未設定または0）、バージョン2ではユーザーが貼り付けたSQLをそのまま保持する`RptqQuery.sqlSourceText`（`docs/project/MAD_SQL_ENTRY.md` §8）が追加されており、`MADStore`はオープン時に未適用のマイグレーションステップを適用します。`RptqQuery`テーブルのフィールドは以下の通りです：

| カラム | 型 | 備考 |
|---|---|---|
| `identifier` | INTEGER | 行キー（主キー） |
| `cachedText` | TEXT | |
| `override` | INTEGER | |
| `overrideText` | TEXT | |
| `sqlSourceText` | TEXT | 最後に正常適用された貼り付けSQL文（原文のまま）。それ以外はNULL |
| `inDatabase_identifier` | INTEGER | `RptqDatabase`への外部キー |
