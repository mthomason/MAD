---
layout: default
lang: zh-CN
---

# 第三方软件：使用与许可证合规

本文档记录 _MAD Designer_ 中的每一个第三方组件——以及已发布的 `mad` 容器镜像（§9）中的组件——记录它们各自如何进入交付的 App 或镜像，以及其许可证有何要求。它是项目的合规登记册：当某个库被新增、移除或升级版本时，这里的条目也随之改变。处理以下各项发现的整改计划是 `LICENSE_COMPLIANCE_PLAN.md`。

**这是一次工程层面的合规审查，不是法律意见。** 以下结论遵循每份许可证的文本，以及其管理者（FSF、Apache Foundation、Oracle）发布的标准解释。标记为**未解决**的条目需要一份书面授权，或所有者的决定。

范围：`Compressor` 的库矩阵（`Compressor/matrix.conf`），以及提交到 git 树中的第三方源码。它不覆盖 Apple SDK 框架，这些框架不附带再分发义务。

---

## 1. 发现摘要

**对“是否有任何东西必须被排除或移除？”的回答——有，一项，可能还有另外三项。**

| # | 组件 | 许可证 | 结论 |
|---|---|---|---|
| 1 | ~~**mysqlclient 8.4.10**~~ | ~~GPL-2.0-only + Universal FOSS Exception~~ | **已于 2026-10-24 移除——由 MariaDB Connector/C（见下文）替代；GPLv2 已从产品中消失。** |
| 1b | **MariaDB Connector/C 3.4.11** | LGPL-2.0-or-later，**选定 LGPL-3.0** | 允许；由与 FreeTDS 相同的重新链接机制覆盖（见 §3.3 和 `ThirdParty/Licenses/README.md`）。 |
| 2 | ~~**Karl Kraft MySQL connector**~~ | ~~无——“All rights reserved”~~ | **已于 2026-10-24 解决——随 MariaDB 替换一并改写为第一方代码。** |
| 3 | **NSOperation+CompletionBlock**（原为 `NSOperation+Advanced`） | ~~无——“All rights reserved”~~ | **已于 2026-10-24 解决——以第一方名称改写为第一方代码。** |
| 4 | **NSData+AES256** | ~~未知——pastie 代码片段~~ | **已于 2026-10-24 解决——改写为第一方代码，格式由黄金测试向量钉住。** |
| 5 | FreeTDS 1.4.27 | LGPL-2.0-or-later，**选定 LGPL-3.0** | 允许；**声明、标记过的头文件、LGPL 文本和书面重新链接要约已于 2026-10-24 落地**（工具包脚本推迟到 MariaDB 提示词处理）。 |
| 6 | OpenSSL 3.5.9 | Apache-2.0 | 允许；**必须随附许可证文本**。 |
| 7 | libarchive 3.8.9 | BSD-2-Clause | 允许；**必须随附声明**。 |
| 8 | zint 2.16.0（后端） | BSD-3-Clause | 允许；**必须随附声明**。 |
| 9 | bzip2 1.0.8 | bzip2（类 BSD） | 允许；建议附声明。 |
| 10 | libpng 1.6.59 | PNG Reference Library v2 | 允许；建议附声明。 |
| 11 | zlib 1.3.2 | Zlib | 允许；欢迎致谢。 |
| 12 | SQLite 3.53.3 | 公有领域 | 无义务。 |
| 12b | PostgreSQL `libpq` 17.11 | PostgreSQL License（宽松型） | 允许；**必须随附版权声明与免责声明**（`ThirdParty/Licenses/postgres-LICENSE.txt`）。 |
| 13 | asn1c 运行时 | BSD | 允许；必须随附声明。 |
| 14 | pngquant `rwpng` | BSD-2-Clause | 允许；必须随附声明。 |
| 15 | miniz | 公有领域（Unlicense） | 无义务。头文件已于 2026-10-04 更正。 |
| 16 | NSData+Base64（Matt Gallagher） | 宽松型，已保留声明 | 没问题。 |
| 17 | 字体 | 混合 | **OFL 文本和 Larabie 的 readme 已于 2026-10-24 提交；ClickBits/InfoBits 是商业字体，不得进入应用包和任何公开镜像。** |

**对“是否必须把其中一些编译为框架而不是 `.a`？”的回答——不。**

* 对于 **GPL** 库，链接方式无关紧要。动态链接并不能治愈 GPL 的 copyleft；只有商业许可证或移除才能做到。把 `libmysqlclient` 构建为 `.framework` 而不是 `.a` 不会改变任何事。
* 对于 **LGPL** 库，共享库*确实*是通往 §6(b) 的教科书式路径——但在 iOS 上，用户无法替换已签名应用包内的库，因此动态框架也不能干净地履行该义务。在 iOS 上行得通的路径是 §6(a)：声明加上重新链接要约。见 §3.3。
* 对于**宽松型**许可证的库，链接方式无关紧要；只有声明才重要。

