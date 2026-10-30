---
layout: default
lang: zh-CN
---

# TASKS.md

_MAD Designer_ 的工程任务队列。

> **代理：维护此文件，不要据此行事。** 随工作推进添加、更新状态并链接任务，但不要仅仅因为某个条目列在这里就着手处理它。只有当用户按名称或编号要求某项任务时，才拾取该项任务。

## 本文件与其他跟踪文件的关系

有三个文件跟踪工作，它们刻意是不同的东西：

* `BUGS.md` —— **缺陷登记册**。每一项已确认的错误行为，以及钉住它的测试。是证据，不是队列。
* `TODO.md` —— 用户的**产品愿望清单**。手工写下的功能与想法。
* `TASKS.md` —— 本文件，**工程队列**。正在积极处理的内容，按顺序排列，并带有足够冷启动的上下文。条目链接到 `BUGS.md`，而不是重述它。

状态键：**待处理** · **进行中** · **已阻塞** · **已完成**。

---

## 1. 钥匙串与凭据流程 —— 最高优先级

**状态：** 待处理 —— 用户已要求回到这项任务。

用户的原话：*“这个钥匙串流程对做对这件事非常重要，否则没人会用这个软件。”* 保存数据库密码是让文档可用的关键，所以一段坏掉的提示序列会阻塞整个产品。

**今天出了什么问题。** 创建文档时，应用会呈现**两个相互竞争的密码提示**：

1. 应用自己的 `MADOperationPromptPolarQuestion` 警告框 —— “Save to Keychain”，Yes/No。
2. **系统**“密码”应用的弹出面板 —— “Update Password?” 带 *Not Now* / *Update* —— 它出现在应用警告框的**上方**。

用户在系统面板上点了 *Update*，然后在应用的警告框上点了 *Yes*，直到这时文档才被创建。除此之外，保存和删除密码都是坏的。

**去哪里看。**
* `MADFoundation/Source/MADKeyChain.m` —— `SecItem*` 封装。注意它最近刚被修复：`-deleteSavedPasswordForKey:error:` 曾吞掉失败，并解引用一个 `NULL` 的错误输出参数。删除失败现在会浮现出来，这可能是用户所见怪异行为的一部分。
* `MADDesigner/Source/` —— `MADOperationKeyChainPut`、`MADOperationKeyChainGet`、`MADOperationKeyChainDeletePassword`、`MADOperationGetCredentials`，以及门控它们的 `MADOperationConditionPolarQuestionAffirmative` 条件。

**需要与用户确定的设计问题。** 重复提示几乎可以肯定是因为应用写入自己的钥匙串条目，*同时* iOS 又为同一主机提供它自己的凭据存储。需要确定由哪个系统拥有密码：

* 使用平台的 AutoFill/`kSecClassInternetPassword` 路径，并删除应用自己的提示，或者
* 保留应用的私有钥匙串条目，并抑制系统面板。

不要猜测选哪个 —— 这是一个产品决策。

**证据：** `MADDesigner/run.log`，第 380–570 行附近的 `MADOperationKeyChainPut` / `KeyChainGet` / `KeyChainDeletePassword` / `GetCredentials` 序列。

**在这里还值得检查：** 下面这行日志

```
MADOperationCreateDocument Keychain keys generated.
  MainKey (connStr):"(TDS)[localhost:localhost:1433]AdventureWorksLT2022"
```

在一个键里把主机名写了**两次**。确认连接字符串格式化器是否发出了重复的主机，因为每一个钥匙串键都派生自那个字符串 —— 键错了就意味着一个再也找不到的已保存密码。相关：该访问器的拼写是 `-[MADDatabase credentalsWithConnection:]`。

**完成标准：** 只有一个提示，保存可用，删除可用，并且键在保存与查找之间完全一致地往返。覆盖这一点的测试见任务 4。

---

## 2. 一个同时报告成功与失败的 SQL Server 连接

**状态：** 报告的一半已修复；实时连接本身仍未验证。

**问题所在。** SQL Server 驱动吞掉了连接点之后的每一次失败。`MADDatabaseSQLServer -connectWithConnection:credentals:connectionError:` 和 `-connect:andPassword:error:` 构造了一个 `NSError`，却从未把它写入调用者的输出参数，而 `-executeQuery:withDataTable:andError:` 两者都忽略了。于是 `MADOperationDatabaseTestConnection` 看到的是 `success = NO` 且 `error = nil`，并记录

```
MADOperation <MADOperationDatabaseTestConnection> finish with 0 direct errors.
MADOperation <MADOperationDatabaseTestConnection> finishing with no errors.
...
MADOperationConditionResult: created 'failed' (not satisfied) for condition name:
    "MADOperationConditionTestConnectionSuccess"
```

—— 操作报告没有错误，而条件消费了它并报告不满足，这就是日志里的那处不一致。

**现在：** 这三个方法把真实的错误写入调用者的 `NSError **`（三者都容忍 NULL），因此 `MADOperationDatabaseTestConnection` 会记录失败及其消息，而 `MADOperationConditionTestConnectionSuccess` —— 它通过 `MADOperationTestResults` 读取 `isSuccess` / `error` —— 看到的与操作看到的一致。由 `MADTdsClient` 的离线和实时套件覆盖；见 `BUGS.md` 中 MADTdsClient 关于 `-connectWithConnection:credentals:connectionError:`、`-connect:andPassword:error:` 和 `-executeQuery:withDataTable:andError:` 的条目。

**仍未解决：** 连接对开发服务器是否*成功*，不是单元测试能回答的 —— 没有服务器时它们会跳过。那是一次手工运行，而且如果失败，它现在会产生一条可以据以追查的真实错误消息。同一份日志中看到的 `[localhost:localhost:1433]` 键怪异现象是另一个问题，属于任务 1。

---

## 3. 需要在运行中的应用里由人确认的两处修复

**状态：** 待处理。

两者都已提交并有单元测试；只有实时运行才能证明它们是对的。

* [ ] **钥匙串** —— 打开并创建一个文档，检查没有出现多余的错误警告框。（与任务 1 重叠。）
* [ ] **文件大小** —— 文档信息界面现在应显示 `1.5 MB`，而不是 `1 MB`。`MTMath` 的换算使用了整数除法，把小数部分截断了（`BUGS.md`，“已修复”部分 → MADCocoaExtensions 批次）。

---

## 4. 钥匙串流程的单元测试与 UI 测试覆盖

**状态：** 待处理 —— 取决于任务 1 中的设计决策。

钥匙串是整个流程中**完全没有单元测试**的那一部分：现有的 `MADKeyChain` 覆盖止于封装层，而 `BUGS.md` 把删除缺陷记录为*“inspection; not covered by a test — keychain calls”*。对于整个产品所依赖的这条路径来说，这还不够好。

需要：
* 对 `MADKeyChain` 封装的单元测试覆盖：添加 / 读取 / 更新 / 删除、未找到路径，以及 `NULL` 错误输出参数。一个测试钥匙串服务（每次运行使用唯一的服务字符串，在 teardown 中删除）让这些测试不碰开发者的真实凭据。
* 对凭据操作的单元测试覆盖 —— `MADOperationKeyChainPut` / `Get` / `DeletePassword`、`MADOperationGetCredentials` —— 以及针对 `MADOperationConditionPolarQuestionAffirmative` 的覆盖。
* 针对提示序列本身的 **UI 测试**，这样“出现两个警告框”会被捕获，而不是靠手工发现。应用已经有 `MADDesignerUITests` target。
* 一个往返测试：保存密码，并**通过同一个连接字符串键**读回 —— 这正是能捕获任务 1 中 `[localhost:localhost:1433]` 怪异现象的测试。

---

## 5. 对 BUGS.md 剩余发现的调用者分析

**状态：** 已完成 —— 每个区域都已分析，每个决策都记录在 `BUGS.md` 中。

第二轮覆盖了 MADFoundation 和 MADCocoaExtensions 之后剩下的 52 项发现。每一项在被触碰之前都做了调用者分析，因为有些“已确认”的行为是承重的 —— `CGRectAdjustForScale` 这个案例就是常设的例子，它的两个调用者把 `zoomScale` 的定义域各自分走了一半。

结果分成三类：

* **43 项已修复**，每一项都翻转或增加了钉住它的测试。
* **6 项已记录并刻意保持原样**，并在代码内注释中点名依赖该行为的调用者：`MADFileManager` 自我替换的元数据初始化器、`MADDatabaseSQLServer -runSQL:onDataTable:fieldKeys:process:` 关闭传给它的进程，以及 `-sqlSampleDataForField:andTable:` 绕过基类的子句构建器。
* **3 项需要用户决断**，三项都已决定：十进制 MB 的文件大小、年/月/周计时器的 fallthrough，以及现代日期/时间值 —— 它们在当时已声明类型但未被取值。这些值于 2026-10-01 取值（`ROADMAP.md` 的 Track 1.1），而取值过程在同一记录中又暴露了第二个缺陷：经典的 `DATETIME` 分支一直在多加一个月，而 freetds 已经加过了。两者都记录在 `BUGS.md` 中；`SYBDATETIME4` 的基准日期算术是新近开放的。

| 区域 | 未解决发现 |
|---|---|
| `MADTdsClient` | 1 —— `SYBDATETIME4` 从错误的纪元起算天数 |
| MAD Designer（应用） | 0 |
| `MADMySQL` | 4 —— `MysqlUpdate` 的越界删除、`MysqlConnection` 的无句柄事务崩溃、`MysqlInsert` 的 `ULONG_MAX` 行数、`MysqlTruncate` 缺失的工厂守卫 |
| `MADFileManager` | 8 —— 两处真实崩溃（`MADCloudFileCoordinator` 初始化、`MADDirectoryMonitor` 取消）外加 `-setFileCoordinator:` 的 URL/元数据混淆和五个次要记录 |
| `MAD` | 0 |
| `MADExplorer` | 0 |
| `MADAPI` | 0 |

`MADSqlite3` 没有。每个区域都以与第一轮相同的三部分结果收尾：缺陷被修复，承重的行为被记录而非更改，`BUGS.md` 就地更新，写明修复、它的 `Now:` 行以及覆盖它的测试。

