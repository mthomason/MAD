[English](README.md) | **简体中文** | [日本語](README_ja.md) | [Português (Brasil)](README_pt-BR.md)

# Linux —— 无头引擎的构建

`docs/project/MAD_LINUX.md` §9：阶段 B 验证了工具链（一个从源码构建 clang + libobjc2 + GNUstep Base 并编译了 MADFoundation 子集的 Dockerfile）；阶段 C 是 §4 的垫片清单，而本目录就是它的落地之处。现在的构建会编译**全部十一个无头框架**——docs/project/MAD_LINUX.md §3 表格中的每个框架加上 `MADPostgres`，除去仅限 UI 的那些（`MADExplorer`、`MADBarcodes`、`MADFeedback`、`Scrimpter`、应用本身）——并在容器内运行它们的测试套件：126 个测试可执行文件、1,303 个测试、7 个已记录的 need。2026-10-10 合入 master 的测试覆盖（约 100 个 Xcode 测试文件）已逐套件完整移植。这里的内容不会随应用发布；CLI——阶段 D 的检查点——也在这里构建和运行（见下文“CLI 在此运行”），阶段 F 的运行时镜像则把它作为交付物来运行（见下文“运行时镜像”）。

## 运行

	./Linux/build.sh              build the image, run the tests, exit with the result
	./Linux/build.sh --test       run the tests in the existing image
	./Linux/build.sh --runtime    build the runtime image (mad-cli:latest)
	./Linux/build.sh --verify     build the runtime image, then verify the CLI in it
	./Linux/build.sh --probe      run only the toolchain probe, with its report
	./Linux/build.sh --info       print clang and gnustep-config from the image
	./Linux/build.sh --shell      interactive shell in the build image
	./Linux/build.sh --toolchain  build only the toolchain image (the cache base)
	./Linux/build.sh --rebuild    rebuild without cache
	./Linux/build.sh --clean      remove both images

Docker Desktop 的 CLI 默认不在 `PATH` 上；`build.sh` 会在 `/Applications/Docker.app/Contents/Resources/bin` 找到它，并在本次运行中把它（以及旁边的凭据助手）加入 `PATH`。首次构建需要 15–25 分钟（工具链阶段），产出约 2.5 GB 的镜像；后续运行会使用缓存——只有源码层会重新构建。`--platform linux/amd64` 交叉检查最后一次端到端运行是在合并的测试覆盖落地之后（2026-10-11，阶段 D 之前）：整个镜像在仿真下构建（amd64 工具链阶段和库来自早先的缓存；子集，包括 55 个新测试套件，重新构建），运行结果与原生 arm64 完全一致——114 个可执行文件、1098 个测试、6 个 need、10 个报告项，即当日的计数。它作为那次手工运行的记录保留；它已被 CI 构建取代，后者在 ubuntu-latest 的原生 amd64 上编译该镜像，并在每次推送到 master 时在那里运行 `--verify`——发布工作流推送的是同一平台的运行时阶段。请在其自己的标签下运行它（`MAD_LINUX_IMAGE=mad-linux:phase-b-amd64 ./Linux/build.sh --platform linux/amd64`），以免原生镜像被替换。

## 固定版本

`toolchain.conf` 是记录工具链组件版本、来源和哈希的唯一位置，形式与 `Compressor/matrix.conf` 相同；git 来源固定发布标签*和*检出的提交，GNUstep 的 tarball 带有根据 `ftp.gnustep.org` 计算出的 sha256 值。

	libobjc2      2.3      v2.3                 (github.com/gnustep/libobjc2)
	libdispatch   6.1.3    swift-6.1.3-RELEASE  (github.com/apple/swift-corelibs-libdispatch)
	gnustep-make  2.9.3    ftp.gnustep.org tarball
	gnustep-base  1.31.1   ftp.gnustep.org tarball

库组合（library-combo）为 `ng-gnu-gnu`，运行时 ABI 为 `gnustep-2.2`，因此所有内容都以 `-fobjc-runtime=gnustep-2.2` 和 ARC 编译。

## 库层

`libraries.conf` + `lib/libraries.sh` 以原生方式将框架所链接的 C 库构建到 `/usr/local`（docs/project/MAD_LINUX.md §7）。形式与意图和隔壁的 Compressor 矩阵相同；这里的内容不会随应用发布。

	sqlite3      3.53.3   the released amalgamation; the option list still comes
	                      from Compressor/sqlite3.xcconfig, the one place it lives
	openssl      3.5.9    static, before freetds
	freetds      1.4.27   --enable-msdblib, apps/server/pool/odbc off, and the
	                      recipe's sybdb.h BOOL edit (spelled for GNU sed)
	zlib         1.3.2
	bzip2        1.0.8    CC=clang: its Makefile hardcodes gcc
	libarchive   3.8.9    the .mad container's tar/bzip2 path
	mariadb      3.4.11   the mariadbclient static target, openssl + external
	                       zlib, auth plugins static, others off (mirrors
	                       Compressor/lib/recipes/mariadb.sh)
	postgres     17.11    the libpq static client library + libpgcommon/libpgport,
	                       with openssl, without readline/icu/gssapi/ldap/pam/xml/
	                       xslt/lz4/zstd/zlib (mirrors Compressor/lib/recipes/postgres.sh)

