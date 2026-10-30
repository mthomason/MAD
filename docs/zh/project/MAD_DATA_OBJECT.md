---
layout: default
lang: zh-CN
---

# 数据对象——报表的定义、架构和结果集

**范围：** 2026-10-16 提出的概念——什么是数据对象、它在本代码库中如何表示，以及形式化它需要什么。同一次交谈中描述的多源 / 子报表搭建，作为该契约的一个后果记录在此，有意不构建。
**日期：** 2026-10-16，基于 `445794e11` 阅读。
**状态：** 设计文档。它提出建议；不实现任何东西，这里也没有任何内容被排期。`MAD_FUTURE.md` 第 1 节——“报表是从数据源到表的函数”——是本文档将其具体化并为其点明代码的愿景。

---

## 1. 这个想法，以及它不是什么

今天，用户针对一个数据库（MySQL、SQL Server 或 Sqlite3）设计即席查询，它返回一张数据表，报表由布局工具在该数据之上构建。报表是查询加布局。这个泛化就是取查询那一半，把它变成对象：

> 数据对象是一个具名定义，它产生一个**架构**和一个**结果集**——即报表的查询，与布局分离并被赋予身份，从而其输出可以被刷新、被寻址，并被另一个数据对象用作来源。报表是数据对象加上绑定到该对象各列的表现层。

用户自己的话（2026-10-16）：*“返回某种架构和结果集的东西，而报表则是即席查询、报表和设计。”*

三个后果，下面逐一展开：

1. **查询成为产品边界。** 同一个对象服务于设计器（MAD Query 标签页所编辑的内容）、查看器（刷新所执行的内容）、CLI（`mad refresh` 运行的内容）、未来的 web 服务器（端点所执行的内容）以及 AI（它起草、引擎验证的内容）。一个定义，多个消费者——只有对象拥有自己的名字和架构，这一点才成立。
2. **对象可以组合。** *“想法是把多个对象链接在一起。在报表世界里，这就是子报表”*（用户）。用数据的话说，它是一张派生表的 DAG：一个对象的输出对另一个对象来说就是一张表，与今天的架构表完全一样。
3. **来源的增多是结果，而不是功能。** 每个源数据库一个对象——每个对象已经携带自己的驱动和连接——物化，然后按它们的输出连接。用户的草图：*“你在一个子报表里查询 MySQL，在另一个子报表里查询 SQL Server……然后你可以在查询设计器中按它们的输出把这些报表作为表链接起来。”* `MAD_FUTURE.md` 第 1 节说的是同一件事：不需要联邦引擎；快照*就是*联邦。

它明确**不是**什么：

- 不是联邦引擎。没有任何新东西在一条语句里同时访问 MySQL 和 SQL Server；每个对象针对自己的源执行，连接发生在已经本地化的结果之上。
- 不是第二套查询实现。SQL 生成器、驱动、结果表和 SQLite 连接引擎都已存在；第 5 节是在它们之上的搭建。
- 不是对两遍拉取全部数据的缓存范式的改变。缓存是承重的，且有意做大（`MAD_FORMAT.md` 第 5.1 节）；数据对象产生的东西与缓存今天已经持有的内容完全相同。

## 2. 词汇表，因为“架构”在这个代码库里有四种不同含义

| 术语 | 是什么 | 今天的类 |
|---|---|---|
| **源架构** | 用户可查询的数据库的表和字段 | 实时浏览：`MADDatabaseTable` / `MADDatabaseField`（`MADAPI`）。快照：`RptqDatabaseSchemaTable` / `RptqDatabaseSchemaField`，在文档创建时导入一次 |
| **定义** | 查询图：哪些表、哪些字段、连接、筛选、分组、排序 | `RptqQuery` + `RptqQueryTable` / `RptqQueryField` / `RptqQueryLinks` / `RptqQueryPredicate` / `RptqQueryGroup` |
| **结果架构** | 输出的列：名称、类型、原生类型、长度 / 精度、主键、非空 | `MADDataColumn`（每列一个），承载在表上 |
| **结果集** | 行 | `MADDataTable` 类簇；物化为 `MADDataTableFast` |
| **物化** | 磁盘上的结果集：SQLite 表及其序列化的架构 | 文档缓存目录中的 `<tag>.maddb`（SQLite）+ `<tag>.mdcache`（plist，`MADDataTable -copyPlist`） |
| **快照** | `MAD_FUTURE.md` 的用词：被赋予名称、版本并变得可寻址的物化 | 不存在；第 4.3 节是它的起点 |
| **存储架构** | 与以上所有无关：文档自身的存储格式 | `MADStoreSchema`（`MAD/Source/rptq/store/`） |

