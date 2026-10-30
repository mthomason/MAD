---
layout: default
lang: zh-CN
---

# BUGS.md

一份持续维护的分诊清单，记录单元测试工作暴露出的缺陷、怪异行为和可疑行为。每个条目都由一个表征测试（characterization test）锁定，因此即使缺陷尚未修复，其行为也已被记录在案。

**已修复的缺陷会被归档。** 某个条目对应的缺陷修复后，该条目会——全文、提交哈希、测试等一切——迁移到 [`BUGS_FIXED.md`](BUGS_FIXED.md)，而这里会在其所属框架标题下保留一行索引，因此引用“BUGS.md，X 条目”仍然能落到实处。本文件是未关闭问题的记录：仍然错误、仍然可疑，或有意保持原样的内容。

状态说明：

- **已确认（Confirmed）** —— 测试证明该行为是错误的；按缺陷处理。
- **待调查（Investigate）** —— 可疑，但需要人工判断（可能是有意的临时做法，或旧的变通方案）。
- **怪异行为（Quirk）** —— 奇怪的实现细节，恰好产生正确的输出。
- **未修复（Open）** —— 已知，尚未修复。
- **已修复（Fixed）** —— 已修正；条目已迁移到 `BUGS_FIXED.md`。

## MADAPI

*已归档（已修复；全文、测试及任何提交哈希见 [`BUGS_FIXED.md`](BUGS_FIXED.md)）：*

- `MADDatabaseConnection` 的子类无法经受基类的 `NSCopying` / `NSCoding`
- `MADDatabase` 仅支持 NSCoding，因此安全归档会拒绝它
- `MADConnectionViewController` / `MADConnectionSQLGenericViewController` 的 `-databaseConnection` 抛出了 NSString
- `MADDatabaseDataBinding`：`nil` 与 `[NSNull null]` 的处理不一致
- `NSStringFromMADQueryType`：`MADQueryTypeCacheIndexDropParameters` 缺少 "TypeCache"
- `NSStringFromMADQueryType`：`MADQueryTypeSampleDataTableRange` 未映射

## MAD（框架）

### 文档缩略图使用了已废弃的 QuickLook 文件属性键
- **状态：** 未修复——有意保留，置于限定作用域的 pragma 之后。
- **问题：** `MAD/Source/MADocument.m -fileAttributesToWriteToURL:forSaveOperation:error:`
  用 `NSThumbnail1024x1024SizeKey` 和 `NSURLThumbnailDictionaryKey`（`:667`、`:671`）
  写入文档缩略图，这两个键在 iOS 15 中均已废弃，应改用 QuickLookThumbnailing。
- **为何此处不改：** 没有可直接替换的方案。现代做法是新建一个 QuickLook 缩略图扩展
  target，按需渲染图标；没有它而删除这段代码，会静默丢掉自定义文档图标。构建警告由一对
  `#pragma clang diagnostic` 在本地抑制，并指向本条目。
- **位置：** `MAD/Source/MADocument.m:661-676`。
- **后续：** 决定应用是否需要缩略图扩展；如果不需要，这段代码可以整体删除，pragma 也随之删除。
- **更新（2026-10-17）：** 当旧的 `-thumbnail` 属性为空时，该属性现在由缓存的缩略图 PNG 填充
  （`MADocument.m -fileAttributesToWriteToURL:...`），因此 Files 应用里的图标会在下次保存时显示
  报表的第一页。这些键仍然已废弃；QuickLook 扩展仍是后续事项。由
  `MADDocumentTests testFileAttributesUseTheCachedThumbnailWhenThePropertyIsNil`
  （提交 `8254c7264`）锁定。

### 渲染器的页面表示只保留它最后构建的一页
- **状态：** 怪异行为（无实际影响——没有任何代码读取它）
- **位置：** `MAD/Source/MADPrintPageRenderer.m:300-301`
  （`-buildPageAtIndex:context:inPageRect:`）、`MAD/Source/MADReportTextRepresentation.m`
  （`-removeAllPages`、`-setPage:forPageIndex:`）。
- **行为：** 每次构建页面都会清空渲染器的 `textRepresentation`，然后存入刚构建的那一页，
  因此在完整跑完第 0 页到第 N-1 页之后，该表示只保留第 N-1 页——而不是每一页，
  这与“报表的文本表示”听起来的意思不符。调用在遍历*之前*执行 `removeAllPages`，
  所以这是每次构建的重置，而不是字典里的 bug。
- **为何不会造成问题：** 唯一的读取者是 `-debugQuickLookObject`
  （`MADPrintPageRenderer.m:351`），它是对最后构建页面的调试视图；
  代码树中没有其他地方向该表示索取页面（`-pageIndex:` 没有调用者）。头文件中的承诺——
  “无论哪条路径，页面都会记录到 `-textRepresentation` 中”——在每一页上都成立。
  若调用者想要所有页面，只会得到一页。
- **保持不变**于 2026-10-16 遍历移到 `MADReportPageBuilder` 时：重置仍留在渲染器中原来的
  位置，因此 PDF 路径和缩略图路径看到的行为不变。如果将来有代码需要整份报表的文本，
  重置应放在页面循环之后（或放在 `-textRepresentation` 的属主中），而不是放在
  `-buildPageAtIndex:` 内部。
- **测试：** 无——没有调用者可供表征。记录于此，以免下一位读者把单页结果误认为丢失了页面。

### MADMySQLFetch 向函数传入了未初始化的值
- **状态：** 未修复——根据分析器运行结果记录。
- **问题：** `core.CallAndMessage` 报告 `MADMySQLFetch+DataTable.m:668` 处某函数调用的第一个参数
  在某些路径上未初始化。
- **位置：** `MADMySQL/Source/MADMySQLFetch+DataTable.m:668`。

### 可空性分析器报告 nil 跨越 nonnull 边界
- **状态：** 未修复——根据分析器运行结果记录；如果对应值真的为 nil，每一处都有崩溃风险。
- **问题：** `xcodebuild analyze` 报告了十四处 nil 跨越声明为非空的边界。返回点（方法承诺
  非 nil，却在守卫路径上 `return nil`）：`MADDocumentObjectDataReference.m:219,225,231,243,253,258`、
  `MADocument.m:978`、`MADStoreGraph.m:65`。实参点（把可能为 nil 的值传给非空参数）：
  `MADModelQuery.m:462,483`（把 nil 表传入字典）、`MADPrintPageElement.m:222`、
  `RptqDocument+Extras.m:610`（`[hasObjects insertObject:reportObject atIndex:0]` 的对象可能为 nil）。
- **备注：** `MADocument.m:598,624` 以前也出现在这里，已由上面的 `writeContents:` 条目覆盖；
  这两处随该条目的修复一并消失。
- **位置：** 上述 file:line 列表。
- **证据：** `xcodebuild analyze` 中的 `nullability.NullReturnedFromNonnull` 和
  `nullability.NullPassedToNonnull`。

### 存储的逐列读取循环依赖架构名为非 nil
- **状态：** 不变式，而非缺陷——记录下来供后续读者了解。
- **问题：** `MADStore.m` 的行循环把 `column.attribute.name`（以及
  `column.relationship.name`）传给 `setAttributeValue:forName:`，后者的实现执行
  `self.values[name] = value`。nil 键会抛异常，但架构总会给属性命名，因此调用点使用显式的
  `(NSString *)` 转换而不是守卫：这是填满每个文档的逐列、逐行循环，当 nil 名称意味着架构畸形时，
  这里加分支毫无收益。
- **位置：** `MAD/Source/rptq/store/MADStore.m:273-278`。

### `MADOperationCreateDocumentAddConnection` 在没有文档时报告成功
- **状态：** 已确认（潜在——仅在队列接线错误时才会走到）
- **位置：** `MAD/Source/MADOperationCreateDocumentAddConnection.m:38-58`
- **行为：** `-execute` 在依赖中查找
  `MADOperationCreateDocumentProtocol`；没有匹配项时 `document` 保持 nil，随后发送
  `[document activeDocumentModel]`（向 nil 发消息，因此是空操作），然后设置
  `self.success = YES` 并结束——没有错误，也没有文档。它的同类
  （`MADOperationCreateDocumentImportSchema`、`...SaveAndCloseNewDocument`）在同样情形下
  以错误结束，而 `MADOperationCreateDocumentFirstTimeSetup` 反而触发 `RptqDocument` 的
  nil 上下文 `NSAssert`，因此这一家族对同一个缺失依赖给出了三种不同答案。
- **为什么重要：** `success` 是排队的消费者能得到的唯一信号；顺序错误的队列会为从未发生的
  工作报告“连接已添加”。
- **测试：** `MADOperationCreateDocumentAddConnectionTests
  testExecuteWithoutADocumentDependencyStillReportsSuccess`。

### `MADOperationKeyChainDeletePassword` 的 `success` 始终不会离开 NO
- **状态：** 已确认（潜在——目前代码树中没有任何代码读取该属性）
- **位置：** `MAD/Source/MADOperationKeyChainDeletePassword.m:19,36-50`
- **行为：** 初始化器设置 `_success = NO`，而 `-execute` 从不给它赋值：
  一次 MADKeyChain 报告为干净的删除，结束时仍然是 `success == NO`。错误路径同样静默——
  删除失败时通过 `-finishWithError:` 携带错误，但标志位仍保持 NO，因此从该属性无法区分
  两种结果。
- **为什么重要：** 将来任何读取 `success` 而不检查
  `errors` 的消费者，都会把每次成功的删除当成失败。
- **测试：** `MADOperationKeyChainDeletePasswordTests
  testExecuteWithAMissingKeyFinishesWithoutError`。

### `MADOperationDeleteFile` 的依赖扫描依赖顺序，且可能协调 nil URL
- **状态：** 已确认（潜在）
- **位置：** `MAD/Source/MADOperationDeleteFile.m:34-60`
- **行为：** 同一个循环中有两个独立隐患：
  1. 扫描一看到 `MADOperationCreateDocumentProtocol`
     依赖就 `break`，所以恰好出现在 `-dependencies` 后面的 `MADOperationTestResults` 依赖
     （其顺序未定义）永远不会被考虑：`deleteFile`
     保持 NO，创建失败留下的文件留在磁盘上，尽管已经为它预留了唯一 URL。
  2. 当 `deleteFile` 为 YES 却没有看到 `MADOperationUniqueUrlForFilenameProtocol`
     依赖时，局部变量 `fileURL` 为 nil，却被交给
     `MADFileUtilities -removeFileAtURL:completion:`，后者再把它传给
     `NSFileAccessIntent`/`NSFileCoordinator`——很可能是无效参数导致的崩溃。
- **为什么重要：** 依赖顺序的路径无法确定性地复现，而
  nil URL 路径会崩溃而不是让操作失败。修复意味着拆分循环（收集全部三种依赖）并守卫 URL。
- **测试：** `MADOperationDeleteFileTests` 锁定了三条确定性路径
  （`testExecuteWithFailingResultsDeletesTheFile`、
  `testExecuteWithSuccessfulResultsLeavesTheFile`、
  `testExecuteWithOnlyADocumentDependencyDoesNotDelete`）；依赖顺序的
  组合和 nil URL 路径有意不做测试——前者无法锁定，后者会让测试进程崩溃。

### `MADOperationDocumentCloseDocument` 把“没有文档”当作成功关闭
- **状态：** 怪异行为（隐患——已记录，未更改）
- **位置：** `MAD/Source/MADOperationDocumentCloseDocument.m:30-52`
- **行为：** 没有 `MADOperationCreateDocumentProtocol` 依赖时，`doc` 为 nil；
  `(doc.documentState & UIDocumentStateClosed)` 为 0，`doc.storeContext == nil` 为真，
  于是守卫直接落到 `[MADocument close:nil completion:]`，后者把 nil 理解为“已经关闭”
  并报告成功。没有任何逻辑能区分关闭一个文档与根本没有文档——与上面的 AddConnection
  条目形态相同。
- **测试：** `MADOperationDocumentCloseDocumentTests
  testExecuteWithoutDependencyFinishes`。

### `MADReportSection -identifier` 在其 section 未接线时无限递归
- **状态：** 已确认（潜在）
- **位置：** `MAD/Source/MADReportSection.m:109-120`（`-documentSection`）和
  `:122`（`-identifier`）
- **行为：** `-identifier` 读取 `self.documentSection.identifier`。惰性
  getter `-documentSection` 在 `_documentSection` 为 nil 时，用
  `newDocumentSectionWithIdentifier:self.identifier` 构建一个——这会在 getter 存入任何值
  之前重新进入 `-identifier`：无界递归（栈溢出），而不是返回 nil。`-type`、`-height`、
  `-isVisible` 走同一个 getter，在未接线的 section 上会以同样方式递归。相关：
  `+initWithReportSection:` 对 `MADDocumentSectionTypeUnknown` 返回 nil
  （switch 的 default 分支让强引用局部变量零初始化），因此未知行会被静默丢弃，而不是
  被暴露出来。
- **测试：** 无——测试递归会让进程崩溃；本条来自代码阅读。Unknown 类型返回 nil 的行为由
  `MADReportSectionTests testInitWithAnUnknownTypeReturnsNil` 锁定（随本条目添加）。