有两个外部构建依赖从已退役的 mysqlclient 构建中保留下来（`libncurses-dev` 和 `libtirpc-dev`，mysql 的 cmake 需要它们）；mariadb 构建不使用它们，但它们仍留在镜像中。

## 编译什么，不编译什么

| 框架 | Linux 构建 | 排除项及原因 |
|---|---|---|
| MADFoundation | 27 个中的 26 个 | `MADKeyChain`（Security.framework；§4——刷新路径从不读取钥匙串）。总头文件（umbrella）也随之排除 |
| MADDataStructures | 全部 17 个 | （Xcode 目标的文件；`madmap.cpp` 也不在其中） |
| MADFileManager | 11 个中的 10 个 | `MADCloudFileCoordinator`（NSMetadataQuery；§4——iCloud 在阶段 D 中消亡） |
| MADCocoaExtensions | 17 个中的 7 个 | 十个 UIKit 绘制器/呈现器（颜色、标签、文本字段、警告框、视图辅助工具、错误呈现器、MessageUI） |
| MADAPI | 11 个中的 8 个 | 三个连接视图控制器（§3：非无头） |
| MADSqlite3 | 全部 26 个 | （五个孤立的 `.m` 文件也不在 Xcode 目标中） |
| MADTds | 全部 1 个 | |
| MADTdsClient | 5 个中的 4 个 | 其连接视图控制器 |
| MADMySQL | 19 个中的 18 个 | 其连接视图控制器 |
| MADPostgres | 6 个中的 5 个 | 其连接视图控制器 |
| MAD | 181 个中的 150 个 | UI 尾部（§5.2）、`MADocument` 及其构建/关闭一个文档的操作（属于阶段 D）、钥匙串操作、由 MADBarcodes 支持的元素文件。每一项都在 `cmake/MADSources.cmake` 中列出名称 |

每个框架的源文件列表是构建旁边的一个 `cmake/<Name>Sources.cmake`，其中列出被排除的文件及其原因——形式与 `MADFoundationSources.cmake` 相同。`MADExplorer`、`MADBarcodes`、`MADFeedback` 和 `Scrimpter` 完全不在 Linux 构建中（docs/project/MAD_LINUX.md §3）。

Linux 构建在不改动框架源码的前提下提供 GNUstep 所缺的功能：

* 每个框架一个 include 垫片，使 `<Framework/…>` 自导入得以解析（MAD 的是一个符号链接目录，因为 Xcode 目标将其头文件压平为 `<MAD/Foo.h>`），外加四个库头文件垫片（`<MADSqlite3/sqlite3.h>`、`<MADTds/sybdb.h>`、MADTdsClient 总头文件、`<MADPostgres/libpq-fe.h>`）；
* 一个前导头文件（`Compat/MADCompat.h`），承载那些以宏或 typedef 形式出现的平台缺失（见下面的列表）；
* 整档链接（whole-archive linking），即 Apple 的 `-ObjC`，缺少它时框架的 category 会从静态归档中被静默丢弃；
* 一个 category 编译进 `libmad.a`（`Linux/CMakeLists.txt` 中的 `target_sources`）：MADQuery+Sqlite3 的 `-whereClauseWithRowIds:` / `-whereClauseWithParameters:` 通过消息发送访问，因此链接器会丢弃该归档成员，而对 `libmadsqlite3.a` 进行整档链接会重复每个框架归档中已嵌入的 compat 对象；
* 链接行上 `-lgnustep-base` 位于 `-lobjc` 之前：libobjc2 导出一个会中止的弱符号 `objc_enumerationMutation()`，而 GNUstep Base 导出会抛出异常的真实版本，链接行上排在最前的库胜出。

框架本身新增了一些小的平台防护，全部是 `#if __APPLE__`，因此 Apple 路径在文本上保持不变。macOS 测试套件证明了它们是行为中性的：MADFoundation、MADDataStructures、MADFileManager、MADCocoaExtensions、MADAPI、MADSqlite3、MADMySQL、MADTdsClient、MADPostgres 和 MAD 在模拟器上全部通过，且 `MAD Designer` 工作区可以构建。

## 驱动是注册的，而非导入的

构造函数过去会导入驱动，这就是 `MAD` ↔ 驱动的循环依赖（`docs/project/ROADMAP.md` §5.1）。`MADDatabaseDriverRegistry`（`MADAPI`）现在是接缝：每个驱动的连接类都遵循 `MADDatabaseDriver` 并在 `+load` 中注册自身，而 `MADDatabase+Constructor` / `MADDatabaseConnection+Constructor` 按 `MADDatabaseType` 查找驱动，而不是指名某一个。因此，一个进程拥有哪些驱动，取决于它*链接*了什么。

在 Apple 上，宿主链接驱动框架——应用和 CLI 指名 MADMySQL、MADTdsClient 和 MADPostgres，而 `MAD.framework` 不再指名它们，因此它的测试捆绑包也指名它们。在 Linux 上，驱动归档从 `mad` 目标进行**整档链接**（`$<LINK_LIBRARY:WHOLE_ARCHIVE,…>`，它会传播到每个使用方）：静态归档是被搜索的，不是被加载的，因此没有任何引用的成员——驱动的 `+load` 或某个 category——否则会被丢弃。这不是可有可无的细节；正是它在修复之前让通过 MySQL 的 `mad refresh` 中止（见下面关于 category 的一节）。`MADDatabaseDriverDispatchTests` 固定了注册表，`Linux/Tests/MADHeadlessDocumentTests.m` 驱动整条链。

