---
layout: default
title: "ヘッドレスPDFライター"
description: "CairoとFreeTypeのスタック、フォントマッピング、および決定論的PDFエクスポート。"
lang: ja-JP
---

# ヘッドレスPDFライター — Cairo + FreeTypeの本体

このページはヘッドレスPDFライターを記録します。CairoとFreeTypeのスタック、フォントマッピングポリシー、決定論的モード、およびjson-reportオラクルに対する受け入れテストです。

*元の日付に書かれ、現状の事実は2026-11-22に整合。*

**ステータス（2026-11-20）: LinuxとWindowsで実装済み、グリーン。** `mad export --format pdf`と`mad serve`の`export`が両方のヘッドレスエンジンでPDFを書きます。`MADReportExporterPDF`のApple本体は変更なく、`--deterministic`下で同じ43,177バイト、5ページ、`sha256 3eb2f1c4…`のLondonサンプルを依然として書きます。以下のセクションは納品された記録です。ここに至る決定履歴（ステータス、候補スタック、未解決の問い）は末尾に保たれています。

## それが何か

これが閉じるギャップは常に書き込みだけでした。`MADReportPageBuilder`がドキュメントを準備してページをウォークし、`html`、`html-flow`、`json-report`はすでにそのウォークを読み、プラットフォーム間でバイト同一です。PDFライターは同じウォーク済みページを取り、それらを描画します。

* `MADReportExporterPDFCairo`（`MAD/Source/MADReportExporterPDFCairo.m`）は`MADReportExporterPDF`の非Apple本体です。AppleではエクスポーターはCore Graphicsパスを保ち、Apple以外では同じ`exportDocument:toURL:options:error:`がドキュメントをここに渡します。
* ライターはApple本体とまったく同じようにドキュメントを準備し（`+MADReportPageBuilder prepareDocumentForRender:`）、ページの境界でCairo PDFサーフェスを作成し、ウォークされた各ページについて白いキャンバス、各ラインのテキストをそのフレームに、各ピクチャ、テキスト装飾を描画します。
* `+isAvailable`はすべてのプラットフォームでYESと答え、`+unavailableReason`はnilです。フォントバンドルの欠落は独自のメッセージを持つエクスポートエラーで、静かな代替ではありません。

## スタックとそのライセンス

| コンポーネント | バージョン | ライセンス | 役割 |
|---|---|---|---|
| cairo | 1.18.6（gitタグ、コミット固定） | **MPL-1.1**（MPLオプション） | PDFサーフェスと描画 |
| pixman | 0.46.4（gitタグ、コミット固定） | MIT | cairoのラスターコア |
| FreeType | 2.15.0 | **FTL** | グリフのアドバンス、カーニング、アウトライン |
| Liberation Sans/Serif/Mono | 2.1.5 | **SIL OFL 1.1** | 代替フェイス |

Pangoなし: ウォークはすでに各ラインのフレーム、テキスト、フォント、サイズ、特性、配置を解決し、フレームの幅が唯一の折り返し境界です（`NSLineBreakByTruncatingTail`）。残るのはアドバンスとカーニングで、FreeTypeが直接供給します。cairoはPDFサーフェスのみでビルドされます——FreeTypeとzlibはin、fontconfig、Pango/glib、Xlib/XCB、Quartz、PNG以外の画像バックエンドはout——そのため上の表以上のものを引き込みません（zlibとlibpngはバーコードスタックのためにすでにありました）。

テキストは`ThirdParty/Licenses/`にあり（`cairo-MPL-1.1.txt`、`pixman-MIT.txt`、`freetype-FTL.txt`、`liberation-OFL-1.1.txt`）、レジスタは`THIRD_PARTY_LICENSES.md` §3.5、§9（Linuxイメージ）、§10（Windowsエンジン）です。4つのどれも再リンク義務を追加しないため、`ThirdParty/Licenses/README.md`の書面による申し出は変わりません。WindowsのAboutウィンドウは`WindowsLicenseRegistry`から4つすべてを一覧します。

## フォントマッピング

ドキュメントはAppleフォントを名指しし、バンドルはLiberationを運ぶため、名前はファミリに、次に要素の太字と斜体フラグ（および名前自体が述べるウェイトや傾き、例えば`HelveticaNeue-Bold`）によってフェイスにマップされます。

