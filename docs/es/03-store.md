---
layout: default
lang: es-419
---

## 3. El almacén

`StoreContent/analyitics` es una base de datos SQLite ordinaria:

```
StoreContent/analyitics: SQLite 3.x database, last written using SQLite version 3043002,
  writer version 2, read version 2, file counter 52, database pages 126, cookie 0x6e,
  schema 4, largest root page 113, UTF-8, vacuum mode 1, version-valid-for 52
```

Contiene la **definición del documento**: la consulta, sus tablas y joins, las secciones
y elementos del informe, y la instantánea del esquema de la base de datos. El modelo de Core Data es
`MAD/MAD.xcdatamodel`; todas sus entidades llevan el prefijo `Rptq` (`RptqDocument`,
`RptqQuery`, `RptqDocumentElement`, `RptqDocumentSection`, …).

Dos propiedades de este almacén son fundamentales para la portabilidad:

1. **Se escribe en modo WAL.** `-wal` y `-shm` se distribuyen dentro del archivo
   junto a la base de datos principal. Un lector que extraiga solo `analyitics` e ignore
   el WAL leerá una base de datos hasta un checkpoint desactualizada. En la muestra `Music` el
   WAL ocupa **313 KB frente a un archivo principal de 516 KB**: esto no es un riesgo teórico.
2. **Es un almacén de Core Data**, así que su esquema es el de Core Data, no el nuestro. Leerlo
   sin Core Data significa leer las propias tablas de Core Data. Eso es posible —es
   SQLite, y la correspondencia es estable—, pero es la parte de este formato que ata un
   lector a Core Data, y es la razón por la que la migración para salir de Core Data importa aquí
   más que en cualquier otro lugar.

### 3.1 El almacén portátil (desde la migración del almacén)

Desde la migración del almacén (`docs/project/design/MAD_STORE_MIGRATION.md`), la definición de un documento vive en
un almacén SQLite portátil de nuestro propio diseño. Su esquema se describe mediante los
descriptores `MADStoreSchema` mantenidos a mano (`MAD/Source/rptq/store/`), generados por
`-createSchemaSQL` y contrastados con el modelo compilado por `MADStoreTests`.
El almacén registra la versión de su esquema en `PRAGMA user_version`: la versión 1 es el esquema
tal como se distribuyó (ausente o 0), la versión 2 añade `RptqQuery.sqlSourceText` —el SQL
pegado por el usuario, conservado textualmente (`docs/developers/sql-entry.md` §8)—, la versión 3 añade los
campos de composición, y la versión 4 añade los diseños por nodo. `MADStore` aplica los pasos
que faltan al abrir; cada descriptor marca la revisión que lo introdujo con
`introducedInVersion` en `MAD/Source/rptq/store/MADStoreSchema.m`.

La composición añadió, en la revisión 3:

| Adición | Propósito |
|---|---|
| `RptqQuery.name` | Un nombre legible para un informe del grafo. |
| `RptqDocument.rootQuery` | El informe predeterminado del documento (el Resultado). |
| `RptqQueryTable.upstreamQuery` | Una tabla cuyo origen es otra consulta, no una tabla de esquema remota. |
| `RptqQueryField.outputIndex`, `RptqQueryField.outputKey` | El nombre y el orden estables de las columnas de salida de un informe compuesto. |

La revisión 4 añade `RptqDocumentSection.ownerQuery`: cada consulta puede tener sus propias secciones y elementos
de diseño, de modo que cada informe de una composición tiene sus propias bandas y enlaces de
campos. Un lector debe aplicar todos los pasos hasta el `user_version` del documento; un lector más antiguo
rechaza un documento más nuevo en lugar de leer un esquema parcial.

Los campos de la tabla `RptqQuery`:

| Columna | Tipo | Notas |
|---|---|---|
| `identifier` | INTEGER | la clave de la fila |
| `cachedText` | TEXT | |
| `override` | INTEGER | |
| `overrideText` | TEXT | |
| `sqlSourceText` | TEXT | la última sentencia pegada aplicada con éxito, textualmente; NULL en caso contrario |
| `inDatabase_identifier` | INTEGER | clave foránea a `RptqDatabase` |