添加一个驱动只需在 `Linux/CMakeLists.txt` 中增加一个链接条目，`MAD` 中无需任何改动。

## compat 垫片自成一个归档——以及原因

过去每个框架归档都嵌入 `Compat/*.m`。这使得把其中两个进行整档链接会出现重复符号错误，正因如此，恰好有一个 category（`MADQuery+Sqlite3`）是手工编译进 `libmad.a` 的。CLI 暴露了这种安排的成本：针对实时 MySQL 的 `mad refresh` 会**中止**（SIGABRT，无诊断信息），因为 `MADMySQLFetch (DataTable)`——执行预编译语句的方法——是一个通过消息发送访问的 category，链接器从未把它的目标文件拉进来。`nm` 显示 `.objc_category_MADMySQLFetchDataTable` 存在于 MySQL 测试二进制中，而在 CLI 的二进制中缺失。

`madcompat` 现在是一个独立的静态库，由每个可执行文件整档链接（`mad_add_test`、`ToolchainProbe`、`mad-cli`），框架归档则是纯净的，因此驱动归档可以像任何其他代码一样整档链接。按文件设置 `target_sources` 的权宜做法已经消失。由此留下的一般规则是：**框架归档只有经过整档链接才可安全链接**；否则其 category 在运行时会静默缺失。

## 探针和测试发现的 GNUstep 差异

* **NSOperationQueue 与 KVO——在此发现，已在 MADOperation 中修复。** GNUstep 的 `NSOperationQueue` 在收到的每个通知上都会移除其 `"isReady"` 观察，并且在注册该观察之后还会再检查一次 `isReady`。MADOperation 过去从 `-isReady` 内部推进其状态机（通过 `state` 的 KVO 依赖键），因此第一次就绪检查触发了队列正在等待的通知，第二次调用随后移除了一个已经不存在的观察——`NSInvalidArgumentException`，操作从未运行。MADOperation 现在显式驱动推进（`-willEnqueue` 启动条件求值），并且仅在 `isReady`、`isExecuting` 和 `isFinished` 各自的值真正变化时才为它们发送 `will`/`didChangeValueForKey:`，因此队列每次入队只看到一个 `isReady` 通知，与 Apple 的行为相同。Linux 测试在两个平台上直接断言这一点；没有任何东西被静默，阶段 D 的刷新路径也不再被它阻塞。
* **缺少安全编码（secure-coding）归档。** `archivedDataWithRootObject: requiringSecureCoding:YES` 返回 nil 且无错误，因此必须在 Apple 之外工作的代码路径——MADArrayCaching 的 `.madac` 渲染缓存、MADDataTableFast 的分组键集合、MADFileUtilities 的归档——在 `#if __APPLE__` 下回退到 `requiringSecureCoding:NO`，即同一个编码器但不带加固。解档一侧不需要回退：`unarchivedObjectOfClass:fromData:error:` 及其复数形式在 GNUstep 上确实可用（2026-10-06 实测——探针早前的报告称它和 `+unarchiveTopLevelObjectWithData:error:` 都不存在，那来自一个 nil 严格归档从未到达的分支，因此只有后者是真的）。后者确实不存在，并在 `Compat/` 中通过 `+unarchiveObjectWithData:` 打垫片。
* **`-localizedCaseInsensitiveCompare:` 在 GNUstep 上区分大小写**——不再起关键作用（2026-10-25 修复）。MADDatabaseSqlite3 注册的 SQLite 排序规则（`compare_string_utf8_localized_asc_collation`）、内存排序选择器以及报表格式器的字符串比较器都统一经过一个第一方定义的顺序（`NSString+Comparison.h`：先进行大小写折叠，再按 UTF-8 码点顺序），因此本地化比较造成的差异已经消除，而不是被掩盖；测试在两个平台上断言相同的定义顺序。参见 `docs/project/MAD_CLI.md` 的 `mad export` 一节。
* **BOOL 的运行时编码，以及 `class_getProperty` 的继承——由 MAD 的 rptq 套件发现，已在 RptqObject 中修复。** 运行时会比较已安装访问器的类型编码与编译调用点的类型编码，而 BOOL 在 GNUstep 上是 `unsigned char`（`'C'`），Apple 则使用 `signed char`（`'c'`），因此 `RptqObject` 动态安装的 bool 访问器现在注册按平台区分的编码（`MAD_RPTQ_BOOL_TYPE`）。另外，GNUstep 的 `class_getProperty()` 只查看类本身，而 Apple 的会沿超类链查找——因此一个继承的属性（标签的 `alignment`）落入了通用对象分支；`RptqPropertyNamed` 在两个平台上都执行这一查找。失败模式是静默的错误值而非崩溃，因此两者都由移植的套件固定。
* **GNUstep 的文件 API 拒绝无 scheme 的 URL——由 MADFileManager 移植的测试发现，已在 MADURLFactory 中修复。** `-contentsOfDirectoryAtURL:` 和 `-writeToURL:` 对不带 `file://` scheme 的 URL 会静默地什么都不做（2026-10-11 实测），而 `+newURLForLocalDocumentsDirectory` 曾用 `-initWithString:` 从路径构建 URL——Apple 容忍这种做法。它现在使用 `+fileURLWithPath:`，这是两个平台上都诚实的答案；这一修复加上下面的协调器垫片，将五个搁置的 need 变成了五个通过的测试（`MADLocalFileCoordinatorTests`，12 个测试，0 个 need）。
* **dispatch 对象是纯 C 指针**（`os/object.h` 在 Darwin 之外不支持 ObjC，并直接拒绝 `OS_OBJECT_USE_OBJC=1`——libdispatch 构建的注释如此说明），因此 ARC 无法持有它们：在 Apple 之外，每个 `strong`/`copy` 的 dispatch 属性都是 `assign`，并在原处添加了注释。队列创建一次，存活于整个进程；没有任何东西释放它们。
* **较小的缺失，已打垫片或已加防护：** `NSOperation.name`、`NSOperation.cancelled` 和 `NSOperation.asynchronous`（GNUstep 只保留旧的 `-isConcurrent` 拼写，作为一个总是回答 NO 的桩——它自己的簿记会查询它，而如果没有 Compat category 回答 `[self isAsynchronous]`，一个正在结束的异步操作会从 `-dealloc` 中抛出）、NSFileManager 的 ubiquity 方法（Apple 之外没有 iCloud；每个答案都是空答案）、NSFileCoordinator 上的 `-initWithFilePresenter:`、`-coordinateAccessWithIntents:queue:byAccessor:`（GNUstep 的实现在运行访问器时会故障——SIGSEGV，已实测；Compat category 在给定队列上调用访问器，因为在 Apple 之外没有什么可协调的）、NSURL 的安全作用域访问和 `-fileSystemRepresentation`、NSData 的 `-options:error:` 读取方法及其常量、NSCoder 上的 `-decodeTopLevelObjectOfClasses:forKey:error:`、NSUndoManager 上的 `-registerUndoWithTarget:handler:`、`+propertyListWithStream:options:format:error:`（一个返回 nil 的桩，流从未被读取——Compat category 读取该流并转交给 `+propertyListWithData:`；有了它，MADDataTable 的 `-loadFromCacheWithUrl:` 可在 Linux 上运行，并在两个平台上都有断言）、NSValue 的 `CG*Value` 拼写、`CF_ENUM`/`CFAvailability` 宏、CFNumber 提取调用（一个 compat 的 `CoreFoundation/CFNumber.h`）、POSIX 中的 `copyfile(3)`、`htonll`、MacTypes 标量（`Float64`、`SInt32`…`UInt64`、`Boolean`）、`NS_RETURNS_INNER_POINTER`、`__nullable` 拼写、`NSOperation.qualityOfService`、`NSDataWritingFileProtection*`、`containerURLForSecurityApplicationGroupIdentifier:`（缺失——这就是 MADURLFactory 的组路径回退到每用户目录的原因）、来自 `<sys/qos.h>` 的 `QOS_CLASS_DEFAULT`（缺失）。
* **已验证良好：** ARC 与弱引用清零、block、异常、`@synchronized`、KVO（手动和依赖键）、`NSOperation` 状态机 KVO、`NSPredicate predicateWithFormat:@"error != nil"`（MAD 的确切谓词）、dispatch（once/队列/组/信号量）、普通可执行文件下的主队列排空、JSON、UUID、日期、plist、排序描述符、流、NSDecimalNumber、NSCalendar，以及宽松路径上的键控归档。完整报告就是 `--probe` 打印的内容；其中 19 项核心检查决定退出码，12 个报告项不决定（CLI 的运行增加了 `directory-enumeration` 和 `directory-enumeration-url-form`）。

