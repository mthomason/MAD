---
layout: default
title: "La dirección"
description: "La dirección de MAD: de los informes a los objetos de datos componibles, un motor embebible y documentos creados por IA."
lang: es-419
---

# La dirección: de los informes a los datos componibles

Actualizado el 2026-11-22. Esta página expone la dirección hacia la que MAD está diseñado
para crecer. Separa lo que se distribuye hoy de lo que se propone, y enlaza los registros
de diseño públicos en lugar de las notas de trabajo internas: el
[diseño del objeto de datos](developers/data-object.html), los
[informes de varias fuentes](developers/multi-source.html) y la
[especificación del formato](README.html).

## Lo que existe hoy

Un documento `.mad` es la **definición** de un informe: la instantánea del esquema, el
grafo de consultas (tablas, joins, predicados, agrupaciones) y el árbol de diseño por
bandas. Al actualizarse, el motor compila el grafo a SQL, lee las filas una vez y las
materializa en una caché SQLite complementaria (`.maddb` + `.mdcache`). Los datos de fila
quedan fuera del documento a propósito; la definición se mantiene por debajo de 100 KB.

El motor ya tiene las piezas que necesita una dirección más amplia:

* Un formato de documento abierto y portátil: un archivo tar con bzip2 que contiene un
  almacén SQLite portátil, sin necesidad de ningún framework de Apple para abrirlo.
* Un generador de consultas que compila definiciones estructuradas a SQL, más un
  analizador de SQL para las sentencias introducidas directamente.
* Cuatro drivers de SQL —MySQL, SQL Server, PostgreSQL y SQLite— que devuelven un
  esquema y filas en forma de tabla.
* Materialización local en SQLite (`MADDataTableFast`) que hace prácticas las
  agrupaciones, los agregados y el renderizado repetido en un teléfono.
* Aplicaciones nativas para iOS y macOS, una aplicación nativa para Windows y el mismo
  motor ejecutándose sin interfaz gráfica en Linux y Windows mediante `mad serve` y la
  CLI `mad`.

Una consecuencia es fácil de pasar por alto: **un informe es una función de fuentes de
datos a una tabla.** Cada driver devuelve un esquema y filas en forma de tabla, y la
salida de un informe *es* un esquema y filas en forma de tabla. El motor ya trata ambos
de forma idéntica.

## Hacia dónde va

Las direcciones siguientes son propuestas. Se basan en la arquitectura anterior, pero
ninguna se distribuye hoy a menos que esta página indique lo contrario.

### Objetos de datos componibles

En una base de datos, se selecciona de tablas base como `employee` o `sales_data`. Un
informe enlaza varias tablas entre sí, y su salida es una tabla SQLite ad hoc y
materializada. Hoy nada puede apuntar una consulta a la salida de otro informe: la caché
de resultados existe, pero se indexa por un hash de nombre de archivo en lugar de por una
identidad direccionable.

Dar a esa salida una identidad estable haría que el resultado de un informe fuese una
tabla de la que otros informes pueden seleccionar y con la que pueden hacer join. Un
informe construido sobre un informe se convierte en un grafo acíclico dirigido (DAG) de
tablas derivadas: una capa semántica portátil en la que diseñar un informe es también
diseñar una fuente de datos reutilizable. El
[diseño del objeto de datos](developers/data-object.html) describe el modelo y lo que
hace falta para formalizarlo.

### Materialización local de varias fuentes

Cada driver materializa su conjunto de resultados en la misma representación local de
tabla SQLite. Una vez que un documento puede contener varias definiciones de consulta y
direccionar cada salida como una tabla, un solo informe podría unir una tabla de
PostgreSQL con una tabla de SQL Server y una tabla de MySQL, combinadas localmente en
SQLite sin un servidor de federación en medio. Cada fuente entiende sus propios datos;
MAD entiende las tablas resultantes. El
[diseño de varias fuentes](developers/multi-source.html) registra la arquitectura y las
fases, no todas construidas.

### Uso embebido y sin interfaz

MAD no tiene por qué limitarse a las aplicaciones llamadas MAD. El mismo motor podría
embeberse en productos de otros desarrolladores: un sistema de inventario, una aplicación
financiera, una herramienta de fabricación o un sistema de gestión específico de un
sector que necesita consultas, informes, exportaciones y resúmenes operativos sin
construir un subsistema de generación de informes desde cero.

La aplicación anfitriona aporta el acceso a datos, la integración y su propia experiencia
de usuario. MAD aporta capacidades reutilizables de consulta, materialización, generación
de informes y exportación. La costura del driver es deliberadamente amplia —una fuente
necesita proporcionar un esquema y filas, no necesariamente una base de datos SQL
convencional—, de modo que el mismo contrato puede acomodar bases de datos relacionales,
datos locales de la aplicación, archivos estructurados y dispositivos. Algunas de esas
fuentes ya tienen driver; otras necesitarían uno.

Esta dirección también va más allá del software de escritorio: un aparato o sistema
industrial con recursos suficientes podría usar el motor localmente para convertir
mediciones y registros de mantenimiento en informes de diagnóstico, sin conectividad
continua. No es una afirmación de que el motor completo quepa en un microcontrolador
diminuto ni en un bucle de control de tiempo real estricto.

### Presentación más allá del papel

