---
layout: default
lang: zh-CN
---

# 许可证合规计划

针对 `THIRD_PARTY_LICENSES.md` 中所列发现的补救计划。那份文档记录的是*现状*；本文档记录的是*我们如何处理它*，按顺序排列，并点明所依赖的决策。

**长期约束：** 当前配置下的应用程序无法合法分发，因为它将 `libmysqlclient`（GPLv2）静态链接进一个专有产品。在工作流 A 落地之前，不要提交构建版本。

---

## 1. 决定一切的问题：GPL、LGPL 与框架

> *“GPL 许可证能否在包裹进框架后使用？*
> *LGPL 要求的是这个吗？”*

**不能，LGPL 也不是这个意思。**

**包裹不改变 GPL 的效力范围。** 框架——无论静态还是动态——只是二进制文件的容器。版权法关注的是 GPL 代码与你的代码是否构成单一组合作品，而将它们链接进同一个进程就构成了，无论打包方式如何。xcframework 里的静态 `.a`、嵌入应用包的动态 `.framework`，以及散落的 `.dylib`，都是同一种行为：GPL 覆盖整个组合后的二进制文件，分发它即要求你以自己的代码按 GPL 授权。这正是 Oracle 的 FOSS 例外存在的原因——没有许可，GPL 库代码无论以何种链接方式都不能进入专有应用。

三种真正的出路是：代码本身是按兼容许可证发布的自由及开源软件（FOSS），你从版权持有人处获得商业许可证，或者你不分发该库。

**LGPL 同样不要求框架。** LGPL *本身*就是允许专有链接的许可——这就是它的全部目的，也是它与 GPL 的区别。代价是一项条件：接收者必须能够修改该库，并用修改后的版本重新链接你的应用。满足该条件有两种方式，框架只是其中之一：

* 接收者可以替换的**共享库**（在 macOS 桌面上，框架提供的就是这个）；或
* 你的应用的**目标文件和构建材料**，以便他们重新链接。

在 iOS 上，第一条路实际上行不通：应用包是签名的，购买者无法直接放入修改后的框架并运行。于是只剩第二条路，本计划对 FreeTDS 和 MariaDB 连接器都采用它——用同一套机制覆盖两者。见工作流 B。

---

## 2. 本计划依赖的决策

| # | 决策 | 负责人 | 阻塞 |
|---|---|---|---|
| D1 | MySQL 客户端：MariaDB Connector/C（推荐）、Oracle 商业许可证，或放弃 MySQL | 负责人——**2026-10-17 推迟：先交付 CLI** | 工作流 A |
| D2 | 如果这些字体最终要随附发布，确认 ClickBits 的购买层级涵盖*应用程序嵌入* | 负责人 | 工作流 E |

工作流 B、D 和 E 中的所有内容都独立于 D1，可以与其并行推进。

---

## 3. 工作流 A——替换 MySQL 客户端库

**目标：** `MADMySQL` 不再链接 GPL 代码，应用程序也不再链接。

### A0. 推荐 MariaDB Connector/C（决策 D1）

MariaDB Connector/C 是从最后一个采用 LGPL 的 MySQL 客户端重新实现的 MySQL C API，由 MariaDB Foundation 维护，采用 **LGPL-2.0-or-later**（其文件带有“either version 2 of the License, or (at your option) any later version”声明）。它在 API 层面可以直接替换：`MADMySQL` 调用的全部 27 个 `mysql_*` 函数都在其接口范围内，包括预处理语句系列（`mysql_stmt_init` … `mysql_stmt_fetch_column`）、`mysql_real_escape_string`、`mysql_use_result` 和 `CLIENT_FOUND_ROWS`。

在许可证层面，它*并非*直接替换——它仍然是 LGPL。但 LGPL 是有条件的许可，而 GPL 是一堵墙；且这个条件正是我们为 FreeTDS 必须满足的。这就是取舍：用一套合规机制取代一个阻断项。

固定使用 **3.4.11**（发布于 2026-09-29）。

### A1. 在 Compressor 中构建它

