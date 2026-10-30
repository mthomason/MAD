---
layout: default
lang: zh-CN
---

# MAD_BARCODES.md——条码元素：现代化与重新整合计划

**状态：** 已于 2026-10-22 归档——该设计及其全部任务（0-7）均已实现（docs/project/TASKS.md §15，于 2026-10-21 完成）。本文档仅供查阅参考，不再是工作队列。

**产品决策（用户，2026-10-20）：** 条码元素在设计器中**始终可用**。IAP 门禁（`com.everydayapps.mad.designer.product.element.barcode`）已从选择器中移除；StoreKit 标志机制保持原样，未作改动。

## 1. 现状（调查，压缩版）

“条码生成器已被移除”这一前提在 Apple 侧是错误的。该元素**从未与应用程序断开连接**——它只是被隐藏了。以下各项今天都能编译并链接：

- **`MADBarcodes` 框架**是工作区成员，由应用 target 链接并嵌入，也由 `MAD` 链接。它封装 **zint 2.16.0**（纯 C，仅使用 BSD-3-Clause 后端），由 Compressor 配方构建进 `Compressor/library/zint.xcframework`，并与 `libpng.xcframework` 和 `zlib.xcframework` 一并链接（`docs/project/LIBRARIES.md:152`）。
- **框架形态：** `MTBarcode` 基类 + `MTBarcodeProtocol` + `MTBarcodeView`（UIView）+ 61 个头文件中的 **67 个码制子类**（有两个文件声明了不止一个类：`MTBarcodeCode128Iso15417.h` 中有 6 个，`MTBarcodeCode39Iso16388.h` 中有 2 个）。类型枚举 `MTBarcodeType`（`MADBarcodeType.h`）按原始值作为 zint 的 `BARCODE_*` 常量的别名。构造经由 `+[MTBarcode newBarcodeWithType:]`（一个 65 分支的 switch）。
- **框架测试存在且通过：** 共享的 scheme `MADBarcodes`，`MADBarcodes/MADBarcodesTests/`（`MTBarcodeTests`、`MTBarcodeSymbologyTests`、`MTBarcodeViewTests`，共 21 个测试）——包括一次真正的端到端绘制，把 Code 39 符号画进离屏上下文。不需要测试夹具。
- **模型层**（`MAD`）：`RptqDocumentElementBarcode`（自动生成）+ 遵循 `MTBarcodeProtocol` 的 Extras 类别；元素类型 `MADPrintPageElementTypeBarcode = 9`（`MAD/Source/MADDocumentObjectType.h:14-26`）；存储架构列已经存在（`MAD/Source/rptq/store/MADStoreSchema.m:522-542`）——**不需要存储迁移**。
- **渲染层**（`MAD`）：`MADPrintPageElementBarcode` 从行数据构建 `MTBarcode` 并绘制；由 `MADPrintPageElement+Constructor.m:30-39` 分发。查看器/页面遍历（`MADReportPageBuilder.m:214-246`）与元素无关——条码元素在**查看器零改动**的情况下即可渲染。
- **设计器层**（应用）：元素选择器**仅在内购权益验证通过时**才追加 Barcode（`MADDesignerElementPickerViewController.m:117-120`）。门禁背后的一切都存在并可编译：编辑器（`MADDesigner/Source/barcodes/`，约 20 个文件，`MTViewControllerBarcode` 家族）、storyboard（`MADDesigner/Resources/Storyboard/MADBarcodeDesigner.storyboard`）、画布视图（`MADDesignerElementBarcodeView`，在 `MADDesignerElementView+Constructor.m:36-37` 中接入），以及 `MADDesignerViewController.m` 中的保存/编辑管线。
- **无头（Linux）：** `MADBarcodes` 被刻意不构建。`MAD` 中三个由条码支撑的文件被排除（`Linux/cmake/MADSources.cmake:21,43-48`），创建路径受 `#if __APPLE__` 保护（`RptqDocument+Extras.m:600`、`MADPrintPageElement+Constructor.m:31`、`MADDocumentObjectDataReference.m` 的条码分支）。这些保护必须保持完整；`./Linux/build.sh` 必须保持通过。

### 已知缺陷（全部固定记录在 docs/project/BUGS.md 中——修复前请先阅读条目）

