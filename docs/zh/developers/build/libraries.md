---
layout: default
title: "Compressor 静态库构建"
description: "第三方 C 库、它们的构建方式，以及 Xcode 如何访问它们。"
lang: zh-CN
---

# 静态库：Compressor 构建系统

本页介绍应用链接的第三方 C 库，以及生成它们的 `Compressor` 构建系统。

*撰写于原定日期；当前状态事实已于 2026-11-22 核实。*

本文档介绍应用链接的第三方静态库，以及生成它们的构建系统——描述的是实际构建方式，
而非计划。改造前的状态（两代重叠的脚本、已提交的二进制文件、按平台划分的
目录）压缩在文末附录中。

**长期约束：** 在构建系统完成所有组合的构建、且应用能针对新产物构建并
通过测试之前，`Compressor/library` 中所有早于本次改造的内容都不会被删除。
清理放在最后，每个提交只处理一项。

---

## 1. 系统是什么

一个声明式矩阵、一个驱动器、每个库一份配方、每次构建一份清单。

```
Compressor/
  matrix.conf                  # the single place version/source/platforms/deps live
  build.sh                     # the driver: ensure (default) / --all / --rebuild /
                               #   --verify / --platforms ios,simulator,macosx
  sqlite3.xcconfig             # the single place SQLite compile options live
  lib/common.sh                # download cache, per-arch compile helpers, lipo,
                               #   xcframework creation, manifest writer, lock
  lib/recipes/<lib>.sh         # one recipe per library (configure/cmake + install)
  lib/verify/<lib>.sh          # optional per-library artifact checks
  patches/                     # local modifications to upstream sources, captured
                               #   as diffs (none current; zint's 2.4.2 patch retired)
  media/<sha256>-<archive>     # content-addressed download cache (gitignored)
  src/  build/                 # extracted sources and build trees (gitignored)
  library/
    <lib>.xcframework/         # the single artifact Xcode links (gitignored)
    <lib>/include/             # the canonical header dir consumers name (gitignored)
    manifests/<lib>.json       # version, source hash, flags, slice SHAs (gitignored)
```

### 矩阵（`matrix.conf`）

面向行，可被 bash 解析：

```
lib        version  sha256  url   ios-archs  sim-archs  mac-archs  min-ios  min-mac  deps
```

`sha256` 是下载归档的哈希——每个库都锁定。`deps` 命名驱动器会优先构建的其他矩阵行。
库构建的其他一切都不在别处：每库标志位于配方中，并被回显到清单里，
因此“哪些标志构建了它？”仅凭清单就能回答。

### 驱动器（`build.sh`）

* `build.sh <lib>…`——确保每个库（先构建依赖）；当清单与矩阵行匹配且每个切片
  都存在时，是一次快速空操作。
* `--all`——矩阵中的每个库。
* `--rebuild`——强制重新构建**指定的**库；它们的依赖仍走正常的
  新鲜检查，因此迭代某份配方不会重建其依赖链。
* `--verify`——按矩阵 + 清单检查产物：版本与来源哈希、切片架构、头文件存在性、
  每个库内嵌的版本字符串，再加上 `lib/verify/` 中的每库检查。
* `--platforms ios,simulator,macosx`——限制构建哪些平台（默认：
  全部三个）。

构建由 `build/.ensure.lock.d` 上的锁串行化（一种带过期所有者恢复的 `mkdir` 锁
——macOS 上没有 `flock`），因为工作区构建期间多个 Xcode 目标可能
并行运行 ensure 阶段。

下载落在内容寻址的 `media/` 缓存中，因此锁定的来源只会下载一次，并在每次使用时
按哈希校验。首次构建需要网络访问；失败信息会说明这一点并指出具体的 tarball。

### 配方

每份配方把锁定的来源解压到 `build/<lib>/source`，按架构构建、
按平台 lipo，并调用 `finish_library`——它创建 xcframework、
安装规范 include 目录并写入清单。每个 xcframework 切片标识符只能对应一个库，
这是 `-create-xcframework` 的硬性约束，因此多组件库会合并：openssl 把 crypto+ssl 合并为 `libopenssl.a`，
freetds 把 ct+sybdb+tds 合并为 `libfreetds.a`，mariadb 则是单一
`libmariadbclient.a`（Connector/C 的 `libmariadb` 目标在
UNIX 上硬编码为共享库，因此配方构建 `mariadbclient` 静态目标）。切片由库的
Mach-O 加载命令推断（各平台的 `-m*-version-min` 标志），这也是为什么不需要
`-platform` 提示。

改动配方时值得了解的备注：

