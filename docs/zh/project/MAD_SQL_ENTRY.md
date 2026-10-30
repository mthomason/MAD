---
layout: default
lang: zh-CN
---

# MAD SQL 录入——把 SQL 查询粘贴到查询设计器中

**范围：** `MAD/Source/sql/` 中一个新的解析器/名称解析器/编译器，`MADocument` 上的一条应用路径，`MADDesigner` 中的 SQL 弹出面板，持久化的源文本（§8，它加入存储的第一个版本化步骤），以及固定这一切的测试。
**日期：** 2026-10-22，基于 `cf0fe3acd` 阅读；2026-10-22 根据持久化决定（§8）修订。
**状态：** 已实现——阶段 A–D 于 2026-10-22 落地，并以 `c48a39fb7` 合并进 master（docs/project/TASKS.md §16）。阶段 E（§9）仍然推迟；§8.1–§8.2 载有建成后的修正。

---

## 1. 目标

今天构建查询的唯一方式是可视化设计器：挑选表、逐字段连接、添加筛选条件、添加分组——全部通过分页 UI 完成。用户想要第二种入口：

> “……用户可以按一个按钮，界面翻转过来，显示一个多行文本视图，让他们可以
> 粘贴 SQL……当这段 SQL 被保存时，它会在报表的后端手工创建查询……
> 它会完成用户选中所有细节时原本会做的一切……
> 软件仍然识别使用了哪些字段、哪些连接、哪些表，
> 它以正确的方式完整搭建文档，然后甚至允许用户
> 用按标准查询输入的字段继续使用查询设计器（如果他们愿意）。”

因此：粘贴的 SQL 会被**编译进文档的查询模型**（`Rptq` 对象图），经由与可视化设计器完全相同的工厂。应用之后，可视化查询设计器、可视化画布和报表设计器都会把该查询视为手工构建的一样——用户还可以继续在那里编辑它。必须有一个校验阶段。

## 2. 今天已存在什么（第一手阅读）

### 2.1 规范查询模型——`Rptq` 图

文档的查询以普通 `Rptq*` 对象的形式存在于可移植存储中（`MAD/Source/rptq/`）；`MADModel*` 层是对它们的只读视图（`MADModel_Layer.md`）。导入器只写入 `Rptq` 行，别无其他。

* `RptqQuery`（`MAD/Source/rptq/autogen/RptqQuery.h:30-34`）：`hasQueryTables`、`hasQueryLinks`、`hasQueryPredicate`（注意这是单数名）、`hasQueryGroups`。
* `RptqQueryTable`——一个架构表引用外加一个别名；别名是*计算*出来的：第一份副本用架构表自身的名称，之后为名称 + drop index（`Customer`、`Customer0`、…——`MADModelQueryTable.m:119-129`）。
* `RptqQueryField`——两个 id：`inQueryTable` + `databaseSchemaField`。每个查询表的每个字段都有一行（添加表流程会为每个架构字段创建一行，`MADQueryViewController.m:762-770`）。
* `RptqQueryLinks`——一个连接：`hasLeftField`/`hasRightField`（各为一个 `RptqQueryField`）、`type`（`MADLinkType`，`MADQueryLinkType.h`：inner / equi / natural / cross / left / right / full outer）。每个连接恰好一对字段；生成器始终输出 `ON l = r`（`MADQueryFull.m:366-380`）。
* `RptqQueryPredicate`——`comparson`（`MADPredicateOperator`：`=`、`<>`、`>`、`>=`、`<`、`<=`——`MADPredicateOperator.h`、`RptqQueryPredicate+Extras.m:245-265`），外加一个左/右侧，它是 `RptqQueryField` 或带类型的值字符串（`leftFieldID`/`rigthFieldID`）。所有谓词都以 AND 连接，每个写作 `(left op right)`（`MADQueryPredicate.m:43-93`）。不支持 OR、LIKE、IN 或函数。
* `RptqQueryGroup`——`hasField`、`sort`（`MADSortOrder`）、`weight` 和 `hasSection`：报表的分组页眉/页脚区段（`RptqQueryGroup.h:24-29`）。

