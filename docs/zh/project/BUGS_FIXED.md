---
layout: default
lang: zh-CN
---

# BUGS_FIXED.md

[`BUGS.md`](BUGS.md) 的归档：每一个缺陷已被修复的条目都原样迁移至此，以保持未关闭问题文件的可读性。没有任何内容被删除——正文、缺陷的行为、修复所做的工作、锁定它的测试以及提交哈希，均与在 `BUGS.md` 中时一致。

当某个条目的“状态”表明缺陷已修复时（或者它位于早于就地归档约定的 *Already fixed (for reference)* 之下），该条目就会进入本文件。部分修复的条目仍留在 `BUGS.md` 中，因为其余部分尚未关闭。

`BUGS.md` 在其所属框架标题下为每个条目保留一行索引，因此引用“BUGS.md，X 条目”仍然能落到实处。

## MADAPI

### `MADDatabaseConnection` 的子类无法经受基类的 `NSCopying` / `NSCoding`
- **状态：** 已修复 2026-10-18（提交 `a25756b5d`）。
- **位置：** `MADAPI/Source/MADDatabaseConnection.m:34-62`
- **行为：** `-initWithCoder:` / `-encodeWithCoder:` / `-copyWithZone:` 读写的是基类*自身*的实例变量。具体子类看不到这些实例变量（它们在基类 `.m` 中合成，未在头文件中声明），因此会用自己的存储遮蔽每一个变量——`MADDatabaseConnectionMySql` 正是通过 `@synthesize databaseType = _databaseType;` 这样做的。基类的访问器从未被调用，因此复制或归档后的连接读回时，`databaseType` 为 `MADDatabaseTypeUnknown`、连接字符串为 nil、`requiresCredentials == NO`，且标识符为 nil。`MADDatabaseConnectionMySql` 通过用真正的初始化器重写 `-copyWithZone:` 绕过了复制这一半的问题；没有任何类重写编码这一半。
- **为什么重要：** 将来对连接对象——或者对编码其 `databaseConnection` 的 `MADDatabase`——进行任何持久化，都会静默丢失连接状态。目前是潜在问题：应用或各框架中尚无这两种类型的归档。
- **现状：** 这四个实例变量在 `MADAPI/Source/MADDatabaseConnection.h` 中声明为 `@protected`，因此驱动使用基类的存储而不再遮蔽它；基类的 `-copyWithZone:` 和编码方法因而能携带标准属性，且 `-initWithCoder:` 通过 `[self init]` 派发，使解码后的驱动能运行自己的初始化器。三个驱动也各自携带自身的参数：`MADDatabaseConnectionMySql`（host、database、port）、`MADDatabaseConnectionSqlite3`（URL）和 `MADDatabaseConnectionSQLServer`（host、server、database、port）重写了编码方法对，调用 super 并重新声明 `+supportsSecureCoding`。头文件记录了对第三方驱动的契约要求。
- **测试：** `MADDatabaseConnectionTests testSubclassCopyCarriesSubclassState` 和 `testSubclassNSCodingCarriesSubclassState`（由 `...DoesNotCarry...` 重命名而来），外加 `MADMySQLTests testConnectionCodingRoundTripCarriesTheConnectionState`、`MADDatabaseSqlite3Tests testConnectionCodingRoundTripCarriesTheUrl` 和 `MADTdsClientTests testConnectionCodingRoundTripCarriesTheConnectionState`，以及各自的 Linux 移植版本。

### `MADDatabase` 仅支持 NSCoding，因此安全归档会拒绝它
- **状态：** 已修复 2026-10-18（提交 `4e9f5af6f`）。
- **位置：** `MADAPI/Source/MADDatabase.h:32`、`MADAPI/Source/MADDatabase.m:50-63`
- **行为：** 该类声明了 `NSCoding` 而非 `NSSecureCoding`，且未实现 `+supportsSecureCoding`。因此 `+[NSKeyedArchiver archivedDataWithRootObject:requiringSecureCoding:YES error:]` 会返回 `nil` 并附带错误。其 `-initWithCoder:` 还使用了非安全的 `-decodeObjectForKey:`，因此即便是现代的类匹配解码 API（`-decodeObjectOfClass:forKey:`）也会拒绝它。往返仅能通过传统路径工作（`[[NSKeyedArchiver alloc] initRequiringSecureCoding:NO]` 以及 `requiresSecureCoding = NO` 的解档器，而这*不是* `-initForReadingFromData:error:` 的默认值）。
- **为什么重要：** 如果调用者使用安全 API——近期 SDK 中强制的默认方式——归档会在运行时失败并返回 nil。目前应用或框架中没有任何地方归档 `MADDatabase`（已检查：仅有的 `NSKeyedArchiver` 用户归档的是缓存和查询可视化负载），因此这是潜在问题。
- **现状：** 该类声明了 `NSSecureCoding` 并实现 `+supportsSecureCoding`；`-initWithCoder:` 用 `-decodeObjectOfClass:` 解码连接，用允许 `NSArray` 和 `NSError` 的 `-decodeObjectOfClasses:` 解码错误数组。传统的非安全往返仍然可用。`MADDatabaseMySQL`、`MADDatabaseSqlite3` 和 `MADDatabaseSQLServer` 未重写任何编码方法，因此它们继承该协议一致性且无需修改（它们各自的实例变量原本就不由基类编码）。
- **现状（初始化器）：** `-initWithCoder:` 通过 `[self init]` 而非 `[super init]` 派发（提交 `8d78329f9`），因此解码后的子类在应用归档的基类状态之前会先运行自己的 `-init`——例如 `MADDatabaseSQLServer` 的 `MADNotificationError` 观察者。这与 `-copyWithZone:` 一致，后者本来就通过具体类的初始化器构造副本。
- **测试：** `MADDatabaseTests testSupportsSecureCoding` 和 `testSecureCodingRoundTrip`（取代 `testSecureArchivingIsUnsupported`）；`testInsecureNSCodingRoundTrip` 仍然通过，`testDecodingRunsTheSubclassInitializer` 锁定初始化器派发。Linux 移植版本断言了协议一致性声明以及 GNUstep 的严格归档拒绝行为，因为 GNUstep 没有安全归档功能（`Linux/README.md`）。

### `MADDatabaseDataBinding`：`nil` 与 `[NSNull null]` 的处理不一致
- **状态：** 已修复
- **位置：** `MADAPI/Source/MADDatabaseDataBinding.m:153`
- **行为：** 设置 `nil` 值会存储 `[NSNull null]`，但设置显式的 `[NSNull null]` 值却会让存储的值保持为 `nil`。这两种“无值”输入本应被一视同仁地处理。
- **为什么重要：** 这种不对称是真实存在的，但**无害**，早先关于“导致错误报表数据”的说法并不正确。生产代码中唯一读取 `.value` 的是 `MADDatabaseSqlite3.m -bindStatement:withBindings:`，而在那里两种输入都会绑定为 SQL NULL：显式的 `[NSNull null]` 会被顶部的 `isEqual:` 测试捕获，而 `nil` 会落入 `case MADDataTypeNull:`（`MADDatabaseSqlite3.m:373`）→ `sqlite3_bind_null`。没有任何调用者会观察到差异。由 `MADDatabaseDataBindingTests.m:58-60` 锁定。
- **现状：** nil 测试和 `[NSNull null]` 测试共享同一个分支，因此两者都存储 `[NSNull null]`，且 `datatype == MADDataTypeNull`。
- **测试：** `testInitWithNullValueStoresNSNull`（由 `testInitWithNullValueLeavesValueNil` 重命名而来）。

### `NSStringFromMADQueryType`：`MADQueryTypeCacheIndexDropParameters` 缺少 "TypeCache"
- **状态：** 已修复
- **位置：** `MADAPI/Source/MADQueryType.h:64`
- **行为：** `NSStringFromMADQueryType(MADQueryTypeCacheIndexDropParameters)` 返回 `@"MADQueryIndexDropParameters"`——漏掉了 `TypeCache` 片段。
- **为什么重要：** 任何展示查询类型名称的 UI（日志、调试视图、未来的 AI 生成查询展示）都会显示错误的字符串。
- **现状：** 它返回 `@"MADQueryTypeCacheIndexDropParameters"`，与正上方的同类分支 `...IndexCreateParameters` 保持一致。由 `testNSStringFromMADQueryTypeCacheIndexDropParameters`（由 `testNSStringFromMADQueryTypeCacheIndexDropParametersDefect` 重命名而来）锁定。

### `NSStringFromMADQueryType`：`MADQueryTypeSampleDataTableRange` 未映射
- **状态：** 已修复
- **位置：** `MADAPI/Source/MADQueryType.h:72`
- **行为：** `MADQueryTypeSampleDataTableRange`（原始值 28）穿透 switch 并返回 `@"MADQueryTypeUnknown"`。
- **为什么重要：** 整整一种查询类型没有名称；任何以该名称为键的逻辑（持久化、UI）都会将它错误标记。
- **现状：** 它拥有自己的分支并返回 `@"MADQueryTypeSampleDataTableRange"`。由 `testNSStringFromMADQueryTypeSampleDataTableRange`（由 `testNSStringFromMADQueryTypeSampleDataTableRangeFallsThrough` 重命名而来）锁定。

### `MADConnectionViewController` / `MADConnectionSQLGenericViewController` 的 `-databaseConnection` 抛出了 NSString
- **状态：** 已修复 2026-10-18（提交 `f492cb00f`）。
- **位置：** `MADAPI/Source/MADConnectionViewController.m:279`、`MADAPI/Source/MADConnectionSQLGenericViewController.m:353`
- **行为：** 该重写点被实现为 `@throw NSInternalInconsistencyException;`，它抛出的是*名称常量*——一个 `NSString`——而不是 `NSException`。`MADDatabase` 上每个“需要子类化”的方法都会用同一个常量构建真正的 `[NSException exceptionWithName:NSInternalInconsistencyException reason:... userInfo:nil]`；这两处却没有。
- **为什么重要：** `@catch (NSException *e)`——本代码库中所有地方唯一编写的捕获形式——无法捕获它；抛出的内容会作为未知异常对象冒出来。只有误用抽象方法的路径会触发它，因此影响范围很小，但这种不一致确实存在。
- **现状：** 两处重写都构建了真正的 `NSException`，名称为 `NSInternalInconsistencyException`，原因中指明需要子类化的类，与 `MADDatabase` 的抽象方法保持一致。`@catch (NSException *)` 现在可以捕获它。
- **测试：** `MADConnectionViewControllerTests testDatabaseConnectionThrowsOnBaseClass` 和 `testDatabaseConnectionThrowsOnSQLGenericClass`，现在它们捕获 `NSException` 并断言其名称和原因（此前它们捕获 `id` 并断言抛出的对象是该名称常量）。

## MAD（框架）

### `MADDesignerLayout` 的多选撤销用单个标量覆盖每个元素的先前值
- **状态：** 已修复 2026-10-29。
- **位置：** `MAD/Source/MADDesignerLayout.m:157-555`（`-updateElements:setFontsize:`、`-updateElements:setFontname:`、`-updateElements:setVerticalAlignment:`、`-updateElements:setHorizontalAlignment:`、`-updateElements:setSizeWidth:`、`-updateElements:setSizeHeight:`，以及 `-updateElements:setMargin*`、`-updateElements:setPadding*` 和 `-updateElements:setBorder*` 系列方法）。
- **行为：** 每个批量更新方法都遍历 `identifiers`，覆写单个局部标量 `previous`（`previous = element.fontsize;` 等），然后注册单个撤销块，将该唯一的 `previous` 值写回所有 `elementIDs`。`-updateElements:setFontname:`（`:184`）只捕获*第一个*元素的字体名称（`if (previous == nil) previous = element.fontname.copy;`），而所有数值/枚举 setter 只捕获*最后一个*元素的值（若 `identifiers` 为空则为 `0.0`）。
- **为什么重要：** 当用户选中两个或更多具有不同尺寸、字体、对齐方式、外边距、内边距或边框的报表元素并修改其中一个属性时，按“撤销”会用某一个元素的旧值覆写所有选中元素，而不是恢复每个元素各自的先前状态。
- **现状：** `MADDesignerLayout` 在应用新值之前，将每个元素的先前值记录在以元素标识符为键的字典中；撤销/重做处理器会恢复每个元素各自的值，同时在相反的栈上记录反向字典。
- **测试：** `MADDesignerViewerTests testDesignerLayoutMultiSelectionUndoRestoresPerElementValues`。

### `MADSQLParser` 在 `FROM`、`JOIN` 和三段式列引用中拒绝架构限定的表名（`schema.table`）
- **状态：** 已修复 2026-10-28。
- **位置：** `MAD/Source/sql/MADSQLParser.m:242-267`（`-parseSelectItemReturningError:`）、`:367-380`（`-parseFromItemReturningError:`）以及 `:630-655`（`-parseColumnReferenceReturningError:`）。
- **行为：** `MADDatabaseSQLServer`（`MADTdsClient`）和 `MADDatabasePostgres`（`MADPostgres`，针对 `public` 之外的表）在文档架构中存储诸如 `SalesLT.Product` 或 `sales.orders` 这样带架构限定的表名，并将每个以点分隔的部分作为单独加引号的标识符输出（`[SalesLT].[Product].[Name]`、`"sales"."orders"."id"`）。`MADSQLParser` 在 `-parseFromItemReturningError:` 中遇到 `FROM` 或 `JOIN` 后只读取单个标识符词法单元（从不消费 `.` + 表名），在 `-parseSelectItemReturningError:` / `-parseColumnReferenceReturningError:` 中最多只读取一个 `.` 限定符，因此粘贴为架构限定表生成的语句时，即便架构字典中存有 `"sales.orders"` 或 `"SalesLT.Product"`，解析也会失败。PostgreSQL 的 `public` 架构中的表以非限定形式存储，通过 `MADSQLParser` 往返没有问题。
- **为何此处不改：** `MAD_SQL_ENTRY.md` §5 围绕单词法单元表名和两段式 `table.column` 引用定义了分析器语法；将其扩展为支持可选的 `schema.table` / `schema.table.column`（以及在带限定的规范名称上检查放置序号别名）属于 `MAD` 中的分析器语法变更，超出了驱动本身的范围。
- **现状：** `MADSQLParser` 在 `-parseFromItemReturningError:` 的第一个标识符后消费可选的 `.` + 表标识符（产生 `schema.table`），在 `-parseSelectColumnReturningError:`（`schema.table.col` 和 `schema.table.*`）及 `-parseColumnReferenceReturningError:`（`schema.table.col`）中消费可选的第二个 `.`，并在表别名中消费可选的 `.`。`MADSQLParser` 和 `MADSQLStatementResolver` 中的放置序号别名校验均接受表自身的名称或 `<base><digits>`，其中 `<base>` 可以是带限定的规范名称（`sales.orders0`），也可以是 `RptqQueryTable +queryAliasForSchemaTableName:dropIndex:` 输出的去点形式（`salesorders0`）。
- **测试：** `MADSQLParserTests`（`testSchemaQualifiedTableAndThreePartColumnsParse`、`testQuotedSchemaQualifiedTableAndThreePartColumnsParsePerDialect`、`testSchemaQualifiedDropIndexAliasesParse`、`testAnUnknownSchemaQualifiedTableIsRejected`、`testAnUnknownThreePartColumnIsRejected`、`testARenamedSchemaQualifiedAliasIsRejected`）和 `MADSQLQueryCompilerTests testSchemaQualifiedTableApplyAndFixpointRoundTrip`，以及它们的 Linux 移植版本。

### MADReportFormatter 通过 id 比较无类型值
- **状态：** 已修复 2026-10-18（提交 `483a77259`）。
- **问题：** `MADReportFormatter.m:219` 和 `:222` 向以 `id` 持有的值发送 `compare:`，而多个类以不同的参数类型声明了该选择器，因此编译器无法绑定它（`-Wstrict-selector-match`）。如果被排序的值并非全都属于同一个类——格式化器对混合了数值和字符串的查询结果进行排序——就可能调用错误的实现，或者根本找不到实现。
- **位置：** `MAD/Source/MADReportFormatter.m:210-225`。
- **更新（2026-10-18，文档梳理——行为未变）：** 值的类是有界的。这些值来自行缓存，经由 `MADDataTableFast -enumeratorForKeyObjectsSorted:` -> `MADDataTableObjectEnumerator` -> `+[MADDatabaseSqlite3 databaseResultValue:columnNumber:]`，后者将 SQLite 的存储类映射为 Foundation 类且不携带其他标签：INTEGER/FLOAT -> `NSNumber`，TEXT -> `NSString`，BLOB -> `NSData`，NULL -> `NSNull`。该读取器绝不会产生 `NSDate`。每个层级的 `NSSortDescriptor` 上的选择器是架构侧的类型提示（`MADDataTypeSelectorForSorting`）：字符串 -> `localizedCaseInsensitiveCompare:`，blob -> `compareData:`，其余全部 -> `compare:`。不需要新的 sqlite API，也不需要每个值的缓存标签：对象的类*就是*读取器产生的标签，而选择器就是调用链上游已知的类型。缓存的实际排序是另一回事：格式化器的枚举器以 `columns:nil` 构建其 ORDER BY 查询，因此目前文本键按二进制排序，而这里的选择器却指定不区分大小写——见 MADSqlite3 下的“缓存的 ORDER BY 忽略列类型”。警告出现在 `-compareValue:withValue:usingSelector:` 中的两处 `-compare:` 发送上；上面的行号已经变动。
- **实际出错之处：** 选择器与值的类不匹配会抛出异常——`unrecognized selector`（例如向 `NSNumber` 发送 `localizedCaseInsensitiveCompare:`）或 Foundation 自身的参数类型异常——而不会静默地错误排序。缓存按每列声明的类型绑定该列，因此一列通常是同质的，但绑定并不强制值的类。Blob 列是宽松的情况（绑定接受 `NSString` 和 `NSData`，分别存储为 TEXT 和 BLOB），而非 sqlite 数据源则可以提供任何值。London 和 Music 夹具只触发匹配的值对（London 为数值，Music 为字符串）。本条目所说的“混合数值和字符串”发生在不同的分组层级之间，而非同一层级内部：每个层级都有自己的值/选择器对，且结果中只读取 `NSOrderedSame`。
- **商定设计（2026-10-18）：** 缓存列声明的 `MADDataType` 是如何比较分组键的唯一事实来源——它是绑定路径实际存储的类型，也是缓存的 ORDER BY 必须使用的类型。分组字段的架构类型是设计意图，并在缓存没有列元数据时作为回退。一个分组层级对应一列及一个声明类型，该层级的每个键都使用根据该类型一次性选定的比较器进行比较。嵌套分组是彼此独立的层级，各有自己的比较器。逐分组的页眉/页脚结构保持不变：两次遍历表达不同的领域行为（页眉由外向内开启，页脚由内向外关闭），且两者共用同一个层级比较器。NULL 在比较器中是一等公民，而非回退：`NSNull` 未实现任何比较方法，因此类型化路径永远不会看到它。规范表示：Date/DateTime/TimeStamp/Time -> `NSNumber` 纪元秒（存储为 REAL，这正是显示路径已经读取的形式）；Decimal -> `NSNumber` double（存储为 REAL，带有已记录的精度损失）；其余 `MADDataType` 值在实现前也归入同一张表。
- **契约归属：** `MADDatabaseDataBinding -initWithDataType:fieldIndex:value:` 是批量插入、非批量插入以及聚合 WHERE 绑定的唯一构造点，因此在此处选定规范类；`-[MADDatabaseSqlite3 bindStatement:withBindings:]` 保留防御性断言和针对手工构建绑定的单次日志。绑定路径必须为每个声明的 `MADDataType` 存储唯一的规范类——数值 -> `NSNumber`，字符串 -> `NSString`，blob -> `NSData`，null -> `NSNull`，Date 和 Decimal 如上所述——并对无法表示的值记录日志或予以拒绝，而不是什么都不绑定或绑定成其他类。这样读取器（`+databaseResultValue:columnNumber:`）返回的类的类型就完全取决于列类型。兼容性：当文件存在时（离线查看），缓存会在不刷新的情况下复用，因此契约之前的旧缓存仍可能到达格式化器。Debug 下断言；Release 下仅在违约时记录一次日志并走冷路径的安全类检查回退——健康的热路径中没有分支。可选的缓存 `user_version` 标记可在日后淘汰该回退。
- **工作顺序（正确性优先于性能）：** (0) 修复缓存的 ORDER BY，使文本键按 LSASC 排序且每列使用其自身的 `MADDataType`：将缓存的列传入枚举器查询，并将五处 `sortDescriptionForColumnType:` 调用点从 `nativeType` 改为 `column.type`（见 MADSqlite3 条目）。不这样做的话，比较器与行顺序会不一致，大小写不同的分组会被拆开。(1) 明确写出每个 `MADDataType` 的规范表示；(2) 在 `MADDatabaseDataBinding` 中规范化，保留绑定器的防御性检查，并将 MySQL 首行类型修正移入 `dataColumnForFieldName:`；(3) 为分组层级提供每次格式化从缓存列类型（架构作为回退）解析一次的比较器，在两次遍历中使用它，并删除泛型的 `id` 路径；(4) 测试：多级分组、字符串（LSASC 不区分大小写）、数值、日期、blob、NULL、畸形缓存值被报告而非令格式化器崩溃，以及旧缓存容错。在此之后，才考虑性能：每层级的函数指针表、每行每层级由两次遍历共享的单一变更/未变更结果，以及（若仍有必要）来自枚举器/SQL 的边界标志。
- **暂缓或否决的方案：** 在格式化器处做带类检查的类型化派发（上一版修订的建议）只是针对违反契约的旧缓存的 Release 回退方案，而非目标方案——它把检查留在渲染循环中，且只修复了一个消费者。把 `MADResult` 变成真正的类型会波及每个数据源、字典和聚合路径。返回 `(value, type)` 的新 sqlite API 会与类重复。在缓存或键数组中为每个值加标签会为每行增加一次分配，而且键数组的值还会传给聚合 WHERE 子句，因此必须保持为原始值。经测量，用 `-isEqual:` 测试相等性比 `compare:` 更慢（对 `NSNumber` 为 32 ns 对 23 ns）。在 SQLite 中做边界检测（LAG 或二次遍历）理论上最快，但会将格式化器与缓存耦合，并改变数据源契约。
- **由第二意见解决（2026-10-18）：** 插入路径是强制执行点（由 `MADDatabaseDataBinding` 完成规范化）；缓存列的类型是唯一事实来源；Date/Decimal 为 `NSNumber` 纪元秒/double；契约之前的缓存通过记录日志的冷路径回退加以容忍；缓存的 ORDER BY 是一个现实存在的独立缺陷（见下文 MADSqlite3 条目）。
- **现状：** 规范表为每个声明类型指定唯一的类，在 `MADDatabaseDataBinding -initWithDataType:fieldIndex:value:`（`MADCanonicalValueForType`）中决定：Bit/Integer/Short/Long/LongLong/Int24/Enum -> `NSNumber`（`longLongValue`；数值型 `NSString` 会被解析并记录一次日志），Float/Double/Number/Decimal -> `NSNumber`（`doubleValue`；`NSDecimalNumber` 是 `NSNumber` 的子类，因此精度损失已记录在案而非静默发生），String/VarChar/Set/Year/Geometry -> `NSString`（`NSNumber` 会存储其文本并记录一次日志），Date/DateTime/TimeStamp/Time -> `NSNumber` 纪元秒（存储为 REAL，即显示路径读取的类；`NSDate`、`NSDateComponents` 和纪元秒字符串均会转换），Blob/Image -> `NSData`（`NSString` 会存储其 UTF-8 字节并记录一次日志），Unknown -> 字符串化（与之前相同），Null -> `NSNull`。该类型无法表示的值会存储为 NULL 并记录一次日志——绝不会静默存储为其他类，旧绑定器的崩溃（把 data/date 塞进数值列）也已消除。`-[MADDatabaseSqlite3 bindStatement:withBindings:]` 现在在每个分支中都看到各自对应的类，并对契约之外手工构建的绑定保留防御性的单次日志 + NULL（Debug 下断言）。`MADReportFormatter +compareValue:withValue:forDataType:` 取代了 `-compareValue:withValue:usingSelector:`（严格选择器匹配警告随之消失）：NULL 是一等公民，各类型化类按缓存 ORDER BY 的排序方式进行比较，每个分组层级在每次格式化时从行缓存的列解析一次其类型（`-groupDataTypes`，仅当缓存中不存在该列时才回退到架构字段——存在的列保留自身类型，包括 Unknown）。如果读取器可能产生的四个类之间发生违约——即契约之前的旧缓存可能持有的内容——会记录一次日志并走安全的类检查回退进行比较：同类值对按值比较，混合值对按类排序（绝不返回 Same，因此异质旧列中的同质连续段仍能成组），离线打开依然能够格式化；若是读取器绝不可能产生的类则触发断言。MySQL 的首行 `column.type` 修正已移除：TEXT 与 BLOB 的区分在 `+[MADMySQLFetch dataColumnForFieldName:mySqlField:]` 中根据列的字符集一次性决定（binary 63 为 BLOB），抓取操作遵循列声明的类型。Enum 列仍然存储解析后的数值（既有行为；"red" 变成 0）——留作后续事项，不在此处静默更改。可选的缓存 `user_version` 标记仍留作后续事项。
- **测试：** `MADSqlite3Tests/MADDatabaseSqlite3BindingTests.m`（绑定矩阵）、`MADAPITests/MADDatabaseDataBindingTests.m`（规范类），以及 `MADTests/MADTestReportFormatter.m` 中的分组边界和比较器测试组，均在 `Linux/Tests/` 下有对应镜像。表征测试锁定了契约保留的值对；原先失败的锁定项（字符串层级中的数值抛异常、日期绑定为 NULL、缺少 LSASC 的 ORDER BY）在通过后已替换为契约断言。
- **代码中已记录：** `MADReportFormatter.m`（`+compareValue:withValue:forDataType:`、`-groupDataTypes`、`-formatDocumentAddDetail`、`-newObjectArrayKeyValuesForResultRow:`、两处分组遍历）、`MADDatabaseDataBinding.m`（`MADCanonicalValueForType`）以及 `MADDatabaseSqlite3.m`（`+databaseResultValue:columnNumber:`、`-bindStatement:withBindings:`、LSASC 排序规则）。

### MADSectionLayout 以错误的宽度读取 CFNumber，破坏了相邻的实例变量
- **状态：** 已修复 2026-10-17。
- **位置：** `MAD/Source/MADSectionLayout.m:52-67`。
- **问题：** `MAD/Source/MADSectionLayout.m` 用 `CFNumberGetValue` 填充其实例变量，但传入的宽度与目标变量不匹配。`:55` 将 `double`（8 字节）写入 `float _height`（4 字节），`:61` 将 `SInt64`（8 字节）写入 `MADDocumentSectionType _type`，而后者是 `int16_t`（`MADDocumentSectionType.h:20`）。因此每次调用都会覆写目标之后的存储空间——`:55` 的高半部分落入 `_groupLevel`，`:61` 的高半部分落入 `_height`——且该文件中此后再未对 `_height` 或 `_groupLevel` 赋值，被破坏的值就这样保留下来。
- **为何此处不修复：** 这些实例变量会作为布局的高度和分组被读取；修正宽度会改变这些读取的返回值（目前 `_height` 实际上为零），从而明显改变报表布局。这是一个行为决策，而非单纯的警告修复。
- **证据：** `xcodebuild analyze`，`osx.coreFoundation.CFNumber`："a CFNumber object that represents a 64-bit integer is used to initialize a 16-bit integer; 48 bits of the CFNumber value will overwrite adjacent storage"。
- **现状：** `_height` 使用 `kCFNumberFloatType` 读取，`_type` 使用 `kCFNumberSInt16Type` 读取，与实例变量匹配。`_height` 现在返回存储的声明高度，设计器据此确定分节视图的尺寸；渲染仍使用由元素计算得出的 `displayHeight`，未发生变化。`_groupLevel` 不再持有 double 的高半部分。
- **测试：** `MADDocumentTests testSectionLayoutReadsEachNumberAtItsDeclaredWidth`（`MAD/MADTests/MADDocumentTests.m`）。
- **提交：** `062eea381`。

### `digit_count_*_int`：`INT_MIN` 被折叠成 `INT_MAX`
- **状态：** 已修复 2026-10-17。
- **位置：** `MAD/MADTests/MADCoreLogicTests.m`
- **行为：** 在计算位数之前，`INT_MIN` 被折叠成了 `INT_MAX`。两者恰好都是 10 位数字，因此输出是正确的，但这纯属巧合。
- **为什么重要：** 目前无害；记录它只是因为这种折叠在数学上不具一般性。
- **现状：** 两个函数针对 `INT_MIN` 都在取负之前先做除法，并加上除法舍去的那一位，因此位数统计不再依赖 `INT_MAX` 的位数，也不会发生取负溢出。对所有输入的结果均保持不变。
- **测试：** `MADCoreLogicTests testDigitCountRecurIntBounds` 和 `testDigitCountIterativeIntBounds`（iOS），以及 `Linux/Tests/MADCoreLogicTests.m` 中相同的边界检查。
- **提交：** `d2000e960`。

### `MADSectionGroupLayout` 在字段没有查询表的分组上发生段错误
- **状态：** 已修复 2026-10-17。
- **位置：** `MAD/Source/MADSectionGroupLayout.m:43`、`:46`、`:49`、`:58`
- **行为：** 初始化器直接从字典结果行中取出分组的 `sort`、`weight`、`hasField.databaseSchemaField.dataType` 以及字段的 `inQueryTable.dropIndex`，并将每一个都传给 `CFNumberGetValue`。nil 值就是 NULL `CFNumberRef`，而 `CFNumberGetValue` 不会对此做检查：进程直接因 SIGSEGV 终止，而不是抛出异常。只要分组的字段背后没有 `RptqQueryTable`——即文档的分组字段不在查询所选的表中——就会走到这里。
- **为什么重要：** 这是格式化器在处理从 `.mad` 读回的数据时发生的硬崩溃，而不是断言或错误数值。由 `MADTestReportFormatter` 发现：一个接线不完整的夹具直接弄垮了测试宿主，而不是让单个测试失败，崩溃日志成了唯一的诊断依据。
- **尚未修复：** 夹具现在接好了表，因此测试在不触及该路径的情况下通过。还没有人决定布局对无法安放的分组*应该*怎么做——是跳过它，还是为这四个数值提供默认值并让它以错误的键渲染。这是一个行为决策，不是一行守卫就能解决的事。
- **更正（2026-10-17）：** 在可移植存储迁移之后，只有当 `RptqQueryGroup.hasField` 本身为 nil 时才会遇到 nil `CFNumberRef`（此时 `MADSectionsLayout.m` 会省略这两个数值键）。存在但没有 `inQueryTable` 的字段不再在那里崩溃：`@(field.inQueryTable.dropIndex)` 为 `@0`，布局会静默地将整份报表作为 `"(null)"` 键下的单个分组进行渲染。这两种状态都是无效数据：添加分组界面在选择字段之前一直禁用 Done（`MADQueryBuilderAddGroupViewController.m:145-154`），且 `MADocument -addQueryGroupWithQueryField:` 接收字段 id，因此 UI 无法持久化其中任何一种状态；但旧版、转换而来或手工编辑的文档可能会有。
- **现状：** 无法推导出键的分组会被拒绝。初始化器仅在数值存在时读取它，并记录分组是否解析成功；`MADSectionGroupLayout -sortDescriptor` 会抛出指明该分节的 `NSInvalidArgumentException`，而 `RptqQuery -sortDescriptorsForDatabase:` 会在构建出 `"(null)"` 键之前抛出指明该查询分组的异常。两者都会先用 `os_log_error` 记录日志。构造过程本身不会抛异常：`MADReportSectionsDataSource.m` 为设计器构建同样的布局，现在它会把损坏的分组标记为 `missing grouping field`，而不是在 `-safeSortKey` 中崩溃。该不变式已记录在 `MAD_DATA_OBJECT.md` 第 3.1 节中。
- **测试：** `testGroupWithoutFieldRaisesWhenFormatted`、`testGroupFieldWithoutQueryTableRaisesWhenFormatted`、`testDesignerDisplayOfGroupWithoutFieldDoesNotThrow`、`testQuerySortDescriptorsRejectGroupWithoutField`、`testQuerySortDescriptorsRejectGroupFieldWithoutQueryTable`（`MAD/MADTests/MADTestReportFormatter.m`）。
- **提交：** `3fcd388d2`。

### 渲染出的货币取决于机器，而不是文档
- **状态：** 已修复 2026-10-17。
- **位置：** `MAD/Source/rptq/RptqDocumentElement+Extras.m`（`-formattedString:forValue:` 和 `-awakeFromInsert`）、`MAD/Source/MADCurrencyFormatter.h`（模型存储的 locale 和 decimalCount）、`MAD/Source/rptq/autogen/RptqNumericFormat.h`（存储的文本列）。
- **行为：** 货币分支构建了一个带有 `NSNumberFormatterCurrencyStyle` 和 `locale = [NSLocale currentLocale]` 的 `NSNumberFormatter`——即使用*进程的*区域设置和*该区域设置的*小数位数——尽管元素的数值格式已经同时存储了设计时的区域设置（`"en_US"`，文本形式）和小数位数。因此渲染出的文本取决于执行渲染的机器。以前只有 Apple 端负责渲染，所以一直未被察觉；将渲染半边迁移到 Linux（2026-10-16）时测出了这个问题：London 夹具导出的 HTML 在 Apple 上显示 `$0.99`，而在镜像中显示 `$ 1`（镜像的当前区域设置是 `en_US_POSIX`，而且 GNUstep 的货币样式对任何区域设置都不渲染小数位）。
- **为什么重要：** 同一份报表在两台机器或两个平台上渲染会显示不同的值。渲染报表的服务器没有可供继承的用户区域设置，而报表的文本本身就是报表的一部分。
- **现状：** 在元素的格式化器中做了三件事：
  1. 区域设置取自文档的数值格式——有存储的标识符时用该标识符，文档未指定时用 `en_US`。回退值有意*不*使用 `[NSLocale currentLocale]`：那正是导致两个平台不一致的原因，而且 London 示例是在 en_US 下设计的，因此参考 PDF 的字节不会改变（`sha256 3eb2f1c4…`，43,177 字节）。
  2. 元素工厂在创建数值格式时记录设计时的区域设置（`-awakeFromInsert`，作为存储文本列保存的标识符），因此新文档会携带各自的区域设置，法语用户的报表保持为法语格式。
  3. 货币符号取自区域设置并显式写出，日元符号从 GNUstep 的全角 U+FFE5 规范化为 U+00A5。
- **实测而非假设：** 在显式区域设置和文档小数位数下，两个平台的货币输出在 60 个用例的对比中字节完全一致——六个区域设置（en_US、fr_FR、de_DE、ja_JP、en_GB、es_ES）乘以十个数值（包含负数、千位分隔、0.005 处的四舍五入以及 1e12）。唯一发现的差异是日元符号码位，已由第 3 点解决。London 夹具的 `html`、`html-flow` 和 `json-report` 导出在 Apple 和镜像中现在具有相同的 sha256（`ba12a289…`、`6baa43ed…`、`5ba282fc…`）。
- **测试：** `testFormattedStringTakesTheCurrencyLocaleAndPrecisionFromTheDocument`（`MAD/MADTests/MADDocumentTests.m`，精确字符串）和 `testMoneyIsFormattedFromTheDocumentNotTheMachine`（`Linux/Tests/MADHeadlessDocumentTests.m`，在 GNUstep 上验证相同事实，外加负小数位数守卫）。Linux 导出器套件的三个渲染端校验和现在与 text/csv/json 一样，都是“Mac 的字节”。


### `MADQueryActiveQueryFields`：SELECT 列表的顺序是集合顺序，而集合顺序不稳定
- **状态：** 已修复
- **位置：** `MAD/Source/MADQuerySelectExpressionActiveFields.m`（`MADActiveFieldAlias` 和 `MADActiveFieldsInOrder`），由 `MAD/Source/MADQuerySelectExpressionAllFields.m`（`MADAllFieldsInOrder`）读取
- **行为：** 活动字段被收集到 `NSMutableSet` 中，因此 SELECT 列表的列顺序是哈希顺序。`RptqObject -hash` 是 `identifier ^ entity.hash`（`MAD/Source/rptq/store/RptqObject.m:42`），这让顺序看起来在每次构建中是确定性的——但实际上并非如此：2026-10-16 实测表明，**同一进程中由同一夹具构建的两个文档会以不同顺序枚举相同的两个字段**，而且 Apple 与 GNUstep 之间也不一致（同一个 `.mad` 在 Linux 的 `mad query` 下与在模拟器下给出了不同的顺序）。*字段本身*始终是正确的；只是顺序会变动。行缓存继承了这一顺序：它的列就是按此顺序排列的字段键。
- **为什么重要：** 跨平台（或跨运行）对 `mad query` 输出或 `.maddb` 缓存进行任何字节对比时，都会看到并非源于数据本身的差异——这正是 `MAD_LINUX.md` §9 阶段 D 所要求的对比，也是 JSON 或 CSV 导出原本会继承的问题。一旦按字段名匹配各列，刷新后的**行数据**始终完全相同（已在 London 夹具上验证：21 列，76 行，每个值都相等）。
- **现状：** 顺序被定义为列别名（`Customer0.City`），使用 `-compare:` 比较，使 Apple 和 GNUstep 保持一致。`MADQueryActiveQueryFields` 仍然收集到 `NSSet` 中——对于“哪些字段处于活动状态”而言，集合是恰当的数据结构——而输出 SQL 的两个构建器会对其进行排序：`MADQuerySelectExpressionActiveFields` 按别名排序，`MADQuerySelectExpressionAllFields` 在每个表内按字段名排序。行缓存继承了该顺序（其 `c<hash-of-fieldName>` 列*名*本来就是按字段名生成且跨平台稳定的）。这一变更在 Apple 上是可见的：相同的字段在生成的 SQL 中以新顺序出现，因此变更前刷新的缓存与变更后刷新的缓存其列顺序不同——数据相同，顺序不同。
- **测试：** `MAD/MADTests/MADQuerySelectExpressionTests.m` 及其 Linux 移植版本中的 `testActiveFieldsSelectListIsOrderedByColumnAlias` 和 `testAllFieldsSelectListIsOrderedByFieldName`：各自以两种创建顺序构建相同的字段，并断言得到同一个列表。`testActiveFieldsSelectListContentComesFromTheSet` 保留为内容守卫，以便将未来的*内容*变更与顺序变更区分开来捕获。
- **最终决定：** 用户在 2026-10-16 选择了按别名排序，而非架构快照顺序、查询字段标识符顺序或仅针对导出的顺序，从而使生成的 SQL、行缓存以及所有导出在两个平台上共享同一个明确定义的顺序。记录于 `MAD_CLI.md` §8（JSON 导出结构）。

