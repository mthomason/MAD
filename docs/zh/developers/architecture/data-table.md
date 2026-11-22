---
layout: default
title: "MADDataTable 架构"
description: "横跨各框架的数据表类簇及其解耦计划。"
lang: zh-CN
---

# MADDataTable——架构与解耦报告

本页是 `MADDataTable` 及 `MADFoundation`、`MAD`、`MADSqlite3`、`MADMySQL` 和 `MADTdsClient` 中每个实现的架构报告。它记录类簇与解耦工作。

*撰写于原定日期；当前状态事实已于 2026-11-22 核实。*

**范围：** `MADDataTable` 及横跨
`MADFoundation`、`MAD`、`MADSqlite3`、`MADMySQL` 和 `MADTdsClient` 的每个实现、子类、协议和调用点。
**分支：** `refactor/mad-database-decouple`
**日期：** 2026-10-01
**验证：** `xcodebuild test`——全部 11 个 scheme、809 个测试、0 个失败；范围内任何
文件无警告（`MADDatabaseMySQL.m` 中的两个 `-Warc-repeated-use-of-weak` 警告是
既有的、未触碰）。（Revision 2 时 798；Revision 3 时 804；Revision 4 时 807。）

以下所有 `file:line` 引用都是本次分析中第一手读取的，而非推断。

> **Revision 5——2026-10-01。** Phase 3 和 5 已关闭，Phase 1 step 7 已证明。
> `-dropTable`、`-dropTableName:`、`-deleteAll` 和 `-vacuumCacheDb` 现在让 `rowCounter`
> 描述文件（§2.5），这正是 step 10/11 的全部；有风险的三个常量
> 由四个新测试覆盖。用一个裸 `<MADDataTableWriting>`
> 遵循者驱动 sqlite 行循环——背后没有 `MADDataTable`、没有 `.maddb`——是 step 7，现在是测试
> （`MADWritePortRecorder`）。Step 14 已完成：`MADDataTableLocation` 已删除。Step 13 和 15
> 是评估而非完成，原因见其条目。
>
> 编写那些测试时发现了两个现网缺陷，现均已修复。`-deleteAll` 把一个
> *字符串*交给 `-[MADQueryCacheDeleteAllFromTable initWithObject:]`，后者把它作为
> 参数字典下标，并在第一行抛出——该方法没有调用者，这就是
> 从未有东西命中它的原因；它现在使用 `-initWithTableName:`。而 `MTTableController` 在其失败路径上把
> `datatable.count` 读作页面游标，而表仍持有上一页，因此失败的抓取报告 `hasMore = YES` 并永远重试。
>
> 计数器注释使 `MADDataTableFast.m` 从 `-deleteAll` 起移动了 13 行，因此该点之后的每个
> `file:line` 引用都是重新推导而非调整；`MTTableController.m`
> 也移动了，其引用随之重新推导。
>
> **Revision 4——2026-10-01。** Revision 3 的 MySQL 障碍已消失。`MADMySQLFetch+DataTable.m`
> 在抓取中途读取的列元数据现在由 `<MADDataTableWriting>`
> 自身声明，因此全部三个驱动——包括 `MADDatabaseMySQL`、`MADDatabase.m` 和
> `MADDatabaseDataSource` 协议——都采用 `id <MADDataTableWriting>`，且抓取的
> 出参改为按值传递（所有调用点丢掉 `&`）。Phase 2（“存储 `urlFastCache`；
> 注入缓存目录”）和 Phase 4 step 12（串行化写入管线）已完成，且
> Phase 3 仅对补水路径完成。§2.1 和 §2.3–§2.5 以及 §4.2 各自标注。新增三个测试；
> 套件从 804 → 807。由于修复使 `MADDataTableFast.m` 移动了 87 行，
> 本报告中对其的每个 `file:line` 引用都是重新推导而非调整，附录行数
> 也随刷新。
>
> **Revision——2026-09-30。** 初版被发现有三点错误后，§2.5、§3.3、§3.5 和 §4.2 被重写：
> `-dataForRow:error:` 的诊断（两行方法签名被误读——该方法*确实*在 `MADDataTableFast` 上实现）、
> `-allObjects` 的“现网缺陷”（无生产调用者）以及 `rowCounter` 漂移的框定（不可达）。
> §4.5 是新加的。更正后的文本标为 **Corrected** / **Fixed**；原始主张在有教益处
> 保留可见。本次修订落地三处代码修复——见 §3.5。
>
> **Revision 3——2026-10-01。** Phase 1 step 5 已落地：`<MADDataTableWriting>`、
> `<MADDataTableReading>` 和 `<MADDataTableCursoring>` 在 `MADDataTable.h` 中声明，且
> 类采纳全部三个。Step 6 对三个驱动中的两个落地——`MADDatabaseSQLServer` 和
> `MADDatabaseSqlite3` 现为写入端口类型。Step 6 **无法**对 `MADDatabaseMySQL` 落地，
> 且 step 5 的“删除现已冗余的存根块”被否决；§4.2 分别记录原因。
> 整个通过是增量的：无行为变化，且全部 11 个 scheme 通过（804 个测试）。
>
> **Revision 2——2026-09-30。** §4.5 的八处 `sqlite3_mprintf` 格式字符串
> 站点现已修复，且 Phase 0 已落地：`MADDataTable.m` 中未实现的操作改为断言
> 而非静默失败（§3.2、§4.2）。§3.1 表和附录行数针对变化文件重新推导。
> 上一修订的两处错误也更正：工作区测试总数曾写作 799，实为 798；
> §3.6 曾引用四处 `_database` 站点，实为十五处。

---

## 1. 当前架构与类层级

### 1.1 类家族

`MADDataTable` **不是**单个类——它是一个小型类簇，沿存储轴
分拆在三个框架中，外加一个以独立枚举器对象实现的游标轴。

```
MADFoundation
└── MADDataTable                          NSObject <NSCoding, NSFastEnumeration>
        │                                 "abstract": declares the full surface,
        │                                 implements metadata + plist persistence
        │
        ├── MADDataTableVirtual            MADFoundation/Source/MADDataTableVirtual.m (240 ln)
        │       In-memory. Rows live in per-column MADDataColumn arrays plus a
        │       `sortIndex` NSMutableArray of row NSDictionaries.
        │
        └── MADDataTableFast               MADSqlite3/Source/MADDataTableFast.m (1368 ln)
                sqlite3-backed. Rows live in a `.maddb` file; the object holds two
                MADDatabaseSqlite3 handles (one for writes, one for reads).

MADSqlite3 (private — NOT exported from the framework)
├── MADDataTableObjectEnumerator          173 ln — wraps a live sqlite3_stmt, yields row dicts
└── MADDataTableSingleColumnEnumerator    149 ln — same, yields a single column (row-ids)

MAD
└── MADDataTable+Constructor              the ONLY place that maps type -> concrete class
                                            (`MADDataTableLocation`, the other class here at
                                            Revision 4, was deleted — see §3.7)
```

已验证的导出面（来自构建出的 `.framework/Headers`）：

| 框架 | 公开导出的数据表头文件 |
|---|---|
| `MADFoundation` | `MADDataTable.h`、`MADDataTableType.h`、`MADDataTableVirtual.h` |
| `MADSqlite3` | **仅** `MADDataTableFast.h` |
| `MADMySQL` | 无 |
| `MADTdsClient` | 无 |

这种拆分是刻意且健康的：枚举器类名从不泄漏。消费者永远
只看到 `NSEnumerator *`，这正是 `MADDataTable.h` 所返回的。

### 1.2 两条正交轴，一个枚举

`MADDataTableType`（`MADFoundation/Source/MADDataTableType.h`）只编码**存储**轴：

```objc
typedef NS_ENUM(short, MADDataTableType) {
    MADDataTableTypeVirtual,    // -> MADDataTableVirtual
    MADDataTableTypePhysical,   // -> MADDataTableFast
};
```

