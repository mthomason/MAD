---
layout: default
title: Desarrolladores
description: "Integra el motor de MAD, usa la CLI mad, lee el contrato del objeto de datos y compila el motor headless."
lang: es-419
---

# Desarrolladores

MAD es un motor de informes relacionales integrable: un documento `.mad` portable, un
motor Objective-C propio, y una herramienta de línea de comandos `mad` que ejecuta el mismo
motor de forma headless en Linux y Windows. Estas páginas son para quienes quieren
integrarlo, controlarlo desde un script, añadir un origen de datos o compilarlo desde el código fuente.

## Empieza aquí

* [La especificación del formato `.mad`](../README.html) — qué es un documento, el
  contenedor, el almacén y el objetivo normativo `v1`.
* [MAD Designer para macOS](../macos.html) — la aplicación nativa de `AppKit`.
* [MAD Designer para Windows](../windows.html) — la aplicación nativa de WPF.
* [Visión](../vision.html) — los informes como orígenes de datos componibles.

## Motor y CLI

* [La herramienta de línea de comandos `mad`](cli.html) — abrir, inspeccionar, consultar, actualizar y
  exportar un documento sin interfaz de usuario.
* [El objeto de datos](data-object.html) — la definición, el esquema y el
  conjunto de resultados de un informe como un solo contrato.
* [Informes multi-origen](multi-source.html) — los informes como tablas, y los controladores
  para cualquier cosa que devuelva una tabla.
* [Pegar SQL en el diseñador de consultas](sql-entry.html) — el subconjunto admitido,
  el analizador y la ruta de aplicación.

## Arquitectura

* [La arquitectura de MADDataTable](architecture/data-table.html) — el
  clúster de clases de tabla de datos a través de los frameworks.
* [La capa MADModel](architecture/model-layer.html) — el modelo de lectura del documento
  sobre las entidades `Rptq`.
* [MADArrayCaching](architecture/array-caching.html) — el arreglo respaldado por disco de la
  caché de renderizado.

## Compilación y pruebas

* [Compilar el motor en Linux](build/linux.html) — la compilación con Docker y los
  doce frameworks headless.
* [Compilar el motor en Windows](build/windows.html) — el toolchain fijado de Clang y
  GNUstep.
* [Portabilidad y la aplicación nativa de macOS](build/macos.html) — la auditoría de
  frameworks y la arquitectura de AppKit.
* [La compilación de bibliotecas estáticas de Compressor](build/libraries.html) — las bibliotecas
  C de terceros y cómo llega Xcode a ellas.
* [El escritor de PDF headless](build/pdf.html) — Cairo, FreeType y
  exportación determinista.

## Satélites y código fuente

* [Repositorios satélite](satellites.html) — cómo se publican `mad-action` y la
  imagen de contenedor desde este repositorio.
* [Código fuente](https://github.com/mthomason/MAD) — el repositorio, los issues y la
  [guía de contribución](https://github.com/mthomason/MAD/blob/master/CONTRIBUTING.md).
