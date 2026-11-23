# MADBarcodes Agent Overview

## Framework Description

The `MADBarcodes` framework provides functionality for generating a wide variety of barcodes. It is a wrapper around the `zint` barcode generation library (2.16.0, built by the `Compressor` recipe on Apple and by `Linux/libraries.conf` / `Windows/Engine/libraries.conf` headlessly). The framework includes classes for different barcode symbologies, a view for displaying barcodes, and protocols for interacting with barcode data. It is maintained and backs the designer's barcode element on every platform.

The encode half is portable: `MADBarcode`'s zint pass feeds `-renderedPNGData` (zint's RGB bitmap through libpng) with no Core Graphics or UIKit, and `MADBarcodeView` / `MADBarcodeCache` / `-drawInRect:` stay behind `#if __APPLE__`. The headless builds compile every symbology subclass except those two UI files (`Linux/cmake/MADBarcodesSources.cmake`).

## Key Features

*   **Barcode Generation**: The framework can generate a wide variety of barcodes, including QR codes, Data Matrix, PDF417, and many others.
*   **Barcode Display**: It includes a `MADBarcodeView` class for displaying barcodes in the user interface.
*   **Extensible**: The framework is designed to be extensible, with a protocol (`MADBarcodeProtocol`) and a base class (`MADBarcode`) that can be used to add support for new barcode types.

## Core Components

*   **`zint.h`**: The header file for the `zint` barcode generation library, which is the core of this framework.
*   **`MADBarcode`**: The base class for all barcode types. It provides common functionality for generating and manipulating barcodes.
*   **`MADBarcode...`**: A set of subclasses of `MADBarcode` that implement specific barcode symbologies (e.g., `MADBarcodeQrCodeIso18004`, `MADBarcodeDataMatrixIso16022`).
*   **`MADBarcodeView`**: A `UIView` subclass that can display a barcode.
*   **`MADBarcodeProtocol`**: A protocol that defines the interface for interacting with barcode objects.
*   **`MADBarcodeType`**: An enumeration of the different barcode types that are supported by the framework.

## Usage Guidelines

The framework is the app's barcode generator: the designer's element picker creates barcode elements through it, and `MADPrintPageElementBarcode` renders them. A symbology is a `MADBarcode` subclass reachable through `+newBarcodeWithType:`; adding one means adding the subclass and its type to that factory. Familiarity with the `zint` library helps when working on the encoder. The `MADBarcodeView` class can be used to display barcodes in the UI.

## Testing and Reports

*   **Tests**: `MADBarcodes/MADBarcodesTests`, exposed by the shared `MADBarcodes`
    scheme. Run with
    `xcodebuild test -workspace Reports.xcworkspace -scheme MADBarcodes -destination 'platform=iOS Simulator,id=<device-udid>' -derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-shared`;
    take `<device-udid>` from `xcrun simctl list devices available` and see the root [`AGENTS.md`](../AGENTS.md) § Testing.
    The headless half is `Linux/Tests/MADBarcodesTests.m` (the factory, the name table and `-renderedPNGData`), run by both `./Linux/build.sh` and `Windows/Engine/build.ps1`.
*   **Tracking**: [`BUGS.md`](../docs/project/registers/BUGS.md) -- the defect register; [`TASKS.md`](../docs/project/registers/TASKS.md) -- the engineering queue. Maintain them, but do not start work from them.
