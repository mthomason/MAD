---
layout: default
lang: zh-CN
---

# ROADMAP.md

_MAD Designer_ 下一阶段工作的计划，以及推进它的顺序。

本文件是一份**计划**，不是要照着执行的队列。`BUGS.md` 是缺陷登记册，`TASKS.md`
是工程队列，`TODO.md` 是产品愿望清单。本文件说明的是：这两者中的哪些条目、以及
2026-10-01 写下的三份设计文档中的哪一份，接下来会被拾起，以及为什么按这个顺序。
`MAD_STORE_MIGRATION.md`（同日写成，在存储决策做出之后）是可移植存储的计划，自成一轨（§4.2 / `TASKS.md` §9）。当用户按名称或编号要求某一轨时，工作从这里开始。

写于 2026-10-01，基于 `master` 的 `073bb2e24`；同日基于 `master` 的
`c6e5cab0f` 重排，此时用户已经敲定了核心任务是什么。

---

## 核心任务

**定义 `.mad` 文档。** 它今天是什么，它应该是什么，它随身携带什么，
以及另一个平台上的读者如何打开它。本文件中的其他每一轨，要么是迈向它的一步，
要么是看清它的工具。

用户的原话：

> *“核心任务是定义这个 `.mad` 文档；我们还需要定义与之相关的文件……所有被构建出来的
> 缓存……我们需要理解它是什么，然后定义它将会是什么，然后让它可移植。此时重建静态库
> 并不会让它更接近这一目标。”*

两个推论重排了整个计划：

- **macOS 库构建不在路径上。** 2026-10-01 延期；Track 2 记录了为什么延期不带来任何代价。
- **`mad` CLI 是工具，不是产品。** 它不随产品发布。它存在的意义是：在应用不挡路的情况下，
  文档可以被读取、演练和测试——这使得 Track 3 成为手段，Track 4 成为目的。

---

## 项目现状

记录下来，以便计划可以被冷读。

**仓库是干净的，并且有备份。** `master` 位于 `c6e5cab0f`，已推送。Track 1 的修复
和 Track 2.1 的对账都已落在其上，两个已合并的工作分支已被删除。

**代码树可以构建，测试套件覆盖面广。** `MAD Designer` 可以构建。11 个套件中共有 885 个测试方法，其中 `MADMySQL` 和 `MADTdsClient` 带有实时套件，在没有可达服务器时跳过。MySQL 和 SQL Server 实例都可用于实时工作，且 `mad` CLI 无需 UI 即可驱动报表。

**格式已经被测量。** `MAD_FORMAT.md` 描述了容器、存储以及来自两个随发布样例的风险，并陈述了规范性目标。它处理得较薄的是伴随文件——Track 4.1。

**登记册的实际情况远比其标题数字所暗示的要好。** `BUGS.md` 有 76 条；56 条已完全修复。在未修复的 20 条中，**12 条是有记录的有意非缺陷**——被记录下来的承重形态，以免有人去“修复”它们。这样剩下大约四条真正未解决的缺陷，全列在 Track 1 中。

---

## Track 1 —— 关闭真正的缺陷积压 —— **2026-10-01 完成**

保留在此，因为其中的证据值得在不翻 git 的情况下也能读到。完整记录连同测试在 `BUGS.md` 中。

### 1.1 SQL Server 丢失每一个现代日期/时间值 —— **2026-10-01 完成**

`DATE`、`TIME`、`DATETIME2` 和 `DATETIMEOFFSET` 返回的是 `[NSNull null]`。只有列的*类型*被修正了；值被丢弃了。这是剩余最严重的缺陷，因为它是在已发布驱动上的静默数据丢失。

这些值现在会被读取。修复比看上去要小：这些类型代码**完全不需要绑定数组**。freetds 把每个值保存在行缓冲区里，且已解码为其自身的内部布局，而 `dbanydatecrack()`——传入该缓冲区加上列自身的类型代码——完成其余部分。绑定会把*转换过的*布局复制到别处，然后再去拆解错误的东西。

做这件事时，在同一个 freetds 记录中暴露了第二个更老的缺陷：经典的 `DATETIME` 和 `DATETIMEN` 分支又加了一个月，而 freetds 已经加过了，于是每个 SQL `DATETIME` 都晚了一个月，12 月的值则晚了一年。那也修好了，由同样的实时测试覆盖。`SYBDATETIME4` 的基准日期算术新登记为未解决。

`BUGS.md`，MADTdsClient，**Fixed**；测试 `testSelectModernDateTimeTypes`、
`testSelectModernDateTimeTypesNull`、`testSelectClassicDateTimeKeepsItsMonth`（实时）。

### 1.2 `MADDataTableFast` 行计数器——两份文档互相矛盾 —— **2026-10-01 完成**

这两份文档是 `BUGS.md` 和 `BUGS.md`。较旧的条目在*已修复（供参考）*之下，仍然写着“重新加载路径已修复；内存路径仍未解决”，并要求做调用方审计；`MADSqlite3` 一节中较新的条目在 `850c32f51` 处标为 **Fixed**，附四个测试，而这正是架构报告 Revision 5 所描述的。所以报告是对的，过时的文档是较旧的那条 `BUGS.md` 条目。

