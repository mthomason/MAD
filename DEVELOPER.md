# Developer

## Third-Party Libraries (Compressor)

The app's third-party static libraries are built on demand by `Compressor` —
nothing third-party is in revision control. See `LIBRARIES.md` for the design;
here is the day-to-day usage.

**First run on a fresh checkout** (network required, ~30–90 min, most of it
mysqlclient):

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
The mysqlclient, freetds and zint recipes carry per-version knowledge — see the
notes in `LIBRARIES.md` §1 before bumping those.

## Building on Linux (Phases B–D)

The Linux toolchain spike lives in `Linux/` and is driven by one script — see
`Linux/README.md` and `MAD_LINUX.md` §9. It needs Docker; Docker Desktop's CLI is
not on `PATH` by default and the script finds it.

```
./Linux/build.sh              build the image, run the Linux tests
./Linux/build.sh --test       run the tests in the existing image
./Linux/build.sh --probe      the toolchain/Foundation report only
./Linux/build.sh --shell      interactive shell in the build image
./Linux/build.sh --rebuild    cold rebuild (~15-25 minutes)
```

Nothing built there ships: it compiles the ten headless frameworks against
GNUstep, runs ported versions of their tests plus a toolchain probe, and builds
the `mad` CLI beside them — `inspect`, `schema`, `query` and `refresh` run inside
the image, `export` (PDF) is Apple-only. The GNUstep divergences it found are
listed in `Linux/README.md`, which also carries the Phase D checkpoint's runs and
the fixtures they use (`CLI/Fixtures/`).

The iOS regression gate for the platform guards those builds required:

```
xcodebuild test -workspace Reports.xcworkspace -scheme MADFoundation \
	-destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5'
```

(The `OS=` qualifier is needed when several simulator runtimes are installed and
the newest one has no device of that name.)

## Test Database Passwords

Test passwords are (it's a never on test server):
MySQL: 127.0.0.1, root, root, employees
SQL Server: 192.168.1.224, test, test, AdventureWorks2022

## MySQL Test Database (Docker)

`MADMySQL/TestDatabase/mysql-test-db.sh` runs the server the live MySQL tests
talk to, in Docker, so those tests do not depend on whatever MySQL happens to
be installed on the Mac. It is pinned end to end by
`MADMySQL/TestDatabase/db.conf`: the server image by tag **and** digest
(MySQL 8.4 LTS — the same line as the mysqlclient the app links), the data by
the `datacharmer/test_db` commit and the archive's sha256. After loading, the
dataset is checked against its own upstream row counts and per-table SHA-1
checksums, so "the same sample database every time" is verified rather than
assumed.

```
MADMySQL/TestDatabase/mysql-test-db.sh up       # start; load the data if needed (default)
MADMySQL/TestDatabase/mysql-test-db.sh status   # container, port, and what is loaded
MADMySQL/TestDatabase/mysql-test-db.sh verify   # re-run the upstream checksums
MADMySQL/TestDatabase/mysql-test-db.sh down     # stop (the volume keeps the data)
MADMySQL/TestDatabase/mysql-test-db.sh reset    # remove the container and its volume
```

The MADMySQL scheme calls `up` from the test action's pre-action and `down`
from its post-action, so the server exists only while that scheme's tests run.
The first `up` pulls ~600 MB of image and imports ~168 MB of SQL (a few
minutes); every later `up` takes seconds, and the import is skipped unless the
pins in `db.conf` changed or the volume was reset.

The container publishes **127.0.0.1:3306**, which is what the tests connect to,
so it needs that port free. A stock MySQL install runs as `_mysql` and will not
show up in `lsof` — if `up` reports the port busy, either stop that server (then
the container owns 3306 and nothing else is needed), or move both halves to
another port: publish the container with `MAD_TESTDB_PORT=<port>` and add
`MAD_MYSQL_TEST_PORT=<port>` to the MADMySQL scheme's **Test** action
environment variables (Xcode: Edit Scheme → Test → Arguments → Environment
Variables). The scheme sets `shouldUseLaunchSchemeArgsEnv = NO` so that the
Test action's own environment is the one the test process gets.

**`xcodebuild` cannot pass these through the shell.** A shell environment
variable does not reach the test process, and neither does a `SIMCTL_CHILD_`
prefix — both were measured, not assumed, so `MAD_MYSQL_TEST_PORT=13306
xcodebuild test …` silently runs against 3306 instead. The scheme's
environment is the only way in. (This applies to the `MAD_TDS_TEST_*` variables
in the `MADTdsClient` suite too.)

None of this is fatal to a test run: when no database can be provisioned, the
live tests skip, exactly as they do on a machine with no MySQL at all.

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