模型**不**持有的内容——导入器必须遵守的边界：

* **没有 SELECT 列表。** SELECT 在构建 SQL 时推导，取决于哪些查询字段被设计器元素（数据标签、聚合、条码）、连接和分组所引用（`MADQueryActiveQueryFields.m:37-97`、`MADQuerySelectExpressionActiveFields.m`）。
* **没有自由的 ORDER BY。** 排序顺序只按分组存在（`RptqQueryGroup.sort`）。
* **没有 OR / IN / LIKE / 函数 / 子查询 / UNION**——这些都不可表示。
* **没有存储的 SQL 文本**，也没有可用于新增列的存储版本化（见下文 §8）。

### 2.2 SQL 生成——往返契约

`MADQueryFull` 从模型构建被执行的 SQL（`SQLOnlyActiveFields:managedObjectContext:error:`，`MADQueryFull.m:143-273`）：

* `SELECT` 部分来自驱动，然后是活动字段，按列别名排序，写出时**不带 `AS`**：`"Table0"."Field"`（`MADQuerySelectExpressionActiveFields.m:32-38, 46-53`）。
* `FROM`——在连接图上做 DFS 遍历：`tableName <connector> queryAlias`，然后每个连接 `LEFT OUTER JOIN tableName <connector> queryAlias ON l.field = r.field`（`MADQueryFull.m:275-426`，连接文本来自 `RptqQueryLinks SqlForLinkType:`，`RptqQueryLinks+Extras.m:76-86`）。
* `WHERE`——以 AND 连接的谓词三元组（`MADQueryPredicate.m`）。
* SQL 中没有 `GROUP BY`/`ORDER BY`——分组和排序在 `.maddb` 缓存之上应用（`MADParameters+QueryCacheAggregate`、`MADQueryCacheSelectGroupKeys`）。
* 由驱动提供的 `LIMIT` 子句。

因此导入器的契约是：**一条粘贴的语句恰好在其可能是某个模型经 `MADQueryFull` 输出的结果时才可接受。** 这正是往返之所以诚实的原因——SQL 弹出面板的 View 一侧显示从导入模型重新生成的 SQL，读起来就像用户粘贴的内容。

### 2.3 刷新管线——校验所复用的模式

`MADOperationRefresh.m:60-172`：用操作依赖提供的凭据连接，**在主队列上**构建 SQL（存储上下文归主队列所有——BUGS.md），然后 `[database executeSQL:fieldKeys:onConnection:intoResultTable:withError:]`（`MADDatabaseProtocol.h:33`）和 `dataTableMakeCache`。校验探针是同样的操作形态，只是少了缓存构建。

### 2.4 UI 已经在调用的后端——编译器复用的接缝

写入 `Rptq` 行并保存就够了；`MADModel*` 层通过存储通知把变更镜像到 UI（`MADModel_Layer.md` §3.3）。要调用的工厂，逐字取自今天的 UI 代码：

* **添加表**——`[RptqQueryTable newQueryTableForSchemaTable:database:forManagedObjectContext:]`，然后每个架构字段一个 `[RptqQueryField newQueryField:context]`，接到该表上，把表加入 `query.hasQueryTables`，保存（`MADQueryViewController.m:744-799`）。
* **添加连接**——`[RptqQueryLinks newQueryLinksWithLeftField:rightField:joinType:managedObjectContext:]`，然后 `[document.activeDocumentModel addQueryLink:link]`，保存（`MADQueryLinkBuilderController.m:112-122`）。
* **添加谓词**——`[RptqQueryPredicate newQueryPredicateFactoryWithLeftFieldID:…]` / `…WithLeftValue:…` 变体（`MADQueryAddPredicateController.m:142-162`、`RptqQueryPredicate+Extras.h:20-39`）。
* **添加分组**——`[document addQueryGroupWithQueryField:andSortOrder:]`（`MADocument.m:728-792`）。这一次调用创建分组行*以及*报表的分组页眉/页脚区段*以及*它们的区段布局管理器——为一个 `GROUP BY` 免费“完整搭建文档”。
* **删除，用于替换路径**——`removeGroupWitObjectID:fromManagedObjectContext:`（`MADocument.m:1130`）、`deleteDatafieldsRelatedToTable:inContent:` 和 `deleteAggregateFieldRelatedToTable:inContent:`（`MADocument.h:91-95`），以及查询 UI 中现有的连接/谓词移除路径。阶段 B 会清点这些；任何缺失的连接/谓词对称辅助方法都会在那里补上。

