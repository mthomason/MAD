---
layout: default
title: "多源报表"
description: "把报表当作表，以及为任何返回表的来源提供驱动。"
lang: zh-CN
---

# 多源报表——把报表当作表，以及为任何来源提供驱动

本页描述可组合报表：一份报表的结果成为另一份报表可查询的表，而驱动可以为任何返回行的来源提供前端。它是一份设计记录；§8 列出了各阶段，并非全部都已构建。

**范围：** 用户于 2026-11-22 描述的架构：用户针对一个数据源（MySQL、SQL Server、PostgreSQL、SQLite，或诸如 eBay
Seller API 的 Web API）设计一份报表；该报表的结果是一张物化 SQLite 表；另一份报表可以
针对那份报表设计查询——把一份报表的输出与另一份报表的
输出以及基础来源，在同一个查询图中联接。刷新时引擎自底向上遍历该图，让每个叶子针对自己的来源执行、物化每个结果，最后
在物化之上运行组合查询。非 SQL 驱动的接缝是其中一部分：为 API 提供前端的驱动接收结构化查询，而非 SQL 文本，并以表形式返回
行。
**日期：** 2026-11-22，读取于 `eba4225a1`；决策于 2026-11-22 并入（§9.2）。
**状态：** 设计报告。它陈述想法和设计；不实现任何东西，也不给 `TASKS.md` 添加工作。支撑
数据对象那一半的代码审计是 [`MAD_DATA_OBJECT.md`](data-object.md)；方向是
[`docs/vision.md`](../vision.md)。本文档增加多源组合模型
（先做文档内子报表）、使非 SQL 来源成为一等的驱动 API，
以及合并后的阶段顺序。

---

## 1. 这个想法，一页纸

报表是从数据源到表的函数。本设计所关心的“账户与订单”之别
已在代码中：

- **定义**是查询图——表、字段、联接、谓词、分组——
  加上带区布局。它位于 `.mad` 归档中。
- **结果**是一个架构（`MADDataColumn`）和行。它位于文档旁的
  伴随 SQLite 缓存（`.maddb` + `.mdcache`）中，在归档之外，因为它是
  派生的、可重新生成的。

扩展是让结果**可作为表寻址**。一份报表的输出于是
成为另一份报表的来源，正如今天架构表是来源一样。建立在
报表之上的报表是派生表的 DAG：一个可移植语义层，设计
报表的同时也在设计可复用的数据源。

同一扩展使多源报表变得自然。每个来源对象针对
自己的数据库或 API、以自己的驱动和凭据执行，并物化进自己的
SQLite 表。组合对象针对**本地缓存**而非远程
服务器执行，联接这些物化。不添加联邦引擎；快照就是
联邦。

用户的例子：一家企业想要其 eBay 商品列表的报表。一个报表对象
查询 eBay Seller API 并物化商品列表；另一个查询公司的
MySQL 数据库以获取销售；一份组合报表按 SKU 联接两个输出。每个驱动只
了解自己的来源。联接发生在 SQLite 中，本地进行。

非 SQL 驱动正是让第一个对象成为可能的东西。其契约与 SQL 驱动所满足的“架构加行”契约
相同——但它的输入应是查询
图，而非它必须解析的 SQL 字符串。

## 2. 代码中已经成立的事实

昂贵的部分已存在。`MAD_DATA_OBJECT.md` §3 是详细审计；本报告的关键承载
事实是：

1. **定义是图，且存储允许多个。** `RptqQuery` 拥有表、
   字段、联接、谓词和分组。`MADModelDocument` 为每个 `RptqQuery` 构建一个 `MADModelDatabase`，
   代码自己的注释说当前版本只用一个。这一基数
   是应用流程的约定，而非存储的（`MAD_DATA_OBJECT.md` §3.1）。
2. **编译器已存在且是确定性的。** `MADQueryFull -copySQLWithManagedObjectContext:error:`
   （`MAD/Source/MADQueryFull.m:133-273`）构建 SELECT 列表、从
   拓扑排序图构建 FROM/JOIN 树、WHERE 子句和限制，经由驱动的
   方言钩子。
3. **执行接缝已是表形态。** `MADDatabase` 的抽象点是
   `executeSQL:fieldKeys:onConnection:intoResultTable:withError:`
   （`MADAPI/Source/MADDatabaseProtocol.h:33-34`），目标是任何
   `id <MADDataTableWriting>`，而非具体表类。全部四个驱动以相同
   方式填充它：移除所有对象、添加列、批量插入、添加行。
4. **物化是真正的 SQLite 表。** `MADDataTableFast` 写出
   `<tag>.maddb` 和表 `t<tag>`（`MADSqlite3/Source/MADDataTableFast.m:403-406`、
   `:463-467`、`:503-511`）。架构 plist 是 `.mdcache`；行与架构可分离
   （`docs/05-companion-files.md` §5）。SQLite 已是驱动
   （`MADSqlite3/Source/MADDatabaseSqlite3.m`），因此“数据库”为缓存的查询是
   今天的代码，而非新代码。
