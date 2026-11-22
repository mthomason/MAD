---
layout: default
title: "将 SQL 粘贴到查询设计器"
description: "支持的 SQL 子集、解析器，以及应用路径。"
lang: zh-CN
---

# MAD SQL 录入——将 SQL 查询粘贴到查询设计器

本页记录 SQL 录入功能：支持的 `SELECT` 子集、解析器与解析器，以及把语句转换回可移植查询图的应用路径。阶段 A-D 已实现；阶段 E 推迟。

**范围：** `MAD/Source/sql/` 中新增的解析器/解析器/编译器、`MADocument` 上的应用路径、
`MADDesigner` 中的 SQL 浮出、持久化的源文本（§8，它增加了存储的第一次
版本化步骤），以及锁定这一切的测试。
**日期：** 2026-10-22，读取于 `cf0fe3acd`；2026-10-22 因持久化决策（§8）修订。
**状态：** 已实现——阶段 A–D 于 2026-10-22 落地，并以 `c48a39fb7` 合并进 master
（内部任务队列 §16）。阶段 E（§9）仍推迟；§8.1–§8.2 载有按实现所作的修订。

---

## 1. 目标

今天构建查询的唯一方式是可视化设计器：选择表、逐字段联接它们、添加筛选器、添加分组——
全部通过标签页 UI 完成。用户想要第二种入口：

> "…a user could hit a button and it flips around and shows a multiline text view where they
> can paste the SQL… when that SQL is saved, it manually creates the query in the backend of
> the report… it does everything it already would do with the user selecting all the details…
> the software still recognizes what fields are used what joins are used what tables are used,
> and it completely setups the document in the proper way, and then allows the user to even
> use the query designer with the fields entered by the standard query (if they wish to)."

因此：粘贴的 SQL 会被**编译进文档的查询模型**（`Rptq` 对象图），
经由可视化设计器所调用的完全相同的工厂。应用之后，可视化查询
设计器、可视化画布和报表设计器都会像查询是手工构建的那样看待它——
且用户可以继续在那里编辑。必须有一个校验阶段。

## 2. 今天存在什么（第一手读取）

### 2.1 规范查询模型——`Rptq` 图

文档的查询以普通 `Rptq*` 对象的形式存在于可移植存储中
（`MAD/Source/rptq/`）；`MADModel*` 层是它们的只读视图
（`MADModel_Layer.md`）。导入器只写 `Rptq` 行，别无其他。

* `RptqQuery`（`MAD/Source/rptq/autogen/RptqQuery.h:30-34`）：`hasQueryTables`、
  `hasQueryLinks`、`hasQueryPredicate`（注意是单数名称）、`hasQueryGroups`。
* `RptqQueryTable`——一个架构表引用加一个别名；别名是*计算出来的*：
  第一份副本用架构表名，之后为名称 + drop index
  （`Customer`、`Customer0`、……——`MADModelQueryTable.m:119-129`）。
* `RptqQueryField`——两个 id：`inQueryTable` + `databaseSchemaField`。每个查询表的每个字段都会有一行
  （添加表流程每个架构字段创建一行，
  `MADQueryViewController.m:762-770`）。
* `RptqQueryLinks`——一个联接：`hasLeftField`/`hasRightField`（各为一个 `RptqQueryField`）、
  `type`（`MADLinkType`，`MADQueryLinkType.h`：inner / equi / natural / cross / left / right
  / full outer）。每个联接恰好一对字段；生成器总是发出 `ON l = r`
  （`MADQueryFull.m:366-380`）。
* `RptqQueryPredicate`——`comparson`（`MADPredicateOperator`：`=`、`<>`、`>`、`>=`、`<`、
  `<=`——`MADPredicateOperator.h`、`RptqQueryPredicate+Extras.m:245-265`），加上一个
  左侧/右侧，要么是 `RptqQueryField`，要么是带类型的值字符串
  （`leftFieldID`/`rigthFieldID`）。所有谓词都以 AND 连接，每个写成 `(left op right)`
  （`MADQueryPredicate.m:43-93`）。无 OR、无 LIKE、无 IN、无函数。
