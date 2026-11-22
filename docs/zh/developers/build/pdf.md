---
layout: default
title: "无头 PDF 写出器"
description: "Cairo 与 FreeType 技术栈、字体映射，以及确定性 PDF 导出。"
lang: zh-CN
---

# 无头 PDF 写出器——Cairo + FreeType 主体

本页记录无头 PDF 写出器：Cairo 与 FreeType 技术栈、字体映射策略、确定性模式，以及针对 json-report 基准的验收测试。

*撰写于原定日期；当前状态事实已于 2026-11-22 核实。*

**状态（2026-11-20）：已实现，可在 Linux 与 Windows 上运行，测试通过。** `mad export
--format pdf` 与 `mad serve` 的 `export` 在两个无头引擎上都会写出 PDF；
`MADReportExporterPDF` 的 Apple 主体未变，在 `--deterministic` 下仍写出同样的
43,177 字节、5 页、`sha256 3eb2f1c4…` 的 London 样本。
下文各节是已交付的记录；引向此处的决策历史
（状态、候选技术栈、未决问题）保留在末尾。

## 它是什么

这里所弥合的缺口一直只是写出部分。`MADReportPageBuilder` 准备
文档并遍历页面；`html`、`html-flow` 和 `json-report` 已经读取
该遍历结果，并在各平台上字节一致。PDF 写出器取同样的已遍历页面并绘制它们：

* `MADReportExporterPDFCairo`（`MAD/Source/MADReportExporterPDFCairo.m`）是
  `MADReportExporterPDF` 的非 Apple 主体。在 Apple 上，导出器保留其 Core
  Graphics 路径；在非 Apple 上，同一个 `exportDocument:toURL:options:error:` 把
  文档交给这里。
* 写出器准备文档的方式与 Apple 主体完全一致
  （`+MADReportPageBuilder prepareDocumentForRender:`），在页面边界处创建 Cairo PDF surface，
  并对每个已遍历页面绘制白色画布、每一行的文本于其框架处、
  每个图片，以及文本装饰。
* `+isAvailable` 在每个平台都返回 YES，`+unavailableReason` 为 nil。
  缺少字体包是一次带自身消息的导出错误，而不是静默
  替换。

## 技术栈及其许可证

| 组件 | 版本 | 许可证 | 作用 |
|---|---|---|---|
| cairo | 1.18.6（git tag，提交已锁定） | **MPL-1.1**（MPL 选项） | PDF surface 与绘制 |
| pixman | 0.46.4（git tag，提交已锁定） | MIT | cairo 的光栅核心 |
| FreeType | 2.15.0 | **FTL** | 字形步进、字偶距和轮廓 |
| Liberation Sans/Serif/Mono | 2.1.5 | **SIL OFL 1.1** | 替代字体外观 |

没有 Pango：遍历已经解析出每一行的框架、文本、字体、字号、字形特征
和对齐方式，而框架宽度就是唯一的换行边界
（`NSLineBreakByTruncatingTail`）。剩下的是步进和字偶距，由
FreeType 直接提供。cairo 仅以 PDF surface 构建——FreeType
和 zlib 引入；fontconfig、Pango/glib、Xlib/XCB、Quartz 以及除 PNG 之外的图像后端
均不引入——因此它不会引入上表之外的任何东西（zlib 和
libpng 已为条形码技术栈存在）。

相关文本位于 `ThirdParty/Licenses/`（`cairo-MPL-1.1.txt`、
`pixman-MIT.txt`、`freetype-FTL.txt`、`liberation-OFL-1.1.txt`），登记表
是 `THIRD_PARTY_LICENSES.md` §3.5、§9（Linux 镜像）和 §10（Windows 引擎）。
四者都不增加重新链接义务，因此
`ThirdParty/Licenses/README.md` 中的书面要约不变。Windows 的“关于”窗口从
`WindowsLicenseRegistry` 列出全部四项。

## 字体映射

文档指定的是 Apple 字体；字体包携带 Liberation，因此名称先映射到
字族，再按元素的粗体与斜体标志映射到字面（也按名称本身声明的
字重或倾斜，例如 `HelveticaNeue-Bold`）：

| 文档字体 | 替代字体 | 备注 |
|---|---|---|
| Helvetica Neue、Helvetica、Arial、Verdana、Tahoma、Trebuchet MS、Calibri、system | Liberation Sans | Arial 的度量孪生体，因此 Helvetica/Arial 行接近；**Verdana 比 Liberation Sans 更宽**，所以 Verdana 行比 Core Graphics 的窄，可能更早截断 |
| Courier、Courier New、Menlo、Consolas | Liberation Mono | Courier New 的度量孪生体 |
| Times New Roman、Times、Georgia、Palatino、Baskerville、Garamond | Liberation Serif | Times New Roman 的度量孪生体；**Georgia 比 Liberation Serif 更宽** |
| 其他任何字体 | Liberation Sans | 渲染器自身的回退字体是系统字体，而无头引擎没有系统字体 |

