---
layout: default
lang: zh-CN
---

# 警告与静态分析清理——工作计划

跨所有目标进行编译器警告 / 分析器清理的工作文档。
**有意排除在版本控制之外**（见 `.gitignore`）；它是一个草稿跟踪器，而不是项目记录。持久性的发现仍按常规方式记录到 `BUGS.md`。

配套数据转储：`WARNINGS_INVENTORY.md`（每个唯一问题，file:line）。

---

## 状态

| 阶段 | 内容 | 状态 |
|---|---|---|
| 0 | 设置审计——每个项目、每个目标 | **已完成** |
| 1 | 基线采集——干净构建 + 分析、清单 | **已完成**（2026-10-04） |
| 2 | 就通用编译设置达成一致、应用、提交 | **已完成**——提交 `c613d5540` |
| 3 | 用新设置重新运行构建 + 分析 | **已完成**——1012 个唯一问题 |
| 4 | 分诊；分类为修复 / 记录 / 保留 | **已完成**——见下文日志 |
| 5 | 修复无副作用的项目；验证 | **已完成**——1012 → 127 个编译器警告 |
| 6 | 记录有风险的剩余项；最终报告 | **进行中**——BUGS.md 条目已写好，最终分析正在运行 |

### 最终状态（2026-10-04）

**编译器警告：127 个不同项**（设置更改后为 906 个，加上分析器共 1012 个）。剩余的每个类别要么经检查无害，要么已在 BUGS.md 中记录：

| 剩余项 | N | 处置 |
|---|---|---|
| `-Wnullable-to-nonnull-conversion` | 34 | 良性：可能为 nil 的键用于字典下标（`objectForKey:` 返回 nil）以及容忍 nil 的集合查询 |
| `-Wimplicit-int-float-conversion` / `-Wimplicit-int-conversion` | 42 | 仅精度问题；检查后未发现崩溃路径 |
| `-Wshadow` | 7 | 名称遮蔽，无行为变化 |
| `-Wdeprecated-declarations` | 5 | 已记录：收据 SHA-1 验证器、QuickLook 缩略图键 |
| `-Wquoted-include-in-framework-header` | 5 | 厂商内置头文件（png.h、client_plugin.h）——有意不动 |
| `-Wstrict-selector-match` | 3 | 已记录（MADReportFormatter 动态 `compare:`） |
| `-Warc-repeated-use-of-weak` | 2 | 已记录：RptqObject.m 中安装的访问器块；提升变量会造成循环 |
| `-Warc-retain-cycles` | 2 | 已记录：AppDelegate 重试钩子 |
| `-Wincompatible-pointer-types` | 2 | 已记录：FreeTDS 日期结构的二重性 |
| `-Wnonnull`、`-Wmismatched-return-types`、`-Wobjc-dictionary-duplicate-keys`、`-Wincomplete-implementation`、`-Wformat` 以及单项 | ~20 | 每项都在 BUGS.md 中记录 |
| 构建系统提示（`<no-flag>`） | 6 | 没有声明输出的脚本阶段；已记录，不是缺陷 |

**分析器：106 个结果**，本次清理未改变数量，因为它们是与编译器警告不同的发现集。它们的处置：

| 检查器 | N | 处置 |
|---|---|---|
| 本地化（未本地化 / 空上下文） | 34 | 本地化积压，按决策保留 |
| `deadcode.DeadStores` | 25 | 死存储；无崩溃路径，留作清理 |
| `osx.NumberObjectConversion` | 14 | NSNumber/double 转换；检查后无害 |
| `nullability.NullReturnedFromNonnull` + `NullPassedToNonnull` | 22 | **已记录**于 BUGS.md（三个分组条目） |
| `osx.cocoa.NSError` | 4 | `NSError **` 处理；API 设计说明 |
| `core.CallAndMessage` | 2 | **已记录**（未初始化值） |
| `security.insecureAPI.strcpy` | 2 | **已记录**，与 MTBarcode 字典键条目一起 |
| `CFNumber`、`NilArg`、`RetainCount` | 3 | **已记录**（MADSectionLayout、MADModelQuery、收据键） |