* `RptqQueryGroup`——`hasField`、`sort`（`MADSortOrder`）、`weight` 和 `hasSection`：
  报表的分组头/尾带区（`RptqQueryGroup.h:24-29`）。

模型**不**持有什么——导入器必须尊重的边界：

* **无 SELECT 列表。** SELECT 在构建 SQL 时根据设计器元素（数据标签、聚合、条形码）、联接和分组
  引用了哪些查询字段推导出来
  （`MADQueryActiveQueryFields.m:37-97`、`MADQuerySelectExpressionActiveFields.m`）。
* **无自由 ORDER BY。** 排序顺序只按分组存在（`RptqQueryGroup.sort`）。
* **无 OR / IN / LIKE / 函数 / 子查询 / UNION**——它们都无法表示。
* **无存储的 SQL 文本**，也没有可用来添加列的存储版本化（下文 §8）。

### 2.2 SQL 生成——往返契约

`MADQueryFull` 从模型构建执行的 SQL
（`SQLOnlyActiveFields:managedObjectContext:error:`，`MADQueryFull.m:143-273`）：

* `SELECT` 部分来自驱动，然后是活动字段，按列别名排序，写出时
  **不带 `AS`**：`"Table0"."Field"`（`MADQuerySelectExpressionActiveFields.m:32-38, 46-53`）。
* `FROM`——对联接图做 DFS：`tableName <connector> queryAlias`，然后
  每个联接 `LEFT OUTER JOIN tableName <connector> queryAlias ON l.field = r.field`
  （`MADQueryFull.m:275-426`，联接文本来自 `RptqQueryLinks SqlForLinkType:`，
  `RptqQueryLinks+Extras.m:76-86`）。
* `WHERE`——以 AND 连接的谓词三元组（`MADQueryPredicate.m`）。
* SQL 中没有 `GROUP BY`/`ORDER BY`——分组和排序在
  `.maddb` 缓存上应用（`MADParameters+QueryCacheAggregate`、`MADQueryCacheSelectGroupKeys`）。
* 驱动提供的 `LIMIT` 子句。

因此导入器的契约是：**粘贴的语句恰好在它能成为某个模型的 `MADQueryFull` 输出时
被接受。** 这正是往返诚实的原因——SQL 浮出的 View 侧显示从导入模型重新生成的 SQL，
读起来就像用户所粘贴的。

### 2.3 刷新管线——校验所复用的模式

`MADOperationRefresh.m:60-172`：用操作依赖提供的凭据连接，
**在主队列上**构建 SQL（存储上下文归主队列所有——BUGS.md），然后
`[database executeSQL:fieldKeys:onConnection:intoResultTable:withError:]`
（`MADDatabaseProtocol.h:33`）和 `dataTableMakeCache`。校验探查是同样的
操作形态，减去缓存构建。

### 2.4 UI 已经调用的后端——编译器所复用的接缝

写入 `Rptq` 行并保存就够了；`MADModel*` 层通过存储通知把变更镜像进
UI（`MADModel_Layer.md` §3.3）。要调用的工厂，逐字取自
今天的 UI 代码：

* **添加表**——`[RptqQueryTable newQueryTableForSchemaTable:database:forManagedObjectContext:]`
  然后每个架构字段一个 `[RptqQueryField newQueryField:context]`，接线到该表，
  表加入 `query.hasQueryTables`，保存（`MADQueryViewController.m:744-799`）。
* **添加联接**——`[RptqQueryLinks newQueryLinksWithLeftField:rightField:joinType:managedObjectContext:]`
  然后 `[document.activeDocumentModel addQueryLink:link]`，保存
  （`MADQueryLinkBuilderController.m:112-122`）。
* **添加谓词**——`[RptqQueryPredicate newQueryPredicateFactoryWithLeftFieldID:…]` /
  `…WithLeftValue:…` 变体（`MADQueryAddPredicateController.m:142-162`、
  `RptqQueryPredicate+Extras.h:20-39`）。
* **添加分组**——`[document addQueryGroupWithQueryField:andSortOrder:]`
  （`MADocument.m:728-792`）。这一个调用创建分组行*以及*报表的分组
  头/尾带区*以及*它们的带区布局管理器——“completely sets up the
  document”，为 `GROUP BY` 免费做到。
