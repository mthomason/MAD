---
layout: default
title: 适用于 Windows 的 MAD Designer
description: >-
  适用于 Windows（WPF）的原生关系型报表设计与查看器，支持 SQLite、MySQL、MariaDB、PostgreSQL 和 SQL Server——可视化查询画布、分带报表设计器、精确分页查看器，以及 HTML/CSV/JSON 导出，运行在与 Linux 和 macOS 相同的 headless 引擎之上。
image: /assets/mad-designer-icon-512.png
lang: zh-CN
---

# <a href="https://raw.githubusercontent.com/mthomason/MAD/master/StaticResources/Images/icons/document/Designer%20Icon@3x.png"><img src="../assets/mad-designer-icon-512.png" alt="适用于 Windows 的 MAD Designer 图标" width="48" height="48" style="vertical-align: middle; margin-right: 10px;" /></a>适用于 Windows 的 MAD Designer

**适用于 Windows 的 MAD Designer** 是一款基于 Windows Presentation Foundation（WPF）和 .NET 10 的原生桌面应用，用于创建、查询、排版、刷新和导出 Mobile Analytics Document（`.mad`）。它运行与 macOS 应用和 Linux 的 headless `mad` CLI 相同的自有 Objective-C 引擎（`mad.exe`），因此它写出的每个文档都与 iPad/iPhone 应用、`mad` CLI 和 GitHub Action [`mad-action`](https://github.com/mthomason/mad-action) 兼容。

> **此 0.7 版本未签名。** 它从公开源代码构建并发布，但不包含商业代码签名证书，因此首次启动时 Windows SmartScreen 会发出警告。这里没有任何隐藏内容：请审查此版本（见下文）、校验其 SHA-256 校验和，然后再运行。

## 下载与安装

* **直接下载：** [**MAD-Designer-Windows-0.7.zip**](https://github.com/mthomason/MAD/releases/download/v0.7.0/MAD-Designer-Windows-0.7.zip)
* **版本：** 应用 0.7 / 引擎 9.0 (r4433)。
* **系统要求：** Windows 10（1903 或更高版本）或 Windows 11，64 位。压缩包是自包含的，因此**无需安装 .NET 运行时**。查看器使用 Microsoft Edge WebView2 Evergreen 运行时，Windows 11 和当前版本的 Edge 已自带该运行时；在较旧的 Windows 10 镜像上，请安装 [Evergreen 运行时](https://developer.microsoft.com/microsoft-edge/webview2/)。

1. 下载 `.zip` 并将其解压到您选择的文件夹。请保持文件夹结构完整：应用、引擎和许可证彼此关联。
2. 运行解压后文件夹根目录中的 `Mad.Designer.Windows.exe`。
3. 首次启动时，Windows SmartScreen 可能提示*“Windows 已保护你的电脑”*。请依次选择**更多信息**和**仍要运行**——此版本按设计不签名（见下文）。

### 压缩包内容

```
MAD-Designer-Windows-0.7/
  Mad.Designer.Windows.exe   WPF 应用（自包含）
  ...                        应用自身的文件
  CLI/Fixtures/              London.portable.mad（示例报表）和
                             chinook.sqlite3（用于刷新的示例数据）
  Windows/Engine/build/mad.exe       headless 引擎
  Windows/Engine/build/*.dll         引擎的 GNUstep/ObjC/VC 运行时
  Windows/Engine/build/fonts/        PDF 导出使用的 Liberation 字体
  ThirdParty/Licenses/       所有第三方许可证和声明
  LICENSE, NOTICE, README-Windows.txt
```

**引擎所在位置：** `Windows/Engine/build/mad.exe`，与它的运行时 DLL 和 `fonts` 文件夹放在一起。应用通过源代码树所用的同一套仓库相对结构找到它；它不使用系统范围的 GNUstep 安装。请保持压缩包放置的文件夹位置不变。

### 验证下载

发布页面会公布压缩包的 SHA-256 校验和。下载后请进行比对：

```powershell
Get-FileHash .\MAD-Designer-Windows-0.7.zip -Algorithm SHA256
```

也可以逐个文件审查解压内容：压缩包只包含已发布的应用、由 `Windows/Engine/build.ps1` 构建的引擎、示例文档和许可证文本。`mad.exe` 就是 [Linux 指南](https://github.com/mthomason/MAD/blob/master/Linux/README.md)和 [Windows 构建记录](https://github.com/mthomason/MAD/blob/master/docs/project/MAD_WINDOWS.md)中记录的命令行引擎。

### 审查并为此版本自行签名

您可以直接运行 `mad.exe`，无需打开图形界面即可检查文档：

```powershell
.\Windows\Engine\build\mad.exe inspect .\CLI\Fixtures\London.portable.mad
```

如果希望 Windows 不再就*您自己的*副本发出警告，可以创建本地代码签名证书并自行签署可执行文件。这是本地信任决定——它不会让公开下载对其他人变得可信：

```powershell
$cert = New-SelfSignedCertificate -Type CodeSigningCert `
    -Subject "CN=MAD Designer (local review)" `
    -CertStoreLocation Cert:\CurrentUser\My
Set-AuthenticodeSignature -FilePath .\Mad.Designer.Windows.exe -Certificate $cert
```

要在此计算机上信任该证书，请将其导出，并使用 `certmgr.msc` 或 `Import-Certificate` 导入到**受信任的根证书颁发机构**；请仅对您自己创建和控制的证书这样做。

## 工作区

该应用与 macOS 应用具有相同的三个报表阶段：

* **MAD Query** —— 可视化查询画布（可拖动的表卡片、贝塞尔连接线、连接类型徽标、筛选和分组）以及直接 SQL 编辑器，二者都针对文档导入的架构工作。
* **MAD Designer** —— 分带布局工作区：页面与节迷你地图、报表带大纲、可搜索的查询字段、带对齐参考线和撤销/重做的可缩放标尺设计画布，以及用于内容、排版和几何的元素检查器。
* **MAD Viewer** —— 将查询刷新到本地物化表，选择页面大小（US Letter、US Legal、A4），在渲染的页面之间翻页，并导出。

查看器可导出 **HTML**、**HTML Flow**、**CSV**、**JSON**、**JSON 完整报表**和**纯文本**。PDF 导出已在引擎和 Windows 的 `mad` CLI 中提供，但尚未出现在此版本查看器的格式选择器中；如需 PDF，请直接调用引擎：

```powershell
.\Windows\Engine\build\mad.exe export .\CLI\Fixtures\London.portable.mad `
    --format pdf --out .\london.pdf
```

## 从源代码构建

应用使用 [`Windows/global.json`](https://github.com/mthomason/MAD/blob/master/Windows/global.json) 固定的 .NET SDK（10.0.404）构建：

```powershell
dotnet publish Windows\App\Mad.Designer.Windows\Mad.Designer.Windows.csproj `
    -c Release -r win-x64 --self-contained true
```

引擎是更难的一半。`Windows\Engine\build.ps1` 重现原生构建（Clang 20.1.8、固定的 Visual Studio MSVC 工具链、NASM、Strawberry Perl、Meson、Python，以及从七个固定修订版构建到 `C:\GNUstep` 的 GNUstep）。它必须在提升权限的 PowerShell 提示符中运行：

```powershell
pwsh -File .\Windows\Engine\build.ps1                 # 完整引导工具链并构建
pwsh -File .\Windows\Engine\build.ps1 -SkipToolchain  # 工具链已存在时重新构建
```

两个 .NET 测试套件针对已构建的引擎运行：

```powershell
dotnet test Windows\App\Mad.Designer.Windows.slnx
```

`Windows/Engine/build.ps1` 还会运行移植的原生套件；在引擎和应用构建完成后，`Windows/package.ps1` 会组装未签名的发布压缩包和 CI 使用的引擎资源。完整配方、Windows 专用的运行时修复、许可证义务和支持的操作系统矩阵记录在 [`docs/project/MAD_WINDOWS.md`](https://github.com/mthomason/MAD/blob/master/docs/project/MAD_WINDOWS.md) 中。

## 许可证

MAD 采用 MIT 许可证（见 [`LICENSE`](https://github.com/mthomason/MAD/blob/master/LICENSE)）；“MAD”、“MAD Designer”和“MAD Viewer”这些名称以及应用美术资源不在许可范围内（见 [`NOTICE`](https://github.com/mthomason/MAD/blob/master/NOTICE)）。引擎还附带 GNUstep 运行时（LGPL-2.1-or-later）和 C 库；每个组件、其许可证以及书面的重新链接要约都位于压缩包的 `ThirdParty/Licenses/` 文件夹和 [`docs/project/THIRD_PARTY_LICENSES.md`](https://github.com/mthomason/MAD/blob/master/docs/project/THIRD_PARTY_LICENSES.md) 中。
