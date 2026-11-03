[English](README.md) | [简体中文](README_zh.md) | [日本語](README_ja.md) | [Português (Brasil)](README_pt-BR.md) | [Deutsch](README_de.md) | **Español**

# Framework MADTds

**MADTds** es un framework para iOS que envuelve `sybdb.h` de la biblioteca FreeTDS. Simplifica la integración y el uso de bases de datos Sybase en proyectos de iOS. Este framework proporciona una API nativa de Objective-C, lo que facilita la interacción con bases de datos Sybase en aplicaciones de iOS.

## Características

- Operaciones de base de datos simplificadas mediante la interfaz `MADTdsDb`.
- Incluye la biblioteca FreeTDS para un soporte robusto de la funcionalidad de bases de datos Sybase.
- Totalmente compatible con iOS y diseñado para funcionar dentro del entorno de Xcode.
- Script de compilación personalizado para gestionar las dependencias de FreeTDS.

---

## Instalación

### Requisitos previos

- Xcode 13 o posterior
- iOS 12.0 o posterior
- Binarios precompilados de FreeTDS (incluidos con el framework)

### Pasos

1. Clone o descargue el repositorio.
2. Añada `MADTds.xcodeproj` a su espacio de trabajo de Xcode.
3. Enlace `MADTds.framework` a su objetivo en **General > Frameworks, Libraries, and Embedded Content**.
4. Añada las cabeceras necesarias del directorio `freetds/lib/include` a las rutas de búsqueda de su proyecto:
   - Vaya a **Build Settings** de su objetivo.
   - Configure **Header Search Paths** para incluir `MADTds/freetds/lib/include`.

---

## Uso

### Importar el framework

Añada la siguiente sentencia de importación al archivo donde quiera usar MADTds:

```objc
#import <MADTds/MADTds.h>
#import <MADTds/MADTdsDb.h>
```

### Conectarse a una base de datos

Aquí tiene un ejemplo de cómo conectarse a una base de datos Sybase y ejecutar una consulta:

```objc
MADTdsDb *db = [[MADTdsDb alloc] init];

// Configure the connection
db.server = @"your-server";
db.database = @"your-database";
db.username = @"your-username";
db.password = @"your-password";

if ([db connect]) {
    NSLog(@"Connected to database successfully.");
    NSArray *results = [db executeQuery:@"SELECT * FROM your_table"];
    NSLog(@"Query Results: %@", results);
} else {
    NSLog(@"Failed to connect to database.");
}
```

---

## Estructura de directorios

```
MADTds.xcodeproj/              - Xcode project configuration
MADTds/                        - Core framework source
├── MADTds.h                   - Framework entry point
├── MADTdsDb.h                 - Database connection interface
├── MADTdsDb.m                 - Database connection implementation
madtds/MADTds.docc/            - Documentation for the framework
freetds/                       - Bundled FreeTDS library
├── lib/include/               - Header files for FreeTDS
├── lib/libct.a                - FreeTDS Client Library
├── lib/libsybdb.a             - FreeTDS Database Library
build_tds.sh                   - Script to manage FreeTDS builds
README.md                      - Project documentation
```

---

## Compilar el framework

1. Asegúrese de que el script `build_tds.sh` tiene permisos de ejecución:
   ```bash
   chmod +x build_tds.sh
   ```
2. Ejecute el script para compilar la biblioteca FreeTDS:
   ```bash
   ./build_tds.sh
   ```
3. Abra `MADTds.xcodeproj` en Xcode y compile el framework.

---

## Documentación

La documentación está disponible en la carpeta `madtds/MADTds.docc`. Para ver la documentación:
1. Abra `MADTds.xcodeproj` en Xcode.
2. Vaya al menú **Product > Build Documentation**.

---

## Contribuir

¡Las contribuciones son bienvenidas! Siga estos pasos:

1. Haga un fork del repositorio.
2. Cree una rama nueva para su funcionalidad o corrección de errores.
3. Haga commit de sus cambios y envíelos a su fork.
4. Envíe una pull request describiendo sus cambios.

---

## Licencia

Este proyecto usa la **licencia MIT**. Consulte el archivo `LICENSE` para más detalles.

---

## Agradecimientos

- [FreeTDS](http://www.freetds.org) por proporcionar la biblioteca de bases de datos Sybase.
- La comunidad de desarrolladores de iOS por su inspiración y apoyo.