* **删除，用于替换路径**——`removeGroupWitObjectID:fromManagedObjectContext:`
  （`MADocument.m:1130`）、`deleteDatafieldsRelatedToTable:inContent:` 和
  `deleteAggregateFieldRelatedToTable:inContent:`（`MADocument.h:91-95`），以及查询 UI 中既有的
  联接/谓词移除路径。阶段 B 会盘点这些；任何缺失的
  对称联接/谓词辅助方法都会在那里添加。

### 2.5 UI 接缝

查询构建器分栏视图控制器已有一个 `barButtonItemSQL` 工具栏项，它会
呈现一个**只读**的 `MADViewControllerSQL` 浮出（`MADQueryBuilderSplitViewController.m:31,
106-111`；`MADQuery.storyboard`；`MADViewControllerSQL.m:27-56` 显示
`[doc.mainQuery SQLOnlyActiveFields:…]`）。该功能是同一界面的一个模式，因此
按钮、浮出和导航都已存在。

## 3. 用户所见的该功能

1. 在查询标签页中，点击既有的 SQL 按钮。浮出现在有 **View / Edit** 模式。
2. **View** 以分段控件显示查询 SQL 的两种表示：
   * **Generated**——`MADQueryFull` 此刻从模型构建出的 SQL（今天的
     浮出内容，保留为默认标签）。
   * **As entered**——用户上次应用的语句，逐字
     （`RptqQuery.sqlSourceText`，§8）；当查询从未由粘贴的 SQL 构建过时
     隐藏或为空。
   两个标签都是只读的——“看到你粘贴了什么，以及它变成了什么”界面。
3. **Edit**——一个等宽多行文本视图，存在 `sqlSourceText` 时以它作为初始内容
   （用户重新编辑*他们自己的*文本，格式和注释保持不变），否则以生成的
   SQL 为初始内容；一个 **Revert to generated** 按钮从生成形式重新播种。
4. **Validate**——结构检查，以及当文档的数据库可到达时
   执行零行服务器探查（§7）。错误会带行号和列号返回。
5. **Apply**——语句被编译进文档（原子性——§6.5），且确切的
   粘贴文本被持久化为 `sqlSourceText`（§8）。浮出关闭；查询表
   列表、可视化画布和报表设计器都显示导入的结构。
   设计器的字段选择器照常工作。
6. 失败或冲突的应用不持久化任何东西——不存文本，不存任何行。先前的
   查询及其先前输入的文本保持原样。
7. 用户可随时切回：可视化设计器继续在导入的
   查询上工作，View 显示两种形式，Edit 重新打开他们自己的文字。

## 4. 架构

```
pasted SQL
  → MADSQLTokenizer        dialect-aware lexer; quotes per driver; tracks line:column
  → MADSQLParser           recursive descent; produces a MADSQLStatement parse tree
  → MADSQLStatementResolver  binds names to RptqDatabaseSchemaTable / RptqDatabaseSchemaField
  → [MADOperationValidateSQL]  server probe, when connected (§7); never writes
  → MADSQLQueryCompiler    the write plan: deletes + creates Rptq rows via the §2.4 factories
  → store save → model notifications → query UI / visualization / designer update
```

**位置。** 除探查操作和编辑器 UI 之外的一切都位于 `MAD`
框架中，纯 Foundation，无 UIKit——因此它能在 `MAD` 测试套件和 Linux
镜像中运行。新文件加入 `Linux/cmake/MADSources.cmake`，`./Linux/build.sh` 保持通过。
探查操作（需要驱动、凭据、UIKit 警报）和浮出 UI 位于
`MADDesigner/Source`。

**新文件。** `MAD/Source/sql/MADSQLTokenizer.{h,m}`、`MADSQLParser.{h,m}`、
`MADSQLStatement.{h,m}`（树及其值类型：`MADSQLColumnReference`、
`MADSQLPredicateTerm`、……）、`MADSQLStatementResolver.{h,m}`、`MADSQLQueryCompiler.{h,m}`、
`MADSQLCompileError.{h,m}`。应用：`MADOperationValidateSQL.{h,m}`（镜像
`MADOperationRefresh`），再加上 `MADViewControllerSQL` 中的编辑器改动，或同一 storyboard 接缝中的兄弟
编辑器控制器。

