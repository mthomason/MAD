---
layout: default
lang: zh-CN
---

# MADDataTable —— 架构与解耦报告

**范围：** `MADDataTable` 以及跨 `MADFoundation`、`MAD`、`MADSqlite3`、`MADMySQL` 和 `MADTdsClient` 的每一个实现、子类、协议与调用点。
**分支：** `refactor/mad-database-decouple`
**日期：** 2026-10-01
**验证：** `xcodebuild test` —— 全部 11 个 scheme，809 个测试，0 个失败；范围内任何文件均无警告（`MADDatabaseMySQL.m` 中的两个 `-Warc-repeated-use-of-weak` 警告是既有问题，未做改动）。（修订 2 时为 798；修订 3 时为 804；修订 4 时为 807。）

下文所有 `file:line` 引用均为本次分析期间亲身阅读所得，而非推断。

> **修订 5 —— 2026-10-01。** 阶段 3 与阶段 5 已关闭，阶段 1 第 7 步已获验证。
> `-dropTable`、`-dropTableName:`、`-deleteAll` 与 `-vacuumCacheDb` 现在都会让 `rowCounter` 如实描述文件（§2.5），这正是第 10/11 步的全部内容；三个处于风险中的常量由四个新测试覆盖。用一个裸的 `<MADDataTableWriting>` 遵循者驱动 sqlite 行循环——背后没有 `MADDataTable`，也没有 `.maddb`——这就是第 7 步，现在已是一个测试（`MADWritePortRecorder`）。第 14 步已完成：`MADDataTableLocation` 已删除。第 13 步与第 15 步是经评估而非执行，理由见下文各自的条目。
>
> 编写这些测试的过程中暴露出两个现存缺陷，现均已修复。`-deleteAll` 把一个*字符串*交给了 `-[MADQueryCacheDeleteAllFromTable initWithObject:]`，而后者把它当作参数字典来下标访问，在第一行就抛出异常——该方法没有任何调用方，所以从未有人触发过；现在改用 `-initWithTableName:`。另外 `MTTableController` 在其失败路径上把 `datatable.count` 当作分页游标读取，而此时表中仍然保留着上一页，于是失败的获取报告 `hasMore = YES` 并永久重试。
>
> 关于计数器的注释使 `MADDataTableFast.m` 从 `-deleteAll` 起偏移了 13 行，因此该点之后的每一条 `file:line` 引用都是重新推导的，而非做行号调整；`MTTableController.m` 也发生了位移，其引用随之重新推导。
>
> **修订 4 —— 2026-10-01。** 修订 3 中的 MySQL 障碍已不复存在。`MADMySQLFetch+DataTable.m` 在获取中途读取的列元数据现在由 `<MADDataTableWriting>` 自身声明，因此全部三个驱动——包括 `MADDatabaseMySQL`、`MADDatabase.m` 以及 `MADDatabaseDataSource` 协议——都接受 `id <MADDataTableWriting>`，且获取的出参改为传值（所有调用点均去掉了 `&`）。阶段 2（“存储 `urlFastCache`；注入缓存目录”）与阶段 4 第 12 步（串行化写入管线）已完成，阶段 3 仅对重新水化路径完成。§2.1、§2.3–§2.5 与 §4.2 分别做了标注。新增了三个测试；测试套件从 804 变为 807。由于这些修复使 `MADDataTableFast.m` 偏移了 87 行，本报告中指向该文件的每一条 `file:line` 引用都是重新推导的而非做行号调整，附录中的行数统计也随之刷新。
>
> **修订 —— 2026-09-30。** §2.5、§3.3、§3.5 与 §4.2 在发现初版于三点上有误后重写：对 `-dataForRow:error:` 的诊断（误读了一个两行的方法签名——该方法*确实*在 `MADDataTableFast` 上实现）、`-allObjects` 的“活缺陷”（没有生产调用方）以及 `rowCounter` 漂移的表述（不可达）。§4.5 为新增。更正后的文字标注为 **已更正** / **已修复**；原文的错误主张在具有启发意义处保留可见。随本次修订落地了三处代码修复——见 §3.5。
>
> **修订 3 —— 2026-10-01。** 阶段 1 第 5 步已落地：`<MADDataTableWriting>`、`<MADDataTableReading>` 与 `<MADDataTableCursoring>` 已在 `MADDataTable.h` 中声明，类已采纳全部三个协议。第 6 步在三个驱动中的两个上落地——`MADDatabaseSQLServer` 与 `MADDatabaseSqlite3` 现在以写端口类型声明。第 6 步在 `MADDatabaseMySQL` 上**无法**落地，第 5 步中的“删除现已多余的 stub 块”被否决；§4.2 记录了各自的理由。整轮改动是加法式的：行为未变，全部 11 个 scheme 通过（804 个测试）。
>
> **修订 2 —— 2026-09-30。** §4.5 中的八个 `sqlite3_mprintf` 格式字符串位置现已修复，阶段 0 已落地：`MADDataTable.m` 中未实现的操作改为断言，而不再静默失败（§3.2、§4.2）。§3.1 的表格与附录行数已针对改动后的文件重新推导。上一修订中的两个错误也已更正：工作区测试总数曾写作 799，实为 798；§3.6 曾引用四处 `_database` 位置，实为十五处。

---

## 1. 当前架构与类层次

### 1.1 类族

`MADDataTable` **不是**单一类——它是一个小型类簇，沿存储轴拆分到三个框架中，外加一个以独立枚举器对象实现的游标轴。

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

经验证的导出接口（来自构建出的 `.framework/Headers`）：

| 框架 | 公开导出的数据表头文件 |
|---|---|
| `MADFoundation` | `MADDataTable.h`、`MADDataTableType.h`、`MADDataTableVirtual.h` |
| `MADSqlite3` | **仅** `MADDataTableFast.h` |
| `MADMySQL` | 无 |
| `MADTdsClient` | 无 |

这种拆分是有意为之且健康的：枚举器的类名从不会外泄。使用方只会看到 `NSEnumerator *`，这正是 `MADDataTable.h` 所返回的类型。

### 1.2 两个正交轴，一个枚举

`MADDataTableType`（`MADFoundation/Source/MADDataTableType.h`）只编码**存储**轴：

```objc
typedef NS_ENUM(short, MADDataTableType) {
    MADDataTableTypeVirtual,    // -> MADDataTableVirtual
    MADDataTableTypePhysical,   // -> MADDataTableFast
};
```

**访问**轴——逐行读取还是游标——与之正交，通过返回枚举器而非类型来表达。不存在 `MADDataTableTypeCursor`。这对重构很重要：游标接缝已经存在，并且被正确地隐藏了。

### 1.3 子类选择的唯一位置

`MAD/Source/MADDataTable+Constructor.m:51-69` 是代码库中唯一指名具体子类的地方：

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

我确认，代码库中任何地方都**没有**对数据表使用 `isKindOfClass:`、`NSClassFromString`、类名字符串比较或 `respondsToSelector:` 探测。这是对重构最有价值的单一属性——类簇可以在这一个方法背后被重新塑形。

同一文件中有两个注意事项：

