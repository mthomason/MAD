# MADFoundation Agent Overview

## Framework Description

`MADFoundation` is the foundational framework for the entire _MAD Designer_ application. It provides a robust set of classes and protocols that are essential for data management, asynchronous operations, and core application functionalities. This framework is a dependency for all other frameworks in the project and does not have any _MAD_ dependencies itself.

## Key Features

*   **Asynchronous Operations**: `MADFoundation` includes a comprehensive set of classes for managing complex, asynchronous operations. `MADOperation` and its subclasses, along with `MADOperationQueue`, allow for sophisticated, dependency-based execution of tasks.
*   **Data Management**: The framework defines core data structures, such as `MADDataTable` and `MADDataColumn`, which are used to handle and manipulate data throughout the application. It also includes protocols like `MADDataProtocol` to ensure consistent data handling.
*   **Credential and Security**: `MADFoundation` provides `MADCredential` and `MADKeyChain` for securely managing user credentials and other sensitive information.
*   **Application-Level Protocols**: It defines essential protocols like `MADApplicationProtocol` that outline the core behaviors and requirements for the main application.

## Core Components

### Operations

*   **`MADOperation`**: The base class for all operations in the application. It extends `NSOperation` with advanced features like conditions and observers.
*   **`MADGroupOperation`**: A subclass of `MADOperation` that allows for the grouping of multiple operations into a single, cohesive unit.
*   **`MADBlockOperation`**: A convenient subclass for creating operations from a simple block of code.
*   **`MADOperationQueue`**: Manages the execution of `MADOperation` instances, handling dependencies and priorities.
*   **`MADOperationCondition`**: A protocol that defines conditions that must be met before an operation can be executed.

### Data Handling

*   **`MADDataTable`**: Represents a table of data, complete with columns and rows. It is a fundamental data structure used for query results and other tabular data.
*   **`MADDataColumn`**: Defines the structure of a column within a `MADDataTable`, including its data type and other properties.
*   **`MADDataType`**: An enumeration of the various data types supported by the application, such as strings, integers, and dates.
*   **`MADCacheProtocol`**: A protocol for caching data, ensuring that frequently accessed information is readily available.

### Security

*   **`MADCredential`**: A class for storing user credentials, such as usernames and passwords.
*   **`MADKeyChain`**: A utility class for securely storing and retrieving sensitive data from the system's keychain.

### Utilities

*   **`MADStringUtilities`**: A collection of utility functions for string manipulation.
*   **`BDHost`**: A class for resolving hostnames and IP addresses.
*   **`madmacros.h`**: A set of macros that provide convenient shortcuts for common coding patterns.

## Usage Guidelines

When working with any other framework in this project, it is highly likely that you will need to interact with classes and protocols from `MADFoundation`. Before creating new classes for data handling or asynchronous tasks, check this framework to see if a suitable solution already exists. Pay close attention to the operation classes, as they are central to the application's workflow.

## Testing and Reports

*   **Tests**: `MADFoundation/MADFoundationTests`. Run with
    `xcodebuild test -workspace Reports.xcworkspace -scheme MADFoundation -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`.
*   **Known issues**: [`BUGS.md`](../docs/project/BUGS.md) -- see the `## MADFoundation` section.
*   **Task queue**: [`TASKS.md`](../docs/project/TASKS.md) -- maintain it, but do not start work from it.
*   **Architecture**: [`MADDataTable_Architecture_Report.md`](../docs/project/MADDataTable_Architecture_Report.md).
