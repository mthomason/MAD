---
layout: default
title: "数据对象"
description: "把报表的定义、架构和结果集作为同一个契约。"
lang: zh-CN
---

# 数据对象——报表的定义、架构与结果集

本页定义数据对象：把报表的定义、架构和结果集作为同一个契约。它是多源工作所依据的设计；格式规范描述的是今天已发布的文档。

**范围：** 2026-10-16 提出的概念——数据对象是什么、它在
本代码库中如何表示，以及形式化它需要什么。同一对话中描述的多源 / 子报表
搭建在此处作为契约的必然结果写下，刻意不构建。
**日期：** 2026-10-16，读取于 `445794e11`。
**状态：** 设计文档。它提出建议；不实现任何东西，此处也没有任何安排。
[项目愿景](../vision.html) §1——“a report is a function from data sources to a table”——是
本文件具体化并为其命名代码的愿景。

---

## 1. 这个想法，以及它不是什么

今天用户针对一个数据库（MySQL、SQL Server 或 Sqlite3）设计即席查询，
它返回一张数据表，报表通过布局工具构建在该数据之上。报表就是查询加布局。泛化是把查询那一半变成
对象：

> 数据对象是一个命名定义，产生一个**架构**和一个**结果集**——
> 报表的查询，从其布局中分离并被赋予身份，使其输出可以被
> 刷新、寻址，并被另一个数据对象用作来源。报表是数据
> 对象加上绑定到该对象列的呈现。

用户自己的话（2026-10-16）：*"something that returns a schema of sorts and a result
set, whereas the report is ad hoc query, reporting, and design."*

三个后果，下面逐一展开：

1. **查询成为产品边界。** 同一个对象服务于设计器（MAD Query 标签页所编辑的）、查看器（刷新所执行的）、CLI（`mad refresh`
   所运行的）、未来的 Web 服务器（端点所执行的）以及 AI（它起草、引擎校验的）。一个定义，多个消费者——只有
   当对象拥有自己的名称和架构时，这一点才成立。
2. **对象可以组合。** *"The idea would be to link multiple ones together. In the reporting
   world, this would be subreports"*（用户）。用数据的话说，它是派生表的 DAG：
   一个对象的输出是另一个对象的表，正如今天的架构表一样。
3. **来源会作为结果而倍增，而非作为功能。** 每个源数据库一个对象——每个都已携带自己的驱动和连接——物化，然后由其
   输出联接。用户的草图：*"you would query MySQL in a subreport, and you would query
   SQL Server in a subreport… and then you could link those reports together as tables in the
   query designer by their output."* [项目愿景](../vision.html) §1 说的是同一件事：无需联邦
   引擎；快照*就是*联邦。

它明确**不是**什么：

- 不是联邦引擎。没有新东西在一条语句中同时与 MySQL 和 SQL Server 对话；每个
  对象针对自己的来源执行，联接发生在已经本地化的结果之上。
- 不是第二套查询实现。SQL 生成器、驱动、结果表和
  SQLite 联接引擎都已存在；§5 只是它们之上的一层搭建。
- 不是对两遍拉取一切缓存范式的改变。缓存是关键承载，且
  刻意很大（`MAD_FORMAT.md` §5.1）；数据对象恰好产生缓存
  今天已持有的内容。

## 2. 术语，因为“架构”在本代码库中是四种不同的东西

| 术语 | 它是什么 | 今天的类 |
|---|---|---|
| **源架构** | 用户可查询的数据库的表和字段 | 实时浏览：`MADDatabaseTable` / `MADDatabaseField`（`MADAPI`）。快照：`RptqDatabaseSchemaTable` / `RptqDatabaseSchemaField`，在创建文档时导入一次 |
| **定义** | 查询图：哪些表、哪些字段、联接、筛选器、分组、排序 | `RptqQuery` + `RptqQueryTable` / `RptqQueryField` / `RptqQueryLinks` / `RptqQueryPredicate` / `RptqQueryGroup` |
| **结果架构** | 输出的列：名称、类型、原生类型、长度/精度、主键、非空 | `MADDataColumn`（每列一个），承载于表上 |
| **结果集** | 行 | `MADDataTable` 类簇；物化为 `MADDataTableFast` |
| **物化** | 磁盘上的结果集：SQLite 表及其序列化架构 | 文档缓存目录中的 `<tag>.maddb`（SQLite）+ `<tag>.mdcache`（plist，`MADDataTable -copyPlist`） |
| **快照** | `MAD_FUTURE.md` 的说法：一次物化被赋予名称、版本并变得可寻址 | 尚不存在；§4.3 是它如何开始 |
| **存储架构** | 与上述全部无关：文档自身的存储格式 | `MADStoreSchema`（`MAD/Source/rptq/store/`） |