已发布的容器镜像（`ghcr.io/mthomason/mad`）是第二个分发面，有自己的组件——GNUstep Base、从源码构建的运行时，以及上面那些同样的 C 库，它们被静态链接进 `mad` 二进制文件。它登记在 §9。

---

## 2. 第三方代码如何进入 App

链接模型决定了哪些义务会附加，因此值得统一说明一次。

* `Compressor/` 把十个库构建为 xcframework 内的**静态 `.a`** 归档。来自 `Compressor/` 的任何东西都不会被嵌入或复制进应用包。
* 每个 `.a` 都被链接进一个**第一方的动态 `MAD*.framework`**：MAD（libarchive、bzip2、zlib）、MADBarcodes（libpng、zlib、zint）、MADMySQL（mariadb、openssl、zlib）、MADPostgres（postgres、openssl）、MADSqlite3（sqlite3）、MADTds（freetds、openssl）。
* App 嵌入并对 13 个 `MAD*.framework` 包进行代码签名。**没有任何第三方 dylib 随产品交付。** 运行时 App 只链接 Apple 库（`libc++`、`libxml2`、`liblzma`、`libiconv`、`libobjc`、`libSystem`）。
* 后果：上述每一个第三方库都**被静态链接进我们分发的二进制文件**。**2026-10-28 已解决（计划 C2、C3）：**“关于”屏幕（`MADDesigner/Source/MADAboutTableViewController.m`）会推入一个 `Acknowledgements` 视图控制器（`MADAcknowledgementsViewController`），它渲染组件声明以及打包在 `ThirdParty/Licenses/`（应用包内为 `Licenses/`）中的完整许可证文本。

---

## 3. Compressor 库

版本来自 `Compressor/matrix.conf`；许可证文本读取自 `Compressor/build/<lib>/source/` 下下载的源码。

### 3.1 宽松许可证的多数派

| 库 | 版本 | 许可证 | 它对纯二进制分发有何要求 |
|---|---|---|---|
| sqlite3 | 3.53.3 | 公有领域 | 无。（`LICENSE.md`：没有任何非公有领域的构建脚本触及 `sqlite3.c`。） |
| zlib | 1.3.2 | Zlib | 不得歪曲来源。欢迎致谢，但不作要求。 |
| bzip2 | 1.0.8 | bzip2 license | 不得歪曲来源；不得使用作者姓名作背书。欢迎致谢。 |
| libpng | 1.6.59 | PNG Reference Library v2 | 不得移除或改动版权声明；不得歪曲来源。 |
| libarchive | 3.8.9 | BSD-2-Clause | **必须在文档或材料中复现版权声明、条件和免责声明。** |
| zint（后端） | 2.16.0 | BSD-3-Clause | **必须在文档或材料中复现版权声明、条件和免责声明。** |
| openssl | 3.5.9 | Apache-2.0 | **必须向接收者提供一份许可证副本**（§4(a)）；保留声明。不随附 `NOTICE` 文件。 |
| postgres（`libpq`） | 17.11 | PostgreSQL License | **版权声明、许可声明和免责声明必须出现在所有副本中。** |

关于 zint 的说明：上游 `LICENSE` 说，*后端*（我们构建的全部就是后端——`ZINT_FRONTEND=OFF`）是 BSD-3-Clause，而 Qt 前端仍为 GPL。只有 BSD 后端被编译，因此不交付任何 GPL 代码。`zint.h` 和后端源码在自己的头文件中确认了 BSD-3-Clause。

在交付的 `libmysqlclient.a` *内部*还打包了另外三个宽松型组件（见 §3.2）——**zstd**（BSD-3-Clause）、**zlib**（Zlib）和 **libdivsufsort**（MIT）。它们都不改变分析结论；整个归档由 Oracle 的 GPLv2 管辖。

### 3.2 libmysqlclient——阻塞项（历史记录，已于 2026-10-24 移除）

**已于 2026-10-24 移除。** D1 由所有者决定：MariaDB Connector/C 是替代品，替换已落地（Compressor 配方、框架链接、Linux 镜像构建，以及在同一轮中改写为第一方代码的 Karl Kraft 层），mysqlclient 的矩阵行和配方均已删除。下面的分析保留下来，作为它为何必须离开的记录。

**许可证。** `Compressor/build/mysqlclient/source/src/LICENSE` 声明该版本是“under version 2 of the GNU General Public License (GPLv2)”，并称 Oracle“elects to use only the General Public License version 2 (GPLv2) at this time”——即 **GPL-2.0-only**，而不是“or later”。同一文件授予了与另行授权软件链接的附加许可（正是这一点使 OpenSSL 3 依赖成为允许的），并把 C 客户端库置于 **Universal FOSS Exception, version 1.0** 之下。