**访问**轴——逐行 vs. 游标——是正交的，通过返回枚举器而非
类型来表达。没有 `MADDataTableTypeCursor`。这对
重构很重要：游标接缝已存在且被正确隐藏。

### 1.3 子类选择的唯一位置

`MAD/Source/MADDataTable+Constructor.m:51-69` 是代码库中唯一命名
具体子类的地方：

```objc
+ (instancetype)newDataTableOfType:(MADDataTableType)type withObjectID:(NSUInteger)objectID {
	switch (type) {
		case MADDataTableTypeVirtual:  result = [[MADDataTableVirtual alloc] initWithId:objectID]; break;
		case MADDataTableTypePhysical: result = [[MADDataTableFast alloc] initWithId:objectID];    break;
		default: NSAssert(NO, @"Not implemented."); break;
	}
	return result;
}
```

我确认代码库中任何地方对数据表都**没有** `isKindOfClass:`、`NSClassFromString`、类名字符串比较，
或 `respondsToSelector:` 探查。这是重构最有价值的
属性——类簇可以在这一个方法背后被重塑。

同一文件中的两个注意事项：

* `+newDataTableWithDefinition:` 调用 `NSAssert(NO, @"Not implemented.")` 并在
  没有对象 id 时返回 `nil`（`:44-46`）。`:31-32` 注释中“默认虚拟”的意图
  不可达——`objectIdSet` 门控唯一的返回路径。
* `+newDataTableForIdentifier:`（`:79-92`）是*事实上的*公开入口：大多数调用点
  （`MTTableController.m:90`、`MADQuerySampleDataTable.m:68`、`MADQuerySampleDataTableRange.m:69`）
  反而直接走 `newDataTableWithDefinition:`，且总是把类型固定为 Virtual。

### 1.4 写入契约

每个数据库驱动都通过**基类** API 填充表，绝不通过
子类特有的 API。`MADDatabaseSqlite3.m:474-540` 是规范循环：

```objc
[dataTable removeAllObjects];
// first row only:
[dataTable addColumn:dataColumn];       // per column, discovered from sqlite metadata
[dataTable beginBulkInsert];
// per row:
[dataTable addRowWithDataForFieldKeys:resultsForRow];
[dataTable endBulkInsert];
```

`MADDatabaseSQLServer.m:500 / :1367 / :1472` 使用同样的五调用形态。
`MADMySQLFetch+DataTable.m:211 / :438 / :442` 同样如此。

这是一个**狭窄、定义良好的写入端口**：五个方法。它是家族中最强的既有
边界，任何重构都应逐字保留。

驱动之间的分歧：

| 驱动 | 它构建的表 | 写入路径 |
|---|---|---|
| `MADDatabaseSqlite3` | 交给它的任何表（通常是 `MADDataTableFast`） | `executeSQL:...intoResultTable:` |
| `MADDatabaseMySQL` | **自己构造** `MADDataTableVirtual`（`MADDatabaseMySQL.m:83, 110, 137, 175, 196, 376`） | `MADMySQLFetch+DataTable.m` |
| `MADDatabaseSQLServer` | **从不构造**——纯写入调用方提供的表 | `MADDatabaseSQLServer.m` |

因此 MySQL 无法产出 `MADDataTableFast`，SQL Server 完全无法产出任何表。
“物理”（sqlite 支撑）存储只为本地缓存存在，不为远程结果。

### 1.5 读取契约

生产中使用三种不同的读取风格：

1. **随机访问**——`-objectAtRow:` / `-objectAtRow:column:`。
   `MADMySQL` 在 O(n) 循环中使用 `objectAtRow:i column:0`
   （`MADDatabaseMySQL.m:88-92, 118-122, 150-154, 187-189`）读取 `SHOW TABLES` 结果。
   `MADQuerySampleDataTable.m:126` / `MADQuerySampleDataTableRange.m:131` 调用 `objectAtRow:0`
   一次以读取宽度行。`MTTableController.m:281, 284, 393` 用 `objectAtRow:` 分页。

2. **枚举**——`-enumeratorForKeyObjectsSorted`。
   `MADocument.m:865-867` 把它作为 `enumeratorForReportData` 返回，由
   `MADReportFormatter.m:449-502` 消费。

3. **计数**——`-rowCounter` / `-count` / `-numberOfRows`。
   `MADocument.m:197`（`numberOfResults`）、`MTTableController.m:249`（表大小）和
   `:377, :399, :449, :455`（页面游标运算）。

`MADReportFormatter` 是最宽容的消费者，也是对
重构约束最少的。注意 `MADReportFormatter.m:463-472`：

```objc
if (!calculatedRowId) {
    if ([resultRow isKindOfClass:[NSDictionary class]]) { rowIdOnly = NO; }
    calculatedRowId = YES;
}
self.machineState.detailRowId = rowIdOnly
    ? ((NSNumber *)resultRow).unsignedIntegerValue
    : ((NSNumber *)resultRow[MADIdentifierROWID]).unsignedIntegerValue;
```

格式化器**已经容忍只产出裸行 id `NSNumber` 的枚举器**，也容忍
完整行字典。`enumeratorForAllObjectsSortedRowIdOnly` 正是为该情形而存在。
这是一个现成的接缝：只流式产出行 id 的游标已是可接受的输入。

---

## 2. 内存模型、生命周期与状态

### 2.1 ARC 与唯一一个原始 ivar

所有文件都是 ARC（`#if !__has_feature(objc_arc) #warning ...` 守卫）。状态位于类
扩展中。`MADDataTableFast` 恰好有一个非对象 ivar：

```objc
@implementation MADDataTableFast {
	sqlite3_stmt *_statementInsert;   // MADDataTableFast.m:103
}
```

它在 `-dealloc`（`:163-165`）和 `-endBulkInsert`（`:1334-1339`）中终结。该模式
正确但*曾*脆弱：`-endBulkInsert` 过去在取得
屏障**之前**把语句置空，使拆除位于唯一没有插入在飞的窗口之外。

**Fixed（Revision 4）。** 拆除现在在屏障内运行，见 `:1337-1338`。

### 2.2 一个文件上的两个 sqlite 连接

`-reopenDbConnection`（`:385-401`）构建**两个**独立的 `MADDatabaseSqlite3` 实例
指向同一 `.maddb` 文件：

```objc
// write handle
MADDatabaseConnection *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:urlFastCache];
MADDatabaseSqlite3 *database = [[MADDatabaseSqlite3 alloc] init];
database.delegate = (id <MADDatabaseResultsProtocol>)cacheDelegate;
database.databaseConnection = connection;
[(MADDatabaseSqlite3 *)database openDatabaseWithFlags:
     SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX];
self.databaseForInserts = database;

// read handle — same URL, separate connection, default flags
MADDatabaseConnection *connectionSelect = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:urlFastCache];
MADDatabaseSqlite3 *databaseSelect = [[MADDatabaseSqlite3 alloc] init];
[databaseSelect setDatabaseConnection:connectionSelect];
[databaseSelect openDatabase];
databaseSelect.delegate = (id <MADDatabaseResultsProtocol>)cacheDelegate;
self.databaseForSelects = databaseSelect;
```

读句柄以 **`-openDatabase`（默认标志）** 打开，写句柄以
`SQLITE_OPEN_FULLMUTEX` 打开。`SQLITE_OPEN_FULLMUTEX` 是**每连接**的串行化模式；
它不在同一文件上的两个连接之间仲裁。结合 §2.4，这是
家族中最大的单一正确性假设。

### 2.3 存储位置从环境全局状态解析

`-urlFastCache` 是一个*计算*属性（本修订前 `:299-311`），而非存储：

