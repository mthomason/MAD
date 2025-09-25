# MADTds Agent Overview

## Framework Description

The `MADTds` framework provides a high-level Objective-C wrapper for the FreeTDS library, enabling the _MAD Designer_ application to connect to and interact with Sybase and Microsoft SQL Server databases. It abstracts the low-level C API of FreeTDS into a more manageable, object-oriented interface. This framework is a crucial component for any functionality that requires a direct connection to a TDS-based database.

## Key Features

*   **TDS Protocol Support**: The framework leverages the FreeTDS library to provide support for the Tabular Data Stream (TDS) protocol, which is used by Sybase and Microsoft SQL Server.
*   **Objective-C Wrapper**: It provides an Objective-C wrapper around the FreeTDS C library, making it easier to work with these databases in an iOS application.
*   **Connection Management**: The framework includes the `MADTdsDb` class, which simplifies the process of connecting to a database, executing queries, and retrieving results.
*   **Custom Build Script**: It includes a shell script (`build_tds.sh`) for building the FreeTDS library, which is a critical part of the framework's setup.

## Core Components

*   **`MADTdsDb`**: The primary class for interacting with a TDS database. It provides methods for connecting, disconnecting, and executing SQL queries. It also manages the connection properties, such as the server, database, username, and password.
*   **`sybdb.h`**: The main header file for the FreeTDS library's `db-lib` API, which is used for interacting with TDS databases.
*   **`tds_sysdep_public.h`**: A system-dependent header file for FreeTDS.
*   **`build_tds.sh`**: A shell script that is used to build the FreeTDS static libraries (`libct.a` and `libsybdb.a`) that are bundled with the framework.

## Usage Guidelines

When you need to connect to a Sybase or Microsoft SQL Server database, you should use the `MADTdsDb` class. This class provides a simple and convenient way to execute queries and retrieve results. You will need to configure the connection properties (server, database, username, and password) before you can connect to the database.

If you need to make changes to the FreeTDS library itself, you will need to modify the `build_tds.sh` script and then rebuild the framework. However, this should only be done if you have a deep understanding of the FreeTDS library and its build process.