**一处小的 API 新增。** 词法器需要在连接存在之前获得每种方言的标识符引用符（MySQL
反引号、T-SQL 方括号、双引号）。给 `MADDatabase` 添加
`+ (NSString *)identifierQuoteCharacters`（默认：双引号），并在
`MADMySQL`/`MADTdsClient` 中按驱动覆盖（`MADPostgres` 使用默认双
引号）——或者，如更偏好，在通过
`MADDatabaseDriverRegistry` 解析的驱动协议上添加类方法。无论哪种都是三个方法的新增。

## 5. 支持的子集

导入器接受**恰好是模型能承载的语言**——一个 `SELECT`，任何地方都无
子查询，且每个子句都在 §2.1 的限制内：

* **SELECT 列表**——仅列引用：`col`、`tbl.col`、`schema.tbl.col`、`alias.col`，
  带引号或不带，加上 `alias.*` / `schema.tbl.*`。该列表*被校验并用于
  表/列发现*，而非存储（模型没有 SELECT 列表——§2.1）：每一列
  都必须可解析，且限定列所命名的表必须出现在 `FROM` 中。表达式、
  聚合、别名（`AS x`）和 `DISTINCT` 会被拒绝，并指向阶段 E（§9），
  即通过合成设计器元素让粘贴的列列表成真的阶段。
  输入的文本本身*会*逐字存储在 `sqlSourceText`（§8）中——校验形态
  与输入文本是两回事。
* **FROM**——一个表引用 `[schema.]name [AS alias]`，然后是一条链/树：
  `[INNER] JOIN`、`LEFT [OUTER] JOIN`、`RIGHT [OUTER] JOIN`、`FULL [OUTER] JOIN`，每个
  恰好一个等值条件 `l.col = r.col`（裸列、两段式或三段式 `schema.tbl.col`
  列；无歧义时允许裸列）。
  * 别名必须是架构表自身的名称（或其去点形式），或是同一张表的第二份副本的 drop-index
    形式（`name0`、`name1`、`schema.name0` 或去点形式的 `schemaname0`，匹配
    `RptqQueryTable -queryAlias`）——模型自行计算
    别名，无法承载重命名（`Customer AS c` 被拒绝：“the designer names
    tables itself”）。
  * 给定表对之间至多一个联接（生成器每个表对发出一个 `JOIN`；同一对之间的两个联接线会使别名
    加倍）。
  * 无逗号联接、无 `NATURAL`/`CROSS` 联接（联接模型恰好持有一对字段，
    且生成器总是写 `ON …`），`FROM`/`ON` 中无子查询。
* **WHERE**——比较 `left op right` 的合取（AND），`op` ∈
  `{ =, <>, >, >=, <, <= }`（`MADPredicateOperator` 集合），每侧是列引用
  或字面量。括号仅在不会改变扁平 AND 形态之处被接受。
  其他一切——`OR`、`IN`、`BETWEEN`、`LIKE`、`NOT`、函数、子查询——都会被
  拒绝：谓词模型只以 AND 连接扁平三元组，别无其他。
* **GROUP BY**——列引用，按顺序（weight）导入，每个通过
  `MADocument` 辅助方法成为一个分组，该方法还会创建报表的分组带区。
* **ORDER BY**——**仅当每一列都是 GROUP BY 列**时才被接受，且
  asc/desc 映射到各分组的排序顺序。否则被拒绝（模型中无自由排序）。
* **LIMIT**——被拒绝：应用会施加自己的设计器/报表模式限制
  （`MADDocument.limitResultsDesignMode`、`MADQueryFull.limitResults`）。

字面量在生成时按方言处理（`newSafeLiteral:`，
`MADDatabaseSQLProtocol.h`）；导入器只记录值字符串和字段的数据
类型，与谓词 UI 完全一致（`MADQueryPredicate.m:74-88`）。

拒绝从不静默：每一次都说明构造、子句、原因（它触及哪项
模型限制）以及行:列。

## 6. 解析与编译

