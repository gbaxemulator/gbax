# Contributing to GBAx

Thanks for helping improve GBAx.

## Quick rules
- Keep changes focused and easy to review.
- Prefer small PRs.
- If you change user-facing text/branding, make sure it says **GBAx** (not upstream names).

## Build & test
Please ensure CI builds locally (or at least your target platform):

```bash
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_QT=ON
cmake --build build
```

## Licensing
By contributing, you agree your contributions are licensed under **MPL-2.0**, consistent with this repository.
