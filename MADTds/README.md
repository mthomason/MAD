**English** | [简体中文](README_zh.md) | [日本語](README_ja.md) | [Português (Brasil)](README_pt-BR.md)

# MADTds Framework

**MADTds** is a framework for iOS that wraps around `sybdb.h` from the FreeTDS library. It simplifies integrating and using Sybase databases in iOS projects. This framework provides a native Objective-C API, making it easier to interact with Sybase databases in iOS applications.

## Features

- Simplified database operations using the `MADTdsDb` interface.
- Includes the FreeTDS library for robust support of Sybase database functionality.
- Fully compatible with iOS and built to work within the Xcode environment.
- Custom build script for managing FreeTDS dependencies.

---

## Installation

### Prerequisites

- Xcode 13 or later
- iOS 12.0 or later
- FreeTDS precompiled binaries (bundled with the framework)

### Steps

1. Clone or download the repository.
2. Add `MADTds.xcodeproj` to your Xcode workspace.
3. Link `MADTds.framework` to your target under **General > Frameworks, Libraries, and Embedded Content**.
4. Add the required headers from the `freetds/lib/include` directory to your project's search paths:
   - Go to your target's **Build Settings**.
   - Set the **Header Search Paths** to include `MADTds/freetds/lib/include`.

---

## Usage

### Importing the Framework

Add the following import statement to the file where you want to use MADTds:

```objc
#import <MADTds/MADTds.h>
#import <MADTds/MADTdsDb.h>
```

### Connecting to a Database

Here's an example of how to connect to a Sybase database and execute a query:

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

## Directory Structure

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

## Building the Framework

1. Ensure the `build_tds.sh` script has execution permissions:
   ```bash
   chmod +x build_tds.sh
   ```
2. Run the script to build the FreeTDS library:
   ```bash
   ./build_tds.sh
   ```
3. Open `MADTds.xcodeproj` in Xcode and build the framework.

---

## Documentation

Documentation is available in the `madtds/MADTds.docc` folder. To view the documentation:
1. Open `MADTds.xcodeproj` in Xcode.
2. Go to the **Product > Build Documentation** menu.

---

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Commit your changes and push them to your fork.
4. Submit a pull request describing your changes.

---

## License

This project uses the **MIT License**. See the `LICENSE` file for more details.

---

## Acknowledgments

- [FreeTDS](http://www.freetds.org) for providing the Sybase database library.
- The iOS developer community for inspiration and support. 

---
