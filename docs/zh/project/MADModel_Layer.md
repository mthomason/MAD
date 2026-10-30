---
layout: default
lang: zh-CN
---

# MADModel——文档读取模型层

**范围：** `MAD/Source/model/MADModel*.{h,m}`、`MAD/Source/model/MADTableFieldIdentifier.{h,m}`，以及
`MAD` 和 `MAD Designer` 中该层的所有使用方。
**日期：** 2026-10-16，基于 `d7faff320` 阅读。
**状态：** 参考。本文所有内容均在该提交上亲自阅读核实；§7 的重构候选是提案，尚未实施。

---

## 1. 该层是什么

`MADModel*` 是**以文档为作用域的、文档定义的只读视图**——包括连接、架构（表和字段），以及查询图（查询使用哪些表、哪些字段，以及它们之间的连接）。它是设计器查询界面所绑定的对象。

它*不是*规范模型。规范模型是可移植存储中的 `Rptq*` 对象图：应用编辑、保存、转换和渲染的正是它。`MADModel*` 对象不过是**一个存储行标识符（`int64_t`）加一个指向 `RptqStoreContext` 的弱指针，再加几个复制出来的显示值**，通过 `objectsForEntity:identifier:` 获取行来惰性解析。

代码遵循的经验法则：

> **通过 `Rptq` 写入；通过 `MADModel` 读取和观察。**

这两层共享同一个标识符空间：模型对象的 `identifier` *就是*存储行的 `identifier`。这就是全部的粘合——见 §3。

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

### 2.1 `MADModel`——身份（`MADModel.h`、`MADModel.m`）

基类只负责身份：`_uid`（`MADModel.m:32-64`），带有 `hash`、`isEqual:`（同类且 `_uid` 相同）和返回装箱为 `NSNumber` 的 `-objectID`。`+[MADModel newModelDocument:]`（`MADModel.m:35`）是名义上的工厂方法——没有任何代码调用它；`MADocument` 直接分配 `MADModelDocument`。`MADModelType.h` 定义了 `MADModelTypeUnknown/Document/Database/Queries`；代码树中没有任何地方使用该枚举。

`objectID` 这个名称，以及一段被注释掉的、格式化 `_objectID.URIRepresentation` 的 `debugDescription`，是该层年代的线索：这些对象过去包装的是 `NSManagedObjectID`（见 §5）。

### 2.2 `MADModelDocument`——根（`MADModelDocument.h`、`.m`）

- 由 `-MADocument.documentModel`（`MADocument.m:389-395`）为每个打开的文档惰性创建一次，基于 `self.storeContext`。生产代码中没有别处构建它；应用委托与此无关。
- 持有 `databases`（由 `-updateDocumentDatabaseQuery` 构建，`MADModelDocument.m:210-240`：*每个 `RptqQuery` 行*对应一个 `MADModelDatabase`——“database”在这里指连接及其架构再加上一个查询），并提供 `firstDatabase` / `firstQuery` 便捷访问器。代码说明了为何复数只是摆设：*“current versions of the software only use one database and query”*（`MADModelDocument.m:207-208`）。
- **注册存储的变更通知**（`RptqStoreContextObjectsDidChange`、`WillSave`、`DidSave`，`MADModelDocument.m:160-176`），在私有 `NSOperationQueue`（`MADModelDocument.m:83-87`，`_objectContextQueue`）上进行。当插入/删除 `RptqQueryTable` 或 `RptqQueryLinks` 行时，它将变更镜像到 `firstQuery`——见 §3.3。
- `-update`（`MADModelDocument.m:201-205`）重新执行 document→database→query 扫描，并用新对象*替换* `_databases`。

### 2.3 `MADModelDatabase`——连接、架构与查询（`MADModelDatabase.h`、`.m`）

- 以 `RptqDatabase` 行的标识符为键。
- 元数据是*通过存储逐属性*解析的：`driverType`（`MADModelDatabase.m:157-164`）、`schemaName`（`:166-173`）和 `driverID`（`:175-182`）各自惰性获取 `RptqDatabase` 并透传到 `RptqDatabaseCredentals`。`schemaName` 和损坏的 `driverName`（§6）都返回凭据的 `dbname`。
- `tables` / `tableDictionary`（`-updateTables`，`MADModelDatabase.m:221-247`）列出 `inDatabase` 匹配的所有 `RptqDatabaseSchemaTable`，**按名称排序**——恢复迁移前某次获取所应用的排序，并有注释指向 BUGS.md。
- `queries`（`-updateQueries`，`:249-261`）对 `RptqQuery` 行做同样的处理。

