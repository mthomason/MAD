# MADSqlite3 Agent Overview

## Framework Description

The `MADSqlite3` framework provides a modern, object-oriented wrapper for the popular Sqlite3 C library. It simplifies the process of working with Sqlite3 databases in the _MAD Designer_ application by providing a set of Objective-C classes that encapsulate the low-level C API. This framework is used for example reports and for caching data from other database systems.

## Key Features

*   **Object-Oriented Wrapper**: The framework provides an Objective-C wrapper around the Sqlite3 C library, making it easier to work with databases in an object-oriented manner.
*   **Database Connection Management**: It includes classes for managing connections to Sqlite3 databases, including creating, opening, and closing databases.
*   **Query Caching**: `MADSqlite3` provides a set of classes for caching query results, which is essential for improving performance and supporting aggregate functions.
*   **Transaction Management**: The framework includes classes for managing database transactions, which ensures data integrity.

## Core Components

### Database and Connection

*   **`MADDatabaseSqlite3`**: The main class for interacting with a Sqlite3 database. It is a subclass of `MADDatabase` and provides a high-level API for executing queries, managing transactions, and accessing database metadata.
*   **`MADDatabaseConnectionSqlite3`**: A class that encapsulates the properties of a connection to a Sqlite3 database.

### Querying and Caching

*   **`MADQuery+Sqlite3`**: A category that adds Sqlite3-specific functionality to the `MADQuery` class.
*   **`MADQueryCache...`**: A set of classes that provide various caching strategies and operations. This includes classes for beginning and ending transactions, deleting data, and dropping tables.
*   **`MADDataTableFast`**: A fast, lightweight data table that is optimized for use with Sqlite3.
*   **`MADArrayCaching`**: A class for caching arrays of data.

### Transaction Management

*   **`MADQueryCacheBeginTransaction`**: A class that begins a database transaction.
*   **`MADQueryCacheEndTransaction`**: A class that ends a database transaction, either by committing or rolling back the changes.

## Usage Guidelines

When you need to work with a Sqlite3 database, you should use the classes provided in this framework. The `MADDatabaseSqlite3` class is the main entry point for all database operations. Use the `MADQueryCache...` classes to improve performance by caching the results of expensive queries.

When performing multiple database operations that need to be treated as a single unit, be sure to wrap them in a transaction using the `MADQueryCacheBeginTransaction` and `MADQueryCacheEndTransaction` classes. This will ensure that your changes are applied atomically and can be rolled back in case of an error.
