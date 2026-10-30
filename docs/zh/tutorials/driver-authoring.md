---
layout: default
lang: zh-CN
---

# 用一个下午写出 MAD 驱动

下文中的每个 file:line 引用都以 2026-10-25 为准。

## 驱动是什么

一个驱动是两个小类加一次注册调用：

1. 一个 `MADDatabase` 的子类（`MADAPI/Source/MADDatabase.h`——头文件说得很直白：“This class is built for subclassing”），它知道如何浏览数据源的架构并对其执行查询；
2. 一个连接类——一个符合 `MADDatabaseDriver` 协议
   （`MADAPI/Source/MADDatabaseDriverRegistry.h`）的 `MADDatabaseConnection` 子类，并在
   `+load` 中注册自身。

其余的一切——查询设计器的图、SQL 生成、行缓存、渲染管线、七种导出格式、CLI、Docker 镜像——都是驱动接入的共享机制。驱动满足的契约是*“以表的形式返回架构和数据行”*
（`docs/project/MAD_STRATEGY.md` §3.7），这就是为什么驱动可以面向任何能做得像表的东西：SQL 数据库、Web 服务、文件。

可以借鉴的三个服务器示例是 `MADPostgres`（6 个文件，
`MADPostgres/Source/`，基于 `libpq` 的 `MADDatabasePostgres` 子类）、
`MADMySQL`（18 个文件，`MADMySQL/Source/`，`MADDatabaseMySQL` 子类）和
`MADTdsClient`（基于 FreeTDS 的 SQL Server）。Sqlite3 是第四个随版本发布的
驱动（`MADSqlite3`），而基于文件的场景
（`+newDatabaseConnectionWithURL:`）在其连接类中展示。

## 第 1 步——类型常量

选择下一个空闲的 `MADDatabaseType` 值（`MADAPI/Source/MADDatabaseType.h`；
已发布的类型是 1–12），或扩展该枚举。这是文档存储的内容，因此它是一个格式常量：一旦存在使用你的类型的文档，
这个数字就永久固定。

## 第 2 步——继承 `MADDatabase`

抽象接缝位于 `MADAPI/Source/MADDatabaseProtocol.h`
（`MADDatabaseDataSource`）。必需的接口：

```objc
- (void)getTables:(void (^)(BOOL success, NSError *error,
                            NSArray <MADDatabaseTable *> *tables))completion;

- (NSArray <MADDatabaseTable *> *)getTablesFromConnection:(id)dbconn
                                                    error:(NSError **)error;
- (NSArray <MADDatabaseField *> *)fieldsForTable:(NSString *)tableName
                                     connection:(id)dbconn
                                          error:(NSError **)error;

- (id)connectWithConnection:(MADDatabaseConnection *)connection
                 credentals:(MADCredential *)credentals
            connectionError:(NSError **)error;

// The execution seam: the driver fills the table it is handed.  The
// destination is any <MADDataTableWriting>, which is what keeps the
// promise to "anything that returns a table" (MADDataTable.h).
- (BOOL)executeSQL:(NSString *)sql
         fieldKeys:(NSArray *)fieldKeys
      onConnection:(id)dbconn
  intoResultTable:(id <MADDataTableWriting>)dataTable
         withError:(NSError **)error;

- (BOOL)executeQuery:(MADQuery *)query withError:(NSError **)error;
- (BOOL)executeQuery:(MADQuery *)query
       withDataTable:(id <MADDataTableWriting>)dataTable
            andError:(NSError **)error;

// Optional: only file-backed drivers have nothing to dial.
- (void)closeConnection:(id)process;
```

架构浏览（`getTables…`、`fieldsForTable:…`）是应用的创建文档流程在把数据库架构导入新 `.mad` 时调用的；执行接缝是 `mad refresh` 和查看器调用的。
`MADOperationRefresh.m:134` 展示了刷新链发出的确切调用。

## 第 3 步——连接类与注册

```objc
@interface MyDriverConnection : MADDatabaseConnection <MADDatabaseDriver>
@end

@implementation MyDriverConnection
+ (void)load {
	[MADDatabaseDriverRegistry registerDriverClass: self];
}
+ (MADDatabaseType)databaseType { return MADDatabaseTypeMyDriver; }
+ (NSString *)Identifier { return @"MyDriver"; } // stored in documents
+ (instancetype)newDatabaseConnection:(NSObject <MADConnectionsPropertiesProtocol> *)credentials { … }
+ (Class)databaseClass { return [MyDatabase class]; }
+ (instancetype)newDatabaseConnectionWithHost:(NSString *)host
										 database:(NSString *)database
											 port:(NSInteger)port { … }
@end
```

`+Identifier` 是 `RptqDatabaseCredentals.driverID` 保存的内容，因此它是
文档格式常量——选择一个稳定的拼写（已发布的是“MySQL”“TDS”
“PostgreSQL”“Sqlite 3”）。第二个类声明已被占用的类型属于编程错误；注册表会断言失败。

## 第 4 步——链接它，让注册生效

注册是按进程、且**按链接**生效的：没有链接你的驱动的进程无法构建其数据库（构造函数会以清晰的消息断言失败，而不是等到后面因 nil 而失败）。

