---
layout: default
title: "MADArrayCaching"
description: "レポートのレンダーキャッシュを支えるディスクベースの追記専用配列。"
lang: ja-JP
---

# `MADArrayCaching`

このページでは、レポートのレンダーキャッシュとして使われるディスクベースの追記専用配列`MADArrayCaching`について説明します。

*元の日付に書かれ、現状の事実は2026-11-22に整合。*

ディスクベースの追記専用順序付き配列で、レポートの**レンダーキャッシュ**として使われます。2026-10-01、`master`の`7ebe82f89`に対して書かれました。

---

## それが何か

`MADArrayCaching<ObjectType>`（`MADSqlite3`内）は`NSEnumerator`サブクラスで、要素がメモリではなくディスクに存在する`NSMutableArray`のように振る舞います。各要素は`NSKeyedArchiver`でシリアライズされ、SQLiteファイルのBLOBとして保存されます。`MAD_FORMAT.md` §5の`.madac`コンパニオンファイルの背後にあるクラスです。

ドキュメントごとに2つのインスタンスがあり、どちらも`MADReportFormatter`が所有します。

| 識別子サフィックス | 保持するもの | 要素型 |
|---|---|---|
| `…ih{w,h}` | ページ**インデックス**（どの行が各ページに着地するか） | `NSArray<NSNumber *>` |
| `…lh{w,h}` | ページ**レイアウト**（ページごとのセクション表現） | `NSArray<MADSectionRepresentation *>` |

`MADReportFormatter`は`beginBulkInserts` / `addObject:` / `endBulkInserts`でそれらを埋め、`objectAtIndex:` / `objectAtIndexedSubscript:`で読み戻します。これがレンダーキャッシュです——Musicキャッシュの約15 MBの`.madac`ファイル——そして再レンダリングがページレイアウトの再計算をスキップできるようにするものです。

## オンディスクフォーマット

`<identifier>.madac`は1つのテーブルを持つ通常のSQLiteファイルです。

| 列 | 型 | 意味 |
|---|---|---|
| `ci` | INTEGER、主キー | 要素のインデックス（0、1、2、……） |
| `ck` | BLOB | `NSKeyedArchiver`でシリアライズされた要素 |

ファイルはドキュメントのキャッシュディレクトリにあり、`[self.identifier stringByAppendingPathExtension:@"madac"]`（`MADArrayCaching.m:269-274`）で名付けられます。ここで`identifier`はフォーマッタの`layoutIdentifier` + `ih`/`lh` + ページサイズです。

## API

`initWithIdentifier:cachedDelegate:types:` — `cachedDelegate`が`MADCacheProtocol`を通じてキャッシュディレクトリを供給し、`types`は`NSKeyedUnarchiver`がデコードしてよいクラスの集合です。

次に: `initializeDatabase`（開き、テーブルがなければ作成）、`addObject:`（追記）、`objectAtIndex:` / `objectAtIndexedSubscript:`（読み取り）、`beginBulkInserts` / `endBulkInserts`（多数の追記を囲むトランザクション）、`removeAllObjects`、`finalizeDatabase`、および`count` / `state` / `identifier`アクセサ。

## なぜ速いのか（設計は正しい）

- **プリペアドステートメント。** 挿入、選択、カウントのステートメントは一度コンパイルされ（`prepareStatement*`）、呼び出しごとに再バインドされます——再パースはありません。
- **インデックス付きルックアップ。** `ci`が主キーなので、`objectAtIndex:`は`SELECT ck WHERE ci = ?`——O(1)のインデックスプローブで、スキャンではありません。
- **トランザクション内のバルク挿入。** `beginBulkInserts` / `endBulkInserts`が追記を囲むため、フルレンダリングはページごとのfsyncではなく1回のコミットです。
- **要素ごとのメモリキャッシュ。** `objectAtIndex:`はアンアーカイブするすべての要素を（インデックスをキーに）キャッシュするため、繰り返し読み取り——レンダラーの通常のパターン——はSQLiteラウンドトリップもアンアーカイブもない`NSDictionary`ルックアップです。`lastObjectSelected`は`nextObject`のために残ります。
- **2つのシリアルキュー**（`archivingQueue`、`unarchiveQueue`）が単一のSQLite接続を1つのライターと1つのリーダーに保ちます。