### 同一文档在 Linux 和 Apple 上不能产出相同的 `.mad`——而且在 Linux 上根本无法写出
- **状态：** 已修复（2026-10-16）：Linux 写入器能够正常结束，可复现模式锁定了归档的输入，两个平台产出的字节完全相等并由测试锁定。
- **位置：** `MAD/Source/MADArchiveManager.m`（`-write_archive:`、成员遍历以及 `backup_file`）、`MAD/Source/madtar.m`（`mad_archive_entry_set_attributes`、`mad_archive_write_file`）、`MAD/Source/MADHeadlessDocument.m`（`-writeToURL:reproducible:error:`），对照 `MAD_FORMAT.md` §7（规范格式）和 §9（验证）。
- **行为：** 2026-10-16 实测。在同一平台上，对成员未发生变化的文档保存两次会产生**不同的字节**：成员内容完全相同（`store.sqlite` 和 `meta.plist` 逐字节相等），但归档不同，因为每个 tar 头部都携带了成员的 mtime——相隔几分钟生成的夹具对在大小上相差 1 字节，且每个目录头部的 mtime/checksum 字段都不同。跨平台时存在差异的输入更多：mtime、文件系统的 **uid/gid/mode**、**成员顺序**（遍历使用的是 `-enumeratorAtURL:...`，顺序取决于枚举器），以及 SQLite 写入器自行决定的任何内容（此处两次保存之间的存储本身*是*逐字节一致的，因此这一层反而不是主要问题）。**在 Linux 上写入器根本无法完成**：`-write_archive:` 将每个枚举出的 URL 向上回溯到正在归档的目录（`while (![baseUrl.lastPathComponent isEqualToString:directoryToArchiveFileName])`），而 GNUstep 的 `-enumeratorAtURL:...` 产出的 URL 剥离了外层目录（见下方条目），因此循环一路回溯到 `/` 并停在那里，每轮分配一个 `NSURL`。512 MB 的容器会杀死进程（SIGKILL）；30 秒超时则会直接耗尽。
- **为什么重要：** 用户在 2026-10-16 提出的需求：*“如果可能的话，我还希望 Linux 和 iOS 产出完全相同的 MAD 文件。”* 这也是让 `.mad` 成为一种*格式*而非单纯转储的关键：`MAD_FORMAT.md` §7 定义了容器，而 `MAD_CLI.md` §6.1 的第一个往返夹具（“解包、重新打包，断言成员列表及每个成员的字节未变”）正是用来守住这一点的测试——此前它还不存在，因此当时只能先通过表征测试锁定。`mad export --deterministic` 标志（`MADCLIPinPDFMetadata`）已经将同样的思路用在了 PDF 上：把时钟和文件系统打上的标记固定住。
- **修复所做的工作（按本条目要求的顺序）：**
  1. **Linux 写入器能够正常结束。** 向上回溯循环已移除：成员通过 `-subpathsAtPath:` 读取，并按其相对于被归档目录的路径命名，因此遍历在任一平台上都不会失控（与 CLI 成员列表所做的修正相同，见 `BUGS.md` 的枚举器条目）。
  2. **归档的输入在特定模式下被锁定。** `MADArchiveManager.reproducible`（与 `-checkpointed` 一样，在 `-archive:` 之前设置）将每个 tar 成员的 uid/gid 设为 0，修改时间设为固定时间 `MADArchiveReproducibleModificationTime`（2001-01-12T00:00:00Z，即 PDF 导出锁定日期所用的同一时刻）且纳秒设为 0，并对成员遍历进行排序；不写入创建时间（birth time）。普通保存保持不变，仍然记录文件系统的元数据。
  3. **对比得以运行并通过。** 同一文档在 Mac 上和在 Linux 镜像中写出的是同一个文件：`mad write CLI/Fixtures/London.portable.mad --out … --reproducible` 在两端均产出 16,243 字节，sha256 为 `22dd3123ea1efe059f298fe39aa54aa3c7dd89aba33cf15870b55b309f9d1848`。这覆盖的是容器层：成员在两端具有相同字节是因为它们来自夹具。未来若有*创建*存储而非重新归档现有存储的写入器，会将同样的对比扩展到存储层；该层的假设（SQLite 可移植，且我们的写入完全一致）目前尚未测试。
- **修复过程中暴露出的一个缺陷。** `backup_file` 将其参数传给 `dirname(3)` 和 `basename(3)`，而标准允许这两个函数修改传入的字符串——glibc 会修改，Apple 不会。在 Linux 上，调用者的归档路径在最后一个斜杠处被截断，导致合成后的文档被写到了它自己的目录上（"Open (/tmp/out) failed - Is a directory"），而不是写成文件。现在每次调用都会获得各自独立的副本。此前无人发觉，是因为在 Linux 上写入器从未走到那一步，而在 Apple 上缓冲区完好无损。
- **测试：** `Linux/Tests/MADArchiveManagerTests.m`（5 个测试，0 个前置需求）提供了覆盖：往返测试（`MAD_CLI.md` §6.1：解包、重新打包、再解包，成员列表及每个成员的字节均未改变）、普通模式的表征测试（陈旧成员会改变字节）、可复现模式（两次写入产出同一个文件，且字节与 Mac 一致——整份文档的 FNV-1a 校验和），以及文档路径（`MADHeadlessDocument -writeToURL:reproducible:error:` 写出副本并保持源文件不变）。在 Apple 上，`MADDocumentTests/testArchiveIsNotReproducibleFromUnchangedMembers` 继续锁定*普通*模式不可复现这一事实——依然成立，因为可复现模式是显式开启的——而 `testArchiveIsReproducibleWithTheModeOn` 则锁定可复现模式本身。

### `objectsForEntity:` 漏掉了每个子实体行
- **状态：** 已修复
- **位置：** `MAD/Source/rptq/store/MADStoreGraph.m`（`-objectsForEntity:`）以及 `MAD/Source/rptq/store/RptqStoreContext.m` 中的注册表查找
- **行为：** 图中的行按其具体种类（`RptqDocumentElementLabel`）作为键存储；单对象查找针对这一点做了表级回退，而多对象查找却只返回精确匹配所请求名称的键下的行。因此 `objectsForEntity:@"RptqDocumentElement"` 什么也不返回，导致四处生产调用点受损：元素 `awakeFromInsert` 的 dropIndex 扫描找不到任何行（每个新元素的 dropIndex 都变成 1，导致 z 序冲突），`nextDropIndexForSection:` 总是返回 0，而两处 `delete*RelatedToTable:` 清理逻辑从未删除任何东西。本应捕获该问题的转换器测试也存在同样的盲区——它的参考获取设置了 `includesSubentities = NO`。
- **现状：** 当所请求的实体拥有自己的表时，两种查找都会应用表级回退，因此基类实体查询会返回共享该表的每个种类的行，而针对特定种类的查询则保持精确匹配。转换器测试的参考获取对拥有表的实体包含了子实体，其总数将每行在各自种类下计入一次，且 `testBaseEntityQueryReturnsRowsOfMixedKinds` 用计数锁定了混合种类查询，因此静默返回空结果的查找无法再通过测试。
- **在存储迁移期间发现。**

### 打开大型报表并刷新时内存飙升至约 8 GB，却始终渲染不出一页
- **状态：** 已修复——2026-10-03 找到根本原因，2026-10-03 修复
- **位置：** 应用在用户的自定义 MySQL 报表上执行打开并刷新：`employees` 数据库，`departments` LEFT OUTER JOIN `dept_emp`——约 331,603 条明细行，按每页约 45 行计算有数千页。两个元素。该文档是旧版 v0 `.mad`（Core Data `analyitics` 存储，打开时转换），在 iPhone 17 模拟器的应用组容器中名为 `Document.mad`。London（5 页）和 Music（3,503 行 / 77 页）都能正常工作，因此该缺陷只在这一报表的规模下才会发作。
- **行为：** 在用户的设备上，打开此报表并刷新会让打印页面渲染器做“各种各样繁重的工作”：内存一路攀升至约 8 GB，而第一页始终渲染不出来。“它根本没走到渲染那一步——处理过程永远跑不完。”症状看似是“绘制了整份报表而不是当前可见页”，但两遍式设计本身在中等规模下是完好的：CLI 导出 Music 时运行相同的 `MADReportFormatter` / `MADPrintPageRenderer`，约 4 秒即可完成 77 页，RSS 约 17 MB。Music 无法触发的是跨越 33.1 万行和约 7,000 页的逐行与逐页累积——格式化器自己的注释（`MADReportFormatter.m:454-459`）就警告过，如果没有逐行的 autoreleasepool，哪怕是“8k 页的报表”也会飙升 100 MB，而这份报表比示例报表大了一个数量级。
- **复现方式：** CLI 现在可以直接针对实机 MySQL 服务器以无头方式驱动用户的实际文档：`CLI/build.sh --run refresh --credentials root:root <copy-of-Document.mad>`，并可用 `--rows N` 限制查询行数。CLI 运行与应用相同的刷新链（`MADOperationRefresh*` 源文件从 `MADDesigner` 编译进 CLI），因此这里的无头失败就是应用的失败。
- **已排除的项**（在分派前对照 `master` 检查）：
  - `MADReportFormatter.m`、`MADViewerController.m`、`MADRefreshOperationReload.m`、`MADReportPageView.m` 与 `master` 零差异；`MADPrintPageRenderer.m` 只是机械性的 4 行键控修改；`MADArrayCaching.m` 和 `MADDataTableFast.m` 的热路径均未改变。
  - 存储查找不是 O(数据量) 的：`objectForEntity:identifier:` 是注册表查找（`RptqStoreContext.m:129-166`），且渲染/设计器路径中每处 `objectsForEntity:` 调用点的规模都受限于文档定义的数量，而非数据行数。
  - 打开时的旧版转换是一次性的（`MADocument.m:515-544`），并非每次打开都执行。
- **根本原因——2026-10-03 发现，待修复。** 对存储支持的对象的每一次属性读取都会分配内存。`-[RptqObject valueForUndefinedKey:]`（`MAD/Source/rptq/store/RptqObject.m:64-93`）先用 `MADStoreAttributeNamed`（在 `entity.allAttributes` 上做线性扫描）再用 `anyRelationshipNamed:`（在 `entity.allRelationships` 上做线性扫描）解析每个键，而且**这两个访问器每次调用都会构建一个新数组**——`-[MADStoreEntity allAttributes]` / `-[MADStoreEntity allRelationships]`（`MAD/Source/rptq/store/MADStoreSchema.m:151-161`）每次调用都通过 `arrayByAddingObjectsFromArray:` 展平继承链。在 Core Data 下，同样的读取只是直接命中实例变量/访问器；而基于存储的属性层却把每次读取变成了一次实体查找、一到两次数组构建，外加逐名称的 `isEqualToString:` 扫描。渲染路径在每一页、每一行、每个元素上读取元素几何信息与文本样式，格式化路径也在每一行读取这些属性——因此在这份报表的规模下（33.1 万行 x 9,475 页），这意味着数以千万计的读取，每一次都在分配内存。已在用户自己的文档上无头复现：对导出过程进行 4 秒 `sample` 采样，2,351 个样本中有 2,343 个落在 `drawPageAtIndex:` -> `drawSection:` -> `RptqGetObject` -> `valueForUndefinedKey:` -> `MADStoreAttributeNamed` -> `-[MADStoreEntity allAttributes]` -> `arrayByAddingObjectsFromArray:` 内部，内存占用大头集中在 **Malloc Small**。（首次测量到的约 5.8 GB 绝对峰值不可信——当时有重叠的孤立导出进程在并发运行——下方 A/B 对比中平稳的约 17 MB RSS 才是真实的单进程数值；调用栈而非那个绝对数字才是证据。）CLI 的渲染循环也没有逐页的 autoreleasepool（`CLI/Source/MADCLIDocument.m:260-263`），因此查找产生的垃圾会跨越全部 9,475 页一路累积到循环结束。在设备上，同一条内存曲线会撞上内存上限（约 8 GB），导致第一页永远无法渲染出来。
- **修复方案。** 对架构查找做记忆化（memoize）：按实体缓存展平后的 `allAttributes` / `allRelationships`（架构构建完成后计算一次），并将 `RptqObject` 中线性的 `MADStoreAttributeNamed` / `anyRelationshipNamed:` 扫描替换为按实体缓存的“名称->描述符”字典，使属性读取变成一次字典命中且零内存分配。将 CLI 的逐页渲染主体包裹在 `@autoreleasepool` 中，使任何残留垃圾都限制在单页范围内。行为不得改变；使用现有测试套件外加下方的无头导出进行验证，其峰值 RSS 必须从约 5.8 GB 降至几百 MB。
- **现状：** 展平后的数组已按实体记忆化，并在架构构造结束时预热一次（此后描述符不可变），且 `RptqObject` 属性层中的名称查找已改为按实体缓存的字典——一次属性读取就是一次字典命中，不分配任何内存。首次匹配顺序、属性优先于关系的优先级，以及通过 `NSObject` 抛出的未知键异常均得以保留，并由 `testSchemaFlattenedArraysAreMemoizedAndStable` 和 `testRptqObjectKVCSemanticsAreUnchanged` 锁定。CLI 的逐页渲染主体已包裹在 `@autoreleasepool` 中。
- **实测（A/B 对比，同一文档，相同输出 9,196,432 字节 / 9,475 页）：** `master` 基线为 32 秒 / 17 MB RSS；修复前的分支为 89 秒 / 17 MB RSS；修复后的分支为 63 秒 / 17 MB RSS。在这台机器上，三者的 RSS 都保持平稳（CLI 自身的自动释放池限制了它；早先的 5.8 GB 采样未在此复现），时间上的改进是实实在在的，但与 `master` 相比仍有约 2 倍的差距：剩余开销来自存储层常数因子的读取路径（采样结果：`valueForUndefinedKey:` -> 两次字典命中、注册表惰性加载，以及选择器名称字符串），现在全部为 O(1) 且零内存分配，修复方案有意不再进一步深入。Music 仍作为对照（77 页 / 约 4-6 秒 / 约 17 MB），London 仍为 5 页。
- **违反的规则：** `RptqObject` 上的属性读取必须是零内存分配的；属性层位于渲染和格式化的热路径上。
- **复现方式（回归守卫）：** `CLI/build.sh --run export --credentials root:root --out /tmp/employees.pdf <copy-of-Document.mad>`——9,475 页 / 9,196,432 字节。需要 MySQL 服务器可达；文档位于 iPhone 17 模拟器的应用组容器中，名为 `Document.mad`（MySQL，`employees`，`departments` LEFT OUTER JOIN `dept_emp`，两个元素）。

### 页面绘制为每个单元格运行一次 SQLite 事务，因此打开大型报表会让 CPU 满载
- **状态：** 已修复
- **现状：** `MADDataTableFast` 按列缓存预编译的 select 语句
  （`-selectStatementForColumn:database:error:`，以列名为键；SQL
  为 `WHERE rowid = ?`，每次调用绑定、单步执行、重置并清除
  绑定，因此一条语句服务于每一行）。当单步执行遇到 `SQLITE_SCHEMA` 时，
  会重新预编译一次并重试——之前按调用预编译的代码从不会看到陈旧的
  语句，缓存后的语句同样不能看到——并且当重新打开连接、添加列或释放表时，
  缓存会被终结（finalize）。select 连接（绝不是写入连接）上的
  `-beginReadTransaction` / `-commitReadTransaction` 包裹了
  `MADPrintPageRenderer -drawPageAtIndex:withContext:inPageRect:`，因此一页的
  单元格读取共享同一个事务。实测：应用打开时的首页绘制从 100% CPU 下耗时约 25 s
  降至启动、打开和绘制合计约 2 s CPU 时间（随后进程立即空闲；已在 iPhone 17
  模拟器中通过启动钩子验证）。CLI 导出耗时从 58 s 降至 52 s
  （9,196,432 字节 / 9,475 页保持不变）；对导出绘制循环进行 25 s 采样显示，
  `sqlite3BtreeBeginTrans` 为零次，整个 `dataForRow:column:` 调用链在 10,151 个样本中占 255 个——
  剩余的 CLI 时间消耗在存储上下文 KVC 绘制路径和 Core Text 字形绘制上，而非本缺陷。
  四个新的 `MADDataTableRegressionTests` 锁定了重复读取的一致性、中间写入后的最新值
  （同一张表以及通过同一缓存文件上的平级表），以及表重建后的读取。
- **位置：** `MADSqlite3/Source/MADDataTableFast.m:981`
  （`-dataForRow:column:error:` 每次都预编译一条新语句并在自动提交模式下恰好单步执行一次，
  因此每次单元格读取都会运行一次隐式的
  begin/journal-stat/lock/commit）。调用者是逐单元格调用的：
  `MAD/Source/MADPrintPageElement.m:80-84`
  （`MADPrintPageElementTextDynamic -initWithDefinition:` 每次实例化元素时都会向数据源请求行值——
  动态的数据绑定元素没有固化在布局缓存中的值），从主线程上的
  `MADReportPageView -drawRect:` 到达此处。
- **行为：** 在应用中打开用户的大型报表时，在任何刷新之前，仅绘制单页就会让 CPU 在 100% 下满载约 25 s，
  RSS 达约 900 MB——已在模拟器中复现并采样：全部 2,908 个样本都落在同一个
  `drawRect:` -> `drawPageAtIndex:` -> `drawSection:` ->
  `newDocumentObject:` -> `dataForRow:column:error:` -> `sqlite3_step` ->
  `sqlite3BtreeBeginTrans` -> `lockBtree` -> 逐单元格日志 `stat()` /
  `fcntl()` 锁中。查看器在每次刷新后都会重绘最后一页，因此同样的风暴正是“点击刷新时一切都卡死”的症状，
  这也是为什么五页的报表看起来正常而这份报表却不正常：开销随所绘制的单元格数量线性增长，
  而与小型示例所覆盖的部分无关。
- **原有问题还是新问题？** 调用模式与 `master` 相比零差异
  （渲染器和 `MADDataTableFast` 均未更改），因此 master 的应用同样付出逐单元格事务的代价；
  只是这份报表的规模（9,475 页、两个动态字段、33.1 万行）从未在旧应用中打开过，
  因此没有这一规模下“以前能正常工作”的测量数据。无论如何，它现在都是一个现实缺陷：
  该设计的初衷是从隐藏的 Sqlite3 缓存中进行快速页面扫描，而每个单元格一次事务彻底挫败了这一初衷。
- **修复形态。** 在风暴所在的两个位置让逐单元格读取变得廉价，且不改变任何结果：
  (1) 在 `MADDataTableFast` 中按列缓存预编译的 select 语句（预编译一次；每次调用绑定、单步执行、重置），
  以及 (2) 在 select 连接上将每次页面绘制包裹在单个读事务中（绘制前 begin，绘制后 commit），
  从而把逐单元格的隐式事务折叠为一个。CLI 导出走的是同一条
  `drawPageAtIndex:` 路径，因此其挂钟时间（查找修复后为 59 s）可作为回归守卫，且应当大幅下降。
- **违反的规则：** 渲染路径绝不能为每个单元格运行一次 SQLite 事务；页面绘制是应用最热的循环。
- **复现：** 在 iPhone 17 模拟器中安装 DEBUG 应用，使用
  `-UITestOpenSample Document -UITestSelectTab Viewer` 启动，观察主线程以 100% CPU 绘制最后一页；
  或者在 CPU 满载期间对应用进程执行 `sample`（上面的调用栈正来自该采样）。

### `insertObjectForEntity:` 按实体而非按表生成标识符
- **状态：** 已修复
- **现状：** `RptqStoreContext -insertObjectForEntity:identifier:` 在表的属主实体上生成标识符——
  当所请求的实体是共享父表的子实体时为 `descriptor.parentName`，否则为所请求的实体本身——
  其 `objectsForEntity:` 表回退会返回该表中的每一种类型，因此新建的
  `RptqDocumentElementLabel` 会在任意元素类型的最后一行之后顺延编号。
  `RptqStoreContextTests` 中有两个回归测试：在持有标识符 5 的标签之后以 0 插入图表时，
  返回的图表标识符大于 5（且不等于 5）；而属主实体插入（`RptqDatabaseSchemaField`）
  仍然在其自身表的最大值之后生成标识符。两个测试套件均通过。
- **位置：** `MAD/Source/rptq/store/RptqStoreContext.m:183-188` —— 当标识符为 0 时，
  新标识符是所请求实体的最大值加一。九种 `RptqDocumentElement*` 类型共享同一张带有
  `identifier INTEGER PRIMARY KEY` 的表（`MADStoreSchema.m:841`），而工厂方法使用具体类型名称进行插入，
  因此新建的 `RptqDocumentElementLabel` 仅在最后一个*标签*之后顺延编号。
  如果任何其他类型已经占用了下一个整数（旧存储为整个继承层次共用一张表，因此转换后的标识符在不同类型间交错），
  生成的标识符就会与现有行冲突——而表级主键会将该冲突变成写入失败或替换现有行。
- **变化原因：** 在 Core Data 下，`identifier` 是具有按类获取语义的索引属性
  （跨类型的重复是合法且无害的）；可移植存储将其变成了表主键，而里程碑 (a) 的标识符生成逻辑
  （`RptqDataHelper nextIdentifierForClass:` 的替代实现）没有计入这一新约束。
- **修复形态。** 在表属主上生成标识符：当所请求的实体不拥有其表时，在*属主*实体的
  `objectsForEntity:`（其表回退会返回共享该表的每一种类型）上计算最大值，然后再加一。
  添加回归测试：持有标识符为 5 的文本字段的上下文以标识符 0 插入新标签时，该标签的标识符必须大于 5。
- **违反的规则：** 在可移植存储中，标识符是表主键；分配必须按表进行，而非按实体进行。

### 里程碑 (a) 的模型重写丢弃了架构排序顺序
- **状态：** 已修复
- **现状：** `MADModelTable -update` 在构建模型对象之前按 `name` 升序对架构字段排序，
  `MADModelDatabase -updateTables` 在构建模型对象之前按 `name` 升序对架构表排序——
  与迁移前的获取操作所使用的 `NSSortDescriptor initWithKey:ascending:` 相同。
  `MADDocumentTests testModelDatabaseSortsTablesAndFieldsByName` 以乱序名称插入表和字段，
  并锁定投影后的顺序（测试通过）。
- **位置：** `MAD/Source/model/MADModelTable.m`（`-update`）和
  `MAD/Source/model/MADModelDatabase.m`（`-updateTables`）
- **行为：** 在迁移之前，这两处投影获取都按 `name` 升序排序；存储重写后保留了插入顺序。
  模型的字段和表顺序会提供给示例数据表以及 SQL/架构显示路径，因此即使其他一切未变，可见顺序也可能发生改变。
- **修复形态。** 在构建模型对象之前恢复这两处排序——各用一个比较器。

### 从源数据库读出的 NULL 打印为文本 `<null>`，或打印为纪元时间
- **状态：** 已修复
- **位置：** 产生处为
  `MAD/Source/rptq/RptqDocumentElement+Extras.m:973`
  （`-formattedString:forValue:`）。试图撤销该结果的四个调用者为
  `MAD/Source/MADDocumentObjectDataReference.m:185`、`:270` 以及
  `MAD/Source/MADDocumentObjectDataReferenceBarcode.m:59`、`:66`。
- **行为：** 该方法开头是 `if (!value) return @"";`，这能捕获 `nil`，
  但捕获不到 `[NSNull null]` —— `NSNull` 是对象，在布尔判断中为真。从源数据库读出的 NULL
  会作为 `NSNull` 到达（关于为何有意采用这种表示，见下文 `MADQueryCacheSelectGroupKeys` 条目），
  因此它会落入下面的各个分支。那里的每条文本路径最后都是 `-initWithFormat:@"%@", value`，而
  `[NSNull description]` 是 `"<null>"` —— 带尖括号。日期分支更糟：
  `NSNull` 既不是 `NSData`、也不是 `NSString`、更不是 `NSNumber`，因此时间间隔默认为 0，
  NULL 日期被打印成了纪元时间 1970-01-01。
- **为何重要：** 数据中的 NULL 在打印出的报表上会变成可见的 `<null>`，
  而 NULL 日期则会变成看起来像真的一样的错误日期。原本预期的守卫从未生效：
  四个调用者将结果与 `MTNullIdentifier` 比较，而后者被声明为
  `@"(null)"` —— *圆括号*，即 nil 指针的格式化方式，而非 `NSNull` 的格式化方式。
  两个字符串不同，因此 `-isEqualToString:` 始终为假。该常量从写下的那天起就是死代码，
  唯一可能匹配它的值是数据中真正拼写为 `(null)` 的文本，而这样的文本反而会被清空。
- **现状：** 守卫同时覆盖两种情况 —— `if (!value || [value isKindOfClass:[NSNull
  class]])` —— 因此 NULL 在进入格式化器时即为空字符串。那四处比较和该常量也随之移除：
  `MTNullIdentifier` 已从 `MAD/Source/rptq/autogen/RptqDocumentElement.h:24` 及 `.m` 的 `:15` 中删除。
  之所以将它们删除而非保留，是因为它们不仅在本次修改后不可达——在修改前就已经不可达了，
  保留对一个没有任何代码会产生的值的比较，只会误导下一位读者以为这个往返转换仍在生效。
- **备注：** `MAD/Source/rptq/autogen/` 存放的是 Xcode 生成的 Core Data 子类代码，
  此处已手动编辑；构建过程中没有任何步骤会重新生成它，因此该删除操作得以保留。
- **测试：** `MADTests MADDocumentTests testFormattedStringRendersNullAsEmpty`。它断言
  `NSNull` 对于字符串、整数、日期和日期时间都格式化为空字符串，`nil` 依然如此，而真实值仍然正常格式化。
  针对旧守卫运行该测试时会在四个方面失败，失败文本正是上文所述的证据：
  字符串和整数情形下为 `("<null>") is not equal to ("")`，日期时间情形下为
  `("12/31/69, 7:00 PM") is not equal to ("")` —— 即美东时区的纪元时间，对应 1970-01-01 UTC。

### `MADSectionLayout` 不计算任何元素高度，因此报表会堆积在最初的几页上
- **状态：** 已修复 —— 2026-10-03 发现，从随附的示例报表中复现
- **位置：** `MAD/Source/MADSectionLayout.m:63-65`（桩代码）。由
  `MAD/Source/MADReportFormatter.m:517`、`:522`、`:580-594`、`:626` 消费。
- **行为：** `-initWithObject:managedObjectContext:` 过去会将 `_displayHeight`
  设为 **section 内元素的最大计算高度** —— 对每个元素而言，即
  `rect.origin.y + rect.size.height + margin.top + margin.bottom + padding.top +
  padding.bottom + border.width.top + border.width.bottom`，由 Core Data
  投影 `RptqDocumentElement +fetchRequestSectionHeight:` 计算得出。注意旧代码*没有*做的事：
  `_displayHeight` 从零开始，section 自身声明的 `height` 从不参与计算。
  该投影随存储迁移一同移除，并被替换为 `_displayHeight = _visibility ? _height : 0.0000f` ——
  即声明的高度，一个旧代码从未用于此目的的值。`displayHeight` 是
  `MADReportFormatter` 累加到 `cumulativePageHeight` 中以放置下一个 section 并决定分页的依据，
  因此各个 section 现在推进的偏移量有误并发生重叠。
- **为何重要：** 每一份渲染出的报表都会分页错误，而声明高度为零的 section 会完全坍缩到它起始所在的页面上。
  通过 CLI 对 London 示例进行实测：迁移前为 5 页 / 43,177 字节 /
  638 个文本字符串；迁移后为 3 页 / 40,547 字节 / 636 个。相差的两个字符串是页面页眉，
  因为页数变少而重复次数减少；其余内容完好无损，但全都挤在了三页而非五页上。
  用户可见的表现就是“所有内容都打印在第一页上”。
- **复现：** `CLI/build.sh --run export --out /tmp/london.pdf
  MADDesigner/Resources/Assets/Samples.xcassets/Reports/London.dataset/London.mad`
  —— 迁移前 5 页，迁移后 3 页。CLI 走的是与应用相同的
  `MADReportFormatter`，因此可作为该修复的无头检查。
- **现状：** 在同一个初始化器中针对存储恢复了该计算：section 通过
  `objectForEntity:@"RptqDocumentSection" identifier:` 解析，在 `hasRows` / `hasObjects`
  上遍历其元素，`_displayHeight` 取
  `rect.origin.y + rect.size.height + margin.top + margin.bottom +
  padding.top + padding.bottom + border.width.top + border.width.bottom` 的最大值，
  其中缺失的边距贡献 0；不可见的 section 与之前完全一样为 0。桩代码及其“临时替代直至……”的注释已移除。
  London 导出恢复为 5 页 / 43,177 字节。由
  `testSectionDisplayHeightIsTheMaximumElementCalculatedHeight`
  （验证求和、较矮元素之上的最大值，以及所有可选边距均缺失的元素）和 CLI 导出本身共同锁定。
  顺带地，元素的 `awakeFromInsert` 补回了 Core Data 版本会创建但存储版本曾漏掉的四个附属对象
  （alignment、border、dropPoint、numericFormat），测试中的边框边距立即暴露了这一遗漏。

### `MADocument -managedObjectContext` 以 Core Data 类型返回 `RptqStoreContext`
- **状态：** 已修复 —— 2026-10-06，阶段 D。
- **位置：** `MAD/Source/MADocument.h`（其中将 `managedObjectContext` 声明为
  `RptqStoreContext *`，紧挨着它所返回的 `storeContext`）。
- **行为：** `managedObjectContext` 过去作为 `NSManagedObjectContext` 从 `UIManagedDocument` 继承，
  而重写方法返回的却是存储上下文 —— 这是一个编译器无法检查的类型谎言。现在超类是 `UIDocument`，
  它没有这个属性：`MADocument` 自己将该属性声明为 `RptqStoreContext *` 并返回 `self.storeContext`，
  因此每个调用点都针对真实类型进行编译（`CLI/Source/MADCLIQuery.m` 中的不兼容指针警告也随之消失）。

### `MADReportTextRepresentation` 的 `-characterCount` / `-elementCount` 在非空输入上崩溃
- **状态：** 已修复
- **位置：** `MAD/Source/MADReportTextRepresentation.m:64` 和 `:76`
- **行为：** 两个方法都直接对页面映射表进行快速枚举，这产生的是
  `NSNumber *` **键**而非页面值。非空的表示会抛出“unrecognized selector”异常。
- **为何重要：** 这些是文本导出 / 字符计数路径，TODO.md 中的文本/JSON 导出工作将会覆盖到它们。
- **现状：** 两者都改为遍历 `self.pages.allValues`，因此每个元素都是循环变量所声明的
  `MADReportPageRepresentation`。该类还补上了此前通过传递性头文件间接引入以使用 `-allValues` 的
  `#import <Foundation/NSArray.h>`。`testTextRepresentationCountsSumPageValues`（由
  `testTextRepresentationCountsEnumerateKeysDefect` 重命名而来）现在断言计数值，而非断言抛出异常。

### `RptqDirectionalAsymmetry +keyRight` 返回 `@"left"`
- **状态：** 已修复
- **位置：** `MAD/Source/rptq/RptqDirectionalAsymmetry+Extras.m:18`
- **行为：** `keyRight` 委托给了 `keyLeft`，返回 `@"left"` 而非 `@"right"`。
- **为何重要：** 影响范围比早先“在右边缘读写了错误键”的说法要小。所有现存的右边缘访问都走真实的
  Core Data 属性（`MADDesignerLayout.m:368,456,544`；
  `RptqDocumentElement+Extras.m:751,769,792`），而非这些键构建器。那六个折叠键构建器仅被
  `+fetchRequestElementsInSectionDetailed:` 消费，而该方法**没有调用者** —— 它会把重复的键路径放进
  `propertiesToFetch`。因此该缺陷是真实的，但目前不可达。由 `MADRptqValueTypeTests.m:99-100` 锁定。
- **现状：** `keyRight` 返回 `[RptqDirectionalProperty keyRight]`，与各自返回自身键的三个同级访问器保持一致。
  `testDirectionalAsymmetryKeyConstants` 现在在过去锁定 `@"left"` 的地方断言 `@"right"`。

### `MADDatabaseTypeReuseIds`（10）与 `MADDatabaseTypeNames`（9）数量不匹配
- **状态：** 已修复
- **位置：** `MAD/Source/rptq/RptqDatabase+Extras.h:17`
- **行为：** 复用 ID 表比本地化名称表多一个条目，因此“Microsoft SQL Server”缺少名称，
  且两张表在索引 4 之后错位。
- **为何重要：** 新建文档的数据库类型选择器很可能同步遍历这两个数组；此处差一错误可能会选错驱动。
- **现状：** `MADDatabaseTypeNames` 在索引 5 处补上了缺失的 `@"Microsoft SQL Server"`，
  因此两张表都有十个条目并对齐。只有“None”包裹在 `NSLocalizedString` 中；其余保持字面量属于翻译任务，
  不属于本缺陷的一部分。`testDatabaseTypeReuseIdsAndNamesAlign`（由
  `testDatabaseTypeReuseIdsAndNamesMismatch` 重命名而来）断言两个计数一致并锁定索引 5。

### `MADDataTableFast -allObjects` 未实现（FIXME）
- **状态：** 已修复
- **提交：** `f25b53118`
- **位置：** `MAD/MADTests/MADDataTableRegressionTests.m`
- **行为：** 即使存在行，该方法也从头文件声明为 `nonnull` 的方法中返回 `nil`。
  现在它通过 `-objectAtRow:limit:` 返回所有行，对没有列的表则返回 `@[]`。
- **为何重要：** 目前没有生产环境调用者，因此该标注是留给下一个调用者的陷阱，而非现存崩溃。
  原先锁定 `nil` 的测试已被 `testFastTableBulkInsertAllObjectsReturnsEveryRow` 和
  `testFastTableAllObjectsIsEmptyWhenThereAreNoRows` 取代。

### `MADQueryPredicate` 和 `MADQueryCacheSelectGroupKeys` 用双引号引用字符串字面量
- **状态：** 已修复
- **提交：** `0c187aca3`
- **位置：** `MAD/Source/MADQueryPredicate.m:80-88`。钩子位于
  `MADAPI/Source/MADDatabaseSQLProtocol.h`（`-newSafeLiteral:`），基类实现位于
  `MADAPI/Source/MADDatabase.m`，重写位于
  `MADTdsClient/Source/MADDatabaseSQLServer.m` 和
  `MADMySQL/Source/MADDatabaseMySQL.m`。分组键构建器
  `MAD/Source/MADQueryCacheSelectGroupKeys.m` 在历史记录中保留了旧形式，现在也通过同一个钩子处理 ——
  见下文*现状（此前留开的另外两处）*。
- **行为：** 谓词的右操作数过去输出为 `"<value>"`：
  `[[NSString alloc] initWithFormat: @"\"%@\"", rightFieldID]`，而分组键构建器则写入
  `[sqlPredicate appendFormat:@"%@ = \"%@\"", left, right]`。两者都用双引号包裹*值*。
  两者都没有对其进行转义，也没有进行参数绑定。生成的 SQL 形如 `("Customer0"."City" = "London")`。
- **为何重要：** 根据 SQL 标准，双引号引起来的词法单元是*标识符*，
  因此这些字面量过去之所以能工作，仅仅是因为 SQLite 对此较为宽容。
  如今在 `Compressor/sqlite3.xcconfig`（提交 `26ca18ff7`）中锁定的 `SQLITE_DQS=0` 关闭了这种宽容，
  `sqlite3_prepare_v2` 随之失败并报错：
  *no such column: "London" — should this be a string literal in single-quotes?*。
  所有带筛选条件的报表刷新结果都是零行。在示例文档上实测，当其他一切不变、仅将 `DQS` 设回 3 时，
  `London.mad` 从 0 行恢复到了 76 行。这正是 `## MADSqlite3` 下 `DQS=0` 条目当初打算评估却随后排除掉的风险。
  除了 SQLite 之外还有两个后果。包含 `'` 或 `"` 的值最好情况下是语法错误，最坏情况下则是注入漏洞，
  因为没有任何转义。而且默认开启 `QUOTED_IDENTIFIER` 的 SQL Server 会将这些相同的词法单元解读为标识符 ——
  因此 `Document22.mad`（SQL Server、方括号引用、AdventureWorksLT）一旦带上筛选条件就会以同样的方式失败。
  MySQL 默认不受影响，会将 `"…"` 读作字符串，这也正是该缺陷在所测试的那个后端中隐藏起来的原因。
