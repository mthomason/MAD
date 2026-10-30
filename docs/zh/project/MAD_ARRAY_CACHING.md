---
layout: default
lang: zh-CN
---

# `MADArrayCaching`

一个由磁盘支持、仅追加的有序数组，用作报表的**渲染缓存**。写于 2026-10-01，对应 `7ebe82f89` 处的 `master`。

---

## 它是什么

`MADArrayCaching<ObjectType>`（位于 `MADSqlite3`）是 `NSEnumerator` 的子类，行为类似一个元素存放在磁盘而非内存中的 `NSMutableArray`。每个元素用 `NSKeyedArchiver` 序列化，并作为 BLOB 存储在 SQLite 文件中。它是 `MAD_FORMAT.md` §5 中 `.madac` 伴随文件背后的类。

每个文档有两个实例，均由 `MADReportFormatter` 持有：

| 标识符后缀 | 保存内容 | 元素类型 |
|---|---|---|
| `…ih{w,h}` | 页面**索引**（哪些行落在哪一页） | `NSArray<NSNumber *>` |
| `…lh{w,h}` | 页面**布局**（每页的区段表示） | `NSArray<MADSectionRepresentation *>` |

`MADReportFormatter` 通过 `beginBulkInserts` / `addObject:` / `endBulkInserts` 填充它们，并通过 `objectAtIndex:` / `objectAtIndexedSubscript:` 读回。这就是渲染缓存——Music 缓存中约 15 MB 的 `.madac` 文件——它使重新渲染可以跳过重新计算页面布局。

## 磁盘格式

`<identifier>.madac` 是一个普通的 SQLite 文件，只有一张表：

| 列 | 类型 | 含义 |
|---|---|---|
| `ci` | INTEGER, primary key | 元素的索引（0、1、2、…） |
| `ck` | BLOB | 经 `NSKeyedArchiver` 序列化的元素 |

该文件位于文档的缓存目录中，命名为 `[self.identifier stringByAppendingPathExtension:@"madac"]`（`MADArrayCaching.m:269-274`），其中 `identifier` 是格式化器的 `layoutIdentifier` + `ih`/`lh` + 纸张大小。

## API

`initWithIdentifier:cachedDelegate:types:`——`cachedDelegate` 通过 `MADCacheProtocol` 提供缓存目录，`types` 是 `NSKeyedUnarchiver` 可以解码的类集合。

然后：`initializeDatabase`（打开，若表不存在则创建）、`addObject:`（追加）、`objectAtIndex:` / `objectAtIndexedSubscript:`（读取）、`beginBulkInserts` / `endBulkInserts`（围绕多次追加的事务）、`removeAllObjects`、`finalizeDatabase`，以及 `count` / `state` / `identifier` 访问器。

## 为什么它很快（设计是正确的）

- **预处理语句。** 插入、选择和计数语句只编译一次（`prepareStatement*`），每次调用时重新绑定——无需重新解析。
- **索引查找。** `ci` 是主键，因此 `objectAtIndex:` 是一次 `SELECT ck WHERE ci = ?`——O(1) 的索引探测，而非扫描。
- **事务中的批量插入。** `beginBulkInserts` / `endBulkInserts` 包裹追加操作，因此一次完整渲染是一次提交，而不是每页一次 fsync。
- **逐元素的内存缓存。** `objectAtIndex:` 会缓存它解档的每个元素（以索引为键），因此重复读取——渲染器的常规模式——只是一次 `NSDictionary` 查找，没有 SQLite 往返，也没有解档。`lastObjectSelected` 保留供 `nextObject` 使用。
- **两个串行队列**（`archivingQueue`、`unarchiveQueue`）将单一的 SQLite 连接限制为一个写入者和一个读取者。

主要成本是 `NSKeyedArchiver` / `NSKeyedUnarchiver` 序列化，而不是 SQLite——渲染缓存把时间花在编组 `MADSectionRepresentation` 图上，这本来就是格式化器无论如何都要做的工作。

## 发现的问题

第 1–4 项已于 2026-10-01 修复；第 5–6 项仍然未决，予以记录而不修复（枚举器是死代码，且在格式化器为单线程时，并发隐患处于潜伏状态）。

1. **`-isEmpty` 逻辑反了。** `MADArrayCaching.m:440` 是 `return _numberOfRows > 0;`——当缓存*有*行时它返回 YES。它是死代码（没有调用者），因此是潜在的陷阱，而不是活跃的缺陷。**已修复**，并作为只读属性暴露。
2. **空缓存时 `-count` 返回 1。** `MADArrayCaching.m:424-438` 将 count 计算为 `max(ci) + 1`，但当表为空时，`SELECT … ORDER BY ci DESC LIMIT 1` 返回 `SQLITE_DONE`，而在已完成执行的语句上调用 `sqlite3_column_int64` 会读到垃圾值；结果是 1 而不是 0。**已修复。**
3. **`-readDataAtIndex:` 和 `-writeData:` 是死代码。** 不在头文件中，也没有调用者。它们是残留的原始 `NSData` 路径，已被 `addObject:` 取代。`readDataAtIndex:` 还混合了类型：在 `lastObjectSelected` 命中时，它返回*解档后*的对象，而不是 `NSData`。**已删除。**
4. **表/列常量重复。** `MTArrayCachedTableName` / `…ColumnKey` / `…ColumnValue` / `…Extension` 在 `MADArrayCaching.m` 中声明为 `static`，又在 `MADArrayCachingEnumerator.m` 中重新声明为全局。应由一个头文件持有它们。**已修复**——`extern` 声明现在位于 `MADArrayCaching.h`，定义位于 `MADArrayCaching.m`。
5. **`MADArrayCachingEnumerator` 仍在使用旧的解档器。** 它调用已弃用的 `unarchiveObjectWithData:`（非安全），而 `MADArrayCaching` 使用 `unarchivedObjectOfClasses:`。而且它的 `nextObject` 在每一步之后都会重置语句，因此手动迭代永远不会前进（通过 `countByEnumeratingWithState:` 的快速枚举不受影响）。**仍未解决**——该类没有调用者。
6. **`_numberOfRows` 在队列之外被读取。** `addObject:` 在 `dispatch_*` 之前读取 `_numberOfRows`，因此并发追加会在索引上发生冲突。格式化器目前以单线程方式调用它们，所以这是潜在的。**仍未解决。**

## 建议的改进

按价值排序：

1. 修复 `-isEmpty` 和 `-count`（两处一行修改），并删除死代码 `readDataAtIndex:` / `writeData:` 对。行为安全：前两者是缺陷修复，后者是带有类型缺陷的死代码。
2. 将 `MTArrayCached*` 常量移入两个文件都会导入的单个头文件。
3. 让 `MADArrayCachingEnumerator` 使用与 `MADArrayCaching` 相同的解档器，并修复或移除其损坏的 `nextObject`。
4. 仅在性能分析表明需要时：用更轻量、专用于缓存的序列化器替换 `NSKeyedArchiver`，和/或在队列已被持有时去掉每次读取的 `dispatch_sync`，改为直接调用。这些是“真正快”的杠杆；上述正确性问题优先。
