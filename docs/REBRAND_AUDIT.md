# GBAx Rebrand Audit (string/path scan)

Generated: 2026-02-18T09:40:02.395125Z

## Summary
- Total text occurrences of `mgba` (case-insensitive): **5816**
- Files/folders whose *paths* contain `mgba`: **212**

These remaining references are primarily **internal engine identifiers** (include paths, namespaces, platform backends) and do **not** necessarily appear in the end-user UI.

## Top files by `mgba` occurrences

| File | Count |
|---|---:|
| `src/platform/libretro/libretro_core_options_intl.h` | 3108 |
| `CHANGES` | 440 |
| `README_DE.md` | 62 |
| `README_ES.md` | 49 |
| `README.md` | 48 |
| `README_ZH_CN.md` | 46 |
| `CMakeLists.txt` | 39 |
| `src/platform/libretro/libretro.c` | 31 |
| `src/platform/python/_builder.py` | 28 |
| `src/gba/core.c` | 23 |

## Path matches by top-level folder

| Top-level | Count |
|---|---:|
| `include/` | 151 |
| `src/` | 37 |
| `res/` | 14 |
| `tools/` | 6 |
| `doc/` | 2 |
| `opt/` | 2 |

## Examples of internal identifiers that remain

- `include/mgba-util/...`
- `src/mgba/...`
- `namespace mgba` in various modules
- `src/platform/libretro/...` (large block of upstream option strings)

## Notes

If you want a *full internal rename* (folders/namespaces/include paths), that is a larger refactor and should be done in controlled phases to avoid breaking ABI/API and build scripts.
