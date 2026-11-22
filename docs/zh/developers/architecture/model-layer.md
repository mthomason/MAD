---
layout: default
title: "MADModel 层"
description: "基于 Rptq 实体的文档读模型，以及它如何保持最新。"
lang: zh-CN
---

# MADModel——文档读模型层

本页介绍 `MADModel`，即基于 `Rptq` 实体的读模型：每个类是什么、如何填充并保持最新，以及谁读取它。

*撰写于原定日期；当前状态事实已于 2026-11-22 核实。*

**范围：** `MAD/Source/model/MADModel*.{h,m}`、`MAD/Source/model/MADTableFieldIdentifier.{h,m}`，以及 `MAD` 与 `MAD Designer` 中该层的每个
消费者。
**日期：** 2026-10-16，读取于 `d7faff320`。
**状态：** 参考。此处一切均于该提交第一手读取；§7 的重构
候选是建议，尚未应用。

---

## 1. 该层是什么

`MADModel*` 是**文档作用域、只读的文档定义视图**——连接、架构（表和字段）以及查询图（查询使用哪些表、
哪些字段，以及它们之间的联接）。设计器的查询 UI 绑定到它。

它*不是*规范模型。规范模型是可移植存储中的 `Rptq*` 对象图：它是应用所编辑、保存、转换和渲染的东西。一个 `MADModel*` 对象
不过是**一个存储行标识符（`int64_t`）加一个指向
`RptqStoreContext` 的弱指针加几个复制的显示值**，通过 `objectsForEntity:identifier:` 取行来惰性解析。

代码遵循的经验法则：

> **通过 `Rptq` 写；通过 `MADModel` 读与观察。**

两层共享一个标识符空间：模型对象的 `identifier` *就是*存储行的
`identifier`。这就是全部的粘合——见 §3。

```
MADModelDocument                       one per open .mad — MADocument.documentModel
 └ databases: [MADModelDatabase]       (today: exactly one)
    ├ driverID / driverType / schemaName   ← RptqDatabase + RptqDatabaseCredentals
    ├ tables / tableDictionary : {id → MADModelTable}      ← RptqDatabaseSchemaTable
    │   └ MADModelTable  (name, queryable)
    │      └ fields / fieldIDs : {id → MADModelField}      ← RptqDatabaseSchemaField
    │         └ MADModelField (name, dataType, decimals, width, primaryKey)
    └ queries: [MADModelQuery]         (today: exactly one; `firstQuery` everywhere)
       └ MADModelQuery
          ├ queryTableIDs / tables : {id → MADModelQueryTable}   ← RptqQueryTable
          │   └ MADModelQueryTable  (schemaTable id, dropIndex, alias)
          │      └ queryFields : {id → MADModelQueryField}       ← RptqQueryField
          │         └ MADModelQueryField (schemaTable + schemaField ids)
          └ queryLinkIDs / links : {id → MADModelQueryLink}      ← RptqQueryLinks
              └ MADModelQueryLink   (left/right table+field ids — one join)
```

## 2. 各类

### 2.1 `MADModel`——标识（`MADModel.h`、`MADModel.m`）

基类只是标识：`_uid`（`MADModel.m:32-64`），带有 `hash`、`isEqual:`（同类
且同 `_uid`）和返回以 `NSNumber` 装箱的 id 的 `-objectID`。
`+[MADModel newModelDocument:]`（`MADModel.m:35`）是名义上的工厂——没有东西调用它；
`MADocument` 直接分配 `MADModelDocument`。`MADModelType.h` 定义了
`MADModelTypeUnknown/Document/Database/Queries`；树中没有任何东西使用该枚举。

名称 `objectID` 以及一段被注释掉的、格式化
`_objectID.URIRepresentation` 的 `debugDescription`，是该层年龄的线索：这些对象过去包装
`NSManagedObjectID`（见 §5）。

### 2.2 `MADModelDocument`——根（`MADModelDocument.h`、`.m`）

