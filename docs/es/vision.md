---
layout: default
lang: es-419
---

# La dirección: un informe es una tabla

Actualizado el 2026-10-29. Esta página expone la dirección hacia la que MAD está diseñado para
crecer. Nada de la maquinaria de composición o migración descrita aquí está construido
todavía; el diseño que fundamenta el modelo de objeto de datos es
[`docs/project/MAD_DATA_OBJECT.md`](https://github.com/mthomason/MAD/blob/master/docs/project/MAD_DATA_OBJECT.md),
el registro de trabajo es
[`docs/project/MAD_FUTURE.md`](https://github.com/mthomason/MAD/blob/master/docs/project/MAD_FUTURE.md),
y la lista de deseos del producto es
[`docs/project/TODO.md`](https://github.com/mthomason/MAD/blob/master/docs/project/TODO.md).

## Dónde está MAD hoy

Un documento `.mad` es la *definición* de un informe: la instantánea del esquema, el grafo de
consultas (tablas, joins, agrupaciones, filtros) y el árbol de diseño por bandas. Al
actualizarse, el motor compila el grafo a SQL, lee las filas una vez y
las materializa en una caché SQLite complementaria (`.maddb` + `.mdcache`). Los datos de fila
quedan fuera del documento a propósito; la definición se mantiene por debajo de 100 KB.

Una consecuencia es fácil de pasar por alto: **un informe es una función de fuentes de datos
a una tabla.** Cada driver devuelve un esquema y filas en forma de tabla, y la salida de un
informe *es* un esquema (`MADDataColumn`) y filas en forma de tabla
(`MADDataTableFast`). El motor ya trata ambos de forma idéntica.

## Hacia dónde va

Cerrar el circuito entre la definición de un informe y su salida materializada
habilita cuatro capacidades:

### 1. Un archivo `.mad` como tabla ad hoc de base de datos

En una base de datos, se hace `SELECT` sobre tablas base como `employee` o `sales_data`. Un
informe enlaza varias tablas y su salida es una tabla SQLite ad hoc y
materializada. Hoy nada puede apuntar una consulta a la salida de otro informe: la caché de
resultados existe, pero se indexa por un hash de nombre de archivo en lugar de por una
identidad direccionable. Hacer direccionable esa salida significa:

> **El resultado de un informe se convierte en una tabla de base de datos sobre la que otros informes y
> consultas pueden hacer `SELECT` y `JOIN`.**

Un informe construido sobre un informe es un DAG de tablas derivadas: una capa semántica
portátil en la que diseñar un informe es también diseñar una fuente de datos reutilizable.

### 2. Varias fuentes de datos en un solo informe

Cada driver (`MADMySQL`, `MADPostgres`, `MADTdsClient`, `MADSqlite3`)
materializa su conjunto de resultados en la misma representación local de tabla SQLite.
Una vez que un documento puede contener varias definiciones de consulta y direccionar cada salida como
una tabla, un informe puede unir una tabla de PostgreSQL con una tabla de SQL Server y una
tabla de MySQL, federadas localmente en SQLite sin un servidor de federación en
medio. Las instantáneas *son* la federación.

### 3. El papel como un paradigma más: vistas nativas de UIKit sobre datos sin procesar

La paginación por bandas (Report Header, Page Header, Groupings, Detail, Footers) se
inventó para imprimir en papel. Como el diseño de un `.mad` son datos paramétricos y
la caché de filas `.maddb` es SQLite local en el dispositivo, las páginas de papel son solo una
forma de presentar un informe. Cuando el usuario no está imprimiendo, la misma definición
y la caché local pueden renderizarse como vistas nativas interactivas de UIKit y exploradores
de datos sin procesar: diseñar una vez, ver como papel o como interfaz nativa.

### 4. Convertir informes heredados de Crystal Reports (`.rpt`) en archivos `.mad` abiertos

Crystal Reports (`.rpt`) y otros archivos de informes heredados similares siguen arraigados
en miles de empresas porque ningún motor abierto y portátil comparte su modelo de
secciones por bandas y grafo de consultas relacionales. Como MAD se construye sobre ese
mismo paradigma estructural —almacenando sus definiciones en un formato abierto y
documentado de SQLite dentro de tar—, convertir documentos `.rpt` heredados en
archivos `.mad` da a las organizaciones una ruta de migración directa desde las pilas
de generación de informes propietarias y heredadas.

## Lo que ya existe

Las partes costosas están construidas: definiciones portátiles, generación y análisis
deterministas de SQL, un formato de materialización portátil (SQLite), cuatro
drivers de base de datos y un motor que se ejecuta de forma nativa en iOS/macOS y
sin interfaz gráfica en Linux.

## Lo que esto no es

Una promesa. Esta página registra la dirección; el diseño y la cola de tareas
viven en `docs/project/`, y nada de lo aquí descrito se distribuye hasta que está
diseñado, probado y documentado como todo lo demás del repositorio.