**货币格式化（2026-10-16 发现，2026-10-17 修复）。**  GNUstep 的两种行为使渲染出的金额与 Apple 不同：`NSNumberFormatterCurrencyStyle` 对任何区域设置都不渲染小数位（`en_US` 得到 `$1`，Apple 得到 `$0.99`），而镜像的当前区域设置是 `en_US_POSIX`，其货币符号后有一个空格且没有分组。两者都在不替换格式化器的前提下得到解决：报表从文档的数字格式中获取其区域设置和小数位数（回退是 `en_US`，而不是机器的区域设置），货币符号则显式写出，并对日元符号进行规范化（GNUstep 将其拼写为全角 U+FFE5）。一个 60 用例的比较——六个区域设置乘以十个值，包括负数和 1e12——现在在两个平台之间逐字节一致；它找到的唯一差异就是那个日元码点。`docs/project/BUGS.md` 有该条目（已归档：已修复），下面渲染侧的导出均固定为 Mac 的字节。

## need 的数量，以及为什么是 6

阶段 B 的镜像报告了 3 个 need；完成的阶段 C 镜像报告 6 个，而新增的三个都来自 MAD 的测试套件落在仅限 Apple 的机制上。它们被刻意设计为 need 而非跳过：该检查在没有 Linux 所缺资源的情况下无法运行，need 会明确说出这一点，而跳过则会加以掩盖。

* **原本就存在的三个。** 工具链探针的严格归档检查（`requiringSecureCoding:YES` 返回 nil，见上文）及其应用组检查（`containerURLForSecurityApplicationGroupIdentifier:` 缺失），加上 MADCredentialTests 针对同一严格归档缺失的条件性 need。
* **MADStoreTests**——模型保真度检查需要 Core Data 和编译后的 `MAD.momd`，两者都仅限 Apple。
* **RptqStoreContextTests，两次**——转换后示例的测试夹具需要 `MADStoreConverter`、Core Data 和 `London.mad`，而文档路径需要 `MADocument` 和 `MADStoreConverter`（由阶段 D 解决）。

