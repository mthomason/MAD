---
layout: default
title: MAD Designer para Windows
description: >-
  Diseñador y visor de informes relacionales nativo para Windows (WPF) para SQLite, MySQL, MariaDB, PostgreSQL y SQL Server — lienzo visual de consultas, diseñador de informes por bandas, visor con paginación exacta y exportación a HTML/CSV/JSON, sobre el mismo motor headless que Linux y macOS.
image: /assets/mad-designer-icon-512.png
lang: es-419
---

# <a href="https://raw.githubusercontent.com/mthomason/MAD/master/StaticResources/Images/icons/document/Designer%20Icon@3x.png"><img src="../assets/mad-designer-icon-512.png" alt="Icono de MAD Designer para Windows" width="48" height="48" style="vertical-align: middle; margin-right: 10px;" /></a>MAD Designer para Windows

**MAD Designer para Windows** es una aplicación de escritorio nativa para Windows Presentation Foundation (WPF) sobre .NET 10 para crear, consultar, maquetar, actualizar y exportar Mobile Analytics Documents (`.mad`). Ejecuta el mismo motor Objective-C propio (`mad.exe`) que la aplicación de macOS y la CLI `mad` headless de Linux, de modo que cada documento que escribe es compatible con las apps de iPad/iPhone, la CLI `mad` y la GitHub Action [`mad-action`](https://github.com/mthomason/mad-action).

> **Esta compilación 0.7 no está firmada.** Se compila y publica desde el código fuente público, pero no lleva un certificado comercial de firma de código, por lo que Windows SmartScreen advertirá en el primer inicio. No hay nada oculto: revise la compilación (más abajo), verifique su suma de comprobación SHA-256 y ejecútela.

## Descarga e instalación

* **Descarga directa:** [**MAD-Designer-Windows-0.7.zip**](https://github.com/mthomason/MAD/releases/download/v0.7.0/MAD-Designer-Windows-0.7.zip)
* **Versión:** app 0.7 / motor 9.0 (r4433).
* **Requisitos:** Windows 10 (1903 o posterior) o Windows 11, 64 bits. El archivo es autocontenido, así que **no hace falta instalar el runtime de .NET**. El visor usa el runtime Evergreen de Microsoft Edge WebView2, que viene con Windows 11 y con Edge actualizado; en imágenes antiguas de Windows 10, instale el [runtime Evergreen](https://developer.microsoft.com/microsoft-edge/webview2/).

1. Descargue el `.zip` y extráigalo en la carpeta que prefiera. Mantenga intacta la estructura de carpetas: la aplicación, el motor y las licencias van juntos.
2. Ejecute `Mad.Designer.Windows.exe` desde la raíz de la carpeta extraída.
3. En el primer inicio, Windows SmartScreen puede mostrar *«Windows protegió su PC»*. Elija **Más información** y luego **Ejecutar de todos modos**: la compilación no está firmada a propósito (vea más abajo).

### Qué contiene el archivo

```
MAD-Designer-Windows-0.7/
  Mad.Designer.Windows.exe   la aplicación WPF (autocontenida)
  ...                        los archivos propios de la aplicación
  CLI/Fixtures/              London.portable.mad (un informe de ejemplo) y
                             chinook.sqlite3 (los datos de ejemplo que actualiza)
  Windows/Engine/build/mad.exe       el motor headless
  Windows/Engine/build/*.dll         el runtime GNUstep/ObjC/VC del motor
  Windows/Engine/build/fonts/        las fuentes Liberation que usa la exportación a PDF
  ThirdParty/Licenses/       todas las licencias y avisos de terceros
  LICENSE, NOTICE, README-Windows.txt
```

**Dónde está el motor:** `Windows/Engine/build/mad.exe`, junto a sus DLL de runtime y a la carpeta `fonts`. La aplicación lo encuentra con la misma estructura relativa al repositorio que usa el árbol de código fuente; no utiliza una instalación global de GNUstep. Deje las carpetas donde las puso el archivo.

### Verificar la descarga

La página de la versión publica una suma de comprobación SHA-256 del archivo. Compárela después de descargarlo:

```powershell
Get-FileHash .\MAD-Designer-Windows-0.7.zip -Algorithm SHA256
```

También puede revisar la extracción archivo por archivo: el comprimido solo contiene la aplicación publicada, el motor compilado por `Windows/Engine/build.ps1`, el documento de ejemplo y los textos de las licencias. `mad.exe` es el mismo motor de línea de comandos que se documenta en la [guía de Linux](https://github.com/mthomason/MAD/blob/master/Linux/README.md) y en el [registro de compilación de Windows](https://github.com/mthomason/MAD/blob/master/docs/project/MAD_WINDOWS.md).

### Revisar y firmar esta compilación uno mismo

Puede ejecutar `mad.exe` directamente para inspeccionar un documento sin abrir la interfaz gráfica:

```powershell
.\Windows\Engine\build\mad.exe inspect .\CLI\Fixtures\London.portable.mad
```

Si quiere que Windows deje de advertir sobre *su propia* copia, cree un certificado local de firma de código y firme el ejecutable. Es una decisión de confianza local: no hace que la descarga pública sea de confianza para nadie más:

```powershell
$cert = New-SelfSignedCertificate -Type CodeSigningCert `
    -Subject "CN=MAD Designer (local review)" `
    -CertStoreLocation Cert:\CurrentUser\My
Set-AuthenticodeSignature -FilePath .\Mad.Designer.Windows.exe -Certificate $cert
```

Para confiar en ese certificado en este equipo, expórtelo e impórtelo en **Entidades de certificación raíz de confianza** con `certmgr.msc` o `Import-Certificate`; hágalo solo con un certificado que usted haya creado y controle.

## Espacios de trabajo

La aplicación tiene las mismas tres etapas de informes que la app de macOS:

* **MAD Query**: el lienzo visual de consultas (tarjetas de tabla arrastrables, conectores de join Bézier, insignias de tipo de join, filtros y agrupaciones) y el editor SQL directo, ambos contra el esquema importado del documento.
* **MAD Designer**: el espacio de trabajo de maquetación por bandas: el minimapa de página y secciones, el esquema de bandas del informe, los campos de consulta con búsqueda, el lienzo de diseño con zoom y reglas, con guías de alineación y deshacer/rehacer, y el inspector de elementos para contenido, tipografía y geometría.
* **MAD Viewer**: actualiza la consulta en la tabla materializada local, elige el tamaño de página (US Letter, US Legal, A4), recorre las páginas renderizadas y exporta.

El visor exporta **PDF**, **HTML**, **HTML Flow**, **CSV**, **JSON**, **JSON Full Report** y **Texto sin formato**, en el orden del visor de macOS. El motor escribe el PDF (el mismo exportador que usa `mad export --format pdf`), de modo que un informe grande no bloquea la ventana: la barra de estado muestra una barra de progreso indeterminada y una línea «Exportando…» hasta que se escribe el archivo, y después indica su tamaño.

## Compilar desde el código fuente

La aplicación se compila con el SDK de .NET fijado en [`Windows/global.json`](https://github.com/mthomason/MAD/blob/master/Windows/global.json) (10.0.404):

```powershell
dotnet publish Windows\App\Mad.Designer.Windows\Mad.Designer.Windows.csproj `
    -c Release -r win-x64 --self-contained true
```

El motor es la mitad más difícil. `Windows\Engine\build.ps1` reproduce la compilación nativa (Clang 20.1.8, la cadena de herramientas MSVC de Visual Studio fijada, NASM, Strawberry Perl, Meson, Python y GNUstep compilado desde siete revisiones fijadas en `C:\GNUstep`). Debe ejecutarse desde un símbolo del sistema de PowerShell elevado:

```powershell
pwsh -File .\Windows\Engine\build.ps1                 # arranque completo de la cadena de herramientas y compilación
pwsh -File .\Windows\Engine\build.ps1 -SkipToolchain  # recompilar cuando la cadena ya existe
```

Las dos suites .NET se ejecutan contra el motor compilado:

```powershell
dotnet test Windows\App\Mad.Designer.Windows.slnx
```

`Windows/Engine/build.ps1` también ejecuta las suites nativas portadas, y `Windows/package.ps1` arma el archivo de publicación sin firma y el recurso del motor para CI una vez compilados el motor y la aplicación. La receta completa, las correcciones de runtime específicas de Windows, las obligaciones de licencia y la matriz de sistemas operativos compatibles están en [`docs/project/MAD_WINDOWS.md`](https://github.com/mthomason/MAD/blob/master/docs/project/MAD_WINDOWS.md).

## Licencia

MAD tiene licencia MIT (vea [`LICENSE`](https://github.com/mthomason/MAD/blob/master/LICENSE)); los nombres «MAD», «MAD Designer» y «MAD Viewer» y las ilustraciones de la app quedan excluidos (vea [`NOTICE`](https://github.com/mthomason/MAD/blob/master/NOTICE)). El motor añade el runtime GNUstep (LGPL-2.1-or-later) y las bibliotecas C; cada componente, su licencia y la oferta escrita de relink están en la carpeta `ThirdParty/Licenses/` del archivo y en [`docs/project/THIRD_PARTY_LICENSES.md`](https://github.com/mthomason/MAD/blob/master/docs/project/THIRD_PARTY_LICENSES.md).