今天文档持有定义和布局；物化存放在它旁边，以文档（而不是定义）为键。这个划分是正确的——`MAD_FORMAT.md` 第 5 节——本设计保留它。

## 3. 这个想法今天是如何表示的

数据对象的每一部分都已存在，位于不同的层，为不同的目的而构建。以下是每一部分的准确状态，以及形式化将要捏合的接缝。

### 3.1 定义已存在——`RptqQuery` 及其查询图

查询图足够完整，可以编译：表（`RptqQueryTable`，带有 `alias` 和 `dropIndex`，因此一张架构表可以被包含多次）、投影（`RptqQueryField`——架构表 + 架构字段 id）、连接（`RptqQueryLinks`，带连接类型）、筛选（`RptqQueryPredicate`）、分组（`RptqQueryGroup`，通过 `RptqQuery -sortDescriptorsForDatabase:` 驱动排序描述符），以及一行残留的排序（`RptqQuerySort`，只被调试描述读取）。设计器通过 `MADModel*` 读模型编辑它（“通过 `Rptq` 写；通过 `MADModel` 读和观察”——`MADModel_Layer.md`）。

分组是查询级定义，不是报表节。`RptqQueryGroup.hasField` 指定查询分组的字段，`sort` 指定方向。查询要能运行，每个分组的字段都必须属于文档所选择的查询表（`hasField.inQueryTable`）：分组被物化为结果行上的有序键（`-sortDescriptorsForDatabase:`），格式化器比较该键来寻找分组边界。报表的分组页眉 / 页脚节只是该分组的呈现——它可以不包含任何显示分组字段的元素，分组仍然发生。任何布局都无法提供缺失的分组字段，因此字段为 nil、或字段没有所选查询表支撑的分组，是无效文档。设计器仍然会构建并标注这样的节，以便看到损坏的分组；查询执行和渲染会以 `NSInvalidArgumentException` 拒绝它，并记录该分组。

关于其身份的两个事实：

- 一个 `RptqQuery` 挂在一行 `RptqDatabase` 下，并通过“各自的第一条”到达文档：`RptqDatabase -defaultQuery` 是 `hasQueries.anyObject`（`RptqDatabase+Extras.m:88`），`RptqDocument -mainQuery` 同理（`RptqDocument+Extras.m:184`）。
- 存储已经允许多条：`MADModelDocument` **每个 `RptqQuery` 行构建一个 `MADModelDatabase`**（`MADModelDocument.m:210-240`），代码自己的注释说“当前版本的软件只使用一个数据库和一个查询”。这种多重性是应用流程的约定，而不是存储的约定。

### 3.2 编译器已存在——`MADQueryFull`

`MADQueryFull -copySQLWithManagedObjectContext:error:`（`MADQueryFull.m:133`）构建 SQL：投影列来自 `MADQuerySelectExpressionActiveFields`，它向 `MADQueryActiveQueryFields` 询问报表的*元素*、连接和分组所引用的每个字段；FROM/JOIN 由表和连接的 `MTGraph` 编译，并做拓扑排序（`:170-204`）；谓词和字面量引用经过 `MADDatabase`（`newSafeIdentifier:`、`newSafeLiteral:`）；`LIMIT` 通过 `sqlLimitClause:`。

这就是 `MAD_FUTURE.md` 第 3 节视为差异化优势的确定性、自主可控的 SQL 生成——它存在，而且是无头的（在 Linux 构建中，`MADSources.cmake:93`）。

**但它被焊死在文档上。** `MADQueryFull` 把初始化时传入的查询存进 `queryObject`（`:79`），却**从不使用它**：SQL 路径重新读取文档的第一个数据库和第一个查询（`:147-149`）。它也没有实现 `-getSql:error:`（基类返回 `@""`，`MADQuery.m:48`），因此通用的 `MADDatabase -executeQuery:withError:` 路径根本无法运行文档的主查询。你交给它的查询对象并不决定运行什么。

### 3.3 执行接缝已存在——`MADDatabase`

