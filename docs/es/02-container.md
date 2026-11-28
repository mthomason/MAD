---
layout: default
lang: es-419
---

## 2. El contenedor

```
$ file Music.mad
Music.mad: bzip2 compressed data, block size = 900k
```

El escritor es `MADArchiveManager.m:86-100`:

| Propiedad | Valor | Dónde |
|---|---|---|
| Formato del archivo | `pax restricted` | `MADArchiveManager.m:88` |
| Filtro de compresión | bzip2 | `MADArchiveManager.m:95` |
| Archivos ocultos | **omitidos** | `MADArchiveManager.m:111` |
| Rutas de los miembros | relativas a la raíz del archivo | `MADArchiveManager.m:124-130` |

`pax restricted` significa pax POSIX con las extensiones que ustar ya cubre, de modo que
cualquier implementación de tar puede leer el archivo. bzip2 está en todos los gestores de
paquetes de todas las plataformas. **Nada del contenedor es específico de Apple.** Un archivo
`.mad` se descomprime con `tar xjf` tanto en macOS como en Linux y Windows.

### Miembros

Ambas muestras distribuidas contienen exactamente estas seis entradas, en este orden:

```
AdditionalContent/
StoreContent/
StoreContent/analyitics-wal
StoreContent/analyitics-shm
StoreContent/analyitics
meta.plist
```

`AdditionalContent/` está presente pero vacío en ambas muestras. Es el directorio que el
documento usa para una miniatura: `MADocument.m:571-583` lee
`thumbnail@2x.png` desde allí hacia `extraInformation`, y
`MADURLFactory.m:58-68` construye esa ruta. Lo escribe
`-writeAdditionalContent:toURL:…` (`MADocument.m:617-648`) como parte del
protocolo de contenido adicional de `UIManagedDocument`.

`StoreContent/` es el almacén persistente de Core Data, nombrado por
`+persistentStoreName` (`MADocument.m:650`), que devuelve `@"analyitics"`.

> El nombre está mal escrito, y está mal escrito **en disco, en documentos distribuidos**.
> No es una errata en un comentario que se pueda corregir: cambiarle el nombre cambia el
> nombre del archivo del almacén y rompe todos los archivos `.mad` existentes. Se queda, y esta nota existe para que
> el siguiente lector no lo «corrija».

`meta.plist` son los metadatos propios del documento, escritos en `MADocument.m:636-644`:

```xml
{
  "generator" => "MAD Designer"
  "version"   => 1
}
```

La versión se escribe como double (`MADocument.m:611`) y se lee como entero en
las muestras. Los consumidores deberían aceptar cualquiera de las dos formas.

### La cabecera de composición `1.1`

Un documento compuesto escribe la versión de formato **1.1** en lugar de 1.0 y añade un
miembro `requirements.plist` junto a `meta.plist`. El registro es un plist pequeño:

```xml
{
  "format" => 1,
  "requiredCapabilities" => ["query-composition"]
}
```

Un lector comprueba cada capacidad requerida contra la compilación antes de abrir el almacén;
una capacidad desconocida, un registro ausente o un registro mal formado produce un error
accionable de «actualice MAD Designer» en lugar de leer mal el documento. Un informe normal
permanece en **1.0** sin miembro de requisitos: el registro es una adición, así que el resto
del contenedor no cambia. Las constantes de versión son
`MADFileFormatMajorVersion`, `MADFileFormatMinorVersion` y
`MADFileFormatCompositionMinorVersion` en `MAD/Source/MADConstants.m`; el archivo
escribe y comprueba el registro en `MADArchiveManager.m`.