**这一告诫中 MySQL 的一半现已关闭。** `MADMySQL/TestDatabase/mysql-test-db.sh` 用固定版本的镜像和一份校验和验证过的标准 `employees` 数据集副本，在 Docker 中构建实时测试服务器，并且 scheme 会为测试动作启动它。`MADMySQL` 套件针对该服务器运行 119 个测试，跳过 0 个（在一台非默认端口的容器上验证过 —— 端口由 scheme 环境携带，因为 `xcodebuild` 不会把 shell 变量转发给测试进程）。`MADTdsClient` 仍带着旧的告诫：它的实时发现是离线验证或通过阅读驱动验证的。

---

## 6. macOS 库构建与声明式构建系统

**状态：** 自 2026-10-04 起进行中（由用户以 Compressor 重构的形式恢复；曾于 2026-10-01 延期）。进度：

- [x] 阶段 0 —— 可移植性小修复：工作区绝对路径、`CLI/build.sh` 的 DerivedData 哈希、MADMySQL 中多余的 `-v`、应用里无效的 `SQLITE_ENABLE_COLUMN_METADATA`。
- [x] 阶段 1 —— 编写了 `matrix.conf` + `build.sh` + `lib/recipes/`，并在九个库各自的基线版本上验证通过（sqlite3 3.49.2、zlib 1.3.1、含 macosx 的 openssl 3.5.0、bzip2 1.0.8、libpng 1.6.47、libarchive 3.7.8、freetds 1.4.26、mysqlclient 8.0.42、zint 2.4.2）。mysqlclient 采用两阶段设计：一次原生 macosx-arm64 构建产出宿主工具与生成文件；各交叉构建以这些为种子，并从原生阶段运行工具。`build.sh --verify --all` 通过。
- [x] 阶段 2 —— 把 Xcode 重新接线到 xcframework 并加入 ensure 阶段。全部八个步骤落地，每个项目一个提交：MADSqlite3（链接 sqlite3.xcframework，sqlite3.c 不再是 target 的源文件，xcconfig 的唯一消费者是 recipe）、MAD（libarchive + bzip2 + zlib 三个 xcframework；错误的系统 libarchive.2.tbd 引用已移除）、MADMySQL（mysqlclient + openssl；硬编码的 Debug/ 搜索路径随这些 arm 一起消失）、MADTds（freetds + openssl）、MADTdsClient（搜索路径清理）、MADBarcodes（libpng + zlib，随后内置的 Zint 树被 zint.xcframework 取代，zint.h 保持 Public）、以及应用（openssl）。每个 target 都新增了一个固定到 ios,simulator 的 Ensure Libraries 阶段。套件：MADSqlite3 77/0、MAD 238/0、MADMySQL 58/0（实时服务器测试已运行并通过）、MADTdsClient 75/0；MADBarcodes 和 MADTds 可构建；应用可为模拟器和设备构建。
- [x] 阶段 3 —— 完整验证。全部十二个套件通过（MADSqlite3 77/0、MAD 238/0、MADMySQL 58/0 实时、MADTdsClient 75/0、MADFoundation 118/0、MADAPI 78/0、MADDataStructures 72/0、MADCocoaExtensions 76/0、MADExplorer 9/0、MADFileManager 31/0；MADBarcodes/MADTds 可构建），应用可为模拟器和设备构建，`--verify --all` 通过，并且**全新克隆模拟通过**：`git archive HEAD` 到新路径，工作区可加载，`Compressor/build.sh --all` 从下载内容引导全部九个库，且 `MAD Designer` 从引导出的产物为设备构建成功。这次模拟抓到两个真实缺陷，均已修复：mysqlclient 的原生阶段需要 openssl 的 macosx 切片，而 ios+simulator 的引导从未构建它（recipe 现在从矩阵行内联构建它），以及按平台重建会丢掉其他平台的切片（finish_library 现在会保留它们，先创建到临时的 xcframework 再替换）。
- [x] 阶段 4 —— 为每个库提供 macOS 切片（矩阵构建全部三个平台；`--verify --all` 覆盖 ios+simulator+macosx）。
- [x] 阶段 5 —— 版本更新，每个提交一个库：zlib 1.3.2、libpng 1.6.59、freetds 1.4.27（75 个测试）、sqlite3 3.53.3（D1 门禁 + 77 个测试；这次升级强制丢弃 --disable-tcl，并改动 vdbe.c/parse.y，以便重新生成过时的已检入 opcodes）、openssl 3.5.9 LTS、mysqlclient 8.4.10 LTS（实时服务器测试在 8.4 客户端上通过；8.4 在树内捆绑 boost 并去掉了 libevent，所以 recipe 的 boost 旗标和 libevent 种子退役）、libarchive 3.8.9、zint 2.16.0（cmake recipe；封装恰好需要那些 ZINT_ 错误码重命名；MADBarcodes 可构建，MAD 238 个测试）。bzip2 保持 1.0.8 —— 仍是最新发布版本。
- [x] 阶段 6 —— 清理完成：十一个旧脚本及其导航器引用，以及全部 1,797 个已跟踪的遗留产物文件（`.a` 二进制、按平台的树、按平台的 include 目录、已跟踪的 sqlite3 amalgamation）。Compressor/AGENTS.md 为新系统重写。清理之后，应用可构建，MADMySQL 的 58 个测试通过。
- [x] 阶段 7 —— 取消跟踪：Compressor/library 下没有任何文件仍被跟踪。全新克隆模拟的重跑就是这一状态的证明（写作时仍在进行中）。

用户早前的话，作为背景：

> *“我们先跳过 2.2 节，那两个真正的构建；我们稍后再为 macOS 构建。我们也会推迟声明式构建系统，尽管我认为它很重要。这些信息应该存在 plist 之类的地方，我不知道。我们需要在某张 TODO 列表里跟踪它们，以前的那些大概没被维护过。”*

**这涵盖什么。**

*   **`ROADMAP.md` §2.2 —— 剩下两个 macOS 构建。** zlib/macOS 和 mysqlclient/macOS。八个库行中已有五个构建完成；这两个没有。`LIBRARIES.md` §3 有矩阵。
*   **`ROADMAP.md` §2.3 —— 声明式构建系统。** `Compressor/matrix.conf`、`Compressor/build.sh`、每个库一个 `manifest.json`，以及把 XCFramework 作为 Xcode 链接的单一产物。`LIBRARIES.md` §7.3 有设计。

**为什么现在延期是安全的。** 两者都不在用户接下来所做的事情的路径上。`mad` CLI 为 **iOS 模拟器**构建，并通过 `xcrun simctl spawn` 在 Mac 上运行，所以它原样链接现有的 iOS 产物 —— CLI 这条线根本不需要 macOS 切片。而*原生* macOS 二进制被 `MADFoundation` 里的 UIKit 导入阻塞（`ROADMAP.md` §4.2），它在构建接线的上游：即使矩阵完美，今天也没有 target 能为 macOS 编译。

**不能丢掉的东西。**

*   用户的“存在 plist 之类的地方”正是 §2.3 中的 `manifest.json`。设计已经回答了引发延期的那份顾虑，所以它应被读作对 §2.3 形态的确认，而不是要求一个新形态。
*   `ROADMAP.md` §2.1 的第三条**不**因此取消。添加 `[sdk=macosx*]` 搜索路径行不通，因为 `PBXFileReference.path` 直接命名一个 iOS 切片，并不是按 SDK 条件化的。只要 macOS 工作恢复，§2.3 的 XCFramework 仍是答案。
*   常设约束仍然有效：在某个替代方案能构建每一种组合之前，`Compressor/library` 里的任何东西都不删除。延期不是清理的许可。

---

## 7. `mad` CLI —— 无头路径

**状态：** 阶段 1–3 于 2026-10-01 完成；§3.4 的收尾工作于 2026-10-16 随驱动注册表落地（`e0741a187`、`61991e85f`）。Linux 运行时镜像及其可重复的 CLI 检查于 2026-10-17 落地（`Linux/Dockerfile` 的 `runtime` 阶段、`Linux/verify-cli.sh`、`./Linux/build.sh --runtime|--verify`；`Linux/README.md`）。没有 CI，也没有发布 —— 这是用户当天的决定：Linux 移植是概念验证与回归测试装置，不是发布。见 `ROADMAP.md` Track 3。

**CLI 不随产品发布。** 用户的决定，2026-10-01：*“CLI 不会被发布（至少现在不会，它只是为了让我们理解软件如何工作，以及用于测试）。”* 它是一个开发者工具。这使签名、公证和安装程序都退出了范围，也意味着 `--credentials user:pass` 可以接受明文参数。

**为什么它是下一件事。** 它是把应用放到一边去读取文档的唯一方式。`mad inspect` 把容器和存储当作原始 SQLite 来读 —— 没有 Core Data，没有 UI —— 这正是 `MAD_FORMAT.md` §7 要求第二个平台能够写出的那种读取器。

**阶段 1 —— 四次运行 —— 于 2026-10-01 完成，未改动代码。** 四次运行在两个样本上都一次通过。`mad refresh` 得到 **76 行（London）** 和 **3503 行（Music）**，而 `mad export` 写出一份 5 页和一份 77 页的 PDF，其内容被读回并检查过。在这之前，无头路径从未被端到端地跑过。

| # | 运行 | 证明了什么 |
|---|---|---|
| 1 | 对 London 和 Music 执行 `mad inspect` | 容器和存储在没有 Core Data 的情况下可读 |
| 2 | 对两者执行 `mad query` | 查询模型可在无头模式下加载 |
| 3 | 对 London 执行 `mad refresh`，然后对 Music | 数据路径，端到端 |
| 4 | `mad export --out` | 从无头运行产出一份 PDF |

第 3 次运行中 London 先走：它的驱动是 **Sqlite 3**，走本地 `chinook.sqlite3`，所以路径里没有服务器，失败就会是代码的失败而不是网络的失败。

**过程中发现：** 一次刷新只重写它需要的缓存文件，并不清空缓存目录，所以 `{0, 0}` 的渲染缓存条目在一次重建了其他一切的刷新后仍然存在。这究竟是测量缓存正常工作还是陈旧内容，仍未解决 —— 作为证据记录在 `MAD_FORMAT.md` §5.3 和 §8.4，未做结论。

用 `CLI/build.sh --run <command> <document.mad>` 运行；它需要一台已启动的模拟器，因为它通过 `xcrun simctl spawn booted` 运行工具。

**阶段 2 —— 表面 —— 于 2026-10-01 完成。** `mad schema` 落地（最后一个占位动词；`MADCLIUnimplemented.m` 已删除），它打印存储的快照：驱动、按名称排序的表、带类型和 `pk` 标记的字段，不需要凭据。`refresh --rows N` 落地，用真正的 SQL `LIMIT` 给查询加盖上限，而不是取回全部再丢弃：`--rows 7` 返回 7 行，不带旗标返回完整集合。之后的缓存里保存的是加上限的行 —— 刷新替换缓存，不会在旁边预览。

