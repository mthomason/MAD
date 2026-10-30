---
layout: default
lang: zh-CN
---

# 静态库：Compressor 构建系统

本文档描述应用链接的第三方静态库，以及生成它们的构建系统——以实际构建为准，而非计划中的样子。改造前的状态（两代相互重叠的脚本、已提交的二进制文件、按平台划分的目录）压缩在末尾的附录中。

**长期约束：** 在新系统构建出每一种组合、应用能够针对新产物构建且其测试通过之前，`Compressor/library` 中早于本次改造的任何东西都不删除。清理放在最后，每项一个提交。

---

## 1. 系统是什么

一个声明式矩阵、一个驱动、每个库一个配方、每次构建一个清单。

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

面向行、可被 bash 解析：

```
lib        version  sha256  url   ios-archs  sim-archs  mac-archs  min-ios  min-mac  deps
```

`sha256` 是所下载归档的哈希——每个库都固定。`deps` 指定驱动先构建的其它矩阵行。关于库构建的信息不存放在别处：每个库的标志位于配方中，并被回显到清单里，因此“是哪些标志构建了这个库？”仅凭清单即可回答。

### 驱动（`build.sh`）

* `build.sh <lib>…`——确保每个库（先依赖）；当清单与矩阵行匹配且每个切片都存在时，快速空操作。
* `--all`——矩阵中的每个库。
* `--rebuild`——强制重建**指定的**库；它们的依赖仍进行常规的新鲜度检查，因此迭代一个配方不会重建其链条。
* `--verify`——依据矩阵和清单检查产物：版本与源码哈希、切片架构、头文件存在性、每个库内嵌的版本字符串，以及 `lib/verify/` 中的逐库检查。
* `--platforms ios,simulator,macosx`——限定构建哪些平台（默认：全部三个）。

构建通过 `build/.ensure.lock.d` 上的锁串行化（一种带过期持有者恢复的 `mkdir` 锁——macOS 上没有 `flock`），因为工作区构建期间可能有多个 Xcode target 并行运行 ensure 阶段。

下载内容进入按内容寻址的 `media/` 缓存，因此固定源码只下载一次，每次使用时都通过哈希验证。首次构建需要网络访问；失败消息会说明这一点并指出具体的压缩包。

### 配方

每个配方将固定源码解压到 `build/<lib>/source`，按架构构建，按平台 lipo，并调用 `finish_library`，后者创建 xcframework、安装规范 include 目录并写入清单。每个 xcframework 切片标识符一个库是 `-create-xcframework` 的硬性约束，因此多组件库会合并：openssl 把 crypto+ssl 合并为 `libopenssl.a`，freetds 把 ct+sybdb+tds 合并为 `libfreetds.a`，而 mariadb 是单个 `libmariadbclient.a`（Connector/C 的 `libmariadb` target 在 UNIX 上被硬编码为共享，因此配方构建 `mariadbclient` 静态 target）。切片从库的 Mach-O 加载命令（各平台的 `-m*-version-min` 标志）推断而来，这就是不需要 `-platform` 提示的原因。

在改动配方时值得了解的几点：

* **sqlite3** 在宿主机上生成 amalgamation，然后按切片编译，选项列表从 `sqlite3.xcconfig` 解析——该配方是该列表的*唯一*使用者（MADSqlite3 target 曾是第二个，这就是 `BUGS.md` 中的隐患 H7）。这些选项固定了 `.maddb` 缓存格式（page size 8192、`DQS=0`、FTS5、STAT4……）；把更改视为格式决策。
* **mariadb** 按切片构建 `mariadbclient` 静态 target，`WITH_SSL=OPENSSL` 针对各平台的 openssl 安装，`WITH_EXTERNAL_ZLIB=ON` 针对 zlib 安装，`caching_sha2_password` 和 `sha256_password` 认证插件静态编入，所有其他插件禁用（不发布任何插件 `.so`）。DEFAULT 安装布局把头文件嵌套在 `include/mariadb` 下；配方将其展平，使 `mysql.h` 能从规范 include 根解析，其 cross preset 用 OpenSSL 的结果回答唯一一个基于运行（run-based）的 cmake 探测（LibreSSL 检查）。
* **zint** 是由 `lib/recipes/zint.sh` 用 cmake 构建的原版 2.16.0（`ZINT_SHARED=OFF`、`ZINT_STATIC=ON`、`ZINT_FRONTEND=OFF`、`ZINT_USE_PNG=ON`，链接到配方自带的 libpng 和 zlib），输出到 `library/zint.xcframework`。2.4.2 时代的直接编译及其本地补丁（`patches/zint-2.4.2-mad.patch`）已退役：补丁回移的 `ZBarcode_Encode_and_Buffer` 在 2.16 中已是上游 API，包装层的 `BARCODE_*` 名称作为别名保留。
* **freetds** 修改的是*已安装*的头文件，而不是源码：每次安装后从 `sybdb.h` 中注释掉 `typedef int BOOL;`，因为 Objective-C 已经为 `BOOL` 定义了 typedef——但库本身必须保留该 typedef，因为 dblib 的 C 源码使用它。
* **postgres** 只构建客户端接口（`src/common`、`src/port`、`src/interfaces/libpq`、`src/bin/pg_config` 和 `src/include`），针对各平台的 `openssl` 安装（`--with-ssl=openssl` 且显式模块标志关闭），然后将 `libpq.a`、`libpgcommon.a` 和 `libpgport.a` 合并为单个 `libpostgres.a`，用于 `postgres.xcframework`。

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