文档今天持有定义和布局；物化位于其旁，以
文档（而非定义）为键。这种划分是正确的——`MAD_FORMAT.md` §5——本设计予以保留。

## 3. 这个想法今天如何表示

数据对象的每一部分都已存在，位于不同的层，为不同目的而构建。以下是每一部分的精确状态，
以及形式化将会捏合的接缝。

### 3.1 定义已存在——`RptqQuery` 及其图

查询图已足够完整以便编译：表（`RptqQueryTable`，带 `alias` 和
`dropIndex`，使一张架构表可被多次包含）、投影
（`RptqQueryField`——架构表 + 架构字段 id）、联接（`RptqQueryLinks`，带联接
类型）、筛选器（`RptqQueryPredicate`）、分组（`RptqQueryGroup`，经由 `RptqQuery -sortDescriptorsForDatabase:` 驱动排序描述符），
以及一条残留的排序行（`RptqQuerySort`，只被调试描述读取）。设计器通过 `MADModel*` 读模型编辑它
（“write through `Rptq`; read and observe through `MADModel`”——`MADModel_Layer.md`）。

分组是查询级定义，而非报表带区。`RptqQueryGroup.hasField`
命名查询所依据的字段，`sort` 命名其方向。为使查询运行，每个
分组的字段必须属于文档所选择的查询表
（`hasField.inQueryTable`）：分组被物化为结果行之上的有序键
（`-sortDescriptorsForDatabase:`），格式化器比较该键以找到分组
边界。报表分组头/尾带区只是该分组的呈现——
它可能不含任何显示分组字段的元素，而分组仍然发生。
任何布局都无法提供缺失的分组字段，因此字段为 nil 的分组，或不由所选查询表支撑的字段，是无效文档。设计器仍会构建并
标注这样的带区，以便看到损坏的分组；查询执行和渲染会以
`NSInvalidArgumentException` 拒绝它并记录该分组。

关于其身份的两个事实：

- `RptqQuery` 挂在 `RptqDatabase` 行上，并通过
  “每类的第一个”抵达文档：`RptqDatabase -defaultQuery` 是 `hasQueries.anyObject`
  （`RptqDatabase+Extras.m:88`），`RptqDocument -mainQuery` 同样如此（`RptqDocument+Extras.m:184`）。
- 存储已允许多个：`MADModelDocument` **每个 `RptqQuery` 行构建一个 `MADModelDatabase`**
  （`MADModelDocument.m:210-240`），代码自己的注释说“current
  versions of the software only use one database and query.” 这一基数
  是应用流程的约定，而非存储的。

### 3.2 编译器已存在——`MADQueryFull`

`MADQueryFull -copySQLWithManagedObjectContext:error:`（`MADQueryFull.m:133`）构建 SQL：
投影列来自 `MADQuerySelectExpressionActiveFields`，它向
`MADQueryActiveQueryFields` 询问报表*元素*、联接和分组所引用的每个字段；FROM/JOIN 由表和联接的 `MTGraph` 拓扑排序后编译
（`:170-204`）；谓词和字面量引用经由 `MADDatabase`
（`newSafeIdentifier:`、`newSafeLiteral:`）；`LIMIT` 经由 `sqlLimitClause:`。

这就是 `MAD_FUTURE.md` §3 视为差异化优势的确定性、自有 SQL 生成
——它存在，且是无头的（在 Linux 构建中，`MADSources.cmake:93`）。