代码给出了定论：`-dropTableName:`（`MADDataTableFast.m:887`）和 `-deleteAll`（`:904`）把计数器清零，`-vacuumCacheDb`（`:868`）故意不清零，而 `-removeAllObjects`（`:756`）会清零。`-numberOfRows` / `-count` 返回实例变量而不是查询文件，这是设计——`-recountRows` 是重新加载路径的检查，不是每次读取的开销。

已修正过时条目的状态和 `Now:` 行，使其指向 `850c32f51`，这样登记册不再自相矛盾。没有代码改动；没有任何未决事项。

### 1.3 MySQL 的 `MADDataTypeMySQL` 映射 —— **2026-10-01 完成**

有两处映射一直处于“延期”状态。现在两者都已决定并记录在案。

`MYSQL_TYPE_TIME` **已修正**为 `MADDataTypeTime`。该映射是生效中的（`MADDatabaseMySQL.m:247`），并且错得会显现出来：`MADMySQLFetch+DataTable.m:431` 仅从时/分/秒构建值，因此 `NSDate` 携带日历的默认日期，而 `dateTimeformatter` 会把一个纯时钟渲染成 “1/1/01, 1:45 PM”。`MADDataTypeTime` 不是休眠情形——SQL Server 驱动多年来一直在产生它，其实时套件也断言它——所以纯时钟分支早已被演练过。测试已翻转：`MADMySQLTests.m`。

`MYSQL_TYPE_NULL` **保持为 `MADDataTypeNumber`**，现在写明了原因。`MADDataTypeNull` 是*绑定*用的 null（用于 null 参数的 `MADDatabaseDataBinding`，`MADQuery+Sqlite3.m`），不是列类型，它没有架构显示分支，因此会渲染成 “Type 24”。NULL 类型的列永远不可能持有值，所以该映射只决定一个架构标签和一个格式化分支。

`MADMySQL` 套件：58 个测试，0 失败。

### 1.4 解除 `MADTestReportFormatter` 的阻塞 —— **2026-10-01 完成**

记录下来的原因错了。据说该测试被阻塞，直到 Core Data 模型进入某个构建阶段；但 `MAD.xcdatamodeld` 一直都在 `MADTests` 的 Sources 阶段，而 `MADCoreDataModelTests` 自存在以来就一直从测试 bundle 加载 `MAD.momd`。所以这一项不是“解决模型”——模型早已解决，剩下的是一个从未运行过的测试夹具。

让它复活需要四处独立的修复，记录在 `BUGS.md` 的*测试基础设施*之下：

- 一个 `MADTestReportFormatterDocument` 替身，因为测试把普通的 `RptqDocument` 强转为 `MADocument *`，而格式化器会从它上面读取 `-filename` 和 `-database`。真正的 `MADocument` 无法顶替——打开一个会解档由应用创建路径生成的 `.mad`。
- 模型从测试 bundle 加载，而不是从框架 bundle 加载，后者没有 `MAD.momd`。
- 一个父上下文，因为每个 `Rptq` 类只有在 `managedObjectContext.parentContext` 被设置时才在 `-awakeFromInsert` 中设置其必需的 `identifier`。
- 在格式化之前保存，因为 `MADSectionsLayout` 以字典形式获取 section，而字典结果集的获取是由存储应答的。

另外两处是关于如何建模缓存而非 Core Data 的：分组值必须以 `MADSectionGroupLayout -safeSortKey` 为键，且每一行都需要一个 `MADIdentifierROWID`。

**这解除的不止那个测试的阻塞。** 这是第一次证明：一个文档的 section 树可以在无头环境下被构建、保存、获取和格式化——这正是 `MAD_CLI.md` §5.1 需要的 CLI 形态，也正是测试套件早已从另一侧撞上的同一约束。

**做这件事时发现：** `MADSectionGroupLayout` 在其字段没有查询表的分组上会段错误——它在 `:43`、`:46`、`:49` 和 `:58` 处把 nil 交给 `CFNumberGetValue`。测试宿主崩溃了而不是测试失败，问题就是这样浮出来的。记录在 `BUGS.md` 中为**仍未解决**：让测试夹具绕过它是本项的正确答案，但*布局应当如何处理一个它无法安置的分组*是一个尚未做出的行为决策。

`MAD` 套件：175 个测试，0 失败。

### 1.5 `"<null>"` / `"<NULL>"` 字符串 hack —— **2026-10-01 完成**

用户自己的描述：“显然是我这边的一个 hack，应该被处理”，并补充“虽然它可能不完美，但也不是意外。”

所以它们是可以动的，但必须先理解其消费者。审计把命中的地方分成三类，只有第一类是缺陷。

**哨兵值的往返早已是坏的。** `RptqDocumentElement -formattedString:forValue:` 用 `if (!value)` 做保护，这会漏掉 `NSNull`——它是对象，是真值。从源数据库读到的 NULL 以 `NSNull` 形式到达（这种表示是有意的，予以保留），于是它落到各分支中，而这些分支的文本路径都以 `-initWithFormat:@"%@"` 结尾。`[NSNull description]` 是 `"<null>"`；因此一个 NULL 会在报表上打印成字面文本 `<null>`。日期分支完全没有保护，会打印纪元。

四个本该撤销这一点的调用方拿 `MTNullIdentifier` 做比较，而它声明为 `@"(null)"`——*圆括号*，那是 nil 指针的格式化方式，不是 `NSNull` 的方式。该比较从未为真。这个常量从写下的那天起就是死的；唯一能匹配它的字符串是拼写为 `(null)` 的真实数据，而那恰好会被它抹掉。

