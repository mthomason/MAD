---
layout: default
lang: zh-CN
---

# MAD 脚本化：Scrimpter 复活问题、公式元素与备选方案

*写于 2026-10-23。状态：分析，建议待用户决定。本文档回答针对 `Scrimpter` 提出的四个问题——它能否被修正、测试、集成，以及它的设计是否正确——并比较各备选方案（包括 C# 问题）及各自的许可范围。它记录事实，而不是队列：此处没有任何内容会启动工作。*

---

## 1. 问题

设计器的元素面板原本要包含一个**可脚本化字段**——即公式元素——而 `Scrimpter`（2014 年 6 月）就是为它编写的脚本语言。用户因为维护成本过高而将其移除，现在在具备 AI 智能体的情况下重新提出以下问题：

1. `Scrimpter` 目前处于什么状态？
2. 要让它正确、补充测试并完全集成，需要付出什么？
3. 设计是否正确？
4. 这是一个好主意吗，还是已经有更好的受支持语言？（用户记得“一个 C# 变体”——在第 6 节评估。）

核心结论：**公式元素在应用里已经完成了一半，但引擎根本不在应用中。Scrimpter 是一个 2014 年的解释器，构建已损坏、文法存在冲突，还有若干真实缺陷——全都可以修复，但没有一个是可以暗中蒙混的。C# 在 iOS 上没有可行路径。引擎决策按照用户的指示（2026-10-23）推迟：不创建新语言，速度和可移植性很重要，当工作启动时，实施智能体必须回来请用户选择引擎（第 8 节）。**

## 2. Scrimpter 今天是什么

### 2.1 形态与规模

* `Scrimpter/` 是一个**独立的 Xcode 项目，不在工作区中**（`Reports.xcworkspace` 列出了除它之外的每个框架）。它构建的是一个**静态库**（`libScrimpter.a`），而不是框架，并带有一个 XCTest 测试包。它没有共享 scheme——只有一个用户 scheme，因此 CI 和 `xcodebuild test -scheme` 都无法触达它（`Scrimpter/AGENTS.md` 已承认这一点）。
* **约 2,340 行 Objective-C**，分布在 44 个文件中：一个词法分析器规范（`scanner.lm`，144 行）、一个 yacc 文法（`parser.ym`，296 行）、一个 AST 类簇（`MTAbstractSyntaxTree` 加 17 个 `MTAstNode*` 子类）、一个符号表和一个值包装器（`MADValue`）。
* `ScrimpterTests.m` 中的 **47 个测试方法**锁定了算术、优先级、比较、if/else、变量、字符串、注释、方法调用函数（`power`、`ceil`、`mod`、`concat` 等）以及一个错误用例。它们是这个项目里最好的部分。
* **原创作品**：每个文件的版权都归 Michael Thomason。任何地方都没有第三方语言源码。（`origin/scrimpter` 分支是 2014 年的陈旧应用历史，落后 master 3,433 个提交——它不是这门语言的开发分支；忽略它。）

### 2.2 历史

编写于 2014 年 6 月（按文件日期），2014 年间被移动/改进，合并（`e9d52f544`），随后搁置。最后一次实质性提交：**2024-07-23**（“修复了一些缺陷”）。关键在于，它所依赖的 `MADDataStructures` API 在 **2016-03** 被重做（`bff7e576e`、`78a3cf3c1`）——而 Scrimpter 从未随之更新。从那时起，它无论如何都无法编译，也从未链接进应用：没有任何 `MADDesigner` 项目文件引用过 `Scrimpter`。

### 2.3 构建状态——2026-10-23 经实证测试

