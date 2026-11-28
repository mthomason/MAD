---
layout: default
title: "Informes de composición"
description: >-
  Combina informes de varias bases de datos en un solo documento .mad portable: cada origen conserva su consulta, diseño y datos, y el Resultado los une en un nuevo informe.
lang: es-419
---

# Informes de composición

Un **Informe de composición** combina otros informes en un solo documento `.mad`. Cada informe
que incorpora es un **Origen**; el informe predeterminado del documento es el **Resultado**, que
une las tablas de resultados de los orígenes en un nuevo informe propio.

La composición es la manera en que un solo documento portable abarca varias bases de datos —MySQL,
PostgreSQL, SQL Server y SQLite— sin un servidor de federación en medio. Los
orígenes se incorporan al documento **con sus diseños**; combinarlos no
aplana un origen hasta convertirlo en una tabla. Cada miembro de una composición es un informe completo.

> **Plataformas:** los Informes de composición están disponibles en **MAD Designer para macOS** (0.8)
> y **MAD Designer para Windows** (0.8). La aplicación de iOS todavía no crea composiciones;
> esta página describe las aplicaciones de escritorio.


## El modelo mental

> Un informe de composición combina otros informes en uno. Usted incorpora informes
> existentes (**orígenes**), une sus tablas de resultados para construir un nuevo informe **Resultado**, elige qué
> **columnas** del resultado mostrar y luego diseña y ve ese Resultado exactamente como un informe
> estándar. Seleccionar un origen le devuelve la consulta, el diseño y las filas de ese origen.

Cuatro verbos cubren el flujo de trabajo: **agregar orígenes → unirlos → elegir las columnas → seleccionar**.

| Término | Qué significa |
|---|---|
| **Informe de composición** | Un documento `.mad` que contiene un grafo de informes: el Resultado más sus orígenes. |
| **Resultado** | El informe predeterminado del documento. Une las tablas materializadas de los orígenes y es lo que se abre primero, se imprime de forma predeterminada y se exporta de forma predeterminada. |
| **Origen** | Un informe hijo incorporado a la composición. Conserva su propia consulta, conexión de base de datos, diseño y filas. |
| **Columnas del informe** | Los campos que el Resultado expone a su propio diseño y a sus padres. Se editan en el espacio de trabajo Query (el elemento **Outputs…** en macOS, **Columnas** en Windows). |
| **Origen sin diseño** | Un origen cuyo informe aún no tiene elementos. El Diseñador ofrece crear un diseño; el Visor muestra sus filas como una tabla. |

### Cada miembro es un informe

Esta es la regla que hace legible la función. Un origen no se reduce a una tabla
cuando se importa: su definición de consulta, su propio diseño de informe y sus datos
lo acompañan, y se guardan en el mismo documento `.mad`. Las filas permanecen en el almacenamiento complementario
(los archivos `.maddb` y `.mdcache` junto al documento), no dentro del `.mad`.

Seleccionar un origen en el selector **Navegación** (macOS) o en el selector **Componente** y el
panel Composición (Windows) cambia **los tres espacios de trabajo** —Query, Designer y
Viewer— a ese origen. Un origen sin diseño sigue siendo un informe válido: el Visor muestra
sus filas en caché en una cuadrícula en lugar de una página.



## Crear una composición

### macOS

* **Archivo ▸ Nuevo documento…** ofrece **Standard Report** y **Composition Report**.
  Elegir Composition Report le pide seleccionar uno o varios informes `.mad` existentes y luego
  dónde guardar la nueva composición.
* **Archivo ▸ Nueva composición…** es el comando directo para el mismo flujo.
* **Archivo ▸ Convertir en composición…** convierte el informe estándar abierto en una composición
  de un solo origen, conservando su diseño.
* En el espacio de trabajo **MAD Query**, el menú Añadir agrega una tabla, una **consulta de origen** desde una
  nueva conexión de base de datos, un **informe importado** o la **consulta raíz** compuesta.

El selector **Navegación** de la barra de herramientas lista el **Resultado** primero (marcado *Resultado — <nombre>*)
y luego cada origen. Seleccionar un elemento nunca cambia el espacio de trabajo activo; cambia
qué informe muestra ese espacio de trabajo.

### Windows

* **Archivo ▸ Nueva composición…** crea una composición a partir de informes existentes.
* **Archivo ▸ Importar…** agrega un informe como origen de la composición abierta.
* **Archivo ▸ Convertir en composición** convierte el informe estándar abierto en una composición.

Un panel **Composición** acoplado se asienta junto al espacio de trabajo (ausente en un informe estándar).
Su grafo muestra el Resultado en la profundidad 0 y sus orígenes debajo, con conectores que apuntan al
consumidor. El panel y el selector **Componente** de la barra de herramientas comparten una sola selección; el
panel puede contraerse y el selector permanece.