### 2.5 UI 接缝

查询构建器的分栏视图控制器已经有一个 `barButtonItemSQL` 工具栏项，用于呈现**只读**的 `MADViewControllerSQL` 弹出面板（`MADQueryBuilderSplitViewController.m:31, 106-111`；`MADQuery.storyboard`；`MADViewControllerSQL.m:27-56` 显示 `[doc.mainQuery SQLOnlyActiveFields:…]`）。本功能是这同一个屏幕的一种模式，因此按钮、弹出面板和导航都已存在。

## 3. 功能，从用户视角看

1. 在查询标签页中，点击现有的 SQL 按钮。弹出面板现在有 **View / Edit** 模式。
2. **View（查看）** 以分段控件展示查询 SQL 的两种表示：
   * **Generated（已生成）**——`MADQueryFull` 此刻从模型构建出的 SQL（即今天弹出面板的内容，保留为默认标签页）。
   * **As entered（按输入）**——用户最后一次应用的语句，逐字（`RptqQuery.sqlSourceText`，§8）；当查询从未由粘贴的 SQL 构建过时，则隐藏或为空。
   两个标签页都是只读的——“看看你粘贴了什么，看看它变成了什么”的屏幕。
3. **Edit（编辑）**——一个等宽多行文本视图，存在 `sqlSourceText` 时以它为初始内容（用户重新编辑*自己的*文本，格式和注释原样保留），否则以生成的 SQL 为初始内容；一个 **Revert to generated（恢复为已生成）** 按钮从生成形式重新填充。
4. **Validate（校验）**——结构检查，外加（当文档的数据库可达时）一次零行服务器探针（§7）。错误返回时会带行号和列号。
5. **Apply（应用）**——语句被编译进文档（原子操作——§6.5），粘贴的原文被持久化为 `sqlSourceText`（§8）。弹出面板关闭；查询表列表、可视化画布和报表设计器都显示导入的结构。设计器的字段选择器照常工作。
6. 失败或冲突的应用不持久化任何东西——不持久化文本，也不持久化任何行。先前的查询及其先前输入的文本保持原样。
7. 用户可随时切回：可视化设计器继续在导入的查询上工作，View 显示两种形式，Edit 重新打开他们自己的文字。

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

**位置。** 除探针操作和编辑器 UI 之外的一切都位于 `MAD` 框架中，纯 Foundation，无 UIKit——因此它能在 `MAD` 测试套件和 Linux 镜像中运行。新文件加入 `Linux/cmake/MADSources.cmake`，且 `./Linux/build.sh` 保持绿色。探针操作（需要驱动、凭据、UIKit 警告框）和弹出面板 UI 位于 `MADDesigner/Source`。

**新文件。** `MAD/Source/sql/MADSQLTokenizer.{h,m}`、`MADSQLParser.{h,m}`、`MADSQLStatement.{h,m}`（解析树及其值类型：`MADSQLColumnReference`、`MADSQLPredicateTerm`、…）、`MADSQLStatementResolver.{h,m}`、`MADSQLQueryCompiler.{h,m}`、`MADSQLCompileError.{h,m}`。应用：`MADOperationValidateSQL.{h,m}`（镜像 `MADOperationRefresh`），以及 `MADViewControllerSQL` 或同一 storyboard 接缝中的同级编辑器控制器里的编辑器改动。