| 步骤 | 结果 |
|---|---|
| `xcodebuild -target Scrimpter` | 立即失败：`IPHONEOS_DEPLOYMENT_TARGET` 为 8.0/8.2；当前 Xcode 要求 ≥ 15.0 |
| 将目标覆盖为 15.0 后同样如此 | Xcode 的 Lex/Yacc 构建规则**仍然存在**并且会运行，但 `LEX = /opt/local/bin/flex` 和 `YACC = /usr/local/bin/yacc` 在任何当前的 Mac 上都不存在 → “unable to spawn process” |
| 系统工具 | `/usr/bin/flex` 2.6.4 存在。`/usr/bin/bison` 和 Xcode 工具链的 bison 都是 **2.3**，它会拒绝 `%code requires`（`parser.ym:42`）——该指令在 bison 2.4 中才加入。没有 Homebrew 的 bison。所以这台机器上现有的任何工具链都无法生成该解析器 |
| 文法生成（仅测试用的补丁：将 `%code requires` 改为序言） | bison 2.3 可以生成，并报告 **19 个移进/归约冲突和 22 个归约/归约冲突**，另有一个无用的非终结符（`expstr`，`parser.ym:153`——字符串只能通过 `term` 解析） |
| 针对 iOS 27.1 SDK 对生成的解析器/扫描器及全部 30 个源文件做语法检查 | 所有错误都是 **MADDataStructures API 漂移**，别无其他：`[MTPair pairWithLeft:andRight:]` 现在是 `newPairWithLeft:andRight:`（`MADDataStructures/Source/MTPair.h`），`MTTree initWithLeftTree:andRightTree:` 现在是 `initWithData:leftTree:rightTree:`（`MTTree.h`）。约 6 个文件中的机械重命名 |

项目中悬空的 `MADDataStructures.framework` 引用已于 2026-10-01 删除（`BUGS_FIXED.md`，“三个库引用指向从未创建的目录”）；重新链接会像其他每个框架一样，通过工作区共享的 `BUILT_PRODUCTS_DIR` 进行。Linux 构建完全排除了 Scrimpter——没有 `Linux/cmake/ScrimpterSources.cmake`，而且镜像里没有 flex/bison（`MAD_LINUX.md` 第 3 节：“Apple 导入为 0，但未使用”）。

**结论：**构建在四个相互独立的层面断裂——部署目标、工具路径、bison 版本，以及一次 2016 年的 API 漂移。每处修复都很小且机械；但从未被应用。

## 3. 正确性审计——已验证的缺陷清单

大致按严重程度排序。每一项都源于源码或生成输出的复现。

### 关键

1. **`while` 会让解析器挂起。** `parser.ym:130`：`stmt: WHILE exp DO list { while ($2) { $$ = $4; } }`。该循环在**解析时**运行，而 `$2` 是一个永远不会变为 nil 的 AST 指针——导致无限循环。任何包含 `while` 的脚本都会让应用挂起。没有测试覆盖 `while`；本应实现它的 AST 类（`MTAstNodeFlow`、`SCFlowTypeWhile`、`initLoopWithList:`）存在，但从未被构造。
2. **多参数函数调用会崩溃。** `MTAbstractSyntaxTree.m:188-191`：`initWithExpression:andList:`（解析器为 `expr(a, b, …)` 调用的工厂方法）会分配一个 `MTAstNodeStatementList`，并向它发送 `initWithExpression:andList:`——而该类并未实现这个选择器（它只有 `initWithStatement:andList:`）。运行时出现无法识别的选择器。没有测试向一次调用传入两个参数（链式测试每次调用都是单参数）。
3. **文法存在深层歧义。** 没有 `%left`/`%right` 声明；比较出现在两个重叠的产生式中（`exp COMPARESON exp` 与 `expnum COMPARESON factor`）。19 个 s/r 加 22 个 r/r 冲突由 yacc 默认规则解决，因此解析的确定性只是生成顺序的偶然产物。今天测试通过的优先级行为并不由文法保证。
4. **布尔值→数值转换是反的。** `MADValue.m:60`：`r = [self.value boolValue] ? 0 : 1.0;`——`true` 转换为 0，`false` 转换为 1。任何涉及布尔值的算术都是错的。

### 实质性

