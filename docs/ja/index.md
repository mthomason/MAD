---
layout: default
title: MAD — モバイル分析ドキュメント (Mobile Analytics Document)
lang: ja-JP
---

**リレーショナルレポーティングのためのオープンフォーマットおよび組み込み可能なエンジン——すべてのレポートは、ポータブルなクエリグラフ、マテリアライズドSQLiteテーブル、そしてパラメトリックレイアウトとして表現されます。**

MADは、アドホッククエリ、レポーティング、およびレポート設計のための組み込み型リレーショナルレポーティングプラットフォームです。iOSおよびネイティブmacOS（`AppKit`）向けの**MAD Designer**および**MAD Viewer**アプリケーション、LinuxおよびmacOS上でそれらをヘッドレス実行するエンジン、そしてオープンな`.mad`ドキュメントフォーマットで構成されています。`.mad`ファイルは、データベースのスキーマスナップショット、クエリグラフ（テーブル、結合、述語、グループ化）、および各要素のバンド型レイアウトというレポート定義全体を100 KB未満で保持し、更新（リフレッシュ）時に生成されるマテリアライズドSQLiteテーブル（`.maddb` + `.mdcache`）から明確に分離されています。

ソースコードは[github.com/mthomason/MAD](https://github.com/mthomason/MAD)にてMITライセンスで公開されています。なお、名称およびアプリケーションのアートワークは同ライセンスの対象外です（[NOTICE](https://github.com/mthomason/MAD/blob/master/NOTICE)を参照）。

## 実際の動作を見る

**[MAD Designer for macOS](macos.html)**——ネイティブ`AppKit`デスクトップアプリケーション（`NSDocument`、視覚的なテーブル／結合クエリキャンバス、インタラクティブなセクションミニマップおよびバンド型レポートデザイナー、ページ分割されたPDF/HTML/CSV/JSONレポートビューアを搭載）：

![ネイティブmacOSアプリケーションのMAD Queryワークスペース](../assets/macos-native-mad-query.png)

![ネイティブmacOSアプリケーションのMAD Designerワークスペース](../assets/macos-native-mad-designer.png)

**MAD Designer for iOS**——データソースの選択からMAD Viewerで完成したレポートを閲覧するまで：

<video controls playsinline preload="metadata" width="360"
  poster="../assets/app-preview-poster.png">
  <source src="../assets/app-preview.mp4" type="video/mp4">
  お使いのブラウザはvideo要素をサポートしていません。<a href="../assets/app-preview.mp4">アプリプレビュー動画</a>は通常のMP4ファイルとしてご覧いただけます。
</video>

**Linux上でヘッドレス動作する同一エンジン**：データベースサーバーも認証情報も不要で、`mad` CLIから`inspect`、`schema`、`query`、`refresh`、`export`を実行：

![.madドキュメントの検査、クエリ確認、更新、エクスポートを行うmad CLI](../assets/mad-cli-demo.gif)

録画内で生成された[エクスポート済みレポート](../assets/london.html)はプレーンなHTMLであり、任意のブラウザで開くことができます。

## なぜMADなのか

* **契約による相互運用性。** 組織内に場当たり的なSQLスクリプトや個別のダッシュボード用グルーコードを散在させる代わりに、`.mad`ファイルはスキーマ契約、クエリAST、およびプレゼンテーションレイアウトを、検査可能かつdiff可能な単一のアーティファクトにパッケージ化します。これにより、AppleプラットフォームとLinuxの間でバイト単位で同一のSQLおよびエクスポート結果が得られます。
* **寄せ集めではなく、一からの自社実装。** SQLジェネレータ、SQLパーサー、データテーブルエンジン、ストア、レイアウトモデル、およびレンダラーは、14個のフレームワークにわたるファーストパーティのObjective-C実装です。サードパーティ製コードは通信層のワイヤライブラリ（MariaDB Connector/C、FreeTDS、`libpq`、SQLite）と、アーカイブ用の`libarchive`/`bzip2`およびバーコード用の`zint`のみに限定されており、プロプライエタリなレポーティングSDKの再販ではありません。
* **モバイルファーストかつ省メモリ設計。** 更新時には結果セットを一度だけSQLiteの行キャッシュ（`MADDataTableFast`）に読み込み、そこから2パスのグループ化と集計を計算するため、スマートフォンの限られたメモリ内でも高速なページ分割レンダリングが可能です。
* **組み込み可能で高いポータビリティ。** 14個のフレームワークのうち11個はUIKitに依存せずヘッドレスでビルドでき、Docker上のLinuxで1,303件のテストに合格しています。`.mad`コンテナはポータブルなSQLiteストアを格納したbzip2圧縮tarアーカイブであり、開くためにApple製フレームワークを必要としません。

## `.mad`フォーマット仕様

1ファイル1章で構成されたオープン仕様書です：

[ドキュメントとは何か](01-document.html) ·
[コンテナ](02-container.html) ·
[ストア](03-store.html) ·
[読み込みと書き込み](04-reading-writing.html) ·
[コンパニオンファイル](05-companion-files.html) ·
[注意点・ハザード](06-hazards.html) ·
[規定仕様 `v1`](07-normative.html) ·
[未解決の論点](08-open-questions.html) ·
[検証](09-verification.html)

## エンジンの活用

* [MAD Designer for macOS](macos.html)——ネイティブ`AppKit`デスクトップアプリ：視覚的なクエリキャンバス、ミニマップとインスペクタを備えたバンド型レポートデザイナー、ページ分割ビューア、およびソースからのビルド・パッケージ化手順。
* [ビルドとテスト](https://github.com/mthomason/MAD#build-and-test)——iOSテストスイート、ネイティブmacOSテストスイート、およびLinuxビルドの正確なコマンド。
* [`mad` CLI](https://github.com/mthomason/MAD#try-it)——Dockerから1行のコマンドで`.mad`を検査、更新、エクスポート。
* [mad-action](https://github.com/mthomason/mad-action)——リポジトリにコミットされた`.mad`をGitHub Actionsで実行し、エクスポート結果をアップロード（`mthomason/mad-action@v1`）。
* [ドライバ作成チュートリアル](tutorials/driver-authoring.html)——最初のコントリビューションとして推奨されるガイド：`MADDatabase`をサブクラス化し、ドライバを登録して行データを返す方法。

## 今後の方向性

[ビジョン](vision.html)——コンポーザブルなデータベーステーブルとしてのレポート、単一レポート内でのマルチデータソースクエリ、紙のパラダイムを超えたネイティブUIKitデータビュー、およびレガシーなCrystal Reports（`.rpt`）からオープンな`.mad`ファイルへの変換。

---

このエンジン上に構築されたレポートデザイナーアプリ**MAD Designer**の製品サイトは[mad.everydayapps.com](https://mad.everydayapps.com/)で公開されています。