```objc
- (NSURL *)urlFastCache {
	NSString *filename = [[self filenameCacheMadDB] copy];
	NSURL *cacheDirectory;
	if (self.cacheDelegate == nil) {
		id <UIApplicationDelegate, MADApplicationProtocol> appDelegate = [MADApplication AppDelegate];
		id groupIdentifier = [appDelegate groupIdentifier].copy;
		cacheDirectory = [MADURLFactory newURLForLocalCacheDirectoryForGroupIdentifier:groupIdentifier];
	} else {
		cacheDirectory = [self.cacheDelegate cachedFilesDirectory].copy;
	}
	return [cacheDirectory URLByAppendingPathComponent:filename isDirectory:NO];
}
```

后果：

* 没有 `cacheDelegate` 的表**静默依赖全局应用委托**来确定其
  磁盘身份。这就是为什么 `MADDataTableFast` 无法在无宿主的逻辑
  测试中没有委托地实例化——回归套件用符合
  `MADCacheProtocol` + `MADDatabaseResultsProtocol` 的存根绕过它。
* `-setCacheDelegate:`（`:377-383`）调用 `-reopenDbConnection`。换一个
  委托**把表重新指向不同文件**，同时在内存中保留 `tag`/`rowCounter`/
  `columnKeys`。没有东西检测这一不匹配。
* `-copyPlist` 断言 `urlFastCache != nil`（`:243`）——因此归档表所持久化的 URL
  取决于归档时的环境状态。

**Fixed（Revision 4）。** `-urlFastCache` 现在解析一次并持有答案
（`_urlFastCache`，`:347-355`，由 getter 和 `-setCacheDelegate:` 在 `:377-383` 写入，
后者在重开前丢弃它）。`-newUrlFastCache`（`:357-373`）保留解析本身，
带一个新的首选：初始化时提供的缓存目录。`MADDataTableFast` 获得
`-initWithId:cacheDirectory:`（`:173-181`），
`+[MADDataTable newDataTableOfType:withObjectID:cacheDirectory:]` 透传它（`nil` 保持
旧行为），且它立即打开连接，使表无需委托和应用即可使用。
上述委托交换重新指向仍会发生——那是“URL 由委托派生”的预期
解读——但它不再取决于*何时*首次读取该属性。

`tag`（由 `initWithId:fromCache:` 设置，`:190`）是唯一稳定身份；它既产生
表名（`t<tag>`，`:403-409`）也产生文件名（`<tag>.maddb`，`:340-343`）。

### 2.4 线程安全：无锁，一个队列

我用 grep 在整个家族中查找 `dispatch_sync`、`dispatch_async`、`@synchronized`、`NSLock`、
`os_unfair_lock` 和 `pthread_mutex`。存在的**唯一**并发原语是
`queueBulkAdd`：

* 创建三次——`initWithId:fromCache:`（`:186`）、`initWithCoder:`（`:202`）
  和 `beginBulkInsert`（`:1322`）——每次 `dispatch_queue_create(..., SERIAL)`。
* 恰好用于**两处**：`-endBulkInsert`（`:1334`）用
  `dispatch_barrier_sync` 包住委托调用，且（自 Revision 4 起）`-addRow:error:` 以
  `dispatch_sync` 进入它。
* Revision 4 之前，它**从未**用于串行化 `-addRow:error:`。

因此 `-addRow:`——变更入口——*曾*完全不受队列保护。在
`_bulkInsertLoop` 下，`-addRow:` 跨调用复用单个缓存的 `_statementInsert`
（`:529-611`）：`sqlite3_bind_*` → `sqlite3_step` → `sqlite3_clear_bindings` →
`sqlite3_reset`，无互斥。两个线程并发进入 `-addRow:` 会在
该共享语句上竞争，无论 `SQLITE_OPEN_FULLMUTEX`，因为竞争在
bind/step/clear/reset 的*序列*中，而非任何单个 sqlite 调用内部。

回归套件记录当前并发行为但无法使其安全——
必须添加串行化。

**Fixed（Revision 4）。** `-addRow:error:`（`:504-528`）现在是一个薄包装，在
`dispatch_sync(queueBulkAdd)` 下运行插入主体
（`:529` 的 `-insertRow:error:`，旧方法改名），仅在队列为 nil 时回退
到直接调用——这只会发生在从未完成初始化的表上。`-endBulkInsert` 的
`sqlite3_finalize(_statementInsert)` 移到其 `dispatch_barrier_sync` *内部*，
使缓存语句只在没有插入在飞时拆除。在串行队列上
屏障和 `dispatch_sync` 互斥，这正是
bind/step/clear/reset 序列所需的全部互斥。两个测试锁定它：
`testFastTableConcurrentWritersLoseNoRows`（新）从*并发*队列驱动四个写入者；
`testFastTableSerializedConcurrentWritesLoseNoRows` 保留应用的串行队列模式，且其
“the table does not serialize internally”契约注释已更正。Step 13（每文件一对连接）
未动。

### 2.5 `rowCounter` 是独立计数器，不是派生值

`-insertRow:error:` 递增 `rowCounter`（`:532`）且**从不查询 sqlite**。
`-numberOfRows` / `-count` 直接返回它（`:1222` / `:1216`），且 `-removeAllObjects` 把它清零
（`:683`）。但 `-dropTable`（`:799`）、`-dropTableName:`（`:804`）、`-deleteAll`（`:818`）和
`-vacuumCacheDb`（`:789`）在 Revision 5 之前**没有**触碰它。

因此两个真相来源可能分歧：

* `rowCounter` 说 N；`.maddb` 文件持有不同数量的行。
* 在一次 `-loadFromCacheWithUrl:` 往返中，计数器来自 plist
  （`MADDataTable.m:305-306`）而行来自 sqlite 文件——它们由
  两个不相关的机制补水。

**Fixed（Revision 4）——重载那一半。** `-loadWithPlist:` 现在以
`self.rowCounter = [self recountRows];`（`:313`）结尾，其中 `-recountRows`（`:317-338`）向
缓存文件询问 `SELECT COUNT(*)`，仅在表尚不存在时回退到 plist 的值。
被内存路径膨胀的计数器不再能在重载后存活。
`testFastTableReloadRecountsRowsFromCacheFile` 通过加载一个计数器说
99 的 plist、覆盖一个持有 3 行的文件来锁定这一点。

**Fixed（Revision 5）——内存那一半，即 step 10/11。** `-dropTable`（`:799`）和
`-dropTableName:`（`:804`）现在清零计数器，`-deleteAll`（`:818`）清零它，且
`-vacuumCacheDb`（`:789`）刻意不清零，因为 VACUUM 保留每一行——源码
带有一处注释说明这一点，因为“为什么这一个*不*重置它”正是
下一个读者会有的问题。`-dropTableName:` 接受任意名称，因此它只在
消失的表是这一张时才清零计数器；删除外来表不得触碰本
计数。`-numberOfRows`（`:1222`）和 `-count`（`:1216`）仍返回 ivar 而非
查询文件，这正是要点——`-recountRows` 是重载路径的检查，不是
每次读取的成本。

`-removeAllObjects`（`:674`）隐藏了整个隐患，且仍然如此：它是全部
四者的唯一调用者，且自身清零计数器（`:683`）。这正是为什么这值得关闭
而非留下——隐患离现网只有一个调用者之遥，`-count` 对应用是页面游标
（§4.3），且四个私有方法离被从某处新调用只有一个 `git log -S`。此处 Revision-4 的注释曾把漂移称为
“real in the code, but no caller can reach it today”；调用者审计仍然成立——
`-deleteAll` 在仓库中**任何地方都没有调用者**，且 `-dropTable` 只从
`-removeAllObjects` 到达——但计数器现在在每条路径上都正确，
而非仅因其唯一调用者碰巧事后整理。
`MADDataTableRegressionTests.m` 中四个测试直接驱动四者之一。

`MADDataTableVirtual` 形态相同（`:179`、`:193`、`:225`）但其计数器与
`sortIndex` 一起变更，因此按构造一致。

