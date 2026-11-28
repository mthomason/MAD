---
layout: default
title: "Portabilidad y la aplicación nativa de macOS"
description: "La auditoría de portabilidad de frameworks y la arquitectura de la aplicación AppKit."
lang: es-419
---

# `MAD_MACOS.md` -- Frameworks multiplataforma y la aplicación nativa de macOS

Esta página registra la auditoría de frameworks multiplataforma y la arquitectura de la aplicación nativa de macOS. La guía para el usuario está en `/macos.html`.

*Escrito en la fecha original; los hechos del estado actual se conciliaron el 2026-11-22.*

Este documento registra la decisión de arquitectura, la auditoría de portabilidad framework por
framework, y el plan de migración e implementación por fases para hacer que los frameworks de MAD
sean genuinamente multiplataforma (`iphoneos`, `iphonesimulator`, `macosx` y Linux headless)
y construir el frontend nativo de macOS (`AppKit`) para **MAD Designer**.

---

## 1. Decisión: macOS nativo (`AppKit`) vs. Mac Catalyst

**Decisión:** Construir una **aplicación nativa de macOS (SDK `macosx`, `AppKit`)** sobre frameworks
multiplataforma compartidos (`MACOSX_DEPLOYMENT_TARGET = 12.0`, admitiendo cada Mac de Apple
Silicon y Macs Intel en Monterey o posterior). **Mac Catalyst se rechaza.**

### Por qué gana macOS nativo

| Dimensión | macOS nativo (`macosx` / `AppKit`) | Mac Catalyst (`maccatalyst` / `UIKit`) |
|---|---|---|
| **Bibliotecas estáticas C (`Compressor`)** | **Ya compiladas.** Los 10 paquetes `.xcframework` en `Compressor/library/` llevan slices universales `macosx` (`arm64` + `x86_64`, `-mmacosx-version-min=11.0`) verificados por `./Compressor/build.sh --verify --all --platforms ios,simulator,macosx`. | **Faltantes.** No existe ningún slice `maccatalyst` (`-target <arch>-apple-ios15.0-macabi`). El enlazador Mach-O rechaza enlazar archivos `MACOS` en binarios `MACCATALYST`; Catalyst requeriría añadir una cuarta plataforma a `Compressor` y recompilar las 10 bibliotecas C (`openssl`, `mariadb`, `postgres`, `freetds`, `libarchive`, `sqlite3`, `zint`, `libpng`, `bzip2`, `zlib`). |
| **Portabilidad del motor central** | **90% completa.** El port headless de Linux (`MAD_LINUX.md`) ya eliminó Core Data de `MAD.framework`, desacopló los controladores de base de datos (`MADDatabaseDriverRegistry`) y los exportadores de informes (`MADReportExporterRegistry`), e introdujo `MADHeadlessDocument`, `MADSQLQueryCompiler` y `MADDesignerLayout`. | El mismo motor, pero atado a `UIDocument` y a los ciclos de vida de tareas en segundo plano de iOS. |
| **Ergonomía de escritorio** | `NSDocument` / `NSDocumentController` nativos (doble clic en Finder, `Cmd+N`, `Cmd+O`, `Cmd+S`, `Cmd+Shift+S`, documentos recientes, restauración de ventanas, `NSUndoManager`), vistas divididas nativas, vistas de tabla/esquema nativas, `PDFView` / `WKWebView` nativos, y menús estándar de macOS. | `UIScrollView` con zoom anidado + secciones `UICollectionView`, barras de pestañas/navegación de iOS, ruedas `UIPickerView`, y navegador de documentos en sandbox de iOS (`MADExplorer`). Los Macs de Apple Silicon ya ejecutan la compilación de iPad mediante *Designed for iPad*. |
| **Distribución vía GitHub** | Paquete `.app` independiente y limpio empaquetado como `.dmg` y `.zip` descargables en GitHub Releases (`arm64` + `x86_64`). | Requiere un perfil de aprovisionamiento de Catalyst y derechos que no encajan con la ergonomía de distribución fuera del App Store. |

---

## 2. Auditoría de bibliotecas estáticas (`Compressor`)

Las diez bibliotecas C vendidas en `Compressor` compilan slices universales `macosx` (`arm64` + `x86_64`)
con `-mmacosx-version-min=11.0`:

| Biblioteca | Versión | `ios` (`arm64`) | `simulator` (`arm64` + `x86_64`) | `macosx` (`arm64` + `x86_64`) | Usada por |
|---|---|:---:|:---:|:---:|---|
| `sqlite3` | 3.53.3 | Sí | Sí | Sí | `MADSqlite3`, `MAD` |
| `zlib` | 1.3.2 | Sí | Sí | Sí | `MAD`, `MADMySQL`, `MADPostgres`, `MADBarcodes` |
| `openssl` | 3.5.9 | Sí | Sí | Sí | `MADTds`, `MADMySQL`, `MADPostgres` |
| `bzip2` | 1.0.8 | Sí | Sí | Sí | `MAD` |
| `libpng` | 1.6.59 | Sí | Sí | Sí | `MADBarcodes` |
| `libarchive` | 3.8.9 | Sí | Sí | Sí | `MAD` |
| `freetds` | 1.4.27 | Sí | Sí | Sí | `MADTds`, `MADTdsClient` |
| `mariadb` | 3.4.11 | Sí | Sí | Sí | `MADMySQL` |
| `postgres` | 17.11 | Sí | Sí | Sí | `MADPostgres` |
| `zint` | 2.16.0 | Sí | Sí | Sí | `MADBarcodes` |

Comando de verificación:

```sh
./Compressor/build.sh --verify --all --platforms ios,simulator,macosx
```

---

## 3. Auditoría multiplataforma framework por framework

Doce frameworks forman la pila multiplataforma (`iphoneos`, `iphonesimulator`, `macosx`,
más Linux para los doce frameworks headless):

1. **`MADFoundation`** (28 archivos `.m`):
   - `MADApplication.h`: proteger `<UIKit/UIApplication.h>` con `#if TARGET_OS_IPHONE`
     en lugar de `#if __APPLE__` (`MADApplication.m` ya tiene
     `#elif TARGET_OS_OSX #import <AppKit/NSApplication.h>`).
   - `MADURLFactory.m`: proteger `<UIKit/UIScreen.h>` con `#if TARGET_OS_IPHONE` y usar
     `NSScreen.mainScreen.backingScaleFactor > 1.0` en `TARGET_OS_OSX`.
   - `MADKeyChain.m`: usa `Security.framework`, que es nativo tanto en iOS como en macOS.
2. **`MADDataStructures`** (17 archivos `.m`):
   - Foundation puro + C++. Cero cambios de código necesarios.
3. **`MADFileManager`** (11 archivos `.m`):
   - Eliminar el `#import <MobileCoreServices/UTType.h>` sin usar en
     `MADMetaDataLocal.m:16` (`<UniformTypeIdentifiers/UTType.h>` ya está importado en
     la línea 17).
4. **`MADCocoaExtensions`** (17 archivos `.m`):
   - `CGGeometry+Extras.h`: proporcionar `UIEdgeInsets` (estructura de diseño compatible con
     `NSEdgeInsets` + `UIEdgeInsetsMake` / `UIEdgeInsetsZero` / `UIEdgeInsetsEqualToEdgeInsets`),
     `NSStringFromCGPoint` / `NSStringFromCGSize` / `NSStringFromCGRect`, y
     `NSValue (MADCGGeometryExtensions)` (`valueWithCGPoint:`, `CGPointValue`,
     `valueWithCGRect:`, `CGRectValue`, `valueWithCGSize:`, `CGSizeValue`) en
     `TARGET_OS_OSX`.
   - `MADColor.h` / `MADColor.m`: puentear `MADColor` a `NSColor` en `TARGET_OS_OSX` mientras
     se conserva `UIColor` en `TARGET_OS_IPHONE`.
   - Proteger las categorías `UIView`, `UIAlertController`, `UITextField` y `UIColor`
     exclusivas de iOS con `#if TARGET_OS_IPHONE`.
5. **`MADAPI`** (11 archivos `.m`):
   - 9 archivos centrales de base de datos, consulta y registro de controladores son Foundation puro.
   - Proteger `MADConnectionViewController` y `MADConnectionSQLGenericViewController`
     con `#if TARGET_OS_IPHONE`.
6. **`MADSqlite3`** (26 archivos `.m`):
   - Foundation puro + `sqlite3.xcframework`. Cero cambios de código necesarios.
