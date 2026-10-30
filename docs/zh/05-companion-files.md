---
layout: default
lang: zh-CN
---

## 5. 文档中*没有*的东西：伴随文件

`.mad` 是定义，不是数据集。报表*显示*的一切都是派生的、可重新生成的，并且被有意放在归档之外。它旁边会生成三类文件：

| 文件 | 写入者 | 保存的内容 |
|---|---|---|
| `<hash>.maddb` | `MADDataTableFast` | 报表的行数据 |
| `<hash>.mdcache` | `MADDataTable`（`:354`） | 描述基于该数据的虚表的 plist |
| `<hash>{ih,lh}{w, h}.madac` | `MADArrayCaching`，由 `MADReportFormatter`（`:179`、`:183`）提供数据 | 渲染后的页面内容——一个 **SQLite** 数据库，以布局标识符和页面大小作为键。`ih` 是报表*索引*缓存，`lh` 是报表*布局*缓存 |

三者都放在每份文档一个的同一目录中，目录名为 `dataTableIdHash`。
`MADocument.m:286-300` 从 `MADURLFactory newURLCacheFilesDirectoryForFilename:`（`MADURLFactory.m:47-49`）提供的目录构建该表，该目录解析到文档之外一个按用户、按设备区分的位置：

```objc
MADDataTableFast *datatable = [[MADDataTableFast alloc] initWithId:dataTableIdHash];
...
NSURL *cacheUrl = [self newUrlCacheForFilename:cacheName];
self.urlDataTableCache = cacheUrl;
[datatable loadFromCacheWithUrl:cacheUrl error:&error];
```

### 5.1 大小并不像名字暗示的那样

在 `Library/Caches/` 下的真实缓存目录中实测：

| 类型 | 文件数 | 总计 |
|---|---|---|
| `<hash>.maddb` | 1 | 816 KB |
| `<hash>.mdcache` | 1 | 1.7 KB |
| `<hash>{ih,lh}{...}.madac` | 6 | **约 15 MB** |

`.madac` 文件是格式化器的页面缓存。`ih` 和 `lh` 键来自
`MADReportFormatter.m:179` 和 `:183`，它们构造 `<layoutIdentifier>ih<CGSize>` 和
`<layoutIdentifier>lh<CGSize>`；`{612, 792}` 是 US Letter 的点数尺寸。因此缓存以*布局标识和页面几何*为键——这正是 §5.3 中两个风险成为现实的原因。

相对于不到 80 KB 的文档，渲染缓存约为**文档体积的 200 倍**。人们本以为会占大头的行数据，只占该目录的不到 6%。

**为什么它有意这么大。** 这个体积是设计的必然结果，不是可以顺手优化掉的意外。两个原因，均来自用户本人的说明（2026-10-01）：

1. **两趟渲染。** 在拿到完整行集之前，无法知道页数和分组。报表页脚中的计数分组可以在最后求和，但报表页眉中的计数分组必须在第一页排版之前就知道——而且在知道行数之前无法给页面编号——因此整个结果集会被一次性拉取并保留在设备上。
2. **缓存是未来视图的平台。** 一旦数据行在本地，就可以从同一份缓存构建同一数据的不同视图，而无需重新查询数据源，这与每翻一页就再次访问数据库的网站正好相反。在这份缓存之上还计划了更多东西，所以把它当作临时空间是错误的。

缓存可以压缩，但它并不是当前亟待改变的事情。

### 5.2 后果

- 一个 `.mad` **小巧且自包含**：它是定义，不是数据集。两份已发布的示例都不到 80 KB。
- 缓存目录中的所有内容都是**可丢弃的**。删除它的代价是一次刷新，绝不会丢失文档。
- 它**不会**在设备之间共享，也不在 iCloud 中，即使文档本身在 iCloud 中也是如此。每台设备在首次打开时都会重新获取。
- 因此 `.mad` **不是**它表面上看起来的那种“把数据装在里面的压缩 SQLite 文件”。它是把*定义*装在里面的压缩 SQLite 文件。

### 5.3 伴随文件尚未定义的内容

该目录有名字、有内容，但没有规范。有三个缺口，第二个平台只能靠猜：

1. **渲染缓存以文件名而不是内容为键——2026-10-01 已确认。**
   `MADReportFormatter -layoutIdentifier`（`MADReportFormatter.m:186`）返回
   `_overrideIdentifier ? _overrideIdentifier.hash : _filename.hash`。因此键是文档的*名称*加上页面大小，加载路径中没有任何内容检查：
   `MADArrayCaching -initializeDatabase`（`MADArrayCaching.m:141`）只要存在 `ac` 表就会复用现有
   SQLite 文件，键或加载过程中都没有版本、时间戳或内容哈希。**以相同文件名编辑文档不会使其 `.madac` 文件失效**——在文件被删除或渲染不同页面大小之前，会一直提供过期的页面。

   **2026-10-01 的实测结果与此一致。** 15:22 对 London 文档执行了一次无头刷新和导出。之后在其缓存目录中：

   | 文件 | 大小 | mtime |
   |---|---|---|
   | `<hash>.maddb` | 835,584 | 15:22 |
   | `<hash>.mdcache` | 1,644 | 15:22 |
   | `<layoutId>ih{612, 792}.madac` | 81,920 | 15:22 |
   | `<layoutId>lh{612, 792}.madac` | 737,280 | 15:22 |
   | `<layoutId>ih{0, 0}.madac` | 1,867,776 | **10:52** |
   | `<layoutId>lh{0, 0}.madac` | 4,333,568 | **10:52** |

   一次刷新只重写它需要的文件——`{612, 792}` 条目（US Letter，即 PDF 的页面几何）——其余文件保持不动。`{0, 0}` 条目没有被触碰，它们合计占该目录 15 MB 中的 6.0 MB。`{0, 0}` 是在真正几何尺寸确定之前的页面大小，因此这两个文件几乎可以肯定是一次测量过程；而且在以文件名为键的方案下，除了删除之外，它们永远不会被任何操作置为失效。
2. **没有任何说明指出哪些内容可以删除。** 三类文件都可重新生成，因此三类都应当是安全的——但一个 0 字节的 `.maddb` 出现在一个除此之外未被触碰的目录中，说明目录在填充之前就已创建，而没有任何地方说明这样的目录是否有意义。
3. **`.mdcache` 的 plist 架构。** 现在已知——它是结果表的序列化架构，由 `MADDataTableFast -copyPlist` 写入，由 `-loadWithPlist:` 读取。顶层键：`name`、`columnKeys`（有序的 `c<hash>` id 数组）、`columns`（以 `c<hash>` 为键的字典，每项是一个 `MADDataColumn` plist：`caption`、`fieldName`、`identifier`、`type`、
   `nativeType`、`dataLength`、`dataPercision`、`isPrimaryKey`、`isNotNull`、
   `isAutoIncrement`、`defaultValue`）、`rowCounter`、`sortDescriptors`，以及快速表的
   `bulkInsertLoop`。`defaultValue` 是哨兵值 `~MTNull~`
   （`MADDataColumnNullSentinel`，`MADDataColumn.m:23`）。注意两个长期存在的怪癖：
   `dataPercision` 在格式中拼写错误，而 `~MTNull~` 哨兵是区别于
   `project/BUGS.md` Track 1.5 中 `"<null>"` / `"(null)"` 家族的第三种 null 标记。
