# MAD Agent Overview

## Framework Description

The `MAD` framework is the central component of the _MAD Designer_ application. It contains the Core Data model definitions, document handling logic, and the core functionality for creating and managing reports. This framework brings together all the other components of the application to deliver the main features of _MAD Designer_. It has dependencies on `MADFoundation`, `MADCocoaExtensions`, and `MADAPI`.

## Key Features

*   **Core Data Model**: The `MAD` framework defines the application's Core Data model, which is used to store all the data related to documents, queries, and report elements. The model classes are prefixed with `Rptq`.
*   **Document Management**: It includes the `MADocument` class, which is a subclass of `UIManagedDocument`. This class is responsible for managing the lifecycle of a `.mad` document, including its creation, saving, and loading.
*   **Report Generation**: The framework contains the logic for rendering reports, including classes for page layout (`MADPrintPageRenderer`), data formatting (`MADDataFormatter`), and report sectioning (`MADReportSectionRepresentation`).
*   **Query and Element Factories**: It provides factories, such as `RptqDocumentElementFactory`, for creating various types of document elements (e.g., labels, charts, barcodes).

## Core Components

### Core Data Model (Rptq classes)

*   **`RptqDocument`**: The root object of the Core Data model, representing a single `.mad` document.
*   **`RptqDatabase`**: Represents the database connection and schema information for a document.
*   **`RptqQuery`**: Represents a query defined within a document, including its tables, fields, and predicates.
*   **`RptqDocumentElement`**: The base class for all elements that can be placed on a report, such as labels, charts, and images. Various subclasses exist for specific element types.
*   **`RptqDocumentSection`**: Represents a section of a report, such as the header, footer, or detail section.

### Document and Report Handling

*   **`MADocument`**: The main document class that manages the Core Data stack and the lifecycle of a `.mad` file.
*   **`MADPrintPageRenderer`**: A class that handles the rendering of a report to a printable format.
*   **`MADReportFormatter`**: A class responsible for formatting the data that appears on a report.
*   **`MADDesignerLayout`**: A class that manages the layout of elements in the report designer.

### Operations

The `MAD` framework defines a large number of `MADOperation` subclasses that are specific to document and data handling. These include operations for:
* Creating and setting up new documents (`MADOperationCreateDocument...`)
* Managing the document lifecycle (`MADOperationDocumentCloseDocument`)
* Interacting with the keychain (`MADOperationKeyChain...`)

## Usage Guidelines

This framework is the core of the application, and any significant changes to the application's functionality will likely involve modifying code within this framework. When working with documents, queries, or report elements, you will be interacting with the Core Data model classes (prefixed with `Rptq`). Be sure to use the provided factory classes when creating new document elements.

When performing asynchronous tasks related to documents or data, look for an existing `MADOperation` subclass in this framework before creating a new one. The operations here are designed to work with the application's document and data models.

## Testing and Reports

*   **Tests**: `MAD/MADTests`. Run with
    `xcodebuild test -workspace Reports.xcworkspace -scheme MAD -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`.
*   **Known issues**: [`BUGS.md`](../BUGS.md) -- see the `## MAD (framework)` section.
*   **Architecture**: [`MADDataTable_Architecture_Report.md`](../MADDataTable_Architecture_Report.md).
