---
layout: default
title: 開発者
description: "MADエンジンの埋め込み、mad CLIの使用、データオブジェクト契約の理解、ヘッドレスエンジンのビルド。"
lang: ja-JP
---

# 開発者

MADは組み込み型のリレーショナルレポーティングエンジンです。ポータブルな`.mad`ドキュメント、ファーストパーティのObjective-Cエンジン、そしてLinuxとWindowsで同じエンジンをヘッドレスで実行する`mad`コマンドラインツールから構成されます。このページ群は、エンジンを組み込みたい人、スクリプトから操作したい人、データソースを追加したい人、ソースからビルドしたい人のためのものです。

## ここから始める

* [`.mad`フォーマット仕様](../README.html) — ドキュメントとは何か、コンテナ、ストア、および規範となる`v1`ターゲット。
* [MAD Designer for macOS](../macos.html) — ネイティブの`AppKit`アプリケーション。
* [MAD Designer for Windows](../windows.html) — ネイティブのWPFアプリケーション。
* [コンポジションレポート](../composition.html) — レポートを1つのドキュメントに統合します。各ソースは自身のクエリ、レイアウト、データを保持します。
* [ビジョン](../vision.html) — 構成可能なデータソースとしてのレポート。

## エンジンとCLI

* [`mad`コマンドラインツール](cli.html) — UIなしでドキュメントを開き、検査し、クエリし、更新し、エクスポートします。
* [データオブジェクト](data-object.html) — レポートの定義、スキーマ、結果セットを1つの契約として扱い、コンポジションがそれをどう実現するかを示します。
* [マルチソースレポート](multi-source.html) — テーブルとしてのレポート、およびテーブルを返すあらゆるもののためのドライバ。同一ドキュメントのコンポジションは構築済みです。
* [クエリデザイナへのSQL貼り付け](sql-entry.html) — サポートされるサブセット、パーサ、および適用パス。

## アーキテクチャ

* [MADDataTableアーキテクチャ](architecture/data-table.html) — フレームワーク横断のデータテーブルクラスクラスタ。
* [MADModelレイヤー](architecture/model-layer.html) — `Rptq`エンティティ上のドキュメント読み取りモデル。
* [MADArrayCaching](architecture/array-caching.html) — レンダーキャッシュを支えるディスクベースの配列。

## ビルドとテスト

* [Linuxでのエンジンビルド](build/linux.html) — Dockerビルドと12のヘッドレスフレームワーク。
* [Windowsでのエンジンビルド](build/windows.html) — 固定されたClangとGNUstepのツールチェーン。
* [ポータビリティとネイティブmacOSアプリケーション](build/macos.html) — フレームワーク監査とAppKitアーキテクチャ。
* [Compressor静的ライブラリビルド](build/libraries.html) — サードパーティCライブラリと、Xcodeがそれらに到達する方法。
* [ヘッドレスPDFライター](build/pdf.html) — Cairo、FreeType、および決定論的エクスポート。

## サテライトとソース

* [サテライトリポジトリ](satellites.html) — `mad-action`とコンテナイメージがこのリポジトリから公開される仕組み。
* [ソース](https://github.com/mthomason/MAD) — リポジトリ、イシュー、および[コントリビューションガイド](https://github.com/mthomason/MAD/blob/master/CONTRIBUTING.md)。