- 每份打开的文档由 `-MADocument.documentModel`
  （`MADocument.m:389-395`）在 `self.storeContext` 上惰性创建一次。生产环境中没有别的东西
  构建它；应用委托与此无关。
- 持有 `databases`（由 `-updateDocumentDatabaseQuery` 构建，`MADModelDocument.m:210-240`：
  每个 `RptqQuery` 行一个 `MADModelDatabase`——这里的“数据库”指连接加上其
  架构再加上一个查询），并带有 `firstDatabase` / `firstQuery` 便捷访问器。代码
  说明了复数为何是做戏：*"current versions of the software only use one database and
  query"*（`MADModelDocument.m:207-208`）。
- **注册存储的变更通知**（`RptqStoreContextObjectsDidChange`、
  `WillSave`、`DidSave`，`MADModelDocument.m:160-176`），在私有 `NSOperationQueue`
  （`MADModelDocument.m:83-87`，`_objectContextQueue`）上。当 `RptqQueryTable`
  或 `RptqQueryLinks` 行插入/删除时，它把变更镜像进 `firstQuery`——见 §3.3。
- `-update`（`MADModelDocument.m:201-205`）重新运行文档→数据库→查询的扫描，并
  *替换* `_databases` 为新对象。

### 2.3 `MADModelDatabase`——连接、架构与查询（`MADModelDatabase.h`、`.m`）

- 以 `RptqDatabase` 行的标识符为键。
- 元数据是*通过存储、一次一个属性*解析的：`driverType`
  （`MADModelDatabase.m:157-164`）、`schemaName`（`:166-173`）和 `driverID`（`:175-182`）各自
  惰性取回 `RptqDatabase` 并透读到 `RptqDatabaseCredentals`。`schemaName`
  和损坏的 `driverName`（§6）都返回凭据的 `dbname`。
- `tables` / `tableDictionary`（`-updateTables`，`MADModelDatabase.m:221-247`）列出所有
  `inDatabase` 匹配的 `RptqDatabaseSchemaTable`，**按名称排序**——恢复了迁移前取数所应用的
  排序，并有一处注释指向 BUGS.md。
- `queries`（`-updateQueries`，`:249-261`）对 `RptqQuery` 行做同样的事。

### 2.4 `MADModelTable` / `MADModelField`——架构（`MADModelTable.{h,m}`、`MADModelField.h`）

- `MADModelTable` 缓存 `name`，并惰性地从 `inTable` 匹配的 `RptqDatabaseSchemaField` 行构建 `fields` / `fieldIDs`
  （`MADModelTable.m:120-146`），按名称排序。`MADModelField` 是普通值：名称、主键标志、数据类型、
  原生类型、小数位、宽度——无存储访问。

### 2.5 `MADModelQuery`——一个查询（`MADModelQuery.h`、`.m`）

最大的类，也是真正物有所值的类。它拥有：

- `queryTableIDs` + `tables`（`MADModelQuery.m:213-283`）：每个其
  `inQueryTable.inQuery` 为本查询的 `RptqQueryField` 被投影为字典
  （`MADStoreProjectionForQueryField`，`:59-68`）——正是旧 Core Data 取数投影所产生的
  形状——并喂给 `-insertTablesFromFetchRequestResults:`。
- `queryLinkIDs` + `links`（`:302-344`）：对 `RptqQueryLinks` 做同样的事
  （`MADStoreProjectionForQueryLink`，`:70-78`）。
- 拓扑辅助方法：`-tablesInLinks`（`:183`）和 `-orphanedQueryTables`（`:196`，即
  没有联接触及的表，通过一个 `NSExpression` 集合减法）。