- **现状：** 值通过 `-newSafeLiteral:` 处理，针对当前使用的数据库进行引用和转义 ——
  在 `MADDatabaseSQLProtocol` 中紧挨着 `-newSafeIdentifier:` 声明，在 `MADDatabase` 上统一实现为将内部引号双写的
  ANSI `'…'` 形式，并在 `MADDatabaseSQLServer` 上重写以添加 T-SQL 的 `N` 前缀（没有该前缀时字面量为 varchar，
  非 ASCII 值会受数据库排序规则影响）。SQLite 和 MySQL 直接继承基类而不做重写：两者都将双写的内部引号读作单个引号，
  且都不赋予字面量内的反斜杠特殊含义，因此 ANSI 形式就已经是它们的转义形式。`London.mad` 重新刷新出 76 行，
  生成的谓词为 `("Customer0"."City" = 'London')`。过去把表名手动拼接进 `OBJECT_ID('%@')` 的 SQL Server
  架构查找也改走同一个钩子；此前表名中的单引号会提前结束字面量，并把表名的剩余部分留作 SQL 代码。
- **现状（此前留开的另外两处）：** 两处均已修复。
  `MADQueryCacheSelectGroupKeys` 采纳了 `MADQueryDatabaseProtocol`，因此
  `-[MADQuery getSql:database:error:]` —— 每个驱动（包括 `MADDatabaseSqlite3.m:591`）所使用的入口 ——
  会将即将针对其运行的数据库交给它。谓词不再在尚无数据库存在的初始化器中组装；
  `-whereClauseQuotedByDatabase:` 用 `-newSafeIdentifier:` 引用列名，用 `-newSafeLiteral:` 引用值，
  列名和表名也采用同一种方言。当未注入数据库时 —— 即普通的 `-getSql:` 入口 —— 它使用
  `MADDatabaseSqlite3` 进行引用，因为该查询只会针对文档的 Sqlite3 缓存运行；它所构建的排序描述本就是 Sqlite3 的。
  该类目前依然不可达：只有 `-initWithQueryType:MADQueryTypeCacheSelectGroupKeys` 会构建它，而没有调用者传入该类型，
  现存的分组键路径是 `MADQuerySelectItemsForGroup`，其 `-whereClauseWithParameters:`
  （`MADSqlite3/Source/MADQuery+Sqlite3.m`）绑定的是 `?`。仔细阅读该类时还顺带发现了两个小缺陷。
  没有谓词的语句过去会生成 `… FROM "Customer"  WHERE  ORDER BY …` 这样的语法错误，现在则完全不生成该子句。
  另外，`NULL` 项过去被写作 `"<null>"` —— 即对 `NSNull` 调用 `-appendFormat:` ——
  这会变成一个不匹配任何内容的字符串字面量；现在它输出为关键字。（缓存中的 `NSNull` 是有意为之的：
  从源数据库读出的 NULL 存为 `NSNull` 而非 `nil`，以便在将列值解包为 `NSObject` 时永远不会遇到 `nil`。
  这不是缺陷，也不应被“修复”。）
  另一处是 MySQL 的反斜杠，它需要驱动此前并未保留的活动连接。见 `## MADMySQL` 条目
  *MySQL 字面量中的反斜杠是转义字符*。
- **测试：** `MADAPITests testNewSafeLiteralQuotesAndEscapes` 和
  `testNewSafeLiteralNilIsNull`；`MADTdsClientTests testNewSafeLiteralIsANvarcharLiteral`；
  以及 `MADSqlite3Tests testNewSafeLiteralProducesAValueSQLiteWillRead`，后者将一个包含引号的值放入真实查询中，
  针对随附的 `DQS=0` 构建运行，因此未加引号或用双引号引用的字面量会在测试套件中失败。最后一个测试在保留前已确认针对旧行为会失败。
  针对分组键构建器，有 `MADTests MADCoreLogicTests`：
  `testGroupKeysQuotesTheValueAsALiteralNotAsAName`、
  `testGroupKeysQuotesColumnAndTableAsIdentifiers`、
  `testGroupKeysWithoutPredicatesLeavesOutTheWhereClause`、
  `testGroupKeysWritesNullAsAKeyword` 和
  `testGroupKeysEscapesAnApostropheInTheValue`。这五个测试均针对 `c2be14442` 时的
  `MADQueryCacheSelectGroupKeys.m` 运行过且全部失败，每次失败都会打印出旧 SQL —— 包括
  `… FROM Customer  WHERE  ORDER BY …` 和 `= "<null>"`。

### `MADocument -paperSize` 读取的是惰性 `-paper` 访问器构建的 `_paper` 实例变量
- **状态：** 已修复
- **位置：** `MAD/Source/MADocument.m`；访问器是同一文件中的 `-paper`
- **行为：** `- (CGSize)paperSize { return _paper.paperSize; }` 直接读取了实例变量，
  但 `_paper` 在有代码调用惰性 `-paper` 访问器（它根据 `activeDocumentModel.paperType` 构建该实例变量）之前始终为 nil。
  如果先询问 `-paperSize`，它会返回 `{0, 0}`。
- **为何重要：** `-format` 和 `-formatContentChange` 都会把 `self.paperSize` 传给报表格式化器，
  而零尺寸布局会使 `PrintableHeightForPage` 变为负数，导致格式化器在每一行都开启新的一页。
  应用程序之所以从未遇到该问题，是因为其查看器在打开文档时会触碰 `paper`。第二个调用者 —— CLI ——
  在学会先访问 `document.paper` 之前，为 3503 行生成了 11602 页。
- **现状：** `-paperSize` 读取 `self.paper` 而非 `_paper`，因此它会像其他任何调用者一样构建纸张对象。
  CLI 中的变通代码 —— `CLI/Source/MADCLIDocument.m` 中的 `(void)document.paper;` 及其指向此处的注释 —— 已移除。
  通过 CLI 验证：Music（3503 行）从 11602 页变为 77 页；London（76 行）为 5 页。
- **测试：** `MADTestsMADDocumentTests testPaperSizeBuildsThePaperItself`，它给文档提供一个
  `papersize` 为 letter 的模型，并断言 `-paperSize` 非零、与 `-paper` 一致且等于 letter 尺寸。
  在保留该测试前已确认它针对直接读取实例变量的旧代码会失败。

### `MTPaper -initWithType:` 对 Legal 和 Government 纸张返回了类对象
- **状态：** 已修复
- **位置：** `MAD/Source/paper/MTPaper.m`；工厂方法中的 `MTPaperLegal`、
  `MTPaperGovernemntLetter` 和 `MTPaperGovernemntLegal` 分支
- **行为：** `result = [MTPaperLegal init]`（以及两个 Government 同级分支）向类对象发送了 `init`，
  而非 `[[MTPaperLegal alloc] init]`，因此工厂方法返回了类本身。纸张设为 Legal、
  Government-Letter 或 Government-Legal 的文档随后会将该类存入 `MADocument -paper`，
  第一次读取 `-paperSize` 时便因 unrecognized selector 而崩溃。（子类头文件中拼写正确的
  `MTPaperGovernmentLetter` 和 `MTPaperGovernmentLegal` 接口根本从未实现过 —— `.m`
  文件实现的是拼写错误的名称。）
- **为何重要：** 设为这三种纸张类型之一的 `.mad` 文档无法打开。
- **现状：** `MTPaper` 简化为带有静态尺寸表的单一类。`-initWithType:` 存储经过验证的类型，
  并对未知类型返回 Letter 尺寸。Legal/Government 分支、拼写错误的类以及 72 个样板子类文件均已移除；
  所有 37 种持久化的纸张类型仍然通过 `+sizeForType:` 返回其原有尺寸。
- **测试：** `MADTests MTPaperTests testEveryKnownTypeBuildsItsPaperAndSize`（锁定每种持久化纸张类型的尺寸）以及
  `testUnknownTypeFallsBackToLetter`。

### `MADArchiveManager -archive:` 在能够恢复之前就删除了自己的备份
- **状态：** 已修复
- **位置：** `MAD/Source/MADArchiveManager.m`
- **行为：** 保存路径的故障恢复中存在两个缺陷。前一个归档的备份（以 `~` 后缀写在归档文件旁）在代码决定是否需要它*之前*就被删掉了，
  而且恢复守卫写成了 `if (!success && access(backup_path, F_OK))` —— 当文件存在时 `access` 返回 0，
  因此该守卫恰恰在备份**不存在**时为真。于是中途失败的写入永远无法恢复先前的文档；它会留下被截断或缺失的归档。
- **为何重要：** 保存失败正是数据损坏缺陷不可恢复的地方，而恢复逻辑存在的唯一目的就是防止这种情况。
  两个缺陷叠加在一起使恢复操作变成了空操作。
- **现状：** `mad_file_remove_if_exist(backup_path)` 在恢复*之后*运行，且守卫改为
  `access(backup_path, F_OK) == 0`，因此当且仅当备份存在时才会放回先前的归档。首次保存（没有先前的归档）不会产生备份，
  守卫会正确地跳过恢复。
- **测试：** 成功路径由 `MADDocumentTests testArchiveRoundTripWritesAndStripsTheV1Header` 锁定。
  恢复路径通过逻辑推导而非故障注入测试验证：在测试装置中强行让 `write_archive` 失败不值得专门搭建那套机制。

### MADocument 以 nil 内容调用 writeContents:
- **状态：** 已修复 —— 2026-10-04，阶段 D（`2bf9af919`），在本轮审视之前已修复。
- **问题：** `saveToURL:forSaveOperation:completionHandler:` 向参数声明为非空的
  `-writeContents:andAttributes:safelyToURL:forSaveOperation:error:` 传递了 `nil` 作为内容和属性（`:598`，以及 `:624`）。
  重写 `contentsForType:error:` 返回 nil 是有意为之的，因为可移植存储会自行写入，因此该调用与设计是一致的 ——
  但编译器指出这违反了 API 自身的契约，这一点也没错。
- **现状：** 保存路径不再调用 `-writeContents:andAttributes:safelyToURL:…`：
  `-saveToURL:forSaveOperation:completionHandler:` 和 `-closeWithCompletionHandler:` 直接调用
  `-writeStoreAndArchiveWithError:`。两个 `writeContents:` 重写 —— 它们忽略传入的内容并返回同一次存储写入的结果 ——
  仍为 UIDocument 自身的机制保留，后者会用自己构建的文件包装器内容来调用它们。分析器在这两处的
  `nullability.NullPassedToNonnull` 报告也随这些调用的移除而消失。
- **位置：** `MAD/Source/MADocument.m:594-630`。
- **锁定依据：** 无需专门锁定 —— 缺陷在于生产路径传入了 nil，而该路径已不复存在。直接以 nil 调用
  `-writeContents:` 的测试（`MADDocumentTests`、`MADOperationDocumentCloseDocumentTests`）测试的是重写方法本身，
  其 `id` 参数在头文件中没有自己的可空性标注。

### UIManagedDocument 的 resetPersistentStore 已声明却从未实现
- **状态：** 已修复 —— 2026-10-06，阶段 D。该声明随分类重命名为 `UIDocument (Extras)`
  （`UIDocument+Extras.h`）一同移除；现在代码树中任何地方都没有 `resetPersistentStore`，
  因此 unrecognized-selector 风险已消除。
- **问题：** `-resetPersistentStore` 在 `UIManagedDocument (Extras)` 分类
  （`UIManagedDocument+Extras.h:16`）中声明但没有实现；实现文件中唯一的引用是一处被注释掉的调用。
  将来任何调用都会导致 `unrecognized selector` 崩溃。

### MADModelQuery 可能把 nil 表插入其字典
- **状态：** 已修复
- **问题：** `[_tables setObject:queryTable forKey:qtidn]`（`:301`）假定 `queryTable` 已在循环前部（`:289`）构建，
  但该赋值仅在 `resultCounter == 0` 时发生，因此带着未设置的 `queryTable` 到达 `:301` 的路径会向
  `setObject:forKey:` 发送 nil，从而抛出异常。
- **位置：** `MAD/Source/model/MADModelQuery.m:285-302`。
- **证据：** `xcodebuild analyze` 报告的 `osx.cocoa.NilArg`。
- **现状：** 投影筛选条件不匹配任何行的表 ID 会在构建任何对象之前被跳过，因此永远不会带着未设置的
  `queryTable` 到达注册步骤（也不会有陈旧的标识符加入 `_queryTableIDs`）。
- **锁定依据：** 修改文件后在 MAD scheme 上重新运行 `xcodebuild analyze`：
  MADModelQuery.m 中原本的一处 `osx.cocoa.NilArg` 报告降为零。没有任何运行时测试能走到该路径：
  表 ID 的有序集合源自筛选器所遍历的同一批投影，因此它目前持有的每个 ID 都至少匹配一行 ——
  这也正是分析器只能给出警告的原因。

### 安装的访问器块重新读取了弱引用的存储上下文
- **状态：** 已修复
- **现状：** `RptqObject.m` 中的四个访问器块在块顶部将弱引用的 `storeContext` 一次性读入强引用局部变量，
  并且过去名为 `self` 的块参数已改名为 `target`（它遮蔽了外层类方法的 `self`）。
  因此，对多（to-many）访问器每次调用只触碰一次该弱引用属性，而非每个成员触碰一次，四处 `-Wshadow` 警告也随同一次编辑一并消除。
- **为何此处的局部变量是安全的：** 强引用局部变量的生命周期仅限于块的*当次调用*；
  它并未被存储的块捕获，因此没有任何对象会获得超出调用期的引用。本条目的早期版本声称将其提升到块顶部会造成循环引用 ——
  那只有在*安装*块时进行强捕获才会发生，而此处并非如此。
- **位置：** `MAD/Source/rptq/store/RptqObject.m:233-254`。

### MADDataTableFast 从声明为非空的方法返回 nil
- **状态：** 已修复
- **问题：** 五处 `return nil` / 可能为 nil 的返回位于声明为始终返回值的方法路径上：
  `:964`、`:973`、`:987`、`:1280`、`:1416`。信任该声明的调用者不会做 nil 检查。
- **位置：** `MADSqlite3/Source/MADDataTableFast.m:964,973,987,1280,1416`。
- **证据：** `xcodebuild analyze` 中的 `nullability.NullReturnedFromNonnull`。
- **现状：** 声明如实反映代码的行为，且不改变任何运行时行为。
  `-dataForRow:column:error:` 和 `-runSelectQuery:` 在 `MADDataTableFast.h` 中改为可空 ——
  前者与基础协议中可空的 `-dataForRow:error:` 一致，后者在查询不产生任何行时返回 nil。
  `objectEnumerator` 的报告比较特殊：Fast 表在没有列时返回 nil，*并且*抽象基类在 Release 下也返回 nil，
  因此失实的声明实际上是 `MADDataTableCursoring` 的 `nonnull` —— `MADFoundation/Source/MADDataTable.h`
  现在将其声明为可空，这正是两个实现一直以来所做的。属性 `databaseForSelects` 也改为可空（没有 delegate 的表没有该数据库连接）。
  MADDataTableFast 自己的头文件也将 `objectEnumerator` 重新声明为可空，以便 Fast 调用点能看到这一标注。
  同级的 `-columnsEnumerator` 在协议中同样带有失实的 `nonnull`，在基类的抽象路径上也同样返回 nil；
  此处保持原样 —— 因为没有任何 MADDataTableFast 路径会为它返回 nil —— 特此记录，以便下一位读者知道这是有意放过而非遗漏。
- **锁定依据：** 清除缓存结果后重新运行分析器：MADDataTableFast.m 中的报告从五处降为零。
  声明改动没有可锁定的运行时失败；每处声明现在所承认的 nil 均在可达之处由测试锁定 ——
  `MADDataTableRegressionTests testFastTableDataForRowWithUnknownColumnReturnsError` 和
  `MADDataTableFastSelectTests testRunSelectQueryYieldsNilWhenTheQueryHasNoRow`
  （修改前后均通过：它记录了头文件现在所声明的行为）—— 且
  `testFastTableObjectEnumeratorIsNilWithoutColumns` 继续锁定该枚举器。

### 图像元素无法在保存后存活
- **状态：** 已修复
- **位置：** `MAD/Source/rptq/RptqDocument+Extras.m:559-562`（工厂方法赋了一个 `UIImage`）、
  `MAD/Source/rptq/store/MADStoreSchema.m:563-565`（属性为 `BlobOpt`）、
  `MAD/Source/rptq/store/MADStore.m:483-485`（Blob 绑定器仅接受 `NSData`，否则绑定 `NULL`）、
  `MADStore.m:217-220`（读取结果作为 `NSData` 返回）。
- **行为：** `RptqDocumentElementImage.image` 声明为 `UIImage *`，工厂方法也存入了一个 `UIImage`，
  但存储的 Blob 列仅对 `NSData` 绑定字节；因此 `UIImage` 会写入 SQL NULL，下次打开时该值就消失了
  （如果真写入了任何内容，读取时返回的也会是 `NSData`）。测试中的存储打开/重开往返过程就是整个缺陷的体现：
  内存中图像还在，保存并重新打开后就变成了 nil。
- **为何重要：** 插入的图片在下次打开文档时会静默消失 —— 而这是报表中唯一能放置徽标的地方。
  修复方法是在属性边界处做转换（存入 PNG 数据，读出 UIImage）。
- **现状：** `RptqDocumentElementImage (Extras)` 在属性边界实现了 `-image` / `-setImage:`。
  setter 写入 `UIImagePNGRepresentation` 字节 —— 这正是旧存储转换器已经锁定的线格式（`MADStorePNGData`，且
  `MADStoreConverterTests` 会检查这些字节）—— 而 getter 则对存储返回的字节调用 `[UIImage imageWithData:]`。
  存储的 Blob 绑定器和读取器保持不变，且内存中已经是 `NSData` 的值无论如何读回的都是图片。
  仅限 Apple 平台（`#if __APPLE__`）：UIImage 属于 UIKit，非 Apple 平台上工厂方法拒绝构建图像元素。
- **锁定依据：** `MADDocumentObjectDataReferenceImageTests`：
  `testImageSurvivesSaveAndReopen`（取代原先锁定数据丢失的 `testImageDoesNotSurviveSaveAndReopen`）、
  `testTheStoredBlobIsTheImagesPNGData`（底层属性持有的是 PNG 字节，而非图像对象或 NULL）以及
  `testImageIsTheElementImageWhileInMemory`（同步更新：元素返回的是同一张图片，而非同一个对象实例）。
  `MADPrintPageElementTests testImageElementAdoptsTheDefinitionImage` 也出于同样原因进行了更新 ——
  其对象同一性断言改为了像素相等性断言。两个新测试均已确认针对旧代码会失败。Linux 移植版锁定了与平台无关的一半：
  `Linux/Tests/MADDocumentObjectDataReferenceImageTests.m testImageDataSurvivesSaveAndReopen`
  （由 `testImageDoesNotSurviveSaveAndReopen` 重命名而来）。

### `MADImageThumbnail` 绘制第 1 页，因此单页文档的缩略图是空白的
- **状态：** 已修复
- **位置：** `MAD/Source/MADImageThumbnail.m:102`
- **行为：** 基于渲染器的路径调用了
  `[printPageRenderer drawPageAtIndex:1 inRect:rect withTransparentBackground:YES]`。
  `MADPrintPageRenderer` 的页面循环是从零开始的（`drawPageAtIndex:withContext:`），因此索引 1 是*第二*页；
  对于单页报表，边界检查返回否，缩略图就成了空白的白色画布。同级绘制代码中的注释称之为“从不绘制第一页”，
  因此这个差一错误对于多页报表看似是有意为之，但作为封面则是错误的。
- **为何重要：** 文档浏览器对单页报表会显示空白缩略图。相关怪异行为：工厂方法声明在
  `MADImageThumbnail`（`UIImage` 的子类）上，返回类型为 `instancetype`，但实际构建的对象却是普通的
  `UIImage` —— 信任静态类型的调用者会对该对象的类判断失误。
- **现状：** 渲染器路径改为请求页面索引 0 —— 即报表的第一页 —— 因此单页文档的封面就是该页本身，
  多页文档的封面则是其首页。其背后的透明画布现在也真正生效了，见下文 `MADPrintPageRenderer` 条目。
- **锁定依据：** `MADImageThumbnailTests testRendererThumbnailIsASquareLetterPageAndDrawsPageOne`
  （其索引断言从 1 改为了 0）、`testAOnePageDocumentsThumbnailIsNotBlank` —— 使用一个像真实渲染器那样做边界检查的分页测试渲染器，
  在有效页面上绘制内容，而在达到或超过页数时不绘制任何内容；该测试在修复前失败 —— 以及针对另一方向的
  `testAMultiPageDocumentsThumbnailShowsTheFirstPage`。

### `MADPrintPageRenderer` 忽略 `withTransparentBackground:`
- **状态：** 已修复
- **位置：** `MAD/Source/MADPrintPageRenderer.m:289-295`
- **行为：** `-drawPageAtIndex:inRect:withTransparentBackground:` 从不读取该标志位；
  它总是先涂满不透明的白色画布，然后再绘制页面。头文件将该参数记录为“绘制透明背景而非白色背景”，
  且 `MADImageThumbnail` 以 `YES` 调用它并期望得到透明背景。
- **为何重要：** 任何请求透明页面的调用者得到的都是不透明的白色页面；该参数名不副实。
- **现状：** 读取该标志位 —— 仅当未请求透明背景时才绘制白色画布，从而让页面自身的绘制独立呈现在调用者的上下文之上。
- **锁定依据：** `MADPrintPageRendererTests testDrawPageWithATransparentBackgroundDrawsNoCanvas`
  （修复前失败：清零后的像素读回为不透明白色）以及取代了
  `testDrawPageDrawsTheWhiteCanvasEvenWithTransparentBackground` 的
  `testDrawPageWithAnOpaqueBackgroundDrawsTheWhiteCanvas`。

### `MADSectionLayoutAttributes +movePlacedItem:` 把孤立的项瞬移到原点
- **状态：** 已修复
- **位置：** `MAD/Source/MADSectionLayoutAttributes.m:62-82`
- **行为：** 候选落点初始为 `CGPointZero`，其距离从该项自身的原点算起，因此当没有*其他*项可供吸附时，
  循环永远不会替换该候选点，该项的 frame 会被设为 `(0, 0, w, h)` —— 即原点，而非附近的有效点。
  一个原本位于合理位置的孤立项，在第一次运行布局时就会被猛拉到左上角。
- **现状：** 循环会记录是否确实存在其他可供吸附的项；如果没有，该项保持原有的 frame。
  在存在邻近项的情况下，搜索逻辑保持不变：原点仍然是远处角点必须击败的下限，这也正是相邻测试所锁定的形态。
- **锁定依据：** `MADSectionLayoutAttributesTests testPlaceItemWithNoOtherItemsStaysWhereItWas`
  （由锁定瞬移行为的 `testPlaceItemWithNoOtherItemsSnapsToTheOrigin` 重命名而来），其前后两半在修复前均确认失败；
  `testPlaceItemSnapsToTheNearestOtherCorner` 和
  `testPlaceItemPrefersTheOriginOverADistantCorner` 保持不变并继续通过。

### MAD 的文档测试夹具在多次测试运行之间共享同一个存储

- **状态：** 已修复（测试）；底层按名称键控的机制记录如下
- **位置：** `MAD/MADTests/MADOperationCreateDocument*Tests.m`、
  `MADOperationDocumentCloseDocumentTests.m`、`MADOperationDeleteFileTests.m`、
  `MADDocumentTests.m` —— 测试夹具使用固定名称创建文档
  （`add-connection.mad`、`first-time.mad`、`open.mad` 等）。
- **行为：** 文档的内部目录 —— 以及其中的存储 —— 解析到
  `<home>/tmp/<name>.mada`（`MADURLFactory +newURLDocumentArchiveForFileURL:extension:`），
  设备在多次测试运行之间共享并保留该目录；测试夹具唯一的临时目录从未进入该路径。
  因此测试套件第二次运行时会打开第一次运行留下的存储，
  `insertObjectForEntity:@"RptqDocument" identifier:1` 随之抛出“already in the graph”。
  2026-10-10 实测：合并后的测试套件第二次运行时出现三处此类失败，第三次运行时（仅清理两处残留后）出现另一处单独失败，第一次运行时则为零失败。
- **现状：** 每个夹具文档的名称都带上其夹具目录的 UUID，因此每个夹具都解析到全新的存储；
  重新打开流程复用同一个 URL，仍然能找到第一个文档写入的内容。
- **备注（产品层面，此处未更改）：** 不同文件夹中具有相同文件名的两个文档在打开期间会解析到同一个内部目录。
  导入路径对重复文件名做了守卫（`MADURLFactory +newURLWithUniqueFilenameForURL:`），因此此处仅作记录而不在产品代码中做变通处理。
- **锁定依据：** 在模拟器上仍保留旧残留文件的情况下，连续运行两次 MAD scheme，每次均为 547/547 通过。

### 存储的颜色列没有读取者，模型的颜色属性没有对应列
- **状态：** 已修复（2026-10-21）。
- **位置：** `MAD/Source/rptq/store/MADStoreSchema.m:496-503`（列定义）、
  `MAD/Source/rptq/autogen/RptqDocumentElement.h:30-31`（声明为 `UIColor *` 的 `backgroundColor`、
  `foregroundColor`）、`MAD/Source/rptq/store/RptqObject.m:63-92`
  （`-valueForUndefinedKey:`：仅做精确名称匹配）、`MAD/Source/rptq/RptqDocumentElementBarcode+Extras.m:89-90`
  （唯一的写入者）。
- **行为：** 可移植存储为每个元素提供了八个颜色列 —— `backgroundColorR/G/B/A` 以及 `foregroundColor` 的同样四个列 ——
  但模型的属性名为 `backgroundColor` / `foregroundColor`，且没有任何代码在两者之间做映射。
  `RptqDocumentElement -backgroundColor` 请求同名属性而找不到，也找不到同名关系，于是落入
  `NSObject -valueForUndefinedKey:`，抛出 `NSUnknownKeyException`。唯一写入颜色的调用者
  （`RptqDocumentElementBarcode+Extras.m:89-90`）看起来也会以同样方式抛出异常；它位于条形码创建路径上，
  不在无头构建中，且在 Apple 平台上未被测试覆盖。写入这四个列的转换器
  （`MADDesigner/Source/MADStoreLegacy/MADStoreConverter.m:66-85, 111`）是唯一触碰它们的代码。
- **为何重要：** 在元素上设置的颜色无法读回，同一份文档也无法将其绘制出来。
  HTML 精确复刻版和 PDF 之所以是单色的（两者都在各自的文件头中记录了这一点），原因正在于此：
  遍历过程没有任何颜色可以提供给它们。横幅只是第一个受害者 —— 任何属于颜色的元素样式都存在同样的漏洞。
- **为何此前未在此处修复：** 映射属于存储层的决策，而非格式的决策。
  读取需要将四个实数合成一个颜色 —— 在 Apple 上是 `UIColor`，在没有 `UIColor` 的 Linux 上则是某种可移植表示 ——
  写入则需要反过来。这与 `MADCurrencyFormatter` 的区域设置问题形态相同，应当归属存储层而非导出器。
- **测试：** 无；此前没有可供表征的读取者。
- **现状：** `RptqObject` 在两个方向上通过四个 RGBA 列映射这两个模型属性。
  getter 在 Apple 上组装为 `UIColor`（在没有 `UIColor` 的非 Apple 平台上组装为四个分量 `NSNumber` 的 `NSArray`），
  当四个列均缺失时返回 nil。setter 将颜色拆解 —— 当 UIKit 无法用 RGB 描述该颜色时，像转换器那样先转换到 sRGB ——
  写入四个列并将该行标记为脏一次；传入 nil 则清空这四个列。架构列保持不变。由
  `MADTests/RptqDocumentElementBarcodeTests testFactoryWritesAndReadsTheElementColours` 锁定，
  该测试通过 `+barcodeWithMtBarcode:...`（昔日的崩溃点）创建条形码元素并读回两个颜色。

## MADFoundation

### `MADURLFactory +newURLForLocalApplicationSupportDirectory` 在没有 bundle identifier 时抛出 `NSInvalidArgumentException`，且 `+groupRootURLForIdentifier:` 在 macOS 上指向 `~/Library/Group Containers`
- **状态：** 已修复（2026-10-29）。
- **位置：** `MADFoundation/Source/MADURLFactory.m:190`（`+groupRootURLForIdentifier:`）
  和 `:302-310`（`+newURLForLocalApplicationSupportDirectory`）。
- **行为：** 在原生 macOS 上运行 `MADFoundationTests` 和 `MADTests` 时暴露出两个相关问题：
  1. `+newURLForLocalApplicationSupportDirectory` 将 `[[NSBundle mainBundle] bundleIdentifier]` 直接传给了
     `[appSupportDirectory URLByAppendingPathComponent:bundleIdentifier]`。在 `bundleIdentifier` 为 `nil`
     的无 bundle 测试宿主或命令行运行器中，Apple Foundation 会抛出 `NSInvalidArgumentException`（`pathComponent` 不能为 nil）。
  2. `+groupRootURLForIdentifier:` 在
     `[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:]` 外使用了 `#if __APPLE__`。
     在 macOS 15+ 上，即使进程没有相应权限（entitlement），该方法也会返回 `~/Library/Group Containers/<groupID>`，
     而在 `~/Library/Group Containers/` 内创建目录会触发阻塞式的 macOS TCC 模态对话框（`mkdirat` 阻塞等待用户批准）。
- **现状：** 当 `bundleIdentifier.length == 0` 时，`+newURLForLocalApplicationSupportDirectory` 回退到
  `[MADApplication groupIdentifier]`；而 `+groupRootURLForIdentifier:` 使用
  `#if defined(__APPLE__) && TARGET_OS_IPHONE` 守卫 App Group 容器查找，使 macOS 使用标准的每用户目录
  `~/Library/Application Support`、`~/Documents` 和 `~/Library/Caches`。
- **测试：** `MADURLFactoryTests testLocalApplicationSupportDirectoryIncludesBundleIdentifier`
  和 `testApplicationDirectoryFallsBackToUserDirectoriesWhenGroupContainerIsUnavailable`。

### `MADDataTable -cacheWithUrl:error:` 在 macOS 上传入 `NSDataWritingFileProtectionCompleteUnlessOpen`，导致无相应权限的缓存写入失败
- **状态：** 已修复（2026-10-29）。
- **位置：** `MADFoundation/Source/MADDataTable.m:218`。
- **行为：** `-cacheWithUrl:error:` 调用了
  `[plistData writeToURL:url options:NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen error:&writeError]`。
  在没有 Data Protection 权限的 macOS 上，`NSDataWritingFileProtectionCompleteUnlessOpen` 会导致
  `writeToURL:options:error:` 失败，从而破坏 `MADDataTableVirtual` 的磁盘缓存写入。
- **现状：** `NSDataWritingFileProtectionCompleteUnlessOpen` 使用
  `#if defined(__APPLE__) && TARGET_OS_IPHONE` 守卫，而在 macOS 和 Linux 上仅使用 `NSDataWritingAtomic`。
- **测试：** `MADDataTableRegressionTests testVirtualTableCacheAndReloadFromDisk`。

### `MADKeyChain` 在存在性检查和变更辅助方法中泄漏每个由 `SecItemCopyMatching` 返回的 `CFDataRef`
- **状态：** 已修复（2026-10-29）。
- **位置：** `MADFoundation/Source/MADKeyChain.m:155-159`（`+credentialsExist:`）、
  `:204-205`（`+saveToken:forKey:withDescription:`）、`:221-223`（`+deleteKey:`）以及
  `:235-247`（`+deleteSavedPasswordForKey:error:`）。
- **行为：** 四个方法都构造了包含 `(__bridge id)kSecReturnData : @YES` 的钥匙串查询，并将
  `(CFTypeRef *)&query...Data` 传给 `SecItemCopyMatching`。当条目存在（`errSecSuccess`）时，
  Security 框架会分配并返回一个引用计数为 `+1`、持有解密后机密字节的 `CFDataRef`。
  四个方法全都既不读取该 `CFDataRef`，也不对其调用 `CFRelease`。
- **为何重要：** 针对现有钥匙串条目每次调用 `+credentialsExist:`、`+saveToken:forKey:withDescription:`、
  `+deleteKey:` 或 `+deleteSavedPasswordForKey:error:`，都会在进程堆上泄漏一个包含明文凭据字节的 `CFDataRef`。
- **现状：** `+saveToken:forKey:withDescription:` 省略 `kSecReturnData` 并向 `SecItemCopyMatching`
  传递 `NULL` 作为结果指针；`+credentialsExist:`、`+deleteKey:` 和
  `+deleteSavedPasswordForKey:error:` 则会释放 `SecItemCopyMatching` 返回的任何非 NULL `CFDataRef`。
- **测试：** `MADKeyChainTests testSaveCheckAndDeleteCredentialsRoundTrip`。

### MADDataTable 的缓存加载器解引用了空错误指针
- **状态：** 已修复
- **现状：** `-loadFromCacheWithUrl:error:` 中对 `outError` 的两处写入均加上了
  `if (outError)` 守卫，与同一方法中原本就做了检查的另外三条失败路径保持一致。
  传入 NULL —— 该参数的 `_Nullable` 标注所允许的惯用法 —— 的调用者现在会收到返回的 NO，而非触发空指针解引用。
- **位置：** `MADFoundation/Source/MADDataTable.m:150`（文件缺失路径）和 `:187`
  （负载解析失败路径）。
- **变化原因：** `xcodebuild analyze` 在 `osx.cocoa.NSError` 下报告了这两处位置
  （“Potential null dereference. According to coding standards in 'Creating and Returning
  NSError Objects' the parameter may be null”）。对 MADFoundation 的全面排查发现该模块中恰好只有这两处未加守卫的写入；
  `MADDataTableVirtual.m:95` 和 `MADKeyChain.m:257` 原本就已有守卫。
- **锁定依据：** `MADDataTableRegressionTests` 的
  `testBaseTableLoadFromCacheWithMissingFileAndNullErrorReturnsNo` 和
  `testBaseTableLoadFromCacheWithInvalidPlistAndNullErrorReturnsNo`。两者在修改前都会使测试进程崩溃（已验证），
  修改后均通过，且现有的 `testBaseTableLoadFromCacheWithMissingFileReturnsError`（断言错误码 -215）和
  `testBaseTableLoadFromCacheWithNilUrlThrows` 仍然通过 —— 该测试类中全部 76 个测试通过。

### `MADOperationConditionResultTests`：异步路径断言与 dispatch_group 发生竞争

- **状态：** 已修复
- **位置：** `MADFoundation/MADFoundationTests/MADOperationConditionResultTests.m`，
  `-testCompletionIsNotCalledBeforeTheMethodReturnsForTheAsyncPath`（即原先位于 `:265` 的
  `XCTAssertFalse(calledBack, ...)`）。
- **行为：** 该测试用一个当场报告结果的条件调用 `evaluateConditions:`，然后紧接着在下一行断言完成回调尚未运行。
  立即报告结果的条件会让 dispatch_group 在循环期间就变为空，因此 `dispatch_group_notify`
  会在方法返回之前将其块排入全局并发队列 —— 另一个 CPU 核心可以在那个时间窗口内运行它。
  在负载较轻的机器上能稳定通过；但在 Linux 镜像的并行 `ctest` 负载（饱和虚拟机上运行 59 个可执行文件）下失败了两次，
  因为调用者在 notify 之后立即被调度挂起。
- **现状：** 并非削弱断言，而是使其变为确定性的：桩条件可以推迟其报告
  （`defersCompletion` / `-reportDeferredCompletion`），因此“尚未调用”的观测发生在条件确凿无疑仍未完成期间 ——
  随后测试再等待此前从未观测过的完成回调。同样的修改也同步到了 Linux 移植版
  （`Linux/Tests/MADOperationConditionResultTests.m`），即当初测出该偶发失败的地方。
- **锁定依据：** 同一个测试；Linux 可执行文件连续循环运行 60 次以及八次并行全套件运行均零失败（2026-10-06 实测），
  且模拟器上 MADFoundation 118/118 全部通过。

### 框架 target 丢弃了 `$(inherited)`，导致 `DEBUG` 从未进入框架代码

- **状态：** 已修复
- **位置：** 每个设置 `MADLOG_ACCESSOR` 的 target 的 `GCC_PREPROCESSOR_DEFINITIONS` ——
  `MADFoundation`、`MAD`、`MADAPI`、`MADCocoaExtensions`、
  `MADFileManager`、`MADSqlite3`、`MADMySQL`、`MADTds`、`MADExplorer`，以及
  `MAD Designer` 应用 target。
- **行为：** 每个 target 的定义列表都只有 `MADLOG_ACCESSOR=<accessor>` 而没有 `$(inherited)`，
  导致项目级的 `DEBUG=1` 被覆盖掉了。因此在 Debug 构建中，框架代码里的每一个 `#if DEBUG` 都是死代码：
  `MADApplication +groupIdentifier` 从不返回 `.local` 组，`MADLogDebug` 始终走空操作分支（`madlog.h`），
  而 `MADMySQL/Source/MADMySQLFetch.m` 的 `#ifdef DEBUG` 块也从未被编译。
- **现状：** 在每个列表（Debug 和 Release，共十个工程）的访问器定义之后添加了 `"$(inherited)"`。
  现在框架和应用 target 的 `-showBuildSettings` 解析结果为 `MADLOG_ACCESSOR=... DEBUG=1`。
- **为何重要：** 组标识决定了 Debug 构建使用哪个共享容器，而这种失败是静默的 ——
  从错误的分支返回了一个看似合理的值。
- **锁定依据：** `MADApplicationTests testGroupIdentifierMatchesBuildConfiguration`
  （在合并测试套件的第二次运行中捕获了该问题），以及随后重新运行并通过的八个框架 scheme 与应用构建。

## MADFileManager