La paginación por bandas —encabezado del informe, encabezado de página, agrupaciones,
detalle, pies de página— se inventó para imprimir en papel. El diseño de un `.mad` son
datos paramétricos, y la caché de filas es SQLite local, así que las páginas de papel son
una presentación de los datos en lugar de su definición.

Mantener separadas la definición y su tabla materializada hace posibles otras
presentaciones sobre el mismo objeto de datos: tablas interactivas y exploradores de
datos, vistas nativas de la aplicación, gráficos y paneles, vistas embebidas en
aplicaciones y visores basados en el navegador. Los informes paginados tradicionales
siguen siendo importantes; el objetivo es hacerlos una presentación útil entre varias, no
abandonarlos.

### Documentos creados por IA

La estructura declarativa de MAD lo hace adecuado para un modelo diferente de generación
de informes asistida por IA. En lugar de generar una imagen de un gráfico, un modelo
podría proponer un documento MAD real: descubrir las fuentes disponibles y los metadatos
del esquema, elegir las tablas y los campos relevantes, construir los grafos de consulta
y las relaciones, proponer un diseño y enviar el resultado al motor para su validación y
ejecución.

La división de responsabilidades importa. El modelo interpreta la intención y propone una
definición estructurada; MAD la valida y la ejecuta. El modelo debería producir grafos de
consulta y definiciones de diseño en lugar de SQL arbitrario sin verificar, y el motor
debería seguir siendo responsable de la generación de SQL, el acceso a datos y la
materialización.

El resultado sería un documento `.mad` normal y editable en lugar de una respuesta
puntual. El grafo de consulta podría inspeccionarse, las uniones y los filtros editarse,
la presentación personalizarse, los resultados actualizarse sin el modelo y el documento
reutilizarse en otro lugar. Eso mantiene al usuario en control del artefacto y evita que
el funcionamiento dependa de la IA que lo creó. La autorización, la validación y los
controles de protección de datos formarían parte de hacer esto realidad; la validación
estructural por sí sola no demuestra que un análisis sea semánticamente correcto.

### Servidor y despliegue web opcionales

Las aplicaciones nativas, los componentes embebidos y la ejecución sin interfaz deberían
seguir siendo de primera clase. Un servicio futuro podría añadir programación, catálogos
de documentos, controles de acceso, gestión de instantáneas, informes compartidos y API,
y un diseñador basado en el navegador podría operar sobre el mismo modelo de documento
que los clientes nativos.

El motor y el formato del documento siguen siendo la base común. Un cliente que necesita
ejecución local, infraestructura privada o funcionamiento sin conexión no debería tener
que adoptar un despliegue en la nube para beneficiarse del motor, y una futura
implementación web no debería bifurcar la semántica de las consultas.

### Conversión de informes heredados

Un importador futuro podría traer definiciones de formatos de informes heredados a
archivos `.mad` abiertos. Es una vía de compatibilidad para organizaciones con
bibliotecas de informes muy longevas, no el centro de la dirección ni un reemplazo de
las direcciones anteriores.

## Tres formas de usar MAD

Estas no son productos separados ni bases de código separadas. Son usos diferentes de la
misma arquitectura, conectados por el modelo de objeto de datos.

### MAD como aplicación

Una experiencia completa de consulta, diseño y generación de informes para quienes
trabajan directamente con sus datos, con aplicaciones nativas, portabilidad de documentos
y generación de informes práctica.

### MAD como motor embebido

Un componente reutilizable de acceso a datos, consulta, materialización y generación de
informes para desarrolladores que incorporan MAD en su propio software o dispositivos,
con el énfasis en la arquitectura de drivers, la ejecución sin interfaz, las definiciones
reutilizables y el procesamiento local.

### MAD como plataforma de datos creada por IA

Un sistema en el que las personas describen la información que necesitan y un modelo
construye objetos de datos y documentos MAD validados, con generación estructurada,
validación por máquina y artefactos editables que siguen siendo útiles independientemente
de la IA.

## Por qué esto importa

El problema es práctico. Muchas organizaciones ejecutan sistemas considerables y de larga
vida construidos alrededor de bases de datos relacionales y aplicaciones empresariales
especializadas. Quieren acceso fiable a sus propios datos, informes que puedan mantener
sin desarrollo personalizado repetido, herramientas nativas con buenas experiencias de
usuario, control sobre las credenciales y sobre dónde se procesan los datos, uso
continuado de la infraestructura de base de datos existente y portabilidad entre
plataformas y entornos.

La parte difícil suele ser llevar los datos a una forma fiable y utilizable. Presentarlos
es el paso final. MAD invierte en la adquisición de datos, el modelado relacional, la
materialización y la ejecución, y la interfaz se apoya sobre ese trabajo en lugar de
ocultarlo.

El valor es positivo: portabilidad, control local, componibilidad, procesamiento fiable,
extensibilidad y una experiencia accesible. Una empresa debería poder obtener respuestas
útiles de sus datos sin aceptar dependencias de plataforma innecesarias.

## Lo que esto no es

Una promesa, una hoja de ruta con fechas o una afirmación de que las propuestas anteriores
se distribuyan. Esta página registra una dirección. Cada capacidad todavía tiene que
diseñarse, probarse y documentarse como todo lo demás del repositorio, y algunas de estas
direcciones pueden cambiar a medida que se construyen.

## El principio rector

> **El documento define el trabajo. El motor lo ejecuta. La presentación
> hace útil el resultado.**
