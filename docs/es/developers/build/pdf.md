---
layout: default
title: "El escritor de PDF headless"
description: "La pila de Cairo y FreeType, el mapeo de fuentes y la exportación PDF determinista."
lang: es-419
---

# El escritor de PDF headless — el cuerpo Cairo + FreeType

Esta página registra el escritor de PDF headless: la pila de Cairo y FreeType, la política de mapeo de fuentes, el modo determinista y la prueba de aceptación contra el oráculo json-report.

*Escrito en la fecha original; los hechos del estado actual se conciliaron el 2026-11-22.*

**Estado (2026-11-20): implementado, en Linux y Windows, y en verde.** `mad export
--format pdf` y el `export` de `mad serve` escriben un PDF en ambos motores headless;
el cuerpo Apple de `MADReportExporterPDF` no cambia y sigue escribiendo la misma
muestra London de 43,177 bytes, 5 páginas, `sha256 3eb2f1c4…` bajo `--deterministic`.
Las secciones siguientes son el registro entregado; la historia de decisiones que llevó aquí
(estado, pilas candidatas, preguntas abiertas) se conserva al final.

## Qué es

La brecha que esto cierra siempre fue solo la escritura. `MADReportPageBuilder` prepara el
documento y recorre las páginas; `html`, `html-flow` y `json-report` ya leen
ese recorrido y son idénticos byte a byte entre plataformas. El escritor de PDF toma las mismas
páginas recorridas y las dibuja:

* `MADReportExporterPDFCairo` (`MAD/Source/MADReportExporterPDFCairo.m`) es el
  cuerpo no-Apple de `MADReportExporterPDF`. En Apple el exportador conserva su ruta de Core
  Graphics; fuera de Apple el mismo `exportDocument:toURL:options:error:` entrega el
  documento aquí.
* El escritor prepara el documento exactamente como el cuerpo Apple
  (`+MADReportPageBuilder prepareDocumentForRender:`), crea una superficie PDF Cairo
  en los límites de la página, y por cada página recorrida dibuja el lienzo blanco, el texto
  de cada línea en su marco, cada imagen y las decoraciones de texto.
* `+isAvailable` responde YES en cada plataforma y `+unavailableReason` es nil.
  Un paquete de fuentes faltante es un error de exportación con su propio mensaje, no una sustitución
  silenciosa.

## La pila y sus licencias

| Componente | Versión | Licencia | Rol |
|---|---|---|---|
| cairo | 1.18.6 (etiqueta git, commit fijado) | **MPL-1.1** (la opción MPL) | la superficie PDF y el dibujo |
| pixman | 0.46.4 (etiqueta git, commit fijado) | MIT | el núcleo ráster de cairo |
| FreeType | 2.15.0 | **FTL** | avances de glifos, kerning y contornos |
| Liberation Sans/Serif/Mono | 2.1.5 | **SIL OFL 1.1** | las caras sustitutas |

Sin Pango: el recorrido ya resuelve el marco, texto, fuente, tamaño, rasgos
y alineación de cada línea, y el ancho del marco es el único límite de ajuste que hay
(`NSLineBreakByTruncatingTail`). Lo que queda son avances y kerning, que
FreeType suministra directamente. cairo se compila solo con la superficie PDF — FreeType
y zlib dentro; fontconfig, Pango/glib, Xlib/XCB, Quartz y los backends de imagen
distintos de PNG fuera — así que no atrae nada más allá de la tabla anterior (zlib y
libpng ya estaban allí para la pila de códigos de barras).

Los textos están en `ThirdParty/Licenses/` (`cairo-MPL-1.1.txt`,
`pixman-MIT.txt`, `freetype-FTL.txt`, `liberation-OFL-1.1.txt`) y el registro
es `THIRD_PARTY_LICENSES.md` §3.5, §9 (imagen Linux) y §10 (motor Windows).
Ninguna de las cuatro añade una obligación de relink, así que la oferta escrita en
`ThirdParty/Licenses/README.md` no cambia. La ventana About de Windows lista
las cuatro desde `WindowsLicenseRegistry`.

## El mapeo de fuentes