**阶段 3 —— `inspect` 报告伴随文件 —— 于 2026-10-01 完成。** `inspect` 现在按扩展名分组列出缓存目录的文件（`.maddb` 行数据、`.mdcache` 索引、`.madac` 渲染缓存）及其大小，`--verbose` 下逐文件列出。该目录用应用自己的 `MADURLFactory` 规则查找，所以不会漂移。Music 的缓存显示 15.0 MB，且完全是 `.madac`；London 的是 402.7 KB，其中 79% 是 `.madac`。两个渲染缓存布局标识符现在并排可见 —— `MAD_FORMAT.md` §5.3 中 `{0, 0}` 对 `{612, 792}` 的问题可以上报，而不必手工测量。

**于 2026-10-16 随驱动注册表完成。** `MADOperationRefresh`、`MADOperationRefreshInitialize` 和 `MADOperationRefreshInitalizeMainDataTable` 从应用 target 移入 `MAD`（`e0741a187`），与 `MADDatabaseDriverRegistry` 是同一次改动：构造函数按 `MADDatabaseType` 查找驱动（`61991e85f`），而不是导入 MySQL 和 TDS，所以刷新链不再重复断言这个循环依赖。`CLI/build.sh` 的 `REFRESH_SOURCES` 已消失；CLI 通过 `-framework MAD` 取得这条链。

---

## 8. 导出格式 —— 第三个可扩展接缝

**状态：** 2026-10-16 完成，两部分都已落地 —— 接缝与 Foundation 格式（`2c0e6df6c`、`c97ded85c`、`55e386700`），以及字节一致的 `.mad` 写入器（`mad write`、可复现模式、跨平台比较）。本节剩下的唯一一块是 Linux 写入器，它创建*存储*而不是重新归档一份：比较今天只覆盖容器。在写代码之前它需要用户的两个决定 —— **JSON 导出的形状**（`MAD_CLI.md` §8.3、`MAD_LINUX.md` §10.1）和**渲染器的分阶段**（§10.2，HTML/SVG 先于 PDF）—— 再加上这项工作提出的另外两个：`json-report` 如何抵达渲染后的报表，以及 `pdf` 现在是否并入接缝。四个都以带建议的选项形式提出，并于 2026-10-16 得到答复：两种 JSON 形状都做，报表那一半作为它自己的格式（`json` + `json-report`）；SELECT 列表的顺序被定义为列别名；HTML/SVG 其次，PDF 最后；`pdf` 在 HTML 这一步之前仍留在 CLI 的臂上；以及针对字节一致性工作，在格式之后落地一个 opt-in 的可复现模式到 `-archive:` 上。

**已落地内容**（`ROADMAP.md` §5.2、`MAD_LINUX.md` §9 阶段 E）：驱动注册表形状的 `<MADReportExporting>` 和 `MADReportExporterRegistry`；`MADReportExportSource` 和 `MADReportExportWriter` 作为那一个读和那一个写；`text`、`csv`、`json`（两个平台，输出在两边字节一致 —— 摘要见 `Linux/README.md`）和 `json-report`（Apple；由页面渲染器的遍历构建，现在已与它的绘制分离）。
**此后于 2026-10-16 落地（HTML 这一步）：** 渲染那一半迁移到 Linux —— 一个格式化器（`MADReportFormatter`，基于 `MADDocumentRenderProtocol`）、一次页面遍历（`MADReportPageBuilder`）、一组渲染读取（`MADDocumentRenderDataSource`）—— 所以 `json-report` 在两个平台上都能运行；用户选择的两种 HTML 格式（`html`，页面盒子的摹本，以及 `html-flow`，可重排的阅读视图）；以及接缝上的 `pdf`（`MADReportExporterPDF`，Apple 的主体，到处注册，输出字节一致）。**仍待完成：** Linux PDF 写入器本身 —— **于 2026-10-17 延期，阻塞在用户的研究上；没有他们的决定不要启动它**（`MAD_PDF_LINUX.md` 是交接文件：有什么、缺什么、候选技术栈和未决问题）。途中发现的货币格式化分歧于 2026-10-17 关闭（报表的金额按文档的 locale 和精度格式化，所以渲染侧的导出跨平台字节一致；见 `BUGS.md` 的存档）。

本条写成之后落地的两件事也属于它：驱动注册表（`ROADMAP.md` §5.1、`61991e85f`）—— 本任务镜像的正是这种接缝形状 —— 以及 CLI 在 Linux 上运行（`040d162c9`），那正是最先验证新格式的地方，因为 `--format json`/`csv` 是纯 Foundation 而 PDF 不是。

**字节一致的 `.mad`**（用户的要求，2026-10-16）是本项工作按队列现状的另一半：`BUGS.md` 记录归档不可复现，而且 Linux 写入器甚至无法终止。它的修复是可复现写入模式加上往返测试夹具，这也是 `MAD_CLI.md` §6 要求的验收层 —— 与用户一起决定它的形态，因为它定义了 `.mad` v1（`MAD_FORMAT.md` §7）。

项目的简介承诺开发者可以添加**导出格式**而无需编辑核心，这与新增数据库类型和新增文档元素类型并列。那个承诺还没有接缝：`mad export` 只有一条臂，PDF，藏在 `MADCLIExport.m` 里的一次字符串比较之后。

用户的表述，2026-10-01：

> *“如果你愿意，也可以创建一种新的导出格式……把那个放进任务里……导出为文本、邮件、markdown 或上百种其他东西。那是应用中应当可扩展的一部分。但是，只有现在做很快并且有助于核心任务时才做。”*

**这项工作。** `MAD_CLI.md` §5.3 要求一个 `<MADReportExporting>` 协议，这样新格式就是一个新类，而不是 switch 的新分支。这与 `ROADMAP.md` §5.1 想要的驱动注册表形状相同，这正是两者应当放在一起的原因。

**被拾起时先构建文本。** 不是因为需要文本，而是因为它是证明接缝真实存在的最便宜的验证：纯 Foundation，没有 Core Graphics，并且它把报表的内容摆在你面前的终端里，不需要 PDF 查看器。如果接缝是对的，文本是一下午的事。如果不对，文本就是显示问题的地方 —— 在 JSON 或 CSV 针对一个装不下它们的形状被写出来之前。

**为什么它要等。** 一个因为刷新坏了而什么都不渲染的导出器无法证明接缝的任何东西，而今天还没有人无头运行过刷新。任务 7 的阶段 1 改变了这一点。之后，这件事就很快，而且确实有助于核心任务，这是用户自己关于现在是否要做的检验 —— 所以它直接排在阶段 1 之后，而不是队尾。

---

## 9. 可移植存储迁移

**状态：** 阶段 A、B、C 于 `portable-store-phase-a` 落地（2026-10-03）—— 存储、遗留转换器和应用集成，文档路径、撤销和脏跟踪都已证明。阶段 D 已大半就位：`MADocument` 是一个 `UIDocument`，遗留转换器位于应用 target 中 `MADLegacyStoreConversion` 之后，编译的 `.momd` 已移出 MAD 框架，转换后的文档在保存前清理它的 Core Data 文件，框架/MADDesigner 清扫移除了剩余的 Core Data 导入、类型和死代码（`2bf9af919` 及其后续）。按决定保留：值转换器、资源管理器的云端面板、iCloud entitlement/`Info.plist` 容器，以及 `MADocumentState`（保留给未来的云端状态功能）。`MAD_STORE_PHASE_C.md` §9 保存评审发现；`MAD_LINUX.md` 阶段 A 是剩余部分的跟踪器 —— 现在没有任何东西在 Core Data 上阻塞 Linux，所以那里剩下的就是用户已延期的 iCloud/entitlement 清理。

`.mad` 存储从 Core Data 迁移到我们自己的可移植 SQLite 格式 —— 这是 `MAD_FORMAT.md` §8.1 和 `ROADMAP.md` §4.2 中的决定，也是移除最后一个 Apple 依赖（危险项 H3）的方式，从而让另一个平台上的读取器可以打开文档。

用户关于如何做的指示，实质内容逐字如下：

> *“我们要把存储迁移到可移植的 Sqlite3 文件格式。但是，我以为我们会继续使用自动生成的 header……不再自动生成它们了，只是使用它们，并且为 Rptq 那部分自己编写插入和更新表的代码。总之，那是个大项目，需要一些规划，因为它必须转换报表，等等。”*

所以：把生成的 `Rptq` header 保留为固定的、手工维护的契约（停止重新生成），并针对 SQLite schema 手工编写 CRUD。难的部分不是 schema —— 而是**转换已有文档**：每一份已发布的 `.mad` 都带有一个 Core Data 存储，迁移必须读取其中一个并写入另一个，不能丢失任何报表。

**随之而来的一个简化。** `MADocument` 是一个 `UIManagedDocument`，所以丢掉 Core Data 也就丢掉了 iCloud 文档机制。用户的备注，2026-10-01：*“随着去掉 Core Data，我们也就去掉了 iCloud 的东西。那应该会简化应用。”* 把这一点并入计划 —— 迁移同时也是一次去 iCloud 化，文档的打开/保存路径变得更简单，而不仅仅是更可移植。

这与 v1 无关（`ROADMAP.md` §4.3，魔法头 + 带检查点的存储）：v1 是识别和一个检查点，它们都不关心存储的 schema 是什么。不要把两者耦合。

未经用户按名称要求不得启动，并且只能在一份书面计划之后进行，该计划要涵盖两个已发布样本和现有用户报表的转换。

---

## 10. 第三方许可证合规

**状态：** 待处理 —— 开源发布提示词 2（MariaDB Connector/C 替换）于 2026-10-24 落地，GHCR 发布提示词于 2026-10-26 关闭了容器镜像那一项（见下），应用内致谢界面与捆绑许可证文本（计划 C2、C3）于 2026-10-28 落地；剩下的是 relink 工具包脚本（计划 §9.3，因所有者决定而延期）。登记册是 `THIRD_PARTY_LICENSES.md`，计划是 `LICENSE_COMPLIANCE_PLAN.md`；先读这两个，本条只是队列。已完成：miniz 版权头已更正（2026-10-04）；提示词 1 于 2026-10-24 落地（两个无许可证的重写 —— `NSOperation+CompletionBlock` 和带黄金向量钉住密文的 `NSData+AES256` —— 选择 LGPL-3.0 的 FreeTDS LGPL 义务、MIT 重新许可，以及 `ThirdParty/Licenses/`）；提示词 2 于 2026-10-24 落地（见下）；C2/C3 于 2026-10-28 落地。