### `RptqDocumentSectionEnumerator` 的两个枚举器与自身的计数不一致
- **状态：** 已确认（潜在——代码树中这两个枚举器没有调用者）
- **位置：** `MAD/Source/rptq/RptqDocumentSectionEnumerator.m:58-61`（类型枚举器的
  `-nextObject`）和 `:102-106`（行枚举器的）
- **行为：** *类型*枚举器预先自增行号
  （`getSectionTypeforRow:++_current`），因此第一次调用就跳过第 0 行（报表页眉），
  而且任何调用都不会终止——越过最后一行后它会一直返回
  `GroupFooter`。*行*枚举器忽略自己的 `_total`：没有查询时它照样返回第 0 行
  （一个并不存在的 `MADReportSection`），而且同样永不结束。
- **为什么重要：** 两者都是 `NSFastEnumeration` 源；任何遍历其中一个的代码都会得到
  无休止的流，并且缺少第一行（或出现幻影行）。
- **测试：** `RptqDocumentSectionEnumeratorTests
  testTypeEnumeratorNextObjectSkipsRowZeroAndHasNoEnd` 和
  `testNextObjectIgnoresTheCountWhenThereIsNoQuery`。

### `MADQueryFullTableEnumerator` 没有重写任何枚举方法
- **状态：** 怪异行为（死类——保持原样）
- **位置：** `MAD/Source/MADQueryFullTableEnumerator.m`
- **行为：** 它继承 `NSEnumerator` 并存储文档标识符和上下文，但从不重写
  `-nextObject`；枚举它会从 `NSEnumerator` 的抽象实现中抛出
  `NSInvalidArgumentException`。代码树中没有任何代码实例化它。
- **测试：** `MADQueryFullTableEnumeratorTests
  testNextObjectIsStillNSEnumeratorsAbstractImplementation`，它锁定继承而来的
  IMP，而不是调用它。

### `MADModelQueryTable -addField:schemaField:` 从不回填字段的查询表
- **状态：** 怪异行为（已记录，未更改）
- **位置：** `MAD/Source/model/MADModelQueryTable.m:92-105`
- **行为：** 字段以标识符为键注册到表的字典中，但它的 `inQueryTable` 反向引用从未设置
  （该类自己的初始化器也没有设置），因此每个 `MADModelQueryField` 报告的查询表都是 nil。
- **为什么重要：** 目前影响不大——没有代码读取该反向引用——但它让注册变成单向的，
  会让下一位读者感到意外。
- **测试：** `MADModelQueryTableTests testAddFieldRegistersTheFieldUnderItsIdentifier`。

### `MADDocumentObjectDataReference -copyWithZone:` 丢弃了 delegate
- **状态：** 怪异行为（已记录，未更改）
- **位置：** `MAD/Source/MADDocumentObjectDataReference.m:134-144`
- **行为：** 副本携带 item、page、row 和弱引用的 datasource，但没有
  delegate，因此副本上的 `-fontAttributes` 始终为 nil（它由
  delegate 构建）。注意这里 delegate 是强属性，而 datasource 是弱引用。
- **测试：** `MADDocumentObjectDataReferenceTests
  testCopyCarriesItemAndIndexesButNotTheDelegate`。

### `MADSectionLayoutManager -removeItemWithID:` 对未知 ID 会破坏索引
- **状态：** 已确认（潜在）
- **位置：** `MAD/Source/MADSectionLayoutManager.m:244-263`
- **行为：** 对不在 `items` 中的 ID 的查找返回 nil，`pathToRemvoe` 为 nil，
  而 `[nil indexAtPosition:]` 读出 0——于是“把后面的项下移”的比较对*每一项*都成立，
  每个索引都被减一，索引 0 处的项下溢为
  `NSUIntegerMax`，并且什么都没被删除。管理器留下损坏的索引路径；
  `NSIndexPath` 容忍这个巨大值，因此损坏会在之后才暴露（或在下游
  崩溃），而不是在本次调用中。
- **测试：** `MADSectionLayoutManagerTests
  testRemoveWithAnUnknownIDLeavesEveryIndexDecremented`。

### `MADReportSectionRowsRepresentation` 声明了 `itemCount` 却实现了 `isItemCount`
- **状态：** 已确认（潜在——两个访问器都没有任何代码读取）
- **位置：** `MAD/Source/MADReportSectionRowsRepresentation.h:20`、
  `MAD/Source/MADReportSectionRowsRepresentation.m:50`
- **行为：** 头文件声明 `@property (nonatomic, readonly) NSUInteger itemCount;`。
  实现从未实现该 getter；它实现的是
  `- (NSUInteger)isItemCount`。因此声明的属性针对一个无人写入的 `_itemCount` 实例变量
  自动合成，无论容器里有多少行，`-itemCount` 都返回
  0，而 `-isItemCount` 返回真实计数。
- **为什么重要：** 使用声明 API 的调用者会静默地看到一个空容器。
  目前生产代码不读取这两个选择器（已检查：`itemCount` 只出现在
  声明中），因此缺陷是潜在的。诚实的修复是重命名
  实现，或将属性声明为 `getter=isItemCount`——这是一行改动，留待
  明确决定。
- **测试：** `MADReportSectionRepresentationTests testDeclaredItemCountGetterReadsZero`，
  它断言声明的 getter 读出 0、实现的 getter 读出 2，通过
  测试套件已用于未声明实现选择器的测试专用桥接。

### `RptqQueryTable -isEqualTo:` 把每个非 nil 表都比较为相等
- **状态：** 已确认（潜在——符合 MTProtocolCompare，但没有生产调用者）
- **位置：** `MAD/Source/rptq/RptqQueryTable+Extras.m:97`
- **行为：** 第一个判断是 `if ([sender isEqual:sender]) return YES;`——一个
  恒真式——因此任何非 nil 实参都比较为相等。回退分支不可达；即便到达，
  它比较两个未初始化的 `NSNumber` 局部变量（ARC 下为 nil），
  结果为 `NO`。因此该方法对每个
  非 nil 对都回答“相等”，只有 nil 回答“不相等”。
- **为什么重要：** 任何把查询表当作图节点的代码都会把每个
  表视为同一个节点。目前 `MADQueryFull` 的图包装的是 `NSNumber` 标识符
  （`MADQueryFull.m:176-193`），而 `MTVertex`/`MTEdge` 的相等性基于
  `uniqueIdForStructure`，所以没有代码能到达这个方法——已在 MAD、
  MADDataStructures 和 MADDesigner 中检查。
- **测试：** `MADRptqQueryTests testQueryTableIsEqualToIsDegenerate`。

### `MADReportFormatterCache` 不在任何 target 的 Sources 构建阶段中
- **状态：** 怪异行为（死文件——保持原样）
- **位置：** `MAD/Source/MADReportFormatterCache.m`
- **行为：** 该文件位于 MAD 项目组中，其头文件在 Headers
  阶段，但 `.m` 不出现在任何 `Sources` 构建阶段，因此该类不在任何二进制中。
  代码树中没有任何代码引用它（已检查：唯一的引用是这个测试套件，
  而它无法链接它）。
- **为什么重要：** 它看起来像一个可用的、按尺寸键控的布局缓存，因此读者可能去
  “使用”一个链接时并不存在的类。真正的修复是把它接进框架
  或删除文件；两者都是项目改动，暂缓。
- **测试：** 无法编写——`MADQuerySimpleTypesTests` 记录了该类为何未被
  覆盖。

### `MADQueryCacheIndexCreateTemplate -parameterCount` 无处声明、无处调用
- **状态：** 怪异行为（死代码——保持原样）
- **位置：** `MAD/Source/MADQueryCacheIndexCreateTemplate.m:54`
- **行为：** `-parameterCount`（`_groupCount * 2 + 2`）已实现，但没有头文件
  声明它，代码树中也没有代码调用它。该类自己的 `-getSql:` 模板
  发出同样数量的 `?` 占位符，所以这个计数大概是给语句绑定器用的，
  而绑定器目前必须自己数占位符（或者干脆不数）。
  该类也不在 `MADQuery (Extras)` 工厂的 switch 中——调用者
  直接构造它。
- **为什么重要：** 影响小；这是没有消费者的内部记账。记录下来，以免
  将来编写绑定器时没有注意到已有约定而重新发明它。
- **测试：** `MADQuerySimpleTypesTests testIndexCreateTemplateWithGroupCount` 和
  `testIndexCreateTemplateWithZeroGroupCount`，经由测试专用桥接。

### `MADQueryFull` 把自己的 `error` 输出参数当作输入，并丢弃排序错误
- **状态：** 已确认（潜在——无测试；两条路径都需要应用目前还不会产生的输入）
- **位置：** `MAD/Source/MADQueryFull.m:206`、`:260`
- **行为：** `-SQLOnlyActiveFields:managedObjectContext:error:` 中有三个相关契约被破坏：
  1. `:206` 处的 `if (*error != NULL)` 把调用者的输出参数当作传入值读取。
     传入的 `NSError **` 其指向值非 nil 的调用者（未初始化局部变量留下的垃圾，或复用的变量）
     会进入“条件错误”分支，为完全正常的查询得到空 SQL。拓扑排序自身的错误写入局部
     `sortError` 后从未被读取，因此循环查询——正是该分支存在的唯一理由——被静默忽略，
     生成器继续运行。
  2. 当调用者传入 `NULL` 时，同样的 `*error` 读取会直接崩溃，而本方法
     和 `-copySQLWithManagedObjectContext:error:` 都接受 `NULL`。崩溃发生在
     每次调用时，在构建任何 SQL 之前。
  3. “无活动字段”分支在 `:260` 写入 `*error = ...`（代码 5774）时没有
     检查 `error != NULL`，这是同一参数上的第二处未加守卫的写入。
- **为什么重要：** 调用者用普通的 C 习惯就能触发的契约违反；
  目前还没有造成问题，因为应用总是传入有效的 `NSError **`，并且
  （大概）从不构建循环查询。修复意味着对参数做 NULL 检查，
  并在守卫中读取 `sortError`——这是有意的行为变更，留待
  队列处理。
- **测试：** 非 nil 错误路径由 `MADQueryFullTests
  testNoActiveFieldsReportsError` 锁定（代码 5774，域 `MADQuery`）；NULL 路径和循环
  路径有意不测，因为两者目前都会崩溃或产出垃圾。

### `MADElementStylizedText` 接受了可空的字体名，而 nil 时会崩溃
- **状态：** 已确认（潜在——调用者总是传入字体名）
- **位置：** `MAD/Source/MADElementStylizedText.h:21`、
  `MAD/Source/UIFontDescriptor+MADAdditions.m:21-25`
- **行为：** `-initWithFontName:fontSize:textStyle:horizontalAlignment:` 把 `fontname`
  （及其返回值）标注为可空，却直接把该名称放进字典字面量中的
  `UIFontDescriptorFamilyAttribute`。nil 名称会从
  `+[NSDictionary dictionaryWithObjects:forKeys:count:]` 抛出
  `NSInvalidArgumentException`，而不是返回 nil。
- **为什么重要：** 标注承诺 nil 会被优雅处理；调用者得到的却是崩溃。
  当前每个调用者都传入名称，因此是潜在的。要么改标注，要么改
  nil 处理。
- **测试：** `MADElementStylizedTextTests testNilFontNameThrows` 锁定当前的
  抛出行为。

### `RptqStoreContext -setRelationship:value:onObject:` 在替换或清除关系时不解开旧的逆向目标
- **状态：** 已确认（在实现 macOS Report Designer 时发现）
- **位置：** `MAD/Source/rptq/store/RptqStoreContext.m:324-363`
- **行为：** `-setRelationship:value:onObject:` 中有两处相关遗漏：
  1. 在 to-one 分支（`!relationship.isToMany`，`:324-342`）中，当 `value` 为 `nil`
     （`targetIdentifier == 0`）时，方法清除 `object` 上的正向引用并在 `:328` 提前返回，
     却没有把 `object.identifier` 从先前目标的逆向集合中移除（也没有清除它的逆向
     to-one 引用），也没有把先前目标标记为脏。同样，当 `value` 被替换为新目标
     （`object.inSectionRow = newRow`）时，`object.identifier` 被追加到新
     目标的逆向集合（`newRow.hasObjects`），却没有从
     旧目标的逆向集合（`oldRow.hasObjects`）中移除。
  2. 在 to-many 分支（`relationship.isToMany`，`:344-362`）中，替换集合
     会更新新成员的逆向引用，但从不清除被移出集合的成员的逆向
     引用。
- **为什么重要：** 仅通过 `element.inSectionRow = targetRow` 在 section 之间移动 `RptqDocumentElement`
  （或通过 `element.inSectionRow = nil` 删除它），会让该元素留在旧 `RptqDocumentSectionRows` 的
  `hasObjects` 集合中，导致元素同时出现在两个 section 中（或删除后仍留在
  旧 section 中），直到调用者通过 `-removeHasObjectsObject:` 显式把它从
  `oldRow.hasObjects` 中移除。

### `RptqDocumentSection -addDocumentObject:withDropPoint:managedObjectContext:` 写入 `rect.origin`，却把 `dropPoint` 留在 `(0, 0)`
- **状态：** 怪异行为 / 缺陷（在实现 macOS Report Designer 时发现）
- **位置：** `MAD/Source/rptq/RptqDocumentSection+Extras.m:472-489`、
  `MAD/Source/rptq/RptqDocumentElement+Extras.m:578-596`