1. `MTBarcode.m:693/:719`——类型名词典有重复的键（`@(MTBarcodeTypeEan14)` 别名 `@BARCODE_EAN14`）。
2. `MTBarcodeQrCodeIso18004.m`——init 与 `+type` 都返回 `MTBarcodeTypeOneCode`，因此 QR 请求**会绘制一个 OneCode 符号**。由 `MTBarcodeSymbologyTests testQrCodeClassClaimsTheOneCodeType` 锁定。
3. `MTBarcodeCode128Iso15417.m:145-161`——`MTBarcodeCode128Ean128` 的 init 赋的是 HIBC 128 类型，而 `+type` 说是 EAN128。GS1-128 请求会绘制 HIBC 128。
4. `MTBarcodeInternationalStandardBookNumberIsbn`——`+type` 调用自身（无限递归；只有工厂路径可用）。
5. `MTBarcode.m:492`——未检查的 `strcpy(barcode->primary, primaryData)` 写入 zint 的 `char primary[128]`；超过 127 字节的输入会破坏该结构体。
6. `MTBarcode.m:376-408`——NSCoding 已损坏（编码器写入空键，解码器丢弃归档）。潜伏状态：今天没有任何东西归档条码。由测试锁定。
7. `MADBarcodes/MADBarcodes/MADBarcodes/MADBarcodeDataInputType.h`——一个死桩（枚举被注释掉；实际生效的私有枚举在 `MTBarcode.m:80-84`；该头文件在 pbxproj 中是一个文件引用，但不属于任何构建阶段）。
8. `docs/project/BUGS.md` 中的“存储的颜色列没有读取者……”——存储有 `backgroundColorR/G/B/A` + `foregroundColorR/G/B/A` 列（`MADStoreSchema.m:496-503`），但模型的 `backgroundColor`/`foregroundColor` 属性（`RptqDocumentElement.h:30-31`）在 `RptqObject.m:63-92` 中没有属性映射，因此读写颜色会抛出 `NSUnknownKeyException`。**唯一的写入者是条码创建路径**（`RptqDocumentElementBarcode+Extras.m:89-90`）——而它在 Apple 上今天未经测试，所以这可能意味着条码创建目前会**崩溃**。必须在解除门禁任务之前修复。
9. 元素模型缺陷：`RptqDocumentElementBarcode+Extras.m:56` 与 `:97` 把**码制 id 写入基础元素的 `type` 列**，覆盖掉 `MADPrintPageElementTypeBarcode`（9）。插入路径随后会重新设置它（`RptqDocument+Extras.m:613`），从而在那里掩盖了这个缺陷；**编辑**路径则不会，因此被编辑过的条码元素类型会变错，编辑器分发随之失效。
10. `MADCellElement.m:138`——条码单元格的编辑操作被禁用（FIXME）；它本应调用的编辑分发已经存在（`MADDesignerViewController.m:1534-1537`）。
11. `MADPrintPageElementBarcode` 没有 `-text`，所以 `MADReportLineRepresentation -text` 对条码行返回 nil——`json-report`、`html`、`html-flow` 和无障碍功能会为该元素序列化一个空字符串。
12. `docs/project/TASKS.md` §13——`MADBarcodes` 仍带有自有代码的编译器警告/分析器发现（五个框架已清理；应用、MAD 和 MADBarcodes 仍有遗留）。

### 性能问题（设计的驱动因素）

`MTBarcode -drawInRect:` 先经由 zint 编码，然后**逐像素地、每个模块一次 `CGContextFillRect`** 地把位图画进当前的 UIKit 上下文。BI 报表每个明细行渲染一个条码；在行数很大且值重复（产品代码会重复）时，这既让每次绘制都很昂贵，又会对同一值的每一次出现重复相同的 zint 编码。而且根本没有返回图像的 API。

## 2. 设计决策

- **D1——重命名框架，而非应用 UI。** 所有框架符号 `MTBarcode*` → `MADBarcode*`：类（67 个子类、基类、视图）、`MTBarcodeProtocol`、`MTBarcodeType`（以及全部约 85 个 `MTBarcodeType*` 枚举值）、`MTBarcodeSizingMode`、私有的 `MTBarcodeDataInputType`，以及 126 个源文件名。应用自己的 `MT*` 条码视图控制器保留原名——`MT` 在应用其他地方是一个活跃的前缀，而且这些类绑定在 storyboard 上（`MADBarcodeDesigner.storyboard` 在 `customClass` 属性中命名它们），所以重命名它们只是无益的折腾。有一处 storyboard 字符串确实会变：`customClass="MTBarcodeView"` → `"MADBarcodeView"`（storyboard:581）。重命名涉及：框架（126 个文件 + umbrella + pbxproj）、`MAD`（7 个文件，全部受 Apple 保护）、应用（12 个文件）、框架测试（3 个文件），以及未关闭的 `docs/project/BUGS.md` 条目中的 `MTBarcode*.m` 路径引用。
- **D2——保留每个码制一个类的层级。** 67 个与 zint 码制一一对应的微小子类是一种可维护的设计（每个只是一个 init + `+type`）。把它折叠成表驱动的注册表将是一次没有产品收益的重写。工厂仍是构造路径。
- **D3——一次 CGImage 绘制 + 一个缓存（性能修复）。** 渲染管线变为：zint 编码 → RGB 缓冲区 → 一个 `UIImage`/`CGImage` → **一次**缩放绘制进元素矩形（经由 `UIImage -drawInRect:`，这也绕开了 CG 的 y 轴翻转陷阱）。框架缓存（`MADBarcodeCache`，一个 `NSCache`）按规范化渲染键（类型 + 两个输入 + 每个影响绘制的选项）保存渲染后的图像。重复的值每次文档渲染只编码一次；此后每次绘制都是一次图像绘制。人类可读文本保留其现有的 `NSStringDrawing` 路径，在条码之后绘制。这就是“必须在移动 BI 上够快”的要求的具体落实。
- **D4——修复测试所锁定的缺陷，并妥善归档。** 上述第 1–8 项在任务 2/任务 5 中修复。NSCoding 获得一份**正确的实现**（在真实的键下编码/解码所有协议属性）——廉价，且让这个类名副其实；锁定测试更新为断言修正后的行为。`docs/project/BUGS.md` 条目逐字移至 `docs/project/BUGS_FIXED.md`，并留下一条单行索引条目（本项目的内部约定）。
- **D5——删除死掉的东西。** 删除 `MADBarcodeDataInputType.h` 桩及其 pbxproj 文件引用、空的 `MADBarcodesTests.m` 模板，以及 `MTBarcode.m` 中被注释掉的颜色代码块（:462-467、:763-782）。输入模式仍硬编码为 Unicode（保留私有枚举）；GS1/Data 模式的接线是记录在案的后续事项，不在本轮。
- **D6——码制 id 永不写入基础 `type`。** 元素的码制存在于 `barcodeType`；基础 `type` 在所有地方都保持 `MADPrintPageElementTypeBarcode`（9）。
- **D7——条码行携带文本。** `MADPrintPageElementBarcode` 增加一个 `-text`（解析后的输入字符串），使每个导出器和无障碍功能都能通过现有的 `MADReportLineRepresentation` 路径拾取条码的内容，而无需改动导出器。
- **D8——解除选择器门禁。** 移除 `MADDesignerElementPickerViewController.m:117-120` 中的权益检查；Barcode 始终提供。`barcodeDesignerEnabled` 标志仍然保留定义（已死但无害；许可机制是另一项独立的清理）。
- **D9——超出范围，已记录（§5）：** 无头/Linux 条码渲染（在 `libraries.conf` 中加入 zint + 一条无 UIKit 的渲染路径）、macOS/Catalyst、GS1/Data 输入模式接线、存在于模型中的 storyboard segue ID（`detailsSegueIdentifer`）、HTML 导出器内的条码图像，以及应用范围的第三方声明缺口（`docs/project/THIRD_PARTY_LICENSES.md:269-284`——zint 的 BSD-3 声明义务在那里已经被标记，属于许可证登记轨道，而不是本轨道）。