| ドキュメントフォント | 代替 | 注記 |
|---|---|---|
| Helvetica Neue、Helvetica、Arial、Verdana、Tahoma、Trebuchet MS、Calibri、system | Liberation Sans | Arialのメトリクス双子なので、Helvetica/Arialのラインは近い。**VerdanaはLiberation Sansより広い**ため、VerdanaのラインはCore Graphicsより狭くなり、早く切り詰められることがある |
| Courier、Courier New、Menlo、Consolas | Liberation Mono | Courier Newのメトリクス双子 |
| Times New Roman、Times、Georgia、Palatino、Baskerville、Garamond | Liberation Serif | Times New Romanのメトリクス双子。**GeorgiaはLiberation Serifより広い** |
| それ以外 | Liberation Sans | レンダラー自身のフォールバックはシステムフォントで、ヘッドレスエンジンにはない |

ウェイトと傾きがフェイスを選び（`Regular`、`Bold`、`Italic`、`BoldItalic`）、下線と取り消し線は計測されたラン（run）の下／中に塗りつぶし矩形として描画され、フェイスのPostScript下線メトリクスを使います。配置はスタイルのもの（`left`、`center`、`right`。両端揃えと自然は左に描画し、HTMLファクシミリに一致）です。フレームより広いランはカットされ、`…`で終わります。レンダラーのtruncating-tailルールです。

**残差は代替フェイスのメトリクスです。** ページ、各ラインのフレーム、各ラインの解決済みテキスト、そのフォントファミリマッピング、サイズ、ウェイト、傾き、配置はウォークのもので正確です。フレーム内のラインの幅は代替フェイスのものなので、Macよりわずかに広いか狭いラインが描画されます——最も目立つのはVerdanaとGeorgiaで、その実際のフェイスはバンドル内の何ともメトリクス互換ではありません。これは視覚的な差異であり、構造的なものではありません。オラクルテストはテキストとフレームを比較し、グリフの範囲は比較しません。

## 決定論

`MADReportExportOptionsDeterministic`は、Cairoがそうでなければ時計から取る2つの日付（`CAIRO_PDF_METADATA_CREATE_DATE` / `_MOD_DATE`）を、Apple本体がそのトレーラで固定するのと同じ瞬間`2001-01-12T00:00:00Z`（PDFエポック）に固定します。Cairoはトレーラ`/ID`を書かず、そのオブジェクト番号付け、フォントサブセットタグ、圧縮、ページツリーは決定論的なので、変更のないレポートの2回のエクスポートは同じバイトです。テストがそれを証明します。

それを真に保つために、ライター側の危険を1つ除去しなければなりませんでした。cairoはフォントフェイスとスケール済みフォントを`FT_Face`ポインタでキャッシュするため、エクスポートごとにフェイスを開いて解放するライターは、アロケータがアドレスを再利用したときに古いキャッシュエントリを渡される可能性があり、コンテンツストリームが`Tj`からグリフごとの`TJ`オフセットに切り替わることがありました。フェイスは今プロセス全体のロードワンス静的で、共有されている間エクスポートは再帰ロック下で直列化されます。

プラットフォーム間で2つのライターはバイト単位で一致することを求められませんが、LondonフィクスチャのCairo出力はLinuxとWindowsで同じサイズで、わずか44バイトだけ異なります——cairoが生成するフォントサブセットプレフィックスです（グリフを`unsigned long`としてハッシュし、Linuxでは8バイト、Windowsでは4バイト）。テキスト、ジオメトリ、ページ構造は同一です。

サーフェスは**PDF 1.4**に制限されます。古典的なクロスリファレンステーブルとプレーンオブジェクトです。Cairoのデフォルト1.7はオブジェクトとクロスリファレンスのストリームを書き、描画はより簡単でなく読み戻しはより困難です。1.4は最も広いリーダーベースでもあります。1つの帰結: CairoのPDF APIにはTrimBoxがないため、ページのMediaBoxはUS Letterで、コンテンツはウォークが使うのと同じ1ptトリムの内側に描画されます（`[1, 1, 610, 790]`）。トリムはフレーム内で構造的で、PDFボックスではありません。