* `+newDataTableWithDefinition:` 在缺少对象 id 时调用 `NSAssert(NO, @"Not implemented.")` 并返回 `nil`（`:44-46`）。`:31-32` 注释中“默认为 virtual”的意图不可达——`objectIdSet` 把关着唯一的返回路径。
* `+newDataTableForIdentifier:`（`:79-92`）是*事实上的*公开入口：大多数调用点（`MTTableController.m:90`、`MADQuerySampleDataTable.m:68`、`MADQuerySampleDataTableRange.m:69`）反而直接走 `newDataTableWithDefinition:`，并且总是把类型固定为 Virtual。

### 1.4 写入契约

每个数据库驱动都通过**基类** API 填充表，从不使用子类特有的 API。`MADDatabaseSqlite3.m:474-540` 是典型的循环：

```objc
[dataTable removeAllObjects];
// first row only:
[dataTable addColumn:dataColumn];       // per column, discovered from sqlite metadata
[dataTable beginBulkInsert];
// per row:
[dataTable addRowWithDataForFieldKeys:resultsForRow];
[dataTable endBulkInsert];
```

`MADDatabaseSQLServer.m:500 / :1367 / :1472` 使用完全相同的五次调用形态。`MADMySQLFetch+DataTable.m:211 / :438 / :442` 亦然。

这是一个**狭窄、定义明确的写端口**：五个方法。它是类族中最强的现有边界，任何重构都应原样保留。

驱动之间的差异：

| 驱动 | 它构建的表 | 写入路径 |
|---|---|---|
| `MADDatabaseSqlite3` | 交给它的任何表（通常是 `MADDataTableFast`） | `executeSQL:...intoResultTable:` |
| `MADDatabaseMySQL` | 自己**构建** `MADDataTableVirtual`（`MADDatabaseMySQL.m:83, 110, 137, 175, 196, 376`） | `MADMySQLFetch+DataTable.m` |
| `MADDatabaseSQLServer` | **从不构建**——纯粹只写入调用方提供的表 | `MADDatabaseSQLServer.m` |

因此 MySQL 无法产出 `MADDataTableFast`，而 SQL Server 根本无法产出任何表。“物理”（sqlite 支撑的）存储只为本地缓存存在，不用于远程结果。

### 1.5 读取契约

生产环境中使用着三种彼此不同的读取方式：

1. **随机访问**——`-objectAtRow:` / `-objectAtRow:column:`。
   `MADMySQL` 在 O(n) 循环内使用 `objectAtRow:i column:0`
   （`MADDatabaseMySQL.m:88-92, 118-122, 150-154, 187-189`）来读取 `SHOW TABLES` 的结果。
   `MADQuerySampleDataTable.m:126` / `MADQuerySampleDataTableRange.m:131` 各调用一次
   `objectAtRow:0` 读取宽度行。`MTTableController.m:281, 284, 393` 用 `objectAtRow:` 进行分页。

2. **枚举**——`-enumeratorForKeyObjectsSorted`。
   `MADocument.m:865-867` 将它作为 `enumeratorForReportData` 返回，由
   `MADReportFormatter.m:449-502` 消费。

3. **计数**——`-rowCounter` / `-count` / `-numberOfRows`。
   `MADocument.m:197`（`numberOfResults`）、`MTTableController.m:249`（表大小）以及
   `:377, :399, :449, :455`（分页游标运算）。

`MADReportFormatter` 是最宽容的使用方，对重构的约束也最小。注意 `MADReportFormatter.m:463-472`：

```objc
if (!calculatedRowId) {
    if ([resultRow isKindOfClass:[NSDictionary class]]) { rowIdOnly = NO; }
    calculatedRowId = YES;
}
self.machineState.detailRowId = rowIdOnly
    ? ((NSNumber *)resultRow).unsignedIntegerValue
    : ((NSNumber *)resultRow[MADIdentifierROWID]).unsignedIntegerValue;
```

格式化器**已经能够容忍只产出裸行 id `NSNumber` 的枚举器**，也能容忍完整的行字典。`enumeratorForAllObjectsSortedRowIdOnly` 正是为这种情况而存在。这是一个现成的接缝：只流式产出行 id 的游标已经是可接受的输入。

---

## 2. 内存模型、生命周期与状态

### 2.1 ARC 与唯一的裸 ivar

所有文件均使用 ARC（`#if !__has_feature(objc_arc) #warning ...` 守卫）。状态存放在类扩展中。`MADDataTableFast` 恰好有一个非对象 ivar：

```objc
@implementation MADDataTableFast {
	sqlite3_stmt *_statementInsert;   // MADDataTableFast.m:103
}
```

它在 `-dealloc`（`:163-165`）与 `-endBulkInsert`（`:1334-1339`）中被终结。模式是正确的，但*曾经*很脆弱：`-endBulkInsert` 过去在取得屏障**之前**就把语句置空，于是拆除发生在唯一没有插入在途的窗口之外。

**已修复（修订 4）。** 拆除现在在屏障内部执行，位于 `:1337-1338`。

### 2.2 一个文件上的两个 sqlite 连接

`-reopenDbConnection`（`:385-401`）构建**两个**独立的 `MADDatabaseSqlite3` 实例，指向同一个 `.maddb` 文件：

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

读句柄以 **`-openDatabase`（默认标志）** 打开，写句柄则以 `SQLITE_OPEN_FULLMUTEX` 打开。`SQLITE_OPEN_FULLMUTEX` 是**按连接**的串行化模式；它不在同一文件的两个连接之间做仲裁。结合 §2.4 来看，这是类族中最大的单一正确性假设。

### 2.3 存储位置由环境全局状态解析

`-urlFastCache` 曾是一个*计算*属性（本次修订前为 `:299-311`），而非存储的：

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

* 没有 `cacheDelegate` 的表在其磁盘身份上**静默依赖全局 app delegate**。这就是为什么 `MADDataTableFast` 在无宿主的逻辑测试中若没有 delegate 就无法实例化——回归套件用一个符合 `MADCacheProtocol` + `MADDatabaseResultsProtocol` 的 stub 绕过了这一点。
* `-setCacheDelegate:`（`:377-383`）会调用 `-reopenDbConnection`。更换 delegate 会**把表重新指向另一个文件**，而内存中的 `tag`/`rowCounter`/`columnKeys` 保持不变。没有任何机制检测这种不匹配。
* `-copyPlist` 断言 `urlFastCache != nil`（`:243`）——因此归档表的持久化 URL 取决于归档时的环境状态。

**已修复（修订 4）。** `-urlFastCache` 现在只解析一次并保存结果（`_urlFastCache`，位于 `:347-355`，由 getter 以及在 `:377-383` 的 `-setCacheDelegate:` 写入，后者在重新打开前将其丢弃）。`-newUrlFastCache`（`:357-373`）保留解析本身，并新增了第一优先项：在初始化时提供的缓存目录。`MADDataTableFast` 新增了 `-initWithId:cacheDirectory:`（`:173-181`），`+[MADDataTable newDataTableOfType:withObjectID:cacheDirectory:]` 将其透传（`nil` 保持旧行为），并且它会立即打开连接，因此表在没有 delegate、没有 app 的情况下也可用。上文所述的更换 delegate 重新指向仍会发生——这正是“URL 派生自 delegate”的预期解读——但它不再取决于该属性是*何时*首次被读取的。