## 3. 基本规则（在每个任务中都要体现其精神）

- 使用制表符缩进；有限注释，与文件语气一致。
- 不使用 `stringWithFormat:`——使用 `initWithFormat:`/`appendFormat:` 的内部风格。
- 刻意不用的代码在声明处获得 clang 属性（文件静态函数用 `__attribute__((unused))`，局部变量/参数用 `__unused`，不应存在的初始化器用 `NS_UNAVAILABLE`）。永远不要在代码之外消除警告；未标记的警告意味着删除。
- zsh 的 `rm`/`cp` 是交互式的——使用 `/bin/rm -f`、`/bin/cp -f` 或 `git mv`。
- 头文件 import 必须与文件大小写完全一致（Linux 文件系统区分大小写）。
- `docs/project/BUGS.md` 是一份记录：当某个条目被修复时，把它**逐字**移至 `docs/project/BUGS_FIXED.md`，并在 `docs/project/BUGS.md` 中留下一条单行索引条目。欢迎更新 `docs/project/TASKS.md` 的状态；永远不要仅仅因为跟踪文件列了某项就开始工作。
- 在 `master` 上工作；每个任务通过其门禁后提交；除非被要求，**不要推送**。
- 门禁（每次提交前运行）：框架测试套件、`MAD` 套件、应用构建，以及——只要有任何 `MAD/Source` 文件变化——在仓库根目录运行 `./Linux/build.sh`。

```sh
xcodebuild test -workspace Reports.xcworkspace -scheme MADBarcodes \
	-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
	-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
xcodebuild build -workspace Reports.xcworkspace -scheme 'MAD Designer' \
	-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
./Linux/build.sh
```

## 4. 任务

### 任务 0——基线（记录改动前状态）

**依赖：** 无。

**给 flash 模型的提示词：**

```
Run these four commands in /Users/michael/Desktop/Reports and record their results
exactly (all four must pass; if any fails, stop and report before doing anything else):

	xcodebuild test -workspace Reports.xcworkspace -scheme MADBarcodes \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild build -workspace Reports.xcworkspace -scheme 'MAD Designer' \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	./Linux/build.sh

Also run `git status` to confirm the tree is clean. This is the safety net: every later
task must return the tree to at least this state. Report the test counts and the app
build result; commit nothing.
```

### 任务 1——重命名 `MTBarcode*` → `MADBarcode*`（框架 + 影响范围）

**依赖：** 任务 0。**这是最大的机械性任务；在做其他任何事之前，先在一次提交中完成并验证。**

**给 flash 模型的提示词：**

