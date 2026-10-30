---
layout: default
lang: zh-CN
---

# `.mad` 文档格式

本文定义 `.mad` 文件是什么。它描述格式**当前的实际情况**，取自两份已发布的示例文档以及读写它们的代码；然后说明格式**应当如何定义**，使另一个平台上的读者——命令行工具、Windows 构建——无需依赖 Core Data 或任何 Apple 框架即可打开文档。

格式之所以重要，是因为报表*很小*——已发布的示例不到 80 KB——而且运行它的引擎既能装在手机上，也能装进容器：同一份定义可在 iOS、macOS 和 Linux 无头构建上运行。格式的发展方向——报表的结果表成为其他报表的数据源，从而让一份文档横跨多个数据库——见 [`vision.md`](vision.md)。规范也作为网站在 <https://docs.everydayapps.com> 上提供。

前半部分的一切都是实测结果，而非推断。两份示例分别是
`../../MADDesigner/Resources/Assets/Samples.xcassets/Reports/Music.dataset/Music.mad` 和
`…/London.dataset/London.mad`。

---

**`.mad` 格式是一份开放规范。** 任何人都可以阅读并实现它。MIT 许可证覆盖本项目的代码。“MAD”“MAD Designer”和“MAD Viewer”这些名称，以及应用图标和其他产品美术资源，归作者所有且未授予许可；对 `.mad` 文件及本项目的描述性引用是受欢迎的。参见 [`../../LICENSE`](../../LICENSE)、[`../../NOTICE`](../../NOTICE)
和 [`project/THIRD_PARTY_LICENSES.md`](project/THIRD_PARTY_LICENSES.md)。

规范按每个文件一章组织。第 1–6 章描述随版本发布的格式；第 7 章是规范性目标（`v1`）；第 8–9 章是开放问题以及各项主张的验证方式：

1. [用一句话说明文档是什么](01-document.md)
2. [容器](02-container.md)
3. [存储](03-store.md)
4. [读取与写入的实现](04-reading-writing.md)
5. [文档中*没有*的东西：伴随文件](05-companion-files.md)
6. [第二读取器必须处理的风险](06-hazards.md)
7. [格式应当如何定义](07-normative.md)
8. [开放问题](08-open-questions.md)
9. [验证](09-verification.md)
