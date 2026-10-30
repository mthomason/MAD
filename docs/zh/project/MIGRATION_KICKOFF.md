---
layout: default
lang: zh-CN
---

# 存储迁移——启动简报

面向接手可移植存储迁移的人的交接简报。先阅读 `MAD_STORE_MIGRATION.md`——它是计划，也是事实来源；本文件是任务分配。

## 任务

将 `.mad` 文档的存储从 Core Data 迁移到我们自有的 SQLite 架构上。这是项目最重要的剩余工作：它移除了最后一个 Apple 依赖（`MAD_FORMAT.md` 中的隐患 H3），正是这一点使文档能够在非 Apple 平台上打开。

## 你所处的位置

Objective-C，iOS 15 及以上，仓库位于仓库根目录，主分支为 `master`。代码库庞大——一个主应用加上约 13 个框架。按顺序阅读：`MAD_STORE_MIGRATION.md`、`MAD_FORMAT.md`、根目录的 `CLAUDE.md`（指向 `AGENTS.md` 的符号链接），然后是 `ROADMAP.md` / `TASKS.md` / `BUGS.md`（维护这些文件；不要从它们开始工作）。

## 迁移的内容

`.mad` 文件是 bzip2-tar 归档（现在带有 `MADFILE\0` 标头——v1）。在其中，`StoreContent/analyitics` 是一个 Core Data SQLite 存储，保存着文档**定义**：三样东西——数据库**架构**（创建时从源数据库导入，可重新加载）、**查询**（在 Query 标签页中构建）和报表**布局**（在 Designer 标签页中构建）。行数据*不*在这里；它位于 `.maddb` 缓存中。将那个 Core Data 存储替换为我们自有的 SQLite 架构，使其他平台上的读取器无需 Core Data 即可打开文档。

## 塑造这项工作的发现（`MAD_STORE_MIGRATION.md` §3）

- 它是一个**简单的数据库**：32 个以 `Rptq` 为前缀的实体，以每个实体都带有的 `identifier`（`Integer 64`）为键。
- **无需 Core Data 的 faulting（故障加载）机制。** 定义小于 80 KB；获取模式是按标识符获取和获取根对象。按部分（架构 / 查询 / 布局）按需加载。
- **撤销不是障碍。** 它是 `MADDesignerLayout` 中手写的高层撤销（在 `NSUndoManager` 上调用 `registerUndoWithTarget:handler:`），只需要按 ID 获取和设置属性——不需要 Core Data 的变更跟踪。
- 需要替换的 Core Data 功能只有 `NSFetchedResultsController`（两个文件）和关系遍历；两者都有简单的等价实现。
- 一个整洁的 `MADModel*` 领域层已经封装了 `Rptq` 实体；它是应当保留的接缝。

## 任务分配——先做且只做阶段 A

从 `MAD_STORE_MIGRATION.md` 的**阶段 A** 开始。在阶段 A 和 B 经过评审之前，**不要**开始阶段 C/D。

1. 定义可移植的 SQLite 架构：每个实体一张表，以 `identifier` 为键；为关系建立外键；在四个有序的一对多关系上提供显式的 `position` 列（`RptqDatabaseSchemaTable.hasFields`、`RptqDatabaseSchemaTable.inQueryTable`、`RptqDocumentSection.hasRows`、`RptqDocumentSectionRows.hasObjects`）；为一个多对多关系（`inQuery`）建立连接表；为四个可转换属性提供可移植的标量表示（`UIColor` → RGBA，`NSLocale` → 标识符字符串，`UIImage` → PNG 字节）。
2. 编写一对读取器/写入器，在无头环境下对 `RptqDocument` 图进行往返：在内存中构建图，写入，再读回，断言相等——包括按标识符获取和按部分获取。
3. 为所有内容编写单元测试。将它们添加到 `MAD/MADTests` 下的现有文件中；新的测试文件需要手动编辑 `project.pbxproj` 条目。

当前模型是 `MADDesigner/Resources/MADFileDefinition/MAD.xcdatamodeld/MAD 3.xcdatamodel/contents`（32 个实体）。生成的 `Rptq` 头文件位于 `MAD/Source/rptq/autogen/`——将它们作为固定的、手工维护的契约保留（停止重新生成），并自行编写 CRUD。

## 不可妥协的事项

- 成功 = 除 iCloud 之外的一切都继续正常工作。本地打开/保存、查询/设计/查看器、刷新/导出，以及 `.maddb`/`.mdcache`/`.madac` 缓存都保持今天的行为。剥离 iCloud 是阶段 D，放在最后。
- 不要删除 `Compressor/library` 下的任何内容。
- 两个样本——`MADDesigner/Resources/Assets/Samples.xcassets/Reports/London.dataset/London.mad` 和 `Music.dataset/Music.mad`——在整个过程中必须始终可打开；它们是阶段 B 的测试夹具。
- 使用制表符缩进；注释从简。
- 在声明处用 clang 属性标记有意未使用的代码（`__attribute__((unused))`、`__unused`、`NS_UNAVAILABLE`）。
- 在紧凑循环中不要使用 `+[NSString stringWithFormat:]`；遵循 `initWithFormat:` / `appendFormat:` 的内部风格。

## 构建与测试

```
xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
```

其他框架的 scheme 可替换为 `MADSqlite3`、`MADFoundation` 等。如果 `iPhone 17 Pro` 无法解析，用 `xcrun simctl list devices` 列出已启动的模拟器。无头的 `mad` CLI——`CLI/build.sh --run <command> <document.mad>`——可以在没有应用的情况下验证文档路径：`inspect`、`schema`、`query`、`refresh`、`export`。

## 汇报

你构建了什么、编写了哪些测试，以及干净的 `xcodebuild test` 结果。在分支上工作；除非被要求，否则不要推送到 `master`。