5. **数据绑定这一半从未完成。** `MADSymbol.h:20` 声明了 `ScrimptData`（宿主的 `dataForkey:` 查找），`MADScrimpter.m:45` 设置了它——但**没有任何 AST 节点调用它**。语言中没有读取字段值的语法。唯一的数据路径是由宿主预先填充符号表，而这同样没有公开 API。`ScrimpterDataSource` 协议是一个退化的残迹。
6. **没有日期类型。** `MADValue` 支持 double、string、boolean、null。BI 公式需要日期（报表格式化器已经在 `RptqDocumentElement+Extras.m -formattedString:forValue:` 中对日期做了特殊处理）。没有日期的公式语言无法做“逾期天数”。
7. **用户自定义函数是一个死类。** `MTAstNodeFunctionCallUserDefined` 没有重写 `evaluate`，从未被构造（不存在函数定义语法），即便构造也会返回 Null。
8. **`return` 不会终止语句列表。** `MTAstNodeStatementList.m:25` 检查 `statement.nodetype != SCNodeTypeResult`——但 `statement` 是 `MTAstNodeStatement` 包装器（类型为 `SCNodeTypeStatement`），因此该检查永远不会触发，`return` 之后的每条语句仍会被求值。对于纯表达式这无害，但一旦函数产生副作用，这就是地雷。
9. **用弱引用字符串作为身份标识。** `MADSymbol.name`（`MADSymbol.h:26`）和 `MADSymbolReference.symbol`（`MADSymbolReference.h:11`）是 `weak` 的 NSString 属性。这些字符串今天能存活，只是因为 NSString 字面量和标记指针从不消亡。只要有一个符号来自非字面量来源，符号表就会静默忘记它的名字。
10. **NaN 防护是死代码。** `MTAstNodeFunctionCallEmbedded.m:108`：`if (base != NAN)`——`NaN != NaN` 恒为真，因此该防护永远不会触发；只有后面的 `isnan(r)` 能捕获它。只是碰巧能工作。
11. **不可重入，非线程安全。** 引擎的整个状态都是全局变量：块 `ScrimptSymbolTable/ScrimptData/ScrimptSymbol/ScrimptSymbolReference/Scrimpted`（`MADSymbol.m:11-14`、`MADScrimpter.m:14`）加上 flex/bison 的 `yylval`/`yylloc` 全局变量。两个 `MADScrimpter` 实例（或者一个实例被两个线程使用——正是查看器求值许多公式元素时会发生的情况）会相互破坏。尽管有块 API，`run:completion:` 也完全是同步的。
12. **错误信息过于简陋。** 解析器错误只以“syntax error”出现，没有 `YYERROR_VERBOSE`，解析器一侧也不带位置（扫描器错误确实携带位置，并由 `testError` 锁定）。`lyyerror`（`parser.ym:278`）是死代码——bison 2.3 调用的是普通的 `yyerror`（已在生成代码中验证，因此不存在签名不匹配的崩溃——但也没有位置）。

### 设计坏味道（不是缺陷，但对维护很重要）

13. `MTAbstractSyntaxTree.m:110-173`：`initWithExpression:` 有一个 17 个分支的 switch，其中每个分支都完全相同。死结构。
14. `MTAbstractSyntaxTree.m:269`：`debugQuickLookObject` 为每个节点都硬编码节点类型字符串“MTAstNodeNumberValue”。
15. 扫描器缺口（`scanner.lm`）：标识符只能是 `[a-zA-Z]+`（不含数字/下划线），数字没有指数或前导点形式，只支持 `//` 注释，`let` 会被扫描但没有产生式，`|` 字符会与 `-` 一起被当作一元负号接受。
16. 软失败语义：`"Michael" + " " + "Thomason"` 求值为 **0**（字符串被强制转换为 double 0），由 `testConcatByStringAddingSoftFail` 特意锁定。在 ROADMAP 的意义上，这“不是意外”——但它也不是用户能猜到的行为。

**结论：**解释器核心在实践中需要重写。AST 节点类可以保留（在 API 重命名之后）；文法、求值顺序逻辑、值模型和状态模型则不行。

## 4. 需要付出什么——四项要求

### 4.1 让它正确

