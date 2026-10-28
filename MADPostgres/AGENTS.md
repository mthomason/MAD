# MADPostgres Agent Overview

## Framework Description

The `MADPostgres` framework provides the PostgreSQL implementation of `MADDatabase`, backed by `libpq` (PostgreSQL 17.11) built via Compressor on Apple platforms and `Linux/lib/libraries.sh` on Linux. It builds upon `MADFoundation` and `MADAPI`.

## Key Features

*   **PostgreSQL Implementation**: Concrete `MADDatabasePostgres` and `MADDatabaseConnectionPostgres` classes registered with `MADDatabaseDriverRegistry` via `+load`.
*   **libpq Client Library**: Static `libpq` linked with OpenSSL for SCRAM-SHA-256 and TLS connections.

## Core Components

*   **`MADDatabasePostgres`**: Subclass of `MADDatabase` implementing SQL dialect methods, schema discovery (`information_schema`), and query execution over `libpq`.
*   **`MADDatabaseConnectionPostgres`**: Connection descriptor (`MADDatabaseTypePostgres`, driver identifier `@"PostgreSQL"`, default port `5432`).
*   **`MADPostgresConnection`**: Objective-C wrapper around `PGconn *`.
*   **`MADDataTypePostgres`**: Maps PostgreSQL `Oid` and `information_schema` type names to `MADDataType`.
*   **`MADPostgresConnectionViewController`**: Connection setup view controller for the iOS/iPadOS/macOS app.

## Testing and Reports

*   **Tests**: `MADPostgres/MADPostgresTests`. Run with
    `xcodebuild test -workspace Reports.xcworkspace -scheme MADPostgres -destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' -derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci`.
*   **Live tests**: `MADPostgresTests/MADPostgresLiveTests.m` talks to a real PostgreSQL server and skips when none is reachable. Override credentials with `MAD_PG_TEST_*` environment variables (`MAD_PG_TEST_HOST`, `MAD_PG_TEST_PORT`, `MAD_PG_TEST_USER`, `MAD_PG_TEST_PASSWORD`, `MAD_PG_TEST_DATABASE`). `TestDatabase/postgres-test-db.sh` manages the `mad-postgres` Docker container.
