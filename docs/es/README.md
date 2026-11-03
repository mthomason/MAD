---
layout: default
lang: es-419
---

# El formato de documento `.mad`

Este documento define qué es un archivo `.mad`. Describe el formato **tal como
existe hoy**, a partir de dos documentos de muestra que se distribuyen y del código que
los lee y escribe, y después expone el formato **tal como debería definirse** para que un
lector en otra plataforma —una herramienta de línea de comandos, una compilación para
Windows— pueda abrir un documento sin depender de Core Data ni de ningún framework de
Apple.

El formato importa porque un informe es *pequeño* —las muestras distribuidas ocupan
menos de 80 KB— y porque el motor que lo ejecuta cabe en un teléfono y en un
contenedor: la misma definición se ejecuta en iOS, macOS y la compilación de Linux
sin interfaz gráfica (headless). Hacia dónde va el formato —la tabla de resultados de un
informe convertida en fuente de datos para otros informes, de modo que un documento pueda
abarcar varias bases de datos— se describe en
[`vision.md`](vision.md). La especificación también se publica como sitio web en
<https://docs.everydayapps.com>.

Todo lo de la primera mitad es medido, no inferido. Las dos muestras son
`../../MADDesigner/Resources/Assets/Samples.xcassets/Reports/Music.dataset/Music.mad` y
`…/London.dataset/London.mad`.

---

**El formato `.mad` es una especificación abierta.** Cualquiera puede leerla e
implementarla. La licencia MIT cubre el código del proyecto. Los nombres «MAD», «MAD Designer»
y «MAD Viewer», y los iconos de las aplicaciones y el resto del arte del producto, son
del autor y no están licenciados; las referencias descriptivas a archivos `.mad` y a
este proyecto son bienvenidas. Consulte
[`../../LICENSE`](https://github.com/mthomason/MAD/blob/master/LICENSE),
[`../../NOTICE`](https://github.com/mthomason/MAD/blob/master/NOTICE)
y
[`../project/THIRD_PARTY_LICENSES.md`](https://github.com/mthomason/MAD/blob/master/docs/project/THIRD_PARTY_LICENSES.md).

La especificación está organizada en un capítulo por archivo. Los capítulos 1-6 describen el formato
tal como se distribuye; el capítulo 7 es el objetivo normativo (`v1`); los capítulos 8-9 son las preguntas
abiertas y cómo se verifican las afirmaciones:

1. [Qué es un documento, en una frase](01-document.md)
2. [El contenedor](02-container.md)
3. [El almacén](03-store.md)
4. [Lectura y escritura, tal como está implementado](04-reading-writing.md)
5. [Lo que *no* está en el documento: los archivos complementarios](05-companion-files.md)
6. [Riesgos que debe afrontar un segundo lector](06-hazards.md)
7. [El formato tal como debería definirse](07-normative.md)
8. [Preguntas abiertas](08-open-questions.md)
9. [Verificación](09-verification.md)
