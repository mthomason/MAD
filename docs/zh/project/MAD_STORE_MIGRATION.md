---
layout: default
lang: zh-CN
---

# `.mad` 存储迁移——从 Core Data 到可移植的 SQLite 存储

这是把 `.mad` 文档的存储从 Core Data 迁移到我们自己的 SQLite 架构的计划。它是 `MAD_FORMAT.md` §8.1 和 `ROADMAP.md` §4.2 所描述工作的基础，也是移除隐患 H3——格式中最后一个 Apple 依赖——的手段。

写于 2026-10-01，基于 `master` 的 `73468c6f4`；当日在阅读代码中实际的 Core Data 用法后修订，起因是用户的问题*“这真的需要 Core Data 式的故障加载（faulting）吗？”* 带有证据的答案见 §3。

---

## 1. 目标，用用户自己的话来说

核心问题是**可移植性**。`.mad` 内部的存储是一个 Core Data SQLite 文件，而 Core Data 在 Apple 平台之外并不存在。由于 `MADocument` 是 `UIManagedDocument`，离开 Core Data 也会移除 iCloud 文档机制——而且**剥离 iCloud 是本计划的明确组成部分，而非副作用。** `MADDocument` 用 `UIDocument` 取代 `UIManagedDocument`，iCloud/ubiquity 容器和文件协调路径随之消失，文档同步不再提供。旧文档不会因此被搁置：用户通过 iOS“文件”App 访问它们并用本应用打开，应用会在打开时进行转换——取回这些文档并不需要 iCloud 机制。

用户的心智模型（代码也证实了这一点）：*“我只是把它看作一个简单的数据库。”* 迁移保留自动生成的 `Rptq` 头文件，作为固定的、手工维护的契约，并由我们自己编写插入/更新/读取代码。

**成功标准：** 除 iCloud 之外的一切继续正常工作。本地文档的打开/保存、查询和设计器工具、查看器、刷新/导出，以及 `.maddb` / `.mdcache` / `.madac` 缓存都表现如常；只有 iCloud 同步路径被移除。

---

## 2. 实际存储的内容

三样东西，仅此而已。它们全都是*定义*——行数据存放在 `.maddb` 缓存中，不属于这个存储。

| 部分 | 实体 | 如何进入 |
|---|---|---|
| **架构** | `RptqDatabase`、`RptqDatabaseSchemaTable`、`RptqDatabaseSchemaField`、`RptqDatabaseCredentals` | 在创建文档时由 `MADOperationCreateDocumentImportSchema` 从源数据库导入，读取 `MADDatabaseTable` / `MADDatabaseField` 并写入 `Rptq` 实体。**可重新加载**——导入是批量替换（丢弃旧的表/字段，写入新的）。 |
| **查询** | `RptqQuery`、`RptqQueryTable`、`RptqQueryField`、`RptqQueryLinks`、`RptqQueryGroup`、`RptqQueryPredicate`、`RptqQuerySort` | 由用户在 MAD Query 标签页中构建。 |
| **布局** | `RptqDocument`、`RptqDocumentSection`、`RptqDocumentSectionRows`、`RptqDocumentElement` + 8 个子类，加上值类型（`RptqPoint`、`RptqRect`、`RptqSize`、`RptqAlignment`、`RptqBorder`、`RptqTextStyle`、`RptqNumericFormat`、`RptqDirectional*`） | 由用户在 MAD Designer 标签页中构建。 |

该图是一棵树，以每个实体都携带的 `identifier`（`Integer 64`）为键。32 个实体、四个有序的对多关系、四个可转换属性和一个多对多连接表，都如本文档原始版本之后附带的模型转储所述。

---

## 3. 代码实际用 Core Data 做了什么

这才是要紧的研究。它涉及的表面比“Core Data”这个词听起来要小得多。