在源头修复，这一族中的另一处 `NSNull` 情形（`MADQueryCacheSelectGroupKeys`）已经在那里修好了：保护现在覆盖 `NSNull`，四个比较被删除，常量也一并删除。

**保持原样，并记录在案。** SQL `NULL` 关键字的各处保留——它们是关键字，不是代表值的字符串。Scrimpter 的 `Null` 是其自身类型的语言级渲染，不在本工作区内。而 `MADQueryValueFromFieldController` 的选择器标签 `"NULL"` 确实是一个会到达 SQL 的字符串，但它是选择处理器复制进值字段的显示文本，而正确的答案——`IS NULL`——需要操作符枚举、SQL 构建器和 UI 三者一起改。记录在 `BUGS.md` 中为**仍未解决**；这是一个产品决策。

`MAD` 套件：176 个测试，0 失败。

### 有意不在 Track 1 中

那 12 处有记录的特殊行为。每一处都已带有代码内注释，点名依赖它的调用方。它们被正确记录，改动它们会破坏正常工作的行为。

---

## Track 2 —— 构建接线 —— **2026-10-01 延期**

**§2.2 和 §2.3 已延期——用户的决定，2026-10-01。** macOS 构建目前不被需要（“我们以后会为 MacOS 构建”），声明式构建系统被认同为重要但不是现在（“我们也会推迟声明式构建系统，尽管我认为它很重要。这些信息应该存进 plist 之类的东西里”）。两者都记录在 `TASKS.md` §6，因此延期是有跟踪的意图，而不是断掉的线索。

**用户的理由，也是正确的理由：** 重建静态库不会推动核心任务前进。Track 3、4 或 5 中没有任何内容需要 macOS slice。

**这一轨不构成任何门槛。** 原标题中的说法——“gates Tracks 3 and 4”——是在读过 `CLI/build.sh` 之前写的。Track 3 完全在 iOS Simulator 产物上构建和运行。如果说有依赖，倒是方向相反：Track 5.1 的解耦才是原生 macOS 二进制真正在等的东西。

这是 `LIBRARIES.md` §7，减去清理部分。

**这个发现是好消息。** 八行库中有五行只需要*接线*。bzip2、libarchive、openssl、libpng 和 freetds 的 macOS slice 已经存在于磁盘上。它们在构造上不可达：有 10 条 `LIBRARY_SEARCH_PATHS[sdk=iphoneos*]` 分支和 10 条 `[sdk=iphonesimulator*]` 分支，而 `[sdk=macosx*]` 分支**为零**。（项目文件中的 84 处 `sdk=macosx*` 命中全部是 `CODE_SIGN_IDENTITY`、`PROVISIONING_PROFILE_SPECIFIER` 和 `DEVELOPMENT_TEAM`——签名样板，不是库路径。）

§2.1 随后澄清了“接线”必须意味着什么。这些 slice 不只是通过一个缺失的设置而不可达：文件引用本身不是 SDK 条件化的，所以加上 `[sdk=macosx*]` 分支并不足以链接它们。见 §2.1。

**桌面上还有第二个 `Compressor`。** `/Users/michael/Desktop/Compressor` 是一个独立的 git 仓库，最后一次改动在 2025 年 6 月；本工作区中的这棵代码树是两个中较新的那个（它带有桌面副本所缺的 `gettext`、`libffi` 和 `sqlite3` 构建产物，以及截至 2026-10-01 的 `build_sqlite3.sh`）。哪个归档真正进入了上一次已发布的构建，从这里无法回答，也不需要回答——但这正是为什么不应未经询问就删除桌面副本。

### 2.1 对账 Xcode 引用 —— **2026-10-01 完成；第三条已完成于 2026-10-04，通过 XCFramework 重接线**

三条中的两条已落地：

- **完成。** 三个悬空引用已删除——`MAD` 在 `../opt/lib/freetds/` 下的 `libct.a` 和 `libsybdb.a`，以及 `Scrimpter` 在 `../MADDataStructures/build/Debug-iphoneos/` 下的 `MADDataStructures.framework`。它们本来也能链接，因为 `ld` 会回退到 `LIBRARY_SEARCH_PATHS`；MAD 的那两个先用 `nm -u` 在构建出的框架上确认了不需要。
- **完成。** 指向从未创建的目录的搜索路径被删除：`MADMySQL` 的基础值（`openssl/lib/iOS`，真实路径是 `openssl/iOS/lib`）以及 MAD Viewer target 的五个死条目和重复的 `$(PROJECT_DIR)`。
- **2026-10-04 完成。** 第三条无法按原文完成——`[sdk=macosx*]` 分支和 `SUPPORTED_PLATFORMS` 在这里不起作用，原因有两个，彼此独立：每个框架都建立在 `MADFoundation` 之上，而它的 `MADApplication.h:13` 导入了 UIKit；并且 `PBXFileReference.path` 不是 SDK 条件化的，所以这些分支仍会把 iOS 文件交给链接器。Compressor 的重做按本节所说的方式关闭了它：每个消费者现在链接一个 XCFramework，其 slice 由工具链挑选，SDK 条件化的搜索路径分支处处删除，矩阵为每个库构建 macOS slice。`SUPPORTED_PLATFORMS`/UIKit 那一半仍然受阻，如 `BUGS.md` 所述。

