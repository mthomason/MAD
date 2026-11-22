---
layout: default
title: "在 Windows 上构建引擎"
description: "锁定版本的 Clang 与 GNUstep 工具链，以及原生 Windows 引擎构建。"
lang: zh-CN
---

# 在 Windows 上编译 MAD 引擎——架构与决策记录

本页记录 Windows 引擎构建：锁定版本的工具链、框架移植及其 shim，以及 `Windows/Engine/build.ps1` 入口点。应用指南位于 `/windows.html`。

*撰写于原定日期；当前状态事实已于 2026-11-22 核实。*

撰写于 2026-11-18，针对 `windows-engine` 分支的 `master`（Windows PoC 的 Phase 2）。
Windows 构建是 `Linux/` 的兄弟：无头引擎的 Objective-C 框架在
Windows 上以 Clang 针对 GNUstep Base 原生编译，使运行 macOS
应用和 Linux CLI 的同一引擎能在 Windows 上运行。本文档是
`Linux/README.md` / `docs/developers/build/linux.md` 的技术伴侣；它记录
工具链配方、每部分为何锁定，以及本增量所做的决策。

---

## 1. 这是什么，不是什么

目标是原生 Windows MAD Designer（.NET 10 LTS 上的 WPF），复用
现有的无头 Objective-C 引擎并原生为 Windows 编译。引擎
构建落在 `Windows/` 下，是 `Mac/` 和 `Linux/` 的兄弟；WPF 应用
随后在 Phase 5–6f 到来（`Windows/App`；§6e–§6i）。

Phase 2b 增量证明了工具链和框架移植。Phase 2（第一个
增量）构建了 **MADDataStructures** 和 **MADFoundation** 并运行了
冒烟测试。Phase 2b 增加了 **MADAPI**（MADSqlite3 引入的传递依赖）和
**MADSqlite3**，把锁定的 SQLite amalgamation 编译为 static
库，并移植了 MADDataStructures、
MADFoundation 和 MADSqlite3 的 Linux 测试套件（GNUstep `Testing.h` + `MADTestSupport.h`）。它
尚未构建其余无头框架、CLI 或应用。

---

## 2. 工具链配方，以及每部分为何锁定

摘要（本节自成一体）：

### 2.1 编译器：Clang 20.1.8

Phase 1 的启动崩溃（每个 Foundation 二进制中的 `0xC0000005`）是
浮动 master 的 GNUstep 组件中的运行时回归——§2.3 的七个锁定
修复了它——而非 Clang 23 的代码生成缺陷。Clang 20.1.8 是 CI 测试过的
编译器，是已证明配方的一部分；带锁定的 Clang 22/23 未经
测试。这是锁定，不是偏好；不要在没有新的
可行性测试的情况下升级 LLVM。

### 2.2 STL 门控覆盖

本机随附 Visual Studio 2026（18.12.0），其 MSVC STL 硬性要求
“Clang 22 或更新”（`_MSVC_STL_UPDATE 202609L`、`yvals_core.h:923`）：

```c
#elif defined(__clang__)
#if __clang_major__ < 22
_EMIT_STL_ERROR(STL1000, "Unexpected compiler version, expected Clang 22 or newer.");
```

覆盖 `-D_ALLOW_COMPILER_AND_STL_VERSION_MISMATCH` 是 STL 自己的
逃生口。它被证明无害：一个使用 `<map>` 的 C++ 程序用 Clang 20.1.8 + 该覆盖编译并
运行，整套工具链和 MAD 的
`.mm` 文件（包含 `<map>`/`<vector>`）也如此。它应用于工具链
构建（`Engine/toolchain/stl-gate-override.patch`），以及框架构建中的每个 Objective-C++
翻译单元。

### 2.3 七个锁定的 GNUstep 修订（浮动 master 回归）

`gnustep/tools-windows-msvc` 克隆每个组件的最新 master
（其阶段脚本中 `TAG=` 为空）。其 CI（`.github/workflows/ci.yml`）
构建并打包工具链，但**从不运行二进制**，因此运行时
回归未被发现。A/B 测试隔离了它：

| 组件 | 11-14（运行） | 11-17/18 master（崩溃） |
|---|---|---|
| libobjc2 | `a21ae931` | `762f9d7` |
| gnustep-base | `24654296` | `ff647838` |
| libdispatch | `22798930` | `20b4c8b2` |
| gnustep-make | `e7c0730d` | `8fa108c7` |
| libffi | v3.8.0 | v3.8.1 |
| libiconv | v1.19（`a536e24a`） | v1.19.1 |

修复是锁定七个已知良好的 11-14 修订
（`Engine/toolchain/revision-pins.patch`）。驱动本身也锁定到
提交 `54d08e57`（其 master 浮动且不得跟踪）。两个事实都
记录在 `Windows/Engine/toolchain.conf`。

### 2.4 构建包装器的三个非显然要求

工具链的 `build.bat` 必须从 `vcvars64` 开发者环境运行，
`BASH` 设为 MSYS2 的 shell，并且以**绝对** `build.bat` 路径运行，不
编辑 `PATH`（vcvars64 的 `PATH` 约 2500 字符，会破坏 cmd 的裸名
解析）。从 Git Bash 调用 `cmd` 时用 `cmd //c`（不是 `cmd /c`）；从
PowerShell，`cmd /c` 是正确的。`Engine/toolchain/bootstrap.ps1` 封装了
这三者。

---

## 3. 构建入口点

`Windows/Engine/build.ps1` 从仓库复现该配方：

1. **先决条件检查**——Clang 20.1.8、lld、CMake、Ninja、MSYS2、git、curl、
   tar、`llvm-lib`、VS 2026、Windows SDK、NASM。
2. **幂等工具链引导**——`Engine/toolchain/bootstrap.ps1`
   克隆锁定的驱动、应用两个补丁文件，并
   从源码把 GNUstep 构建到 `C:\GNUstep`（可配置；首次运行约 20–30 分钟）。
3. **SQLite 库构建**——从
   `Engine/libraries.conf` 下载 3.53.3 amalgamation，校验其 sha256，解压，按 `Compressor/sqlite3.xcconfig` 选项列表编译 `sqlite3.c`，并用 `llvm-lib` 把它归档为
   COFF `sqlite3.lib`。
4. **框架构建**——编译 MADDataStructures、MADFoundation、MADAPI 和
   MADSqlite3（加上 `Engine/Compat` shim）。
5. **测试构建**——为每个移植的测试文件编译并链接一个可执行文件（加上
   冒烟测试）。
6. **测试运行**——运行冒烟测试和每个套件；任何
   失败时以非零退出。

框架编译标志匹配 Linux 构建的 Debug 配置：GNUstep 的
`gnustep-config --objc-flags` 在 `--enable-debug-by-default` 下（Linux
工具链所用）携带 `-DDEBUG`，因此 `build.ps1` 向每个
翻译单元——库和测试都一样——传 `-DDEBUG=1`，且**不**定义
`NS_BLOCK_ASSERTIONS`，保持 `NSAssert` 与 Linux 上完全一样活跃。

**决策——`build.ps1` 直接驱动 Clang，而非经由 CMake。** CMake 在 Windows 上的
Objective-C 语言支持对此配方所需的组合是坏的
（GNU 驱动的 `clang` 目标为 `x86_64-pc-windows-msvc`）：
其 Objective-C 链接探查把 GNU-ld 标志（`--out-implib`、`-nostdlib`、
`-nostartfiles`）传给 `lld-link`，并在已带 `-l` 前缀的库名后追加 `.lib`，
因此链接失败（`undefined symbol: $_OBJC_CLASS_NSObject`，
以及 ObjC 元数据的 section-GC 错误）。已证明的配方是直接 `clang`
调用——可行性阶段的 `compile-mad.sh` / `link-and-run.sh`——而
`build.ps1` 是那份配方清理并幂等化的版本。按框架的
源列表仍位于 `Engine/cmake/<Name>Sources.cmake`（规范的、
CMake 就绪的清单，带排除原因），且 `build.ps1` 读回它们
使两者不会漂移；一旦 CMake 的 Windows Objective-C 支持落地，真正的 CMake 构建可以原样消费它们。
 