`tag`（在 `initWithId:fromCache:` 中设置，`:190`）是唯一的稳定身份；它同时生成表名（`t<tag>`，`:403-409`）与文件名（`<tag>.maddb`，`:340-343`）。

### 2.4 线程安全：无锁，只有一条队列

我在整个类族中检索了 `dispatch_sync`、`dispatch_async`、`@synchronized`、`NSLock`、`os_unfair_lock` 与 `pthread_mutex`。存在的**唯一**并发原语是 `queueBulkAdd`：

* 被创建了三次——`initWithId:fromCache:`（`:186`）、`initWithCoder:`（`:202`）与 `beginBulkInsert`（`:1322`）——每次都是 `dispatch_queue_create(..., SERIAL)`。
* 仅在**两**处使用：`-endBulkInsert`（`:1334`）用 `dispatch_barrier_sync` 包裹 delegate 调用，以及（自修订 4 起）`-addRow:error:` 用 `dispatch_sync` 进入该队列。
* 在修订 4 之前，它**从未**用于串行化 `-addRow:error:`。

因此 `-addRow:`——变更入口——*曾经*完全不受队列保护。在 `_bulkInsertLoop` 下，`-addRow:` 跨调用复用单个缓存的 `_statementInsert`（`:529-611`）：`sqlite3_bind_*` → `sqlite3_step` → `sqlite3_clear_bindings` → `sqlite3_reset`，没有任何互斥。两个线程并发进入 `-addRow:` 时会在该共享语句上产生竞态，无论 `SQLITE_OPEN_FULLMUTEX` 如何，因为竞态发生在 bind/step/clear/reset 的*序列*中，而不在任何单次 sqlite 调用内部。

回归套件记录了当前的并发行为，但无法使其安全——串行化必须补上。

**已修复（修订 4）。** `-addRow:error:`（`:504-528`）现在是一个薄包装，在 `dispatch_sync(queueBulkAdd)` 下运行插入主体（`-insertRow:error:`，位于 `:529`，即原方法改名），仅当队列为 nil 时才回退为直接调用——这只会发生在一个从未完成初始化的表上。`-endBulkInsert` 中的 `sqlite3_finalize(_statementInsert)` 移到了其 `dispatch_barrier_sync` *内部*，因此缓存语句只会在没有插入在途时被拆除。在串行队列上，屏障与 `dispatch_sync` 互斥，而这正是 bind/step/clear/reset 序列所需的全部互斥。两个测试固定了这一点：`testFastTableConcurrentWritersLoseNoRows`（新增）从*并发*队列驱动四个写者；`testFastTableSerializedConcurrentWritesLoseNoRows` 保留应用中的串行队列模式，其“表内部不做串行化”的契约说明已更正。第 13 步（每个文件一对连接）未做改动。

### 2.5 `rowCounter` 是独立计数器，而非派生值

`-insertRow:error:` 递增 `rowCounter`（`:532`），且**从不查询 sqlite**。`-numberOfRows` / `-count` 直接返回它（`:1222` / `:1216`），`-removeAllObjects` 将其归零（`:683`）。但 `-dropTable`（`:799`）、`-dropTableName:`（`:804`）、`-deleteAll`（`:818`）与 `-vacuumCacheDb`（`:789`）直到修订 5 都**没有**触碰它。

因此两个事实来源可能产生分歧：

* `rowCounter` 声称有 N 行；`.maddb` 文件中却存放着不同数量的行。
* 在 `-loadFromCacheWithUrl:` 的一次往返中，计数器来自 plist（`MADDataTable.m:305-306`），而行来自 sqlite 文件——它们由两套互不相关的机制重新水化。

**已修复（修订 4）——重新加载的一半。** `-loadWithPlist:` 现在以 `self.rowCounter = [self recountRows];`（`:313`）结束，其中 `-recountRows`（`:317-338`）向缓存文件询问 `SELECT COUNT(*)`，仅当表尚不存在时才回退到 plist 的值。经内存路径膨胀的计数器不再能在重新加载后幸存。`testFastTableReloadRecountsRowsFromCacheFile` 通过在一个存放 3 行的文件上加载计数器声称 99 的 plist 来固定这一点。

**已修复（修订 5）——内存的一半，即第 10/11 步。** `-dropTable`（`:799`）与 `-dropTableName:`（`:804`）现在会将计数器归零，`-deleteAll`（`:818`）将其归零，而 `-vacuumCacheDb`（`:789`）刻意不归零，因为 VACUUM 保留每一行——源码中带有说明这一点的注释，因为“为什么这一个*不*重置它”正是下一位读者会有的疑问。`-dropTableName:` 接受任意表名，因此只有当消失的表正是本表时才将计数器归零；删除外部表绝不能触碰这个计数。`-numberOfRows`（`:1222`）与 `-count`（`:1216`）仍然返回 ivar 而不查询文件，这正是设计要点——`-recountRows` 是重新加载路径的检查，而不是每次读取的开销。

`-removeAllObjects`（`:674`）掩盖了整个隐患，现在依然如此：它是这四个方法唯一的调用方，并且自己将计数器归零（`:683`）。这正是它值得关闭而不是搁置的原因——这个隐患距离被触发只差一个调用方，`-count` 对应用而言是分页游标（§4.3），而这四个私有方法距离被新代码调用只差一次 `git log -S`。此处修订 4 的注释曾称这种漂移“在代码中真实存在，但今天没有调用方能触达”；调用方审计仍然成立——`-deleteAll` 在**整个仓库中没有任何调用方**，`-dropTable` 仅从 `-removeAllObjects` 触达——但计数器现在在每一条路径上都正确，而不只是因为它唯一的调用方碰巧会在事后收拾干净。`MADDataTableRegressionTests.m` 中的四个测试分别直接驱动这四个方法。

`MADDataTableVirtual` 形态相同（`:179`、`:193`、`:225`），但其计数器与 `sortIndex` 是一起变更的，因此从构造上就是一致的。

这是类簇重构中风险最大的状态：`MTTableController.m` 在 `:377` 与 `:399` 读取 `datatable.count`，并在 `:455` 由其推导 `hasMore = (count == limit)`，因此一个偏离实际的计数器会破坏分页。修订 5 也让这一推导变得完整——空页不再把 `offset + count - 1` 回绕到 `NSUIntegerMax`（`:380`、`:402`），失败路径返回 `completion(NO)`（`:449`），而不再读取仍然描述*上一*页的计数。

编写这些测试时发现 `-deleteAll` 中有一个与计数器无关的缺陷：它把一个 `NSString` 传给了 `-[MADQueryCacheDeleteAllFromTable initWithObject:]`，而后者把参数当作参数字典来下标访问，于是在第一行抛出 `unrecognized selector`。`-initWithTableName:` 才是接受表名的初始化器，也是 `MADDatabaseSqlite3 -beginBulkInsert` 已经使用的那一个。从未有调用方触发过它，因为没有调用方。

### 2.6 两套互不相关的持久化机制