**一处小的 API 新增。** 词法分析器需要在连接存在之前就获得每种方言的标识符引号（MySQL 反引号、T-SQL 方括号、双引号）。给 `MADDatabase` 添加 `+ (NSString *)identifierQuoteCharacters`（默认：双引号），并在 `MADMySQL`/`MADTdsClient` 中按驱动覆盖（`MADPostgres` 使用默认的双引号）——或者，如果更偏好，在驱动协议上添加一个类方法，经 `MADDatabaseDriverRegistry` 解析。无论哪种方式，都是三处方法的增加。

## 5. 受支持的子集

导入器**恰好接受模型所能容纳的语言**——一条 `SELECT`，任何地方都没有子查询，每个子句都在 §2.1 的限度之内：

* **SELECT 列表**——仅限列引用：`col`、`tbl.col`、`schema.tbl.col`、`alias.col`，带引号或不带，外加 `alias.*` / `schema.tbl.*`。该列表会被*校验并用于表/列发现*，但不被存储（模型没有 SELECT 列表——§2.1）：每一列都必须解析成功，限定列所指的表必须出现在 `FROM` 中。表达式、聚合、别名（`AS x`）和 `DISTINCT` 会被拒绝，并指向阶段 E（§9），那是通过合成设计器元素让粘贴的列列表变为真实的阶段。输入文本本身*会*被逐字存储在 `sqlSourceText` 中（§8）——校验形态和输入文本是两回事。
* **FROM**——一个表引用 `[schema.]name [AS alias]`，然后是一串或一棵由 `[INNER] JOIN`、`LEFT [OUTER] JOIN`、`RIGHT [OUTER] JOIN`、`FULL [OUTER] JOIN` 组成的链/树，每个都恰好带一个等值条件 `l.col = r.col`（裸列、两段列或三段 `schema.tbl.col` 列；无歧义时允许裸列）。
  * 别名必须是架构表自身的名称（或其去掉点号的形式），或者，对于同一张表的第二份副本，使用 drop-index 形式（`name0`、`name1`、`schema.name0`，或去掉点号的 `schemaname0`，与 `RptqQueryTable -queryAlias` 匹配）——模型自己计算别名，无法持有重命名（`Customer AS c` 被拒绝：“设计器自己给表命名”）。
  * 给定的表对之间至多一个连接（生成器对每对表输出一个 `JOIN`；同一对表之间的两个连接会使别名翻倍）。
  * 没有逗号连接，没有 `NATURAL`/`CROSS` 连接（连接模型恰好持有一对字段，生成器总是写 `ON …`），`FROM`/`ON` 中没有子查询。
* **WHERE**——比较 `left op right` 的合取（AND），`op` ∈ `{ =, <>, >, >=, <, <= }`（即 `MADPredicateOperator` 集合），每一侧是列引用或字面量。括号只在不会改变扁平 AND 形态的地方被接受。其他一切——`OR`、`IN`、`BETWEEN`、`LIKE`、`NOT`、函数、子查询——都被拒绝：谓词模型只把扁平三元组做 AND，别无其他。
* **GROUP BY**——列引用，按顺序导入（weight），每个都经由 `MADocument` 辅助方法成为一个分组，该方法还会创建报表的分组区段。
* **ORDER BY**——**仅当每一列都是 GROUP BY 列时**才被接受，升/降序映射到各分组的排序顺序。否则被拒绝（模型中没有自由排序）。
* **LIMIT**——被拒绝：应用会施加自己的设计器/报表模式限制（`MADDocument.limitResultsDesignMode`、`MADQueryFull.limitResults`）。

字面量在生成时按方言处理（`newSafeLiteral:`、`MADDatabaseSQLProtocol.h`）；导入器只记录值字符串和字段的数据类型，与谓词 UI 的做法完全相同（`MADQueryPredicate.m:74-88`）。

拒绝从不沉默：每一条都指明构造、子句、原因（触碰到哪一模型限制）以及行:列。

## 6. 名称解析与编译

### 6.1 名称解析器

* 别名（或裸表名）→ 按名称匹配 `RptqDatabaseSchemaTable`，大小写不敏感。未知 → 错误“未知表”。
* 列 → `RptqDatabaseSchemaField`：限定列必须存在于其表上；裸列在 `FROM` 集合中必须唯一，否则“列有歧义”。

