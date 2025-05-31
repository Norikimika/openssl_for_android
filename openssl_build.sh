#!/bin/bash -e

################################################################################
#   Copyright 2021-2025 217heidai<217heidai@gmail.com>
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
################################################################################

################################################################################
#   build OpenSSL for Android armeabi-v7a arm64-v8a x86 x86_64 riscv64
#   support Linux and macOS
################################################################################


WORK_PATH=$(cd "$(dirname "$0")";pwd)

ANDROID_TARGET_ABI=$1
OPENSSL_VERSION=$2
ANDROID_NDK_VERSION=$3
ANDROID_NDK_PATH=${WORK_PATH}/android-ndk-${ANDROID_NDK_VERSION}
OPENSSL_PATH=${WORK_PATH}/openssl-${OPENSSL_VERSION}
OUTPUT_PATH=${WORK_PATH}/openssl_${OPENSSL_VERSION}_${ANDROID_TARGET_ABI}
OPENSSL_OPTIONS="no-asm no-docs no-engine no-gost no-legacy no-shared no-tests no-zlib"

if [ "$(uname -s)" == "Darwin" ]; then
    echo "Build on macOS..."
    PLATFORM="darwin"
    export alias nproc="sysctl -n hw.logicalcpu"
else
    echo "Build on Linux..."
    PLATFORM="linux"
fi

function build(){
    mkdir ${OUTPUT_PATH}

    cd ${OPENSSL_PATH}

    export ANDROID_NDK_ROOT=${ANDROID_NDK_PATH}
    export PATH=${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${PLATFORM}-x86_64/bin:$PATH
    export CXXFLAGS="-fPIC -Os -flto"
    export CPPFLAGS="-DANDROID -fPIC -Os -flto"

    if   [ "${ANDROID_TARGET_ABI}" == "armeabi-v7a" ]; then
        ./Configure android-arm -static ${OPENSSL_OPTIONS} --prefix=${OUTPUT_PATH}
    elif [ "${ANDROID_TARGET_ABI}" == "arm64-v8a"   ]; then
        ./Configure android-arm64 -static ${OPENSSL_OPTIONS} --prefix=${OUTPUT_PATH}
    elif [ "${ANDROID_TARGET_ABI}" == "x86"         ]; then
        ./Configure android-x86 -static ${OPENSSL_OPTIONS} --prefix=${OUTPUT_PATH}
    elif [ "${ANDROID_TARGET_ABI}" == "x86_64"      ]; then
        ./Configure android-x86_64 -static ${OPENSSL_OPTIONS} --prefix=${OUTPUT_PATH}
    elif [ "${ANDROID_TARGET_ABI}" == "riscv64"     ]; then
        ./Configure android-riscv64 -static ${OPENSSL_OPTIONS} --prefix=${OUTPUT_PATH}
    else
        echo "Unsupported target ABI: ${ANDROID_TARGET_ABI}"
        exit 1
    fi

    make -j$(nproc)
    make install

    echo "Stripping binaries..."
    STRIP_TOOL=${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${PLATFORM}-x86_64/bin/llvm-strip

    if [ -f "${OUTPUT_PATH}/bin/openssl" ]; then
        echo "Stripping ${OUTPUT_PATH}/bin/openssl"
        ${STRIP_TOOL} ${OUTPUT_PATH}/bin/openssl
    else
        echo "Warning: ${OUTPUT_PATH}/bin/openssl not found, skipping strip."
    fi

    echo "Build completed! Check output libraries in ${OUTPUT_PATH}"
}

function clean(){
    if [ -d ${OUTPUT_PATH} ]; then
        rm -rf ${OUTPUT_PATH}/share
        rm -rf ${OUTPUT_PATH}/ssl
        rm -rf ${OUTPUT_PATH}/lib/cmake
        rm -rf ${OUTPUT_PATH}/lib/engines-3
        rm -rf ${OUTPUT_PATH}/lib/ossl-modules
        rm -rf ${OUTPUT_PATH}/lib/pkgconfig
    fi
}

build
clean
