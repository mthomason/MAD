# MADFileManager Agent Overview

## Framework Description

The `MADFileManager` framework is responsible for all file-related operations in the _MAD Designer_ application. It provides a high-level API for working with both local and iCloud files, abstracting away the complexities of file coordination and metadata management. This framework is essential for the application's file explorer and document handling capabilities.

## Key Features

*   **Unified File Management**: The framework provides a unified interface for managing files, regardless of their location (local or iCloud).
*   **File Coordination**: It includes classes for file coordination, which is crucial for preventing data corruption when multiple processes or threads access the same file.
*   **Metadata Handling**: `MADFileManager` provides classes for reading and writing file metadata, such as creation date, modification date, and file size.
*   **Storage State**: The framework includes functionality for monitoring the storage state of the device, which is important for handling low-storage situations.

## Core Components

### File Coordination and Control

*   **`MADFilesController`**: The main class for managing files. It provides a high-level interface for enumerating, creating, deleting, and moving files.
*   **`MADLocalFileCoordinator`**: A class that handles file coordination for local files.
*   **`MADCloudFileCoordinator`**: A class that handles file coordination for files stored in iCloud.
*   **`MADFileLocationManagerDelegate`**: A protocol for objects that manage file locations, allowing for a flexible and extensible file management system.

### File Information and Metadata

*   **`MADFileInfo`**: A class that encapsulates information about a file, such as its name, path, and size.
*   **`MADMetaData`**: A class for reading and writing metadata associated with a file.
*   **`MADMetaDataLocal`**: A subclass of `MADMetaData` that is specific to local files.

### Utilities and Delegates

*   **`MADFileUtilities`**: A collection of utility functions for common file-related tasks.
*   **`MADFilesControllerDelegate`**: A protocol that allows objects to be notified of changes in the file system, such as the creation or deletion of files.
*   **`MADStorageState`**: A class for monitoring the available storage space on the device.

## Usage Guidelines

When you need to perform any file-related operations, such as creating, deleting, or moving files, you should use the `MADFilesController` class. This will ensure that all file operations are properly coordinated and that the UI is updated accordingly. When you need to get or set information about a file, use the `MADFileInfo` and `MADMetaData` classes.

If you need to support a new file storage location (e.g., a different cloud service), you will need to create a new class that conforms to the `MADFileLocationManagerDelegate` protocol.

## Testing and Reports

*   **Tests**: `MADFileManager/MADFileManagerTests`. Run with
    `xcodebuild test -workspace Reports.xcworkspace -scheme MADFileManager -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`.
*   **Known issues**: [`BUGS.md`](../docs/project/BUGS.md) -- see the `## MADFileManager` section.
*   **Task queue**: [`TASKS.md`](../docs/project/TASKS.md) -- maintain it, but do not start work from it.