5. **缓存是可丢弃的、每设备的。** 它不在文档中，也不在 iCloud
   中（`docs/05-companion-files.md` §5.2）。对派生产物而言这是正确的，但它是对任何把另一份报表缓存当作来源的设计的
   约束：缓存可能不在那里。

同一节还列出了三个单查询硬接线点，它们今天
仍然成立：

- `MADQueryFull` 重新读取文档的第一个数据库和第一个查询，而非使用
  它初始化时所带的查询（`MAD/Source/MADQueryFull.m:147-149`）。
- `MADocument -dataTableForQuery:` 是一个单槽开关：对 `MADQueryFull` 返回文档的唯一表，
  对其他一切返回 nil（`MAD/Source/MADocument.m:873-880`）。
- `MADQueryActiveQueryFields` 扫描存储中的每个元素、联接和分组，没有
  查询作用域（`MAD/Source/MADQueryActiveQueryFields.m:27-100`）。第二个查询的字段
  会泄漏进第一个查询的 SELECT 列表。

组合设计还有两个事实重要：

- **地址是文件名哈希。** 文档以
  `initWithId: self.fileURL.lastPathComponent.hash`（`MAD/Source/MADocument.m:273-275`）创建其表，且
  缓存目录以该哈希命名。没有东西能通过稳定的
  身份指向该表。
- **一个 `MADDataTableFast` 就是一个文件。** `filenameCacheMadDB` 是 `<tag>.maddb`
  （`MADSqlite3/Source/MADDataTableFast.m:403-406`），每个实例打开自己的插入
  和选择连接（`:482-501`）。今天没有“一个 `.maddb` 中多张表”的模式。
  `MAD_DATA_OBJECT.md` §5.1 把该模式描述为设计变体；当前
  类不实现它。
- **没有 `ATTACH` 支持。** 搜索 `MADSqlite3`、`MAD` 和 `CLI` 找不到
  `ATTACH DATABASE` 的使用。跨文件组合需要添加它，或添加拷入步骤。

## 3. 组合模型

### 3.1 节点与边

- **来源对象**拥有一个 `RptqDatabase`（驱动 + 连接 + 凭据）和一个
  查询定义。它针对自己的来源执行。
- **组合对象**拥有一个表为其他数据对象（来源或组合）的查询。它针对本地缓存执行。
  在本设计中，组合对象不拥有远程来源：它需要的远程表是一个**来源对象**，它引用其输出。
  这使节点分类保持为两种——远程叶子与本地组合者——并保持刷新遍历诚实。
- **边**是组合查询中对另一个对象输出架构的表引用。
- 图必须无环。环是设计时错误，在违规引用处报告，
  而非刷新时的栈溢出。

### 3.2 刷新是拓扑的

1. 自底向上遍历 DAG。既有编译器已对联接图进行拓扑排序
   （`MAD/Source/MADQueryFull.m:170-204`）；对象图在
   对象级别需要同样的纪律。
2. 让每个叶子针对自己的来源、通过自己的驱动执行，进入自己的
   物化。
3. 附加或打开组合对象所需的物化。
4. 针对本地 SQLite 数据库执行组合查询并物化其结果。
5. 沿图重复。根是一份普通报表；其缓存就是查看器所读取的。

分页不变。引擎仍把完整结果拉进本地缓存；UI
在缓存上分页。对 API 驱动而言，“分页”是对 API 各页的**内部循环**，以填充其物化；
它不是与引擎之间的流式或分页契约。计划中的 `limit`/`offset` 用于设计模式预览，以及希望限制其抓取的驱动，
而非查看器的分页。

分组、排序和聚合不变：它们在本地缓存之上计算
（`MAD_DATA_OBJECT.md` §3.5）。驱动返回明细行；它不需要实现
`GROUP BY` 或报表的分组。计划中的排序提示让驱动在有限制时下推
top-N 请求；引擎仍会重新排序。

### 3.3 两种物化布局

用户的直觉是 `ATTACH`，而当前代码使它成为更短的路径。

**布局 A——每个来源对象一个 `.maddb`，用 `ATTACH` 联接。**
- 每个对象的 `MADDataTableFast` 保留自己的 `<tag>.maddb` 和 `t<tag>`。
- 组合查询打开到本地缓存（或内存数据库）的连接，并
  为所需的每个来源对象运行 `ATTACH DATABASE '<path>' AS <alias>`。
- SQL 生成把表限定为 `<alias>.t<tag>`。
- 新工作：`MADDatabaseSqlite3` 中对 `ATTACH` 的支持、别名管理和路径引用。
  该类已是完整的 SQLite 包装器，因此这是小的新增。
- 限制：SQLite 的 `SQLITE_MAX_ATTACHED` 默认 10，仓库中没有任何构建配方
  提高它（`Compressor/sqlite3.xcconfig`、`Linux/`、`Windows/Engine/`）。提高
  它是三个平台上的构建变更。v1 把超过十个直接来源视为
  设计时错误。
- 组合对象自身像任何其他结果一样物化进自己的 `.maddb`。