支配的なコストはSQLiteではなく`NSKeyedArchiver` / `NSKeyedUnarchiver`のシリアライズです。レンダーキャッシュは`MADSectionRepresentation`グラフのマーシャリングに時間を使い、それはフォーマッタがとにかく行うのと同じ作業です。

## 見つかった問題

項目1〜4は2026-10-01に修正されました。項目5〜6は未解決のままで、修正ではなく記録されています（列挙子は死んだコードで、並行性の落とし穴はフォーマッタがシングルスレッドである間は潜在しています）。

1. **`-isEmpty`が反転している。** `MADArrayCaching.m:440`は`return _numberOfRows > 0;`です——キャッシュが行を*持つ*ときにYESを返します。死んだコード（呼び出し元なし）なので、生きた不具合ではなく潜在的な罠です。**修正済み**、読み取り専用プロパティとして公開。
2. **`-count`が空のキャッシュで1を返す。** `MADArrayCaching.m:424-438`はカウントを`max(ci) + 1`として計算しますが、テーブルが空のとき`SELECT … ORDER BY ci DESC LIMIT 1`は`SQLITE_DONE`を返し、doneステートメントに対する`sqlite3_column_int64`はゴミを読みます。結果は0ではなく1になります。**修正済み。**
3. **`-readDataAtIndex:`と`-writeData:`が死んでいる。** ヘッダーになく、呼び出し元もありません。`addObject:`に取って代わられた生`NSData`パスの残りです。`readDataAtIndex:`は型も混ぜます。`lastObjectSelected`ヒット時に`NSData`ではなく*アンアーカイブされた*オブジェクトを返します。**削除済み。**
4. **テーブル／列定数が重複している。** `MTArrayCachedTableName` / `…ColumnKey` / `…ColumnValue` / `…Extension`は`MADArrayCaching.m`で`static`宣言され、`MADArrayCachingEnumerator.m`でグローバルに再宣言されています。1つのヘッダーがそれらを所有すべきです。**修正済み**——`extern`宣言は今`MADArrayCaching.h`にあり、定義は`MADArrayCaching.m`にあります。
5. **`MADArrayCachingEnumerator`が古いアンアーカイバを使っている。** `MADArrayCaching`が`unarchivedObjectOfClasses:`を使う場所で、非推奨の`unarchiveObjectWithData:`（非セキュア）を呼びます。またその`nextObject`は各ステップ後にステートメントをリセットするため、手動反復は決して進みません（`countByEnumeratingWithState:`経由の高速列挙は影響を受けません）。**未解決**——クラスに呼び出し元がありません。
6. **`_numberOfRows`がキューの外で読まれる。** `addObject:`は`dispatch_*`の前に`_numberOfRows`を読むため、並行追記はインデックスで衝突します。フォーマッタは今日シングルスレッドでそれらを呼ぶので潜在的です。**未解決。**

## 提案される改善

価値の順:

1. `-isEmpty`と`-count`を修正し（2つの1行修正）、死んだ`readDataAtIndex:` / `writeData:`の対を削除する。振る舞い安全: 最初の2つは不具合修正で、2つ目は型不具合のある死んだコード。
2. `MTArrayCached*`定数を、両ファイルがインポートする単一のヘッダーに移す。
3. `MADArrayCachingEnumerator`を`MADArrayCaching`と同じアンアーカイバに引き上げ、壊れた`nextObject`を修正または削除する。
4. プロファイリングが示した場合にのみ: `NSKeyedArchiver`をより軽いキャッシュ専用シリアライザに置き換え、かつ／またはキューがすでに所有されているときは読み取りごとの`dispatch_sync`を直接呼び出しに落とす。これらは「本当に速くする」レバーで、上の正確性項目が先です。