- **行为：** 尽管参数名是 `withDropPoint:(CGPoint)origin`，
  `-addDocumentObject:withDropPoint:managedObjectContext:` 调用
  `[documentObject setOriginPoint:origin]`（`:476`），写入 `self.rect.origin.x`
  和 `self.rect.origin.y`（`RptqDocumentElement+Extras.m:593-596`），而让
  `documentObject.dropPoint`（`x`、`y`）保持 `(0, 0)`。与此同时，
  `-[RptqDocumentElement placementPoint]`（`:578-581`）和被注释掉的
  `-[RptqDocumentSection layoutHeightCalculated]`（`:503`）读取的是 `self.dropPoint`。
- **为什么重要：** 任何调用者或检查代码，在用 `-setOriginPoint:` 或
  `-addDocumentObject:withDropPoint:managedObjectContext:` 写入元素坐标的同时读取
  `element.dropPoint`（或 `-placementPoint`），读回的都是 `(0, 0)`，
  从而把元素钉在原点。在 macOS Report Designer 中，`rect.origin` 和
  `dropPoint` 现在保持同步（`MADMacDesignerCanvasView
  -setElement:originInSectionContent:`）。

### `RptqDocumentElementAggregate -updateAggregateFunctionWithFunctionType:…` 在 `RptqDocumentElement` 而非 `RptqQueryField` 中查找 `aggregateObjectID`
- **状态：** 已确认（在实现 macOS Report Designer 时发现）
- **位置：** `MAD/Source/rptq/RptqDocumentElementAggregate+Extras.m:144-162`
- **行为：** 第 144 行用以下代码取 `aggregateObjectID` 的目标：
  ```objc
  RptqObject *object = [storeContext objectForEntity:NSStringFromClass([RptqDocumentElement class])
                                          identifier:aggregateObjectID];
  ```
  然后在 `:155-156`，当 `inputType == MTAggregateFunctionInputTypeField` 时，把
  `object` 强制转换为 `(RptqQueryField *)object` 并赋值给 `self.aggregateField`。
  在可移植存储（`MADStoreSchema.m`）中，`RptqQueryField` 和 `RptqDocumentElement`
  位于不同的表，主键序列各自独立（`1, 2, 3…`）。在
  `RptqDocumentElement` 中查找 `aggregateObjectID`，要么返回 `nil`（没有文档元素
  拥有该标识符，`aggregateField` 保持未绑定），要么返回一个恰好共享同一整数标识符、
  却毫不相干的 `RptqDocumentElement`。
- **为什么重要：** 通过
  `-updateAggregateFunctionWithFunctionType:inputType:groupType:aggregateObjectID:groupNumber:`
  把聚合元素绑定到查询字段，会静默破坏或丢弃 `self.aggregateField`。macOS Report Designer
  直接赋值 `agg.functionType`、`agg.groupType`、`agg.groupNumber` 和 `agg.aggregateField`，
  而不是调用这个辅助方法。

*已归档（已修复；全文、测试及任何提交哈希见 [`BUGS_FIXED.md`](BUGS_FIXED.md)）：*

- `MADDesignerLayout` 的多选撤销用单个标量覆盖每个元素的先前值
- `MADSQLParser` 在 `FROM`、`JOIN` 和三段式列引用中拒绝架构限定的表名（`schema.table`）
- `MADSectionLayout` 以错误的宽度读取 CFNumber，破坏了相邻的实例变量
- `digit_count_*_int`：`INT_MIN` 被折叠成 `INT_MAX`
- `MADSectionGroupLayout` 在字段没有查询表的分组上发生段错误
- `MADReportFormatter` 通过 id 比较无类型值
- 渲染出的货币取决于机器，而不是文档
- `MADQueryActiveQueryFields`：SELECT 列表的顺序是集合顺序，而集合顺序不稳定
- 同一文档在 Linux 和 Apple 上不能产出相同的 `.mad`——而且在 Linux 上根本无法写出
- `objectsForEntity:` 漏掉了每个子实体行
- 打开大型报表并刷新时内存飙升至约 8 GB，却始终渲染不出一页
- 页面绘制为每个单元格运行一次 SQLite 事务，因此打开大型报表会让 CPU 满载
- `insertObjectForEntity:` 按实体而非按表生成标识符
- 里程碑 (a) 的模型重写丢弃了架构排序顺序
- 从源数据库读出的 NULL 打印为文本 `<null>`，或打印为纪元时间
- `MADSectionLayout` 不计算任何元素高度，因此报表会堆积在最初的几页上
- 存储的颜色列没有读取者，模型的颜色属性没有对应列
- `MADocument -managedObjectContext` 以 Core Data 类型返回 `RptqStoreContext`
- `MADReportTextRepresentation` 的 `-characterCount` / `-elementCount` 在非空输入上崩溃
- `RptqDirectionalAsymmetry +keyRight` 返回 `@"left"`
- `MADDatabaseTypeReuseIds`（10）与 `MADDatabaseTypeNames`（9）数量不匹配
- `MADDataTableFast -allObjects` 未实现（FIXME）
- `MADQueryPredicate` 和 `MADQueryCacheSelectGroupKeys` 用双引号引用字符串字面量
- `MADocument -paperSize` 读取的是惰性 `-paper` 访问器构建的 `_paper` 实例变量
- `MTPaper -initWithType:` 对 Legal 和 Government 纸张返回了类对象
- `MADArchiveManager -archive:` 在能够恢复之前就删除了自己的备份
- MADocument 以 nil 内容调用 writeContents:
- UIManagedDocument 的 resetPersistentStore 已声明却从未实现
- MADModelQuery 可能把 nil 表插入其字典
- 安装的访问器块重新读取了弱引用的存储上下文
- MADDataTableFast 从声明为非空的方法返回 nil
- 图像元素无法在保存后存活
- `MADImageThumbnail` 绘制第 1 页，因此单页文档的缩略图是空白的
- `MADPrintPageRenderer` 忽略 `withTransparentBackground:`
- `MADSectionLayoutAttributes +movePlacedItem:` 把孤立的项瞬移到原点
- MAD 的文档测试夹具在多次测试运行之间共享同一个存储

## MADFoundation

### `MADDataTable` 支持 `NSCoding` 但不支持安全编码
- **状态：** 未修复——在 `MADDatabase` 采用 `NSSecureCoding` 时发现
  （2026-10-18）；因改动较大而暂缓。
- **位置：** `MADFoundation/Source/MADDataTable.h:90`（`NSCoding`）、
  `MADFoundation/Source/MADDataTable.m:73-110`（非安全的 `-decodeObjectForKey:`）、
  `MADFoundation/Source/MADDataTableVirtual.m:64-88`、
  `MADSqlite3/Source/MADDataTableFast.m:226-260`。
- **行为：** 基类声明了 `NSCoding`，但它和两个子类都没有实现
  `+supportsSecureCoding`，也没有用类匹配的 API 解码。
  因此 `+[NSKeyedArchiver archivedDataWithRootObject:requiringSecureCoding:YES error:]`
  没有安全编解码器可用，`+[NSKeyedUnarchiver unarchivedObjectOfClass:fromData:error:]`
  会拒绝其结果。表自身的缓存路径（`-cacheWithUrl:error:` /
  `-loadFromCacheWithUrl:error:`）使用属性列表而非键控归档；键控
  编码是 `MADDataTableFast` 重写的那条路径。
- **为什么重要：** 通过 SDK 的安全编码默认值归档数据表的调用者——缓存、文档负载、
  导出——都做不到，只有不安全路径可用。
- **后续：** 按 `MADDatabase` 现在的做法，在基类和两个子类中采用 `NSSecureCoding`，
  并为 `MADDataColumn`、`NSSortDescriptor`、列键和行存储提供解码允许列表。
- **测试：** 尚无；现有的编码测试使用的是宽松的归档器。

### `MADOperation -willEnqueue` 越过 `Pending` 直接推进到 `Ready`
- **状态：** 怪异行为（已记录；不是缺陷）
- **位置：** `MADFoundation/Source/MADOperation.m:163-166`
- **行为：** `-willEnqueue` 设置 `state = Pending`，但由于 `isReady` 是
  `state` 的 KVO 依赖键（见 `+keyPathsForValuesAffectingValueForKey:`），
  `didChangeValueForKey:@"state"` 通知会重新进入 `-isReady`，后者运行
  `-evaluateConditions`，把无依赖的操作直接推进到 `Ready`。该操作在可观察层面
  从不停留在 `Pending`。
- **为何不是缺陷：** `isReady` → `state` 的映射正是 NSOperation 依赖调度所要求的，
  因此不能移除它。`MADOperation.m` 之外没有代码读取 `.state`，这使得被跳过的
  状态转换不可观察。之前的一轮曾称之为缺陷；保留于此，以免下一位读者去
  “修复”该映射、破坏依赖关系。
- **锁定依据：** `MADOperationTests.m` 的 `testWillEnqueueAdvancesPastPendingToReady`
  （注释已更正，记录为有意行为）。

### `MADDataTable` 的缓存方法对抛出的是 NSError 对象，而不是 NSException
- **状态：** 已确认（保持原样——功能没有改变）
- **位置：** `MADFoundation/Source/MADDataTable.m:139`（`-loadFromCacheWithUrl:error:`，
  代码 -213）和 `:201`（`-cacheWithUrl:error:`，代码 -22）
- **行为：** 两处 nil URL 守卫都 `@throw` 了 `NSError` 对象本身。同一方法中的其他
  失败路径返回 `NO`，并通过输出参数传回错误。
- **为什么重要：** `@catch (NSException *)`——本代码库唯一使用的形式——
  捕获不到它，因此传入 nil 的调用者（签名本就禁止：`url`
  是 `nonnull`）会收到一个越过它的无类型对象。与 MADAPI 的连接视图控制器
  的 `@throw NSInternalInconsistencyException;` 形态相同（已于 2026-10-18 修复）。
- **测试：** `MADDataTableBaseTests testCacheWithNilUrlThrowsTheErrorObject` 和
  `testLoadFromCacheWithNilUrlThrowsTheErrorObject`，它们捕获 `id` 并断言
  抛出对象的类、代码和域。
- **已记录（2026-10-18）：** `MADDataTable.h` 中的两个声明现在都带有 `///`
  注释，说明 `url` 是必需的，nil URL 会抛出 `NSError` 对象
  而不会填充 `error`（提交 `e72b1e8df`）。行为不变；约定问题记录在
  本文件末尾。

### `BDHost +addressForHostname:` 在名称无法解析出 IPv4 地址时崩溃
- **状态：** 已确认（潜在——测试环境中没有仅解析到 IPv6 的情形）
- **位置：** `MADFoundation/Source/BDHost.m:27`
- **行为：** 守卫是 `addresses.class > 0 ? addresses[0] : nil`。`[NSArray class]`
  永远不会是 0，因此测试只排除了 nil；对只解析到 IPv6 的名称，
  `+addressesForHostname:` 返回*空*数组（它会过滤掉所有不是
  `AF_INET` 的项），而对空数组取下标 0 会抛出 `NSRangeException`。
- **为什么重要：** 仅支持 IPv6 的主机名——在某些网络上是常态——会让连接界面
  崩溃，而不是报告查找失败。
- **测试：** 无，且是有意的：在离线模拟器中没有任何仅 IPv6 的测试夹具能
  确定性地解析。非空路径由 `BDHostTests
  testLocalhostResolvesToLoopback` 锁定。

### `BDHost +ipAddresses` / `+ethernetAddresses` 是对 `getifaddrs()` 的无检查遍历
- **状态：** 怪异行为（死代码——保持原样）
- **位置：** `MADFoundation/Source/BDHost.m:117`、`:140`
- **行为：** 两者都遍历接口列表并读取 `ifa_addr->sa_family`，却不检查
  `ifa_addr` 是否为 NULL；没有地址的接口会解引用 NULL。这两个方法
  也没有在任何头文件中声明，代码树中无人调用（已在
  所有框架和应用中检查）。
- **为什么重要：** 对合法输入就会崩溃的死代码，最好接好或
  删除；两者都是改动，因此仅记录。
- **测试：** 无——无检查的遍历正是测试套件不调用它们的原因；
  `BDHostTests` 的头文件记录了这一点。

### `MADDataTableVirtual -addRow:error:` 让过短的行使两个视图失步
- **状态：** 怪异行为（隐患——已记录，未更改）
- **位置：** `MADFoundation/Source/MADDataTableVirtual.m:179-195`
- **行为：** 方法按位置遍历传入的数组，数组耗尽时停止。因此，比列列表短的行
  只以提供的键存储行字典，只把这些值追加到列
  对象，却仍然递增行计数器并追加索引。于是行
  视图与列视图描述的是不同的行：对缺失列调用 `-objectAtRow:column:` 会索引一个空的
  `MADDataColumn`，它在 Debug 下触发断言
  （`MADDataColumn.m:170`），在 Release 下越界读取。