### 6.2 写入计划

名称解析器的输出是一个值对象计划：有序表列表、连接列表（每个连接一个 `MADLinkType`）、谓词列表（`MADPredicateOperator` + 左/右项）、带排序顺序的分组列表。计划在写入任何东西之前整体校验。

### 6.3 冲突检查——应用是原子的

Apply **替换**查询（粘贴的 SQL *就是*查询——这正是功能所在）。写入之前，对新计划**不**包含的每一张表，检查是否存在来自设计器元素的引用——即 `MADQueryActiveQueryFields` 知道的三种形态（`MADQueryActiveQueryFields.m:37-68`：标签-数据、聚合、条码引用），外加任何将被删除的分组区段。如果被丢弃表的某个字段被引用，则以指明这些元素的错误中止（“此字段被设计器中的……使用”）；不删除任何东西，不写入任何东西，旧查询仍可运行。这是导入无法既原子又沉默的唯一情形，因此它反而会大声失败。

### 6.4 写入

按逆依赖顺序使用 §2.4 的辅助方法：移除连接和谓词，移除分组（经由现有的分组移除路径，该路径会解除其区段和布局管理器的关联），移除不在计划中的表（经由现有的 `deleteDatafieldsRelatedToTable:` 家族），然后通过与 UI 所调用的相同工厂依次创建表 → 连接 → 谓词 → 分组。一次保存；随后调用方把文档标记为脏并自动保存，正如添加表流程所做的那样（`MADQueryViewController.m:796-799`）。

### 6.5 写入之后

无需触碰 UI：存储通知路径会更新模型层和两个查询屏幕（`MADModel_Layer.md` §3.3）。编译器返回一个摘要（表 / 连接 / 谓词 / 分组的数量）供弹出面板使用。

## 7. 校验——两个层级

**结构校验（始终，离线）。** 解析 + 名称解析，§5–§6。错误是 `MADSQLCompileError` 域的 `NSError`，带代码、行、列和消息。当文档的数据库不可达时，这就是整个功能。

**服务器探针（当能建立连接时）。** 把语句包起来：

```sql
SELECT * FROM (<user sql>) AS _mad_probe WHERE 1=0
```

派生表别名在 MySQL 中是必需的，在 T-SQL 中有效；`WHERE 1=0` 会被折叠，因此探针会编译查询并返回列元数据而不读取行。按 `MADOperationRefresh` 的形态运行它（`MADOperationRefresh.m:104-162`）：用来自操作依赖的凭据连接，存储读取封送到主队列，结果经由驱动的 `executeSQL:…intoResultTable:…` 取得，以便 `MADDataColumn` 给出名称和类型。探针随后能捕获静态解析无法捕获的问题——服务器端名称解析（大小写敏感性、视图、保留字）、方言差异，以及服务器自身的语法错误（以其消息呈现）。列名/类型与已解析的架构字段比较，不匹配会作为警告报告，而不是失败。

离线时，或凭据不可用时，探针被跳过，UI 显示“仅按结构校验”。

## 8. 持久化的源文本——`RptqQuery.sqlSourceText`

编译后的模型仍是执行的唯一事实来源，但**用户粘贴的文本是文档的一部分**：`RptqQuery` 上一个新的可空文本属性 `sqlSourceText` 保存最后一次成功应用的语句，逐字。删除用户的文字从来都不是选项——文档同时保留输入和它的编译结果。用户选择单个属性而非历史数组（2026-10-22）；修订历史日后可以作为有序对多关系添加，并从当前文本回填，不会丢失数据。

持久化规则：

* 仅在 Apply 成功时写入，整体替换；失败或冲突的应用既不触碰存储行，也不触碰该文本（§3.6）。
* Edit 视图在存在时以它为初始内容；View 标签页把它作为 **As entered** 展示在 **Generated** 旁边（§3.2-3.3）。

### 8.1 存储变更

该属性落在架构交叉校验的两侧：编译模型和手工维护的 `MADStoreSchema` 描述符，外加 `RptqQuery` 的自动生成属性（`MAD/Source/rptq/autogen/`）。`MAD_FORMAT.md` 的字段列表增加该列。

