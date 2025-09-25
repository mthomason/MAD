# MADTdsClient Agent Overview

## Framework Description

The `MADTdsClient` framework provides the specific implementation for connecting to and interacting with Microsoft SQL Server databases. It builds upon the `MADAPI` and `MADTds` frameworks to deliver a complete solution for SQL Server connectivity within the _MAD Designer_ application. This framework includes the necessary view controllers for managing SQL Server connections and the logic for processing SQL Server-specific data.

## Key Features

*   **SQL Server Implementation**: The framework provides a concrete implementation of the `MADDatabase` protocol for Microsoft SQL Server.
*   **Connection UI**: It includes a dedicated view controller (`MADTdsConnectionViewController`) for creating and managing SQL Server database connections.
*   **SQL Server-Specific Logic**: The framework contains logic for handling SQL Server-specific data types and query processing.

## Core Components

*   **`MADDatabaseSQLServer`**: The main class for interacting with a SQL Server database. It is a subclass of `MADDatabase` and uses the `MADTds` framework to communicate with the database.
*   **`MADDatabaseConnectionSQLServer`**: A class that encapsulates the properties of a connection to a SQL Server database.
*   **`MADTdsConnectionViewController`**: A view controller that provides a user interface for creating and editing SQL Server database connections.
*   **`MADDatabaseProcessSQLServer`**: A class that likely handles the processing of data retrieved from a SQL Server database.

## Usage Guidelines

When you need to work with a Microsoft SQL Server database, you will be using the classes from this framework. The `MADDatabaseSQLServer` class is the main entry point for all SQL Server-related operations. If you need to modify the user interface for creating or editing SQL Server connections, you should look at the `MADTdsConnectionViewController` and its associated storyboard.

This framework serves as a good example of how to add support for a new database system to the _MAD Designer_ application. It demonstrates how to subclass `MADDatabase` and provide the necessary UI and logic for a specific database platform.