- **为什么重要：** 应用中没有代码用短行调用 `-addRow:error:`——
  `-addRowWithDataForFieldKeys:`（驱动使用的路径）会用 `@""` 补齐缺失值——因此这是潜在的。
  但它是那种在驱动第一次写入
  参差行时就会暴露的潜在问题。
- **测试：** `MADDataTableVirtualTests testShortRowLeavesTheColumnViewDesynchronized`
  锁定存储状态；空列读取不做测试，因为它会触发断言。

### `MADDataTableVirtual` 有未声明的实现选择器
- **状态：** 怪异行为（保持原样）
- **位置：** `MADFoundation/Source/MADDataTableVirtual.m`（对照 `MADDataTableVirtual.h`）
- **行为：** `-objectAtIndex:`（`:147`）和 `-sortedIndexForIndex:`（`:124`）
  已实现，但没有在任何头文件中声明；声明的接口只包含
  `-objectAtIndexedSubscript:`。`+keySortIndex` 同样是内部的。
- **为什么重要：** 隐藏 API 很容易被静默破坏；今天这些都没有从类外调用。
  与 `MADFileUtilities` 的未声明辅助方法、
  `MADQueryCacheIndexCreateTemplate -parameterCount` 形态相同，后者记录在本文件的其他
  位置。
- **测试：** `MADDataTableVirtualTests testObjectAtIndexAndSubscriptAgree`，经由
  测试套件已使用的测试专用 category 桥接。

*已归档（已修复；全文、测试及任何提交哈希见 [`BUGS_FIXED.md`](BUGS_FIXED.md)）：*

- `MADURLFactory +newURLForLocalApplicationSupportDirectory` 在没有 bundle identifier 时抛出 `NSInvalidArgumentException`，且 `+groupRootURLForIdentifier:` 在 macOS 上指向 `~/Library/Group Containers`
- `MADDataTable -cacheWithUrl:error:` 在 macOS 上传入 `NSDataWritingFileProtectionCompleteUnlessOpen`，导致无相应权限的缓存写入失败
- `MADKeyChain` 在存在性检查和变更辅助方法中泄漏每个由 `SecItemCopyMatching` 返回的 `CFDataRef`
- MADDataTable 的缓存加载器解引用了空错误指针
- `MADOperationConditionResultTests`：异步路径断言与 dispatch_group 发生竞争
- 框架 target 丢弃了 `$(inherited)`，导致 `DEBUG` 从未进入框架代码

## MADCocoaExtensions

### `CGRectAdjustForScale` 无论缩放方向如何都会收缩
- **状态：** 怪异行为（承重；不要“修复”其中一个分支）
- **位置：** `MADCocoaExtensions/Source/CGGeometry+Extras.h`
- **行为：** 当 `zoomScale > 1` 时乘以 `1/zoomScale`；当
  `zoomScale < 1` 时乘以 `zoomScale`。两条路径都收缩矩形。
- **为何是有意的：** 两个调用者把 `zoomScale` 的定义域分了开来。`MADDesignerScrollView.m:30` 只在
  `zoomScale < 1` 的路径上调用它，而 `:146` 只在 `:142-144` 强制
  `zoomScale >= 1` 之后调用；随后在 `:150` 用
  `CGRectContainsRect` 比较两个结果。因此各自落入对自己情形
  正确的分支，若只改动一个分支而不重做
  两个调用点，就会破坏该测试——这正是上一轮所
  怀疑的。保持原样，头文件中函数上方有注释说明。
- **锁定依据：** `MADGeometryExtrasTests.m` 的 `testAdjustForScale`。

### `newColorWitColors` 把 "With" 拼错了
- **状态：** 怪异行为（暂缓）
- **位置：** `MADCocoaExtensions/Source/MADColor.h`
- **行为：** 公共工厂名为 `newColorWitColors`（缺少
  "h"）。已存在修正后的 `newColorWithColorsAlpha` 变体。
- **为什么重要：** 表面的 API 拼写错误，与 MADAPI 下记录的 `TypeCache` 拼写
  错误一致。暂缓：修复方式是添加别名
  （`+newColorWithColors:` 转发到拼错的方法），这样无需任何调用者
  修改，而这只是为表面收益所做的折腾。

### `MADColorEverydayApps` 的页眉颜色绕过了 8 位到单位值的转换
- **状态：** 已确认（按原样锁定——功能没有改变）
- **位置：** `MADCocoaExtensions/Source/UIColor+EverydayApps.m:30`
  （`-newColorHeaderColor`）和 `:40`（`-blueHeaderSecondaryColor`）
- **行为：** 调色板的其他成员都通过
  `newColorWitColors` / `newColorWithColorsAlpha` 构建颜色，这些方法把 8 位三元组除以
  255。这两个动态颜色的浅色模式分支却用原始 8 位数
  （2、108、182 和 13、158、215）调用 `+[UIColor colorWithRed:green:blue:alpha:]`。该初始化器期望 0-1 的取值；
  分量按原样存储——成为一个扩展范围 sRGB 颜色——因此颜色携带的并不是
  预期的蓝色，绘制时 Core Animation 会把超范围
  分量钳制为白色。
- **为什么重要：** 浅色模式下页眉色调渲染成 20% alpha 的白色
  薄纱，而不是蓝色。`blueHeaderSecondaryColor` 运算相同，
  但 alpha 为 0，所以无论如何都不可见。修复方法是除以 255，
  如同每个同类。
- **测试：** `MADColorEverydayAppsTests testHeaderColorLightModeComponentsAreOutOfRange`
  和 `testBlueHeaderSecondaryLightModeComponentsAreOutOfRange`，它们锁定
  存储的 2/108/182 和 13/158/215 分量；调色板的其他每个成员都按
  单位刻度锁定。

## MADFileManager

### `MADMetaData -initWithURL:` / `-initWithMetadataItem:` 是自我替换的工厂方法
- **状态：** 怪异行为（承重——已记录，未更改）
- **位置：** `MADFileManager/Source/MADMetaData.m`
- **行为：** `-initWithURL:` 从不触碰 `self`；它分配一个新的
  `MADMetaDataLocal` 并返回它。`-initWithMetadataItem:` 同理（返回
  `MADMetaDataCloud`）。调用者最初分配的 `MADMetaData` 被丢弃。
- **为什么重要：** 作为类簇风格的工厂可以工作，但在 ARC 下
  原始的 `self` 泄漏，且 `instancetype` 签名对具体类撒了谎。执行
  `[[MADMetaData alloc] initWithURL:]` 的调用者会得到子类。
- **调用者分析（2026-10-01）：承重——不要阻止替换。**
  每个 `MADMetaData` 生产者都依赖返回具体子类：
  `MADFilesController.m`（`:311,318,325,370,381,396,411,428,439,580`）把
  结果赋给 `MADMetaData *` 并立即使用，而
  `+newMetaDatumForMetadataItems:` 要求 `MADMetaDataCloud`。基类的每个访问器都抛出
  `exceptionNotImplemented`，所以“初始化并返回
  `self`”会破坏所有调用者。真正的缺陷只是 ARC 泄漏和
  类型谎言；修复它们意味着实现一个合适的 `+allocWithZone:` 类簇，并保持
  返回值完全相同。源代码中现在有内联注释记录这一点。

### `MADFileUtilities -removeContentsOfDirectory:` 会删除目录本身
- **状态：** 怪异行为（承重——已记录，未更改）
- **位置：** `MADFileManager/Source/MADFileUtilities.m:656`
- **行为：** 方法逐一移除每个子项，然后也删除目录，
  尽管名字承诺只删除内容。
- **调用者分析（2026-10-01）：承重——不要阻止删除目录。**
  唯一的生产调用者是
  `+removeCachedFileForDocumentUrl:groupIdentifier:`（`.m:645`），它拆除
  文档的整个本地缓存目录；留下一个空目录正是它不想要的。
  错的是方法名，不是其行为。源代码中现在有内联注释记录这一点，
  测试的头注释也指向它。

### `MADFileUtilities` 有若干未声明的准公共辅助方法
- **状态：** 怪异行为（保持原样）
- **位置：** `MADFileManager/Source/MADFileUtilities.m`（对照 `.h`）
- **行为：** `+createDirectoryForUrlIfItDoesNotExist:`、
  `+contentsOfDirectory:withPathExtension:`、`+removeContentsOfDirectory:`、
  `+removeCachedFileForDocumentUrl:` 等已实现，但未在
  公共头文件中声明。测试通过测试专用 category 暴露它们。
- **为什么重要：** 隐藏 API 很容易被静默破坏；这些方法可能本意是私有的也可能是
  公共的，但目前两者都不明确。
- **保持原样（2026-10-01）。** 公开它们会扩大框架的公共
  表面，而没有任何调用者受益；把它们正式设为私有则只是声明位置的
  移动，不改变行为。测试专用 category 是有意为之的桥接，测试文件的头注释也如此
  说明。

### `MADMetaDataLocal` 对本地文件报告 100% 已上传/已下载
- **状态：** 怪异行为（保持原样——当初的影响说法有误）
- **位置：** `MADFileManager/Source/MADMetaDataLocal.m:130`
- **行为：** 对非无处不在（non-ubiquitous）的本地文件，`-ubiquitousItemPercentUploaded` /
  `-ubiquitousItemPercentDownloaded` 返回 `100.0`。
- **为什么重要：** 早先“显示满进度条而不是 N/A”的说法不成立。
  唯一的生产读取者是
  `MADCollectionViewCellDocument.m:387-390`，它为每个百分比配了守卫——
  `isUploading` / `isDownloading`，对本地项都是 `NO`——而
  `+updateProgressView:active:percent:` 在 `active` 为 `NO` 时隐藏视图并把进度归零
  （`.m:60-64`）。该值从不显示。

### `MADFilesController -setFileCoordinator:` 把 URL 当作元数据传递——导致崩溃
- **状态：** 未修复（2026-10-06 由测试发现；尚未修复）
- **位置：** `MADFileManager/Source/MADFilesController.m:193-220`（有问题的
  值在 `:204`，交接在 `:208-212`）
- **行为：** 替换协调器时，被跟踪列表被读作
  `allURLs = [self.fileMetaDatum valueForKey:@"URL"]`——一个 `NSURL` 数组——然后
  被直接当作 `removedMetaDatum:` 传入。`-processContentChangesWithInsertedMetaDatum:removedMetaDatum:updatedMetaDatum:completion:`
  下游的一切都把这个参数当作 `MADMetaData`，而第一件事就是构建
  `[NSPredicate predicateWithFormat:@"URL in %@.URL", …]` 并用它过滤
  （`.m:474-478`）。`NSURL` 没有 `URL` 键，因此谓词抛出
  `NSUnknownKeyException`。
- **为什么重要：** 抛出发生在 delegate 操作队列上，因此
  无人捕获，进程崩溃。只要至少跟踪了一个文件，任何协调器替换都会触发（空列表过滤为空，
  能够存活）。应用的 file-location manager 在
  存储设置改变时会调用 `-setFileCoordinator:`；空列表可能正是至今未观察到该问题的原因。
- **锁定依据：** `MADFilesControllerTests`
  `-testSettingANewCoordinatorStopsTheOldOneAndStartsTheNewOne`，它只能
  覆盖空列表的情形——非空情形会终结测试进程。
  测试的头注释记录了这一点。
- **修复草案：** 先把 URL 映射为 `MADMetaData`
  （`-fileInfosByMappingURLs:` 已存在于 `.m:584`），或让该方法直接接收
  被跟踪的对象。

### `MADLocalFileCoordinator -removeFileAtURL:` 把删除报告为更新
- **状态：** 未修复（2026-10-06 由测试发现；尚未修复）
- **位置：** `MADFileManager/Source/MADLocalFileCoordinator.m:112-119`
- **行为：** 成功分支构建 `removes = @[URL]`，然后调用
  `fileCoordinatorDidUpdateContentsWithInsertedURLs: removedURLs:updates
  updatedURLs:removes`——`removes` 和 `updates` 数组被交换了。delegate 被告知
  文件被*更新*，而 `removedURLs` 保持为空。文件
  无论如何都会被删除。
- **为什么重要：** `MADFilesController` 信任这些分桶：被报告为更新的删除会
  查找仍被跟踪的条目并原地重写它
  （`.m:530-549`），而不是取消跟踪，因此通过协调器删除的文件会留在
  浏览器列表中，直到某次刷新发现文件系统差异。同样的交换调用也存在于
  `MADCloudFileCoordinator -createURLWithName:`（`.m:214-221`），那里两个数组
  都为空，这种颠倒没有实际影响。
- **锁定依据：** `MADLocalFileCoordinatorTests
  -testRemoveReportsTheURLAsUpdatedNotRemoved`。

### `MADLocalFileCoordinator -documentsDirectory` 没有 setter
- **状态：** 未修复（2026-10-06 由测试发现；尚未修复）
- **位置：** `MADFileManager/Source/MADLocalFileCoordinator.m:38`（`@dynamic`）
  对照 `MADFileCoordinatorProtocol.h:18-19`（`readwrite, copy`）
- **行为：** 类把该属性声明为 `@dynamic`，却只实现了
  `-documentsDirectory`（`.m:206-209`）。协议承诺的 setter 从未
  提供，因此调用 `-setDocumentsDirectory:` 会在调用点抛出 `NSInvalidArgumentException`
  （"unrecognized selector"）。