**顺带发现：** MAD Viewer target 自 `09e0e7b8d` 起就没有构建过。它的 `CODE_SIGN_ENTITLEMENTS`、`GCC_PREFIX_HEADER` 和 `INFOPLIST_FILE` 都指向该提交删除的 `MADStack/` 目录。它们现在指向 `Targets/MADViewer/` 下 viewer 自己的文件，这把构建推进到链接步骤——在那里因属于 Designer target 的七个类而失败。独立 viewer 应当是什么，是一个产品决策；已记录，未打补丁。

两者都在 `BUGS.md` 的*构建接线*之下。

**这删除的是引用，不是库。** 既有约束仍然有效：磁盘上不会删除任何东西，直到替代品能构建每一种组合。

### 2.2 两个真正的构建 —— **自 2026-10-04 起进行中**

zlib/macOS 和 mysqlclient/macOS。已有五行构建完成；这两个还没有。

由用户作为 Compressor 重做的一部分而恢复：新矩阵为每个库构建每个平台，所以这两行随 Phase 4 到来（openssl/macosx slice 已经能构建，因为 mysqlclient 配方的主机工具阶段需要它）。

### 2.3 声明式构建系统 —— **自 2026-10-04 起进行中**

`Compressor/matrix.conf`、`Compressor/build.sh`、每个库的 `manifest.json`，以及一个 XCFramework 作为 Xcode 链接的单一产物。在取得信任之前，作为与现有脚本并存的第三个入口点保留。`manifest.json` 让“这些标志是哪个构建出来的？”成为可回答的问题——今天这个问题只能通过反汇编归档来回答。

由用户作为 Compressor 重做的一部分而恢复；`TASKS.md` §6 载有阶段检查清单。延期交换中值得保留的是：用户的直觉是“这些信息应该存进 plist 之类的东西里”——而这正是 `manifest.json` 所做的事，所以按原文写下的设计已经回答了促成它的顾虑。每个库的 manifest 是**先**建成的：正是它让矩阵的其他每一部分都可被检查，而不只是可被运行。

XCFramework 仍然是 §2.1 第三条的答案。那个发现不会随延期而过期——`PBXFileReference.path` 直接命名一个 iOS slice，所以无论何时重新拾起 macOS 工作，都没有任何搜索路径能修好它。

### 2.4 最后再清理

只有在矩阵构建了每一行**并且**应用能构建且其测试在新产物上通过之后。每项一次提交，在消息中附上矩阵差异作为证据。

---

## Track 3 —— 无头 CLI（工具）

**CLI 不随产品发布。** 用户的决定，2026-10-01：

> *“CLI 不会被发布（至少现在不会，它只是为了让我们理解软件如何工作，以及用于测试）。”*

这敲定了 `MAD_CLI.md` §8.1——它是开发者工具——并随之敲定了几个只因假设要发布才变得困难的问题：不签名、不公证、无安装器，且 `--credentials user:pass` 可以接受明文参数。

**为什么它仍然排在最前。** 它是唯一能在应用不挡路的情况下看到文档的方式。`mad inspect` 已经把容器和存储读作原始 SQLite——没有 Core Data，没有 UI——这正是 `MAD_FORMAT.md` §7 要求第二个平台能够写出的读取器。所以 CLI 不是偏离核心任务的绕路；它是核心任务得到检验的方式。

**Track 2 不构成本轨的门槛。** `CLI/build.sh` 为 **iOS Simulator** 构建 `mad`，并通过 `xcrun simctl spawn` 在 Mac 上运行它，原样链接现有框架和现有 iOS 静态库。macOS slice 只在需要*原生* macOS 二进制时才需要，而阻碍那一点的是 Track 5.1。

**这一轨比读起来要小。** `CLI/Source` 有 1011 行，整个未实现的面只有两个条目，都可以 grep `"not implemented yet"` 找到：

- `schema` —— `MADCLIUnimplemented.m` 的全部（15 行）。
- `refresh --rows N` —— 在 `MADCLIRefresh.m:17` 处被拒绝。

`inspect`（115 行）、`query`（36 行）、`refresh`（54 行）和 `export`（66 行）是真正的实现，会打开文档并完成工作。所以下面的 §3.2 既是对现有内容的描述，也是对要构建内容的规格说明。

### 3.1 Phase 1 —— 证明路径 —— **2026-10-01 完成**

**四次运行全部通过，两个样例都通过，第一次就过，未改一行代码。** 无头路径此前从未端到端演练过；它是可行的。

| # | 运行 | London | Music |
|---|---|---|---|
| 1 | `mad inspect` | 6 个成员，41 个 section，25 个元素 | 6 个成员，29 个 section，10 个元素 |
| 2 | `mad query` | 6 个表的连接，`WHERE "Customer0"."City" = 'London'` | 4 个表的连接 |
| 3 | `mad refresh` | **76 行，0.02 秒** | **3503 行，0.10 秒** |
| 4 | `mad export --out` | 5 页，43 KB | 77 页，354 KB |

