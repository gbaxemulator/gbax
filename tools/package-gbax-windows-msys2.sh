#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# GBAx Windows (MSYS2/MinGW64) "production portable" packager
#
# Goal:
#   Produce a folder that runs on a clean Windows machine:
#     - GBAx.exe
#     - libGBAx.dll (core)
#     - Qt runtime + plugins (platforms/qwindows.dll, imageformats, etc.)
#     - MinGW runtime DLLs + any other dependent DLLs (FFmpeg, epoxy, etc.)
#
# Usage (run inside MSYS2 MINGW64 shell, after a successful build):
#   tools/package-gbax-windows-msys2.sh [build_dir]
#
# Example:
#   cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_QT=ON
#   cmake --build build
#   tools/package-gbax-windows-msys2.sh build
# -----------------------------------------------------------------------------

BUILD_DIR="${1:-build}"
PROJECT_NAME="GBAx"

DIST_DIR="${BUILD_DIR}/dist/${PROJECT_NAME}"
mkdir -p "${DIST_DIR}"

die() { echo "ERROR: $*" >&2; exit 1; }
warn() { echo "WARN: $*" >&2; }

# -----------------------------------------------------------------------------
# 1) Locate the built executable
# -----------------------------------------------------------------------------
EXE_PATH=""

# Prefer branded name
EXE_PATH="$(find "${BUILD_DIR}" -maxdepth 10 -type f -iname "${PROJECT_NAME}.exe" | head -n 1 || true)"

# Fallbacks (upstream naming)
if [[ -z "${EXE_PATH}" ]]; then
  EXE_PATH="$(find "${BUILD_DIR}" -maxdepth 10 -type f \( -iname "mgba.exe" -o -iname "mGBA.exe" -o -iname "mgba-qt.exe" \) | head -n 1 || true)"
fi

