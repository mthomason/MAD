# Developer

## Third-Party Libraries (Compressor)

The app's third-party static libraries are built on demand by `Compressor` —
nothing third-party is in revision control. See `LIBRARIES.md` for the design;
here is the day-to-day usage.

**First run on a fresh checkout** (network required, ~30–90 min, most of it
the larger source tarballs):

```
Compressor/build.sh --all --platforms ios,simulator
```

Xcode builds then no-op through their "Ensure Libraries" phases; if a library is
missing or stale, the phase builds it before compiling. To force a rebuild of one
library: `Compressor/build.sh --rebuild <lib>`.

**Verify the artifacts:**

```
Compressor/build.sh --verify --all --platforms ios,simulator
```

**Bump a library version:** edit its row in `Compressor/matrix.conf` (version,
URL, sha256 of the new archive), then `Compressor/build.sh --rebuild <lib>` and
run the consuming framework's test suite plus `--verify`. One library per commit.
The mariadb, freetds and zint recipes carry per-version knowledge — see the
notes in `LIBRARIES.md` §1 before bumping those.

## Building on Linux (Phases B–D)

The Linux toolchain spike lives in `Linux/` and is driven by one script — see
`Linux/README.md` and `MAD_LINUX.md` §9. It needs Docker; Docker Desktop's CLI is
not on `PATH` by default and the script finds it.

```
./Linux/build.sh              build the build image, run the Linux tests
./Linux/build.sh --test       run the tests in the existing build image
./Linux/build.sh --runtime    build the CLI runtime image (mad-cli:latest)
./Linux/build.sh --verify     build the runtime image, then verify the CLI in it
./Linux/build.sh --probe      the toolchain/Foundation report only
./Linux/build.sh --shell      interactive shell in the build image
./Linux/build.sh --rebuild    cold rebuild (~15-25 minutes)
```

Nothing built there ships: it compiles the ten headless frameworks against
GNUstep, runs ported versions of their tests plus a toolchain probe, and builds
the `mad` CLI beside them. All six verbs run inside the image; `export --format
pdf` refuses with its reason (the Linux PDF writer is deferred). The GNUstep
divergences it found are listed in `Linux/README.md`, which also carries the
checkpoint's runs and the fixtures they use (`CLI/Fixtures/`).

The iOS regression gate for the platform guards those builds required:

```
xcodebuild test -workspace Reports.xcworkspace -scheme MADFoundation \
	-destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5'
```

(The `OS=` qualifier is needed when several simulator runtimes are installed and
the newest one has no device of that name.)

## Test Databases (Docker)

The live suites and the CLI fixtures use two containers, each created and
maintained by a script beside its framework. Both scripts are idempotent:
`up` creates the container when it is missing, starts it when it is stopped,
and leaves it alone when the pinned image, port and data all match.

|  | MySQL | SQL Server |
|---|---|---|
| container | `mad-mysql` | `mad-mssql` |
| image | `mysql:8.4` (tag + digest) | `mcr.microsoft.com/mssql/server:2022-latest` (tag + digest) |
| host port | `13306` (all interfaces) | `1433` (all interfaces) |
| login | `root` / `root` | `sa` / `Root1@Root2` |
| database | `employees` (300,024 employees) | `AdventureWorksLT2022` (295 products) |
| volume | `mad-mysql-test-data` | `mad-mssql-data` |
| script | `MADMySQL/TestDatabase/mysql-test-db.sh` | `MADTdsClient/TestDatabase/sqlserver-test-db.sh` |
| pins | `db.conf`: image tag + digest, dataset commit + sha256 | `db.conf`: image tag + digest, backup URL + sha256 |

Both scripts take the same verbs:

```
<the framework's script> up       # create/start; load the data if missing (default)
<the framework's script> wait     # block until the server answers
<the framework's script> verify   # re-check the pinned dataset
<the framework's script> status   # container, port, volume, what is loaded
<the framework's script> logs     # tail the server log
<the framework's script> down     # stop (the volume keeps the data)
<the framework's script> reset    # remove the container and its volume
```

The iOS schemes call `up` from the Test action's pre-action and `down` from
the post-action, so each server runs only while its suite does. `up` is also
what to run before the Linux suite or the CLI's `--verify --live`; both
containers publish on every interface because the Linux image and the CLI
fixtures reach the Mac by name (`mac`), not by loopback.