7. **`MADTds`** (1 archivo `.m`):
   - Foundation puro + `freetds.xcframework` + `openssl.xcframework`. Cero cambios de código
     necesarios.
8. **`MADTdsClient`** (4 archivos `.m`):
   - `MADDatabaseSQLServer`, `MADTdsConnection` y `MADDataTypeSQLServer` son Foundation
     puro. Proteger `MADTdsConnectionViewController` con `#if TARGET_OS_IPHONE`.
9. **`MADMySQL`** (19 archivos `.m`):
   - 18 archivos de controlador son Foundation puro + `mariadb.xcframework`. Proteger
     `MADMySQLConnectionViewController` con `#if TARGET_OS_IPHONE`.
10. **`MADPostgres`** (5 archivos `.m`):
    - 4 archivos de controlador son Foundation puro + `postgres.xcframework`. Proteger
      `MADPostgresConnectionViewController` con `#if TARGET_OS_IPHONE`.
11. **`MADBarcodes`** (70 archivos `.m`):
    - 67 clases de simbología son Foundation puro + `zint.xcframework`.
    - `MADBarcode`, `MADBarcodeCache` y `MADBarcodeView`: puentear `UIImage` / `NSImage`
      y `UIView` / `NSView` en `TARGET_OS_OSX` sobre la tubería existente de `CGImageRef`
      `MADBarcodeImageFromZintBitmap`.
12. **`MAD`** (199 archivos `.m`):
    - Reemplazar `#if __APPLE__` con `#if TARGET_OS_IPHONE` y `#elif TARGET_OS_OSX`
      con puentes AppKit en los 9 archivos compartidos de modelo/renderizado (`RptqObject.m`,
      `RptqDocumentElementImage+Extras.m`, `RptqDocument+Extras.m`,
      `RptqDocumentSection+Extras.m`, `RptqDocumentElement+Extras.m`,
      `MADPrintPageElement.m`, `MADElementStylizedText.m`, `MADFonts.m` y
      `MADReportExporterPDF.m`).
    - En `MADReportExporterPDF.m`, renderizar PDF paginados en `TARGET_OS_OSX` usando
      `CGPDFContextCreateWithURL` / `CGPDFConsumerCreateWithCFData` y
      `NSGraphicsContext` (`+graphicsContextWithCGContext:flipped:YES`), para que
      `MADPrintPageRenderer` y `MADPrintPageElement` dibujen de forma nativa en macOS.
    - Proteger los 22 archivos `UIDocument` (`MADocument`), `UIView` y
      `UICollectionViewLayout` exclusivos de iOS con `#if TARGET_OS_IPHONE`.

`MADExplorer` sigue siendo solo de iOS (macOS usa `NSDocumentController`, Finder y `NSOpenPanel` con un botón principal **New Document**). `MADFeedback` y `Scrimpter` siguen sin usar según
`AGENTS.md`.

---

## 4. Plan de implementación por fases

### Fase 1: Correcciones de errores y habilitación de frameworks multiplataforma (completada)

1. **Se corrigieron 6 defectos surgidos durante la auditoría y el port de macOS** y se archivaron de
   `docs/project/registers/BUGS.md` a `docs/project/registers/BUGS_FIXED.md` con pruebas unitarias:
   - `MADKeyChain` (`MADFoundation/Source/MADKeyChain.m`): se dejó de solicitar
     `kSecReturnData : @YES` (y de filtrar el `CFDataRef` devuelto) en
     `+credentialsExist:`, `+saveToken:forKey:withDescription:`, `+deleteKey:` y
     `+deleteSavedPasswordForKey:error:`.
   - `MADURLFactory` (`MADFoundation/Source/MADURLFactory.m`): se protegió
     `+newURLForLocalApplicationSupportDirectory` cuando `[NSBundle mainBundle].bundleIdentifier`
     es `nil` (recurriendo a `[MADApplication groupIdentifier]`), y se protegió
     `containerURLForSecurityApplicationGroupIdentifier:` con
     `#if defined(__APPLE__) && TARGET_OS_IPHONE` para que los procesos de macOS sin derechos usen
     directorios estándar por usuario en lugar de disparar avisos de TCC en
     `~/Library/Group Containers/`.
   - `MADDataTable` (`MADFoundation/Source/MADDataTable.m`): se protegió
     `NSDataWritingFileProtectionCompleteUnlessOpen` con
     `#if defined(__APPLE__) && TARGET_OS_IPHONE` para que las escrituras de caché de macOS sin derechos tengan éxito.
   - `MADDatabaseSqlite3` (`MADSqlite3/Source/MADDatabaseSqlite3.m`): se protegió
     `[dataTable endBulkInsert]` con `if (rowCounter > 0)` para que las consultas `SELECT` de cero filas
     no ejecuten `COMMIT TRANSACTION` cuando nunca se llamó a
     `[dataTable beginBulkInsert]`.
   - `MADBarcode` (`MADBarcodes/MADBarcodes/MADBarcodes/MADBarcode.m`): se corrigió
     `-drawInRect:` que duplicaba `rect.origin` cuando `self.center == YES`.
   - `MADDesignerLayout` (`MAD/Source/MADDesignerLayout.m`): se conservó el valor previo propio de cada elemento
     seleccionado en un diccionario al registrar acciones de deshacer en todos
     los métodos de actualización masiva (`setFontsize:`, `setFontname:`, `setVerticalAlignment:`,
     `setHorizontalAlignment:`, `setSizeWidth:`, `setSizeHeight:`, `setMargin*`,
     `setPadding*`, `setBorder*`).