评审发现了一个阻塞项、三个完全没有许可证授权条款的组件，以及一组应用目前不满足的声明义务（它不附带任何署名）。

**D1 —— 2026-10-24 决定，同日落地。** 所有者选择 MariaDB Connector/C 作为 mysqlclient 的替代。替换内容：Compressor 构建 3.4.11（recipe `lib/recipes/mariadb.sh`，由 `lib/verify/mariadb.sh` 验证，门禁静态 `caching_sha2_password` 插件），`MADMySQL` 链接 `mariadb.xcframework` + `zlib.xcframework` 且不再重新导出库的头文件树，Karl Kraft 层被改写为一等公民代码（计划 §3 A3），Linux 镜像构建把 `Linux/libraries.conf`/`lib/libraries.sh`/`CMakeLists.txt` 换成同一个库。MySQL 套件通过 MariaDB 客户端保持通过 —— 122 个测试，包括针对 Docker MySQL 8.4 服务器的实时套件 —— 并且在每一项门禁之后删除了 mysqlclient 的矩阵行和 recipe。旧的 GPLv2 分析仍作为 `THIRD_PARTY_LICENSES.md` §3.2 存在，标记为历史。2026-10-24 的 MIT 重新许可及其对 FOSS 例外分析的影响，作为决策所权衡的事实记录在那里。

**阻塞项 —— 历史性，已于 2026-10-24 解决。** `libmysqlclient` 8.4.10 是 GPLv2，而 Universal FOSS Exception 只覆盖本身是 FOSS 的软件。_MAD Designer_ 是专有软件，所以按当时的配置分发 MySQL 客户端库会迫使我们以 GPLv2 发布应用源码。选项是：购买 Oracle 商业许可证、用 MariaDB Connector/C 替换客户端（LGPL-2.0-or-later，同一 C API —— `MADMySQL` 使用的全部 27 个 `mysql_*` 入口都在其接口中），或者放弃 MySQL 支持。动态链接**并不**有帮助；GPL copyleft 对链接方式无动于衷。D1 选择了 MariaDB，替换已落地；mysqlclient 的矩阵行、recipe 和链接都已消失，GPLv2 已离开产品。

**必须解决的无许可证代码。** 三个已提交的组件带有“all rights reserved”且无授权条款：Karl Kraft MySQL 连接器（`MADMySQL/Source/`，30 个文件）、`NSData+AES256`（`MADDesigner/Source/`，一段没有作者的 pastie 片段），以及 `NSOperation+Advanced`，现为 `NSOperation+CompletionBlock`（`MADFoundation/Source/`，两个小方法，上游 `kas-kad/AdvancedNSOperations` 没有 LICENSE 文件）。三者都是重写而非谈判。**三者都已落地：** `NSOperation+Advanced`（重命名为 `NSOperation+CompletionBlock`）和 `NSData+AES256` 在提示词 1（2026-10-24），Karl Kraft 连接器在提示词 2 的重做中（2026-10-25，`c46201465`）—— 删除 28 个 `Mysql*` 文件，替换为依据 MySQL C API 编写的 `MADMySQL*` 类，类结构和面向 `MADMySQL` 的 API 保持不变，行为在前后都由 122 个测试的 MySQL 套件（含实时测试）钉住。2026-10-24 的第一遍（`68d885440`）保留了旧文件名，读起来像一次头文件编辑而不是重写；它已在历史中被替换。具体到连接器：原始发行版（2026-10-04 检查过，随后删除）同样没有授权 —— 一篇公开博客文章不是对公有领域的奉献 —— 而且既然 MariaDB 替换无论如何都要触碰那一层，计划就把它改写为一等公民代码（计划 §3 A3）。

**一旦上述决定做出，就是机械性的合规工作。** 许可证文本已提交（`ThirdParty/Licenses/`），FreeTDS 的 LGPL 事项于 2026-10-24 落地：选择并记录 LGPL-3.0（它链接 OpenSSL 3，而 Apache-2.0 与 v2 条款不兼容），修改后的 `sybdb.h` 现在由 recipe 附带其声明，书面的 relink 要约在 `ThirdParty/Licenses/README.md` 中（工具包脚本因所有者的决定而延期，计划 §9.3）。FontAwesome 的 OFL 文本和 CarbonBlock 的 Larabie readme 已提交。应用内致谢界面和捆绑的 `ThirdParty/Licenses/` 资源目录（计划 C2、C3）于 2026-10-28 在 `MADAboutTableViewController` 中落地。仍然开放：relink 工具包脚本。miniz 的头文件于 2026-10-04 更正。

**Linux 工具链，于 2026-10-06 标记（见 §11）—— 于 2026-10-26 解决。** 阶段 B 镜像构建在 libobjc2（MIT）、libdispatch（Apache-2.0 带 Swift 运行时例外）、GNUstep Make（GPL-3.0-or-later）和 GNUstep Base（LGPL-2.1-or-later）之上，并把 gnustep-make 的 GPL-3.0 `Testing.h` 编译进它的测试二进制。没有任何东西被链接进应用。运行时镜像（阶段 F，`Linux/Dockerfile` 的 `runtime` 阶段）在本地构建并运行过，未发布（用户决定，2026-10-17）；GHCR 发布提示词推翻了那个决定，镜像以 `ghcr.io/mthomason/mad` 发布（CI 构建 amd64，`.github/workflows/publish-image.yml`）。该标记所指的义务现已履行：`ThirdParty/Licenses/README.md` 中的 relink 要约点名了该镜像（GNUstep Base 和两个静态链接的 LGPL 库 —— mariadb 和 freetds —— 并给出公开的固定版本与重建路径），gnustep-make 仍是构建工具且不在镜像中，登记册条目是 `THIRD_PARTY_LICENSES.md` §9。`Linux/README.md` 的 §Licences 有细节。

未经用户按名称要求，不要启动其中任何一项 —— 尤其是阻塞项，那是商业决策，不是工程任务。

---

## 11. Linux 工具链（docs/project/MAD_LINUX.md 阶段 B）

**状态：** 于 2026-10-06 在 `linux-port` 上完成（由 `linux-phase-b` 改名；2026-10-16 合并到 `master`，`524e0d86e`）—— 验证原型（spike）已通过，阶段 C 是下一步。阶段 C 的两个输入来自这项工作：记录在 `Linux/README.md` 中的 GNUstep 分歧，以及因此短得多的垫片清单。

**已落地内容。** `Linux/` 构建一个 Docker 镜像 —— Ubuntu 24.04、发行版 clang 18、源码构建的 libobjc2 2.3、libdispatch 6.1.3、gnustep-make 2.9.3 和 gnustep-base 1.31.1，全部钉在 `Linux/toolchain.conf` —— 针对 GNUstep 编译 27 个 MADFoundation 实现文件中的 23 个外加 `madlib.c`，并在容器内运行 15 个测试可执行文件（14 个移植套件和工具链探针）：全部通过，伴随 5 项记录的待办和探针的 10 个报告项。`./Linux/build.sh` 是入口点；iOS 套件（118 个测试，0 失败）是这次构建所需六个小型平台守卫的回归门禁。amd64 交叉检查在一台 arm64 机器上端到端跑过（2026-10-06）：工具链在模拟下构建，运行 15/15，配有相同的 3 项待办和 10 个报告项。

**最重要的发现 —— 于 2026-10-06 解决。** GNUstep 的 `NSOperationQueue` 会在每次通知时移除它的 `isReady` KVO 观察，而 MADOperation 的状态机过去在每次入队时不止一次通知 `isReady`（`Pending` → `EvaluatingConditions` → `Ready`），Apple 的实现只通知一次；第二次移除抛出 `NSInvalidArgumentException`，操作永远不运行，这使阶段 D 的刷新路径面临风险。MADOperation 现在从 `-willEnqueue` 显式驱动推进，并且只在值真正变化时发送 `isReady`/`isExecuting`/`isFinished` KVO，所以队列只看到一次通知，与 Apple 一致。Linux 测试在两个平台上直白断言队列路径，计入的待办从 5 降到 3（探针的归档/app-group 项和凭据安全编码项仍在）。机制写在 `Linux/README.md` 中。

**这一阶段刻意未证明的：** 四个被排除的文件（`BDHost`、`MADApplication`、`MADKeyChain`、`MADURLFactory`）、CLI、其他框架和驱动、导出格式、CI 和发布。阶段 D 的数据路径检查点仍是 go/no-go。

**这项工作产生的后续事项：**
* ~~其他八个 `madlog.h` 副本在各自的框架到达 Linux 时都需要同样的平台分支~~ —— 2026-10-06 完成：全部九个副本合并为 MADFoundation 单一的 `madlog.h`/`madlog.m`，按 target 以 `MADLOG_ACCESSOR` 路由；其他框架剩余的阶段 C 工作是它们直接的 `os_log_*(Get*Log(), ...)` 调用点（§12）；
* ~~MADFoundation 的头文件不是自包含的 —— Linux 构建用 `Compat/MADCompat.h` 掩盖了这一点~~ —— 2026-10-06 完成：Linux 构建中的每个头文件和源文件都导入它所用的东西（通过把每个文件编译成只有 `NSOperation name` 垫片作为前导的单行翻译单元来验证），而 `MADCompat.h` 就只剩那个垫片；
* 工具链组件的许可证登记册条目（上文 §10）。

未经用户按名称要求不得启动。

---

## 12. Linux 阶段 C —— §4 垫片清单

**状态：** 于 2026-10-06 在 `linux-port` 上完成，2026-10-16 合并到 `master`（`524e0d86e`）。全部十个无头框架都在 Linux 镜像内编译并链接，它们的套件在 ctest 下运行，剩余排除项都在各自的 `Linux/cmake/<Name>Sources.cmake` 中带理由点名。阶段 D —— CLI/数据路径检查点 —— 于 2026-10-16 落地，写在 `Linux/README.md` 和 `MAD_LINUX.md` §9 中：`mad` 在镜像内构建并运行，`inspect`/`schema`/`query`/`refresh` 针对 `CLI/Fixtures/` 中的测试夹具以及实时 MySQL 和 SQL Server 都通过，117 个可执行文件（1153 个测试）在 ctest 下通过，而文档问题以 `MADDocumentDataProtocol` + `MADHeadlessDocument` 解决（用户的选择，2026-10-16）。