**布局 B——一个 `.maddb` 中多张表。**
- 每文档一个缓存文件，多个 `t<tag>` 表，无 `ATTACH`。
- 这需要把 `MADDataTableFast` 从“一个实例拥有一个文件”改为共享
  文件/连接模型，或在其上添加表注册表。这比 `ATTACH` 更大的改动，
  且与类当前每表一文件的设计相悖。
- 其优势是单一文件且无附加限制。

**建议：** 首次组合实现采用布局 A，因为它遵循
当前类边界并匹配用户的模型。若曾重新审视每表一文件模型，布局 B 仍是更干净的
长期文件故事。

### 3.4 引用意味着什么

组合查询的表引用需要在 `databaseSchemaTable`
（今天的 `RptqQueryTable.databaseSchemaTable`，`MAD/Source/rptq/autogen/RptqQueryTable.h:27`）之外增加第二种。
用户的决定（2026-11-22）是组合**先做文档内**：一个 `.mad`
文档包含多个报表/查询定义——**子报表**——组合
报表按其身份引用其中一个。单可移植文件属性得以保留，且
v1 不会出现 iOS 跨文件重新授权问题。对**另一个 `.mad` 文件中报表**
的引用（文档身份加路径）是较晚、单独的关切，
推迟到同文档组合之后。

缓存是每设备且可丢弃的，因此引用记录*要运行什么*，而非*数据在哪里*：

- **实时引用（默认）。** 父级存储子级的定义引用，并在
  刷新时执行子级并物化其结果。
- **钉住快照。** 父级在伴随缓存中保留子级的物化
  （`.maddb`/`.mdcache`），并复用它而非重新执行子级。钉住是保留的
  缓存产物，**绝不是嵌入 `.mad` 中的数据**——归档保持仅定义
  （§6）。实时和钉住都从缓存目录读取；“钉住”意味着“保留并复用
  此物化”，而非“把数据复制进文档”。

物化命名从文件名哈希移到稳定对象身份，使文件
不会冲突，且父级可以寻址特定子级（§3.6、§6）。

### 3.4.1 父级如何命名子级的列

`RptqQueryField` 恰好有一个字段引用 `databaseSchemaField`
（`MAD/Source/rptq/autogen/RptqQueryField.h:27`），且选择构建器、联接构建器、
谓词和联接 UI 都读取 `queryField.databaseSchemaField.name`。子级的输出
列是 `MADDataColumn`，而非架构字段。建议是**从子级的 `MADDataColumn` 合成
每对象的结果架构表和字段集**：父级的查询字段于是指向普通架构字段行，所有既有构建器
和 UI 无需改动即可工作。合成行是子级结果架构的快照，并在子级架构变化时刷新。替代方案——在 `RptqQueryField` 上增加第二种字段引用
——会触碰每个构建器，不推荐。**构建者决定。**

### 3.5 失败、陈旧与协调

- 若子级失败，父级刷新以子级的错误和该节点名称失败。父级
  先前的缓存不会被半构建的结果替换。
- 缺失的子级文件、移动的文件、变化的架构或缺失的凭据，是
  UI 可以解释的刷新时错误，而非静默的空结果。
- 环、自引用以及同时是祖先的子级，在执行前被拒绝。
- 跨文档引用（推迟到 v1 之后）在到来时，将经由 iOS 上的文件
  协调和安全作用域 URL；iCloud 可能驱逐子级。CLI 和
  macOS 采用显式路径。设计需要在三者之间一个路径解析策略。
- 刷新进度应按节点。子级中长时间的 API 抓取应显示为该
  子级的进度，而非不明原因的停滞。
- 取消必须到达正在运行的驱动。当前执行方法是同步的
  且没有取消令牌；计划执行选项对象是放置它的自然位置。

### 3.6 父级存储什么

设计时父级需要子级的**结果架构**——列名、类型、
长度——以绘制联接 UI 并校验字段引用。它不应需要子级的
行，也不应需要子级的源连接。架构就是缓存已序列化的同一
`MADDataColumn` 描述。这是数据对象契约的“无需执行即可 describe”那一半；
它是组合的前提条件，而非可选的锦上添花。

用户的决定（2026-11-22）是**结果架构就是活动字段**——
报表元素、联接和分组所引用的列——正是 `MADQueryActiveQueryFields` 已计算的 SELECT 列表
（`MAD/Source/MADQueryActiveQueryFields.m:27-100`）。
无行为变化：describe 在不运行的情况下把该列表作为 `MADDataColumn` 返回。
全列形式仍是表预览的关切，而非数据对象架构。公开列
名应是人类可读的：`MADDataColumn.caption` 已存在用于显示名，
SELECT 列表构建器应在架构字段有显示名时从中设置它，
而非只暴露内部 `"Table0"."Field"` 别名。

还缺一块身份：**根**。`RptqDocument -mainQuery` 和
`RptqDatabase -defaultQuery` 都是 `hasQueries.anyObject`
（`MAD/Source/rptq/RptqDocument+Extras.m:184-186`、
`MAD/Source/rptq/RptqDatabase+Extras.m:88`），而 `MADocument -database` 取
`hasDatabaseSchemas.anyObject`（`MAD/Source/MADocument.m:1248-1258`）。当一个文档中有多个数据
对象时，查看器和设计器所渲染的查询是非确定性的。给文档添加
显式根引用（或标志），把今天的单查询迁移到它。**构建者决定。**