字重与倾斜选择字面（`Regular`、`Bold`、`Italic`、`BoldItalic`）；
下划线和删除线绘制为实测文本段下方/贯穿的填充矩形，
使用该字面的 PostScript 下划线度量。对齐方式采用样式自身的（`left`、`center`、`right`；两端对齐和自然对齐按左对齐绘制，与
HTML 摹本一致）。比其框架更宽的文本段会被裁切并以 `…` 结尾，这是
渲染器的截断尾部规则。

**残余差异在于替代字体的度量。** 页面、每一行的框架、每一行解析后的文本、
其字族映射、字号、字重、倾斜与对齐均来自遍历且是精确的。行在框架内的宽度来自
替代字面，因此绘制出的行可能比 Mac 上略宽或略窄——
最明显的是 Verdana 和 Georgia，其真实字面与字体包中的任何字体都不度量兼容。这是
视觉差异，而非结构差异；基准测试比较文本和框架，而非字形轮廓。

## 确定性

`MADReportExportOptionsDeterministic` 把 Cairo 原本会从时钟取得
的两个日期（`CAIRO_PDF_METADATA_CREATE_DATE` / `_MOD_DATE`）固定为 Apple 主体在其 trailer 中固定的同一
时刻 `2001-01-12T00:00:00Z`（PDF
纪元）。Cairo 不写 trailer `/ID`，其对象编号、字体子集
标记、压缩和页树都是确定性的，因此同一份未变报表的两次导出是相同字节。
测试证明了这一点。

为保持这一点，必须移除一个写出器侧的隐患：cairo 按 `FT_Face` 指针缓存其
字体字面和缩放字体，因此一个每次导出都打开并释放一组字面的写出器，在
分配器复用地址时可能拿到过期的缓存项，内容流有时会
从 `Tj` 切换为逐字形的 `TJ` 偏移。现在字面是进程级的加载一次
静态量，且在它们被共享时导出在递归锁下串行化。

跨平台而言，并不要求两个写出器逐字节一致，但
London fixture 的 Cairo 输出在 Linux 和 Windows 上大小相同，仅相差 44
字节——这是 cairo 生成的字体子集前缀（它把字形哈希为
`unsigned long`，Linux 上 8 字节，Windows 上 4 字节）。文本、几何和页面
结构完全相同。

surface 被限制为 **PDF 1.4**：经典交叉引用表和
普通对象。Cairo 默认的 1.7 会写对象流和交叉引用流，
这既不容易绘制也更难读回；1.4 也是读者基础最广的。一个后果是：
Cairo 的 PDF API 没有 TrimBox，所以页面的 MediaBox 是 US Letter，内容绘制在
遍历所用的同一 1pt 裁切内（`[1, 1, 610, 790]`）；裁切是框架中的结构性属性，
而非 PDF 框。

## 绘制

对每个页面，在 cairo 的 PDF 用户空间中（原点左上，y 向下；cairo
自己写出 `1 0 0 -1 0 H cm` 翻转，因此遍历的框架原样通过）：

* 白色裁切框，与 Apple 渲染器的 `drawWhiteCanvas:pageRect:` 一致；
* 每一行文本：字面与字号来自 `MADReportLineStyle`，解析后的文本
  来自该行，字形以 FreeType 的步进和字偶距按
  行字号放置（`FT_KERNING_UNFITTED`，因此整形只取决于字面和
  字号），置于框架左（或居中/右）边缘及其基线处；
* 每个图片：图像元素存储的 PNG 或条形码的符号
  （`MADReportLineRepresentation -imageData`，按需渲染），按
  HTML 摹本适配它的方式（`object-fit: contain`）等比适配进
  框架，经 cairo 的 PNG 读取器解码；
* 装饰：下划线和删除线作为填充矩形；
* 每页的 `cairo_show_page`（以及白色填充）。

页面遍历与其他地方一样，每页一个读事务；图片在它关闭后
读取，对没有图片的文档没有开销。

## 验收测试

`Linux/Tests/MADPDFExportTests.m`（以及 `Windows/Engine/Tests/`）打开 London
fixture，添加一个条形码和一个图片，刷新并导出。它用测试中的一个小型 PDF 1.4 读取器
把 PDF 读回（页树、MediaBox、内容
流、字体 ToUnicode 映射），并与同一文档的 `json-report` 比较——这是两个平台字节一致
认可的基准：

* 页数以及每页的 US Letter MediaBox；
* 每个已遍历行的框架位于 1pt 裁切内；
* 每个文本行的文本，按遍历顺序逐页（当框架比文本窄时
  允许截断尾部省略号）；
* 条形码和图片作为图像 XObject，而非文本；
* 两次确定性导出字节相同，且日期固定；普通
  导出则采用时钟日期。

`MADReportExporterTests` 还会导出纯 London fixture，并检查五
页，即遍历的页数。Apple 字节锁定不是无头测试：
Apple 套件仍断言 43,177 字节 / `3eb2f1c4…` 的导出，且
`#if __APPLE__` 主体未被触碰。

## 构建它