```
Goal: rename the MADBarcodes framework's MTBarcode* symbols to MADBarcode*. Everything
else (app-side MT* view controller class names) stays. Work on master in
/Users/michael/Desktop/Reports. zsh rm/cp are interactive; use git mv, /bin/rm -f or
/bin/cp -f.

Scope — rename these symbols everywhere in the framework AND in the files that consume
them (see the consumer list below):
	MTBarcodeProtocol    -> MADBarcodeProtocol    (protocol)
	MTBarcodeSizingMode  -> MADBarcodeSizingMode  (enum type; the value names
	                                               AutomaticResizing/SpecificSize/
	                                               SpecificErrorLevel do not change)
	MTBarcodeType        -> MADBarcodeType        (enum type)
	MTBarcodeType*       -> MADBarcodeType*       (all ~85 enum value names)
	MTBarcodeDataInputType -> MADBarcodeDataInputType  (the private enum in MTBarcode.m:80-84)
	MTBarcodeView        -> MADBarcodeView        (class)
	MTBarcode            -> MADBarcode            (base class; last, because it is a
	                                               substring of the names above)

Order matters: rename the longer names first, MTBarcode itself last.

Steps:
1. In MADBarcodes/MADBarcodes/MADBarcodes/: rename every file MTBarcode*.h/.m to
   MADBarcode*.h/.m (61 headers + 63 implementations, including the two multi-class
   headers), MTBarcodeProtocol.h to MADBarcodeProtocol.h, MTBarcodeView.h/.m to
   MADBarcodeView.h/.m. Use git mv. Then update the class names inside every renamed
   file (sed is fine; use word-boundary-safe patterns) and fix each file's own
   #import statements to the renamed headers.
2. Rename the umbrella exports in MADBarcodes/MADBarcodes/MADBarcodes/MADBarcodes.h
   and the header list in the framework target's Headers build phase: edit
   MADBarcodes/MADBarcodes.xcodeproj/project.pbxproj — every file reference's name,
   path and comment string that contains MTBarcode. The pbxproj also contains
   MTBarcode*.h as Public-header phase entries and the two dead references to
   MADBarcodeDataInputType.h (leave those dead references for Task 2). Verify with
   `xcodebuild -list -workspace Reports.xcworkspace` and a framework build before
   moving on.
3. Rename the test files MADBarcodes/MADBarcodesTests/MTBarcodeTests.m,
   MTBarcodeSymbologyTests.m, MTBarcodeViewTests.m to MADBarcode*.m; update their
   #imports (they use quoted imports of the renamed headers) and any MTBarcode* symbol
   references inside; update their pbxproj entries in the MADBarcodesTests target.
   Check MADBarcodes.xcodeproj/xcshareddata/xcschemes/MADBarcodes.xcscheme for test
   file names and update if it names them.
4. Update the storyboard: MADDesigner/Resources/Storyboard/MADBarcodeDesigner.storyboard
   contains customClass="MTBarcodeView" (around line 581). Change exactly that string
   to "MADBarcodeView". Do NOT rename any other MT* class in the storyboard.
5. Update consumers (all reference MTBarcode symbols and import <MADBarcodes/...>):
   - MAD framework:
       MAD/Source/MADPrintPageElementBarcode.m            (import, ivar, +newBarcode:)
       MAD/Source/MADPrintPageRenderer.m                  (@class MTBarcode; forward decl)
       MAD/Source/MADDocumentObjectDataReference.h        (@protocol forward decl, line 21)
       MAD/Source/MADDocumentObjectDataReferenceBarcode.h/.m
       MAD/Source/rptq/RptqDocumentElementBarcode+Extras.h/.m   (protocol conformance)
       MAD/Source/rptq/RptqDocument+Extras.m              (line ~603, inside #if __APPLE__)
     IMPORTANT: keep every #if __APPLE__ guard exactly as it is — the Linux build
     compiles RptqDocument+Extras.m and MADDocumentObjectDataReference.h/.m and relies
     on those guards.
   - App target:
       MADDesigner/Source/barcodes/MTViewControllerBarcode.h/.m
       MADDesigner/Source/barcodes/MTViewControllerBarcodeOptions.h/.m
       MADDesigner/Source/barcodes/MTViewControllerBarcodePreview.h/.m
       MADDesigner/Source/barcodes/MTViewControllerBarcodePreviewDelegate.h
       MADDesigner/Source/barcodes/MTViewControllerBarcodeType.h/.m
       MADDesigner/Source/barcodes/MADViewControllerBarcodeDelegate.h
       MADDesigner/Source/barcodes/MADViewControllerBarcodeOptionsDelegate.h
       MADDesigner/Source/MADDesignerElementBarcodeView.m
       MADDesigner/Source/MADDesignerViewController.m     (lines ~1761, ~2454)
       MADDesigner/Source/MADElementCanvas.h/.m
     The app-side CLASS names (MTViewControllerBarcode, MTTableViewControllerBarcodeExtra*
     etc.) do NOT change — only the MTBarcode* framework symbols they reference.
6. Update the open docs/project/BUGS.md entries that cite MTBarcode*.m paths (the ## MADBarcodes
   section and the colour entry at ~line 89): change the file paths to the new names.
   Do not change any other wording.
7. Grep to confirm nothing is left: `grep -rn 'MTBarcode' MADBarcodes MAD MADDesigner/Source
   MADDesigner/Resources/Storyboard/MADBarcodeDesigner.storyboard` must return nothing
   except intentional app-side names that do not start with MTBarcode (none of the
   classes above do).

Verify (all must pass):
	xcodebuild test -workspace Reports.xcworkspace -scheme MADBarcodes \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild build -workspace Reports.xcworkspace -scheme 'MAD Designer' \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	./Linux/build.sh

Commit on master with a message like "Rename the barcode classes from MTBarcode to
MADBarcode". Do not push. If the grep or any build shows a straggler you cannot place,
fix it or stop and ask.
```

### 任务 2——修复框架缺陷；删除死代码；归档 BUGS 条目

**依赖：** 任务 1。

**给 flash 模型的提示词：**