## 4. 非 SQL 来源的驱动接缝

### 4.1 为何 SQL 文本是错误的边界

今天报表刷新把图编译为 SQL 并调用
`executeSQL:fieldKeys:onConnection:intoResultTable:withError:`
（`MAD/Source/MADOperationRefresh.m:134`）。对 SQL 方言而言这是正确的。对 REST API
而言，它迫使驱动把 SQL 解析回图，而解析器的子集至少在两个地方与
生成的 SQL 不匹配：生成器追加一个 `LIMIT` 子句
（`MADQueryFull.m:164`），而 `MADSQLParser` 拒绝它（`MAD/Source/sql/MADSQLParser.m:151-154`）；
且设计器可以生成 `NATURAL`/`CROSS` 联接
（`RptqQueryLinks+Extras.m:76-86`、`MADQueryLinkType.h:15-16`），解析器同样拒绝
（`MADSQLParser.m:330-338`）。复用解析器还会颠倒分层：它位于
`MAD` 中、驱动之上，而在 Linux 上 `mad` 以 whole-archive 链接驱动
（`Linux/CMakeLists.txt:469-474`）。

直接传 `MADQuery`/`MADQueryFull` 也不是答案：`MADQueryFull` 绑定存储、位于 `MAD`，且
只在构建 SQL 时计算活动字段列表。驱动会针对文档存储编译。

### 4.2 计划

在 `MADAPI` 中添加驱动中立的值对象：

```objc
@interface MADQueryPlanTable : NSObject
@property (copy) NSString *name;                        // schema table or object name
@property (copy) NSString *alias;                       // query alias
@property (copy, nullable) NSString *sourceIdentifier;  // nil = schema table
@end

@interface MADQueryPlanField : NSObject
@property (strong) MADQueryPlanTable *table;
@property (copy) NSString *field;
@property (copy) NSString *outputKey; // exactly what the driver names the column
@end

@interface MADQueryPlanLink : NSObject
@property (assign) MADLinkType type;              // moved down to MADAPI
@property (strong) MADQueryPlanTable *leftTable, *rightTable;
@property (copy) NSString *leftField, *rightField;
@end

@interface MADQueryPlanPredicate : NSObject
@property (assign) MADPredicateOperator op;        // moved down to MADAPI
@property (strong) MADQueryPlanOperand *left, *right; // field reference or literal
@end

@interface MADQueryPlan : NSObject
@property (copy) NSArray<MADQueryPlanTable *> *tables;
@property (copy) NSArray<MADQueryPlanField *> *fields;   // the active SELECT list
@property (copy) NSArray<MADQueryPlanLink *> *links;
@property (copy) NSArray<MADQueryPlanPredicate *> *predicates;
@property (copy) NSArray<MADQueryPlanSort *> *sort;      // pushdown hint
@property (assign) NSUInteger limit;
@property (assign) NSUInteger offset;
@end
```

`MADLinkType`、`MADPredicateOperator` 和 `MADSortOrder` 目前在 `MAD` 中
（`MAD/Source/MADQueryLinkType.h`、`MADPredicateOperator.h`、`MADSortOrder.h`）。`MADAPI` 中的
计划在它们下移之前无法引用它们（或计划定义自己的枚举，
这会重复模型）。下移这三个纯枚举是正确的修复。

执行成为既有协议上的可选方法：

```objc
@protocol MADDatabaseDataSource <NSObject>
// existing required methods stay ...
@optional
- (BOOL)executeQueryPlan:(MADQueryPlan *)plan
                 options:(MADDatabaseExecutionOptions *)options
          intoResultTable:(id <MADDataTableWriting>)table
                withError:(NSError **)error;
@end

@interface MADDatabaseExecutionOptions : NSObject
@property (copy) BOOL (^isCancelled)(void);
@property (copy) void (^progress)(double fraction, NSString *node);
@property (strong) id credentials;                  // driver-specific, or a resolver
@property (copy) NSArray<MADMaterializationReference *> *attachments; // SQLite composer
@end
```

计划保持**逻辑**；选项承载执行上下文。组合 SQLite
驱动把每张表的 `sourceIdentifier` 解析为 `options` 中提供的附加项（路径、表、别名）。
这使文件路径远离第三方驱动表面，并为
取消和逐节点进度提供归宿。**构建者决定。**

当驱动实现它时 `MADOperationRefresh` 优先使用它，否则回退到
既有 SQL 路径。四个随附驱动在第一天无需改动。参考
实现可以在内部把计划编译为 SQL，并断言它与
当前编译器的输出匹配，从而以既有套件锁定该计划。

### 4.3 能力

引擎和 UI 应询问驱动它能做什么，而非硬编码驱动 ID：

