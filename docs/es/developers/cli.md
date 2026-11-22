---
layout: default
title: "La herramienta de línea de comandos `mad`"
description: "Abrir, inspeccionar, consultar, actualizar y exportar documentos `.mad` sin una interfaz de usuario."
lang: es-419
---

# `mad` -- la interfaz de línea de comandos de MAD Designer

Esta página describe la herramienta de línea de comandos `mad`: la superficie de integración del motor y la forma más rápida de ejercitar un documento `.mad` sin la aplicación. Lee primero la especificación del formato si el contenedor y el almacén son nuevos para ti.

Este documento define una herramienta de línea de comandos que abre, inspecciona, actualiza y exporta
documentos `.mad` sin una interfaz de usuario.

Este registro se escribió cuando la capa de presentación de la aplicación de Apple era completamente UIKit, por lo que no podía ejecutarse como una aplicación nativa de macOS o Windows. Ahora existen las aplicaciones nativas de macOS (AppKit) y Windows (WPF); la CLI `mad` sigue siendo la ruta sin interfaz que ejecuta el mismo motor sin una UI. La ruta de datos -- abrir el documento, ejecutar la consulta, llenar la caché, renderizar el informe -- está casi por completo libre de UIKit (véase §4), y eso es lo que hace que la CLI sea portátil.

---

## 1. Alcance

**En alcance.** Un único binario, `mad`, que puede:

- abrir un documento `.mad` e informar qué contiene
- imprimir el esquema de base de datos contra el que se construyó el documento
- imprimir la consulta que define el documento, como SQL
- conectarse a la base de datos de origen, ejecutar la consulta y llenar la caché de filas
- exportar un informe renderizado

**Fuera de alcance, deliberadamente.** Cualquier cosa que edite un documento. La CLI lee y
ejecuta documentos; no los diseña. El análisis de argumentos, los verbos y los códigos
de salida son toda la superficie.

---

## 2. Por qué primero una CLI

| | CLI | Aplicación de Mac |
|---|---|---|
| Necesita un kit de herramientas de interfaz | no | AppKit (reescritura) o Catalyst (rechazado) |
| Necesita que los frameworks sean portables | **sí** | sí |
| Necesita que la caché de filas sea portable | **sí** | sí |
| Necesita que `.mad` esté definido | **sí** | sí |
| Entrega algo que pediste | sí | sí |
| Trabajo que se descarta si el formato cambia | ninguno | la interfaz |

Todo lo que la aplicación de Mac necesita para existir -- frameworks portables, un
formato de archivo definido, bibliotecas compiladas para más de una plataforma -- la CLI lo necesita
primero. Hacer primero el port de la interfaz sería la forma cara de descubrir los mismos
problemas. La aplicación de Mac sigue siendo una decisión separada, tomada más adelante, con los
frameworks ya portables.

---

## 3. Superficie de comandos

```
mad <command> [options] <document.mad>
```

### `mad inspect <doc.mad>`

Lee solo el contenedor. Sin conexión a la base de datos, sin Core Data.

```
$ mad inspect London.mad
London.mad
  format      v0 (bzip2 tar, no magic header)
  generator   MAD Designer
  version     1
  store       StoreContent/analyitics (SQLite 3.43.2, 126 pages)
  wal         present, 313152 bytes (not checkpointed)
  thumbnail   none
  elements    14 sections, 63 elements
```

Este es el verbo que demuestra que `MAD_FORMAT.md` §7 se ha implementado: debe funcionar
sobre una muestra v0. También es el verbo que hace visibles los peligros del formato -- H2
(el WAL sin checkpoint) se informa en lugar de sufrirse en silencio.

### `mad schema <doc.mad>`

Imprime el esquema de base de datos capturado en la definición del documento: el controlador, las
tablas ordenadas por nombre, y los campos de cada tabla con su tipo de presentación y una marca `pk`.
Lee la instantánea almacenada en el momento de la creación, así que no necesita credenciales ni
base de datos de origen. (El plan original aquí era emitir SQL `CREATE TABLE`; la
instantánea almacena la abstracción `MADDataType` en lugar de los nombres de tipo de cada dialecto
de origen, así que un `CREATE TABLE` fiel necesita una asignación por dialecto que no existe
todavía. El listado legible es lo que produce la herramienta hasta entonces.)