London 的 PDF 检查的是内容，而不只是它是否存在：它带有真实的 chinook 数据——*“Sales Report”*、客户 Phil Hughes、发票 #335、R.E.M. 的 *The Wrong Child*，价格 $0.99。文本谓词是这件事有意义的原因：第 2 次运行输出 `WHERE "Customer0"."City" = 'London'`，第 3 次运行是第一次证明无头刷新能正确执行它。字面量引号修复（`0c187aca3`）的两半都得到了实时确认。

**一次虚惊，值得知道。** `file` 报告 Music 的导出为 8 页，而 `mad` 说是 77 页。`mad` 是对的——PDF 有 77 个 `/Type /Page` 对象和一个根 `/Count 77`；`file` 从 13 个嵌套的页面树节点中取了一个节点的 `/Count`。不要用 `file` 来检查这些文件的页数。

对两个随发布样例的四次运行。每一次都是验收测试；没有东西坏掉。按原文记录如下：

| # | 运行 | 它证明了什么 |
|---|---|---|
| 1 | 在 London 和 Music 上运行 `mad inspect` | 容器和存储无需 Core Data 即可读取 |
| 2 | 对两者运行 `mad query` | 查询模型可无头加载 |
| 3 | **先 London**、再 Music 运行 `mad refresh` | 数据路径，端到端 |
| 4 | `mad export --out` | 从无头运行产出的 PDF |

第 3 次运行中 London 先行，因为它的驱动是 **Sqlite 3**，作用于本地 `chinook.sqlite3`：路径中没有服务器，所以失败是代码的而非网络的。Music 是对照。

前置条件：`xcrun simctl spawn booted` 需要一个已启动的模拟器。`CLI/build/mad` 已经构建好了。

**不要先做 §3.4。** 把 `MADOperationRefresh` 移入 `MAD` 是一件有可用变通方案的整理工作——`CLI/build.sh` 的 `REFRESH_SOURCES` 跨越 target 边界，今天就能编译它。在运行结果说明代码想要什么形态之前就重组，是错误的顺序。

### 3.2 Phase 2 —— 关闭表面 —— **2026-10-01 完成**

`mad schema`，以及 `refresh --rows N`。两者都已落地，且都在样例上验证过。

**`schema`** 是唯一一个桩动词（`MADCLIUnimplemented.m` 里没有别的，而那个文件现已删除）。它从存储自身的 `Rptq` 实体中读取创建时存入的架构快照——`RptqDocument` → `RptqDatabase` → `RptqDatabaseSchemaTable` → `RptqDatabaseSchemaField`——并打印驱动、按名称排序的表，以及每张表的字段及其显示类型和 `pk` 标记。它不需要凭据也不需要数据库，因为它不是实时读取。

```
London.mad
  schema 1   Sqlite 3
  tables     11
    Album (3 fields)
      AlbumId  Integer  pk
      Title  String
      ArtistId  Integer
    …
```

**`--rows N`** 限制的是查询而不是抓取：它在刷新运行之前设置 `MADQueryFull.limitResults`，所以 SQL 带上真正的 `LIMIT N`，而不是拉取每一行再丢弃多余的。`refresh --rows 7` 返回 7 行；不带标志返回完整的 76 行（London）/ 3503 行（Music）。上限就是 SQL 限制，所以之后缓存的 `.maddb` 持有 N 行——刷新替换缓存，而不是在旁边预览。

### 3.3 Phase 3 —— 让 CLI 成为文档的规格 —— **2026-10-01 完成**

`mad inspect` 现在报告伴随文件，按扩展名分组，带每类描述，并在 `--verbose` 下列出每个文件：

```
  cache       7308922102201200 (6 files, 402.7 KB)
    madac 4 files  320.0 KB  rendered-page cache
    maddb 1 file   80.0 KB   row data
    mdcache 1 file   2.7 KB   virtual-table index
```

目录用应用自己的规则定位——`MADURLFactory
newURLCacheFilesDirectoryForFilename:`——而不是重新推导，所以 CLI 不会偏离应用关于缓存位置的认知。子目录被跳过（手动备份不构成占用的一部分），未刷新的文档报告 `cache none`。

这是伴随文件第一次被*报告*而不是手工测量，它立刻让 Track 4.1 变得具体：Music 的缓存是 15.0 MB，其中每一个字节都是 `.madac`；London 的是 402.7 KB，79% 是 `.madac`。两个渲染缓存布局标识符（`1138777405839048766` 和 Music 自己的 `14013296909766`）现在并排可见，而不是从目录列表中推断出来。

本轨的成功标准——**`mad inspect` 能仅凭一个文件、不靠应用，陈述 `MAD_FORMAT.md` 声称的一切**——对于容器、存储、成员、WAL/SHM 和伴随文件已经达成。`inspect` 尚未陈述的一项主张是存储的*架构*，那是 `schema` 的职责，不是 `inspect` 的；两者合起来覆盖了整个文档。

### 3.4 把 `MADOperationRefresh` 移入 `MAD` 框架 —— **与 §5.1 耦合**

`MADDesigner/Source/MADOperationRefresh.m`——131 行，零 UIKit 符号，只导入 `MADAPI`、`MADFoundation` 和 `MAD`。它已经是 CLI 的刷新动词；它只是位于错误的 target 中。两个 `Reload` 操作留在应用里。

变通方案在 `CLI/build.sh` 中可见：它的 `REFRESH_SOURCES` 列表跨越 target 边界，直接从 `MADDesigner/Source` 编译 `MADOperationRefresh.m` 和两个 `MADOperationRefreshInitial*` 文件。所以 CLI 今天能用。