### `MADMetaData -fileSystemFileCreationDate` / `-fileSystemContentChangeDate` 返回的是 `NSData` 而不是 `NSDate`
- **状态：** 已修复（类型谎言）
- **位置：** `MADFileManager/Source/MADMetaData.m`、`MADMetaDataLocal.m`、`MADMetaDataCloud.m`
- **行为：** 头文件将两者都声明为 `@property (readonly) NSDate *`，但访问器实现的返回类型却是 `- (NSData *)...`。实际返回的对象是 `NSDate`（从文件属性复制而来），因此信任编译器的 `NSData` 类型的调用者在调用 `-length` 等方法时会崩溃。
- **为何重要：** 编译器与运行时对这两个类型意见不一；一旦文件元数据通过新的手写 SQL 缓存路由，这种属性与访问器不匹配的问题就会引发故障。
- **现状：** 两个子类的访问器以及基类抛出异常的桩方法都已声明为 `- (NSDate *)...`，因此实现与头文件中的 `NSDate *` 属性一致。返回的对象保持不变。

### `MADMetaDataLocal` 的下载状态报告“当前”，但派生的标志却是 NO
- **状态：** 已修复
- **位置：** `MADFileManager/Source/MADMetaDataLocal.m:125`
- **行为：** `-ubiquitousItemDownloadingStatus` 返回 `NSMetadataUbiquitousItemDownloadingStatusCurrent`，然而 `-isUbiquitousItemDownloadingStatusCurrent` 硬编码了 `NO`，而不是从该字符串派生。一个本地文件同时声称自己“当前”和“非当前”。
- **为何重要：** 任何依赖该状态布尔值的 UI（例如“下载中”旋转指示器）都会与状态字符串不一致。
- **现状：** 该布尔值从 `-ubiquitousItemDownloadingStatus` 派生，因此两者保持一致。`testLocalDownloadingStatusIsConsistent`（原名 `testLocalDownloadingStatusInconsistency`）断言其为 YES。

### `MADFileInfo -isEqual:` 没有匹配的 `-hash` 重写
- **状态：** 已修复
- **位置：** `MADFileManager/Source/MADFileInfo.m:72`
- **行为：** `-isEqual:` 比较 `URL.absoluteURL`，但 `-hash` 仍沿用 `NSObject` 的身份哈希。指向同一文件的两个 `MADFileInfo` 对象比较结果为相等，哈希值却不同。
- **为何重要：** 将 `MADFileInfo` 用作 `NSSet` 成员或 `NSDictionary` 键时，查找或 `containsObject:` 会静默失败。
- **现状：** `-hash` 返回 `self.URL.absoluteURL.hash`，与 `-isEqual:` 比较的键相同。由 `testEqualObjectsHaveEqualHashes`（原名 `testEqualObjectsHaveDifferentHashes`）锁定。

### `MADDirectoryMonitor` 的 cancel handler 解引用 nil 属主——dealloc 时 SIGSEGV
- **状态：** 已修复
- **位置：** `MADFileManager/Source/MADDirectoryMonitor.m:99-104`
- **行为：** 两个处理程序都通过弱引用加载其属主（`.m:70` 处的 `MADDirectoryMonitor __weak *weakself = self;`），随后在不做 nil 检查的情况下使用它。cancel handler 通过**直接访问实例变量**来操作：

  ```objc
  dispatch_source_set_cancel_handler(self.directoryMonitorSource, ^{
      MADDirectoryMonitor *sself = weakself;
      close(sself->_fileDescriptor);          // *(int *)((void *)0 + 8)
      sself->_fileDescriptor = NotListening;
      sself.directoryMonitorSource = nil;
  });
  ```

  向 nil 发送消息是无害的；对 nil 使用 `->` 则是在地址 `offset` 处进行加载/存储，会导致段错误。`_fileDescriptor` 位于偏移量 8 处，与报告的故障地址完全吻合。
- **为何重要：** 当监视器在其 source 仍然存活（或仍在取消中）时被释放，属主销毁后会在 cancel handler 中崩溃：`dispatch_source_cancel` → cancel 回调 → `sself->_fileDescriptor` → `EXC_BAD_ACCESS (SIGSEGV) KERN_INVALID_ADDRESS at 0x8`。调用者除了让监视器一直存活到 cancel handler 运行完毕之外别无避免办法，而没有任何调用者这样做。同样缺失的守卫还使 event handler 只差一次弱引用加载就会触发 `dispatch_source_get_data(NULL)`。
- **现状：** cancel handler **强引用**捕获属主并通过它关闭描述符；其最后一行的 `directoryMonitorSource = nil` 会在其唯一一次运行时打破 source→block→self→source 循环，因此监视器由该处理程序释放，而不是在其中触发段错误。event handler 保留弱引用加载——若在那里使用强捕获，会在整个 source 生命周期内一直持有监视器——并对它做 nil 检查，因为同样缺失的守卫曾使它只差一次弱引用加载就会触发 `dispatch_source_get_data(NULL)`（且在非 Apple 平台上还会触发同样的直接实例变量读取）。
- **锁定依据：** 两个平台上的 `MADDirectoryMonitorTests testReleasingAMonitorWithACancelPendingDoesNotCrash`。它先挂起监视器的队列，使 cancel handler 无法在监视器释放前运行，随后释放监视器，再恢复队列：旧代码会在此处触发段错误（iOS 运行会报告 "Restarting after unexpected exit, crash, or test timeout"，且执行测试数为零），而修复后该测试还断言监视器确实已被释放，因此若修复方案泄漏了属主也会失败。（其他测试中的停止并排空操作不再承担防崩溃作用，但保留原样。）

## MADExplorer

### 查看器重写之后，文档浏览器缩略图仍然是空白
- **状态：** 已于 2026-10-17 修复。
- **位置：** `MADExplorer/MADExplorer/MADExplorer/MADThumbnailView.m`（`-setThumbnailPath:`）、`MADDesigner/Source/MADReportPageView.m`（写入处）。
- **行为：** 查看器在每次刷新后都会重写 `Caches/<hash>/Name@2x.png`。缩略图视图仅在*路径*改变时才重新加载，而路径是稳定的，因此刷新后重新配置的单元格保留了旧图像——通常是首次写入前加载的空白占位图。写入操作也不是原子的，因此读取方可能会解码写了一半的 PNG 并回退到空白图像。
- **为何重要：** 刷新报表，或打开后离开报表，都会使原本正常的缩略图从文档浏览器中消失，尽管磁盘上的 PNG 是正确的。
- **现状：** `-setThumbnailPath:` 会在文件修改日期改变时重新加载（不再仅凭路径判断），并且 `MADReportPageView` 以原子方式写入 PNG，且在编码失败时跳过写入。
- **测试：** `MADExplorerTests testSamePathRewriteReloadsTheImage`（`MADExplorer/MADExplorerTests/MADExplorerTests.m`）。
- **提交：** `7dff3b42b`。

### `MADStandard -standardStringForFileSize:` 有一处死代码会引发潜在抛出
- **状态：** 已修复
- **位置：** `MADExplorer/MADExplorer/MADStandard.mm`
- **行为：** 守卫 `if (filesize_str.length() <= range_end) { filesize_str.append(zero, range_end); }` 对 `double` 永远不会命中（格式化后的字符串总是 `dec_pos + 7` 个字符，而 `range_end` 是 `dec_pos + 4`）。一旦它真的执行，双参数重载 `append(str, subpos)` 会尝试在 `subpos >= 4` 处读取单字符 `"0"` 并抛出 `std::out_of_range`。
- **为何重要：** 如果输入格式将来发生变化，这段死代码就会崩溃；值得删除或修复 append 的参数个数。
- **现状：** 该守卫改用 `(count, char)` 重载——`append(range_end - filesize_str.length(), '0')`——填充到 `range_end`，使其行为与字面含义一致且不会抛出异常。未使用的常量 `zero` 已移除。

### `MADStandard` 隐藏了 `+standardStringForDouble:` / `+standardStringForUnsignedLong:`
- **状态：** 已修复
- **位置：** `MADExplorer/MADExplorer/MADStandard.mm`（对照 `MADStandard.h`）
- **行为：** 这两个类方法已实现，但未在公共头文件中声明；测试通过仅限测试使用的 category 访问它们。
- **为何重要：** 与 `MADFileUtilities` 辅助方法相同的隐藏 API 坏味道。
- **现状：** 两者均已在 `MADStandard.h` 中声明，`MADStandardTests.m` 中仅限测试使用的 category 已移除。

### `MADOpenDocumentManager -removeDocumentWithUrl:` 移除的是 `self.openUrl` 而不是 `url`
- **状态：** 已于 2026-10-28 修复。
- **位置：** `MADExplorer/MADExplorer/MADExplorer/MADOpenDocumentManager.m:58-67`。
- **行为：** `-removeDocumentWithUrl:` 从 `self.openUrl.absoluteURL` 而不是 `url.absoluteURL` 计算 `absoluteString`，因此传入 `self.openUrl` 以外的 URL 调用它时，会从 `self.openFiles` 中移除当前活动文档的条目，同时使 `self.openUrl` 保持非 nil，并把 `url` 的条目留在 `self.openFiles` 中。此外，尽管 `MADocument` 现在直接继承自 `UIDocument`，`MADOpenDocumentManager` 仍将其文档访问器和存储声明为 `UIManagedDocument *` 类型。
- **现状：** `-removeDocumentWithUrl:` 解析 `url.absoluteURL.absoluteString`，且 `MADOpenDocumentManager` 将其文档参数和返回值类型声明为 `__kindof UIDocument *`。
- **测试：** `MADExplorerTests -testRemoveDocumentWithUrlRemovesRequestedURLNotActiveURL`（`MADExplorer/MADExplorerTests/MADExplorerTests.m`）。

### `MADThumbnailView` 在 `DISPATCH_QUEUE_PRIORITY_BACKGROUND` 加载缩略图，并阻塞在 `dispatch_sync(dispatch_get_main_queue(), …)`
- **状态：** 已于 2026-10-28 修复。
- **位置：** `MADExplorer/MADExplorer/MADExplorer/MADThumbnailView.m:42-92`。
- **行为：** `-setThumbnailToDefault` 和 `-setThumbnailPath:` 将图像解码派发到 `dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)`（`QOS_CLASS_BACKGROUND`），随后调用 `dispatch_sync(dispatch_get_main_queue(), …)` 为 `self.image` 赋值。在 Darwin 的 QoS 调度器下，`QOS_CLASS_BACKGROUND` 会被限流到空闲 CPU（在 `MADExplorerTests -testSamePathRewriteReloadsTheImage` 中主线程泵送 `NSRunLoop` 时会饥饿超过 2 秒），并且让后台工作线程在主线程上同步阻塞会有优先级反转风险。
- **现状：** 两个方法都在 `QOS_CLASS_USER_INITIATED` 上解码，并用 `dispatch_async(dispatch_get_main_queue(), …)` 切回主队列。
- **测试：** `MADExplorerTests -testSamePathRewriteReloadsTheImage`（`0.225s`）。

## MADSqlite3

### `MADDatabaseSqlite3` 在零行 `SELECT` 上无条件调用 `-endBulkInsert`，抛出 `cannot commit - no transaction is active`
- **状态：** 已于 2026-10-29 修复。
- **位置：** `MADSqlite3/Source/MADDatabaseSqlite3.m:545-605`（`-executeSQL:fieldKeys:onConnection:intoResultTable:transactionSet:returnsResults:binaryBindings:withError:`）。
- **行为：** 在 `if (returnsResults && dataTable != nil)` 代码块内部，`[dataTable beginBulkInsert]` 在 `while (sqlite3_step(statement) == SQLITE_ROW)` 的第一次迭代中于 `if (rowCounter == 0)` 内部被调用（`:583`），而 `[dataTable endBulkInsert]` 却在 `while` 循环之后被无条件调用（`:603`）。当 `SELECT` 查询返回 0 行（`sqlite3_step` 在第一步就返回 `SQLITE_DONE`）时，`rowCounter` 保持为 0，`[dataTable beginBulkInsert]` 从未被调用，而 `[dataTable endBulkInsert]` 在没有活动事务的情况下对 `_databaseForInserts` 执行了 `COMMIT TRANSACTION;`，触发 `NSAssert`（`cannot commit - no transaction is active`）。
- **现状：** `[dataTable endBulkInsert]` 由 `if (rowCounter > 0)` 守卫，使其仅在进入过 `[dataTable beginBulkInsert]` 时才被调用。
- **测试：** `MADDatabaseSqlite3DatabaseTests testDriverZeroRowSelectDoesNotCallUnpairedEndBulkInsert`。

### 缓存的 ORDER BY 忽略列类型，因此文本键按二进制排序
- **状态：** 已于 2026-10-18 修复（提交 `483a77259`）。
- **位置：** `MADSqlite3/Source/MADQueryCacheSelectLimitOffset.m` 的 ORDER BY 块；报表枚举器在 `MADDataTableFast.m` 中传入了 `columns:nil`；同样的将 `nativeType` 当作 `MADDataType` 的转换也出现在 `MADQuery+Sqlite3.m`、`MADQueryCacheIndexCreate.m` 和 `MAD/Source/MADQueryCacheSelectGroupKeys.m`。
- **行为：** `+[MADDatabaseSqlite3 sortDescriptionForColumnType:ascending:]` 期望传入 `MADDataType`，且仅对文本类型返回 `COLLATE LSASC`。调用者传入的是 `MADDataColumn.nativeType`（驱动原生类型代码），而报表枚举器甚至根本没有传入列，因此 `dataColumn` 为 nil，`nativeType` 为 0（`MADDataTypeBit`）：每一列都得到了普通二进制 `ASC`。报表格式化器使用 `localizedCaseInsensitiveCompare:` 比较相同的键，导致相等性判断与相邻性不一致。行 `"Apple"`、`"Armadillo"`、`"apple"` 按此顺序到达，格式化器会输出三个分组，而在不区分大小写的排序下应输出两个分组（`{Apple, apple}`、`{Armadillo}`）。
- **为何重要：** 分组边界是通过比较相邻行找到的，因此与比较器不一致的 ORDER BY 会拆散大小写变体分组（用户可见）。类型化比较器的设计依赖于两者保持一致，所以这是正确性的第一步，而非性能后续工作。
- **现状：** 排序枚举器（以及 `MADDataTableFast.m` 中其他 `MADQueryCacheSelectLimitOffset` 调用点）会传入缓存的 `columns`，且每个 `sortDescriptionForColumnType:` 调用点都传入 `column.type`；未获传入列的查询会按普通方式排序，而不是猜测排序规则。文本键现在按 LSASC 排序，这与格式化器所做的比较相同，从而使相等性与相邻性一致。在 GNUstep 上，`localizedCaseInsensitiveCompare:` 是区分大小写的（README.md），因此两边在那里仍然一致，只是不做大小写折叠——已在 Linux 测试套件中记录为待办需求。
- **测试：** `MADDataTableFastSelectTests testSelectLimitOffsetWithATextColumnOrdersWithLSASC`、`testEnumeratorOrdersTextKeysCaseInsensitively`（两个平台）以及 `testSelectLimitOffsetWithoutColumnsOrdersPlainly`（无列时的回退）。iOS 与 `Linux/Tests` 镜像结果一致。
- **相关：** 上文的“MADReportFormatter 通过 id 比较无类型值”——其比较器使用缓存列的类型，而此处的 ORDER BY 修复是其前提条件。

### `fieldsForTable:` 运行了表查询并把表作为字段返回
- **状态：** 已修复
- **位置：** `MADSqlite3/Source/MADDatabaseSqlite3.m`（`-fieldsForTable:connection:error:`）
- **行为：** 该方法运行了与 `-getTablesFromConnection:` 相同的 `sqlite_master` 查询，将每一行包装为 `MADDatabaseTable`，并将其作为字段列表返回。架构导入链将结果直接送入 `RptqDatabaseSchemaField` 工厂，后者向 `MADDatabaseTable` 发送 `fieldType` 消息时崩溃。
- **现状：** 该方法运行 `PRAGMA table_info("…")`，为每一列构建一个 `MADDatabaseField`，并通过 `+dataTypeForNativeType:` 映射声明的类型，同时从 `pk` 列获取主键标志。由创建文档链测试（`testCreateDocumentChainImportsAChinookSchema`，导入全部十一张 Chinook 表）发现并修复。
- **在存储迁移期间发现。**

### `connectWithConnection:credentals:connectionError:` 在连接成功后返回 nil
- **状态：** 已修复
- **位置：** `MADSqlite3/Source/MADDatabaseSqlite3.m`（`-connectWithConnection:credentals:connectionError:`）
- **行为：** 驱动打开了数据库却返回 nil。创建链将 nil 连接对象视为连接失败，导致架构导入中止并报错 "Failed to establish database connection for schema import (nil connection object)."
- **现状：** 驱动返回自身作为句柄；接收连接对象的调用者将其传回给表读取器和字段读取器，而后者会忽略它。由创建文档链测试发现并修复。
- **在存储迁移期间发现。**

### `MADDataTableFast` 存储了绝对缓存 URL，容器变化会使其失效

- **状态：** 已修复
- **提交：** `d8de8ece0`
- **位置：** `MADSqlite3/Source/MADDataTableFast.m:304`（`-loadWithPlist:`），写入位于 `:244`（`-copyPlist:`）、`:226`（`-encodeWithCoder:`）、`:206`（`-initWithCoder:`）
- **行为：** `.mdcache` plist 将 `urlFastCache` 记录为绝对 URL——`file:///…/Containers/Data/Application/<container-UUID>/Library/Caches/<tag>/<tag>.maddb`。`-loadWithPlist:` 原封不动地采用了它，因此缓存会在*写入*该 plist 的容器所指定的路径下打开。应用程序的数据容器 UUID 并不稳定：重新安装或设备恢复会分配新的 UUID 并删除旧目录。存储的 URL 随后指向一个不存在的目录，而带有 `SQLITE_OPEN_CREATE` 的 `sqlite3_open_v2` 无法在目录缺失的地方创建文件，因此返回 `SQLITE_CANTOPEN`。
- **为何重要：** 这是崩溃，而非误读。`-openDatabaseWithFlags:` 会在打开失败时断言，而每次打开文档都会走到这里——`MADocument -initWithFileURL:andDatabaseConnection:` → `loadFromCacheWithUrl:` → `-loadWithPlist:` → `-reopenDbConnection` → `-openDatabaseWithFlags:`。因此整个应用在文件资源管理器中第一次点按时就会崩溃，只留下一句 `openDatabaseWithFlags failed (unable to open database file).`。在诊断该问题的模拟器上的四个缓存中发现了三个不同的失效容器 UUID，说明每次重装都在重新埋下这颗雷。
- **现状：** `-loadWithPlist:` 仅在所存储 URL 的目录仍然存在时才采用它。否则会将其丢弃，记录缺失目录的日志，并让 `-urlFastCache` 在当前使用的缓存目录下重新计算路径。`-openDatabaseWithFlags:` 还在断言中指明了路径，这正是原始错误消息所隐瞒的——原失败消息只说 "unable to open database file"，既未指明文件也未说明原因。
- **测试：** `MADSqlite3/MADSqlite3Tests/MADDatabaseSqlite3DatabaseTests.m` 中的 `testLoadWithPlistDiscardsACacheUrlWhoseDirectoryIsGone` 和 `testLoadWithPlistKeepsACacheUrlWhoseDirectoryIsPresent`。移除守卫后，第一个测试会精确复现该崩溃：`*** Assertion failure in -[MADDatabaseSqlite3 openDatabaseWithFlags:] … (unable to open database file) for …/gone/gone.maddb.`
- **格式，现已一并修复：** `-copyPlist:` 和 `-encodeWithCoder:` 过去写入的是绝对 URL，因此读取过期 URL 虽然安全了，但写入操作仍然是过期 URL 混入的源头。它们现在只记录文件名——`<tag>.maddb`——并在读取 plist 时由 `-cacheUrlForStoredValue:` 针对当前使用的缓存目录（即 `-cacheDirectoryURL:`：优先取调用者的目录，其次是缓存 delegate 的目录，最后是应用组的目录）进行解析。旧构建写入的 plist 仍保留绝对路径形式，且仅在其所指目录存在时才被采纳，从而仍能读取现有缓存。`-initWithCoder:` 也经过同一个辅助方法。已通过读取 CLI 写入的缓存 plist 验证：`"urlFastCache" => "7308922102201200.maddb"`。
- **测试：** `MADDatabaseSqlite3DatabaseTests.m` 中的 `testCopyPlistStoresTheCacheFileNameNotAnAbsoluteUrl` 和 `testLoadWithPlistResolvesAStoredFileNameInTheDirectoryInUseNow`。第二个测试针对一个缓存目录写入 plist，再针对另一个缓存目录读取它，这是绝对 URL 无法承受的场景。两者在保留前均已确认在旧写入逻辑下会失败。

### `MADDataTableFast` 在内存中删除或 drop 之后让行计数器过期
- **状态：** 已修复
- **提交：** `850c32f51`
- **位置：** `MADSqlite3/Source/MADDataTableFast.m:799`、`:804`、`:818`、`:789`
- **行为：** `rowCounter` 是 `-count` 和 `-numberOfRows` 唯一参考的值（`:1216`、`:1222`），而 `-dropTable`、`-dropTableName:`、`-deleteAll` 或 `-vacuumCacheDb` 全都没有触碰它。执行这四个方法中的任何一个之后，计数器都会指向文件中已不再持有的行数。
- **为何重要：** 目前没有调用者能走到这里——代码库中没有任何地方调用 `-deleteAll`，其余三个仅从 `-removeAllObjects` 到达，而后者自己会将计数器清零——因此没有现役路径受损。但对 `MTTableController` 而言，`-count` 是*页面游标*（见下文应用一节），因此只需新增一个调用者就会触发该隐患。
- **现状：** `-dropTable` 和 `-dropTableName:` 会将计数器清零，`-deleteAll` 也一样。`-vacuumCacheDb` 有意不清零——VACUUM 会重写文件但保留每一行，源码中带有说明这一点的注释。`-dropTableName:` 接受任意表名，因此它仅在被删除的表正是当前表时才将计数器清零；删除外部表绝不能改动此计数。
- **测试：** `MAD/MADTests/MADDataTableRegressionTests.m` 中的 `testFastTableDropTableZeroesRowCount`、`testFastTableDropForeignTableKeepsRowCount`、`testFastTableDeleteAllZeroesRowCount` 和 `testFastTableVacuumKeepsRowCount`，各自直接驱动其中一个私有方法。它们会先调用 `-reopenDbConnection`：`-endBulkInsert` 会关闭插入连接并将其句柄置空，因此在重新打开它之前，通过它发送 SQL 的变更操作无法运行。`-removeAllObjects` 也是这样做的。

### `MADDataTableFast -deleteAll` 用错误的初始化器构建查询
- **状态：** 已修复
- **提交：** `850c32f51`
- **位置：** `MADSqlite3/Source/MADDataTableFast.m:818`
- **行为：** `-deleteAll` 发送了 `[[MADQueryCacheDeleteAllFromTable alloc] initWithObject:tableName]`。`-initWithObject:` 期望传入参数*字典*并对它做下标访问，因此传入 `NSString` 会在第一行抛出 `-[NSTaggedPointerString objectForKeyedSubscript:]`。sqlite 驱动自己的 `-beginBulkInsert` 正是为此使用 `-initWithTableName:`。
- **为何重要：** 没有任何代码调用该方法，所以此前从未触发——上面的计数器漂移未被注意也是同样原因。将来任何调用者第一次调用它时都会抛出异常。
- **现状：** 改用 `-initWithTableName:`。
- **测试：** `testFastTableDeleteAllZeroesRowCount`。

### 批量插入行循环把整个结果集保存在自动释放内存中
- **状态：** 已修复
- **提交：** `94a8d2068`、`3fbfb800b`
- **位置：** `MADSqlite3/Source/MADDataTableFast.m:618`、`MADSqlite3/Source/MADQueryCacheAddRow.m:51`
- **行为：** `-addRowWithDataForFieldKeys:` 是写端口的逐行入口，其下方的插入路径在每次调用时都会产生自动释放对象——绑定语句会按列构建自动释放对象。在这个粒度上没有自动释放池：该方法带有作者留下的 `// FIXME: Maybe wrap in autorelease block.`，自动释放池代码写好了却在首尾两端被注释掉，而且也没有任何调用者建立自动释放池，因此这些对象一直存活到调用者自己的循环结束。同一路径上还有第二处独立的浪费：`MADQueryCacheAddRow -update` 每行运行一次，每次都会重建整条 `INSERT INTO … VALUES (?, ?, …)` 语句——这个字符串在第一行 prepare 之后就没有任何代码再读取——并且每次都替换其绑定数组，而不是清空已有的数组。
- **为何重要：** 报表的设计目标是容纳数十万行数据，而这正是写入数据的路径。该内存尖峰是瞬态的而非泄漏，但瞬态就足够致命了：在进程负载最重的时刻占用常驻内存，这正是触发 jetsam 强杀的形态。该路径从 sqlite 驱动自己的行循环 `MADDatabaseSqlite3.m:535` 到达，因此每次刷新报表都要付出这一代价。
- **现状：** `-addRowWithDataForFieldKeys:` 在单行外围开启 `@autoreleasepool`，而 `-update` 保留其绑定数组且只构建一次 `_sql`，并像旁边的 `_sqlColumnPart` 一样用 `_sql == nil` 守卫。自动释放池应当放在表内而非调用者处，因为只有表知道一行的结束时机，而且调用者只是针对 `<MADDataTableWriting>` 的通用循环，没有理由知道内部需要自动释放池。
- **测试：** `MADSqlite3/MADSqlite3Tests/MADDataTableFastBenchmarkTests.m` 中的 `testIngestSpikeStaysBounded`（除非携带 `MAD_BENCH_ROWS` 构建，否则跳过）。在 200000 行下，内存尖峰从 49.1 MB 降至 2.5 MB（每行从 256 字节降至 13 字节），摄取耗时从 1.156 s 降至 0.975 s；自动释放池的开销约为 2%，在多次运行的波动范围内，因此整体比原先更快完成。`testRetainedFootprintDoesNotScaleWithRowCount` 则锁定另一个独立问题——自动释放池排空后是否仍有对象残留——并报告第二个包含额外 200000 行的表的内存增长为 0.0 MB。

### SQLite 引擎只按构建脚本声明的二十个选项之一编译
- **状态：** 已修复
- **提交：** `26ca18ff7`
- **位置：** `Compressor/build_sqlite3.sh:25`、`MADSqlite3/MADSqlite3.xcodeproj/project.pbxproj:571`、`:630`
- **行为：** `build_sqlite3.sh` 为 SQLite 声明了二十个编译选项——FTS5、STAT4、列元数据、8192 字节页大小、`DQS=0`、`TEMP_STORE=2` 等——但它们从未应用到实际发布的引擎上。`sqlite3.c` 并没有被编译成 `.a`；它是 `MADSqlite3` target 的源文件（`project.pbxproj:494`），而该 target 只传入了一个宏定义 `SQLITE_ENABLE_COLUMN_METADATA=1`。其余所有选项都回退到了合并源码（amalgamation）自身的 `#ifndef` 默认值。
- **为何重要：** 其中一个选项会改变磁盘上的文件。SQLite 通过由 `#ifdef` 守卫构建的表（`sqlite3.c:22411`）报告其编译选项，而构建出的框架仅列出了 `DEFAULT_PAGE_SIZE=4096` 和 `ENABLE_COLUMN_METADATA`，别无其他。页大小记录在每个写入数据库的头部，因此写入每个 `.maddb` 缓存的引擎所生成的文件与构建脚本的本意不同——而且真正遵循该脚本的第二个构建（macOS 或 CLI 工作，`LIBRARIES.md`）所写出的缓存，将是本应用会去读取却从未亲手写出的格式。至于其余选项，影响在于功能直接缺失：FTS5 永远无法使用，因为其代码根本没有编译进去。
- **现状：** 这些选项保存在 `Compressor/sqlite3.xcconfig` 中，被指定为 `MADSqlite3` target 的 Debug 和 Release 的基础配置，同时由 `build_sqlite3.sh` 读取作为其自身的 CFLAGS。一份清单，两个消费者，不会再各自偏离。重新构建后，引擎报告 `DEFAULT_PAGE_SIZE=8192`、`DQS=0`、`ENABLE_FTS5`、`ENABLE_STAT4`、`TEMP_STORE=2` 和 `THREADSAFE=1`，并在上述守卫原本完全未定义符号的地方定义了 599 个 fts5 符号。
- **随后（Compressor 重构，2026-10-04）：** 两个消费者合二为一。sqlite3 配方（`Compressor/lib/recipes/sqlite3.sh`）生成合并源码，并使用这些宏定义按架构切片编译 `libsqlite3.a`，而 `MADSqlite3` 从 `sqlite3.xcframework` 链接该归档文件——该 target 不再编译 `sqlite3.c`，也不再将该 xcconfig 指定为基础配置，因此两份清单*不可能*再次出现分歧。已针对重新构建的框架验证：编译选项字符串全部存在，且 `sqlite3Fts5Init` 已链接。fts5 *符号数量*从 599 降至 336，因为归档文件是以 `-Os` 编译的（旧计数来自 Debug `-O0` 二进制；在 `-Os` 下优化器内联消除了大部分 fts5 静态函数）——现在的存在性检查依据是初始化符号加选项字符串，而非符号计数。
- **测试：** `MADSqlite3` 测试套件——77 个测试，5 个跳过，0 个失败——但它并*没有*覆盖该选项带来的风险。`DQS=0` 移除了 SQLite 将未知的双引号词法单元当作字符串字面量读取的习惯，而本条目的早期版本曾轻率放过了这一点，声称查询构建器“对标识符加双引号并通过 `?` 绑定值，因此它的写法已经符合 `DQS=0` 的要求”。**这一说法是错误的。** `MADQueryPredicate.m:81` 和 `MADQueryCacheSelectGroupKeys.m:55` 都把*值*包裹在双引号中，且都没有使用参数绑定，因此这次提交静默导致所有带筛选条件的报表都无法刷新。参见 `## MAD（框架）` 下的条目。捕捉到该问题的检查是对示例文档运行 `mad refresh`，其中 `London.mad` 展示了这一问题：在 `DQS=0` 下为 0 行，在 `DQS=3` 下为 76 行，其余一切未变。这两处加引号的位置随后均已通过 `-newSafeLiteral:` 修复（提交 `0c187aca3`）；该条目记录了具体改动以及有意保留的一条路径。
- **首次编译该列表时还发现：**
  `SQLITE_OMIT_DECLTYPE` 与 `SQLITE_ENABLE_COLUMN_METADATA` 互斥——合并源码拒绝同时指定两者，报错 *"Must not define both SQLITE_OMIT_DECLTYPE and SQLITE_ENABLE_COLUMN_METADATA"*，因为列元数据建立在 `sqlite3_column_decltype` 之上。脚本同时要求了这两者，这根本不可能编译通过，而这本身就证明这些标志此前从未生效。`SQLITE_ENABLE_JSON1` 在 3.49 上作为空操作被移除（自 3.38 起 JSON 已成为核心的一部分），`-DNOMINMAX` 则作为 Visual C++ 遗留产物被移除。

### `MADArrayCaching -isEmpty` 和 `-count` 对空缓存返回错误结果
- **状态：** 已修复
- **位置：** `MADSqlite3/Source/MADArrayCaching.m`
- **行为：** `-isEmpty` 返回 `_numberOfRows > 0`——即缓存有行时返回 YES，与其名称含义完全相反。`-count` 计算 `max(ci) + 1`，但在空表上 `SELECT ci ORDER BY ci DESC LIMIT 1` 返回 `SQLITE_DONE`，而在已完成的语句上调用 `sqlite3_column_int64` 会读出垃圾值，导致空缓存报告 1 行而不是 0 行。两者都属于渲染缓存（`MADReportFormatter` 的 `.madac` 存储），布局期间会从中读取 `count`。
- **为何重要：** `-isEmpty` 是死代码（无调用者），属于潜在陷阱。`-count` 仅在空表/边界情形下行为异常，正常的先添加后读取流程不会触发——但如果在添加任何元素之前询问新缓存的计数，它会报告 1。
- **现状：** `-isEmpty` 改为 `_numberOfRows == 0` 并作为只读属性暴露；`-count` 在 `SQLITE_DONE` 时返回 0。死代码对 `readDataAtIndex:` / `writeData:`（原始 `NSData` 遗留代码，且 `readDataAtIndex:` 中有类型缺陷）已被删除，重复的 `MTArrayCached*` 常量已合并到 `MADArrayCaching.h` 中。高频路径 `objectAtIndex:` 还增加了按元素的内存缓存，使重复读取不必重新执行 SQLite 往返和解档。
- **测试：** `MADSqlite3Tests MADDatabaseSqlite3DatabaseTests testArrayCachingIsEmptyAndCountForEmpty` 和 `testArrayCachingRepeatedReadsReturnTheCachedObject`。

### `MADDataTableFast` 的读取事务在没有 selects 数据库时崩溃
- **状态：** 已修复
- **位置：** `MADSqlite3/Source/MADDataTableFast.m:1062-1082`
- **行为：** `-beginReadTransaction` 和 `-commitReadTransaction` 检查了 `self.databaseForSelects->_database == NULL`，但在没有缓存目录或缓存 delegate 的情况下构建的表，其 `databaseForSelects == nil`：通过 nil 对象读取实例变量会在到达句柄检查之前就崩溃。构造这样一个表并调用这一对方法会让测试进程崩溃；测试此前只能锁定前置条件（`databaseForSelects` 为 nil）。
- **为何重要：** 渲染器的绘制循环会在每次页面绘制前后调用这一对方法；任何没有缓存目录却到达绘制流程的快速表都会使应用崩溃。
- **现状：** 两个方法都只读取一次 `self.databaseForSelects`，并在它（或其句柄）为 nil 时直接返回：没有 selects 连接的表没有什么可开启或提交的事务，因此这一对方法在此时为空操作。该属性在头文件中声明为 nullable，与它一直以来的实际情况相符。
- **锁定依据：** `MADDataTableFastSelectTests testReadTransactionsWithoutASelectsDatabaseAreANoOp`（原名 `testReadTransactionsWithoutASelectsDatabaseAreNotSafe`，因为调用本身就会崩溃，原先只能锁定前置条件）。针对旧代码运行时，该调用仍会使测试进程崩溃——运行报告 "Restarting after unexpected exit, crash, or test timeout"——而在修复后通过。
- **已记录，未更改：** 相邻的几个查询路径（`-selectStatementForColumn:`、`-objectsForGroupKeys:`、`-runSelectQuery:`，位于 `:1044`、`:1250`、`:1433`）以同样方式解引用 `databaseForSelects->_database`，但它们各自都需要有 selects 连接才能开展任何工作，因此在没有该连接的表上都不会到达这些路径。

### `MADDataTableFast -whereClauseForGroupKeys:` 索引越过排序描述符
- **状态：** 已修复
- **位置：** `MADSqlite3/Source/MADDataTableFast.m:1167-1182`
- **行为：** 循环遍历分组键，并在相同索引处读取 `self.sortDescriptors[i]`；当排序描述符少于分组键时，它会越过数组末尾并抛出 `NSRangeException`。这种配对也是纯位置性的——分组键的值按索引与描述符配对，而不做任何键查找。
- **为何重要：** 该调用来自分组键缓存路径（`-objectsForGroupKeys:`），其中两个数组由不同来源构建；一旦数量不匹配就会直接崩溃，而不是生成空子句。
- **现状：** 循环上限设为 `MIN(groupKeys.count, self.sortDescriptors.count)`：处于没有对应描述符位置的分组键无法命名——因为描述符*就是*列名——所以会略过该配对并记录不足情况，而不会越界访问。能够构建出的配对与旧循环构建出的完全一致。
- **锁定依据：** `MADDataTableFastSelectTests testFewerSortDescriptorsThanGroupKeysClipsToTheDescriptors`（原名 `testFewerSortDescriptorsThanGroupKeysRaises`；针对旧代码运行时会以本条目描述的 `NSRangeException` 失败）以及保持不变的 `testGroupKeysProducePositionalColumnValuePairs`。

### `MADArrayCaching` 可能从空标识符构建缓存 URL
- **状态：** 已修复
- **位置：** `MADSqlite3/Source/MADArrayCaching.h:53-57`、`MADSqlite3/Source/MADArrayCaching.m:121`、`:284-290`
- **行为：** `-url` 将 `"madac"` 追加到 `self.identifier`，并将结果直接传给 `URLByAppendingPathComponent:`。对于空标识符，`-stringByAppendingPathExtension:` 返回 nil，而 URL API 在收到 nil 时会抛出异常，因此空标识符或缺失标识符会在构造缓存 URL 时表现为深层的 `NSInvalidArgumentException`。该类还继承了 `-init`，这会让标识符保持为 nil。
- **为何重要：** 标识符会成为磁盘上的文件名；在没有指定初始化器的情况下，该类宣传了一条永远无法正常工作的构造路径。
- **现状：** `-initWithIdentifier:cachedDelegate:types:` 被标记为 `NS_DESIGNATED_INITIALIZER`，`-init` 和 `+new` 被标记为 `NS_UNAVAILABLE`，且空标识符会在初始化时触发 `NSParameterAssert`。`-url` 仍对可空文件名做了守卫，在禁用断言检查时会返回 nil 而非抛出异常。
- **测试：** `MADDatabaseSqlite3DatabaseTests` 通过指定初始化器构造该类；完整测试套件 89/89 通过（5 个基准测试跳过）。

### `MADDataTableFast` 把可能为 nil 的值传入会抛出的路径
- **状态：** 已修复
- **位置：** `MADSqlite3/Source/MADDataTableFast.m:447`、`:562`、`:1132`
- **行为：** 三个可空值跨越了 nonnull 边界，且在为 nil 时会抛出异常：
  - `url.URLByDeletingLastPathComponent.path` 被传给 `-fileExistsAtPath:`；
  - `NSSortDescriptor.key` 被传给 `-indexOfObject:`；
  - `self.lastDataForCacheId.object` 被传给 `-initWithDictionary:`。
  静态分析器将这三处均报告为 `-Wnullable-to-nonnull-conversion`。