| 机制 | 位置 | 存储内容 |
|---|---|---|
| Plist，`NSPropertyListBinaryFormat_v1_0` | `MADDataTable.m:193-220`、`:135-191` | `name`、`columnKeys`、`columns`（元数据）、`rowCounter`。**不含行数据。** |
| sqlite `.maddb` 文件 | `MADDataTableFast.m` | 实际行数据，以及 `MADDataTableFast` 特有的键（`urlFastCache`、`tag`、`bulkInsertLoop`、`sortDescriptorsSet`、`groupKeyIndexes`） |

基类中的 `-cacheWithUrl:error:` 被文档化为通用缓存，但它只序列化*形状*，从不序列化*内容*。`MADocument.m:413-414` 由 `[self.dataTable newFilenameMDCache]` 推导出 `urlDataTableCache`（`<tag>.mdcache`），而 `MADDataTableFast` 读写的却是 `<tag>.maddb`（`:340-343`）。两个文件扩展名，两种格式，两个所有者，一张逻辑表。

**已评估（修订 5）——第 15 步要求做一次统一。前提本身是错的，而这正是发现。** “基类 plist 只含元数据”对基类成立，对整个类族不成立：每个子类都通过恰好一个额外的键扩展 `-copyPlist` / `-loadWithPlist:`，而这个键*就是*它的存储。

| 类 | 存储 | 承载它的 plist 键 |
|---|---|---|
| `MADDataTable` | 无（抽象） | `name`、`columnKeys`、`columns`、`rowCounter` |
| `MADDataTableVirtual` | `sortIndex`，一个行字典数组（`MADDataTableVirtual.m:106-109`、`:89-104`） | `keySortIndex`——行本身 |
| `MADDataTableFast` | `.maddb` 文件 | `keyUrlFastCache`、`keyTag`、……——行的*定位符* |

因此，在 plist 就是存储的地方，行已经能通过 plist 往返；而在存储是 sqlite 文件的地方则不能。无论是改名（“就叫元数据”）还是另一种做法（“把行放进去”），对整个类族而言都不正确；基类是*两个*子类共享的元数据，而这套机制在设计上就是按子类区分的。这两个扩展也并不冲突：`MADocument` 把 `<tag>.mdcache`（plist）写在 `<tag>.maddb`（行数据）旁边，`-loadFromCacheWithUrl:` 读取前者以找到后者——前提是 tag 一致，而它确实一致，因为 `-filename`（`MADocument.m:1397-1399`）是 `fileURL.lastPathComponent` 经 `stringByDeletingPathExtension` 的结果，与 init 为 tag 计算的哈希是同一个字符串。

值得做而这里没有做的，是文档而非重构：在 `MADocument` 的缓存目录中按实际用途命名这两个文件，并在 `MADDataTable.h` 中说明 `-copyPlist` 返回的是共享元数据、拥有自有存储的子类必须扩展它。这是一处没有行为需要保持的注释改动，因此属于文档整理，而不属于这里。

### 2.7 枚举器的生命周期

`MADDataTableObjectEnumerator` 持有自己的 `MADDatabaseSqlite3` + 连接 + 预处理语句，全部在 `-initWith...`（`:60-72`）中构建，并在 `-dealloc`（`:45-49`）中释放。因此：

* 只要枚举器被持有，它就使一个数据库句柄和一个文件描述符保持存活——而 `MADReportFormatter.m:449-502` 会在整个报表渲染期间持有一个。
* 任何删除或重建该表的变更（`-removeAllObjects`、`-dropTable`）都会使未完成枚举器中正在使用的语句失效。没有任何防护。
* 每次调用 `-objectEnumerator` / `-enumeratorFor...` 都会为同一文件分配一个**全新连接**（`:1139`、`:1158`、`:1186`、`:1202`）。枚举两次就打开 sqlite 两次。

**已评估（修订 5）——第 13 步要求每个文件一对共享连接。未执行，理由在于生命周期，而不在于数量。** 插入连接根本无法共享：`MADDatabaseSqlite3 -endBulkInsert` 以关闭该连接并将 `_database` 置空（`:794-795`）收尾，这就是为什么 `MADDataTableFast -removeAllObjects` 在删除任何东西之前要重新打开，以及为什么四个私有变更方法在被直接驱动时断言（直接驱动它们是错误的——参见修订 5 的测试，它们正因此先重新打开）。因此共享的“一对连接”只能是共享的*读*连接加上按周期的写连接，这样只省下一个句柄，而不是两个。

而且这点节省比看上去更小：这里的每个连接都以 `SQLITE_OPEN_SHAREDCACHE` 打开（`MADDatabaseSqlite3.m:220`），因此枚举器已经在该文件上共享一个页缓存和一套锁。每次枚举的实际开销是一个 `sqlite3*` 和一个文件描述符——真实存在，但并不是该步骤所暗示的缓存重复开销。

与此相对，共享读连接反而会*失去*一些东西。枚举器会在整个报表渲染期间被持有（`MADReportFormatter.m:449-502`），而 `-removeAllObjects` 会在其下方删除并重建表；如今未完成的枚举器拥有自己的语句和句柄，因此二者只通过文件相互影响。给它们一个共享句柄会把这种交互塞进单个连接内部，而该类的读取本身并不携带任何锁。需要设计的场景正是 §2.7 已经指出的那个——一个跨表重建存活的枚举器——共享连接会让它更糟，而不是更好。故有意保持原状。

---

## 3. 公共 API vs. 泄漏的抽象

### 3.1 声明的接口与实际实现

`MADDataTable.h` 声明了 30 个方法（外加 `name` / `columnKeys` / `sortDescriptors` / `columns` / `rowCounter` / `tag` 属性，其中两个被写协议重新声明——见 §4.2）。基类实现了其中 18 个，其余 12 个为桩：

| 在 `MADDataTable.h` 中声明 | 基类实现（`MADDataTable.m`） | Virtual | Fast |
|---|---|---|---|
| `-addColumn:` | **断言** `:365` | 覆盖 `:112` | 覆盖 `:431` |
| `-addRow:error:` | **断言** `:369` | 覆盖 `:179` | 覆盖 `:504` |
| `-addRowWithDataForFieldKeys:` | **断言** `:374` | 覆盖 `:197` | 覆盖 `:614` |
| `-sortUsingDescriptors:` | **断言** `:378` | 覆盖 `:208` | 覆盖 `:634` |
| `-removeAllObjects` | **断言** `:382` | 覆盖 `:225` | 覆盖 `:674` |
| `-objectAtRow:column:` | **断言** `:386` | 覆盖 `:159` | 覆盖 `:834` |
| `-objectAtRow:` | **断言** `:391` | 覆盖 `:151` | 覆盖 `:848` |
| `-columnsEnumerator` | **断言** `:396` | 覆盖 `:149` | 覆盖 `:1123` |
| `-objectEnumerator` | **断言** `:401` | 覆盖 `:148` | 覆盖 `:1127` |
| `-beginBulkInsert` / `-endBulkInsert` | 空操作 `:408-409` | 空操作 `:236-238` | 覆盖 `:1311`/`:1330` |
| `-allObjects` | `return @[]` `:414-417` | 覆盖 `:118` | 覆盖 `:1209` |
| `-objectAtRow:limit:` | `return @[]` `:419` | 覆盖 `:220` | 覆盖 `:1086` |
| `-count` / `-numberOfColumns` / `-numberOfRows` | `0` `:420-422` | 覆盖 `:122`、`:214`、`:216` | 覆盖 `:1216`、`:1220`、`:1222` |
| `-countByEnumeratingWithState:...` | `0` `:423-427` | 覆盖 `:140` | 继承（0） |
| `-enumeratorForAllObjectsSorted*`、`-objectsForGroupKeys:`、`-dataForRow:error:`、`-enumeratorForKeyObjectsSorted` | `NSAssert(NO, @"Not implemented")` `:327-350` | **同样** `NSAssert(NO)` `:31-54` | 已实现 `:1034`、`:1148`、`:1172`、`:1193`；`-dataForRow:error:` `:941` |

