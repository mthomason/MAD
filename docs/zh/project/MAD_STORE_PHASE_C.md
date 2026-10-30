---
layout: default
lang: zh-CN
---

# 阶段 C——应用集成：机制

这是把 `Rptq` 类从 `NSManagedObject` 子类转变为由可移植存储支持的普通对象，并用存储替换应用的 `NSManagedObjectContext` / `NSFetchRequest` / `NSEntityDescription` 用法的设计。阶段 C 的其余部分是执行这一机制；架构家族切片是它的第一个证明。

§8 是执行替换所依据的迁移地图；**§9 是里程碑（a）–（c）的审查和未完成事项清单**，写于 2026-10-03。开始进一步工作之前请阅读 §9。

## 1. 两个新类型

一切都依附于两个存储侧类型，两者都不含 Core Data：

- **`RptqObject`**——`Rptq` 实体继承的普通基类。它包装一个 `MADStoreObject`（原始行：实体、标识符、值、引用、集合）和一个指向拥有它的上下文的弱回指针。
- **`RptqStoreContext`**——`NSManagedObjectContext` 角色的存储支持替代品。它拥有一个打开的 `MADStore`，持有已加载的 `MADStoreGraph`（已完成逆关系），并且是创建、故障加载、保存和删除对象的唯一场所。

`MADStoreObject` 本身*就是*那一行。`RptqObject` 只增加一个上下文和带类型的故障加载访问；`RptqStoreContext` 增加存储有意不具备的对象图语义（身份、逆关系维护、脏跟踪）。

## 2. 属性支撑

`Rptq` 头文件保留其属性声明。`.m` 文件不再为 Core Data 声明 `@dynamic`，而是从 `RptqObject` 继承通用访问，后者重写了两个 KVC 兜底钩子：

- `valueForUndefinedKey:`——在 `MADStoreSchema` 中查找该键。**属性**读取 `backingObject.values[name]`；**对一关系**通过上下文把 `references[name]` 解析为已故障加载的 `RptqObject`；**对多关系**按顺序把 `collections[name]` 解析为已故障加载的 `RptqObject` 组成的 `NSArray`。
- `setValue:forUndefinedKey:`——镜像操作，也是进行逆关系维护的地方（见 §4）。

由于 `MADStoreSchema` 已经携带每个属性的名称、类型和关系描述符，因此**没有逐实体的访问器代码**需要编写：架构是路由的唯一事实来源，正如它对存储的读取器/写入器一样。头文件仍然承诺的类型化 `@dynamic` 访问器由基类上的 `resolveInstanceMethod:` 满足（一个分派到这两个钩子的通用 getter/setter），因此 `element.textStyle.bold = bold` 继续编译并照常运行。

## 3. 获取、插入、保存

应用的三个 Core Data 动词一一对应：

| 目前 | 存储支持 |
|---|---|
| `+[RptqX fetchRequest]` + `executeFetchRequest:`（投影字典） | `-[RptqStoreContext objectsForEntity:]` + 对已故障加载对象的属性读取 |
| `NSEntityDescription insertNewObjectForEntityForName:` | `-[RptqStoreContext insertObjectForEntity:identifier:]` |
| `[context save:]` | `-[RptqStoreContext save:]` → `-[MADStore writeGraph:replacingAll:]` |
| `[context objectWithID:]` / 按 id 获取 | `-[RptqStoreContext objectForEntity:identifier:]` |
| `RptqDataHelper nextIdentifierForClass:` | 已加载图上的最大标识符 + 1 |

按迁移计划的 §8，加载是按部分进行的（`-[RptqStoreContext loadPart:]` → `graphForPart:`），既不按关系，也不加载整个图。

`MADModel*` 层保留其公共 API 和基于 `_uid` 的对象模型；只有它的 `NSFetchRequest`/`NSExpressionDescription` 投影获取被重写为普通属性读取（它们本来就只需要 `{identifier, name, queryable}` 形状的元组）。`MADModel*` 目前持有一个 `__weak NSManagedObjectContext`；该 ivar 的类型改为 `RptqStoreContext`，该层契约中的其他内容都不变。

## 4. 关系与故障加载

对一边是以标识符形式存在于 `references` 中；对多边是 `collections` 中的有序标识符列表。`RptqObject` 惰性解析边——`objectForEntity:identifier:`——因此“故障”只是一个带有未加载行的存储支持对象，而加载一个部分会一次性填满该部分的所有行（存储读取的是一张表，而不是一行）。

设置一条边会维护其逆关系，镜像 Core Data 自动完成的行为以及 `graphByCompletingInverses` 在图层面所做的：