本次清理在 BUGS.md 中新增了十六条条目（十一个编译器警告发现、三个分析器可空性条目，以及更早的两条：收据 SHA-1 和 QuickLook 缩略图）。

### 变更后基线（阶段 3，构建）

使用统一设置对应用 scheme 做干净的 Debug 构建：**906 个不同的编译器警告**（如果把每个重复报告共享框架头文件的目标分别计数，则为 948 个），相比 278 个有所上升——每一个都是既有问题且新变得*可见*，没有新的破坏。Analyze 增加了 **106 个分析器结果**（原为 91 个）。构建和所有测试包都能编译。

**总计：1012 个唯一问题**（906 个编译器 + 106 个分析器），原为 369 个。

| 诊断 | N | 说明 |
|---|---|---|
| `-Wunused-parameter` | 236 | C/C++ 回调（应用中 165 个，MAD 中 24 个） |
| `-Wincomplete-umbrella` | 232 | 模块已开启：伞头文件遗漏公共头文件（仅 MAD.h 就有约 65 个） |
| `-Wquoted-include-in-framework-header` | 56 | 原为 33；现在更多目标带有该检查 |
| `-Wincompatible-pointer-types` | 81 | 未变 |
| `-Wsign-compare` | 70 | 新启用 |
| `-Wnullable-to-nonnull-conversion` | 64 | 原为 46 |
| `-Wexplicit-ownership-type` | 34 | 未变 |
| `-Wimplicit-int-float-conversion` | 22 | |
| `-Wimplicit-int-conversion` | 20 | 新启用 |
| `-Warc-repeated-use-of-weak` | 15 | 未变 |
| `-Wunknown-pragmas` | 12 | 新启用 |
| `-Wdocumentation` | 11 | 新启用 |
| `-Wpointer-integer-compare` | 9 | 未变 |
| `-Wdeprecated-declarations` | 8 | |
| 其余所有 | ~40 | |

按框架：应用 381、MAD 323、MADTdsClient 76、MADFileManager 25、MADSqlite3 21、MADExplorer 20、MADBarcodes 20、MADAPI 11，其余 < 10。

验证：应用 scheme 的干净构建，以及应用和 MADFoundation / MADSqlite3 / MADBarcodes 测试包的 `build-for-testing`——全部成功。（模拟器必须按 id 指定：三个“iPhone 17 Pro”设备存在于不同的运行时上，因此仅用名称的 destination 是有歧义的。）

---

## 基线（阶段 1——2026-10-04，Xcode 27.0）

通过干净的 Debug 构建和对 `MAD Designer` scheme 的 analyze（覆盖整个依赖图）复现了所报告的数字：

| 操作 | 原始日志行 | 唯一问题 | 报告值 |
|---|---|---|---|
| `xcodebuild build` | 629 | **278 个编译器警告** | ~280 |
| `xcodebuild analyze` | 719 | **368 = 277 个编译器 + 91 个分析器** | 309 + 91 |

合并清单（构建 + 全部 15 次 scheme 分析运行，按 file/line/diagnostic 去重）：**377 个唯一问题——286 个编译器警告 + 91 个分析器结果。**

分布：MAD 框架 209、应用 128、其他所有框架合计约 36、构建系统提示 7。

完整列表：`WARNINGS_INVENTORY.md`。

### 采集命令（可复现）

```sh
xcodebuild build -workspace Reports.xcworkspace -scheme "MAD Designer" \
  -configuration Debug -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/warnaudit/dd_build CODE_SIGNING_ALLOWED=NO

xcodebuild analyze -workspace Reports.xcworkspace -scheme "MAD Designer" \
  -configuration Debug -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/warnaudit/dd_analyze CODE_SIGNING_ALLOWED=NO
```

---

## 阶段 2 提案——通用编译设置

目标：为每个框架和应用目标制定一套规范的警告 / 分析器策略，集中在一处，使“设置”在各处一致，不可能发生漂移。

### 机制（决策 D1）