### `mad query <doc.mad>`

Imprime el SQL que genera la consulta del documento, sin ejecutarlo. Esta es la
función alrededor de la cual está construida la aplicación -- el usuario arma tablas, uniones y
filtros, y el software escribe el SQL -- así que exponerla es el primer verbo no trivial
natural.

```
$ mad query London.mad --format sql
SELECT ... FROM ... WHERE ...
```

### `mad refresh <doc.mad>`

Se conecta a la base de datos de origen, ejecuta la consulta y llena la caché de filas. Esta es la
ruta de datos, y es el verbo del que depende el resto.

```
$ mad refresh London.mad --credentials user:pass
refreshed 148,392 rows in 1.21 s (122,638 rows/s)
cache  ~/Library/Caches/MADDesigner/<id>/<tag>.maddb
```

Opciones: `--credentials`, `--host`, `--port`, `--database`, `--no-cache` (ejecutar
sin persistir), `--rows N` (detenerse después de N filas, para pruebas de humo).

`--rows` existe porque es lo que hace que el verbo sea comprobable en CI contra un servidor
en vivo sin extraer un millón de filas, y porque el benchmark en
`MADDataTableFastBenchmarkTests` ya demuestra que la ruta es medible a escala.

### `mad export <doc.mad>`

Renderiza el informe y lo escribe.

```
$ mad export London.mad --format pdf  --out London.pdf
$ mad export London.mad --format json --out -          # to the standard output
```

Los formatos son la costura de exportación (§5.3): cada uno es una clase registrada con
`MADReportExporterRegistry`, y el texto de uso nombra lo que tenga la compilación.

| formato | escribe | dónde se ejecuta |
|---|---|---|
| `pdf` | el informe renderizado (páginas, dibujado) | Apple: `UIPrintPageRenderer` de UIKit, Core Graphics; Linux explica por qué no |
| `html` | el informe renderizado como un archivo HTML, una caja de página por página, impreso desde un navegador | ambas plataformas |
| `html-flow` | el informe renderizado como HTML refluible, una tabla por sección | ambas plataformas |
| `text` | las filas como una tabla de ancho fijo | ambas plataformas |
| `csv` | las filas como CSV RFC 4180 | ambas plataformas |
| `json` | el esquema y las filas como JSON (§8.3) | ambas plataformas |
| `json-report` | `json` más las secciones del informe renderizado | ambas plataformas |

`--out` es opcional para los formatos de Foundation -- ausente, o `-`, escribe la salida
estándar -- y obligatorio para `pdf`. Los formatos de Foundation escriben los mismos bytes en Apple
y en Linux para el mismo documento (`Linux/README.md`; las exportaciones de ambas plataformas del
fixture de London se comparan como iguales por digest).

**El orden definido.** El orden de los grupos en la exportación forma parte de ese contrato, así que es un
orden definido, no el de la plataforma: las claves de texto se comparan sin distinguir mayúsculas, luego por
orden de punto de código sobre los bytes UTF-8. El plegado de mayúsculas es el plegado simple (uno a uno)
de mayúsculas de Unicode 17.0.0, mantenido como una tabla versionada (`MADStringOrderingTable` en
`MADFoundation/Source/NSString+Comparison.m`, generada a partir de las entradas de estado C/S de
`CaseFolding.txt` del UCD) -- ASCII y todos los pares Unicode que la tabla mapea se
pliegan; cualquier otra cosa, incluidos los diacríticos, se compara como su propio punto de código. Debido a que
el plegado lleva cada letra al rango de minúsculas, que sigue a cada byte de puntuación ASCII,
una clave que comienza con puntuación (`[1997] Black Light Syndrome`) se ordena antes que
una que comienza con palabra (`Core`) -- el mismo lugar donde SQLite `NOCASE` la coloca. UTF-8 preserva
el orden de puntos de código, así que la comparación de bytes es la comparación de puntos de código. Un
comparador (`-[NSString mad_orderedCompare:]` y su núcleo C
`MADStringOrderedCompareUTF8`) impulsa los tres sitios: la colación `LSASC` de la caché,
los descriptores de ordenación en memoria (`MADDataTypeSelectorForSorting`), y la comparación
de límites de grupo del formateador de informes. El orden es determinista entre plataformas,
versiones de sistema operativo y configuraciones regionales; cambió del orden localizado el 2026-10-25, así que
las exportaciones anteriores a esa fecha no se comparan como iguales con las posteriores.