- **变更面**：`-insertQueryTable:` / `-insertQueryLink:` /
  `-deleteQueryTableID:` / `-deleteQueryLinkID:` 以及基于 id 的变体。每个都先应用到
  集合，然后**在主队列**通过 `[NSOperationQueue mainQueue] addOperationWithBlock:` 重新发送
  `MADNotificationQueryTableInsert/Delete` 或
  `MADNotificationQueryLinkInsert/Delete`（名称在 `MADModel.h:22-26`），
  并带有受影响的模型对象在 `userInfo` 中。这些通知是该层的公开事件流；设计器
  订阅它们（§4）。

### 2.6 `MADModelQueryTable` / `MADModelQueryField`——查询的表和字段

- `MADModelQueryTable`（`MADModelQueryTable.m`）缓存 `dropIndex` 和**架构**表 id，
  并惰性持有 `queryFields` / `queryFieldIDs`（由 `-addField:schemaField:` 构建，`:92`）。
  `-alias`（`:119-129`）是面向 SQL 的名称：第一份副本用架构表名，
  之后为名称 + drop index（`Customer`、`Customer0`、……）。
- `MADModelQueryField`（`MADModelQueryField.m`）是两个 id：架构表和架构
  字段。`-schemaField`（`:52-57`）通过遍历
  database → `tableDictionary[schemaTable]` → `fields[schemaField]` 解析真实元数据。这条链——
  联接 → 查询表 → 架构表 → 查询字段 → 架构字段——是该层的标志性
  模式；`MADQueryVisualizationViewController.m:1024-1048` 手工执行它以放置一个
  连接器。

### 2.7 `MADModelQueryLink` / `MADTableFieldIdentifier`

- `MADTableFieldIdentifier`（`MADTableFieldIdentifier.{h,m}`）是一个极小的值对
  （表 id + 字段 id），带 `NSNumber` 访问器。
- `MADModelQueryLink`（`MADModelQueryLink.m`）每一端持有一个 `MADTableFieldIdentifier`，
  或从原始 id 构建，或从 `RptqQueryLinks` 行构建（`-initWithRptqQueryLink:`，
  `:60-76`，读取 `hasLeftField.inQueryTable.identifier` / `hasLeftField.identifier`）。
  `-isAdjacentToQueryTable:`（`:78`）和 `-tables`（`:82`）回答可视化所询问的图问题。

### 2.8 协议与残留部分

- `MADModelIDProtocol`——四行：`identifier`（`MADModelIDProtocol.h`）。
- `MADModelDataProtocol`（`MADModelDataProtocol.h`）——`managedObjectContext`、
  `-initWithIdentifier:managedObjectContext:` 和 `-update`。实际上 `-update` 是一个
  内部刷新钩子：只被该层自身的惰性 getter 调用
  （`MADModelDocument.m:188`、`MADModelTable.m:99` 和 `:115`）。`MADModelDatabase -update`
  （`MADModelDatabase.m:148`）和 `-MADModelQuery -update`（`MADModelQuery.m:354`，一个空
  方法）完全没有调用者。

## 3. 生命周期

### 3.1 创建

`MADocument` 惰性构建一个 `MADModelDocument`（`MADocument.m:389-395`）并在
文档生命周期内保留它。它**弱**持有 `RptqStoreContext`
（`MADModelDocument.m:42`），与每个持有上下文的模型对象一样——存储上下文由
文档拥有。

### 3.2 填充

文档之下的一切都是**惰性且缓存的**：首次读取 `databases`、`tables`、
`fields`、`queryTableIDs`、`queryFields` 或 `links` 会触发一次取数与过滤过程
（对相关 Rptq 实体执行 `objectsForEntity:`，按父对象的标识符过滤，然后在
迁移前取数会排序的地方排序）。缓存只会因调用 `-update` 或下述通知路径而失效；
没有东西会自行过期。

### 3.3 实时变更——往返

在设计器中添加表或联接会写入 **Rptq 行**（例如
`MADQueryViewController.m:745-790` 的添加表流程创建 `RptqQueryTable` + `RptqQueryField` 行并保存
上下文）。随后模型自行追赶：