**提议：** 一个共享的 `Config/CompileSettings.xcconfig`，在全部 15 个工作区项目中作为每个目标 Debug 和 Release 的基础配置引用，并删除这些键的各项目 / 各目标副本，让 xcconfig 起支配作用。`Compressor/sqlite3.xcconfig` 文件是如何记录该做法的先例。

*替代方案：* 把相同的值粘贴到每个项目（保留当前机制，但漂移会回来）。

### A. 核心设置——在所有地方采用（Xcode 当前模板基线）

已同意为无争议项；这些在大多数目标中已经开启。

| 设置 | 值 |
|---|---|
| `CLANG_ENABLE_MODULES` | YES |
| `CLANG_ENABLE_OBJC_ARC` | YES |
| `CLANG_ENABLE_OBJC_WEAK` | YES |
| `CLANG_CXX_LANGUAGE_STANDARD` | `gnu++20` |
| `GCC_C_LANGUAGE_STANDARD` | `gnu17` |
| `GCC_NO_COMMON_BLOCKS` | YES |
| `ENABLE_STRICT_OBJC_MSGSEND` | YES |
| `CLANG_WARN__DUPLICATE_METHOD_MATCH`, `_BLOCK_CAPTURE_AUTORELEASING`, `_BOOL_CONVERSION`, `_COMMA`, `_CONSTANT_CONVERSION`, `_DEPRECATED_OBJC_IMPLEMENTATIONS`, `_EMPTY_BODY`, `_ENUM_CONVERSION`, `_INFINITE_RECURSION`, `_INT_CONVERSION`, `_NON_LITERAL_NULL_CONVERSION`, `_OBJC_IMPLICIT_RETAIN_SELF`, `_OBJC_LITERAL_CONVERSION`, `_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER`, `_RANGE_LOOP_ANALYSIS`, `_STRICT_PROTOTYPES`, `_SUSPICIOUS_MOVE`, `_UNREACHABLE_CODE` | YES |
| `CLANG_WARN_DIRECT_OBJC_ISA_USAGE` | `YES_ERROR` |
| `CLANG_WARN_OBJC_ROOT_CLASS` | `YES_ERROR` |
| `CLANG_WARN_DOCUMENTATION_COMMENTS` | YES |
| `GCC_WARN_64_TO_32_BIT_CONVERSION`, `GCC_WARN_UNDECLARED_SELECTOR`, `GCC_WARN_UNUSED_FUNCTION`, `GCC_WARN_UNUSED_VARIABLE` | YES |
| `GCC_WARN_ABOUT_RETURN_TYPE` | `YES_ERROR` |
| `GCC_WARN_UNINITIALIZED_AUTOS` | `YES_AGGRESSIVE` |
| `GCC_TREAT_WARNINGS_AS_ERRORS` | NO（保留——警告不得中断构建） |

### B. “最大信息量”设置——恢复到每个框架

目前存在于大约一半的目标中（为高信噪比手工配置的那些）；有几个框架从未获得。建议全部采用。

| 设置 | 值 | 预期新发现 |
|---|---|---|
| `CLANG_WARN_IMPLICIT_SIGN_CONVERSION` | YES | 中等 |
| `CLANG_WARN_SUSPICIOUS_IMPLICIT_CONVERSION` | YES | 少量 |
| `CLANG_WARN_NULLABLE_TO_NONNULL_CONVERSION` | YES | 已在触发（46） |
| `CLANG_WARN_OBJC_EXPLICIT_OWNERSHIP_TYPE` | YES | 已在触发（34） |
| `CLANG_WARN_OBJC_IMPLICIT_ATOMIC_PROPERTIES` | YES | 少量 |
| `CLANG_WARN_OBJC_REPEATED_USE_OF_WEAK` | YES | 已在触发（15） |
| `CLANG_WARN_ASSIGN_ENUM` | YES | 少量（在 5 个目标中曾显式设为 NO） |
| `CLANG_WARN_UNGUARDED_AVAILABILITY` | `YES_AGGRESSIVE` | **可能很多**——对每个比 iOS 15 新的 API 都发出警告（见 D3） |
| `GCC_WARN_SHADOW` | YES | 现在 4 个，缺少它的框架会带来更多 |
| `GCC_WARN_SIGN_COMPARE` | YES | 中等 |
| `GCC_WARN_STRICT_SELECTOR_MATCH` | YES | 现在 3 个 |
| `GCC_WARN_ABOUT_MISSING_FIELD_INITIALIZERS`, `_MISSING_PROTOTYPES`, `_MISSING_NEWLINE` | YES | 少量 |
| `GCC_WARN_INITIALIZER_NOT_FULLY_BRACKETED` | YES | 少量 |
| `GCC_WARN_UNUSED_LABEL` | YES | 少量 |
| `GCC_WARN_UNKNOWN_PRAGMAS` | YES | 少量 |
| `GCC_WARN_UNUSED_PARAMETER` | YES（见 D3） | 仅 C/C++ 函数，不含 ObjC 方法 |