### 6.1 解析器

* 别名（或裸表名）→ 按名称（不区分大小写）找到 `RptqDatabaseSchemaTable`。
  未知 → 错误“unknown table”。
* 列 → `RptqDatabaseSchemaField`：限定列必须存在于其表上；裸列必须在
  整个 `FROM` 集合中唯一，否则“ambiguous column”。

### 6.2 写入计划

解析器输出是一个值对象计划：有序表列表、联接列表（每个联接一个 `MADLinkType`）、
谓词列表（`MADPredicateOperator` + 左/右项）、带排序顺序的分组列表。
计划在写入任何东西之前整体校验。

### 6.3 冲突检查——应用是原子的

应用**替换**查询（粘贴的 SQL *就是*查询——这就是该功能）。写入之前，
检查新计划**不**包含的每张表是否被设计器元素引用——即
`MADQueryActiveQueryFields` 所知的三种形态
（`MADQueryActiveQueryFields.m:37-68`：标签数据、聚合、条形码引用），加上任何会被删除的
分组带区。若被丢弃表的字段被引用，则中止
并给出错误，说明涉及的元素（“this field is used by … in the designer”）；不删除任何东西，
不写入任何东西，旧查询仍可运行。这是导入无法做到
原子且静默的唯一情形，因此它会大声失败。

### 6.4 写入

按反向依赖顺序使用 §2.4 的辅助方法：移除联接和谓词，移除
分组（通过既有的分组移除路径，它会分离其带区和布局
管理器），移除不在计划中的表（通过既有的
`deleteDatafieldsRelatedToTable:` 家族），然后通过 UI 所调用的相同工厂创建表 → 联接 → 谓词 → 分组。
一次保存；随后调用方把文档标脏
并自动保存，如添加表流程所做（`MADQueryViewController.m:796-799`）。

### 6.5 写入之后

不触碰 UI：存储通知路径会更新模型层和两个查询界面
（`MADModel_Layer.md` §3.3）。编译器返回一个摘要（表 / 联接 / 谓词 /
分组数量）供浮出使用。

## 7. 校验——两个层级

**结构（始终，离线）。** 解析 + 解析，§5–§6。错误是
`MADSQLCompileError` 域的 `NSError`，带代码、行、列和消息。当
文档的数据库不可达时，这就是全部功能。

**服务器探查（当能建立连接时）。** 包装语句：

```sql
SELECT * FROM (<user sql>) AS _mad_probe WHERE 1=0
```

派生表别名在 MySQL 中是必需的，在 T-SQL 中有效；`WHERE 1=0` 会被折叠，因此
探查编译查询并返回列元数据而不读取行。通过
`MADOperationRefresh` 形态运行它（`MADOperationRefresh.m:104-162`）：用操作依赖的凭据连接，
存储读取编组到主队列，结果经由
驱动的 `executeSQL:…intoResultTable:…`，使 `MADDataColumn` 给出名称和类型。随后探查
捕获静态解析无法捕获的东西——服务器端名称解析（大小写敏感性、
视图、保留字）、方言差异，以及服务器自身的语法错误，这些
会带服务器消息浮现。列名/类型会与解析出的
架构字段比较，不匹配会作为警告报告，而非失败。

离线时，或凭据不可用时，探查被跳过，UI 提示
“validated by structure only.”

## 8. 持久化的源文本——`RptqQuery.sqlSourceText`

编译后的模型仍是执行的真相来源，但**用户粘贴的文本
是文档的一部分**：`RptqQuery` 上新增一个可空文本属性 `sqlSourceText`，
逐字保存最后一次成功应用的语句。删除用户的文字从来不是
一个选项——文档保留输入及其编译结果。用户选择了单一
属性而非历史数组（2026-10-22）；修订历史以后可以作为
有序的 to-many 添加，并从当前文本回填，无数据丢失。

持久化规则：

* 仅由成功的 Apply 写入，整体替换；失败或冲突的应用
  既不触碰存储行，也不触碰该文本（§3.6）。
* Edit 视图在存在时以它为初始内容；View 标签把它作为 **As entered** 显示在
  **Generated** 旁边（§3.2-3.3）。