**修正（阶段 A，2026-10-22）。** 模型变更是**新的 `MAD 4.xcdatamodel` 版本**，而不是就地编辑 `MAD 3`：已发布模型版本的哈希固定了所有现存文档的存储元数据，编辑它会使这些文档成为孤儿。`MAD 4` 还去掉了 `RptqDocumentElementBarcode.barcodeBorderType` 已失效的 `elementID="type"`（任何 `MAD 3` 之前的版本都没有条码实体；BUGS.md）。

### 8.2 存储版本化——新增、小巧、且现在是必需的

可移植存储今天没有版本化（`MADStore.m` 不含 `user_version` pragma）。本阶段添加该机制，刻意保持最小：

* `MADStoreSchema` 获得一个版本常量和一份有序的迁移步骤列表。今天该列表只有一项：版本 1（现存的架构——`user_version` 缺失或为 0）→ 版本 2（`ALTER TABLE` 添加 `sqlSourceText`）。
* 打开时，`MADStore` 读取 `PRAGMA user_version`，在一个事务中应用缺失的步骤，并写入新版本。全新的存储以当前版本创建（`createSchemaSQL` 已经生成整个架构）。
* `MADLegacyStoreConversion` 在流程上不受影响——转换后的 Core Data 文档经同一条 `MADStore` 打开路径以当前版本创建。
* Linux 无头引擎编译同样的 `MADStore` 代码，因此现有文档在镜像中打开方式相同；迁移测试也在那里运行。

**修正（阶段 A，2026-10-22）。** `MADStoreConverter` 现在用与其元数据匹配的 momd 版本打开每个遗留存储，绝不通过自动迁移：Core Data 无法为这个模型家族推断映射（条码 `elementID` 冲突，BUGS.md），而且 momd 当前模型已不再是现存存储所写入的版本。

### 8.3 已考虑并否决：guts 元数据 plist

在 guts 目录中伴随存储的元数据 plist 可以完全无需架构变更地保存该文本。否决理由：查询数据属于存储的查询部分（`MADStorePartQuery`——存储的契约是“三个部分，别无其他”，`MADStoreSchema.h:12-13`），而无头引擎读取存储，不读取 plist。

### 8.4 由此解锁的未来

存储的输入文本是产品愿景中智能体驱动的查询设计（`MAD_FUTURE.md`）的天然输入面：一个智能体——或一个人——写一条语句，下方的编译器把它变成文档，而 `sqlSourceText` 保存记录在案的提示词。严格的编译模型架构正是让它循序渐进的原因：当写作者变成智能体时，编译器本身没有任何改变。

## 9. 阶段

**阶段 A——持久化源文本：存储版本化（仅 MAD；Linux 绿色）。**
1. `RptqQuery` 上的 `sqlSourceText`：编译模型 + `MADStoreSchema` 描述符 + 自动生成属性，一次变更完成（否则交叉校验测试会失败）。
2. §8.2 的版本化机制——版本常量、迁移列表、打开时读取/应用/写入 `user_version`、全新存储以当前版本创建。
3. 测试：`MADStoreSchemaTests` 在两侧保持绿色；新的迁移测试（§10.2）；更新 `MAD_FORMAT.md`。

验收：本阶段之前创建的文档能干净打开、获得该列、保留其数据，并通过 Linux 往返；全新文档以当前版本诞生。本阶段是自包含的——它先于解析器落地，且独立于解析器。

**阶段 B——黄金测试，然后是解析器（仅 MAD；Linux 绿色）。**
4. 黄金 SQL 测试，固定 `MADQueryFull` 每种方言的精确输出（§10.1）——先写，这样解析器是针对真实生成器构建的。
5. `MADSQLTokenizer`/`MADSQLParser`/`MADSQLStatement` + 标识符引号 API（§4）。
6. `MADSQLParserTests`——§5 的接受/拒绝矩阵、错误码、行:列。