这是类簇重构下风险最大的状态：`MTTableController.m` 在
`:377` 和 `:399` 读取 `datatable.count`，并在
`:455` 由此推导 `hasMore = (count == limit)`，因此漂移的计数器会破坏分页。Revision 5 也
使该推导完备——空页面不再把 `offset + count - 1` 回绕到 `NSUIntegerMax`
（`:380`、`:402`），且失败路径返回 `completion(NO)`（`:449`）而非读取仍描述
*上一*页的计数。

编写那些测试发现 `-deleteAll` 中一个与计数器无关的缺陷：
它把一个 `NSString` 传给 `-[MADQueryCacheDeleteAllFromTable initWithObject:]`，后者
把其参数作为参数字典下标，因此在第一行抛出
`unrecognized selector`。`-initWithTableName:` 是接受名称的初始化器，也是
`MADDatabaseSqlite3 -beginBulkInsert` 已经使用的那个。没有调用者曾命中它，因为没有
调用者。

### 2.6 两个不相关的持久化机制

| 机制 | 位置 | 存储 |
|---|---|---|
| Plist，`NSPropertyListBinaryFormat_v1_0` | `MADDataTable.m:193-220`、`:135-191` | `name`、`columnKeys`、`columns`（元数据）、`rowCounter`。**无行。** |
| sqlite `.maddb` 文件 | `MADDataTableFast.m` | 实际行数据，加上 `MADDataTableFast` 特有的键（`urlFastCache`、`tag`、`bulkInsertLoop`、`sortDescriptorsSet`、`groupKeyIndexes`） |

基类中的 `-cacheWithUrl:error:` 被文档化为通用缓存，但只
序列化*形状*，从不序列化*内容*。`MADocument.m:413-414` 从
`[self.dataTable newFilenameMDCache]`（`<tag>.mdcache`）推导 `urlDataTableCache`，而 `MADDataTableFast`
读写 `<tag>.maddb`（`:340-343`）。两个扩展名、两种格式、两个所有者、一张逻辑
表。

**Evaluated（Revision 5）——step 15，它要求调和。框定是错的，这就是发现。**
“基础 plist 仅元数据”对基类为真，对
家族为假：每个子类用恰好一个额外键扩展 `-copyPlist` / `-loadWithPlist:`，
而该键*就是*其存储。

| 类 | 存储 | 承载它的 plist 键 |
|---|---|---|
| `MADDataTable` | 无（抽象） | `name`、`columnKeys`、`columns`、`rowCounter` |
| `MADDataTableVirtual` | `sortIndex`，一个行字典数组（`MADDataTableVirtual.m:106-109`、`:89-104`） | `keySortIndex`——行本身 |
| `MADDataTableFast` | `.maddb` 文件 | `keyUrlFastCache`、`keyTag`、……——行的*定位器* |

因此行在 plist 即存储处已通过 plist 往返，在存储是 sqlite 文件处
则不能。重命名（“叫它元数据”）与替代（“把行放进去”）对整个家族
都不对；基类是*两个*子类共享的元数据，机制按设计
按子类。两个扩展也不冲突：`MADocument` 把 `<tag>.mdcache`（plist）写在
`<tag>.maddb`（行）旁，且 `-loadFromCacheWithUrl:` 读前者以找到后者——
前提 tag 一致，而它确实一致，因为 `-filename`（`MADocument.m:1397-1399`）是 `fileURL.lastPathComponent`
的 `stringByDeletingPathExtension`，与初始化哈希为 tag 的字符串相同。

值得做、但此处未做的是文档化而非重构：按其实质命名
`MADocument` 缓存目录中的两个文件，并在 `MADDataTable.h` 中说明
`-copyPlist` 返回共享元数据，且有自己存储的子类必须扩展
它。那是无行为需要保留的注释改动，因此属于文档梳理，而非此处。

### 2.7 枚举器生命周期

`MADDataTableObjectEnumerator` 持有自己的 `MADDatabaseSqlite3` + 连接 + 预编译
语句，全部在 `-initWith...`（`:60-72`）中构建并在 `-dealloc`（`:45-49`）中释放。
因此：

* 枚举器在其被保留期间保持数据库句柄和文件描述符存活
  ——且 `MADReportFormatter.m:449-502` 在整个报表渲染期间持有其一。
* 任何丢弃或重建表的变更（`-removeAllObjects`、`-dropTable`）
  会使未完成枚举器中的活动语句失效。没有东西守卫这一点。
* 每次 `-objectEnumerator` / `-enumeratorFor...` 调用都分配一个到同一文件的
  **新连接**（`:1139`、`:1158`、`:1186`、`:1202`）。枚举两次就打开 sqlite 两次。

**Evaluated（Revision 5）——step 13，它要求每文件一对共享连接。未做，原因在
生命周期，而非数量。** 插入连接完全无法共享：`MADDatabaseSqlite3 -endBulkInsert`
以关闭它并把 `_database` 置空收尾
（`:794-795`），这就是为什么 `MADDataTableFast -removeAllObjects` 在丢弃任何东西前重开，
以及为什么四个私有变更在被直接驱动时断言（它们直接驱动是不对的——见 Revision 5 测试，正因此先在测试中重开）。
因此共享的“一对”必须是共享的*读*连接加每周期写连接，
这省一个句柄，不是两个。

而且节省比看起来小：这里的每个连接都打开
`SQLITE_OPEN_SHAREDCACHE`（`MADDatabaseSqlite3.m:220`），因此枚举器已在文件间共享一个
页缓存和一组锁。每次枚举的实际成本是一个
`sqlite3*` 和一个文件描述符——真实，但不是该步骤所暗示的重复缓存成本。

与此相对，共享读连接会*失去*一些东西。枚举器在整个报表渲染期间被持有
（`MADReportFormatter.m:449-502`），且 `-removeAllObjects` 在它们下面丢弃并
重建表；今天未完成的枚举器拥有其语句和
句柄，因此两者只通过文件干扰。给它们一个共享句柄会
把该交互放进单个连接内，而该类的读取自身不携带锁。
要设计的场景正是 §2.7 已标记的——活动枚举器跨表
重建——而共享连接使它更糟，而非更好。刻意保持原样。

---

## 3. 公开 API 与泄漏的抽象

### 3.1 声明面与实际实现

`MADDataTable.h` 声明 30 个方法（加上 `name` / `columnKeys` / `sortDescriptors` /
`columns` / `rowCounter` / `tag` 属性，其中两个被写入协议重新声明——
见 §4.2）。基类实现其中 18 个，存根 12 个：

| 在 `MADDataTable.h` 中声明 | 基类实现（`MADDataTable.m`） | Virtual | Fast |
|---|---|---|---|
| `-addColumn:` | **断言** `:365` | 重写 `:112` | 重写 `:431` |
| `-addRow:error:` | **断言** `:369` | 重写 `:179` | 重写 `:504` |
| `-addRowWithDataForFieldKeys:` | **断言** `:374` | 重写 `:197` | 重写 `:614` |
| `-sortUsingDescriptors:` | **断言** `:378` | 重写 `:208` | 重写 `:634` |
| `-removeAllObjects` | **断言** `:382` | 重写 `:225` | 重写 `:674` |
| `-objectAtRow:column:` | **断言** `:386` | 重写 `:159` | 重写 `:834` |
| `-objectAtRow:` | **断言** `:391` | 重写 `:151` | 重写 `:848` |
| `-columnsEnumerator` | **断言** `:396` | 重写 `:149` | 重写 `:1123` |
| `-objectEnumerator` | **断言** `:401` | 重写 `:148` | 重写 `:1127` |
| `-beginBulkInsert` / `-endBulkInsert` | 空操作 `:408-409` | 空操作 `:236-238` | 重写 `:1311`/`:1330` |
| `-allObjects` | `return @[]` `:414-417` | 重写 `:118` | 重写 `:1209` |
| `-objectAtRow:limit:` | `return @[]` `:419` | 重写 `:220` | 重写 `:1086` |
| `-count` / `-numberOfColumns` / `-numberOfRows` | `0` `:420-422` | 重写 `:122`、`:214`、`:216` | 重写 `:1216`、`:1220`、`:1222` |
| `-countByEnumeratingWithState:...` | `0` `:423-427` | 重写 `:140` | 继承（0） |
| `-enumeratorForAllObjectsSorted*`、`-objectsForGroupKeys:`、`-dataForRow:error:`、`-enumeratorForKeyObjectsSorted` | `NSAssert(NO, @"Not implemented")` `:327-350` | **也** `NSAssert(NO)` `:31-54` | 实现 `:1034`、`:1148`、`:1172`、`:1193`；`-dataForRow:error:` `:941` |

