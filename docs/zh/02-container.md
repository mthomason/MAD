---
layout: default
lang: zh-CN
---

## 2. 容器

```
$ file Music.mad
Music.mad: bzip2 compressed data, block size = 900k
```

写入器位于 `MADArchiveManager.m:86-100`：

| 属性 | 值 | 位置 |
|---|---|---|
| 归档格式 | `pax restricted` | `MADArchiveManager.m:88` |
| 压缩过滤器 | bzip2 | `MADArchiveManager.m:95` |
| 隐藏文件 | **跳过** | `MADArchiveManager.m:111` |
| 成员路径 | 相对于归档根目录 | `MADArchiveManager.m:124-130` |

`pax restricted` 指带 ustar 已覆盖扩展的 POSIX pax，因此任何 tar 实现都能读取该归档。bzip2 存在于每个平台的每个包管理器中。**容器中没有任何 Apple 专有的东西。** `.mad` 文件在 macOS、Linux 和 Windows 上都能用 `tar xjf` 解包。

### 成员

两份已发布的示例都恰好包含以下六个条目，顺序如下：

```
AdditionalContent/
StoreContent/
StoreContent/analyitics-wal
StoreContent/analyitics-shm
StoreContent/analyitics
meta.plist
```

`AdditionalContent/` 在两份示例中都存在但为空。它是文档用来存放缩略图的目录：`MADocument.m:571-583` 从中读取
`thumbnail@2x.png` 存入 `extraInformation`，`MADURLFactory.m:58-68` 构造该路径。它由
`-writeAdditionalContent:toURL:…`（`MADocument.m:617-648`）作为
`UIManagedDocument` 附加内容协议的一部分写入。

`StoreContent/` 是 Core Data 持久化存储，由
`+persistentStoreName`（`MADocument.m:650`）命名，它返回 `@"analyitics"`。

> 这个名字拼错了，而且是在**磁盘上、在已发布的文档中**拼错的。
> 它不是注释里可以改正的笔误：重命名会改变存储文件名，并破坏每一个现有的 `.mad` 文件。它保持原样，这段说明的存在是为了让下一位读者不要去“修复”它。

`meta.plist` 是文档自身的元数据，写入位置为 `MADocument.m:636-644`：

```xml
{
  "generator" => "MAD Designer"
  "version"   => 1
}
```

版本在写入时是 double（`MADocument.m:611`），在示例中读回时是整数。使用方应当同时接受两者。