### 3.2 泄漏 1——基类无法表达“抽象”

Objective-C 没有 `abstract`。因此基类过去会**从 `-addRow:error:` 返回 `YES`**，并**从每个读取方法返回 `nil`**。一个部分实现的子类，或一个直接的 `MADDataTable` 实例，会静默接受写入并报告成功，然后什么也读不回来。

**已修复（阶段 0）。** 存储子类必须覆盖的九个写/读操作现在以 `NSAssert(NO, @"%s must be overridden", __PRETTY_FUNCTION__)` 开头（`MADDataTable.m:365`、`:369`、`:374`、`:378`、`:382`、`:386`、`:391`、`:396`、`:401`），与 `:327-350` 一组保持一致。`-addRow:error:` 在 Release 中返回 `false` 而非 `true`，因此即使断言被编译掉，它也不再声称某行已存储。

有两组被刻意**保留**为静默默认值，因为对它们而言沉默是正确的：

* `-beginBulkInsert` / `-endBulkInsert`（`:408-409`）——可选钩子。不需要批量模式的子类完全可以合法地继承空操作。
* `-allObjects`（`:414-417`）、`-objectAtRow:limit:`（`:419`）、`-count` / `-numberOfColumns` / `-numberOfRows`（`:420-422`）以及 `-countByEnumeratingWithState:...`（`:423-427`）——它们返回 `@[]` / `0`，这对一张没有行的表来说是*如实的*答案，并且与 `MADDataTableVirtual` 的返回一致。对 `-count` 断言会把一个正确回答变成崩溃。

这一泄漏余下的一半——在类型系统中而非通过断言来表达这种拆分——是阶段 1（§4.2）。

### 3.3 泄漏 2——一个已经破裂的可空性契约

`MADDataTable.h:65` 声明（在 `@protocol MADDataTableCursoring` 内部）：

```objc
- (nonnull NSArray *)allObjects;
```

`MADDataTableFast.m` 过去这样实现它（本次修订前为 `:1093-1096`）：

```objc
- (NSArray *)allObjects {
	// FIXME: Implement this.
	return nil;
}
```

一个声明为 `nonnull` 的方法在一个子类上返回 `nil`，在另两个上返回 `@[]` / `[self.sortIndex copy]`。任何信任该注解的调用方都会崩溃——它是类族中唯一与头文件契约相矛盾的 `FIXME`。

**已更正：** 没有生产调用方。对数据表的 `-allObjects` 的全部发送都在这套回归测试中，且 `MADDataTableRegressionTests.m` 在 `testFastTableBulkInsertAllObjectsIsUnimplemented` 中有意固定了这个 `nil`。因此该注解是给未来调用方埋下的陷阱，而非现存的崩溃。

**已修复：** `MADDataTableFast -allObjects`（`:1209-1214`）现在通过 `-objectAtRow:0 limit:numberOfRows` 返回每一行，对没有列的表返回 `@[]`，符合 `nonnull` 声明与 `MADDataTableVirtual` 的既有行为（`:118-120`）。固定 `nil` 的那项测试已由两个断言真实契约的测试取代。

### 3.4 泄漏 3——`-objectAtRow:column:` 在各子类中含义不同

两个实现在 `row` 的含义以及所查询的存储上都存在分歧：

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

还要注意边界纪律也不同：Virtual 对 `column` **不做**边界检查（`self.columnKeys[column]` 在越界时会抛出 `NSRangeException`，只由 `-objectAtRow:` 中的 `@try` 捕获，而不在这里），也不对 `dataInColumn` 做 nil 检查；Fast 两者都做。

同一个选择器，两套语义。`MADMySQL` 在紧循环中调用它（`MADDatabaseMySQL.m:88-92` 及另外三处），因此统一语义的重构会首先被 MySQL 感知到。

### 3.5 泄漏 4——`-dataForRow:error:` 在一个子类上实现，在另一个上缺失

**本节在本报告初版中是有误的。** 它声称 `MADDataTableFast` 未实现 `-dataForRow:error:`，因此条码/打印路径会命中基类的 `NSAssert(NO)`。这是错误的，会把读者引向错误的方向。以下是更正后的分析。

`MADDataTable.h:67` 声明
`- (nullable NSDictionary<NSString *, id> *)dataForRow:(NSUInteger)rowID error:(NSError **)error;`，
基类将其实现为 `NSAssert(NO, @"Not implemented: %s")` + `return nil`
（`MADDataTable.m:342-345`）。

* **`MADDataTableFast` 确实实现了它**，位于 `MADDataTableFast.m:941-1015`：

  ```objc
  - (NSDictionary <NSString *, MADResult *> *)dataForRow:(NSUInteger)cacheId
                                                   error:(NSError * __autoreleasing *)outError {
  ```

  这是一个两行签名，此前的修订正是误读于此：选择器折到第二行，第二行被当成了单独的 `-dataForRow:column:` 重载。（真正的 `-dataForRow:column:error:` 是 `:866-932` 处的另一个方法。）实现是真实的，回归套件已经覆盖了它——
  `MADDataTableRegressionTests.m` 的 `testFastTableDataForRowReturnsValues` 与
  `testFastTableDataForRowCachesLastRow` 都向一个活动的 `MADDataTableFast` 发送这个双参数选择器并通过。

* **`MADDataTableVirtual` 两种形式都未实现。** 它在 `:41-44` 有一个 `-dataForRow:` 桩，但该桩是 `NSAssert(NO, @"Not implemented: %s")` + `return nil`——它不是可用的重载，也没有在 `MADDataTableVirtual.h` 中声明。双参数形式会落到会断言的基类。因此内存子类完全没有按 id 访问行的能力。

因此调用点并无风险：`MADocument.m:875/880/919` 派发到 `MADocument.dataTable`，它在静态类型上和实际上都是 `MADDataTableFast`（`MADocument.m:159`，在 `:230` 与 `:288` 分配）。`MADPrintPageElement.m:80` 与 `MADPrintPageElementBarcode.m:30` 路径到达的是同一个对象。活动路径上没有任何断言。

真正的缺陷更狭窄，且现已修复：由于 `MADDataTableVirtual` 从未实现该选择器，任何持有 `MADDataTable *`、而该对象恰好是 Virtual 表的未来调用方，都会在 Debug 中断言、在 Release 中静默收到 `nil`。`MADDataTableVirtual` 现在通过委托给 `-objectAtRow:` 来实现 `-dataForRow:error:`，并通过错误指针报告越界情况。