## 描画

各ページについて、cairoのPDFユーザー空間で（原点左上、y下。cairoが`1 0 0 -1 0 H cm`の反転を自身で書くため、ウォークのフレームは変更なしで通ります）:

* 白いトリムボックス。Appleレンダラーの`drawWhiteCanvas:pageRect:`がするように。
* 各テキストライン: `MADReportLineStyle`からのフェイスとサイズ、ラインからの解決済みテキスト、グリフはFreeTypeのアドバンスとカーニングでラインのサイズに配置（`FT_KERNING_UNFITTED`、シェーピングがフェイスとサイズだけに依存するように）、フレームの左（または中央／右）端とベースライン。
* 各ピクチャ: 画像要素の保存されたPNGまたはバーコードのシンボル（`MADReportLineRepresentation -imageData`、遅延レンダリング）、HTMLファクシミリがフィットさせる方法（`object-fit: contain`）でフレームにアスペクトフィットし、cairoのPNGリーダーを通じてデコード。
* 装飾: 下線と取り消し線を塗りつぶし矩形として。
* ページごとに`cairo_show_page`（および白い塗りつぶし）。

ページウォークはページごとに1つの読み取りトランザクションで、他のすべての場所と同じです。ピクチャはそれが閉じた後に読まれ、持たないドキュメントにはコストがかかりません。

## 受け入れテスト

`Linux/Tests/MADPDFExportTests.m`（および`Windows/Engine/Tests/`）はLondonフィクスチャを開き、バーコードとピクチャを追加し、リフレッシュし、エクスポートします。テスト内の小さなPDF 1.4リーダー（ページツリー、MediaBox、コンテンツストリーム、フォントToUnicodeマップ）でPDFを読み戻し、同じドキュメントの`json-report`と比較します——両プラットフォームがバイト単位で一致するオラクルです。

* ページ数と各ページのUS Letter MediaBox。
* ウォークされた各ラインのフレームが1ptトリムの内側にあること。
* 各テキストラインのテキストを、ウォークの順序で、ページごとに（フレームがテキストより狭い場所ではtruncating-tailの省略記号を許容）。
* バーコードとピクチャがテキストではなく画像XObjectとして。
* 2つの決定論的エクスポートが固定日付でバイト同一。通常のエクスポートは時計の日付を取る。

`MADReportExporterTests`はまた、プレーンなLondonフィクスチャをエクスポートし、5ページ、ウォークのページ数をチェックします。Appleのバイトピンはヘッドレステストではありません。Appleスイートは依然として43,177バイト / `3eb2f1c4…`のエクスポートをアサートし、`#if __APPLE__`本体は触れられていません。

## ビルド

* **Linux** — `Linux/libraries.conf`がpixman、FreeType、cairo、Liberation tarballを固定します。`Linux/lib/libraries.sh`には`build_pixman`（meson）、`build_freetype`（autoconf、コアのみ）、`build_cairo`（meson、PDFサーフェス）、`build_liberation`（12のフェイスを`${PREFIX}/share/mad/fonts`へ）があります。イメージはそれらを`/usr/local`にインストールし、ランタイムステージはフォントのために`/usr/local/share/mad`をコピーします。Dockerfileの`toolchain-base`は`meson`と`ninja-build`（cairoとpixmanのビルドシステム）と`xz-utils`（FreeTypeのピンは`.tar.xz`）を必要とします。
* **Windows** — `Windows/Engine/build.ps1`はFreeTypeを自身のCMakeで、pixmanとcairoをMSVC環境下でMesonでビルドし（cairoはそのDWriteバックエンド付きで、cairoのwin32ソースがリンクに必要）、3つの静的`.lib`を`mad.exe`にリンクし、Liberationフェイスを`Build\fonts`にコピーします（libpqビルドがすでに必要としたpkg-configシムが、生成された`.pc`ファイルを通じてローカルのピンを見つけます）。ライターは`<exe>/fonts`、`<exe>/../fonts`、`<exe>/../share/mad/fonts`、`/usr/local/share/mad/fonts`、`/usr/share/mad/fonts`、`/usr/local/share/fonts/liberation`、`/usr/share/fonts/truetype/liberation`、および`MAD_FONTS_DIR`上書きを探します。