Los documentos nombran fuentes de Apple; el paquete lleva Liberation, así que un nombre se mapea a
una familia y luego a una cara por las banderas de negrita y cursiva del elemento (y por cualquier
peso o inclinación que el nombre mismo declare, p. ej. `HelveticaNeue-Bold`):

| Fuente del documento | Sustituta | Notas |
|---|---|---|
| Helvetica Neue, Helvetica, Arial, Verdana, Tahoma, Trebuchet MS, Calibri, system | Liberation Sans | la gemela métrica de Arial, así que las líneas Helvetica/Arial están cerca; **Verdana es más ancha que Liberation Sans**, así que una línea Verdana es más estrecha que la de Core Graphics y puede truncarse antes |
| Courier, Courier New, Menlo, Consolas | Liberation Mono | la gemela métrica de Courier New |
| Times New Roman, Times, Georgia, Palatino, Baskerville, Garamond | Liberation Serif | la gemela métrica de Times New Roman; **Georgia es más ancha que Liberation Serif** |
| cualquier otra | Liberation Sans | el respaldo propio del renderizador es la fuente del sistema, que el motor headless no tiene |

El peso y la inclinación eligen la cara (`Regular`, `Bold`, `Italic`, `BoldItalic`);
el subrayado y el tachado se dibujan como rectángulos rellenos debajo/a través del
tramo medido, usando las métricas de subrayado PostScript de la cara. La alineación es la del
estilo (`left`, `center`, `right`; justificado y natural dibujan a la izquierda, igual que el
facsímil HTML). Un tramo más ancho que su marco se corta y termina con `…`, la
regla de cola truncada del renderizador.

**El residual son las métricas de las sustitutas.** La página, el marco de cada línea, el
texto resuelto de cada línea, su mapeo de familia de fuente, tamaño, peso, inclinación y alineación
son los del recorrido y son exactos. El ancho de una línea dentro de su marco es el de la
cara sustituta, así que una línea se dibuja un poco más ancha o más estrecha que la del Mac —
más visiblemente para Verdana y Georgia, cuyas caras reales no son métricamente compatibles
con nada del paquete. Esta es una diferencia visual, no estructural;
la prueba de oráculo compara texto y marcos, no extensiones de glifos.

## Determinismo

`MADReportExportOptionsDeterministic` fija las dos fechas que Cairo tomaría de otro modo
del reloj (`CAIRO_PDF_METADATA_CREATE_DATE` / `_MOD_DATE`) al mismo
instante que el cuerpo Apple fija en su tráiler, `2001-01-12T00:00:00Z` (la época
PDF). Cairo no escribe `/ID` en el tráiler, y su numeración de objetos, etiquetas de subconjunto
de fuentes, compresión y árboles de páginas son deterministas, así que dos exportaciones de un
informe sin cambios son los mismos bytes. La prueba lo demuestra.

Hubo que eliminar un peligro del lado del escritor para mantenerlo cierto: cairo cachea sus
caras de fuente y fuentes escaladas por el puntero `FT_Face`, así que un escritor que abría
y liberaba un conjunto de caras por exportación podía recibir una entrada de caché obsoleta cuando
el asignador reutilizaba una dirección, y el flujo de contenido a veces cambiaba
de `Tj` a desplazamientos `TJ` por glifo. Las caras ahora son
estáticas de carga única en todo el proceso, y las exportaciones se serializan bajo un bloqueo recursivo mientras se
comparten.

Entre plataformas no se pide que los dos escritores coincidan byte a byte, pero la
salida Cairo del fixture de London tiene el mismo tamaño en Linux y Windows y difiere en 44
bytes solo — los prefijos de subconjunto de fuentes que genera cairo (hashea los glifos como
`unsigned long`, 8 bytes en Linux y 4 en Windows).  El texto, la geometría y la estructura de página
son idénticos.

La superficie está restringida a **PDF 1.4**: una tabla de referencias cruzadas clásica y
objetos simples. El 1.7 predeterminado de Cairo escribe flujos de objetos y de referencias cruzadas,
que no es más fácil de dibujar y es más difícil de leer de vuelta; 1.4 también es la base de lectores
más amplia. Una consecuencia: la API PDF de Cairo no tiene TrimBox, así que el MediaBox de la página
es US Letter y el contenido se dibuja dentro del mismo recorte de 1pt que usa el recorrido
(`[1, 1, 610, 790]`); el recorte es estructural en los marcos, no una caja PDF.