---

## 4. 什么编译，以及 Windows shim

| 框架 | Windows 构建 | 排除，以及原因 |
|---|---|---|
| MADFoundation | 27 个中的 26（+ `madlib.c`） | `MADKeyChain`（Security.framework；Linux 上已排除）和 `BDHost`（POSIX socket 反向 DNS——`sys/socket.h`/`netpacket/packet.h`/`ifaddrs.h`/`arpa/inet.h`；需要 Winsock2 移植）。总括头随 `MADKeyChain` 一起。 |
| MADDataStructures | 全部 17 |（`madmap.cpp` 也不在 Xcode 目标中） |
| MADAPI | 11 个中的 8 | 三个连接视图控制器（`MADConnectionViewController`、`MADConnectionSQLGenericViewController`）——UIKit，非无头。不是 Phase 2b 自身的交付物；MADSqlite3 的传递依赖。 |
| MADSqlite3 | 全部 26 | 五个孤儿 `.m` 文件也不在 Xcode 目标中（在 `Engine/cmake/MADSqlite3Sources.cmake` 中命名） |

`Windows/Engine/Compat/` 是 `Linux/Compat` 的副本，为 Windows 调整：

* **`syslog.h`**——空操作的 `syslog()` 和 `LOG_*` 常量，用于 `madlog` 的
  非 Apple 分支（`madlog.h` 在未定义 `__APPLE__` 时包含 `<syslog.h>`）。
* **`pthread.h`**——`pthread_mutex_t`（递归）在 Windows
  `CRITICAL_SECTION` 之上，用于 `MADOperation.m` 的状态锁。
* **`NSData+ReadingOptions` 移除**——锁定的 GNUstep master 已
  携带 `NSDataReadingOptions` 和 `-options:error:`；Linux shim
  （为 gnustep-base 1.31.1 重新声明它们）在 Windows 上会是重复
  接口。
* **`NSPropertyListSerialization+Stream.m`** 增加一个显式
  `#import <Foundation/NSData.h>`——一处 Windows 头文件包含顺序分歧
  （Linux 的头文件恰好先到 NSData；Windows 的不会）。
* **`MADCompat.h`**（强制包含的序言）去掉 `<endian.h>` +
  `htonll`/`ntohll` 块——MADFoundation 和 MADDataStructures 都不用它
  （经 grep 核实），且 Windows 上没有 `<endian.h>`。驱动层
  （`MAD`）被移植时将需要一个 Windows 字节序 shim。
* **`MADCompat.h`** 还增加一个 `static inline strlcat`——Windows UCRT 没有
  `strlcat`/`strlcpy`（BSD/Apple 拼写；glibc 2.38+ 提供它们，这正是
  Linux 无需 shim 的原因），而 `MADQueryCacheAddRow.m` 需要它。
* **`NSURL+FileSystem.m`** 用 `self.path.UTF8String` 回答 `-fileSystemRepresentation`，
  而非 GNUstep 的 `GSNativeChar*` 拼写（Windows 上是 UTF-16），后者在被伪装为
  `const char *` 时破坏了 `sqlite3_open_v2` 的路径。

其他 Linux shim 原样沿用，因为 Windows 和 Linux 的
GNUstep-base 是同一条 1.31.x 线。

---

## 5. 不可避免的共享源码改动

需要两处共享源码改动，都最小且可移植（Linux
CI 和 Apple 套件是门槛）：

### 5.1 `madlib.c` 的 `itoa`/`ltoa`/`ultoa` 重命名

`MADFoundation/Source/madlib.c` 定义了 `itoa`/`ltoa`/`ultoa`，它们与
Windows UCRT 同拼写的三参数非标准名称冲突。
它们重命名为 `mad_itoa`/`mad_ltoa`/`mad_ultoa`，且每个调用方都已更新：

* `MADFoundation/Source/madlib.{c,h}`——定义和声明；
  还去掉 `#import <strings.h>`（未使用，且 Windows 上不存在）。
* `MADFoundation/MADFoundationTests/madlibTests.m` 和 `Linux/Tests/madlibTests.m`
  ——测试。
* `MAD/Source/model/MADModelQueryTable.m`、`MAD/Source/rptq/RptqQueryTable+Extras.m`
  （`ltoa`）以及 `MADSqlite3/Source/MADDataTableFast.m`、
  `MADSqlite3/Source/MADQueryCacheAddRow.m`（`ultoa`）。

这是纯机械重命名，在 Apple 和 Linux 上行为中立。
`uitoa`、`reverse`、`count_digits` 和 `count_digits_ul` 未动（它们
不与 UCRT 冲突）。`MADExplorer` 中的 `itoa` 引用位于
注释掉的块中，不是调用方。

### 5.2 快速枚举游标指针

`MTStack.m`、`MTQueue.m` 和 `MTLinkedList.m` 把它们的 `countByEnumerating…
` 游标节点指针存储在 `NSFastEnumerationState.extra[0]` 中，经 `unsigned long` 转换。
那在 Windows（LLP64）上是 32 位，但在 Linux/Apple
（LP64）上是 64 位，因此指针被截断，多批枚举（任何超过一个栈缓冲量的集合）
崩溃或产出垃圾。三个文件现在用 `memcpy` 把指针复制进 `extra`（在
LP64 和 LLP64 上都正确），并把它保存在 `__unsafe_unretained` 局部变量中——
集合拥有节点链，它比调用活得更久，因此在每个平台上借用指针都是诚实的
所有权模型。该改动在 Apple/Linux 上行为中立（同样的指针字节流动）。

---

## 6. 已知缺口与下一增量

> 本节记录 Phase 1/2 当时的缺口。Phase 3a–6e
> 除已接受者外全部关闭；参见 §6b–§6h，以及
> `Windows/README.md` 了解当前状态。

* **`BDHost`**（反向 DNS）和 **`MADKeyChain`**（Security.framework）
  被排除；`BDHost` 需要 Winsock2 移植，`MADKeyChain` 尚无 Windows
  钥匙串等价物。`BDHostTests` 因同样原因不在 Windows 上注册
  （没有 `BDHost.m` 就无法链接）——记录，而非跳过。
* **其余无头框架**（`MAD`、驱动、`MADFileManager`、
  `MADCocoaExtensions`、……）和 **CLI** 是下一增量。
* **WPF 应用**是较晚的阶段。

## 6b. Phase 3a——框架、归档栈与 CLI

Phase 3a 构建其余无头框架、`.mad` 容器的 C
库以及 `mad.exe`：

* **框架。** `MADCocoaExtensions`（7 个文件）、`MADFileManager`（10）和 `MAD`
  （168）加入 Phase 2/2b 集合，来自同样的 Linux 源列表并带
  同样的排除原因（UI 长尾、`MADocument`、钥匙串操作、
  `MADCloud`）。`MADDirectoryMonitor` 针对一个惰性的 `sys/inotify.h`
  shim 编译——CLI 是单次的，不需要变更事件。
* **C 库。** `zlib` 1.3.2、`bzip2` 1.0.8 和 `libarchive` 3.8.9（Linux
  锁定版本）在 `build.ps1` 中构建：zlib 和 bzip2 由直接 clang + `llvm-lib`，
  libarchive 经 CMake + clang-cl（zlib/bzip2 入；xml2/lzma/zstd/lz4/openssl
  和工具出），匹配 `Linux/lib/libraries.sh` / Compressor。条形码
  栈——`libpng` 1.6.59 和 `zint` 2.16.0——以相同方式构建（两者都经
  CMake + clang-cl），因此 `MADBarcodes` 也能在此编译和渲染。
* **CLI。** `CLI/Source` → `mad.exe`，whole-link。`inspect`、`schema`、`query`
  和 `refresh`（76 行）在 `London.portable.mad` 上运行；全部六个导出摘要
  与 Mac/Linux 锁定版本字节一致，且 `write --reproducible` 写出与 Mac 和 Linux 相同的 16261 字节文档（`09815b24…`）。

