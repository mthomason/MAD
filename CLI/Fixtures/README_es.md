[English](README.md) | [简体中文](README_zh.md) | [日本語](README_ja.md) | [Português (Brasil)](README_pt-BR.md) | [Deutsch](README_de.md) | **Español**

# Fixtures de la CLI

Documentos contra los que se ejecutan los verbos de la CLI, junto a las muestras de las que proceden
(`docs/project/MAD_CLI.md` §6).

| Fixture | Origen | Qué fija |
|---|---|---|
| `London.portable.mad` | `MADDesigner/Resources/Assets/Samples.xcassets/Reports/London.dataset/London.mad` | la ruta de datos de Sqlite3: esquema de 11 tablas, el predicado London, 76 filas |
| `Music.portable.mad` | `.../Reports/Music.dataset/Music.mad` | la misma ruta en la muestra más grande (3503 filas) |
| `MySQL.employees.mad` | la base de datos de muestra `employees`, en vivo (MySQL 8.4) | la ruta del driver de MySQL de extremo a extremo: importación del esquema, SQL con acentos graves, una obtención con sentencia preparada |
| `TDS.AdventureWorksLT2022.mad` | AdventureWorksLT2022, en vivo (SQL Server 2022) | la ruta TDS de extremo a extremo: tablas cualificadas por esquema, T-SQL entre corchetes, la obtención de freetds |
| `Postgres.chinook.mad` | Chinook, en vivo (PostgreSQL 17) | la ruta de PostgreSQL de extremo a extremo: importación del esquema, SQL con comillas dobles, la obtención de libpq |

## Por qué hubo que convertir las muestras

Ambas muestras distribuidas son documentos **heredados**: su definición es un almacén de Core Data
(`StoreContent/analyitics`), y convertir uno necesita Core Data, que el
framework MAD no enlaza y Linux no tiene (`docs/project/MAD_LINUX.md` §5.1, §9).
`London.portable.mad` y `Music.portable.mad` son los mismos documentos escritos en
el almacén portátil, para que una plataforma sin Core Data pueda leerlos y actualizarlos,
que es lo que hacen la CLI de Linux y `Linux/Tests/MADHeadlessDocumentTests.m`.

También son la contraparte del lado de la lectura de las muestras v0: `mad inspect` informa de una
fixture como v1 con `StoreContent/store.sqlite` y de la muestra como v0 con el almacén
heredado, y ambas afirmaciones provienen del mismo lector de contenedores.

Las tres fixtures en vivo son documentos ordinarios que la cadena de creación de documentos
de la aplicación escribió contra un servidor real, así que sus esquemas son reales (8 tablas de `employees`, 12 de
AdventureWorksLT, 11 de Chinook) y sus consultas son SELECT reales.

## Cómo se crearon

En el Mac, con las propias rutas de código de la aplicación: nada de esto está escrito a mano:

	CLI/build.sh --make-fixture portable "$PWD/MADDesigner/Resources/Assets/Samples.xcassets/Reports/London.dataset/London.mad" \
		"$PWD/CLI/Fixtures/London.portable.mad"
	CLI/build.sh --make-fixture portable "$PWD/MADDesigner/Resources/Assets/Samples.xcassets/Reports/Music.dataset/Music.mad" \
		"$PWD/CLI/Fixtures/Music.portable.mad"

	CLI/build.sh --make-fixture create mysql mac 13306 root root employees "$PWD/CLI/Fixtures/MySQL.employees.mad"
	CLI/build.sh --make-fixture select "$PWD/CLI/Fixtures/MySQL.employees.mad" titles "title,from_date,to_date"

	CLI/build.sh --make-fixture create tds mac 1433 sa 'Root1@Root2' AdventureWorksLT2022 "$PWD/CLI/Fixtures/TDS.AdventureWorksLT2022.mad"
	CLI/build.sh --make-fixture select "$PWD/CLI/Fixtures/TDS.AdventureWorksLT2022.mad" "SalesLT.Product" "Name,ListPrice,Color"

	CLI/build.sh --make-fixture create postgres mac 5432 mad mad_test_pw chinook "$PWD/CLI/Fixtures/Postgres.chinook.mad"
	CLI/build.sh --make-fixture select "$PWD/CLI/Fixtures/Postgres.chinook.mad" track "name,composer,unit_price"

`--make-fixture` compila `MADFixtureMaker.m` (con los mismos indicadores que la herramienta, más el
convertidor heredado y los transformadores de valores) y lo ejecuta en el simulador:

* `portable` copia el documento, lo abre con `MADocument` —que convierte el
  almacén heredado al entrar—, lo marca como modificado y lo cierra, que es la ruta de
  guardado.
* `create` ejecuta la cadena de creación de documentos de la aplicación contra un servidor en vivo: crea el
  documento, configurarlo por primera vez, añadir la conexión, importar el esquema, cerrar (que
  guarda).
* `select` hace lo que hace el diseñador cuando se marcan una tabla y sus campos: añade
  la tabla de consulta, un campo de consulta por cada campo del esquema, y una etiqueta de datos por cada campo de consulta
  —las etiquetas son lo que hace que los campos sean *activos*, ya que la lista SELECT
  son los campos a los que hacen referencia los elementos del informe (`MADQueryActiveQueryFields`).

El resultado no es estable byte a byte entre ejecuciones (el almacén es SQLite y el archivo
lleva marcas de tiempo), así que las fixtures solo se regeneran cuando cambia una muestra o el
formato del almacén, y un diff en ellas es uno real que hay que mirar.

## El nombre de host en las fixtures en vivo

Las tres nombran el servidor como `mac`: el nombre de host de este Mac, que se resuelve a su dirección de LAN
aquí y dentro de los contenedores Docker. Un solo nombre, entonces, para el MySQL del Mac
(publicado en el bucle local *y* en la LAN por el contenedor de fixtures de abajo) y
para los contenedores de SQL Server y PostgreSQL (publicados en todas las interfaces), para que el mismo documento
se pueda actualizar desde el Mac y desde la imagen de Linux. `host.docker.internal`
solo funcionaría dentro de un contenedor; `127.0.0.1` solo en el Mac.

Las tres fixtures en vivo se crearon contra los contenedores de prueba canónicos, que
`docs/project/DEVELOPER.md` documenta y cuyos scripts los crean a partir de imágenes fijadas y
conjuntos de datos verificados con checksum:

	MADMySQL/TestDatabase/mysql-test-db.sh up          # mad-mysql on 13306
	MADTdsClient/TestDatabase/sqlserver-test-db.sh up  # mad-mssql on 1433
	MADPostgres/TestDatabase/postgres-test-db.sh up    # mad-postgres on 5432

Los tres publican en todas las interfaces, así que el nombre de host `mac` de los documentos se resuelve
desde el Mac y desde dentro de la imagen de Linux. El contenedor de MySQL está en 13306,
no en 3306, porque el servicio launchd del instalador de Oracle MySQL puede ocupar 3306.
`down` detiene un servidor (los volúmenes conservan los datos); `reset` lo elimina y el
siguiente `up` lo reconstruye.

Los parámetros `--host`, `--port` y `--database` de la CLI sobrescriben la conexión almacenada
para una ejecución (`docs/project/MAD_CLI.md` §3), que es como un trabajo de CI apunta uno de
estos documentos a un contenedor de servicio cuyo host y puerto difieren de los
del Mac. El documento en sí no se reescribe.
