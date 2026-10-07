# Changelog

## 0.06 - 07.10.2026

- Reworked project scanning into a modal progress dialog with cancellation.
- Increased the project selector drop-down so multiple choices are visibly available.
- Replaced free-form language and logging fields with selectors.
- Added standard .NET RESX localization for Czech and English and removed legacy JSON language files.
- Added functional application logging modes: off, single, and all.
- Made Settings more compact and added Reset, Save, and Cancel actions.
- Added HandBrake source opening with executable auto-detection and explicit error reporting.
- Removed legacy PowerShell/VBS application files; PowerShell remains only in the updater.

## 0.04 - 30.09.2026

- Migrated the application UI from PowerShell to C# / .NET 10 WinForms.
- Added immediate native GUI startup with project scanning performed asynchronously after the window is shown.
- Added scan progress with current/total project count.
- Added Cancel action to stop scanning while keeping the application open.
- Close exits the complete application and cancels an active scan.
- Kept the compact file table with checkbox, file name, and conversion status.
- Kept live project search across pending and completed projects.
- Added native settings dialog and HandBrake executable auto-detection.
- Updated run.cmd to launch the compiled Windows executable without a console window.
- Updated upgrade lifecycle to require, build, publish, and verify .NET 10 output.

## 0.03 - 30.09.2026

- Fix network-share Git bootstrap by applying repository-local safe.directory context before the first Git command.
- Fix project search to filter the complete project directory list live while typing.
- Include completed projects in live search results.
- Make search case-insensitive and match any part of the project name.

## 0.02 - 30.09.2026

- Hide the PowerShell console when launching the GUI.
- Replace the large file list with a compact table: checkbox, file name, status.
- Size the file table for approximately five visible rows.
- Add File menu with Settings and Close.
- Add settings dialog for project root, DELIVERY folder, converted suffix, HandBrake path, language, and logging.
- Auto-detect HandBrake in common installation locations when its path is unset.
- Rename Cancel to Close.

## 0.01 - 30.09.2026

- Initial project structure.
- Added project discovery under the Sueneé Universe EDITING tree.
- Added descending Z-A project ordering.
- Added searchable project selector including completed projects.
- Added checkbox source-file selection.
- Excluded `*-conv.mp4` from source selection.
- Added CZ/EN language resources and logging configuration.
- Added HandBrake integration boundary without modifying private HandBrake queue files.
- Added Wipe Codes compatible upgrade bootstrap.