`MADDataTableFast` 的实现也有一个真实缺陷，现已修复：它的 `if (sqlite3_prepare == SQLITE_OK)` **没有 `else`**，因此 prepare 失败时返回 `nil` 而不设置 `*outError`，并且 `-getSql:` 的错误被丢弃。其同类方法 `-dataForRow:column:error:`（`:905-932`）正确处理了这两种情况。此外，SQL 被作为*格式*字符串传给 `sqlite3_mprintf`（`sqlite3_mprintf((char *) sql.UTF8String)`），这会在 SQL 含有 `%` 时产生乱码或崩溃；现在改为 `sqlite3_mprintf("%s", ...)`，与 `:901` 处的同类方法一致。`MADSqlite3` 中另有八处存在同样的缺陷；现已全部修复——见 §4.5。

### 3.6 泄漏 5——`MADDataTableFast` 伸手访问另一个类的私有 ivar

`MADDataTableFast.m` 在十五处直接访问 `MADDatabaseSqlite3` 的私有 ivar `_database`——`:488`、`:538`、`:784`、`:793`、`:810`、`:829`（通过 `_databaseForInserts`）以及 `:905`、`:976`、`:1065`、`:1078`、`:1106`、`:1108`、`:1248`、`:1251`、`:1261`（通过 `databaseForSelects`）：

```objc
sqlite3 *sqlite_database = _databaseForInserts->_database;                       // :451
NSAssert(prepareResult == SQLITE_OK, @"%s", sqlite3_errmsg(databaseForSelects->_database)); // :1008
```

这完全绕过了 `MADDatabaseSqlite3` 的 API，也是 `MADDataTableFast` 要做任何事都需要一个真实 sqlite 文件的原因。这也是测试目标需要 `MADDataTable+Constructor` 模块导入工作的原因：这个类族只有在同时链接两个框架的代码中才可用。

### 3.7 泄漏 6——死掉的公共 API——**已移除（修订 5）**

`MADDataTableLocation`（`MAD/Source/MADDataTableLocation.{h,m}`，67 行）是一个 `(row, column)` 值对象，具有 `NSCoding` 和一个 `+newDataTableLocationForRow:inColumn:` 工厂方法。我在排除其自身实现的前提下检索了整个代码库：**它唯一的引用出现在回归测试文件中。** 它在生产中是死的。它还采纳了 `NSCoding` 但没有采纳 `NSSecureCoding`，回归套件曾将此记录为一项契约。

阶段 5 第 14 步提出了一个选择——把它接入某个功能，或者删除它。它被删除了，因为没有功能在等它：它的整个历史中只有一次提交（`e702bb062`，`MAD` 框架重组），没有调用方，除了它自己的三个测试之外没有任何东西描述它的用途。一个只靠自己的测试存活的类，是一个让测试付了两次代价的类。文件、它们在 `.pbxproj` 中的两个构建条目以及这三个测试都已随之消失；§3.7 作为泄漏 6 保留而不重新编号，以便本报告其余部分引用的编号仍然成立。

### 3.8 泄漏 7——表反过来伸手进入写查询

`MADDataTableFast` 私有地符合四个协议（`:71`）：

```objc
@interface MADDataTableFast () <MADQueryParametersStandardProtocol,
                                MADQueryParametersColumnKeysProtocol,
                                MADQueryParametersColumnMetaProtocol,
                                MADQueryParametersColumnDataProtocol>
```

并实现 `-queryTableName` / `-queryColumnKeys` / `-queryColumns` / `-queryRowData`（`:419-430`），纯粹是为了让 `MADQueryCacheAddRow` 能把它正在写入的表中的状态拉回来。因此插入路径是一个环：表 → 查询对象 → 回到表。注意名称冲突风险——`-queryRowData`（`:428`）与私有的 `_rowDataLastInserted` 属性都与公开的 `-dataForRow:` 系列无关。

### 3.9 哪些*没有*泄漏（应予以保留）

* 所有子类选择都在 `MADDataTable+Constructor.m:51-69`。
* 写端口是五个基类方法（§1.4）。
* 枚举器类对 `MADSqlite3` 私有，只以 `NSEnumerator *` 形式出现。
* `MADReportFormatter.m:463-472` 已经能够容忍只含行 id 的枚举。
* `MADArrayCaching`（`MADSqlite3`）是本代码库中具有更窄、协议形接口的缓存抽象的先行范例。
* 任何地方都没有对表的运行时类嗅探。

---

## 4. 解耦与重构策略

目标是让 `MADDataTable` 成为可替换的存储与访问策略之上的*稳定接口*，同时不改变五个驱动与四个使用方已经依赖的行为。

### 4.1 目标形态

保留类名（它们已固化进 `NSCoding` 归档和 Core Data），但把变化移到构造器返回的两个协议之后：

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

`MADDatabaseSqlite3.m:474-540` 与 `MADDatabaseSQLServer.m:500-1472` 应接受 `id <MADDataTableWriting>` 而非 `MADDataTable *`。仅此一项就消除了每个驱动中“基类对我丢弃的写入返回 YES”的隐患。

### 4.2 分阶段计划

**阶段 0——让失败模式变得响亮（不改变行为）。**
1. **已完成**，范围比最初提议更窄。存储子类必须覆盖的九个操作现在会断言（`MADDataTable.m:365-403`）；如实的空表回答与可选的批量钩子保留为默认值，因为对它们而言静默值才是*正确*的。拆分方式与理由见 §3.2，契约见
   `MADDataTableRegressionTests.m` 的 `testBaseTableAbstractOperationsAssert`。
2. **不需要——见 §3.5。** 这里的原文说要实现
   `MADDataTableFast -dataForRow:error:`，因为其“目前会断言”。并非如此；该方法在 `:941-1015` 处已实现，早先的阅读把两行签名误当成了 `column:` 重载。真正缺少该选择器的子类是
   `MADDataTableVirtual`，它现在通过委托给 `-objectAtRow:` 来实现它。
3. **已完成。** `-allObjects`（§3.3）曾是一个在 `MADDataTableFast` 上返回 `nil` 的 `nonnull` 方法；现在返回行。同一轮中
   `MADDataTableFast -dataForRow:error:` 补上了其 prepare 检查中缺失的 `else`，不再丢弃 `-getSql:` 的错误，也不再以格式字符串方式把 SQL 传给 `sqlite3_mprintf`。
4. 对照现有回归套件（`MADDataTableRegressionTests.m`）重新验证——它
   已经固定了实例化、枚举与并发，因此能检测出这里的错误。
   （在修订 5 删除该类之前，它还固定了 `MADDataTableLocation` 的契约。）

**阶段 1——声明协议。**