**为什么 FOSS 例外帮不上忙。** Universal FOSS Exception 只授予这样的权利：将 MySQL 与那些本身“distributed with complete corresponding source under a license that is OSI-approved and/or categorized by the FSF as free”（“Other FOSS”）的软件一起分发。它的结尾写道：*“Nothing in this additional permission ... grants any additional permission of any kind for use or distribution of the Software in conjunction with software other than Other FOSS.”*

_MAD Designer_ 当时采用 `LICENSE.md`：“Copyright © Michael Thomason 2025. All rights reserved.”它不属于 Other FOSS，因此**没有任何例外适用**：在链接了 `libmysqlclient` 的情况下分发本应用，意味着 GPLv2 的 copyleft 覆盖了整个作品，而应用的源码将不得不在 GPLv2 下发布。把该库构建为动态框架并不能改变这一点。

**2026-10-24 因开源发布而改变：** 仓库现在按 MIT 许可证发布（见 `LICENSE`），这是 OSI 认可的许可证。为 MariaDB 决策记录在案（发布计划的 Prompt 2）：作为 MIT 软件，_MAD Designer_ 现在可以说落入了 Universal FOSS Exception 的“Other FOSS”定义，这会改变上述分析。这留给所有者权衡；MariaDB 替换仍然是计划的建议。

**选项，按优劣排序：**

1. **用 MariaDB Connector/C 替代。** 它是相同的 C API（`mysql_init`、`mysql_real_connect`、`mysql_stmt_*`、……，`MADMySQL` 调用的全部 27 个 API 都在其表面中），采用 **LGPL-2.1**，明确允许与专有应用一起分发。这把问题转化为与 FreeTDS 同类的问题，而后者我们无论如何都得解决（§3.3），并且完全移除了阻塞项。
2. **购买 Oracle 商业（OEM/ISV）许可证。** 这是在闭源产品中保留原版 `libmysqlclient` 的唯一方式。预算和条款是商业决策。
3. **放弃 MySQL 支持**，只交付 SQL Server。
4. 将 _MAD Designer_ 重新许可为 GPLv2，与商业产品在 App Store 的分发不兼容，此处仅为完整性而列出。

**无论选择哪个选项都值得清理：** App 目标直接链接 `openssl.xcframework`，但交付的 App 二进制文件没有定义任何 OpenSSL 符号——它被死代码剥离了。该链接可以直接移除。

### 3.3 FreeTDS——LGPL，允许但有条件

**许可证。** 交付库（`tds/`、`ctlib/`、`dblib/`、`replacements/`）中的每个源文件都带有相同的授权声明：

> This library is free software; you can redistribute it and/or modify it under
> the terms of the GNU Library General Public License as published by the Free
> Software Foundation; **either version 2 of the License, or (at your option) any
> later version.**

因此它是 **LGPL-2.0-or-later**，分发者可以选择依据哪个版本来合规。（`COPYING.txt` 中的 GPL 文本覆盖应用程序和服务器，而 `--disable-apps --disable-server` 将它们排除在构建之外；`replacements/` 中没有头文件的文件是宽松的公有领域/BSD 替代实现。）

**§6 义务。** LGPL 第 6 条（v2）/ 第 4 条（v3）允许将专有作品与该库链接，前提是接收者仍然能够修改该库并重新链接。具体而言，把 FreeTDS 静态地交付在 App 内需要满足以下全部条件：

* 一份醒目的声明，说明使用了 FreeTDS 且其受 LGPL 覆盖；
* 一份 LGPL 副本；
* FreeTDS 源码（可从上游获得——版本在 `matrix.conf` 中固定）；
* **一种重新链接的方式**——“Corresponding Application Code”：应用的目标文件和构建材料，向任何接收者提供，以便他们能把修改后的 FreeTDS 链接进一个可用的应用。

**在 iOS 上，动态框架解决不了这个问题。** §6(b) 的“合适的共享库机制”假设用户能在自己的系统上替换该库；在一个已签名、经 App Store 分发的应用包内部，他们做不到。上面 §6(a) 的路径才是适用于此处的路径，也是大多数交付 LGPL 代码的 iOS 发行方的做法。

**该选哪个版本，以及为何重要。** FreeTDS 链接 OpenSSL 3，而 OpenSSL 3 是 Apache-2.0。Apache-2.0 与 GPLv3/LGPLv3 兼容，但**不**与 GPLv2/LGPLv2 兼容。因此必须把 FreeTDS 取为 **LGPL-3.0**，OpenSSL 的组合才在许可证上兼容——“or later”的措辞正是让这一点可行的地方。这值得明确记录，因为这也意味着必须随附的是 LGPLv3 的声明和源码提供措辞。