### 3.2 泄漏 1——基类无法表达“抽象”

Objective-C 没有 `abstract`。因此基类过去从 `-addRow:error:` 返回 **`YES`**，从每个读取器返回
**`nil`**。部分实现的子类，或直接的 `MADDataTable`
实例，会静默接受写入并报告成功，然后读回空。

**Fixed（Phase 0）。** 存储子类必须重写的九个写入/读取操作现在
以 `NSAssert(NO, @"%s must be overridden", __PRETTY_FUNCTION__)` 开头（`MADDataTable.m:365`、
`:369`、`:374`、`:378`、`:382`、`:386`、`:391`、`:396`、`:401`），与 `:327-350` 组一致。
`-addRow:error:` 在 Release 中返回 `false` 而非 `true`，因此即使断言被编译掉
它也不再声称存入了行。

两组被刻意**保留**为静默默认，因为对它们而言静默是正确的：

* `-beginBulkInsert` / `-endBulkInsert`（`:408-409`）——可选钩子。不需要批量模式的子类
  可以合法继承空操作。
* `-allObjects`（`:414-417`）、`-objectAtRow:limit:`（`:419`）、`-count` / `-numberOfColumns` /
  `-numberOfRows`（`:420-422`）和 `-countByEnumeratingWithState:...`（`:423-427`）——它们
  返回 `@[]` / `0`，这是无行表的*真实*答案，且与
  `MADDataTableVirtual` 返回的一致。对 `-count` 断言会把正确回答变成崩溃。

本泄漏的另一半——在类型系统中而非通过断言表达拆分——是 Phase 1（§4.2）。

### 3.3 泄漏 2——已经破裂的可空性契约

`MADDataTable.h:65` 声明（在 `@protocol MADDataTableCursoring` 内）：

```objc
- (nonnull NSArray *)allObjects;
```

`MADDataTableFast.m` 过去这样回答它（本修订前 `:1093-1096`）：

```objc
- (NSArray *)allObjects {
	// FIXME: Implement this.
	return nil;
}
```

一个声明为 `nonnull` 的方法在一个子类上返回 `nil`，在另外两个上返回 `@[]` / `[self.sortIndex copy]`。
任何信任该注解的调用者都会崩溃——它是家族中唯一与头文件契约矛盾的 `FIXME`。

**Corrected：** 没有生产调用者。对数据表的 `-allObjects` 唯一发送
都在本回归套件中，且 `MADDataTableRegressionTests.m` 刻意在
`testFastTableBulkInsertAllObjectsIsUnimplemented` 中锁定 `nil`。所以注解是为未来调用者设下的陷阱，
而非现网崩溃。

**Fixed：** `MADDataTableFast -allObjects`（`:1209-1214`）现在通过
`-objectAtRow:0 limit:numberOfRows` 返回每一行，对无列的表返回 `@[]`，匹配
`nonnull` 声明和 `MADDataTableVirtual` 的既有行为（`:118-120`）。锁定 `nil` 的测试
被两个断言真实契约的测试替换。

### 3.4 泄漏 3——`-objectAtRow:column:` 对每个子类含义不同

两个实现既在 `row` 的含义上不同，也在所查询的存储上不同：

```objc
// MADDataTableVirtual.m:159-163 — reads the per-column store, applies the sort index
- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column {
	NSString *fieldKey = self.columnKeys[column];
	MADDataColumn *dataInColumn = self.columns[fieldKey];
	return [dataInColumn objectAtIndex:[self sortedIndexForIndex:row]];   // LOGICAL row
}
```

```objc
// MADDataTableFast.m:834-846 — reads the row dictionary, physical order
- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column {
	NSDictionary *objForRow = [self objectAtRow:row];
	if (objForRow == nil || column >= self.columnKeys.count) return nil;
	NSString *key = self.columnKeys[column];
	MADDataColumn *columnMetaData = self.columns[key];
	if (columnMetaData == nil) return nil;
	return objForRow[columnMetaData.identifier];      // PHYSICAL (sqlite) order
}
```

还要注意边界纪律不同：Virtual 对 `column` **不做**边界检查
（`self.columnKeys[column]` 在越界时会抛 `NSRangeException`，只在
`-objectAtRow:` 中的 `@try` 捕获，不在此处），且对 `dataInColumn` 不做 nil 检查；Fast 二者都做。

同一选择器，两套语义。`MADMySQL` 在紧循环中调用它
（`MADDatabaseMySQL.m:88-92` 及另外三处），因此统一语义的重构会
首先被 MySQL 感受到。

### 3.5 泄漏 4——`-dataForRow:error:` 在一个子类上实现，在另一个上缺失

**本节在本报告初版中是错的。** 它声称
`MADDataTableFast` 不实现 `-dataForRow:error:`，因此条形码/打印路径
命中基类的 `NSAssert(NO)`。那是假的，它把一位读者引向
错误路径。更正后的分析如下。

`MADDataTable.h:67` 声明
`- (nullable NSDictionary<NSString *, id> *)dataForRow:(NSUInteger)rowID error:(NSError **)error;`
且基类实现为 `NSAssert(NO, @"Not implemented: %s")` + `return nil`
（`MADDataTable.m:342-345`）。

* **`MADDataTableFast` 确实实现它**，见 `MADDataTableFast.m:941-1015`：

  ```objc
  - (NSDictionary <NSString *, MADResult *> *)dataForRow:(NSUInteger)cacheId
                                                   error:(NSError * __autoreleasing *)outError {
  ```

  这是两行签名，正是早先修订误读之处：选择器换行
  到第二行，而第二行被当成了单独的 `-dataForRow:column:`
  重载。（真正的 `-dataForRow:column:error:` 是 `:866-932` 的另一个方法。）该
  实现是真实的，且回归套件已覆盖它——
  `MADDataTableRegressionTests.m` 的 `testFastTableDataForRowReturnsValues` 和
  `testFastTableDataForRowCachesLastRow` 都把双参数选择器发给活动的
  `MADDataTableFast` 并通过。

* **`MADDataTableVirtual` 两种形式都不实现。** 它在
  `:41-44` 有一个 `-dataForRow:` 存根，但该存根是 `NSAssert(NO, @"Not implemented: %s")` + `return nil`——
  它不是可工作的重载，也未在 `MADDataTableVirtual.h` 中声明。双参数
  形式落到断言的基类。因此内存子类完全没有按 id 的行访问。

因此调用点并不危险：`MADocument.m:875/880/919` 分派到
`MADocument.dataTable`，后者在静态和实际上都是 `MADDataTableFast`
（`MADocument.m:159`，在 `:230` 和 `:288` 分配）。`MADPrintPageElement.m:80` 和
`MADPrintPageElementBarcode.m:30` 路径到达同一对象。活动路径上没有东西
断言。

真正的缺陷更窄且现已修复：因为 `MADDataTableVirtual` 从未
实现该选择器，任何未来持有 `MADDataTable *` 且恰为
Virtual 表的调用者会在 Debug 中断言，在 Release 中静默得到 `nil`。
`MADDataTableVirtual` 现在通过委托给 `-objectAtRow:` 并
通过错误指针报告越界情形来实现 `-dataForRow:error:`。