**获取，大多按标识符。** 约有 81 处获取/执行位置，但主要模式是：按 `identifier` 获取单个对象（`RptqDocumentElement -newDocumentElementWithIdentifier:fromObjectContext:`、`RptqDocumentSection -newDocumentSectionWithIdentifier:…`），以及用 `fetchLimit = 1` 获取唯一的根对象（`RptqDocument -newDocumentReadFromManagedObjectContext:`）。这就是一条 `SELECT … WHERE identifier = ?`——在普通 SQLite 存储中轻而易举。

**关系遍历，目前是故障加载。** 诸如 `MADQueryFull.m:151-152` 的代码先读取 `document.hasDatabaseSchemas.anyObject`，再读取 `databaseSchema.hasQueries.anyObject`。这会对每个关系进行惰性故障加载。但整个定义不到 80 KB，因此**故障加载是实现细节，而非需求**——以三个部分（架构、查询、布局）为粒度的惰性加载绰绰有余，用户不一次性全部加载的直觉是对的。

**少量生命周期钩子。** 约 11 个 `Rptq+Extras` 文件中的 `-awakeFromInsert` / `-awakeFromFetch` 负责分配 `identifier` 和默认值。`obtainPermanentIDsForObjects:` 只出现一次。KVO（对 `identifier` 调用 `-willChangeValueForKey:`）用于扇出变更通知。所有这些都有普通的等价物。

**两个需要替换的真正 Core Data 特性，都很小：**
- `NSFetchedResultsController`——用于 `MADQueryBuilderAddTableViewController` 和 `MTGraph+RptqQuery`。它为表格视图提供分组和变更跟踪。普通存储用变更时手动重新加载来替代，应用在其他地方已经这样做（`reloadData` 随处可见）。
- 托管对象上下文上的 `NSUndoManager`（§4）。

**撤销——用户标记的那部分，它并不是阻碍。** 所有撤销逻辑都在 `MADDesignerLayout` 中，而且是**手动的、高层的撤销**：每个操作都调用 `[delegate.undoManager setActionName:…]` 和 `[delegate.undoManager registerUndoWithTarget:self handler:…]`，其中处理程序调用*相反*的高层方法（例如 `updateElements:setBold:` 注册的撤销会调用 `updateElements:setBold:NO`）。相反操作按标识符重新获取并重新设置属性。因此撤销恰好需要三样东西，没有一样来自 Core Data：一个 `NSUndoManager`（Foundation 类）、按标识符获取、设置属性。它**不**依赖 Core Data 的自动变更跟踪——没有 `processPendingChanges` / `disableUndoRegistration` 调用，也没有对自动撤销的依赖。

**一个干净的领域层已经存在。** `MADModel*`（`MADModelDocument`、`MADModelDatabase`、`MADModelQuery`、`MADModelTable`、`MADModelField` 等）是普通的 `NSObject` 子类，包装 `Rptq` 实体并暴露应用的词汇——`databases`、`firstQuery`、`tableDictionary`。约 20 个文件使用它；其余直接访问 `Rptq`。这就是接缝：迁移把 `MADModel*`（以及 `Rptq` 访问器）重新指向我们的存储，而领域层在可辨认的范围内保持不变。

---

## 4. 存储应该是什么样

一个普通的 SQLite 架构，每个实体一张表，以 `identifier` 为键，对象图以外键形式保留，并在有序关系上设一列用于排序。可转换类型变成可移植的标量（`UIColor` → RGBA、`NSLocale` → 标识符字符串、`UIImage` → PNG）。多对多的 `inQuery` 保留其连接表。

与初稿的区别在于**加载模型**：没有按关系的故障加载。读取器按需获取三个部分——打开文档，在设计器标签页显示时获取 `RptqDocument` 行及其节树，在查询标签页显示时获取查询，在需要时获取架构。每一项都是一到两条带索引的 `SELECT`。

---

## 5. 困难部分，重新排序

