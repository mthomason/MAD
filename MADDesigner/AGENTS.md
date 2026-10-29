# MAD Designer App Agent Overview

## Project Description

`MADDesigner` is the application itself. It holds `MAD Designer.xcodeproj`, the app and
viewer targets, the interface resources, and the app's unit and UI tests. Anything the app
is built from that is not one of the frameworks lives here.

The project defines four targets:

*   **`MAD Designer`** -- the shipped app, built for iPhone, iPad, and My Mac (Designed for
    iPad). This is the target that hosts the unit tests (`MAD_DESIGNER=1`).
*   **`MAD Viewer`** -- the stand-alone viewer target (`MAD_VIEWER=1`). Shares `AppDelegate`,
    `SceneDelegate`, and `Source/` with `MAD Designer`, launches to the file explorer titled
    `"MAD Viewer"` with the `+` (Create New Document) button hidden, and opens `.mad` reports
    directly into `MADViewerController` with the Query and Designer tabs omitted and the tab
    bar hidden.
*   **`MADDesignerUnitTests`** -- the app's non-UI tests.
*   **`MADDesignerUITests`** -- the UI tests.

## Layout

*   `Source/` -- the app source: `AppDelegate`, `SceneDelegate`, the document and designer view
    controllers, the report viewer, and the `MADOperationCondition` classes used by the app's
    operations.
*   `Targets/` -- the unit-test, UI-test, and viewer targets.
*   `Resources/`, `Assets/` -- storyboards, localizations, sample reports, and asset catalogs.
*   `ReceiptModuleAsn1c/` -- the App Store receipt validation module.

## Testing and Reports

*   **Tests**: `MADDesigner/Targets/MADDesignerUnitTests`. Run with:
    ```sh
    xcodebuild test -workspace Reports.xcworkspace -scheme "MAD Designer" \
        -only-testing:MADDesignerUnitTests \
        -destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
        -derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
    ```
*   **Unit test files**:
    *   `MADDesignerUnitTests.m` -- the app-source helper categories (Base64, RFC 3339 date
        formatting), framework consumption, designer/viewer controller regressions, and
        `MAD Viewer` mode behavior.
    *   `MADAppLogicTests.m` -- `MADFeature`, the `NSData` AES256 extension,
        `MADPageViewAttributes`, and `MADDateFromTimeFormatter`.
    *   `MADAppOperationConditionTests.m` -- the app's `MADOperationCondition` classes and
        `MADMutualExclusiveCondition`.
    *   `MADOperationValidateSQLTests.m` -- SQL validation probe generation.
    *   `MADStatusLabelRefreshTests.m` -- status label formatting progress and coalescing.
*   **UI tests**: `MADDesigner/Targets/MADDesignerUITests`.
*   **Known issues**: [`BUGS.md`](../docs/project/BUGS.md) -- see the `## MAD Designer (app)` section. The
    faults found in this test target itself are under `## Test infrastructure`.
*   **Task queue**: [`TASKS.md`](../docs/project/TASKS.md) -- maintain it, but do not start work from it.
