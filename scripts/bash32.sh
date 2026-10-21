#!/usr/bin/env bash
# Print the path of a bash 3.2 (macOS /bin/bash equivalent), building it if needed.
# Order: $BASH32 -> docker image bash:3.2 (wrapper) -> cached source build in .cache/bash32.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT=$PWD
if [[ -n "${BASH32:-}" ]]; then echo "$BASH32"; exit 0; fi
if command -v docker >/dev/null && docker info >/dev/null 2>&1; then
  W="$ROOT/.cache/bash32-docker"; mkdir -p .cache
  printf '#!/bin/sh\nexec docker run --rm -i -v "%s:%s" -w "$PWD" -e TCC_PREFLIGHT_MOCK -e TCC_PREFLIGHT_TRACE bash:3.2 bash "$@"\n' "$ROOT" "$ROOT" > "$W"; chmod +x "$W"
  echo "$W"; exit 0; fi
B="$ROOT/.cache/bash32/bin/bash"
if [[ ! -x "$B" ]]; then
  command -v bison >/dev/null || { echo "need bison (and gcc, make) to build bash 3.2" >&2; exit 1; }
  T=$(mktemp -d); ( cd "$T"
    curl -fsSL https://ftp.gnu.org/gnu/bash/bash-3.2.57.tar.gz | tar xz && cd bash-3.2.57
    F="-O1 -std=gnu89 -Wno-implicit-function-declaration -Wno-int-conversion -Wno-incompatible-pointer-types -Wno-implicit-int"
    ./configure --prefix="$ROOT/.cache/bash32" --without-bash-malloc CFLAGS="$F" >/dev/null
    touch parse.y   # regenerate y.tab.c with bison
    make -j4 YACC="bison -y" CFLAGS_FOR_BUILD="$F" CFLAGS="$F" >/dev/null 2>&1
    make install YACC="bison -y" CFLAGS="$F" >/dev/null 2>&1 ) >&2
  rm -rf "$T"
fi
echo "$B"