**但它被焊死在文档上。** `MADQueryFull` 把它初始化时所带的查询存储在
`queryObject`（`:79`）中，却**从不使用它**：SQL 路径重新读取文档的第一个
数据库和第一个查询（`:147-149`）。并且它不实现 `-getSql:error:`（基类
返回 `@""`，`MADQuery.m:48`），所以通用的 `MADDatabase -executeQuery:withError:` 路径
根本无法运行文档的主查询。你交给它的查询对象并不决定
运行什么。

### 3.3 执行接缝已存在——`MADDatabase`

抽象点是
`-[MADDatabase executeSQL:fieldKeys:onConnection:intoResultTable:withError:]`
（`MADAPI/Source/MADDatabase.m:147`，由全部三个驱动重写）。其目标类型为
`id <MADDataTableWriting>`——*任何*可写表，而非某个表类。填充契约
在各驱动间一致：`removeAllObjects` → `addColumn:` → `beginBulkInsert` →
`addRowWithDataForFieldKeys:` → `endBulkInsert`（`MAD_DATA_OBJECT` 的驱动：MySQL
`MADMySQLFetch+DataTable.m:148-235`、SQL Server `MADDatabaseSQLServer.m:485-571`、Sqlite3
`MADDatabaseSqlite3.m:474-540`）。

当查询遵循 `MADQueryDataTableProtocol` 时，驱动也已优先使用查询自身的
目标表而非文档的（`MADQuery.h:28-50`；每个驱动的
`-executeQuery:` 都会检查——例如 `MADDatabaseMySQL.m:331-339`）。每进程多个
结果表是预期的扩展点，只被样本数据查询家族使用。

文档级缝合是 `MADOperationRefresh`（`MADDesigner/Source/MADOperationRefresh.m`，
131 行，零 UIKit）：凭据输入，`document.mainQuery` → SQL，`document.database`
连接，执行进 `document.dataTable`，`dataTableMakeCache` 写入 `.mdcache`，
`document.refreshed = YES`。它也是 CLI 的刷新动词，由
`CLI/build.sh` 的 `REFRESH_SOURCES` 跨目标边界编译（`ROADMAP.md` §3.4）。它是*刷新 +
持久化 + 发布*，而非*执行*：它硬接在共享文档状态上，通过检查 `self.dependencies` 发现
凭据，并变更文档。

### 3.4 返回值已存在——`MADDataTable` 与 `MADDataColumn`

`MADDataTable`（`MADFoundation/Source/MADDataTable.h`）是类簇，其全部职责
是“架构加行”：基类上的元数据加持久化，每个子类的存储
（内存中的 `MADDataTableVirtual`，SQLite 之上的 `MADDataTableFast`）。架构对象是
`MADDataColumn`——`identifier`、`fieldName`、`caption`、`type`（`MADDataType`）、`nativeType`、
`dataLength`、`dataPercision`、`isPrimaryKey`、`isNotNull`、`isAutoIncrement`、`defaultValue`
——一等、可序列化的列描述。

而且架构在磁盘上已可与行分离：`-copyPlist`
（`MADDataTable.m:238-253`）序列化名称 + 列键 + 列 plist + 行计数器，
**明确不含行**——这正是 `.mdcache` 文件，由
`MADDataTableFast` 写入和读取（`-copyPlist` / `-loadWithPlist:`；`MAD_FORMAT.md` §5.3）。

该层缺失的：

- **没有仅架构的 API。** 没有东西在不执行查询的情况下返回其结果架构。
  架构和数据是一个对象，从不是两个——架构是*从*行发现的。
- **零行 Sqlite3 结果完全失去架构。** Sqlite3 驱动只在第一个 `SQLITE_ROW` 迭代内部发现
  列（`MADDatabaseSqlite3.m:496-535`），因此空结果产生一个无列、无 DDL 的表。MySQL 和 SQL Server 在
  任何行到达之前就从结果元数据添加列，因此该缺口是 Sqlite3 特有的。
- `MADDataTableFast` 的 `columnKeys` 是生成的 `c<hash>` 名称，而非字段名；可用的
  架构表面是 `MADDataColumn` 的 `columns` 字典。且 `for (x in fastTable)`
  静默地产出空——基类返回 0 项，Fast 不重写
  `countByEnumeratingWithState:`；调用方必须使用 `objectEnumerator`。

### 3.5 物化今天是一张 SQLite 表