## Unir orígenes y elegir columnas

En el lienzo del Resultado, arrastre un campo de una tarjeta de origen a un campo de otra para crear
una unión, y luego haga clic en la insignia de la unión para cambiar su tipo (`INNER`, `LEFT OUTER`,
`RIGHT OUTER`, `FULL OUTER`, `CROSS`) o invertir su dirección. El Resultado es una consulta
normal: puede unir cualquier número de orígenes, filtrar, agrupar y ordenar.

Un origen que es en sí mismo una composición se une al grafo con sus propios orígenes; el padre
hace referencia al Resultado de esa composición. Un nodo componedor hace referencia solo a sus hijos —
nunca a una tabla remota—, de modo que cada hoja se ejecuta contra su propia base de datos y cada paso de unión
se ejecuta localmente en SQLite.

Use el editor de **Columnas del informe** del Resultado para elegir, nombrar y ordenar los campos que el
Resultado expone. La lista de campos del Diseñador del Resultado es exactamente ese conjunto. Un origen expone
sus propios campos de consulta.

## Actualizar, credenciales y privacidad

La actualización ejecuta el grafo **primero los hijos, el Resultado al final**. Cada hoja se ejecuta contra
su propia base de datos con sus propias credenciales; cada informe compuesto se ejecuta localmente sobre las
tablas materializadas de sus hijos. Cada nodo materializa su propia tabla, y un nodo fallido
hace fallar la actualización mientras deja legibles los resultados completos anteriores.

Una composición multi-origen, por lo tanto, pide **una credencial por origen**, una hoja a
la vez, con el controlador, host, puerto, base de datos y usuario no secreto ya rellenados.
Las contraseñas nunca se guardan en el archivo `.mad`: macOS las conserva en el Llavero (o en la
sesión actual), y Windows las conserva en la sesión o en el almacén de credenciales de la plataforma.
Un origen SQLite no necesita credenciales.

## Muestras

Hay dos composiciones ejecutables en [`Samples/Reports`](https://github.com/mthomason/MAD/tree/master/Samples/Reports):

* **`Chinook-Composition.mad`** — dos orígenes SQLite (un informe de Albums con su propio
  diseño y un informe de Artists sin ninguno) unidos en un Resultado. No necesita nada más que
  el `chinook.sqlite3` incluido.
* **`Composition-MySQL-PostgreSQL-SQLServer.mad`** — una pequeña tabla de MySQL,
  PostgreSQL y SQL Server unida por `demo_id`, que demuestra un solo documento que
  abarca tres bases de datos.

Levante los tres servidores en vivo y siembre la tabla entre bases de datos con un único script
idempotente (macOS, Linux y Git Bash en Windows):

```sh
./Samples/setup-databases.sh up
```

En Windows PowerShell:

```powershell
.\Samples\setup-databases.ps1 -Action up
```

`up` crea o inicia los contenedores fijados mediante los scripts de base de datos de prueba y carga
la tabla `composition_demo` en cada servidor. `status` informa los contenedores y los recuentos de
filas; `down` los detiene. El mismo SQL puede imprimirse sin Docker con
`./Samples/setup-databases.sh sql`. Consulte [la guía de muestras](https://github.com/mthomason/MAD/blob/master/Samples/README.md)
para el recorrido de primera ejecución, incluidas las solicitudes de contraseña por origen.

## Límites actuales

* **Solo el mismo documento.** La definición y el diseño de cada origen viven dentro del único
  archivo `.mad`. No se admite hacer referencia a un informe de otro archivo.
* **Hasta diez hijos directos por informe compuesto.** La compilación de SQLite del motor admite
  diez bases de datos adjuntas; el Diseñador rechaza un undécimo hijo.
* **Las composiciones anidadas son de solo lectura en el espacio de trabajo Query.** Un origen que es en sí mismo
  una composición muestra los orígenes que une, pero crear un compositor anidado directamente es
  una pieza de trabajo posterior.
* **`json-report` exporta solo el Resultado.** Todos los demás formatos de exportación exportan el
  informe seleccionado.

## Relacionado

* [MAD Designer para macOS](macos.html) — la aplicación nativa de AppKit.
* [MAD Designer para Windows](windows.html) — la aplicación nativa de WPF.
* [La dirección](vision.html) — los informes como orígenes de datos componibles.
* [El objeto de datos](developers/data-object.html) — la definición, el esquema y el
  conjunto de resultados de un informe como un solo contrato.
* [Informes multi-origen](developers/multi-source.html) — la arquitectura detrás de
  la composición dentro del mismo documento.
