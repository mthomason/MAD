---
layout: default
lang: ja-JP
---

## 4. 実装されている読み込みと書き込み

```
write:  document model ──▶ UIManagedDocument ──▶ ~/tmp/<name>.mada/ ──▶ tar.bz2 ──▶ <name>.mad
read:   <name>.mad ──▶ tar.bz2 ──▶ ~/tmp/<name>.mada/ ──▶ UIManagedDocument
```

中間ディレクトリは**guts**と呼ばれます。拡張子は`.mada`（`MADConstants.m:12`、`MADFileExtentionMobleApplicationDocumentArchive`）で、ドキュメント名にちなんで名付けられ、一時ディレクトリ（`MADURLFactory.m:51-56`、`newURLLocalTemporaryDirectory` → `~/tmp`）に配置されます。

- 保存 — `MADocument.m:497-514`：モデルをgutsに書き込み、そのgutsをアーカイブしてドキュメントURLを上書きします。
- オープン — `MADocument.m:456-476`：ドキュメントをgutsに展開し、そこからストアを読み込みます。

`-readFromURL:`の上にあるコメント（`MADocument.m:452-455`）には、作者自身の言葉で次のように記されています：

> 1. Unarchive the MAD file; it's a zip file (tar.bz2 maybe).
> 2. Read the unarchived file. It's currently a Core Data file.

「It's currently a Core Data file（現在はCore Dataファイルである）」という一文が、ストア移行のすべてを端的に表しています。