### 6b.1 两个仅 Windows 的运行时修复（Phase 3a 最终）

* **`write --reproducible`（116 字节的存储读取）。** 归档写出器的
  `open`/`read` 经过 `Windows/Engine/Compat/unistd.h`，其 `open`
  映射到 UCRT 的 `_open`——默认是*文本*模式。一个 SQLite 存储在
  偏移 116 处包含一个 `0x1A`（Ctrl-Z）字节；文本模式的 `_read` 在此停止
  作为 EOF，因此写出器看到 663552 字节中的 116，并发出一个 518 字节的归档。
  shim 现在把 `_O_BINARY` OR 进标志，使 `open`/`read` 是 POSIX
  字节级行为。仅保护到 Windows shim；Apple/Linux 的字节
  不变。由 `MADArchiveManagerTests` 锁定（5 个测试，0 个需求）。
* **同一用户中重复的 `export`（`.mdcache` 重命名）。** 行缓存
  `.mdcache` 是一个经 `NSInputStream` 读取、然后原子重写的 plist。
  `Compat/NSPropertyListSerialization+Stream.m` 第二次打开已经打开的流；
  GNUstep 的 win32 `GSFileInputStream -open` 每次都调用 `CreateFileW`
  （`FILE_SHARE_READ`）并覆盖 `_loopID`，泄漏第一个
  句柄。该句柄阻塞了随后对 `.mdcache` 的 `MoveFileEx`
  （`"being used by another process"`），因此第二次导出失败。shim
  现在读取已打开的流而不重新打开它（Apple 的契约），两个
  导出在同一用户中都成功。

### 6b.2 测试清单

复制的 MAD/MADFileManager/MADCocoaExtensions/MADAPI 套件接入
`build.ps1`（fixture 路径为 `Windows/Engine/Tests` 调整）：**107 个移植
套件 + 冒烟测试，966 个测试，6 个需求，5 个跳过，0 个失败**。六个
需求匹配 Linux 镜像的平台缺口：`MADDirectoryMonitorTests`（3——Windows 监视器是惰性的）、`MADStoreTests`（1——Core Data + `MAD.momd`）和
`RptqStoreContextTests`（2——转换器/文档路径）。四个需要 Phase 3b 驱动的 MAD 套件
被推迟并记录在 `build.ps1` 中：
`MADDatabaseDriverDispatchTests`、`MADQueryFullTests`、`MADSQLParserTests` 和
`MADQueryMaxFieldLengthTests`。五个跳过是默认规模的 SQLite 基准。

额外的 Windows `Compat` shim 是 `unistd.h`、`dirent.h`、`libgen.h`、
`sys/{unistd,fcntl,inotify}.h`，加上 `MADCompat.h` 获得 `strlcpy`、
`S_IS*`/`S_IR*` 模式宏、`ssize_t`/`mode_t`、`M_PI`、`arc4random` 和
`gmtime_r`。额外的极小共享源码改动（全部 `#if __APPLE__` 安全
或在 Linux 上字节中立；Linux CI 和 Apple 套件是门槛）：

* `MADReportSectionRepresentation.m` 去掉一个空的 `@finally`（clang 20.1.8 的
  GNUstep-2.2 + ARC 代码生成在它上面崩溃）。
* `madtar.m` 增加一个 `_WIN32` mtime 分支（UCRT `struct stat` 有 `st_mtime`、
  没有 `st_mtim`）。
* `MADArchiveManager.m`、`MADStore.m` 和 `MADCLIInspect.m` 在原先取
  `-fileSystemRepresentation` 的地方使用 `NSString -UTF8String`（GNUstep 的
  NSString 拼写在 Windows 上返回 UTF-16）。
* `MADDatabaseConnection+Constructor.m` 的 `+Identifier:` 直接返回四个
  文档格式常量，使只链接 Sqlite3 的进程仍能把存储的 `driverID`
  映射为类型。（Phase 3b 移除了该守卫——见 §6c。）

## 6c. Phase 3b——驱动、BDHost 与实时 fixture

Phase 3b 增加四个数据库驱动及其链接的 C 库：

* **C 库**（`Windows/Engine/libraries.conf`、`build.ps1` §3c）：OpenSSL
  3.5.9（Strawberry Perl + `VC-WIN64A` + `nmake`，静态）、FreeTDS 1.4.27（CMake
  `db-lib`、`ENABLE_MSDBLIB`、`sybdb.h` BOOL 编辑）、MariaDB Connector/C 3.4.11
  （CMake `mariadbclient`、认证插件静态）、libpq 17.11（**Meson + MSVC
  `cl.exe`**，`libpq_st` + `libpgcommon_shlib` + `libpgport_shlib` 合并为一个
  COFF `libpq.lib`）。PostgreSQL 17 放弃了 MSVC 构建，因此 Meson 是其 Windows
  路径；使用 `cl.exe`（而非 `clang-cl`）是因为 PostgreSQL 的 Meson 检查
  `cc.get_id() == 'msvc'` 而 `clang-cl` 报告 `clang-cl`，静默丢弃
  `win32gettimeofday.c`/`dirent.c` 和 `win32_msvc` include 目录。Meson 和
  Strawberry Perl 是已记录的先决条件。
* **BDHost**——`MADFoundation/Source/BDHost.m` 增加一个 `#elif defined(_WIN32)`
  分支，覆盖 `winsock2.h`/`ws2tcpip.h`（`WSAStartup` 一次、
  `getaddrinfo`/`getnameinfo`、仅 IPv4）；`+ipAddresses`/`+ethernetAddresses` 在 Windows 上
  编译掉。`BDHostTests` 通过 3/3。
* **驱动**——四个 `cmake/*Sources.cmake` 列表（18/1/3/4 个文件）和头文件 shim
  用于 `<MADTds/sybdb.h>`、`<MADTdsClient/MADTdsClient.h>` 和
  `<MADPostgres/libpq-fe.h>` 等。`MADTdsDb.m` 正常链接（其全局
  `err_handler` 与 `MADDatabaseSQLServer.m` 的冲突）。Phase 3a 的
  `+Identifier:` 守卫被移除——注册表查找在四个驱动全部链接时工作，
  由 `MADDatabaseDriverDispatchTests` 锁定（9/9）。
* **测试清单**——**130 个套件，1,313 个测试（含冒烟测试），6 个需求，5 个跳过
  （实时容器未运行时 48 个），0 个失败**（条形码增量
  增加 `MADBarcodesTests` 和 `MADBarcodeExportTests`；镜像收尾增加
  `MADImageElementTests` 和 `MADImageExportTests`）。针对本地
  `127.0.0.1` 容器的实时套件：`MADMySQLLiveTests` 44/44、`MADTdsClientLiveTests` 29/29、`MADPostgresLiveTests`
  14/14。CLI `mad refresh` 返回 50 行 MySQL / 20 行 TDS / 25 行 PostgreSQL。

## 6d. Phase 4——stdio JSON 进程契约

Phase 4 增加 `mad serve`，即 WPF shell 将使用的长驻进程边界。它
在标准输入上读取换行分隔的 JSON，并在标准输出上为每个请求写一个换行分隔的 JSON
响应；诊断留在标准错误，因此
两者永不混淆。线格式复用项目既有的 JSON 契约，而非
发明平行的契约。

**请求 / 响应**——每行一个 JSON 值，UTF-8，以 `\n` 终止：

```text
request:   { "id": <int|string>, "method": "<name>", "params": { … } }
ok:        { "id": <id>, "ok": true,  "result": { … } }
error:     { "id": <id|null>, "ok": false, "error": { "code": <int>, "message": "…" } }
```

`id` 由客户端选择并回显用于关联；畸形请求以
`"id": null` 回答。`error.code` 是 CLI 的退出码（MADCLI.h）：1 用法/协议、2 坏
文档、3 数据库不可达、4 查询失败、5 导出失败。畸形行、
未知方法、缺失参数和意外的引擎异常都以消息回答
`ok: false`——绝不是 traceback——且会话继续运行。