### 2.4 `MADModelTable` / `MADModelField`——架构（`MADModelTable.{h,m}`、`MADModelField.h`）

- `MADModelTable` 缓存 `name`，并惰性构建 `fields` / `fieldIDs`（`MADModelTable.m:120-146`），取自 `inTable` 匹配的 `RptqDatabaseSchemaField` 行，按名称排序。`MADModelField` 是一个纯值对象：名称、主键标志、数据类型、原生类型、小数位数、宽度——不访问存储。

### 2.5 `MADModelQuery`——一个查询（`MADModelQuery.h`、`.m`）

最大的类，也是真正有其价值的类。它持有：

- `queryTableIDs` + `tables`（`MADModelQuery.m:213-283`）：`inQueryTable.inQuery` 指向本查询的每个 `RptqQueryField` 都会被投影为一个字典（`MADStoreProjectionForQueryField`，`:59-68`）——与旧 Core Data 获取投影产生的形状完全一致——并送入 `-insertTablesFromFetchRequestResults:`。
- `queryLinkIDs` + `links`（`:302-344`）：对 `RptqQueryLinks` 做同样的事（`MADStoreProjectionForQueryLink`，`:70-78`）。
- 拓扑辅助方法：`-tablesInLinks`（`:183`）和 `-orphanedQueryTables`（`:196`，没有任何连接触及的表，通过 `NSExpression` 的集合减法）。
- **变更接口**：`-insertQueryTable:` / `-insertQueryLink:` / `-deleteQueryTableID:` / `-deleteQueryLinkID:` 以及基于 id 的变体。每个方法先对集合应用变更，然后通过 `[NSOperationQueue mainQueue] addOperationWithBlock:` **在主队列**上重新发送 `MADNotificationQueryTableInsert/Delete` 或 `MADNotificationQueryLinkInsert/Delete`（名称见 `MADModel.h:22-26`），并在 `userInfo` 中带上受影响的模型对象。这些通知是该层的公开事件流；设计器订阅它们（§4）。

### 2.6 `MADModelQueryTable` / `MADModelQueryField`——查询的表和字段

- `MADModelQueryTable`（`MADModelQueryTable.m`）缓存 `dropIndex` 和**架构**表 id，并惰性持有 `queryFields` / `queryFieldIDs`（由 `-addField:schemaField:` 构建，`:92`）。`-alias`（`:119-129`）是面向 SQL 的名称：第一份副本用架构表名，之后用名称 + drop index（`Customer`、`Customer0` 等）。
- `MADModelQueryField`（`MADModelQueryField.m`）是两个 id：架构表和架构字段。`-schemaField`（`:52-57`）沿 database → `tableDictionary[schemaTable]` → `fields[schemaField]` 查找，解析出真实元数据。这条链——连接 → 查询表 → 架构表 → 查询字段 → 架构字段——是该层的标志性模式；`MADQueryVisualizationViewController.m:1024-1048` 手工执行这一链来放置连接线。

### 2.7 `MADModelQueryLink` / `MADTableFieldIdentifier`

- `MADTableFieldIdentifier`（`MADTableFieldIdentifier.{h,m}`）是一个极小的值对（表 id + 字段 id），带有 `NSNumber` 访问器。
- `MADModelQueryLink`（`MADModelQueryLink.m`）为两端各持有一个 `MADTableFieldIdentifier`，可从未加工的 id 或从 `RptqQueryLinks` 行构建（`-initWithRptqQueryLink:`，`:60-76`，读取 `hasLeftField.inQueryTable.identifier` / `hasLeftField.identifier`）。`-isAdjacentToQueryTable:`（`:78`）和 `-tables`（`:82`）回答可视化所提出的图问题。

### 2.8 协议与残留部分

- `MADModelIDProtocol`——四行：`identifier`（`MADModelIDProtocol.h`）。
- `MADModelDataProtocol`（`MADModelDataProtocol.h`）——`managedObjectContext`、`-initWithIdentifier:managedObjectContext:` 和 `-update`。实际上 `-update` 是一个内部刷新钩子：只由该层自己的惰性 getter 调用（`MADModelDocument.m:188`、`MADModelTable.m:99` 和 `:115`）。`MADModelDatabase -update`（`MADModelDatabase.m:148`）和 `-MADModelQuery -update`（`MADModelQuery.m:354`，空方法）完全没有调用者。

