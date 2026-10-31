[English](CONTRIBUTING.md) | [简体中文](CONTRIBUTING_zh.md) | **日本語**

# MADへのコントリビューション

ご覧いただきありがとうございます。MAD（Mobile Analytics Document）は、MAD DesignerおよびMAD Viewerアプリ、フレームワーク群、そしてヘッドレスエンジンから成るプロジェクトであり、新しいデータベースドライバ、新しいドキュメント要素、新しいエクスポートフォーマットといった拡張ポイント（seam）こそが本プロジェクトの要です。ドライバ作成チュートリアル（[`docs/tutorials/driver-authoring.md`](docs/ja/tutorials/driver-authoring.md)）では最初のドライバ実装手順を解説しており、最初のコントリビューションとして推奨しています。

## 前提条件

* **XcodeがインストールされたmacOS** — iOS側は14個のフレームワークとアプリから成るワークスペースで、iOS 15以降を対象にビルドされます。フレームワークはObjective-Cで記述されています。
* **Docker** — ヘッドレスエンジンのLinuxビルド用です。単一のイメージ内でObjective-Cツールチェーン（libobjc2、libdispatch、GNUstep）とCライブラリ群をソースからビルドし、11個のヘッドレスフレームワークをコンパイルしてテストスイートを実行します。
* コントリビューションにあたってデータベースサーバーは必須ではありません。MySQL、SQL Server、およびPostgreSQLのライブテストスイートはサーバーに到達できない場合は自動的にスキップされます。また、それらを提供するDockerコンテナの起動手順は[`docs/project/DEVELOPER.md`](docs/project/DEVELOPER.md)に記載されています。

## はじめに

1. リポジトリをフォークし、自分のフォークをクローンします。
2. 変更を加える前にまずビルドとテストを実行し、ベースラインが正常であることを確認します：

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

   [`docs/project/DEVELOPER.md`](docs/project/DEVELOPER.md)に、完全なコマンドマトリクス、フレームワークが前提とする共有DerivedDataパス、およびテストデータベースのセットアップ手順が記載されています。
3. 取り組む対象を選びます。新しいドライバ、要素、または`"good first issue"`ラベルが付いたIssueなどが適しています。レビューでは正確さが重視されるため、小さな変更から始めることを推奨します。

## テストファーストの原則

**最初に失敗するテストを書いてください。** これは単なる提案ではなくプロジェクトの文化です。コードが存在する前にテストによって仕様・挙動を固定（ピン留め）し、それをグリーンにする変更こそが修正（実装）となります。フォーマットやデータに関する作業では、新しいコードで期待値を生成するのではなく、変更前のフィクスチャをスナップショットしてください。フィクスチャこそが実際の挙動を証明する根拠となります。

作業ループは以下の順序で行います：

1. 意図する挙動を表す、失敗するテストを追加する。
2. テストを実行し、想定通りの理由で失敗することを確認する。
3. 実装を行い、テストをグリーンにする。
4. テストスイート全体を実行する——Linuxビルドがコンパイルするファイル（`Linux/cmake/*Sources.cmake`を参照）に触れた場合は、iOS*および*`./Linux/build.sh`の両方を実行します。すべてのコミットにおいて、すべてのテストスイートがグリーンでなければなりません。

Linuxテストスイートでは、既知のプラットフォーム差異を黙ってスキップするのではなく`NEED`行として記録します。新しい`NEED`には必ず理由を添える必要があり、修正も記録もされていない差異はビルド失敗として扱われます。

## コーディングスタイル

* インデントにはスペースではなくタブを使用します。コメントは本当に必要な箇所にのみ記述します。
* 意図的に未使用としているコードには、宣言箇所でclangの`unused`属性を付与します。属性の付いていない未使用警告はデッドコードを意味するため削除対象となります。
* 新規ファイルには1行ヘッダー`Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT`（ソースコードは`//`、スクリプトは`#`）を記載します。
* [`docs/project/BUGS.md`](docs/project/BUGS.md)には未解決の不具合とそれを固定するテストが記録されています。不具合を修正した場合は、そのエントリを[`docs/project/BUGS_FIXED.md`](docs/project/BUGS_FIXED.md)へ移動します——記録されていない修正は完了とはみなされません。

## Developer Certificate of Origin (DCO)

本プロジェクトではCLAの代わりにDCOによる署名（sign-off）を必須としています。すべてのコミット末尾には次の行を含める必要があります：

    Signed-off-by: Name <email>

（`git commit -s`で自動追加されます。）この行を追加することで、[developercertificate.org](https://developercertificate.org)に基づき、自身がその変更を作成したか、またはプロジェクトのライセンス（MIT、`LICENSE`を参照）の下でそれを提供する権利を有していることを証明したものとみなされます。GitHub上でプルリクエストを作成するとDCOチェックが実行されます。

## プルリクエスト

* 1つのPRにつき1つの関心事（テーマ）に絞ってください。コミットはレビューしやすい単位に保ってください。プロジェクトの履歴は記録であり、メモ帳ではありません。
* PRテンプレートに記入してください——テストファーストのチェックリストはレビュアーのためのものであり、該当しない項目には「該当なし（not applicable）」と記載して構いません。
* Linuxビルドに関わるファイルに触れるPRは、そのブランチ上で`./Linux/build.sh`がグリーンであることを示す必要があります。

## Issue

バグ報告およびドライバ提案用のテンプレートは[`.github/ISSUE_TEMPLATE/`](.github/ISSUE_TEMPLATE/)にあります。セキュリティに関する問題は決して公開Issueには投稿せず、[`SECURITY.md`](SECURITY_ja.md)に記載された非公開の連絡経路を使用してください。

## 質問・サポート

質問がある場合はIssue（または公開後のDiscussionsボード）でお尋ねください。メンテナがすべてのIssueに回答します。本プロジェクトは個人開発からコミュニティへと成長している段階であるため、何を試したかが明確に書かれた質問ほど迅速に回答できます。

## プロジェクトへの支援

MADのコードはMITライセンスのフリーソフトウェアであり、コントリビューションこそが最大の支援です。もし本プロジェクトによってチームの時間が節約でき、さらなる支援をご検討いただける場合は、[GitHub Sponsors](https://github.com/sponsors/mthomason)やエージェント駆動開発用のAPIクレジットを受け付けています——いただいた支援はすべて開発作業へ直接還元されます（[README](README_ja.md)の「サポート」セクションを参照）。