### C. 分析器

| 设置 | 值 |
|---|---|
| `CLANG_ANALYZER_NONNULL` | YES |
| `CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION` | `YES_AGGRESSIVE` |
| `CLANG_ANALYZER_SECURITY_FLOATLOOPCOUNTER`, `_INSECUREAPI_RAND`, `_INSECUREAPI_STRCPY` | YES |
| `CLANG_ANALYZER_LOCALIZABILITY_NONLOCALIZED`, `_EMPTY_CONTEXT` | 见 D4 |

### D. 决策（2026-10-04 达成一致）

- **D1——机制：按项目。** 这些值直接写入每个项目的构建设置（项目级别，因此项目中的每个目标都会继承）。不使用 xcconfig。
- **D2——范围：每个工作区目标**，包括两个应用目标和测试包。`Scrimpter` 和 `ReceiptModuleAsn1c` 保持不动且开放——它们在工作区之外，不计入基线。
- **D3——附加项：采用。** 激进的可用性检查、未使用参数和本地化分析器全部纳入。已验证安全：`MADTds` 已使用 `-Wunguarded-availability` 编译，基线中产生的可用性诊断**为零**，因此该标志今天没有成本，且能保护新代码。
- **D4——MADSqlite3：移除全部五个抑制。** 该合并源码*并未*在 `MADSqlite3` 目标中编译——链接进来的是 Compressor 构建的 `sqlite3.xcframework`——所以那些标志一揽子压制了框架自己的 27 个 Objective-C 源文件。引擎在其自己的构建中保留 `Compressor/lib/recipes/sqlite3.sh` 给它的任何标志。

### E. 已记录的例外（按文件标志）

- `MADDesigner/Source/rwpng/rwpng.c` 以*按文件*的编译器标志携带 `-fno-modules`。它是纯 C，并包含 `<MADBarcodes/png.h>`；在应用目标开启模块的情况下，该包含会通过框架的伞头文件解析，而伞头文件会导入 Foundation——这在 C 翻译单元中是不可能的。该标志精确恢复了文件在启用模块之前的行为，并且是工作区中唯一的此类例外。

### F. 顺带完成的清理

- 删除残留的空操作：`MADFoundation` 为空的 `WARNING_CFLAGS`、`MADFeedback` 的 `-Wno-error=unused-command-line-argument`（死代码——任何地方都没有 `-Werror`）、显式的旧 `GCC_TREAT_*_AS_ERRORS = NO` 键。
- **重新审视 `MADSqlite3` 的五个目标级抑制**（`-Wno-sign-conversion`、`-Wno-shorten-64-to-32`、`-Wno-implicit-int`、`-Wno-pointer-sign`、`-Wno-comma`）。它们一揽子覆盖该框架全部 27 个第一方源码。建议：移除并修复后果。
- 保留 `MAD` 对厂商内置 `miniz.c` 的按文件抑制（对第三方代码的正确做法），并在原处记录。
- 厂商内置头文件（`png.h`、`sybdb.h`、`client_plugin.h`）占 33 个引号包含警告中的 4 个；在第一方 29 个修复后再决定。

