[English](README.md) | [简体中文](README_zh.md) | [日本語](README_ja.md) | [Português (Brasil)](README_pt-BR.md) | [Deutsch](README_de.md) | **Español**

# <a href="../StaticResources/Images/icons/document/Designer%20Icon@3x.png"><img src="../docs/assets/mad-designer-macos-icon-256.png" alt="Icono de MAD Designer" width="44" height="44" align="absmiddle" /></a> Mac: la aplicación nativa de macOS (`AppKit`)

`Mac/` contiene el frontend nativo de macOS (`AppKit`, SDK `macosx`, `MACOSX_DEPLOYMENT_TARGET = 12.0`) de **MAD Designer**, construido sobre los doce frameworks multiplataforma de MAD (`MADFoundation`, `MADDataStructures`, `MADCocoaExtensions`, `MADFileManager`, `MADAPI`, `MADSqlite3`, `MADTds`, `MADTdsClient`, `MADMySQL`, `MADPostgres`, `MADBarcodes` y `MAD`) y las diez bibliotecas C estáticas universales (`arm64` + `x86_64`) compiladas por `Compressor`.

Para la descripción general de los espacios de trabajo orientada al usuario y las capturas de pantalla, consulte [`docs/macos.md`](../docs/es/macos.md). Para la auditoría de portabilidad framework por framework y el registro arquitectónico, consulte [`docs/project/MAD_MACOS.md`](../docs/project/MAD_MACOS.md).

## Instalar una versión precompilada

```sh
brew install --cask mthomason/tap/mad-designer
```

O descargue [**MAD-Designer-macOS.dmg**](https://github.com/mthomason/MAD/releases/download/v9.1.0-macos/MAD-Designer-macOS.dmg) / [**MAD-Designer-macOS.zip**](https://github.com/mthomason/MAD/releases/download/v9.1.0-macos/MAD-Designer-macOS.zip) de la [versión `v9.1.0-macos`](https://github.com/mthomason/MAD/releases/tag/v9.1.0-macos).

## Compilar y ejecutar desde el código fuente

```sh
./Mac/build.sh                     # build 12 macOS frameworks + Mac/build/MAD Designer.app
./Mac/build.sh --no-frameworks     # rebuild only MAD Designer.app (fast iteration)
./Mac/build.sh --smoke-test        # build and run the end-to-end macOS smoke suite
./Mac/build.sh --package           # create Mac/build/MAD-Designer-macOS.zip and .dmg
```

También puede compilar, ejecutar y depurar la aplicación directamente en Xcode abriendo `Reports.xcworkspace`, seleccionando el scheme compartido **`MAD Designer Mac`** y eligiendo el destino **My Mac**.

## Estructura

* `Mac/Source/` — aplicación `AppKit`, arquitectura `NSDocument` y los tres espacios de trabajo:
  * `MADMacAppDelegate.{h,m}` — ciclo de vida de la aplicación, registro de drivers y convertidores, y barra de menús principal (`MAD Designer`, `File`, `Edit`, `View`, `Report`, `Window`, `Help`).
  * `MADMacAboutWindowController.{h,m}` — ventana nativa **About MAD Designer** (`Overview`, `License & Notice` y `Acknowledgements`, con barra lateral de componentes y textos de licencias de terceros incluidos).
  * `MADMacDocumentController.{h,m}` — subclase de `NSDocumentController` que configura el panel de apertura estándar con filtros `UTType` de `.mad` (`com.everydayapps.productivity.mad` y `com.thomason.report.mad`) y un botón principal **New Document**.
  * `MADMacDocument.{h,m}` — envoltorio `NSDocument` sobre `MADHeadlessDocument`, `MADDesignerLayout` (`NSUndoManager`), `MADSectionsLayout`, actualización asíncrona (`MADOperationQueue`) y exportación.
  * `MADMacWindowController.{h,m}` — ventana principal del documento con el control segmentado **Workspace** centrado (`MAD Query`, `MAD Designer`, `MAD Viewer`).
  * `MADMacConnectionWindowController.{h,m}` — asistente de conexión a base de datos e importación de esquema compatible con SQLite, MySQL, Microsoft SQL Server y PostgreSQL, con almacenamiento de credenciales en `MADKeyChain`.
  * `MADMacQueryViewController.{h,m}` — espacio de trabajo **MAD Query** con el lienzo visual de tablas y joins (`MADMacQueryCanvasView`, `MADMacQueryTableCardView`, `MADMacQueryLinksOverlayView`), paneles emergentes de filtros y agrupaciones, y el editor de SQL Query a todo el ancho (`MADSQLParser` / `MADSQLQueryCompiler`).
  * `MADMacDesignerViewController.{h,m}` y `MADMacDesignerCanvasView.{h,m}` — espacio de trabajo **MAD Designer** con la paleta de elementos, el minimapa interactivo de página y secciones (`MADMacDesignerMinimapView`), el esquema Report Bands, la fuente de arrastre Query Fields, el lienzo de diseño ampliable y con reglas, y el inspector derecho de dos tarjetas.
  * `MADMacViewerViewController.{h,m}` — espacio de trabajo **MAD Viewer** con selección de tamaño de papel (`MTPaper`), actualización, zoom y navegación de páginas, renderizado enmarcado en `PDFView`, barra de estado, impresión con `NSPrintOperation` y exportación en 7 formatos (`PDF`, `HTML`, `HTML Flow`, `CSV`, `JSON`, `JSON Report`, `Plain Text`).
* `Mac/Resources/Info.plist` — metadatos del bundle y declaraciones de tipo de documento / UTI de `.mad`.
* `Mac/Tests/MADMacSmokeTest.m` — ejecutable de verificación integral que ejercita la estructura del bundle, la importación de esquema, el diseño visual de consultas, la entrada de SQL, las mutaciones del lienzo, el minimapa y el inspector del diseñador, deshacer/rehacer, la actualización de datos y los siete formatos de exportación.