`MADDataTableFast` 不是表的抽象；它*就是*表。每个实例在 `<tag>.maddb` 中拥有
一张物理 SQLite 表 `t<tag>`（`-tableName` `MADDataTableFast.m:498`、
`-filenameCacheMadDB` `:399`），列为 `c<fieldName 的哈希>`。第二个连接
（`databaseForSelects`）运行选择侧。分组是那张表上的索引
（`-sortUsingDescriptors:` `:737`、`-setupGroupKeyIndexes` `:545`，每个分组前缀
级别一个索引），聚合是缓存之上的 SQL（`MADQueryCacheAggregateFunction`，由
`MADocument -dataForRows:column:groups:function:groupBy:` 驱动）。**从不为源数据库生成 `GROUP BY`**
——已核实：该字符串不出现在任何源文件中。源被扁平查询；一切分组或聚合都在本地、在
物化之上由 Sqlite3 计算。

两个透露真相的存根表明架构有理由想要*多张*表：类工厂
`MADDataTable+Constructor`（`newDataTableOfType:withObjectID:cacheDirectory:`——物理映射
到 `MADDataTableFast`，id 作为 tag，`:56-78`）在构造上使第二、第三张表廉价；
以及 `-cacheTableNameForGroupLevel:`（`MADDataTableFast.m:813`）会为每个分组级别命名一张
`s<level>` 表——它**没有调用者**；它所暗示的按分组表从未物化。

**地址就是文件名。** 文档的表以
`initWithId: fileURL.lastPathComponent.hash`（`MADocument.m:269-283`）创建；缓存目录
命名为 `dataTableIdHash`（`MADURLFactory newURLCacheFilesDirectoryForFilename:`）。每文档一张结果
表；其名称在文档重命名时改变；没有东西能指向它。

### 3.6 缺失什么，一张表

| 层 | 已存在 | 数据对象所缺 |
|---|---|---|
| 定义 | 完整查询图；读模型；存储允许多个查询 | 自己的名称和身份；可以是另一个数据对象的来源引用 |
| 编译器 | 从图生成确定性 SQL | 摆脱“文档的第一个查询”；仅架构路径 |
| 执行 | 任何 `MADDataTableWriting` 目标；三个驱动；每查询目标表 | 不是刷新的执行——不变更文档，凭据传入而非发现 |
| 结果值 | `MADDataTable` + `MADDataColumn`；仅架构的持久化（`-copyPlist`） | 无需执行的架构 API；零行架构丢失 |
| 物化 | 真实 SQLite 表 `t<tag>`；本地分组与聚合 | Tag = 文件名哈希；按约定每文档一张表 |
| 绑定 | 布局 → `referencesQueryField` → 渲染时由 `MADDocumentObjectDataReference*` 解析 | 绑定到*一个*数据对象，而非文档唯一的查询 |
| 地址 | — | 一切 |

三个硬接线点是具体的阻塞项，三者在代码中都可见：

1. `MADQueryFull` 忽略自己的查询对象（`MADQueryFull.m:147-149`）。
2. `MADDocument -dataTableForQuery:` 对 `MADQueryFull` 返回 `self.dataTable`，对其他
   一切返回 nil（`MADocument.m:908`）——一个单槽开关。
3. `MADQueryActiveQueryFields` 扫描存储中**所有**元素、联接和分组，没有
   查询作用域（`MADQueryActiveQueryFields.m:27-99`），其自身头文件的 FIXME：*"Right
   now the software only handles one query object."* 第二个查询的字段会泄漏进
   第一个查询的 SELECT 列表。

## 4. 契约

### 4.1 代码形态（建议，示意）

两半，刻意分离：

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

名称是示意；拆分才是要点。**Describe** 必须能在无
连接、无凭据、无行的情况下工作——来自图加存储的架构快照——
因为这是设计器所绘制的、AI 所校验的、Web 服务器所列举的，也是一份重命名文档无法破坏的。**Execute** 必须把目标表和
凭据作为参数并返回表——不变更文档，因此 `MADOperationRefresh`
缩小为“调用 execute，然后持久化，然后发布”，而 CLI、服务器和测试都
调用同一件事。

### 4.2 无需执行的架构

