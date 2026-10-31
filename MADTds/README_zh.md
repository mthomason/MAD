[English](README.md) | **简体中文** | [日本語](README_ja.md)

# MADTds 框架

**MADTds** 是一个面向 iOS 的框架，封装了 FreeTDS 库中的 `sybdb.h`。它简化了在 iOS 项目中集成和使用 Sybase 数据库的过程。该框架提供原生 Objective-C API，使在 iOS 应用中与 Sybase 数据库交互更加容易。

## 功能

- 通过 `MADTdsDb` 接口简化数据库操作。
- 内置 FreeTDS 库，为 Sybase 数据库功能提供可靠支持。
- 完全兼容 iOS，构建为可在 Xcode 环境中使用。
- 自定义构建脚本，用于管理 FreeTDS 依赖。

---

## 安装

### 前置条件

- Xcode 13 或更高版本
- iOS 12.0 或更高版本
- FreeTDS 预编译二进制文件（随框架捆绑）

### 步骤

1. 克隆或下载仓库。
2. 将 `MADTds.xcodeproj` 添加到你的 Xcode 工作区。
3. 在 **General > Frameworks, Libraries, and Embedded Content** 下将 `MADTds.framework` 链接到你的目标。
4. 将 `freetds/lib/include` 目录中所需的头文件添加到项目的搜索路径：
   - 转到目标的 **Build Settings**。
   - 将 **Header Search Paths** 设置为包含 `MADTds/freetds/lib/include`。

---

## 用法

### 导入框架

在要使用 MADTds 的文件中添加以下 import 语句：

```objc
#import <MADTds/MADTds.h>
#import <MADTds/MADTdsDb.h>
```

### 连接到数据库

以下示例展示如何连接 Sybase 数据库并执行查询：

```objc
MADTdsDb *db = [[MADTdsDb alloc] init];

// Configure the connection
db.server = @"your-server";
db.database = @"your-database";
db.username = @"your-username";
db.password = @"your-password";

if ([db connect]) {
    NSLog(@"Connected to database successfully.");
    NSArray *results = [db executeQuery:@"SELECT * FROM your_table"];
    NSLog(@"Query Results: %@", results);
} else {
    NSLog(@"Failed to connect to database.");
}
```

---

## 目录结构

```
MADTds.xcodeproj/              - Xcode project configuration
MADTds/                        - Core framework source
├── MADTds.h                   - Framework entry point
├── MADTdsDb.h                 - Database connection interface
├── MADTdsDb.m                 - Database connection implementation
madtds/MADTds.docc/            - Documentation for the framework
freetds/                       - Bundled FreeTDS library
├── lib/include/               - Header files for FreeTDS
├── lib/libct.a                - FreeTDS Client Library
├── lib/libsybdb.a             - FreeTDS Database Library
build_tds.sh                   - Script to manage FreeTDS builds
README.md                      - Project documentation
```

---

## 构建框架

1. 确保 `build_tds.sh` 脚本具有执行权限：
   ```bash
   chmod +x build_tds.sh
   ```
2. 运行该脚本以构建 FreeTDS 库：
   ```bash
   ./build_tds.sh
   ```
3. 在 Xcode 中打开 `MADTds.xcodeproj` 并构建框架。

---

## 文档

文档位于 `madtds/MADTds.docc` 文件夹中。要查看文档：
1. 在 Xcode 中打开 `MADTds.xcodeproj`。
2. 转到 **Product > Build Documentation** 菜单。

---

## 贡献

欢迎贡献！请按以下步骤操作：

1. Fork 仓库。
2. 为你的功能或缺陷修复创建新分支。
3. 提交更改并将其推送到你的 fork。
4. 提交描述更改的拉取请求。

---

## 许可证

本项目使用 **MIT License**。更多详情请参见 `LICENSE` 文件。

---

## 致谢

- [FreeTDS](http://www.freetds.org) 提供 Sybase 数据库库。
- iOS 开发者社区提供的灵感与支持。 

---
