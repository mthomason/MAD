---
layout: default
lang: zh-CN
---

# 方向：报表即表

更新于 2026-10-29。本页说明 MAD 设计上要发展的方向。这里描述的组合同构或迁移机制尚未构建；奠定数据对象模型基础的设计是
[`docs/project/MAD_DATA_OBJECT.md`](https://github.com/mthomason/MAD/blob/master/docs/zh/project/MAD_DATA_OBJECT.md)，
工作记录是
[`docs/project/MAD_FUTURE.md`](https://github.com/mthomason/MAD/blob/master/docs/zh/project/MAD_FUTURE.md)，
产品愿望清单是
[`docs/project/TODO.md`](https://github.com/mthomason/MAD/blob/master/docs/zh/project/TODO.md)。

## MAD 的现状

一个 `.mad` 文档是报表的*定义*：架构快照、查询图（表、连接、分组、筛选）以及带区布局树。刷新时，引擎把查询图编译为 SQL，一次性读取数据行，并把它们物化到伴随 SQLite 缓存（`.maddb` + `.mdcache`）中。行数据被有意留在文档之外；定义则保持在 100 KB 以下。

有一个后果很容易被忽略：**报表是一个从数据源到表的函数。** 每个驱动都以表的形式返回架构和数据行，而报表的输出*就是*表形式的架构（`MADDataColumn`）和数据行（`MADDataTableFast`）。引擎已经把两者同等对待。

## 它将走向何方

打通报表定义与其物化输出之间的闭环，将解锁四项能力：

### 1. 把 `.mad` 文件当作即席数据库表

在数据库中，你从 `employee` 或 `sales_data` 这样的基表中选择数据。报表把多张表连接在一起，其输出是一张即席的、物化的 SQLite 表。今天没有任何东西能把查询指向另一份报表的输出——结果缓存确实存在，但它的键是文件名哈希，而不是可寻址的身份。让该输出可寻址意味着：

> **报表的结果成为一张数据库表，其他报表和查询可以从中选择并与之连接。**

建立在报表之上的报表，构成由派生表组成的有向无环图（DAG）——一个可移植的语义层：设计报表的同时，也在设计可复用的数据源。

### 2. 单份报表中的多数据源

每个驱动（`MADMySQL`、`MADPostgres`、`MADTdsClient`、`MADSqlite3`）都把自己的结果集物化为相同的本地 SQLite 表表示。一旦一份文档可以容纳多个查询定义，并把每个输出寻址为一张表，一份报表就可以把 PostgreSQL 表、SQL Server 表和 MySQL 表连接起来——在 SQLite 中本地联邦，中间不需要联邦服务器。快照*就是*联邦。

### 3. 纸张只是一种范式——基于原始数据的原生 UIKit 视图

带区分页（报表页眉、页眉、分组、明细、页脚）是为在纸上打印而发明的。由于 `.mad` 布局是参数化数据，且 `.maddb` 行缓存是设备上的本地 SQLite，纸面页面只是呈现报表的一种方式。当用户不打印时，同一份定义和本地缓存可以渲染为可交互的原生 UIKit 视图和原始数据浏览器——一次布局，既可查看纸面，也可查看原生 UI。

### 4. 把旧版 Crystal Reports（`.rpt`）转换为开放的 `.mad` 文件

Crystal Reports（`.rpt`）及类似的旧版报表文件仍在数千家企业中根深蒂固，因为没有任何开放、可移植的引擎共享它们的带区节 + 关系查询图模型。由于 MAD 正是构建在这一结构范式之上——同时把定义存储在开放、有文档的 SQLite-in-tar 格式中——把旧版 `.rpt` 文档转换为 `.mad` 文件，为企业提供了一条直接迁离专有旧版报表技术栈的路径。

## 已经存在的部分

昂贵的部分已经构建完成：可移植定义、确定性的 SQL 生成与解析、可移植的物化格式（SQLite）、四个数据库驱动，以及一个在 iOS/macOS 上原生运行、在 Linux 上以无头方式运行的引擎。

## 这不是什么

不是承诺。本页记录方向；设计和任务队列位于 `docs/project/`，这里描述的任何东西，都要像仓库中其他所有内容一样经过设计、测试和文档化之后才会发布。