**方法：**

| 方法 | 参数 | 结果 |
|---|---|---|
| `open` | `path`，可选 `host`/`port`/`database` | `handle`、`filename`、`driver` |
| `create` | `path`、`driver` + 连接字段，可选 `credentials` | `handle`、`filename`、`driver`（创建的文档） |
| `test-connection` | `driver` + 连接字段，可选 `credentials` | `tableCount` |
| `describe` | `handle` | `driver`、`columns`（键/名称/表/类型）、`tables`（名称 + 字段） |
| `connection` | `handle` | `driver` + `file`/`host`/`port`/`database`/`server` |
| `apply-connection` | `handle`、`driver` + 连接字段，可选 `credentials` | `{}` |
| `query` | `handle` | `sql` |
| `query-model` | `handle` | `driver` token、`sql`、`sqlSourceText`、`tables`/`links`/`predicates`/`groups`（带存储标识符） |
| `add-table` | `handle`、`table`（架构名） | 完整的 `query-model` |
| `remove-table` | `handle`、`table`（查询表 id） | 完整的 `query-model` |
| `add-link` | `handle`、`leftField`、`rightField`（字段 id） | 完整的 `query-model`（默认 Left Outer Join） |
| `set-link-type` | `handle`、`link`、`type` | 完整的 `query-model` |
| `swap-link` | `handle`、`link` | 完整的 `query-model` |
| `delete-link` | `handle`、`link` | 完整的 `query-model` |
| `add-predicate` | `handle`、`leftField`、`operator`、`value` | 完整的 `query-model` |
| `remove-predicate` | `handle`、`predicate` | 完整的 `query-model` |
| `add-group` | `handle`、`field`、`sort` | 完整的 `query-model` |
| `remove-group` | `handle`、`group` | 完整的 `query-model` |
| `validate-sql` | `handle`、`sql` | `tables`、`links`、`predicates`、`groups`（计划的计数） |
| `apply-sql` | `handle`、`sql` | `tables`、`links`、`predicates`、`groups` |
| `refresh` | `handle`，可选 `rows`/`credentials` | `rowCount`、`elapsed` |
| `export` | `handle`、`format`，可选 `path`/`deterministic` | `format` + `data`（导出器的字节）或 `path` + `bytes` |
| `write` | `handle`、`out`，可选 `reproducible` | `path`、`bytes`——序列化活动文档 |
| `shutdown` | — | `{}`，然后进程退出 0 |

连接方法（`create`、`test-connection`、`connection`、`apply-connection`）
取一个 `driver` token——`sqlite3` | `mysql` | `sqlserver` | `postgres`——以及
驱动特定字段：SQLite 取 `file`；服务器驱动取
`host`/`port`/`database`（SQL Server 还取可选的 `server` 实例），加上
既有的 `credentials`（`user:password`）字符串。它们复用引擎的
`createDocumentAtURL:`、`MADDatabase`（connect/getTables/close）和
`applyDatabaseConnection:`——与 Mac 的连接窗口所做的相同调用。

`export` 是导出接缝（`MADReportExporting` / `MADReportExporterRegistry`），不是
新架构：`format: "json"` 返回 `mad export
--format json` 所写的确切 `mad.report/1` 字节（`MADReportExporterJSON`——`columns` 和 `rows`），而 `format:
"csv"` 返回 RFC 4180 字节。此构建无法产出的格式（例如非
Apple 上的 `pdf`）以导出器的原因回答 `error.code` 5。`describe` 的 `columns` 是
那些同样的 `mad.report/1` 列（`MADReportExportSource`），其 `tables` 是
`mad schema` 打印的存储数据库架构。`open` 以一次性动词的方式应用 `host`/`port`/`database`，
因此一份签入的文档可以在会话中针对不同服务器
运行。`write` 现在序列化活动会话文档，而非重新打开
`sourceURL`，因此会话中应用的连接会被持久化。标准输入上的
文件结束是干净关闭，`shutdown` 也是。

`query-model`/`add-table`/…/`apply-sql` 方法是 Phase 6b 的 Query 工作区
扩展。原始 `serve` 契约只把查询作为其生成的 `sql` 暴露，
Mac 通过在进程内变更 `RptqQuery` 对象来推导它；WPF 应用没有
这样的进程内句柄，因此这些方法弥合该缺口。`query-model` 读取完整
查询模型——tables/fields/links/predicates/groups 及其存储标识符、
输入的 `sqlSourceText` 和驱动 token——且每个变更方法回答同样
形态，使客户端原子替换其快照。变更调用与 Mac 的 `MADMacQueryViewController` 所用的相同
工厂和 `MADSQLQueryDocument` 辅助方法
（`newQueryTableForSchemaTable:`、`newQueryLinksWithLeftField:`、`addQueryGroupWithQueryField:`、
`removeGroupWitObjectID:`、……），而 `validate-sql`/`apply-sql` 原样运行既有的
`MADSQLParser` → `MADSQLStatementResolver` → `MADSQLQueryCompiler` 路径。
`query` 现在先返回全字段 SQL，回退到活动字段选择，
匹配 Mac 的 `generatedSQLString:`——因此没有报表元素的新文档
仍产出 SQL。

**客户端与测试。** `Windows/Client/` 持有 .NET 10 控制台验收客户端
（`Mad.Client`）和 xunit 套件（`Mad.Client.Tests`），两者都由
`Windows/global.json` 锁定。客户端启动 `mad serve` 并覆盖七个方法；测试
在 `CLI/Fixtures/London.portable.mad` 上走成功路径（open → describe
→ query → refresh 76 行 → export json/csv → shutdown、退出 0、无孤儿进程）、
畸形请求、未知方法、坏文档、不可用格式，以及
进程关闭。

## 6e. Phase 5——WPF shell 证明

Phase 5 在 Phase 4 进程边界之上增加第一个 WPF 应用：一个
位于 `Windows/App/` 下的 `net10.0-windows` shell，证明引擎从真实 UI 运行。
它原样复用 `Mad.Client`，并增加异步 `EngineService`（`SemaphoreSlim`
串行化单线程行协议；每个阻塞调用在线程池运行）、手写的 MVVM 层（`ObservableObject`、`RelayCommand`、`AsyncRelayCommand`），
以及第一个切片中镜像 Mac `MADMacDocument` 的 `DocumentViewModel`：
open → describe → query → refresh → export。

shell 有三工作区框架（MAD Query / Designer / Viewer）。Query 显示
存储的架构和生成的 SQL；Viewer 在 `DataGrid` 中显示刷新后的行（通过
把 `mad.report/1` 解析为 `DataTable` 喂入）并导出 CSV/JSON；Designer 是 Phase 6
占位符。启动时它自动打开 `CLI/Fixtures/London.portable.mad`（用
`MAD_DOCUMENT` 覆盖），因此零点击演示。“关于”窗口（Overview / License &
Notice / Acknowledgements）从 `ThirdParty/Licenses/Windows/` 渲染 Windows 依赖登记表和重新链接要约——
Windows 组件集，绝不是 Apple 的。

验收由 `Windows/App/Mad.Designer.Windows.Tests`（xunit）无头验证：
打开 London → describe（21 列 / 11 表 / 驱动 "Sqlite 3"）→ refresh 76 行 →
export json（76 行）/ csv（78 行）→ 干净关闭无孤儿，加上
`mad.report/1` 解析器和许可证登记表检查。应用和测试在
`net10.0-windows` 上构建并运行（由 `Windows/global.json` 锁定）；Linux CI 不受影响（它从不
构建 .NET）。

## 6f. Phase 6c——报表布局模型（Designer）