抽象点是 `-[MADDatabase executeSQL:fieldKeys:onConnection:intoResultTable:withError:]`（`MADAPI/Source/MADDatabase.m:147`，由全部三个驱动重写）。其目标类型是 `id <MADDataTableWriting>`——*任何*可写表，而不是某个表类。填充契约在各驱动之间是一致的：`removeAllObjects` → `addColumn:` → `beginBulkInsert` → `addRowWithDataForFieldKeys:` → `endBulkInsert`（`MAD_DATA_OBJECT` 的驱动：MySQL `MADMySQLFetch+DataTable.m:148-235`、SQL Server `MADDatabaseSQLServer.m:485-571`、Sqlite3 `MADDatabaseSqlite3.m:474-540`）。

当查询遵循 `MADQueryDataTableProtocol` 时，驱动也已经优先使用查询自己的目标表而不是文档的（`MADQuery.h:28-50`；每个驱动的 `-executeQuery:` 都会检查它——例如 `MADDatabaseMySQL.m:331-339`）。每个进程多个结果表是一个有意的扩展点，目前只有示例数据查询系列在使用。

文档级的拼接是 `MADOperationRefresh`（`MADDesigner/Source/MADOperationRefresh.m`，131 行，零 UIKit）：凭据输入，`document.mainQuery` → SQL，`document.database` 连接，执行进 `document.dataTable`，`dataTableMakeCache` 写出 `.mdcache`，`document.refreshed = YES`。它也是 CLI 的 refresh 动词，通过 `CLI/build.sh` 的 `REFRESH_SOURCES` 跨目标边界编译（`ROADMAP.md` 第 3.4 节）。它是*刷新 + 持久化 + 发布*，而不是*执行*：它硬连线到共享的文档状态，通过检查 `self.dependencies` 发现凭据，并修改文档。

### 3.4 返回值已存在——`MADDataTable` 和 `MADDataColumn`

`MADDataTable`（`MADFoundation/Source/MADDataTable.h`）是类簇，其全部职责就是“架构加行”：基类上有元数据和持久化，每个子类有各自的存储（`MADDataTableVirtual` 在内存中，`MADDataTableFast` 基于 SQLite）。架构对象是 `MADDataColumn`——`identifier`、`fieldName`、`caption`、`type`（`MADDataType`）、`nativeType`、`dataLength`、`dataPercision`、`isPrimaryKey`、`isNotNull`、`isAutoIncrement`、`defaultValue`——一个一等的、可序列化的列描述。

而且架构在磁盘上已经可以与行分离：`-copyPlist`（`MADDataTable.m:238-253`）序列化名称 + 列键 + 列 plist + 行计数器，**明确不含行**——这正是 `.mdcache` 文件的内容，由 `MADDataTableFast` 写入和读取（`-copyPlist` / `-loadWithPlist:`；`MAD_FORMAT.md` 第 5.3 节）。

这一层缺少的是：

- **没有仅架构的 API。** 没有任何东西能在不执行查询的情况下返回其结果架构。架构和数据是一个对象，从来不是两个——架构是*从*行中发现的。
- **零行 Sqlite3 结果会完全丢失架构。** Sqlite3 驱动只在第一次 `SQLITE_ROW` 迭代中才发现列（`MADDatabaseSqlite3.m:496-535`），因此空结果会产生一个没有列、也没有 DDL 的表。MySQL 和 SQL Server 在任何行到达之前就从结果元数据添加列，所以这个缺口是 Sqlite3 特有的。
- `MADDataTableFast` 的 `columnKeys` 是生成的 `c<hash>` 名称，而不是字段名；可用的架构表面是 `MADDataColumn` 的 `columns` 字典。而且 `for (x in fastTable)` 会静默地什么都不产出——基类返回 0 个项，而 Fast 没有重写 `countByEnumeratingWithState:`；调用方必须使用 `objectEnumerator`。

### 3.5 物化今天就是一张 SQLite 表

`MADDataTableFast` 不是对表的抽象；它*就是*表。每个实例在 `<tag>.maddb` 中拥有一张物理 SQLite 表 `t<tag>`（`-tableName` `MADDataTableFast.m:498`，`-filenameCacheMadDB` `:399`），列为 `c<hash-of-fieldName>`。第二个连接（`databaseForSelects`）负责 select 一侧。分组就是那张表上的索引（`-sortUsingDescriptors:` `:737`、`-setupGroupKeyIndexes` `:545`，每个分组前缀层级一个索引），聚合则是对缓存的 SQL（`MADQueryCacheAggregateFunction`，由 `MADocument -dataForRows:column:groups:function:groupBy:` 驱动）。**从不为源数据库生成 `GROUP BY`**——已验证：该字符串不出现在任何源文件中。源以扁平方式查询；一切分组或聚合都由 Sqlite3 在本地、在物化之上计算。