```objc
@interface MADDatabaseCapabilities : NSObject
@property (assign) MADLinkTypeMask supportedLinkTypes;
@property (assign) MADPredicateOperatorMask supportedOperators;
@property (assign) BOOL supportsLimitOffset;
@property (assign) BOOL supportsServerSideSort;
@property (assign) BOOL supportsNativeStatementText; // SQL editor
@property (assign) BOOL isReadOnly;
@property (assign) NSUInteger maximumPageSize;
@end
```

这取代了 `MADDesigner/Source/MADDriverSelectorController.m:64-90,124-140`、
`MAD/Source/rptq/RptqDatabaseCredentals+MADDatabaseConnection.m:19-33`、
`Mac/Source/MADMacConnectionWindowController.m:198-204,359-375`、
`CLI/Source/MADCLIServe.m:277-291` 以及
`MADDesigner/Source/MADQueryAddLinkJoinTypeController.m:46-95` 中硬编码的驱动列表和联接规则。注册表已
枚举驱动（`registeredDriverClasses`）；UI 可以使用它加上
`driverName`/`imageIconName` 而非 switch。

### 4.4 每层保留什么

- **架构浏览**保持 `getTables:` / `getTablesFromConnection:error:` 和
  `fieldsForTable:connection:error:`。非 SQL 驱动返回 `MADDatabaseTable` 和
  `MADDatabaseField` 值；报表用户像今天架构表一样在查询设计器中看到它们。
- **结果契约**保持 `id <MADDataTableWriting>`；驱动添加
  `MADDataColumn` 和以 `fieldKeys`/`outputKey` 为键的行。
- **分组、排序、聚合**保持在引擎中、缓存之上。驱动返回
  明细行。
- **联接**是一种能力：原生、客户端或不受支持。组合是
  回退。不支持联接的驱动仍可作为来源对象；用户
  把资源拆成单独对象，并在组合报表中联接它们。
- **SQL 文本录入与校验探查**受能力门控。非 SQL 驱动不需要
  接受粘贴的 SELECT。
- **注册**可以保留在连接类（`MADDatabaseDriver`）上以保持兼容。
  更干净的长期契约把类型、标识符、能力和连接
  构造放在 `MADDatabase` 子类上；这可与当前
  协议并行添加，不破坏四个驱动。

## 5. 通用 API 驱动

用户的“为整类数据源提供单一驱动”是一个架构来自**来源清单**、而非代码的驱动。引擎看到普通的 `MADDatabase`；
清单告诉驱动存在哪些表、字段、端点和分页规则。

最小清单形态：

```json
{
  "name": "eBay Seller",
  "baseURL": "https://api.ebay.com",
  "resources": {
    "listings": {
      "path": "/sell/inventory/v1/inventory_item",
      "rowsPath": "inventoryItems",
      "primaryKey": "sku",
      "pagination": { "limitParam": "limit", "offsetParam": "offset", "max": 100 },
      "fields": {
        "sku": "string",
        "listingId": "string",
        "product.title": "string",
        "price.value": "number"
      },
      "filters": { "sku": { "eq": "sku" } }
    }
  }
}
```

驱动把计划映射为请求：

- `tables[0]` 选择资源。
- `fields` 变成选择列表，若 API 返回整个对象则被忽略。
- `predicates` 在清单命名映射时变成查询参数；否则
  驱动在本地筛选。
- `limit`/`offset` 驱动页循环。无限制时驱动分页直到耗尽。
- `links` 在 API 支持时是原生的，在驱动实现哈希
  联接时是客户端的，或不受支持（该能力在 UI 中禁用联接）。
- JSON 值通过清单的字段类型映射到 `MADDataType`。

连接方面，今天的凭据行覆盖 SQL 驱动（`host`、`username`、
`password`、`database`）。对于需要客户端密钥、刷新令牌、
商城 ID 或沙箱标志的 API 驱动，用户的决定（2026-11-22）是凭据上单一**可扩展
选项字段**：一个文本列持有 JSON（或 XML），版本化进
存储格式，由驱动解析——而非每个驱动新增一个存储列。既有的
字段映射常见情形（`host` = 基础 URL、`database` = 清单名、`username` =
客户端 ID、`password` = OAuth 令牌）。敏感值（客户端密钥、刷新令牌）属于
钥匙串，而非文档；JSON 持有非密钥形态加一个钥匙串键
引用。这不是变通——它是扩展点，使驱动在每次添加参数时
无需改变文档格式。

清单的作者身份**先是随附/由开发者编写**（用户的决定，
2026-11-22）：驱动的开发者编写清单并随驱动发布。面向用户的清单编辑器/导入及其信任边界推迟到插件
系统之后（§5.1）。长期愿望——驱动可插拔、并通过
UI 添加/移除——记录在此；它首先是 macOS/Linux/Windows 和服务器关切，因为 iOS
历来阻止加载任意第三方代码，因此在 iOS 上驱动保持在构建时链接。

通用驱动还承担计划不承担的非 SQL 义务：HTTP 客户端和
TLS、认证刷新、速率限制、重试、取消、响应大小上限和错误
映射。那些属于驱动框架，而非引擎。