Phase 6c 用 Designer 工作区所编辑的报表布局模型扩展 `serve`，使用
与 6b 查询模型方法相同的细粒度模式。`layout-model` 读取完整快照；
每个变更方法变更现有的 `RptqDocumentSection`/`RptqDocumentElement` 对象
并回答同一快照，使客户端原子替换其状态。条形码是模型的一部分
（条形码收尾增量增加元素种类、其内容编辑、
符号学目录、引擎渲染预览和 WPF 组合器——§6j；图像
收尾随后带来 PNG 内容和 WPF 文件选择器——§6k）。颜色推迟（无头模型中
无可移植颜色类型）。撤销/重做是客户端侧。

| 方法 | 参数 | 结果 |
|---|---|---|
| `layout-model` | `handle` | `paperSize`、`sections[]`、`elements[]`、`fields[]` |
| `add-element` | `handle`、`kind`（`label`\|`data-field`\|`aggregate`\|`image`\|`line`\|`barcode`）、`section`、`x`、`y`；图像用 `data`（base64 PNG） | 完整快照 |
| `remove-elements` | `handle`、`elements: [id…]` | 完整快照 |
| `duplicate-elements` | `handle`、`elements: [id…]` | 完整快照 |
| `move-elements` | `handle`、`elements: [id…]`、`section` | 完整快照 |
| `set-element-geometry` | `handle`、`elements: [{id,x,y,w,h}…]` | 完整快照 |
| `set-element-content` | `handle`、`element`、`content{text,field,function,scope,group,barcodeType,humanReadable,borderStyle,data}`（`data` 是图像的 base64 PNG；空值清除它） | 完整快照 |
| `set-element-typography` | `handle`、`elements: [id…]`、`style{fontname,fontsize,bold,italic,underline,strikethrough,hAlign,vAlign}` | 完整快照 |
| `set-element-box-model` | `handle`、`elements: [id…]`、`box{borderTop,borderBottom,borderLeft,borderRight,padding,margin}` | 完整快照 |
| `set-section` | `handle`、`section`、`{height,visible,pageBreak}` | 完整快照 |
| `set-paper-size` | `handle`、`paperSize`（`MTPaperType` int16：Letter 2 / Legal 7 / A4 19） | 完整快照 |

快照按设计器的规范顺序携带带区（Report Header、Page
Header、Group Headers、Detail、Group Footers、Page Footer、Report Footer），每个带 `id`、
`type`（`MADocumentSectionType`）、`title`、`height`（接口高度 `layoutHeight`）、
`visible`、`pageBreak` 和 `groupField`。每个元素带 `id`、`type`
（`MADPrintPageElementType`）、`section`、`x/y/w/h`、`text`、`field`（绑定的查询字段 id）、
`table`/`column`、`function`/`scope`/`group`（聚合）、`fontname`/`fontsize`、
`bold`/`italic`/`underline`/`strikethrough`、`hAlign`/`vAlign`、`borderTop`/`borderBottom`/
`borderLeft`/`borderRight`、`padding` 和 `margin`。条形码元素还携带
嵌套的 `barcode` 对象（§6j）；图像元素携带 `image{data}`，即以
base64 PNG 存储的图片（没有时为空——§6k）。`fields[]` 列出查询字段（带存储 id）
供侧栏浏览器和绑定弹出使用。

## 6g. Phase 6d——Viewer 工作区（渲染、页面尺寸、导出、打印）

Phase 6d 在 6a–6c shell 之上完成 MAD Viewer。Mac 查看器在 `PDFView` 中渲染
分页 PDF；Windows 没有 PDFKit，因此预览改为渲染引擎的
HTML 摹本，而 PDF 本身由引擎自己的导出器在
导出时写出（§6l）：

* **渲染方式——WebView2 之上的引擎 HTML 导出器。** 预览显示
  确切的 `export --format html` 字节（每页一个 `<div class="page" data-index="N">` 框，
  与 PDF 和每个其他导出器使用同一格式化器），托管在 WebView2 中。
  状态行上的页数就是这些页面框的数量，因此引擎
  仍是唯一的分页器，且没有导出器在 C# 中重新实现。预览只增加
  呈现性外壳（灰色桌面、页面间隙和阴影）通过注入的样式；
  导出的字节不受触碰。HTML 写入临时文件并按 URL 导航，
  因为 `NavigateToString` 有 2 MB 上限，大报表会触及。缩放是
  WebView2 的 `ZoomFactor`；页面导航把所请求的页面框滚动到视图中。
  **打印**使用 `CoreWebView2.ShowPrintUI`——临时 HTML 打印路径。浏览器在
  `Loaded` 时创建，而非 XAML 中，因此工作区可为其测试无头组合。
* **`ViewerViewModel`** 拥有页面尺寸选择及其渲染锁（默认 US Letter、
  US Legal、A4）、缩放步进（0.25–4.0、1.25×、100% 复位）、上一/下一页
  导航、导出格式目录和状态行。状态行是 Mac 的：`Rendered N pages from M cached rows.`，带其单复数文法，成功时绿色、
  失败时红色。选择纸张尺寸在下一次刷新前不改变渲染后的报表
  （Mac 的 `selectedPaperType`/`renderedPaperType` 分离）；选择
  在刷新后保留，且导出使用渲染纸张。
* **导出**提供此构建产出的七种格式，按 Mac 查看器的顺序——
  PDF Document、HTML Page、HTML Flow、CSV、JSON Data、JSON Full Report 和 Plain Text——
  各自有文件扩展名（`pdf`、`html`、`html`、`csv`、`json`、`json`、`txt`）。
  工具栏携带格式选择器；Export 打开按所选格式过滤的保存对话框。PDF 走 `serve` 的路径形式（`export` 带 `path`），因此
  引擎把导出器的字节写到所选文件，响应只携带
  字节数；文本格式所用的 `data` 读回是 UTF-8，会损坏
  二进制 PDF。在刷新前导出会先刷新，如 Mac 的 Export 所做，且
  导出运行时状态栏显示其不确定进度条并带
  “Exporting…”行（命令被禁用；`serve` 不流式进度，导出
  是单个请求）。
* **文档集成。** `DocumentViewModel.RefreshAsync` 运行查询，然后调用
  `Viewer.RenderAsync`，后者通过文档应用所选纸张（使
  Designer 的快照跟随）并加载 HTML 预览。Viewer 的 Refresh、Export
  和 Print 按钮都走同一文档路径。
* **引擎修正。** `set-paper-size` 变更存储的 `RptqDocument` 但不
  变更渲染文档，后者的 `MTPaper` 在首次布局后缓存，因此第二次纸张
  变更从未到达导出。它现在还在渲染文档上调用 `setPaperType:`
  （Mac 查看器刷新前所做的调用），并重新格式化已经
  布局的报表，使新尺寸到达随后无需另一次刷新的导出。

Viewer 取代 Phase 5 的占位行网格：渲染后的报表就是工作区，
与 Mac 上一样，而行仍可通过 CSV/JSON 导出获得。

**测试。** `ViewerViewModelTests`（状态文法、格式目录、页数、缩放、
导航、打印请求）、`ViewerSurfaceTests`（在 STA 线程上物化的工作区——
工具栏、七种格式、页面尺寸选择器、状态颜色和
页面标签），以及针对引擎的 `ViewerAcceptanceTests`（London → 5 页 / 76 缓存
行、页面尺寸锁和跨 A4 的持久化，导出页面框为 595 × 842、
每种导出格式及其扩展名，PDF 由其 `%PDF-` 签名检查，一次
带空格和非 ASCII 字符的路径导出、写 PDF 时设置并在之后清除的
导出中状态，以及 A4 → Legal → Letter 的纸张切换到达
每个导出）。

## 6h. Phase 6e——关于、本地化与 WPF 冒烟测试

Phase 6e 在不改变引擎的情况下关闭合并门：它完成“关于”
窗口的依赖登记表，把 WPF 应用本地化为 Mac 应用的语言
集，增加 `MADMacSmokeTest.m` 的 WPF 对应物，并让本记录和
`Windows/README.md` 保持最新。公开的 `docs/windows.md` 及其翻译
按设计推迟。

