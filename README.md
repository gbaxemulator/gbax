# GBAx

**GBAx** is a Game Boy Advance emulator for Windows, macOS, Linux, and more.

This repository is a branded fork of the upstream mGBA codebase, with user-facing branding (name, icons, About screen, and website links) updated for **GBAx**.

- Website: https://gba-x.com
- License: Mozilla Public License, version 2.0 (MPL-2.0)

## Downloads
Releases are published on GitHub Releases (when enabled for this repo).

## Build (CMake)

### Prerequisites
- CMake
- Ninja (recommended)
- A C/C++ compiler
- Qt 6 (for the Qt desktop UI)

### Build the Qt desktop app

```bash
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_QT=ON
cmake --build build
```

On Windows, the Qt build outputs **`GBAx.exe`**.

## Windows portable folder
A helper script is included to assemble a portable folder similar to upstream Windows releases.

```bash
./tools/package-gbax-windows-msys2.sh build
```

Output:
- `build/dist/GBAx/`

## Rebrand notes
This fork intentionally keeps many internal identifiers (folder names, namespaces, etc.) from upstream for compatibility and to minimize churn.

For a detailed string/path audit of remaining `mgba` references, see:
- `docs/REBRAND_AUDIT.md`

## Trademarks
Game Boy Advance is a trademark of Nintendo. This project is not affiliated with Nintendo.