**为什么这不是单纯的整理。** 刷新*链*必须触及具体驱动：`MADOperationRefreshInitialize` 导入 `MADDatabase+Constructor`，而那个文件（及其兄弟 `MADDatabaseConnection+Constructor`）导入全部三个驱动——`<MADSqlite3/MADDatabaseSqlite3.h>`、`<MADMySQL/MADDatabaseMySQL.h>`、`<MADTdsClient/MADDatabaseSQLServer.h>`。这就是为什么刷新被留在链接一切的应用 target 中。这也解释了为什么它已有一半解决：`Constructor` 文件住在 `MAD` 里，而 `MAD.framework` 已经链接 `MADSqlite3`、`MADMySQL` 和 `MADTdsClient`，所以机械地移动即可编译。但那会重新确认驱动与 `MAD` 之间已经形成的循环——驱动继承 `MADDatabase`（它们依赖 `MAD`），而 `MAD` 的 `Constructor` 又导入它们。把刷新操作移上这一堆，会让 §5.1 想要切开的接缝*更难*切，而不是更容易。

所以在 §5.1 的驱动注册表存在之前**不要**移动这些文件；到那时，移动和注册表是同一项改动，刷新通过注册表构造驱动，而不是通过硬导入它们的 `Constructor`。

---

## Track 4 —— `.mad` 文档（核心任务）

`MAD_FORMAT.md` 就是定义：格式今天是什么，从两个随发布样例测得；它的风险；以及规范性目标。本轨是该文档所蕴含的工作。

### 4.1 伴随文件 —— **现已完整描述**

`MAD_FORMAT.md` §5 现在覆盖全部三种伴随类型——`.maddb`（行）、`.mdcache`（虚拟表架构 plist）和 `.madac`（渲染页缓存，它本身是一个 SQLite 数据库）——外加作为整体的缓存目录：它的 `dataTableIdHash` 命名、测得的尺寸，以及它为何被有意做大的设计理由（§5.1）。两个曾是空白的地方现在有了答案，都是靠读代码而非猜测：

- **`.mdcache` 架构**是序列化的结果表元数据（`MADDataTableFast
  -copyPlist` / `-loadWithPlist:`）：`name`、`columnKeys`、`columns`（每个是一个 `MADDataColumn` plist）、`rowCounter`、`sortDescriptors`、`bulkInsertLoop`。记录在 §5.3。
- **渲染缓存以文件名为键，而不是内容。** `MADReportFormatter -layoutIdentifier` 返回 `_filename.hash`（或覆盖值），而 `MADArrayCaching` 只要其表存在就复用该 SQLite 文件，路径中任何地方都没有版本或内容哈希。所以在同一文件名下编辑文档不会使其 `.madac` 页面失效。记录在 §5.3 和 §8.4，作为一个已确认的机制加上一个仍未解决的产品决策（“它应该吗？”），而不是一个可被无提示修复的缺陷——用户已经说过缓存是承重的，且不是当务之急。

这就是伴随文件的“理解它是什么，并定义它将会是什么”的全部。文档本身剩下的，是 §4.2 的决策，然后是 §4.3 的 v1。

### 4.2 决策

`MAD_FORMAT.md` §8。最大的那个现已决定；其余仍开放。

- **存储是否继续用 Core Data？——2026-10-01 决定：不。** 存储迁移到我们自己的可移植 SQLite 文件格式。用用户的话说，方法是：继续原样使用自动生成的 `Rptq` 头（停止重新生成，直接使用），并自己为 `Rptq` 表编写插入/更新/读取代码。这是一次大规模迁移——它必须转换现有报表，因此需要自己的计划，并且自成一轨，不属于 v1。记录在 `TASKS.md` §9。
- **字节完全一致的 `.mad` —— 2026-10-16 完成。** 用户的要求（“Linux 和 iOS 应当产出完全相同的 MAD 文件”）已经满足并经测量：`mad write --reproducible` 在两个平台上为 London 夹具写出 16,261 字节，sha256 为 `09815b24…`（在 SQL 录入 Phase A 的存储迁移改变所写字节之前为 16,243 / `22dd3123…`），而 `Linux/Tests/MADArchiveManagerTests.m` 把它钉住。该模式是可选的（`MADArchiveManager.reproducible`），普通保存保留文件系统的元数据，它暴露的两个仅 Linux 的缺陷也已修复。留待后续一轮的是一个在 Linux 上*创建存储*的写入器——今天的比较覆盖的是容器。
- 缩略图应该在文档里，还是像其他一切那样可重新生成？——开放，次要。
- `.mad` 是否应可选地携带行缓存，使文档能在别处离线打开？——开放；以后可以添加新变体而不破坏 v0/v1。
- 内容变化是否应使渲染缓存失效？——机制现在已知（§5.3）；当需要时修复很便宜，而目前还不需要。

### 4.3 `.mad` v1

压缩流之外的一个固定头部（`"MADFILE\0"` + 版本 + 标志）加上一个检查点化的存储，按 `MAD_FORMAT.md` §7。按设计向后兼容：魔数的缺席意味着旧式 v0，所以两个随发布样例都能继续打开。它还能自我回本——Music 样例三分之一的字节花在 WAL 上。