* **sqlite3** 在主机上生成 amalgamation，然后按切片编译，
  选项列表从 `sqlite3.xcconfig` 解析——该配方是这份列表的*唯一*
  消费者（MADSqlite3 目标曾是第二个，即 `BUGS.md` 中的隐患 H7）。这些选项锁定了
  `.maddb` 缓存格式（页面大小 8192、`DQS=0`、FTS5、STAT4、……）；应把改动视为格式决策。
* **mariadb** 按切片构建 `mariadbclient` 静态目标，
  使用 `WITH_SSL=OPENSSL` 链接各平台的 openssl 安装，并使用
  `WITH_EXTERNAL_ZLIB=ON` 链接 zlib 安装，把 `caching_sha2_password`
  和 `sha256_password` 认证插件静态编译进去，其余所有
  插件均停用（不随附插件 `.so`）。DEFAULT 安装布局把头文件嵌套在
  `include/mariadb` 下；配方将其展平，使 `mysql.h`
  能从规范 include 根解析，其交叉预设用一个基于运行的 cmake 探查（LibreSSL 检查）回答
  OpenSSL 的结果。
* **zint** 是原版 2.16.0，由 `lib/recipes/zint.sh` 用 cmake 构建
  （`ZINT_SHARED=OFF`、`ZINT_STATIC=ON`、`ZINT_FRONTEND=OFF`、`ZINT_USE_PNG=ON`，
  链接到配方自带的 libpng 和 zlib），产物为
  `library/zint.xcframework`。2.4.2 时代的直接编译及其本地
  补丁（`patches/zint-2.4.2-mad.patch`）已退役：该补丁回移植的
  `ZBarcode_Encode_and_Buffer` 在 2.16 中是上游 API，包装器的
  `BARCODE_*` 名称则作为别名保留。
* **freetds** 修改的是*已安装*的头文件，而非源码：每次安装后都会从
  `sybdb.h` 中注释掉 `typedef int BOOL;`，因为 Objective-C 已经
  typedef 了 `BOOL`——但库本身必须保留该 typedef，因为 dblib 的 C
  源码使用了它。
* **postgres** 只构建客户端接口（`src/common`、`src/port`、
  `src/interfaces/libpq`、`src/bin/pg_config` 和 `src/include`），针对
  各平台的 `openssl` 安装（`--with-ssl=openssl`，并关闭显式模块
  标志），然后把 `libpq.a`、`libpgcommon.a` 和 `libpgport.a` 合并为
  单一 `libpostgres.a` 以供 `postgres.xcframework` 使用。

### 清单（`library/manifests/<lib>.json`）

```json
{
  "library": "openssl", "version": "3.5.0",
  "source": { "url": "…", "sha256": "…" },
  "toolchain": { "xcode": "…", "clang": "…" },
  "headers": "ios",
  "flags": "configure: no-shared no-asm no-async; opt: -O3",
  "built": "…",
  "slices": { "ios": { "archs": "…", "sha256": "…" }, … }
}
```

`headers` 记录规范 include 目录采用了哪个平台生成的
头文件（freetds 按平台生成 `tds_sysdep_public.h`；ios 副本是
规范副本，正如旧布局所选）。

---

## 2. Xcode 如何消费这些库

每个消费目标都通过文件引用链接一个或多个 xcframework，在其头文件搜索路径中
指定规范的 `Compressor/library/<lib>/include`，并在其构建阶段最前面运行一个
**Ensure Libraries** shell 阶段：

```sh
set -euo pipefail
"${SRCROOT}/../Compressor/build.sh" --platforms ios,simulator <lib>
```

当清单是最新时，该阶段在毫秒内空操作，否则只构建缺失的部分；
每个带该阶段的目标都固定了 `ENABLE_USER_SCRIPT_SANDBOXING = NO`。平台被固定为
`ios,simulator`，因为目前没有目标为 macOS 构建——矩阵的 macOS 切片已为
UIKit 解耦落地时做好准备（参见 `ROADMAP.md` Track 2）。

| 目标 | 链接 | Ensure 阶段 |
|---|---|---|
| MADSqlite3 | `sqlite3.xcframework` | `sqlite3` |
| MAD | `libarchive.xcframework`、`bzip2.xcframework`、`zlib.xcframework` | `libarchive` |
| MADMySQL | `mariadb.xcframework`、`openssl.xcframework`、`zlib.xcframework` | `mariadb` |
| MADPostgres | `postgres.xcframework`、`openssl.xcframework` | `postgres` |
| MADTds | `freetds.xcframework`、`openssl.xcframework` | `freetds` |
| MADTdsClient | 没有来自 Compressor 的内容（tds 符号经由 MADTds 提供） | — |
| MADBarcodes | `libpng.xcframework`、`zlib.xcframework`、`zint.xcframework` | `zint` |
| MAD Designer 应用 | `openssl.xcframework` | `openssl` |