* **Linux**——`Linux/libraries.conf` 锁定 pixman、FreeType、cairo 和
  Liberation tarball；`Linux/lib/libraries.sh` 有 `build_pixman`（meson）、
  `build_freetype`（autoconf，仅核心）、`build_cairo`（meson，PDF surface）
  和 `build_liberation`（十二个字面到
  `${PREFIX}/share/mad/fonts`）。镜像把它们安装到 `/usr/local`；
  运行时阶段复制 `/usr/local/share/mad` 以获得字体。Dockerfile 的
  `toolchain-base` 需要 `meson` 和 `ninja-build`（cairo 与 pixman 的构建
  系统）以及 `xz-utils`（FreeType 的锁定版本是 `.tar.xz`）。
* **Windows**——`Windows/Engine/build.ps1` 用其 CMake 构建 FreeType，用 Meson 在
  MSVC 环境下构建 pixman 和 cairo（cairo 带其 DWrite 后端，
  cairo 的 win32 源码需要它才能链接）（libpq 构建已经需要的 pkg-config shim
  通过生成的 `.pc` 文件找到本地锁定版本），把三个静态 `.lib` 链接进 `mad.exe`，并把
  Liberation 字面复制到 `Build\fonts`。写出器会查找
  `<exe>/fonts`、`<exe>/../fonts`、`<exe>/../share/mad/fonts`、
  `/usr/local/share/mad/fonts`、`/usr/share/mad/fonts`、
  `/usr/local/share/fonts/liberation`、`/usr/share/fonts/truetype/liberation`
  以及一个
  `MAD_FONTS_DIR` 覆盖项。

字体是数据文件，不是代码：Windows 包必须随 `mad.exe` 附带
`Windows/Engine/build/fonts`，而 Linux 镜像已经
在 `/usr/local/share/mad/fonts` 携带它们。

## Apple 主体未变

`MADReportExporterPDF` 的 `#if __APPLE__` 路径——Core Graphics、
`MADPrintPageRenderer`、元数据固定——未被触碰。Apple 目标
不链接 Cairo，新写出器的源码也不在其 Xcode 目标中。为记录在案，
Apple 构建命令如下：

	xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
		-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild build -workspace Reports.xcworkspace -scheme 'MAD Designer' \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
		-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci

（它们不会在 Windows 工作站上运行——那里没有 Xcode；本次增量触碰的
Apple 文件是导出器的非 Apple 分支及其
注释。）

## 刻意的限制

* **结构一致，而非字节一致**——Core Graphics 的写出器无法复现。
  基准是遍历（`json-report`/`html`），而非 Apple PDF。
* **无 TrimBox**——cairo 的 PDF API 没有；内容位于裁切内。
* **拉丁文本，从左到右**——字形放置是 FreeType 步进 + `kern` 表，
  而不是整形引擎（无 HarfBuzz/Pango）：无连字、无
  组合标记合成、无双向重排。文档的字段
  和标签是拉丁文本；非拉丁的文档会按逻辑顺序绘制每个码点自身的
  字形。
* **替代字体度量**——见上方残余差异（Verdana 和 Georgia
  差距最大）。
* **Windows WPF Viewer 的格式选择器**不列出 PDF；`mad export
  --format pdf` 和 `mad serve` 的 `export` 会，这就是闭合面。
  添加选择器行是一项 UI 改动，带有自己的字符串资源。

---

## 早先的决策记录

这些小节保留作决策历史，而非指令。

### 候选技术栈（MAD_LINUX.md §10.2）

| 选项 | 许可证 | 它提供什么 | 它的成本 |
|---|---|---|---|
| **Cairo + Pango**（+ FreeType/HarfBuzz） | LGPL-2.1/MPL-1.1、LGPL-2.1、FTL/GPLv2 双许可、MIT | 带 PDF surface 的矢量绘制，以及真正的文本布局 | 镜像中新增一个依赖及其许可证/声明工作 |
| **libharu** | zlib | PDF 输出，许可宽松 | 仅 PDF，无布局引擎 |
| **Skia** | BSD-3 | 能力最接近 CG + Core Text | 沉重的 C++ 构建 |
| **手写 PDF 发射器** | 无 | 无依赖 | 近似排版，第二条绘制路径 |

**所选择的是（2026-11-20）：Cairo + FreeType，无 Pango。** 遍历提供
布局；只剩字形步进和字偶距，FreeType 的 `kern` 表
无需布局引擎即可提供它们。Pango 会为一个无人需要的换行增加一个依赖（及其 LGPL/glib 树）。

### 未决问题，已有答案

1. **字体**——见上方映射表：Liberation Sans/Serif/Mono，选择
   依据是度量兼容的字族，并记录了 Verdana 和 Georgia 的残余差异。
2. **哪个技术栈和许可证**——Cairo（MPL-1.1）、pixman（MIT）、FreeType（FTL）、
   Liberation（OFL）：全部宽松或 MPL，没有 LGPL，无重新链接义务。
3. **写出器位于何处**——在 `MAD` 中，作为 `MADReportExporterPDFCairo`，拥有自己的
   翻译单元和隐藏头文件，仅在非 Apple 上编译。Apple 目标
   不链接它。
4. **是否需要无人值守的服务器端 PDF？**——需要：CLI 的 `export` 动词和
   `serve` 的 `export` 就是这一闭合面，而计划任务没有浏览器。