**`json-report`** (`MAD_LINUX.md` §10.1, §9 Fase E) es el mismo esquema con el
informe renderizado como un miembro `report`: páginas, las secciones de cada página en orden de dibujo (tipo,
nivel de grupo, visibilidad), las filas de cada sección, y el tipo de elemento, marco y texto resuelto
de cada línea. Es lo que leen las pruebas y un renderizador, y es la propia estructura del renderizador
-- el recorrido de páginas sin nada dibujado -- así que no puede desviarse de lo que muestra un PDF.
El marco es donde se asienta la línea **en la página** (el marco del elemento desplazado por
su sección), que es lo que necesita un renderizador o un navegador. La mitad de renderizado se compila
en Linux ahora, así que este formato se ejecuta en ambas plataformas.

**`html`** es el artefacto con forma de página que imprime un navegador: una caja de página CSS por cada página
recorrida, cada elemento posicionado de forma absoluta en su marco, su texto resuelto en la
fuente, tamaño, grosor, inclinación, decoración y alineación propios del elemento. La regla de salto de línea
es la del renderizador (`NSLineBreakByTruncatingTail` -> `white-space: pre; overflow:
hidden; text-overflow: ellipsis`). Es un archivo UTF-8 con un bloque de estilo incrustado
y sin script. **`html-flow`** es el mismo informe con las páginas eliminadas: un `<section>`
por sección de informe, un `<table>` por sección, un `<td>` por elemento, el mobiliario de página
emitido una vez, y una clase generada por cada estilo de elemento distinto. Es una vista de lectura;
`json` es el contrato de datos. Ninguno lleva colores (las columnas de color del almacén no tienen
lector en ninguna plataforma hoy) ni imágenes en Linux (la ruta de Apple las dibuja desde
`UIImage`; una exportación de Linux coloca la caja vacía).

El renderizado a PDF pasa por `MADPrintPageRenderer`; el contenedor de la hoja de compartir
`MADActivityItemProviderPdf` es su otro llamador, y `MADActivityItemProviderDelegate.h`
es el protocolo con el que habla. Los tres viven en el framework `MAD` en lugar de en la
aplicación. Lo que PDF no es, es **headless**: es `UIPrintPageRenderer` de UIKit, que es por lo que
es el único formato aún implementado del lado de la CLI (véase §5.3).

### `mad write <doc.mad> --out <copy.mad>`

Escribe el documento como un `.mad` -- una *copia*: el directorio interno en el que se
leyó el documento, archivado de nuevo con la cabecera v1.  No edita el documento que leyó,
y la CLI sigue sin diseñar documentos (§1); para lo que sirve este verbo es para el
requisito de identidad de bytes -- el mismo documento escrito en dos plataformas debe ser el
mismo archivo -- y el fixture de ida y vuelta de §6.1, que necesita un escritor que un script pueda ejecutar.

```
$ mad write London.portable.mad --out copy.mad --reproducible
wrote /tmp/copy.mad (16261 bytes, reproducible)
```

`--reproducible` fija lo que el reloj y el sistema de archivos estamparían de otro modo en el
archivo: una hora de modificación fija (2001-01-12T00:00:00Z, el instante al que la exportación PDF
fija sus fechas), propietario y grupo 0, y un recorrido de miembros ordenado
(`MADArchiveManager.reproducible`).  Sin él se escribe un guardado ordinario, con los
metadatos reales de los miembros.  El documento se abre de forma headless en ambas plataformas
(`MADHeadlessDocument`), así que los dos lados de la comparación ejecutan el mismo escritor, y
el mismo documento escribe los mismos bytes allí (16,261 bytes en el fixture de London,
`Linux/README.md`).