**LGPL-3.0 的选择已记录。** 2026-10-24：本项目为 FreeTDS 选定 **LGPL-3.0**，理由是上文的兼容性。该选择也记录在 `ThirdParty/Licenses/README.md` 和 `NOTICE` 中；LGPL-3.0 文本提交于 `ThirdParty/Licenses/LGPL-3.0.txt`。**同一选择覆盖 MariaDB Connector/C（§3.4）**，它是 LGPL-2.0-or-later，并链接同一个 OpenSSL 3——一个选择，一套机制，两个库。

**两个具体缺陷，均已处理：**

1. ~~**交付的头文件被修改却没有声明。**~~ **2026-10-24 修复。** `sybdb.h` 中的 `typedef int BOOL;` 被配方（`Compressor/lib/recipes/freetds.sh`）注释掉了，而该被编辑的文件会随 `freetds.xcframework` 的全部三个切片以及规范 include 目录一起交付。配方现在会在被注释的那一行正上方插入一段关于该修改及其日期（2026-10-24）的醒目声明，因此每一份交付的修改后头文件都带有它。
2. ~~**重新链接材料尚不存在。**~~ **2026-10-24 部分处理。** 书面的重新链接要约已经存在（`ThirdParty/Licenses/README.md`：如何索取目标文件和构建材料、三年期声明，以及一句诚实的说明：iOS 接收者需要开发者账户）。`Compressor/relink-kit.sh` 脚本因所有者的决定而推迟（计划 §9.3）；它将同时服务 FreeTDS 和 MariaDB，属于 Prompt 2 的工作。

---

### 3.4 MariaDB Connector/C——LGPL，mysqlclient 的替代品

**许可证。** 每个源文件都带有相同的授权声明：“This library is free software; you can redistribute it and/or modify it under the terms of the GNU Library General Public License ... either version 2 of the License, or (at your option) any later version.”因此它是 **LGPL-2.0-or-later**，并且——与 FreeTDS 完全一样——本项目选定 **LGPL-3.0**，因为该连接器链接 OpenSSL 3（Apache-2.0），而 v3 条款才是兼容的条款。该选择记录在 §3.3、`NOTICE` 和 `ThirdParty/Licenses/README.md` 中；那里提交的 LGPL-3.0 文本同时服务两个库。

**交付内容。** `Compressor` 从固定的 GitHub release tarball 构建 3.4.11，输出到 `mariadb.xcframework`；静态归档是 `libmariadbclient.a`（Connector/C 的 `libmariadb` 目标在 UNIX 上被硬编码为共享库）。配方把 `caching_sha2_password` 和 `sha256_password` 认证插件编译进静态归档，并禁用其他所有插件，因此产品中根本不存在任何插件 `.so`。`MADMySQL` 链接 `mariadb.xcframework` 加上 `zlib.xcframework`（外部 zlib 构建会将 `compress2`/`uncompress` 留作链接依赖）。Linux 镜像把同一版本构建到 `/usr/local`（`Linux/libraries.conf`）。

**义务。** LGPL-3.0 的重新链接条件与 FreeTDS 完全一样地适用，并由同一套机制履行：`ThirdParty/Licenses/README.md` 中的书面要约点名了两个库，而重新链接工具包脚本（因所有者的决定而推迟，计划 §9.3）将同时服务两者。源码即固定的上游发布版；没有任何修改。

**这一节为何存在。** 这是 D1 的解决方案（所有者的决定，2026-10-24），也是 GPLv2 离开产品的途径（§3.2 是历史记录）。C API 之上的 `MADMySQL` 层在同一轮中被改写为第一方代码（§4.1）。

## 4. App 目标内提交的第三方源码

`DEVELOPER.md` 说“nothing third-party is in revision control”。这句话并不属实，值得纠正：以下组件已经提交，并会编译进交付的 App。

### 4.1 未解决——没有许可证授权

**Karl Kraft MySQL 连接器**——`MADMySQL/Source/`（30 个文件）。**2026-10-25 已解决：随 MariaDB 替换改写为第一方代码（计划 §3 A3；提交 `c46201465`）。** 28 个 `Mysql*` 文件被删除，替换为根据 MySQL C API 编写的 `MADMySQL*` 类，保留了类结构和面向 `MADMySQL` 的 API，删除了署名，行为在改动前后都由既有的 `MADMySQL` 测试套件钉住（122 个测试，包括针对 Docker MySQL 8.4 服务器的实况套件）。2026-10-24 的第一版（`68d885440`）保留了旧文件名，读起来像是一次头文件编辑；它已在历史中被替换。原状：头文件写着“Created by Karl Kraft on 5/21/08. Copyright 2008-2012 Karl Kraft. All rights reserved.” 仓库中任何地方都没有许可证文本，而上游项目（原 `svn.karlkraft.com/mysql_connector`，在他 2010–2011 年的博客文章中有描述）已无法访问；找不到任何镜像或许可证声明。在没有授权的情况下，“all rights reserved”意味着没有复制和分发它的许可。