**审计，工作前重跑一次 2026-10-06，结束时又跑一次**（匹配模式的文件，`*.m`/`*.h`/`*.c`，排除 `.xcodeproj`）。之前：`asl.h` MAD 2；`copyfile.h` MAD 2；`vm_param` MAD 1；`CFNetwork`/`CFHost` MADFoundation 1；`os/log.h` MADFoundation 1（预期的 Apple 分支）；`CoreFoundation` MADFoundation 2、MAD 18、MADSqlite3 1；`UIKit` MADFoundation 4、MADCocoaExtensions 12、MADAPI 3、MAD 29；`CoreGraphics` MADCocoaExtensions 3、MAD 14；`AppKit` MADFoundation 1。应用侧（MADDesigner/MADExplorer）按 §3 的表不在范围内；独立的 MAD Viewer target 的 `MADNavigationController.m` 保留它自己的 `<os/log.h>` —— 它不链接任何 MAD 框架。

**已落地内容，按框架**（全部在 `linux-port` 上，现为 `master`）：

* **日志层。** `madlog.h` 的非 Apple 分支以宏的形式在 `MADLogEmit` 之上提供 `os_log_t`、`OS_LOG_DEFAULT`、`os_log_create` 和五个 `os_log_*` 函数，所以每个框架中以 Apple 拼写写成的调用点都原样编译；访问器以空操作句柄存在，`MADLogFormat` 剥掉 GNUstep 会按字面打印的 `%{public}` 注解。在头文件之外扫过 `os_log_*`：没有剩余。
* **MADFoundation。** `BDHost`（`__APPLE__` 后面的 `getaddrinfo`/`getnameinfo`，以太网遍历用 AF_PACKET）、`MADApplication`（无头下 `AppDelegate` 为 nil；头文件前向声明 `UIApplicationDelegate`）、`MADURLFactory`（无屏幕；app-group 路径回退到每用户目录）。`MADKeyChain` 留在外面（§4），伞头文件随之。27 个文件中的 26 个。
* **MADDataStructures**（全部 17 个）、**MADFileManager**（11 个中的 10 个；云协调器按 §4 排除，目录监视器移植到 inotify）、**MADCocoaExtensions**（17 个中的 7 个：十个 UI 文件排除）、**MADAPI**（11 个中的 8 个：连接视图控制器排除）、**MADSqlite3**（全部 26 个）、**MADTds**（1 个）、**MADTdsClient**（5 个中的 4 个）、**MADMySQL**（19 个中的 18 个）。
* **MAD**（181 个中的 150 个）。§4 的事项：`asl.h` 和 `vm_param.h` 的导入是残留，已移除；`copyfile(3)` 在 POSIX 中得到回答（`Compat/MADCompatFileCopy.h`）；CoreFoundation 的位点是 `CFNumberGetValue` 提取调用，由一个兼容的 `CoreFoundation/CFNumber.h` 回答。31 个排除项分为：UI 尾部（§5.2）、`MADocument` 加上构建/关闭它的操作（阶段 D 的）、钥匙串操作（§4），以及由 MADBarcodes 支撑的元素文件（§3：未使用；元素*类型*留在模型中，两条创建路径在非 Apple 上记录日志并跳过）。
* **库层。** `Linux/libraries.conf` + `lib/libraries.sh` 把 sqlite3 3.53.3（已发布的 amalgamation，用 `Compressor/sqlite3.xcconfig` 中的选项列表编译）、openssl 3.5.9、freetds 1.4.27、zlib 1.3.2、bzip2 1.0.8、libarchive 3.8.9 和 mysqlclient 8.4.10 构建进镜像的 `/usr/local`。没有任何东西发布；GPL 问题归 `LICENSE_COMPLIANCE_PLAN.md` 管（§10）。

**测试。** 每个移植的套件都是 `Linux/Tests/` 下的一个 ctest 可执行文件，按 `Linux/AGENTS.md` 中的 `Testing.h` 约定编写。114 个可执行文件（1098 个测试）在 ctest 下运行，全部通过，记录 6 项待办 —— 计数器和每一项待办都在 `Linux/README.md` 中论证。2026-10-10 合并的测试覆盖主线（约 100 个 Xcode 测试文件，横跨 MAD、MADFoundation、MADAPI、MADCocoaExtensions、MADFileManager、MADSqlite3 和 MADMySQL，加上 MySQL 测试数据库 Docker 基础设施）已完整移植：新增 55 个可执行文件，套件对套件。需要实时数据库的套件在没有可连接对象时跳过（从不失败）；`MADTdsClientLiveTests` 在 Linux 镜像内部针对 SQL Server 2022 容器运行过 —— 29/29，169 项检查 —— `MADMySQLLiveTests` 针对宿主机的 MySQL（44/44，309 项检查），所以数据库交互路径真正被跑过，而不只是编译。
MAD 的八个套件也已移植（186 个测试，覆盖数据表、可移植存储、rptq 对象层、查询和文档区段），运行它们又发现了三处 GNUstep 分歧，都已修复或垫片并写在 `Linux/README.md` 中：BOOL 的运行时编码（这里是 `'C'`，Apple 上是 `'c'` —— 在 `RptqObject` 中按平台注册）、`class_getProperty()` 不走父类（在 `RptqObject` 中显式遍历），以及桩实现 `+propertyListWithStream:options:format:error:`（一个 Compat category，它让 MADDataTable 的 `-loadFromCacheWithUrl:` 能被断言，而不是作为待办搁置）。合并与移植这一轮又加了更多：框架 target 丢失的 `$(inherited)`（DEBUG 在每个 Apple 框架 target 中都失效了 —— 已在十个项目中修复）和 MAD 的非封闭式文档测试夹具（两者都记录在 `BUGS.md` 中）；Linux 侧则包括 `NSOperation.asynchronous`/`-isConcurrent`（一个 Compat category —— 没有它，一个正在结束的异步操作会在 `-dealloc` 中抛出异常）、会触发故障的 `-coordinateAccessWithIntents:`（一个 Compat category）、`MADURLFactory` 产出的无 scheme URL（现改为 `+fileURLWithPath:`），以及 MADQuery+Sqlite3 的 category 被链接器丢弃（通过 `target_sources` 编译进 `libmad.a`）。仍有六项待办属于 Apple 专属机制 —— Core Data、编译的模型、`MADocument`、转换器 —— 记录在无法运行的测试中。
有一处分歧是钉住而非修复：`-localizedCaseInsensitiveCompare:` 在 GNUstep 上区分大小写，所以 MADSqlite3 注册的 SQLite collation 排序不同（在 `MADDatabaseSqlite3Tests` 中按平台断言）。

**仍然存在的排除项及其记录位置：** `MADKeyChain` 和伞头文件（MADFoundation）、云协调器（MADFileManager）、十个 UI 文件（MADCocoaExtensions）、三个视图控制器（MADAPI）、一个（MADTdsClient）、一个（MADMySQL），以及 MAD 的 31 个 —— 每一项都在框架的 `cmake/<Name>Sources.cmake` 中带理由点名。`MADExplorer`、`MADBarcodes`、`MADFeedback` 和 `Scrimpter` 完全不构建（§3 的表）。

**推进下去的后续事项：**
* ~~驱动注册表（`ROADMAP.md` §5.1）~~ —— 2026-10-16 完成（`61991e85f`）：`MADDatabaseDriverRegistry` 注册驱动，构造函数查找它们，Linux 构建对驱动的归档使用 whole-archive，使它们的 category 和 `+load` 在静态链接中存活；
* ~~`MADocument` 和 `MADReportFormatter`~~ —— 2026-10-16 由用户选择无头文档路径而解决：`MADDocumentDataProtocol` 是数据那一半，`MADHeadlessDocument` 实现它，`MADocument` 原样遵从，刷新链对两者都能运行。`MADReportFormatter` 仍只限 Apple，`mad export` 也是（§8）；
* 工具链和库组件的许可证登记册条目（§10）—— 阶段 F 的工作，在镜像发布之时。

---

## 13. 编译器警告与分析器清理

**状态：** 进行中 —— 五个框架于 2026-10-17 完成，MADBarcodes 于 2026-10-20 清除；应用和 MAD 仍在。

2026-10-17 对 `MAD Designer` 的干净 Analyze 报告了 128 条原始 / 124 条唯一的编译器警告和 98 个分析器问题。五个被要求的框架先被清除，每个都用私有的 derived-data 路径单独分析，并在套件通过时提交：

* **MADTds** —— 没有第一方诊断；内置 `sybdb.h` 的引文和 Compressor 沙箱备注保持记录。提交 `c55cef2bc`。
* **MADTdsClient** —— 清除 8 条；`-runSQL:` 现在记录并传播它的 SQL 错误。套件针对 SQL Server 2022 为 76/76。提交 `93c2e1d57`。
* **MADMySQL** —— 清除 3 条；`NULL` 的 `error` 加了守卫，`MYSQL_BIND` 零初始化。套件针对 MySQL 为 121/121。提交 `598cadd03`。
* **MADAPI** —— 清除 3 条源码和 12 条测试包 `-Wnonnull`。套件 105/105。提交 `cd814227d`。
* **MADSqlite3** —— 清除 11 条源码和 5 条测试包警告；`MADArrayCaching` 初始化器契约和 `MADDataTableFast` 的 nil 路径与用户一起确定。套件 89/89（跳过 5 个基准测试）。提交 `daff35986`。
* **MADBarcodes** —— 在一次隔离的干净构建和 Analyze 中清除 20 条编译器警告和一个分析器问题。`CGImageCreate` 的 alpha 转换为 `CGBitmapInfo`，`height` 赋值转换为 `float`，输出参数显式标记为 `__autoreleasing`，而已经做过边界检查的、拷入 zint `primary[128]` 的复制改用 `memcpy` 而不是 `strcpy`；十七个 `NSInteger`/枚举选项赋值接受显式的 `int16_t` 转换，行为不变。套件 29/29；应用构建通过。项目的 Copy Headers 沙箱备注是构建设置警告，不是源码。提交 `2be05d692`。