两个暴露意图的桩表明架构有理由想要*许多*表：类工厂 `MADDataTable+Constructor`（`newDataTableOfType:withObjectID:cacheDirectory:`——physical 映射到以 id 为 tag 的 `MADDataTableFast`，`:56-78`）在构造上让第二、第三张表变得廉价；而 `-cacheTableNameForGroupLevel:`（`MADDataTableFast.m:813`）会为每个分组层级命名一张 `s<level>` 表——它**没有调用方**；它所暗示的按分组表从未物化。

**地址就是文件名。** 文档的表用 `initWithId: fileURL.lastPathComponent.hash` 创建（`MADocument.m:269-283`）；缓存目录以 `dataTableIdHash` 命名（`MADURLFactory newURLCacheFilesDirectoryForFilename:`）。每个文档一张结果表；文档重命名时它的名字就会改变；没有任何东西能指向它。

### 3.6 一张表说清缺少什么

| 层 | 已有 | 数据对象所需但缺失 |
|---|---|---|
| 定义 | 完整的查询图；读模型；存储允许多个查询 | 自己的名称和身份；可以指向另一个数据对象的来源引用 |
| 编译器 | 从查询图生成确定性 SQL | 摆脱“文档的第一个查询”；仅架构的路径 |
| 执行 | 任何 `MADDataTableWriting` 目标；三个驱动；按查询的目标表 | 一个不是刷新的 execute——不修改文档，凭据是传入的而不是发现的 |
| 结果值 | `MADDataTable` + `MADDataColumn`；仅架构的持久化（`-copyPlist`） | 无需执行的架构 API；零行架构丢失 |
| 物化 | 真实的 SQLite 表 `t<tag>`；本地分组和聚合 | Tag = 文件名哈希；按约定每个文档一张表 |
| 绑定 | 布局 → `referencesQueryField` → 渲染时由 `MADDocumentObjectDataReference*` 解析 | 绑定到*某个*数据对象，而不是*文档的*单一查询 |
| 地址 | — | 一切 |

三个硬连线点是具体的阻碍，三者都在代码中可见：

1. `MADQueryFull` 忽略自己的查询对象（`MADQueryFull.m:147-149`）。
2. `MADDocument -dataTableForQuery:` 对 `MADQueryFull` 返回 `self.dataTable`，对其他一切返回 nil（`MADocument.m:908`）——一个单槽开关。
3. `MADQueryActiveQueryFields` 扫描存储中的**所有**元素、连接和分组，没有任何查询作用域（`MADQueryActiveQueryFields.m:27-99`），其头文件自己的 FIXME 写着：*“目前软件只处理一个查询对象。”* 第二个查询的字段会泄漏到第一个查询的 SELECT 列表中。

## 4. 契约

### 4.1 代码中的形态（提议、示意性）

两半，有意分开：

```objc
@protocol MADDataObjectSchema <NSObject>            // describe: no database needed
- (NSArray<MADDataColumn *> *)resultSchema;          // columns, types, from graph + snapshot
@end

@protocol MADDataObjectExecuting <NSObject>          // execute: yields the materialization
- (nullable MADDataTable *)executeIntoDataTable:(nullable MADDataTable *)target
                                      credentials:(MADCredentials *)credentials
                                            error:(NSError **)error;
@end
```

名称是示意性的；拆分才是重点。**Describe** 必须能在没有连接、没有凭据、没有行的情况下工作——仅凭查询图加上已存储的架构快照——因为这才是设计器绘制的内容、AI 验证所依据的内容、web 服务器列出的内容，以及文档重命名后不会破坏的内容。**Execute** 必须把目标表和凭据作为参数，并返回该表——不修改文档，于是 `MADOperationRefresh` 缩减为“调用 execute，然后持久化，然后发布”，CLI、服务器和测试调用的是同一个东西。

### 4.2 无需执行的架构