- **为何重要：** 没有目录的已存储缓存 URL、没有键的排序描述符，或持有 nil 的末行缓存，都会使进程崩溃，而不是给出有定义的结果。
- **现状：**
  - 目录路径先存入局部变量并做检查；无法解析的已存储 URL 会落入重新计算缓存 URL 的分支（且日志记录的是已存储的值而非 nil）；
  - 为 nil 的排序键会抛出带有指明原因消息的 `NSInvalidArgumentException`——与 `-indexOfObject:nil` 抛出的异常类型相同，但提供了可用的诊断信息；
  - 为 nil 的末行缓存对象会落入重建该行的 SQLite 查询；违反不变式的情况通过 `dispatch_once` 在每个进程中记录一次，且不在成功读取路径上。
- **测试：** `MADSqlite3Tests` 89/89（5 个基准测试跳过），包括 `MADDataTableFastSelectTests` 和数据库套件。

### `MADQueryCacheAddRow` 用 `strcat` 构建占位符列表
- **状态：** 已修复
- **位置：** `MADSqlite3/Source/MADQueryCacheAddRow.m:100-112`
- **行为：** 批量插入的 `?` 列表是用 `strcat(buf, ", ?")` 构建到固定大小的栈缓冲区中的，同时写入位置在 `buf_ptr` 中单独跟踪。静态分析器报告了 `security.insecureAPI.strcpy`（CWE-119）。
- **为何重要：** 缓冲区大小恰好按 `n` 个占位符分配，因此现有算术不会溢出，但追加操作本身是无界的，且其长度是靠假定而非返回值获得的。
- **现状：** `buf_ptr = (int)strlcat(buf, ", ?", sizeof(buf));` 对追加操作加以边界限制，并从调用返回值获取新长度。在现有大小配置下，输出与原先逐字节完全一致；Linux 镜像的 glibc 2.39 提供了 `strlcat`。
- **测试：** `MADDatabaseSqlite3DatabaseTests` 中的缓存写入路径；Linux 构建是该 libc 调用的跨平台门禁。

## MADBarcodes

### `MADBarcode -drawInRect:` 在 `self.center` 为 `YES` 时重复计算 `rect.origin`
- **状态：** 已于 2026-10-29 修复。
- **位置：** `MADBarcodes/MADBarcodes/MADBarcodes/MADBarcode.m:566-571`
- **行为：** `-drawInRect:` 先初始化 `CGFloat x = rect.origin.x;` 和 `CGFloat y = rect.origin.y;`，随后在 `if (self.center)` 内部执行：
  ```objc
  x += CGRectGetMidX(rect) - (bitmapWidth * skewValue) / 2.0000f;
  y += CGRectGetMidY(rect) - (bitmapHeight * skewValue) / 2.0000f;
  ```
  由于 `CGRectGetMidX(rect)` 等于 `rect.origin.x + rect.size.width / 2.0`，使用 `+=` 而不是 `=` 会把 `rect.origin.x` 和 `rect.origin.y` 再加一遍。
- **为何重要：** 每当 `self.center` 为 `YES` 且 `rect.origin` 非零时（例如，按元素的 frame 直接在页面上下文中绘制居中的条形码，而不是绘制到原点为零的 bounds 矩形中），条形码都会额外向右偏移 `rect.origin.x` 并向下偏移 `rect.origin.y`，绘制到 `rect` 之外。
- **现状：** 居中分支直接赋值 `x = CGRectGetMidX(rect) - ...` 和 `y = CGRectGetMidY(rect) - ...`。
- **测试：** `MADBarcodeTests testCenteredDrawWithNonZeroOriginPaintsInsideTargetRect`。

### MADBarcode 的类型名字典有重复键
- **状态：** 已于 2026-10-20 修复。
- **问题：** `MADBarcode.m` 中构建的字典字面量同时使用了 `@(MADBarcodeTypeEan14)`（`:693`）和 `@BARCODE_EAN14`（`:719`）；该枚举是 zint 宏的别名，因此两者都将值 72 装箱，第二个条目静默替换了第一个条目——"Code 128 (EAN-14)" 永远不可能被返回。
- **位置：** `MADBarcodes/MADBarcodes/MADBarcodes/MADBarcode.m:693,719`。
- **证据：** `-Wobjc-dictionary-duplicate-keys`。
- **现状：** 删除了冗余的 `@(MADBarcodeTypeEan14)` 条目，保留的 `@BARCODE_EAN14` 条目为该类型提供唯一的名称 "EAN-14"。
- **测试：** `MADBarcodeTests testDictionaryNamesAreWellFormed`。

### 两个符号学类用另一个类的类型初始化
- **状态：** 已于 2026-10-20 修复。
- **位置：** `MADBarcodes/MADBarcodes/MADBarcodes/MADBarcodeQrCodeIso18004.m`（init 和 `+type` 都返回 `MADBarcodeTypeOneCode`）以及 `MADBarcodes/MADBarcodes/MADBarcodes/MADBarcodeCode128Iso15417.m:145-161`（`MADBarcodeCode128Ean128` 的 init 赋值为 `[MADBarcodeCode128Hibc type]`——即 HIBC Code 128——而其 `+type` 却是 `MADBarcodeTypeEAN128`）
- **行为：** `+[MADBarcode newBarcodeWithType:MADBarcodeTypeQrcode]` 构建出的 `MADBarcodeQrCodeIso18004`，其 `barcodeType` 为 `MADBarcodeTypeOneCode`；工厂的 `MADBarcodeTypeEAN128` 分支构建出的 `MADBarcodeCode128Ean128`，其 `barcodeType` 为 `MADBarcodeTypeHibc128`。`-drawInRect:` 将实例的类型直接传给 `barcode->symbology`，因此每个对象绘制出的符号都与其类名所代表的符号不符——QR 码画成了 USPS Intelligent Mail，GS1-128 画成了 HIBC Code 128。
- **为何重要：** 任何请求 QR 码或 GS1-128 条形码的功能都会得到错误的符号体系和错误的载荷校验。穷举工厂矩阵发现了第二个问题；其余 63 种已映射类型均可正确往返。
- **测试：** `MADBarcodeSymbologyTests testQrCodeClassClaimsTheOneCodeType` 和 `testEan128ClassClaimsTheHibcType`，其余类型由 `testEveryMappedTypeRoundTripsExceptTheTwoKnownMismatches` 覆盖。
- **现状：** `MADBarcodeQrCodeIso18004 +type` 返回 `MADBarcodeTypeQrcode`，且 `MADBarcodeCode128Ean128 -init` 赋值为 `[MADBarcodeCode128Ean128 type]`。`+type` 也在 `MADBarcode` 上声明（基类返回 0），以便选择器可以向类询问其类型而不会触发私有 selector 警告。两个锁定测试更名为 `testQrCodeClassClaimsTheQrType` 和 `testEan128ClassClaimsTheEan128Type`；`testEveryMappedTypeRoundTripsExceptTheTwoKnownMismatches` 移除了跳过逻辑并更名为 `testEveryMappedTypeRoundTrips`，现在覆盖全部 65 种已映射类型。

### `MADBarcodeInternationalStandardBookNumberIsbn +type` 调用自身
- **状态：** 已于 2026-10-20 修复。
- **位置：** `MADBarcodes/MADBarcodes/MADBarcodes/MADBarcodeInternationalStandardBookNumberIsbn.m`
- **行为：** 该类方法的方法体是 `return [MADBarcodeInternationalStandardBookNumberIsbn type];`——调用自身，因此任何调用都会无限递归直至栈耗尽。初始化器没有问题（直接赋值 `MADBarcodeTypeIsbnX`），因此工厂路径可以工作；只有该类方法访问器是个陷阱。
- **为何重要：** 枚举各个符号学类以获取其 `+type` 的通用调用者（构建选择器的自然方式）会在 ISBN 条目上使进程崩溃。
- **测试：** `MADBarcodeSymbologyTests testIsbnClassInitializesToItsOwnType` 仅测试工厂路径；有意不调用 `+type`。
- **现状：** `+type` 返回 `MADBarcodeTypeIsbnX`。工厂路径测试保持不变，新增的 `MADBarcodeSymbologyTests testIsbnClassTypeReturnsItsOwnType` 直接调用 `+type`。

### `MADBarcode` 的 NSCoding 往返丢失一切
- **状态：** 已于 2026-10-20 修复。
- **位置：** `MADBarcodes/MADBarcodes/MADBarcodes/MADBarcode.m:376-408`
- **行为：** `-encodeWithCoder:` 将所有属性都写入同一个空键（`@""`）下，因此归档中只有最后一个值能留存下来；`-initWithCoder:` 完全忽略解码器，只调用 `[super init]`。因此解码出的条形码只是正确类的默认实例——连子类的 `-init` 默认值都不会生效，因为 `[super init]` 跳过了它们。该类遵循 `NSCoding` 而非 `NSSecureCoding`，因此安全归档会直接拒绝它。
- **为何重要：** 目前没有任何地方对条形码进行归档，因此这是潜在缺陷；一旦首次持久化条形码就会出问题。
- **测试：** `MADBarcodeTests testNSCodingRoundTripLosesTheState`。
- **现状：** 每个 `MADBarcodeProtocol` 属性、两个输入（`input`、`primaryData`）以及子类状态（`name`、`detailsSegueIdentifer`、`has2dComponent`、`hasOptionalInput`、`center`、`width`、`has2dComponentType`、`rotate`）都使用各自的字符串键进行编码和解码；`-initWithCoder:` 通过 `[self init]` 派发，使子类自己的初始化器在应用归档值之前运行。该类声明遵循 `NSSecureCoding`，并使用 `-decodeObjectOfClass:forKey:` 解码字符串。在整个工作区中 grep 未发现对条形码对象使用归档器的情况，因此旧格式无需兼容路径。锁定测试更名为 `testNSCodingRoundTripPreservesTheState`。

### `MADBarcode -drawInRect:` 未经检查地把用户输入复制到 `primary[128]`
- **状态：** 已于 2026-10-20 修复。
- **位置：** `MADBarcodes/MADBarcodes/MADBarcodes/MADBarcode.m:492`（`strcpy(barcode->primary, primaryData)`），对照 `Compressor/library/zint/include/zint.h:121`（`char primary[128]`）
- **行为：** 当启用 `has2dComponentEnabled` 时，用户的第二个输入会用 `strcpy` 复制到 zint 固定 128 字节的 `primary` 缓冲区中——之前没有长度检查，这与通过 `ZBarcode_Encode_and_Buffer` 接受长度参数的 API 传入的主载荷不同。
- **为何重要：** 128 字节或更长的 primary-data 字符串会使结构体缓冲区溢出。未在测试中触发：其失败模式是内存损坏，而非断言。
- **测试：** 无，有意为之。
- **现状：** 在复制前将 UTF-8 长度与 `sizeof(barcode->primary)` 进行比较；超长值会被记录日志、跳过 `ZBarcode_Encode_and_Buffer` 并走普通错误路径——当启用 `showErrorMessage` 时绘制错误文本，且无论哪种设置都不绘制符号。`MADBarcodeTests testOverlongPrimaryDataIsRefused` 用 200 字节的输入覆盖了两种设置。

## MADMySQL

### 抓取操作根据第一行修正了列的类型
- **状态：** 已于 2026-10-18 修复（提交 `483a77259`）。
- **位置：** 原位于 `MADMySQL/Source/MADMySQLFetch+DataTable.m` 的 `MYSQL_TYPE_*_BLOB` 抓取分支：在第一行解码字节，当字节可读作 UTF-8 时，将缓存列的 `type` 修改为 String（一个死掉的 NSNumber 分支会将其修改为 Integer）。
- **行为：** 列的类型取决于其第一行的内容，而在类型改变时，缓存表早已按原先的类型亲和性（affinity）创建完毕。在分组键契约（每个声明类型对应唯一的规范类，并在绑定时强制执行）下，按行决定类型的做法无法立足。
- **现状：** TEXT 和 BLOB 共用类 blob 的协议类型；区分它们的是列的字符集——binary（63）是 BLOB，其余均为 TEXT。现在这一判定在创建表之前的 `+[MADMySQLFetch dataColumnForFieldName:mySqlField:]` 中一次性完成，抓取分支对 BLOB 列存储字节，对 TEXT 列解码 UTF-8（空文本与以前一样存储 NULL——空 NSData 没有字节）。字节恰好能解码为 UTF-8 的二进制 BLOB 现在会被当作数据而非文本——这是正确的解读，对此类列而言也是用户可见的变化。
- **测试：** 实机套件（`MADMySQLLiveTests`）覆盖了抓取流程；对于可解码为文本的二进制 blob 没有基于内容的固定夹具，因此字符集判定改由 `MADSqlite3Tests/MADDatabaseSqlite3BindingTests.m` 中的绑定路径契约测试锁定。

### `MADMySQLFetch+DataTable`：非 SELECT 语句永远无法执行
- **状态：** 已修复
- **位置：** `MADMySQL/Source/MADMySQLFetch+DataTable.m`
- **行为：** `mysql_stmt_bind_result` 被无条件调用。对于任何 `field_count == 0` 的语句——每一个 `INSERT`、`UPDATE`、`DELETE`、`CREATE`、`DROP`——都会在客户端以错误码 3534 失败，从而在到达 `mysql_stmt_execute` 之前中止调用。通过 `MADMySQLFetch` 执行的所有 DDL 和 DML 都静默地什么也没做。
- **为何重要：** `MADDatabaseMySQL -executeSQL:...` 以及 `MADMySQLInsert`/`MADMySQLUpdate`/`MADMySQLDelete`/`MADMySQLTruncate` 构建器全都经过这条路径，因此 MySQL 驱动的整个写入侧当时都是死路。

### `MADMySQLFetch+DataTable`：抓取出错时行循环无限空转
- **状态：** 已修复
- **位置：** `MADMySQL/Source/MADMySQLFetch+DataTable.m`
- **行为：** 行循环仅在 `MYSQL_NO_DATA` 时终止。对于没有结果集的语句，`mysql_stmt_fetch` 返回 `1`（`stmt_read_row_no_result_set` → `set_stmt_error`）而非 `MYSQL_NO_DATA`，导致循环永远不会退出。通过对卡在 98% CPU 的测试运行进行栈采样发现。
- **为何重要：** 一条异常语句就会让应用线程挂死，既无错误提示也无法退出。循环现在会在遇到任何既非数据行也非截断的结果时结束。

### `MADMySQLFetch+DataTable`：`MYSQL_TYPE_INT24`（MEDIUMINT）把 4 字节当作 8 字节读取
- **状态：** 已修复
- **位置：** `MADMySQL/Source/MADMySQLFetch+DataTable.m`，`-fetchResultsFromConnection:`
- **行为：** `MYSQL_TYPE_INT24` 分支没有 `break`，直接落入了 `MYSQL_TYPE_DECIMAL`/`MYSQL_TYPE_DOUBLE` 分支，将 4 字节的 `int` 缓冲区当作 8 字节的 `double` 重新读取。这是堆越界读取，并且会用垃圾值覆盖掉原本正确的值。
- **为何重要：** MEDIUMINT 列会返回无意义的垃圾数据。现已通过探测表的实机往返测试覆盖。

### `MADMySQLFetch+DataTable`：绑定和执行失败从未被报告
- **状态：** 已修复
- **位置：** `MADMySQL/Source/MADMySQLFetch+DataTable.m`，`-fetchWithCommand:...`
- **行为：** 两个失败分支都构建了 `NSError`，却从未将其赋值给调用者的 `*error` 输出参数，因此绑定或执行失败与成功无法区分。nil 连接分支也有同样的问题。
- **为何重要：** 这正是上面那个 DDL 缺陷能够隐藏如此之久的原因：语句根本没运行，却没有任何地方报错。

### `MADMySQLFetch+DataTable`：`MYSQL_TYPE_NULL` 让其输出参数未初始化
- **状态：** 已修复
- **位置：** `MADMySQL/Source/MADMySQLFetch+DataTable.m`，`-bindDataForStatement:andField:`
- **行为：** `MYSQL_TYPE_NULL` 分支仅设置了 `buffer_type` 和 `buffer`，随后落入 `default:` 并触发 `NSAssert(NO, ...)`。`length`、`error` 和 `is_null` 指针都被留作未初始化的栈垃圾值，而行循环会解引用 `*bindings[x].is_null`。
- **为何重要：** `SELECT NULL`——即任何即席查询中的字面量 `NULL`——在 debug 构建中会触发断言，在 release 构建中则会解引用野指针。

### `MADMySQLFetch+DataTable`：错误路径上绑定和语句泄漏
- **状态：** 已修复
- **位置：** `MADMySQL/Source/MADMySQLFetch+DataTable.m`，`-fetchWithCommand:...`
- **行为：** `free()` 调用和 `mysql_stmt_close` 位于仅成功时才进入的分支内部，因此一旦绑定或执行失败，每次调用都会泄漏由 `calloc` 分配的绑定缓冲区和 `MYSQL_STMT`。
- **为何重要：** 每条失败语句都会发生内存泄漏。一旦失败的 DML 能够实际运行，该路径就变得可达。

### `MADMySQLFetch`：`mySQLTypeForType` 对三种类型返回错误名称
- **状态：** 已修复
- **位置：** `MADMySQL/Source/MADMySQLFetch.m`
- **行为：** `MYSQL_TYPE_MEDIUM_BLOB` 和 `MYSQL_TYPE_LONG_BLOB` 都返回 `"MYSQL_TYPE_DECIMAL"`（复制粘贴错误），而 `MYSQL_TYPE_LONGLONG` 根本没有分支，直接落入 `"Unknown"`。
- **为何重要：** 仅用于诊断，但这正是遇到未映射类型时 `NSAssert` 消息中的字符串，因此会严重误导调试。

### `MADDataTypeMySQL` 的映射对三种类型有损
- **状态：** 已修复（三种类型均已作出决定——两种已修正，一种有意保留）
- **位置：** `MADMySQL/Source/MADDataTypeMySQL.m`
- **行为：** `MYSQL_TYPE_TIME` 映射到了 `MADDataTypeDateTime`（而非专用的 `MADDataTypeTime`）；`MYSQL_TYPE_NULL` 映射到 `MADDataTypeNumber`（而非 `MADDataTypeNull`）；`MYSQL_TYPE_INT24` 映射到了 `MADDataTypeInteger`（而非 `MADDataTypeInt24`）。这三个专用枚举值都是存在的。
- **调用者分析（2026-10-01）及各自决定：**
  - **INT24——已修正。** 所有消费者都将 `MADDataTypeInt24` 与 `MADDataTypeInteger` 归为一类（`MADDatabaseField.m -isDataTypeNumeric`、sqlite3 绑定 switch、`RptqDocumentElement+Extras.m:1074` 值格式化），因此使用专用枚举值在行为上保持中立且更加准确。已更新测试：`MADMySQLTests.m`、`MADMySQLLiveTests.m:594`。
  - **TIME——已修正。** `MYSQL_TYPE_TIME` 现在映射到 `MADDataTypeTime`。该映射是可达的（`MADDatabaseMySQL.m:247` 用它设置每个架构字段的 `fieldType`），而且其错误会明显表现出来：`MADMySQLFetch+DataTable.m:431` 仅根据时/分/秒构建值，因此生成的 `NSDate` 带有日历默认的任意日期，而 `RptqDocumentElement+Extras.m:1008-1076` 通过 `dateTimeformatter` 渲染 `MADDataTypeDateTime`——把该值根本没有的日期部分也渲染了出来。`MADDataTypeTime` 是现役分支而非休眠分支：SQL Server 驱动早在此次改动之前就会产出它，且其实机套件断言了这一点（`MADDatabaseSQLServer.m:174`、`:251`），因此仅显示时钟的分支是经过检验的。唯一用户可见的变化是 MySQL 的 TIME 列现在显示为时间，而不是 "1/1/01, 1:45 PM"。已更新测试：`MADMySQLTests.m`。
  - **NULL——有意保留。** `MYSQL_TYPE_NULL` 保持为 `MADDataTypeNumber`。`MADDataTypeNull` 根本不是列类型：它是*绑定*用的 null，由 `MADDatabaseDataBinding.m:141`/`:157` 为空参数产出，并由 `MADQuery+Sqlite3.m:66` 消费。它在 `RptqDatabaseSchemaField+Extras.m` 中没有显示分支，因此携带它的架构字段会渲染为 "Type 24"（`MADRptqDatabaseTests.m:45`）。原生类型为 NULL 的列永远不可能持有值，因此该映射只是在挑选架构标签和格式化分支，而对这两者而言 `MADDataTypeNull` 都是错误的。这是明确决定，而非推迟处理。由 `MADMySQLTests.m` 的 `-testDataTypeForNativeTypeMapsNullToNumber` 锁定。

### `MADMySQLFetch+DataTable` 的注释声称不支持 SMALLINT/MEDIUMINT/BIT
- **状态：** 已修复
- **位置：** `MADMySQL/Source/MADMySQLFetch+DataTable.m:139`
- **行为：** 绑定循环上方的注释块称这些类型 "not handled currently - exception will occur if used"，但这三种类型都有对应的 `bindDataForStatement:` 分支和抓取分支，且能正常工作。
- **为何重要：** 该注释会误导人不去使用本来完全正常的类型。
- **现状：** 这三行注释改为指明每种类型实际经过的绑定类型（`MYSQL_TYPE_SHORT`、`MYSQL_TYPE_INT24`、`MYSQL_TYPE_BIT`），与上方条目的注释风格保持一致。

### MySQL 字面量中的反斜杠是转义字符，因此仅靠 ANSI 引号是错误的
- **状态：** 已修复
- **位置：** `MADMySQL/Source/MADDatabaseMySQL.m`（`-newSafeLiteral:`，以及 `-connectWithConnection:credentals:connectionError:`、`-executeSQL:fieldKeys:onConnection:intoResultTable:withError:`、`-executeQuery:withDataTable:andError:`、`-getTables:` 和 `-closeConnection:` 中的连接生命周期）
- **行为：** `-newSafeLiteral:` 从 `MADDatabase` 继承了基类的 ANSI 引号规则——用 `'…'` 包裹并将内部单引号双写——这对 SQLite 和 T-SQL 是正确的，但对 MySQL 是错误的，因为在 MySQL 字面量内部，反斜杠是转义字符。值 `C:\temp` 被写作 `'C:\temp'`，被服务器读回时变成了 `C:<TAB>emp`。这是实测结果而非纸面推理：下方测试的失败输出打印出 `("C:\temp") is not equal to ("C:	emp")`，其中包含制表符。该转义问题此前记录在上面的 `MADQueryPredicate` / `MADQueryCacheSelectGroupKeys` 条目中，并在那里保持未修复，因为修复它需要本驱动当时尚不具备的机制。
- **为何重要：** 只有 `mysql_real_escape_string` 知道给定会话如何解释反斜杠，而它需要一个活动连接。本驱动原本每次查询都打开一个连接，用完即弃，从不在 `self` 上保留它，因此到 SQL 构建器运行 `-newSafeLiteral:` 时，根本没有可询问的会话。任何针对包含反斜杠的值（UNC 路径、Windows 路径、正则表达式）的筛选条件都会静默地与被篡改的字符串作比较，而且精心构造用来提前闭合自身字面量的值也毫无阻拦。
- **现状：** 在查询构建和运行期间，连接会一直保存在 `self` 上：`-connectWithConnection:credentals:connectionError:` 保留它打开的会话，而经过它的各个查询入口点会在结束时将其释放——`-executeSQL:…`、`-executeQuery:withDataTable:andError:`、`-getTables:` 和 `-closeConnection:`，每个都由 `dbconn == self.liveConnection` 守卫，以确保绝不会丢弃非本驱动拥有的连接。驱动仍然不持有空闲连接；改变的只是打开与运行之间的时间窗口。当会话存在时，`-newSafeLiteral:` 通过该会话进行转义；不存在时（例如在从未建立连接的预览中构建 SQL），则回退到基类实现，这与驱动此前的输出相同，对这类值而言不会比以前更差。句柄仍由 `MADMySQLConnection -dealloc` 释放：传给 `mysql_init` 的是由我方 `calloc` 分配的内存，因此客户端的 `free_me` 为 false，`mysql_close` 不会释放它。
- **测试：** `MADMySQLLiveTests testNewSafeLiteralEscapesABackslashThroughTheLiveSession` 和 `testNewSafeLiteralEscapesAnApostropheThroughTheLiveSession`。两者都按查询的方式建立连接，向驱动索取字面量，然后让服务器将其读回——`SELECT <literal> AS v`——因为只有服务器的读取结果才能证明转义有效。两者均已确认在旧行为下会失败并打印出制表符。离线测试 `MADMySQLTests testNewSafeLiteralWithoutASessionFallsBackToAnsiQuoting` 则锁定了无会话路径（连同反斜杠行为），使这一局限性被明确声明而非隐含。

### `MADMySQLUpdate -execute` 抛出越界字符串异常，而不是它自己的错误
- **状态：** 已修复
- **位置：** `MADMySQL/Source/MADMySQLUpdate.m:56-62`（`-execute` 中的三个守卫）
- **行为：** 两个缓冲区在构建时都带有前导分隔符，随后用 `deleteCharactersInRange:NSMakeRange(0, 2)` / `NSMakeRange(0, 4)` 进行裁剪。没有任何逻辑保证任一缓冲区至少有那么多字符：

  - 没有 `rowData`（或为空字典）→ 列表仍为空 → 删除两个字符会抛出 `NSInvalidArgumentException`（"Range or index out of bounds"）；
  - 有 `rowData` 但没有 `qualifier` → WHERE 子句仍为空 → 删除四个字符会以同样方式抛出异常。

  该类本意是报告 "table must be specified"（对于缺失的表确实如此），并对缺失的限定条件也需要同等报告，但两个守卫都未能到达。
- **为何重要：** 构建更新语句时漏掉限定条件是经典的“忘了写 WHERE 子句”错误；它没有给出诊断信息，反而以指明 `__NSCFString` 而非调用者错误的异常使进程崩溃。（*静默*丢失限定条件会更糟——报错正是目的所在。）
- **现状：** `-execute` 在构建任一缓冲区之前先对两者加以守卫：没有行数据和没有限定条件会分别抛出该类自己的 `MADMySQLException`——*row data must be specified to perform an update* 和 *a qualifier must be specified to perform an update*——形式与旁边的表守卫在 nil 连接下一致。2026-10-25 的连接器重写在不使用前导分隔符裁剪的情况下重构了语句构建，因此旧代码所裁剪的缓冲区已不复存在；这些守卫、其错误字符串及测试均保持不变，“忘了写 WHERE 子句”的更新会被带有诊断信息的异常拒绝，而不会触发 `__NSCFString` 范围异常。
- **锁定依据：** `MADMySQLUpdateTests testExecuteWithoutRowDataRaisesTheUpdatesOwnError`（原名 `testExecuteWithoutRowDataRaisesAnInvalidArgumentException`）和 `testExecuteWithAnEmptyRowDataDictionaryRaisesTheSameWay`，两者均已确认在旧代码下失败；外加新增的 `testExecuteWithoutAQualifierRaisesTheUpdatesOwnError`，其未捕获的 `NSInvalidArgumentException` 在旧代码下同样会失败。实机测试 `MADMySQLLiveTests testUpdateWithoutAQualifierRaisesTheUpdatesOwnError`（已重命名）针对真实服务器运行同一守卫——它现在会在旧崩溃所需的会话调用之前就抛出异常，但仍将实机连接保持在测试环路中。两个 Linux 移植版本均包含相同的测试。

### `MADMySQLConnection +connectToServer:error:` 通过 NULL 错误指针写入
- **状态：** 已修复
- **位置：** `MADMySQL/Source/MADMySQLConnection.m:56-64`（`+connectToServer:error:`）
- **行为：** 在 `internal_connectToServer:outError:` 返回非 nil 的 `connectionError` 后，该方法未检查 `error` 就直接执行了 `*error = [connectionError copy]`。`internal_connectToServer:outError:` 以及邻近的 `:157` 都将该指针视为可选参数，因此针对不可达服务器调用 `+connectToServer:error:NULL` 会解引用 NULL 并导致进程崩溃。静态分析器将其报告为 `osx.cocoa.NSError`。
- **为何重要：** 只关心连接结果的调用者没有安全的办法选择不接收错误对象。
- **现状：** 写入操作由 `if (error != NULL)` 守卫。所有传入错误指针的调用者行为与之前完全一致；传入 NULL 指针则表示完全不需要错误对象。
- **测试：** `MADMySQLTests testConnectToServerWithNoListenerAndANULLErrorPointerDoesNotCrash`（新增；旧代码在此崩溃）以及针对非 NULL 路径的 `testConnectToServerWithNoListenerFailsCleanly`。

### `MADMySQLConnection` 的事务开关在没有句柄的连接上崩溃
- **状态：** 已由第一方连接器重写修复（2026-10-25，`c46201465`）
- **位置：** `MADMySQL/Source/MADMySQLConnection.m:157-186`（`enableTransactions`、`disableTransactions` 以及旁边的 commit/rollback 一对方法）
- **行为：** 旧类在 `-init` 之后让其句柄保持为 NULL，而这些开关方法不经检查就调用 `mysql_autocommit` / `mysql_commit` / `mysql_rollback`。`mysql_autocommit` 会解引用该句柄，因此 `[[MADMySQLConnection alloc] init]` 后紧跟 `-enableTransactions` 会导致进程崩溃（已验证：测试进程在该调用处直接终止，没有可捕获的异常）。
- **为何重要：** 仅属潜在缺陷。所有生产路径都从 `+connectToServer:…` 获取连接，后者在失败时返回 `nil` 而非无句柄对象，且代码树中没有调用者调用这些事务方法——它们是为查询缓存和可移植存储预留的 API。陷阱在于该类是可以 `init` 的，看起来可以直接使用；注意邻近的访问器（`-errorNumber`、`-errorText`）原本就是 NULL 安全的，这使得此处的遗漏显得像是前后不一致而非有意为之。
- **现状：** 重写后的 `-init` 会预先分配句柄（`calloc` + `mysql_init`，由 `-dealloc` 释放），因此每个变更会话的命令都有一个可供失败的句柄，这些开关方法会抛出 `MADMySQLException`（commit/rollback 一对方法抛出各自的子类）而不会解引用 NULL。无服务器的连接现在会抛出可捕获的异常，而不再使进程崩溃。
- **测试：** `MADMySQLTests testErrorAccessorsOnAConnectionWithoutAServer` 和 `testTransactionsFlagStartsOff` 仍然锁定安全的那一半行为。旧的崩溃无法用断言测试——它会直接终止测试进程，因此无从捕获。

### `MADMySQLFetch+DataTable` 在 default 分支读取未初始化的 `MYSQL_BIND`
- **状态：** 已修复
- **位置：** `MADMySQL/Source/MADMySQLFetch+DataTable.m:499`、`:668`（`+bindDataForStatement:andField:`）
- **行为：** `MYSQL_BIND binding;` 未经初始化，而 `default:` 分支在尚未赋任何值之前就在 `NSAssert` 内部求值 `mySQLTypeForType(binding.buffer_type)`。静态分析器报告了 `core.CallAndMessage`。default 分支返回的结构体中，`length`、`error` 和 `is_null` 字段同样未经初始化。
- **为何重要：** 一旦进入 default 分支（遇到不支持的列类型），就会读取不确定的内存；在 Debug 构建下，断言本身就会读取未初始化内存。
- **现状：** `MYSQL_BIND binding = {0};` 将结构体零初始化，因此 switch 未赋值的每个字段在所有路径上都为零。`MYSQL_TYPE_NULL` 分支仍然填充三个输出参数缓冲区。唯一可观察到的差异是不支持类型路径上的 Debug 断言文本（现在会指明 DECIMAL，即枚举值 0，而非垃圾值）。
- **测试：** 实机套件的 SELECT NULL 和类型转换用例；对于驱动支持的 SQL 类型，default 路径不可达。

## MADTdsClient

### `-getTables:` 把 process 包装器当作 `DBPROCESS` 传给 freetds
- **状态：** 已修复
- **位置：** `MADTdsClient/Source/MADDatabaseSQLServer.m:241`
- **行为：** `-connectWithConnection:credentals:connectionError:` 返回一个包装了 `DBPROCESS` 的 `MADDatabaseProcessSQLServer`，但代码把该对象直接桥接转换为 `DBPROCESS *` 并交给 `dbcmd()`。随后 freetds 在 Objective-C 对象内部的某个偏移处执行 realloc，而不是在其命令缓冲区中执行，导致每次调用都会中止进程：`tds_realloc → dbcmd → -[MADDatabaseSQLServer getTables:]`。现在在第一次调用 freetds 之前会先通过 `-process` 解包该包装器。
- **为何重要：** 该方法根本无法工作，而且它会直接拖垮整个宿主进程，而不是返回错误——连接创建流程正是唯一调用它的地方。

### 每个 `DECIMAL` / `NUMERIC` 值都会丢失或损坏
- **状态：** 已修复
- **位置：** `MADTdsClient/Source/MADDatabaseSQLServer.m:1043`（`case SYBDECIMAL: case SYBNUMERIC:`）
- **行为：** 分隔符检测代码块通过修剪值字符串两端的十进制数字来推导出一个“分隔符”，然后仅当这个虚假的分隔符与当前区域设置的分隔符不同时，才会给工作副本赋值：

  ```objc
  NSString *objectStr2 = nil;
  if (tdsDecimalSeperatorMatchesCocoaDecimalSeperator == NO) {
      objectStr2 = [objectStr stringByReplacingOccurrencesOfString:...];
  }
  NSDecimalNumber *decimalNumber = [[NSDecimalNumber alloc] initWithString:objectStr2];
  ```

  当不需要替换时，`objectStr2` 保持为 `nil`，而在 `nil` 上调用 `-initWithString:` 会返回 `notANumber`。该值被丢弃。负数的情况更糟：`"-2.5"` 推导出的分隔符是字面量 `"-2."`，它出现在正在重写的字符串内部，因此 `"-2.5"` 变成 `".5"` 并被报告为 `0.5`——一个看似合理却静默错误的数值。
- **对服务器验证：** 对于测试所使用的表达式，`sqlcmd` 返回 3.5、1.00 和 123.456；数据丢失发生在框架内。
- **为何重要：** 任何建立在 `DECIMAL` 或 `NUMERIC` 列上的报表都会显示 `NaN`，或者显示错误的值，且没有任何失败迹象。
- **现状：** 分隔符通过扫描第一个既非数字也非前导正负号的字符来查找，因此 `"-2.5"` 得到 `"."` 而不是 `"-2."`；值字符串的工作副本默认取该值本身而不是 `nil`；并且仅当存在需要替换的分隔符时才执行替换。`-2.5`、`3.5`、`1.00` 和 `123.456` 都能解码为它们的服务器值。
- **测试：** `testSelectDecimalReturnedValues` 和 `testSelectNegativeDecimalKeepsItsSign`（重命名自表征测试 `testSelectDecimalReturnsNotANumber` / `testSelectNegativeDecimalReturnsCorruptedValue`），外加 `testTypeConversionRoundTrip` 的 DECIMAL 列。

### `-fieldsForTable:connection:error:` 把 sybdb 类型代码送入 SQL Server 类型 id 的表中
- **状态：** 已修复
- **位置：** `MADTdsClient/Source/MADDatabaseSQLServer.m:1993`
- **行为：** 查询选出 `sys.columns.system_type_id` 并将其传给 `+dataTypeForNativeType:`，而后者是针对 sybdb（`SYB*`）代码编写的。这两套编号方案仅在旧类型上重合，因此映射正确的部分纯属巧合。`DECIMAL` 在两套方案中都是 106——而 106 没有对应的 case，于是落入 `default` 并报告为 `String`。`VARBINARY` 是 165，根本不是 sybdb 代码，因此也报告为 `String`。与查询路径不同，这里没有 `SYBDECIMAL → SYBNUMERIC` 重写来挽救它。
- **现状：** 专用的 `+dataTypeForSystemTypeId:`（`.m:226`）按 `sys.columns.system_type_id` 自身的定义将其映射到 `MADDataType`，并由 `-fieldsForTable:` 调用它。`Weight`（106）为 `MADDataTypeDecimal`，`ThumbNailPhoto`（165）为 `MADDataTypeBlob`。
- **测试：** `testFieldsForTableMapsDecimalAndBinary`（重命名自 `testFieldsForTableMisreportsDecimalAndBinaryAsString`），外加 `MADTdsClientTests.m` 中新增的 `+dataTypeForSystemTypeId:` 测试用例。

### `+dataTypeForNativeType:` 对若干现役 SQL Server 类型没有分支
- **状态：** 已修复
- **位置：** `MADTdsClient/Source/MADDatabaseSQLServer.m:156`
- **行为：** `SYBDECIMAL`（106）、`SYBDATE`（49）、`SYBTIME`（51）、`SYBMONEY4`（122）、`SYBMSDATE`（40）、`SYBMSTIME`（41）、`SYBMSDATETIME2`（42）、`SYBMSDATETIMEOFFSET`（43）、`SYBBIGDATETIME`（187）和 `SYBBIGTIME`（188）全部落入 `default` 并变成 `MADDataTypeString`。在查询路径上，`-runSQL:` 会在调用该方法前重写类型代码，从而挽救 `SYBDECIMAL` 和 `SYBMONEY4`，但没有任何逻辑重写 2005 之后的日期/时间类型。
- **为何重要：** `DATE`、`TIME`、`DATETIME2` 和 `DATETIMEOFFSET` 列被归类为字符串，因此设计器中的日期分组、格式化和比较都不适用于它们。
- **现状：** 全部十个代码都有了分支。`SYBDECIMAL` 与 `SYBNUMERIC` 一道归为 `MADDataTypeDecimal`；`SYBMONEY4` 与其他货币代码一道归为 `MADDataTypeFloat`；`SYBDATE`/`SYBMSDATE` 为 `MADDataTypeDate`；`SYBTIME`/`SYBMSTIME`/`SYBBIGTIME` 为 `MADDataTypeTime`；`SYBBIGDATETIME`/`SYBMSDATETIME2`/`SYBMSDATETIMEOFFSET` 为 `MADDataTypeDateTime`。
- **现状（2026-10-01，值）：** 这些现代类型代码也能携带各自的值，且无需绑定数组即可完成。freetds 将每个值保存在行缓冲区中，其布局只有该类型代码才能解释，因此行转换将缓冲区连同列自身的类型代码直接交给 `dbanydatecrack()`；NULL 读回为空指针，与 `SYBDATETIME` 分支原本依赖的信号一致。这正是 freetds 自己打印此类列时所做的调用（`src/dblib/dblib.c`，`dbspr1row`）。绑定的形态是错误的：这些代码的绑定常量写入的是*转换后的*布局，而不是 `dbanydatecrack()` 读取的布局。
- **测试：** 离线套件中的 `testDataTypeForNativeTypeMapsModernDateTimeFamily`、`testDataTypeForNativeTypeMapsNumericToDecimal` 和 `testDataTypeForNativeTypeMapsMoneyAndFloatingPointToFloat`，以及实机套件中的 `testSelectModernDateTimeTypes`（值）和 `testSelectModernDateTimeTypesNull`（NULL）。

