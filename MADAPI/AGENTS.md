# MADAPI Agent Overview

## Framework Description

`MADAPI` is a crucial framework that defines the application's database-related classes and protocols. It serves as an abstraction layer for database interactions, providing a consistent interface for various database types. This framework is essential for creating new database connections, managing database schemas, and constructing queries. It has dependencies on `MADFoundation` and `MADCocoaExtensions`.

## Key Features

*   **Database Abstraction**: `MADAPI` provides the `MADDatabase` class, which is the base class for all database connections. This allows the application to support different database systems (e.g., MySQL, SQL Server, PostgreSQL) through a common interface.
*   **Connection Management**: The framework includes classes and view controllers for managing database connections, such as `MADDatabaseConnection` and `MADConnectionViewController`.
*   **Query Construction**: `MADAPI` defines the `MADQuery` class, which is used to build and represent database queries. This allows for a consistent approach to query creation, regardless of the underlying database system.
*   **Schema Representation**: The framework includes classes like `MADDatabaseTable` and `MADDatabaseField` to represent the structure of a database, including its tables and fields.

## Core Components

### Database and Connection

*   **`MADDatabase`**: The abstract base class for all database connections. It defines the common interface for connecting to a database, executing queries, and retrieving schema information.
*   **`MADDatabaseConnection`**: A class that encapsulates the properties of a database connection, such as the server address, username, and password.
*   **`MADConnectionViewController`**: A view controller that provides a user interface for creating and editing database connections.
*   **`MADDatabaseProtocol`**: A protocol that defines the essential methods for a database connection, such as connecting, disconnecting, and executing queries.

### Query and Schema

*   **`MADQuery`**: A class that represents a database query. It includes properties for specifying the tables, fields, joins, and filters of a query.
*   **`MADDatabaseTable`**: A class that represents a table in a database, including its name and a list of its fields.
*   **`MADDatabaseField`**: A class that represents a field in a database table, including its name, data type, and other properties.
*   **`MADDatabaseDataBinding`**: A class that likely handles the binding of data from a database to UI elements or other data structures.

### Protocols and Utilities

*   **`MADDatabaseResultsProtocol`**: A protocol for handling the results of a database query.
*   **`MADDatabaseCacheProtocol`**: A protocol for caching database query results.
*   **`MADErrorContainer`**: A class for encapsulating and managing errors that occur during database operations.
*   **`MADAliases`**: A header file that likely defines type aliases for commonly used data types.

## Usage Guidelines

When you need to interact with a database, you should use the classes and protocols defined in this framework. To add support for a new database system, you will need to create a new subclass of `MADDatabase` that implements the required functionality. When building queries, use the `MADQuery` class to ensure that your queries are constructed in a consistent and portable manner.

## Testing and Reports

*   **Tests**: `MADAPI/MADAPITests`. Run with
    `xcodebuild test -workspace Reports.xcworkspace -scheme MADAPI -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`.
*   **Known issues**: [`BUGS.md`](../docs/project/BUGS.md) -- see the `## MADAPI` section.
*   **Task queue**: [`TASKS.md`](../docs/project/TASKS.md) -- maintain it, but do not start work from it.