这是契约真实存在的第一个诚实证明，因为它是*可推导的*，而今天没有东西
推导它：结果架构恰是 `MADQueryFull` 已计算的 SELECT 列表——活动查询字段，
别名为 `Table.Field`，加上聚合和分组所投影的任何东西。类型和宽度来自架构快照
（`RptqDatabaseSchemaField`）；聚合列来自 `MADAggregateFunctionType`。工作是
把 SELECT 列表构造从执行中拆出，并作为 `MADDataColumn` 返回。它还
免费修复了零行 Sqlite3 缺口——就在列先于行存在的那一刻：驱动
已在 `addRow:` 之前 `addColumn:`，而表的 DDL 在第一个列时创建
（`MADDataTableFast.m:526-543`）。

### 4.3 身份与地址

数据对象需要一个在重命名后存活的名称，以及一个在重新生成后存活的地址：

- **身份：** 存储行的 `identifier`，像每个其他 `Rptq` 实体一样，加上一个
  面向人类的名称。物化 tag 变成对象的标识符哈希，而非
  `fileURL.lastPathComponent.hash`——这在此用途上退役了以文件名为键的
  寻址（`MAD_FORMAT.md` §5.3 隐患；`MAD_FUTURE.md` §2.2 的“content hash the key”
  注释是渲染层的同一修复）。
- **地址：** 缓存目录已为每文档持有一个 `.maddb`；自然的形式化是
  其中**每个数据对象**一张 `t<tag>` 表（tag 已使它们
  独特），每张都有自己的 `.mdcache` 式架构 plist。按对象的 `.maddb` 文件
  （把 `t<tag>`/`<tag>.maddb` 配对字面理解）是替代方案；§5.1 说明何时
  重要。

### 4.4 存储何处改变——以及它已经允许什么

最小形态，推荐：

- `RptqQuery` 获得名称（它已是定义；没有东西移动）。
- `RptqQueryTable` 的引用——今天是某个 `RptqDatabase` 内的架构表 id——获得
  第二种：**另一个数据对象**。这是组合所需的唯一架构变更，
  且是增量的：带架构表引用的 v1 行含义与今天完全相同。
- 多源完全不需要存储变更：存储已支持许多 `RptqDatabase`
  行，每行有自己的查询（每个 `RptqQuery` 一个 `MADModelDatabase`，§3.1）。今天的
  文档各有其一，是因为创建流程只做一个；架构在 2017 年就做了前瞻，
  至今仍在等待。

更重的替代方案——新增 `RptqDataObject` 实体拥有定义，把
`RptqQuery` 降级——是更干净的命名和更大的迁移。记录为决策 9.1。

## 5. 组合——子报表搭建，已记录，未构建

**本节刻意未排期**（用户，2026-10-16：*"I don't want to rig it
up… but I want to document this idea"*）。它的存在是为了当需要时，它是计划
而非发现。

### 5.1 机制，精确地说

1. 每个数据对象针对自己的来源——自己的 `RptqDatabase`、驱动和
   凭据——执行，并物化进自己的 SQLite 表（文档缓存中的 `t<tag>`，按 §4.3）。
2. 组合对象的查询图在种类上不变：其“表”包括数据对象；
   联接、筛选器和别名都适用，因为两侧的表都是具名
   列的集合。
3. 执行在对象 DAG 上按拓扑顺序（与 `MADQueryFull` 已在联接图上运行的同一算法，
   `MADQueryFull.m:202`）：来源在前，组合对象最后，其结果
   像任何其他结果一样物化。
4. 组合对象**针对缓存而非远程数据库**执行——它是一个其“数据库”为 `.maddb` 的查询。
   `MADSqlite3` 已是完整的 `MADDatabase`，因此这一步的驱动
   今天已随附。一个 `.maddb` 持有多个 `t<tag>` 表完全不需要
   `ATTACH`；`ATTACH DATABASE` 是**独立文件**的变体——每对象一个 `.maddb`，
   或来自*不同文档*的对象，即子报表边界是文件边界、`ATTACH`（或拷入）是唯一联接路径的情形。

一句话版本，也是这件事为何是搭建而非项目的原因：**每个查询的结果已经是一张 SQLite 表，而 SQLite 已经是一个驱动。** 联邦引擎就在盒子里；它目前
以文件名哈希寻址。

