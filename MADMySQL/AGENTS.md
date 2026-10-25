# MADMySQL Agent Overview

## Framework Description

The `MADMySQL` framework provides the specific implementation for connecting to and interacting with MySQL databases. It builds upon the `MADAPI` framework to deliver a complete solution for MySQL connectivity within the _MAD Designer_ application. This framework includes the necessary classes for managing MySQL connections and the logic for processing MySQL-specific data.

## Key Features

*   **MySQL Implementation**: The framework provides a concrete implementation of the `MADDatabase` protocol for MySQL.
*   **MySQL Client Headers**: It includes the necessary header files from the MySQL client library, which are required for communicating with a MySQL server.

## Core Components

*   **`MADDatabaseMySQL`**: The main class for interacting with a MySQL database. It is a subclass of `MADDatabase` and uses the MySQL client library to communicate with the database.
*   **`MADDatabaseConnectionMySql`**: A class that encapsulates the properties of a connection to a MySQL database.
*   **`client_plugin.h` and `plugin_auth_common.h`**: Header files from the MySQL client library that are related to client plugins and authentication.

## Usage Guidelines

When you need to work with a MySQL database, you will be using the classes from this framework. The `MADDatabaseMySQL` class is the main entry point for all MySQL-related operations.

This framework, along with `MADTdsClient`, serves as a good example of how to add support for a new database system to the _MAD Designer_ application. It demonstrates how to subclass `MADDatabase` and provide the necessary logic for a specific database platform.

## Testing and Reports

*   **Tests**: `MADMySQL/MADMySQLTests`. Run with
    `xcodebuild test -workspace Reports.xcworkspace -scheme MADMySQL -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`.
*   **Known issues**: [`BUGS.md`](../docs/project/BUGS.md) -- see the `## MADMySQL` section.
*   **Task queue**: [`TASKS.md`](../docs/project/TASKS.md) -- maintain it, but do not start work from it.
*   **Architecture**: [`MADDataTable_Architecture_Report.md`](../docs/project/MADDataTable_Architecture_Report.md).
*   **Live tests**: `MADMySQLTests/MADMySQLLiveTests.m` talks to a real MySQL server
    and skips when none is reachable. The credentials it expects are in
    [`DEVELOPER.md`](../docs/project/DEVELOPER.md); override them with the `MAD_MYSQL_TEST_*`
    environment variables. Use `127.0.0.1`, not `localhost` -- the MySQL
    client libraries read `localhost` as a request for a Unix socket, which the
    Simulator does not have.
    `TestDatabase/mysql-test-db.sh` provides that server in Docker -- one
    container, `mad-mysql`, from a pinned image with a checksum-verified copy of
    the standard `employees` dataset. It publishes 13306; the scheme sets
    `MAD_MYSQL_TEST_PORT=13306` on its Test action and starts the container
    before the tests and stops it after. Do not start a second MySQL container.
    See [`DEVELOPER.md`](../docs/project/DEVELOPER.md) for the commands, the volumes and why
    3306 is left to the Oracle installer's launchd service.
