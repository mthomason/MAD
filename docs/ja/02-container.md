---
layout: default
lang: ja-JP
---

## 2. コンテナ

```
$ file Music.mad
Music.mad: bzip2 compressed data, block size = 900k
```

書き込み処理は`MADArchiveManager.m:86-100`にあります：

| プロパティ | 値 | 実装箇所 |
|---|---|---|
| アーカイブ形式 | `pax restricted` | `MADArchiveManager.m:88` |
| 圧縮フィルタ | bzip2 | `MADArchiveManager.m:95` |
| 隠しファイル | **スキップされる** | `MADArchiveManager.m:111` |
| メンバパス | アーカイブルートからの相対パス | `MADArchiveManager.m:124-130` |

`pax restricted`は、ustarがすでにカバーしている範囲では拡張を使わないPOSIX pax形式を意味するため、どのtar実装でも読み取ることができます。bzip2はあらゆるプラットフォームのパッケージマネージャに含まれています。**コンテナ自体にApple固有の要素は一切ありません。** `.mad`ファイルはmacOS、Linux、Windowsのいずれでも`tar xjf`で展開できます。

### メンバ構成

出荷されている2つのサンプルには、いずれも以下の6つのエントリがこの順序で含まれています：

```
AdditionalContent/
StoreContent/
StoreContent/analyitics-wal
StoreContent/analyitics-shm
StoreContent/analyitics
meta.plist
```

`AdditionalContent/`は両方のサンプルに存在しますが中身は空です。これはドキュメントがサムネイル用に使用するディレクトリであり、`MADocument.m:571-583`がここから`thumbnail@2x.png`を`extraInformation`に読み込み、`MADURLFactory.m:58-68`がそのパスを構築します。書き込みは`UIManagedDocument`の追加コンテンツプロトコルの一部として`-writeAdditionalContent:toURL:…`（`MADocument.m:617-648`）によって行われます。

`StoreContent/`は永続ストアであり、`+persistentStoreName`（`MADocument.m:650`）が返す`@"analyitics"`という名前が付けられています。

> この名前にはスペルミスがありますが、**出荷済みのドキュメント内のディスク上のファイル名として**この通りに記録されています。コメント内の単なる誤字ではないため、修正することはできません。名前を変更するとストアのファイル名が変わり、既存のすべての`.mad`ファイルが壊れてしまいます。そのためこのスペルのまま維持されており、後続の実装者が誤って「修正」しないようここに明記しています。

`meta.plist`は`MADocument.m:636-644`で書き込まれるドキュメント自身のメタデータです：

```xml
{
  "generator" => "MAD Designer"
  "version"   => 1
}
```

バージョンは書き込み時にはdouble型として出力されますが（`MADocument.m:611`）、サンプル内では整数として読み取られます。コンシューマ（読み取り側）は両方を受け入れる必要があります。