**关于与 WebView2 声明。** Viewer 预览运行在
**Microsoft Edge WebView2** 控件中（NuGet `Microsoft.Web.WebView2` 1.0.4314.35）。
随应用提供的 SDK 是 BSD-3-Clause 并携带 Microsoft 的
第三方声明；Evergreen WebView2 Runtime 是 Microsoft
可再分发组件，而非开源软件。因此“关于”窗口列出
`Microsoft Edge WebView2`，带两项条款和运行时归属，全部在
`ThirdParty/Licenses/Windows/WebView2-LICENSE.txt`。登记表是
`docs/project/THIRD_PARTY_LICENSES.md` §10。其余组件列表
不变（GNUstep Base、gnustep-corebase、libiconv、libobjc2、
libdispatch/BlocksRuntime、libffi 和 C 库），且 LGPL 重新链接
要约仍命名 Windows 引擎；WPF 应用绝不显示 Apple 集。

**本地化。** 每个面向用户的字符串位于 WPF `ResourceDictionary`
`Windows/App/Mad.Designer.Windows/Resources/` 下：`Strings-en.xaml` 是
权威来源，`Strings-de.xaml`、`Strings-es.xaml`、
`Strings-ja.xaml`、`Strings-pt-BR.xaml` 和 `Strings-zh-Hans.xaml` 镜像
Mac 应用的语言集（`MAD_APP_LOCALIZATION.md` D1/D9）。这些字典
嵌入主程序集（不是编译的 `Page` 项，也不是卫星
程序集——`Strings-de.xaml` 中的连字符使 MSBuild 不把
语言代码读作文化后缀），且 `Infrastructure/Localizer.cs` 用 `XamlReader` 加载它们
并提供 `Get`/`Format`。XAML 通过
`{infra:Loc Key}` 标记扩展消费它们，在加载时解析；代码后置和
视图模型调用 `Localizer`。语言在启动时跟随 OS UI 文化
（`de`、`es`、`ja`、`pt-BR`、`zh-Hans`；其他一切为英语），且
`MAD_LANGUAGE` 为检查而覆盖它：

```powershell
$env:MAD_LANGUAGE = "de"
dotnet run --project .\Windows\App\Mad.Designer.Windows\Mad.Designer.Windows.csproj
```

翻译在英语源匹配处复用 Mac 的 `Localizable.xcstrings`，然后遵循机器辅助策略（MAD_APP_LOCALIZATION.md D14）：
About Overview 以每种语言中“翻译为机器辅助且可能包含错误”的声明
结尾。About 外壳、
连接助手、查询/设计器/查看器工具栏和状态行、对话框，
以及带区名称都已翻译；许可证正文、组件声明、LGPL
重新链接要约、版权和品牌名称保持逐字英语（D6/§8），并有一句
本地化句子说明许可证文本以其原始
英语复制。SQL 关键字、数据类型名称和字段/表标识符不
翻译，引擎自身返回的错误文本（驱动失败、SQL
解析器消息）保持英语，如 Mac 的驱动消息一样。

**冒烟测试。** `Windows/App/Mad.Designer.Windows.Tests/SmokeTests.cs` 是
`MADMacSmokeTest.m` 的视图模型/服务级对应物，而非像素
测试：

1. **London。** 打开 `CLI/Fixtures/London.portable.mad`，刷新 76 行（5
   页），然后通过 Viewer 自身路径导出 HTML Page、HTML Flow、CSV、JSON Data、JSON Full Report 和
   Plain Text。每个文件的字节数和 SHA-256
   都按 `Linux/README.md` 中的 Mac/Linux 锁定断言（`html`
   `285541ed…`、`html-flow` `0565204a…`、`csv` `773f6215…`、`json` `569c6ee2…`、
   `json-report` `9d01d0da…`、`text` `7dcee96c…`）。
2. **新文档。** 从 `chinook.sqlite3` 创建 `.mad`，应用 Mac 的
   SQL 语句（`SELECT Customer.FirstName, Customer.LastName, Customer.City
   FROM Customer WHERE Customer.Country = 'United Kingdom';`），添加一个静态
   标签、一个绑定到 `LastName` 的数据字段和一个报表范围 COUNT 聚合，
   刷新，然后导出每个可用格式并检查 JSON 行数
   和 HTML 页数。

Viewer 在两个测试中都通过引擎的路径导出 PDF；冒烟测试检查其 `%PDF-` 签名，
而非把它当文本读取。套件与应用其余测试一起无头运行；参见 `Windows/README.md`。

## 6i. Phase 6f——主题、外壳与可用性梳理

Phase 6f 仅涉及呈现：无引擎、协议、文档或工作流变更。
它修复设计评审报告的两个功能缺陷，并在既有三工作区
架构上应用一套受 Fluent 启发的设计系统和外壳。（主题梳理不是合并门的一部分；
它跟随其后。）

**修复的缺陷。** Help ▸ About 终止了进程：About 窗口的
只读 `Overview`、`LicenseNotice` 和 `SelectedAcknowledgement` 绑定
到 `TextBox.Text`，其默认绑定模式是 TwoWay，且绑定在窗口首次布局时抛出
`InvalidOperationException`。绑定现在是 OneWay，
且 `AboutWindowTests` 显示窗口以锁定它。Designer 的拖拽缺陷是
Z 序：每个带区的不透明背景与其元素一起添加，因此拖入较后带区的元素绘制在该带区
之下并在放下重建画布前消失；其调整大小手柄也留在
旧位置。拖拽元素现在绘制在每个带区之上，拖拽时隐藏
手柄，选择外壳原地更新而非重建，ScrollViewer 偏移在重建间保留，
且拖拽数学在缩放 2 且视图滚动时被锁定。

**设计系统。** `Themes/Theme.xaml` 是单一资源集：
排版（Segoe UI Variable Text/Display、Fluent 尺寸）、间距、圆角半径、
表面、命令和导航样式、主要/次要按钮、分段
开关、表单和卡片样式，以及语义状态颜色。外壳画刷是
Fluent 动态资源键，因此浅色/深色、用户强调色和高对比度
跟随系统；`App.xaml` 用 `ThemeMode="System"` 选入原生 Fluent 主题
（实验 API 的 `WPF0001` 被抑制）。报表
文档保持自己的固定调色板：`Infrastructure/DesignPalette.cs` 是
纸张、元素色调、选择强调色、联接和小地图的单一冻结来源。
`MAD_THEME=Light|Dark` 是像 `MAD_LANGUAGE` 一样的检查覆盖，
Viewer 的 WebView2 桌面跟随它（或 Windows
AppsUseLightTheme 设置）。

**外壳。** 应用图标从既有 MAD 美术资源
（`Assets/AppIcon.png` 和多尺寸 `AppIcon.ico`）生成，是窗口、
任务栏和 About 身份。无报表启动时显示欢迎/主页屏幕
（New report、Open report、最近报表、简短介绍），而非
空 Viewer。三个工作区是 NavigationView 风格左侧栏，带
图标 + 标签、清晰的选中状态和 Ctrl+1/Ctrl+2/Ctrl+3；显示欢迎时它们被禁用。
新建报表在 Designer 中打开；已有报表在 Viewer 中打开。没有 Home 目标：
三个工作区仍是第一等的同级集。File 菜单保留 New/Open/Save/Save As/Recent/
Connection/Exit；命令栏保留 New 和 Open（About 留在 Help）。

**工作区组织。** 连接助手是固定 640 × 660
窗口（可调整大小，带滚动主体），其分组卡片把驱动
特定表单保留在同一框架内；SQLite → MySQL/SQL Server/
PostgreSQL 的切换不改变其大小。Query 有分段 Designer/SQL 开关、分组
命令、表面板头部正常尺寸的 Add table 命令，以及
底部缩放栏，带放大/缩小、百分比和 Fit。Designer 分组插入和
编辑命令，把小地图从左上角移到检查器顶部的折叠
Expander，并把缩放/网格/吸附/标尺放在
底部视图栏。Viewer 把文档/页面/输出命令放在顶部，
缩放、页面导航和状态/纸张行放在底部，给报表
最大面积。

