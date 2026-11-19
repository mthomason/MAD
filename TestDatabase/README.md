# Test databases

One place for everything about the three pinned test servers the live driver
suites and the CLI fixtures talk to. Each is a Docker container created from a
digest-pinned image, holding a checksum-verified copy of a sample dataset on a
named volume.

| | MySQL | SQL Server | PostgreSQL |
|---|---|---|---|
| container | `mad-mysql` | `mad-mssql` | `mad-postgres` |
| image (tag + digest) | `mysql:8.4` | `mcr.microsoft.com/mssql/server:2022-latest` | `postgres:17-bookworm` |
| host port | `13306` | `1433` | `5432` |
| login | `root` / `root` | `sa` / `Root1@Root2` | `mad` / `mad_test_pw` |
| database | `employees` | `AdventureWorksLT2022` | `chinook` |
| dataset size (verified) | 300,024 employees | 295 `SalesLT.Product` rows | 275 artists / 347 albums / 3,503 tracks |
| volume | `mad-mysql-test-data` | `mad-mssql-data` | `mad-postgres-test-data` |
| script | `MADMySQL/TestDatabase/mysql-test-db.sh` | `MADTdsClient/TestDatabase/sqlserver-test-db.sh` | `MADPostgres/TestDatabase/postgres-test-db.sh` |

The three canonical scripts are the source of truth (each is idempotent and
reads its pins from its own `db.conf`). This directory adds a cross-platform
**orchestrator** that calls them, and a PowerShell wrapper for Windows:

* `TestDatabase/test-databases.sh` — macOS / Linux / Git Bash.
* `TestDatabase/test-databases.ps1` — Windows PowerShell 7 (locates Git Bash and
  calls the shell orchestrator).

The orchestrator does not duplicate any container logic; every verb is delegated
to the matching script.

## Prerequisites

* **Docker Desktop running, with Linux containers.** The images are all
  linux/amd64 (`SQL Server` is linux/amd64-only, so on Apple silicon Docker
  Desktop emulates it). Docker Desktop's WSL2 backend is Docker's own and is
  already present — do **not** install a second Linux platform or VM.
* **Windows:** Git for Windows (`C:\Program Files\Git\bin\bash.exe`); PowerShell
  7 to use the `.ps1` wrapper. The shell scripts also run directly under Git
  Bash.
* **macOS / Linux:** the system `bash` (macOS bash 3.2 is fine).

## First run: `download` then `up`

`download` fetches and checksum-verifies the datasets into the local cache
**without needing Docker**. `up` always runs the fetch first, so it downloads
on its own if you skip `download` — but running `download` first lets you see
the small downloads succeed before the large image pulls begin.

Download sizes (cache) and load times:

| service | download (cache) | image pull | first `up` load |
|---|---|---|---|
| mysql | ~35 MB archive → ~168 MB of `employees` SQL | ~600 MB | a few minutes |
| tds | ~8 MB `.bak` | ~1.5 GB | a minute or two (restore) |
| postgres | ~0.6 MB SQL | ~160 MB | seconds |

Every later `up` takes seconds (the images and volumes are cached).

```bash
TestDatabase/test-databases.sh download   # fetch + verify datasets, no Docker
TestDatabase/test-databases.sh up         # create/start all three, load data
```

On Windows:

```powershell
.\TestDatabase\test-databases.ps1 -Action download
.\TestDatabase\test-databases.ps1 -Action up
```

The cache lives at a per-platform location and is overridable with
`MAD_TESTDB_CACHE`:

| platform | default cache |
|---|---|
| macOS | `$HOME/Library/Caches/MADTestDatabase` |
| Linux | `${XDG_CACHE_HOME:-$HOME/.cache}/MADTestDatabase` |
| Windows | `${LOCALAPPDATA}\MADTestDatabase` |

## Commands

Every verb below accepts an optional service selector — `all` (default),
`mysql`, `tds` or `postgres`. `all` runs mysql → tds → postgres in that order
and stops on the first hard failure.

| verb | what it does |
|---|---|
| `up` | create/start the server, load the data if missing (idempotent) |
| `download` | fetch + checksum-verify the dataset into the cache (no Docker) |
| `wait` | block until the server answers |
| `verify` | re-check the pinned dataset (row counts / checksums) |
| `status` | container, port, and what is loaded |
| `logs` | tail the server log (pass a service, e.g. `logs mysql`) |
| `down` | stop the container (the volume keeps the data) |
| `reset` | remove the container **and** its volume (the next `up` rebuilds) |

macOS / Linux / Git Bash:

```bash
TestDatabase/test-databases.sh status            # all three
TestDatabase/test-databases.sh verify mysql      # one service
TestDatabase/test-databases.sh logs tds          # tail SQL Server
TestDatabase/test-databases.sh down              # stop all three
TestDatabase/test-databases.sh reset postgres    # destructive: drops PG volume
```

Windows PowerShell:

```powershell
.\TestDatabase\test-databases.ps1 -Action status
.\TestDatabase\test-databases.ps1 -Action verify -Service mysql
.\TestDatabase\test-databases.ps1 -Action logs -Service tds
.\TestDatabase\test-databases.ps1 -Action down
.\TestDatabase\test-databases.ps1 -Action reset -Service postgres
```