## El dibujo

Por cada página, en el espacio de usuario PDF de cairo (origen arriba a la izquierda, y hacia abajo; cairo
escribe el volteo `1 0 0 -1 0 H cm` él mismo, así que los marcos del recorrido pasan
sin cambios):

* la caja de recorte blanca, como hace el `drawWhiteCanvas:pageRect:` del renderizador Apple;
* cada línea de texto: la cara y el tamaño de `MADReportLineStyle`, el texto resuelto
  de la línea, los glifos colocados con los avances y el kerning de FreeType al
  tamaño de la línea (`FT_KERNING_UNFITTED`, así que la formación depende solo de la cara y el
  tamaño), en el borde izquierdo (o centrado/derecho) del marco y su línea base;
* cada imagen: el PNG almacenado de un elemento de imagen o el símbolo de un código de barras
  (`MADReportLineRepresentation -imageData`, renderizado de forma perezosa), ajustado por aspecto a
  el marco como lo ajusta el facsímil HTML (`object-fit: contain`), decodificado
  a través del lector PNG de cairo;
* las decoraciones: subrayado y tachado como rectángulos rellenos;
* `cairo_show_page` (y el relleno blanco) por página.

El recorrido de páginas es una transacción de lectura por página, como en todos lados; las imágenes se
leen después de que se cierra y no cuestan nada para un documento sin ellas.

## La prueba de aceptación

`Linux/Tests/MADPDFExportTests.m` (y `Windows/Engine/Tests/`) abre el fixture London,
añade un código de barras y una imagen, actualiza y exporta. Lee el PDF
de vuelta con un pequeño lector PDF 1.4 en la prueba (árbol de páginas, MediaBox, flujos de contenido,
mapas ToUnicode de fuentes) y lo compara con el `json-report` para el mismo
documento — el oráculo en el que ambas plataformas coinciden byte a byte:

* el recuento de páginas y el MediaBox US Letter de cada página;
* el marco de cada línea recorrida dentro del recorte de 1pt;
* el texto de cada línea de texto, en el orden del recorrido, página por página (con el
  punto suspensivo de cola truncada permitido donde el marco es más estrecho que el texto);
* el código de barras y la imagen como XObjects de imagen, no texto;
* dos exportaciones deterministas idénticas byte a byte, con la fecha fijada; una exportación ordinaria
  tomando la fecha del reloj.

`MADReportExporterTests` también exporta el fixture London simple y comprueba cinco
páginas, el recuento de páginas del recorrido. La fijación de bytes de Apple no es una prueba headless: la
suite Apple sigue afirmando la exportación de 43,177 bytes / `3eb2f1c4…`, y el
cuerpo `#if __APPLE__` no se tocó.

## Compilarlo

* **Linux** — `Linux/libraries.conf` fija pixman, FreeType, cairo y el
  tarball de Liberation; `Linux/lib/libraries.sh` tiene `build_pixman` (meson),
  `build_freetype` (autoconf, solo núcleo), `build_cairo` (meson, la superficie PDF)
  y `build_liberation` (las doce caras en
  `${PREFIX}/share/mad/fonts`). La imagen las instala en `/usr/local`; la
  etapa de tiempo de ejecución copia `/usr/local/share/mad` para las fuentes. El `toolchain-base` del Dockerfile
  necesita `meson` y `ninja-build` (el sistema de compilación de cairo y pixman) y `xz-utils`
  (la fijación de FreeType es `.tar.xz`).
* **Windows** — `Windows/Engine/build.ps1` compila FreeType con su CMake, pixman
  y cairo con Meson bajo el entorno MSVC (cairo con su backend DWrite,
  que el código win32 de cairo requiere para enlazar) (el shim de pkg-config que la
  compilación de libpq ya necesitaba encuentra las fijaciones locales a través de archivos `.pc` generados),
  enlaza los tres `.lib` estáticos en `mad.exe`, y copia las caras
  Liberation en `Build\fonts`. El escritor busca
  `<exe>/fonts`, `<exe>/../fonts`, `<exe>/../share/mad/fonts`,
  `/usr/local/share/mad/fonts`, `/usr/share/mad/fonts`,
  `/usr/local/share/fonts/liberation`, `/usr/share/fonts/truetype/liberation`
  y una anulación `MAD_FONTS_DIR`.