- **为什么重要：** 协议是调用者能看到的唯一契约；持有
  `id <MADFileCoordinatorProtocol>` 的代码有权写入该属性，
  却会崩溃。`MADFilesController` 目前只读取它，应用的
  写入走读取侧的访问器，这就是它尚未暴露的原因。
- **锁定依据：** `MADLocalFileCoordinatorTests -testDocumentsDirectoryHasNoSetter`
  （`-respondsToSelector:` 加上会抛出的调用）。

### `MADFilesController` 接受并忽略 `sortComparator`
- **状态：** 怪异行为（保持原样）
- **位置：** `MADFileManager/Source/MADFilesController.m:154-174`
- **行为：** `-initWithFileCoordinator:delegateQueue:sortComparator:` 从不
  保存或调用该 block。两个类工厂都传入一个文件静态的
  `sortComparator`（`.m:53`），而控制器自己的排序是按 `fileSystemName` 的
  `finderSortWithLocale`（`.m:495-501`）。
- **为什么重要：** 传入比较器的调用者既得不到警告也得不到效果；
  该参数是初始化器签名中的谎言。Finder 排序才是
  浏览器真正想要的，因此这个 block 是累赘而非错误
  结果。
- **锁定依据：** `MADFilesControllerTests -testTheSortComparatorArgumentIsIgnored`
  （一个会保持逆序的比较器毫无区别）。

### `MADFilesController` 用删除回调来把关重命名失败
- **状态：** 未修复（2026-10-06 由测试发现；尚未修复）
- **位置：** `MADFileManager/Source/MADFilesController.m:405-416`
- **行为：** `-fileCoordinatorDidFailRenamingFileAtURL:withError:` 在
  `respondsToSelector:` 检查里放的是 `@selector(filesController:didFailRemovingFileInfo:withError:)`，但发送的却是
  `filesController:didFailRenamingFileInfo:withError:`。只实现重命名回调的
  delegate——自然的选择——永远听不到重命名失败；
  只实现删除回调的 delegate 反而会收到重命名失败。
- **为什么重要：** 对预期的 delegate 形态而言，重命名失败是静默的。
- **锁定依据：** `MADFilesControllerTests
  -testRenamingFailureIsGatedOnTheRemovingCallback`。

### `+[MADFilesController getFileStorageLocationsForUbiquityIdentifier:…]` 把两个 URL 弄反了
- **状态：** 未修复（潜在；2026-10-06 由测试发现）
- **位置：** `MADFileManager/Source/MADFilesController.m:136-137`
- **行为：** completion block 的参数是 `(cloudAvailable,
  documents, data)`，但非云分支返回
  `documents = [MADURLFactory newURLForLocalDataDirectoryForGroupIdentifier:…]`
  （**Data** 目录）和
  `data = [MADURLFactory newURLLocalDocumentsDirectoryForGroupIdentifier:…]`
  （**Documents** 目录）。
- **为什么重要：** 今天之所以是潜在的，只因为唯一调用者——
  `MADFileLocationManager -setupFileStorageLocationsForCloud`
  （`MADExplorer/…/MADFileLocationManager.m:223`）——把两者都声明为 `__unused`。
  第一个信任这些标签的调用者会拿到错误的目录。
- **锁定依据：** `MADFilesControllerTests
  -testStorageLocationsWithoutCloudAnswerLocalDirectories`。

### `MADLocalFileCoordinator` 在最后一个匹配文件消失时丢弃删除通知
- **状态：** 怪异行为（保持原样——该守卫早于测试）
- **位置：** `MADFileManager/Source/MADLocalFileCoordinator.m:251`
- **行为：** `-processChangeToLocalDocumentsDirectory` 用 `if (localListURLs.count > 0)` 包住整个
  插入/删除比较。目录中不再有匹配文件时，完全不发送 delegate 回调——
  连刚刚发生的删除也不发。这种情况下协调器还把
  `currentLocalContents` 留在旧值。
- **为什么重要：** 以这种方式清空文档存储的浏览器什么也收不到；
  下一次有任何文件存在的刷新才会报告这些删除。它是
  上面 `removeFileAtURL:` 交换的镜像：删除是脆弱路径。
- **锁定依据：** `MADLocalFileCoordinatorTests
  -testRefreshIsSilentWhenTheLastMatchingFileIsGone`。

### `MADCloudFileCoordinator -init…` 通过弱引用的 self 写入 `_documentsDirectory`——SIGSEGV
- **状态：** 未修复（2026-10-06 由测试发现；尚未修复）
- **位置：** `MADFileManager/Source/MADCloudFileCoordinator.m:74-79`
- **行为：** 初始化器异步解析 iCloud Documents 目录，并用直接实例变量
  访问赋值：

  ```objc
  MADCloudFileCoordinator __weak *wself = self;
  dispatch_barrier_async(self.documentsDirectoryQueue, ^{
      MADCloudFileCoordinator *sself = wself;
      sself->_documentsDirectory =            // objc_storeStrong(&nil->_documentsDirectory, …)
          [MADFileUtilities newURLForCloudDocumentsDirectoryForUbiquityID: identifier];
  });
  ```

  没有 nil 检查，且该赋值是通过
  `&sself->_documentsDirectory` 的 ARC 存储。
- **为什么重要：** 任何在排队的 barrier block 执行之前被释放的 `MADCloudFileCoordinator`
  都会在该 block 中崩溃：`EXC_BAD_ACCESS (SIGSEGV)
  KERN_INVALID_ADDRESS at 0x10`，位于
  `__80-[MADCloudFileCoordinator initWithPredicate:identifier:firstQueryUpdateHandler:]_block_invoke`。
  构建一个云协调器并让它很快释放——工厂对任何短命调用者正是如此——
  就足够了。协调器通常由 `MADFilesController` 在浏览器生命期内持有，
  这掩盖了问题。
- **修复草案：** `if (sself == nil) return;`，或在 init block 中强捕获 `self`
  （该 block 是一次性赋值；没有循环需要保留）。
- **锁定依据：** 上面的崩溃报告。`MADCloudFileCoordinatorTests`、
  `MADFileCoordinatorTests` 和 `MADFilesControllerTests` 都让每个云协调器保持存活，
  并在释放前排空 `documentsDirectoryQueue`
  （`-tearDown`），这是变通方案，不是修复。

### `MADDirectoryMonitor` 吞掉启动失败，并把多标志事件记录为未跟踪
- **状态：** 怪异行为（保持原样——仅是日志和无操作）
- **位置：** `MADFileManager/Source/MADDirectoryMonitor.m:52`、`:73-96`
- **行为：** (1) 对无法打开的路径（`open(2)` 失败，`.m:52`）调用 `-startMonitoring`
  时，既无 source 也无错误地返回——监视器静默地
  永远不观察任何东西。(2) 事件处理按原始的
  `dispatch_source_get_data` 位掩码做 switch，因此携带多个标志的事件
  （`WRITE|EXTEND`，很常见）落入 `default` 并记录 "Untracked event."
  delegate 仍会被调用。
- **为什么重要：** (1) 是设置错误，看起来会像“浏览器
  不刷新”；(2) 只损失一行误导性的日志。
- **锁定依据：** `MADDirectoryMonitorTests`
  `-testStartMonitoringAMissingDirectoryIsANoOp` 和
  `-testObservesAChangeInTheMonitoredDirectory`。

*已归档（已修复；全文、测试及任何提交哈希见 [`BUGS_FIXED.md`](BUGS_FIXED.md)）：*

- `MADMetaData -fileSystemFileCreationDate` / `-fileSystemContentChangeDate` 返回的是 `NSData` 而不是 `NSDate`
- `MADMetaDataLocal` 的下载状态报告“当前”，但派生的标志却是 NO
- `MADFileInfo -isEqual:` 没有匹配的 `-hash` 重写
- `MADDirectoryMonitor` 的 cancel handler 解引用 nil 属主——dealloc 时 SIGSEGV

## MADExplorer

> MADExplorer 几乎完全是 UI（collection-view 单元格、数据源、视图
> 控制器），逻辑测试 bundle 无法测试。它唯一的非 UI 逻辑
> 是 `MADStandard`，即下面的文件大小格式化器。

### `MADStandard -standardStringForFileSize:` 使用十进制兆字节
- **状态：** 已确认（怪异行为）——**保持原样**（十进制 MB 是本项目
  约定；现有测试对 2^20 字节锁定 `1.049 MB`）
- **位置：** `MADExplorer/MADExplorerTests/MADStandardTests.m`
- **行为：** 刻度是 `1000000.0`（十进制 MB）而不是 `1048576.0`
  （二进制 MiB），因此 `2^20` 字节的文件被报告为 `1.049 MB` 而不是
  `1.000 MB`。
- **为什么重要：** 资源管理器中文件旁显示的数字，不会与
  Finder / `NSFileManager` 报告的二进制兆字节一致。

### `MADStandard -standardStringForFileSize:` 没有字节/kB 回退
- **状态：** 怪异行为——**保持原样**（约 500 字节以下的文件显示 `0.000 MB`，
  由 `testTinyFileReportsZero` 锁定）
- **位置：** `MADExplorer/MADExplorerTests/MADStandardTests.m`
- **行为：** 任何约 500 字节以下的文件都格式化为 `0.000 MB`。
- **为什么重要：** 很小的示例报表/文档在资源管理器中显示 `0.000 MB`，
  而不是字节或千字节数字。

*已归档（已修复；全文、测试及任何提交哈希见 [`BUGS_FIXED.md`](BUGS_FIXED.md)）：*

- 查看器重写之后，文档浏览器缩略图仍然是空白
- `MADStandard -standardStringForFileSize:` 有一处死代码会引发潜在抛出
- `MADStandard` 隐藏了 `+standardStringForDouble:` / `+standardStringForUnsignedLong:`
- `MADOpenDocumentManager -removeDocumentWithUrl:` 移除的是 `self.openUrl` 而不是 `url`
- `MADThumbnailView` 在 `DISPATCH_QUEUE_PRIORITY_BACKGROUND` 加载缩略图，并阻塞在 `dispatch_sync(dispatch_get_main_queue(), …)`

## MADSqlite3

`MADDatabaseSqlite3` 中的 `MADDataTypeUnknown → String`/`TEXT` 强制转换
是有意的回退，并由测试覆盖。本框架中的一个缺陷是通过代码审查而非
测试发现的，记录在“已修复（供参考）”下：八处调用点把变量当作
格式字符串传给 `sqlite3_mprintf`。下面的前两个是在编写证明驱动已与
`MADDataTable` 解耦的写端口测试时发现的；第三个由摄取基准
发现，而该基准也是衡量它的手段。第四个是在为 CLI 工作
清点静态库构建时发现的，也是这里唯一改动应用所写文件的
条目。第五个让应用崩溃，是从崩溃日志中发现的；它是这里唯一属于崩溃而非错误
答案的条目。

### `MADDatabaseSqlite3 +databaseResultValueCast:…` 释放了 sqlite 自己的文本指针
- **状态：** 已确认（潜在——代码树中无调用者）
- **位置：** `MADSqlite3/Source/MADDatabaseSqlite3.m:1288` 和 `:1313`
  （对 `sqlite3_column_text` 返回的指针执行 `free((char *)text)`）
- **行为：** sqlite3 返回的指针属于语句，仅在下一步/重置/终结之前有效；
  释放它会破坏分配器（以及 sqlite 自己的缓冲区记账），而不会做任何
  有益的事。无类型的同类 `+databaseResultValue:columnNumber:`——热路径——不释放。
- **为什么重要：** 该方法是公共的，但目前没有调用者，因此是潜在的；
  第一个通过它读取文本列的调用者会遭遇堆损坏。
- **测试：** 文本系列分支没有测试，且是有意的：失败模式是内存
  损坏。`MADDatabaseSqlite3ResultValueTests` 覆盖数值、blob 和
  null/unknown 分支，这些是安全的。

### `MADDatabaseResultValue` 是 MADDatabaseSqlite3 工厂的死的近似副本
- **状态：** 怪异行为（死代码——保持原样）
- **位置：** `MADSqlite3/Source/MADDatabaseResultValue.m`（不在任何 target 的 Sources
  阶段），对照 `MADDatabaseSqlite3.m:1206-1319`
- **行为：** 该文件实现了与现役 MADDatabaseSqlite3 类方法相同的两个结果值工厂
  （只是少了那个多余的 `free`），但它不在任何 target 中，因此
  该类不在任何二进制里——导入其头文件的测试会在链接时失败，
  报 "Undefined symbol: _OBJC_CLASS_$_MADDatabaseResultValue"（已核实）。它的
  `-copyWithZone:` 还无条件抛出，而头文件却宣称
  `<NSCopying>`。
- **为什么重要：** 读者可能挑中这个死文件去修复结果
  读取，然后眼看着修复永远无法链接；两个副本已经开始漂移（那个
  `free`）。真正的修复是删掉一个、保留另一个。
- **测试：** 无法编写——该类未被链接。`MADDatabaseSqlite3ResultValueTests`
  覆盖现役副本。

### `MADArrayCachingEnumerator` 不在任何 target 中
- **状态：** 怪异行为（死文件——保持原样）
- **位置：** `MADSqlite3/Source/MADArrayCachingEnumerator.m`（不在任何 Sources 阶段；头文件
  自己就这么说）