**第 1 部分 —— 头部 —— 2026-10-01 完成。** `MADConstants` 承载魔数、头部长度和版本；`MADArchiveManager` 在保存时写入 16 字节头部（归档到临时文件，然后组合头部 + 主体）并在打开时剥离（检测 `MADFILE\0`，从无头部的副本中提取）。两个随发布样例保持 v0 并能原样打开。通过一个往返单元测试以及通过 CLI 容器和应用的打开路径读取 v1 副本得以验证。

**第 2 部分 —— 检查点 —— 2026-10-01 完成。** `MADDatabaseSqlite3
+checkpointStoreAtURL:` 在归档前把存储的 WAL 折入 `analyitics`（`PRAGMA wal_checkpoint(TRUNCATE)`，返回是否完成）。`MADocument
-writeContents:` 在存储保存之后调用它，并设置 `MADArchiveManager.checkpointed`，后者设置标志位 0。如果检查点无法完成（Core Data 仍持有存储），归档会带上 WAL，标志记录 `0`。检查点状态存在于头部标志中，而不是 `meta.plist` 中，因为 meta plist 在检查点运行之前就已写入——标志是权威记录，且无需解压即可读取。

由 `MADSqlite3Tests testCheckpointStoreAtURLFoldsTheWal`（一次 WAL 模式写入被折入，WAL 重置为零字节）和 `MADDocumentTests testArchiveHeaderRecordsTheCheckpointFlag` 钉住。

**v1 独立于 §4.2。** 头部和检查点与存储迁移正交：迁移稍后移除 H3，而 v1 是按内容识别加一个检查点，两者都不关心存储是 Core Data 还是我们自己的 SQLite。所以 v1 现在推进，而迁移是它自己的一轨（`TASKS.md` §9）。

---

## Track 5 —— 三个接缝

项目概要列出了开发者应该能够在不修改核心的情况下扩展的三样东西：**数据库类型**、**文档元素类型**和**导出格式**。今天这三者都没有接缝，而本文件对它们也都没有计划。

### 5.1 数据库类型

今天核心 `MAD` 框架恰好在三个文件中导入具体驱动：

- `MAD/Source/MADDatabaseConnection+Constructor.m` —— MySQL、SQL Server
- `MAD/Source/MADDatabase+Constructor.m` —— MySQL、SQL Server
- `MAD/Source/MADPrintPageElementBarcode.m` —— MADBarcodes

驱动注册表把“添加一个驱动”从*编辑核心*变成*添加一个框架*。它也是原生 macOS 构建所等待的东西：这些导入中有三条通向 UIKit，这就是今天没有任何 target 为 macOS 编译的原因。

### 5.2 导出格式

**2026-10-16 落地，按路线图自己的顺序：先接缝，再文本，再 JSON 和 CSV。** `<MADReportExporting>` + `MADReportExporterRegistry` 是驱动注册表的形态（§5.1）——一种格式在 `+load` 中注册自己，CLI 按名称查找它；用法文本列出构建链接了什么。`text`、`csv` 和 `json` 是纯 Foundation，在两个平台上都运行；`mad export --format json` 是 `MAD_DATA_OBJECT.md` §6 的数据契约，`MAD_CLI.md` §8.3 现在回答了形态问题，而三种格式为 London 夹具在 **Apple 和 Linux 上写出字节完全一致的输出**（摘要经比较，见 `Linux/README.md` 的 CLI 一节），并且 `json-report`——同一架构加上渲染后的报表作为额外成员——随它们一起落地，由页面渲染器自己的遍历构建（现在与它的绘制分离），所以它不会偏离 PDF 所显示的内容。**然后是 HTML 和渲染那一半的迁移（2026-10-16）。** `MADReportFormatter` 接受 `id <MADDocumentRenderProtocol>`，`MADHeadlessDocument` 遵循它，所以两个平台上只有一个格式化器；页面遍历从 `MADPrintPageRenderer` 移入 `MADReportPageBuilder`，渲染那一半的读取移入 `MADDocumentRenderDataSource`，所以只有一次遍历和一组读取。`json-report` 在两个平台上运行。随它落地的还有两种 HTML 格式，由用户选择：`html` 是摹本（每页一个 CSS page box，每个元素绝对定位在其被遍历到的 frame 处），`html-flow` 是可重排的阅读视图（section 作为表）。`pdf` 也在接缝上——`MADReportExporterPDF`，主体是 Apple 的，处处注册并说明为何在 Apple 之外不可用——而 CLI 没有本地分支；其输出字节完全一致（43,177 字节 / 5 页，`sha256 3eb2f1c4…`，前后相同）。剩下的是 Linux PDF 写入器本身（`MAD_LINUX.md` §10.2 有形态）以及 GNUstep 格式化器携带的货币格式差异（`BUGS.md`）。各格式携带的列是查询自己的列，按 SELECT 列表现在定义的别名顺序（`BUGS.md`）。

`mad export` 曾经只有一个分支：PDF，藏在 `MADCLIExport.m` 中的一次字符串比较之后。`MAD_CLI.md` §5.3 要求一个 `<MADReportExporting>` 协议，使 `--format json` 成为一个*新类*而不是新分支——与 5.1 的驱动注册表同一形态，这就是为什么两者属于同一轨。

用户的表述，2026-10-01：