---

## 分诊队列（来自阶段 1 基线）

各警告类别，按设置确定后将要处理的顺序排列：

| 类别 | N | 初读 |
|---|---|---|
| `-Wincompatible-pointer-types` | 81 | `insertObjectForEntity:` 返回 `RptqObject *`；调用方赋给具体类型 |
| `-Wnullable-to-nonnull-conversion` | 46 | 潜在的 nil→nonnull 崩溃；逐点处理 |
| `-Wexplicit-ownership-type` | 34 | 仅声明性（`NSError *__autoreleasing *`） |
| `-Wquoted-include-in-framework-header` | 33 | MAD 公共头文件；头文件卫生 |
| 本地化分析器 | 34 | 产品决策（D4） |
| `deadcode.DeadStores` | 25 | 清理；少数可能是真的 |
| `-Wimplicit-int-float-conversion` | 21 | 仅精度问题，布局计算除外 |
| `-Warc-repeated-use-of-weak` | 15 | **真实风险**（两次读取之间 weak 变为 nil） |
| `-Wdeprecated-declarations` | 13 | Security.framework 收据代码（iOS 15 弃用） |
| 可空性分析器 | 22 | `NullReturnedFromNonnull` + `NullPassedToNonnull`——崩溃风险 |
| `-Wpointer-integer-compare` | 9 | 可疑；很可能属实 |
| 其余所有 | ~40 | 逐项处理 |

### 已标记的突出问题（优先分诊）

- `MAD/Source/MADSectionLayout.m:61`——CFNumber 64→16 位：**内存损坏**
- `MADDesigner/Source/MADToolboxStyleViewController.m:609`——未初始化的参数
- `MADMySQL/Source/MysqlFetch+DataTable.m:668`——传给调用的未初始化值
- `MADDesigner/Source/MADQueryViewController.m:605`——`%` 格式类型不匹配（UB）
- `MADDesigner/Source/barcodes/MTViewControllerBarcode.m:321,325`——实现 / 声明的返回类型冲突
- `MAD/Source/UIManagedDocument+Extras.m:17`——声明的方法从未实现
- `MADDesigner/Source/AppDelegate.m:205,256`——循环引用
- `MADDesigner/Source/MADVerificationController.m:482`——泄漏 + 已弃用的 SHA-1 收据验证
- `MAD/Source/MADModelQuery.m:301`——使用 nil 调用 `setObject:forKey:` → 崩溃
- `MADBarcodes/.../MTBarcode.m:719`——重复的字典键；`:492`——`strcpy`
- `MADFoundation/Source/MADDataTable.m:150,187`——未做空检查就解引用 `NSError **`
- `MADDesigner/Targets/MADViewer/MADViewerAppDelegate.m:55`——协议不符合
- `MAD/Source/paper/MTPaper.m:241`——指定初始化器违规
- `MAD/Source/MADocument.m:598,624`——null 传给 nonnull

---

## 阶段 7——按模块（2026-10-04 开始）

工作约定：每个修复都伴随一个表征测试，锁定修复所触及的行为，在修复前后各运行一次；提交前重新运行模块测试套件并保持绿色。

### MADFoundation——已完成

`MADDataTable.m`（`-loadFromCacheWithUrl:`）中有两个 `osx.cocoa.NSError` 分析器发现：两者都通过 `outError` 写入，却没有该方法其他三条失败路径所用的 `if (outError)` 防护，因此传入 NULL 错误参数会崩溃。一次模块扫描确认这是 MADFoundation 中仅有的两处未防护写入。

- **证明：** 修复前，`MADDataTableRegressionTests` 中的两个新表征测试使测试进程崩溃（“Restarting after unexpected exit, crash”）。
- **修复：** 添加防护（提交 `0f4387f88`）。
- **验证：** `MADDataTableRegressionTests` 中 76/76 通过（包括既有的 -215 和 nil-URL 抛错契约），MADFoundation 模块套件 118/118 通过。
- **记录：** BUGS.md，状态：已修复。