### 5.2 若想要，会构建什么

1. §4 的契约（describe/execute、身份、地址）——前提条件，而非阶段。
2. 来源种类：`RptqQueryTable` → 数据对象；SQL 生成把它解析为
   对象的物化表，而非 `db.table`。
3. 执行顺序：遍历 DAG；刷新过期对象；然后是组合查询。
4. 设计器的伸缩（用户的说法）：在 Add Table 面板中，架构表旁的第二类
   来源——文档的其他数据对象，或一个列出其他对象输出字段的子报表框。
   联接 UI 不变；两端都是字段。
5. 若曾需要跨文件组合，在 `MADDatabaseSqlite3` 中支持 `ATTACH`。

### 5.3 为何它不是一行代码

记录下来以使估算保持诚实：§3.6 的三个硬接线点
（`MADQueryFull` 的重新读取、单槽 `dataTableForQuery:`、无作用域的
`MADQueryActiveQueryFields`）都必须在第二个查询——更不用说*嵌套*
查询——能执行之前倒下；`MADModelDocument` 在变更路径上只镜像 `firstQuery`
（`MADModel_Layer.md` §8）；且 `RptqQuery -sortDescriptorsForDatabase:` 针对
文档单一缓存分组。没有一个是难的；全都是当前单查询应用的关键承载。

## 6. CLI、Web 服务器与引擎

用户的问题，2026-10-16：*"the CLI is really for testing, understanding, and future
use… it's important, but the goal is to have something that can be called from the webserver,
and I don't know if the CLI is the best way to do that."*

就产物现状而言，诚实的回答：

- **CLI 是引擎的客户端，而非引擎。** 它的六个动词——
  `inspect`、`schema`、`query`、`refresh`、`export`、`write`——是 §3 调用链的样本调用点：
  打开容器、读取存储、生成 SQL、执行进表、渲染。Web 服务器所需的
  是同一调用链背后稳定的入口点；子进程是该调用链的一种
  绑定（`MAD_LINUX.md` §2 勾画的形态：`mad --format json` 作为
  子进程），链接库是另一种，进程内 Objective-C/Swift API 是第三种。
- **入口点就是缺失的那块，而且已命名。** 今天没有无 UIKit 的
  顶层类能打开 `.mad`、运行查询并返回行：在 Apple 上，
  `MADocument` 是 `UIDocument`；CLI 的 `MADCLIDocument` 在*行为*上无头，却
  为该 UIDocument 等待运行循环。（阶段 D 解决了无头侧：
  `MADHeadlessDocument` 是 Linux 上的入口点，且自阶段 E 起它还携带渲染
  那一半——`MADDocumentRenderProtocol`、`MADReportPageBuilder`——因此 `mad export` 在那里运行。
  `MAD_LINUX.md` §9。）§4 的契约正是这样一个入口点会暴露的：
  打开 → 列出数据对象 → describe → execute →（架构、行）。
- **线格式是一个决定，不是三个。** 架构 + 行作为 JSON 与
  JSON 导出（`MAD_CLI.md` §8.3、`ROADMAP.md` 决策表）以及 AI 层所校验的结构化输出
  （`MAD_FUTURE.md` §7）是同一形态。`MADDataColumn` 已是可 plist 化的列
  描述；`.mdcache` plist 已是序列化的结果架构。一旦公开设计 JSON
  形态，导出、API 和 AI 都消费它。
- **CLI 继续负责的**是 `ROADMAP.md` Track 3 所设定的纪律：
  应用让路时文档依然可见、退出码（0–5）作为错误词汇、
  锁定格式的往返 fixture。那些不搬到 Web 服务器；它们是
  Web 服务器引擎保持诚实的方式。

“契约存在后这很便宜”背后的实测事实：数据路径已经
无头——SQL 生成、存储、`MADDataTableFast` 和全部三个驱动今天都在
Linux 上编译，124 个测试可执行文件和 1,270 个测试通过（`Linux/README.md`），且自
阶段 D 起 CLI 在该镜像中构建并运行（`inspect`、`schema`、`query`、`refresh`、
`export`、`write`）。因此接下来的顺序是契约第一、入口点第二、
前端第三——它使“CLI 还是 Web 服务器？”成为一个两行回答的问题，
而非架构分叉。