### 8.1 存储变更

该属性落在架构交叉检查的两侧：编译后的模型和
手工维护的 `MADStoreSchema` 描述符，加上 `RptqQuery` autogen 属性
（`MAD/Source/rptq/autogen/`）。`MAD_FORMAT.md` 的字段列表新增该列。

**修订（阶段 A，2026-10-22）。** 模型变更是**新的 `MAD 4.xcdatamodel`
版本**，而非就地编辑 `MAD 3`：已发布模型版本的哈希固定了每个
在野文档的存储元数据，编辑它会使它们成为孤儿。`MAD 4` 还移除了
`RptqDocumentElementBarcode.barcodeBorderType` 中已死的 `elementID="type"`（没有早于 `MAD 3`
的版本拥有条形码实体；BUGS.md）。

### 8.2 存储版本化——新增、小型，且现在必需

可移植存储今天没有版本化（`MADStore.m` 不携带 `user_version` pragma）。
该阶段添加该机制，刻意保持最小：

* `MADStoreSchema` 获得一个版本常量和一个有序的迁移步骤列表。今天
  该列表有一项：版本 1（在野的架构——`user_version` 缺失或为 0）
  → 版本 2（`ALTER TABLE` 添加 `sqlSourceText`）。
* 打开时，`MADStore` 读取 `PRAGMA user_version`，在一个
  事务中应用缺失的步骤，并写入新版本。全新存储以当前版本创建
  （`createSchemaSQL` 已生成整个架构）。
* `MADLegacyStoreConversion` 的流程不受影响——转换后的 Core Data 文档通过同一个 `MADStore` 打开路径
  以当前版本创建。
* Linux 无头引擎编译同样的 `MADStore` 代码，因此现有文档在镜像中
  同样打开；迁移测试也在那里运行。

**修订（阶段 A，2026-10-22）。** `MADStoreConverter` 现在以
匹配其元数据的 momd 版本打开每个遗留存储，绝不通过自动迁移：Core Data 无法
为该模型家族推断映射（条形码 `elementID` 冲突，BUGS.md），且
momd 当前模型不再是在野存储写入时所依据的版本。

### 8.3 已考虑并否决：guts 元数据 plist

guts 目录中随存储一起携带的元数据 plist 可以完全不动架构地
保存该文本。否决：查询数据属于存储的查询部分
（`MADStorePartQuery`——存储的契约是“三个部分，别无其他”，
`MADStoreSchema.h:12-13`），且无头引擎读取的是存储，而非 plist。

### 8.4 这解锁的未来

存储的已输入文本是产品地平线上由代理驱动的查询设计的天然输入面
（`MAD_FUTURE.md`）：一个代理——或一个人——写出语句，
下面的编译器把它变成文档，`sqlSourceText` 保留作为记录的提示词。
严格的编译模型架构正是让这一步可逐步推进的原因：当写入者
变成代理时，编译器没有任何变化。

## 9. 阶段

**阶段 A——持久化源文本：存储版本化（仅 MAD；Linux 通过）。**
1. `RptqQuery` 上的 `sqlSourceText`：编译模型 + `MADStoreSchema` 描述符 + autogen
   属性，一次改动（否则交叉检查测试会失败）。
2. §8.2 的版本化机制——版本常量、迁移列表、打开时 `user_version`
   读取/应用/写入、全新存储以当前版本创建。
3. 测试：`MADStoreSchemaTests` 两侧保持通过；新增迁移测试（§10.2）；
   `MAD_FORMAT.md` 更新。

验收：本阶段之前创建的文档能干净打开、获得该列、保留其
数据，并在 Linux 上往返；全新文档以当前版本诞生。本
阶段自包含——它在解析器之前且独立于解析器落地。

**阶段 B——黄金测试，然后解析器（仅 MAD；Linux 通过）。**
4. 锁定 `MADQueryFull` 每方言确切输出的黄金 SQL 测试（§10.1）——先写，
   使解析器针对真实生成器构建。
5. `MADSQLTokenizer`/`MADSQLParser`/`MADSQLStatement` + 标识符引用 API（§4）。
6. `MADSQLParserTests`——§5 的接受/拒绝矩阵、错误代码、行:列。

