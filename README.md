# Aquarius

[![Swift](https://github.com/CrazyFanFan/Aquarius/actions/workflows/xcodebuild.yml/badge.svg?branch=main)](https://github.com/CrazyFanFan/Aquarius/actions/workflows/xcodebuild.yml)

[中文版](https://github.com/CrazyFanFan/Aquarius/blob/master/README_CN.md)
A tool to obtain dependencies by analyzing "Podfile.lock"

## Machine Translation

> :warning: **The following is the result of machine translation**
>
> :warning: **The English in the readme and software is the result of machine translation. Please correct any errors**

**[ChangeLog](./ChangeLog/change_log.md)**

## Environment

- Xcode: version ≥ 26.3
- macOS: version ≥ 14.0

## Preview

![Image](./Screenshots/s_1.jpg)

## Usage

- clone this repo
- open **Aquarius.xcodeproj** by Xcode
- `Command` + `R`, after resolve  Swift Packages

```shell
git clone https://github.com/CrazyFanFan/Aquarius.git
cd Aquarius
open Aquarius.xcodeproj
```

## Author

Crazy凡, [ccrazyfan@gmail.com](mailto:ccrazyfan@gmail.com)

## ChangeLog

### [2026-06-20]

- **Feature**
  - Add Podspec access guidance and syntax highlighting.
  - Improve relation view with better layout, localization, and path loading.
- **Optimize**
  - Improve tree rendering, search, pathfinding, and tree copy performance.
  - Reduce memory use when copying recursive trees.
  - Modernize SwiftUI navigation and startup data flow.
  - Improve CoreData to SwiftData migration safety.
  - Show errors when opening or dropping unsupported files.
  - Use lightweight copy success toasts with automatic dismissal.
  - Rename predecessor tree to reverse dependencies.
  - Update the required Xcode version to 26.3.
  - Update the Xcode project group structure.
- **Fix**
  - Resolve Yams update issues and async task races.
  - Defer startup state updates to avoid initial state conflicts.
  - Reuse the main window and select the opened Podfile.lock when opening files from the command line.
  - Fix fuzzy matching behavior.
  - Update English localizations and typo fixes.
  - Correctly show the cancellation error when copying is cancelled.

### [2025-03-26]

- **Feature**
  - Support multi-column list layout.
  - Support to find the dependency path between two Pods
- **Optimize**
  - Optimize the copy operation of the complete dependency tree.

### [2022-11-18]

- **Feature**
  - Search supports simple fuzzy matching and highlighting.
- Other
  - Change color of some text.
  
### [2020-11-30]

- Add custom order support.
- Switch to core data to save bookmark.
- Support to open multiple Podfile.lock files.
- Support open Podfile.lock by drop on dock icon.
- Some UI details.

## License

Aquarius is released under the MIT license. See [LICENSE](https://github.com/CrazyFanFan/Aquarius/blob/master/LICENSE) for details.

**Additional Terms**:
- **The software may not be used for commercial purposes**. Commercial purposes include, but are not limited to, selling copies of the software, using the software to deliver services for a fee, or including the software in products or services intended for sale.
- **The software may not be distributed through any app stores or other commercial distribution channels**.
