---
layout: default
lang: zh-CN
---

# 开发者

## 第三方库（Compressor）

应用的第三方静态库由 `Compressor` 按需构建——没有任何第三方内容处于版本控制之下。设计见 `LIBRARIES.md`；这里是日常用法。

**在全新检出上首次运行**（需要网络，约 30–90 分钟，其中大部分时间花在较大的源码压缩包上）：

```
Compressor/build.sh --all --platforms ios,simulator
```

此后 Xcode 构建会在其“Ensure Libraries”阶段直接空转；如果某个库缺失或已过期，该阶段会在编译之前把它构建出来。强制重建单个库：`Compressor/build.sh --rebuild <lib>`。

**验证产物：**

```
Compressor/build.sh --verify --all --platforms ios,simulator
```

**升级库版本：** 编辑 `Compressor/matrix.conf` 中它的那一行（版本、URL、新归档的 sha256），然后运行 `Compressor/build.sh --rebuild <lib>`，并运行使用该库的框架的测试套件以及 `--verify`。每个提交只处理一个库。mariadb、freetds、postgres 和 zint 的配方带有按版本区分的知识——在升级这些之前，请先看 `LIBRARIES.md` §1 中的说明。

## 在 Linux 上构建（阶段 B–D）

Linux 工具链的探索项目位于 `Linux/`，由单个脚本驱动——见 `Linux/README.md` 和 `MAD_LINUX.md` §9。它需要 Docker；Docker Desktop 的 CLI 默认不在 `PATH` 中，脚本会自行找到它。

```
./Linux/build.sh              build the build image, run the Linux tests
./Linux/build.sh --test       run the tests in the existing build image
./Linux/build.sh --runtime    build the CLI runtime image (mad-cli:latest)
./Linux/build.sh --verify     build the runtime image, then verify the CLI in it
./Linux/build.sh --probe      the toolchain/Foundation report only
./Linux/build.sh --shell      interactive shell in the build image
./Linux/build.sh --rebuild    cold rebuild (~15-25 minutes)
```

在那里构建的东西都不会发布：它针对 GNUstep 编译十一个无头框架，运行这些框架移植后的测试以及一个工具链探针，并在旁边构建 `mad` CLI。全部六个动词都在镜像内运行；`export --format pdf` 会拒绝执行并给出原因（Linux PDF 写出器已推迟）。它发现的 GNUstep 差异列在 `Linux/README.md` 中，该文件还记录了检查点的运行情况及其使用的测试夹具（`CLI/Fixtures/`）。

针对这些构建所要求的平台守卫，iOS 回归门禁为：

```
xcodebuild test -workspace Reports.xcworkspace -scheme MADFoundation \
	-destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5'
```

（当安装了多个模拟器运行时、且最新的运行时没有该名称的设备时，需要 `OS=` 限定符。）

## 测试数据库（Docker）

实时测试套件和 CLI 测试夹具使用三个容器，每个容器都由其框架旁边的脚本创建和维护。三个脚本都是幂等的：`up` 在容器缺失时创建它，在它停止时启动它，而在固定镜像、端口和数据全部匹配时不予干预。

|  | MySQL | SQL Server | PostgreSQL |
|---|---|---|---|
| 容器 | `mad-mysql` | `mad-mssql` | `mad-postgres` |
| 镜像 | `mysql:8.4`（标签 + 摘要） | `mcr.microsoft.com/mssql/server:2022-latest`（标签 + 摘要） | `postgres:17-bookworm`（标签 + 摘要） |
| 主机端口 | `13306`（所有接口） | `1433`（所有接口） | `5432`（所有接口） |
| 登录 | `root` / `root` | `sa` / `Root1@Root2` | `mad` / `mad_test_pw` |
| 数据库 | `employees`（300,024 名员工） | `AdventureWorksLT2022`（295 个产品） | `chinook`（275 位艺术家，3,503 首曲目） |
| 卷 | `mad-mysql-test-data` | `mad-mssql-data` | `mad-postgres-test-data` |
| 脚本 | `MADMySQL/TestDatabase/mysql-test-db.sh` | `MADTdsClient/TestDatabase/sqlserver-test-db.sh` | `MADPostgres/TestDatabase/postgres-test-db.sh` |
| 固定项 | `db.conf`：镜像标签 + 摘要、数据集提交 + sha256 | `db.conf`：镜像标签 + 摘要、备份 URL + sha256 | `db.conf`：镜像标签 + 摘要、SQL URL + sha256 |

三个脚本接受相同的动词：

```
<the framework's script> up       # create/start; load the data if missing (default)
<the framework's script> wait     # block until the server answers
<the framework's script> verify   # re-check the pinned dataset
<the framework's script> status   # container, port, volume, what is loaded
<the framework's script> logs     # tail the server log
<the framework's script> down     # stop (the volume keeps the data)
<the framework's script> reset    # remove the container and its volume
```