### 每个 SQL `DATETIME` 读回时晚一个月
- **状态：** 已修复
- **位置：** `MADTdsClient/Source/MADDatabaseSQLServer.m:1330` 和 `:1354`（行转换中的 `case SYBDATETIME` 和 `case SYBDATETIMEN`）
- **行为：** 两个分支都执行了 `comps.month = dateinfo.datemonth + 1`。freetds 填充的记录在返回前*已经*偏移到了从 1 开始的 Microsoft 月份——当 `DBPROCESS` 处于 MS 模式（当前构建正是如此）时，`dblib_datecrack()` 会把 `datemonth` 加一——因此额外的 `+ 1` 把一月算了两次。针对实机服务器实测：`CAST('2020-01-15T13:45:00' AS DATETIME)` 返回为二月，而 `CAST('2020-12-15T13:45:00' AS DATETIME)` 返回为 **2021**-01-15。
- **为何重要：** 在已发布的驱动中，来自 SQL Server 的每个 `DATETIME` 和 `SMALLDATETIME` 家族的值都偏移了一个月，而十二月的值还会跨年。下游没有任何补偿逻辑：这种偏移在值本身中看不出来，只有将报表与数据库对比时才会暴露。
- **现状：** 两个分支都按原样读取传入的 `dateinfo.datemonth`，并附有注释说明原因。该问题是在修复上述经过同一条 freetds 记录的 2005 之后日期/时间值时发现的。
- **未更改：** `SYBDATETIME4` 不使用拆解后的记录——它自己做天数/分钟算术——因此不受影响。它的基准日期则是另一回事；见相关说明。
- **测试：** 实机测试 `testSelectClassicDateTimeKeepsItsMonth`，锁定一月仍为一月、十二月留在其原本年份。

### `-connectWithConnection:credentals:connectionError:` 从不报告其错误
- **状态：** 已修复
- **位置：** `MADTdsClient/Source/MADDatabaseSQLServer.m:1593`
- **行为：** `error = &dberror;` 将参数重新绑定到了局部变量，因此调用者的输出参数从未被写入。这也意味着外围的 `if (error && dberror)` 在发生失败时恒为真，于是本会生成包装器的 `else` 分支被跳过，方法返回 `nil`——这是调用者得到的唯一失败信号。
- **为何重要：** 调用者传入 `NSError **` 却什么也得不到，因此连接失败与任何其他返回 nil 的情况无法区分。这是造成 SQL Server 创建报表静默失败的两个原因之一。
- **现状：** 该方法将底层 `dberror` 穿透写入调用者的指向位置（有非 NULL 守卫），并照常将其插入 `self.errors`。
- **测试：** `testConnectWithConnectionReportsErrorToCaller`（重命名自表征测试 `testConnectWithConnectionDoesNotReportErrorToCaller`），现在断言错误非 nil 且属于 `MTDatabaseTds` 域。

### `-connect:andPassword:error:` 解引用 `*error` 时没有 NULL 检查
- **状态：** 已修复
- **位置：** `MADTdsClient/Source/MADDatabaseSQLServer.m:1602`
- **行为：** 失败路径的第一条语句是 `if (*error != NULL)`，且后续多条路径直接对 `*error` 赋值。传入 `NULL` 的调用者——即 Cocoa 文档约定的“我不关心错误”——会崩溃。
- **为何重要：** 只想拿到 `DBPROCESS *` 的调用者恰恰会传入 `NULL`。
- **现状：** 该方法使用 `NSError * __autoreleasing *err`，当调用者提供了指针时作为其别名，未提供时指向一个临时局部变量，所有赋值都通过 `*err` 进行。`dbinit` 失败处写反了的 `if (*error != NULL)` 守卫也随之移除。

### `-fieldsForTable:connection:error:` 有会解引用已知 NULL 指针的死错误处理
- **状态：** 已修复
- **位置：** `MADTdsClient/Source/MADDatabaseSQLServer.m:1993`
- **行为：** 有一个分支写着 `if (sqlReturnCode != SUCCEED && error == NULL) { if (error != NULL) {...} NSAssert(error == NULL, @"...", *error); }`——在一个已经确立 `error == NULL` 的代码块内，内层判断永远不可能为真，而断言的消息参数无论如何都会解引用 `*error`。
- **为何重要：** 这段代码本想处理的失败根本没有被报告；代码只是看起来像处理了而已。
- **现状：** 当返回值不是 `SUCCEED` 时，该方法向调用者的指向位置写入一个代码为 `3456`、描述语法失败的 `MADDomainTDS` 错误（有非 NULL 守卫）。`MADTdsClientLiveTests` 针对服务器演练了这一分支。

### `port` 从未传给 freetds
- **状态：** 已修复
- **位置：** `MADTdsClient/Source/MADDatabaseSQLServer.m:1602`
- **行为：** `MADDatabaseConnectionSQLServer` 带有 `port` 并将其包含在 `connectionString` 中，但 `-connect:andPassword:error:` 只调用了 `DBSETLUSER`、`DBSETLPWD`、`DBSETLAPP` 和 `DBSETLDBNAME`。从未调用 `DBSETLPORT`，因此 freetds 总是拨打默认端口。
- **为何重要：** 监听在非默认端口上的 SQL Server 无法连接，尽管连接 UI 允许用户输入端口。实机套件之所以能工作，仅仅是因为测试实例在 1433 端口上。
- **现状：** 当前 freetds 构建未导出 `DBSETLPORT`，因此当连接携带非零端口时，端口通过传给 `dbopen()` 的服务器字符串传递——即 `"host:port"`，freetds 会解析它。

### `+newSafeQueryField:andTable:` 不拆分架构限定的表
- **状态：** 已修复
- **位置：** `MADTdsClient/Source/MADDatabaseSQLServer.m:1730`
- **行为：** 该方法将表名当作单个标识符加方括号——`[[NSString alloc] initWithFormat:@"[%@].[%@]", tableName, fieldName]`——没有处理点号。因此 `dbo.employees` 会变成 `[dbo.employees].[emp_no]`，这表示一张名为 `dbo.employees` 的表，而不是 `dbo` 下 `employees` 表的列。
- **为何重要：** 架构发现返回的是架构限定名称（`SalesLT.Customer`），因此针对发现的表构建的任何查询，其生成的 SQL 所点名的表根本不存在。
- **现状：** 表名部分交由 `+newSafeIdentifier:` 处理，它会为每个以点分隔的组件加方括号：`dbo.employees` → `[dbo].[employees]`，因此结果是 `[dbo].[employees].[emp_no]`。
- **测试：** `testNewSafeQueryFieldSplitsSchemaQualifiedTable`（重命名自表征测试 `testNewSafeQueryFieldDoesNotSplitSchemaQualifiedTable`）。

### `-executeQuery:withDataTable:andError:` 丢弃其错误
- **状态：** 已修复
- **位置：** `MADTdsClient/Source/MADDatabaseSQLServer.m:325`
- **行为：** 它声明了 `NSError * __autoreleasing dberror = nil`，将 `&dberror` 传给连接调用，随后却既不读取 `dberror` 也不写入 `*error`。连接失败只会返回 `NO` 而没有任何解释。
- **为何重要：** 与上面的 `-connectWithConnection:...` 相同：未遵守调用者的 `NSError **` 契约。这两处加在一起，构成了所报告的“SQL Server 静默失败”症状的全部原因——`MADOperationDatabaseTestConnection.m:166-183` 现在会将真实错误路由到 `finishWithError:`，而不是 `finishWithError:nil`。
- **现状：** 当 process 为 nil 时，该方法将 `dberror` 写入调用者的 error；成功时则将调用者的 `error` 转发给 `-runQuery:...`。注意当时 `-runQuery:...` 和 `-executeSQL:...withError:` 对于连接后的 SQL 失败仍未填充它们自己的错误输出参数——这属于另一项发现。

### REAL 和 FLTN 结果值在转为 NSNumber 之前被收窄为 float
- **状态：** 已修复——不过这种收窄在 SQL Server 自身的类型下不可观察。
- **问题：** 结果构建 switch 的 `SYBREAL` 和 `SYBFLTN` 分支用 `initWithFloat:` 从 `double` 绑定缓冲区构建 `NSNumber`；编译器将其报告为损失精度的隐式转换。两者现在都改用 `initWithDouble:`，与旁边的 `SYBFLT8` 分支一致，直接装箱 double。
- **为何安全：** 按定义，`SYBREAL` 值是 4 字节浮点数，因此无论哪种方式都能精确表示，而且 SQL Server 会将 `FLOAT` 作为 `SYBFLT8` 发送（原本就是正确的）。此次改动消除了 `SYBFLTN` 携带 8 字节值时的收窄——Sybase 服务器会这样做——而不影响当今 SQL Server 产生的任何值。
- **对 SQL Server 无变化的证据：** 实机套件分别针对旧的 `initWithFloat:` 代码和新代码运行，两种方式下均完全一致地通过。
- **锁定测试：** `MADTdsClientLiveTests -testSelectFloatKeepsDoublePrecision` 守卫 8 字节 FLOAT 路径；其注释记录了 `SYBREAL`/`SYBFLTN` 分支无法通过任何值加以区分，因此没有测试能鉴别它们。
- **位置：** `MADTdsClient/Source/MADDatabaseSQLServer.m:1131-1150`。

### dbdatecrack 在 microsoft 的 DBDATEREC 名称下被传入 sybase 的 DBDATETIME
- **状态：** 已修复——类型名称不匹配是真实存在的，但上游厂商保证两者的内存布局一致。
- **问题：** `MADTdsClient/Source/MADDatabaseSQLServer.m` 将每个 `SYBDATETIME` / `SYBDATETIMN` 值复制到 malloc 分配的缓冲区中，并传给 `dbdatecrack`（`:1327`、`:1355`）。FreeTDS 将该缓冲区的类型声明为 `struct tds_sybase_dbdaterec *`，而调用的第三个参数是 `DBDATEREC *`，当前构建将其别名化为 `struct tds_microsoft_dbdaterec *`；编译器在两处调用上都报告了不匹配。外围的局部变量（`dateinfo`，`:1323`）同样是用 sybase 结构体声明的。
- **第一遍为何未更改：** FreeTDS 的 sybase/microsoft 结构体双重性决定了 `dbdatecrack` 读取的数据布局，因此正确形式取决于所集成的 FreeTDS 是以哪种兼容模式构建的——这是驱动正确性问题，而不是机械添加类型转换。代码带有早期留下的 `// CORRECTED:` 注释，说明这一区域本来就很敏感。
- **位置：** `MADTdsClient/Source/MADDatabaseSQLServer.m:1320-1360`。
- **证据：** `xcodebuild analyze` 在两处 `dbdatecrack` 调用上报告 `-Wincompatible-pointer-types`；这两处是工作区中该诊断仅存的实例。
- **现状：** FreeTDS 自己的头文件声明 sybase 和 microsoft 日期记录在内存中物理上完全相同，且 `dbdatecrack()` 内部自己也会将一种强制转换为另一种。两处调用现在都带有显式的 `(DBDATEREC *)` 转换，并且文件作用域的 `_Static_assert(sizeof(struct tds_sybase_dbdaterec) == sizeof(DBDATEREC), ...)` 在将来升级 FreeTDS 时继续校验这一厂商保证。内存布局和运行时行为均未改变；两处分析器警告均已消除。
- **测试：** 实机套件的 DATETIME/SMALLDATETIME 用例，包括 `testSelectClassicDateTimeKeepsItsMonth` 和 `testSelectModernDateTimeTypes`。

### `-runSQL:...`、`-runQuery:...` 和 `-executeSQL:...withError:` 丢弃了它们的 SQL 错误
- **状态：** 已修复
- **位置：** `MADTdsClient/Source/MADDatabaseSQLServer.m`（`-runSQL:onDataTable:fieldKeys:process:`、`-runQuery:onProcess:withDataTable:withError:`、`-executeSQL:fieldKeys:onConnection:intoResultTable:withError:`）
- **行为：** `-runSQL:` 在名为 `localError` 的局部变量中构建了三个 `NSError` 对象，却返回 `NO` 而不暴露其中任何一个；该方法没有错误输出参数。`-runQuery:withError:` 丢弃了来自 `-getSql:` 的错误，且从不穿透写入其自身的 `error` 参数，而 `-executeSQL:...withError:` 完全忽略了其 `error`。`-executeQuery:withDataTable:andError:` 的调用者看到的是 `NO` 和一个 nil 错误。分析器将这三处 `localError` 写入报告为 `deadcode.DeadStores`，因为没有任何地方读取它们。
- **为何重要：** `-executeQuery:withDataTable:andError:` 和 `-executeSQL:...withError:` 所承诺的错误接口无法解释失败的查询；用户可见的失败只是一个静默的 `NO`。
- **现状：** `-runSQL:` 接受 `NSError * __autoreleasing *`，在入口处将其清空，将失败记录到 `GetTdsLog()`（仅记录错误对象，不记录 SQL 或行数据），并在返回 `NO` 前将错误交回。`-runQuery:` 传播 `-getSql:` 错误并将调用者的错误转发给 `-runSQL:`；`-executeSQL:` 转发其自身的错误。`-executeQuery:withDataTable:andError:` 原本就转发给 `-runQuery:`，因此现在也能收到连接后的 SQL 失败。`-runSQL:` 的主体及其承重的 `dbclose` 保持未动。
- **测试：** `MADTdsClientLiveTests -testFailingStatementReturnsNo` 现在同时断言 `NO` 和传播出来的错误域；连同实机服务器在内，完整套件共 76 个测试。

## MAD Designer（应用）

### 编译后的模型无法通过 Core Data 的推断迁移（重命名标识符冲突）
- **状态：** 已于 2026-10-22 修复——合并为 `c48a39fb7`；修复完全位于可移植存储一侧。
- **问题：** `MAD 3.xcdatamodel` 的 `RptqDocumentElementBarcode` 为 `barcodeBorderType` 声明了 `elementID="type"`，而同一实体又继承了基础元素的 `type` 属性。因此同一实体的两个属性共享重命名标识符 `type`，`NSMappingModel` 推断会以 *"Each property must have a unique renaming identifier"* 拒绝整个模型——于是 `NSMigratePersistentStoresAutomaticallyOption` 永远无法迁移针对任何包含条码实体的模型版本所写入的存储。这一问题此前未被察觉，是因为 momd 的当前版本总是与存储完全匹配，从未真正运行过迁移。
- **为何不承重：** `MAD 3` 之前的任何模型版本都根本没有条码实体（`MAD.mom` 和 `MAD 2.mom` 均无此实体），因此该 `elementID` 什么也没有重命名。它是该实体重新集成时留下的遗迹（`TASKS.md` §15）。
- **位置：** `MADDesigner/Resources/MADFileDefinition/MAD.xcdatamodeld/MAD 3.xcdatamodel`（仍然保留它——其版本哈希锁定着已发布的现存文档，不能更改）和 `MAD 4.xcdatamodel`（在 `sql-entry` 分支上去除）。通过针对编译后的 `MAD.momd` 中的每个 `.mom` 调用 `-inferredMappingModelForSourceModel:destinationModel:error:` 诊断：`MAD`→`MAD 4` 和 `MAD 2`→`MAD 4` 可干净推断；`MAD 3`→`MAD 4` 因重命名标识符错误而失败。
- **修复（`sql-entry`，随 SQL 录入阶段 A；已合并 `c48a39fb7`）：** `MAD 4.xcdatamodel` 去掉了该 `elementID`，使当前模型成为未来版本的干净推断源；同时 `MADStoreConverter` 使用与其元数据匹配的 momd 版本（`-modelInMomdMatchingStoreAtURL:`）打开每个旧存储，而不是尝试自动迁移——这也一并修复了 `MAD`/`MAD 2` 文档的潜在损坏。由 `MADStoreConverterTests` 锁定（London/Music 示例在当前版本为 `MAD 4` 的 momd 下转换并读回相等）。

### 条码 delegate 的查询字段访问器与其声明不一致
- **状态：** 已于 2026-10-22 修复。
- **问题：** `MADViewControllerBarcodeOptionsDelegate` 协议声明了 `- (RptqQueryField *)barcodeQueryField1;` 和 `:2`（`MADViewControllerBarcodeOptionsDelegate.h:60-61`），但 `MTViewControllerBarcode` 将两者都实现为返回 `int64_t`（`MTViewControllerBarcode.m:321`、`:325`）。随后调用者 `MTViewControllerBarcodeOptions.m:347` 向结果发送消息（`[[delegate barcodeQueryField1] toStringHumanReadable]`），于是整数被当作对象指针处理——每当填充该单元格时就会崩溃。同一个文件在 `:168` 和 `:219` 处自己将标识符解析为 `RptqQueryField` 对象，这正是协议调用者看起来所期望的。
- **为何当时仅记录而未修复：** 正确形态取决于意图——是返回查找到的字段对象，还是把协议和两处调用点都改为标识符。两者都是真正的选项，且都不是单纯的编译修复。
- **位置：** `MADDesigner/Source/barcodes/MTViewControllerBarcode.m:321-327`、`MADViewControllerBarcodeOptionsDelegate.h:60-61`、`MTViewControllerBarcodeOptions.m:347,516`。
- **证据：** 两个实现上均有 `-Wmismatched-return-types`。
- **现状：** 访问器返回协议所声明的类型。两个 getter 都委托给 `-queryFieldForIdentifier:`，它对标识符 `0`（尚未选择字段）返回 `nil`，否则通过 `self.document.storeContext` 解析标识符——与 `MTViewControllerBarcode` 在 `-viewWillAppear:` 中已执行的以及选项控制器在选中字段时执行的 `objectForEntity:identifier:` 查找完全相同。过期/已删除的标识符会解析为 `nil`，详情标签只是保持为空。调用点处的内联 EXC_BAD_ACCESS 注释已移除，`-Wmismatched-return-types` 警告也已消除。
- **测试：** 无；演练该 getter 需要从 storyboard 实例化的条码视图控制器以及带有已填充存储的文档，而应用的单元测试 bundle 没有相应的测试夹具。已通过编译器（上述警告）和应用测试套件验证：74 个单元测试和 33 个 UI 测试，0 失败，且应用构建通过。

### AppDelegate 的重试 block 捕获了自身
- **状态：** 已于 2026-10-28 修复。
- **问题：** `tryOpen` 和 `tryRefresh` 是通过 `dispatch_after` 重新调度自身的 `__block` 块（`AppDelegate.m:205`、`:256`），因此每个 block 都会强引用自身直到重试链结束。它们是 UI 测试的启动钩子；循环引用会在调用链停止时解开，但在重试不断失败期间，block 及其捕获的一切都会一直存活。
- **位置：** `MADDesigner/Source/AppDelegate.m:200-260`。
- **现状：** 每个重试 block 通过 `__weak __block dispatch_block_t` 引用重新调度，并在重试完成或达到尝试次数上限时清空强引用 `__block` 持有者，从而消除 `-Warc-retain-cycles` 编译器警告。

### 一处断言用 %@ 格式化整数
- **状态：** 已于 2026-10-28 修复。
- **问题：** `MADQueryViewController.m:605` 断言 `NSAssert(objectToDelete != nil, @"Need a non-nil value for %@", tableID)`，其中 `tableID` 是 `int64_t`；`%@` 期望的是对象。`NSAssert` 在 Release 构建中会被编译掉，因此这只在 Debug 下触发，此时格式化器会把该整数当作指针处理。
- **位置：** `MADDesigner/Source/MADQueryViewController.m:605`。
- **现状：** 格式说明符改为 `%lld` 并配合 `(long long)tableID`。

### `MADToolboxFormatViewController` 的多选小数位数检查从未求值为 `YES`
- **状态：** 已于 2026-10-28 修复。
- **位置：** `MADDesigner/Source/MADToolboxFormatViewController.m:152-170`。
- **行为：** 当选中多个文档元素时，`allTheSame` 被初始化为 `NO`，且 `lastInteger` 仅在 `counter > 0` 时才被赋值，因此 `lastInteger == element.numericFormat.decimalCount && allTheSame` 永远不可能求值为 `YES`（源码中已有 `#warning Don't think BOOL allTheSame ever becomes "YES"` 标注）。因此对于任何多选，即使所有选中元素都具有相同的小数位数，小数位数标签也始终为空白。
- **现状：** `allTheSame` 初始为 `self.userSelectedObjectIDs.count > 0`，每次迭代都记录 `lastInteger`，且仅当 `counter > 0` 且 `lastInteger != element.numericFormat.decimalCount` 时才将 `allTheSame` 清为 `NO`。
- **状态：** 已修复
- **现状：** 刷新路径上的存储读取被封送到主队列（若已在主队列则内联执行），即该存储的所属队列。在 `MADOperationRefresh -execute` 中，SQL 构建和字段键读取在主队列上运行，只有构建好的字符串和键数组跨线程返回操作线程。在 `MADOperationRefreshInitialize -execute` 中，文档图读取和排序在主队列上运行，只有解析后的查询跨线程返回。`MADRefreshOperationReload -execute` 现在也将 `prepareForQuery`（其排序描述符遍历会读取存储）封送到主队列；格式化器自身的布局部分读取仍在操作线程上运行——它们负责在统计页数期间保持逐页 UI 更新不断流动，而且布局部分在刷新期间是静止的（打开流程只写入查询部分）。`MADQueryValueFromFieldController -loadPickerView` 在派发前先在主队列上解析架构字段及其凭据（构建数据库连接），因此全局队列 block 只持有普通值。在创建文档的操作中，`MADOperationCreateDocumentFirstTimeSetup` 将其插入并保存封送到主队列；`MADOperationCreateDocumentImportSchema` 则有意留在其操作线程上——该操作的全部意义就是受网络限制的架构导入，其存储写入若放到主线程会在整个导入期间阻塞 UI，而且在创建文档期间存储的其余部分是静止的。`MADQuerySampleDataField -getSql:` 在示例数据查询于同一全局队列上执行时，仍会从驱动内部读取架构字段的 `name`/`inTable.name`；这些属性在抓取期间是不可变的，但这是该路径上唯一残留的非主线程存储读取。之所以选择主队列封送而不是专用的串行存储队列，是因为存储本就记录为主线程所有，且这些操作的存储工作量很小。没有向任何访问器添加锁。
- **位置：** `MADDesigner/Source/MADOperationRefresh.m:104-118` 和 `MADDesigner/Source/MADOperationRefreshInitialize.m:64-99`（两个现役位置），外加 `MADQueryValueFromFieldController.m:157-159`（全局 GCD 队列）中的同一模式。其他原先调用 `performBlock:` 的位置（`MADDesignerViewController`、`MADQueryViewController` 的删除/添加流程）现在在主线程上内联运行，虽然改变了时机，但都是线程安全的。
- **行为：** 里程碑 (b) 的映射把每个私有 `NSManagedObjectContext` + `performBlockAndWait:` 替换成了在操作自身线程上直接读取共享的 `document.storeContext`。Core Data 的队列隔离不复存在，而 `RptqStoreContext` / `MADStoreGraph` 维护着没有任何同步机制的普通可变集合（注册表、脏集合、图行）。因此，刷新会在后台线程上修改并遍历这些集合，而主线程同时在持续读取它们——这一数据竞争可能导致对象被二次 fault、丢失注册表条目或破坏遍历。阶段 C 的设计（`docs/project/MAD_STORE_PHASE_C.md` §2-3）规定了单一共享上下文，但从未处理队列隔离，因此这是设计缺口，而非机械性疏漏。
- **修复形态。** 在不触碰热路径的前提下恢复刷新路径上的队列隔离：刷新操作执行的存储读取很小（SQL 生成和布局设置），因此将它们封送到主队列（或拥有全部上下文访问权的单一串行存储队列）是正确的恢复方式；而在每个 `RptqStoreContext` 访问器内部加锁则不可取（那会拖累重建存储本来要服务的渲染/格式化器热路径）。`MADQueryValueFromFieldController` 的全局队列读取应当在主线程上读取字段，并将普通值传入 block。
- **违反的规则：** 共享存储上下文归主线程所有；除非显式添加隔离机制，否则只有其所属队列可以触碰它。

### 页数更新从不触发，因为格式化器实例不稳定
- **状态：** 已修复
- **现状：** 重新加载操作以 `object:nil` 而不是格式化器实例来观察 `MADNotificationDidFormatPagesName`，并在即将执行格式化的那个格式化器上重新设置 `didRefresh`。文档的格式化器不是稳定的实例：`-activeDocumentModel`（通过 `-prepareForQuery` 到达）会调用 `-resetReportFormatter`，而刷新的初始化步骤又会将其替换为一个新实例，因此绑定到特定实例的观察最终可能监听的是一个已不再执行格式化的旧格式化器——格式化运行了，页数统计了，但 `reportFormatterDidFormatPage:` 从未被调用。同样的实例更替还会丢失刷新操作已设置的 `didRefresh` 标志，之后重新创建的格式化器会从索引缓存重新加载旧布局，导致格式化被完全跳过。已通过启动钩子和插桩后的发送者/观察者验证：逐页通知现在能到达重新加载操作，页数更新正常流动。
- **位置：** `MAD/Source/MADDocument.m`（`-activeDocumentModel` -> `-resetReportFormatter`）、`MADDesigner/Source/MADOperationRefreshInitialize.m`（替换 `document.reportFormatter`）、`MADDesigner/Source/MADRefreshOperationReload.m`（`-watchFormatter:` / `-ignoreFormatter:` / 格式化调用）。
- **行为：** 由用户报告：“报表刷新时应当反复调用 `reportDocumentDidReadRows:`，并且在每页格式化时应当调用 `reportFormatterDidFormatPage:`……但现在在格式化期间它从未被调用。看起来格式化确实在发生，但 UI 更新不像以前那样工作了。”两种故障模式都源于格式化器身份更替：绑定到旧实例的观察者错过了每一次通知发送（格式化发生了，但没有更新），而丢失的 `didRefresh` 则跳过了格式化（页数过期，根本没有通知发送）。具体出现哪一种，取决于重新创建相对于注册观察和刷新标志落在哪个时机。
- **违反的规则：** 通知观察绝不能依赖所属对象图可以随时替换的对象身份。

### 打开时的重新加载操作隐藏了刷新活动指示器
- **状态：** 已修复
- **现状：** 查看器的 `operationDidFinish:` 把任何 `MADRefreshOperationReload` 的完成都当作重新加载完成，并将显示状态切回活动状态。查看器在 `viewDidAppear:` 中入队的重新加载恰恰是这个类，因此当它在用户发起的刷新仍在进行中时完成，活动指示器就会在刷新中途熄灭（指示器是否曾显示过，取决于哪个操作最后完成）。现在，当 `_refreshing` 置位时，该回调会跳过对 `MADRefreshOperationReload` 的显示更新；而刷新组（`MADOperationRefreshReload`）仍通过第一个分支更新显示。已通过启动钩子和插桩后的格式化器门控验证：刷新 -> 格式化运行 -> 逐页更新流动 -> 最终页数落定。
- **位置：** `MADDesigner/Source/MADViewerController.m`（`-operationDidFinish:`）以及在 `-viewDidAppear:` 中入队的重新加载。
- **行为：** 由用户报告：“应用并不总是显示刷新活动指示器”，而且刷新之后重新加载的页数更新没有显示。刷新链本身是完成的——插桩后的格式化器门控显示 `formatDocument` 正在运行且最终页数落定——但打开时重新加载的延迟完成可能掩盖指示器，而且现在整个格式化在 1-3 秒内就完成了（迁移前的 Core Data 版本耗时足够长，肉眼能看到页数在“分析后备存储”）。与修复前的 HEAD（`fff8d7dff`）进行的 A/B 对比显示最终状态完全相同，因此这是存储迁移带来的回归，而不是那四项修复造成的。
- **违反的规则：** 活动指示器属于正在进行中的刷新；无关操作的完成绝不能清除它。

### "Formatting page N." 状态消息被设置却从未显示
- **状态：** 已修复——待用户检查运行中的应用
- **位置：** `MADDesigner/Source/MADRefreshOperationReload.m`（投递路径）、`MADDesigner/Source/MADViewerController.m`（`-operation:didFormatPage:` 以及 `-viewDidAppear:` 中入队的重新加载）、`MADDesigner/Source/MADLabelStatus.m`（`-updateFormattingStarted:`）、`MADDesigner/Source/MADOperationRefreshReloadProtocol.h`。
- **行为：** 由用户报告：在刷新期间和打开时的重新加载期间，`MADNotificationDidFormatPagesName` 反复发送且最终页数正确落定，但在格式化耗费的 2-3 秒内屏幕上没有任何变化。标签的文本其实被设置了（见测试），因此出问题的是告知标签的时机和频率。
- **现状：** 状态行主动宣告运行所处的阶段，而不是等待格式化器的通知发送。
  * 刷新的第一阶段在运行开始时由查看器宣告（`-refresh:` 和打开时的重新加载）：状态行显示 "Refreshing…"。在大型报表上，读取可能耗时数秒，而这段时间窗口过去一直显示上一次运行的页码位置。
  * 在格式化开始前发送 `-operationDidBeginFormatting:`（新协议方法），将 "Formatting…" 放到状态行上；随后的页面通知在此基础上不断细化它。
  * 格式化进度经过合并（coalesce）。只保留最新页码，投递频率下限设为 10 Hz——即状态标签原本的重渲染速率——而尚未发出的最新页码会在同一派发中紧挨着页码位置之前冲刷出去，因此页码位置仍然是标签的最终显示内容。对于 9,212 页的示例（1,321 次发送），标签现在收到约 6 次投递，而不是 1,322 次；记录数路径在 `MADOperationRefreshReload -updateNumberOfRecords:` 中也以同样方式合并。
  * 打开时的重新加载（`-viewDidAppear:`）在其运行期间禁用刷新按钮，并将查看器注册为其观察者——`-operationDidFinish:` 一直为该操作保留着这个分支（`!_refreshing`），但此前因为没有任何地方注册观察者而从未到达。在格式化中途启动刷新，本来会针对同一个文档再启动第二次格式化。对于用户发起的刷新，按钮此前已通过指示器切换被禁用。
- **在运行中的应用中验证：** 使用应用自身的钩子（`-UITestOpenSample Music -UITestRefresh`）以无头方式启动，并以 debug 级别流式输出日志。完整链路在应用中运行——发送、投递、写入标签——并且在为了观察而将格式化拉长到几秒钟后，追踪到标签通过 `-drawTextInRect:` 先绘制 "Formatting…"，随后每约 100 ms 绘制递增的 "Formatting page N."，最后绘制 "Page 1 of 77 pages."。示例无法展示的是所报告的空白期：它们的整个格式化只需 40-80 ms，因此在那里该阶段只是亚帧级事件——正因如此，必须在代码路径中而不是屏幕上寻找故障原因。
- **测试：** `MADStatusLabelRefreshTests`（新增）驱动真实的操作、真实的通知单例和真实的标签；它记录交给标签的每一个字符串，渲染标签像素以证明其确实绘制，并锁定两个阶段的消息、合并后的投递次数、冲刷顺序以及最终页码位置。使用 `-only-testing:MADDesignerUnitTests/MADStatusLabelRefreshTests` 运行。
- **另需了解：** `MADViewerController -reportFormatterDidFormatPage:` 和 `-reportDocumentDidReadRows:` 重复了重新加载操作的处理程序，但没有注册方——重新加载操作是格式化通知的唯一观察者——因此那里的断点在刷新期间永远不会触发，实际触发的日志行来自该操作。
- **发现于：** 用户关于状态标签的报告；该测试是为这条此前毫无覆盖的路径新建的基础设施。

### `MADOperationRefresh` 用连接错误替代了执行错误
- **状态：** 已修复
- **位置：** `MADDesigner/Source/MADOperationRefresh.m`
- **行为：** 当 `-executeSQL:fieldKeys:onConnection:intoResultTable:withError:` 返回 NO 时，处理程序以 `NSError *error = eerror;` 结束。`eerror` 是 `:78-88` 处 `-connectWithConnection:credentals:connectionError:` 调用的*连接*错误，而该调用早已成功，因此仍为 nil。前一行在 `:104` 处捕获的 `executeError` 在 `:112` 处记录日志后就被丢弃了。
- **为何重要：** `-finishWithError:nil` 会以空的错误列表完成该操作，因此失败的查询与未匹配到任何结果的查询无法区分——更糟的是，与成功的查询也无法区分。`-resetCache`（`MAD/Source/MADocument.m:229-238`）在该操作运行前会*加载*现有的 `.maddb`，因此在当前查询失败时，`-numberOfResults` 仍然回答上一次运行的行数，而调用者看到的正是那些行。在 `SQLITE_DQS=0` 下针对 `London.mad` 实测：当其过期的 76 行缓存存在时，`mad refresh` 打印 "refreshed 76 rows" 并以 0 退出；将该缓存移开后，完全相同的命令打印 "refreshed 0 rows"。两种情况下 prepare 失败都是不可见的，真正的错误消息只有在插桩下才会浮现。`-executeSQL:` 与缓存之间的每一次失败都被报告为成功，而缓存又让这次成功看起来像携带了数据。
- **相关：** 凭据分支对*缺失凭据*抛出了域为 `@"MADCache"`、代码为 `errCache + 1` 的错误，因此当文档的数据库需要凭据而调用者未提供时，会报告 "MADCache error 3"，读起来就像缓存故障。两者都是同一方法中的可诊断性缺陷，且都在 CLI 工作中耗费了排查时间。
- **现状：** 失败路径以 `executeError` 结束，并且仅在驱动未报告错误时才构建其自身的错误——域为 `com.everydayapps.operation.refresh`，代码为 `errExecute`。凭据分支使用同一个域及新的 `errMissingCredentials` 代码，并携带指明缺失内容的描述。CLI 的错误输出经过 `MADCLIDescriptionForError`（`CLI/Source/`），它会追加 `-localizedFailureReason`，因为各个驱动都把数据库自身的错误原文放在那里——没有它，结果就只是一句光秃秃的 "refresh failed: Error"。
- **已验证：** 将 `chinook.sqlite3` 移开后，`mad refresh London.mad` 在旧代码下输出 "refreshed 76 rows"（过期缓存的行）并以 0 退出，而在当前代码下输出 `refresh failed: Error: no such table: Customer` 并以 4 退出。
- **测试：** 无；复现需要一个查询针对实时数据库失败的文档，CLI 会这样做，而单元测试 target 不会。

### `MTTableController` 在抓取失败后读取了过期的页数
- **状态：** 已修复
- **提交：** `7b3e976db`
- **位置：** `MADDesigner/Source/MTTableController.m:449`（以及 `:380`、`:402`）
- **行为：** `-fetchFromAPIWithOffset:limit:completion:` 从其*两个*分支都回答 `hasMore = (datatable.count == limit)`。在成功分支上这是正确的：驱动在填充表之前会先清空表，因此该计数就是刚刚写入的那一页。而在失败分支上，驱动没有清空任何内容，因此计数仍然描述的是*上一*页——失败的抓取会报告 `hasMoreData = YES` 并重新发出同一个查询。另外两处（在 `-fetchMoreRows` 和 `-fetchRowAtIndex:` 中）未检查空页就计算 `offset + count - 1`；当 `count == 0` 且 `offset == 0` 时，结果为 `NSUIntegerMax`，强转为 `NSInteger` 后是 `-1`，因此 `maxKnownRow` 停留在 `-1`，而不是表示“无行”的值。
- **为何重要：** 失败一次的查询会不断自我重试而不是停止——这一半是实打实会触发的问题。下溢则是潜在的而非直接可见的：`-invalidateLayout` 的 `maxKnownRow >= minKnownRow` 守卫会把 `-1` 变成行数 0，这对空页来说恰巧是正确答案；随后 `-fetchMoreRows` 的 `maxKnownRow == NSIntegerMin` 哨兵检查落空，进入将 `-1` 回绕为偏移量 0 的算术。两边都纯属巧合地能工作，正因如此才值得消除。
- **现状：** 失败路径报告 `completion(NO)`；分页游标算术在推导最后一行之前先守卫 `count > 0`。
- **测试：** 无。`MTTableController` 是应用源码，而应用的单元测试 bundle 只能通过本地声明的副本触及应用类（该 bundle 的头文件搜索路径不包含 `MADDesigner/Source`），因此这里没有可直接驱动它的入口。它所依赖的分页不变式——驱动在填充表之前会先清空表——改在驱动侧由 `MADSqlite3Tests` 中的 `testDriverFillsAWritePortWithNoDataTableBehindIt` 锁定。

