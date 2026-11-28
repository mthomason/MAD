---
layout: default
title: "组合报表"
description: >-
  将来自多个数据库的报表合并为一个可移植的 .mad 文档：每个源保留自己的查询、布局和数据，结果将它们联接成一份新报表。
lang: zh-CN
---

# 组合报表

一份**组合报表**将其他报表合并到一个 `.mad` 文档中。你引入的每份报表都是一个**源**；文档的默认报表是**结果**，它把各源的结果表联接成一份属于它自己的新报表。

组合让单个可移植文档横跨多个数据库——MySQL、PostgreSQL、SQL Server 和 SQLite——而无需在中间放置联邦服务器。源是**连同其布局**一起被引入文档的；组合它们并不会把源压平成一张表。组合中的每个成员都是一份完整的报表。

> **平台：** 组合报表在 **MAD Designer for macOS**（0.8）和 **MAD Designer for Windows**（0.8）中可用。iOS 应用尚不能创作组合；本页介绍桌面应用。


## 心智模型

> 组合报表把其他报表合并为一个。你引入现有报表（**源**），联接它们的结果表以构建一份新的**结果**报表，选择要显示的结果**列**，然后像标准报表一样设计和查看该结果。选中一个源，你又会得到该源的查询、布局和数据行。

四个动词概括了工作流：**添加源 → 联接它们 → 选择列 → 选择**。

| 术语 | 含义 |
|---|---|
| **组合报表** | 一个保存报表图的 `.mad` 文档：结果及其各个源。 |
| **结果** | 文档的默认报表。它联接各源的物化表，是首先打开的报表、默认打印的报表和默认导出的报表。 |
| **源** | 引入组合的子报表。它保留自己的查询、数据库连接、布局和数据行。 |
| **报表列** | 结果向其自身布局及其父级公开的字段。在 Query 工作区中编辑（macOS 上是 **Outputs…** 项，Windows 上是 **Columns**）。 |
| **无布局的源** | 报表尚无任何元素的源。设计器会提议创作布局；查看器把它的数据行显示为表格。 |

### 每个成员都是一份报表

是这条规则让该功能清晰可读。源在被导入时并不会被简化为一张表：它的查询定义、它自己的报表布局和它的数据都会一同带入，并保存在同一个 `.mad` 文档中。数据行保留在伴随存储中（文档旁的 `.maddb` 和 `.mdcache` 文件），而不是 `.mad` 内部。

在 **Report** 选取器（macOS）或 **Component** 选取器与 Composition 窗格（Windows）中选择一个源，会把**全部三个工作区**——Query、Designer 和 Viewer——切换到该源。无布局的源仍然是一份有效的报表：查看器会把它的缓存行显示为网格，而不是页面。



## 创建组合

### macOS

* **File ▸ New Document…** 提供 **Standard Report** 和 **Composition Report**。选择 Composition Report 会让你挑选一个或多个现有的 `.mad` 报表，然后选择新组合的保存位置。
* **File ▸ New Composition…** 是同一流程的直接命令。
* **File ▸ Convert to Composition…** 把当前打开的标准报表变成一个单源组合，并保留其布局。
* 在 **MAD Query** 工作区中，Add 菜单可以添加表、来自新数据库连接的**源查询**、**导入的报表**，或组合后的**根查询**。

工具栏的 **Report** 选取器先列出**结果**（标记为 *Result — <name>*），然后列出每个源。选择某一项从不会改变活动工作区；它改变的是该工作区正在显示哪份报表。

### Windows

* **File ▸ New Composition…** 从现有报表创建组合。
* **File ▸ Import…** 把一份报表添加为当前组合的源。
* **File ▸ Convert to Composition** 把当前打开的标准报表变成组合。

工作区旁有一个停靠的 **Composition** 窗格（标准报表没有该窗格）。它的图在深度 0 显示结果，并在下方显示各个源，连接线指向消费方。该窗格与工具栏的 **Component** 选取器共享同一个选择；窗格可以折叠，而选取器仍然保留。