通用驱动不能做什么与能做什么同样重要：任意 GraphQL、行非表格的来源，
或清单无法表达的服务器端联接。能力对象是它说明这一点的方式，
而查询设计器是用户得知的地方。

### 5.1 即插即用驱动（未来，非 v1）

用户更大的目标是像插件一样安装、注册和注销的驱动，
且能通过 UI 添加或移除，而非链接进应用。注册表
已按链接做每进程注册（驱动教程 §1）；真正的插件
系统是叠在其上的打包与信任问题：动态加载、发现
位置、签名/沙箱和 UI。那是 macOS/Linux/Windows 和服务器功能，而非
iOS 功能，且不在本设计各阶段的范围内。此处提及是为了让
驱动接缝（阶段 0）不会把自己画进角落：计划、能力和
注册类型应保持可从动态链接镜像加载，这意味着不
在编译时耦合到固定驱动列表。

## 6. 存储与格式中改变什么

最小形态，遵循 `MAD_DATA_OBJECT.md` §4.4：

- `RptqQuery` 获得名称。它已是定义。
- `RptqQueryTable` 的引用获得第二种：**同一文档中的数据对象（子报表）**，
  除架构表之外。命名架构表的 v1 行含义与今天完全
  相同。对*另一个* `.mad` 文件中报表的引用推迟到
  v1 之后；到来时需要文档身份和路径，加上实时/钉住标记。
- 凭据获得可扩展的 **options** 文本列（JSON/XML），用于驱动特定
  参数（§5），随格式版本化。
- 物化地址变成对象的身份哈希，而非
  `fileURL.lastPathComponent.hash`。表名保持 `t<tag>`；tag 变成
  对象的身份。
- 每个对象获得自己的架构 plist（`.mdcache`）和表。布局 A 保持每对象一个文件；
  布局 B 会改变文件模型。
- 存储需要为新引用和选项字段添加版本步骤。既有
  存储已有用于 SQL 来源列的版本化机制（`MADStoreSchema.m:314`），
  因此这是已知模式，而非新机制。

`.mad` 文档保持定义，**现在和以后都不持有数据**——这是
用户的明确决定。快照和物化是用户系统上的伴随缓存文件，
它们是 `ATTACH` 联接在一起的东西。这些缓存文件的自动命名
从文件名哈希移到稳定对象身份，使文件不会冲突。

## 7. UI、CLI 与无头引擎

- Add Table 面板增加第二类来源：文档的其他数据对象
  （子报表）。联接 UI 不变；两端都是字段。跨文档 `.mad`
  引用是较晚的添加。
- 设计器必须能够在不执行的情况下显示子级的结果架构，并在刷新前
  标记损坏的引用（架构变化、凭据缺失）。
- 刷新需要逐节点进度和错误。失败的子级应被明确命名。
- 凭据按节点。同文档子报表把凭据保留在一个
  文档中，因此策略按对象；跨文档刷新在到来时需要
  获取子级凭据的策略。
- CLI 和无头引擎遍历同一 DAG。`MADOperationRefresh` 由
  应用、macOS 和 CLI 共享（`CLI/Source/MADCLIDocument.m:120-127`、
  `Mac/Source/MADMacDocument.m:337-360`），因此拓扑遍历属于那里或它调用的辅助方法，
  而非每个前端。
- macOS 应用的连接表单和 CLI 的驱动令牌映射需要与 iOS 选择器
  相同的注册表驱动处理。

## 8. 阶段

排序使每个阶段发布时通过，且单查询应用继续工作。第一阶段
独立于组合，是解锁非 SQL 来源的那一个。

| 阶段 | 工作 | 依赖 |
|---|---|---|
| 0 | **驱动接缝。** 添加 `MADQueryPlan` + 值类型并把三个枚举移到 `MADAPI`；添加可选的 `executeQueryPlan:`；添加能力；让刷新优先使用计划并回退到 SQL。在一个既有驱动中实现计划作为参考，并用测试锁定计划到 SQL 的等价性。无行为变化。 | — |
| 1 | **数据对象契约。** 把 SELECT 列表构造从执行中拆出；添加 describe/execute；把结果架构作为 `MADDataColumn` 返回；让刷新调用该契约。这是 `MAD_DATA_OBJECT.md` 阶段 1。 | 0（重叠） |
| 2 | **查询拥有自己。** `MADQueryFull` 使用所给的查询；`dataTableForQuery:` 按查询解析；`MADQueryActiveQueryFields` 限定到查询；`MADModelDocument` 镜像任何查询。 | 1 |
| 3 | **同文档组合。** 查询表可以引用另一个数据对象（子报表）；拓扑刷新；`MADDatabaseSqlite3` 中对 `ATTACH` 的支持；组合查询针对本地缓存执行。这是用户的单可移植文件模型。 | 1、2 |
| 4 | **跨文档组合（推迟）。** 对另一个 `.mad` 报表的引用；文档身份和路径解析；实时 vs 钉住；文件协调；凭据策略；缺失/重命名处理。优先级较低：同文档组合已满足用户的模型。 | 3 |
| 5 | **通用 API 驱动。** 一个清单驱动的 HTTP/JSON 驱动；架构来自清单；计划到请求的映射；分页循环；类型映射；可扩展凭据 `options` 字段；eBay Seller 作为示例。 | 0、1（以及联接的 3） |
| 6 | **表面与文档。** 注册表驱动的驱动列表和联接规则；逐节点刷新 UI；CLI 动词；用计划/能力接缝更新驱动编写教程。 | 0–5 |

