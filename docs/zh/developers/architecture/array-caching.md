---
layout: default
title: "MADArrayCaching"
description: "报表渲染缓存背后的磁盘支撑、只追加数组。"
lang: zh-CN
---

# `MADArrayCaching`

本页介绍 `MADArrayCaching`，即用作报表渲染缓存的磁盘支撑、只追加数组。

*撰写于原定日期；当前状态事实已于 2026-11-22 核实。*

一个磁盘支撑、只追加的有序数组，用作报表的**渲染缓存**。撰写于 2026-10-01，针对 `7ebe82f89` 处的 `master`。

---

## 它是什么

`MADArrayCaching<ObjectType>`（位于 `MADSqlite3`）是一个 `NSEnumerator` 子类，行为类似 `NSMutableArray`，但元素存放在磁盘上而非内存中。每个元素都用 `NSKeyedArchiver` 序列化，并作为 BLOB 存储在 SQLite 文件中。它就是 `MAD_FORMAT.md` §5 中 `.madac` 伴随文件背后的类。

每份文档有两个实例，均由 `MADReportFormatter` 持有：

| 标识符后缀 | 保存内容 | 元素类型 |
|---|---|---|
| `…ih{w,h}` | 页面**索引**（哪些行落在哪一页） | `NSArray<NSNumber *>` |
| `…lh{w,h}` | 页面**布局**（每页的带区表示） | `NSArray<MADSectionRepresentation *>` |

`MADReportFormatter` 通过 `beginBulkInserts` / `addObject:` / `endBulkInserts` 填充它们，并通过 `objectAtIndex:` / `objectAtIndexedSubscript:` 读回。这就是渲染缓存——一个 Music 缓存中约 15 MB 的 `.madac` 文件——它让重新渲染得以跳过重新计算页面布局。

## 磁盘格式

`<identifier>.madac` 是一个普通的 SQLite 文件，只有一张表：

| 列 | 类型 | 含义 |
|---|---|---|
| `ci` | INTEGER, primary key | 元素的索引（0、1、2、……） |
| `ck` | BLOB | 经 `NSKeyedArchiver` 序列化的元素 |

该文件位于文档的缓存目录中，命名为
`[self.identifier stringByAppendingPathExtension:@"madac"]`（`MADArrayCaching.m:269-274`），其中
`identifier` 是格式化器的 `layoutIdentifier` + `ih`/`lh` + 页面尺寸。

## API

`initWithIdentifier:cachedDelegate:types:`——`cachedDelegate` 通过
`MADCacheProtocol` 提供缓存目录，`types` 是 `NSKeyedUnarchiver` 可以解码的类集合。

然后是：`initializeDatabase`（打开，若不存在则创建表）、`addObject:`（追加）、
`objectAtIndex:` / `objectAtIndexedSubscript:`（读取）、`beginBulkInserts` / `endBulkInserts`
（围绕多次追加的事务）、`removeAllObjects`、`finalizeDatabase`，以及 `count` /
`state` / `identifier` 访问器。

## 它为什么快（设计是正确的）

- **预编译语句。** 插入、选择和计数语句只编译一次
  （`prepareStatement*`），每次调用重新绑定——无需重新解析。
- **索引查找。** `ci` 是主键，所以 `objectAtIndex:` 就是 `SELECT ck WHERE ci = ?`
  ——一次 O(1) 的索引探查，而非扫描。
- **事务内的批量插入。** `beginBulkInserts` / `endBulkInserts` 包住这些追加，所以
  一次完整渲染只提交一次，而不是每页一次 fsync。
- **逐元素的内存缓存。** `objectAtIndex:` 会缓存它反归档过的每个元素（以
  索引为键），因此重复读取——渲染器的常规模式——只是一次 `NSDictionary` 查找，
  既无 SQLite 往返，也无反归档。`lastObjectSelected` 保留给 `nextObject`。
- **两个串行队列**（`archivingQueue`、`unarchiveQueue`）让单一的 SQLite 连接
  保持为一个写入者和一个读取者。

主要开销是 `NSKeyedArchiver` / `NSKeyedUnarchiver` 序列化，而非 SQLite——
渲染缓存把时间花在编组 `MADSectionRepresentation` 图上，而这本来就是格式化器
无论如何都要做的工作。

## 发现的问题

第 1–4 项于 2026-10-01 修复；第 5–6 项仍未解决，仅作记录而不修复（该
枚举器是死代码，而在格式化器为单线程时并发隐患处于潜伏状态）。

1. **`-isEmpty` 是颠倒的。** `MADArrayCaching.m:440` 是
   `return _numberOfRows > 0;`——当缓存*有*行时它返回 YES。它是死代码
   （无调用者），因此是潜在陷阱，而非现网缺陷。**已修复**，并暴露为只读
   属性。
2. **`-count` 对空缓存返回 1。** `MADArrayCaching.m:424-438` 把 count 计算为
   `max(ci) + 1`，但表为空时 `SELECT … ORDER BY ci DESC LIMIT 1` 返回
   `SQLITE_DONE`，而对已完成语句调用 `sqlite3_column_int64` 会读到垃圾值；结果是
   1 而非 0。**已修复。**
3. **`-readDataAtIndex:` 与 `-writeData:` 是死代码。** 不在头文件中，无调用者。它们是被
   `addObject:` 取代的遗留原始 `NSData` 路径。`readDataAtIndex:` 还混用了类型：
   在命中 `lastObjectSelected` 时它返回*已反归档*的对象，而非 `NSData`。**已删除。**
4. **表/列常量有重复定义。** `MTArrayCachedTableName` / `…ColumnKey` /
   `…ColumnValue` / `…Extension` 在 `MADArrayCaching.m` 中声明为 `static`，又在
   `MADArrayCachingEnumerator.m` 中重新声明为全局。应由一个头文件拥有它们。**已修复**——
   `extern` 声明现在位于 `MADArrayCaching.h`，定义位于
   `MADArrayCaching.m`。
5. **`MADArrayCachingEnumerator` 仍用旧的反归档器。** 它调用已弃用的
   `unarchiveObjectWithData:`（非安全），而 `MADArrayCaching` 用的是
   `unarchivedObjectOfClasses:`。而且它的 `nextObject` 每步之后都会重置语句，所以
   手动迭代永远无法前进（通过 `countByEnumeratingWithState:` 的快速枚举不受影响）。
   **仍未解决**——该类没有调用者。
6. **`_numberOfRows` 在队列之外被读取。** `addObject:` 在 `dispatch_*` 之前读取
   `_numberOfRows`，因此并发追加会在索引上冲突。目前格式化器以单线程调用它们，
   所以处于潜伏状态。**仍未解决。**

## 建议的改进

按价值排序：

1. 修复 `-isEmpty` 和 `-count`（两处单行更正），并删除死代码
   `readDataAtIndex:` / `writeData:` 对。行为安全：前两个是缺陷修复，
   第二个是带有类型缺陷的死代码。
2. 把 `MTArrayCached*` 常量移入一个两个文件都会导入的单一头文件。
3. 让 `MADArrayCachingEnumerator` 使用与 `MADArrayCaching` 相同的反归档器，并修复或
   移除它损坏的 `nextObject`。
4. 仅在剖析表明确实需要时：用更轻量、缓存专用的序列化器替换 `NSKeyedArchiver`，
   和/或在队列已被独占时把每次读取的 `dispatch_sync` 换成直接调用。这些是“真正快”的
   杠杆；上面的正确性事项优先。