这是契约真实存在的最诚实的第一个证明，因为它是*可推导的*，而今天没有任何东西推导它：结果架构恰好就是 `MADQueryFull` 已经计算出的 SELECT 列表——活动查询字段，以 `Table.Field` 为别名，加上聚合和分组投影的任何内容。类型和宽度来自架构快照（`RptqDatabaseSchemaField`）；聚合列来自 `MADAggregateFunctionType`。工作在于把 SELECT 列表的构建从执行中拆分出来，并作为 `MADDataColumn` 返回。它还免费修复了零行 Sqlite3 缺口，一旦列先于行存在：驱动已经在 `addRow:` 之前 `addColumn:`，而表的 DDL 在第一个列上创建（`MADDataTableFast.m:526-543`）。

### 4.3 身份与地址

数据对象需要一个在重命名后仍存在的名称，以及一个在重新生成后仍存在的地址：

- **身份：** 存储行的 `identifier`，与每个其他 `Rptq` 实体一样，外加一个面向人的名称。物化 tag 变为对象的标识符哈希，而不是 `fileURL.lastPathComponent.hash`——为此目的，这会让以文件名为键的寻址退役（`MAD_FORMAT.md` 第 5.3 节的隐患；`MAD_FUTURE.md` 第 2.2 节“以内容哈希为键”的说明是渲染层的同一修复）。
- **地址：** 缓存目录已经为每个文档持有一个 `.maddb`；自然的形式化是其中**每个数据对象**一张 `t<tag>` 表（tag 已经使它们彼此不同），每张表带有自己的 `.mdcache` 风格架构 plist。每个对象一个 `.maddb` 文件（字面理解 `t<tag>`/`<tag>.maddb` 的配对）是替代方案；第 5.1 节说明何时它才重要。

### 4.4 存储在哪里改变——以及它已经允许什么

最小形态（推荐）：

- `RptqQuery` 增加一个名称（它已经是定义；没有任何东西移动）。
- `RptqQueryTable` 的引用——今天是一个 `RptqDatabase` 内的架构表 id——增加第二种类型：**另一个数据对象**。这是组合所需的唯一架构变更，而且是增量式的：带架构表引用的 v1 行，其含义与今天完全相同。
- 多源完全不需要存储变更：存储已经支持多行 `RptqDatabase`，每行有自己的查询（每个 `RptqQuery` 一个 `MADModelDatabase`，第 3.1 节）。今天的文档各有一个，是因为创建流程只创建一个；该架构在 2017 年就做了前瞻设计，至今仍在等待。

更重的替代方案——新增一个拥有定义的 `RptqDataObject` 实体，并把 `RptqQuery` 降级——命名更干净，但迁移更大。记录为决策 9.1。

## 5. 组合——子报表搭建，已记录，未构建

**本节有意未排期**（用户，2026-10-16：*“我不想把它搭起来……但我想把这个想法记录下来”*）。它存在，是为了在需要时它是一份计划，而不是一次发现。

### 5.1 机制，精确地说

1. 每个数据对象针对自己的源执行——自己的 `RptqDatabase`、驱动和凭据——并物化到自己的 SQLite 表（文档缓存中的一张 `t<tag>`，见第 4.3 节）。
2. 组合对象的查询图在种类上不变：它的“表”包括数据对象；连接、筛选和别名都适用，因为两边的一张表都是一组具名列。
3. 执行按对象 DAG 拓扑进行（与 `MADQueryFull` 已在连接图上运行的算法相同，`MADQueryFull.m:202`）：源先执行，组合对象最后执行，其结果像任何其他结果一样物化。
4. 组合对象**针对缓存、而不是远程数据库**执行——它是一个“数据库”为 `.maddb` 的查询。`MADSqlite3` 已经是一个完整的 `MADDatabase`，因此这一步的驱动今天就已经随附。一个持有若干 `t<tag>` 表的 `.maddb` 完全不需要 `ATTACH`；`ATTACH DATABASE` 是**分离文件**场景的变体——每个对象一个 `.maddb`，或来自*不同文档*的对象，这种情况下子报表边界就是文件边界，`ATTACH`（或复制进来）是唯一的连接途径。

一句话版本，也正是这是搭建而非项目的原因：**每个查询的结果已经是一张 SQLite 表，而 SQLite 已经是一个驱动。** 联邦引擎就在盒子里；它目前正以文件名哈希被寻址。