不是一个阶段：**即插即用驱动加载**（§5.1）是与本设计分开跟踪的 macOS/Linux/Windows 和服务器
功能；阶段 0–6 没有任何东西依赖它，阶段 0
只应避免耦合到固定驱动列表，使动态加载保持可能。

阶段 0 是“不远”的部分：它是新值类型、一个可选方法、刷新中的一个分支和测试。
它不需要存储、UI 或组合模型改变。阶段 3 是用户的 `ATTACH` 模型落地之处，它比听起来更小，
因为 SQLite 已是驱动，且编译器已排序图。

## 9. 决策

### 9.1 本文档记录的构建者决定

这些由代码或设计权衡敲定；可以重新审视，但计划假定它们。

1. **布局 A，用 `ATTACH`。** 每对象一个 `.maddb`；组合连接附加
   它们。这遵循 `MADDataTableFast` 的每表一文件模型。布局 B（一个文件中多张表）
   是较晚重构，非 v1。这取代 `MAD_DATA_OBJECT.md` §9.2 对本设计的
   布局 B 建议。
2. **组合对象仅限本地。** 组合查询的表是数据对象；远程表
   包装在来源对象中。无混合远程/本地执行。
3. **父级的子级字段是普通架构字段。** 从子级的 `MADDataColumn` 合成每对象
   结果架构表/字段集，并在子级架构变化时刷新它。无第二种字段引用
   种类。
4. **根是显式的。** 文档级根引用（或标志），从
   今天的单查询迁移。而非 `hasQueries.anyObject`。
5. **计划是逻辑的；执行上下文是单独的。** `MADDatabaseExecutionOptions`
   承载取消、进度、凭据和 SQLite 组合者的附加集。
   `MADQueryPlanTable.sourceIdentifier` 命名逻辑来源；它不是文件路径。
6. **超过十个直接来源在 v1 中是设计时错误。** 提高
   `SQLITE_MAX_ATTACHED` 是三平台构建变更，推迟。
7. **与 SQL 编译器并行构建计划，然后锁定等价性。** 在计划由当前
   套件证明之前，不要把 SQL 编译器重构为从计划渲染。
8. **命名已有的 `RptqQuery`；暂不引入 `RptqDataObject`。**
   `MAD_DATA_OBJECT.md` §9.1 建议这一点，且迁移更小。
9. **为兼容保留连接类上的 `MADDatabaseDriver`。** 以后可以并行添加
   数据库类注册契约。
10. **第一个通用 API 驱动声明联接不受支持。** 它依赖组合
    实现联接，然后在能力对象后长出客户端哈希联接。这使
    第一个驱动保持为单资源抓取。
11. **同文档组合先于跨文档发布。** 阶段 3 退役硬接线点，
    无路径/协调/凭据复杂性；跨文档是
    阶段 4。

### 9.2 用户回答的决策（2026-11-22）

以下是用户的原话；含义由作者给出。

1. **输出架构是活动字段——不变。** 数据对象的输出是
   报表使用的列：布局元素的字段、联接字段和分组
   字段，正是 `MADQueryActiveQueryFields` 已计算的 SELECT 列表
   （`MADQueryActiveQueryFields.m:27-100`）。用户：*"it would just be the fields that are
   used in that report."* 全列形式仅是表预览的关切。Describe
   在不执行的情况下把同一列表作为 `MADDataColumn` 返回。两个后果被记为
   未来功能，而非本工作的一部分：**人类可读的列名**（设置
   已存在的 `MADDataColumn.caption`，而非只暴露
   `"Table0"."Field"` 别名），以及**预览分页**（预览目前上限约 512 行，
   应分页遍历完整结果——用户将此标记到愿望清单，即用户的 `TODO.md`，而非本文档）。零行规则仍然适用：来源
   对象即使返回零行也会物化其完整架构。
2. **驱动预期在每个平台上运行；即插即用是目标。** 用户：
   *"That's really up to the person who writes the driver, but yes I'd expect so."*
   无头引擎和同一 DAG 在 Linux/Windows 上成立；*某个*驱动是否
   无头运行是其作者的事。更大的愿望——*"drivers could be plug-and-play…
   add and remove drivers through the UI"*——是 §5.1，一个未来功能，也是
   macOS/Linux/Windows/服务器关切，因为 iOS 历来阻止加载任意
   第三方代码。
3. **快照位于伴随缓存，绝不在 `.mad` 中。** 用户：*"The `.mad`
   file only describes the schema… that shouldn't change… It would be in whatever the cache
   file is right now… the cached files that are Sqlite3 data stores, and that is what would
   be `ATTACH`ed together."* 因此归档保持仅定义；钉住的快照是
   保留的 `.maddb`/`.mdcache`，物化命名移到稳定对象身份
   以避免冲突。
