# CSV Reader

CSV Reader is a SwiftUI application for the Rabobank Team Native assignment. It opens a CSV file, displays the supplied issues in a list, and offers a Table mode for inspecting all columns. Both views load data in pages of 100 rows. A new CSV can be selected from the Files picker while the app is running.

## Requirements

- Xcode with the iOS 27 SDK
- An iOS 27.0 or later simulator or device

The project uses Apple's SwiftUI, Observation, and TabularData frameworks and has no third-party package dependencies. iOS 27.0 is the project's current deployment target; it has not been established as the minimum required by the implementation.

## Running the app

1. Open `CSVReader.xcodeproj` in Xcode.
2. Select the shared `CSVReader` scheme and an iOS simulator or device.
3. Build and run the app.

By default, the app opens the bundled `CSVReader/Resources/issues.csv`. To start with no file instead, change `loadsBundledCSVOnLaunch` to `false` in `CSVReader/Application/AppContainer.swift` and rebuild. The empty screen provides a **Choose CSV** button. This switch controls only the initial file; it does not save or restore files selected later.

Run the tests with **Product → Test** in Xcode using the same scheme.

## Choosing or changing a CSV

Tap **Choose CSV** in the toolbar to open a `.csv` file from Files. This replaces the current file for the running session. The selection is not retained after the app restarts.

To change the CSV that opens automatically, replace the contents of `CSVReader/Resources/issues.csv` and rebuild the app. Keep the file name and location unchanged because `AppContainer` looks up `issues.csv` in the application bundle.

The **Issues** view expects these exact column names (their order may vary):

```csv
"First name","Sur name","Issue count","Date of birth"
"Theo","Jansen",5,"1978-01-02T00:00:00"
```

`Issue count` must be an integer, and `Date of birth` must use the date-time format shown above. Required cells must not be empty. For a CSV with a different schema, select **Table** manually; it displays the parsed columns without applying the issues-specific mapping. The parser detects comma, semicolon, and tab separators and ignores empty lines within the data.

## Architecture

The feature follows a unidirectional flow:

```text
View action → Input → ViewModel → CSV/Issues service → StateMapper → ViewState → View
```

`AppContainer` assembles the dependencies and selects the initial file. `TabularDataCSVParser` runs as an actor, detects the separator, and reads a requested page. `IssuesServiceMapper` validates and converts the four required columns into domain models. `IssuesViewModel` owns loading, pagination, cancellation, and presentation mode. `IssuesStateMapper` prepares values for the SwiftUI list and table. Birth dates are displayed in GMT so the calendar day does not change with the device's time zone.

## Current limitations and possible improvements

- **Original cell text is not preserved.** TabularData infers column types before the app converts values back to strings. Formatting such as leading zeroes may be lost. A parser that keeps raw field text would make Table mode faithful to the source CSV.
- **A blank line before the header can select the wrong separator.** Separator detection stops at the first line break, even though the CSV reader ignores empty lines. Detection should start at the first non-empty header record.
- **Errors lack detail on screen.** The mapper identifies invalid values and CSV row numbers, but the UI currently shows only “Unable to load CSV.” Showing the underlying reason and row would help diagnose input files.
- **Other schemas require manual Table selection.** The app does not switch modes automatically when the four Issues columns are absent.
- **The selected file is session-only.** Restoring a file after relaunch would require storing and resolving access to the selected document.
- **ViewModel behavior is not covered by unit tests.** Tests for file changes during loading, cancellation, retries, and page order would strengthen the existing parser and mapper coverage.