`MADDataTableFast` 的实现也有一个真实缺陷，现已修复：其
`if (sqlite3_prepare == SQLITE_OK)` **没有 `else`**，因此 prepare 失败返回 `nil`
而未设置 `*outError`，且 `-getSql:` 错误被丢弃。其兄弟
`-dataForRow:column:error:`（`:905-932`）正确处理两者。SQL 也曾被传给
`sqlite3_mprintf` 作为*格式*字符串（`sqlite3_mprintf((char *) sql.UTF8String)`），会在含 `%` 的 SQL 上
弄坏或崩溃；现在是 `sqlite3_mprintf("%s", ...)`，匹配
`:901` 的兄弟。`MADSqlite3` 中另外八处站点有同样缺陷；现均已
修复——见 §4.5。

### 3.6 泄漏 5——`MADDataTableFast` 深入另一个类的私有 ivar

`MADDataTableFast.m` 在十五处直接访问 `MADDatabaseSqlite3` 的私有 ivar `_database`
——`:488`、`:538`、`:784`、`:793`、`:810`、`:829`（经 `_databaseForInserts`）
以及 `:905`、`:976`、`:1065`、`:1078`、`:1106`、`:1108`、`:1248`、`:1251`、`:1261`（经
`databaseForSelects`）：

```objc
sqlite3 *sqlite_database = _databaseForInserts->_database;                       // :451
NSAssert(prepareResult == SQLITE_OK, @"%s", sqlite3_errmsg(databaseForSelects->_database)); // :1008
```

这完全绕过了 `MADDatabaseSqlite3` 的 API，也是 `MADDataTableFast` 需要
真实 sqlite 文件才能做任何事的原因。这也是测试目标需要
`MADDataTable+Constructor` 模块导入工作的原因：类家族只能从同时
链接两个框架的代码使用。

### 3.7 泄漏 6——死掉的公开 API——**已移除（Revision 5）**

`MADDataTableLocation`（`MAD/Source/MADDataTableLocation.{h,m}`，67 行）是一个
`(row, column)` 值对象，带 `NSCoding` 和 `+newDataTableLocationForRow:inColumn:`
工厂。我 grep 了整个代码库（排除其自身实现）：**它唯一的引用
都在回归测试文件中。** 它在生产中是死的。它还采纳了 `NSCoding` 但不
`NSSecureCoding`，回归套件将其记录为契约。

Phase 5 step 14 提供了一个选择——把它接进功能或删除它。它被删除，因为
没有功能在等它：其全部历史只有一个提交（`e702bb062`，
`MAD` 框架重组）、没有调用者，除了它自己的三个测试外没有任何东西说明它
为何存在。只因测试而存活的类是测试在为其双倍付费。
文件、它们两个 `.pbxproj` 构建条目和三个测试随之消失；§3.7 保留
为泄漏 6 而非重新编号，使报告其余部分引用的编号成立。

### 3.8 泄漏 7——表*反向*伸入写入查询

`MADDataTableFast` 私有遵循四个协议
（`:71`）：

```objc
@interface MADDataTableFast () <MADQueryParametersStandardProtocol,
                                MADQueryParametersColumnKeysProtocol,
                                MADQueryParametersColumnMetaProtocol,
                                MADQueryParametersColumnDataProtocol>
```

并实现 `-queryTableName` / `-queryColumnKeys` / `-queryColumns` / `-queryRowData`
（`:419-430`），纯粹为了让 `MADQueryCacheAddRow` 能从它正在写入的表
拉回状态。因此插入路径是一个循环：表 → 查询对象 → 回到表。注意
名称冲突风险——`-queryRowData`（`:428`）和私有 `_rowDataLastInserted` 属性
与公开的 `-dataForRow:` 家族无关。

### 3.9 哪些*不*泄漏（保留这些）

* 所有子类选择都在 `MADDataTable+Constructor.m:51-69`。
* 写入端口是五个基类方法（§1.4）。
* 枚举器类对 `MADSqlite3` 私有，且只以 `NSEnumerator *` 出现。
* `MADReportFormatter.m:463-472` 已容忍仅行 id 枚举。
* `MADArrayCaching`（`MADSqlite3`）是本代码库中更窄、协议形态表面的缓存
  抽象的先行者。
* 任何地方都没有对表的运行时类嗅探。

---

## 4. 解耦与重构策略

目标是让 `MADDataTable` 成为可换存储与访问策略之上的*稳定接口*，
而不改变五个驱动和四个消费者已依赖的行为。

### 4.1 目标形态

保留类名（它们已烙进 `NSCoding` 归档和 Core Data），但把
变化移到构造器返回的两个协议之后：

```
                    ┌─────────────────────────────────────┐
                    │  MADDataTable        (concrete base) │
                    │  metadata, plist persistence,        │
                    │  NSCoding, — no-op defaults removed   │
                    └──────────────┬──────────────────────┘
                                   │
        ┌──────────────────────────┴───────────────────────────┐
        │                                                       │
  MADDataTableVirtual                                   MADDataTableFast
  (unchanged semantics)                          (sqlite; owns a connection pair)

  Both conform to:
     <MADDataTableWriting>   removeAllObjects / addColumn: /
                             begin|endBulkInsert /
                             addRowWithDataForFieldKeys:
     <MADDataTableReading>   objectAtRow: / objectAtRow:column: /
                             count / numberOfRows
     <MADDataTableCursoring> enumeratorForKeyObjectsSorted /
                             enumeratorForAllObjectsSorted /
                             enumeratorForAllObjectsSortedRowIdOnly
```

`MADDatabaseSqlite3.m:474-540` 和 `MADDatabaseSQLServer.m:500-1472` 应接受
`id <MADDataTableWriting>` 而非 `MADDataTable *`。仅此就从每个驱动移除“基类
从我丢弃的写入返回 YES”的隐患。

### 4.2 分序计划

**Phase 0——让失败模式大声（无行为变化）。**
1. **完成**，范围比最初提议更窄。存储
   子类必须重写的九个操作现在断言（`MADDataTable.m:365-403`）；诚实的空表
   回答和可选批量钩子保留为默认，因为对它们而言静默值就是*正确*的。拆分与理由见 §3.2，以及
   `MADDataTableRegressionTests.m` 的 `testBaseTableAbstractOperationsAssert` 为契约。
2. **不需要——见 §3.5。** 此处原文说实现
   `MADDataTableFast -dataForRow:error:`，因为它“currently asserts”。它没有；该方法
   在 `:941-1015` 实现，早先读取把两行签名误认为 `column:` 重载。真正缺失该选择器的子类是
   `MADDataTableVirtual`，它现在通过委托给 `-objectAtRow:` 实现它。
3. **完成。** `-allObjects`（§3.3）曾是一个在
   `MADDataTableFast` 上返回 `nil` 的 `nonnull` 方法；它现在返回行。同一次通过中
   `MADDataTableFast -dataForRow:error:` 在其 prepare 检查上获得缺失的 `else`，且
   不再丢弃 `-getSql:` 错误，也不再把 SQL 作格式字符串传给 `sqlite3_mprintf`。
4. 针对既有回归套件（`MADDataTableRegressionTests.m`）重新验证——它
   已锁定实例化、枚举和并发，因此会检测此处的错误。
   （它还在 Revision 5 删除该类之前锁定 `MADDataTableLocation` 契约。）

**Phase 1——声明协议。**