```
Goal: fix the five framework defects below and delete the dead code, each pinned by
docs/project/BUGS.md entries. Work on master in /Users/michael/Desktop/Reports. House rules: tabs;
no stringWithFormat:; unused code gets a clang attribute at the declaration, never a
silenced warning. Read each docs/project/BUGS.md entry in full before touching its code — the entry
names the exact symbols.

1. Duplicate dictionary key (docs/project/BUGS.md ## MADBarcodes, "MTBarcode's type-name dictionary
   has a duplicate key"): in MADBarcodes/MADBarcodes/MADBarcodes/MADBarcode.m the
   dictionary literal built around lines 693/719 uses both @(MADBarcodeTypeEan14) and
   @BARCODE_EAN14 (the enum value aliases the zint constant, so they collide). Delete
   the redundant line (keep the @BARCODE_EAN14 entry). Update the dictionary-shape test
   if it asserts the entry count.
2. Wrong symbology types (docs/project/BUGS.md, the QR and EAN128 entry): in
   MADBarcodeQrCodeIso18004.m make init and +type both return the QR type (they return
   MADBarcodeTypeOneCode today, and -drawInRect: passes the instance's type to zint, so
   the object draws the wrong symbol). In MADBarcodeCode128Iso15417.m lines ~145-161,
   MADBarcodeCode128Ean128's init assigns the HIBC 128 type — make it assign the EAN128
   type its +type already claims. Then update the two pinning tests in
   MADBarcodes/MADBarcodesTests/MADBarcodeSymbologyTests.m
   (testQrCodeClassClaimsTheOneCodeType and the EAN128 one) to assert the corrected
   behavior, renaming them to match.
3. ISBN recursion (docs/project/BUGS.md): MADBarcodeInternationalStandardBookNumberIsbn's +type
   calls itself. Make it return the enum value its class is named for (check
   MADBarcodeType.h and the factory case in MADBarcode.m +newBarcodeWithType: for the
   right spelling). Add a test if the suite does not already pin it.
4. strcpy overflow (docs/project/BUGS.md): MADBarcode.m around line 492 does an unchecked
   strcpy(barcode->primary, primaryData) into zint's char primary[128]
   (Compressor/library/zint/include/zint.h:121). Guard it: if the input's UTF-8 length
   would not fit (>= sizeof(barcode->primary)), skip the encode and follow the
   existing error path used for zint error codes (the mapping around lines 512-536),
   logging the reason; honor showErrorMessage the way the existing error path does.
   Add a test: a >127-byte input must not crash and must produce the defined error
   result (no symbol, or an error image per showErrorMessage).
5. NSCoding (docs/project/BUGS.md): MADBarcode.m's encodeWithCoder:/initWithCoder: pair is broken
   (empty-key encoding; decoder discards the archive). First grep the workspace for
   NSKeyedArchiver/NSKeyedUnarchiver use with barcode objects to confirm nothing
   depends on the broken format (docs/project/BUGS.md says nothing does). Then implement it
   properly: encode every MTBarcodeProtocol property plus the inputs and subclass
   state under real string keys, decode them back, and update the pinning test in
   MADBarcodesTests to assert a round-trip preserves the values.
6. Delete dead code (house rule: unmarked dead code goes):
   - MADBarcodeDataInputType.h (the stub header with the commented-out enum) and its
     file references in MADBarcodes.xcodeproj/project.pbxproj (two references, no build
     phase). The live enum stays private in MADBarcode.m.
   - The empty Xcode template MADBarcodesTests/MADBarcodesTests.m and its pbxproj
     entries in the test target.
   - The commented-out colour blocks in MADBarcode.m (~lines 462-467 and 763-782).
7. docs/project/BUGS.md bookkeeping: for each of the five fixed entries, move the entry VERBATIM
   (full text, including its test names) to docs/project/BUGS_FIXED.md under the same framework
   heading, and leave a one-line index entry in docs/project/BUGS.md under ## MADBarcodes so
   "docs/project/BUGS.md, the X entry" still lands. The colour-columns entry stays open (Task 5).

Verify:
	xcodebuild test -workspace Reports.xcworkspace -scheme MADBarcodes \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild build -workspace Reports.xcworkspace -scheme 'MAD Designer' \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	./Linux/build.sh

Commit on master ("Fix the pinned MADBarcodes defects and delete the dead code"). Do
not push.
```

### 任务 3——快速渲染路径：一次图像绘制 + `MADBarcodeCache`

**依赖：** 任务 2（上述修复改变了绘制路径的周边）。

**给 flash 模型的提示词：**

```
Goal: replace MADBarcode's per-pixel painting with one image draw backed by a cache.
This is the performance design — a BI report renders a barcode per detail row, values
repeat, and today every draw encodes via zint and paints the bitmap one CGContextFillRect
per module. Work on master in /Users/michael/Desktop/Reports. House rules: tabs, no
stringWithFormat:, unused-attribute discipline.

Context: MADBarcode -drawInRect: (MADBarcodes/MADBarcodes/MADBarcodes/MADBarcode.m)
currently: builds a zint_symbol, copies the protocol properties into it, encodes with
ZBarcode_Encode_and_Buffer, maps zint error codes to messages, then walks the RGB
bitmap painting each module with CGContextFillRect, with rotate/scale-to-fit/center
geometry, and finally draws the human-readable text via NSStringDrawing when
humanReadable is set.

Steps:
1. Split the method: extract a `- (UIImage *)renderedImage` that performs everything up
   to and including the bitmap, and builds one UIImage from the RGB buffer
   (UIGraphicsBeginImageContextWithOptions at the zint bitmap's size, draw the pixels
   into it — or equivalently a CGBitmapContext + CGBitmapContextCreateImage — then
   UIGraphicsEndImageContext). Keep the error mapping where it is; on a zint error the
   method returns the error rendering it does today if showErrorMessage, else nil.
2. Rewrite -drawInRect: to call -renderedImage (via the cache below) and draw the
   result ONCE with [image drawInRect:destRect] using the same rotate/scale-to-fit/
   center geometry math the current code has (read it and preserve the behavior; the
   existing tests pin the draw result). Using UIImage's drawInRect: avoids the
   CoreGraphics y-flip trap. Draw the human-readable text after the image, exactly as
   today.
3. Add MADBarcodeCache (new files MADBarcodeCache.h/.m in the framework, public,
   listed in the umbrella and the Headers phase):
   - A shared singleton `+ (MADBarcodeCache *)sharedCache;`
   - Backed by NSCache; stores UIImage keyed by an NSString render key.
   - `- (UIImage *)imageForBarcode:(MADBarcode *)barcode;` — looks up the key, renders
     on miss, stores on hit.
   - `- (void)flush;` (removeAllObjects) for tests and for the report refresh.
   Keep it small: no subclassing, no eviction policy beyond NSCache defaults
   (optionally totalCostLimit by pixel bytes, your call — document it in a comment).
4. Add `- (NSString *)renderCacheKey` on MADBarcode: a canonical string composing every
   draw-affecting value — the type, both inputs, and every MTBarcodeProtocol property
   (border style/width, height, humanReadable, option1-3, showErrorMessage, scale,
   whitespace width, has2dComponent) plus center. Do NOT use description. Two barcodes
   that draw identically must produce equal keys.
5. Where should the cache be invalidated: MADBarcode is a value object built fresh per
   row, so nothing to invalidate per object; but call [MADBarcodeCache.sharedCache flush]
   from the element's refresh boundary if one exists — look at
   MAD/Source/MADPrintPageElementBarcode.m and the report refresh path
   (MADDesigner/Source/MADViewerController.m refresh: → MADOperationRefreshReload) and
   flush on refresh completion so a changed document never serves stale images. If the
   cache key already includes every input (it does), flushing is belt-and-braces — do
   the simplest correct thing and say in the commit message what you did.
6. Tests (extend MADBarcodesTests; quoted imports of the new headers):
   - -renderedImage returns a non-nil UIImage with the expected zint dimensions for a
     Code 39 sample, and nil (or the error image) for an invalid input.
   - The existing end-to-end draw test (non-white pixels in an offscreen context) still
     passes unchanged.
   - Cache: two identical barcodes share the identical UIImage object from the cache
     (flush between cases); two barcodes differing only in input produce different
     images; -renderCacheKey differs when an option differs.
   - A >127-byte input still behaves as Task 2 defined.
7. Update the umbrella MADBarcodes.h to export MADBarcodeCache.h.

Verify:
	xcodebuild test -workspace Reports.xcworkspace -scheme MADBarcodes \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild build -workspace Reports.xcworkspace -scheme 'MAD Designer' \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	./Linux/build.sh

Commit on master ("Render barcodes as one cached image draw"). Do not push.
```