2. **Se habilitó `macosx` en los 12 proyectos de Xcode de frameworks:**
   - Establecer `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx"` y
     `MACOSX_DEPLOYMENT_TARGET = 12.0`.
   - Se añadió `platformFilters = (ios, maccatalyst, );` en las referencias de `UIKit.framework` y
     se enlazó `AppKit.framework` con `platformFilters = (macos, );` donde era necesario.
   - Se actualizaron las fases de compilación `Ensure Libraries` para pasar
     `--platforms ios,simulator,macosx`.
3. **Se verificaron los 12 frameworks en macOS nativo (`-destination 'platform=macOS,arch=arm64'`):**
   - `MADFoundation`: **199 pruebas pasadas, 0 fallos**
   - `MADDataStructures`: **72 pruebas pasadas, 0 fallos**
   - `MADCocoaExtensions`: **80 pruebas pasadas, 0 fallos**
   - `MADFileManager`: **85 pruebas pasadas, 0 fallos**
   - `MADAPI`: **106 pruebas pasadas, 0 fallos**
   - `MADSqlite3`: **118 pruebas pasadas (5 benchmarks omitidos), 0 fallos**
   - `MADTds`: **Compilado limpiamente para `macosx`**
   - `MADTdsClient`: **77 pruebas pasadas (incluida la suite en vivo de SQL Server), 0 fallos**
   - `MADMySQL`: **Todas las pruebas sin conexión y en vivo de MariaDB/MySQL pasadas, 0 fallos**
   - `MADPostgres`: **31 pruebas pasadas (incluida la suite en vivo de PostgreSQL), 0 fallos**
   - `MADBarcodes`: **30 pruebas pasadas, 0 fallos**
   - `MAD`: **650 pruebas pasadas, 0 fallos**

### Fase 2: Importación de esquema multiplataforma y capa `NSDocument` (completada)

1. **Creación de documentos e importación de esquema multiplataforma (`MADHeadlessDocument`):**
   - Se añadió `+createDocumentAtURL:withDatabaseConnection:credentials:error:` en
     `MADHeadlessDocument` (`MAD/Source/MADHeadlessDocument.h`, `.m`), que se conecta a
     cualquier controlador registrado (`SQLite3`, `MySQL`, `SQL Server`, `PostgreSQL`), importa todas
     las tablas de la base de datos (`-getTablesFromConnection:error:`) y columnas
     (`-fieldsForTable:connection:error:`) en `RptqDatabaseSchemaTable` /
     `RptqDatabaseSchemaField`, inicializa las secciones de informe estándar (`Report Header`,
     `Page Header`, `Report Detail`, `Page Footer`, `Report Footer`), y escribe el
     contenedor portable `.mad`.
2. **`MADMacDocument` (subclase de `NSDocument` en `Mac/Source/MADMacDocument.m`):**
   - Envuelve `MADHeadlessDocument` (con conversión automática de `.mad` heredados de Core Data mediante
     `MADStoreConverter` cuando es necesario), cumple `MADocumentDesignerProtocol` para que
     `MADDesignerLayout` registre deshacer/rehacer directamente en `NSDocument.undoManager`, y
     admite `readFromURL:ofType:error:`,
     `writeToURL:ofType:forSaveOperation:originalContentsURL:error:` y
     `refreshWithCredentials:maxRows:completion:` asíncrono.

