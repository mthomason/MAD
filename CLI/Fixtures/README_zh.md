[English](README.md) | **简体中文** | [日本語](README_ja.md)

# CLI 测试夹具

记录 CLI 各动词所针对运行的文档，与它们来源的示例放在一起（`docs/project/MAD_CLI.md` §6）。

| 测试夹具 | 来源 | 固定验证的内容 |
|---|---|---|
| `London.portable.mad` | `MADDesigner/Resources/Assets/Samples.xcassets/Reports/London.dataset/London.mad` | Sqlite3 数据路径：11 张表的架构、London 谓词、76 行 |
| `Music.portable.mad` | `.../Reports/Music.dataset/Music.mad` | 同一路径在较大示例上的应用（3503 行） |
| `MySQL.employees.mad` | `employees` 示例数据库，实时（MySQL 8.4） | MySQL 驱动路径的端到端验证：架构导入、反引号 SQL、预编译语句提取 |
| `TDS.AdventureWorksLT2022.mad` | AdventureWorksLT2022，实时（SQL Server 2022） | TDS 路径的端到端验证：带架构限定的表、方括号 T-SQL、freetds 提取 |
| `Postgres.chinook.mad` | Chinook，实时（PostgreSQL 17） | PostgreSQL 路径的端到端验证：架构导入、双引号 SQL、libpq 提取 |

## 示例为什么需要转换

两个随附示例都是**旧式**（legacy）文档：它们的定义是一个 Core Data 存储（`StoreContent/analyitics`），而转换其中一个需要 Core Data，MAD 框架不链接 Core Data，Linux 也没有 Core Data（`docs/project/MAD_LINUX.md` §5.1、§9）。
`London.portable.mad` 和 `Music.portable.mad` 是同样这两个文档以可移植存储写成的版本，因此没有 Core Data 的平台也能读取和刷新它们——Linux CLI 和 `Linux/Tests/MADHeadlessDocumentTests.m` 正是这样做的。

它们也是 v0 示例在读取侧的对应物：`mad inspect` 将测试夹具报告为 v1，带有 `StoreContent/store.sqlite`，而将示例报告为 v0，使用旧式存储；这两个结论都来自同一个容器读取器。

三个实时测试夹具是应用的创建链针对真实服务器写出的普通文档，因此它们的架构是真实的（`employees` 的 8 张表、AdventureWorksLT 的 12 张表、Chinook 的 11 张表），查询也是真实的 SELECT。

## 它们是如何制作的

在 Mac 上，使用应用自身的代码路径——这里没有任何内容是手工编写的：

	CLI/build.sh --make-fixture portable "$PWD/MADDesigner/Resources/Assets/Samples.xcassets/Reports/London.dataset/London.mad" \
		"$PWD/CLI/Fixtures/London.portable.mad"
	CLI/build.sh --make-fixture portable "$PWD/MADDesigner/Resources/Assets/Samples.xcassets/Reports/Music.dataset/Music.mad" \
		"$PWD/CLI/Fixtures/Music.portable.mad"

	CLI/build.sh --make-fixture create mysql mac 13306 root root employees "$PWD/CLI/Fixtures/MySQL.employees.mad"
	CLI/build.sh --make-fixture select "$PWD/CLI/Fixtures/MySQL.employees.mad" titles "title,from_date,to_date"

	CLI/build.sh --make-fixture create tds mac 1433 sa 'Root1@Root2' AdventureWorksLT2022 "$PWD/CLI/Fixtures/TDS.AdventureWorksLT2022.mad"
	CLI/build.sh --make-fixture select "$PWD/CLI/Fixtures/TDS.AdventureWorksLT2022.mad" "SalesLT.Product" "Name,ListPrice,Color"

	CLI/build.sh --make-fixture create postgres mac 5432 mad mad_test_pw chinook "$PWD/CLI/Fixtures/Postgres.chinook.mad"
	CLI/build.sh --make-fixture select "$PWD/CLI/Fixtures/Postgres.chinook.mad" track "name,composer,unit_price"

`--make-fixture` 编译 `MADFixtureMaker.m`（与工具相同的标志，外加旧式转换器和值转换器），并在模拟器中运行它：

* `portable` 复制文档，用 `MADocument` 打开它——打开时会转换旧式存储——将其标记为已更改并关闭，这就是保存路径。
* `create` 针对实时服务器运行应用的创建文档链：创建文档、首次设置、添加连接、导入架构、关闭（关闭时保存）。
* `select` 执行设计器在勾选表及其字段时所做的工作：添加查询表、为每个架构字段添加一个查询字段，并为每个查询字段添加一个数据标签——正是这些标签使字段变为*活动*状态，因为 SELECT 列表就是报表元素所引用的字段（`MADQueryActiveQueryFields`）。

结果在不同次运行之间不是字节稳定的（存储是 SQLite，归档携带时间戳），因此只有在示例或存储格式变化时才重新生成测试夹具；它们出现的差异是真正值得查看的差异。

## 实时测试夹具中的主机名

三者都将服务器命名为 `mac`——这台 Mac 的主机名，在这里以及在 Docker 容器内都会解析为其局域网地址。因此，一个名称同时用于 Mac 的 MySQL（由下面的测试夹具容器发布在回环地址*和*局域网上）以及 SQL Server 和 PostgreSQL 容器（发布在所有接口上），这样同一文档既可以从 Mac 刷新，也可以从 Linux 镜像刷新。`host.docker.internal` 只能在容器内使用；`127.0.0.1` 只能在 Mac 上使用。

三个实时测试夹具都是针对规范的测试容器创建的；`docs/project/DEVELOPER.md` 记录了这些容器，其脚本从固定版本的镜像和经校验和验证的数据集创建它们：

	MADMySQL/TestDatabase/mysql-test-db.sh up          # mad-mysql on 13306
	MADTdsClient/TestDatabase/sqlserver-test-db.sh up  # mad-mssql on 1433
	MADPostgres/TestDatabase/postgres-test-db.sh up    # mad-postgres on 5432

三者都在所有接口上发布，因此文档中的 `mac` 主机名从 Mac 和 Linux 镜像内部都能解析。MySQL 容器使用 13306 而不是 3306，因为 Oracle MySQL 安装程序的 launchd 服务可能占用 3306。`down` 停止服务器（数据卷保留数据）；`reset` 将其移除，下一次 `up` 会重新构建它。

CLI 的 `--host`、`--port` 和 `--database` 在单次运行中覆盖存储的连接（`docs/project/MAD_CLI.md` §3），CI 任务正是以此将其中一个文档指向主机和端口与 Mac 不同的服务容器。文档本身不会被改写。