* **Apple：** 把你的框架链接进宿主（CLI 在 `CLI/build.sh` 的 `FRAMEWORKS` 列表中列出其驱动），或者在链接静态归档时使用 `-ObjC`——否则分类和 `+load` 方法会被静默丢弃。
* **Linux：** 把你的归档以 **whole-archive** 方式加入 `Linux/CMakeLists.txt` 中的 `mad` 目标，就像 `madsqlite3`、`madmysql`、`madtdsclient`
  和 `madpostgres` 那样：

  ```cmake
  target_link_libraries(mad PUBLIC
      "$<LINK_LIBRARY:WHOLE_ARCHIVE,my_driver>" …)
  ```

  这不是锦上添花——驱动的工作是通过分类（消息发送，没有符号）触达的，非 whole 静态链接会把它们丢掉：失败表现为第一次消息发送时崩溃，而不是链接器警告
  （`Linux/README.md`，“The compat shims” / “The drivers are registered”）。
  `cmake/MyDriverSources.cmake` 中的按驱动源文件列表遵循
  `MADFoundationSources.cmake` 的形状，每个被排除的文件都要命名并说明原因。

## 第 5 步——测试约定（这是本项目的风格；请照做）

在框架的测试目标中准备两套测试套件：

1. **离线测试**——架构结构、字段元数据、标识符引用、连接属性的往返。这些始终运行。
2. **实时测试**——与真实数据源通信；当数据源不可达时**跳过，绝不失败**。`MADMySQL/MADMySQLTests/MADMySQLLiveTests.m` 是模板：凭据默认指向一个有文档记录的本地服务器，每项都可通过环境变量覆盖
   （`MAD_MYSQL_TEST_HOST`、`MAD_MYSQL_TEST_PORT`、`MAD_MYSQL_TEST_USER`、
   `MAD_MYSQL_TEST_PASSWORD`、`MAD_MYSQL_TEST_SCHEMA`），每个实时测试都以 `XCTSkipIf(![self serverIsAvailable], …)` 开头。没有你的数据源的机器仍然会得到绿色的测试套件。注意 MySQL 文件中的注释：在 iOS 模拟器内使用 `127.0.0.1`，而不是 `localhost`。
3. **注册表测试**——`MADDatabaseDriverRegistryTests` 展示了形状：注册一个测试驱动，断言查找，断言重复类型抛出异常。你的驱动天然就能免费获得一个这样的测试。
4. 如果驱动属于无头构建，请把测试套件移植到 `Linux/Tests/`（参见 `cmake/` 和 `Linux/README.md` 的“Adding the next framework”）；否则在 PR 中说明为什么仅限 Apple。

## 第 6 步——诚实的注意事项：非 SQL 驱动今天能做什么、不能做什么

这是整套设想中唯一尚未完成的部分，而且是有意记录下来的（`docs/project/MAD_STRATEGY.md` §4.7）：**执行**层是驱动形状的——`executeSQL:…intoResultTable:…` 和
`MADDataTableWriting` 目标诚实地面对“任何返回表的东西”——但**编译**层是共享的：`MADQueryFull` 把查询图编译为每个驱动一份 SQL 文本。你的驱动收到的是 **SQL 文本**，而不是图（表、字段、谓词、分组）。

因此，今天的 REST/Web 服务驱动：

* **可以**浏览其架构（`getTables…`、`fieldsForTable:…`）、采用应用已有的连接表单、接收生成的 SQL 并将其转换为 API 调用、把数据行送入任何可写表，并走完整个刷新/渲染/导出路径——一个完全可用的驱动；
* **不能**原生接收查询图：要知道引擎在*请求什么*，它必须从交给它的字符串中把 SQL 文本解析回来。实际路线是：引擎自己的 SQL 解析器（为 SQL 输入功能而构建，`docs/project/MAD_SQL_ENTRY.md`）已经能解析受支持的子集——生成的 SQL 按构造就属于该子集——因此驱动可以复用它来恢复查询图；
* **正确的修复**是每个驱动一个编译钩子——项目早在 2012 年就为 Salesforce SFQL 勾勒过同样的形状——这样“安装一个驱动”就意味着“为任何东西安装一个驱动”，而不是“为我们碰巧匹配的 SQL 方言安装驱动”。它被排定为引擎契约工作（阶段 1），如果你想比编写驱动咬下更大一口，这确实是一个受欢迎的首次 PR。

还有一条诚实的说明，针对服务器部署而不是驱动：用户安装的驱动是**服务器进程中的任意代码**。注册表目前适用于受信任的第一方驱动；驱动市场在存在之前需要签名、沙箱或工作进程隔离，而这要设计进服务器的 API，而不是事后补上。

## 第 7 步——合入

通过驱动提案 issue 模板提出驱动，遵循 [CONTRIBUTING.md](https://github.com/mthomason/MAD/blob/master/CONTRIBUTING_zh.md) 中的测试先行规则（先写
失败的测试，再让代码走向绿色；对夹具做快照，而不是用新代码生成它们），如果驱动链接了新的第三方
库，请同时扩展
[docs/project/THIRD_PARTY_LICENSES.md](https://github.com/mthomason/MAD/blob/master/docs/zh/project/THIRD_PARTY_LICENSES.md)
以及相应的许可证义务——仓库非常重视那个文件。