The first `up` is the slow one: MySQL pulls ~600 MB and imports ~168 MB of SQL
(a few minutes); SQL Server pulls ~1.5 GB, starts, and restores the 8 MB
AdventureWorks backup (a minute or two). Every later `up` takes seconds. If a
container or volume is deleted, the next `up` rebuilds it from the pins in
`db.conf`; nothing needs to be created by hand. The SQL Server image is
`linux/amd64` only, so on Apple silicon Docker Desktop emulates it and prints a
platform warning — expected, and why the first start is slower than MySQL's.

**MySQL is on 13306, not 3306.** The Oracle MySQL installer's launchd service
(`com.oracle.oss.mysql.mysqld`) may own 3306 on this Mac, as it did on
2026-10-17. The test container deliberately leaves 3306 alone; the MADMySQL
scheme's Test action sets `MAD_MYSQL_TEST_PORT=13306`, which is what points the
live tests at the container. The CLI fixtures already store `mac:13306`.

**`xcodebuild` cannot pass these through the shell.** A shell environment
variable does not reach the test process, and neither does a `SIMCTL_CHILD_`
prefix — both were measured, not assumed, so `MAD_MYSQL_TEST_PORT=13306
xcodebuild test …` silently runs against 3306 instead. The scheme's
environment is the only way in; the MADMySQL scheme sets
`shouldUseLaunchSchemeArgsEnv = NO` so that its Test action's environment is
the one the test process gets. (The same rule applies to the `MAD_TDS_TEST_*`
variables in the `MADTdsClient` suite; its scheme sets `up`/`down` too.)

For a different server, either override the environment (`MAD_MYSQL_TEST_*`,
`MAD_TDS_TEST_*`) or change the defaults in the test file; the scripts are the
zero-configuration path. When no database can be provisioned, the live tests
skip rather than fail.

## Docker: what runs, and what persists

Only the two test servers are containers. The Linux build has no persistent
container: `./Linux/build.sh` runs `docker run --rm` for every test run, so
nothing from it survives except the images it builds:

* `mad-linux-toolchain:1` — the toolchain cache base (1.15 GB);
* `mad-linux:phase-b` — the build/test image (6.69 GB), whose default command
  runs ctest;
* `mad-cli:latest` — the CLI runtime image (283 MB; `Linux/README.md`).

`docker ps -a` should therefore show `mad-mysql` and `mad-mssql` (running or
stopped), and nothing else from this project. `./Linux/build.sh --clean`
removes the three Linux images; the two scripts' `down`/`reset` manage the
servers.

## Common Commands

The following command was used to create the app preview for iOS.

`ffmpeg -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 -i AppPreview-iPhone-6_3.mov -vf "scale=886:1920" -c:v libx264 -r 30 -c:a aac -shortest AppPreview-Final.mp4`

## Set the Simulator Time

`xcrun simctl status_bar booted override --time "9:41" `


## PrivacyInfo.xcprivacy Justification

Here is the simple breakdown of why they are correct:

The rejection is because of `BoringSSL`, which is a library that creates a secure, encrypted connection to your database. To do its job, it needs to perform two critical security tasks:

1.  **Generate Randomness:** To make the encryption strong, the library needs to generate truly random numbers. A common and secure way to do this is by using the system's boot time as a starting point.
    * This is what **`NSPrivacyAccessedAPICategorySystemBootTime`** with reason **`35F9.1`** is for. Apple's reason `35F9.1` is specifically "to provide randomness for security purposes."

2.  **Validate Certificates:** To make sure it's connecting to the *real* database server and not an imposter, the library has to check the server's security certificate. Part of that check involves looking at the creation and modification dates of files.
    * This is what **`NSPrivacyAccessedAPICategoryFileTimestamp`** with reason **`C617.1`** is for. Apple's reason `C617.1` is "to access metadata...to validate the integrity and security of files."

In short, you are telling Apple: "My framework uses APIs that access boot time and file timestamps, but it does so for standard, legitimate security reasons required to make a database connection safe."

These are the exact reasons used by thousands of other apps that include `OpenSSL`, `BoringSSL`, or similar cryptographic libraries for secure networking. You are on the right track.