1. **构建层**（约半天，机械工作）：部署目标 → 15.0；`LEX`/`YACC` → Xcode 工具链（`$(DEVELOPER_DIR)/Toolchains/…/usr/bin/flex|bison`），**或者**把生成的解析器/扫描器签入，完全去掉工具链依赖（推荐——它还能解除 Linux 镜像的阻塞，该镜像没有 flex/bison）；六个文件的 `MADDataStructures` 重命名；把项目加入工作区并配一个共享 scheme。
2. **文法层**（2–4 天）：重构到零冲突——优先级声明、单一的比较产生式、移除 `expstr`，只有在用现代 bison 重新生成时才保留 `%code requires`（或者干脆去掉它）。文法动作必须**只**构建 AST 节点——这正是从构造上消除 `while` 挂起的方法。
3. **语义层**（2–5 天）：修正布尔转换；把 `while` 变成由 `MTAstNodeFlow` 求值的 AST 节点；实现多参数函数调用；让 `return` 终止；显式处理 NaN；要么把 `ScrimptData` 接入 `data(key)` 风格的产生式，要么新增一个公开的符号填充 API；决定日期方案（把 `NSDate` 包装进 `MADValue`）；删除死的用户函数类，或者实现用户函数。
4. **状态层**（1–2 天）：把块全局变量移入每次运行独立的上下文（`%parse-param`、可重入 flex `yylex`）；把 `run:` 契约明确为（同步）且可从任意线程安全调用。

### 4.2 补充测试

现有的 47 个测试是真正的资产——它们锁定了今天的语义，因此重写从第一天起就有回归网。缺少的是：

* 一个可运行的目标：共享 scheme + 工作区成员身份 + 可用的链接（Scrimpter 的 `AGENTS.md` 命令目前写的是 `-scheme None`，而该 scheme 不存在）。
* 针对已验证缺口的新测试套件：`while`（挂起）、多参数调用（崩溃）、布尔算术、日期、NaN/null 传播、解析器错误用例（不只是扫描器错误）、数据源绑定，以及可重入性（两次交错运行）。
* 如果 Scrimpter 加入无头引擎：一个 `Linux/cmake/ScrimpterSources.cmake` 加移植的测试套件（镜像通过签入的文件获得生成的解析器——见 4.1.1）。

### 4.3 完全集成——公式元素

这是好消息，通过端到端追踪条码模板发现：**公式元素在模型层已经完成了一半。**

* `MADPrintPageElementTypeFormula = 4` 已存在（`MAD/Source/MADDocumentObjectType.h:19`）。
* `RptqDocumentElementFormula` 已存在，带有 `functionScope`、`functionType`、`inputType`、`name`、`resultType` 以及 **`source`**——脚本文本的自然存储槽（`MAD/Source/rptq/autogen/RptqDocumentElementFormula.h`）。它被持久化在可移植存储架构中（`MADStoreSchema.m:603-612`），并有一个创建工厂（`RptqDocumentElementFormula+Extras.m:37-57`）。
* 聚合甚至声明了公式输入（`MADAggregateFunctionInputType` 的 Field/Formula）——从未被求值。

缺少的部分（与条码端到端的方式一致，`MADBarcodes` + `RptqDocumentElementBarcode` + `MADDesignerElementBarcodeView` + `MADDocumentObjectDataReferenceBarcode` + `MADPrintPageElementBarcode`）：

1. 面板条目 + 一个公式设计器视图控制器（选择器在 `MADDesignerElementPickerViewController.m:259-269` 有一个休眠的 `MADViewTagFieldOrFormulaSelector` 钩子）。
2. 一个设计器元素视图（今天设计器把 Formula 渲染为纯文本标签——`MADDesignerViewController.m:1854-1858`）。
3. 查看器的一对类：`MADDocumentObjectDataReferenceFormula` + `MADPrintPageElementFormula`，并把 `MADPrintPageElement+Constructor.m:51` 处的 case **取消注释**，从渲染数据源（`MADDocumentRenderDataSource`、`dataForRow:column:error:`）按行计算值。
4. 求值钩子本身——今天应用中没有任何地方引用 Scrimpter。