Las fuentes son archivos de datos, no código: un paquete de Windows debe enviar
`Windows/Engine/build/fonts` junto a `mad.exe`, y la imagen Linux ya
las lleva en `/usr/local/share/mad/fonts`.

## El cuerpo de Apple no cambia

La ruta `#if __APPLE__` de `MADReportExporterPDF` — Core Graphics,
`MADPrintPageRenderer`, la fijación de metadatos — no se toca. El objetivo Apple
no enlaza Cairo, y la fuente del nuevo escritor no está en su objetivo de Xcode. Los
comandos de compilación de Apple para el registro:

	xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
		-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild build -workspace Reports.xcworkspace -scheme 'MAD Designer' \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
		-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci

(No se ejecutan en la estación de trabajo de Windows — no hay Xcode allí; los
archivos Apple que toca este incremento son los brazos no-Apple del exportador y sus
comentarios.)

## Límites deliberados

* **Paridad estructural, no de bytes** — el escritor de Core Graphics no se puede reproducir.
  El oráculo es el recorrido (`json-report`/`html`), no el PDF de Apple.
* **Sin TrimBox** — la API PDF de cairo no tiene ninguno; el contenido está dentro del recorte.
* **Texto latino, de izquierda a derecha** — la colocación de glifos es avances de FreeType + la
  tabla `kern`, no un motor de formación (sin HarfBuzz/Pango): sin ligaduras, sin
  composición de marcas combinadas, sin reordenamiento bidireccional. Los campos y
  etiquetas de los documentos son latinos; un documento que no lo sea dibujaría el glifo propio de cada punto de código
  en orden lógico.
* **Métricas sustitutas** — véase el residual arriba (Verdana y Georgia las brechas
  más anchas).
* **El selector de formatos del Windows WPF Viewer** no lista PDF; `mad export
  --format pdf` y el `export` de `mad serve` sí, que es la superficie del cierre.
  Añadir la fila del selector es un cambio de interfaz con sus propios recursos de cadenas.

---

## El registro de decisiones anterior

Estas secciones se conservan para la historia de decisiones, no como instrucciones.

### Las pilas candidatas (MAD_LINUX.md §10.2)

| opción | licencia | qué aporta | qué cuesta |
|---|---|---|---|
| **Cairo + Pango** (+ FreeType/HarfBuzz) | LGPL-2.1/MPL-1.1, LGPL-2.1, FTL/GPLv2-dual, MIT | dibujo vectorial con una superficie PDF, y diseño de texto real | una nueva dependencia en la imagen y su trabajo de licencia/aviso |
| **libharu** | zlib | salida PDF, permisiva | solo PDF, sin motor de diseño |
| **Skia** | BSD-3 | la capacidad más cercana a CG + Core Text | una compilación C++ pesada |
| **emisor PDF escrito a mano** | ninguna | sin dependencia | tipografía aproximada, una segunda ruta de dibujo |

**Lo elegido (2026-11-20): Cairo + FreeType, sin Pango.** El recorrido proporciona
el diseño; solo quedan los avances de glifos y el kerning, y la tabla `kern` de FreeType
los suministra sin un motor de diseño. Pango habría añadido una dependencia (y
su árbol LGPL/glib) para un ajuste que nadie necesita.

### Las preguntas abiertas, respondidas

1. **Fuentes** — véase la tabla de mapeo arriba: Liberation Sans/Serif/Mono, elegidas
   por las familias métricamente compatibles, con los residuales de Verdana y Georgia
   registrados.
2. **Qué pila y licencia** — Cairo (MPL-1.1), pixman (MIT), FreeType (FTL),
   Liberation (OFL): todas permisivas o MPL, ninguna LGPL, sin obligación de relink.
3. **Dónde vive el escritor** — en `MAD`, como `MADReportExporterPDFCairo`, su propia
   unidad de traducción y encabezado oculto, compilado solo fuera de Apple. El objetivo Apple
   no lo enlaza.
4. **¿Se necesita PDF de servidor desatendido?** — sí: el verbo `export` de la CLI y
   el `export` de `serve` son la superficie, y un trabajo programado no tiene navegador.