`headers` 记录规范 include 目录采用了哪个平台生成的头文件（freetds 按平台生成 `tds_sysdep_public.h`；ios 副本是规范的那一份，与旧布局的选择一致）。

---

## 2. Xcode 如何使用这些库

每个使用方 target 通过文件引用链接一个或多个 xcframework，在其头文件搜索路径中指定规范的 `Compressor/library/<lib>/include`，并在其构建阶段里首先运行一个 **Ensure Libraries** shell 阶段：

```sh
set -euo pipefail
"${SRCROOT}/../Compressor/build.sh" --platforms ios,simulator <lib>
```

当清单是新鲜的时，该阶段在毫秒级内空操作；否则只构建缺失的部分；每个拥有该阶段的目标都固定了 `ENABLE_USER_SCRIPT_SANDBOXING = NO`。平台固定为 `ios,simulator`，因为目前没有 target 为 macOS 构建——矩阵中的 macOS 切片已为 UIKit 解耦落地时准备就绪（见 `ROADMAP.md` Track 2）。

| Target | 链接 | Ensure 阶段 |
|---|---|---|
| MADSqlite3 | `sqlite3.xcframework` | `sqlite3` |
| MAD | `libarchive.xcframework`, `bzip2.xcframework`, `zlib.xcframework` | `libarchive` |
| MADMySQL | `mariadb.xcframework`, `openssl.xcframework`, `zlib.xcframework` | `mariadb` |
| MADPostgres | `postgres.xcframework`, `openssl.xcframework` | `postgres` |
| MADTds | `freetds.xcframework`, `openssl.xcframework` | `freetds` |
| MADTdsClient | 不链接 Compressor 中的任何东西（tds 符号经由 MADTds 提供） | — |
| MADBarcodes | `libpng.xcframework`, `zlib.xcframework`, `zint.xcframework` | `zint` |
| MAD Designer 应用 | `openssl.xcframework` | `openssl` |

值得记住的头文件事实：静态库 xcframework **不会**可靠地暴露其头文件，因此每个使用方都显式指定规范 include 目录（头文件也会被打包进 xcframework 以求归档完整）。`zint.h`、`sqlite3.h` 和 `libpq-fe.h`（及其伴随头文件）是 Public 框架头文件，其文件引用指向规范 include 目录，因为 MAD 的公开头文件导入了 `<MADBarcodes/zint.h>`，`MADSqlite3` 导出 `sqlite3.h`，而 `MADPostgres` 导出 `libpq-fe.h`。

MAD Viewer target 遗留的 `LIBRARY_SEARCH_PATHS` 列表和 Scrimpter（在工作区之外）被有意保持原样：查看器的链接失败是产品决定（见 `BUGS.md`），而不是构建接线问题。

---

## 3. 首次运行、日常使用与版本升级

**在全新检出上首次运行**（或在清空 `Compressor/library/` 之后）：在首次 Xcode 构建之前或期间，先构建一次这些库：

```
Compressor/build.sh --all --platforms ios,simulator
```

下载需要网络访问，首次构建需要 30–90 分钟，其中大部分时间花在较大的源码压缩包上。此后，Xcode 的 ensure 阶段都是空操作，正常构建即可继续。

**验证产物：**

```
Compressor/build.sh --verify --all --platforms ios,simulator
```

**升级库：** 编辑其 `matrix.conf` 行（版本、URL、新归档的 sha256），然后运行 `Compressor/build.sh --rebuild <lib>`，并运行使用该库的框架的测试套件以及 `--verify`。每个提交只处理一个库。如果新版本增加了 cmake 运行探测（run-probe），mariadb 的 preset 会大声失败并指出它——要显式回答，绝不靠猜。

**zint/freetds/mariadb/postgres 的配方带有按版本区分的知识**（补丁、已安装头文件的修改、探测答案、插件类型名、安装布局、仅客户端子树列表）。版本升级时，这些是需要重新检查的地方。

---

## 4. 验证命令

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

在 2026-10-04 之前，这些库由两代相互重叠的工具构建——逐库的 `Compressor/build_*.sh` 脚本和一个 1,293 行的 `compressor.sh` 驱动（无法运行：未定义的变量在 `set -e` 下导致 404 下载；其声明的版本已过时多年）——结果被**提交**：`Compressor/library/` 下的 99 个 `.a` 文件（约 350 MB）、所有头文件、9.2 MB 的 `sqlite3.c` amalgamation，以及 MADBarcodes 内 53 个随源码附带的 Zint 源文件。Xcode 纯靠文件引用加 SDK 条件搜索路径来使用它们，这就是 macOS 始终无法接线的原因（`PBXFileReference.path` 不是 SDK 条件的——`BUGS.md` 中的该条目由 xcframework 重接线关闭）。旧脚本和被提交的目录树在清理阶段移除，而且只有在新系统构建出每一种组合、应用能够针对新产物构建且其测试通过之后才移除。

矩阵起始时的基线版本及其目标更新，记录在 `TASKS.md` §6 中。