1. 在 `matrix.conf` 中添加一行 `mariadb`——版本 `3.4.11`，发布 tarball 取自 MariaDB Connector/C 的 GitHub releases，`deps: openssl`，平台和部署目标列与其他行相同。
2. 参照 `freetds.sh` 编写 `Compressor/lib/recipes/mariadb.sh`：
   * 按平台/架构执行 cmake，`-DWITH_SSL=OPENSSL` 指向我们按平台安装的 openssl（mysqlclient 和 freetds 的 recipe 已经这样做）；
   * 针对我们的 zlib 安装使用 `-DWITH_EXTERNAL_ZLIB=ON`，以免再携带第二个 zlib；
   * `-DWITH_CURL=OFF` 和 `-DWITH_UNIT_TESTS=OFF`——两者都不需要，而 curl 会引入我们本来没有的依赖；
   * 构建静态目标（`libmariadb.a`）并对其调用 `finish_library`，与其他 recipe 一样。
3. 添加 `lib/verify/mariadb.sh`，检查切片架构以及我们所依赖的认证插件已编译进去——`caching_sha2_password` 是关键的一个，因为 MySQL 8.4 不再默认启用 `mysql_native_password`。

这个 recipe 比 mysqlclient 的简单得多：没有宿主机工具的两阶段构建，没有 try_run 预设，没有捆绑的 boost。这整套装置都是因为 MySQL 的构建系统才存在的，随着它一起消失。

### A2. 更换链接

* `MADMySQL` 链接 `mariadb.xcframework`，而不是 `mysqlclient.xcframework` 和 `openssl.xcframework`（openssl 通过 mariadb 构建进入，因此直接链接可能不再必要——验证后若确实不需要则移除）。
* 头文件搜索路径移到 `Compressor/library/mariadb/include`。`#import <mysql.h>` 继续可用：Connector/C 在 include 根目录安装 `mysql.h`。
* 删除 mysqlclient 的 Ensure-Libraries 阶段调用。

### A3. 将 Objective-C 层重写为第一方代码

这里是 Karl Kraft 问题通过构造方式得到解决的地方。

`Objc_Mysql_iPhone_OSX/` 中的下载内容（现已删除）已经过检查：原始发行版**没有许可证文件，也没有授权声明**——只有“Copyright 2008–2010 Karl Kraft. All rights reserved.”版权头。在公共博客上发布并不会使作品进入公有领域；在没有授权的情况下，默认状态是保留所有权利。发行版中的 `notes.txt` 是空白的样板文件。

`MADMySQL/Source/` 中的代码与该原始版本相比已有实质性修改，而且封装层很薄——连接、取数、取字段、异常类，以及四个语句辅助函数。既然换成 MariaDB 无论如何都要改动这一层，不如重写而不是修补：

* 保留类结构和面向 `MADMySQL` 的 API，使其上层的任何东西都不变；
* 针对 MySQL C API 重新编写函数体——`mysql_real_connect` / `mysql_query` / `mysql_use_result` / `mysql_fetch_fields` / `mysql_stmt_*` 系列——这是一个小而文档完备的接口；
* 尽可能保留现有的 `<MADMySQL/...>` 公共头文件，以及 `MADDatabaseConnectionMySql` / `MADDataTypeMySQL` 胶水代码不动。

`MADDatabaseMySQL` 已经是第一方代码，保持不变。重写于 2026-10-25 落地，替换后的类改用 `MADMySQL` 前缀（`MADMySQLConnection`、`MADMySQLFetch`、`MADMySQLFetchField`、`MADMySQLServer`、异常类以及四个语句辅助函数）——这次重做取代了 2026-10-24 的第一版，那一版保留了旧的 `Mysql*` 名称，读起来像一次头文件编辑而不是重写。

### A4. 验证

实时测试套件是 `MADMySQL/MADMySQLTests/MADMySQLLiveTests.m`；在没有可达服务器时它会跳过，因此离线套件在任何情况下都保持绿色。让它指向 `127.0.0.1:3306` 上的本地 **MySQL 8.0.42**（Oracle 安装器的 launchd 服务）或 `13306` 上固定的 **`mad-mysql`** 容器——这也是该 scheme 的默认值，两者都记录在 `DEVELOPER.md` 中——并检查：

