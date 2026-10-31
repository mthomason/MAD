[English](README.md) | [简体中文](README_zh.md) | **日本語** | [Português (Brasil)](README_pt-BR.md)

# CLIフィクスチャ

サンプルドキュメントと並び、CLIの各サブコマンド（verb）の実行対象となるドキュメント群です（`docs/project/MAD_CLI.md` §6）。

| フィクスチャ | 元データ | 固定（ピン留め）する対象 |
|---|---|---|
| `London.portable.mad` | `MADDesigner/Resources/Assets/Samples.xcassets/Reports/London.dataset/London.mad` | Sqlite3データパス：11テーブルのスキーマ、London述語、76行 |
| `Music.portable.mad` | `.../Reports/Music.dataset/Music.mad` | より大規模なサンプル（3503行）での同一パス |
| `MySQL.employees.mad` | `employees`サンプルデータベース、ライブ環境（MySQL 8.4） | MySQLドライバのエンドツーエンドパス：スキーマインポート、バッククォート付きSQL、プリペアドステートメントによるフェッチ |
| `TDS.AdventureWorksLT2022.mad` | AdventureWorksLT2022、ライブ環境（SQL Server 2022） | TDSのエンドツーエンドパス：スキーマ修飾されたテーブル、角括弧付きT-SQL、freetdsによるフェッチ |
| `Postgres.chinook.mad` | Chinook、ライブ環境（PostgreSQL 17） | PostgreSQLのエンドツーエンドパス：スキーマインポート、ダブルクォート付きSQL、libpqによるフェッチ |

## サンプルを変換する必要があった理由

出荷されている2つのサンプルはいずれも**レガシー**なドキュメントです。その定義はCore Dataストア（`StoreContent/analyitics`）であり、変換にはCore Dataが必要ですが、MADフレームワーク自体はCore Dataをリンクしておらず、LinuxにもCore Dataは存在しません（`docs/project/MAD_LINUX.md` §5.1, §9）。`London.portable.mad`と`Music.portable.mad`は同じドキュメントをポータブルストア形式で書き出したものであり、Core Dataを持たないプラットフォームでも読み込みと更新が可能です——Linux CLIおよび`Linux/Tests/MADHeadlessDocumentTests.m`はこれを使用しています。

また、これらはv0サンプルに対する読み取り側の対照群でもあります。`mad inspect`はフィクスチャを`StoreContent/store.sqlite`を持つv1として報告し、サンプルをレガシーストアを持つv0として報告しますが、どちらも同じコンテナリーダーから出力されます。

3つのライブフィクスチャは、アプリのドキュメント作成チェーンを実際のサーバーに対して実行して書き出した通常のドキュメントであり、実際のスキーマ（`employees`の8テーブル、AdventureWorksLTの12テーブル、Chinookの11テーブル）と実際のSELECTクエリを持っています。

## 作成手順

手書きされたものは一切なく、すべてMac上でアプリ自身のコードパスを使って生成されています：

	CLI/build.sh --make-fixture portable "$PWD/MADDesigner/Resources/Assets/Samples.xcassets/Reports/London.dataset/London.mad" \
		"$PWD/CLI/Fixtures/London.portable.mad"
	CLI/build.sh --make-fixture portable "$PWD/MADDesigner/Resources/Assets/Samples.xcassets/Reports/Music.dataset/Music.mad" \
		"$PWD/CLI/Fixtures/Music.portable.mad"

	CLI/build.sh --make-fixture create mysql mac 13306 root root employees "$PWD/CLI/Fixtures/MySQL.employees.mad"
	CLI/build.sh --make-fixture select "$PWD/CLI/Fixtures/MySQL.employees.mad" titles "title,from_date,to_date"

	CLI/build.sh --make-fixture create tds mac 1433 sa 'Root1@Root2' AdventureWorksLT2022 "$PWD/CLI/Fixtures/TDS.AdventureWorksLT2022.mad"
	CLI/build.sh --make-fixture select "$PWD/CLI/Fixtures/TDS.AdventureWorksLT2022.mad" "SalesLT.Product" "Name,ListPrice,Color"

	CLI/build.sh --make-fixture create postgres mac 5432 mad mad_test_pw chinook "$PWD/CLI/Fixtures/Postgres.chinook.mad"
	CLI/build.sh --make-fixture select "$PWD/CLI/Fixtures/Postgres.chinook.mad" track "name,composer,unit_price"

`--make-fixture`は`MADFixtureMaker.m`をコンパイルし（ツールと同じフラグに加え、レガシーコンバータとバリュートランスフォーマを含む）、シミュレータ内で実行します：

* `portable`はドキュメントをコピーし、`MADocument`で開きます（読み込み時にレガシーストアを自動変換します）。その後、変更済みマークを付けてクローズすることで保存パスを実行します。
* `create`はライブサーバーに対してアプリのドキュメント作成チェーンを実行します：ドキュメント作成、初回セットアップ、接続の追加、スキーマのインポート、クローズ（保存）。
* `select`はデザイナー上でテーブルとそのフィールドにチェックを入れたときと同じ処理を行います：クエリテーブルを追加し、スキーマフィールドごとにクエリフィールドを追加し、クエリフィールドごとにデータラベルを1つ追加します——SELECTリストはレポートの要素が参照するフィールド群（`MADQueryActiveQueryFields`）であるため、ラベルを配置することでフィールドが*アクティブ*になります。

生成結果は実行ごとにバイト単位で同一にはなりません（ストアはSQLiteであり、アーカイブにはタイムスタンプが含まれるため）。したがって、フィクスチャはサンプルまたはストアフォーマットが変更されたときにのみ再生成し、差分が生じた場合は意味のある変更として確認します。

## ライブフィクスチャ内のホスト名

3つのライブフィクスチャはいずれもサーバー名を`mac`としています。これは作成元Macのホスト名であり、ローカル環境およびDockerコンテナ内の双方からLANアドレスへ名前解決されます。これにより、Mac上のMySQL（下記のフィクスチャコンテナによってループバック*および*LANに公開）と、SQL ServerおよびPostgreSQLコンテナ（全インターフェースに公開）に対して単一のホスト名でアクセスでき、同じドキュメントをMacからもLinuxイメージからも更新できます。`host.docker.internal`はコンテナ内でしか機能せず、`127.0.0.1`はMac上でしか機能しないためです。

3つのライブフィクスチャはすべて、`docs/project/DEVELOPER.md`に文書化されている標準テストコンテナに対して作成されました。これらのスクリプトは固定イメージとチェックサム検証済みデータセットからコンテナを構築します：

	MADMySQL/TestDatabase/mysql-test-db.sh up          # mad-mysql on 13306
	MADTdsClient/TestDatabase/sqlserver-test-db.sh up  # mad-mssql on 1433
	MADPostgres/TestDatabase/postgres-test-db.sh up    # mad-postgres on 5432

3つともすべてのインターフェースにポートを公開するため、ドキュメント内のホスト名`mac`はMac上からもLinuxイメージ内からも解決されます。MySQLコンテナが3306ではなく13306を使用しているのは、Oracle MySQLインストーラのlaunchdサービスが3306を使用している場合があるためです。`down`でサーバーを停止し（ボリューム内のデータは保持されます）、`reset`で削除すると次回の`up`で再構築されます。

CLIの`--host`、`--port`、および`--database`オプションは、1回の実行に限って保存された接続設定を上書きします（`docs/project/MAD_CLI.md` §3）。CIジョブではこれを利用して、Macとはホストやポートが異なるサービスコンテナへこれらのドキュメントを向けます。ドキュメント自体が書き換えられることはありません。