```
user adds a table / link
  → RptqQueryTable / RptqQueryLinks rows written + saved
    → RptqStoreContextObjectsDidChangeNotification
      → MADModelDocument's observer (on its private queue)     MADModelDocument.m:91-158
        → [firstQuery insertQueryTable:/insertQueryLink:]       MADModelQuery.m:361-410
          → MADNotification…Insert/Delete reposted on main      MADModelQuery.m:361-514
            → MADQueryVisualizationViewController, MADQueryBuilderAddTableViewController
```

涉及两个队列：模型在 `_objectContextQueue`（一个私有
`NSOperationQueue`，`MADModelDocument.m:83-87`）上*变更*，而通知在**主队列**上*到达*。
集合本身未做同步。

### 3.4 陈旧

`-update`（文档或数据库）用**新**模型对象重建集合；此前交出的任何
模型对象对其缓存的内容仍可用，但不再是
`firstQuery.tables` 中的那个。目前树中没有任何东西在模型对象上调用 `-update`——
通知路径是实时的——但跨一次 `-update` 存储模型对象的代码
会读到陈旧条目。

## 4. 消费者

### 4.1 Query 标签页（即席查询构建器）

- `MADQueryViewDataSource.m:365`——数据源头部单元格：“You are connecting to
  *driverID* datasource named *schemaName*”，来自 `firstDatabase`。
- `MADQueryViewDataSource.m:533-546`——查询表列表取 `firstQuery` 并用
  `query.identifier` 过滤 `RptqQueryTable` 行。注意这一模式：**模型提供
  标识和元数据；行本身是 Rptq 对象。**
- `MADQueryTableViewController.m:163-174`——查询表的框标题来自
  `firstQuery.tables[id].alias`；`:186-200` 和 `:239-266` 从
  `firstDatabase.tableDictionary[schemaTableID]` → `fieldIDs` / `fields` 渲染架构字段列表。这就是架构
  浏览器的全部内容模型。
- `MADQueryBuilderAddTableViewController.m:29-33`——观察模型的插入/删除
  通知以保持其表面板最新。

### 4.2 Query Visualization 标签页（框与连接器）

- `MADQueryVisualizationModel`（`MADQueryVisualizationModel.m:40-77`）通过
  `-[MTGraph initWtthQueryID:]`（`MTGraph+RptqQuery.m:39-67`）构建一个 `MTGraph`，它**完全写在
  模型上**：`query.queryTableIDs` 成为顶点，`query.links` 成为边。然后它
  进行拓扑排序，计算 `startingPoints`（没有被联接*指向*的表）并存储
  DAG 标志。（同一个 category 还有基于存储的初始化器，`:69-93`，早于
  模型路径；可视化使用模型的那个。）
- `MADQueryVisualizationViewController`（`MADQueryVisualizationViewController.m`）是通知流的
  主要消费者：它订阅全部四个模型通知
  （`:314-335`），在它们到达时添加/移除框和连接器，在删除联接后
  使用 `-orphanedQueryTables` 重新标记根表（`:936`），按表询问 `-linksForQueryTable:`（`:644`），
  并通过遍历标识符链
  （`:1024-1048`，§2.6）来布局每个连接器。
- `MADQueryVisualizationCacheManager` 以模型标识符为键持久化画布布局
  （`updateCacheWithQuery:…`，`MADQueryVisualizationCacheManager.h:20`）。

### 4.3 文档与测试

`MADocument.documentModel` 是唯一的生产入口。测试：
`MADDocumentTests.m:263-265`（重新打开的文档的 `databases`/`queries`）、
`MADDocumentTests.m:399-404`（一个 `MADModelDatabase` 的表/字段顺序），加上专门的
套件 `MADModelQueryTableTests`、`MADModelQueryFieldTests` 以及
`MADModelValueTypesTests` 中的 `MADModelField` / `MADModelQueryLink` 覆盖。

### 4.4 哪些*不*使用它