1. **应用集成，而不是架构。** 大约 110 个文件涉及 `NSManagedObjectContext` / `NSFetchRequest` / `NSManagedObject`，约有 158 处获取/插入位置。这是工作的主体：用我们的存储替换 `@dynamic` Core Data 属性和 `NSFetchRequest`。
2. **撤销，但比担心的要小。** 保留 `NSUndoManager`；保留 `MADDesignerLayout` 的手动处理程序；针对我们的存储提供按 id 获取和设置属性。撤销*设计*已经是对的；改变的只是它的数据源。
3. **元素层次结构。** Core Data 已经把 8 个 `RptqDocumentElement` 子类展平到一张表中，带有 `Z_ENT` 判别列和名称改写过的列（`ZTEXT`/`ZTEXT1`、`ZGROUPNUMBER`/`ZGROUPNUMBER1`）。因此转换必须**通过模型对象**进行（用 Core Data 加载，再重新保存到我们的存储），绝不手工解析 `Z_` 表。
4. **`NSFetchedResultsController`。** 两个文件；替换为手动重新加载，应用在其他地方已经这样做。

---

## 6. 转换

用现有的 `MADocument` 路径读取旧版 `.mad`，遍历对象图，并将其序列化到我们的架构。每个旧版文档在迁移发布后的首次打开时运行一次，然后以新格式重新保存。两个随应用发布的样本（`London.mad`、`Music.mad`）是固定它的测试夹具。

---

## 7. 分阶段

- **阶段 A——独立存储。** 定义 SQLite 架构以及一对能对 `RptqDocument` 图进行往返读写的读取器/写入器。以无头方式验证：在内存中构建图、写入、读回、断言相等——包括按标识符获取和按部分获取。
  *已完成：* `MAD/Source/rptq/store/`，含 `MADStoreTests`。
- **阶段 B——转换。** 打开 Core Data `.mad`，序列化到新存储。由两个样本通过*转换 → 读取 → 比较*来固定。
  *已完成：* `MADStoreConverter`——存储家族中唯一导入 Core Data 的文件。它遍历模型对象（绝不使用 Core Data 的 `Z_` 表），由 `MADStoreSchema` 驱动属性和边列表，因此两者不会漂移，并为模型未提供标识符的十个实体生成标识符。由 `MADStoreConverterTests` 固定，该测试转换两个随发布的样本并比较图，也针对 Core Data 统计每一行。有一处差异是故意保留的：模型把凭据的键称为 `dbkey`，而存储称之为 `key`，转换器对其重命名而不是改动任何一侧。
- **阶段 C——应用集成。** 用我们的存储替换 `Rptq` 类的 Core Data 后端，保留头文件，按实体家族逐个进行（先架构，再查询，然后节/元素），并用变更时重新加载替换 `NSFetchedResultsController`。设计器/查询/查看器标签页就是验收测试，撤销全程保持可用。
  *2026-10-03 以三个里程碑落地，每个都以绿色结束*——细节见 `MAD_STORE_PHASE_C.md`，未完成事项见其 §9。

  - **（a）替换与文档路径。** 全部 33 个 `Rptq` 类已脱离 `NSManagedObject`；`MADocument` 的打开/保存经由存储进行（打开时转换旧版 Core Data 文档）。MAD 框架套件绿色。
  - **（b）应用。** `MADDesigner` 已迁移——有四个 `NSFetchedResultsController` 使用点，而不是计划中预测的两个。两个套件均为绿色。
  - **（c）验收路径。** 归档层面的旧版往返、端到端的撤销、针对 Sqlite3 源创建文档的链路、在模拟器中走查三个标签页，以及真正的脏跟踪：无所变更时 `save:` 提前返回，否则只写入脏行。MAD 框架 222 个测试，MAD Designer 70 个——于 2026-10-03 实测。

  两项发现界定了剩余工作。第一，**并非每个元素查询都能工作**：复数的 `objectsForEntity:` 没有子实体回退，因此四处请求 `RptqDocumentElement` 并期望得到其子类的调用点什么也拿不到——见 `MAD_STORE_PHASE_C.md` 的 §9.1。第二，本应抓住这个问题的测试与缺陷一致，因为它们以相同方式收窄了范围（§9，“覆盖率的教训”）。剩余阶段 C 工作就是这些事项，加上那些被点名推迟的加固工作。