- **行为：** 头文件在项目中，声明了一个基于缓存 URL 的 `NSEnumerator`；实现
  没有在任何地方编译，因此该类不在任何二进制里，也
  无法链接。头文件的注释称它尚未完成，并要求调查。
- **测试：** 无法编写——与 `MADDatabaseResultValue` 一样，该类在链接时
  不存在。已用 `MADArrayCachingEnumerator.m in Sources` == 0 核实。

*已归档（已修复；全文、测试及任何提交哈希见 [`BUGS_FIXED.md`](BUGS_FIXED.md)）：*

- `MADDatabaseSqlite3` 在零行 `SELECT` 上无条件调用 `-endBulkInsert`，抛出 `cannot commit - no transaction is active`
- `MADArrayCaching` 可能从空标识符构建缓存 URL
- `MADDataTableFast` 把可能为 nil 的值传入会抛出的路径
- `MADQueryCacheAddRow` 用 `strcat` 构建占位符列表
- `fieldsForTable:` 运行了表查询并把表作为字段返回
- `connectWithConnection:credentals:connectionError:` 在连接成功后返回 nil
- `MADDataTableFast` 存储了绝对缓存 URL，容器变化会使其失效
- `MADDataTableFast` 在内存中删除或 drop 之后让行计数器过期
- `MADDataTableFast -deleteAll` 用错误的初始化器构建查询
- 缓存的 `ORDER BY` 忽略列类型，因此文本键按二进制排序
- 批量插入行循环把整个结果集保存在自动释放内存中
- SQLite 引擎只按构建脚本声明的二十个选项之一编译
- `MADArrayCaching -isEmpty` 和 `-count` 对空缓存返回错误结果
- `MADDataTableFast` 的读取事务在没有 selects 数据库时崩溃
- `MADDataTableFast -whereClauseForGroupKeys:` 索引越过排序描述符

## MADBarcodes

*已归档（已修复；全文、测试及任何提交哈希见 [`BUGS_FIXED.md`](BUGS_FIXED.md)）：*

- `MADBarcode -drawInRect:` 在 `self.center` 为 `YES` 时重复计算 `rect.origin`
- MADBarcode 的类型名字典有重复键
- 两个符号学类用另一个类的类型初始化
- `MADBarcodeInternationalStandardBookNumberIsbn +type` 调用自身
- `MADBarcode` 的 NSCoding 往返丢失一切
- `MADBarcode -drawInRect:` 未经检查地把用户输入复制到 `primary[128]`

### `MADBarcodeView` 是框架中唯一手动 retain/release 的文件
- **状态：** 怪异行为（保持原样）
- **位置：** `MADBarcodes/MADBarcodes/MADBarcodes/MADBarcodeView.m`（用
  `-fno-objc-arc` 编译）、`MADBarcodeViewTests`
- **行为：** 项目是 ARC 的，但这个文件保留了一个 `-dealloc`，释放
  `_barcode` 并调用 `[super dealloc]`，所以它必须保持 `-fno-objc-arc`。它的
  `-initWithFrame:` 断言 "Don't you dare!"，而 `UIView -init` 会转发到那里，因此该
  视图只能从 storyboard（`-initWithCoder:`）构建；逻辑测试无法
  构建它，这就是 `MADBarcodeViewTests` 锁定构造器契约和
  属性声明的存储、而不是行为的原因。
- **测试：** `MADBarcodeViewTests testProgrammaticConstructionIsRefused` 和
  `testBarcodePropertyIsAnInstanceOfMADBarcode`。

## MADMySQL

由离线套件（`MADMySQLTests.m`）加一个实机套件
（`MADMySQLLiveTests.m`）覆盖，后者针对
`DEVELOPER.md` 中的开发实例运行。实机套件是到达 `MADMySQLConnection`、
`MADMySQLFetch` 和 `MADMySQLFetch+DataTable` 的唯一途径——它们是对
libmysqlclient 的薄封装；没有服务器可达时它会跳过而不是失败。

### `MADDatabaseMySQL -closeConnection:` 和 `MADMySQLConnection -dealloc` 都对句柄调用 `mysql_close`
- **状态：** 已确认（潜在——closeConnection 路径是从架构创建文档的导入流程）
- **位置：** `MADMySQL/Source/MADDatabaseMySQL.m:397-403` 和 `MADMySQL/Source/MADMySQLConnection.m:79-85`
- **行为：** `-closeConnection:` 对连接的句柄调用 `mysql_close`，而连接的
  自己的 `-dealloc` 在对象消亡时又对同一句柄调用 `mysql_close`。句柄的
  存储由连接 calloc 分配且 `free_me` 为 false，因此两次调用都不释放
  该结构体——但每次调用都会释放会话的内部缓冲区，所以
  第二次是双重释放。
- **为什么重要：** 只是潜在的。其他所有路径都在不经过
  `-closeConnection:` 的情况下丢弃连接，因此 `-dealloc` 中的单次关闭是常见情形；导入
  路径（`MADOperationCreateDocumentImportSchema.m:246,293`）是唯一先关闭再释放的调用者。
  在连接器重写期间记录，以免下一位读者
  把这种安排误认为经过检查。
- **测试：** 无——该路径需要应用和实机服务器。

### `MADMySQLInsert -execute` 对忽略的重复项报告 `ULONG_MAX` 行
- **状态：** 怪异行为（保持原样）
- **位置：** `MADMySQL/Source/MADMySQLInsert.m:110-126`
- **行为：** 设置了 `ignoreDuplicateErrors` 时，失败的 `mysql_stmt_execute` 被
  吞掉，代码直接继续读取 `mysql_affected_rows`，而它对未运行的
  语句返回 `(my_ulonglong)-1`。因此 `affectedRows` 返回
  18446744073709551615 而不是 0。
- **为什么重要：** 该标志是为了让插入可以“发射后不管”；记录或累加
  `affectedRows` 的调用者会加进一个比宇宙行数还大的数字。
  代码树中没有调用者在忽略重复项之后读取它。
- **测试：** `MADMySQLLiveTests testInsertRejectsADuplicateKeyUnlessToldToIgnoreIt`
  精确断言该值，因此将来若修复为 0，测试会失败而不是静默
  通过。

### `MADMySQLTruncate` 的工厂跳过了其他 DML 类所做的 nil 连接检查
- **状态：** 怪异行为（保持原样）
- **位置：** `MADMySQL/Source/MADMySQLTruncate.m:30-40` 对照 `MADMySQLInsert.m:44-50`、
  `MADMySQLUpdate.m:43-50`、`MADMySQLDelete.m:28-34`
- **行为：** `MADMySQLInsert`、`MADMySQLUpdate` 和 `MADMySQLDelete` 在收到 nil 连接时
  都会从工厂抛出 `MADMySQLException`；两个 truncate
  工厂不这样做，而是返回一个最终在 `-execute` 失败的对象。
- **为什么重要：** 检查是否抛出的调用者（或依赖工厂拒绝的调用者）得到的是一个
  对象，而不是诊断信息。今天无害——代码树中没有传入 nil 的代码——
  但这四个类应当行为一致。
- **测试：** `MADMySQLTruncateTests testFactoryAcceptsANilConnection`。

*已归档（已修复；全文、测试及任何提交哈希见 [`BUGS_FIXED.md`](BUGS_FIXED.md)）：*

- `MADMySQLConnection` 的事务开关在没有句柄的连接上崩溃
- `MADMySQLConnection +connectToServer:error:` 通过 NULL 错误指针写入
- `MADMySQLFetch+DataTable` 在 default 分支读取未初始化的 `MYSQL_BIND`
- `MADMySQLFetch+DataTable`：非 SELECT 语句永远无法执行
- `MADMySQLFetch+DataTable`：抓取出错时行循环无限空转
- `MADMySQLFetch+DataTable`：`MYSQL_TYPE_INT24`（MEDIUMINT）把 4 字节当作 8 字节读取
- `MADMySQLFetch+DataTable`：绑定和执行失败从未被报告
- `MADMySQLFetch+DataTable`：`MYSQL_TYPE_NULL` 让其输出参数未初始化
- `MADMySQLFetch+DataTable`：错误路径上绑定和语句泄漏
- `MADMySQLFetch`：`mySQLTypeForType` 对三种类型返回错误名称
- `MADDataTypeMySQL` 的映射对三种类型有损
- `MADMySQLFetch+DataTable` 的注释声称不支持 SMALLINT/MEDIUMINT/BIT
- 抓取操作根据第一行修正了列的类型
- MySQL 字面量中的反斜杠是转义字符，因此仅靠 ANSI 引号是错误的
- `MADMySQLUpdate -execute` 抛出越界字符串异常，而不是它自己的错误

## MADTds

### MADTds 原样发布 FreeTDS 的头文件，因此保留了一处引号 include
- **状态：** 非我方问题——该头文件是第三方的；记录而不更改。
- **问题：** `sybdb.h` 由 `Compressor/library/freetds/include/` 提供，用双引号
  include 引入 `tds_sysdep_public.h`（`:31`），
  `-Wquoted-include-in-framework-header` 会报告这一点，因为 MADTds 将该头文件作为
  其公共模块的一部分重新发布。在警告清理中，所有第一方公共头文件
  都改成了尖括号 include；这一个被保留，因为文件是
  FreeTDS 的，而 `THIRD_PARTY_LICENSES.md` 已经记录所发布的副本经过
  修改——这本身就负有 LGPL 声明义务。
- **若将来要处理：** 给 Compressor 配方为框架安装的那份副本
  打补丁，不动构建副本。那是许可证声明变更，不是
  警告修复。
- **位置：** `Compressor/library/freetds/include/sybdb.h:31`。

### MADTds 的构建带有一条未沙盒化脚本的提示
- **状态：** 有意为之——已记录；不破坏 Compressor 就无法修复。
- **问题：** Xcode 警告 "tasks in 'Copy Headers' are delayed by unsandboxed script
  phases; set ENABLE_USER_SCRIPT_SANDBOXING=YES"。每个带有 Compressor
  "Ensure Libraries" 阶段的项目都会带有它。沙盒被有意关闭：该阶段运行
  `Compressor/build.sh`，它会写入 `Compressor/library/`，在任何脚本
  沙盒之外。
- **备注：** 配套警告——"will be run during every build because it does not
  specify any outputs"——已通过把这些阶段标记为 `alwaysOutOfDate` 清除。
  该脚本是清单检查，本意就是每次构建都运行，且当库是最新时
  跳过重建，因此这是记录意图而非改变意图。
- **位置：** 带有该阶段的六个项目：MAD、MADBarcodes、MADMySQL、MADSqlite3、
  MADTds、MAD Designer。

### `MADTdsDb` 泄漏登录记录，并可能在 NULL 进程上执行
- **状态：** 未修复——在 2026-10-17 的警告清理中通过代码审查发现；记录，未
  更改。
- **位置：** `MADTds/MADTds/MADTdsDb.m:79`（`dblogin()`）、`:94-105`（`dbopen`/`dbuse`
  失败路径）和 `:111-151`（`-executeQuery:`）。
- **行为：** `:79` 返回的 `LOGINREC *login` 从未传给 `dbloginfree()`，
  `dbopen` 失败时没有，`dbuse` 失败时没有，成功连接之后也没有。另外，
  `-executeQuery:` 把 `self.dbProcess` 交给 `dbcmd`、`dbsqlexec`、
  `dbresults` 和行访问器时不检查是否为 NULL，而 `-connect` 可能让它保持
  NULL。
- **为什么重要：** 每次连接尝试都会泄漏一条登录记录。在成功 `-connect` 之前，
  或某次连接失败之后发出的查询，会在 freetds 内部解引用 NULL，而不是
  干净地失败。
- **测试：** 无——MADTds 不提供测试 target；它通过 `MADTdsClient` 接受测试。
  两条路径都需要驱动级测试才能修复。

## MADTdsClient

由离线套件（`MADTdsClientTests.m`，47 个测试）加一个实机套件
（`MADTdsClientLiveTests.m`，29 个测试）覆盖，后者针对 `DEVELOPER.md` 中的本地
SQL Server 2022 实例（`127.0.0.1`、`sa`、`AdventureWorksLT2022`）运行。实机
套件是到达 `-connect:andPassword:error:`、
`-getTablesFromConnection:error:`、`-fieldsForTable:connection:error:` 和
`-runSQL:onDataTable:fieldKeys:process:error:` 的唯一途径——它们是对 freetds 的薄封装；
没有服务器可达时它会跳过而不是失败。

### `-runSQL:onDataTable:fieldKeys:process:error:` 关闭了传给它的连接
- **状态：** 怪异行为（承重——已记录，未更改）
- **位置：** `MADTdsClient/Source/MADDatabaseSQLServer.m:1648`
- **行为：** `dbclose(dbconn)` 在每条退出路径上都运行，包括成功
  路径，作用于调用者打开的 `DBPROCESS`。读取路径
  （`-getTablesFromConnection:error:`、`-fieldsForTable:connection:error:`）的
  `dbclose` 调用被注释掉了；这一个没有。
