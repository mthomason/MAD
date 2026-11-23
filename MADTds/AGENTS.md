# MADTds Agent Overview

## Framework Description

The `MADTds` framework provides a high-level Objective-C wrapper for the FreeTDS library, enabling the _MAD Designer_ application to connect to and interact with Sybase and Microsoft SQL Server databases. It abstracts the low-level C API of FreeTDS into a more manageable, object-oriented interface. This framework is a crucial component for any functionality that requires a direct connection to a TDS-based database.

## Key Features

*   **TDS Protocol Support**: The framework leverages the FreeTDS library to provide support for the Tabular Data Stream (TDS) protocol, which is used by Sybase and Microsoft SQL Server.
*   **Objective-C Wrapper**: It provides an Objective-C wrapper around the FreeTDS C library, making it easier to work with these databases in an iOS application.
*   **Connection Management**: The framework includes the `MADTdsDb` class, which simplifies the process of connecting to a database, executing queries, and retrieving results.
*   **Pinned FreeTDS**: The framework links the FreeTDS static libraries and headers built by the `Compressor` recipe (`Compressor/matrix.conf`, `Compressor/lib/recipes/freetds.sh`), and exposes the matching headers as its own public headers.

## Core Components

*   **`MADTdsDb`**: The primary class for interacting with a TDS database. It provides methods for connecting, disconnecting, and executing SQL queries. It also manages the connection properties, such as the server, database, username, and password.
*   **`sybdb.h`**: The main header file for the FreeTDS library's `db-lib` API, supplied by the `Compressor` FreeTDS build and exposed as `<MADTds/sybdb.h>`.
*   **`tds_sysdep_public.h`**: The FreeTDS system-dependent header, supplied by the same build and exposed as `<MADTds/tds_sysdep_public.h>`.

## Usage Guidelines

When you need to connect to a Sybase or Microsoft SQL Server database, you should use the `MADTdsDb` class. This class provides a simple and convenient way to execute queries and retrieve results. You will need to configure the connection properties (server, database, username, and password) before you can connect to the database.

If you need to change the FreeTDS version or its build, edit its row in `Compressor/matrix.conf` and its recipe in `Compressor/lib/recipes/freetds.sh`, then rebuild through `Compressor/build.sh`; see `docs/developers/build/libraries.md` §1.

## Testing and Reports

*   **Note**: the framework ships no tests of its own; it is exercised through `MADTdsClient`.
*   **Tracking**: [`BUGS.md`](../docs/project/registers/BUGS.md) -- the defect register; [`TASKS.md`](../docs/project/registers/TASKS.md) -- the engineering queue. Maintain them, but do not start work from them.