模型和架构的工作已经完成；成本在于 UI + 查看器管线加上引擎。**无论选择哪个引擎，这个成本都相同**——引擎只是末尾的一个 `case`。

### 4.4 设计是否正确？

该架构是小型嵌入式语言的教科书形态——词法分析器 → 解析器 → AST → 树遍历求值器，带引用跟踪的符号表，装箱的值类型，宿主数据协议——正确的做法是保留它。错的是它偏离该形态的地方：**在文法动作内求值**（`while` 挂起）、没有优先级层、**用全局变量代替解析器上下文**，以及设计了但未完成的功能（数据绑定、用户函数）。修复设计*就是*修复正确性清单——它们是同一项工作。AST 节点类簇（大约一半代码）原样保留。

诚实的总量：让 Scrimpter 正确、经过测试并完成集成，在 AI 辅助下需要 **4–6 周**的专注工作，之后还要**长期维护这门语言**——文档、面向用户的语言参考、错误信息质量，以及未来每个功能都要做两遍（语言 + 应用）。AI 智能体的前提是成立的：自定义语言之所以有风险，是因为文档和维护成本，而智能体确实改变了这一点。问题在于这门语言是否物有所值——见第 6 节。

## 5. 引擎决策——JavaScriptCore，以及它为何胜出

对于*公式元素*，候选集如下：

| 引擎 | 第三方代码 | 许可证范围 | 日期 | 可重入 | 无头/Linux | 用户是否熟悉 |
|---|---|---|---|---|---|---|
| **JavaScriptCore**（系统框架） | 无 | 无——Apple 系统框架 | 内置 `Date` | 每次求值一个 `JSContext` | 否（仅 Apple） | 是——JavaScript |
| **QuickJS**（与 JSC 搭配，作为 JS 配对方案中 Linux 的一半） | 有（C） | MIT——署名 + 许可证文本（docs/project/THIRD_PARTY_LICENSES.md 第 6/7 节） | 内置 `Date` | 是 | 是 | 是（JS） |
| **Scrimpter** | 无（自有代码） | 无 | 目前缺失 | 否（全局变量） | 可移植（ObjC+GNUstep） | 否 |
| **Lua 5.5** | 有（约 25k 行 C） | MIT——署名 + 许可证文本（docs/project/THIRD_PARTY_LICENSES.md 第 6/7 节） | 无原生日期 | 是 | 是 | 部分 |
| **Wren** | 有（约 4k 行 C） | MIT——同样的义务 | 无 | 是 | 是 | 否 |
| **NSExpression**（Foundation） | 无 | 无 | 是 | 是 | 部分（GNUstep 有） | 否——且没有控制流/变量，仅限表达式 |
| **C# / .NET** | — | — | **不可行**，见下文 | — | — | — |

一点澄清，因为它改变了权衡：**JavaScriptCore 并非仅在 macOS 上可用。** 它是每个 Apple 平台上的系统框架，包括 iOS（自 iOS 7 起——它是 WKWebView 背后的引擎，`JSContext` 完全可供 iOS 应用使用）。它*不*具备的是*可移植性*：Linux 无头镜像无法链接任何 Apple 框架。这是唯一的缺口，下面的 JS 配对方案就是为了填补它。

**就公式字段本身的价值而言：**