实时数据库测试套件在没有可到达的服务器时会跳过（从不失败）——与 Xcode 方案相同的约定——SQLite 基准测试在默认规模下跳过；跳过会单独计数，不算作 need。

## 实时数据库套件在此运行

`MADMySQLLiveTests`、`MADTdsClientLiveTests` 和 `MADPostgresLiveTests` 与真实服务器通信，在没有可到达的服务器时会跳过（从不失败）——与 Xcode 方案相同的约定。这些服务器就是 `docs/project/DEVELOPER.md` 记录的三个容器；请先启动它们：

	MADMySQL/TestDatabase/mysql-test-db.sh up          # mad-mysql on :13306
	MADTdsClient/TestDatabase/sqlserver-test-db.sh up  # mad-mssql on :1433
	MADPostgres/TestDatabase/postgres-test-db.sh up    # mad-postgres on :5432

	docker run --rm \
		-e MAD_MYSQL_TEST_HOST=host.docker.internal \
		-e MAD_MYSQL_TEST_PORT=13306 \
		-e MAD_TDS_TEST_HOST=host.docker.internal \
		-e MAD_PG_TEST_HOST=host.docker.internal \
		--entrypoint bash mad-linux:phase-b -c \
		'/src/Linux/build/MADMySQLLiveTests && /src/Linux/build/MADTdsClientLiveTests && /src/Linux/build/MADPostgresLiveTests'

2026-10-17 在该干净环境下测得：MySQL 44/44、311 项检查（预编译语句、类型转换、架构发现），SQL Server 29/29、169 项检查（freetds 线路路径、日期/时间解析、decimal/blob/nvarchar、架构发现）；PostgreSQL 14/14、132 项检查（2026-10-27 实测：libpq 提取、OID 类型转换、跨 public 和非 public 架构的架构发现）——因此三个驱动都能在 Linux 上工作，而不只是能编译。`MADTdsClientTests` 的两个连接失败测试无需服务器即可运行。

## 许可证

镜像中的所有内容都是构建工具；没有任何内容链接进应用。libobjc2 是 MIT；libdispatch 是 Apache-2.0 并带有 Swift 运行时例外；GNUstep Base 是 LGPL-2.1-or-later；gnustep-make 是 GPL-3.0-or-later，其 `Testing.h`（GPL-3.0-or-later）被编译进 Linux 测试二进制——这些二进制只存在于本构建镜像内。C 库带有各自的许可证（docs/project/THIRD_PARTY_LICENSES.md）；mysqlclient 的 GPL 问题已经解决——D1 改为 MariaDB Connector/C（LGPL-2.0-or-later，选用 LGPL-3.0），本镜像构建它（`docs/project/TASKS.md` §10）。运行时镜像以 `ghcr.io/mthomason/mad` 发布，因此它分发的 LGPL 组件需要重链接要约：`ThirdParty/Licenses/README.md` 中的书面要约现在写明了该镜像，登记条目是 `THIRD_PARTY_LICENSES.md` §9。gnustep-make 是构建工具，不在运行时镜像中。

## CLI 在此运行——阶段 D

`mad` 由本 CMakeLists 从 `CLI/Source` 构建（与 `CLI/build.sh` 为 iOS 模拟器构建的源码相同），整档链接十一个框架，并在镜像中运行：

	/build/mad inspect <document.mad>
	/build/mad schema  <document.mad>
	/build/mad query   <document.mad>
	/build/mad refresh --credentials user:pass <document.mad>

`export` 是唯一不在此处的动词：PDF 是由 `UIPrintPageRenderer` 绘制的 Core Graphics 上下文，因此它留在 Apple 上，并会说明这一点（`docs/project/MAD_LINUX.md` §5.2；渲染器决策属于阶段 E）。

**`export` 在这里增加了它的 Foundation 格式（阶段 E，2026-10-16）。** 导出接缝（`MADReportExporting` + `MADReportExporterRegistry`，`docs/project/MAD_CLI.md` §5.3）位于 `mad` 中，因此 `text`、`csv` 和 `json` 在镜像中运行，并写出与 Mac 工具相同的字节（渲染侧格式——`html`、`html-flow`、`json-report`——也在这里运行；见下面一节，`pdf` 则说明它为什么不能运行）。为留档而在 London 测试夹具（`CLI/Fixtures/London.portable.mad`，先刷新，两侧均做 `sha256sum`）上运行的比较：

| 格式 | 字节 | sha256（两个平台一致） |
|---|---|---|
| `json` | 64595 | `569c6ee25223c51ecffd15923dd897e75c8362d72f4ece72f8dbeee3e9c8cdbc` |
| `csv` | 12538 | `773f6215a5447f72d499282d337a5916b11f0f3b06cb4c5aec134db6f493cb21` |
| `text` | 40441 | `7dcee96c45951fac0e0057094a6a142c90a88d6d88a1c03278b273f5140c6e49` |