`./Linux/build.sh` 120/120 通过。在五个框架之后，全项目分析器计数为 86（原为 98）；MADBarcodes 那一个隔离的问题在此清除，所有剩余的分析器结果和编译器警告都在应用和 MAD 中。测试包还带有部署目标链接器警告（XCTest 为 17.0 构建，包的下限是 15.0），属于 §6/项目设置那一轮。

---

## 14. 报表格式化器端到端性能

**状态：** 待处理 —— 组分界比较阶段已完成（`327cccc1b`）；剩下的是下面的逐行工作。

2026-10-20 的性能轮次做到每次格式化只解析一次每个组层级的比较器，并为每个层级每行计算一个变化旗标，由页眉和页脚遍历共享。在用来测量它的合成 200k 行、3 层级格式上，分界阶段从约 0.20 秒降到约 0.03 秒（5–6 倍），而 London 和 Music 的 `json-report` 导出保持字节一致。那个阶段现在只占约 38 秒的 Debug/simulator 格式的约 0.1%；其余就是下面的逐行工作。设计和测量在提交 `327cccc1b` 中；它构建于其上的正确性契约是 `483a77259`，以及 `BUGS_FIXED.md` 中的存档条目（“MADReportFormatter compares untyped values through id”和“The cache's ORDER BY ignores column types, so text keys sort binary”）。

**热点，按预期影响排序。**

1. **页面索引数组每行都被复制。** `MADReportFormatter.m:756`：
   `self.pageIndexesTemporary = [self.pageIndexesTemporary arrayByAddingObject:rowIDObject]`
   对每个明细行都是 O(page) 的复制，一页下来是 O(rows²/page)。循环自己的注释（`:687-692`）在内存尖峰的故事里已经怀疑到它。用一个可变页面缓冲区替换它，每页重置一次，在分页处和结尾把一份副本刷入报表缓存；保持缓存收到的数组不变。很可能是最大的墙钟时间收益。
2. **每行都新建一个键值数组。** `-newObjectArrayKeyValuesForResultRow:`（`:491`，在 `:708` 调用）分配一个 `NSMutableArray`，并为每组每行做一次字典查找。一个可复用的按格式化器缓冲区（或一个把键递回来的枚举器）可以去掉这次分配。不要改变方法的公开结果：`MADDocumentRenderDataSource -groupLevelKeys:` 用它来生成聚合的 WHERE 子句（`MADDocumentRenderDataSource.m:87`），所以复用的缓冲区必须保持在格式化器内部。
3. **逐行的 `@autoreleasepool`。** `:687-693`。它是刻意的，防止了 8k 页的内存尖峰；不要移除它。只在 1 和 2 之后再测量它，并且只在剩余的逐行工作值得时才测。
4. **逐明细行的区段对象与缓存插入。** 每个正文行都分配一个 `MADSectionRepresentation`（`:752`），而每页的布局数组和索引数组都被插入 `MADArrayCaching`（`:638-641`、`:861-867`）。表示池或另一种页面布局载体是更大的设计改动；先测量再设计。
5. **公开比较器的每次调用路径。** `+compareValue:withValue:forDataType:`（`:335-352`）每次调用都解析族（`MADComparisonFunctionForDataType`，`:329`），实测比预遍历实现慢约 16 ns。它是面向测试的稀有路径，不是行循环；除非外部调用者让它变热，否则不要动它。

**如何测量并证明收益。** 在同一台机器和同一配置上复现基线：

* 一个由 `MADDataTableVirtual` 支撑的文档，200,000 行、3 个组层级（一个十值循环模式，让约 1,110 个分界触发），把 `format:` 计时为三次运行的中位数，并带一个 0 组对照；
* 分别报告分界阶段和端到端时间：端到端噪声大（这台机器上 ±1.5 秒），所以只移动一个小阶段的改动可能在那里看不出来；
* 构建 CLI（`CLI/build.sh --no-frameworks`），用 `--deterministic` 刷新并导出 London 和 Music，比较 `json-report` 的字节；前后必须完全一致；
* 运行 MAD 套件和 `./Linux/build.sh`（普通模式，Docker 已启动）；`MADReportFormatter.m` 在 Linux 构建中。

**完成标准：** 至少一个热点显示出高于噪声底的、实测的端到端改进，导出字节一致，并且 MAD 与 Linux 套件通过。作为提速改动的一部分，不要改变比较契约、页眉/页脚遍历顺序，或缓存收到的页面数组。

**还没有队列条目的后续事项：** 枚举存储（`"red"` 解析为 0）以及能让契约前的冷回退退役的缓存 `user_version` 戳记。两者目前只存在于已存档的 `BUGS_FIXED.md` 条目中；被拾起时，给每个都建自己的任务或 `BUGS.md` 条目。

---

## 15. 条码元素：现代化 MADBarcodes 并重新集成该元素

**状态：** 于 2026-10-21 完成 —— 任务 0-7 均已落地。任务 8（伞头文件）是可选的，未采纳。

条码元素**始终可用**：设计器选择器与其他元素类型一起添加 `MADPrintPageElementTypeBarcode`（`MADDesignerElementPickerViewController.m`），而 `barcodeDesignerEnabled` 旗标仍为单独的许可证清理而保留定义。`MADBarcodes` 框架在 67 个 `MADBarcode*` 码制子类之后封装 zint 2.16.0（Compressor recipe）；它仅限 Apple，并被排除在 Linux 构建之外，在那里元素类型只存在于模型中（`#if __APPLE__` 的创建路径记录日志并跳过）。

提交，每个任务一个：

* `bd37d0ec4` —— 任务 1：框架改名 `MTBarcode*` -> `MADBarcode*`。
* `db5087c61` —— 任务 2：修复被钉住的框架缺陷，删除死代码。
* `2b71079af` —— 任务 3：单次 `CGImage` 绘制的渲染路径加 `MADBarcodeCache`。
* `2be05d692`（记录在 `78b21621f` 中）—— 任务 4：警告清扫。
* `b762d1ded` —— 任务 5：元素层修复（基类 `type` 被覆写、存储颜色映射、`-text`、编辑菜单）。
* `e4c29cbc6` —— 任务 6：导出与辅助功能覆盖。
* 任务 7（本次提交）：移除选择器门禁，更正文档，端到端验证。

门禁：`MADBarcodes` 29/29 和 `MAD` 608/608；应用可为模拟器构建，并在禁用签名的情况下为通用设备构建（这台机器没有 `iOS Distribution` 证书）；`./Linux/build.sh` 120/120 通过。设计记录和逐任务提示词留在 `docs/archive/MAD_BARCODES.md` 中（2026-10-22 存档）。

**仍待完成**（记录在 `docs/archive/MAD_BARCODES.md` §5，刻意未构建）：无头条码渲染（把 zint 加入 `Linux/libraries.conf` 再加一个不依赖 UIKit 的渲染核心）、GS1/Data 输入模式、模型上的 `detailsSegueIdentifer`、HTML 导出器中的条码图像，以及应用范围的第三方声明缺口（zint 的 BSD-3-Clause 声明随许可证登记册这条线走）。

---

## 16. SQL 录入 —— 将 SQL 语句粘贴到查询设计器

**状态：** 于 2026-10-22 完成 —— 阶段 A–D 在 `sql-entry` 上落地，并作为 `c48a39fb7` 合并进 master（未推送）。阶段 E 延期（有它自己的决定）。合并时的门禁：应用 scheme 79/79、MAD 696/696、`./Linux/build.sh` 123/123 —— 由评审者重跑，而不只是构建者。完整设计见 `MAD_SQL_ENTRY.md`；本条是指针，不是重述。

功能：在现有只读 SQL 弹出层（`MADViewControllerSQL`，由 `MADQueryBuilderSplitViewController` 中的 `barButtonItemSQL` 呈现）上加一个查看/编辑模式，用户在其中粘贴一条 SELECT 语句；点击 Apply 时，它被解析（parse）、针对文档 schema 做名称解析（resolve）、验证（可选地通过零行服务器探针），并通过视觉设计器所用的同一批工厂编译进 `Rptq` 查询图 —— 表、连接、谓词、分组 —— 于是视觉查询设计器、可视化画布和报表设计器都能继续作用于导入的查询。粘贴的确切文本作为 `sqlSourceText` 持久化在 `RptqQuery` 上（一个新的存储属性，也是可移植存储的第一个版本化步骤）；弹出层的查看以一个 **As entered** 形式展示它，旁边是 **Generated** 形式。

设计的各个阶段，每个都带验收标准和测试：

* **阶段 A（仅 MAD；Linux 通过）** —— 持久化的源文本：`RptqQuery` 上的 `sqlSourceText`（编译模型 + `MADStoreSchema` 描述符 + 自动生成属性，一次改动），加上存储的第一个版本化机制（`PRAGMA user_version`，一个带单条目的迁移列表 —— v1 → v2 添加该列 —— 在打开时应用；新存储直接位于当前版本）。MAD 和 Linux 镜像中的迁移测试。自包含；先于解析器落地。
  **于 `sql-entry` 完成（2026-10-22，合并 `c48a39fb7`）。** 与设计有两处偏离，都是 Core Data 机制所迫：模型改动是一个新的 `MAD 4` 版本（就地编辑 `MAD 3` 会改变它的版本哈希，并使每一份野生文档的元数据成为孤儿），而遗留转换器现在按其元数据匹配的 momd 版本打开每个存储 —— 自动迁移对这个模型家族永远行不通（条码 `elementID` 冲突，BUGS.md）。
* **阶段 B（仅 MAD；Linux 通过）** —— 黄金 SQL 测试钉住 `MADQueryFull` 的按驱动输出，然后是 `MADSQLTokenizer`/`MADSQLParser`/`MADSQLStatement`（`MAD/Source/sql/`）和 `MADSQLParserTests`。支持的子集恰好是模型能容纳的内容（`MAD_SQL_ENTRY.md` §5）；拒绝带有编码错误和行:列。
  **于 `sql-entry` 完成（2026-10-22，合并 `c48a39fb7`）。** 十个黄金测试（确切的语句、MySQL 和 TDS 方言、全部七种连接类型、drop-index 别名、全部六种谓词运算符及其字面量引用、按别名排序的活动 select 列表）在 `MADQueryFullTests` 中，两个平台都跑；解析器套件（64 个测试）覆盖 §5 的接受矩阵和 §10.3 的拒绝表，带错误码和行:列，两个平台都跑。`MADDatabase` / `MADDatabaseMySQL` / `MADDatabaseSQLServer` 上的 `+identifierQuoteCharacters` 把它的引用字符对喂给词法分析器。对阶段 C 的提示：解析器接收 schema（表 → 字段名），自己完成 §5 的名称检查 —— 未知表/列、歧义、别名形式、每对一次连接、ORDER BY ⊆ GROUP BY —— 所以解析器（resolver）的职责是把验证过的名称绑定到 Rptq 行。
