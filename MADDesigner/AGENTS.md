# MAD Designer App Agent Overview

## Project Description

`MADDesigner` is the application itself. It holds `MAD Designer.xcodeproj`, the app and
viewer targets, the interface resources, and the app's unit and UI tests. Anything the app
is built from that is not one of the frameworks lives here.

The project defines four targets:

*   **`MAD Designer`** -- the shipped app, built for iPhone, iPad, and My Mac (Designed for
    iPad). This is the target that hosts the unit tests.
*   **`MAD Viewer`** -- the stand-alone viewer target.
*   **`MADDesignerUnitTests`** -- the app's non-UI tests.
*   **`MADDesignerUITests`** -- the UI tests.

## Layout

*   `Source/` -- the app source: `AppDelegate`, the document and designer view controllers,
    the report viewer, and the `MADOperationCondition` classes used by the app's operations.
*   `Targets/` -- the unit-test, UI-test, and viewer targets.
*   `Resources/`, `Assets/` -- storyboards, localizations, sample reports, and asset catalogs.
*   `ReceiptModuleAsn1c/` -- the App Store receipt validation module.

## Testing and Reports

*   **Tests**: `MADDesigner/Targets/MADDesignerUnitTests`. Run with
    `xcodebuild test -workspace Reports.xcworkspace -scheme 'MAD Designer' -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`.
*   **Unit test files**:
    *   `MADDesignerUnitTests.m` -- the app-source helper categories (Base64, RFC 3339 date
        formatting) and framework consumption: the connection construction and SQL
        generation the app performs when it opens a connection.
    *   `MADAppLogicTests.m` -- `MADFeature`, the `NSData` AES256 extension,
        `MADPageViewAttributes`, and `MADDateFromTimeFormatter`.
    *   `MADAppOperationConditionTests.m` -- the app's `MADOperationCondition` classes and
        `MADMutualExclusiveCondition`.
*   **UI tests**: `MADDesigner/Targets/MADDesignerUITests`.
*   **Known issues**: [`BUGS.md`](../docs/project/BUGS.md) -- see the `## MAD Designer (app)` section. The
    faults found in this test target itself are under `## Test infrastructure`.
*   **Task queue**: [`TASKS.md`](../docs/project/TASKS.md) -- maintain it, but do not start work from it.