### MADTds + MADTdsClient——已完成（提交 `92b2b7ace`）

**MADTds 的三个问题是两个构建提示加一个厂商内置头文件：**
- “Ensure Libraries ... will be run during every build”——该 Compressor 阶段是一个清单检查，本就打算每次构建都运行；在携带它的全部六个项目中标记为 `alwaysOutOfDate`。警告已清除，无行为变化，不需要重新构建。
- “Copy Headers delayed by unsandboxed script phases”——需要 ENABLE_USER_SCRIPT_SANDBOXING=YES，那会破坏 Compressor。已记录。
- FreeTDS 的 `sybdb.h` 引号包含——厂商内置且涉及许可证敏感。已记录。

**MADTdsClient：** 两个 `initWithFloat:` 窄化点现在使用 `initWithDouble:`，与相邻的 SYBFLT8 分支保持一致。负向测试运行表明，该变化在 SQL Server 的类型下不可观察（REAL 是 float 精确的；FLOAT 以 SYBFLT8 到达），因此新测试守护 8 字节路径，并明确说明了这一点。套件：连接实时服务器 76/76 通过。

注意：构建 MADTdsClient 也会带出三个 MADAPI 警告（MADDatabaseConnection.m:36、MADDatabaseField.m:124,125）——属于 MADAPI 自己，留待其模块处理。

### MADFileManager——已完成（提交 `8ef45c29d`）

该模块的三个 `-Wshadow` 发现已修复（MADFilesController 的内部块重新声明了 `sself`；MADFileUtilities 在两个块中遮蔽了 `path`），并审计了 MADFileUtilities 的公开接口：三个方法没有调用方，被从头文件降入一个标记为 `__attribute__((unused))` 的私有类扩展——`deleteCoreDataFilesAtDirectory:`（单参数）、`copyInitialFiles:groupId:`、`readObjectOfClass:fromURL:completion:`。`moveFileAtURL:toUrl:completion:` 仅在内部使用；记为未来候选。31/31 测试通过，整个工作区构建干净，127 -> 116。

剩余的 `-Wshadow`（4 个）是 RptqObject.m 中名为 `self` 的块参数——属于 MAD 的模块。

### MAD——已完成（提交 `c807eeb4d`）

38 个警告 -> 3 个已记录的（writeContents: 的 nil 参数、`compare:` 派发、未实现的 resetPersistentStore）。热路径改动仅限于一项*改进*：RptqObject 的 to-many 访问器块现在每次调用读取一次弱存储上下文，而不是每个成员读取一次，同一次编辑还重命名了遮蔽 `self` 的块参数。其余全是类型转换、提升到局部变量以便既有防护能够收窄、`entityNamed:` 上的可空参数、两个改为合并而非抛出的比较器，以及 MTPaper 的私有 `init` 不再声称是指定初始化器。MAD 的套件：240/240 通过。

注意：MADTests（测试包）带有自己的一组警告——可空转换、未使用参数，以及与应用相同的 `objectForEntity:` 向下转换模式。它从来不属于应用构建计数；如果需要，这是一次单独的、更小的清理。

### 按模块接下来

剩余的副作用候选，按处理顺序排列：MAD（`MADSectionLayout` 的 CFNumber 损坏、`MADModelQuery` 的 nil `setObject:`、`MADocument` 的 writeContents:、`MADStoreGraph`、`RptqDocument+Extras`）、MAD Designer（条码委托不匹配、AppDelegate 循环）、MADSqlite3（`MADDataTableFast` 返回）。

## 日志