### Fase 3: Aplicación nativa de macOS (`Mac/`) (completada)

Construida bajo `Mac/` (`Mac/Source/`, `Mac/Resources/`, `Mac/Tests/`, `Mac/build.sh`) e integrada en `MAD Designer.xcodeproj` mediante el objetivo **`MAD Designer Mac`** y el esquema compartido:

1. **Ciclo de vida de la aplicación, ventana About y controlador de documentos (`MADMacAppDelegate`, `MADMacAboutWindowController` y `MADMacDocumentController`):**
   - Registra los cuatro controladores de base de datos y `MADStoreLegacyConverter`, construye el menú principal nativo de macOS (`MAD Designer`, `File`, `Edit` con `Undo`/`Redo`, `View` con cambio de espacio de trabajo `Cmd+1`/`Cmd+2`/`Cmd+3`, `Report` con actualización `Cmd+R`, `Window`, `Help`), y presenta el `NSOpenPanel` estándar al iniciar cuando no hay un documento abierto.
   - `MADMacAboutWindowController` presenta la ventana nativa **About MAD Designer** (elementos del menú `MAD Designer → About MAD Designer` y `Help`) con la versión/compilación del motor (`MADMeta.plist`) y la versión de la aplicación macOS (`CFBundleShortVersionString`) mostradas como valores distintos, aviso de copyright y de marca/arte reservados, acción **Source Code on GitHub**, y tres secciones con pestañas: **Overview** (qué es MAD, el flujo de trabajo de informes de 4 pasos, y los controladores/bandas/exportadores admitidos), **License & Notice** (licencia MIT, `NOTICE`, y la oferta escrita de relink LGPL-3.0 para FreeTDS y MariaDB Connector/C), y **Acknowledgements** (barra lateral interactiva de los 16 componentes de código abierto de terceros emparejados con sus atribuciones y los 12 textos de licencia completos incluidos en `Contents/Resources/Licenses/`).
   - `MADMacDocumentController` configura `NSOpenPanel` con todos los identificadores `UTType` de `.mad` (`com.everydayapps.productivity.mad` y `com.thomason.report.mad`) para que los archivos `.mad` existentes nunca se atenúen, y coloca un botón principal **New Document** directamente en la barra inferior izquierda del panel Open.
2. **Asistente de conexión a base de datos e importación de esquema (`MADMacConnectionWindowController`):**
   - Admite **SQLite** (archivo `.sqlite3`/`.db` personalizado mediante `NSOpenPanel`), **MySQL**, **Microsoft SQL Server** y **PostgreSQL**, con **Test Connection**, almacenamiento de contraseña en `MADKeyChain`, y **Create Document…** (`NSSavePanel`).
3. **Ventana principal del documento (`MADMacWindowController`):**
   - Centra el control segmentado **Workspace** (**MAD Query**, **MAD Designer**, **MAD Viewer**) en la barra de herramientas de la ventana.
4. **Espacio de trabajo MAD Query (`MADMacQueryViewController`):**
   - Modos de espacio de trabajo **Query Designer** y **SQL Query** mutuamente exclusivos (alternados en
     la barra de encabezado del espacio de trabajo para que el diseño visual de consultas y la entrada manual de SQL nunca se
     muestren simultáneamente).
   - **Modo Query Designer**: Una lista **Database Tables** de `200px` a la izquierda (redimensionable por el usuario
     mediante `NSSplitViewDelegate` sin volver a su sitio, y mantenida a un ancho fijo cuando se
     redimensiona la ventana para que el lienzo visual se redimensione en su lugar) emparejada con un lienzo visual
     interactivo a la derecha (`MADMacQueryCanvasView`). Hacer doble clic en una tabla de esquema
     la añade a la consulta (poblando todas las filas `RptqQueryField`) y la muestra como una
     tarjeta de tabla flotante AppKit arrastrable y redimensionable (`MADMacQueryTableCardView` +
     `MADMacQueryFieldTableView`) con estilo de encabezados raíz/hijo topológicos (`MTGraph`),
     y arrastrar desde un campo de una tarjeta de tabla a un campo de otra crea un
     **Left Outer Join** predeterminado (`MADLinkTypeLeftOuterJoin`) dibujado mediante conectores Bezier y
     distintivos de tipo de unión (`MADMacQueryLinksOverlayView`, igual que el `MADConnectorView` del iPad).
     Hacer clic o clic derecho en un conector de unión visual abre un popover de inspector de unión o
     un menú contextual para cambiar el tipo de vínculo, invertir la dirección o eliminar el vínculo; los popovers de encabezado
     proporcionan **Filters (WHERE)**, **Groupings (GROUP BY)** y **Arrange Tables**.
   - **Modo SQL Query**: Editor de sentencias SQL a ancho completo que muestra el SQL generado o introducido
     y admite validación, compilación y aplicación (`MADSQLParser` +
     `MADSQLStatementResolver` + `MADSQLQueryCompiler`).
