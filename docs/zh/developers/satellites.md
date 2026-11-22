---
layout: default
title: "卫星仓库"
description: "`mad-action` 与容器镜像如何从本仓库发布。"
lang: zh-CN
---

# 卫星仓库

本页说明 `mad-action` GitHub Action 与容器镜像如何从本仓库发布，以及让卫星仓库保持最新的规则。

卫星是 `mthomason/MAD` 之外的一个仓库，它发布由 MAD 构建出的东西：目前是
`mad-action` GitHub Action，以及 GHCR 上的容器镜像。卫星是**发布目标，而不是分支**。
MAD 是事实来源；卫星由本仓库中的一个目录生成，跨越边界的只有已发布的产物
和 `satellites/<name>/` 下的文件。

这与镜像采用同一模型：`Linux/` 是来源，
`.github/workflows/publish-image.yml` 在每次推送到 `master` 时发布
`ghcr.io/mthomason/mad`，而引擎源码不会复制到任何别处。Action 用户能得到
新引擎，是因为镜像标签移动了，而不是因为卫星仓库收到了提交。

## 登记表

| 卫星 | 来源 | 发布者 | 引用 | 版本标签 |
|---|---|---|---|---|
| [mthomason/mad-action](https://github.com/mthomason/mad-action) | `satellites/mad-action/` | `.github/workflows/publish-mad-action.yml` | `ghcr.io/mthomason/mad:latest` | `v1`（移动；`satellites/mad-action/VERSION`） |
| `ghcr.io/mthomason/mad`（镜像，非仓库） | `Linux/` | `.github/workflows/publish-image.yml` | — | `latest`、`<short-sha>` |

`mthomason/mad-action` 是生成出来的。不要直接编辑它：改动应提交到本仓库的
`satellites/mad-action/`，经过正常的 PR 门槛，由发布工作流带过去。针对该 Action 的
议题和拉取请求应提交到 `mthomason/MAD`。

## 什么需要卫星提交

| MAD 中的改动 | 卫星更新 |
|---|---|
| 引擎或应用代码 | 无——下一次 master 推送会重新发布 `:latest`，Action 运行它 |
| 文档 | 无——Action 的 README 链接到 MAD |
| CLI 动词、标志、凭据输入或导出格式 | `satellites/mad-action/action.yml`，若输入映射或文档变化则还有 `README.md` |
| 镜像名称或标签策略 | `satellites/mad-action/action.yml`、`README.md`、各工作流 |
| `CLI/Fixtures/London.portable.mad` | 自动：发布工作流把它复制到 `fixtures/` |
| `LICENSE` 或 `NOTICE` | 自动：发布工作流复制两者 |
| `satellites/mad-action/**` | 自动：发布工作流同步该目录 |

当上述任一路径变化时，发布工作流会在 `master` 上运行，也可用 `workflow_dispatch`
手动运行。它针对已发布镜像测试来源，同步目标，以 `MAD release bot` 身份提交，
移动主标签，并让目标自身的测试工作流在推送后运行。卫星的测试
工作流还每天定时运行——这是一只金丝雀，用来捕捉那些即使包装器源码没变
却仍破坏包装器的引擎改动。

GitHub 会在仓库 60 天无活动后停用定时工作流。下一次同步提交会重新启用它；
在此期间，手动 `workflow_dispatch` 会立即运行测试。这是整套安排中唯一
可能静默失效而不报错的部分。

## 发布清单

**普通的源码改动。**

1. 在此处编辑 `satellites/mad-action/` 和/或 fixture。
2. 若接口有变，在本地运行包装器（`./Linux/build.sh
   --verify` 会构建 `mad-cli:latest`；可用
   `image: mad-cli:latest` 让 Action 指向它）。
3. 打开 PR。`Linux verification` 会在 PR 自己的运行时镜像上运行包装器
   （`linux.yml`），此外目标的 Action 测试也会运行。
4. 合并。`Publish mad-action` 测试并发布；随后目标仓库中卫星自身的测试运行
   必须通过。

**CLI 契约改动。** 同一个 PR 会更新 `action.yml` 的输入和 README。发布会移动 `v1`；
现有用户下次运行时会得到新的包装器。若该改动是破坏性的——某个输入被重命名或移除、
某个默认值发生了不兼容变化——在同一 PR 中把 `satellites/mad-action/VERSION` 提升为 `v2`，
并更新 README 中的 `@v1` 引用。工作流随后移动 `v2` 并把 `v1` 留在原处，这样
`mthomason/mad-action@v1` 用户在他们迁移前仍保留旧主版本。

**fixture 刷新。** 在 MAD 中重新生成 fixture
（`CLI/Fixtures/README.md`）；路径过滤器会复制它。不要编辑卫星仓库中的副本。

**部署密钥轮换。** 生成新的 ed25519 密钥，把公钥加入
`mthomason/mad-action` 作为写入部署密钥，把私钥设为 `mthomason/MAD` 上的
`MAD_ACTION_DEPLOY_KEY` 秘密，派发 `Publish
mad-action`，然后删除旧部署密钥。该密钥仅限那一个目标仓库，且只能写入。

## 一次性设置，已记录

目标仓库创建时为空且公开。GitHub 的默认分支是 `main`，首次发布会填充它；
工作流推送 `main`。它创建时没有 README 或许可证，因为首次同步会提供
两者。那里的议题和 wiki 已停用：README 把两者都导向 MAD。若它需要重建，
重复以下步骤：

1. `gh repo create mthomason/mad-action --public`
2. 停用议题和 wiki。
3. 添加一个标题为 `MAD publish workflow` 的写入部署密钥。
4. 把其私钥设为 `mthomason/MAD` 上的 `MAD_ACTION_DEPLOY_KEY` 秘密。
5. 派发 `Publish mad-action`。

卫星自身没有第三方依赖：它的主体是对已发布镜像的
`docker run`，其许可证文件就是 MAD 的
（`LICENSE`、`NOTICE`）。

## 添加另一个卫星

在此处创建 `satellites/<name>/`，按 `publish-mad-action.yml` 的形式添加
发布工作流，并在上方登记表添加一行。规则相同：MAD 是事实来源，卫星消费已发布产物，
而一个版本文件（或等价物）命名用户所固定的移动标签。不要把引擎源码镜像进
卫星；它已经随镜像传播了。
