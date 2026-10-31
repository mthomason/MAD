---
layout: default
lang: ja-JP
---

# `.mad`ドキュメントフォーマット

本ドキュメントは、`.mad`ファイルとは何かを定義します。まず、出荷されている2つのサンプルドキュメントおよびそれらを読み書きするコードに基づき、**現在存在する通りのフォーマット**を記述します。次に、コマンドラインツールやWindowsビルドなど別のプラットフォーム上のリーダーが、Core DataやApple製フレームワークに依存することなくドキュメントを開けるよう、**本来定義されるべきフォーマット**を規定します。

このフォーマットが重要である理由は、レポートが*小さい*こと（出荷されているサンプルは80 KB未満）、そしてそれを実行するエンジンがスマートフォンにもコンテナにも収まることにあります。同一の定義がiOS、macOS、およびヘッドレスLinuxビルド上で動作します。レポートの結果テーブルを他のレポートのデータソースとして利用可能にし、1つのドキュメントで複数のデータベースを横断できるようにする今後の方向性については、[`vision.md`](vision.md)を参照してください。本仕様書はウェブサイトとしても<https://docs.everydayapps.com>で公開されています。

前半の記述はすべて推測ではなく実測に基づいています。対象となる2つのサンプルは`../../MADDesigner/Resources/Assets/Samples.xcassets/Reports/Music.dataset/Music.mad`および`…/London.dataset/London.mad`です。

---

**`.mad`フォーマットはオープン仕様です。** 誰でも本仕様を読み、実装することができます。プロジェクトのコードにはMITライセンスが適用されます。「MAD」「MAD Designer」「MAD Viewer」という名称、ならびにアプリケーションアイコンおよびその他の製品アートワークは著作者に帰属し、ライセンス供与の対象外ですが、`.mad`ファイルや本プロジェクトに対する説明的な言及は歓迎します。[`../../LICENSE`](https://github.com/mthomason/MAD/blob/master/LICENSE)、[`../../NOTICE`](https://github.com/mthomason/MAD/blob/master/NOTICE)、および[`../project/THIRD_PARTY_LICENSES.md`](https://github.com/mthomason/MAD/blob/master/docs/project/THIRD_PARTY_LICENSES.md)を参照してください。

本仕様書は1ファイル1章で構成されています。第1〜6章は現在出荷されているフォーマットを記述し、第7章は規定ターゲット（`v1`）、第8〜9章は未解決の論点および各記述の検証方法を示します：

1. [一言で言うとドキュメントとは何か](01-document.md)
2. [コンテナ](02-container.md)
3. [ストア](03-store.md)
4. [実装されている読み込みと書き込み](04-reading-writing.md)
5. [ドキュメントに含まれ*ない*もの：コンパニオンファイル](05-companion-files.md)
6. [別のリーダー実装が対処すべき注意点（ハザード）](06-hazards.md)
7. [本来定義されるべきフォーマット（規定仕様）](07-normative.md)
8. [未解決の論点](08-open-questions.md)
9. [検証](09-verification.md)