5. **完成——存根块被刻意保留。** 三个协议声明在
   `MADFoundation/Source/MADDataTable.h` 中 `@interface` 之上，后者现在读作
   `MADDataTable : NSObject <NSCoding, NSFastEnumeration, MADDataTableWriting,
   MADDataTableReading, MADDataTableCursoring>`，且过去坐在 `@interface` 主体中的三十个扁平方法声明
   已从中消失。按轴拆分：**Writing** 是可变表面（`removeAllObjects`、`addColumn:`、`addRow:error:`、
   `addRowWithDataForFieldKeys:`、`sortUsingDescriptors:`，加上 `@optional`
   `beginBulkInsert`/`endBulkInsert`）；**Reading** 是随机访问和计数；
   **Cursoring** 是枚举，三个排序枚举器和
   `objectsForGroupKeys:` 为 `@optional`，因为 `MADDataTableVirtual` 确实无法提供
   它们。

   计划的“删除现已冗余的存根块”**未**执行，因为两个
   存根块是锁定的契约，而非冗余：
   `testBaseTableAbstractOperationsAssert` 要求九个基类断言存根
   存在并抛出，而 `testVirtualTableDoesNotImplementSortedEnumerators` 断言
   四个仅 sqlite 选择器在 `MADDataTableVirtual` 上的 `-respondsToSelector:` 为 **YES**。删除任一个都会把已捕获的缺陷变成
   无法识别的选择器崩溃，并破坏一个正为此存在而有的测试。
   `MADDataTable` 通过断言满足协议的 `@required` 成员，这正是
   Phase 0 放在那里的。

6. **完成（Revision 4）——全部三个驱动和协议。** 下面的块是 Revision 3
   关于为何受阻的记述；保留作记录。它所识别的解除被采纳：
   `MADMySQLFetch+DataTable.m` 所需的列元数据（`columns`、`columnKeys`）现在由
   `<MADDataTableWriting>` 自身声明，因此写入端口对 MySQL 也足够。
   `MADMySQLFetch` 的两个 `fetchWithCommand:dataTable:...` 方法及其私有
   `-fetchResultsFromConnection:intoDataTable:...` 按值接受 `id <MADDataTableWriting>` 并
   返回同一表（`(MADDataTable *)dataTable`）；`MADDatabaseMySQL.m` 中全部 11 个调用点和
   `MADMySQLLiveTests.m` 中 7 个调用点丢掉了 `&`。元数据被
   放在写入协议而非第四个协议上，因为 MySQL *在写入时*读取它——
   它在第一行时修正列的类型——也因为每个遵循者都能从基类免费获得它。
   §2.5 的 `// FIXME: This is a hack.` 未动。

   *Revision 3 文本，作记录：* **部分完成——三个驱动中的两个，且协议
   声明刻意不缩小。** `MADDatabaseSqlite3`
   （`executeSQL:...intoResultTable:`、
   `executeQuery:withDataTable:andError:`、`executeQuery:withError:`）和
   `MADDatabaseSQLServer`（同样的两个，加上私有 `-runQuery:onProcess:withDataTable:`
   和 `-runSQL:onDataTable:fieldKeys:process:`）现在接受 `id <MADDataTableWriting>`。两者都
   真正只写：`grep` 它们向表发送什么，恰好返回五调用端口，
   别无其他。
   
   **`MADDatabaseMySQL` 尚不能缩小**，`MADAPI/Source/MADDatabaseProtocol.h:28-31` 也不能。
   障碍不在驱动——而在 `MADMySQLFetch+DataTable.m`，它在*填充表时*
   读取 `(*dataTable).columns` 和 `.columnKeys`，以在看到第一行时修正列的类型
   （`:301` 和 `:321`，在 `:297` 既有的 `// FIXME: This is a hack.` 下）。因此不暴露列元数据的写入端口
   对该路径不够。由于 `MADDatabaseMySQL` 遵循
   `MADDatabaseDataSource` 且必须继续，缩小
   协议会使其承诺其自身实现无法兑现的东西——
   对下一个调用者是远程崩溃，而非编译错误。两个声明都带指向此处的注释。
   
   **检查时发现的具体解除：** `MADMySQLFetch+DataTable.m` 从不
   通过其 `MADDataTable * __autoreleasing *` 出参赋值——
   `grep -n '\*dataTable *=' MADMySQL/Source/MADMySQLFetch+DataTable.m` 返回空。该
   指针是调用方从未被告知的入参。使其按值
   （`dataTable:(id <MADDataTableWriting>)dataTable`）直接移除指针类型问题，
   并让 `MADDatabaseMySQL.m` 中 11 个调用点丢掉 `&`。那，加上
   把列元数据访问器加入 `<MADDataTableWriting>` 或第四个协议，
   就是 MySQL 剩余的全部。它被推迟而非打包，因为
   §4.3 已把 MySQL 列为风险最高的消费者，且该改动足够机械，
   可以单独评审。

7. **现在对 sqlite 可能，对 MySQL 未证明。** `MADDatabaseSqlite3` 的行循环可以
   由任何遵循 `<MADDataTableWriting>` 的对象驱动，无需 `.maddb` 文件、无需
   应用委托，因为参数不再隐含 `MADDataTable` 类——并通过它，隐含
   §2.3 描述的 `-urlFastCache` 对 `[MADApplication AppDelegate]` 的依赖。尚未编写这样的 mock 测试；它是自然的下一步，也是 Phase 2 注入缓存目录
   使之更便宜的第一件事。
   **Revision 4：** 无宿主那一半已证明——`testFastTableInitWithCacheDirectoryNeedsNoDelegate`
   用目录且无委托构建一个可工作的物理表。
   **Revision 5：完成，两半。** `testDriverFillsAWritePortWithNoDataTableBehindIt`
   （`MADSqlite3Tests/MADDatabaseSqlite3DatabaseTests.m`）把行循环交给一个
   `MADWritePortRecorder`——一个遵循 `<MADDataTableWriting>` 且别无其他的 `NSObject`，
   因此没有 `MADDataTable`、没有 `MADDataTableFast`、没有缓存委托、没有 `.maddb`——并断言
   五个调用按承诺顺序到达且两行完好，若有任何 `.maddb` 文件出现则失败。
   mock 之所以可表达，正因为参数是协议。

**Phase 2——移除存储位置的歧义。已完成（Revision 4）。**
8. ✅ 使 `urlFastCache` 存储而非计算（§2.3）。解析一次进 `_urlFastCache`；委托交换在 `-setCacheDelegate:`
   中重开前丢弃它，因此解析总是针对当前委托。
9. ✅ 注入缓存目录，而非在属性内触及 `[MADApplication AppDelegate]`。
   `-initWithId:cacheDirectory:` 和
   `+newDataTableOfType:withObjectID:cacheDirectory:` 携带它；`nil` 保持旧链。
   `testFastTableInitWithCacheDirectoryNeedsNoDelegate` 在完全无委托下构建、填充并读取物理表。

**Phase 3——使 `rowCounter` 派生。**
10. ✅ 添加一个由 `SELECT COUNT(*)` 支撑的私有 `-recountRows`，并使其在
    `MADDataTableFast` 上供 `-numberOfRows`/`-count` 使用（或据此失效）。为
    归档兼容保留 `rowCounter` 属性，但停止把它当作真相来源（§2.5）。
    **Revision 4：** `-recountRows` 存在并在 `-loadWithPlist:` 末尾运行，因此重载的
    表不再能携带与其文件不一致的计数器。
    **Revision 5：** 内存那一半已关闭——四个从未触碰
    计数器的变更现在让它描述文件（§2.5）。`-numberOfRows`/`-count` 按设计仍返回
    ivar；它现在是唯一读取者，且 `-recountRows` 守护重载。
    四个测试覆盖四个方法。
11. ✅ 审计 `MTTableController.m`（原 `:375/395/440/445`）——分页不得读取可能与文件漂移的计数器。
    **已完成（Revision 5）**，且一旦计数器诚实它就不能：每次抓取都从 `-removeAllObjects` 开始，它清空表并清零计数器，因此
    完成时的计数恰好度量刚写入的页面，别无其他。那两个确切行上的两个缺陷
    还是被发现并修复。空页面时 `offset + count - 1` 在
    `:380`/`:402` 回绕到 `NSUIntegerMax`；且 `:449` 的失败路径从驱动*未*清空的表读取计数（它只在成功时清空），
    因此它度量上一页，失败的抓取报告 `hasMore = YES` 并重新发出自身。失败的页面现在报告没有更多。