验收：`MADQueryFull` 能发出的每个受支持构造都能解析；每个被拒绝的
构造都以带代码、带位置的错误失败；MAD 套件和 `./Linux/build.sh` 通过。

**阶段 C——解析器 + 编译器（仅 MAD；Linux 通过）。**
7. `MADSQLStatementResolver`、带原子应用（§6）和
   成功时写入 `sqlSourceText`（§8）的 `MADSQLQueryCompiler`。
8. 删除辅助方法盘点；添加缺失的联接/谓词移除辅助方法。
9. `MADSQLQueryCompilerTests` + 不动点往返测试（§10.4）。

验收：应用一条语句产生与可视化设计器完全相同的 Rptq 行，
并逐字存储文本；在既有查询上应用不留下孤儿；冲突情形中止，
存储——及先前文本——不受触碰；不动点测试
通过。

**阶段 D——应用（MADDesigner）。**
10. §3 的 View/Edit 浮出、`MADOperationValidateSQL` 探查、摘要视图。
11. 使用样本文档（sqlite3 驱动——无需服务器）的 UI 测试（§10.6）。

验收：粘贴 → 校验 → 应用后，查询设计器和可视化中显示表/联接/谓词，
报表设计器中显示分组带区，刷新运行查询；View
显示生成的 SQL 和输入的文本；关闭并重新打开文档保留
输入的文本。

**阶段 E——推迟，有其自身的决定。**
* SELECT 列表物化：合成设计器元素（数据标签、聚合），使
  刷新恰好返回粘贴的列。在那之前，导入的查询与任何
  新文档行为相同——SELECT 从元素、联接和分组推导（§2.1）。
* 已应用语句的历史（若曾需要）：从
  当前 `sqlSourceText` 回填的有序 to-many（§8）——§8.4 由代理驱动的查询设计的天然
  伴侣。

## 10. 测试

### 10.1 锁定既有功能（先写）

* `MAD/MADTests` 中的**黄金 SQL 测试**（扩展 `MADQueryFullTests.m`，它今天
  只断言片段，`MADQueryFullTests.m:140-162`）：固定存储 fixture → 确切的
  期望 SQL 字符串，按驱动方言（MySQL、TDS 和 PostgreSQL 配置），覆盖别名命名
  和 drop-index 形式、每种联接类型、每个带字面量引用符的谓词运算符，
  以及活动字段排序。这些锁定解析器必须往返的生成器，且
  它们也在 Linux 镜像中运行。
* **往返契约**——见下面的不动点测试；它把生成器 ∪ 导入器
  锁定为一个系统。

### 10.2 存储持久化与迁移测试

* `MADStoreSchemaTests`——既有的交叉检查现在断言描述符和
  编译模型在 `sqlSourceText` 上一致（正是它迫使 §8.1 的两侧
  一起落地的测试）。
* 新增 `MADStoreMigrationTests`（MAD）：在版本 1 构建一个带行的磁盘存储
  （即今天的架构，`user_version` 缺失）→ 用新 `MADStore` 打开 → 该
  列存在，`user_version` 读出当前版本，且每个既有的行和
  关系都保留；全新存储以当前版本创建；打开两次是
  幂等的。这些也在 Linux 镜像中运行，因为无头引擎共享
  迁移代码。
* 编译器级断言（在 §10.4）：成功应用**逐字**存储文本——
  注释、空白、大小写——而冲突的应用保持先前文本不受触碰。

### 10.3 解析器测试——`MADSQLParserTests`（MAD）

* 词法器：每方言的引用标识符、带转义引号的字符串字面量、注释
  （`--`、`/* */`）、数字、运算符、大小写不敏感的关键字；错误位置。
* 解析器：完整的 §5 接受矩阵（单表、每种联接类型、联接链、包括
  drop-index 的别名、裸列和限定列、WHERE 合取、GROUP BY、
  ORDER BY ⊆ GROUP BY）和拒绝表（OR、IN、LIKE、子查询、UNION、DISTINCT、
  SELECT 中的表达式、多条件 ON、别名重命名、逗号联接、NATURAL/CROSS、
  LIMIT、未知表/列、歧义列、GROUP BY 之外的 ORDER BY）——每个断言
  错误**代码**和行:列，绝不只是消息。