iOS 的 scheme 在 Test action 的 pre-action 中调用 `up`，在 post-action 中调用 `down`，因此每个服务器只在其测试套件运行期间运行。在 Linux 测试套件或 CLI 的 `--verify --live` 之前，也要运行 `up`；三个容器都在所有接口上发布，因为 Linux 镜像和 CLI 测试夹具是通过名称（`mac`）而不是回环地址访问 Mac 的。

第一次 `up` 是慢的那次：MySQL 拉取约 600 MB 并导入约 168 MB 的 SQL（几分钟）；SQL Server 拉取约 1.5 GB、启动并还原 8 MB 的 AdventureWorks 备份（一两分钟）；PostgreSQL 拉取约 160 MB 并在几秒内加载 Chinook SQL。之后每次 `up` 只需几秒。如果容器或卷被删除，下一次 `up` 会根据 `db.conf` 中的固定信息重建它；无需手动创建任何东西。SQL Server 镜像仅支持 `linux/amd64`，因此在 Apple 芯片上 Docker Desktop 会模拟它并打印平台警告——这是预期行为，也是首次启动比 MySQL 慢的原因。

**MySQL 在 13306 上，而不是 3306。** Oracle MySQL 安装程序的 launchd 服务（`com.oracle.oss.mysql.mysqld`）可能在这台 Mac 上占用 3306，2026-10-17 就是如此。测试容器有意不动 3306；MADMySQL scheme 的 Test action 设置 `MAD_MYSQL_TEST_PORT=13306`，正是它把实时测试指向该容器。CLI 测试夹具已经存储了 `mac:13306`。

**`xcodebuild` 无法通过 shell 传递这些变量。** shell 环境变量不会到达测试进程，`SIMCTL_CHILD_` 前缀也不行——两者都是实测而非假设，因此 `MAD_MYSQL_TEST_PORT=13306 xcodebuild test …` 会静默地改为针对 3306 运行。scheme 的环境是唯一的入口；MADMySQL scheme 设置 `shouldUseLaunchSchemeArgsEnv = NO`，使其 Test action 的环境就是测试进程得到的环境。（同样的规则适用于 `MADTdsClient` 和 `MADPostgres` 套件中的 `MAD_TDS_TEST_*` 和 `MAD_PG_TEST_*` 变量；它们的 scheme 也设置了 `up`/`down`。）

要使用其他服务器，可以覆盖环境变量（`MAD_MYSQL_TEST_*`、`MAD_TDS_TEST_*`、`MAD_PG_TEST_*`），或修改测试文件中的默认值；脚本是零配置路径。当无法提供任何数据库时，实时测试会跳过而不是失败。

## Docker：什么在运行，什么会持久保留

只有三个测试服务器是容器。Linux 构建没有持久容器：`./Linux/build.sh` 每次测试运行都执行 `docker run --rm`，因此除了它构建的镜像之外，没有任何东西留存下来：

* `mad-linux-toolchain:1` —— 工具链缓存基础镜像（1.15 GB）；
* `mad-linux:phase-b` —— 构建/测试镜像（6.69 GB），其默认命令运行 ctest；
* `mad-cli:latest` —— CLI 运行时镜像（283 MB；见 `Linux/README.md`）。

因此 `docker ps -a` 应显示 `mad-mysql`、`mad-mssql` 和 `mad-postgres`（运行中或已停止），不应显示本项目的任何其他内容。`./Linux/build.sh --clean` 会删除三个 Linux 镜像；三个脚本的 `down`/`reset` 管理这些服务器。

## 常用命令

以下命令用于创建 iOS 的应用预览。

`ffmpeg -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 -i AppPreview-iPhone-6_3.mov -vf "scale=886:1920" -c:v libx264 -r 30 -c:a aac -shortest AppPreview-Final.mp4`

## 设置模拟器时间

`xcrun simctl status_bar booted override --time "9:41" `


## PrivacyInfo.xcprivacy 的理由说明

以下是它们为何正确的简要分析：

被拒绝的原因是 `BoringSSL`，这个库为你的数据库建立安全、加密的连接。为完成工作，它需要执行两项关键的安全任务：

1.  **生成随机数：** 为使加密足够强，该库需要生成真正的随机数。常见且安全的做法是以系统启动时间作为起点。
    * 这正是 **`NSPrivacyAccessedAPICategorySystemBootTime`** 搭配原因 **`35F9.1`** 的用途。Apple 的原因 `35F9.1` 具体是“为安全目的提供随机性”。

2.  **验证证书：** 为确保连接的是*真正的*数据库服务器而不是冒名者，该库必须检查服务器的安全证书。这项检查的一部分涉及查看文件的创建和修改日期。
    * 这正是 **`NSPrivacyAccessedAPICategoryFileTimestamp`** 搭配原因 **`C617.1`** 的用途。Apple 的原因 `C617.1` 是“访问元数据……以验证文件的完整性和安全性”。

简而言之，你是在告诉 Apple：“我的框架使用了访问启动时间和文件时间戳的 API，但这样做的原因是标准、正当的安全理由，是保证数据库连接安全所必需的。”

这些正是成千上万个其他应用（它们包含 `OpenSSL`、`BoringSSL` 或类似的加密库用于安全网络通信）所使用的理由。你的方向是对的。