`Linux/Tests/MADReportExporterTests.m` 是同一检查的测试形式：它刷新测试夹具，并针对 Mac 的字节断言每个导出的 FNV-1a 校验和（外加形状和少量值），因此在 GNUstep 与 Apple 之间漂移的拼写会在这里失败——而且现在 Mac 一侧也固定了相同的 FNV-1a 校验和（`MAD/MADTests/MADReportExporterTests.m`），所以漂移在两个平台上都无法静默。`json-report` 是相同的架构，以渲染后的报表作为一个额外成员；它需要渲染那一半（`MADReportFormatter` 和页面渲染器），自阶段 E 起可在此编译——下面一节载有它的摘要，只有 `pdf` 会注册并说明它为什么不能运行（`docs/project/MAD_CLI.md` §3）；`Linux/Tests/MADReportExporterTests.m` 断言它会失败，而不是静默地只写出数据那一半。

**文档类是如何确定的。** `MADocument` 是一个 `UIDocument`，因此无法一同移植，而 `MADCLIDocument` 过去构建在它之上。文档的数据那一半现在是一个协议——`MADDocumentDataProtocol`——`MADocument` 遵循它（行为不变；每个成员本来就已是它的某个访问器），`MADHeadlessDocument` 实现它：它用 `MADDocumentStore` 打开容器和可移植存储（与 MADocument 使用的存储布局相同，因此两者不可能不一致）、编译查询、通过注册表构建由驱动支持的数据库，并持有行表。刷新链接受该协议，因此 Apple 和 Linux 运行*相同*的 `MADOperationRefresh`——只有它的一个渲染侧分支（报表格式器和节区布局管理器）是 `#if __APPLE__`。用户在 2026-10-16 选择了这种形态，而非 Compat 中的 `UIDocument` 垫片，也非拆分 `MADocument` 本身。

**检查点，从镜像内部观察**（Docker Desktop；文档位于 `CLI/Fixtures/`，其主机名 `mac` 在这里解析为这台 Mac）：

| 运行 | 结果 |
|---|---|
| 对 `London.mad` 运行 `mad inspect`（旧式示例） | v0，6 个成员，报告 store + WAL + SHM |
| 对 `London.portable.mad` 运行 `mad inspect` | v1，4 个成员，`StoreContent/store.sqlite (portable)`，41 个节区 / 25 个元素 |
| 对两个可移植测试夹具运行 `mad schema` | 与 Mac 的输出逐字节相同 |
| 对同样两个夹具运行 `mad query` | 与 Mac 相同的字段集；*顺序*不同（见下文） |
| 对 `London.portable.mad` 运行 `mad refresh` | 76 行，行缓存与 Mac 的相同（按名称 21 列、76 行，每个值都相等） |
| 对 `MySQL.employees.mad` 运行 `mad refresh --rows 50 --credentials root:root` | 50 行，来自实时 MySQL 8.4（预编译语句提取，数据库 `employees`） |
| 对 `TDS.AdventureWorksLT2022.mad` 运行 `mad refresh --rows 20 --credentials sa:Root1@Root2` | 20 行，来自实时 SQL Server 2022（freetds，`AdventureWorksLT2022`） |
| 对 `Postgres.chinook.mad` 运行 `mad refresh --rows 25 --credentials mad:mad_test_pw` | 25 行，来自实时 PostgreSQL 17（libpq，`chinook`） |

实时套件的结果一致：来自同一镜像的 `MADMySQLLiveTests` 44/44、`MADTdsClientLiveTests` 29/29 和 `MADPostgresLiveTests` 14/14。`Linux/Tests/MADHeadlessDocumentTests.m` 是同一检查点的测试形式——打开、架构、查询、驱动解析、刷新、76 行——因此它会在 CI 中失败，而不是在手工运行中失败。

**两个值得了解的差异，都在这里发现。** SELECT 列表的列顺序曾是*集合*顺序（`MADQueryActiveQueryFields` 累积到一个 `NSSet` 中），因此同一文档在 Apple 和 GNUstep 上产生不同的顺序——相同的字段，不同的顺序；一旦按字段名比较，缓存的*数据*是相同的，而缓存的 `c<hash>` 列名由哈希派生，因此每个平台也不同。**2026-10-16 已解决（JSON 导出形状决策，`docs/project/MAD_LINUX.md` §10.1）：** 现在两个 SQL 构建器都将顺序定义为按 `-compare:` 排序的列别名，因此生成的 SQL、行缓存和每个导出在两个平台上都一致（docs/project/BUGS.md 的 SELECT 列表条目；顺序测试在 `Linux/Tests/MADQuerySelectExpressionTests.m`）。在该变更之前刷新的缓存，其列顺序与之后刷新的缓存不同——相同的数据，新的顺序——因此在跨该日期比较缓存之前先刷新一次。

## 写入器在此运行，两个平台结果一致

阶段 E 的另一半（`docs/project/MAD_LINUX.md` §9；用户的要求，2026-10-16）：`.mad` 写入器在 Linux 上工作，并对同一文档产出与 Mac 的**相同字节**。  `mad write <doc.mad> --out <copy.mad> [--reproducible]` 是其命令行接口，文档在两个平台上都以无头方式打开，因此两侧运行同一个写入器。

在 London 测试夹具（`CLI/Fixtures/London.portable.mad`）上测得：

	$ mad write London.portable.mad --out copy.mad --reproducible
	16261 bytes, sha256 09815b24e91e03b6e526008f7c2700074fed10679771b9e1ee4609e54a1192f5
	                                     (identical on the Mac and in this image)