* **零许可、零维护。** 它是系统框架——二进制中不随附任何东西，许可证合规计划中不新增任何条目，引擎由 Apple 维护。否则智能体必须永远保持正确的东西，已经是别人的工作了。
* **用户已经熟悉这门语言。** 一个“小段 JavaScript 表达式”的公式字段不需要语言参考；`amount * quantity`、`price > 100 ? "HIGH" : "LOW"`、`date1 - date2` 都一目了然，也可以直接搜到答案。
* **日期、字符串、数值、null 免费桥接**（`NSString`/`NSNumber`/`NSDate`/`NSNull` ↔ `JSValue`），这正是报表字段所需的值范围。
* **设计上即沙箱化**——`JSContext` 没有文件系统、没有网络、没有全局变量，除非宿主授予；公式元素可以只获得它的行字段和几个函数。
* **App 审核无碍。** 指南 2.5.2 针对的是由自定义解释器运行的下载代码；JavaScriptCore 是 Apple 自己的引擎，用户输入的公式是文档数据（应用已经支持用户编写的 SQL）。没有暴露面。
* **已知成本：** 在 iOS 上 JavaScriptCore 以解释方式运行（第三方应用没有 JIT 授权）——比桌面 JS 慢 3–5 倍。对于在行缓存上逐行计算的公式，这无关紧要（每次求值只需微秒），而且此列表中的每个备选方案也是解释执行。每次文档刷新使用一个 `JSContext`（行值按行设置，而不是按求值设置），即使大型报表也能保持快速。

**C# 问题的答案：** iOS 上没有可行的 C# 脚本方案。iOS 上的 .NET 仅支持 AOT——操作系统的无 JIT 模型禁止 `System.Reflection.Emit` 和运行时编译，而 Mono 的解释器无法执行动态生成的程序集。要脚本化 C#，需要 Roslyn（iOS 上不受支持）加手写的 IL 解释器，或者把 Mono 运行时 dylib 嵌入 ObjC 应用——这是一个以数百兆字节和许可证义务计的研究项目。“C# 变体”的记忆很可能是 NCalc 或类似东西——一个 .NET 库，而不是可嵌入的引擎。放弃这条路径。

**反对 JavaScriptCore 的唯一真正论点**是无头引擎：`mad` CLI 和未来的 Linux PDF 写入器无法链接 JSC，因此无法在那里求值公式元素。今天没有任何无头组件会渲染页面（`MAD_PDF_LINUX.md` 已推迟），所以现在这没有代价；如果有一天它变得重要，逃生舱口很干净——选择 JavaScript 作为*语言*，在 Linux 镜像中用 **QuickJS**（MIT，纯 C）运行它。为 JSC 编写的公式在 QuickJS 上运行结果完全相同。

## 6. Scrimpter 的诚实路径

有三条，用户已经关掉了一条：

1. **作为公式引擎复活——不推荐。** 正确性审计表明，这是一次重写，然后是一个永久的第二产品（语言 + 文档 + 维护），用来解决 JavaScriptCore 已经以零义务解决的问题。2014 年的解释器并不包含足以抵消这一点的宝藏；它包含一个不错的 AST 类簇和一个损坏的文法。
2. **把该语言作为独立产品——用户已拒绝（2026-10-23）。** `MAD_FUTURE.md` 第 7 节为报表 DSL 作为 AI 时代文档的文本形式提出了真正的理由，上面提到的规范优先/转译为 JS 的路径是它可辩护的版本——但用户对创建新语言并不热衷，而“它是嵌入式的”本身并不是理由。这条路径已出局；`MAD_FUTURE.md` 第 7 节的愿景本身没有改变，可以独立于公式元素重新审视。
3. **继续搁置。** 该框架不在工作区中、不被构建、不被链接，它自己的 AGENTS.md 也说不要使用它。git 历史保留了一切；`MAD_SCRIPTING.md` 记录了它为什么保持搁置。直接删除仍然是一个选项，但没有任何要求这样做。

## 7. 许可证摘要

* **Scrimpter（如果保留）：** 用户自己的版权——没有义务。重新生成解析器：bison 的输出带有 GPL 例外文本；该例外允许专有使用，但通知必须保留在生成的文件中。flex 输出不施加任何要求（flex 是 BSD 风格，且 ≥ 2.5.4 不在生成的扫描器中嵌入通知）。两者都是 App Store 的常规情况。
* **JavaScriptCore：** Apple 系统框架——不随附任何东西，无通知，不向 `THIRD_PARTY_LICENSES.md` 添加任何内容。
* **Lua / Wren / QuickJS：** MIT——被允许，但每个都会在合规计划（`THIRD_PARTY_LICENSES.md` 第 6/7 节）中增加一行：携带许可证文本、添加署名界面、保持清单条目最新。不是阻碍；而是一项真实的、持续的义务。
* **C#/.NET：** 无意义（不可行），而且本会是最重的选项。
* **App Store：** 用户输入的公式是文档数据，就像应用已经执行的 SQL 一样。JavaScriptCore 是 Apple 自己的引擎，因此指南 2.5.2 不适用于它。运行用户编写脚本的自定义解释器（Scrimpter、Lua）也在指南允许范围内，但 JSC 完全消除了这个问题。