验收：`MADQueryFull` 能输出的每个受支持构造都能解析；每个被拒绝的构造都以带代码、带位置的错误失败；MAD 套件和 `./Linux/build.sh` 绿色。

**阶段 C——名称解析器 + 编译器（仅 MAD；Linux 绿色）。**
7. `MADSQLStatementResolver`、`MADSQLQueryCompiler`，具备原子应用（§6）以及成功时写入 `sqlSourceText`（§8）。
8. 删除辅助方法清点；补上缺失的连接/谓词移除辅助方法。
9. `MADSQLQueryCompilerTests` + 不动点往返测试（§10.4）。

验收：应用一条语句产生的 Rptq 行与可视化设计器所会产生的完全相同，并逐字存储文本；在现有查询之上应用不留下孤儿；冲突情形中止，存储——以及先前的文本——不被触碰；不动点测试通过。

**阶段 D——应用（MADDesigner）。**
10. §3 的 View/Edit 弹出面板、`MADOperationValidateSQL` 探针、摘要视图。
11. 使用样本文档的 UI 测试（§10.6）（sqlite3 驱动——无需服务器）。

验收：粘贴 → 校验 → 应用后在查询设计器和可视化中显示表/连接/谓词，在报表设计器中显示分组区段，且刷新能运行该查询；View 显示生成的 SQL 和输入的文本；关闭并重新打开文档后保留输入的文本。

**阶段 E——推迟，各有自己的决定。**
* SELECT 列表物化：合成设计器元素（数据标签、聚合），使刷新恰好返回粘贴的列。在那之前，导入的查询表现得像任何新文档——SELECT 从元素、连接和分组推导（§2.1）。
* 应用语句的历史，如果确有需要：一个从当前 `sqlSourceText` 回填的有序对多关系（§8）——§8.4 智能体驱动查询设计的天然伴侣。

## 10. 测试

### 10.1 固定既有功能（先写）

* `MAD/MADTests` 中的**黄金 SQL 测试**（扩展 `MADQueryFullTests.m`，后者今天只断言片段，`MADQueryFullTests.m:140-162`）：固定的存储夹具 → 精确的预期 SQL 字符串，按驱动方言（MySQL、TDS 和 PostgreSQL 配置），覆盖别名命名和 drop-index 形式、每种连接类型、每个谓词运算符及其字面量引用，以及活动字段排序。这些测试固定解析器必须往返的生成器，它们也在 Linux 镜像中运行。
* **往返契约**——见下面的不动点测试；它把生成器 ∪ 导入器作为一个系统来固定。

### 10.2 存储持久化与迁移测试

* `MADStoreSchemaTests`——现有的交叉校验现在断言描述符和编译模型在 `sqlSourceText` 上一致（正是这个测试迫使 §8.1 的两侧一同落地）。
* 新增 `MADStoreMigrationTests`（MAD）：构建一个版本 1 的磁盘存储（即今天的架构，`user_version` 缺失），其中带行 → 用新的 `MADStore` 打开 → 该列存在，`user_version` 读取为当前版本，每个既有行和关系都存活；全新存储以当前版本创建；打开两次是幂等的。这些也在 Linux 镜像中运行，因为无头引擎共享迁移代码。
* 编译器级断言（在 §10.4 中）：成功的应用**逐字**存储文本——注释、空白、大小写——而冲突的应用让先前的文本保持不动。

### 10.3 解析器测试——`MADSQLParserTests`（MAD）

* 词法分析器：按方言的带引号标识符、含转义引号的字符串字面量、注释（`--`、`/* */`）、数字、运算符、关键字大小写不敏感；错误时给出位置。
* 解析器：完整的 §5 接受矩阵（单表、每种连接类型、连接链、包括 drop-index 的别名、裸列和限定列、WHERE 合取、GROUP BY、ORDER BY ⊆ GROUP BY）和拒绝表（OR、IN、LIKE、子查询、UNION、DISTINCT、SELECT 中的表达式、多条件 ON、别名重命名、逗号连接、NATURAL/CROSS、LIMIT、未知表/列、歧义列、GROUP BY 之外的 ORDER BY）——每项都断言错误**代码**和行:列，绝不只是消息。