**`NSOperation+Advanced.{h,m}`**——`MADFoundation/Source/`。**2026-10-24 已解决：改写为第一方代码并重命名为 `NSOperation+CompletionBlock.{h,m}`。** 两个方法（`addCompletionBlock:`、`addDependencies:`）依据 `NSOperation` 有文档的语义重新实现——`addCompletionBlock:` 忽略 nil，把新 block 接到已有 block 之后（各自运行一次），否则直接赋值；`addDependencies:` 做枚举——分类、文件、伞头导出和每一处 import 都随重命名更新。行为由 `MADFoundationTests/NSOperationAdvancedTests.m` 及其 Linux 移植版钉住，两者原样通过，另加一个 nil block 测试。原状：头文件写着“Copyright (c) 2015 Andrey K. All rights reserved.” 项目名称和日期与 GitHub 项目 `kas-kad/AdvancedNSOperations` 相符（创建于 2015-07-05，Objective-C，类名相同）——该项目没有 LICENSE 文件，报告 `license: null`。

**`NSData+AES256.{h,m}`**——`MADDesigner/Source/`。**2026-10-24 已解决：改写为第一方代码。** 密文格式首先由 `MADAppLogicTests.m` 中的黄金测试向量钉住，这些向量用 `openssl enc -aes-256-cbc` 独立计算，并对改写前的实现验证通过；随后函数体依据 AES-256-CBC 规范（CommonCrypto 有文档的 `CCCrypt` 用法、PKCS#7）重写，密钥派生保持不变（UTF-8，零填充至 32 字节，过长则拒绝），IV 处理也保持不变（随机 IV 前置到密文）。改写后黄金测试向量原样通过。原状：头文件署名 Michael Thomason，但带有“Found at http://pastie.org/426530#44”——一个没有作者、没有许可证的公开代码片段粘贴，现已移除。

### 4.2 宽松型，需附带声明

| 组件 | 位置 | 许可证 | 义务 |
|---|---|---|---|
| asn1c 运行时（Lev Walkin） | `MADDesigner/Source/ReceiptModuleAsn1c/`（约 50 个运行时文件加上生成的 receipt 代码） | BSD，依据 `asn_application.h`：“Redistribution and modifications are permitted subject to BSD license” | 在材料中包含版权声明、条件和免责声明。 |
| pngquant `rwpng` | `MADDesigner/Source/rwpng/`（2 个文件） | BSD-2-Clause，依据 `rwpng.c` | 在材料中包含版权声明、条件和免责声明。 |
| NSData+Base64（Matt Gallagher） | `MADDesigner/Source/`（2 个文件） | 自定义宽松型：源码再分发时必须保留声明；允许二进制使用 | 声明已保留——按现状交付没问题。 |
| miniz（Rich Geldreich） | `MAD/Source/miniz.c`、`miniz.h` | 公有领域 / Unlicense，在 `miniz.c` 末尾声明 | 无——**但见下文**。 |

**miniz 头文件**——**2026-10-04 已修复。** 两个文件都带有第一方头文件（“Created by Michael Thomason on 5/13/16. Copyright © 2017 Michael Thomason. All rights reserved.”），而 `miniz.h` 被直接改名为 `madmini.h`，完全没有任何署名。miniz 是 Rich Geldreich 的公有领域代码，因此两个头文件现在都注明了他，并记录了这次 vendoring；`miniz.c` 末尾的 Unlicense 声明从未被改动，所以从未涉及任何义务——那是对作者身份的错述，现已纠正。无需进一步处理。

### 4.3 字体

| 字体 | 状态 | 说明 |
|---|---|---|
| `FontAwesome.ttf` | **随产品交付**（`UIAppFonts`；用于 `MADAttributedStringCommon.m:31`、`MADToolboxStyleViewController.m:157`、`MADStoreViewController.m:151`） | 字体文件是 **SIL OFL 1.1**；OFL 要求版权声明和许可证文本随字体一起提供。Font Awesome 自己的条款不要求署名。OFL 文本目前不在仓库或应用包中——需要添加。 |
| `CarbonBlock.ttf` | **随产品交付**（作为资源复制） | 名称表：“© 1999 Ray Larabie. This font is freeware. Read attached text file for details.” Larabie 的免费软件条款就在那份随附文本文件中，而该文件**不在**仓库里。取回并保存它，让免费软件条件有据可查。 |
| `ClickBits*.otf`、`InfoBits*.otf`（13 个文件） | 位于 `StaticResources/Fonts/`，**不随产品交付** | 商业零售字体：名称表写着“Copyright (c) Ethan Dunham / Fonthead Design Inc. All rights reserved”，已注册商标，通过 Fontspring/Linotype 销售。它们不在应用包中，也未被项目引用。它们提交在一个**私有**仓库中，因此今天没有公开再分发任何东西。 |