# Last resort: first non-helper exe
if [[ -z "${EXE_PATH}" ]]; then
  EXE_PATH="$(find "${BUILD_DIR}" -maxdepth 12 -type f -iname "*.exe" \
    ! -iname "updater-stub.exe" \
    ! -iname "*sdl*.exe" \
    ! -path "*/CMakeFiles/*" \
    | head -n 1 || true)"
fi

[[ -n "${EXE_PATH}" ]] || die "Could not find a built executable under ${BUILD_DIR}"

echo "[*] Using exe: ${EXE_PATH}"
cp -f "${EXE_PATH}" "${DIST_DIR}/${PROJECT_NAME}.exe"

# -----------------------------------------------------------------------------
# 2) Locate & copy the core runtime DLL (libGBAx.dll / libmgba.dll)
# -----------------------------------------------------------------------------
CORE_DLL="$(find "${BUILD_DIR}" -maxdepth 12 -type f \( \
  -iname "lib${PROJECT_NAME}.dll" -o -iname "${PROJECT_NAME}.dll" -o \
  -iname "libmgba.dll" -o -iname "mgba.dll" \
\) | head -n 1 || true)"

if [[ -n "${CORE_DLL}" ]]; then
  echo "[*] Found core DLL: ${CORE_DLL}"
  cp -f "${CORE_DLL}" "${DIST_DIR}/"
else
  warn "Could not find core DLL (lib${PROJECT_NAME}.dll/libmgba.dll). The app will not run without it."
fi

# Portable marker (some frontends look for it)
: > "${DIST_DIR}/portable.ini"

# Copy runtime data folders/files
for p in shaders scripts licenses; do
  if [[ -d "res/${p}" ]]; then
    rm -rf "${DIST_DIR:?}/${p}"
    cp -R "res/${p}" "${DIST_DIR}/${p}"
  fi
done

for f in CHANGES LICENSE README.md README_DE.md README_ES.md README_ZH_CN.md; do
  [[ -f "${f}" ]] && cp -f "${f}" "${DIST_DIR}/"
done

[[ -f "res/nointro.dat" ]] && cp -f "res/nointro.dat" "${DIST_DIR}/nointro.dat"

# -----------------------------------------------------------------------------
# 3) Deploy Qt runtime + plugins (CRITICAL for GUI apps)
# -----------------------------------------------------------------------------
# We rely on Qt5 in current CI (frontend is Qt5-based).
WINDEPLOYQT=""
if command -v windeployqt >/dev/null 2>&1; then
  WINDEPLOYQT="windeployqt"
elif command -v windeployqt-qt5 >/dev/null 2>&1; then
  WINDEPLOYQT="windeployqt-qt5"
elif command -v windeployqt5 >/dev/null 2>&1; then
  WINDEPLOYQT="windeployqt5"
fi

if [[ -n "${WINDEPLOYQT}" ]]; then
  echo "[*] Running ${WINDEPLOYQT} (Qt deploy)..."
  (
    cd "${DIST_DIR}"
    # --compiler-runtime ensures MinGW runtime DLLs get pulled in (libstdc++, libgcc, pthread, etc.)
    "${WINDEPLOYQT}" --no-translations --no-angle --no-opengl-sw --compiler-runtime "${PROJECT_NAME}.exe"
  )
else
  warn "windeployqt not found; Qt plugins may be missing. Install: mingw-w64-x86_64-qt5-tools"
fi

# Validate critical Qt platform plugin exists
if [[ ! -f "${DIST_DIR}/platforms/qwindows.dll" ]]; then
  warn "Qt platform plugin platforms/qwindows.dll is missing. The app will likely not launch."
  warn "Make sure windeployqt is available and that you're using the Qt (not SDL-only) frontend."
fi

# -----------------------------------------------------------------------------
# 4) Copy all non-Qt dependent DLLs (FFmpeg, epoxy, etc.)
# -----------------------------------------------------------------------------
# Even with windeployqt, some DLLs can be missed if they are loaded indirectly.
# Use ntldd to recursively collect dependencies of both the EXE and the core DLL.
copy_deps_with_ntldd() {
  local bin="$1"
  command -v ntldd >/dev/null 2>&1 || return 0

  echo "[*] Collecting dependencies via ntldd for: $(basename "${bin}")"
  # ntldd output often looks like:
  #   foo.dll => /mingw64/bin/foo.dll (0x...)
  # or:
  #   foo.dll => not found
  # We take the resolved path column and copy it if it exists and is not Windows/System32.
  ntldd -R "${bin}" 2>/dev/null \
    | awk '{print $3}' \
    | grep -E '^/|^[A-Za-z]:\\' \
    | grep -vi 'windows/system32' \
    | while read -r dep; do
        # Normalize MSYS paths -> Windows paths are OK too; cp can handle MSYS paths.
        [[ -f "${dep}" ]] && cp -f "${dep}" "${DIST_DIR}/" || true
      done
}

copy_deps_with_ntldd "${DIST_DIR}/${PROJECT_NAME}.exe"
if [[ -n "${CORE_DLL}" ]]; then
  # Use the copy in dist (not the original build path) so ntldd sees local paths the same way end-users will.
  CORE_DLL_BASENAME="$(basename "${CORE_DLL}")"
  if [[ -f "${DIST_DIR}/${CORE_DLL_BASENAME}" ]]; then
    copy_deps_with_ntldd "${DIST_DIR}/${CORE_DLL_BASENAME}"
  fi
fi

# -----------------------------------------------------------------------------
# 5) Hard-include core MinGW runtime DLLs (belt & braces)
# -----------------------------------------------------------------------------
MINGW_BIN="/mingw64/bin"
for dll in libstdc++-6.dll libgcc_s_seh-1.dll libwinpthread-1.dll; do
  if [[ -f "${MINGW_BIN}/${dll}" ]]; then
    cp -f "${MINGW_BIN}/${dll}" "${DIST_DIR}/"
  fi
done

# -----------------------------------------------------------------------------
# 6) Final sanity printout
# -----------------------------------------------------------------------------
echo "[*] Dist contents (top-level):"
ls -la "${DIST_DIR}" | sed -n '1,120p' || true

if [[ -f "${DIST_DIR}/${PROJECT_NAME}.exe" ]]; then
  echo "[✓] Portable folder created at: ${DIST_DIR}"
  echo "    Run: ${PROJECT_NAME}.exe"
else
  die "Packaging failed: ${PROJECT_NAME}.exe missing in dist."
fi