### `MADPageViewAttributes` 把缺失的缓存日期解码为 2001-01-01
- **状态：** 已修复
- **位置：** `MADDesigner/Source/MADPageViewAttributes.m:66-67` 和 `:92-93`
- **行为：** `-encodeWithCoder:` 写入 `_reportLastCacheDate.timeIntervalSinceReferenceDate`；向 `nil` 发送消息得到 `0.0`。`-initWithCoder:` 用 `-decodeDoubleForKey:` 将其读回，并构建 `[[NSDate alloc] initWithTimeIntervalSinceReferenceDate:]`，而后者不可能返回 `nil`。因此，“从未缓存”在往返编码后会变成基准日期 2001-01-01 00:00:00 UTC，测试该属性是否为 `nil` 的调用者将看不到 `nil`。真正的 2001 年基准日期也会编码为同一个 0，因此这两种状态事后无法区分。
- **现状：** 仅当日期非 nil 时才将其写入，同时附带一个配套的 `encodeBool:forKey:` 存在标志，且仅在该标志置位时才读回日期。单靠 `-decodeDoubleForKey:` 无法区分这两种状态，因此由该标志来承载 nil。
- **测试：** `testPageViewAttributesCodingPreservesANilDate`（重命名自 `testPageViewAttributesCodingTurnsANilDateIntoTheReferenceDate`）和 `testPageViewAttributesCodingRoundTrip`。

### `MADPageViewAttributes` 把 `zoomScaleInital` 和 `contentScaleFactor` 收窄为 float
- **状态：** 已修复
- **位置：** `MADDesigner/Source/MADPageViewAttributes.m:58` 和 `:61`
- **行为：** 两者都是 `double` 属性，编码时用 `-initWithDouble:`，解码时却用 `-.floatValue`，因此往返编码后只保留了单精度。对于应用实际存储的值（接近 1.0 的缩放比例）无害，但编码往返不是无损的。
- **现状：** 解码后的 `NSNumber` 用 `-.doubleValue` 解包，与生成它的 `-initWithDouble:` 相匹配。
- **测试：** `testPageViewAttributesCodingPreservesTheZoomScalePrecision`（重命名自 `testPageViewAttributesCodingNarrowsTheZoomScaleToFloat`）。

### `NSData (AES256)` 用 NULL IV 加密，因此密文是确定性的
- **状态：** 已修复
- **位置：** `MADDesigner/Source/NSData+AES256.m:43` 和 `:87`
- **行为：** 调用 `CCCrypt` 时传入了 NULL IV，因此给定密钥下的每次加密都使用全零 IV。相同的明文总是产生相同的密文，这会泄露两个存储值是否相等。修复方法是生成随机 IV 并将其与密文一同存储。
- **现状：** 两个方法都从 `arc4random_buf` 抽取全新的 16 字节 IV 并传给 `CCCrypt`；`-AES256EncryptWithKey:` 将其前置到密文头部，而 `-AES256DecryptWithKey:` 将第一个分组读作 IV 并解密其余部分。短于一个分组的载荷会被拒绝，而不是被误读。对调用者而言往返加解密保持不变；只有字节流布局发生了变化。
- **测试：** `testAES256EncryptionIsNotDeterministic`、`testAES256RoundTripOfAnEmptyPayload` 和 `testAES256RoundTrip`。这两个分类方法没有生产调用者——测试是唯一的使用者——因此布局变更不会破坏测试套件以外的任何代码。

### 密钥超过 32 字节时，`NSData (AES256)` 静默回退到全零密钥
- **状态：** 已修复
- **位置：** `MADDesigner/Source/NSData+AES256.m:24` 和 `:68`
- **行为：** 密钥通过 `-getCString:maxLength:encoding:` 复制到清零的 33 字节缓冲区中，且返回值被丢弃。UTF-8 形式放不下的密钥在转换时会失败且什么也不写入，使缓冲区保留为 `bzero` 清零后的 32 个零字节。因此，两个完全不同的超长密钥会产生完全相同的密文——密钥本身毫无作用。32 字节及以下的密钥会被复制进去并以零填充，这符合文档记录的意图；超长的情况则不然。
- **现状：** 两个方法都检查 `-getCString:maxLength:encoding:` 的结果，并在密钥放不下时返回 nil。短密钥仍然以零填充，测试通过同时用显式填充形式解密来锁定这一点。
- **测试：** `testAES256KeyLongerThanThirtyTwoBytesIsRefused` 和 `testAES256ShortKeyIsZeroPadded`。

### `NSData (Base64) +dataFromBase64String:` 写出其输出缓冲区之外
- **状态：** 已修复
- **位置：** `MADDesigner/Source/NSData+Base64.m:78`
- **行为：** `NewBase64Decode` 按 `(length / 4) * 3` 确定缓冲区大小，但写入循环对每一组（包括最后的不完整组）总是写入 3 个字节。对于长度不是 4 的倍数的输入，最后一组最多会在已分配空间之外多写 3 个字节：`@"YWJjY"` 得到一个 3 字节缓冲区，却在偏移 3、4 和 5 处写入。解码值仍然是正确的，因为返回的长度是单独跟踪的，因此越界写入落在 malloc 的松弛空间中，除非运行 guard-malloc 或 ASan，否则不可见。测试只能锁定解码后的值。
- **现状：** 分配向上取整到整组数量 `((length + 3) / 4) * 3`，使最后的不完整组落在缓冲区内部。解码出的字节和返回的长度保持不变。
- **测试：** `testBase64DecodeOfTruncatedInput`（改名自 `testBase64DecodeOfTruncatedInputOverrunsItsBuffer`，其旧注释说明越界超出了测试可见的范围），并附带注释记录改动在于缓冲区大小计算。

### `+[NSDateFormatter RFC_3339]` 拒绝带数值偏移的 RFC 3339 时间戳
- **状态：** 已修复
- **位置：** `MADDesigner/Source/NSDateFormatter+RFC_3339.m:23`
- **行为：** 格式字符串以字面量 `'Z'` 结尾，而不是时区占位符，因此只接受 UTC 的 `Z` 写法。由于区域设置为 `en_US_POSIX`，格式器也是严格的，所以 `2020-01-15T13:45:00+02:00` 会返回 `nil` 而不是被误读为 UTC。RFC 3339 允许两种写法，使用偏移形式的服务器时间戳会被静默丢弃。
- **现状：** 格式字符串以 `XXXXX`（“带冒号的 ISO 8601”）结尾，在偏移为零时输出 `Z`，否则输出 `±hh:mm`，并在解析输入时同时接受两种写法。`Z` 形式仍然产生与之前相同的日期。
- **测试：** `testRFC3339FormatterAcceptsAnExplicitNumericOffset`（改名自 `testRFC3339FormatterRejectsAnExplicitNumericOffset`），断言 `2020-01-15T13:45:00+02:00` 的纪元秒数。

### `MADOperationConditionPolarQuestionAffirmative` 丢弃了给它的答案
- **状态：** 已修复
- **位置：** `MADDesigner/Source/MADOperationConditionPolarQuestionAffirmative.m:65`
- **行为：** 满足分支调用 `+[MADOperationConditionPolarQuestionAffirmativeResult newOperationConditionResult:name:]` 时，把*依赖对象*放在了 `BOOL satisfied` 位置上。在 `BOOL` 为 `_Bool` 的 arm64 上，指针通过“非空”而不是通过依赖项的答案转换为 `YES`——因此条件确实报告为已满足，但结果自身的 `result` 属性仍留在 NO。调用者如果从结果中读回答案，在回答了“是”之后会被告知“否”。隔壁的否定条件通过设置 `result` 的 `+newOperationCondition:name:` 正确地完成了这件事；这两个类本应互为镜像，但只有一个做到了。
- **为何重要：** 没有任何东西指向调用点。`arm64` 和 `x86_64` 上的 `-fsyntax-only` 都无警告地接受了这一行，因此只有从结果中读回值时才能看到这个错误。测试锁定的行为是 arm64 上的行为（其中 `BOOL` 是 `_Bool`）；在 `BOOL` 为 `signed char` 的 `x86_64` 上，同一个表达式则会变成指针的低字节。
- **现状：** 肯定类声明并调用否定类所使用的同一个 `+newOperationCondition:name:`，使依赖项的答案落入结果的 `result` 属性中。这两个类再次互为镜像。
- **测试：** `testAffirmativeCarriesTheAnswerItWasGiven`（改名自 `testAffirmativeDropsTheAnswerItWasGiven`），断言结果的 `result` 为 YES。

### `MADOperationConditionSuccess` 在没有匹配依赖时断言而不是失败
- **状态：** 已修复
- **位置：** `MADDesigner/Source/MADOperationConditionSuccess.m:78`
- **行为：** 当循环没有找到 `NSOperation.name` 等于条件键的依赖时，结束时 `result` 仍为 nil，方法在返回前触发 `NSAssert(result != nil, @"We expect dependencies.")`。下一行的 `result != nil ? result : [self result: NO]` 因此在 Debug 构建中不可达，反而会中止调用方的操作。Release 构建定义了 `NS_BLOCK_ASSERTIONS`，确实会得到静默失败，因此同样的输入在开发环境中触发断言，而在生产环境中静默失败。另请注意，`dependency.name` 在 `conformsToProtocol:` 检查*之前*被读取，这只是因为 `NSOperation` 声明了 `name` 才恰好安全。
- **现状：** 断言已移除，方法在两种配置下都返回 `result != nil ? result : [self result: NO]`，使 Debug 与 Release 一致。循环现在在读取名称之前跳过不遵循 `MADOperationTestResults` 的依赖，因此上面的顺序说明不再适用。
- **测试：** `testSuccessFailsWhenNoDependencyMatchesTheKey`（改名自 `testSuccessAssertsWhenNoDependencyMatchesTheKey`）。

### `MADOperationConditionDisplayedAlertConfirm` 在无人能回答时返回 nil
- **状态：** 已修复
- **位置：** `MADDesigner/Source/MADOperationConditionDisplayedAlertConfirm.m:70`
- **行为：** 如果没有任何依赖遵循 `MADOperationConditionDisplayedAlertProtocol` 或 `MADOperationHoldsCredentialsProtocol`，循环会直落到底，并从一个声明为 `nonnull` 的方法返回 nil。空依赖情况会返回正常的失败，因此只有当存在依赖但没有一个能回答时才会出现 nil——而这正是调用者最不可能测试的情况。
- **现状：** 直落路径以条件的名称返回 `+[MADOperationConditionResult newOperationConditionResultFailedNotSatisfied:]`，与上面空依赖情况已返回的失败相同。
- **测试：** `testDisplayedAlertConfirmFailsWhenNoDependencyCanAnswer`（改名自 `testDisplayedAlertConfirmReturnsNilWhenNoDependencyCanAnswer`）。

### 文档状态信号在两端都是惰性的
- **状态：** 已解决 —— 2026-10-06。信号端已接通（见下文里程碑 d）；标志端是一项**决策，而非缺陷**：`MADDocumentState.needsSave` 和 `.contextChagned` 被有意保留，作为计划中云状态功能的预留位置。目前没有任何代码读取它们；也不应将它们当作死代码删除。
- **位置：** `MAD/Source/MADocument.m`（`handleManagedObjectContext…` 处理程序以及它们写入的 `MADDocumentState` 标志）；`MADDesigner/Source/MADDesignerViewController.m`（`-managedObjectContextDidChange:`、`-managedObjectContextDidSave:`、`-addObservers`）；`MADDesigner/Source/MADQueryViewController.m`（`-managedObjectContextDidChange:`、`-ingnoreManagedObjectContextChanges:` 和 `-observeManagedObjectContextChanges:`）
- **行为：** 状态信号在**两端**都是惰性的，而不仅仅是等待存储信号的休眠状态。没有任何地方能触发它——`RptqStoreContext` 不发送变更通知——也没有任何地方消费它：全仓 grep 显示没有任何代码读取 `MADDocumentState.needsSave` 或 `.contextChagned`；这些处理程序写入的是无人使用的标志。设计器和查询控制器同样注册了存储从不发送的 Core Data 通知。`MADDesignerViewController.m` 在 `RptqObject` 上带有一个私有的 `changedValues` 垫片，返回的是*每一个*属性，而不是实际变更的键，以保证这些处理程序一旦收到通知时仍然正确。出于同样的原因，`MADQueryViewController.m` 的 `_suspendAutomaticTrackingOfChangesInManagedObjectContext` 切换不产生任何效果，其处理程序体也已被简化为空操作。观察者方法名 `ingnoreManagedObjectContextChanges:` 还带有一个由来已久的拼写错误。
- **现状（里程碑 d）：** 信号端已接通。`RptqStoreContext` 在 `insertObjectForEntity:`、`markObjectChanged:`、`deleteObject:` 以及 `save:` 之后发送 `RptqStoreContextObjectsDidChangeNotification`（object = 上下文，自阶段 D 起使用 `RptqStoreContext*` 名称下的相同 userInfo 键），并在每个运行循环周期内合并为一次发送。设计器的撤销按钮/元素刷新处理程序以及查询控制器的列表跟踪再次消费该通知，`MADModelDocument` / `MADQueryFull` 也会接收它。剩下的决策收窄到这些标志本身，并于 2026-10-06 拍板：保留 `MADDocumentState.needsSave` 和 `.contextChagned` 供未来的云状态功能使用。
- **在存储迁移期间发现。**

### 保存现在无条件运行，且每次都重写整个存储
- **状态：** 已修复
- **位置：** `MADDesigner/Source/MADDesignerViewController.m`（裸 `{ // Save unconditionally … }` 块，例如 `:2969`、`:2986`、`:3332`、`:3381`）以及 `MADDesigner/Source/MADDesignerElementView.m:286-292`
- **行为：** `RptqStoreContext` 没有 `hasChanges`，因此原先的每一处 `if ([context hasChanges])` 守卫都被机械地替换成了无条件保存，而 `-save:` 是 `writeGraph:replacingAll:YES`——一次完整的存储重写。设计器中的捏合、平移、插入和删除路径在每次手势事件时都会重写整个存储，而 Core Data 以前只保存脏对象。
- **现状：** `RptqStoreContext` 跟踪脏对象——每次属性设置（设为相同的值不算变更）、在边的任一端进行的每次关系设置、每次插入，以及作为待处理行的删除——而 `-save:` 在单个事务中仅写入脏行，外加其对多边产生的位置行和连接表行；干净的保存不会触碰文件。设计器的守卫恢复为真正的 `if ([context hasChanges])` 检查，因此无操作的平移不会保存任何内容。由 `RptqStoreContextTests` 中的 `testHasChangesTracksInsertEditAndSave`、`testSettingTheSameValueDoesNotDirtyTheRow`、`testACleanSaveLeavesTheStoreFileUntouched`、`testOnePropertyChangeWritesOnlyThatRow`、`testAnOrderedToManyReorderIsWrittenIncrementally` 和 `testDeleteIsPendingUntilSave` 锁定。

### 资源管理器不列出任何文档，Query 标签页不列出任何表
- **状态：** 已修复
- **位置：** `MADDesigner/Source/MADExplorerController.m`（文件列表）以及 `MADDesigner/Source/MADQueryViewController.m` / `MADQueryViewDataSource.m`（查询表列表）
- **行为：** 在模拟器中，即使应用组的 `Documents/` 目录里有 `London.mad` 和 `Music.mad`，资源管理器的列表仍为空，且打开 London 后 MAD Query 标签页渲染不出任何表。
- **现状：** Query 标签页的问题出在被掏空的变更通知处理程序：一旦 `RptqStoreContext` 发送 `NSManagedObjectContextObjectsDidChangeNotification`（里程碑 (d) 的变更信号），恢复后的处理程序就会重新加载查询列表，标签页便会显示表、链接、分组和谓词各节。资源管理器则根本不是存储缺陷：它的列表受首次启动时的存储选项引导守卫，而在无头模拟器中该选项保持未设置状态（没人能点击提示框），导致资源管理器处于未配置状态。将存储选项预设为本地后，资源管理器即可列出 London 和 Music。
- **在存储迁移期间发现。**

### 查询分组、链接和谓词列表加载存储中的每一行
- **状态：** 已修复
- **位置：** `MADDesigner/Source/MADQueryViewDataSource.m`（`queryLinksController`、`queryGroupsController` 和 `queryPredicatesController` 的 getter）；`MADDesigner/Source/MTGroupByViewController.m`（`-viewDidLoad`）
- **行为：** 只有 `queryTablesController` 按当前打开的查询过滤了行；链接、分组和谓词列表都会抓取各自实体的每一行，因此第二个查询的行会出现在第一个查询的列表中。迁移前的 fetched-results 控制器也是同样的形态，因此这是保留下来的旧行为，而不是新的回归。
- **现状：** 数据源保存查询标识符，每个列表都按它过滤（链接按 `hasLeftField.inQueryTable.inQuery.identifier`，分组和谓词按 `inQuery.identifier`）；group-by 选择器限定在文档的默认查询范围内；恢复后的变更通知处理程序会在任何查询行变更时重置全部四个列表。
- **在存储迁移期间发现。**

### 选择字段列表过去只抓取单个字段；现在会抓取全部
- **状态：** 已修复
- **位置：** `MADDesigner/Source/MADQueryChooseFieldController.m`（`-sections`）
- **行为：** 迁移前的控制器从 `[RptqQueryField fetchRequestFields:1]`——限制为一行的抓取——构建其分节的 fetched-results 控制器，因此选择器最多只显示一个字段。基于存储的 getter 会抓取每一个 `RptqQueryField` 并按表别名对它们分组。
- **现状：** 全字段形态已确认是正确的——只显示一行的字段选择器才是 bug——并且该列表遵循展示者的 `excludeTables`（链接构建器按别名排除正在被链接的表）。
- **在存储迁移期间发现。**

### MADToolboxStyleViewController 把未初始化的值传给 setter
- **状态：** 已于 2026-10-28 修复。
- **问题：** `core.CallAndMessage` 报告 `MADToolboxStyleViewController.m:609` 处传给属性 setter 的实参未初始化——在某些路径上，该值可能在任何赋值之前被读取。
- **位置：** `MADDesigner/Source/MADToolboxStyleViewController.m:609`。
- **现状：** `size` 初始化为 `CGSizeZero`，且 `_stepperSizeHeight.value` / `_stepperSizeWidth.value` 读取 `sizeHolder.height` 和 `sizeHolder.width`，与它们上方的同级外边距、内边距和边框步进器一致。

### 应用把可能为 nil 的值传给非空参数
- **状态：** 已于 2026-10-28 修复。
- **问题：** 三处实参位置上，可能为 nil 的值传到了声明为非空的参数：`AppDelegate.m:210`、`MADQueryBuilderSplitViewController.m:151`、`MADQueryChooseFieldController.m:169`。
- **位置：** 上述 file:line 列表。
- **证据：** `xcodebuild analyze` 中的 `nullability.NullPassedToNonnull`。
- **现状：** `AppDelegate.m` 在调用 `NSStringFromClass` 前对 `rootClass` 和 `topClass` 做守卫；`MADQueryBuilderSplitViewController.m` 对 `barButtonItemRevealQuery != nil` 做守卫，而不是向 `-[NSArray initWithObjects:]` 传入 nil 作为第一个实参；`MADQueryChooseFieldController.m` 在比较别名的同时检查 `current == nil`，确保即使字段的 `inQueryTable.alias` 为 nil，第一个分节数组也总会分配。

### `MADFontSelectorViewController -setFamilyName:` 递归调用自身
- **状态：** 已于 2026-10-28 修复。
- **位置：** `MADDesigner/Source/MADFontSelectorViewController.m:155`。
- **行为：** `- (void)setFamilyName:(NSString *)familyName` 写成了 `self.familyName = [familyName copy];`，每当调用 `setSelectedFamilyName:` 或 `self.familyName = ...` 时都会无限递归调用自身。
- **现状：** `-setFamilyName:` 赋值为 `_familyName = [familyName copy];`。

### Viewer 工具栏中的 Refresh / Formatting / Page 状态标签在 Liquid Glass 上不可读
- **状态：** 已于 2026-10-28 修复。
- **位置：** `MADDesigner/Source/MADLabelStatus.m:50-58`、`MADCocoaExtensions/Source/MADLabelTitle.m:114` 以及 `MADDesigner/Source/MADThemeManager.m`。
- **行为：** `MADLabelStatus` 和 `MADLabelTitle` 硬编码了 `NSForegroundColorAttributeName: [UIColor whiteColor]`，而 `MADThemeManager` 在浅色模式下配置不透明蓝条、在深色模式下配置深色模糊，同时强制白色 `UIBarButtonItem.tintColor`。在采用系统 / Liquid Glass 栏材质的现代 iOS 上，白色文本和栏按钮在浅色模式下对比度极低甚至为零。
- **现状：** `MADThemeManager` 使用 `configureWithDefaultBackground` 和语义化动态颜色（`labelColor`、`secondaryLabelColor`、`systemBlueColor`），`MADLabelTitle` 使用 `[UIColor labelColor]`，`MADLabelStatus` 使用 `[UIColor labelColor]` 和 `[UIColor secondaryLabelColor]`。
- **测试：** `MADCocoaExtensionsTests/MADLabelTitleTests`。

### `MADTabBarController` 在每次 `-viewWillAppear:` 时重建全部三个 tab 视图控制器
- **状态：** 已于 2026-10-28 修复。
- **位置：** `MADDesigner/Source/MADTabBarController.m:85-104,138-143`。
- **行为：** `-viewWillAppear:` 无条件地实例化并赋值新的 Query、Designer 和 Viewer 视图控制器，而 `-viewDidDisappear:` 即使在 tab 栏之上弹出模态表单时也会清空 `self.viewControllers = nil`。
- **现状：** `-viewWillAppear:` 仅在 `self.viewControllers.count == 0` 时填充 `self.viewControllers`，而 `-viewDidDisappear:` 仅在 `self.isMovingFromParentViewController || self.isBeingDismissed` 时清空它们。

### `MADDesignerViewController`：编辑动态标签的字段时按字段 ID 查找标签，并把 popover 锚定在 `CGRectZero`
- **状态：** 已于 2026-10-28 修复。
- **位置：** `MADDesigner/Source/MADDesignerViewController+CollectionView.m`（`-editDocumentObjectLabelDynamic:`）以及 `MADDesigner/Source/MADDesignerViewController+ElementSaving.m`（`-tableViewControllerChooseFieldDidFinish:withFieldID:`）。
- **行为：** `-editDocumentObjectLabelDynamic:` 使用元素的标识符在 `self.view.scroller.container.sectionLabels`（以节标识符为键）中查找 `viewToEdit`，返回 `nil` 并将 popover 锚定在 `CGRectZero`。随后，当用户在 `-tableViewControllerChooseFieldDidFinish:withFieldID:` 中选择新字段时，它抓取的是 `+[RptqDocumentElementLabelDataField newDocumentElementWithIdentifier:field.identifier ...]` 而不是 `self.objectIdEditDynamicLabel.longLongValue`，因此被编辑的标签元素从未被找到或更新。
- **现状：** `-editDocumentObjectLabelDynamic:` 在 `self.elementViewsDictionary[@(object.identifier)]` 中查找 `viewToEdit`，而 `-tableViewControllerChooseFieldDidFinish:withFieldID:` 使用 `self.objectIdEditDynamicLabel.longLongValue` 抓取标签元素并清空 `self.objectIdEditDynamicLabel`。
- **测试：** `MADDesignerUnitTests testChooseFieldDidFinishUpdatesEditedDynamicLabelFieldReference`。

### `MADDesignerViewController -sectionForLabelTag:` 和 `-documentSectionViewWithIdentifier:` 查找了错误的 section
- **状态：** 已于 2026-10-28 修复。
- **位置：** `MADDesigner/Source/MADDesignerViewController.m`（`-sectionForLabelTag:` 和 `-documentSectionViewWithIdentifier:`）。
- **行为：** `-sectionForLabelTag:(NSInteger)tag` 忽略了其 `tag` 参数，转而查询 `self.lastSelectedSectionControlPanel`。`-documentSectionViewWithIdentifier:(NSInteger)identifier` 比较的是 `((MADDesignerSectionView *)subview).tag == identifier`，但 `MADDesignerSectionView` 将其节 ID 保存在 `.identifier` 中，而 `UIView.tag` 始终为 `0`。
- **现状：** `-sectionForLabelTag:` 查询 `(int64_t)tag`，`-documentSectionViewWithIdentifier:` 比较 `((MADDesignerSectionView *)subview).identifier == identifier`。
- **测试：** `MADDesignerUnitTests testSectionForLabelTagUsesPassedTagNotLastSelectedSectionControlPanel` 和 `testDocumentSectionViewWithIdentifierMatchesIdentifierPropertyNotViewTag`。

### `MADViewerController -showPrintDialog` 颠倒了队列优先级，且 `MADOperationLoadPrintPageRender -main` 读取了未初始化的 `MADocument *` 指针
- **状态：** 已于 2026-10-28 修复。
- **位置：** `MADDesigner/Source/MADViewerController+PrintingAndExport.m`（`-showPrintDialog` 和 `-[MADOperationLoadPrintPageRender main]`）。
- **行为：** `-showPrintDialog` 将一个 block 分派到 `DISPATCH_QUEUE_PRIORITY_BACKGROUND`，而其主体立即调用 `dispatch_sync(dispatch_get_main_queue(), ...)`，在不做任何后台工作的情况下造成主线程优先级反转。在 `MADOperationLoadPrintPageRender -main` 中，局部变量 `MADocument *document;` 在读取和赋值 `document.printPageRenderer` 之前从未由 `self.document` 初始化。
- **现状：** `-showPrintDialog` 用 `dispatch_async(dispatch_get_main_queue(), ...)` 分派 UI 展示，且 `-[MADOperationLoadPrintPageRender main]` 初始化 `MADocument *document = self.document;`。

### 未选中的 tab bar 图标对白色 PNG 描边强制 `UIImageRenderingModeAlwaysOriginal`，使其在浅色模式以及 Liquid Glass 的白色表面上不可见
- **状态：** 已于 2026-10-28 修复。
- **位置：** `MADDesigner/Source/UIViewController+tabBarItem.m:32-38`、`MADDesigner/Source/MADThemeManager.m:82-116` 以及 `MADDesigner/Resources/Assets/Images.xcassets/UIBarButtonItem*8.imageset/Contents.json`。
- **行为：** `UIViewController+tabBarItem` 用 `UIImageRenderingModeAlwaysOriginal` 创建 `tabBarItem.image`，却用 `UIImageRenderingModeAutomatic` 创建 `tabBarItem.selectedImage`，且三个 tab bar 图标资源集（`UIBarButtonItemDatabase8`、`UIBarButtonItemMadDesigner8`、`UIBarButtonItemMadViewer8`）均无模板渲染意图。由于底层 PNG 是透明背景上的白色描边配少量红色点缀，选中的 tab 会被 UIKit 染成蓝色，而未选中的 tab 在浅色模式下会将原始白色像素直接渲染在白色 Liquid Glass 胶囊上（只剩微小的红色点缀可见），在深色模式下浮动于白色内容之上时对比度也很差。
- **现状：** `tabBarItem.image` 和 `tabBarItem.selectedImage` 均使用 `UIImageRenderingModeAlwaysTemplate`，三个资源目录图像集均声明 `"template-rendering-intent" : "template"`，且 `MADThemeManager` 用全对比度的 `[UIColor labelColor]` 配置未选中的 tab bar 项。
- **测试：** `MADDesignerUnitTests testTabBarAndViewerToolbarLayout`。

### `MADNavigationControllerViewer` 和 `MADNavigationControllerQueryBuilder` 的底部工具栏在 iOS 26 上与浮动 `UITabBar` 重叠，并挤压 `MADLabelStatus`
- **状态：** 已于 2026-10-28 修复。
- **位置：** `MADDesigner/Source/MADNavigationControllerViewer.m`、`MADDesigner/Source/MADNavigationControllerQueryBuilder.m` 以及 `MADDesigner/Source/MADLabelStatus.m`。
- **行为：** 在 iOS 26+ 上，`UINavigationController` 将其工具栏托管在私有的 `FloatingBarContainerView` 内，仅使用窗口的底部安全区域内边距定位，忽略了父 `UITabBarController` 的浮动 `UITabBar`。结果，尽管 `UINavigationController` 在计算 `MADViewerController.view` 尺寸时在 tab bar 上方预留了空间，状态工具栏本身却被固定在屏幕底部、正处于浮动 `UITabBar` 下方。此外，iOS 26 将 `UIBarButtonItem.customView`（`MADLabelStatus`）包装在 `UIPlatformGlassInteractionView` 内的 `_UITAMICAdaptorView` 中，由于 `MADLabelStatus` 没有 `-intrinsicContentSize` 或宽高约束，`MADLabelStatus` 被压缩到了 `38pt` 宽。
- **现状：** `MADNavigationControllerViewer` 和 `MADNavigationControllerQueryBuilder` 实现 `-viewDidLayoutSubviews`，当 tab bar 可见时，将经典的 `self.toolbar`（`self.toolbar.superview == self.view`）和 iOS 26 的 `FloatingBarContainerView` 都定位在 `self.tabBarController.tabBar` 正上方；同时 `MADLabelStatus` 提供 `-intrinsicContentSize`（`230x44`）和显式的宽高约束，使 3 行状态读数在浮动工具栏胶囊内不会被压缩。
- **测试：** `MADDesignerUnitTests testTabBarAndViewerToolbarLayout`。

### `MAD Viewer` 启动黑屏，原因是缺少 `UIScene` 生命周期清单、应用源码未被编译、storyboard 和示例资源未打包
- **状态：** 已于 2026-10-29 修复。
- **位置：** `MADDesigner/Targets/MADViewer/info.plist`、`MADDesigner/Targets/MADViewer/SupportingFiles/main.m`、`MADDesigner/Source/AppDelegate.m`、`MADDesigner/Source/MADTabBarController.m`、`MADDesigner/Source/MADExplorerNavigationItem.m`、`MADDesigner/Source/MADExplorerController.m`、`MADDesigner/Source/MADExplorerController+DocumentActions.m`、`MADDesigner/Source/MADUpgradeManager.m` 以及 `MADDesigner/MAD Designer.xcodeproj/project.pbxproj`。
- **行为：** 启动 `MAD Viewer` 应用 target 会记录日志 `"`UIScene` lifecycle will soon be required. Failure to adopt will result in an assert in the future."` 并显示纯黑窗口。具体而言：
  1. `MADDesigner/Targets/MADViewer/info.plist` 没有 `UIApplicationSceneManifest`，也没有 `UIMainStoryboardFile`，而 `MADViewerAppDelegate.m` 手动实例化了一个没有 `rootViewController` 的 `UIWindow`。
  2. 在 `project.pbxproj` 中，`MAD Viewer` 的 `Sources` 构建阶段只编译了 7 个文件（缺少 `AppDelegate.m`、`SceneDelegate.m`、`MADExplorerController.m`、`MADTabBarController.m`、`MADViewerController.m` 以及 `MADDesigner/Source/` 的其余文件），其 `Resources` 构建阶段只打包了 4 个文件（缺少 `MADExplorer.storyboard`、`MADDesigner.storyboard`、`SampleDatabases.xcassets`、`FontAwesome.ttf` 以及关于/商店 storyboard），且其 Debug 配置缺少 `MAD DesignerDebug.entitlements`（`group.everydayapps.mad.local`）。
  3. `MADTabBarController` 总是创建全部 3 个标签页（`MADQueryBuilderSplitViewController`、`MADNavigationControllerDesigner` 和 `MADNavigationControllerViewer`）并保持 `UITabBar` 可见；`MADExplorerNavigationItem` 将标题硬编码为 `"MAD Designer"`；`MADExplorerController` 保留了可见的 `+`（创建新文档）栏按钮项。
- **现状：** `MAD Viewer` 与 `MAD Designer` 共享 `AppDelegate` 和 `SceneDelegate`（退役过时的 `MADViewerAppDelegate` 副本，并在 `#if MAD_VIEWER` 下选择阅读器标识符/名称），在 `MADDesigner/Targets/MADViewer/info.plist` 中声明 `UIApplicationSceneManifest`（`SceneDelegate` + `MADExplorer` storyboard），在 `project.pbxproj` 中编译完整的共享源码集并打包所有必需的 storyboard/资源/素材，将资源管理器标题设为 `"MAD Viewer"`，在 `MADExplorerController` 中隐藏 `+` 按钮，并在 `MAD_VIEWER` 或 `[MADApplication isMADViewer]` 为真时将 `MADTabBarController` 配置为隐藏 `UITabBar` 且仅以 `[navControllerViewer]` 作为唯一子控制器。
- **测试：** `MADDesignerUnitTests testMADViewerModeHidesTabBarOmitsDesignerTabsAndHidesAddDocumentButton`。

### `MADNavigationController +documentNavigationControllerWithType:document:` 在 `MAD Viewer` 中为 `MADNavigationControllerTypeViewer` 抛出 `NSInternalInconsistencyException`
- **状态：** 已于 2026-10-29 修复。
- **位置：** `MADDesigner/Source/MADNavigationController.m:20-23,149-182`。
- **行为：** `+documentNavigationControllerWithType:document:` 将其整个 `switch (type)` 块（包括 `case MADNavigationControllerTypeViewer:`）包裹在 `#if MAD_DESIGNER` 内，导致编译进 `MAD Viewer` target（其中定义了 `MAD_VIEWER=1` 而未定义 `MAD_DESIGNER`）时直落到 `@throw [NSException exceptionWithName:NSInternalInconsistencyException ...]`。
- **为何重要：** 在 `MAD Viewer` 中打开任何文档都会让 `MADTabBarController` 通过 `[UINavigationController documentNavigationControllerWithType:MADNavigationControllerTypeViewer document:document]` 构建阅读器导航控制器，从而无条件因 `NSInternalInconsistencyException` 崩溃。
- **现状：** 无条件导入 `MADNavigationControllerViewer.h`，且在 `MAD Designer` 和 `MAD Viewer` 中均编译 `case MADNavigationControllerTypeViewer:`，而 `MADNavigationControllerTypeDesigner` 和 `MADNavigationControllerTypeQuery` 仍限定在 `#if MAD_DESIGNER` 内。
- **测试：** `MADDesignerUnitTests testNavigationControllerViewerFactoryAndNavigationBar`。

### `MADViewerController` 把刷新按钮、完成按钮和刷新活动指示器设在隐藏的 `self.tabBarController.navigationItem` 上，而不是 `self.navigationItem`
- **状态：** 已于 2026-10-29 修复。
- **位置：** `MADDesigner/Source/MADViewerController.m:203-204,225,421,442`。
- **行为：** `-viewDidAppear:`、`-viewDidDisappear:`、`-setDisplayActive` 和 `-setDisplayInactive` 修改的是 `self.tabBarController.navigationItem.rightBarButtonItem` 和 `leftBarButtonItem`。然而，`MADTabBarController -viewDidLoad` 隐藏了其外围导航控制器的导航栏（`[self.navigationController setNavigationBarHidden:YES animated:NO]`），而阅读器中可见的导航栏是 `MADNavigationControllerViewer` 的 `MADViewerNavigationBar`，它显示的是 `MADViewerController` 自身的 `self.navigationItem`。
- **为何重要：** 当 `-setDisplayInactive` 启动刷新时，旋转的 `UIActivityIndicatorView` 被放到了隐藏的 `tabBarController.navigationItem` 上，而可见的导航栏一直显示静态的刷新图标；同时 `-viewDidAppear:` / `-setDisplayActive` 也将它们新创建的 `buttonRefresh` 和 `buttonDone` 项写到了隐藏的导航项上，而不是可见的那个。
- **现状：** `-viewDidAppear:`、`-viewDidDisappear:`、`-setDisplayActive` 和 `-setDisplayInactive` 全部更新 `self.navigationItem`。
- **测试：** `MADDesignerUnitTests testViewerControllerNavigationItemsSetOnOwnNavigationItem`。

### `MADOperationInstallSampleDocument` 在追加 `.mad` 文件扩展名之前检查 `fileExistsAtPath:`，覆盖了已有的示例文档
- **状态：** 已于 2026-10-29 修复。
- **位置：** `MADDesigner/Source/MADOperationInstallSampleDocument.m:60-85`（以及 `MADDesigner/Source/MADOperationInstallSampleDatabase.m:51-77` 中配套的 `fileExistsAtPath:` 守卫）。
- **行为：** `MADOperationInstallSampleDocument -execute` 构建了 `destination = [localDocumentsDirectory URLByAppendingPathComponent:_filename isDirectory:NO]`（例如不带 `.mad` 的 `.../Documents/London`），检查 `[[NSFileManager defaultManager] fileExistsAtPath:destination.path isDirectory:&isDirectory]`，并且只有在 `fileExistsAtPath:` 返回 `NO` *之后*才追加 `destination = [destination URLByAppendingPathExtension:_fileExtension]`（`.../Documents/London.mad`）并覆盖文件。
- **为何重要：** 因为磁盘上从不存在 `Documents/London`（不带 `.mad`），升级存在性检查总是求值为 `NO`，启动 `MAD Viewer`（或重置 `NSUserDefaults`）会覆盖共享应用组容器中已有的任何 `London.mad` 或 `Music.mad`。反过来，`MADOperationInstallSampleDatabase` 只相信 `NSUserDefaults` 布尔值，而不检查 `chinook.sqlite3` 是否确实存在于磁盘上。
- **现状：** `MADOperationInstallSampleDocument` 在调用 `fileExistsAtPath:` 之前将 `_fileExtension` 追加到 `destination`，而 `MADOperationInstallSampleDatabase` 同时验证 user-defaults 键以及 `databaseURL.path` 上的 `fileExistsAtPath:`。
- **测试：** `MADDesignerUnitTests testInstallSampleDocumentDoesNotOverwriteExistingFileWithExtension`。