> *“如果你想，你也可以创建新的导出格式……把那个放进任务里……导出为文本或电子邮件或 markdown 或上百种东西里的任何一种。那是应用的一部分，本来就应该是可扩展的。”*

**当这一项被拾起时，先构建文本导出器。** 不是因为需要文本，而是因为它是接缝真实存在的最便宜证明：纯 Foundation，无 Core Graphics，并且它让报表的*内容*在 CLI 中可见而不需要 PDF 查看器——这正是 Track 3.1 本来就想要的。如果接缝是对的，文本是一个下午的事；如果不对，文本正是它暴露的地方。

**但不要在 Track 3.1 之前。** 一个因为刷新坏了而什么都不渲染的导出器，对接缝什么也证明不了。

### 5.3 文档元素类型

第三个接缝，也是本文件只字未提的那个。`RptqDocumentElement` 及其子类是扩展点——概要列出了静态标签、数据标签、聚合和条码标签作为这一族——但没有任何东西描述第三方如何添加一个。在值得写代码之前，值得先做一次设计。

---

## 用户必须做出的决策

这些是阻塞工作，而不是工作本身。

| 决策 | 位置 | 为何阻塞 |
|---|---|---|
| 数据库密码归哪个系统所有——应用自己的钥匙串项，还是平台的 AutoFill / `kSecClassInternetPassword` 路径？ | `TASKS.md` §1 | 双重提示是症状。`TASKS.md` §4 阻塞在它后面。 |
| `.mad` 存储是否继续用 Core Data？ | `MAD_FORMAT.md` §8.1 | **2026-10-01 决定：不**——我们自己的可移植 SQLite 格式，原样使用 `Rptq` 头并手写 CRUD。其自身的迁移轨，`TASKS.md` §9。 |
| 文档变化时渲染缓存是否失效？ | `MAD_FORMAT.md` §5.3, §8.4 | 机制现在已知（以文件名为键，无内容哈希——所以编辑时会提供过期页面）。开放的部分是它*是否应该*失效。 |
| 缩略图和行缓存应该放在文档里吗？ | `MAD_FORMAT.md` §8.2–8.3 | 决定 `.mad` 的每个成员是否都是权威的。 |
| `.mad` v1 值得做吗？ | `MAD_FORMAT.md` §7 | 它是向后兼容的，但它是一个格式决策。 |
| JSON 导出的形态是什么？ | `MAD_CLI.md` §8.3 | **2026-10-16 决定：两者都要，报表那一半作为独立格式**——`json` 是数据契约（架构 + 行），`json-report` 加上渲染报表的 section。SELECT 列表的顺序是列别名，已排序，所以 SQL/缓存/导出在两个平台上一致。 |
| 用哪个渲染器，以什么顺序？ | `MAD_LINUX.md` §10.2 | **2026-10-16 决定：先 HTML/SVG，最后 PDF**——不做 Linux PDF 渲染器，不做 macOS 侧工作进程；HTML 这一步也是渲染那一半迁往 Linux 的地方。 |
| 字节完全一致的 `.mad` 是否是写入器模式，何时？ | `BUGS.md`（`.mad` 字节一致条目） | **2026-10-16 决定：在 `-archive:` 上提供一个可选的可复现模式（类似 `-checkpointed:`），在导出格式之后落地**——固定 mtime、固定 uid/gid、排序的成员遍历；普通保存保留今天的元数据。 |

已划掉：*“`mad` 会随产品发布吗，还是开发者工具？”*——2026-10-01 敲定；它是开发者工具，暂时。

---

## 顺序

1. **Track 3.1** —— 四次运行。下一个，不应有任何东西先于它。
2. **Track 3.2–3.3** —— 关闭表面，然后让 `inspect` 描述整个文档。
3. **Track 4** —— 伴随文件、决策，然后 v1。这是核心任务；一旦 CLI 能展示文档，它就正式启动。
4. **Track 5.2** —— 导出接缝，先文本，因为它便宜且能让报表可见。
5. **Track 5.1** —— 驱动注册表，它也是 macOS 的前提条件。
6. **Track 5.3** —— 文档元素类型；需要先做一次设计。
7. **Track 2.2–2.4** —— 已延期；只在需要原生 macOS 构建时恢复，并先构建 `manifest.json`。
8. **清理** —— `LIBRARIES.md` §7.4，只有在满足其门槛之后。

## 常设约束

- 在替代品能构建每一种组合之前，不会删除 `Compressor/library` 中的任何东西。
- `/Users/michael/Desktop/Compressor` 处的第二个 `Compressor` 是一个独立仓库；未经询问不要删除或对账它。
- `TEST-DB-INFO.md` 和 `MADDesigner/run.log` 保持不受跟踪。
- 本代码库有意避免 `+[NSString stringWithFormat:]`——移动设备上的紧密循环。改用 `initWithFormat:` / `appendFormat:` 的代码风格。（该约束关乎热路径，代码库并非字面上完全不出现该调用：它出现在一次性路径中，包括 CLI。循环中的新代码不应添加。）
- 行为安全的重构和清理无需请求即受欢迎；`MTPaper` 纸张类是已知的例子。“行为安全”意味着可由测试套件证明。
- 有意未使用的代码在声明处用正确的 clang 属性标记（`__attribute__((unused))`、`__unused`、`NS_UNAVAILABLE`）。