### 任务 4——`MADBarcodes` 警告清扫（docs/project/TASKS.md §13）

**依赖：** 任务 3。

**给 flash 模型的提示词：**

```
Goal: clear MADBarcodes' remaining first-party compiler warnings and analyzer findings
(docs/project/TASKS.md §13: five frameworks were cleared 2026-10-17; the app, MAD and MADBarcodes
remain). Work on master in /Users/michael/Desktop/Reports.

1. Build the framework and run Analyze on it in isolation:
	xcodebuild build -workspace Reports.xcworkspace -scheme MADBarcodes \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
   plus Product > Analyze equivalent (or the analyze xcodebuild flag) and record every
   first-party diagnostic.
2. Fix first-party diagnostics the house way: deliberately-unused code gets a clang
   attribute at the declaration (__attribute__((unused)) on file-static functions,
   __unused on locals/parameters, NS_UNAVAILABLE for initializers that must not be
   built). Never suppress a warning away from the code; an unmarked warning means the
   code is dead and should be deleted. Do not "fix" warnings inside vendored zint/png
   headers — those are not ours.
3. If a diagnostic reveals a real defect you are unsure how to fix without behavior
   change, leave the code alone and record it as a new docs/project/BUGS.md entry under
   ## MADBarcodes (Status: Open, with the file:line and what you saw) rather than
   papering over it.
4. Update docs/project/TASKS.md §13's status line to note MADBarcodes is cleared (or what remains).

Verify:
	xcodebuild test -workspace Reports.xcworkspace -scheme MADBarcodes \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild build -workspace Reports.xcworkspace -scheme 'MAD Designer' \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	./Linux/build.sh

Commit on master ("Clear the MADBarcodes warning sweep"). Do not push.
```

### 任务 5——`MAD` 中的元素层修复（类型覆盖、颜色列、`-text`、编辑菜单）

**依赖：** 任务 3。触及 `MAD/Source`，因此 Linux 门禁是强制的。

**给 flash 模型的提示词：**