## 7. 需要什么——按阶段，在既有轨道上

排序使应用持续发布、套件全程通过；每个阶段命名它所退役的 §3 变更。

| 阶段 | 工作 | 退役 |
|---|---|---|
| 1 | **契约。** 把 `MADQueryFull` 的 SELECT 列表构造从执行中拆出；作为 `MADDataColumn` 返回。添加 describe/execute 协议；让 `MADOperationRefresh` 调用它们。无行为变化。 | 无仅架构 API；零行 Sqlite3 架构丢失 |
| 2 | **查询拥有自己。** `MADQueryFull` 采用所给查询（不重新读取文档）；`-dataTableForQuery:` 按查询解析；`MADQueryActiveQueryFields` 限定到查询；`MADModelDocument` 镜像任何查询。一个文档，多个对象。 | §3.6 的全部三个硬接线点 |
| 3 | **身份与地址。** 在存储中命名对象；按对象标识符而非文件名标记物化；缓存中每对象一张结果表；每对象架构 plist。 | 文件名哈希物化；每文档一张表 |
| 4 | **绑定与表面。** 布局绑定到数据对象的架构；CLI 增加 `describe`；JSON 形态一次固定（导出 + API + AI）。 | 绑定到“文档的查询” |
| 5 | **组合**（§5），仅在被要求时。 | — |

阶段 1 是设计的真正载荷，也是最小的：它不需要存储变更、不需要 UI
变更、不需要新格式——它重排已存在的代码，且可由
当前套件加上零行查询的架构断言证明。阶段 2–4 是同一想法
应用于持有单查询假设的各层。阶段 5 是搭建，已记录，
未排期。

## 8. 不要做什么

- **现在不要构建多源搭建。** 用户的决定，2026-10-16；本文档是
  记录，而非队列项。（`TASKS.md`/`BUGS.md` 约定适用：此处没有东西
  在代理主动发起时开始。）
- **不要压缩或重新设计缓存。** 它是关键承载，两遍设计需要它，
  `MAD_FORMAT.md` §5.1 是常设分析。
- **不要构建联邦引擎。** 按 §1 和 §5，物化就是
  联邦。
- **不要实现第二个 SQL 生成器或执行器。** 除寻址和
  排序外，一切已存在。
- **不要作为此项的一部分触碰刻意已死的东西**（`MADQueryDefinition*`、`RptqQuerySort`、
  `MADQueryFullTableEnumerator`、自由文本覆盖字段）——它们是
  单独的整理决定。

## 9. 未决决策

1. **存储形态。** 命名已有的 `RptqQuery`（最小，推荐），还是引入
   `RptqDataObject` 作为自己的实体（更干净，迁移更大）？
2. **物化单元。** 每文档一个 `.maddb`，每对象一个 `t<tag>`
   （推荐——无 `ATTACH`、无新文件），还是每对象一个文件（组合时
   `ATTACH`）？
3. **快照是什么。** `MAD_FUTURE.md` §2.2 使物化对
   （`.maddb` + `.mdcache`）成为可共享产物。在本设计下，共享单元
   是数据对象的结果，还是文档？
4. **数据对象的架构向外暴露什么。** `MADDataColumn` 很丰富；
   名称/类型/长度才是 Web 服务器和 AI 所需。JSON 形态（一次决定，§6）是
   固定这一点的地方。
5. **命名。** “Data object”是用户和本文档的术语；`MAD_FUTURE.md` 把该
   行业产物称为*模型*。构建任何东西之前二者之一应胜出，因为它
   会落在存储实体、协议和 CLI 的动词中。

## 10. 主线

查询标签页已构建该函数；刷新链已编译并执行它；
结果表*就是*磁盘上作为 SQLite 的架构加结果集；会联接其中两个的驱动
已存在，且已在 Linux 上编译。它缺少的是
名称、地址和 describe 那一半——这三样把“报表的查询”变成
数据对象，把数据对象变成另一个数据对象可用的表。其余——子报表、
多来源、立于引擎之上的 Web 服务器——是其上的组合，且恰好
能组合，因为无需发明任何新东西：它就是既有管线，以比
文件名哈希更好的东西寻址。