## 联接源并选择列

在结果的画布上，把字段从一个源卡片拖到另一个源卡片中的字段即可创建联接，然后点击联接徽标更改其类型（`INNER`、`LEFT OUTER`、`RIGHT OUTER`、`FULL OUTER`、`CROSS`）或反转其方向。结果是一条普通查询：它可以联接任意数量的源，并进行筛选、分组和排序。

本身就是一个组合的源会带着自己的各个源加入图；父级引用该组合的结果。组合节点只引用它的子级——绝不引用远程表——因此每个叶子针对自己的数据库运行，而每个联接步骤都在本地 SQLite 中运行。

使用结果的**报表列**编辑器来选择、命名和排列结果所公开的字段。结果的设计器字段列表正是该集合。源公开它自己的查询字段。

## 刷新、凭据与隐私

刷新按**子级在前、结果最后**的顺序运行图。每个叶子以自己的凭据针对自己的数据库执行；每份组合报表在本地、在其子级的物化表之上运行。每个节点都物化自己的表，某个节点失败会使刷新失败，同时让上一次的完整结果保持可读。

因此，多源组合会为**每个源请求一份凭据**，一次一张表单，驱动、主机、端口、数据库和非机密用户名都已预先填好。密码绝不存储在 `.mad` 文件中：macOS 把它们保存在钥匙串中（或当前会话中），Windows 把它们保存在会话或平台凭据存储中。SQLite 源不需要凭据。

## 示例

两个可运行的组合位于 [`Samples/Reports`](https://github.com/mthomason/MAD/tree/master/Samples/Reports)：

* **`Chinook-Composition.mad`**——两个 SQLite 源（一个 Albums 报表拥有自己的布局，一个 Artists 报表没有）联接成一个结果。除随附的 `chinook.sqlite3` 外，它不需要任何东西。
* **`Composition-MySQL-PostgreSQL-SQLServer.mad`**——从 MySQL、PostgreSQL 和 SQL Server 各取一张小表，按 `demo_id` 联接，演示一份横跨三个数据库的文档。

用一个幂等脚本启动三个实时服务器并填充跨数据库表（macOS、Linux 和 Windows 上的 Git Bash）：

```sh
./Samples/setup-databases.sh up
```

在 Windows PowerShell 上：

```powershell
.\Samples\setup-databases.ps1 -Action up
```

`up` 通过测试数据库脚本创建或启动固定版本的容器，并把 `composition_demo` 表载入每个服务器。`status` 报告容器和行数；`down` 停止它们。使用 `./Samples/setup-databases.sh sql` 可以在没有 Docker 的情况下打印同样的 SQL。首次运行的操作演练（包括每个源的密码提示）见[示例指南](https://github.com/mthomason/MAD/blob/master/Samples/README.md)。

## 当前限制

* **仅限同一文档。** 每个源的定义和布局都位于同一个 `.mad` 文件内。不支持引用不同文件中的报表。
* **每份组合报表最多十个直接子级。** 引擎的 SQLite 构建允许十个附加数据库；设计器会拒绝第十一个子级。
* **嵌套组合在 Query 工作区中为只读。** 本身是一个组合的源会显示它所联接的各个源，但直接创作嵌套组合是后续工作。
* **`json-report` 只导出结果。** 其他所有导出格式都导出所选报表。

## 相关

* [适用于 macOS 的 MAD Designer](macos.html)——原生 `AppKit` 应用。
* [适用于 Windows 的 MAD Designer](windows.html)——原生 WPF 应用。
* [方向](vision.html)——把报表作为可组合的数据源。
* [数据对象](developers/data-object.html)——把报表的定义、架构和结果集作为同一个契约。
* [多源报表](developers/multi-source.html)——同一文档组合背后的架构。