```
Goal: four MAD-layer fixes that make the barcode element actually work on Apple.
Work on master in /Users/michael/Desktop/Reports. House rules: tabs; no
stringWithFormat:; unused-attribute discipline; imports match file case exactly (Linux
is case-sensitive); every #if __APPLE__ guard you see stays intact — the Linux build
compiles some of these files and excludes others (Linux/cmake/MADSources.cmake).

1. Stop clobbering the base element type.
   In MAD/Source/rptq/RptqDocumentElementBarcode+Extras.m, updateWithBarcode:
   (~line 56) and barcodeWithMtBarcode: (~line 97) both assign the SYMBIOLOGY id into
   the base element's `type`. The base type must stay MADPrintPageElementTypeBarcode
   (9); the symbology belongs in `barcodeType`. The insert path re-sets type
   afterwards (RptqDocument+Extras.m ~line 613), which masks the bug on insert but not
   on edit — after an edit, documentObjectType returns the symbology id and the editor
   dispatch breaks. Fix: updateWithBarcode: and barcodeWithMtBarcode: must copy the
   symbology into barcodeType and NEVER assign base type; verify the insert path still
   sets type = MADPrintPageElementTypeBarcode. Add a MAD test (in MAD/MADTests, pattern
   MADDocumentObjectDataReferenceBarcodeTests.m): create a barcode element through the
   factory, assert documentObjectType == MADPrintPageElementTypeBarcode and barcodeType
   == the symbology; then call updateWithBarcode: and assert the same invariant.
2. Fix the store's colour columns (docs/project/BUGS.md "The store's colour columns have no reader,
   and the model's colour properties have no column" — read the whole entry first).
   The store has backgroundColorR/G/B/A + foregroundColorR/G/B/A columns
   (MAD/Source/rptq/store/MADStoreSchema.m:496-503); the model exposes
   backgroundColor/foregroundColor (RptqDocumentElement.h:30-31); nothing maps them, so
   RptqObject's -valueForUndefinedKey: (MAD/Source/rptq/store/RptqObject.m:63-92)
   raises NSUnknownKeyException. The ONE writer is the barcode creation path
   (RptqDocumentElementBarcode+Extras.m:89-90) — so creating a barcode element likely
   raises today; the HTML facsimile and PDF are monochrome for the same reason.
   Fix the mapping properly: teach RptqObject (or wherever sibling attributes are
   mapped — study how the other element attributes in the schema are registered first)
   to read/write backgroundColor and foregroundColor through the four RGBA columns.
   Do not change the schema columns. Then add a MAD test that creates a barcode element
   via the factory (exercising the :89-90 write) and reads its colours back without an
   exception. Once green, move the docs/project/BUGS.md entry VERBATIM to docs/project/BUGS_FIXED.md and leave
   the one-line index entry behind. (This fixes the whole element colour story, not
   just barcodes — the entry's "Why it matters" names the HTML/PDF consequences.)
3. Give barcode lines text.
   MAD/Source/MADPrintPageElementBarcode.h/.m: the class currently has no -text, so
   MADReportLineRepresentation -text returns nil for barcode lines and json-report /
   html / html-flow / accessibility serialize an empty value. Make it carry the
   resolved input: the cleanest is to subclass MADPrintPageElementText (whose -text
   property the line representation already reads via respondsToSelector) — check that
   class's initializer contract in MADPrintPageElement.h/.m first, and set text to the
   composed input (input1, plus input2 when present, in the same order the drawn
   barcode uses them). Keep drawInRect: unchanged. Add a MAD test: build the print
   element from a MADDocumentObjectDataReferenceBarcode with known values (see
   MADPrintPageElementBarcodeTests.m for the existing pattern) and assert -text; then
   build a MADReportLineRepresentation over it and assert its -text.
4. Re-enable Edit on barcode elements.
   MADDesigner/Source/MADCellElement.m line ~138: canPerformAction:withSender: disables
   edit for barcodes with a FIXME; the dispatch it would call exists
   (MADDesignerViewController.m ~1534-1537, editDocumentObjectRepresentedByCell: →
   editDocumentObjectBarcodeWithID:). Remove the exception so barcode elements allow
   the same delete/format/edit actions as their siblings. No new plumbing.

Verify:
	xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild test -workspace Reports.xcworkspace -scheme MADBarcodes \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild build -workspace Reports.xcworkspace -scheme 'MAD Designer' \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	./Linux/build.sh

Commit on master ("Fix the barcode element's type, colours, text and edit path"). Do
not push.
```

### 任务 6——条码行的导出与无障碍覆盖

**依赖：** 任务 5。

**给 flash 模型的提示词：**

```
Goal: prove that a document containing a barcode element exports correctly. Work on
master in /Users/michael/Desktop/Reports. House rules as always (tabs, no
stringWithFormat:, case-exact imports).

Context: the exporters do not switch on element types — they serialize the walked
MADReportLineRepresentation: the kind token comes from
NSStringFromMADPrintPageElementType (MAD/Source/MADDocumentObjectType.h:29-44, which
already names Barcode), and the value from the line's -text (fixed in Task 5). So this
task is mostly tests; change code only where a test proves a gap.

1. Read MADReportExporterTypeToken (used at MADReportExporterJSONReport.m:181-182),
   MADReportExporterHTMLTypeToken (MADReportExporterHTML.m:143-144) and
   MADReportExporterFlowTypeToken (MADReportExporterHTMLFlow.m:218-219). Confirm each
   maps the string "Barcode" (from NSStringFromMADPrintPageElementType) to a sane
   token ("barcode" or equivalent) rather than rejecting it. If one rejects unknown
   names, fix it minimally to pass Barcode through like the other element names.
2. Add tests in MAD/MADTests (follow the existing exporter test files' fixture
   pattern): build a temporary store/document containing one barcode element (create it
   through the RptqDocumentElementBarcode factory like the Task 5 test does, with a
   known symbology and inputs), walk it the way the exporters do, and assert:
   - json-report: the line's kind token is the barcode token and its value equals the
     element's resolved input text;
   - html and html-flow: same, with the text escaped the way sibling elements are;
   - MADAccessibilityLine built over the element carries the value, not an empty string.
   These are Apple-only tests (the Linux build cannot construct barcode elements by
   design — the creation paths log-and-skip there), so guard nothing; just do not add
   them to the Linux test set.
3. Do not change the Linux build or its source lists.

Verify:
	xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild test -workspace Reports.xcworkspace -scheme MADBarcodes \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild build -workspace Reports.xcworkspace -scheme 'MAD Designer' \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	./Linux/build.sh

Commit on master ("Cover the barcode element in the report exporters"). Do not push.
```

### 任务 7——解除选择器门禁；文档清扫；端到端验证

**依赖：** 任务 5 和任务 6。

**给 flash 模型的提示词：**