### 5.2 如果要做，会构建什么

1. 第 4 节的契约（describe/execute、身份、地址）——前提条件，而不是一个阶段。
2. 来源种类：`RptqQueryTable` → 数据对象；SQL 生成将其解析为对象的物化表，而不是 `db.table`。
3. 执行顺序：遍历 DAG；刷新过期的对象；然后执行组合查询。
4. 设计器的伸缩（用户的用词）：在“添加表”面板中，架构表旁边出现第二类来源——文档的其他数据对象，或者一个列出另一个对象输出字段的子报表框。连接 UI 不变；两端都是字段。
5. 当需要跨文件组合时，在 `MADDatabaseSqlite3` 中支持 `ATTACH`。

### 5.3 为什么它不是一行代码

记录在此，以便估算保持诚实：第 3.6 节的三个硬连线点（`MADQueryFull` 的重新读取、单槽的 `dataTableForQuery:`、无作用域的 `MADQueryActiveQueryFields`）都必须在第二个查询——更不用说*嵌套*查询——能够执行之前倒掉；`MADModelDocument` 在变更路径上只镜像 `firstQuery`（`MADModel_Layer.md` 第 8 节）；而 `RptqQuery -sortDescriptorsForDatabase:` 针对文档的单一缓存进行分组。没有一个困难；每一个对当前的单查询应用都是承重的。

## 6. CLI、web 服务器和引擎

用户的问题，2026-10-16：*“CLI 其实是为了测试、理解和未来使用……它很重要，但目标是有一个可以从 web 服务器调用的东西，我不知道 CLI 是不是做到这一点的最好方式。”*

就现有产物而言，诚实的答案是：

- **CLI 是引擎的客户端，而不是引擎。** 它的六个动词——`inspect`、`schema`、`query`、`refresh`、`export`、`write`——是第 3 节调用链的示例调用点：打开容器、读取存储、生成 SQL、执行到表中、渲染。web 服务器需要的是同一条调用链背后的一个稳定入口点；子进程是该链的一种绑定（`MAD_LINUX.md` 第 2 节勾画的形态：把 `mad --format json` 作为子进程），链接库是另一种，进程内 Objective-C/Swift API 是第三种。
- **入口点就是缺失的那块，而且它有名字。** 今天没有一个不依赖 UIKit 的顶层类能打开 `.mad`、运行查询并返回行：在 Apple 上，`MADocument` 是一个 `UIDocument`；CLI 的 `MADCLIDocument` 在*行为*上是无头的，但它要在运行循环上等待那个 UIDocument。（阶段 D 解决了无头一侧：`MADHeadlessDocument` 是 Linux 上的入口点，自阶段 E 起它还承载渲染那一半——`MADDocumentRenderProtocol`、`MADReportPageBuilder`——因此 `mad export` 在那里运行。`MAD_LINUX.md` 第 9 节。）第 4 节的契约正是这样一个入口点将要暴露的：打开 → 列出数据对象 → describe → execute →（架构，行）。
- **线上格式是一个决策，而不是三个。** 架构 + 行作为 JSON，与 JSON 导出（`MAD_CLI.md` 第 8.3 节、`ROADMAP.md` 决策表）以及 AI 层验证的结构化输出（`MAD_FUTURE.md` 第 7 节）是同一形态。`MADDataColumn` 已经是可 plist 化的列描述；`.mdcache` plist 已经是序列化的结果架构。公开地一次性设计 JSON 形态，导出、API 和 AI 都会消费它。
- **CLI 继续负责的是** `ROADMAP.md` 轨道 3 设定的纪律：在不启动应用的情况下让文档可见、以退出码（0–5）作为错误词汇、锁定格式的往返测试夹具。这些不会迁移到 web 服务器；它们正是 web 服务器的引擎保持诚实的方式。

“契约存在之后这很便宜”背后的实测事实：数据路径已经是无头的——SQL 生成、存储、`MADDataTableFast` 和全部三个驱动今天都能在 Linux 上编译，124 个测试可执行文件、1,270 个测试通过（`Linux/README.md`），并且自阶段 D 起 CLI 在该镜像中构建和运行（`inspect`、`schema`、`query`、`refresh`、`export`、`write`）。因此接下来的顺序是契约第一、入口点第二、前端第三——这使“CLI 还是 web 服务器？”成为一个两行答案的问题，而不是一次架构分叉。

