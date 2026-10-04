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

## Test Database Passwords

Test passwords are (it's a never on test server):
MySQL: 127.0.0.1, root, root, employees
SQL Server: 192.168.1.224, test, test, AdventureWorks2022

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