## 3. 生命周期

### 3.1 创建

`MADocument` 惰性构建一个 `MADModelDocument`（`MADocument.m:389-395`），并保持其与文档同寿。它**弱**持有 `RptqStoreContext`（`MADModelDocument.m:42`），与每个持有上下文的模型对象一样——存储上下文由文档拥有。

### 3.2 填充

文档以下的一切都是**惰性且带缓存的**：首次读取 `databases`、`tables`、`fields`、`queryTableIDs`、`queryFields` 或 `links` 会触发一次获取并过滤的过程（对相关 Rptq 实体执行 `objectsForEntity:`，按父级的标识符过滤，然后按迁移前获取所采用的排序进行排序）。缓存只会因调用 `-update` 或下面的通知路径而失效；没有任何东西会自行过期。

### 3.3 实时变更——往返流程

在设计器中添加表或连接会写入 **Rptq 行**（例如 `MADQueryViewController.m:745-790` 的添加表流程会创建 `RptqQueryTable` + `RptqQueryField` 行并保存上下文）。随后模型会自行跟进：

```
user adds a table / link
  → RptqQueryTable / RptqQueryLinks rows written + saved
    → RptqStoreContextObjectsDidChangeNotification
      → MADModelDocument's observer (on its private queue)     MADModelDocument.m:91-158
        → [firstQuery insertQueryTable:/insertQueryLink:]       MADModelQuery.m:361-410
          → MADNotification…Insert/Delete reposted on main      MADModelQuery.m:361-514
            → MADQueryVisualizationViewController, MADQueryBuilderAddTableViewController
```

两个队列在起作用：模型在 `_objectContextQueue`（一个私有 `NSOperationQueue`，`MADModelDocument.m:83-87`）上*执行变更*，而通知在主队列上*到达*。集合本身没有同步。

### 3.4 陈旧性

`-update`（文档或数据库）会用**新**模型对象重建集合；先前交出的任何模型对象对其缓存的内容仍然可用，但已不再是 `firstQuery.tables` 中的那个。目前代码树中没有任何地方对模型对象调用 `-update`——实时路径是通知路径——但若代码跨 `-update` 保留模型对象，就会读到过期条目。

## 4. 使用方

### 4.1 查询标签页（即席查询构建器）

- `MADQueryViewDataSource.m:365`——数据源标题单元格：从 `firstDatabase` 生成“正在连接到名为 *schemaName* 的 *driverID* 数据源”。
- `MADQueryViewDataSource.m:533-546`——查询表列表取 `firstQuery`，并用 `query.identifier` 过滤 `RptqQueryTable` 行。注意这个模式：**模型提供身份和元数据；行本身是 Rptq 对象。**
- `MADQueryTableViewController.m:163-174`——查询表的框标题来自 `firstQuery.tables[id].alias`；`:186-200` 和 `:239-266` 从 `firstDatabase.tableDictionary[schemaTableID]` → `fieldIDs` / `fields` 渲染架构字段列表。这就是架构浏览器的全部内容模型。
- `MADQueryBuilderAddTableViewController.m:29-33`——观察模型的插入/删除通知，以保持其表格面板最新。

### 4.2 查询可视化标签页（框与连接线）

- `MADQueryVisualizationModel`（`MADQueryVisualizationModel.m:40-77`）通过 `-[MTGraph initWtthQueryID:]`（`MTGraph+RptqQuery.m:39-67`）构建 `MTGraph`，后者**完全基于模型**实现：`query.queryTableIDs` 成为顶点，`query.links` 成为边。然后它进行拓扑排序，计算 `startingPoints`（没有任何连接指向*它们*的表）并存储 DAG 标志。（同一 category 还有基于存储的初始化方法，`:69-93`，早于模型路径；可视化使用的是模型那个。）
- `MADQueryVisualizationViewController`（`MADQueryVisualizationViewController.m`）是通知流的主要使用方：它订阅全部四个模型通知（`:314-335`），在框和连接线到达时添加/移除它们，在删除连接后使用 `-orphanedQueryTables`（`:936`）重新标记根表，对每张表询问 `-linksForQueryTable:`（`:644`），并通过遍历标识符链来布局每个连接线（`:1024-1048`，§2.6）。
- `MADQueryVisualizationCacheManager` 以模型标识符为键持久化画布布局（`updateCacheWithQuery:…`，`MADQueryVisualizationCacheManager.h:20`）。

