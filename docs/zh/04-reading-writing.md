---
layout: default
lang: zh-CN
---

## 4. 读取与写入的实现

```
write:  document model ──▶ UIManagedDocument ──▶ ~/tmp/<name>.mada/ ──▶ tar.bz2 ──▶ <name>.mad
read:   <name>.mad ──▶ tar.bz2 ──▶ ~/tmp/<name>.mada/ ──▶ UIManagedDocument
```

中间目录称为 **guts**。它的扩展名是 `.mada`
（`MADConstants.m:12`，`MADFileExtentionMobleApplicationDocumentArchive`），以文档名命名，
并放在临时目录中（`MADURLFactory.m:51-56`，`newURLLocalTemporaryDirectory` → `~/tmp`）。

- 保存——`MADocument.m:497-514`：把模型写入 guts，然后把 guts 归档到文档 URL 上。
- 打开——`MADocument.m:456-476`：把文档解包到 guts，然后从那里读取存储。

`-readFromURL:` 上方的注释（`MADocument.m:452-455`）用作者自己的话说明了这一点：

> 1. 解包 MAD 文件；它是一个 zip 文件（也可能是 tar.bz2）。
> 2. 读取解包后的文件。它目前是一个 Core Data 文件。

“它目前是一个 Core Data 文件”用五个词概括了整场迁移。