```
Goal: make the barcode element always available in the designer and bring the
documentation in line with reality. Work on master in /Users/michael/Desktop/Reports.

1. Un-gate the picker. In MADDesigner/Source/MADDesignerElementPickerViewController.m,
   the choice list in viewWillAppear (~lines 106-123) appends the barcode type only
   when [MADStoreKitController sharedObject].barcodeDesignerEnabled. Remove the
   conditional so the barcode choice is always added, exactly like the other element
   types. Leave the barcodeDesignerEnabled property and MTStoreKitController+Features
   untouched (the licensing machinery is a separate cleanup). The segue
   (MTIdentifierSeguePushBarcodeLabelNew) and the creation flow behind it already
   exist and are compiled.
2. Documentation sweep (keep each change minimal and factual):
   - AGENTS.md (repo root; CLAUDE.md is a symlink to it): the frameworks list says
     "MADBarcodes: This is used for the barcode element. MADBarcodes is currently
     unused and unmaintained." Replace the last sentence with the true state: the
     framework is maintained, links zint 2.16.0 via the Compressor recipe, and backs
     the barcode element on Apple; it is deliberately excluded from the Linux build.
     Also add MAD_BARCODES.md to the Related Documents list.
   - MADBarcodes/AGENTS.md (and its CLAUDE.md symlink): remove the "unused and
     unmaintained" claim; state the framework's role and its test scheme.
   - docs/project/LIBRARIES.md lines ~100-102 are stale: they still describe zint 2.4.2 with
     patches/zint-2.4.2-mad.patch. Correct them to the actual arrangement: zint
     2.16.0 built by the Compressor recipe (Compressor/matrix.conf + lib/recipes/zint.sh)
     into Compressor/library/zint.xcframework; the old 2.4.2 patch is retired
     (ZBarcode_Encode_and_Buffer is upstream API in 2.16). docs/project/THIRD_PARTY_LICENSES.md
     ~283-284 already flags the staleness — check that note and update it to say the
     docs/project/LIBRARIES.md text is now corrected. Do not touch the notices gap itself (it is on
     the licence-register track).
   - docs/project/BUGS.md: the colour-columns entry's "untested on Apple" note was resolved by
     Task 5 (the entry moved to docs/project/BUGS_FIXED.md). The "barcode creation path, which is
     off the headless build" wording in any remaining open entry: adjust only the
     stale "untested on Apple" phrasing where the facts have changed; leave everything
     else verbatim.
   - docs/project/TASKS.md: update §15 (this queue entry) with what landed, commit hashes included,
     and mark it Done; keep the follow-ups listed there under a short "Remains" line
     (see MAD_BARCODES.md §5).
3. End-to-end verification:
   - Build the app for the simulator AND for a generic device
     (xcodebuild build ... -destination 'generic/platform=iOS' — use the scheme
     'MAD Designer'). Both must pass.
   - Run the full suites (MADBarcodes, MAD) and ./Linux/build.sh.
   - Launch the app in the simulator (the /run skill, or xcrun simctl launch after
     installing the built app). You cannot see the screen, so do the mechanical checks
     and hand the visual pass to the user: (a) the element picker offers Barcode
     without any entitlement; (b) choosing it opens the barcode options composer
     (MADBarcodeDesigner.storyboard) — the app must not crash on the colour write
     (Task 5 fixed the exception); (c) the designer canvas shows the sample barcode;
     (d) after refresh, the viewer draws the barcode from live row data; (e) a
     json-report export of a document with a barcode element contains the barcode
     line's text. Report which of these you could verify mechanically and list the
     visual checks for the user.

Verify (the mechanical ones):
	xcodebuild test -workspace Reports.xcworkspace -scheme MADBarcodes \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild build -workspace Reports.xcworkspace -scheme 'MAD Designer' \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild build -workspace Reports.xcworkspace -scheme 'MAD Designer' \
		-destination 'generic/platform=iOS'
	./Linux/build.sh

Commit on master ("Return the barcode element to the designer"). Do not push.
```

### 任务 8——可选：补全 umbrella 头文件

**依赖：** 任务 1。仅在还有时间/意愿时进行；否则跳过。

**给 flash 模型的提示词：**

```
Goal: end the "public subset vs factory-reachable classes" inconsistency. Only 16 of
the 61 symbology headers are marked Public, yet every class is reachable through
+newBarcodeWithType:, and MADBarcodes.h carries a comment about keeping the umbrella in
sync with the Public headers phase (-Wincomplete-umbrella). Make every MADBarcode*
symbology header Public in the framework target and list it in the umbrella
MADBarcodes.h, so the public surface matches the reachable surface. Do not change any
class. Verify with the MADBarcodes suite, the MAD suite, the app build and
./Linux/build.sh, and commit on master ("Complete the MADBarcodes umbrella header").
Do not push.
```

## 5. 后续事项（在此记录，刻意不构建）

- **无头条码渲染。** `MADBarcodes` 绑定 UIKit（`UIGraphics`、`UIColor`、`NSStringDrawing`、`UIView`），而 zint 不在 `Linux/libraries.conf` 中。无头路径需要一个无 UIKit 的渲染核心（zint 自带的 PNG 输出是一个候选）加上镜像中的 zint 版本固定——适用 `Linux/CLAUDE.md` 的“添加下一个框架”配方。在那之前，Linux 构建继续排除那三个条码文件，元素类型在那里保持仅存在于模型，与今天完全一致。
- **GS1 / Data 输入模式。** 编码器中的输入模式硬编码为 Unicode；私有的 `MADBarcodeDataInputType` 枚举存在，但 GS1/Data 模式未接到选项字段上。
- **模型上的 `detailsSegueIdentifer`。** 码制类带有 storyboard segue ID；映射应当放在应用的类型选择器中（`MTViewControllerBarcodeType`）。装饰性解耦，为免 storyboard 折腾而延后。
- **HTML 导出器内的条码图像。** 今天仿真件携带条码的输入文本；内嵌 data-URI PNG 仅在 Apple 上可行。
- **应用范围的第三方声明。** zint 的 BSD-3-Clause 声明义务仍未满足（已在 `docs/project/THIRD_PARTY_LICENSES.md:269-284` 中标记）；它走许可证登记轨道，而不是本轨道。