- **SQL 生成**——`MADQueryFull` 和 `Rptq*+Extras` 类工作在 Rptq 层
  （例如 `RptqQueryField+Extras.m:137` 从 `RptqQueryTable.alias` 构建 `table.field` 名称）。
- **布局与渲染**——`MADDesignerLayout` 和报表路径工作在
  `RptqDocumentElement` 上；`MADReportFormatter` 完全不用该层（其在
  `MADReportFormatter.m:18-20` 的三处 `MADModel*` 导入已陈旧）。
- **行数据**——这些都不触碰 `.maddb` 缓存；那是 `MADDataTableFast` /
  `MADReportFormatter` 的地盘。

因此该层今天的真实范围是：**设计器的查询侧，别无其他。**

## 5. 它为何存在

该层来自 2017 年初（文件头 `1/22/17`–`6/3/17`），在 Core Data
时代构建，作为**查询 UI 的手工视图模型**：设计器的表视图
和可视化画布可以绑定的轻量对象，而不是 `NSManagedObject` 和
`NSFetchedResultsController`。证据在文件中：`-objectID`、`MADModel.m:66-80` 中被注释掉的
`NSManagedObjectID` 调试描述，以及三处幸存下来、说
“was an `NSFetchedResultsController`”的注释（`MADQueryChooseFieldController.m:149`、
`MTGroupByViewController.m:53`、`MADTableViewControllerCoreDataResults.h:14`）。

存储迁移（`MAD_STORE_MIGRATION.md` 的 Phase C/D）把每次取数从 Core Data
重新接线到 `RptqStoreContext` + `objectsForEntity:`，**而没有改变该层的表面**——这就是为什么
`MIGRATION_KICKOFF.md` §Findings 称它为“[a] clean `MADModel*` domain layer [that]
already wraps the `Rptq` entities; it is the seam to keep.”

所以它算是一种 MVC，但不是“应用的模型”：它是一个**每文档读模型**（控制器所见的 MVC
“模型”），而规范领域对象是 Rptq 图。该
抽象带来三样东西，其余各处都很薄：(1) 查询图以
展示形态呈现（别名、邻接、id 到元数据的查找），无需关系
遍历；(2) 一个把存储变更通知转换为查询图事件的地方；
(3) 一个界面，使 UI 可以在底下存储彻底改变时保持不变——
这正是实际发生的事。

## 6. 已知的粗糙边缘

第一手读取；这些今天都没有消费者，因此都是潜伏的。

1. `MADModelField.inTable`（`MADModelField.h:20`）声明为 `weak MADModelField *`——
   类型是错的（应为 `MADModelTable *`）——且从未被赋值。
2. 其他父回指针同样未被使用：`MADModelTable.inDatabase`、
   `MADModelQueryTable.inQuery` 和 `MADModelQueryField.inQueryTable` 从未被
   树中任何代码路径赋值。只有 `MADModelQuery.inDatabase` 会被设置
   （`MADModelQuery.m:108-114`）。（`-addField:schemaField:` 未接线其字段的回指针
   已记录在 BUGS.md。）
3. `MADModelDatabase -driverName`（`MADModelDatabase.m:184-215`）以 `return @"";` 结尾，因此它
   即使缓存了真实名称也返回空字符串；`-schemaName` 已从同一处返回
   同一字符串。没有读取者。
4. `MADModelDocument.m:228-234` 解码一个文档 id（`docID`）却从不使用它。
5. `MADModelQuery -update`（`MADModelQuery.m:354`）为空；`MADModelDatabase -update` 没有
   调用者；`+[MADModel newModelDocument:]` 没有调用者。
6. `MADModelType` 未被使用。
7. 变更模型的私有队列与主线程读取者之间没有同步；
   且 `MADModelDocument` 弱持有存储上下文，因此比其文档活得久的模型
   没有上下文可用于解析任何东西。
8. 命名：`MADModelDocument` 有 `databases`，`MADModelDatabase` 有 `queries`——但
   文档*每个查询*构建一个“数据库”，而今天每种各只有一个。
   该结构是单数据库/单查询简化之前的前瞻性设计。