- **2026-10-04**——设置审计（16 个项目）完成；基线已采集；清单已编写。等待就阶段 2 设置提案达成一致。
- **2026-10-04**——决策达成一致（按项目应用；所有工作区目标；保留激进可用性 + 未使用参数 + 本地化检查；移除 MADSqlite3 抑制）。已应用到 14 个项目并作为 `c613d5540` 提交。一个按文件例外：`rwpng.c` 获得 `-fno-modules`。重新运行构建：948 个唯一警告，构建和测试包均为绿色。
- **2026-10-04**——阶段 7 开始：MADFoundation 的两个空解引用发现已修复并用测试锁定（`0f4387f88`）；MADFoundation 118/118，MADDataTable 回归类 76/76。
- **2026-10-04**——分诊开始（阶段 5）。已修复并提交：伞头文件 + 引号包含（`8905c3ad7`）、`__unused` 参数（`95d400751`）、SQL Server 驱动中的符号比较（`287407ff4`）、76 个存储上下文向下转换（`61e38740c`），然后是机械类别——`__autoreleasing`、`#pragma mark`、文档注释、int 与 nil 的比较、弱引用读取提升（`6bd74163d`）。新增两条 BUGS.md 条目（收据 SHA-1 + 泄漏；QuickLook 缩略图键）以及 FreeTDS 日期结构说明（`39870b9e3`）。干净构建计数：**157 个唯一项**，从设置更改后的 906 个降下来。剩余：nullable-to-nonnull 64（已分类，等待审查）、implicit-int-float 22、implicit-int-conversion 20、shadow 7、deprecated 5、厂商内置引号包含 5，以及单项。

---

## 阶段 8——五个被要求的框架（2026-10-17）

基线：用户今天 17:06 对 `MAD Designer` 做的干净 Analyze——总体上 128 条原始 / 124 个唯一警告，以及 98 个分析器结果。这五个框架携带 24 个第一方诊断（编译器 + 分析器），外加两条厂商内置头文件提示和三条 Compressor 构建提示。

每个框架都在独立的、干净的私有派生数据路径下单独分析：

```sh
xcodebuild clean analyze -workspace Reports.xcworkspace -scheme <Scheme> \
  -configuration Debug -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/reports-cleanup/dd-<Scheme> \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES COMPILER_INDEX_STORE_ENABLE=NO \
  CODE_SIGNING_ALLOWED=NO
```

| 框架 | 清理数 | 结果 | 提交 |
|---|---:|---|---|
| MADTds | 0（仅有已记录的第三方 / 构建项） | 干净 | `c55cef2bc` |
| MADTdsClient | 8 | 76/76 实时套件绿色 | `93c2e1d57` |
| MADMySQL | 3（+2 条本地化注释） | 121/121 实时套件绿色 | `598cadd03` |
| MADAPI | 3（+12 个测试包 `-Wnonnull`） | 105/105 通过 | `cd814227d` |
| MADSqlite3 | 11（+5 个测试包可空项） | 89/89，跳过 5 个基准测试 | `daff35986` |

与用户共同做出的行为决策：

- MADTdsClient 被丢弃的 SQL 错误：记录到 `GetTdsLog()`，并通过 `-runSQL:` 上新增的 `NSError **` 传播；`-runQuery:` 和 `-executeSQL:` 现在会转发各自的错误。
- MADMySQL 的 NULL `error` 指针：添加防护，与相邻代码保持一致。
- `MYSQL_BIND`：零初始化。
- MADArrayCaching：使用指定初始化器，`-init`/`+new` 不可用，断言标识符非空，缓存 URL 加防护。
- MADDataTableFast：nil 目录路径会重新计算；nil 排序键显式抛出错误；nil 的最后一行缓存会回落到查询，每个进程记录一次日志。

最终检查（2026-10-17）：

- 全部五次按 scheme 的分析运行：**零个第一方诊断**（只剩厂商内置的 `sybdb.h` / `client_plugin.h` 引号包含和 Compressor 沙箱提示）。
- `MAD Designer` Debug 构建：**BUILD SUCCEEDED**，剩余 115 条原始警告行，没有一条来自这五个框架。
- `./Linux/build.sh`：见日志；这五个框架在那里编译，移植的套件运行。

从最初的 124/98 中仍未关闭的有：应用（MADDesigner，47 个编译器 + 57 个分析器 + 23 个 IB）、MAD（10 + 27）、MADBarcodes（22 + 2）、MADExplorer（1），以及每个测试包中的部署目标链接器警告（XCTest 17.0 对 iOS 15.0）——属于项目设置工作。