**Phase 4——修复并发。**
12. ✅ 在 `queueBulkAdd` 上串行化 `-addRow:error:`（§2.4）。队列已存在且已
    用于 `-endBulkInsert`；把它扩展到变更路径是小而受控的改动。
    把 `-endBulkInsert` 中的 `sqlite3_finalize(_statementInsert)` 移到
    屏障*内部*，使缓存语句只在没有 `-addRow:` 在飞时拆除。
    **完成（Revision 4）**——拆除现在是 `:1334` 的
    `dispatch_barrier_sync` 内第一件事。
13. **评估并否决（Revision 5）**——每文件一对共享连接，而非每个
    表实例，因为 `-objectEnumerator` 目前每次调用都打开新连接
    （§2.7）。写那一半不可共享（`-endBulkInsert` 关闭该句柄），读那一半
    几乎买不到什么（`SQLITE_OPEN_SHAREDCACHE` 已共享缓存），
    同时使活动枚举器跨重建的情形更糟而非更好。§2.7 有
    完整论证。

**Phase 5——退役死表面。**
14. ✅ 删除 `MADDataTableLocation`（§3.7）及其三个测试，或把它接进实际功能。
    它目前是无生产调用者的公开 API。**Revision 5 中移除**——删除
    而非接入，因为其历史只有一个提交，除了它自己的测试外没有任何东西
    描述它。MAD 目标的 Headers 和 Sources 阶段随之丢掉两个文件。
15. **评估（Revision 5）**——调和两个持久化机制（§2.6）。前提
    对家族不成立：行在 plist 即存储处*确实*通过 plist 往返
    （`MADDataTableVirtual` 的 `keySortIndex`），在它是 sqlite 文件处则不能
    （`MADDataTableFast` 的 `keyUrlFastCache`），因此重命名和替代都不对。
    §2.6 记录按子类的表以及尚待做的文档改动。

### 4.3 当前消费者的破坏度排名

| 消费者 | 位置 | 重构下的风险 |
|---|---|---|
| `MTTableController` | `:249, :281, :284, :377, :393, :399, :449, :455` | **高**——把 `count` 当页面游标；任何 `rowCounter` 语义变化都破坏分页。Revision 5 使推导完备——空页面不再下溢，失败抓取不再读取上一页的计数（§2.5）——但耦合不变 |
| `MADDatabaseMySQL` | `:88-92, :118-122, :150-154, :187-189` | **高**——O(n) `objectAtRow:i column:0`；必须先统一按子类的 `row` 语义 |
| `MADocument` | `:197`（`rowCounter`）、`:865-867`（枚举器）、`:874-919`（`dataForRow:error:`）、`:1053-1072` | **高**——但仅对枚举器和 `rowCounter`。其 `-dataForRow:error:` 发送解析到 `MADDataTableFast`，后者实现该选择器，因此打印/条形码路径健全（见 §3.5） |
| `MADMySQLFetch+DataTable` | `:301, :321` | **中**——在 `// FIXME: This is a hack.`（`:297`）背后于抓取中途变更 `column.type`；列字典必须保持公开可变 |
| `MADQuerySampleDataTable(Range)` | `:118, :126` / `:123, :131` | **低**——单次 `objectAtRow:0` 宽度探查 |
| `MADReportFormatter` | `:449-502` | **低**——容忍行 id 和字典枚举 |
| `MADDatabaseSQLServer` | `:500, :1367, :1472` | **低**——通过五方法端口的只写 |

### 4.4 要尊重的约束

* **不要改变 `MADDataTableType` 的原始值。** `MADDataTableParametersType` 被编码
  进定义字典（`MTTableController.m:91`、`MTTableViewControllerBarcodeExtraMaxicode.m:104`）
  且枚举经 `initWithShort:` 序列化。
* **不要重命名类。** `MADDataTableFast` 归档携带
  `[MADDataTableFast keyTag]` 式键（`:114-119`），且 `MADDataTableVirtual` 携带
  `keySortIndex`（`:202`）进既有 `.mdcache`/`.maddb` 文件。
* **保留五方法写入端口。** 全部三个驱动都依赖确切序列
  `removeAllObjects → addColumn: → beginBulkInsert → addRowWithDataForFieldKeys: → endBulkInsert`。
* **未引入类名嗅探。** 保持这一点：任何新分支都应基于
  协议或枚举，绝不基于类。

### 4.5 把 SQL 作为格式字符串传给 `sqlite3_mprintf`

修复 §3.5 时发现。另外八个调用点把变量作为*格式*字符串而非
参数传给 `sqlite3_mprintf`。SQL 中的任何 `%` 随后会被读作
转换，因此含 `%` 的查询会被弄坏——或读越参数列表并崩溃。

**Fixed。** 全部八个现在传字面量 `"%s"` 并把 SQL 作为参数，
匹配已经正确的站点：

| 文件 | 站点 |
|---|---|
| `MADSqlite3/Source/MADDataTableFast.m` | `:1062`、`:1102`、`:1245` |
| `MADSqlite3/Source/MADDatabaseSqlite3.m` | `:301`、`:397`、`:875` |
| `MADSqlite3/Source/MADDataTableObjectEnumerator.m` | `:69` |
| `MADSqlite3/Source/MADDataTableSingleColumnEnumerator.m` | `:64` |

已正确的参考站点是 `MADDataTableFast.m:548`、`:901` 和 `:973`，以及
`MADDatabaseSqlite3.m:459`。`MADSqlite3` 中每个 `sqlite3_mprintf` 调用现在要么使用
字面量 `"%s"`，要么使用不含转换的字面格式字符串——`grep -n
sqlite3_mprintf MADSqlite3/Source/*.m` 返回十四个调用且无变量格式字符串。

可达性低：SQL 来自生成的查询构建器，且全仓搜索
未发现会引入 `%` 的 `LIKE` 模式。然而标识符来自
所连接数据库的架构，因此列或表名中的 `%` 会命中它。它是
潜在正确性缺陷而非现网缺陷——修复因为改动机械且
错误的后果是静默损坏。

---

## 附录——检查的文件

| 文件 | 行数 |
|---|---|
| `MADFoundation/Source/MADDataTable.h` / `.m` | 123 / 435 |
| `MADFoundation/Source/MADDataTableVirtual.h` / `.m` | 21 / 240 |
| `MADFoundation/Source/MADDataTableType.h` | 17 |
| `MADFoundation/Source/MADDataColumn.h`、`MADDataProtocol.h`、`MADCacheProtocol.h` | — |
| `MADSqlite3/Source/MADDataTableFast.h` / `.m` | 47 / 1355 |
| `MADSqlite3/Source/MADDataTableObjectEnumerator.m` | 173 |
| `MADSqlite3/Source/MADDataTableSingleColumnEnumerator.m` | 149 |
| `MADSqlite3/Source/MADQueryCacheAddRow.m` | 152 |
| `MADSqlite3/Source/MADDatabaseSqlite3.m` | 1346 |
| `MAD/Source/MADDataTable+Constructor.h` / `.m` | 30 / 94 |
| `MAD/Source/MADocument.m`、`MADReportFormatter.m` | — |
| `MADMySQL/Source/MADDatabaseMySQL.m`、`MADMySQLFetch+DataTable.{h,m}` | — |
| `MADTdsClient/Source/MADDatabaseSQLServer.m` | — |
| `MADAPI/Source/MADDatabaseProtocol.h`、`MADQuery.h`、`MADDatabaseResultsProtocol.h` | — |
| `MADDesigner/Source/MTTableController.m` | — |
| `MAD/MADTests/MADDataTableRegressionTests.m` | 69 个测试 |