### 4.3 文档与测试

`MADocument.documentModel` 是唯一的生产入口点。测试：`MADDocumentTests.m:263-265`（重新打开的文档的 `databases`/`queries`）、`MADDocumentTests.m:399-404`（`MADModelDatabase` 的表/字段顺序），以及专门的测试套件 `MADModelQueryTableTests`、`MADModelQueryFieldTests`，和 `MADModelValueTypesTests` 中的 `MADModelField` / `MADModelQueryLink` 覆盖。

### 4.4 哪些地方*不*使用它

- **SQL 生成**——`MADQueryFull` 和 `Rptq*+Extras` 类工作在 Rptq 层（例如 `RptqQueryField+Extras.m:137` 从 `RptqQueryTable.alias` 构建 `table.field` 名称）。
- **布局与渲染**——`MADDesignerLayout` 和报表路径工作在 `RptqDocumentElement` 上；`MADReportFormatter` 完全不使用该层（其在 `MADReportFormatter.m:18-20` 的三处 `MADModel*` 导入是过时的）。
- **行数据**——这些都不触及 `.maddb` 缓存；那是 `MADDataTableFast` / `MADReportFormatter` 的领域。

因此，该层今天的真实范围是：**设计器的查询侧，仅此而已。**

## 5. 它为何存在

该层来自 2017 年初（文件头 `1/22/17`–`6/3/17`），是在 Core Data 时代作为**查询界面的手工视图模型**构建的：轻量对象，供设计器的表格视图和可视化画布绑定，而不是 `NSManagedObject` 和 `NSFetchedResultsController`。证据就在文件中：`-objectID`、`MADModel.m:66-80` 中被注释掉的 `NSManagedObjectID` 调试描述，以及三条留存下来的注释，写着“was an `NSFetchedResultsController`”（`MADQueryChooseFieldController.m:149`、`MTGroupByViewController.m:53`、`MADTableViewControllerCoreDataResults.h:14`）。

存储迁移（`MAD_STORE_MIGRATION.md` 的 Phase C/D）将每次获取从 Core Data 重新连接到 `RptqStoreContext` + `objectsForEntity:`，**而没有改变该层的表面**——这就是 `MIGRATION_KICKOFF.md` §Findings 称其为“一层干净的 `MADModel*` 领域层，已经封装了 `Rptq` 实体；这是值得保留的接缝”的原因。

所以它算是一种 MVC，但不是“应用的模型”：它是一个**按文档划分的读取模型**（控制器视角下的 MVC“模型”），而规范领域对象是 Rptq 图。这一抽象带来三项好处，其余各处都很薄：(1) 以适合显示的形态呈现查询图（别名、邻接关系、id 到元数据的查找），无需遍历关系；(2) 一个将存储变更通知转换为查询图事件的统一位置；(3) 一个界面，使 UI 可以保持不变，而其下的存储完全改变——这正是实际发生的事。

## 6. 已知的粗糙边缘

亲自阅读核实；这些目前都没有使用方，因此都处于潜伏状态。

1. `MADModelField.inTable`（`MADModelField.h:20`）声明为 `weak MADModelField *`——类型错误（应为 `MADModelTable *`）——而且从未被赋值。
2. 其他父级反向指针同样未被使用：`MADModelTable.inDatabase`、`MADModelQueryTable.inQuery` 和 `MADModelQueryField.inQueryTable` 在代码树的任何路径中都从未被赋值。只有 `MADModelQuery.inDatabase` 被设置过（`MADModelQuery.m:108-114`）。（`-addField:schemaField:` 没有接通其字段的反向指针，这一点已记录在 BUGS.md 中。）
3. `MADModelDatabase -driverName`（`MADModelDatabase.m:184-215`）以 `return @"";` 结束，因此即使在缓存真实名称之后它仍返回空字符串；`-schemaName` 已经从同一位置返回同一字符串。没有读取者。
4. `MADModelDocument.m:228-234` 解码了一个文档 id（`docID`），却从未使用。
5. `MADModelQuery -update`（`MADModelQuery.m:354`）为空；`MADModelDatabase -update` 没有调用者；`+[MADModel newModelDocument:]` 没有调用者。
6. `MADModelType` 未使用。
7. 变更模型的私有队列与主线程读取者之间没有同步；而且 `MADModelDocument` 弱持有存储上下文，因此比其文档存活更久的模型没有上下文可解析任何东西。
8. 命名：`MADModelDocument` 有 `databases`，`MADModelDatabase` 有 `queries`——但文档是*按查询*构建一个“database”，而今天两者都恰好只有一个。这一结构是单数据库/单查询简化之前的前瞻性设计。

