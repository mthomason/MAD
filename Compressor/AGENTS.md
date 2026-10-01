# Compressor Agent Overview

## Project Description

The `Compressor` project is a collection of shell scripts that are used to build the various third-party static libraries that are required by the _MAD Designer_ application. This project is essential for ensuring that all dependencies are built with the correct configurations and for the correct architectures.

## Key Features

*   **Automated Builds**: The project provides a set of scripts that automate the process of building the third-party libraries.
*   **Dependency Management**: It manages the dependencies between the various libraries, ensuring that they are built in the correct order.
*   **Architecture Support**: The scripts are configured to build the libraries for the required architectures (e.g., arm64, x86_64).

## Core Components

The `Compressor` project consists of a number of shell scripts, each of which is responsible for building a specific library. The main scripts are:

*   **`compressor.sh`**: This is the main script that is used to run all the other build scripts. It ensures that the libraries are built in the correct order and with the correct configurations.
*   **`build_archive.sh`**: This script builds the `archive` library.
*   **`build_bzip2.sh`**: This script builds the `bzip2` library.
*   **`build_mysqlclient.sh`**: This script builds the `mysqlclient` library.
*   **`build_openssl.sh`**: This script builds the `openssl` library.
*   **`build_png.sh`**: This script builds the `png` library.
*   **`build_sqlite3.sh`**: This script builds the `sqlite3` library.
*   **`build_tds.sh`**: This script builds the `tds` library (FreeTDS).
*   **`build_zlib.sh`**: This script builds the `zlib` library.

## Usage Guidelines

To build all the third-party libraries, you can run the `compressor.sh` script. This will build all the libraries in the correct order and place them in the appropriate directories.

If you need to rebuild a specific library, you can run its corresponding build script (e.g., `build_openssl.sh`). However, be aware that some libraries have dependencies on other libraries, so it is generally recommended to run the main `compressor.sh` script to ensure that all dependencies are up-to-date.

If you need to add a new third-party library to the project, you will need to create a new build script for it and add it to the `compressor.sh` script. Your new script should follow the same pattern as the existing scripts, ensuring that it builds the library for the correct architectures and places the output in the appropriate directory.

## Testing and Reports

*   **Note**: the project ships no tests. `compressor.sh` is verified by building the libraries.