`env` prints the complete live-suite environment in both POSIX and PowerShell
forms (it ignores the service selector):

```bash
TestDatabase/test-databases.sh env
# or
.\TestDatabase\test-databases.ps1 -Action env
```

```
export MAD_MYSQL_TEST_HOST=127.0.0.1
export MAD_MYSQL_TEST_PORT=13306
export MAD_MYSQL_TEST_USER=root
export MAD_MYSQL_TEST_PASSWORD=root
export MAD_MYSQL_TEST_SCHEMA=employees
export MAD_TDS_TEST_HOST=127.0.0.1
export MAD_TDS_TEST_USER=sa
export MAD_TDS_TEST_PASSWORD='Root1@Root2'
export MAD_TDS_TEST_DATABASE=AdventureWorksLT2022
export MAD_PG_TEST_HOST=127.0.0.1
export MAD_PG_TEST_PORT=5432
export MAD_PG_TEST_USER=mad
export MAD_PG_TEST_PASSWORD=mad_test_pw
export MAD_PG_TEST_DATABASE=chinook
```

There is deliberately **no `MAD_TDS_TEST_PORT`** — the current TDS live suite
hardcodes 1433 (see below).

## Running the live suites

### macOS

The `MADMySQL`, `MADTdsClient` and `MADPostgres` Xcode schemes own the server
lifecycle: their Test action's pre-action runs `up` and the post-action runs
`down`, and the scheme supplies the environment (`MAD_MYSQL_TEST_PORT=13306`,
etc.). Run the schemes from Xcode, or with the `xcodebuild` command in
`docs/project/DEVELOPER.md`. The pre/post actions are macOS-only.

### Windows (after Phase 3b)

The drivers do not build on Windows until Phase 3b. When they do: apply the
PowerShell env block in the **same session** as `Windows/Engine/build.ps1`, then
run the built live-suite executables (or `build.ps1`):

```powershell
$env:MAD_MYSQL_TEST_HOST = "127.0.0.1"   # ... the full block from `-Action env`
pwsh -File .\Windows\Engine\build.ps1 -SkipToolchain
```

The live tests default to `127.0.0.1` and **skip cleanly** when a server is
unreachable, so a machine without a running container still gets a green run
for the offline tests.

## Monitoring

```bash
docker ps                 # the three containers, running or stopped
docker stats              # live CPU/memory/network
TestDatabase/test-databases.sh status
TestDatabase/test-databases.sh verify
TestDatabase/test-databases.sh logs mysql
```

## Troubleshooting

* **Docker daemon not running** — start Docker Desktop and wait for "engine
  running". `docker version` and `docker info` are the quick checks.
* **Port conflict** — MySQL `13306`, TDS `1433`, PostgreSQL `5432`. A port held
  by a *foreign* process is a hard conflict; a port held by our own (mismatched)
  container is recreated on the same volume, never reported as a conflict. The
  TDS suite hardcodes 1433 (there is no `MAD_TDS_TEST_PORT`), so it cannot move
  off 1433 without a test change. MySQL/PG can move via `MAD_TESTDB_PORT` plus
  the matching test env var.
* **Windows path conversion** — the scripts convert host paths with `cygpath -w`
  for Docker and set `MSYS_NO_PATHCONV=1` on Docker invocations so container-side
  paths (`/dataset`, `/var/opt/mssql`, `/opt/mssql-tools18`, `container:/path`)
  are not rewritten. Run the scripts from Git Bash rather than passing `C:\…`
  paths through another shell.
* **Cache / checksum mismatch** — a cached dataset whose sha256 no longer matches
  `db.conf` is re-downloaded automatically. `download` reports "already cached"
  when the cache is valid.
* **SQL Server EULA** — the script passes `ACCEPT_EULA=Y`; running the image
  constitutes acceptance of Microsoft's EULA.
* **SQL Server is linux/amd64 only** — on Apple silicon it runs under emulation
  (Docker prints a platform warning; the first start is slower).
* **Docker Desktop resources** — SQL Server wants a couple of GB of RAM. If a
  container exits 137 (OOM), raise Docker Desktop's memory limit.
* **Do not start a second container** — one `mad-mysql`, one `mad-mssql`, one
  `mad-postgres`. The scripts are written around those names and volumes.

## Security

* **Windows binds published ports to loopback (`127.0.0.1`) by default**, so the
  test servers are not exposed on the LAN. Override with `MAD_TESTDB_BIND` (or
  `MAD_TESTDB_BIND=""` for all interfaces) only if you have a reason.
* **macOS / Linux keep all-interface publishing** — the Linux build image and
  the CLI fixtures reach the Mac's containers by host name (`mac`), so the
  existing behaviour is preserved and must not change.
* Never expose the test databases publicly. They use well-known logins and test
  data and are not hardened.

## The two daemons are independent

The Mac containers and the Windows containers are separate Docker daemons; the
same container/volume names on both is expected and harmless. A `reset`/`up` on
one machine never touches the other.

## Why MySQL is on 13306

The Oracle MySQL installer's `launchd` service may own 3306 on the Mac, so the
container deliberately leaves 3306 alone. The MADMySQL scheme points the tests
at `MAD_MYSQL_TEST_PORT=13306`, and the CLI fixtures store `mac:13306`. Windows
keeps the same 13306 so there is one env contract across platforms.