值得记住的头文件事实：静态库 xcframework **不会**可靠地
暴露其头文件，因此每个消费者都显式指定规范 include 目录
（头文件也会打包进 xcframework 以便存档完整）。`zint.h`、`sqlite3.h` 和 `libpq-fe.h`（及其伴随头文件）
是 Public 框架头文件，其文件引用指向规范
include 目录，因为公开的 MAD 头文件导入了 `<MADBarcodes/zint.h>`，
`MADSqlite3` 导出 `sqlite3.h`，
`MADPostgres` 导出 `libpq-fe.h`。

MAD Viewer 目标的遗留 `LIBRARY_SEARCH_PATHS` 列表和 Scrimpter（在工作区之外）
被刻意保持原样：查看器的链接失败是产品
决策（参见 `BUGS.md`），而非构建接线问题。

---

## 3. 首次运行、日常使用与版本升级

**全新检出上的首次运行**（或清空 `Compressor/library/` 之后）：在首次 Xcode 构建之前或
期间，先构建一次这些库：

```
Compressor/build.sh --all --platforms ios,simulator
```

下载需要网络访问，首次构建需要 30–90 分钟，
大部分时间花在较大的源码 tarball 上。
之后，Xcode 的 ensure 阶段便是空操作，正常构建得以继续。

**校验产物：**

```
Compressor/build.sh --verify --all --platforms ios,simulator
```

**升级某个库：** 编辑其 `matrix.conf` 行（版本、URL、新归档的 sha256），
然后 `Compressor/build.sh --rebuild <lib>`，并运行消费框架的测试
套件以及 `--verify`。每个提交只处理一个库。若新版本增加了 cmake 运行探查，
mariadb 预设会显式失败并指出它——要明确回答，绝不要猜测。

**zint/freetds/mariadb/postgres 配方带有按版本的知识**（补丁、
已安装头文件的编辑、探查答案、插件类型名、安装布局、
仅客户端子树列表）。版本升级时，这些就是需要重新检查的地方。

---

## 4. 校验命令

```sh
# slice inventory
for f in Compressor/library/*.xcframework/*/lib*.a; do lipo -archs "$f"; done

# version strings (each library embeds its matrix version)
strings Compressor/library/openssl.xcframework/*/libopenssl.a | grep -m1 "OpenSSL 3.5.0"

# sqlite correctness, against the BUILT framework (the H7 gate)
nm MADSqlite3.framework/MADSqlite3 | grep -c sqlite3Fts5Init     # present
strings MADSqlite3.framework/MADSqlite3 | grep -x 'DEFAULT_PAGE_SIZE=8192\|DQS=0'

# wiring cleanliness -- expect "" bases plus the MAD Viewer legacy list only
grep -rn 'LIBRARY_SEARCH_PATHS' --include='*.pbxproj' .

# the fresh-clone simulation (proves portability + on-demand building)
git archive HEAD | tar -x -C /tmp/fresh
cd /tmp/fresh
Compressor/build.sh --all --platforms ios,simulator     # bootstrap path (a)
xcodebuild build -workspace Reports.xcworkspace -scheme "MAD Designer" -destination …
Compressor/build.sh --verify --all --platforms ios,simulator
# path (b): wipe library/ xcframeworks and build in Xcode only -- the ensure
# phases rebuild everything
```

---

## 附录：改造前的状态（供参考）

2026-10-04 之前，这些库由两代重叠的工具构建——每库一个
`Compressor/build_*.sh` 脚本，以及一个 1,293 行的
`compressor.sh` 驱动器（无法运行：未定义变量导致 `set -e` 下 404 下载；
其声明的版本已过时多年）——而结果被**提交**：99 个 `.a` 文件（约 350 MB）、所有头文件，
以及 9.2 MB 的 `sqlite3.c` amalgamation 位于 `Compressor/library/`，
此外 MADBarcodes 内还有 53 个 vendored Zint 源码文件。Xcode 仅通过文件引用和
依赖 SDK 的搜索路径消费它们，这也是 macOS 始终无法接线的原因
（`PBXFileReference.path` 不依赖 SDK——`BUGS.md` 中的该条目
已由 xcframework 重新接线关闭）。旧脚本和已提交的目录树
在清理阶段移除，且只在新系统完成所有组合的构建、
应用能构建并针对新产物通过测试之后。

矩阵起步时的基线版本及其目标更新
记录在 `TASKS.md` §6。