5. **已完成——stub 块被刻意保留。** 三个协议声明在
   `MADFoundation/Source/MADDataTable.h` 中 `@interface` 之上，后者现在读作
   `MADDataTable : NSObject <NSCoding, NSFastEnumeration, MADDataTableWriting,
   MADDataTableReading, MADDataTableCursoring>`，原先位于 `@interface` 主体中的三十个扁平方法声明已从中移除。按轴拆分：**Writing**
   是可变接口（`removeAllObjects`、`addColumn:`、`addRow:error:`、
   `addRowWithDataForFieldKeys:`、`sortUsingDescriptors:`，外加 `@optional`
   `beginBulkInsert`/`endBulkInsert`）；**Reading** 是随机访问与计数；
   **Cursoring** 是枚举，其中三个有序枚举器与
   `objectsForGroupKeys:` 为 `@optional`，因为 `MADDataTableVirtual` 确实无法提供它们。

   计划中“删除现已多余的 stub 块”**没有**被执行，因为两个 stub 块都是被固定下来的契约，而非冗余：
   `testBaseTableAbstractOperationsAssert` 要求九个基类断言桩存在并抛出，
   `testVirtualTableDoesNotImplementSortedEnumerators` 断言在 `MADDataTableVirtual` 上 `-respondsToSelector:` 对四个仅 sqlite 可用的选择器为 **YES**。删除任何一个都会把一个已被捕获的缺陷变成未识别选择器崩溃，并破坏一个专门为防止此事而存在的测试。
   `MADDataTable` 通过断言满足协议的 `@required` 成员，这正是阶段 0 所放置的内容。

6. **已完成（修订 4）——全部三个驱动与协议。** 下面这一段是修订 3 对此事为何受阻的记述；保留以存档。它识别出的解阻方案已被采纳：`MADMySQLFetch+DataTable.m` 所需的列元数据（`columns`、`columnKeys`）现在由 `<MADDataTableWriting>` 自身声明，因此写端口对 MySQL 也足够了。`MADMySQLFetch` 的两个 `fetchWithCommand:dataTable:...` 方法及其私有的 `-fetchResultsFromConnection:intoDataTable:...` 以传值方式接受 `id <MADDataTableWriting>` 并返回同一个表（`(MADDataTable *)dataTable`）；`MADDatabaseMySQL.m` 中全部 11 个调用点以及 `MADMySQLLiveTests.m` 中的 7 个都去掉了 `&`。元数据被放到写协议上而不是第四个协议，因为 MySQL 是在*写入的同时*读取它——它在第一行修正列的类型——并且每个遵循者都能从基类免费得到它。§2.5 的 `// FIXME: This is a hack.` 未作改动。

   *修订 3 文本，存档：* **部分完成——三个驱动中的两个，且协议声明被刻意保持不窄化。** `MADDatabaseSqlite3`
   （`executeSQL:...intoResultTable:`、
   `executeQuery:withDataTable:andError:`、`executeQuery:withError:`）与
   `MADDatabaseSQLServer`（同样两个，外加私有的 `-runQuery:onProcess:withDataTable:`
   与 `-runSQL:onDataTable:fieldKeys:process:`）现在接受 `id <MADDataTableWriting>`。两者都是真正的只写：对它们向表发送的内容执行 `grep`，返回的恰好是那个五调用端口，别无其他。

   **`MADDatabaseMySQL` 尚不能窄化**，`MADAPI/Source/MADDatabaseProtocol.h:28-31` 也一样。障碍不在驱动里——而在 `MADMySQLFetch+DataTable.m` 中，它在填充表*的同时*读取 `(*dataTable).columns` 与 `.columnKeys`，以便在看到第一行时修正列的类型
   （`:301` 与 `:321`，位于 `:297` 处既有的 `// FIXME: This is a hack.` 之下）。因此，不暴露列元数据的写端口对该路径而言并不足够。由于
   `MADDatabaseMySQL` 符合 `MADDatabaseDataSource` 且必须继续符合，窄化协议会让它承诺其自身实现无法兑现的东西——对下一个调用方而言是远程崩溃，而不是编译错误。两处声明都带有指向此处的注释。

   **在检查过程中找到的具体解阻方案：** `MADMySQLFetch+DataTable.m` 从未通过其 `MADDataTable * __autoreleasing *` 出参进行赋值——
   `grep -n '\*dataTable *=' MADMySQL/Source/MADMySQLFetch+DataTable.m` 没有任何返回。该指针是一个调用方从未被告知的入参。将其改为传值
   （`dataTable:(id <MADDataTableWriting>)dataTable`）可直接消除指针类型问题，并让 `MADDatabaseMySQL.m` 中的 11 个调用点去掉 `&`。加上把列元数据访问器加入 `<MADDataTableWriting>` 或第四个协议，
   就是 MySQL 所剩的全部工作。它被推迟而非一并纳入，是因为
   §4.3 已将 MySQL 列为风险最高的使用方，而这项改动足够机械，可以单独评审。

7. **对 sqlite 现已可行，对 MySQL 尚未证实。** `MADDatabaseSqlite3` 的行循环可由任何符合 `<MADDataTableWriting>` 的对象驱动，不需要 `.maddb` 文件，也不需要 app delegate，因为参数不再隐含 `MADDataTable` 类——以及经由它产生的、§2.3 所述的对 `[MADApplication AppDelegate]` 的 `-urlFastCache` 依赖。这样的 mock 测试尚未编写；它是自然的下一步，也是阶段 2 注入缓存目录后最先变得廉价的东西。
   **修订 4：** 无宿主的一半已获证实——`testFastTableInitWithCacheDirectoryNeedsNoDelegate`
   用一个目录、没有 delegate 就构建出可用的物理表。
   **修订 5：两部分均已完成。** `testDriverFillsAWritePortWithNoDataTableBehindIt`
   （`MADSqlite3Tests/MADDatabaseSqlite3DatabaseTests.m`）把一个 `MADWritePortRecorder`——一个只符合 `<MADDataTableWriting>`、别无其他的 `NSObject`，因此没有 `MADDataTable`、没有 `MADDataTableFast`、没有缓存 delegate、没有 `.maddb`——交给行循环，并断言五次调用按承诺的顺序到达、两行数据完好，若有任何 `.maddb` 文件出现则失败。这个 mock 之所以能表达，仅仅因为参数是协议。

**阶段 2——消除存储位置的歧义。已完成（修订 4）。**
8. ✅ 让 `urlFastCache` 成为存储属性而非计算属性（§2.3）。只解析一次并存入 `_urlFastCache`；更换 delegate 会在 `-setCacheDelegate:` 中于重新打开之前丢弃它，因此解析总是针对当前 delegate。
9. ✅ 注入缓存目录，而不是在属性内部去取 `[MADApplication AppDelegate]`。`-initWithId:cacheDirectory:` 与
   `+newDataTableOfType:withObjectID:cacheDirectory:` 负责携带它；`nil` 保持旧的解析链。
   `testFastTableInitWithCacheDirectoryNeedsNoDelegate` 在完全没有 delegate 的情况下构建、填充并读取一张物理表。

**阶段 3——让 `rowCounter` 成为派生值。**
10. ✅ 添加一个由 `SELECT COUNT(*)` 支撑的私有 `-recountRows`，并让 `MADDataTableFast` 上的 `-numberOfRows`/`-count`
    使用它（或据它失效）。为归档兼容保留 `rowCounter` 属性，但不再把它当作事实来源（§2.5）。
    **修订 4：** `-recountRows` 已存在并在 `-loadWithPlist:` 末尾运行，因此重新加载的表不再可能携带与其文件不一致的计数器。
    **修订 5：** 内存的一半已关闭——四个从未触碰计数器的变更方法现在会留下与文件相符的计数器（§2.5）。`-numberOfRows`/`-count` 按设计仍返回 ivar；它现在是唯一的读取方，而 `-recountRows` 把关重新加载。
    四个测试覆盖这四个方法。
