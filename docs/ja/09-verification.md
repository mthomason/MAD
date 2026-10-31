---
layout: default
lang: ja-JP
---

## 9. 検証

§§2–5の記述は以下のコマンドで再現・検証できます（リポジトリルートから実行してください）：

```sh
tar tjf MADDesigner/Resources/Assets/Samples.xcassets/Reports/Music.dataset/Music.mad
mkdir -p /tmp/mad && tar xjf … -C /tmp/mad
plutil -p /tmp/mad/meta.plist
file /tmp/mad/StoreContent/analyitics
```

§5の記述はデバイスまたはシミュレータのコンテナから再現できます：

```sh
ls -la ~/Library/Developer/CoreSimulator/Devices/<UDID>/data/Library/Caches/<dataTableIdHash>/
```

フォーマットに変更を加える場合は、本ファイルの定義が文章だけでなくテストによって固定（ピン留め）されるよう、`docs/project/MAD_CLI.md` §6に記載されているラウンドトリップフィクスチャを必ず拡張しなければなりません。コンテナのフィクスチャは2026-10-16時点で存在しており（`../Linux/Tests/MADArchiveManagerTests.m`：展開、再パック、再展開を行い、メンバ一覧とバイト列が不変であることを検証）、§7.2のチェックポイントビットもそれを設定するライター（`mad write`）によって固定されています。ライターの*再現可能モード（reproducible mode）*——固定のメンバ時刻、所有者ID 0、ソート済み探索——によって2つのプラットフォーム間で生成されるドキュメントが完全に一致します。これはオプトイン機能であるため、通常のアーカイブ書き込みではファイルシステムのメタデータがそのまま記録され、フォーマットバージョン自体は変わりません（いずれの場合もファイルはv1です）。現時点でそのようなフィクスチャが存在しないのは§5の部分です。コンパニオンファイルは実測に基づいてここに記述されており、将来その実測値と異なる挙動になっても自動的に失敗するテストはまだありません。
