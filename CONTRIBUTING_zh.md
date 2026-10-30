[English](CONTRIBUTING.md) | **简体中文**

# 为 MAD 做贡献

感谢你的到来。MAD（Mobile Analytics Document，移动分析文档）是一个项目——包括 MAD Designer 和 MAD Viewer 应用、各个框架以及无头引擎——而新工作的接缝正是重点：一个新的数据库驱动、一个新的文档元素、一种新的导出格式。驱动编写教程
（[`docs/tutorials/driver-authoring.md`](docs/zh/tutorials/driver-authoring.md)）
会带你完成第一个；它是我们预期的首个贡献。

## 前置条件

* **装有 Xcode 的 macOS**——iOS 侧是一个包含十四个框架加应用的工作区，面向 iOS 15 及更高版本构建。这些框架使用 Objective-C。
* **Docker**——无头引擎的 Linux 构建：一个镜像，从源码构建
  Objective-C 工具链（libobjc2、libdispatch、GNUstep）和 C
  库，编译十一个无头框架，并运行它们的测试套件。
* 贡献不需要数据库服务器：当没有服务器可达时，MySQL、SQL Server 和
  PostgreSQL 的实时测试套件会跳过，而
  [`docs/project/DEVELOPER.md`](docs/zh/project/DEVELOPER.md) 记录了提供这些服务器的
  Docker 容器。

## 开始

1. Fork 仓库并克隆你的 fork。
2. 在改动任何东西之前先构建并测试，这样你才知道基线：

   ```sh
   # iOS: any framework's suite, against the iOS Simulator
   xcodebuild test -workspace Reports.xcworkspace -scheme MADFoundation \
       -destination 'platform=iOS Simulator,id=<device-udid>' \
       -derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-shared
   ```

   ```sh
   # Linux: the whole headless engine — 126 test executables, 1,303 tests
   ./Linux/build.sh
   ```

   [`docs/project/DEVELOPER.md`](docs/zh/project/DEVELOPER.md) 有完整的
   命令矩阵、框架所依赖的共享 DerivedData 路径，以及测试数据库的设置。
3. 挑点事情做。一个新的驱动、一个元素，或者一个标着
   “good first issue”的 issue。小一点是好事：这里的评审文化是精确。

## 测试先行规则

**先写失败的测试。** 这是项目的文化，不是建议：测试在代码存在之前就把行为固定下来，而修复就是让它变绿的那次改动。对于格式或数据工作，请对变更前的夹具做快照，而不是用新代码生成期望值——
夹具是行为曾经真实的见证。

循环按顺序进行：

1. 添加一个失败的测试，说明你打算实现的行为。
2. 运行它；看着它因为正确的原因失败。
3. 实现，然后让它变绿。
4. 运行整个测试套件——如果你改动了 Linux 构建会编译的任何东西，iOS *和* `./Linux/build.sh` 都要运行
   （参见 `Linux/cmake/*Sources.cmake`）。每个提交都必须让每个套件保持绿色。

Linux 套件把已知的平台差异记录为 `NEED` 行，而不是静默跳过——新的 `NEED` 必须带有原因，而既未修复也未记录的差异就是一次失败的改动。

## 风格

* 用制表符，不用空格。注释只在值得的地方出现，而不是到处都是。
* 有意不用的代码在声明处用 clang 的 `unused` 属性标记——未标记的未使用警告意味着该代码是死代码。
* 新文件带有单行头注释：`Copyright © 2012-2026 Michael
  Thomason. SPDX-License-Identifier: MIT`（源码用 `//`，脚本用 `#`）。
* [`docs/project/BUGS.md`](docs/zh/project/BUGS.md) 记录未解决的缺陷以及固定它们的测试；当你修复一个缺陷时，该条目会移到
  [`docs/project/BUGS_FIXED.md`](docs/zh/project/BUGS_FIXED.md)——没有被记录的修复等于没有发生。

## 开发者原创证书（DCO）

本项目要求 DCO 签署，而不是 CLA。每个提交都必须以以下内容结尾：

    Signed-off-by: Name <email>

（`git commit -s` 会添加它。）添加该行即表示你依据
[developercertificate.org](https://developercertificate.org) 证明：你编写了该改动，或有权在项目的许可证（MIT，参见 `LICENSE`）下贡献它。DCO 检查会在仓库发布到 GitHub 后对拉取请求运行。

## 拉取请求

* 每个 PR 只处理一件事。保持提交可审阅；项目历史是记录，不是草稿本。
* 填写 PR 模板——测试先行检查清单是给评审者看的，而“不适用”的答案在确实不适用时是可以的。
* 触碰到 Linux 构建的 PR 必须在其自己的分支上显示 `./Linux/build.sh` 为绿色。

## Issue

Bug 报告和驱动提案模板位于
[`.github/ISSUE_TEMPLATE/`](.github/ISSUE_TEMPLATE/)。安全问题请走
[`SECURITY.md`](SECURITY_zh.md) 中的私密路径，绝不要发到公开 issue。

## 帮助

在 issue 中提问（讨论板开放后也可以在那里提问）。维护者会回复每一个 issue；这个项目是单人努力，正在成长为社区，因此一个清晰、能展示你尝试过什么的提问会得到最快的答复。

## 支持

MAD 的代码以 MIT 许可证发布并且免费，贡献是最好的支持方式。如果这个项目为你的团队节省了时间，而你想给予更多，维护者接受 [GitHub Sponsors](https://github.com/sponsors/mthomason) 以及用于智能体驱动开发的 API 额度——每一分都会回到工作中（参见 [README](README_zh.md) 的“支持”一节）。