### Opciones globales

| Opción | Significado |
|---|---|
| `--verbose` | registrar la ruta de datos en cada etapa |
| `--quiet` | suprimir todo excepto el resultado |
| `--credentials user:pass` | credenciales de la base de datos de origen; si no, el llavero |
| `--host <name>` | sustitución del host de la base de datos de origen (refresh, export) |
| `--port <n>` | sustitución del puerto de la base de datos de origen, 1-65535 (refresh, export) |
| `--database <name>` | sustitución del nombre de la base de datos de origen (refresh, export) |
| `--no-keychain` | no tocar nunca el llavero |
| `--format <name>` | formato de salida |
| `--out <path>` | ruta de salida; salida estándar por defecto |
| `--deterministic` | fijar las fechas y el identificador de la exportación, para que dos ejecuciones sobre datos sin cambios sean idénticas byte a byte |
| `--reproducible` | fijar las entradas del archivo `.mad` -- hora, propiedad, orden de miembros (`write`) |

La definición de conexión -- host, puerto y nombre de base de datos -- forma parte del
almacén portable del documento; el nombre de usuario y la contraseña nunca lo son. `--host`,
`--port` y `--database` sustituyen la conexión almacenada solo para esta ejecución,
así que un documento versionado puede ejecutarse contra un contenedor de servicio de CI sin
ser reescrito. Lo que no se da conserva su valor almacenado. Se rechazan
en un documento Sqlite3, cuya conexión es un archivo, y en los verbos que no
se conectan (`inspect`, `schema`, `query`, `write`) simplemente no se usan.
Las credenciales siguen siendo `--credentials`; el almacén no contiene nombre de usuario ni contraseña.

### Códigos de salida

| Código | Significado |
|---|---|
| 0 | éxito |
| 1 | error de uso |
| 2 | el documento no se pudo leer o no es un `.mad` |
| 3 | base de datos de origen inalcanzable, o credenciales rechazadas |
| 4 | la consulta falló en el servidor |
| 5 | la exportación falló |

Los códigos distintos importan porque el primer uso real de esta herramienta es un script, y un
script necesita distinguir "el documento es malo" de "el servidor está caído".

---

## 4. Qué debe existir antes de poder construir la CLI

La ruta de datos ya está casi libre de UIKit. Esto está medido, no estimado:

| Framework | Archivos que importan UIKit | Necesitado por la CLI |
|---|---|---|
| `MADDataStructures` | 0 / 37 | sí |
| `MADFileManager` | 0 / 31 | sí |
| `MADSqlite3` | 0 / 65 | sí |
| `MADMySQL` | 0 / 42 | sí |
| `MADTds` / `MADTdsClient` | 0 / 3, 0 / 9 | sí |
| `Scrimpter` | 0 / 48 | no |
| `MADFoundation` | 4 / 66 | sí |
| `MADAPI` | 3 / 34 | en parte |
| `MAD` | 28 / 464 | en parte |

Cuatro archivos en `MADFoundation` llevan toda la dependencia de UIKit del framework base:

| Archivo | Uso de UIKit | Disposición |
|---|---|---|
| `MADApplication.{h,m}` | un contenedor de `UIApplication` | no necesitado por la CLI; excluido del objetivo headless |
| `MADURLFactory.m:32` | `UIScreen.mainScreen.scale > 1.0` | una llamada; devolver 2.0 fuera de iOS |
| `MADOperation.m:550-563` | `beginBackgroundTaskWithName:` | una función, protegida por `#if TARGET_OS_IPHONE` |

El autor ya señaló el último (`MADOperation.m:21`): *"Wish I didn't have to
import UIApplication here, but it's really the cleanest way."* Para una compilación headless no
es la forma más limpia, y es el único lugar en el framework base donde eso es
cierto.

Los tres archivos de UIKit de `MADAPI` son *controladores de vista* de conexión y simplemente no forman
parte de un objetivo headless.

### 4.1 El núcleo de actualización debe moverse

La única pieza sustantiva de trabajo es esta. La orquestación de actualización está **en el objetivo de la aplicación,
no en un framework**:

| Archivo | Líneas | Símbolos de UIKit | Rol |
|---|---|---|---|
| `MADDesigner/Source/MADOperationRefresh.m` | 131 | **0** | construye el SQL, lo ejecuta, escribe la caché |
| `MADDesigner/Source/MADOperationRefreshReload.m` | 196 | 3 | recarga del lado de la interfaz |
| `MADDesigner/Source/MADRefreshOperationReload.m` | 132 | 1 | recarga del lado de la interfaz |

`MADOperationRefresh.m` solo importa `MADAPI`, `MADFoundation` y `MAD`, y no toca
nada de UIKit. Ya es el verbo de actualización de la CLI; simplemente está en el objetivo equivocado. Se
mueve al framework `MAD`, y las dos operaciones `Reload` se quedan en la aplicación,
que es lo que sus nombres han estado diciendo todo el tiempo.

### 4.2 El objetivo headless

Una configuración de compilación de `MADFoundation`, `MADAPI` y `MAD` que compila sin
UIKit, más el propio objetivo de la CLI. Mecánicamente, esto es `SUPPORTED_PLATFORMS` extendido
con `macosx`, las rutas de búsqueda de bibliotecas por SDK de `LIBRARIES.md` §6, y las tres
exclusiones a nivel de archivo anteriores.

**Hecho en Linux, 2026-10-16** (`MAD_LINUX.md` §9 Fase D), y hecho de esta manera: el
objetivo headless es los doce frameworks compilados por `Linux/CMakeLists.txt` contra
GNUstep, y la CLI es un objetivo junto a ellos. La pieza que §4.1 asignó al framework
`MAD` -- la cadena de actualización -- se movió allí, y la pieza que no anticipó --
`MADocument`, un `UIDocument`, sobre el cual se construyó `MADCLIDocument` -- se responde con
`MADHeadlessDocument` detrás de `MADDocumentDataProtocol`: la misma mitad de datos, sin
ciclo de vida de documento y nada que renderizar. `inspect`, `schema`, `query` y `refresh`
son las mismas fuentes en ambas plataformas; `export` es PDF y se queda en Apple (§5.2,
la puesta en escena de §9). Un objetivo de macOS sigue siendo el de la Pista 5.1, pero ahora tiene la costura y la
clase de documento que le faltaba.

---

## 5. Diseño

### 5.1 Un binario, sin frameworks en el camino

`mad` enlaza los frameworks headless directamente. No carga el paquete de la aplicación,
y no debe requerir que el modelo de Core Data esté presente en una fase de compilación --
una restricción con la que la suite de pruebas ya se ha encontrado (véase la nota sobre
`MADTestReportFormatter` en la memoria del proyecto).

### 5.2 El verbo de actualización reutiliza la ruta medida

`mad refresh` debe llamar al mismo código que llama la aplicación:
`MADOperationRefresh` → `MADDatabase executeSQL:fieldKeys:onConnection:intoResultTable:`
→ `<MADDataTableWriting>`. No debe reimplementarlo. El benchmark añadido en
`MADDataTableFastBenchmarkTests` mide exactamente esta ruta a 200,000 filas
(1.16 s de ingesta, 2.5 MB transitorios), así que una CLI que la degrade aparecerá como una
prueba fallida en lugar de como una queja de usuario.

### 5.3 La exportación es un protocolo, no un switch

`MAD_FORMAT.md` describe documentos; los documentos contienen elementos de informe. La exportación debe
ser un punto extensible, que coincida con el objetivo declarado del proyecto de que los desarrolladores
"creen nuevos formatos de exportación de documentos (p. ej., exportar a PDF y JSON)". Define
`<MADReportExporting>` con un método y registra implementaciones, para que `--format json`
sea una clase nueva en lugar de una rama nueva en un switch.

