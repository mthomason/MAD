[English](CONTRIBUTING.md) | [简体中文](CONTRIBUTING_zh.md) | [日本語](CONTRIBUTING_ja.md) | [Português (Brasil)](CONTRIBUTING_pt-BR.md) | [Deutsch](CONTRIBUTING_de.md) | **Español**

# Contribuir a MAD

Gracias por estar aquí. MAD (Mobile Analytics Document) es el proyecto —las
aplicaciones MAD Designer y MAD Viewer, los frameworks y el motor sin interfaz
gráfica—, y las costuras para trabajo nuevo son el punto: un nuevo driver de base
de datos, un nuevo elemento de documento, un nuevo formato de exportación. El tutorial
para escribir drivers
([`docs/tutorials/driver-authoring.md`](docs/es/tutorials/driver-authoring.md))
recorre el primero; es la primera contribución prevista.

## Requisitos previos

* **macOS con Xcode** — el lado de iOS es un espacio de trabajo de catorce frameworks
  más la aplicación, compilados para iOS 15 y posterior. Los frameworks son Objective-C.
* **Docker** — la compilación de Linux del motor sin interfaz gráfica: una imagen que compila
  desde fuentes la cadena de herramientas de Objective-C (libobjc2, libdispatch, GNUstep) y las bibliotecas
  C, compila los once frameworks sin interfaz gráfica y ejecuta sus suites.
* No se necesita ningún servidor de base de datos para contribuir: las suites en vivo de MySQL, SQL Server y
  PostgreSQL se omiten cuando no hay ningún servidor disponible, y
  [`docs/project/DEVELOPER.md`](docs/project/DEVELOPER.md) documenta los
  contenedores Docker que los proporcionan.

## Primeros pasos

1. Haga un fork del repositorio y clone su fork.
2. Compile y pruebe antes de cambiar nada, para conocer la línea de base:

   ```sh
   # iOS: any framework's suite, against the iOS Simulator
   xcodebuild test -workspace Reports.xcworkspace -scheme MADFoundation \
       -destination 'platform=iOS Simulator,id=<device-udid>' \
       -derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-shared
   ```

   ```sh
   # Linux: the whole headless engine — 126 test executables, 1,303 tests
   ./Linux/build.sh
   ```

   [`docs/project/DEVELOPER.md`](docs/project/DEVELOPER.md) contiene la matriz completa de
   comandos, la ruta compartida de DerivedData que esperan los
   frameworks y la configuración de las bases de datos de prueba.
3. Elija algo. Un nuevo driver, un elemento o un issue etiquetado
   «good first issue». Pequeño es bueno: la cultura de revisión aquí es exacta.

## La regla de las pruebas primero

**Escriba primero la prueba que falla.** Es la cultura del proyecto, no una
sugerencia: la prueba fija el comportamiento antes de que exista el código, y la corrección es
el cambio que la pone en verde. Para trabajo de formato o de datos, haga una instantánea de la
fixture anterior al cambio en lugar de generar el valor esperado con el código nuevo:
la fixture es el testigo de que el comportamiento era real.

El ciclo, en orden:

1. Añada una prueba que falla y que declare el comportamiento que pretende.
2. Ejecútela; observe que falla por el motivo correcto.
3. Implemente y después póngala en verde.
4. Ejecute toda la suite —iOS *y* `./Linux/build.sh` si tocó algo
   que compila la compilación de Linux (consulte `Linux/cmake/*Sources.cmake`). Cada commit
   debe dejar todas las suites en verde.

Las suites de Linux registran las divergencias de plataforma conocidas como líneas `NEED` en lugar de
omitirlas silenciosamente: una nueva `NEED` debe llevar un motivo, y una divergencia
que no se corrige ni se registra es un cambio que falla.

## Estilo

* Tabulaciones, no espacios. Comentarios donde se ganan su lugar, no en todas partes.
* El código deliberadamente sin usar se marca con el atributo `unused` de clang en la
  declaración: una advertencia de código sin usar no marcada significa que el código está muerto.
* Los archivos nuevos llevan la cabecera de una línea `Copyright © 2012-2026 Michael
  Thomason. SPDX-License-Identifier: MIT` (`//` para código fuente, `#` para scripts).
* [`docs/project/BUGS.md`](docs/project/BUGS.md) registra los defectos abiertos con
  las pruebas que los fijan; cuando corrija uno, la entrada pasa a
  [`docs/project/BUGS_FIXED.md`](docs/project/BUGS_FIXED.md): una corrección que
  no se registra no ocurrió.

## Developer Certificate of Origin

Este proyecto requiere una firma DCO en lugar de una CLA. Cada commit debe terminar
con:

    Signed-off-by: Name <email>

(`git commit -s` la añade). Al añadir la línea, usted certifica, según
[developercertificate.org](https://developercertificate.org), que escribió
el cambio o tiene derecho a contribuirlo bajo la licencia del proyecto
(MIT, consulte `LICENSE`). La comprobación DCO se ejecuta en las pull
requests una vez que el repositorio se publica en GitHub.

## Pull requests

* Un asunto por PR. Mantenga los commits revisables; el historial del proyecto es un
  registro, no un bloc de notas.
* Rellene la plantilla de PR: la lista de verificación de pruebas primero está ahí para el
  revisor, y las respuestas «no aplica» son válidas donde lo sean.
* Una PR que toque la compilación de Linux debe mostrar `./Linux/build.sh` en verde en su
  propia rama.

## Issues

Las plantillas de informe de errores y de propuesta de driver están en
[`.github/ISSUE_TEMPLATE/`](.github/ISSUE_TEMPLATE/). Los problemas de seguridad van por
la vía privada de [`SECURITY.md`](SECURITY_es.md), nunca a un issue público.

## Ayuda

Pregunte en un issue (o en el tablero de discusiones cuando se abra). El mantenedor
responde a cada issue; el proyecto es un esfuerzo solitario que crece hacia una comunidad,
así que una pregunta clara que muestre lo que ha intentado obtiene la respuesta más rápida.

## Soporte

El código de MAD tiene licencia MIT y es libre, y las contribuciones son el mejor tipo de
apoyo. Si el proyecto le ahorra tiempo a su equipo y quiere dar más, el
mantenedor acepta [GitHub Sponsors](https://github.com/sponsors/mthomason) y créditos
de API para el desarrollo impulsado por agentes: todo ello vuelve al
trabajo (consulte la [README](README_es.md), sección «Soporte»).