### 10.4 编译器测试——`MADSQLQueryCompilerTests`（MAD）

带架构 fixture 的内存存储（`MADModelQueryTableTests` 所用的模式）：

* 顺利路径：应用 → 断言产生的 Rptq 行——表带正确的架构引用和
  每字段行，联接带正确的 `MADLinkType` 和左/右字段，谓词带
  正确的 `comparson` 和值字符串，分组带排序/权重**以及**创建的分组
  头/尾带区和布局管理器；保存一次；`sqlSourceText` 与输入
  语句完全相等（包括注释和空白）。
* 替换路径：在已填充的查询上应用 → 旧表/联接/谓词/分组消失，无
  孤儿行（按实体计数），新结构存在，且 `sqlSourceText` 被替换。
* 冲突路径：设计器元素引用被丢弃表的字段 → 错误，且
  前后快照显示存储未变——包括先前的 `sqlSourceText`。
* **不动点往返**：通过工厂构建模型 → 通过
  `MADQueryFull` 生成 SQL → 解析 → 编译进全新存储 → 再次生成 SQL → 两个 SQL
  字符串相等。正是这个测试*定义*了“the software recognizes what was
  pasted.”

### 10.5 校验测试

* 每驱动探查 SQL 构造（单元，在应用的测试目标中）：包装器、
  别名、`WHERE 1=0` 折叠——用伪造数据库，无服务器。
* `MADMySQLLiveTests.m` 风格的**实时测试**（无服务器时跳过）：有效的粘贴 SQL
  以期望的列名/类型干净探查；坏列返回服务器的
  错误；读取零行。

### 10.6 UI 测试——`MADDesignerUITests`

使用样本 `.mad`（sqlite3 驱动）：打开 SQL 浮出，切到 Edit，粘贴一个
带筛选器和分组的两表联接，Apply，然后断言查询表列表显示
两张表，可视化画布显示两个框和一个连接器，设计器显示
分组带区，且 View 模式显示重新生成的 SQL。然后关闭并重新打开
文档：**As entered** 标签仍显示确切的粘贴文本，**Generated**
标签仍显示编译查询的 SQL——文档保留了两者。

### 10.7 为可测试性而设的约束（对实现者具有约束力）

* 解析器/解析器/编译器：纯 Foundation、无 UIKit、无应用导入——MAD 套件和
  Linux 镜像会编译它们。
* 每个公开失败都是带代码的 `NSError`（`MADSQLCompileError`）；测试断言代码。
* 探查位于一个小型协议之后，以便单元测试伪造数据库；实时覆盖
  只存在于实时套件中（既有模式）。
* 编译器接收文档/上下文，绝不接收视图控制器；应用不传任何
  UI 形态的东西。
* 新 MAD 文件加入 `Linux/cmake/MADSources.cmake`；`./Linux/build.sh` 保持通过。
* 迁移机制位于共享 `MADStore` 代码中，带测试可引用的版本常量——
  绝不在仅 Apple 的路径中——使 Linux 套件能运行它。

## 11. 决策——与用户共同敲定（2026-10-22）

1. **严格子集。** 确认：模型无法承载的任何东西都会被拒绝并给出原因
   （§5）。无不由我们解析的 SQL 回退。
2. **应用替换查询**（原子，§6.3）。确认。
3. **GROUP BY 导入会自动创建报表的分组带区**——既有的
   `MADocument` 辅助方法做这件事，并保持原样。确认。
4. **SELECT 列表被校验而不存储，直到阶段 E**——在元素合成
   存在之前，导入的查询在刷新时返回联接/分组列，直到用户添加
   元素，与任何新文档完全一致。确认按阶段推进。
5. **粘贴的文本被持久化。** 确认——`RptqQuery` 上的 `sqlSourceText`，一个
   属性保存最后一次成功应用的语句（§8），显示为 **As entered**
   在 **Generated** 旁边。生成形式仍是刷新所执行的内容；存储文本
   不改变执行。曾考虑历史数组并搁置
   （§8，阶段 E）。
