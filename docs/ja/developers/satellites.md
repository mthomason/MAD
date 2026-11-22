---
layout: default
title: "サテライトリポジトリ"
description: "`mad-action`とコンテナイメージがこのリポジトリから公開される仕組み。"
lang: ja-JP
---

# サテライトリポジトリ

このページでは、`mad-action` GitHub Actionとコンテナイメージがこのリポジトリから公開される仕組み、およびサテライトを最新に保つルールを説明します。

サテライトとは、`mthomason/MAD`の外にあるリポジトリで、MADから構築された何かを公開するものです。今日では`mad-action` GitHub Actionが、GHCR上のコンテナイメージと並んで該当します。サテライトは**公開ターゲットであり、フォークではありません**。MADが真実の源であり、サテライトはここのディレクトリから生成され、境界を越えるのは公開成果物と`satellites/<name>/`の下のファイルだけです。

これはイメージと同じモデルです。`Linux/`がソースで、`.github/workflows/publish-image.yml`が`master`へのプッシュごとに`ghcr.io/mthomason/mad`を公開し、エンジンのソースをどこか別の場所にコピーするものはありません。アクションのユーザーが新しいエンジンを得るのは、サテライトリポジトリがコミットを受け取ったからではなく、イメージタグが動いたからです。

## レジスタ

| サテライト | ソース | 公開元 | 参照 | バージョンタグ |
|---|---|---|---|---|
| [mthomason/mad-action](https://github.com/mthomason/mad-action) | `satellites/mad-action/` | `.github/workflows/publish-mad-action.yml` | `ghcr.io/mthomason/mad:latest` | `v1`（移動中。`satellites/mad-action/VERSION`） |
| `ghcr.io/mthomason/mad`（イメージ、リポジトリではない） | `Linux/` | `.github/workflows/publish-image.yml` | — | `latest`、`<short-sha>` |

`mthomason/mad-action`は生成されます。直接編集しないでください。変更はここの`satellites/mad-action/`に行い、通常のPRゲートを通し、公開ワークフローがそれを運びます。アクションのイシューとプルリクエストは`mthomason/MAD`に属します。

## サテライトのコミットが必要なもの

| MADでの変更 | サテライトの更新 |
|---|---|
| エンジンまたはアプリのコード | なし——次のmasterプッシュが`:latest`を再公開し、アクションがそれを実行する |
| ドキュメント | なし——アクションのREADMEがMADにリンクする |
| CLIの動詞、フラグ、認証情報入力、またはエクスポートフォーマット | `satellites/mad-action/action.yml`、入力マッピングやドキュメントが変わる場合は`README.md` |
| イメージ名またはタグポリシー | `satellites/mad-action/action.yml`、`README.md`、ワークフロー |
| `CLI/Fixtures/London.portable.mad` | 自動: 公開ワークフローが`fixtures/`へコピーする |
| `LICENSE`または`NOTICE` | 自動: 公開ワークフローが両方をコピーする |
| `satellites/mad-action/**` | 自動: 公開ワークフローがディレクトリを同期する |

公開ワークフローは、これらのパスのいずれかが変わると`master`で実行され、`workflow_dispatch`で手動でも実行できます。公開イメージに対してソースをテストし、ターゲットを同期し、`MAD release bot`としてコミットし、メジャータグを動かし、プッシュ時にターゲット自身のテストワークフローを走らせます。サテライトのテストワークフローは毎日スケジュールもされます——ラッパーのソースが変わっていなくてもエンジンの変更がラッパーを壊したときに捕捉するカナリアです。

GitHubはリポジトリの活動が60日ないとスケジュールされたワークフローを無効にします。次の同期コミットがそれを再有効化し、その間は手動の`workflow_dispatch`がテストを直ちに実行します。これがこの取り決めで、失敗せずに静かになり得る唯一の部分です。

## リリースチェックリスト

**通常のソース変更。**

1. ここの`satellites/mad-action/`および／またはフィクスチャを編集します。
2. インターフェースが変わった場合はラッパーをローカルで実行します（`./Linux/build.sh --verify`が`mad-cli:latest`をビルドし、アクションは`image: mad-cli:latest`でそれを指せます）。
3. PRを開きます。`Linux verification`がPR自身のランタイムイメージに対してラッパーを実行し（`linux.yml`）、ターゲットでのアクションのテストに加えます。
4. マージします。`Publish mad-action`がテストして公開し、ターゲットリポジトリでのサテライト自身のテスト実行がその後グリーンでなければなりません。

**CLI契約の変更。** 同じPRが`action.yml`の入力とREADMEを更新します。公開は`v1`を動かし、既存ユーザーは次回実行時に新しいラッパーを得ます。変更が破壊的——入力の名前変更や削除、デフォルトの非互換な変更——の場合は、同じPRで`satellites/mad-action/VERSION`を`v2`に上げ、READMEの`@v1`参照を更新します。ワークフローは`v2`を動かし、`v1`をそのまま残すため、`mthomason/mad-action@v1`のユーザーは移行するまで古いメジャーを保ちます。

**フィクスチャのリフレッシュ。** MADでフィクスチャを再生成し（`CLI/Fixtures/README.md`）、パスフィルタがそれをコピーします。サテライトリポジトリのコピーを編集しないでください。

**デプロイキーのローテーション。** 新しいed25519キーを生成し、その公開半分を書き込みデプロイキーとして`mthomason/mad-action`に追加し、秘密半分を`mthomason/MAD`の`MAD_ACTION_DEPLOY_KEY`シークレットとして設定し、`Publish mad-action`をディスパッチし、その後古いデプロイキーを削除します。キーは1つのターゲットリポジトリにスコープされ、書き込みしかできません。

## 一度きりのセットアップ、記録

ターゲットリポジトリは空で公開として作成されました。GitHubのデフォルトブランチは`main`で、最初の公開がそれを埋めます。ワークフローは`main`にプッシュします。最初の同期がREADMEとライセンスの両方を供給するため、READMEやライセンスで初期化されませんでした。イシューとWikiはそこで無効です。READMEが両方をMADへ送ります。もし再作成されることがあれば、これを繰り返してください。

1. `gh repo create mthomason/mad-action --public`
2. イシューとWikiを無効にする。
3. `MAD publish workflow`というタイトルの書き込みデプロイキーを追加する。
4. その秘密半分を`mthomason/MAD`の`MAD_ACTION_DEPLOY_KEY`シークレットとして設定する。
5. `Publish mad-action`をディスパッチする。

サテライトは独自のサードパーティ依存を持ちません。その本体は公開イメージの`docker run`であり、ライセンスファイルはMADのもの（`LICENSE`、`NOTICE`）です。

## 別のサテライトの追加

ここの`satellites/<name>/`を作成し、`publish-mad-action.yml`の形で公開ワークフローを追加し、上のレジスタ行を追加します。ルールは同じです。MADが真実の源であり、サテライトは公開成果物を消費し、バージョンファイル（または同等物）がユーザーがピン留めする移動タグを名指しします。エンジンのソースをサテライトにミラーしないでください。それはすでにイメージの中で旅をします。
