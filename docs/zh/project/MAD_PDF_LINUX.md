---
layout: default
lang: zh-CN
---

# Linux PDF 写入器——现状、选项以及仍然缺失的部分

**现状（2026-10-17）：有意推迟，需等待用户的研究完成。未经用户决定，不要开始。** 本文件的存在是为了让下一个代理知道缺少什么、已经决定了什么，以及有意不做什么。

## 已有的部分

`pdf` 位于导出接缝上，但它是唯一无法在 Linux 上运行的格式：

* `MADReportExporterPDF` 在所有平台注册（`+load`），要求 `--out`，其主体是 Apple 的实现——通过 `UIPrintPageRenderer` 进行 Core Graphics 绘制。它与接缝出现之前 CLI 使用的代码相同，输出与之逐字节一致（London 样本上为 43,177 字节、5 页、`sha256 3eb2f1c4…`）。
* 在非 Apple 平台上，它以给出原因的方式回答 `+isAvailable NO`，并且 `mad export --format pdf` 会以退出码 5 退出并说明原因。不会有任何东西悄然生成不同的产物。
* 写入之上的一切已经共享，并且在两个平台上已经一致：`MADReportPageBuilder` 准备文档（对行排序、确定格式化器尺寸、布置报表），并以 US Letter 纸张加 1pt 裁边遍历页面；`MADReportPageBuilder` + `MADDocumentRenderProtocol` + `MADDocumentRenderDataSource` 构成唯一的渲染路径。对于 London 测试夹具，`html`、`html-flow` 和 `json-report` 导出在各平台之间逐字节一致（`Linux/README.md`），因此页面数量、每个元素的 frame、每行的文本，以及每行的字体、字号、字重特征和对齐方式，都是对写入器而言已知良好的输入。
* 目前 Linux 上受支持的获取 PDF 的方式，是用浏览器打印 `--format html`——这就是复制本存在的原因，也是它带有页面框的原因。

## 缺少的部分

**只缺写入。** 一个 `MADReportExporterPDF` 的 Linux 主体，将遍历得到的页面绘制到 PDF 文件中。它之上的一切都不变：相同的准备、相同的页面、相同的 frame、相同的文本、相同的样式。

## 已确定的目标（`MAD_LINUX.md` §10.2）

相同的页面数量、相同的区段与元素框、相同的文本和相同的字体——**而非**逐字节一致。Core Graphics 的 PDF 写入器无法复现，因此字节相等不可行，也不应作为测试。验收目标是结构性的：

* 页面数量以及每页的尺寸和裁边；
* 每行的 frame（由遍历给出）和已解析文本；
* 每行的字体族、字号、字重、倾斜、装饰和对齐；
* 相同的页面上带有相同的页面附属元素。

## 候选技术栈

记录在 `MAD_LINUX.md` §10.2；为便于决策在此重复：

| 选项 | 许可证 | 提供什么 | 代价是什么 |
|---|---|---|---|
| **Cairo + Pango** (+ FreeType/HarfBuzz) | LGPL-2.1/MPL-1.1, LGPL-2.1, FTL/GPLv2-dual, MIT | 带 PDF 表面的矢量绘制，以及真正的文本布局——Linux 上最接近 Core Graphics + Core Text 的方案；GTK/WebKit/Firefox 使用的技术栈 | 镜像中新增一个依赖以及相应的许可证/声明工作；LGPL 是项目已经处理过的一类许可证（FreeTDS） |
| **libharu** | zlib | PDF 输出，许可证宽松 | 仅支持 PDF，没有布局引擎：换行和定位需要手工实现 |
| **Skia** | BSD-3 | 在单个库中最接近 CG + Core Text 的能力，带有 PDF 后端 | 沉重的 C++ 构建；值得加一个 Impl 包装层 |
| **手写 PDF 生成器** | 无 | 无依赖；base-14 字体无需嵌入 | 排版近似，且会出现第二条绘制路径——正是用户在 2026-10-16 否决的偏差 |

## 需要研究的未决问题

1. **字体是问题的一半，而它们并不在上表中。** 文档指定的是 Apple 字体：`MADFont` 默认为 Helvetica Neue，London 样本使用 Verdana、Helvetica Neue 和 Courier。Linux 上这些字体一个都没有。写入器需要度量兼容的替代字体（Nimbus Sans / TeX Gyre Heros / Liberation）和一套映射策略，而该策略会改变“看起来一样”的含义。这是如果跳过，最有可能令人失望的部分。
2. **选择哪个技术栈，以及付出多少许可证代价。** 就能力而言，推荐 Cairo + Pango；其 LGPL 义务对于部署形态是否可接受由用户决定，`Compressor`/`Linux/libraries.conf` 中的构建成本同样如此。
3. **写入器放在哪里。** 放在 `MAD` 中（由镜像和 CLI 链接，Apple 主体不变），还是放在导出器链接的独立框架中？接缝对两者都支持；这取决于该依赖的影响范围。
4. **是否真的需要无人值守的服务器端 PDF？** 浏览器打印 HTML 复制本目前可以覆盖人工驱动的导出。而没有浏览器的计划任务则不能。在这一点得到回答之前，没有任何事情受阻。

## 验收测试，决策后即可使用

判定基准已经存在：可以将 Linux PDF 与两个平台已经一致的结果进行比较。

* 页面数量、纸张大小和裁边，对比 `MADReportPageBuilder` 的遍历结果；
* 每行的 frame 和文本，对比同一文档的 `json-report` 输出（Linux 与 Mac 的字节相同，因此它是稳定的判定基准）；
* 视觉页面对比 `html` 复制本（相同的框、相同的文本）；
* Apple 的 PDF 不得改变：在 London 样本上为 43,177 字节 / 5 页 / `sha256 3eb2f1c4…`，用 `--deterministic` 检查。

## 在此期间做什么

阶段 F（`MAD_LINUX.md` §9）：Compressor Linux 驱动、CMake 打磨、CI 行和可部署镜像。这些都不依赖 PDF 写入器，并且是阶段 E 之后记录在案的下一步。`BUGS.md` 中的未决条目也可以着手——但根据该文件自身的规则，不由代理主动发起。