## 7. 重构候选（建议——均未应用）

按价值相对风险排序。A 和 B 是纯整理；C 改变公开头文件所承诺的内容；
D 是一个决定。

**A. 文档化，而非合并。** 最廉价的清晰度收益是每类头注释
（2–4 行：类是什么、以什么为键、谁读取它）加上本文档。合并
各类的*文件*是昂贵的选项，而不是廉价的：十六个以上的文件导入
每类头文件（`#import <MAD/MADModelQueryField.h>` 等），每个头文件在 Xcode 目标中都是独立文件，
且 Linux 构建的 include shim 是一个由每头文件符号链接组成的目录
（`Linux/README.md`，MAD 的 shim）。合并会触碰 pbxproj、Linux 源列表
以及每个导入点，只为外观收益。若真要合并，安全的方向
相反：保持每个文件一个类，并让**入口点**显而易见（`MADModel.h` 的文档开头，
“start at `MADModelDocument`”）。

**B. 删除或补全残留表面。** 这些都行为安全（没有东西
读取它们），但会触碰头文件，因此应视为 API 决定：
- `MADModelField.inTable`：修正类型并在 `MADModelTable -update` 中设置它（一行，
  与其他父对象对称），或删除该属性。
- `MADModelDatabase -driverName`：像其兄弟一样返回缓存值，或删除它。
- `MADModelType`：删除头文件。（需要项目文件移除；在一个提交中完成。）
- `+[MADModel newModelDocument:]`：要么让 `MADocument -documentModel` 使用它（恢复
  工厂的用途），要么删除它。
- `MADModelDocument.m:228-234` 中未使用的 `docID` 解码。

**C. 接线已声明的回指针。** `inDatabase`、`inQuery` 和 `inQueryTable` 的存在是为了让
图可以向上遍历；今天只有向下查找可用。在构造时赋值
（`MADModelDatabase -updateTables` 已有 `self`；`insertTableRptqQueryTable:` 有
模型查询；`-addField:schemaField:` 有表）使对象图与其头文件匹配，
且安全，正因为目前没有东西读取它们。需记住的语义：它们
声明为 `weak`，这对向下拥有的父对象是正确的。

**D. 跨刷新的标识（一个决定，而非整理）。** `-update` 替换对象；若
曾需要跨更新稳定标识，更新方法必须原地变更
（为某标识符复用对象，增删差异）而非重建。这会
改变已交出对象的可观察标识，因此需要刻意选择。

**E. 机械去重。** `MADModelTable.fields` 和 `-fieldIDs`（`MADModelTable.m:88-118`）
包含同一段初始化块两次，而 `MADModelQuery` 的三个 getter 重复
同样的“确保集合，然后更新”舞步（`MADModelQuery.m:116-181`）。两者都可以
各自折叠为一个私有辅助方法，行为不变；只在文件因其他事
打开时才值得做。

**F. 不推荐：重命名。** `MADModelDatabase` → 诸如 `MADModelConnection` 之类
读起来更好，但此处的重命名是横跨 Xcode/Linux 项目文件的杂务，没有
功能收益。

## 8. 如果你修改该层

- 保持仅标识符的契约：模型对象必须仍能仅由 id 构建
  （通知路径和测试依赖于此）。
- 任何创建或删除 `RptqQueryTable` / `RptqQueryLinks` 行的东西都会被
  `MADModelDocument` 的观察者自动拾取——但只限通过
  `firstQuery` 到达的行；文档中的第二个查询不会被镜像。
- 四个 `MADNotification…` 名称是该层给 UI 的公开 API；针对
  `firstQuery` 对象观察它们，如 `MADQueryVisualizationViewController` 所做。
- iOS 套件（`MAD` scheme）和 `./Linux/build.sh` 都会编译这些文件；参见
  `Linux/cmake/MADSources.cmake`。