- 设置 `db.ownedByUser = credential` → 同时设置 `credential.inDatabase = db`，因此导入流程的 `credential.inDatabase.databaseDriverTypeEnum = …` 继续工作。
- 追加到 `document.hasDatabaseSchemas` → 同时设置每个数据库的 `ownedByQueryAsStaticResource`。

上下文针对图中的 `MADStoreObject` 执行这些操作，因此即使在保存之前也成立，并且与存储自身的逆关系补全幂等。

## 5. 撤销

撤销是高层的，且已经与形状无关：在 `NSUndoManager` 上调用 `registerUndoWithTarget:handler:`，其处理程序调用按 id 获取 + 设置属性（`[RptqDocumentElement newDocumentElementWithIdentifier:fromObjectContext:]`，然后 `element.textStyle.bold = bold`）。按 id 获取是 `objectForEntity:identifier:`，设置属性是 `setValue:forUndefinedKey:`——不再有任何 Core Data 特有的东西。

## 6. `NSFetchedResultsController`

两个文件使用它（`MADQueryBuilderAddTableViewController`、`MTGraph+RptqQuery`）。存储没有实时查询，因此两者都变成先加载、变更时重新加载：获取行、存放在数组中，并在文档发出变更信号时重新加载视图（`MADModel*` 层已经为此发布 `MADNotificationQueryTableInsert`/`…Delete`）。

## 7. 顺序安排（如何在不破坏构建的情况下落地该阶段）

整个 `Rptq` 层次结构在一个机械步骤中切换父类（33 个 `.m` 文件：移除 Core Data，移除工厂的 `initWithEntity:insertIntoManagedObjectContext:`，改用 `insertObjectForEntity:`）。应用的*使用*按家族逐个迁移，先架构，再查询，然后节/元素——每个家族都把 `MADModel*` 读取和操作插入重新指向存储。尚未迁移的家族之所以还能编译，仅因为父类替换是一次性预先完成的；不存在 Core Data 关系伸入普通对象的半转换对象图。

这个检查点交付两个类型、路由，以及针对存储验证过的架构家族，此时应用的查询或节/元素代码尚未迁移。

---

## 8. 剩余工作：替换与使用方迁移（切片 2）

上述机制已落地并通过（213 个测试）。下一个切片是父类替换加上使用方迁移，这是剩余阶段 C 工作的全部。以下是该地图的记录，以便该切片能在冷启动下继续。

### 8.1 替换（机械式、脚本化）

三十三个自动生成的实体。二十四个声明 `: NSManagedObject`；九个 `RptqDocumentElement*` 子类声明 `: RptqDocumentElement` 并继承这一变化。

- 在每个 `autogen/*.h` 中：用 `#import "RptqObject.h"` 替换两行 `#import <CoreData/NSManagedObject.h>` / `#import <CoreData/NSFetchRequest.h>`；把 `: NSManagedObject` 改为 `: RptqObject`；删除每个 `+ (NSFetchRequest…) fetchRequest…` 声明。
- 在每个 `autogen/*.m` 中：删除 `+fetchRequest` 方法体（保留 `@dynamic` 列表）。有两个文件带有手工添加的 Core Data 方法需要改为剥离：`RptqQuery.m`（`fetchRequestTableCount:objectContext:`，从 `MADDesigner/Source/MADQueryViewDataSource.m:125` 调用）以及 `RptqQuery.h` 中的头文件声明。
- `@dynamic` 保留；`RptqObject` 上的 `+resolveInstanceMethod:` 提供访问器（见 §2）。

### 8.2 使用方表面（约 65 个文件）

