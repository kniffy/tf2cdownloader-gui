#!/usr/bin/env bash
set -eu

## run this within the chicken source dir (chicken-5.4.0)

make PREFIX=/opt/chicken-shit/target PLATFORM=cross-linux-mingw \
        HOSTSYSTEM=x86_64-w64-mingw32 \
        TARGET_FEATURES="-no-feature linux -feature windows"
make PREFIX=/opt/chicken-shit/target PLATFORM=cross-linux-mingw \
        HOSTSYSTEM=x86_64-w64-mingw32 \
        TARGET_FEATURES="-no-feature linux -feature windows" \
        install

echo "============="
echo "aaaaaaaaaaaaa"

make confclean

make PREFIX=/opt/chicken-shit/cross PROGRAM_PREFIX=mingw- \
        TARGET_PREFIX=/opt/chicken-shit/target PLATFORM=linux \
        TARGETSYSTEM=x86_64-w64-mingw32 TARGET_LIBRARIES="-lm -lws2_32" \
        TARGET_FEATURES="-no-feature linux -feature windows"
make PREFIX=/opt/chicken-shit/cross PROGRAM_PREFIX=mingw- \
        TARGET_PREFIX=/opt/chicken-shit/target PLATFORM=linux \
        TARGETSYSTEM=x86_64-w64-mingw32 TARGET_LIBRARIES="-lm -lws2_32" \
        TARGET_FEATURES="-no-feature linux -feature windows" \
        install

echo " all done?"