该测试夹具是版本 1 的存储，而写入会先打开文档，因此打开的副本在两个平台上都带有存储迁移（SQL 输入阶段 A：`sqlSourceText` 列和 `user_version` 2）；上面的字节是迁移后文档的字节。

`--reproducible` 固定 uid/gid 0、固定时间 2001-01-12T00:00:00Z 以及排序的成员遍历；普通写入保留成员的真实元数据，因此按设计会在不同次运行和不同平台之间不同。

为了让写入器在此运行，必须修复两件事，均记录在 `docs/project/BUGS.md`（`.mad` 字节一致性条目）中：

* `-write_archive:` 遍历每个枚举到的 URL *直到*归档目录为止，而 GNUstep 的 `-enumeratorAtURL:` 会剥离包含目录，因此循环从未到达。现在改用 `-subpathsAtPath:` 读取成员，CLI 的成员列表本来就是这样做的。
* `backup_file` 将其路径交给 `dirname(3)`/`basename(3)`，glibc 被允许修改该缓冲区而且确实修改了：调用者的归档路径在最后一个斜杠处被截断，因此合成后的文档被写到了它自己的目录上（`Open (…) failed - Is a directory`）。Apple 的实现不改动该缓冲区，这就是为什么只有 Linux 遇到了这个问题。

`Linux/Tests/MADArchiveManagerTests.m` 是相应的覆盖（5 个测试，0 个 need）：往返（`docs/project/MAD_CLI.md` §6.1）、普通模式的特性刻画、可复现模式——包括对整个文档相对 Mac 字节的 FNV-1a 校验和——以及文档路径，它写出一份副本并保持源文件不变。

## 渲染那一半和 HTML 格式在此运行

阶段 E 的第二个决策（用户的决策，2026-10-16）是先做 HTML、最后做 PDF，而 HTML 这一步正是渲染那一半离开 Apple 的地方。它以遵循协议的方式迁移：

* `MADReportFormatter` 接受 `id <MADDocumentRenderProtocol>`；`MADHeadlessDocument` 遵循该协议，而 `MADOperationRefreshInitialize` 的渲染分支以该协议为依据。
* `MADReportPageBuilder` 是页面遍历，从 `MADPrintPageRenderer` 中拆出（后者保留 `UIPrintPageRenderer` 和绘制）。它拥有渲染侧的几何（US Letter、1pt 的裁切）和准备顺序，因此 PDF、json-report 和 HTML 格式不可能对页面产生分歧。
* `MADDocumentRenderDataSource` 是渲染侧读取的唯一实现，由 `MADocument` 和 `MADHeadlessDocument` 共享；`MADPrintPageElement` 系列在此编译（其初始化器属于 Foundation；只有绘制是 Apple 的）。

`mad export` 现在在这里有 `html`、`html-flow` 和 `json-report`，而 `pdf` 会注册并说明它为什么不能运行（其主体是 Core Graphics）。  在 London 测试夹具上与 Mac 对比测得：

| 格式 | 字节 | sha256（两个平台一致） |
|---|---|---|
| `json-report` | 118,109 | `9d01d0daabbb5e38921c0bfbed083b288031c9340e9a4af81679d03b691ce94c` |
| `html` | 62,007 | `285541ed59333e0e55b8c7fe5619e4b64dde7aaf8e93a24ba881b40111ab2327` |
| `html-flow` | 54,766 | `0565204a55d02f925602b5c0bf298bb0e41c9cbe56bea6df770e828a35782382` |
| `pdf` | — | 在此未生成；`+isAvailable` 为 NO 并给出原因 |

渲染侧格式在各平台之间逐字节一致，与数据格式一样：每个 frame、字体、字号、特性、对齐、文本段和页面框，以及金额（使它们产生差异的发现及其修复见上文和 `docs/project/BUGS.md`）。`Linux/Tests/MADReportExporterTests.m` 固定了这三个校验和。

## 运行时镜像——CLI 交付物（阶段 F）

阶段 F 的交付物是一个运行 CLI 的容器，而不是一棵开发者必须记住其路径的构建树。`./Linux/build.sh --runtime` 从同一个 Dockerfile 构建它（`runtime` 阶段，位于 `build` 下游），标记为 `mad-cli:latest`：

	docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro mad-cli:latest \
		mad inspect /docs/London.portable.mad

该镜像（2026-10-26）以 `ghcr.io/mthomason/mad` 发布，标记为 `latest` 和该提交的短 SHA。已发布的标签由 CI（`.github/workflows/publish-image.yml`）在 ubuntu-latest 上构建，因此它们是 **linux/amd64**——Mac 本地的 `mad-cli:latest` 构建是 arm64。拉取而不是构建是十秒钟的路线；在 Apple silicon 上请添加 `--platform linux/amd64`（Docker Desktop 在仿真下运行该标签——不加此标志，拉取会以 `no matching manifest` 失败）：

	docker run --rm --platform linux/amd64 -v "$PWD/CLI/Fixtures":/docs:ro \
		ghcr.io/mthomason/mad mad inspect /docs/London.portable.mad

分发该镜像有义务为其中的 LGPL 组件（GNUstep Base，以及静态链接进 `mad` 的 mariadb 和 freetds）提供重链接要约；`ThirdParty/Licenses/README.md` 中的书面要约写明了该镜像（见上文“许可证”一节）。