- **Extras**（`MAD/Source/rptq/*+Extras.{h,m}`）：工厂方法（`new…FactoryForManagedObjectContext:`）、`awakeFromInsert`（标识符自增——现在是 `insertObjectForEntity:identifier:0`）、`NSFetchRequest` 投影辅助方法（删除——它们的调用方直接读取存储），以及 `objectWithID:` / `[obj managedObjectContext]` 位置。全部将 `NSManagedObjectContext *` → `RptqStoreContext *`。
- **`RptqDataHelper`**：`nextIdentifierForClass:managedObjectContext:` 被 `insertObjectForEntity:identifier:0` 取代；保留该类或将其折叠掉。
- **`MADModel*`**（`MADModelDatabase/Table/Field/Document/Query/QueryTable/QueryLink`）：`__weak NSManagedObjectContext *` ivar 变为 `RptqStoreContext *`；每个 `NSFetchRequest` + `NSExpressionDescription` 投影变成 `objectsForEntity:` + 属性读取（例如 `MADModelDatabase.updateTables` 本来就只需要 `{identifier, name, queryable}`）。
- **`MADocument`**：打开 = 解档 + 通过 `RptqStoreContext` 加载可移植存储（当存储仍是 Core Data 时先运行 `MADStoreConverter`）；保存 = 写入存储而不是 `[super writeContents:]`。`activeDocumentModel` 从上下文读取根对象。
- **操作**（`MADOperationCreateDocument*`）：带 `parentContext` 的私有 `NSManagedObjectContext` 变成基于存储的 `RptqStoreContext`；`storeDatabaseConnectionDefination:` 和 `storeTablesAndFieldsForTables:`（在 `RptqDocument+Extras.m` 中）是架构写入路径。
- **MAD 查询/报表源码**（`MADQueryFull`、`MADQuerySelectExpression*`、`MADReportFormatter`、`MADSectionLayout`、`MADSectionsLayout`、`MADReportSection`、`MADQueryActiveQueryFields` 等）：获取/插入位置。
- **MADDesigner**（约 22 个文件，`MADQuery*` 控制器、设计器元素视图、条码、`MTGraph+RptqQuery`）：两处 `NSFetchedResultsController` 使用（`MADQueryBuilderAddTableViewController`、`MTGraph+RptqQuery`）变成加载 + 重新加载。
- **测试**：`MADCoreDataModelTests`（模型加载）基本保留；`MADRptqDatabaseTests`、`MADRptqDocumentSectionTests`、`MADRptqQueryTests`、`MADRptqValueTypeTests` 通过 Core Data 构建对象，必须切换到 `RptqStoreContext` + `insertObjectForEntity:`。

### 8.3 写/读词汇（已构建）

`insertObjectForEntity:identifier:`（为 0 时铸造）、`objectForEntity:identifier:`、`objectsForEntity:`、`loadPart:`/`loadAllWithError:`、`save:`、`deleteObject:error:`、`setRelationship:value:onObject:` + `addObject:toRelationshipNamed:onObject:` / `removeObject:fromRelationshipNamed:onObject:`（维护逆关系），以及通过 `+resolveInstanceMethod:` 的 `@dynamic` 点语法。

---

## 9. 审查发现，2026-10-03

里程碑（a）、（b）和（c）已落地，并依据其已提交的差异进行了审查。经验证良好的内容见 §9.4；以下是未完成事项，按应处理的顺序排列。

### 9.1 `objectsForEntity:` 遗漏子实体行——已完成

在提交 `3a949dcd1` 中修复：复数图查找和注册表查找现在携带与单数查找相同的表回退，且限定到该表的**所有者**实体（基实体查询返回共享该表的每一种类型；针对单一类型的查询仍保持精确）。`allObjects` 是直接的按标识符排序遍历，因此回退不会重复计数，写入器的行顺序保持稳定。转换器测试的参考获取现在为拥有表的实体设置 `includesSubentities`，其总数在各自的类型下对每一行只计数一次，而 `testBaseEntityQueryReturnsRowsOfMixedKinds` 按计数固定了一个混合类型的基实体查询——一个静默返回空结果的查找无法通过。全部四个活跃位置都恢复了（dropIndex 扫描、`nextDropIndexForSection:`、两处 `delete*RelatedToTable:` 清理）。

### 9.2 覆盖率的教训——已完成

已应用：参考实现现在提出的问题与代码不同（对拥有表的实体使用 `includesSubentities = YES`，总数使用精确计数），并且新查找有一个基于计数的测试，在结果为空时会失败。见 9.1。

### 9.3 未完成清单的其余部分