**Hecho 2026-10-16**, con la forma que ya tiene el registro de controladores de §5.1: `MADReportExporting.h` es el
protocolo (el nombre de un formato, extensión, si necesita `--out`, si esta compilación puede
producirlo, y un método de exportación), `MADReportExporterRegistry` es la búsqueda, y cada
exportador se registra a sí mismo en `+load` -- así que qué formatos tiene un proceso es lo que enlaza,
y la CLI pide uno por nombre. `text`, `csv` y `json` son los propios del framework
(`MADReportExporterText/CSV/JSON`, Foundation puro, ambas plataformas);
`MADReportExportSource` es el único lugar donde un documento se lee como columnas y filas, así que los
formatos no pueden discrepar sobre qué es un documento; y `MADReportExportWriter` es el único
lugar donde los bytes llegan a un archivo o a la salida estándar.

`json-report`, `html` y `html-flow` también están en la costura, construidos sobre el protocolo de la mitad de renderizado
(`MADDocumentRenderProtocol`: un documento que puede preparar sus filas, formatear y
entregar su formateador) y sobre un único recorrido de páginas (`MADReportPageBuilder`). **`pdf` también está en
la costura** ahora: `MADReportExporterPDF` se registra en todas partes, su cuerpo es de
Core Graphics (el de Apple), y fuera de Apple responde `+isAvailable NO` con la razón
(`MAD_LINUX.md` §10.2: el escritor de Linux es el siguiente paso). La CLI no tiene brazos locales
restantes; cada formato, incluido `pdf`, se busca en el registro.

### 5.4 Credenciales

La CLI nunca debe solicitar entrada. Toma `--credentials`, o lee el llavero que
escribió la aplicación, o falla con el código de salida 3. `--no-keychain` existe para que una ejecución de prueba
no pueda leer ni escribir las credenciales reales de un desarrollador.

### 5.5 Ejecutarla: la imagen de Linux

`Linux/build.sh --runtime` compila `mad-cli:latest`, una capa solo de tiempo de ejecución con la
CLI en PATH, las bibliotecas compartidas que enlaza, y la base de datos de ejemplo Sqlite3 -- sin
compilador, fuentes ni binarios de prueba (283 MB en disco; `Linux/README.md` tiene el
contenido). Un documento se monta, no se almacena:

	docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro mad-cli:latest \
		mad inspect /docs/London.portable.mad
	docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro mad-cli:latest \
		mad refresh /docs/MySQL.employees.mad --credentials root:root --rows 50

La imagen se publica (2026-10-26, revirtiendo la decisión anterior de no publicar)
como `ghcr.io/mthomason/mad`, etiquetada `latest` y el SHA corto del commit,
empujada por `.github/workflows/publish-image.yml` en cada push a master
(más `workflow_dispatch`). Las etiquetas publicadas son **linux/amd64**, compiladas por
CI en ubuntu-latest; el `mad-cli:latest` local del Mac es arm64, y en
Apple silicon la etiqueta publicada necesita `--platform linux/amd64` (ejecutada bajo
emulación; sin la opción, el pull falla con `no matching manifest`).
Los mismos verbos sobre la imagen publicada:

	docker run --rm --platform linux/amd64 -v "$PWD/CLI/Fixtures":/docs:ro \
		ghcr.io/mthomason/mad mad inspect /docs/London.portable.mad

Un documento Sqlite3 resuelve su nombre de base de datos almacenado contra el directorio
Application Support por usuario, que es
`/root/GNUstep/Library/ApplicationSupport` en la imagen; `chinook.sqlite3` está
allí, así que los fixtures de London y Music se actualizan sin configuración. La caché de filas
vive bajo el mismo home y es por contenedor; cada exportación actualiza el
documento mismo, así que una caché no necesita persistir entre ejecuciones. Los componentes LGPL
de la imagen publicada obligan a ofertas de relink; la oferta escrita en
`ThirdParty/Licenses/README.md` nombra la imagen (`THIRD_PARTY_LICENSES.md`
§9 es la entrada del registro).

`Linux/build.sh --verify` reconstruye la imagen y ejecuta la comprobación repetible: los
seis verbos sobre los fixtures, el digest fijado de cada formato, la negativa de `pdf`, los
bytes del escritor y los códigos de salida (`Linux/verify-cli.sh`; `--live` añade las tres
bases de datos en vivo).

---

## 6. Pruebas

El formato y la CLI están fijados por **fixtures de ida y vuelta**, no por prosa:

1. **Fidelidad del contenedor.** Descomprime `Music.mad` y `London.mad`, vuelve a comprimirlos y
   afirma que la lista de miembros y los bytes de cada miembro no cambian. Esto fija
   `MAD_FORMAT.md` §2 y detecta H4 (archivos ocultos) de inmediato.  **Aterrizó
   2026-10-16** como la ida y vuelta de `Linux/Tests/MADArchiveManagerTests.m` -- `mad write`
   escribe el contenedor en ambas plataformas ahora -- con los bytes del modo reproducible
   fijados contra los del Mac.
2. **Legibilidad v0.** `mad inspect` en ambas muestras enviadas debe tener éxito e informar
   los valores de `MAD_FORMAT.md` §2 -- incluido el WAL sin checkpoint, que es la
   afirmación que prueba que el peligro del WAL se informa en lugar de ignorarse.
3. **Ida y vuelta sin caché.** Abrir un documento, actualizar, exportar, cerrar, reabrir. La
   segunda apertura no debe necesitar la red. Esto fija §5 del documento de formato -- que
   la caché es derivada y externa.
4. **Escala.** `mad refresh --rows 200000` contra una fuente SQLite local, afirmado
   contra los mismos techos que usa el benchmark, para que la CLI no pueda convertirse en silencio en la
   ruta lenta.
5. **Códigos de salida.** Una prueba por fila de la tabla en §3, impulsada por entradas
   deliberadamente rotas.

Los fixtures viven junto a las muestras que prueban. Las pruebas que necesitan un servidor MySQL, SQL Server
o PostgreSQL en vivo **se omiten** cuando uno no es alcanzable, siguiendo la convención existente
en `MADMySQLLiveTests.m`, `MADTdsClientLiveTests.m` y
`MADPostgresLiveTests.m`.

---

## 7. Fases

| Fase | Entregable | Depende de |
|---|---|---|
| 0 | `MAD_FORMAT.md`, `MAD_CLI.md`, `LIBRARIES.md` | -- |
| 1 | Sistema de compilación de bibliotecas, opciones de sqlite fijadas | Fase 0 |
| 2 | Rutas de búsqueda por SDK; slices de macOS conectados | Fase 1 |
| 3 | Subconjunto headless; `MADOperationRefresh` movido a `MAD` | Fase 2 |
| 4 | Objetivo `mad`: `inspect`, `schema`, `query` | Fase 3 |
| 5 | `mad refresh` | Fase 4 |
| 6 | `mad export` (PDF primero) | Fase 5 |
| 7 | Fixtures de ida y vuelta conectados a la matriz de pruebas | Fase 6 |

Las fases 4-6 están ordenadas por dependencia, no por dificultad: `inspect` necesita solo el
contenedor, `query` necesita el modelo de documento, y `refresh` necesita una conexión
a base de datos.

---

## 8. Preguntas abiertas

1. **¿La CLI se envía, o es una herramienta de desarrollador?** Eso decide si necesita
   firma de código, notarización y un instalador, y si `--credentials` puede
   aceptar un argumento en texto plano o debe tomar un descriptor de archivo.
2. **¿Debería `mad` aceptar la caché de filas desde un archivo externo?** Un `.mad` empaquetado
   (§8.3 del documento de formato) haría posible la exportación sin conexión. Nada lo necesita
   todavía.
3. **¿Cuál es la forma de la exportación JSON? -- respondida 2026-10-16: ambas, la mitad del informe como
   su propio formato.** `--format json` es el contrato de datos, `--format json-report`
   añade el informe renderizado como un miembro extra. La forma está en
   `MADReportExporterJSON.h`, implementada por `MADReportExporterJSON` (la mitad de datos,
   ambas plataformas) y `MADReportExporterJSONReport` (el miembro de informe, donde está la mitad
   de renderizado). Sus columnas son las de la consulta, en el orden que define la lista SELECT
   -- el alias de la columna, ordenado (`BUGS.md`, la entrada de la lista SELECT) --
   y un valor conserva su tipo JSON: los números son números, NULL es `null`, las fechas son
   ISO 8601 y lo binario es base64.