1. **认证。** 该服务器目前对 `root@localhost` 使用 `mysql_native_password`，走的是简单路径——*有风险*的路径是默认使用 `caching_sha2_password` 的现代服务器。在信任这次替换之前，先用配置了该插件的用户进行测试，因为一个无法对 MySQL 8.4 完成认证的连接器不能算替代品。
2. **结果类型。** `MADDataTypeMySQL` 将 `MYSQL_TYPE_*` 值映射为 MAD 类型。针对相同的架构重新运行类型覆盖测试，并比对差异。
3. **错误文本。** 任何对 `mysql_error()` 字符串做断言的代码都需要更新——两个库的措辞不同。
4. **TLS**，因为 MySQL 8 服务器越来越要求 TLS。
5. 对新产物运行 `Compressor/build.sh --verify --all`。

### A5. 淘汰 mysqlclient

只有在 A4 通过之后：从 `matrix.conf` 中删除 `mysqlclient` 行，删除 `lib/recipes/mysqlclient.sh`，让 prune 移除已构建的产物。这样就彻底从产品中去掉了 GPLv2。

**如果 D1 改为选择 Oracle 商业许可证**，工作流 A 就简化为“删除 A0–A1，保留 A2–A3”——Karl Kraft 重写仍然是需要的，因为商业许可证只回答了*库*的问题，而不是未授权的 *Objective-C* 问题。如果 D1 选择放弃 MySQL，A3 的重写就失去意义，`MADMySQL` 将从应用 target 和工作区中移除。

---

## 4. 工作流 B——FreeTDS 和 MariaDB 的 LGPL 合规

一套机制，两个库。LGPL §6（v2）/ §4（v3）允许专有链接，前提是接收者能够修改该库并重新链接。

**B1. 选择 LGPL-3.0，并记录原因。** 两个库都是“version 2 or later”，因此版本由我们选择。两者都链接 OpenSSL 3，而 OpenSSL 3 是 Apache-2.0，Apache-2.0 与 GPLv3/LGPLv3 兼容，但与 v2 条款不兼容。选择 v3 才能使这一组合在许可证上兼容。将这一选择记录在 `THIRD_PARTY_LICENSES.md` 中，以免将来的版本升级悄然推翻它。

**B2. 随附声明。** 显著声明、LGPL-3.0 文本副本，以及获取源代码位置的指引——放在应用的致谢屏幕中（工作流 C）。

**B3. 公布源代码位置。** 两个库都是未修改的上游构建，在 `matrix.conf` 中按哈希固定，因此源代码就是该版本的上游代码。唯一的例外是 FreeTDS 的*已安装头文件*修改——见 B4。

**B4. 标记修改过的 FreeTDS 头文件。** `sybdb.h` 中的 `typedef int BOOL;` 被 `Compressor/lib/recipes/freetds.sh` 注释掉了，而修改后的文件会随三个 xcframework 切片一起分发。LGPL §2 要求修改过的文件带有显著的修改声明及其日期。在 recipe 的修改位置添加该注释，使其进入每一份副本（并且使修改由做出它的 recipe 描述，紧邻其解释）。

**B5. 提供重新链接工具。** 这是实质性义务，也是唯一尚未构建的东西。以脚本加书面要约的形式交付：

* 一个 `Compressor/relink-kit.sh`（名称可自定），生成一个 tarball，包含应用的目标文件——`MAD Designer` 应用 target 和 `MAD*.framework` 二进制文件的目标文件——连同固定版本的 FreeTDS 和 MariaDB 源代码、Compressor 的 recipe，以及一份说明如何重新链接的简短 README；
* 致谢文本中的书面要约：如何请求它，以及声明该要约自应用最后一次分发起至少三年内有效。

在文档中如实说明，iOS 接收者还需要开发者账户才能安装重新链接的构建；义务是让重新链接*成为可能*，而这样做到了。

---

## 5. 工作流 C——声明与许可证文本

**C1. 许可证文本的提交存放处。** 创建 `ThirdParty/Licenses/`，存放 `THIRD_PARTY_LICENSES.md` §7 中每个组件的许可证文本，从固定版本的源代码复制。这是对“仓库中不放第三方内容”的刻意例外：我们不提交它们的代码，只提交我们有义务再分发的声明。添加一份简短的 `README` 说明该目录存在的原因，以免将来的清理将其删除。

**C2. 应用中的致谢界面。** **已于 2026-10-28 完成。** 关于屏幕（`MADDesigner/Source/MADAboutTableViewController.m`）带有一行 **致谢**，点击后推入 `MADAcknowledgementsViewController`，呈现组件声明和捆绑的许可证文本。