フォントはコードではなくデータファイルです。Windowsパッケージは`mad.exe`の隣に`Windows/Engine/build/fonts`を同梱しなければならず、Linuxイメージはすでに`/usr/local/share/mad/fonts`にそれらを運びます。

## Appleの本体は変更なし

`MADReportExporterPDF`の`#if __APPLE__`パス——Core Graphics、`MADPrintPageRenderer`、メタデータ固定——は触れられていません。AppleターゲットはCairoをリンクせず、新しいライターのソースはそのXcodeターゲットにありません。記録のためのAppleビルドコマンド:

	xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
		-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild build -workspace Reports.xcworkspace -scheme 'MAD Designer' \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
		-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci

（それらはWindowsワークステーションでは実行されません——そこにXcodeはありません。この増分が触れるAppleファイルはエクスポーターの非Apple腕とそのコメントです。）

## 意図的な制限

* **構造的同等性であり、バイト同等性ではない** — Core Graphicsのライターは再現できません。オラクルはウォーク（`json-report`/`html`）であり、Apple PDFではありません。
* **TrimBoxなし** — cairoのPDF APIにありません。コンテンツはトリムの内側です。
* **ラテン文字、左から右** — グリフ配置はFreeTypeのアドバンス + `kern`テーブルで、シェーピングエンジン（HarfBuzz/Pangoなし）ではありません。リガチャなし、結合マークの合成なし、双方向並べ替えなし。ドキュメントのフィールドとラベルはラテン文字です。そうでないドキュメントは各コードポイント自身のグリフを論理順で描画します。
* **代替メトリクス** — 上の残差参照（VerdanaとGeorgiaが最大のギャップ）。
* **Windows WPF Viewerのフォーマットピッカー**はPDFを一覧しません。`mad export --format pdf`と`mad serve`の`export`が一覧し、それがクロージャの表面です。ピッカー行の追加は独自の文字列リソースを持つUI変更です。

---

## 以前の決定記録

これらのセクションは指示ではなく、決定履歴のために保たれています。

### 候補スタック（MAD_LINUX.md §10.2）

| オプション | ライセンス | 与えるもの | コスト |
|---|---|---|---|
| **Cairo + Pango**（+ FreeType/HarfBuzz） | LGPL-2.1/MPL-1.1、LGPL-2.1、FTL/GPLv2デュアル、MIT | PDFサーフェス付きベクター描画と本物のテキストレイアウト | イメージ内の新しい依存とそのライセンス／通知作業 |
| **libharu** | zlib | PDF出力、寛容 | PDFのみ、レイアウトエンジンなし |
| **Skia** | BSD-3 | CG + Core Textに最も近い能力 | 重いC++ビルド |
| **手書きPDFエミッタ** | なし | 依存なし | 近似タイポグラフィ、2つ目の描画パス |

**選ばれたもの（2026-11-20）: Cairo + FreeType、Pangoなし。** ウォークがレイアウトを提供し、残るのはグリフのアドバンスとカーニングだけで、FreeTypeの`kern`テーブルがレイアウトエンジンなしで供給します。Pangoは誰も必要としない折り返しのために依存（とそのLGPL/glibツリー）を追加したでしょう。

### 未解決の問いへの答え

1. **フォント** — 上のマッピング表参照: Liberation Sans/Serif/Mono、メトリクス互換ファミリのために選ばれ、VerdanaとGeorgiaの残差が記録されています。
2. **どのスタックとライセンス** — Cairo（MPL-1.1）、pixman（MIT）、FreeType（FTL）、Liberation（OFL）: すべて寛容かMPLで、LGPLはなく、再リンク義務もありません。
3. **ライターはどこに住むか** — `MAD`内、`MADReportExporterPDFCairo`として、独自の翻訳単位と隠しヘッダーで、Apple以外でのみコンパイル。Appleターゲットはそれをリンクしません。
4. **無人サーバーPDFは必要か?** — はい: CLIの`export`動詞と`serve`の`export`が表面で、スケジュールされたジョブにはブラウザがありません。
