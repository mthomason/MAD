---
layout: default
title: "Repositorios satélite"
description: "Cómo se publican `mad-action` y la imagen de contenedor desde este repositorio."
lang: es-419
---

# Repositorios satélite

Esta página explica cómo se publican la GitHub Action `mad-action` y la imagen de contenedor desde este repositorio, y la regla que mantiene actualizado un satélite.

Un satélite es un repositorio fuera de `mthomason/MAD` que publica algo
construido a partir de MAD: hoy la GitHub Action `mad-action`, junto con la imagen de
contenedor en GHCR. Los satélites son **objetivos de publicación, no forks**. MAD es la
fuente de verdad; un satélite se genera a partir de un directorio aquí, y lo único
que cruza la frontera es el artefacto publicado y los archivos bajo
`satellites/<name>/`.

Este es el mismo modelo que el de la imagen: `Linux/` es la fuente,
`.github/workflows/publish-image.yml` publica `ghcr.io/mthomason/mad` en
cada push a `master`, y nada copia el código fuente del motor a ningún otro lado.
Un usuario de la acción obtiene un motor nuevo porque la etiqueta de la imagen se movió, no porque el
repositorio satélite recibiera un commit.

## Registro

| Satélite | Fuente | Publicado por | Referencias | Etiqueta de versión |
|---|---|---|---|---|
| [mthomason/mad-action](https://github.com/mthomason/mad-action) | `satellites/mad-action/` | `.github/workflows/publish-mad-action.yml` | `ghcr.io/mthomason/mad:latest` | `v1` (móvil; `satellites/mad-action/VERSION`) |
| `ghcr.io/mthomason/mad` (imagen, no un repo) | `Linux/` | `.github/workflows/publish-image.yml` | — | `latest`, `<short-sha>` |

`mthomason/mad-action` se genera. No lo edites directamente: un cambio va
a `satellites/mad-action/` aquí, a través de la compuerta normal de PR, y el flujo de trabajo de publicación
lo traslada. Los issues y pull requests de la acción pertenecen a
`mthomason/MAD`.

## Qué necesita un commit en el satélite

| Cambio en MAD | Actualización del satélite |
|---|---|
| Código del motor o de la aplicación | Ninguna — el siguiente push a master republica `:latest`, y la acción lo ejecuta |
| Documentación | Ninguna — el README de la acción enlaza a MAD |
| Verbos de la CLI, opciones, entrada de credenciales o formatos de exportación | `satellites/mad-action/action.yml`, `README.md` si cambian la asignación de entradas o la documentación |
| Política de nombre o etiqueta de imagen | `satellites/mad-action/action.yml`, `README.md`, los flujos de trabajo |
| `CLI/Fixtures/London.portable.mad` | Automático: el flujo de trabajo de publicación lo copia a `fixtures/` |
| `LICENSE` o `NOTICE` | Automático: el flujo de trabajo de publicación copia ambos |
| `satellites/mad-action/**` | Automático: el flujo de trabajo de publicación sincroniza el directorio |

El flujo de trabajo de publicación se ejecuta en `master` cuando cambia una de esas rutas, y a
mano con `workflow_dispatch`. Prueba la fuente contra la imagen publicada, sincroniza el
destino, hace commit como `MAD release bot`, mueve la etiqueta mayor,
y deja que el flujo de trabajo de pruebas propio del destino se ejecute en el push. El flujo de trabajo de pruebas del satélite
también está programado a diario — el canario que detecta un cambio del motor
que rompe el contenedor aunque el código fuente del contenedor no haya cambiado.

GitHub desactiva los flujos de trabajo programados después de 60 días sin actividad en el repositorio.
El siguiente commit de sincronización lo reactiva; un `workflow_dispatch` manual ejecuta la prueba
de inmediato mientras tanto. Esta es la única parte del arreglo que puede
quedarse en silencio sin fallar.

## La lista de verificación de lanzamiento

**Un cambio normal en el código fuente.**

1. Edita `satellites/mad-action/` y/o el fixture aquí.
2. Ejecuta el contenedor localmente si la interfaz cambió (`./Linux/build.sh
   --verify` compila `mad-cli:latest`; la acción puede apuntarse a él con
   `image: mad-cli:latest`).
3. Abre el PR. `Linux verification` ejecuta el contenedor contra la propia
   imagen de tiempo de ejecución del PR (`linux.yml`), además de la prueba de la acción en el
   destino.
4. Haz merge. `Publish mad-action` prueba y publica; la ejecución de pruebas propia del satélite,
   en el repositorio destino, debe entonces estar en verde.

**Un cambio de contrato de la CLI.** El mismo PR actualiza las entradas de `action.yml` y el
README. La publicación mueve `v1`; los usuarios existentes obtienen el nuevo contenedor en su
siguiente ejecución. Si el cambio es incompatible — una entrada renombrada o eliminada, un valor predeterminado
cambiado de forma incompatible — sube `satellites/mad-action/VERSION` a `v2` en el
mismo PR y actualiza las referencias `@v1` del README. El flujo de trabajo entonces mueve
`v2` y deja `v1` donde está, así que los usuarios de `mthomason/mad-action@v1` conservan la
versión mayor antigua hasta que se muevan.

**Una actualización de fixture.** Regenera el fixture en MAD
(`CLI/Fixtures/README.md`); el filtro de rutas lo copia. No edites la copia en
el repositorio satélite.

**Rotación de la clave de despliegue.** Genera una nueva clave ed25519, añade su mitad pública a
`mthomason/mad-action` como clave de despliegue de escritura, establece la mitad privada como el
secreto `MAD_ACTION_DEPLOY_KEY` en `mthomason/MAD`, despacha `Publish
mad-action`, y luego elimina la clave de despliegue antigua. La clave está limitada al único
repositorio destino y solo puede escribir.

## Configuración única, registrada

El repositorio destino se creó vacío y público. La rama predeterminada de GitHub es
`main`, y la primera publicación la llena; el flujo de trabajo empuja a `main`. No se
inicializó con un README ni una licencia, porque la primera sincronización suministra
ambos. Los issues y la wiki están deshabilitados allí: el README envía ambos a MAD. Si
alguna vez se recrea, repite esto:

1. `gh repo create mthomason/mad-action --public`
2. Deshabilita los issues y la wiki.
3. Añade una clave de despliegue de escritura titulada `MAD publish workflow`.
4. Establece su mitad privada como el secreto `MAD_ACTION_DEPLOY_KEY` en
   `mthomason/MAD`.
5. Despacha `Publish mad-action`.

El satélite no tiene dependencias de terceros propias: su cuerpo es
`docker run` de la imagen publicada, y sus archivos de licencia son los de MAD
(`LICENSE`, `NOTICE`).

## Añadir otro satélite

Crea `satellites/<name>/` aquí, añade un flujo de trabajo de publicación con la forma de
`publish-mad-action.yml`, y añade la fila del registro anterior. Las reglas son las
mismas: MAD es la fuente de verdad, el satélite consume un artefacto publicado,
y un archivo de versión (o equivalente) nombra la etiqueta móvil que un usuario fija. No
dupliques el código fuente del motor en un satélite; ya viaja en la imagen.