* **阶段 C（仅 MAD；Linux 通过）** —— `MADSQLStatementResolver` + `MADSQLQueryCompiler`（原子替换；对照设计器元素引用做冲突检查；成功时原样写入 `sqlSourceText`），外加 `MADSQLQueryCompilerTests` 和不动点往返测试（模型 → SQL → 解析 → 编译 → 同样的 SQL）。
  **于 `sql-entry` 完成（2026-10-22，合并 `c48a39fb7`）。** 编译器通过一个新的 `MADSQLQueryDocument` 协议与文档对话：`MADocument` 用设计器的布局管理器实现它（外加两个新的清理辅助方法，用于连接和谓词），`MADHeadlessDocument` 只用定义行实现它。冲突检查覆盖三种元素形状（标签数据、聚合、条码）外加分组区段；不动点测试把 WHERE 子句限制为一个谓词，因为生成器迭代谓词集合，而 GNUstep 的集合顺序与 Apple 不同（顺序在黄金测试中也是刻意不钉住的）。
* **阶段 D（MADDesigner）** —— 查看/编辑弹出层（Generated 和 As entered 两个标签页，编辑从存储的文本播种）、`MADOperationValidateSQL`（通过 `MADOperationRefresh` 模式探针 `SELECT * FROM (<sql>) AS _mad_probe WHERE 1=0`），以及在一个样本 sqlite3 文档上的 UI 测试，包括关闭并重新打开的持久化。
  **于 `sql-entry` 完成（2026-10-22，合并 `c48a39fb7`），有一处记录的缺口。** 弹出层的查看/编辑模式在 storyboard 场景之上用代码构建；`MADOperationValidateSQL` 及其五个构造测试在应用 target 中（应用 scheme 79/79；一个既有的 `MADStatusLabelRefreshTests` 方法从不执行）。**§10.6 的 UI 断言没有运行：** XCUITest 环境看到的是空的无障碍树（docs/project/BUGS.md，“Test infrastructure”），所以表列表/画布/设计器的断言无法做出，UI 测试的刷新断言记录在此而不是伪造。UI 测试本会展示的 §9 关闭并重新打开持久化，在存储层由阶段 A 的迁移套件和阶段 C 的编译器套件覆盖（`sqlSourceText` 原样、一次保存、重新打开），它们两个平台都跑。
* **阶段 E（延期；有它自己的决定）** —— SELECT 列表的元素合成，以及若有需要时的已应用语句历史（一个从当前 `sqlSourceText` 回填的有序 to-many）。

产品决策，于 2026-10-22 解决（`MAD_SQL_ENTRY.md` §11）：严格子集、替换而非追加的原子应用、GROUP BY 自动创建报表分组区段、SELECT 列表在阶段 E 之前只验证不存储，以及粘贴文本作为单个 `sqlSourceText` 属性持久化。

## 17. 开源发布 —— 提示词 1–7

**状态：** 进行中 —— 提示词 4 于 2026-10-25 落地（只有草稿，什么都没发布）；提示词 5 的报告在同日刷新；提示词 6（libmysqlclient 历史清理）于 2026-10-25 落地，包括首次把 `master` 推送到私有远程；salesforce/RestKit/Azure、Karl Kraft/zlib 和 zint 的后续清理也在同日落地。名称门禁仍开放（已询问；用户倾向“Madfile”）。

MIT 发布是一个由 `~/Desktop/MADOpenSource/` 驱动的六提示词操作（提示词文件 `0[1-6]-*.md`），在 `open-source-prep` 分支上运行；在用户拨动开关之前什么都不发布。策略是 `MAD_STRATEGY.md` 附录 A；发布所依赖的许可证工作是 §10（提示词 1–2）。git 历史清洗于 2026-10-23 完成（备份 `~/Desktop/Reports-prescrub/` 和 `.git.prescrub-2026-10-23`）；第二次清洗 —— libmysqlclient 那一遍 —— 于 2026-10-25 完成（备份 `~/Desktop/Reports-prescrub-libmysql-20261025.bundle`）。

* **提示词 1（许可证卫生）—— 2026-10-24 完成。** 无许可证的重写（`NSOperation+CompletionBlock`、`NSData+AES256`）、FreeTDS 的 LGPL 义务、`LICENSE`/`NOTICE`、`ThirdParty/Licenses/`。
* **提示词 2（MariaDB 替换）—— 2026-10-24 完成。** Connector/C 取代 mysqlclient；Karl Kraft 层改写为 `MADMySQL*` 类（重做于 2026-10-25 落地，`c46201465`）；实时套件通过。
* **提示词 3（头文件与公开表面）—— 2026-10-25 完成。** SPDX 清扫（`3d685d220`）：在 1,913 个第一方文件上加了确认的一行头（旧的 `All rights reserved` 行就地转换；没有头的文件补上该行；第三方不动）。公开表面：围绕“报表就是一个文件”重写的 `README.md`、`CONTRIBUTING.md`（测试先行、DCO）、`SECURITY.md`、`CODE_OF_CONDUCT.md`、issue/PR 模板、`.github/workflows/linux.yml` CI（buildx 层缓存，master 触发）、重构进 `docs/` 的规范（规范性内容逐字搬移；`MAD_FORMAT.md` 现在是一个指针），以及从 `.gitignore` 中删掉的过时 `opt/` mysqlclient 模式。门禁：`./Linux/build.sh` 通过（123 个可执行文件、1,262 个测试、8 项待办），`--verify` 通过（MADVERIFY 30 passed），以及 iOS MADFoundation（191）+ 应用（87）套件通过。`--verify` 还暴露了一处替换残留：Dockerfile 的 runtime 阶段仍在复制已退役 mysqlclient 的共享对象、错误消息和字符集表，所以 runtime 镜像构建自提示词 2 以来一直是坏的；那三个 COPY 和 soname 符号链接已删除（静态 mariadb 不需要其中任何一样），该阶段的注释现在记录了发布许可证的立场（`4615e9266`）。
* **提示词 4（营销交付物）—— 2026-10-25 完成。** 只有草稿，在 `~/Desktop/MADOpenSource/drafts/` 下（仓库之外）：发布公告（`01`，Show HN 标题 + 正文，`[NAME]` 占位符）、演示脚本（`02`，每条命令都运行并捕获输出 —— Docker 单行命令、`inspect`、`refresh --verbose`（0.05 秒内 76 行）、`export --format html`（62,007 字节）、对钉住的表做摘要匹配、打开浏览器；两平台的演示环节被记录为在 BUGS.md 的导出顺序条目关闭之前*不可*演示）、名称备忘录（`03`，候选名经网络搜索检查；以那个问题结尾 —— 已询问，用户在“MAD = mobile analytics document”上倾向“Madfile”），以及驱动编写教程（`04`；前向链接是 `docs/tutorials/driver-authoring.md`，从 `README.md`、`CONTRIBUTING.md` 和驱动提案模板引用 —— 一旦选定名称，草稿发布的归宿）。演示验证发现了记录在 BUGS.md 中的 LSASC 导出顺序分歧（钉住的跨平台摘要在 `c27cd4188` 之后于 Apple 侧已过时）。
* **提示词 7（导出顺序分歧修复）—— 2026-10-25 完成，`b07b51f43`。** 提示词 4 的验证发现的 BUGS.md 条目以其选项 (a) 关闭：导出的分组顺序现在是一个定义好的顺序 —— 先大小写折叠（一张检入的 Unicode 17.0.0 simple-fold 表），再 UTF-8 码点顺序 —— 由一个比较器（MADFoundation 中的 `NSString+Comparison`）驱动 LSASC collation、排序描述符和格式化器。所有钉住值都从两个平台重新测量且一致；Mac 侧的摘要门禁现在存在（`MAD/MADTests/MADReportExporterTests.m`）。门禁：`./Linux/build.sh` 通过（124 个套件）+ `--verify` 30/30，以及 iOS MADFoundation/MAD/MADSqlite3/MADAPI 套件通过。发布草稿（`~/Desktop/MADOpenSource/drafts/01` 和 `02`）带有新的摘要，演示的两平台环节现在可以演示了；FINAL-REPORT.md §2 第 10 项可以标记为已解决。
* **提示词 5（发布决定）—— 报告写于 2026-10-25（仓库之外，`~/Desktop/MADOpenSource/FINAL-REPORT.md`），并在同日以提示词 4 的成果刷新；其中的发布命令除 §3.2–3.3（由提示词 6 执行）外仍未执行。**
* **提示词 6（libmysqlclient 历史清理）—— 2026-10-25 完成。** 第二次 `git filter-repo` 清扫（FINAL-REPORT §4 第 7 项，选项 (b)）：无许可证的上游 MySQL 客户端发行版和 GPL 的 `libmysqlclient` 二进制从整个已发布历史中消失 —— 提示词中的五个家族（`libMySqlClient*`、`Reports/libMysqlClient*`、`Reports/libmysqlclient*`、`Reports/TheReportViewer/APIs/libmysqlclient*`、`README-libmysqlclient.txt`）加上该遍验证门禁要求的同家族路径（两个 `mysql-connector-c-6.0.2` 发行版、`TheReportViewer/libmysqlclient.a` 与框架副本，以及两种布局下的 `Objc_Mysql_iPhone_OSX` 内置目录）。filter-repo 解析了 9,216 个提交；`7120a3b02` 未能存活（它的祖先被重写了）—— 新的顶端是 `9ef855d1d`，树与 `94aa729ae` 字节一致；最早的 13 个提交保留了它们的哈希。18 个过时的清洗前分支和 11 个标签已从远程删除，重写后的 `master` 在仓库仍为私有时被强制推送（受 lease 保护）。本地的清洗前分支和更新后的安全引用 `kk-rewrite`/`open-source-prep-backup-kk` 只留在本地。GitHub GC 告诫：被删除的引用不再可浏览，但 GitHub 按它自己的时间表清除；全新仓库是唯一绝对确定的选择。
* **提示词 6 的后续（salesforce/RestKit/SBJson/Azure 那一遍）—— 2026-10-25 完成，由用户直接指示。** 第三次 `git filter-repo` 清扫从整个历史中移除了剩余的第三方书架，覆盖两种遗留布局（`Reports/TheReportViewer/…` 和 2012 年代的 `TheReportViewer/…`）：RestKit（编译的 `.a` 库和头文件，包括捆绑的 YAJL/JSONKit 头文件）、SBJson（`libsbjson-ios.a` 和头文件）、Salesforce Mobile SDK（`SalesforceOAuth`、`SalesforceSDK`、`APIs/salesforce`、含 SampleApps 和 Force.com xctemplate 的 `native/`）以及 Windows-Azure watoolkit（`libwatoolkitios.a` 和头文件）。第一方的 salesforce 驱动代码（`MTDatabaseSalesForce`、`NSDatabaseSalesForce`、选择器/设置视图控制器）和 `UIImageExportTypeSalesforce` 图标未被触碰 —— 它们是项目自己的作品。filter-repo 解析了 13,910 个提交；顶端 `cf74dd2a2` 未能存活 —— 新的顶端是 `d670b968d`，树与 `86b5d0630` 字节一致；没有提交变为空。备份：`~/Desktop/Reports-prescrub-apis-20261025.bundle`（已验证）。重写后的 `master` 在仓库仍为私有时被强制推送（受 lease 保护）；本地标签和安全引用被移到它们重写后的对应物（树字节一致）。
* **Karl Kraft/zlib 后续清理 —— 2026-10-25 完成，由用户直接指示。** 第四次 `git filter-repo` 清扫从整个历史中移除了最后几个第三方家族：第一方源码树里的 Karl Kraft 封装副本（`MAD/MAD/MAD/MySQL/`、`Reports/MySQL/`，以及零散的 2012 年代 `MySQL/MySQL-Prefix.pch`）和内置的 zlib（`Reports/Barcodes/libz.1.2.8.a` 和 `Reports/Barcodes/zlib.h`）。第一方的 `MTDatabaseMySql`/`MysqlFetch+DataTable`/`MTQueryMySql` 代码、`MySQLClientObjC` 和 `libdbmysql` 脚手架，以及 `ThirdParty/Licenses/zlib-LICENSE.txt` 许可证记录未被触碰。filter-repo 解析了 18,156 个提交；顶端 `ab3f1f47f` 未能存活 —— 新的顶端是 `6ef6d3664`，树与 `7b4feeb79` 字节一致；一个提交变为空。备份：`~/Desktop/Reports-prescrub-kk-zlib-20261025.bundle`（已验证）。重写后的 `master` 在仓库仍为私有时被强制推送（受 lease 保护）；本地标签和安全引用被移到它们重写后的对应物（树字节一致）。
* **zint 后续清理 —— 2026-10-25 完成，由用户直接指示。** 第五次 `git filter-repo` 清扫从整个历史中移除了内置的 zint 条码源码 —— 三种布局（`Barcodes/Barcodes/`、`Reports/Barcodes/Barcodes/`、`MADBarcodes/MADBarcodes/MADBarcodes/`）中各自的完整 zint 2.x 源码集（`2of5.c` … `zint.h` 外加捆绑的 `DEVELOPER`、`ms_stdint.h`、`sjis.h`、`maxipng.h` 垫片；52 个文件）。第一方的 `MTBarcode*`/`MADBarcode*` 类、`Barcodes-Prefix.pch` 模板头，以及 `Compressor` 的 zint recipe/patch 未被触碰（当前树中没有 zint 源码；MADBarcodes 链接 Compressor 构建的 zint）。filter-repo 解析了 18,239 个提交；顶端 `eb94fa6b5` 未能存活 —— 新的顶端是 `d3681c0ac`，树与 `49fc2ed6` 字节一致；没有提交变为空。备份：`~/Desktop/Reports-prescrub-zint-20261025.bundle`（已验证）。重写后的 `master` 在仓库仍为私有时被强制推送（受 lease 保护）；本地标签和安全引用被移到它们重写后的对应物（树字节一致）。仍只报告、未过滤（用户决定留待以后一遍）：第一方条码类旁边的第三方 `UIColor+Expanded` category 文件。
* **提示词 8（开源文档轮次）—— 2026-10-25 完成。** 用户为发布做的文档一轮清理。名称已定：项目以 **MAD (Mobile Analytics Document)** 发布（仓库 `MAD`；应用名称仍为 MAD Designer / MAD Viewer），关闭了名称备忘录的未决问题。工作文档移入 `docs/` 之下 —— 记录和设计文档在 `docs/project/`，存档的条码设计在 `docs/archive/` —— 只有面向 GitHub 的那一套留在根目录（`README.md`、`LICENSE`、`NOTICE`、`CONTRIBUTING.md`、`SECURITY.md`、`CODE_OF_CONDUCT.md`、`AGENTS.md`）。驱动编写教程从 `~/Desktop/MADOpenSource/drafts/04` 发布到 `docs/tutorials/`，TODO 愿望清单被清理，README 徽章现在指向 `mthomason/MAD` 的 `linux.yml` 工作流，加了 `.github/FUNDING.yml` 和 Support 小节，工作区的 Documents 组现在显示根文档加 `docs/` 树。每一个过时的引用 —— 链接、引述和代码注释 —— 都被重新指向，Linux 计数重新测量并达到 124 个可执行文件 / 1,270 个测试 / 7 项待办（2026-10-25）。

