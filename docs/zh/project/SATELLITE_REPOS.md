---
layout: default
lang: zh-CN
---

# 卫星仓库

卫星仓库是 `mthomason/MAD` 之外的仓库，它发布由 MAD 构建的东西：目前是 `mad-action` GitHub Action，以及 GHCR 上的容器镜像。卫星仓库是**发布目标，而非复刻（fork）**。MAD 是事实来源；卫星仓库由这里的一个目录生成，跨越边界的只有已发布的产物和 `satellites/<name>/` 下的文件。

这与镜像采用相同的模型：`Linux/` 是源，`.github/workflows/publish-image.yml` 在每次推送到 `master` 时发布 `ghcr.io/mthomason/mad`，没有任何东西把引擎的源代码复制到其他任何地方。Action 用户获得新引擎是因为镜像标签移动了，而不是因为卫星仓库收到了提交。

## 登记表

| 卫星仓库 | 源 | 发布方 | 引用 | 版本标签 |
|---|---|---|---|---|
| [mthomason/mad-action](https://github.com/mthomason/mad-action) | `satellites/mad-action/` | `.github/workflows/publish-mad-action.yml` | `ghcr.io/mthomason/mad:latest` | `v1`（移动；`satellites/mad-action/VERSION`） |
| `ghcr.io/mthomason/mad`（镜像，不是仓库） | `Linux/` | `.github/workflows/publish-image.yml` | — | `latest`、`<short-sha>` |

`mthomason/mad-action` 是生成出来的。不要直接编辑它：更改应提交到这里的 `satellites/mad-action/`，经过正常的 PR 关卡，由发布工作流携带过去。该 action 的 issue 和拉取请求应提交到 `mthomason/MAD`。

## 什么需要卫星仓库提交

| MAD 中的变更 | 卫星仓库更新 |
|---|---|
| 引擎或应用代码 | 无需——下一次 master 推送会重新发布 `:latest`，action 会运行它 |
| 文档 | 无需——action 的 README 链接到 MAD |
| CLI 动词、标志、凭据输入或导出格式 | `satellites/mad-action/action.yml`；若输入映射或文档有变化则更新 `README.md` |
| 镜像名称或标签策略 | `satellites/mad-action/action.yml`、`README.md`、各工作流 |
| `CLI/Fixtures/London.portable.mad` | 自动：发布工作流将其复制到 `fixtures/` |
| `LICENSE` 或 `NOTICE` | 自动：发布工作流会复制两者 |
| `satellites/mad-action/**` | 自动：发布工作流会同步该目录 |

当这些路径之一发生变化时，发布工作流会在 `master` 上运行，也可通过 `workflow_dispatch` 手动运行。它针对已发布的镜像测试源代码，同步目标仓库，以 `MAD release bot` 身份提交，移动主版本标签，并让目标仓库自身的测试工作流在该推送之上运行。卫星仓库的测试工作流还每天定时运行——这是金丝雀，用来捕获即使包装器源代码未变也会破坏包装器的引擎变更。

GitHub 会在仓库 60 天无活动后停用定时工作流。下一次同步提交会重新启用它；在此期间，手动 `workflow_dispatch` 会立即运行测试。这是整套安排中唯一可能在未失败的情况下悄然静默的部分。

## 发布清单

**普通的源变更。**

1. 在此编辑 `satellites/mad-action/` 和/或测试夹具。
2. 如果接口发生变化，在本地运行包装器（`./Linux/build.sh --verify` 构建 `mad-cli:latest`；可以用 `image: mad-cli:latest` 将 action 指向它）。
3. 打开 PR。`Linux verification` 会在目标仓库中 action 测试之外，针对该 PR 自身的运行时镜像（`linux.yml`）运行包装器。
4. 合并。`Publish mad-action` 会测试并发布；随后目标仓库中卫星仓库自身的测试运行必须为绿色。

**CLI 契约变更。** 同一个 PR 会更新 `action.yml` 的输入和 README。发布会移动 `v1`；现有用户会在下次运行时获得新的包装器。如果变更是破坏性的——输入被重命名或移除、默认值发生了不兼容的更改——则在同一 PR 中将 `satellites/mad-action/VERSION` 升到 `v2`，并更新 README 中的 `@v1` 引用。工作流随后移动 `v2`，并把 `v1` 留在原处，因此 `mthomason/mad-action@v1` 用户在他们迁移之前仍保留旧的主版本。

**测试夹具刷新。** 在 MAD 中重新生成测试夹具（`CLI/Fixtures/README.md`）；路径过滤器会复制它。不要编辑卫星仓库中的副本。

**部署密钥轮换。** 生成新的 ed25519 密钥，将其公钥部分作为写部署密钥添加到 `mthomason/mad-action`，将私钥部分设置为 `mthomason/MAD` 上的 `MAD_ACTION_DEPLOY_KEY` 机密，调度 `Publish mad-action`，然后删除旧的部署密钥。该密钥仅限单个目标仓库，并且只能写入。

## 一次性设置（记录在案）

目标仓库创建时为空且公开。GitHub 的默认分支是 `main`，第一次发布会填充它；工作流推送 `main`。它没有用 README 或许可证初始化，因为第一次同步会提供两者。那里的 issue 和 wiki 已被禁用：README 将两者都指向 MAD。如果它被重新创建，请重复以下步骤：

1. `gh repo create mthomason/mad-action --public`
2. 禁用 issue 和 wiki。
3. 添加一个标题为 `MAD publish workflow` 的写部署密钥。
4. 将其私钥部分设置为 `mthomason/MAD` 上的 `MAD_ACTION_DEPLOY_KEY` 机密。
5. 调度 `Publish mad-action`。

卫星仓库本身没有第三方依赖：它的主体是对已发布镜像的 `docker run`，其许可证文件是 MAD 的（`LICENSE`、`NOTICE`）。

## 添加另一个卫星仓库

在此创建 `satellites/<name>/`，按 `publish-mad-action.yml` 的形态添加发布工作流，并添加上面的登记行。规则相同：MAD 是事实来源，卫星仓库消费已发布的产物，版本文件（或等价物）命名用户固定的移动标签。不要将引擎源代码镜像到卫星仓库；它已经随镜像传递。