5. **Espacio de trabajo MAD Designer (`MADMacDesignerViewController` + `MADMacDesignerCanvasView` + `MADMacDesignerMinimapView`):**
   - **Barra de espacio de trabajo superior (altura `38pt`):** Proporciona elementos de paleta de símbolos SF
     en los que se puede hacer clic y arrastrar (**Label**, **Data Field**, **Aggregate**, **Barcode**,
     **Image**, **Line**), controles rápidos de alineación de múltiples elementos (`Left`, `Center`,
     `Right`, `Top`, `Middle`, `Bottom`), **Size to Fit**, alternadores **Grid** / **Snap** /
     **Rulers**, y un deslizador **Zoom** con restablecimiento a `100%` con un clic.
   - **Vista dividida de 3 paneles redimensionable por el usuario (`NSSplitViewDelegate`):** La barra lateral de navegación izquierda
     tiene `220pt` por defecto (`180–340pt`), el inspector derecho tiene `260pt` por defecto
     (`220–380pt`), y ambas barras laterales mantienen sus anchos a través de los redimensionamientos de ventana mientras
     preservan los ajustes del divisor del usuario.
   - **Barra lateral izquierda (minimapa + bandas + navegador de campos de consulta):**
     - **Minimapa interactivo de página y sección (`MADMacDesignerMinimapView`):** Dibuja
       bandas de informe proporcionales con franjas codificadas por color, bloques de elementos en miniatura en vivo,
       y un rectángulo de ventana gráfica azul; hacer clic o arrastrar salta a la banda y la selecciona.
     - **Esquema de bandas del informe:** Lista todas las secciones de informe y de grupo con recuentos de elementos,
       alturas e indicadores de salto de página; hacer doble clic alterna la visibilidad de la banda.
     - **Navegador de campos de consulta:** Lista filtrable (`NSSearchField`) de todas las columnas
       `RptqQueryField`; arrastrar un campo a cualquier banda de sección del lienzo (o hacer doble clic)
       inserta un `RptqDocumentElementLabelDataField` vinculado.
   - **Lienzo interactivo central (`MADMacDesignerCanvasView`):** Lienzo `NSView` volteado y con zoom,
     con reglas horizontales/verticales, márgenes de papel, bandas de sección codificadas por color,
     manijas de arrastre de altura de sección, guías de alineación inteligentes, ajuste a la cuadrícula, selección por
     lazo, multiselección con `Shift`+clic, manijas de redimensionado de 8 puntos, edición de etiquetas en línea con doble clic,
     colocación inteligente de elementos sin superposición
     (`-nextAvailableOriginInSection:forElementSize:`), y arrastrar y soltar entre secciones
     (`-moveElement:toSection:atOrigin:`) con resaltado en vivo de la banda de destino e integración total
     con `NSUndoManager`.
   - **Barra lateral del inspector derecho (claramente dividida y desplazable):**
     - **Tarjeta 1 (`1 · PAGE & SELECTED SECTION`):** Tamaño de papel, distintivo de banda seleccionada,
       altura de banda (`pt`) con botón **Fit Height**, **Section Visible**, y **Page Break
       After**.
     - **Divisor visual prominente + Sección 2 (`2 · SELECTED ELEMENT INSPECTOR`):**
       4 tarjetas de inspector agrupadas (**Element & Band Assignment** con popup de movimiento entre secciones,
       **Duplicate** y **Delete**; **Content & Data Binding** con texto estático,
       vinculación de campos de consulta, función y ámbito de agregado, formato de moneda y opciones de código de barras;
       **Typography & Appearance** con familia/tamaño de fuente, negrita/cursiva/subrayado/
       tachado, alineación horizontal/vertical y colores de texto/fondo; y
       **Position, Size & Box Model** con `X`, `Y`, `W`, `H` sincronizados en
       `rect.origin` y `dropPoint`, más bordes, relleno y margen).