## 7. 重构候选（提案——均未实施）

按价值与风险之比排序。A 和 B 是纯整理；C 改变了公共头文件的承诺；D 是一个决策。

**A. 文档化，而非合并。** 最便宜的清晰度收益是按类添加头注释（2–4 行：这个类是什么、以什么为键、谁读取它），再加上本文档。合并这些类的*文件*是昂贵的选项，而不是便宜的：十六个以上文件导入按类拆分的头文件（`#import <MAD/MADModelQueryField.h>` 等），每个头文件在 Xcode target 中都是单独文件，而 Linux 构建的 include shim 是一个逐头文件符号链接的目录（`Linux/README.md`，MAD 的 shim）。合并会触碰 pbxproj、Linux 源文件列表和每个导入点，只为一个外观上的收益。如果真要合并，安全的方向恰恰相反：保持每个文件一个类，并让**入口点**显而易见（在 `MADModel.h` 顶部写明文档，“从 `MADModelDocument` 开始”）。

**B. 删除或补全残留表面。** 每一项都是行为安全的（没有代码读取它们），但会触及头文件，因此应视为 API 决策：
- `MADModelField.inTable`：修正类型并在 `MADModelTable -update` 中设置它（一行，与其他父级对称），或者删除该属性。
- `MADModelDatabase -driverName`：像其同级一样返回缓存值，或者删除它。
- `MADModelType`：删除该头文件。（需要从项目文件中移除；在一个提交中完成。）
- `+[MADModel newModelDocument:]`：要么让 `MADocument -documentModel` 使用它（恢复工厂方法的用途），要么删除它。
- `MADModelDocument.m:228-234` 中未使用的 `docID` 解码。

**C. 接通已声明的反向指针。** `inDatabase`、`inQuery` 和 `inQueryTable` 的存在是为了让图可以向上遍历；今天只有向下查找可用。在构造时赋值（`MADModelDatabase -updateTables` 已有 `self`；`insertTableRptqQueryTable:` 有模型查询；`-addField:schemaField:` 有表）可使对象图与其头文件一致，而且恰恰因为尚无代码读取它们而安全。需要留意的语义：它们声明为 `weak`，对于向下持有的父级来说这是正确的。

**D. 跨刷新的身份（这是一个决策，不是整理）。** `-update` 会替换对象；如果将来需要跨更新的稳定身份，更新方法必须就地变更（按标识符复用对象，增删差异），而不是重建。这会改变已交出对象的可观察身份，因此需要刻意选择。

**E. 机械去重。** `MADModelTable.fields` 和 `-fieldIDs`（`MADModelTable.m:88-118`）包含相同的初始化代码块两次，而 `MADModelQuery` 的三个 getter 重复了同样的“确保集合存在，然后更新”的套路（`MADModelQuery.m:116-181`）。两者都可以各自折叠为一个私有辅助方法，行为不变；只在因其他原因打开该文件时值得做。

**F. 不建议：重命名。** `MADModelDatabase` → 类似 `MADModelConnection` 会更好读，但这里的重命名是在 Xcode/Linux 项目文件中的无谓改动，没有功能收益。

## 8. 如果你要修改这一层

- 保持仅基于标识符的契约：模型对象必须能够仅凭 id 构造（通知路径和测试依赖这一点）。
- 任何创建或删除 `RptqQueryTable` / `RptqQueryLinks` 行的操作都会被 `MADModelDocument` 的观察者自动捕获——但只针对通过 `firstQuery` 可达的行；文档中的第二个查询不会被镜像。
- 四个 `MADNotification…` 名称是该层面向 UI 的公共 API；像 `MADQueryVisualizationViewController` 那样，针对 `firstQuery` 对象观察它们。
- iOS 套件（`MAD` scheme）和 `./Linux/build.sh` 都会编译这些文件；见 `Linux/cmake/MADSources.cmake`。