4. **清单先是随附/由开发者编写。** 用户：*"your answer is correct…
   the idea was always that new drivers could be added through some plugin system… I don't
   believe you can have plugins in iOS."* v1 发布一个清单驱动、由
   开发者编写清单的驱动；面向用户的清单编辑器/导入及其信任边界
   居于插件系统之后。
5. **组合先做文档内——一个可移植文件中的子报表。** 用户：
   *"maybe you could add 'sub-reports' to the mad document… the idea would still be one
   portable file."* 一个 `.mad` 包含多个报表/查询定义；每个运行到一张
   SQLite 表；组合报表 `ATTACH` 它们。这保留了单文件属性
   并为 v1 移除 iOS 跨文件重新授权问题。跨*文档*
   引用推迟到同文档组合之后。
6. **凭据长出可扩展选项字段。** 用户：*"we could design one and add
   it to the report format… perhaps all in one database field, that we parse out somehow
   (like JSON or XML) so it can be extensible."* 一个文本列持有 JSON，版本化进
   存储，由驱动解析。敏感值（客户端密钥、刷新令牌）放入
   钥匙串；JSON 持有非密钥形态加一个钥匙串引用。

### 9.3 作者假定的默认值（构建者决定）

- **实时是默认；钉住意味着保留缓存快照。** 实时在
  刷新时执行子级；钉住复用保留的物化。两者都从缓存目录读取。
- **刷新策略。** 刷新时重新计算每个节点（用户的自底向上描述）。对昂贵 API 子级的
  新鲜度/缓存复用旋钮是较晚的添加，位于
  能力对象之后。
- **命名。** “Data object”是存储/协议术语；“sub-report”是用户面向的术语，
  用于组合 UI 中被引用的对象。

## 10. 风险，以及为何它不是一行代码

- **三个硬接线点**（`MADQueryFull` 的重新读取、单槽数据表、
  无作用域的活动字段）是今天单查询应用的关键承载。它们必须在第二个查询——更不用说嵌套查询——
  能执行之前倒下。
- **缓存地址是文件名哈希**，且缓存是每设备的。可寻址性是
  前提条件，而非细节。
- **跨文档引用**带来路径解析、iCloud 驱逐、文件协调、
  缺失子级，以及父级不拥有的来源的凭据。这是最
  产品密集的部分。
- **`ATTACH` 有上限**（`SQLITE_MAX_ATTACHED`，默认 10），且需要别名/名称
  管理和路径引用。不要在生产中发现它。
- **全量刷新成本。** 缓存设计按设计是拉取一切；DAG 会使
  其倍增。缓存/新鲜度策略是设计的一部分，而非优化。
- **API 速率限制和数据量。** 每次刷新都为 API 分页的驱动需要
   重试、上限、取消和可见的进度故事。
- **架构漂移。** 子级的列可能变化；父级的查询随后引用不再
   存在的字段。需要设计时校验和刷新时错误。
- **驱动 API 稳定性。** 第三方驱动针对 `MADAPI` 编译；计划和
   能力类型成为公开表面。要刻意版本化它们。
- **测试矩阵。** 四个平台（iOS、macOS、Linux、Windows）、SQL 和非 SQL 驱动、
  同文档和跨文档组合。阶段顺序就是缓解：一次一个新
  轴。

## 11. 这不是什么

- **不是联邦引擎。** 没有新东西在一条语句中同时与 MySQL 和 API 对话。每个
  对象针对自己的来源执行；联接是本地。
- **不是第二套查询实现。** 图、编译器、驱动、结果
  表和 SQLite 的联接引擎都已存在。
- **不是对拉取一切缓存的改变。** 两遍缓存是关键承载
  （`docs/05-companion-files.md` §5.1）。
- **未排期。** 这是未来工作的设计记录。`docs/project/TODO.md` 是
  用户自己的愿望清单（预览分页的愿望属于那里），`TASKS.md` 是
  工程队列，`ROADMAP.md` 说明接下来做什么。此处没有东西在代理主动发起时
  开始。

此处提到两个未来功能，但它们属于用户的跟踪文件，而非本设计：
**预览分页**修复（§9.2.1）和**即插即用驱动系统**（§5.1）。本文档
是记录它们形态的地方；它不排期它们。

## 12. 主线

查询标签页已构建函数。刷新链已编译并执行
它。结果表已是磁盘上作为 SQLite 的架构加结果集。SQLite 已
是驱动。驱动已返回表。缺失的是名称、地址、describe 那一半，以及非 SQL 驱动所需的、代替
SQL 文本的结构化查询。那些都是增量的：计划值对象、能力对象、可选执行方法、
稳定对象身份、第二种表引用、拓扑遍历和 `ATTACH`。

组合于是就是既有管线，以比文件名哈希更好的东西寻址。
非 SQL 驱动是同一管线，只是执行体不同。两者都不是
新引擎；两者都是这些抽象本就是为了允许的。
