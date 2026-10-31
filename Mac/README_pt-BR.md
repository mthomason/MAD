[English](README.md) | [简体中文](README_zh.md) | [日本語](README_ja.md) | **Português (Brasil)**

# Mac — o aplicativo nativo para macOS (`AppKit`)

`Mac/` contém o frontend nativo para macOS (`AppKit`, SDK `macosx`, `MACOSX_DEPLOYMENT_TARGET = 12.0`) do **MAD Designer**, construído sobre os doze frameworks MAD multiplataforma (`MADFoundation`, `MADDataStructures`, `MADCocoaExtensions`, `MADFileManager`, `MADAPI`, `MADSqlite3`, `MADTds`, `MADTdsClient`, `MADMySQL`, `MADPostgres`, `MADBarcodes` e `MAD`) e as dez bibliotecas C estáticas universais (`arm64` + `x86_64`) compiladas pelo `Compressor`.

Para a visão geral dos workspaces voltada ao usuário e capturas de tela, consulte [`docs/macos.md`](../docs/pt-br/macos.md). Para a auditoria de portabilidade framework por framework e o registro arquitetural, consulte [`docs/project/MAD_MACOS.md`](../docs/project/MAD_MACOS.md).

## Executando

```sh
./Mac/build.sh                     # build 12 macOS frameworks + Mac/build/MAD Designer.app
./Mac/build.sh --no-frameworks     # rebuild only MAD Designer.app (fast iteration)
./Mac/build.sh --smoke-test        # build and run the end-to-end macOS smoke suite
./Mac/build.sh --package           # create Mac/build/MAD-Designer-macOS.zip and .dmg
```

Você também pode compilar, executar e depurar o aplicativo diretamente no Xcode abrindo o `Reports.xcworkspace`, selecionando o esquema compartilhado **`MAD Designer Mac`** e escolhendo o destino **My Mac**.

## Estrutura de Diretórios

* `Mac/Source/` — aplicativo `AppKit`, arquitetura `NSDocument` e os três workspaces:
  * `MADMacAppDelegate.{h,m}` — ciclo de vida da aplicação, registro de drivers/conversores e barra de menus principal (`MAD Designer`, `File`, `Edit`, `View`, `Report`, `Window`, `Help`).
  * `MADMacAboutWindowController.{h,m}` — janela nativa **About MAD Designer** (`Overview`, `License & Notice` e `Acknowledgements` com barra lateral de componentes e textos de licenças de terceiros embutidos).
  * `MADMacDocumentController.{h,m}` — subclasse de `NSDocumentController` que configura o painel padrão de abertura com filtros `UTType` para `.mad` (`com.everydayapps.productivity.mad` e `com.thomason.report.mad`) e um botão principal **New Document**.
  * `MADMacDocument.{h,m}` — wrapper `NSDocument` sobre `MADHeadlessDocument`, `MADDesignerLayout` (`NSUndoManager`), `MADSectionsLayout`, atualização assíncrona (`MADOperationQueue`) e exportação.
  * `MADMacWindowController.{h,m}` — janela principal do documento com o controle segmentado **Workspace** centralizado (`MAD Query`, `MAD Designer`, `MAD Viewer`).
  * `MADMacConnectionWindowController.{h,m}` — assistente de conexão de banco de dados e importação de esquema com suporte a SQLite, MySQL, Microsoft SQL Server e PostgreSQL, além de armazenamento de credenciais via `MADKeyChain`.
  * `MADMacQueryViewController.{h,m}` — workspace **MAD Query** com canvas visual de tabelas/joins (`MADMacQueryCanvasView`, `MADMacQueryTableCardView`, `MADMacQueryLinksOverlayView`), popovers de filtros/agrupamentos e editor SQL Query em largura total (`MADSQLParser` / `MADSQLQueryCompiler`).
  * `MADMacDesignerViewController.{h,m}` & `MADMacDesignerCanvasView.{h,m}` — workspace **MAD Designer** com paleta de elementos, Page & Section Minimap interativo (`MADMacDesignerMinimapView`), outline Report Bands, origem de arrasto Query Fields, canvas de design com zoom e réguas, e inspetor direito de cartão duplo.
  * `MADMacViewerViewController.{h,m}` — workspace **MAD Viewer** com seleção de tamanho de papel (`MTPaper`), atualização, zoom e navegação de páginas, renderização emoldurada em `PDFView`, barra de status, impressão via `NSPrintOperation` e exportação em 7 formatos (`PDF`, `HTML`, `HTML Flow`, `CSV`, `JSON`, `JSON Report`, `Plain Text`).
* `Mac/Resources/Info.plist` — metadados do bundle e declarações de tipos de documento / UTI para `.mad`.
* `Mac/Tests/MADMacSmokeTest.m` — executável de verificação ponta a ponta que exercita a estrutura do bundle, importação de esquema, design visual de consulta, entrada de SQL, alterações no canvas/minimapa/inspetor do designer, undo/redo, atualização de dados e todos os sete formatos de exportação.