## 7. 需要付出什么——在现有轨道上分阶段进行

排序使应用持续发布、套件始终保持绿色；每个阶段点明它所退役的第 3 节变更。

| 阶段 | 工作 | 退役 |
|---|---|---|
| 1 | **契约。** 把 `MADQueryFull` 的 SELECT 列表构建从执行中拆分；以 `MADDataColumn` 返回。添加 describe/execute 协议；让 `MADOperationRefresh` 调用它们。无行为变化。 | 没有仅架构的 API；零行 Sqlite3 架构丢失 |
| 2 | **查询拥有自己。** `MADQueryFull` 使用传给它的查询（不重新读取文档）；`-dataTableForQuery:` 按查询解析；`MADQueryActiveQueryFields` 作用于单个查询；`MADModelDocument` 镜像任何查询。一个文档，多个对象。 | 第 3.6 节的全部三个硬连线点 |
| 3 | **身份与地址。** 在存储中为对象命名；按对象标识符而非文件名标记物化；缓存中每个对象一张结果表；每个对象一个架构 plist。 | 以文件名哈希的物化；每文档一表 |
| 4 | **绑定与各种表面。** 布局绑定到数据对象的架构；CLI 新增 `describe`；JSON 形态一次性固定（导出 + API + AI）。 | 绑定到“文档的查询” |
| 5 | **组合**（第 5 节），仅在要求时。 | — |

阶段 1 是设计的真正载荷，也是最小的：它不需要存储变更、不需要 UI 变更、不需要新格式——它重新整理已经存在的代码，并且可以用当前套件加上对零行查询的架构断言来证明。阶段 2–4 是同一想法应用到持有单查询假设的各层。阶段 5 是搭建，已记录，未排期。

## 8. 不要做什么

- **现在不要构建多源搭建。** 用户的决定，2026-10-16；本文档是记录，不是队列项。（`TASKS.md`/`BUGS.md` 的约定适用：这里没有任何内容会因智能体的主动而启动。）
- **不要压缩或重新设计缓存。** 它是承重的，两遍设计需要它，`MAD_FORMAT.md` 第 5.1 节是长期有效的分析。
- **不要构建联邦引擎。** 根据第 1 节和第 5 节，物化就是联邦。
- **不要实现第二套 SQL 生成器或执行器。** 除寻址和排序之外的一切都已存在。
- **不要动那些有意死掉的东西**（`MADQueryDefinition*`、`RptqQuerySort`、`MADQueryFullTableEnumerator`、自由文本覆盖字段）作为本工作的一部分——它们是独立的整理决策。

## 9. 待定决策

1. **存储形态。** 给现有的 `RptqQuery` 命名（最小，推荐），还是引入 `RptqDataObject` 作为独立实体（更干净，迁移更大）？
2. **物化单位。** 每个文档一个 `.maddb`，每个对象一张 `t<tag>`（推荐——不需要 `ATTACH`，不新增文件），还是每个对象一个文件（组合时使用 `ATTACH`）？
3. **快照是什么。** `MAD_FUTURE.md` 第 2.2 节把物化对（`.maddb` + `.mdcache`）作为可共享的产物。在本设计下，共享的单位是数据对象的结果，还是文档？
4. **数据对象的架构向外暴露什么。** `MADDataColumn` 很丰富；名称 / 类型 / 长度才是 web 服务器和 AI 所需的。JSON 形态（一次性决策，第 6 节）是这一点被固定的地方。
5. **命名。** “数据对象”是用户和本文档的用词；`MAD_FUTURE.md` 把行业产物称为*模型*。在构建任何东西之前，两者之一应当胜出，因为它会落到存储实体、协议和 CLI 的动词里。

## 10. 贯穿主线

查询标签页已经构建了这个函数；刷新链已经编译并执行了它；结果表已经*是*一个架构和一个结果集，以 SQLite 形式存在于磁盘上；将要连接其中两个的驱动已经存在，并且已经在 Linux 上编译。它缺少的是一个名称、一个地址和一个 describe 那一半——正是把“报表的查询”变成数据对象、把数据对象变成另一个数据对象可用的表的三样东西。其余——子报表、多数据源、站在引擎之上的 web 服务器——是在此之上的组合，而之所以能精确组合，是因为无需发明任何新东西：它就是现有的管线，只是用一个比文件名哈希更好的东西来寻址。