6. **Espacio de trabajo MAD Viewer (`MADMacViewerViewController`):**
   - **Barra de herramientas superior del visor (altura `40pt`):** Popup **Page Size** (tipos de papel estándar `MTPaper`: `US Letter`, `US Legal`, `US Tabloid`, `A3`, `A4`, `A5`, `B4`, `B5`, `JIS B4`, `JIS B5`), **Refresh** (`Cmd+R`), controles de **Zoom** (`-`, `100%`, `+`), **Page Navigation** (`Previous`, `Page N of M`, `Next`), **Print…** (`Cmd+P` vía `NSPrintOperation`), y **Export…** (`Cmd+E`).
   - **Vista previa paginada enmarcada (`PDFView`):** Renderiza páginas PDF paginadas al tamaño de papel seleccionado desde la caché de tabla SQLite local (`MADDataTableFast`) con sombras de página y una barra de estado inferior (`statusBarView`) que muestra el recuento de páginas renderizadas, el recuento de filas en caché y las dimensiones del papel.
   - **Exportación multiformato (`NSSavePanel`):** Configura un popup de formato accesorio que admite los 7 exportadores registrados (`PDF`, `HTML`, `HTML Flow`, `CSV`, `JSON`, `JSON Report`, `Plain Text`) y actualiza dinámicamente la extensión de archivo permitida del panel de guardado.

### Fase 4: Compilación, verificación de humo y empaquetado de versión de GitHub (completada)

```sh
./Mac/build.sh --smoke-test --package
```

Produce:
- `Mac/build/MAD Designer.app` (paquete de aplicación nativa de macOS independiente con los 12
  frameworks y los modelos heredados Core Data `.momd` incrustados y firmados)
- `Mac/build/MAD-Designer-macOS.zip`
- `Mac/build/MAD-Designer-macOS.dmg`

La documentación pública para usuarios y desarrolladores de la aplicación nativa de macOS está publicada en [`docs/macos.md`](../../macos.md) (con capturas en `docs/assets/macos-native-mad-query.png` y `docs/assets/macos-native-mad-designer.png`) y en [`Mac/README.md`](https://github.com/mthomason/MAD/blob/master/Mac/README.md).

### Integración continua (completada)

`.github/workflows/macos.yml` se ejecuta en cada pull request y push a `master`.
Compila (y cachea) las bibliotecas estáticas de Compressor, luego ejecuta las
suites `MADBarcodes` y `MAD` en un simulador de iPhone descubierto en el
runner, compila el esquema `MAD Designer` de iOS, y ejecuta
`./Mac/build.sh --smoke-test`. La ventana About informa la versión del motor
(`MADMeta.plist`, `v9.0 (r4433)`) y la versión de la aplicación macOS
(`CFBundleShortVersionString`, `v0.7`) como valores distintos, coincidiendo con la
presentación posterior a la Fase 6f de la ventana About de Windows.

`macos-latest` es un runner arm64, y `Mac/build.sh` compila los frameworks para
`platform=macOS,arch=arm64`. La primera ejecución descarga y compila cada fuente
de terceros fijada para tres plataformas (aproximadamente 15–40 minutos); las ejecuciones posteriores
restauran `Compressor/library` desde la caché de Actions y el paso ensure es nulo.
La receta de freetds obtiene `config.guess`/`config.sub` de Savannah una vez con
sin reintentos, así que el flujo de trabajo siembra `Compressor/media` primero (véanse los comentarios
del flujo de trabajo). Un residual, no un fallo de compilación: el paso configure de libarchive encontró
el `libbz2.tbd` del SDK en lugar de la instalación de bzip2 de Compressor, porque
`BZIP2_LIBRARY` no es la pista que lee el `FindBZIP2` de CMake moderno; la biblioteca del SDK
está presente y la aplicación procesa el xcframework bzip2.