- **`RptqObject` 身份——已完成。** 基于（实体、标识符）实现 `-isEqual:`/`-hash:`，注册表以该行自身的实体为键，查找时使用相同的所有者表回退。通过两个名称到达的同一行只故障加载一次，`-save:` 的删除清理在 `row.entity` 下找到该条目。
- **非可选属性的默认值在写入时填充——已完成。** 填充移到了 `insertObjectForEntity:`，正如 Core Data 在插入时应用默认值；`writeRowForObject:` 不再臆造值，而某行如果不知何故缺失默认值，会大声触发 NOT NULL 约束失败。保存路径去掉了 `O(attributes × columns)` 的逐行填充。
- **以 `object: nil` 注册的通知——已完成，且信号已接通（里程碑 d）。** 处理程序按文档自己的存储上下文进行过滤，而 `handleManagedObjectContextWillSave:` 与其同类一样针对 nil 注册。`RptqStoreContext` 发布自己的变更通知（object = 上下文，自阶段 D 起以 `RptqStoreContext*` 名称镜像 Core Data 的 userInfo 键），合并为每个运行循环轮次一次发布，从插入、标记对象已更改、删除以及保存之后触发。设计器的撤销按钮和元素刷新处理程序，以及查询控制器的列表跟踪，再次消费它（Query 标签页的表、链接、分组和谓词列表会重新填充），`MADModelDocument` / `MADQueryFull` 也会接收它。**决定（2026-10-06）：** `MADDocumentState.needsSave` / `.contextChagned` 保留——用户决定：它们预留给未来的云状态功能；今天没有任何东西读取它们，`BUGS.md` 记录了这一点。
- **`closeWithCompletionHandler:` 绕过 `[super …]`——已由阶段 D 解决。** 文档已迁移到 `UIDocument`，打开/关闭再次经过状态机：`open` 报告 `UIDocumentStateNormal` 并注册其文件呈现器（file presenter），`close` 保存、释放存储、返回 `UIDocumentStateClosed` 并注销呈现器。从未打开过的文档仍被显式处理（UIDocument 的 close 不会为它回调）。由 `testOpenAndCloseMoveThroughTheUIDocumentStateMachine` 加上原有的 `testCloseReachesClosedStateAndReleasesTheFilePresenter` 固定。
- **`objectsForEntity:` 每次调用都排序和分配——未关闭，低优先级。** 未做记忆化：没有任何分析显示它是热点。如果将来分析显示为热点，再按加载进行记忆化。
- **从 `MADSectionsLayout` 投影中移除 `layoutHeight`——确认安全。** 模型属性及其 setter 仍在（`RptqDocument+Extras.m:291,336`）；没有投影使用方读取它。
- **发布应用中的测试脚手架——已完成。** `-UITestOpenSample` / `-UITestSelectTab` 钩子被包裹在 `#if DEBUG` 中。
- **`MAD.momd` 曾被编译进 MAD 框架**，以便旧版转换总能找到其模型。**在阶段 D 中完成，并记录了决定：** 模型离开了框架（现在由应用包和测试包携带它，转换正位于那里），`MADStoreConverter` 移到了 `MADDesigner/Source/MADStoreLegacy/`，通过 `MADLegacyStoreConversion` 访问。转换被有意保留——用户决定，2026-10-04：用户会打开 iCloud 时代的文档，它们必须被转换——因此 `MAD_STORE_MIGRATION.md` §7 中“一旦没有正式发布的文档是 v0 就退役它”的说明已被取代；见该文档的阶段 D 文本。

### 9.4 验证良好

- **刷新和分页未受存储迁移影响。** `MADReportFormatter.m`、`MADDataTableFast.m` 和 `MADArrayCaching.m` 与 `master` 的差异为零；行缓存和渲染缓存仍然承载热路径，正如 `MAD_FORMAT.md` §5 所描述。
- **没有遗留的 Core Data 调用。** 每个 Core Data 专有选择器（`executeFetchRequest`、`objectWithID`、`existingObjectWithID`、`insertNewObjectForEntityForName`、`registeredObjects`、`refreshObject:mergeChanges:`、`deleteCacheWithName`）都在 MAD 和 MADDesigner 中扫过：唯一的命中是一段被注释掉的代码块和 `MADStoreConverter`，后者是被允许的。**阶段 D 将其推至终局（2026-10-06）：** 转换器及其 `NSManagedObject`/`NSFetchRequest` 代码移到了应用 target，残留的导入、`@class` 前向声明、无用的获取请求投影（`MADModelDocument`、`MADModelQueryLink`、`NSPredicate+Creators` 的 object-ID 变体）、`MADTableFieldReference` 孪生类和 `MADSectionLayout.objectID` 属性都已消失，`MAD`/`MADDesigner` 在 `MADDesigner/Source/MADStoreLegacy/` 和测试包之外没有任何 Core Data 导入即可编译。
- **被移除的 `awakeFromInsert` 方法体只做标识符分配**，现在由 `insertObjectForEntity:` 执行——没有行为损失。
- **两个 Sqlite3 驱动修复是真实的。** `connectWithConnection:` 确实打开了数据库却返回 `nil`；`fieldsForTable:` 确实在要求字段时列出了表，而 `PRAGMA table_info` 是正确的替代品。
- **脏跟踪是真实的。** 干净时 `-save:` 在任何 I/O 之前提前返回，增量路径只写入脏行、脏的有序父级的位置，以及脏参与者的连接行。