**关于。** 窗口现在报告两个不同身份：引擎
（`v9.0 (r4433)`）和 Windows 应用（`v0.7`）。已敲定的决定是
Windows 应用在引擎成熟时仍处于 1.0 之前。

**可访问性与本地化。** 导航和命令表面有
工具提示、图标含义不明时的文本标签、UI Automation 名称（包括
仅图标的缩放和页面按钮）、键盘快捷键，以及 Fluent 焦点和
禁用状态。每个新增或重命名的字符串都在全部六个字典中
（`LocalizerTests` 检查完整性和占位符；英语仍是
权威来源）；许可证正文、声明、版权和品牌名称保持
逐字英语。套件是 110 个测试，包括 Welcome/导航/
第一工作区测试、About 窗口显示测试、主题字典测试和
查询缩放/适配测试。

**Ribbon 评估。** 未引入 ribbon。Designer 的命令表面
是两个组（插入调色板、编辑）加一个视图栏；ribbon 会增加外壳
并占用画布空间，而在此命令数量下没有可发现性收益。仅 Designer 的 ribbon
只有在元素/命令集大幅增长时才值得重新审视（例如，完整排版、对齐和表布局组）。
三个工作区的命令有实质不同，因此应用级
ribbon 会更复杂，而非更简单。

**未做（记录，非缺陷）。** 无第四 Home 目标；无应用内
关闭到欢迎。Viewer 的 WebView2 桌面颜色在创建浏览器时读取，
因此会话中切换主题需要重新启动。简报中命名的参考 WPF
应用不在工作站上；方向遵循 Microsoft 的 Windows 11 设计指南、原生 Fluent 主题和
既有 MAD 美术资源，调色板和间距集中以便轻松
调校。公开的 `docs/windows.md` 及其翻译仍推迟。

## 6j. 条形码收尾（2026-11-20）

条形码元素在边界两侧都不再是缺口。

**引擎。** `MADBarcodes` 在此编译（每个符号学子类；`MADBarcodeView` 和
`MADBarcodeCache` 留在仅 Apple），链接来自
`libraries.conf` 的 libpng 1.6.59 和 zint 2.16.0。`MADBarcode` 的编码过程是共享的，且 `-renderedPNGData` 通过 libpng 写 zint 的
RGB 位图、无 Core Graphics，因此无头引擎产出同样的
符号。`MADPrintPageElementBarcode`、`RptqDocumentElementBarcode+Extras` 和
`MADDocumentObjectDataReferenceBarcode` 在无头构建中；页面遍历把 PNG
放在 `MADReportLineRepresentation.imageData`，HTML 摹本把它嵌入为 data URI（
输入是 `alt` 文本），且 JSON 报告以 `"image": true` 命名它。使用
`useStaticInput1`/`inputStatic1` 的条形码渲染该字符串；绑定的读取其查询字段。

**serve。** `add-element` 接受 `"kind": "barcode"`（Code 128、人类可读、静态
`MAD-2026`、160×48、Mac 的默认值）；`layout-model` 携带嵌套 `"barcode"` 对象
（符号学 id 和名称、选项、输入绑定，以及来自同一
渲染核心的 base64 PNG `preview`）；`set-element-content` 编辑符号学、人类可读标志、边框样式和
静态或字段绑定；`duplicate-elements` 复制条形码列；
`barcode-types` 以按名称排序的 `{id, name}` 返回 MADBarcode 的名称表。

**WPF。** 调色板的 Barcode 按钮插入一个；画布绘制引擎的预览
（zint 拒绝时文本回退）；检查器显示符号学选择器、Show text、
边框选择器和输入选择器（静态，由 Text 框编辑，或一个查询字段）。
`DesignerAcceptanceTests.Barcode_InsertEditBindAndUnbind` 和创建的文档冒烟测试
锁定它（HTML/JSON 导出携带符号及其文本），且 London 字节锁定
不变，因为无条形码文档的字节未动。

**许可证。** zint（BSD-3-Clause）和 libpng（PNG Reference Library v2）在 §10、About
窗口的组件列表和 `ThirdParty/Licenses/` 中（两份文本都已存在）。

## 6k. 图像收尾（2026-11-20）

图像元素不再是占位符。未添加库：存储的图像列
已持有 PNG 字节。

**引擎。** 非 Apple 上 `MADReferenceImage` 和 `MADElementImage` 是 `NSData`——
存储的线格式本身——因此模型无头就绪，且 `RptqDocumentElementImage (Extras)`
获得可移植的 `-pngData` / `-setPngData:`，在各处逐字存储字节
（Apple 的 `-image` 访问器仍在有 UIKit/AppKit 处编解码图片）。
`MADPrintPageElementImage -renderedImageData` 回答存储的 PNG，因此
`MADReportLineRepresentation.imageData`——条形码收尾的接缝——也携带图片：
HTML 摹本把它嵌入为 `data:image/png;base64,…` URI，且 JSON 报告以
`"image": true` 命名它、无文本。在 Apple 上 PDF 路径仍绘制元素，且
`-renderedImageData` 回答 nil，这是既有的 Mac 导出行为。

**serve。** `add-element` 接受 `"kind": "image"` 与可选 base64 `"data"`（
在插入元素前解码，因此畸形请求不留下任何东西）；`layout-model`
携带嵌套 `"image"` 对象 `{data}`；`set-element-content` 接受 `"data"`（base64 PNG；
空值清除它）；`duplicate-elements` 复制图片。

**WPF。** 调色板的 Image 按钮插入元素；检查器为选中的图像显示本地化的
“Choose Image…”按钮（Mac 检查器的行）。选择器通过 WIC 解码任何
PNG/JPEG 并在发送前重新编码为 PNG（`ImageFileEncoder`）——
该列始终是 PNG，因此 HTML data URI 诚实。画布绘制存储的图片并在元素没有图片时
回退到 `[Image]` 占位符。`ImageElementTests` 锁定
协议、选择器的重新编码和画布；创建的文档冒烟测试向导出文档添加一个。

## 6l. PDF 收尾（2026-11-20）

`mad export --format pdf` 和 `mad serve` 的 `export` 现在在 Windows 上写出 PDF，且
Windows 那一半是构建携带的第三个无头库栈。

**库。** `Windows/Engine/libraries.conf` 精确锁定 Linux 的锁定版本：pixman
0.46.4 和 cairo 1.18.6（git 标签，提交锁定）和 FreeType 2.15.0（tarball），加上
Liberation 2.1.5 字体 tarball。`build.ps1` 用 FreeType 自己的 CMake
（clang-cl、静态、仅核心）构建 FreeType，然后在 MSVC 环境（`cl`）下用 Meson 构建 pixman 和 cairo，
静态且仅带 PDF surface。Meson 构建通过生成的 `.pc` 文件和 libpq 构建引入的同一 Windows 原生
pkg-config shim（`Ensure-PkgConfigShim`，现在是函数，使
两个构建共享它）找到其本地依赖。三个归档加入链接：`cairo.lib`、`freetype.lib`、
`pixman-1.lib`；`msimg32` 为 cairo 的 win32 surface 加入系统列表。

**字体。** Liberation 字面复制到 `Engine/build/fonts`；
`MADReportExporterPDFCairo` 先搜索 `<exe>/fonts`（使 `mad.exe` 找到
`build/fonts`，`build/tests` 中的测试通过 `<exe>/../fonts` 找到 `build/fonts`），
然后是安装布局和 `MAD_FONTS_DIR`。

**写出器。** `MAD/Source` 中的 `MADReportExporterPDFCairo` 是
`MADReportExporterPDF` 的非 Apple 主体；Apple 主体未动且不链接 Cairo。
结构目标、字体映射和确定性是
`docs/developers/build/pdf.md` 的。`MADPDFExportTests` 是两个引擎上的验收测试；
它读回 PDF 并把页数、MediaBox、每个框架和每
行文本与 `json-report` 基准比较，把条形码和图片作为图像
XObject 检查，并检查确定性字节相等。

