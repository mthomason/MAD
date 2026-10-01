# MADExplorer Agent Overview

## Framework Description

The `MADExplorer` framework provides the user interface components for the file explorer in the _MAD Designer_ application. It is responsible for displaying files and directories, handling user interactions, and coordinating with the `MADFileManager` framework to perform file operations. This framework is a key part of the application's user experience, as it is the first thing a user sees when they launch the app.

## Key Features

*   **File and Directory Display**: The framework includes UI components for displaying files and directories in a collection view.
*   **User Interaction**: It handles user interactions such as selecting, opening, and deleting files.
*   **Document Management**: `MADExplorer` includes classes for managing the opening of documents and saving files.
*   **Extensible File Locations**: The framework is designed to be extensible, allowing for the addition of new file storage locations through the `MADFileLocationManager`.

## Core Components

### UI Components

*   **`MADCollectionViewCellDocument`**: A `UICollectionViewCell` subclass that is used to display a single document in the file explorer. It likely shows a thumbnail of the document, its name, and other relevant information.
*   **`MADBackgroundViewSelected`**: A view that is used to indicate that a file or directory is selected.

### Document and File Management

*   **`MADOpenDocumentManager`**: A class that manages the process of opening a document. It likely coordinates with `MADFileManager` to access the file and then presents the document to the user.
*   **`MADFileLocationManager`**: A class that manages the different file storage locations that are available in the application (e.g., local storage, iCloud).
*   **`MADSaveFileProtocol`**: A protocol for objects that can save files. This is likely used to ensure that documents are saved correctly.

### Delegates and Protocols

*   **`MADExplorerViewDelegate`**: A protocol that allows other objects to be notified of events that occur in the file explorer, such as the selection of a file.

## Usage Guidelines

When you need to make changes to the file explorer's user interface or behavior, you will need to work with the classes in this framework. The `MADCollectionViewCellDocument` class is the place to start if you need to change how documents are displayed. The `MADOpenDocumentManager` class is the key to understanding how documents are opened.

If you need to add a new file storage location to the application, you will need to work with the `MADFileLocationManager` class. This class is designed to be extensible, so you should be able to add new locations without modifying the existing code extensively.

## Testing and Reports

*   **Tests**: `MADExplorer/MADExplorerTests`. Run with
    `xcodebuild test -workspace Reports.xcworkspace -scheme MADExplorer -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`.
*   **Known issues**: [`BUGS.md`](../BUGS.md) -- see the `## MADExplorer` section.
*   **Task queue**: [`TASKS.md`](../TASKS.md) -- maintain it, but do not start work from it.
