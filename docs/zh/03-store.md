---
layout: default
lang: zh-CN
---

## 3. 存储

`StoreContent/analyitics` 是一个普通的 SQLite 数据库：

```
StoreContent/analyitics: SQLite 3.x database, last written using SQLite version 3043002,
  writer version 2, read version 2, file counter 52, database pages 126, cookie 0x6e,
  schema 4, largest root page 113, UTF-8, vacuum mode 1, version-valid-for 52
```

它保存**文档定义**：查询、其表与连接、报表的节区和元素，以及数据库架构快照。Core Data 模型是
`MAD/MAD.xcdatamodel`；其所有实体都带 `Rptq` 前缀（`RptqDocument`、
`RptqQuery`、`RptqDocumentElement`、`RptqDocumentSection` 等）。

这个存储有两个属性对可移植性至关重要：

1. **它以 WAL 模式写入。** `-wal` 和 `-shm` 与主数据库一起打包在归档中。只解出 `analyitics` 而忽略
   WAL 的读取器，读到的数据库最多会落后一个检查点。在 `Music` 示例中，
   WAL 是 **313 KB，而主文件为 516 KB**——这不是理论风险。
2. **它是 Core Data 存储**，因此其架构是 Core Data 的，而不是我们的。不依赖 Core Data 读取它，
   意味着读取 Core Data 自己的表。这可行——它就是 SQLite，映射关系是稳定的——但这是本格式中
   把读取器绑定到 Core Data 的部分，也是迁离 Core Data 在这里比任何其他地方都更重要的原因。

### 3.1 可移植存储（存储迁移之后）

自存储迁移（`project/MAD_STORE_MIGRATION.md`）以来，文档定义存放在我们自己设计的可移植 SQLite 存储中。
其架构由手工维护的 `MADStoreSchema` 描述符（`MAD/Source/rptq/store/`）描述，由
`-createSchemaSQL` 生成，并由 `MADStoreTests` 与编译后的模型交叉校验。
存储在 `PRAGMA user_version` 中记录架构版本：版本 1 是随版本发布的架构
（缺失或为 0），版本 2 增加 `RptqQuery.sqlSourceText`——用户粘贴的 SQL，按原样保存
（`project/MAD_SQL_ENTRY.md` §8）——`MADStore` 在打开时应用缺失的
步骤。`RptqQuery` 表的字段：

| 列 | 类型 | 说明 |
|---|---|---|
| `identifier` | INTEGER | 行键 |
| `cachedText` | TEXT | |
| `override` | INTEGER | |
| `overrideText` | TEXT | |
| `sqlSourceText` | TEXT | 最近一次成功应用的粘贴语句，按原样保存；否则为 NULL |
| `inDatabase_identifier` | INTEGER | 指向 `RptqDatabase` 的外键 |