11. ✅ 审计 `MTTableController.m`（原为 `:375/395/440/445`）——分页绝不能读取一个可能偏离文件的计数器。**已完成（修订 5）**，而一旦计数器如实，它就不可能偏离：
    每次获取都从 `-removeAllObjects` 开始，该方法清空表并将计数器归零，因此完成时的计数只度量刚写入的这一页，别无其他。尽管如此，恰好在那些行上发现了两个缺陷并予以修复。`offset + count - 1` 在空页时于 `:380`/`:402` 回绕到 `NSUIntegerMax`；而 `:449` 处的失败路径从一张驱动*未*清空的表读取计数（它只在成功时清空），因此度量的是上一页，于是失败的获取报告 `hasMore = YES` 并重新发起自己。现在失败的页会报告没有更多。

**阶段 4——修复并发。**
12. ✅ 在 `queueBulkAdd` 上串行化 `-addRow:error:`（§2.4）。队列已存在且已用于 `-endBulkInsert`；将其扩展到变更路径是一项小而受控的改动。把 `-endBulkInsert` 中的 `sqlite3_finalize(_statementInsert)` 移到屏障*内部*，使缓存语句只在没有 `-addRow:` 在途时被拆除。
    **已完成（修订 4）**——拆除现在是 `:1334` 处 `dispatch_barrier_sync` 内的第一件事。
13. **已评估并否决（修订 5）**——每个文件共享一对连接，而非每个表实例一对，因为 `-objectEnumerator` 目前每次调用都打开一个新连接（§2.7）。写的一半无法共享（`-endBulkInsert` 会关闭该句柄），读的一半几乎买不到什么（`SQLITE_OPEN_SHAREDCACHE` 已经共享缓存），反而会让“活动枚举器跨越表重建”的场景更糟而非更好。完整论证见 §2.7。

**阶段 5——退役死接口。**
14. ✅ 删除 `MADDataTableLocation`（§3.7）及其三个测试，或将其接入某个实际功能。它目前是没有生产调用方的公共 API。**在修订 5 中移除**——删除而非接入，因为它的历史中只有一次提交，除了它自己的测试之外没有任何东西描述它。MAD 目标的 Headers 与 Sources 阶段随之去掉了这两个文件。
15. **已评估（修订 5）**——统一两套持久化机制（§2.6）。前提对整个类族不成立：在 plist 就是存储的地方，行*确实*能通过 plist 往返（`MADDataTableVirtual` 的 `keySortIndex`），而在存储是 sqlite 文件的地方则不能（`MADDataTableFast` 的 `keyUrlFastCache`），因此改名与另一种做法都不正确。§2.6 记录了按子类的表格以及尚待进行的文档改动。

### 4.3 当前使用方的破坏风险排名

| 使用方 | 位置 | 重构下的风险 |
|---|---|---|
| `MTTableController` | `:249, :281, :284, :377, :393, :399, :449, :455` | **高**——把 `count` 当作分页游标；任何对 `rowCounter` 语义的改动都会破坏分页。修订 5 使推导变得完整——空页不再下溢，失败的获取不再读取上一页的计数（§2.5）——但耦合未变 |
| `MADDatabaseMySQL` | `:88-92, :118-122, :150-154, :187-189` | **高**——O(n) 的 `objectAtRow:i column:0`；必须先统一按子类的 `row` 语义 |
| `MADocument` | `:197`（`rowCounter`）、`:865-867`（枚举器）、`:874-919`（`dataForRow:error:`）、`:1053-1072` | **高**——但仅限枚举器与 `rowCounter`。其 `-dataForRow:error:` 发送解析到 `MADDataTableFast`，后者实现了该选择器，因此打印/条码路径是健全的（见 §3.5） |
| `MADMySQLFetch+DataTable` | `:301, :321` | **中**——在 `// FIXME: This is a hack.`（`:297`）背后于获取中途修改 `column.type`；列字典必须保持公开可变 |
| `MADQuerySampleDataTable(Range)` | `:118, :126` / `:123, :131` | **低**——单次 `objectAtRow:0` 宽度探测 |
| `MADReportFormatter` | `:449-502` | **低**——同时容忍行 id 与字典两种枚举 |
| `MADDatabaseSQLServer` | `:500, :1367, :1472` | **低**——仅通过五方法端口写入 |

### 4.4 必须遵守的约束

* **不要改变 `MADDataTableType` 的原始值。** `MADDataTableParametersType` 会被编码进定义字典（`MTTableController.m:91`、`MTTableViewControllerBarcodeExtraMaxicode.m:104`），且该枚举通过 `initWithShort:` 序列化。
* **不要重命名这些类。** `MADDataTableFast` 归档携带 `[MADDataTableFast keyTag]` 形式的键（`:114-119`），`MADDataTableVirtual` 将 `keySortIndex`（`:202`）写入既有的 `.mdcache`/`.maddb` 文件。
* **保留五方法写端口。** 全部三个驱动都依赖 `removeAllObjects → addColumn: → beginBulkInsert → addRowWithDataForFieldKeys: → endBulkInsert` 这一确切序列。
* **没有引入类名嗅探。** 请保持这一点：任何新分支都应基于协议或枚举，绝不基于类。

### 4.5 SQL 被作为格式字符串传给 `sqlite3_mprintf`

在修复 §3.5 时发现。另有八处调用点把变量作为*格式*字符串而非参数传给 `sqlite3_mprintf`。于是 SQL 中的任何 `%` 都会被当作转换说明读取，因此含 `%` 的查询会被破坏——或者越过参数列表读取并崩溃。

**已修复。** 全部八处现在传入字面量 `"%s"` 作为格式、SQL 作为参数，与原本就正确的位置一致：

| 文件 | 位置 |
|---|---|
| `MADSqlite3/Source/MADDataTableFast.m` | `:1062`、`:1102`、`:1245` |
| `MADSqlite3/Source/MADDatabaseSqlite3.m` | `:301`、`:397`、`:875` |
| `MADSqlite3/Source/MADDataTableObjectEnumerator.m` | `:69` |
| `MADSqlite3/Source/MADDataTableSingleColumnEnumerator.m` | `:64` |

原本就正确的参考位置是 `MADDataTableFast.m:548`、`:901` 与 `:973`，以及 `MADDatabaseSqlite3.m:459`。`MADSqlite3` 中的每一次 `sqlite3_mprintf` 调用现在要么使用字面量 `"%s"`，要么使用不含转换说明的字面格式字符串——`grep -n sqlite3_mprintf MADSqlite3/Source/*.m` 返回十四次调用，且没有变量格式字符串。

可达性很低：SQL 来自生成的查询构建器，全仓库检索也没有发现会引入 `%` 的 `LIKE` 模式。然而标识符来自所连接数据库的架构，因此列名或表名中的 `%` 会命中此问题。这是一个潜在的而非现存的正确性缺陷——之所以修复，是因为改动是机械的，而出错的后果是静默的数据损坏。

---

## 附录——已检查的文件

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