从提示词 3 带出的开放事项：`README.md` 中的 CI 徽章占位符（owner/repo 在发布时填写）、工作流的 `master` 触发在默认分支改名时需更新，以及运行时镜像的注册表发布（README 说它目前只在本地构建）。

---

## 18. 发布后步骤 —— 提示词 01–04

**状态：** 01、02 和 04 已完成；03 是 PR #7。提示词在 `~/Desktop/MADOpenSource-PostSteps/` 中。

* **01 —— 发布 CLI 镜像。** `.github/workflows/publish-image.yml` 在每次推送到 `master` 时推送 `ghcr.io/mthomason/mad:latest` 和 `:<short-sha>`；软件包是公开的（2026-10-26）。许可证立场见 `Linux/README.md` 的“Licences”和 `THIRD_PARTY_LICENSES.md` §9。
* **02 —— 终端演示。** CLI 演示 GIF、应用预览和导出的 London 报表在 `docs/assets/` 和 `docs.everydayapps.com` 上（PR #5，`db57127b1`）。
* **03 —— `mad-action` GitHub Action（PR #7）。** 该 action 的源码在 `satellites/mad-action/`；`.github/workflows/publish-mad-action.yml` 把它发布到 `mthomason/mad-action` 并移动 `v1`。策略和发布检查单是 `docs/project/SATELLITE_REPOS.md`。`mad` CLI 新增了 `--host`、`--port` 和 `--database`，使一个检入的文档可以指向 CI 数据库而无需被改写（`MAD_CLI.md` §3）。
* **04 —— PostgreSQL 驱动（`MADPostgres`）—— 2026-10-28 在 `postgres-driver` 上完成。**
  * **阶段 A（C 客户端库，两个平台）：** 把 PostgreSQL 17.11（`libpq` + `libpgcommon`/`libpgport`，链接 OpenSSL）钉在 `Compressor/matrix.conf`（`Compressor/lib/recipes/postgres.sh` + verify）和 `Linux/libraries.conf`（`Linux/lib/libraries.sh` 中的 `build_postgres`）中。宽松的 PostgreSQL 许可证记录在 `ThirdParty/Licenses/postgres-LICENSE.txt` 和 `docs/project/THIRD_PARTY_LICENSES.md`。
  * **阶段 B（Apple 上的 `MADPostgres` 框架）：** `MADDatabaseTypePostgres = 12`（`MADAPI`）、`+Identifier` = `@"PostgreSQL"`、`MADDatabasePostgres`、`MADDatabaseConnectionPostgres`（用 `MADDatabaseDriverRegistry` 做 `+load` 注册）、`MADPostgresConnection`（`libpq` 的薄封装）、`MADDataTypePostgres`（PostgreSQL OID 与类型名到 `MADDataType` 的映射），以及 `MADPostgresConnectionViewController`（默认端口 5432）。`public` 中的表以非限定名导入；其他非系统 schema 中的表限定为 `schema.table`，而标识符辅助方法对每个以点分隔的组件用 `"..."` 引用（内嵌的 `"` 转义为 `""`）。离线单元套件：`MADPostgresTests.m` 中 21 个测试。
  * **阶段 C（Linux 移植 + `MAD` Rptq 分派）：** `Linux/cmake/MADPostgresSources.cmake`、`<MADPostgres/libpq-fe.h>` 垫片、`Linux/CMakeLists.txt` 中 `mad` 的 whole-archive 链接条目、`MAD` 中的 `RptqDatabaseCredentals+Postgres`，以及移植的 MRC 套件 `Linux/Tests/MADPostgresTests.m`（17 个测试）。
  * **阶段 D（实时测试 + Chinook 测试容器）：** `MADPostgres/TestDatabase/postgres-test-db.sh`（`postgres:17.4-bookworm`，校验和验证的 Chinook PostgreSQL 数据集，位于 `127.0.0.1:5432`，用户 `mad`，密码 `mad_test_pw`，数据库 `chinook`）、`MADPostgresLiveTests.m`（Apple 和 Linux 上 14 个实时测试；不可达时干净跳过），以及记录在 `docs/project/DEVELOPER.md` 中的凭据。
  * **阶段 E（应用集成 + CLI）：** `MADDriverSelectorController`（第 2 行：`PostgreSQL Native Driver`，`UIImageExportTypePostgres`）、`MADQueryAddLinkJoinTypeController`（为 `MADDatabaseTypePostgres` 启用所有连接类型）、`MADOperationValidateSQL` 对 `MADDatabaseTypePostgres` 的分号剥离、Apple 和 Linux 上 `MADQueryFullTests` + `MADSQLParserTests` 的双引号覆盖，以及把 `MADPostgres` 链接进 `MAD Designer` 和 `CLI/build.sh`。
  * **阶段 F（文档与测试夹具）：** 通过 `MADFixtureMaker` 生成的 `CLI/Fixtures/Postgres.chinook.mad`、`Linux/verify-cli.sh --live` 扩展了 25 行的 PostgreSQL 刷新检查，以及 `Linux/README.md`、`CLI/Fixtures/README.md`、`docs/tutorials/driver-authoring.md`、`docs/project/LIBRARIES.md`、`docs/project/THIRD_PARTY_LICENSES.md`、`docs/project/BUGS.md` 和 `AGENTS.md` 的更新。