- **为什么重要：** 两个后果，都是致命的：
  - 关闭自己打开的连接的调用者会在 freetds 内部双重释放。
    实机套件在绕过问题之前复现了它——
    `dbstring_free → dbclose → -[MADDatabaseSQLServer closeConnection:]`、
    `SIGSEGV`。`-executeQuery:withDataTable:andError:` 根本不关闭自己的
    连接，因此是泄漏而不是崩溃；`-getTables:` 会关闭，因此会崩溃。
  - 每个连接只能运行一条语句，这违背了
    `-runSQL:` 的契约，并使 `-getTables:` 自己第 291 行的 `dbclose`
    （在那里是合法的，因为该方法打开自己的连接）显得反常。
  - 由 `testEachStatementNeedsItsOwnConnection` 锁定，它固定了缺陷所强制的
    每连接一条语句模式。
- **调用者分析（2026-10-01）：承重——不要移除 `dbclose`。**
  每个调用者都假定 `-runSQL:` 会消费交给它的 process：
  `MADOperationRefresh.m:80-122` 和
  `-executeQuery:withDataTable:andError:` 各打开一个 process、运行一条
  语句，自己从不关闭。以“双重释放”为由删除 `dbclose`，反而会每个查询
  泄漏一个 `DBPROCESS`。契约难看，但每个调用者对它都是正确的。调用点现在有
  内联注释记录这一点；若要改变，必须先给这些调用者
  明确的属主关系和自己关闭的能力。

### `SYBDATETIME4` 从错误的纪元起算天数
- **状态：** 仍未修复——记录，未修复
- **位置：** `MADTdsClient/Source/MADDatabaseSQLServer.m:432`
  （`janFirst1990Components`，在 `:1295` 处读取）
- **行为：** 变量以 1990 命名，其分量却是 1900-01-00，但 `DBDATETIME4.days`
  从 **1900-01-01** 起算，因此第 0 天也必须取
  1900-01-01。把基准构造成 1900-01-**00**（即 1899-12-31），会让
  每个 `SMALLDATETIME` 都早一天。
- **为什么重要：** `SMALLDATETIME` 列会差一天。
- **为何此处不修复：** 它与已破解记录的情形走的是不同的算术路径，
  而且尚未对服务器验证过，因此
  这个差一是从代码读出来的，而非观察到的。它需要先有自己的
  实机测试——形态与
  `testSelectClassicDateTimeKeepsItsMonth` 相同——然后才能修改基准日期。

### `-sqlSampleDataForField:andTable:` 绕过了基类的子句构建器
- **状态：** 怪异行为（承重——已记录，未更改）
- **位置：** `MADTdsClient/Source/MADDatabaseSQLServer.m:1680`
- **行为：** 重写方法硬编码 `SELECT DISTINCT TOP 511 ...`，而不是
  像基类那样组合 `-selectPart` / `-selectPartWithLimitedResults:` 并调用
  `-sqlAggregateFunctionLength`。它能工作，正是 SQL Server 示例数据不会发出
  基类那条无效 `LIMIT 511;` 的原因，但两条路径将会漂移。
- **为什么重要：** 今天没有坏掉；记录于此，以免把这份重复
  误认为基类实现。
- **调用者分析（2026-10-01）：承重——不要“去重”。** `MADAPI/Source/MADDatabase.m` 中的
  基类实现把 `LIMIT 511;` 硬编码进格式字符串，从不
  经过 `-sqlLimitClause`，因此 SQL Server 的空 limit 子句无法抵消它。
  组合基类实现会发出无效的 T-SQL。源代码中现在有内联注释记录
  这一点。

*已归档（已修复；全文、测试及任何提交哈希见 [`BUGS_FIXED.md`](BUGS_FIXED.md)）：*

- dbdatecrack 在 microsoft 的 DBDATEREC 名称下被传入 sybase 的 DBDATETIME
- `-runSQL:...`、`-runQuery:...` 和 `-executeSQL:...withError:` 丢弃了它们的 SQL 错误
- `-getTables:` 把 process 包装器当作 `DBPROCESS` 传给 freetds
- 每个 `DECIMAL` / `NUMERIC` 值都会丢失或损坏
- `-fieldsForTable:connection:error:` 把 sybdb 类型代码送入 SQL Server 类型 id 的表中
- `+dataTypeForNativeType:` 对若干现役 SQL Server 类型没有分支
- 每个 SQL `DATETIME` 读回时晚一个月
- `-connectWithConnection:credentals:connectionError:` 从不报告其错误
- `-connect:andPassword:error:` 解引用 `*error` 时没有 NULL 检查
- `-fieldsForTable:connection:error:` 有会解引用已知 NULL 指针的死错误处理
- `port` 从未传给 freetds
- `+newSafeQueryField:andTable:` 不拆分架构限定的表
- `-executeQuery:withDataTable:andError:` 丢弃其错误
- REAL 和 FLTN 结果值在转为 NSNumber 之前被收窄为 float

## MAD Designer（应用）

由宿主的 `MADDesignerUnitTests` bundle 覆盖（96 个测试，分布在
`MADDesignerUnitTests.m`、`MADAppLogicTests.m`、
`MADAppOperationConditionTests.m`、`MADOperationValidateSQLTests.m` 和
`MADStatusLabelRefreshTests.m` 中）。该 bundle
由 `MAD Designer.app` 宿主（TEST_HOST/BUNDLE_LOADER），因此通过正在运行的可执行文件
到达应用自身的源码；应用的类在测试文件中就地声明而非导入，因为
`MADDesigner/Source` 不在该 bundle 的头文件搜索路径上。

- 编译后的模型无法通过 Core Data 的推断迁移（重命名标识符冲突）

### 值选择器把 `NULL` 当作一个值提供，而它不是 SQL NULL
- **状态：** 仍未修复
- **位置：** `MADDesigner/Source/MADQueryValueFromFieldController.m:269-270`
  （`-pickerView:titleForRow:forComponent:`）和 `:283-284`
  （`-pickerView:didSelectRow:inComponent:`）
- **行为：** 当采样行的值对象为 nil 时，选择器把该行标为
  `@"NULL"`。随后 `-didSelectRow:` 把该标签原样复制到文本字段，而
  字段内容就成为谓词的右侧值。由此
  `MADQueryPredicate` 会给非数值加引号——因此 SQL 读作 `= 'NULL'`，一个只匹配这四个
  字符的文本字面量——而对数值则裸发 `= NULL`，那是 SQL NULL，匹配不到任何
  行。两者都不是 `IS NULL`，而标签对用户暗示的正是 `IS NULL`。
- **为何不是一行修复：** 运算符集合中没有 `IS NULL`，因此
  “无值”的情形无处可去。正确做法需要同时改比较
  符号枚举、`MADQueryPredicate` 和谓词录入 UI，而且这是一个
  产品决策——空值应当意味着什么——而不是要打补丁的缺陷。
- **该分支还针对错了对象：** 它测试 `resultObject == nil`，但从数据表读出的
  字典不可能为某个值持有 nil；它持有的是 `NSNull`。
  因此真正的 NULL 会越过这个分支落到最后的 `else`，显示为
  空行，也就是说，标签根本触及不到它为之编写的情形。
- **未修复：** 已为 ROADMAP Track 1.5 审计过并保持原样。这里的字符串
  代表一个 NULL，这正是该项所讨论的，但它是选择器的显示文本，
  会被选择处理程序复制进值字段——改变它会改变用户看到的内容和键入的内容，
  而今天两者都没有覆盖。

### `+[MADDateFromTimeFormatter timeIntervalForResolution:]` 对一毫秒返回 0.1 秒
- **状态：** 已调查——保持原样
- **位置：** `MADDesigner/Source/NSDate+Extras.m:250`
- **行为：** `MTDateResolutionMillisecond` 分支返回 `0.1`。一毫秒
  是千分之一秒（`0.001`），因此该值大了 100 倍。`MADViewerController.m:870` 的调用者把它直接交给
  `+[NSTimer scheduledTimerWithTimeInterval:]`，因此以“毫秒”分辨率设防的
  查看器刷新会以 10 Hz 而非 1000 Hz 运行。
- **已调查（2026-10-01）：保持原样。** 调用者是一个一次性定时器，其
  处理程序会重新设防自身（`-updateTimeSinceLastRefresh:`），因此 0.1 秒把
  状态标签的重渲染节流到每秒十次。把值“修正”为 0.001
  会让它每秒重新设防一千次，每次都要重建一个拼写出来的
  经过时间字符串。这个常量是读起来像分辨率的 UI 刷新节流；
  错的是名字，不是值。

### `+[MADDateFromTimeFormatter timeIntervalForResolution:]` 没有年、月或周的分支
- **状态：** 已调查——保持原样
- **位置：** `MADDesigner/Source/NSDate+Extras.m:253`
- **行为：** switch 只覆盖 Day、Hour、Minute、Second 和 Millisecond。
  Year、Month 和 Week 落入 `default:` 并返回 `86400.0`——一天
  ——因此请求年分辨率的调用者会得到每天触发的定时器。
  `-stringWithTimeIntervalSinceDate:` *确实*会报告 `MTDateResolutionYear`、
  `MTDateResolutionMonth` 和 `MTDateResolutionWeek`，因此该类的两半
  对存在哪些分辨率意见不一。
- **已调查（2026-10-01）：保持原样。** 一个月不是固定的秒数，因此
  这个方法能诚实回答的分辨率，只剩它本来也没有合理常量的那两个；
  这里落到每天正是查看器实际想要的，
  因为它驱动的标签最细也只拼出
  “一天前”。测试锁定了这个落空，以免后来的读者靠猜测
  把它“修正”为 2629746 或 604800。

### `MADFeature -initWithDictionary:` 在缺少 "type" 键时给出类型 0
- **状态：** 部分修复
- **位置：** `MADDesigner/Source/MADFeature.m:59`
- **行为：** 每个键都通过下标读取并强制转换为 `NSNumber`——
  `((NSNumber *)dictionary[@"type"]).shortValue`。缺失或非数值的条目
  读作 `nil`，向 `nil` 发消息得到 0。0 不是两个已声明的
  `MADFeatureType` 值之一（`NonConsumable` = 1，`Subscription` = 2），因此 plist 的笔误
  会产生一个两者都不是的功能，而不是错误。该方法已被指定初始化器取代
  并标记为废弃，因此实践中可能无实际意义。
- **现状：** 数值条目现在在发送 `-shortValue` 之前用 `isKindOfClass:` 检查形态，
  因此形态错误的值（"type" 是字符串）读作 0 而不崩溃。零类型
  行为本身按上面“已由指定初始化器取代”的说明保持不动；它现在
  在调用点有注释记录。
- **测试：** `testFeatureFromDictionaryWithWrongShapedValuesDoesNotCrash`，以及现有的
  `testFeatureFromIncompleteDictionaryYieldsZeroedType`，后者把
  零类型锁定为有意行为。

### 收据校验使用已废弃的 SHA-1 验证 API，并在失败时泄漏密钥
- **状态：** 未修复——由警告清理发现，记录而不更改。
- **问题：** `MADDesigner/Source/MADVerificationController.m` 使用 `SecTrustCopyPublicKey`
  （`:482`，在 iOS 14 中废弃）和带 `kSecPaddingPKCS1SHA1` 的 `SecKeyRawVerify`（`:484`，在 iOS 15 中废弃）
  校验 App Store 收据，作用于收据的 SHA-1 摘要（`CC_SHA1_*`，`:475-480`）。另外，
  分析器的 `osx.cocoa.RetainCount` 检查报告 `receipt_signing_key`（`:482`）在失败路径上泄漏：
  `__Require` 宏直接跳到 `outLabel`，而 `:489` 处的 `CFRelease`
  只有在验证成功时才会到达。
- **为何此处不改：** 把 `SecKeyRawVerify`/PKCS1SHA1 换成带
  `kSecKeyAlgorithmRSASignatureMessagePKCS1v15SHA256` 的 `SecKeyVerifySignature`，
  会改变应用接受哪些签名——这是安全决策，不是警告修复。
  相比之下泄漏是机械性的：删掉 `:489` 处的 `CFRelease`（成功路径
  会落到 `outLabel`），改在那里释放。
- **位置：** `MADDesigner/Source/MADVerificationController.m:475-489`。
- **复现：** 对应用 scheme 的每次
  `xcodebuild analyze`，分析器都会报告废弃和泄漏两项。

### `MADToolboxStyleViewController -updateDisplay` 在多选时错算不同的盒模型和字号值
- **状态：** 已确认（在 macOS Report Designer 审计中发现）
- **位置：** `MADDesigner/Source/MADToolboxStyleViewController.m:460-614`
- **行为：** 在遍历 `self.userSelectedObjectIDs` 之前，`borderHolder`、
  `marginHolder`、`paddingHolder` 和 `sizeHolder` 被零初始化（`{0, 0, 0, 0}`
  和 `0.0`），而每个计数器（`numberOfBorderTop`、`numberOfMarginLeft`、
  `numberOfPaddingTop`、`numberOfFontSize` 等）只在
  `documentObject.<prop> != holder.<prop>` 时递增。后果：
  1. 当单个元素（或多个元素）的属性等于 `0`（例如
     `border.width.top == 0`，新元素的默认值）时，`documentObject.border.width.top != borderHolder.top`
     为 `NO`，因此 `numberOfBorderTop` 保持 `0` 而不是 `1`。
  2. 当第一个选中元素的值非零（例如 `2.0`，计数器递增到
     `1` 并设置 `holder = 2.0`），第二个选中元素为 `0.0` 时计数器递增到 `2` 并设置 `holder = 0.0`，
     第三个选中元素为 `2.0` 时计数器递增到 `3`，尽管只存在两个不同的值；
     反过来，如果第一个元素是 `0.0`、第二个是 `2.0`，计数器为 `1` 而不是 `2`
     （未能检测出混合选择）。