**许可证。** cairo（MPL-1.1）、pixman（MIT）、FreeType（FTL）和 Liberation 字体
（SIL OFL 1.1）登记在 `THIRD_PARTY_LICENSES.md` §3.5 和 §10，其文本在
`ThirdParty/Licenses/`，且 `WindowsLicenseRegistry` 为 About
窗口列出全部四项。没有一项增加重新链接义务。

**Viewer。** WPF Viewer 的格式选择器像 Mac 的一样首先列出 PDF，并通过 `serve` 的路径形式（`export` 带 `path`）导出它，因此引擎写出
导出器的字节，响应携带字节数。文本格式保留 `data`
读回，其 UTF-8 解码对它们是无损的。不确定进度条和
“Exporting…”状态行覆盖该调用；`Format.Pdf` 和 `Viewer.Exporting` 字符串
在全部六个字典中发布。

## 7. 支持的 Windows 版本

.NET 10 支持的操作系统矩阵（Windows 10 Enterprise 21H2/1809/1607、Windows
11）和 GNUstep 的 Windows 10 1903+ 基线；在 Windows 11 Enterprise
26H2（build 26300）上测试。.NET 10 不支持 Windows 7/8。

## 8. 第三方许可与 Windows 关于页面

Windows 引擎是第三个分发表面，登记在
`docs/project/THIRD_PARTY_LICENSES.md` §10。它把 GNUstep 运行时加入
合规表面：

* **GNUstep Base、gnustep-corebase 和 libiconv 库**是
  LGPL-2.1-or-later。Windows 分发必须携带 LGPL-2.1 文本、
  声明以及 `ThirdParty/Licenses/README.md` 中的书面重新链接要约。
* **libobjc2（包括 libBlocksRuntime）和 libffi** 是 MIT；保留
  声明。
* **libdispatch** 是 Apache-2.0 加 Swift 运行时例外；发布完整
  文本。
* **FreeTDS 和 MariaDB Connector/C** 在既有 LGPL-3.0
  选择下静态链接；FreeTDS `sybdb.h` 编辑被标记，且既有
  重新链接要约现在命名 Windows 引擎。
* **C 库**（SQLite、zlib、bzip2、libarchive、libpng、zint、OpenSSL、
  libpq）使用 `ThirdParty/Licenses/` 中的既有条目和文本。
* **Microsoft Edge WebView2**（WPF Viewer 的预览控件，NuGet
  `Microsoft.Web.WebView2` 1.0.4314.35）是 Microsoft 产品，不是开源
  软件：Evergreen WebView2 Runtime 随 Windows 11 和 Edge
  安装，本项目既不修改也不再分发它。它以 SDK 的 BSD-3-Clause 许可证和
  Microsoft 的第三方声明、运行时的 Microsoft Software License Terms
  以及本项目的归属登记——全部在
  `ThirdParty/Licenses/Windows/WebView2-LICENSE.txt`。
* **gnustep-make** 是 GPL-3.0-or-later 构建工具，不分发；其
  `Testing.h` 只编译进测试二进制，不随发布。libiconv 的 `iconv` 工具和
  gnustep-corebase 的测试程序同样不
  分发。GNUstep Base 命令行工具（`gdomap`、`gdnc`、
  `defaults`、`plutil`、`gspath`）是 GPL-3.0-or-later，不属于
  `mad.exe`；不要在没有 GPL 文本和相应源码
  要约的情况下打包它们。

确切的 DLL/静态划分从构建出的 `mad.exe` 用
`dumpbin /dependents`（或 `llvm-objdump -p`）测量，并记录在 Phase 3b
报告中；它不根据工具链布局推断。构建和任何包
都必须复制 `ThirdParty/Licenses/` 和 `NOTICE`。

WPF **关于**窗口（Phase 5 shell 证明，Phase 6e 完成；引擎/应用版本分离在 Phase 6f 到来）
镜像 Mac 的三个标签——Overview、License & Notice 和 Acknowledgements——并
列出上述每个组件，包括 WebView2，文本来自
`ThirdParty/Licenses/Windows/`、共享根文本和 LGPL 书面
要约。Acknowledgements 列表是 Windows 组件列表，而非 Apple
应用的；License & Notice 标签携带 MIT/品牌声明和 Windows
重新链接要约；Overview 携带机器辅助翻译声明。其
外壳已本地化，而每个许可证正文、组件声明、许可证名称
和版权行保持逐字英语（`MAD_APP_LOCALIZATION.md` 的 D6/§8）。既有的 iOS 和 macOS About 屏幕保持
仅 Apple：它们列出 Apple 应用链接的 C 库，且不得宣称
Apple 应用链接 GNUstep 运行时。公开的 `docs/windows.md` 和
`README.md` 的 Windows 条目随 0.7 未签名发布（2026-11-21）落地；
该页面在文档契约（`docs/project/localization/LOCALIZATION.md`）下以全部六种语言存在。Windows 验证工作流
（`.github/workflows/windows.yml`）针对附加到
`v0.7.0` 的 `mad-windows-x64.zip` 引擎资产测试 .NET 套件；
`Windows/package.ps1` 组装该资产和应用发布 zip。

## 测试数据库

三个实时驱动套件（Phase 3b）针对 Apple/Linux 构建所用的同一锁定
Docker 测试服务器演练，以**绑定到 `127.0.0.1` 的本地 Windows
容器**运行（Mac 保留全接口发布，使
Linux 镜像和 CLI fixture 能按名称到达其容器）。跨平台
入口点是 `TestDatabase/test-databases.sh`（Git Bash）和
`TestDatabase/test-databases.ps1`（PowerShell），它们委托给三个
按框架的脚本；`TestDatabase/README.md` 是参考。

```powershell
.\TestDatabase\test-databases.ps1 -Action download   # fetch datasets, no Docker
.\TestDatabase\test-databases.ps1 -Action up         # create/start all three
.\TestDatabase\test-databases.ps1 -Action status     # -Service mysql|tds|postgres
.\TestDatabase\test-databases.ps1 -Action verify
.\TestDatabase\test-databases.ps1 -Action env        # print the env block
```

`env` 块是 Phase 3b 实时套件读取的契约；在与 `build.ps1`
相同的会话中应用它：

```powershell
$env:MAD_MYSQL_TEST_HOST = "127.0.0.1"; $env:MAD_MYSQL_TEST_PORT = "13306"
$env:MAD_MYSQL_TEST_USER = "root"; $env:MAD_MYSQL_TEST_PASSWORD = "root"
$env:MAD_MYSQL_TEST_SCHEMA = "employees"
$env:MAD_TDS_TEST_HOST = "127.0.0.1"; $env:MAD_TDS_TEST_USER = "sa"
$env:MAD_TDS_TEST_PASSWORD = "Root1@Root2"; $env:MAD_TDS_TEST_DATABASE = "AdventureWorksLT2022"
$env:MAD_PG_TEST_HOST = "127.0.0.1"; $env:MAD_PG_TEST_PORT = "5432"
$env:MAD_PG_TEST_USER = "mad"; $env:MAD_PG_TEST_PASSWORD = "mad_test_pw"
$env:MAD_PG_TEST_DATABASE = "chinook"
```

没有 `MAD_TDS_TEST_PORT`——TDS 套件硬编码 1433。驱动构建
结果记录在 Phase 3b 报告中，不在此处。

## 相关文档

* `docs/developers/build/linux.md` 和 `Linux/README.md`——本
  Windows 构建所镜像的 Linux 构建。
* `docs/developers/build/macos.md` 和 `Mac/README.md`——WPF 应用将镜像其行为的
  原生 macOS 应用。
* `docs/project/THIRD_PARTY_LICENSES.md` §10——Windows 引擎的许可证
  登记表；`ThirdParty/Licenses/` 和 `ThirdParty/Licenses/Windows/`——
  文本和书面重新链接要约。
