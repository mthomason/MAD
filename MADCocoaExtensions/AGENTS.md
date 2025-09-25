# MADCocoaExtensions Agent Overview

## Framework Description

`MADCocoaExtensions` is a vital framework that provides a wide range of extensions and helper classes for the Cocoa Touch framework. It is designed to simplify common UI tasks, enhance standard components, and provide convenient utilities that can be used throughout the _MAD Designer_ application. This framework depends on `MADFoundation`.

## Key Features

*   **UI Helpers**: The framework includes a variety of helper classes and categories that simplify working with UI elements. This includes extensions for `UIColor`, `NSNumberFormatter`, and `UIApplication`.
*   **Custom UI Components**: `MADCocoaExtensions` provides custom UI components like `MADLabelTitle`, `MADTextField`, and `MADAlertController` that offer enhanced functionality beyond the standard UIKit components.
*   **Styling and Layout**: The framework introduces classes for managing layout and styling, such as `MADMargin`, `MADPadding`, `MADBorderStyle`, and `MADTextStyle`. These classes help maintain a consistent look and feel across the application.
*   **Error Handling**: It includes extensions for `NSError` that make it easier to create and manage error objects, which is crucial for a robust application.

## Core Components

### UI Components and Helpers

*   **`MADAlertController`**: A custom alert controller that provides more flexibility than the standard `UIAlertController`.
*   **`MADLabelTitle`**: A specialized label class for titles, likely with predefined styling.
*   **`MADTextField`**: A custom text field with additional features.
*   **`MADViewHelpers`**: A collection of helper functions for working with `UIView` objects.
*   **`UIColor+EverydayApps`**: A category that adds a custom color palette to `UIColor`.
*   **`UIApplication+Helpers`**: A category that provides helper methods for the main application object.

### Styling and Layout

*   **`MADMargin`**: A class for defining margins around UI elements.
*   **`MADPadding`**: A class for defining padding within UI elements.
*   **`MADBorderStyle`**: A class for defining the style of borders, such as color and width.
*   **`MADTextStyle`**: A class for defining text styles, including font, color, and alignment.
*   **`CGGeometry+Extras`**: A category that provides extra functions for working with Core Graphics geometry.

### Utilities

*   **`NSError+Constructors`**: A category that simplifies the creation of `NSError` objects.
*   **`NSNumberFormatter+MADExtensions`**: A category that adds convenient formatting options to `NSNumberFormatter`.
*   **`MTMath`**: A utility class for mathematical calculations.
*   **`MFMailComposeViewController+MADExtensions`**: A category that provides helper methods for the mail compose view controller.

## Usage Guidelines

When you need to create or modify UI elements, consult this framework first. It is likely that `MADCocoaExtensions` already provides a helper class or category that can simplify your task. Use the styling classes (`MADMargin`, `MADPadding`, etc.) to ensure that your UI changes are consistent with the rest of the application.