## 8. 建议

**引擎决策已按用户的指示（2026-10-23）推迟。** 已确定的是：C# 已死；**不会创建新语言**（用户对之并不热衷，而且新语言的存在只会是为了被称作“嵌入式”）；速度和可移植性很重要。当公式元素工作启动时——一条仅在用户要求时才创建的 `TASKS.md` 条目——**实施智能体必须回来请用户从下面的候选名单中选择引擎**。本文档是这个问题的上下文，而不是它的答案。

根据这些标准，候选名单如下：

1. **JavaScript，在 Apple 上由 JavaScriptCore 运行，在 Linux 镜像中由 QuickJS 运行。** 用户已经熟悉的语言；内置日期；Apple 一侧零许可，Linux 一侧一行 MIT；一种语言，两个引擎。这是保留 JavaScript 的最可移植方式，也让公式功能无需引擎维护。
2. **Lua 5.5。** 该集合中最快的解释器，也是最可移植的单一引擎——到处都是一套 MIT 代码库，包括无头环境。代价：带有署名义务的第三方代码、没有原生日期（需要包装层）、需要编写 ObjC 桥接，以及大多数最终用户不熟悉的语言。
3. **Wren。** 小巧、MIT、可移植；基于类的语法读起来更接近 C 风格预期。代价：最冷门的选项、关注者更少、没有日期。
4. **NSExpression。** 系统自带、零成本、可通过 GNUstep 移植——但仅限表达式（没有控制流，没有用户变量）。只有当“可脚本化字段”缩水为“公式字段”时才会考虑。

Scrimpter 保持搁置（第 6 节）；`MAD_FUTURE.md` 第 7 节的 AI-DSL 愿景没有改变，且与这一决策无关。公式元素的模型层（`MADPrintPageElementTypeFormula`、`RptqDocumentElementFormula.source`、存储架构）与引擎无关，仍然随时可用于所选的任何引擎。

## 来源

* React Native——JavaScript 环境（JavaScriptCore，iOS 上无 JIT）：
  https://reactnative.dev/docs/javascript-environment
* NativeScript——iOS 运行时（App Store 构建中禁用 JIT）：
  https://v7.docs.nativescript.org/core-concepts/ios-runtime/overview
* outl RFC 0025——插件引擎选择（iOS 禁止 JIT；为可移植性选择解释器而非 JSC）：https://github.com/outlmd/outl/blob/main/docs/rfcs/0025-plugin-system.md
* App Store 指南 2.5.2 的实践（WebKit/JavaScriptCore 获豁免）：
  https://appcompliance.io/blog/guideline-2-5-2-rejection/
* Microsoft Learn——iOS/Mac Catalyst 上的 .NET 解释器（默认 AOT，Mono 解释器的限制）：https://learn.microsoft.com/zh-cn/dotnet/maui/macios/interpreter?view=net-maui-10.0
* dotnet/runtime 讨论 #112420——在普通 iOS 应用中嵌入 Mono 运行时（“iOS 上的 C#”的现有技术水平，以及为什么它不是脚本化）：
  https://github.com/dotnet/runtime/discussions/112420
* Lua 5.5 发布（2025-12-22，MIT，C）：https://www.opennet.dev/opennews/art.shtml?num=64476
* Wren 与 Lua 对比（两者均为 MIT；Wren 约 4k 行 C，近期有活动）：
  https://www.libhunt.com/compare-wren-vs-LuaDist--lua