- **为什么重要：** iOS 样式检查器中的多元素选择，只要任一选中元素在某条边上为 `0`，
  就会错误地报告选中元素是否共享统一的边框、外边距或内边距
  值。

*已归档（已修复；全文、测试及任何提交哈希见 [`BUGS_FIXED.md`](BUGS_FIXED.md)）：*

- 条码 delegate 的查询字段访问器与其声明不一致
- AppDelegate 的重试 block 捕获了自身
- 一处断言用 %@ 格式化整数
- `MADToolboxFormatViewController` 的多选小数位数检查从未求值为 `YES`
- MADToolboxStyleViewController 把未初始化的值传给 setter
- 应用把可能为 nil 的值传给非空参数
- `MADFontSelectorViewController -setFamilyName:` 递归调用自身
- Viewer 工具栏中的 Refresh / Formatting / Page 状态标签在 Liquid Glass 上不可读
- `MADTabBarController` 在每次 `-viewWillAppear:` 时重建全部三个 tab 视图控制器
- `MADDesignerViewController`：编辑动态标签的字段时按字段 ID 查找标签，并把 popover 锚定在 `CGRectZero`
- `MADDesignerViewController -sectionForLabelTag:` 和 `-documentSectionViewWithIdentifier:` 查找了错误的 section
- `MADViewerController -showPrintDialog` 颠倒了队列优先级，且 `MADOperationLoadPrintPageRender -main` 读取了未初始化的 `MADocument *` 指针
- 未选中的 tab bar 图标对白色 PNG 描边强制 `UIImageRenderingModeAlwaysOriginal`，使其在浅色模式以及 Liquid Glass 的白色表面上不可见
- `MADNavigationControllerViewer` 和 `MADNavigationControllerQueryBuilder` 的底部工具栏在 iOS 26 上与浮动 `UITabBar` 重叠，并挤压 `MADLabelStatus`
- `MAD Viewer` 启动黑屏，原因是缺少 `UIScene` 生命周期清单、应用源码未被编译、storyboard 和示例资源未打包
- `MADNavigationController +documentNavigationControllerWithType:document:` 在 `MAD Viewer` 中为 `MADNavigationControllerTypeViewer` 抛出 `NSInternalInconsistencyException`
- `MADViewerController` 把刷新按钮、完成按钮和刷新活动指示器设在隐藏的 `self.tabBarController.navigationItem` 上，而不是 `self.navigationItem`
- `MADOperationInstallSampleDocument` 在追加 `.mad` 文件扩展名之前检查 `fileExistsAtPath:`，覆盖了已有的示例文档
- `MADExplorerController -documentManagerDidChangeContent:removes:updates:completion:` 在未挂载的 `UICollectionView`（`window == nil`）上调用 `performBatchUpdates:`，因 `NSInternalInconsistencyException` 崩溃

*已归档（已修复；全文、测试及任何提交哈希见 [`BUGS_FIXED.md`](BUGS_FIXED.md)）：*

- 刷新路径从操作队列线程读取共享存储上下文
- 页数更新从不触发，因为格式化器实例不稳定
- 打开时的重新加载操作隐藏了刷新活动指示器
- "Formatting page N." 状态消息被设置却从未显示
- `MADOperationRefresh` 用连接错误替代了执行错误
- `MTTableController` 在抓取失败后读取了过期的页数
- `MADPageViewAttributes` 把缺失的缓存日期解码为 2001-01-01
- `MADPageViewAttributes` 把 `zoomScaleInital` 和 `contentScaleFactor` 收窄为 float
- `NSData (AES256)` 用 NULL IV 加密，因此密文是确定性的
- 密钥超过 32 字节时，`NSData (AES256)` 静默回退到全零密钥
- `NSData (Base64) +dataFromBase64String:` 写出其输出缓冲区之外
- `+[NSDateFormatter RFC_3339]` 拒绝带数值偏移的 RFC 3339 时间戳
- `MADOperationConditionPolarQuestionAffirmative` 丢弃了给它的答案
- `MADOperationConditionSuccess` 在没有匹配依赖时断言而不是失败
- `MADOperationConditionDisplayedAlertConfirm` 在无人能回答时返回 nil
- 文档状态信号在两端都是惰性的
- 保存现在无条件运行，且每次都重写整个存储
- 资源管理器不列出任何文档，Query 标签页不列出任何表
- 查询分组、链接和谓词列表加载存储中的每一行
- 选择字段列表过去只抓取单个字段；现在会抓取全部

## Linux 构建

### GNUstep 的 `-enumeratorAtURL:…` 产生的 URL 丢失了所在目录
- **状态：** 怪异行为（平台问题；在依赖它的唯一调用点做了变通）
- **位置：** 在 `Linux/Tests/ToolchainProbe.m` 中测量（报告项
  `directory-enumeration-url-form`），并在
  `CLI/Source/MADCLIContainer.m:192`（`-memberPaths`）中变通
- **行为：** 在 GNUstep 1.31.1 上，`-enumeratorAtURL:includingPropertiesForKeys:
  options:errorHandler:` 产生的子 URL *不包含*被枚举的目录：枚举
  `file:///repo/…/London.dataset` 得到
  `file:///Contents.json`，该 URL 相对于进程工作目录解析
  （镜像中为 `/src/Contents.json`）。`-contentsOfDirectoryAtURL:`、
  `-enumeratorAtPath:` 和 `-subpathsAtPath:` 都正确，且
  `-URLByAppendingPathComponent:` 也正确——只有这个 URL 形式的枚举器有问题。
  Apple 的实现是正确的，因此这是 GNUstep 的缺陷，不是我们的。
- **为什么重要：** `mad inspect` 对一个文件明明都在的文档列出了 **0 个成员**
  （存储头和元素计数不经过枚举，是正确的）。框架中也有调用点
  （`MADArchiveManager.m:146`、
  `MADFileUtilities.m:64,448`、`UIDocument+Extras.m:23`）——它们的套件都能过，因为
  没有一处依赖枚举器的 URL 携带目录，因此保持原样而不是扰动。
- **现状：** CLI 的成员列表改用 `-subpathsAtPath:`（这个列表本来就是由相对路径构成的），
  在两个平台上都正确。探针把 GNUstep 的行为报告为 NEED，因此修复了该问题的
  GNUstep 版本会出现在
  `--probe` 中，而不会被忽略。
- **测试：** 探针的报告项（只计数，从不致命）。

*已归档（已修复；全文、测试及任何提交哈希见 [`BUGS_FIXED.md`](BUGS_FIXED.md)）：*

- 通过 MySQL 执行 `mad refresh` 会中止：category 不是符号，因此链接器丢弃了它
- 三处 `Rptq…+extras.h` 导入的大小写写错了，只有区分大小写的文件系统才能发现
- 固定的跨平台导出摘要（digest）在 Apple 侧变得过时

## 构建接线（Xcode 引用）

在做 ROADMAP §2.1 时发现。这些是项目文件缺陷，不是源码缺陷：
`.pbxproj` 中指向不存在路径的引用，或指定了任何 target
都无法构建的平台的构建设置。

*已归档（已修复；全文、测试及任何提交哈希见 [`BUGS_FIXED.md`](BUGS_FIXED.md)）：*

- MAD Viewer target 自 `09e0e7b8d` 起就未能链接
- 三个库引用指向从未创建的目录
- 五个库搜索路径指向从未创建的目录
- 工作区用绝对路径固定了 MADTds
- CLI/build.sh 指定了机器相关的 DerivedData 目录
- MADMySQL 每次构建都带着多余的 `-v` 链接
- 应用 target 无谓地定义了 SQLITE_ENABLE_COLUMN_METADATA
- 仅靠搜索路径无法接好 macOS 构建

## 已修复（供参考）

*已归档（已修复；全文、测试及任何提交哈希见 [`BUGS_FIXED.md`](BUGS_FIXED.md)）：*

- MADFoundation 批次：十个缺陷，每个都先做了调用者审计
- MADCocoaExtensions 批次：七个缺陷，一处有意的非改动
- `MADDataTableFast -objectAtRow:column:` 忽略其 `column` 参数
- `sqlite3_mprintf` 被传入 SQL 作为其格式字符串（8 处）
- `MADDataTable` 基类静默失败而不是触发陷阱
- 批量插入运行期间 `MADDataTableFast -addRow:error:` 未受保护
- 重新加载的 `MADDataTableFast` 信任了可能过期的行计数器
- `MADDesignerTestConnection.m` 是一个空模板，却仍在运行

## 测试基础设施（非产品缺陷）

### XCUITest 运行器看到应用的无障碍树为空
- **状态：** 仍未修复
- **位置：** `MADDesigner/Targets/MADDesignerUITests`
- **行为：** 对运行中应用的每次 XCUITest 查询——甚至
  `app.debugDescription`——都报告完全没有元素，因此此环境中任何 UI 断言都无法
  通过。模拟器演练（打开示例、走遍三个标签页）改为用
  应用的启动参数驱动（见
  `AppDelegate.m`：`-UITestOpenSample`、`-UITestSelectTab`），并用截图验证。
  `MADDesignerUITests.m` 记录了这一点，且有意留空。
- **在存储迁移期间发现；未调查。**

### `MADDesignerUnitTests` 配置错误，已有一段时间无法构建
- **位置：** `MADDesigner/MAD Designer.xcodeproj/project.pbxproj`、
  `MADDesigner/Targets/MADDesignerUnitTests/MADDesignerUnitTests.m`
- **行为：** 四个独立且先前就存在的问题，现均已修复：
  - `MADDesignerUnitTests` 和 `MADDesignerUITests` 的 `IPHONEOS_DEPLOYMENT_TARGET`
    都是 `12.0`，低于此工具链支持的 15.0 下限。
  - `INFOPLIST_FILE` 指向 `MADDesignerUnitTests/Info.plist`；该文件实际位于
    `Targets/MADDesignerUnitTests/Info.plist`。
  - 单元测试 target 的 Frameworks 阶段为空。`BUNDLE_LOADER` 只针对宿主*可执行文件*
    解析未定义符号，不针对应用链接的 dylib，因此必须显式链接
    `_OBJC_CLASS_$_MADQueryTest` 以及测试使用的其他框架类。
  - 测试文件本身是 Xcode 模板加一个 `testExample`，它用硬编码凭据在
    `us-east-1` 打开一个现役 RDS 实例，调用已不存在的 API。已围绕应用自己的辅助
    category 和框架用法重写。

### XCTest 断言宏会在方括号内的逗号处拆分
- **位置：** 任何使用 `XCTAssert*(...)` 的测试文件
- **行为：** 预处理器按不在*圆括号*内的逗号分隔宏参数，
  因此 `XCTAssertEqualObjects(a, [Foo bar:baz, qux])` 会被撕裂为
  `expression2` 和一个多余的变参参数而解析失败，错误报告在
  语句末尾而不是逗号处。把该消息发送用圆括号包起来，或先提升到局部变量，
  即可解决。值得知道，因为应用的条件所接受的消息常常是双参数发送。

*已归档（已修复；全文、测试及任何提交哈希见 [`BUGS_FIXED.md`](BUGS_FIXED.md)）：*

- `MADTestReportFormatter` 被阻塞，而记录的原因有误
- 两个并行的 Linux 套件在同一个 London 测试夹具和示例数据库上发生竞争

## 约定（非产品缺陷）

### 可空性与错误报告在整个程序中不统一
- **状态：** 观察——记录，并非缺陷。
- **问题：** 三条相关约定是临时应用的：
  - **参数可空性：** 有些参数标注了 `nonnull`；许多没有，因此仅凭签名无法看出是否容忍 nil。
  - **nil 实参行为：** 程序尚未决定对 nil 参数抛出异常。有些方法抛出 `NSException`，
    有些 `@throw` 的是 `NSError` 对象本身（`MADDataTable` 的缓存方法
    对），有些返回 `NO` 并填充输出参数，还有些静默容忍 nil。
  - **错误格式：** 没有统一的错误域、代码范围或 `userInfo`
    契约；仅 `MADDataTable` 就用了两个域
    （`NSStringFromClass([MADDataTable class])` 配负代码，以及
    `MADDataTableErrorDomain`），其他类各自定义自己的域。
- **为何记录：** 调用者无法从声明判断如何处理 nil 或
  非法实参，同一个失败会以三种不同形态报告。
  选定一种约定是全项目范围的设计决策，不是单文件的修复。
- **缓解措施（2026-10-18）：** `MADDataTable -cacheWithUrl:error:` 和
  `-loadFromCacheWithUrl:error:` 现在带有 `///` 注释，说明其 nil URL 抛出行为。
  程序其余部分仍无约定。
