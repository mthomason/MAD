# MADBarcodes Agent Overview

## Framework Description

The `MADBarcodes` framework provides functionality for generating a wide variety of barcodes. It is a wrapper around the `zint` barcode generation library (2.16.0, built by the `Compressor` recipe). The framework includes classes for different barcode symbologies, a view for displaying barcodes, and protocols for interacting with barcode data. It is maintained and backs the designer's barcode element on Apple; it is deliberately excluded from the Linux build, where the element type is model-only.

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
    `xcodebuild test -workspace Reports.xcworkspace -scheme MADBarcodes -destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' -derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci`.
*   **Tracking**: [`BUGS.md`](../BUGS.md) -- the defect register; [`TASKS.md`](../TASKS.md) -- the engineering queue. Maintain them, but do not start work from them.