*行动：如果 App 将来嵌入了任何 ClickBits/InfoBits 字体，必须先购买应用嵌入许可证。把它们挡在构建产品之外，并且如果仓库将来公开，要留意它们。*

---

## 5. 直言缺口

1. ~~App **完全没有随附任何第三方声明**，却在交付其许可证要求声明随附的代码（libarchive BSD-2、zint BSD-3、OpenSSL Apache-2.0、asn1c BSD、rwpng BSD-2、PostgreSQL libpq PostgreSQL License、FreeTDS LGPL、MariaDB Connector/C LGPL）。~~ **已于 2026-10-24（仓库）和 2026-10-28（App 内，计划 C2/C3）修复：** 仓库中有 `NOTICE` 和 `ThirdParty/Licenses/`，App 目标把 `ThirdParty/Licenses/` 打包为 `Licenses/`，而“关于”屏幕的 **Acknowledgements** 行会渲染这些声明和打包的许可证文本。
2. ~~**任何地方都没有提交许可证文本。**~~ **2026-10-24 已修复：** `ThirdParty/Licenses/` 收录了 §7 表格中的每一份文本。`Compressor` 有意不提交任何第三方内容，这对于*代码*是正确的默认做法——声明和许可证文本恰恰是必须分发的那部分，所以它们有了自己专门提交的家。
3. **FreeTDS 的重新链接义务**——头文件已标记，书面要约已于 2026-10-24 落地；重新链接工具包脚本因所有者的决定（计划 §9.3）推迟到 MariaDB 提示词，届时该机制同时服务两个库。
4. ~~按现有配置，**`libmysqlclient` 无法合法地随本产品交付**。~~ **2026-10-24 已解决：** D1 选择了 MariaDB Connector/C，替换已落地——mysqlclient 的矩阵行、配方和链接都已消失，GPLv2 已离开产品（§3.2 是历史记录）。
5. ~~**三个组件没有许可证授权。**~~ **三者均已于 2026-10-24 解决：** `NSOperation+CompletionBlock`（原 `NSOperation+Advanced`）、`NSData+AES256`，以及——随 MariaDB 替换——Karl Kraft 连接器，全部改写为第一方代码。
6. `DEVELOPER.md` 关于“版本控制中没有任何第三方内容”的说法不准确。过时的 `patches/zint-2.4.2-mad.patch` 引用已更正：`LIBRARIES.md`（§1）现在描述的是 zint 2.16.0 的配方，而 `Compressor/lib/recipes/zint.sh` 提到该补丁只是为了记录它已退役（该文件已在 `f7526ba04` 中删除）。

---

## 6. 必需的行动，按顺序

**P0——阻塞性，下一次提交之前决定**

1. ~~决定 `libmysqlclient` 问题：Oracle 商业许可证、MariaDB Connector/C（LGPL-2.1），还是放弃 MySQL。~~ **2026-10-24 已决定：MariaDB Connector/C，替换于同日落地。** 2026-10-24 的 MIT 重新许可记录在 §3.2 中，作为该决策权衡过的事实。
2. ~~解决三个无许可证组件。~~ **三者均已于 2026-10-24 解决：** `NSOperation+CompletionBlock`（原 `NSOperation+Advanced`）、`NSData+AES256`，以及 Karl Kraft 连接器（随 MariaDB 替换）均改写为第一方代码。
3. 从 App 目标中移除失效的 `openssl.xcframework` 链接。**未完成。**

**P1——合规，应当在交付之前完成**

4. ~~为 App 添加第三方声明界面（“关于 → 致谢”是自然的归宿），并提交它显示的许可证文本。草稿文本见 §7。~~ **2026-10-28 已完成（计划 C2、C3）：** `MADAboutTableViewController` 包含一个 **Acknowledgements** 行，会推入 `MADAcknowledgementsViewController`，而 `ThirdParty/Licenses/` 已打包进 `MAD Designer` 和 `MAD Viewer` 的 App 资源中。
5. FreeTDS：添加 LGPL 声明和许可证文本；标记被修改的 `sybdb.h`；选定 LGPL-3.0 并记录理由；撰写重新链接要约，并让构建能够产出相应的目标文件。**2026-10-24 基本完成：选择已记录，LGPL-3.0 文本已提交，配方现在会标记交付的头文件，书面的重新链接要约在 `ThirdParty/Licenses/README.md` 中。重新链接工具包脚本因所有者的决定（计划 §9.3）推迟到 MariaDB 提示词。**
6. ~~更正 miniz 版权头文件。~~ 2026-10-04 已完成。
7. 在 FontAwesome 旁添加 OFL 文本，在 CarbonBlock 旁添加 Larabie 的 readme。**2026-10-24 已完成——两份文本均提交在 `ThirdParty/Licenses/` 中，出处记录在那里。**

---

