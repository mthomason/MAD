---
layout: default
title: MAD — 移动分析文档
description: >-
  面向关系型报表的开放格式与可嵌入引擎——适用于原生 macOS（AppKit）与 iOS 的 MAD Designer 和 MAD Viewer、面向 Linux 与 macOS 的无头 mad CLI，以及开放的 .mad 规范。
image: /assets/mad-icons-banner.png
lang: zh-CN
---

<p><a href="https://raw.githubusercontent.com/mthomason/MAD/master/StaticResources/Images/icons/document/Designer%20Icon@3x.png"><img src="../assets/mad-designer-macos-icon-256.png" alt="MAD Designer 图标" width="64" height="64" align="left" style="margin-right: 16px; margin-bottom: 8px;" /></a><strong>面向关系型报表的开放格式与可嵌入引擎——在这里，每一份报表都是一个可移植的查询图、一张物化的 SQLite 表和一套参数化布局。</strong></p>

MAD 是一个用 Objective-C 从零构建的关系型报表平台，用于即席查询、报表和设计：面向 iOS 与原生 macOS（`AppKit`）的 **MAD Designer** 和 **MAD Viewer** 应用，在 Linux 与 macOS 上以无头方式运行它们的引擎，以及开放的 `.mad` 文档格式。一个 `.mad` 文件在不到 100 KB 的体积内保存报表的完整定义——数据库架构快照、查询图（表、连接、谓词、分组）以及各元素的带区布局——并与刷新时生成的物化 SQLite 表（`.maddb` + `.mdcache`）清晰分离。

代码位于 [github.com/mthomason/MAD](https://github.com/mthomason/MAD)，采用 MIT 许可证；项目名称与应用美术资源不在该许可证的授权范围内（参见 [NOTICE](https://github.com/mthomason/MAD/blob/master/NOTICE)）。

## 看看效果

**[适用于 macOS 的 MAD Designer](macos.html)**——原生 `AppKit` 桌面应用（`NSDocument`、可视化的表与连接查询画布、可交互的节区缩略图与带区报表设计器，以及分页的 PDF/HTML/CSV/JSON 报表查看器）：

![原生 macOS 应用中的 MAD Query 工作区](../assets/macos-native-mad-query.png)

![原生 macOS 应用中的 MAD Designer 工作区](../assets/macos-native-mad-designer.png)

**适用于 iOS 的 MAD Designer**，从选择数据源到在 MAD Viewer 中阅读完成的报表：

<video controls playsinline preload="metadata" width="360"
  poster="../assets/app-preview-poster.png">
  <source src="../assets/app-preview.mp4" type="video/mp4">
  你的浏览器不支持 video 元素；<a href="../assets/app-preview.mp4">应用预览</a>是一个普通 MP4 文件。
</video>

**同一引擎在 Linux 上以无头方式运行**：通过 `mad` CLI 执行 `inspect`、`schema`、`query`、`refresh` 和 `export`，无需数据库服务器，也无需凭据：

![mad CLI 正在检查、查询、刷新并导出一个 .mad 文档](../assets/mad-cli-demo.gif)

录像中[导出的报表](../assets/london.html)是纯 HTML，可在任意浏览器中打开。

## 为什么选择 MAD

* **通过契约实现互操作。** 与其在整个组织内散落一次性的 SQL 脚本和定制的仪表板胶水代码，`.mad` 文件把架构契约、查询 AST 和呈现布局打包成一个可检查、可 diff 的产物，在 Apple 与 Linux 上生成逐字节一致的 SQL 和导出结果。
* **自研，而非拼装。** SQL 生成器、SQL 解析器、数据表引擎、存储、布局模型和渲染器都是十四个框架中自研的 Objective-C 代码。第三方代码严格限于通信链路——MariaDB Connector/C、FreeTDS、`libpq`、SQLite——以及用于条形码的 `libarchive`/`bzip2` 和 `zint`。没有转售任何专有报表 SDK。
* **移动优先，按内存预算设计。** 一次刷新会把结果集一次性读入 SQLite 行缓存（`MADDataTableFast`），并在其中计算两趟分组和聚合，因此分页渲染在手机的内存预算内依然很快。
* **可嵌入、可移植。** 十四个框架中有十一个不依赖 UIKit，可以无头构建，并在 Docker 中的 Linux 上通过 1,303 个测试。`.mad` 容器是一个 bzip2 tar 归档，内含可移植的 SQLite 存储；打开它不需要任何 Apple 框架。

## `.mad` 格式

开放规范，每个文件一章：

[文档是什么](01-document.html) ·
[容器](02-container.html) ·
[存储](03-store.html) ·
[读取与写入](04-reading-writing.html) ·
[伴随文件](05-companion-files.html) ·
[风险](06-hazards.html) ·
[规范性 `v1`](07-normative.html) ·
[开放问题](08-open-questions.html) ·
[验证](09-verification.html)

## 使用引擎

* [适用于 macOS 的 MAD Designer](macos.html)——原生 `AppKit` 桌面应用：
  可视化查询画布、带缩略图和检查器的带区报表设计器、分页查看器，以及如何从源码构建或打包。
* [构建与测试](https://github.com/mthomason/MAD#build-and-test)——
  iOS 测试套件、原生 macOS 测试套件和 Linux 构建的确切命令。
* [`mad` CLI](https://github.com/mthomason/MAD#try-it)——用一行 Docker 命令
  检查、刷新并导出 `.mad`。
* [mad-action](https://github.com/mthomason/mad-action)——在 GitHub Actions 中
  运行仓库中签入的 `.mad` 并上传其导出结果；`mthomason/mad-action@v1`。
* [驱动编写教程](tutorials/driver-authoring.html)——理想的第一个贡献：
  继承 `MADDatabase`、注册驱动、返回数据行。

## 方向

[愿景](vision.html)——报表即组合式数据库表、单份报表中的多数据源查询、超越纸面范式的原生 UIKit 数据视图，以及把旧版 Crystal Reports（`.rpt`）转换为开放的 `.mad` 文件。

---

构建于该引擎之上的报表设计器 **MAD Designer** 应用有自己的站点：[mad.everydayapps.com](https://mad.everydayapps.com/)。