### 10.4 编译器测试——`MADSQLQueryCompilerTests`（MAD）

带架构夹具的内存存储（`MADModelQueryTableTests` 所用的模式）：

* 正常路径：应用 → 断言产生的 Rptq 行——表具有正确的架构引用和每字段行，连接具有正确的 `MADLinkType` 和左/右字段，谓词具有正确的 `comparson` 和值字符串，分组具有排序/权重**以及**已创建的分组页眉/页脚区段和布局管理器；保存一次；`sqlSourceText` 与输入语句完全相等（包括注释和空白）。
* 替换路径：在已有内容的查询上应用 → 旧表/连接/谓词/分组消失，没有孤儿行（按实体计数），新结构存在，且 `sqlSourceText` 被替换。
* 冲突路径：设计器元素引用了被丢弃表的字段 → 报错，且前后快照显示存储未变——包括先前的 `sqlSourceText`。
* **不动点往返**：通过工厂构建模型 → 经 `MADQueryFull` 生成 SQL → 解析 → 编译进全新存储 → 再次生成 SQL → 两个 SQL 字符串相等。正是这个测试*定义*了“软件识别了所粘贴的内容”。

### 10.5 校验测试

* 按驱动的探针 SQL 构造（单元测试，在应用的测试目标中）：包装、别名、`WHERE 1=0` 折叠——使用伪造的数据库，无需服务器。
* `MADMySQLLiveTests.m` 风格的**在线测试**（无服务器时跳过）：有效的粘贴 SQL 干净通过探针，列名/类型符合预期；坏的列返回服务器的错误；读取零行。

### 10.6 UI 测试——`MADDesignerUITests`

使用一个样本 `.mad`（sqlite3 驱动）：打开 SQL 弹出面板，切换到 Edit，粘贴一个带筛选条件和分组的双表连接，Apply，然后断言查询表列表显示两张表、可视化画布显示两个框和一个连接线、设计器显示分组区段，且 View 模式显示重新生成的 SQL。然后关闭并重新打开文档：**As entered** 标签页仍显示完全相同的粘贴文本，**Generated** 标签页仍显示编译后查询的 SQL——文档把两者都保留了。

### 10.7 可测试性设计约束（对实现者有约束力）

* 解析器/名称解析器/编译器：纯 Foundation，无 UIKit，无应用导入——MAD 套件和 Linux 镜像会编译它们。
* 每个公开失败都是带代码的 `NSError`（`MADSQLCompileError`）；测试断言代码。
* 探针置于一个小协议之后，以便单元测试伪造数据库；在线覆盖只存在于在线套件中（既有模式）。
* 编译器接收文档/上下文，绝不接收视图控制器；应用不传递任何 UI 形态的东西。
* 新的 MAD 文件加入 `Linux/cmake/MADSources.cmake`；`./Linux/build.sh` 保持绿色。
* 迁移机制位于共享的 `MADStore` 代码中，带有测试可引用的版本常量——绝不在仅 Apple 的路径中——以便 Linux 套件能够执行到它。

## 11. 决定——已与用户确定（2026-10-22）

1. **严格子集。** 已确认：模型无法容纳的任何东西都会带原因被拒绝（§5）。没有不透明 SQL 回退。
2. **Apply 替换查询**（原子，§6.3）。已确认。
3. **GROUP BY 导入会自动创建报表的分组区段**——现有的 `MADocument` 辅助方法就是这样做的，它保持原样。已确认。
4. **SELECT 列表在阶段 E 之前只被校验、不被存储**——在元素合成存在之前，导入的查询在刷新时返回连接/分组列，直到用户添加元素为止，完全像任何新文档。确认为分阶段。
5. **粘贴的文本被持久化。** 已确认——`RptqQuery` 上的 `sqlSourceText`，一个保存最后一次成功应用语句的单一属性（§8），作为 **As entered** 显示在 **Generated** 旁边。生成形式仍是刷新所执行的内容；存储文本这件事不会改变执行。历史数组曾被考虑并搁置（§8、阶段 E）。