**C3. 捆绑许可证文本。** **已于 2026-10-28 完成。** `ThirdParty/Licenses/` 被复制到 `MAD Designer` 和 `MAD Viewer` 应用包中，作为 `Licenses/`，使许可证文本随二进制一起分发，这是 Apache-2.0 §4(a) 和 BSD 条件所要求的。

---

## 6. 工作流 D——两个未授权遗留项

两者都很小，而且都是重写而非谈判。

* ~~**`NSOperation+Advanced.{h,m}`**~~ **已于 2026-10-24 完成——重写为第一方代码并更名为 `NSOperation+CompletionBlock.{h,m}`。** 这两个方法依据 `NSOperation` 的文档语义重新实现，署名已删除。
* **`NSData+AES256.{h,m}`**（`MADDesigner/Source/`）——基于 CommonCrypto 的 AES-256-CBC。依据 Apple 文档中的 `CCCrypt` 用法重写；也就是三十来行成熟的代码。

两者都不阻塞其他任何工作。

---

## 7. 工作流 E——字体

* **FontAwesome** 会随附分发，并在三个文件中使用。在其旁边捆绑 **SIL OFL 1.1** 文本（`ThirdParty/Licenses/`），这是 OFL 对分发字体的要求。Font Awesome 自身的条款不要求署名，但许可证文本必须随字体一起分发。
* **CarbonBlock** 会随附分发。找回其 name 表所引用的“附加文本文件”——Larabie 的免费软件条款——并与字体放在一起，使免费软件条件有据可查，而不是靠推断。
* **ClickBits / InfoBits** 是商业字体（Fonthead Design Inc.），已购买——将购买记录与许可证文本放在一起。它们目前**不**随附分发，应继续排除在应用包之外，除非 D2 确认所购层级涵盖应用程序嵌入。如果仓库将来开源，也应将它们排除在任何公开镜像之外。

---

## 8. 排序

| 步骤 | 工作 | 依赖 |
|---|---|---|
| 1 | ~~修正 miniz 头文件~~ | **已完成 2026-10-04** |
| 2 | FreeTDS：修改过的头文件声明（B4）；选择 LGPL-3.0 并记录（B1） | — |
| 3 | `ThirdParty/Licenses/` 和许可证文本（C1） | — |
| 4 | MariaDB：recipe、matrix 行、验证脚本（A1） | D1 |
| 5 | MariaDB：更换链接（A2） | 步骤 4 |
| 6 | 重写 Objective-C 层（A3） | 步骤 4 |
| 7 | 针对本地服务器进行实时测试，包括 `caching_sha2_password`（A4） | 步骤 5、6 |
| 8 | 淘汰 mysqlclient（A5） | 步骤 7 |
| 9 | ~~致谢屏幕与捆绑文本（C2、C3）~~ | **已完成 2026-10-28** |
| 10 | 重新链接工具包与书面要约（B5） | 步骤 2、9 |
| 11 | ~~重写 `NSOperation+Advanced` 和 `NSData+AES256`（D）~~ | 已完成 2026-10-24 |
| 12 | 字体：OFL 文本、Larabie readme（E） | — |
| 13 | 卫生清理：`DEVELOPER.md` 的措辞、过时的 patch 引用 | — |

步骤 2、3、11 和 12 相互独立，可以任意顺序、在任何时间完成。步骤 4–8 是关键路径。假设 D1 选择 MariaDB，步骤 9 是应用达到可提交合规程度的节点。

**为什么步骤 2 在步骤 9 之前很重要：** LGPL 义务不能仅靠声明来满足——它需要声明*加上*重新链接工具。只落地声明而没有 B5，看起来合规，却缺少可执行的部分。

---

## 9. 本计划需要所有者决定的事项

1. **D1——MySQL 决策。** 推荐：MariaDB Connector/C。重写范围可控（一个类簇），构建比其所替代的更简单，并且从产品中去掉 GPL。替代方案是 Oracle 商业许可证；第三个选项是放弃 MySQL。
2. **D2——ClickBits 许可证层级**，仅当这些字体最终要分发时才需要。
3. **关于 B5 形式的决定**：重新链接工具包是本仓库中任何人都能运行的脚本，还是按请求提供它的书面要约。两者都满足许可证；前者工作量更大，也更站得住脚。