镜像包含：

* `/usr/local/bin/mad`，CMake 安装规则的稳定路径（该二进制不再只能通过 `Linux/build/mad` 访问）；
* 该二进制所链接的共享对象——GNUstep Base、libobjc2、libdispatch 和 libBlocksRuntime——加上 GNUstep 的运行时目录和配置。其他 C 库（sqlite3、freetds、openssl、zlib、bzip2、libarchive、mariadb、postgres）是静态的，已经在二进制内部；
* 没有任何 mysqlclient 的 share 数据：Connector/C 内嵌其客户端错误消息，不安装 `share/` 文件；
* 位于 `/root/GNUstep/Library/ApplicationSupport/` 的 `chinook.sqlite3`，Sqlite3 文档的裸数据库名在此解析。文档存储的是名称而不是路径，因此正是这一个文件让已检入的 London 和 Music 测试夹具无需额外设置即可刷新。

它不携带编译器、cmake、git、源码、126 个测试二进制以及静态归档和头文件：最终阶段是 `ubuntu:24.04` 加上通过 apt 获取的运行时库，而不是工具链镜像。它在磁盘上**占 283 MB（压缩后 66.5 MB）**；构建镜像是 6.65 GB。

每个动词都以相同方式运行：

	docker run --rm -v "$PWD/docs":/docs mad-cli:latest mad schema /docs/x.mad
	docker run --rm -v "$PWD/docs":/docs -v "$PWD/out":/out mad-cli:latest \
		mad export /docs/x.mad --format html --out /out/x.html
	docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro mad-cli:latest \
		mad refresh /docs/MySQL.employees.mad --credentials root:root --rows 50

实时测试夹具将服务器命名为 `mac`（`CLI/Fixtures/README.md`）；从容器中，该名称会通过 Docker Desktop 解析到这台 Mac。刷新缓存写入容器内的 `/root/GNUstep/Library/Caches`，因此不会在 `--rm` 之后保留；`export` 会刷新文档本身，所以这不是问题。如果缓存需要在多次运行之间持久保留，请添加数据卷。镜像以 root 运行；以 `--user` 运行时，需要将示例数据库（以及任何文档）放在该用户自己的 Application Support 目录中。

**`--verify` 是可重复的检查。** 它会重新构建运行时镜像，并在其中以只读方式挂载仓库来运行 `Linux/verify-cli.sh`：六个动词、每个导出格式对照其固定摘要、`pdf` 的拒绝、`--reproducible` 写入器的字节、退出码，以及镜像自身的形态（没有 clang、cmake、git 或构建树）。共 41 项检查；任何失败都会使其以非零状态退出。

	./Linux/build.sh --verify
	...
	MADVERIFY 41 passed, 0 failed

`--live` 会增加 MySQL、TDS 和 PostgreSQL 的刷新（分别为 50、20 和 25 行）；请先启动三个测试容器（`docs/project/DEVELOPER.md` 中有它们的脚本和登录信息）：

	MADMySQL/TestDatabase/mysql-test-db.sh up
	MADTdsClient/TestDatabase/sqlserver-test-db.sh up
	MADPostgres/TestDatabase/postgres-test-db.sh up
	docker run --rm -v "$PWD":/repo:ro mad-cli:latest \
		bash /repo/Linux/verify-cli.sh --live

**已由 CI 发布（2026-10-26，推翻了 2026-10-17 的决定）。** `.github/workflows/publish-image.yml` 在每次推送到 master 时将运行时阶段推送到 `ghcr.io/mthomason/mad`，标记为 `latest` 和 `<short-sha>`，此外还可以从 Actions 选项卡手动触发（`workflow_dispatch`）；本地 `./Linux/build.sh --runtime` 构建保持不变。已发布的标签是 CI 构建的 amd64；Mac 的本地构建是 arm64。

**一个 Dockerfile 陷阱，记录下来是因为它曾让第一次构建出过问题。** 运行时阶段是 Dockerfile 的最后一个阶段，因此不带 `--target` 的 `docker build` 现在会产出运行时镜像。`build.sh` 为构建镜像传递 `--target build`，为工具链缓存传递 `--target toolchain`；手工运行构建时也应照此处理。

## 尚未完成的事项

Linux PDF 写入器——**2026-10-17 推迟，取决于用户的研究；未经其决定不要启动。**  `docs/project/MAD_PDF_LINUX.md` 是交接文件（已有什么、缺少什么、带许可证的候选技术栈、未决问题、验收测试）；`docs/project/MAD_LINUX.md` §10.2 记录了理由。  在它落地之前，Linux 上的 PDF 就是用浏览器打印 `--format html`。

截至 2026-10-17，阶段 F 的其他部分：**运行时镜像**及其**可重复验证**已完成（见上面一节），而 **CI 这一行因用户的决定被删除**——不使用 GitHub Actions，因为 Linux 移植是用于测试的概念验证，而不是产品发布。2026-10-26 的 GHCR 发布改变了这一点：镜像已发布，`publish-image.yml` 构建并推送它（见上面一节）。**Compressor Linux 驱动**尚未完成，CLI 也不需要它：镜像已经以原生方式构建 C 库（`libraries.conf` + `lib/libraries.sh`）。  启动之前请先询问。
