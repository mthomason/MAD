---
layout: default
lang: es-419
---

## 7. El formato tal como debería definirse

Este es el objetivo normativo. Es deliberadamente una diferencia pequeña respecto de lo que
existe, porque lo que existe está casi bien.

### 7.1 Identificación por contenido, no por nombre

Un archivo `.mad` debería empezar con una cabecera fija **fuera** del flujo de
compresión, para que un lector pueda identificarlo desde los primeros bytes:

```
offset 0  8 bytes   "MADFILE\0"      magic
offset 8  2 bytes   uint16 LE        format major version
offset 10 2 bytes   uint16 LE        format minor version
offset 12 4 bytes   uint32 LE        flags (bit 0: WAL checkpointed)
offset 16 ...       bzip2 stream
```

Fundamento: esto es lo que elimina el problema de Windows. La extensión pasa a ser una
*convención* para el explorador de archivos, no lo que identifica el archivo. Un `.mad`
renombrado a `.zip`, o un documento recibido por un canal que altera las extensiones,
sigue siendo reconociblemente un `.mad`. También permite detectar la versión sin descomprimir.

La cabecera es incompatible hacia atrás con las dos muestras distribuidas. Eso es
aceptable *solo* porque un lector puede recurrir a otra vía: sin los bytes mágicos `MADFILE` → se trata como un
documento heredado v0 (§7.4).

### 7.2 Un almacén con checkpoint

El escritor aplica un checkpoint al WAL del almacén antes de archivar, de modo que los miembros WAL y SHM
pasan a ser opcionales y un lector que los encuentre debe reproducirlos en lugar de ignorarlos.
El resultado se registra en el bit 0 de los flags de la cabecera —**no** en `meta.plist`, que se
escribe antes de que se ejecute el checkpoint, así que el flag es el registro autoritativo y se
puede leer sin descomprimir.

Esto también reduce los documentos: la muestra `Music` dedica un tercio de sus bytes a un WAL
que un checkpoint integraría en el archivo principal.

### 7.3 Miembros

| Miembro | Obligatorio | Contenido |
|---|---|---|
| `meta.plist` | sí | `generator`, `version` |
| `StoreContent/<name>` | sí | la definición del documento |
| `StoreContent/<name>-wal` / `-shm` | no | presentes solo cuando no hay checkpoint (bit 0 de los flags de la cabecera = 0) |
| `AdditionalContent/` | no | `thumbnail@2x.png` |

### 7.4 Compatibilidad

- **v0** — lo que se distribuye hoy: sin bytes mágicos, posiblemente un WAL, `version` 1. Los lectores deben
  aceptarlo indefinidamente; ambos documentos de muestra son v0.
- **v1** — cabecera mágica, almacén con checkpoint, `version` 1, nuevos miembros como arriba.

Un escritor emite v1 y, por lo demás, `meta.plist` sin cambios. Un lector detecta v0 por
la ausencia de los bytes mágicos.