- **阶段 D——移除 Core Data 和 iCloud。** 删除 `UIManagedDocument` / Core Data 栈、值转换器、`.xcdatamodel` 以及 iCloud 机制（`UIManagedDocument` → `UIDocument`、ubiquity 容器、文件协调）。去 iCloud 化和简化在这里落地，这也是本计划有意改变的唯一行为。

  **阶段 D 绝不能漏掉的一项：** 里程碑（c）把 `MAD.momd` 编译进了 **MAD 框架**，以便旧版文档总能找到其模型进行转换。在旧版转换存在期间这是正确的，当它停止时必须移除——否则框架会在内部携带 Core Data 模型，这与本次迁移的目的正好相反。转换本身（`MADStoreConverter`）是同一时点要退役的另一项：一旦没有正式发布的文档是 v0，旧版转换就是累赘。

  **2026-10-04 落地，带有一处有意的偏离（`2bf9af919` 及其后续）。** 模型离开了 MAD 框架——由应用包和测试包携带它，转换正位于那里——`MADStoreConverter` 随之移到 `MADDesigner/Source/MADStoreLegacy/`，通过 `MADLegacyStoreConversion`（框架拥有的协议注册表，因此没有任何框架引用应用代码）访问。**转换被保留，这是用户的决定：** iCloud 时代的文档仍通过“文件”App 到达用户手中，退役转换器会让它们搁浅。因此上文“一旦没有正式发布的文档是 v0 就退役它”的说明尚不适用；当没有正式发布的文档是 v0 时，会重新考虑。

  **阶段 D 绝不能漏掉的第二项：iCloud 时代的文档在打开时转换。** 拥有旧报表的用户——可能很少——通过 iOS“文件”App 访问它们并交给应用，应用在打开时通过 `MADStoreConverter` 转换它们，与任何其他旧版文档路径相同。iCloud 机制本身（ubiquity 容器、文件协调、同步）在取回这些文档时并不需要，因此删除它不会让任何文档搁浅。唯一的要求是在旧版文档存在期间保留打开时转换——上文第一项已经涵盖。

**不早于阶段 C：** 将 `MADOperationRefresh` 移入 `MAD`（`ROADMAP.md` §3.4）和驱动注册表（`§5.1`）；一旦存储归我们所有，两者都会更便宜。

---

## 8. 用户必须做出的决定

- **`Rptq` 类是否仍保留为 `NSManagedObject` 子类？** 建议不要——它们变成由我们的存储支持的普通对象，保留属性名和 `MADModel*` 层。这就是“保留头文件，编写 CRUD”在实践中的含义，它决定了其余一切。
- **加载粒度。** 建议：按部分（架构/查询/布局）按需获取，而不是整个图，也不是按关系。这与用户的“我不会一次性全部加载”相符。
- **可转换类型的线格式。** 颜色用 RGBA 还是十六进制；图像用 PNG 还是 JPEG。在架构中固定它们，以便第二个平台以相同方式读取。

---

## 9. 长期约束

- 两个随发布的样本全程保持可打开；它们是转换的测试夹具。
- 不会因此从 `Compressor/library` 中删除任何东西。
- `+[NSString stringWithFormat:]` 继续远离紧密循环；遵循 `initWithFormat:` / `appendFormat:` 的团队风格。
- 行为安全：测试套件是证明。约 110 个 Core Data 文件是已知的混乱之处，用户说过既然我们在里面，就值得收紧。
