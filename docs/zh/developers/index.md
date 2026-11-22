---
layout: default
title: 开发者
description: "嵌入 MAD 引擎、使用 mad CLI、阅读数据对象契约，并构建无头引擎。"
lang: zh-CN
---

# 开发者

MAD 是一个嵌入式关系型报表引擎：一份可移植的 `.mad` 文档、一个第一方 Objective-C 引擎，以及一个 `mad` 命令行工具——它在 Linux 与 Windows 上以无头方式运行同一个引擎。这些页面面向希望嵌入它、用脚本驱动它、添加数据源，或从源码自行构建的人。

## 从这里开始

* [`.mad` 格式规范](../README.html)——文档是什么、容器、存储，以及规范性的 `v1` 目标。
* [适用于 macOS 的 MAD Designer](../macos.html)——原生 `AppKit` 应用。
* [适用于 Windows 的 MAD Designer](../windows.html)——原生 WPF 应用。
* [愿景](../vision.html)——将报表作为可组合的数据源。

## 引擎与 CLI

* [`mad` 命令行工具](cli.html)——无需界面即可打开、检查、查询、刷新和导出一份文档。
* [数据对象](data-object.html)——把报表的定义、架构和结果集作为同一个契约。
* [多源报表](multi-source.html)——把报表当作表，以及为任何返回表的来源提供驱动。
* [将 SQL 粘贴到查询设计器](sql-entry.html)——支持的子集、解析器和应用路径。

## 架构

* [MADDataTable 架构](architecture/data-table.html)——横跨各框架的数据表类簇。
* [MADModel 层](architecture/model-layer.html)——基于 `Rptq` 实体的文档读模型。
* [MADArrayCaching](architecture/array-caching.html)——渲染缓存的磁盘支撑数组。

## 构建与测试

* [在 Linux 上构建引擎](build/linux.html)——Docker 构建与十二个无头框架。
* [在 Windows 上构建引擎](build/windows.html)——锁定版本的 Clang 与 GNUstep 工具链。
* [可移植性与原生 macOS 应用](build/macos.html)——框架审计与 AppKit 架构。
* [Compressor 静态库构建](build/libraries.html)——第三方 C 库以及 Xcode 如何访问它们。
* [无头 PDF 写出器](build/pdf.html)——Cairo、FreeType 与确定性导出。

## 卫星仓库与源码

* [卫星仓库](satellites.html)——`mad-action` 与容器镜像如何从本仓库发布。
* [源码](https://github.com/mthomason/MAD)——仓库、议题，以及[贡献指南](https://github.com/mthomason/MAD/blob/master/CONTRIBUTING.md)。