## 7. 声明文本草稿

以下是 App 需要随附的署名块。它的写法是可以原样放入致谢屏幕。**它对 `libmysqlclient` 是故意不完整的，** 因为该组件按现有配置不得交付——只有在获得商业许可证时才添加 Oracle 的声明，此时还要添加 GPLv2 文本以及相应源码的书面要约。

> ### 开源组件
>
> 本应用包含以下开源软件。
>
> **SQLite**——公有领域。<https://sqlite.org>
>
> **zlib**——© 1995–2026 Jean-loup Gailly and Mark Adler。按 zlib 许可证提供。
>
> **bzip2**——© 1996–2019 Julian R Seward。按 bzip2 许可证提供。
>
> **libpng**——© 1995–2026 The PNG Reference Library Authors，© 2018–2026 Cosmin Truta and contributors。按 PNG Reference Library License version 2 提供。
>
> **libarchive**——© 2003–2018 Tim Kientzle and contributors。按 BSD 2-Clause 许可证提供。
>
> **zint**——© 2008–2025 Robin Stuart and contributors。按 BSD 3-Clause 许可证提供。
>
> **OpenSSL**——© 1998–2026 The OpenSSL Project Authors。按 Apache License 2.0 提供。许可证副本附于下文。
>
> **PostgreSQL `libpq`**——部分 © 1996–2026 PostgreSQL Global Development Group；部分 © 1994 The Regents of the University of California。按 PostgreSQL Licence 提供。
>
> **MariaDB Connector/C**——© MariaDB Corporation Ab and contributors。本库是自由软件；你可以依据自由软件基金会发布的 GNU 宽通用公共许可证条款重新分发和/或修改它，许可证第 3 版，或（由你选择）任何更新的版本。许可证副本附于下文，完整相应源码可在 <https://mariadb.org> 获取。**要行使将本应用与修改后的 MariaDB Connector/C 重新链接的权利，请通过 mthomason@gmail.com 联系，以获取实现该目的所需的目标文件和构建材料（自本应用最后一次分发起至少三年内可用）。**
>
> **asn1c 运行时**——© 2004, 2006 Lev Walkin。在 BSD 许可证条件下允许再分发和修改。
>
> **pngquant `rwpng`**——© 1998–2000 Greg Roelofs，© 2009–2014 Kornel Lesiński。按 BSD 2-Clause 许可证提供。
>
> **NSData+Base64**——© 2009–2011 Matt Gallagher。按一份保留了版权声明的宽松许可证提供。
>
> **miniz**——Rich Geldreich。已释放到公有领域（Unlicense）。
>
> **FreeTDS**——© 1998–2015 Brian Bruns, Frediano Ziglio and contributors。本库是自由软件；你可以依据自由软件基金会发布的 GNU 宽通用公共许可证条款重新分发和/或修改它，许可证第 3 版，或（由你选择）任何更新的版本。安装的一个头文件（`sybdb.h`）按文件中的标记作了修改。许可证副本附于下文，FreeTDS 的完整相应源码可在 <https://www.freetds.org> 获取。**要行使将本应用与修改后的 FreeTDS 重新链接的权利，请通过 mthomason@gmail.com 联系，以获取实现该目的所需的目标文件和构建材料（自本应用最后一次分发起至少三年内可用）。**
>
> **Font Awesome**——© Dave Gandy。该字体按 SIL Open Font Licence 1.1 提供。
>
> **Carbon Block**——© 1999 Ray Larabie。免费软件，按随字体附带的条款使用。

此外，仓库中还包含上述每一组件的完整许可证文本，它们正是本次审查所读取的文本。**已于 2026-10-24 提交到 `ThirdParty/Licenses/`，** 每个组件一个文件；每个已提交文件的出处（包括 LGPL-3.0 的选择、OFL 的出处以及找回的 Larabie readme）记录在 `ThirdParty/Licenses/README.md` 中。各文本的读取路径如下：

| 组件 | 许可证文本来源（本次审查所读取） |
|---|---|
| libarchive | `Compressor/build/libarchive/source/src/COPYING` |
| zint | `Compressor/build/zint/source/src/LICENSE` |
| openssl | `Compressor/build/openssl/source/src/LICENSE.txt` |
| freetds | `Compressor/build/freetds/source/src/COPYING_LIB.txt` |
| libpng | `Compressor/build/libpng/source/src/LICENSE` |
| bzip2 | `Compressor/build/bzip2/source/src/LICENSE` |
| zlib | `Compressor/build/zlib/source/src/LICENSE` |
| sqlite3 | `Compressor/build/sqlite3/source/src/LICENSE.md` |
| postgres | `Compressor/build/postgres/source/src/COPYRIGHT` |
| asn1c | `MADDesigner/Source/ReceiptModuleAsn1c/asn_application.h` 中的 BSD 文本 |
| rwpng | `MADDesigner/Source/rwpng/rwpng.c` 中的 BSD 文本 |
| FontAwesome | SIL OFL 1.1 文本 |