### `MADExplorerController -documentManagerDidChangeContent:removes:updates:completion:` 在未挂载的 `UICollectionView`（`window == nil`）上调用 `performBatchUpdates:`，因 `NSInternalInconsistencyException` 崩溃
- **状态：** 已于 2026-10-29 修复。
- **位置：** `MADDesigner/Source/MADExplorerController.m:402-415`。
- **行为：** 当 `MADFilesController` 完成文件枚举并在 `self.collectionView.window == nil` 时（在集合视图被添加到窗口或执行初始布局之前）将插入内容投递给 `MADExplorerController -documentManagerDidChangeContent:removes:updates:completion:`，调用 `[self.collectionView performBatchUpdates:completion:]` 会导致 `UICollectionView` 在批次开始时首次查询 `[dataSource collectionView:numberOfItemsInSection:0]`——此时 `fileMetaDatum` 已经持有了插入的项——随后再应用 `insertItemsAtIndexPaths:`，从而抛出 `NSInternalInconsistencyException`（`Invalid batch updates detected`）。
- **现状：** 当 `self.collectionView.window == nil` 时，`-documentManagerDidChangeContent:removes:updates:completion:` 调用 `[self.collectionView reloadData]` 并直接调用 `completion(YES, nil)`。
- **测试：** `MADDesignerUnitTests testMADViewerModeHidesTabBarOmitsDesignerTabsAndHidesAddDocumentButton`。

## Linux 构建

### 通过 MySQL 执行 `mad refresh` 会中止：category 不是符号，因此链接器丢弃了它
- **状态：** 已修复
- **位置：** `Linux/CMakeLists.txt:138,381-384` 和 `Linux/cmake/MADLinuxFramework.cmake` 中的编排；失败表现在 `CLI/Source/MADCLIDocument.m` 的刷新链中
- **行为：** 从 Linux 镜像内部针对现役 MySQL 执行的第一次 `mad refresh` 在进入 `executeSQL:` 之后、抓取之前以 SIGABRT 中止，且没有任何诊断信息。`MADMySQLFetch (DataTable)`——`-fetchWithCommand:dataTable:onConnection:extendedNames:error:`，唯一运行预处理语句的路径——是一个 *category*，而 category 通过消息发送到达，不会留下供链接器解析的符号；libmadmysql.a 按常规方式链接，因此该成员从未被拉入。`nm` 显示 `.objc_category_MADMySQLFetchDataTable` 存在于 MySQL 测试二进制文件中，却不存在于 CLI 二进制文件中；运行时 `instancesRespondToSelector:` 为假，未识别的选择子最终导致 `abort()`。
- **为何重要：** 未做 whole-archive 的任何框架归档中的每一个 category 都潜伏着同样的失败。构建本来知道这种形态（出于完全相同的原因，`MADQuery+Sqlite3.m` 这一个文件被手动编译进了 `libmad.a`），但原因——category 对链接器不可见——没有写下来，因此每新增一个 category 就是一颗新地雷。
- **现状：** `Linux/Compat/*` 成为独立的静态库 `madcompat`（`Linux/CMakeLists.txt:138`），由每个可执行文件以 whole-archive 方式链接，从而保证框架归档纯净、自身也能被 whole-archive：`mad` target 对 `madsqlite3`、`madmysql` 和 `madtdsclient` 进行 whole-archive（而 MADTds 被有意排除在外——它没有 category，且对它做 whole-archive 会与 freetds 的 `err_handler` 冲突）。按文件的 `target_sources` 权宜做法已移除。`Linux/README.md` 记录了来龙去脉；`Linux/AGENTS.md` 写明了规则。
- **测试：** `Linux/Tests/MADDatabaseDriverDispatchTests.m`（`testTheDriversCategoriesAreLinked`）在运行时断言 `MADMySQLFetch` 仍然响应其 `DataTable` 选择子，且 `MADQuery` 仍然响应 `-whereClauseWithRowIds:` / `-whereClauseWithParameters:`——数据路径所需的两个 category。一旦某个归档不再被 whole-archive，该测试立即失败。

### 三处 `Rptq…+extras.h` 导入的大小写写错了，只有区分大小写的文件系统才能发现
- **状态：** 已修复
- **位置：** `MAD/Source/MADOperationRefreshInitialize.m:34-36`（在 `a17d802be` 中修复）、`MAD/Source/MADOperationCreateDocumentFirstTimeSetup.m`（同样的三处，预防性修复）
- **行为：** 导入写的是 `<MAD/RptqDocument+extras.h>`、`<MAD/RptqDatabase+extras.h>` 和 `<MAD/RptqQuery+extras.h>`；头文件实际为 `RptqDocument+Extras.h`、`RptqDatabase+Extras.h`、`RptqQuery+Extras.h`。Mac 的文件系统不区分大小写，因此应用 target 编译了它们好几年，模拟器 CLI 也顺利编译。Linux 镜像将源码复制到 ext4 上并*拒绝*了它们：镜像构建在迁移后的文件上因致命错误失败。
- **为何重要：** 这是一类缺陷，而非孤例：任何大小写与文件名不符的导入都只会在这里暴露，而在 Mac 上完全不可见。找出全部此类问题的审计方法已记录在 `Linux/AGENTS.md` 中（将每个 `<Framework/Header>` 导入与目录列表比对精确大小写）。
- **现状：** 三处导入均按磁盘上的实际拼写书写头文件。第一处由镜像构建发现；第二个文件尚未纳入 Linux 构建（它是创建文档操作之一），也一并修正，否则将来纳入当天也会以同样方式失败。
- **测试：** Linux 镜像构建（该修复自身的回归测试）。

## 构建接线（Xcode 引用）

### 三个库引用指向从未创建的目录
- **状态：** 已修复
- **位置：** `MAD/MAD.xcodeproj/project.pbxproj` —— `libct.a` 和 `libsybdb.a`，均位于 `../opt/lib/freetds/`；`Scrimpter/Scrimpter.xcodeproj/project.pbxproj` —— 位于 `../MADDataStructures/build/Debug-iphoneos/` 的 `MADDataStructures.framework`
- **行为：** 三个路径均相对于项目目录，因此它们指向 `MAD/../opt/lib/freetds/` 和 `Scrimpter/../MADDataStructures/build/…`。这两个目录在此检出树中从未存在过。
- **为何重要：** 悬空引用不会让构建失败，因此没有任何机制能将它暴露出来。`ld` 收到一个不存在的文件，随后又通过 `LIBRARY_SEARCH_PATHS` 找到了该库——对于 MAD 的两个库，即 `Compressor/library/freetds/iOS/lib` 中的 iOS 切片。该引用是一个看似真实依赖的谎言：正是它让 `MAD` 看起来像是直接链接了 freetds，而实际上链接 freetds 的框架是 `MADTds`。
- **现状：** 三处均已移除——包括 `PBXBuildFile`、`PBXFileReference`、Frameworks 阶段条目和组子项。MAD 的两处可以安全移除，因为在构建产物 `MAD.framework/MAD` 上运行 `nm -u` 报告没有任何 `ct_`、`sybdb` 或 `tds` 未定义符号。Scrimpter 的那一处从工作区外且无共享 scheme 的项目中移除，该项目原本就无法链接：其 `LIBRARY_SEARCH_PATHS` 指向一个不存在的 `DerivedData/Reports-dojbzwnmytpjqefezxjmhftrkacg`，且没有任何地方构建 `MADDataStructures`。在此记录 Scrimpter 的头文件确实写了 `#import <MADDataStructures/MADDataStructures.h>`，以免这一依赖关系随引用的删除而遗失。
- **证据：** `MAD Designer` 可构建；`MAD` 176 个测试，0 失败。

### 五个库搜索路径指向从未创建的目录
- **状态：** 已修复
- **位置：** `MADMySQL/MADMySQL.xcodeproj/project.pbxproj`（无后缀的 `LIBRARY_SEARCH_PATHS`，Debug 和 Release）以及 `MADDesigner/MAD Designer.xcodeproj/project.pbxproj` 中的 MAD Viewer target（Debug 和 Release）
- **行为：** MADMySQL 的基础值为 `$(SRCROOT)/../Compressor/library/openssl/lib/iOS`；真实布局是 `openssl/iOS/lib`，`[sdk=…]` 分支已经正确指定了该路径。MAD Viewer target 列出了五个不存在的目录——`library/libsybdb`、`../libMySqlClientObjectiveC/build/Release-iphoneos`、`libMysqlClient/MysqlClient`、`../CloudManager/build/Debug-iphoneos`、`../MAD/MAD/build/Debug-iphoneos`——并把 `$(PROJECT_DIR)` 列了两次。
- **现状：** MADMySQL 中的基础值改为 `""`，与同级框架一致；阅读器的失效条目和重复项均已移除。阅读器 target 生成的链接行现在只包含存活的条目：`Compressor/library`、`library/libmysqlclient`、`library/libpng`、`library/openssl`、`MADDesigner`。
- **测试：** `MADMySQL` 58 个测试，0 失败，且应用构建成功链接 MADMySQL。

### 工作区用绝对路径固定了 MADTds
- **状态：** 已修复
- **位置：** `Reports.xcworkspace/contents.xcworkspacedata:44`
- **行为：** MADTds 的 `FileRef` 是 `location = "group:/Users/michael/Desktop/Reports/MADTds/MADTds.xcodeproj"`——工作区中唯一的绝对路径；其他所有项目都使用可移植的 `group:<name>` 形式。移动源码树会留下过期引用，导致工作区丢掉 MADTds。
- **为何重要：** 它使工作区与特定机器绑定，因而是 Compressor 改造所要通过的“移动源码树”可移植性测试中的第一个失败点。
- **现状：** `location = "group:MADTds/MADTds.xcodeproj"`，与其他所有条目一致。
- **证据：** 在源码树迁移后的副本上运行 `xcodebuild -list -workspace Reports.xcworkspace` 可列出全部 18 个 scheme。

### CLI/build.sh 指定了机器相关的 DerivedData 目录
- **状态：** 已修复
- **位置：** `CLI/build.sh:22`
- **行为：** DerivedData 默认值为 `${HOME}/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci`，这是 Xcode 曾在这台机器上生成的单机哈希。在任何其他检出环境上，脚本会先构建各框架，然后去一个不存在的目录里寻找产物。
- **为何重要：** 新克隆仓库后运行 `CLI/build.sh` 会找不到它刚刚构建好的框架——这是另一个构建入口点中出现的、与上面工作区修复所解决的同一种可移植性失败。
- **现状：** 默认值改为项目本地的 `${REPO_ROOT}/.cli-deriveddata`，传给 `xcodebuild -derivedDataPath`，并已加入 `.gitignore`。`MAD_DERIVED_DATA` 仍可像以前一样覆盖默认值。
- **证据：** `CLI/build.sh` 可从干净源码树完成构建，且 `CLI/build.sh --run inspect` 可正常运行。

### MADMySQL 每次构建都带着多余的 `-v` 链接
- **状态：** 已修复
- **位置：** `MADMySQL/MADMySQL.xcodeproj/project.pbxproj` —— 项目级 Debug 和 Release 的 `OTHER_LDFLAGS`
- **行为：** `OTHER_LDFLAGS = ("-lc++", "-v")`——框架及其测试的每次链接都让链接器以详细（verbose）模式运行，淹没了真正的链接输出。
- **现状：** 仅保留 `"-lc++"`。
- **证据：** `MADMySQL` 58 个测试，0 失败，链接行输出干净。

### 应用 target 无谓地定义了 SQLITE_ENABLE_COLUMN_METADATA
- **状态：** 已修复
- **位置：** `MADDesigner/MAD Designer.xcodeproj/project.pbxproj` —— `MAD Designer` target 的 `GCC_PREPROCESSOR_DEFINITIONS_NOT_USED_IN_PRECOMPS`（Debug 和 Release）
- **行为：** `SQLITE_ENABLE_COLUMN_METADATA=1` 留在应用的宏定义中，在那里毫无作用：应用并不编译 `sqlite3.c`——合并源码（amalgamation）是由 `MADSqlite3` target 编译的，其选项来自 `Compressor/sqlite3.xcconfig`。它看起来像是 SQLite 标志的第二个归宿，而这正是 H7 修复所消除的“两个消费者”错误。
- **现状：** 已移除。应用的 SQLite 行为完全取决于构建 `MADSqlite3` 时所用的配置，理应如此。
- **证据：** `MAD Designer` 可构建；`MADSqlite3` 72 个测试通过，5 个跳过，0 失败。

### 仅靠搜索路径无法接好 macOS 构建
- **状态：** 已修复 —— 通过 Compressor 改造中的 XCFramework 重新接线完成
- **位置：** 每一处随仓提供的 `.a` 引用，例如 `MAD/MAD.xcodeproj` 中位于 `../Compressor/library/libarchive/iOS/lib/libarchive.a` 的 `libarchive.a`、`MADTds/MADTds.xcodeproj` 中位于 `freetds/iOS-arm64/lib/` 的 `libct.a`，以及 `MADBarcodes/MADBarcodes.xcodeproj` 中位于 `libpng/libpng.a` 的 `libpng.a`
- **行为：** 两者之中只有 `LIBRARY_SEARCH_PATHS` 可以按 SDK 条件化（`[sdk=…]` 分支），`PBXFileReference.path` 则不能。因此即便配置了 `[sdk=macosx*]` 搜索路径，仍然会链接文件引用所指定的 iOS 切片，而 `lipo -info` 显示它们没有一个是 macOS 架构：`libarchive/iOS/lib/libarchive.a` 是 `arm64 arm64e`，`freetds/iOS-arm64/lib/libct.a` 是 `arm64`，`openssl/iOS/lib/libssl.a` 是 `arm64 arm64e`。链接器会拒绝为其他平台构建的文件。
- **现状：** 每个消费方 target 都改为链接 XCFramework 而非 `.a` 路径，因此工具链会自动挑选当前构建平台对应的切片，无需再做任何按 SDK 条件化的配置。按 SDK 条件化的搜索路径分支已从各处删除（仅 MAD Viewer target 的遗留列表以及工作区外的 Scrimpter 保持原样）。构建矩阵也为每个库构建了 macOS 切片，因此 `zlib/macOS` 和 `mysqlclient/macOS` 现已存在（补齐了 Track 2.2 缺失的两行）。
- **仍然受阻，且暂保持如此：** `SUPPORTED_PLATFORMS` 目前还不能加入 `macosx`，因为每个框架都构建在 `MADFoundation` 之上，而 `MADFoundation/Source/MADApplication.h:13` 导入了 `UIKit/UIApplication.h`。探测命令（`xcodebuild build … -destination 'platform=macOS' SUPPORTED_PLATFORMS=macosx`）会因 `'UIKit/UIApplication.h' file not found` 失败。现在打开该设置只会宣称支持一个没有任何 target 能编译通过的平台。XCFramework 已经为未来解耦落地的那一天做好了准备；此处改动不会提前解除应用侧 macOS 工作的阻塞。

### MAD Viewer target 自 `09e0e7b8d` 起就未能链接
- **状态：** 已修复
- **位置：** `MADDesigner/MAD Designer.xcodeproj/project.pbxproj` 中的 MAD Viewer target、`MADDesigner/Source/MADNavigationController.m`、`MADDesigner/Targets/MADViewer/MADViewerAppDelegate.m`
- **行为：** 其构建设置仍指向已被 `09e0e7b8d`（“Project cleanup and reorganization”）删除的目录 `MADStack/`——`CODE_SIGN_ENTITLEMENTS` 和 `GCC_PREFIX_HEADER` 指向 Designer 的旧路径，且 `INFOPLIST_FILE = MADStack/MADViewer/info.plist`。构建在 `ProcessProductPackaging` 阶段便因 *"Build input file cannot be found"* 停止。将这六项设置改指 `Targets/MADViewer/` 后得以进入链接阶段，但随后又因未定义类（`MADApplication`、`MADDesignerNavigationBar`、`MADNavigationControllerDesigner`、`MADNavigationControllerViewer`、`MADSalesReceipt`、`MADThemeManager`、`MADViewerNavigationBar`）和缺失的框架链接而失败。
- **现状：** `MAD Viewer` target 编译 `MADStoreConverter.m`、`MADStoreLegacyConverter.m`、`MADThemeManager.m`、`MADSalesReceipt.m`、`NSData+Base64.m` 和 `MADViewerNavigationBar.m`，链接并嵌入工作区各框架及 `openssl.xcframework`，将 `MADNavigationController.m` 中针对 Designer 标签页的工厂方法 `+documentNavigationControllerWithType:document:` 限定在 `#if MAD_DESIGNER` 下，并在 `MADViewerAppDelegate` 上实现缺失的 `MADApplicationProtocol` 方法。
- **验证：** `xcodebuild build -workspace Reports.xcworkspace -scheme "MAD Viewer"` 可干净地完成构建与链接。

## 已修复（供参考）

### MADFoundation 批次：十个缺陷，每个都先做了调用者审计
- **状态：** 已修复
- **提交：** `39ffa249c`（同时更正了 BUGS.md 中两处有误的影响说明）
- **位置：** `MADFoundation/Source/MADDataColumn.{h,m}`、`MADGroupOperation.{h,m}`、`MADKeyChain.m`、`MADOperationConditionResult.m`、`MADOperationConditionTestConnectionSuccess.m`
- **行为与修复：**
  - `MADDataColumn -addRows:` 循环条件为 `i <= count`，多加了一行。**现状：** `i < count`。旧记录称 SQLite 结果缓存会“多出一行”；那是不对的——该方法**没有生产调用者**，因此从未产生过幽灵行。
  - `MADDataColumn -initWithType:` 将 `length:` 实参存入了 `dataLength`。**现状：** 存入 `dataLen:`，与属性名一致。目前无实际影响（唯一的调用者从不读回它）；`number:`、`indexOfType:` 和 `length:` 暂保持未用，留待 MADTdsClient 阶段处理。
  - `MADDataColumn -initWithPlist:` 没有解码 `-copyPlist` 写入的 `@"~MTNull~"` 哨兵值。**现状：** 读写双方共用同一个具名常量，并将该哨兵值解码回 `[NSNull null]`。旧记录称这会“破坏报表数据”；同样不对——该哨兵值只触及从未被读取的 `defaultValue`，而行单元格挂在单独的 `"column"` 键下，往返完好无损。
  - `MADDataColumn -initWithCoder:` 编码了 `notNull` / `autoIncrement` 却从未解码。**现状：** 两者均已解码。
  - `MADDataColumn -objectAtIndex:` 在头文件中声明为 `instancetype`，而实现早已返回 `id`。**现状：** 头文件中改为 `id`。
  - `MADGroupOperation -addOperation:` 声明接受 `NSArray`，但实现接受 `NSOperation`；单参数的 `-addOperations:` 在头文件中缺失。**现状：** 两者均与实现一致并已在头文件中声明。
  - `MADGroupOperation` 的 delegate 调用了 `-finishWithError:self.aggregatedErrors.copy`，在预期单个 `NSError *` 的位置传入了一个*数组*，将其重新包装成一个本身是数组的虚假“错误”。**现状：** 改为调用接受数组的 `-finish:`。一词之改——`-finish:` 本就已在 `MADOperation` 上声明。消除了 `MADViewerController.m:925` 处的潜在崩溃（该处会向每个元素发送 `-localizedDescription`）。
  - `MADKeyChain -deleteSavedPasswordForKey:error:` 用 `if (deleteError != nil && *error != nil)` 做守卫，对 `NULL` 的 `error` 解引用，并把失败静默吞进新建的 `&err` 中。**现状：** `NULL` 情况合法，且失败会正常传出。
  - `MADOperationConditionTestConnection`（抽象基类）从 `-evaluateForOperation:` 返回 `nil`，违反了协议的 nonnull 契约。**现状：** 触发断言（`NSAssert(NO, … must be overridden)`）并在 Release 下返回 `nil`，与 `MADDataTable` 基类一致。
  - `MADOperationConditionResult` 用 `domain:NSStringFromClass([self class])` 构建错误，把*结果子类*名称放进了错误域。**现状：** 使用固定的 `@"MADOperationCondition"`；条件名称仍通过 `userInfo[MADOperationConditionKey]` 传递。
- **测试：** MADFoundation 116 → 118，0 失败。原先锁定缺陷行为的表征测试已翻转；`-finish:` 获得了它此前从未有过的回归守卫（`MADGroupOperationTests.m` `testFinishingWithSeveralErrorsKeepsThemSeparate`）。

### MADCocoaExtensions 批次：七个缺陷，一处有意的非改动
- **状态：** 已修复
- **提交：** `86e9ecfb9`（同时更正了 BUGS.md 中一处有误的“未使用”说法）
- **位置：** `MADCocoaExtensions/Source/CGGeometry+Extras.h`、`MADTextStyle.m`、`MTMath.{h,m}`、`MADColorSocial.{h,m}`
- **行为与修复：**
  - `CGRectBottomLeft` / `CGRectBottomRight` / `CGRectTopRight` 返回了转置的点（仅对位于 `(0,0)` 的正方形矩形才凑巧正确）。**现状：** 返回真正的角点，与同级的 `CGCorner*PointInRect` 函数一致。
  - `CGCenterRect` 返回 `((x + w)/2, (y + h)/2)`。**现状：** `origin + size/2`。
  - `MADDirectionHorizontalDirectionOfPoint` 的左/右颠倒了。**现状：** 与函数字面含义一致。无论改前改后都没有调用者。
  - `MADDirectionVerticalDirectionOfPoint` 比较的是 X 而不是 Y，导致竖直线段报告 `NoDirection`。**现状：** 比较 Y。
  - `MADGeneralDirectionOfDegrees` 使用了严格不等号，导致精确的边界角度（`0`、`30`、`60` 等）全部落入 `north`。**现状：** 使用半开八分象限。
  - `MADTextStyle` 的初始化器向 `MADLayoutTextStyleMake` 传入了 `(bold, strikethrough, italic, underline)`，打乱了标志顺序。**现状：** 按结构体构造函数所需的顺序传入。各个 setter 原本就是正确的。
  - `MTMath` 的文件大小转换使用了整数除法（`1500000` → `1.0`）。**现状：** 除以 `1000000.0`。保留十进制兆字节——遵循项目约定（`MADStandard`）。整数到双精度浮点数的提升需要显式 `(double)` 转换，否则每个包含该头文件的 target 都会触发 `-Wimplicit-int-float-conversion`。
  - `MADColorSocial +newBlueTwitter` 声明为 `instancetype`，但实际返回 `newColorWitColors(…)`，即普通的 `UIColor`。**现状：** 声明为 `UIColor *`。旧记录称“这些类似乎未被使用”——那是不对的：它在 `MADAttributedStringCommon.m:32` 处用于渲染 Twitter 按钮。真正未使用的 `+newBlueLinkedIn` / `+newBlueFacebook`（从未声明、从未调用）已删除。
- **有意不作改动：** `CGRectAdjustForScale` —— 见上文 MADCocoaExtensions 下承重行为条目。仅添加了注释。
- **测试：** MADCocoaExtensions 76 个测试，0 失败。所有表征测试均已翻转，以锁定修正后的行为。

### `MADDataTableFast -objectAtRow:column:` 忽略其 `column` 参数
- **状态：** 已修复
- **提交：** `f51be71ef`
- **备注：** 在测试期间发现；该方法现在遵循 column 参数。保留于此，作为这项工作旨在捕获的缺陷类型的记录。

### `sqlite3_mprintf` 被传入 SQL 作为其格式字符串（8 处）
- **状态：** 已修复
- **位置：** `MADSqlite3/Source/MADDataTableFast.m`、`MADDatabaseSqlite3.m`、`MADDataTableObjectEnumerator.m`、`MADDataTableSingleColumnEnumerator.m`
- **行为：** `sqlite3_mprintf` 将其第一个实参当作*格式字符串*处理，因此直接传入 SQL（`sqlite3_mprintf(sql.UTF8String)`）意味着该 SQL 中的 `%` 会被读作格式转换符。函数随后会消费从未传入的实参并读取栈上的任意内容——破坏语句或导致崩溃。
- **现状：** 每处调用都传入字面量 `"%s"` 并将 SQL 作为实参传入。`grep -n sqlite3_mprintf MADSqlite3/Source/*.m` 显示共有十四处调用，没有任何一处使用可变格式字符串。
- **备注：** 可达性较低——`%` 必须出现在列名或表名中才会触发——但一旦触发就是静默的数据损坏。这是在修复 `-dataForRow:error:` 契约时通过代码检查发现的，而非通过测试发现；没有回归测试，因为触发它需要包含 `%` 的架构标识符。

### `MADDataTable` 基类静默失败而不是触发陷阱
- **状态：** 已修复（阶段 0）
- **位置：** `MADFoundation/Source/MADDataTable.m`
- **行为：** 基类将每一项行操作和列操作都做成了空桩。最糟糕的是，`-addRow:error:` 在丢弃行的同时返回 `YES`，导致忘记重写该方法的存储子类丢失数据却还报告成功。
- **现状：** 具体子类必须实现的九个操作均以 `NSAssert(NO, @"%s must be overridden", __PRETTY_FUNCTION__)` 断言，与现有的未实现枚举器组保持一致。`-addRow:error:` 在 Release 下返回 `false` 而不是 `YES`。
- **有意保持不变：** 可选的批量插入钩子，以及对于空表而言*如实*的读取结果（`-count` → `0`、`-allObjects` → `@[]` 等）。对这些方法加断言会把正确答案变成崩溃。划分依据见架构报告 §3.2。
- **测试：** `MADDataTableRegressionTests.m` 中的 `testBaseTableAbstractOperationsAssert`（受 Debug 守卫，因为 `NSAssert` 在 Release 中会被编译掉）取代了原先锁定静默行为的 `testBaseTableOperationsAreInert`。

### 批量插入运行期间 `MADDataTableFast -addRow:error:` 未受保护
- **状态：** 已修复
- **提交：** `470dfcab6`
- **位置：** `MADSqlite3/Source/MADDataTableFast.m`
- **行为：** 在 `-beginBulkInsert` 下，表在每次 `-addRow:error:` 调用之间复用同一个缓存的 `_statementInsert`，并在其上依次运行 `sqlite3_bind_*` → `sqlite3_step` → `sqlite3_clear_bindings` → `sqlite3_reset`。没有任何机制对这些序列进行串行化，因此两个写入器在同一张表上竞争时会在同一个语句上交错绑定并丢失行。`SQLITE_OPEN_FULLMUTEX` 对此无济于事：竞争发生在调用序列之间，而不是任何单个 sqlite 调用内部。该类唯一的并发原语 `queueBulkAdd` 只在一处使用——`-endBulkInsert` 的 barrier——这也使得 `_statementInsert` 的销毁同样与插入操作发生竞争。
- **现状：** `-addRow:error:` 在 `dispatch_sync(queueBulkAdd)` 下运行插入主体，而 `-endBulkInsert` 在其 `dispatch_barrier_sync` *内部*终结缓存的语句。在串行队列上，barrier 与 sync 互斥，这足以提供该序列所需的全部互斥保护。此前从未有调用者从多个线程驱动 `-addRow:`，因此这曾是一处隐患而非已发生的实际数据丢失。
- **测试：** `MADDataTableRegressionTests.m` `testFastTableConcurrentWritersLoseNoRows`（来自并发队列的四个写入器，写入 100 行并枚举出 100 行）。`testFastTableSerializedConcurrentWritesLoseNoRows` 上的 CONTRACT 注释原先写的是不支持并发写入器；现在改成了相反的说明。

### 重新加载的 `MADDataTableFast` 信任了可能过期的行计数器
- **状态：** 已修复
- **提交：** `470dfcab6`（重新加载半边）；`850c32f51`（内存半边）
- **位置：** `MADSqlite3/Source/MADDataTableFast.m`
- **行为：** plist 携带 `rowCounter` 但不携带行数据——行数据保存在 `.maddb` 文件中——因此 `-loadWithPlist:` 从一个来源恢复计数，却从另一个来源恢复数据。计数器与文件发生偏离的表在恢复后会报告偏离的计数。`-dropTable:`、`-deleteAll` 和 `-vacuumCacheDb` 都会改变行数而不触碰该计数器。
- **现状：** 重新加载半边先行落地：`-loadWithPlist:` 以 `-recountRows` 收尾，后者在查询连接上运行 `SELECT COUNT(*) FROM t<tag>`，仅当文件无法回答（尚无表或无句柄）时才回退到已保存的计数器。内存半边随后在 `850c32f51` 中落地——`-dropTable`、`-dropTableName:` 和 `-deleteAll` 将计数器归零，而 `-vacuumCacheDb` 有意不归零，因为 VACUUM 会保留每一行。`-numberOfRows` / `-count` 仍然返回实例变量而不是查询文件：这是刻意的设计，而非遗留缺口，因为 `-recountRows` 是重新加载路径的校验，不应成为每次读取的开销。本条目过去所要求的调用者审计已记录在上文的 `MADSqlite3` 一节中——`-deleteAll` 没有调用者，`-dropTable` 仅从 `-removeAllObjects` 到达，而 `MTTableController` 将 `count` 当作页游标使用。
- **测试：** `MADDataTableRegressionTests.m` 中的 `testFastTableReloadRecountsRowsFromCacheFile`（声称有 99 行的 plist 加载在只有 3 行的文件之上时，现在报告 3），外加 `testFastTableDropTableZeroesRowCount`、`testFastTableDropForeignTableKeepsRowCount`、`testFastTableDeleteAllZeroesRowCount` 和 `testFastTableVacuumKeepsRowCount`。

### `MADDesignerTestConnection.m` 是一个空模板，却仍在运行
- **状态：** 已修复
- **位置：** `MADDesigner/Targets/MADDesignerUnitTests/MADDesignerTestConnection.m`
- **备注：** 一个未曾改动过的 Xcode 模板——空的 `-testExample` 和空的 `-testPerformanceExample`——每次运行都会贡献两个空操作测试。该文件及其在 `project.pbxproj` 中的四处条目已移除。

## 测试基础设施（非产品缺陷）

### `MADTestReportFormatter` 被阻塞，而记录的原因有误
- **状态：** 已修复
- **位置：** `MAD/MADTests/MADTestReportFormatter.m`
- **行为：** 整个文件被注释掉了。登记表（以及一条记忆笔记）称，在将 Core Data 模型加入构建阶段之前无法恢复它。但那件事早就做过了：`MAD.xcdatamodeld` 已在 `MADTests` target 的 Sources 阶段中，因此 `MAD.momd` 会被构建进测试 bundle，而且 `MADCoreDataModelTests` 一直在加载它。所记录的阻塞原因早已过时；真正阻塞该测试的是测试夹具（fixture）。
- **现状：** 该测试已运行，且 `testGroupFooterRowIDAssociation` 通过。有四件彼此独立的事必须弄对，没有一件是模型本身：
  - `MADReportFormatter` 接受一个 `MADocument`，并从中读取 `-filename`、`-database` 的类、`-managedObjectContext` 和 `-resetSectionLayoutManagers`。测试把一个普通的 `RptqDocument` 强转为 `MADocument *`，但它并不是 `MADocument`——这正是最初 `unrecognized selector` 的原因。现在由测试替身 `MADTestReportFormatterDocument` 从内存栈回答这四项。真正的 `MADocument` 无法顶替：打开它会走 `-readFromURL:error:`，去解档由应用创建路径生成的 `.mad`。
  - 模型原先从 `[NSBundle bundleForClass:[RptqDocument class]]`（即没有 `MAD.momd` 的 **MAD.framework** bundle）加载。现在改为像 `MADCoreDataModelTests` 那样从测试 bundle 加载。
  - 上下文原先是扁平的。每个 `Rptq` 类都在 `-awakeFromInsert` 中分配其必需的 `identifier`，而该重写受 `self.managedObjectContext.parentContext` 守卫，因此扁平上下文会让每个新对象的 `identifier` 保持为 nil，保存时以 `NSValidationMultipleErrorsError`（1560）失败。测试现在采用与 `MADocument` 相同的双上下文结构。
  - 格式化之前没有保存任何内容。`MADSectionsLayout` 通过 `NSDictionaryResultType` 抓取读取各节，而字典结果抓取由存储回答，因此未保存的插入对它不可见，布局取不到任何节——将五个节布局全部置为 nil 并在 `MADSectionsLayout.m:115` 处崩溃。现在会先保存两个上下文。
- **另外：** 夹具还必须模拟缓存的行形态：以 `MADSectionGroupLayout -safeSortKey`（`alias + drop index + "." + field`）为键的分组值，以及每行的 `MADIdentifierROWID`（由基于 sqlite 的表在其枚举器中注入）。如果用裸字段名作键，每一行比较起来都相等，报表会坍缩成一个分组；如果没有行 id，每一行都会报告 0。

### 两个并行的 Linux 套件在同一个 London 测试夹具和示例数据库上发生竞争
- **状态：** 已修复（2026-10-17）
- **位置：** `Linux/CMakeLists.txt`（`mad_add_framework(mad …)` 块）、`Linux/Tests/MADHeadlessDocumentTests.m`、`Linux/Tests/MADReportExporterTests.m`
- **行为：** ctest 并行运行 119 个测试二进制文件，而这两个套件都会把 `chinook.sqlite3` 安装到同一个每用户 Application Support 目录（先删除再复制），并将同一个 London 夹具刷新到同一个缓存目录。当它们的时间窗口重叠时，其中一个就会失败——表现为 `MADHeadlessDocumentTests` 的 *problem in testTheRefreshChainFillsTheRowCache*，以及一次莫名的 `MADURLFactoryTests` 失败。GNUstep 从 `getpwnam` 而非 `HOME` 获取主目录，因此按测试设置 `HOME` 无法隔离它们。
- **现状：** 这两个测试带有共享的 ctest `RESOURCE_LOCK`（`mad-london-fixture`），因此在套件其余部分保持并行的同时由它们轮流执行。已于 2026-10-17 通过连续 35 次全绿并行运行验证；`Linux/AGENTS.md` 记录了该规则供后续套件遵循。
- **测试：** 套件自身（`./Linux/build.sh`）。

## Linux 构建

### 固定的跨平台导出摘要（digest）在 Apple 侧变得过时

- **状态：** 已于 2026-10-25 修复（提交 `b07b51f43`）。
- **位置：** `Linux/README.md` 中固定的摘要（导出表格）以及 `Linux/Tests/MADReportExporterTests.m` 中的 FNV-1a 预期值，于 2026-10-16 根据 Mac 侧导出的字节记录。行为变更来自 `c27cd4188`（"cache ORDER BY uses the column's MADDataType, so text keys sort under LSASC"，2026-10-18）：该排序规则位于 `MADSqlite3/Source/MADDatabaseSqlite3.m`（`compare_string_utf8_localized_asc_collation`），由 `MADDataTableFast -enumeratorForKeyObjectsSorted`（`MADSqlite3/Source/MADDataTableFast.m:1380`）选用。
- **行为：** 缓存的导出 ORDER BY 在 LSASC 下对文本键排序，即 `localizedCaseInsensitiveCompare:`——在 Apple 上走 ICU，在 GNUstep 上按码点排序（这一分歧已在 `MADDatabaseSqlite3Tests` 中按平台分别锁定）。ICU 将标点排在字母之前，因此 `[1997] Black Light Syndrome` 排在 `Core` 前面；按码点排序则将 `[` 排在 `Z` 之后。2026-10-25 在 `CLI/Fixtures/London.portable.mad` 上实测：Mac CLI（iOS 26.0 与 26.1 模拟器，框架构建于 `91d5b55ff`）导出的全部六种格式*大小*相同，但*分组顺序*不同——html 为 `285541ed…`，而固定值（以及当时的 Linux）为 `ba12a289…`；json、csv、text、json-report 和 html-flow 也以同样方式产生分歧。两边缓存的插入顺序完全一致（76 行按值逐一比较）；只有经过排序规则排序后的顺序不同。Linux 仍然匹配每一个固定摘要，因此 Linux 套件保持全绿，又没有任何机制重新测量 Mac 侧——这种过时是静默发生的。
- **为何重要：** “两个平台上字节完全相同”是发布声明（`MAD_STRATEGY.md` §3.2）和营销草稿的核心主张；固定摘要正是演示脚本所展示的内容。在此问题解决之前，该主张仅对 Linux 成立。
- **可选方案：** (a) 使导出顺序不依赖平台排序规则——采用两个平台都能实现的稳定、明确定义的顺序，这是保住该主张的修复方式；(b) 将固定值重新对齐到选为规范的任一平台顺序，并将主张弱化为“在给定平台排序规则下完全一致”；(c) 接受现状并写入文档。这不阻塞 Linux 演示，但在方案 (a) 落地之前，发布文章不得宣称 Apple/Linux 字节级一致。
- **现状：** 方案 (a) 已落地：导出的分组顺序采用明确定义的顺序——先做大小写折叠（Unicode 17.0.0 的简单一对一折叠，作为检入源码树的表位于 `MADFoundation/Source/NSString+Comparison.m`），再按 UTF-8 码点顺序比较——并由同一个比较器（`-[NSString mad_orderedCompare:]` 及其 C 核心）驱动全部三处位置：LSASC 排序规则、内存排序描述符（`MADDataTypeSelectorForSorting`）以及格式化器的字符串比较对。所有固定值均已在两个平台上重新测量且完全一致；`--reproducible` 写出的字节（16,261，`09815b24…`）未发生变化。在 Apple 上，London 夹具的分组顺序完全未变；`Music.portable.mad` 有 31 个专辑块（89 行）移到了该明确定义的顺序。
- **测试：** 将 Mac CLI 导出结果与 `Linux/README.md` 的表格比对（2026-10-25）。此前没有自动化的 Mac 侧摘要门禁；补上该门禁（`MADReportExporterTests` 的 Mac 侧对应测试）即为本次修复的证明——现已添加（`MAD/MADTests/MADReportExporterTests.m` 打开、刷新并导出 London 夹具，且锁定 FNV-1a 校验和），同时配套添加了明确定义顺序的测试（`NSStringComparisonTests`，双平台）以及 `MADDatabaseSqlite3Tests` 和 `MADReportExporterTests` 中排序规则与格式化器的一致性遍历测试。