这些路径位于被 gitignore 的构建树中，因此文本必须**复制到一个已提交的目录**（例如 `ThirdParty/Licenses/`）——这是“仓库中没有任何第三方内容”的唯一正当例外：我们不提交它们的代码，只提交我们有义务再分发的声明。

---

## 8. 附带发现

与许可证无关，是在追踪链接图时发现的——记录于此，以免遗失：

* **OpenSSL 把构建机器的路径烘进了交付的二进制文件。** 字符串 `/Users/michael/Desktop/Reports/Compressor/build/openssl/ios/arm64/install/ct_log_list.cnf` 出现在 `MAD Designer.app/MAD Designer` 中——这是 OpenSSL 配置的 `OPENSSLDIR`。它把一条本地绝对路径泄漏进发布产物，并指向一个设备上并不存在的证书透明度列表。OpenSSL 配方应当设置一个相对于安装位置或系统的 `OPENSSLDIR`。
* **MAD 链接了 Apple 的 `libsqlite3.tbd`**（`MAD.xcodeproj:29, :525`），与 `MADSqlite3` 链接的 Compressor 构建的 SQLite 并存。运行时只会加载静态副本，但一个进程中存在两份 SQLite 副本是一种潜在隐患，值得由缺陷登记册而非本文档来审视。

---

## 9. 已发布的容器镜像

于 2026-10-26 发布为 `ghcr.io/mthomason/mad`（`mad` CLI 的 Linux 运行时，由 `.github/workflows/publish-image.yml` 构建；`Linux/README.md` 的“The runtime image”一节）。分发该镜像会增加 App 不交付的组件，因此它们登记在这里，而不是 §1 的 App 表格中。

| 组件 | 版本 | 许可证 | 位置 | 要求 |
|---|---|---|---|---|
| GNUstep Base | 1.31.1 | LGPL-2.1-or-later | 镜像中的共享对象 | 重新链接要约 + 醒目声明；LGPL-3.0 的选择不适用于它（它链接的是 GnuTLS，不是 OpenSSL） |
| MariaDB Connector/C | 3.4.11 | LGPL-2.0-or-later，**选定 LGPL-3.0** | 静态链接进 `mad` | 与 §3.3/§3.4 相同的机制，扩展到镜像 |
| FreeTDS | 1.4.27 | LGPL-2.0-or-later，**选定 LGPL-3.0** | 静态链接进 `mad` | 相同的机制 |
| libobjc2（含 libBlocksRuntime） | 2.3 | MIT | 镜像中的共享对象 | 保留声明 |
| libdispatch | 6.1.3 | Apache-2.0 with the Swift runtime exception | 镜像中的共享对象 | 必须向接收者提供一份许可证副本 |
| gnustep-make | 2.9.3 | GPL-3.0-or-later | **构建工具——不在运行时镜像中** | 无；它不分发 |
| 各 C 库（§3.1） | 按固定版本 | 按登记 | 静态链接进 `mad` | 与 App 相同的宽松条款；镜像第二次传递它们 |
| apt 运行时包 | Ubuntu 24.04 | 发行版软件包 | 镜像中的共享对象 | 发行版自带的许可证文本，位于 `/usr/share/doc` |

两个静态 LGPL 库（MariaDB Connector/C 和 FreeTDS）的重新链接义务，以及覆盖 GNUstep Base 的要约，由 `ThirdParty/Licenses/README.md` 中的书面要约履行，该要约现在还点名了镜像：固定的源码公开在 `Linux/toolchain.conf` 和 `Linux/libraries.conf` 中，镜像用 `./Linux/build.sh --runtime` 从它们重新构建，且该要约自最后一次分发起至少三年内有效。`docs/project/TASKS.md` §10 曾带有“镜像发布会产生此义务”的标记；它在那里已关闭。

---

## 附录：重新运行本次审查

```sh
# 1. the library inventory and pinned versions
cat Compressor/matrix.conf

# 2. license texts for the Compressor libraries
find Compressor/build -maxdepth 4 \( -name 'COPYING*' -o -name 'LICENSE*' \) -print

# 3. what actually ships in the app binary
nm -g "…/MAD Designer.app/Frameworks/MADTds.framework/MADTds" | grep ' T _SSL_'

# 4. third-party source committed to the tree (the ones that are not gitignored)
git grep -l -e 'Copyright' -e 'Redistribution and use' -- '*.c' '*.h' '*.m' \
  ':!Compressor/build' ':!Compressor/library'

# 5. attribution surface (expected: none, until §6 is done)
grep -rn -i 'acknowledg\|third.party\|open source' MADDesigner/Source \
  MADDesigner/Resources --include='*.m' --include='*.plist'
```
