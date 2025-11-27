#!/bin/bash

# FFmpeg Thumbnail-Only Build Script for Android ARMv8-A
# This script builds a minimal FFmpeg library optimized for thumbnail generation only

if [[ -z ${ANDROID_SDK_ROOT} ]]; then
  echo -e "\n(*) ANDROID_SDK_ROOT not defined\n"
  exit 1
fi

if [[ -z ${ANDROID_NDK_ROOT} ]]; then
  echo -e "\n(*) ANDROID_NDK_ROOT not defined\n"
  exit 1
fi

# LOAD INITIAL SETTINGS
export BASEDIR="$(pwd)"
export FFMPEG_KIT_BUILD_TYPE="android"
source "${BASEDIR}"/scripts/variable.sh
source "${BASEDIR}"/scripts/function-${FFMPEG_KIT_BUILD_TYPE}.sh
disabled_libraries=()

# ONLY ENABLE ARM64-V8A ARCHITECTURE
ENABLED_ARCHITECTURES[ARCH_ARM_V7A]=0
ENABLED_ARCHITECTURES[ARCH_ARM_V7A_NEON]=0
ENABLED_ARCHITECTURES[ARCH_ARM64_V8A]=1
ENABLED_ARCHITECTURES[ARCH_X86]=0
ENABLED_ARCHITECTURES[ARCH_X86_64]=0

# ENABLE MINIMAL LIBRARIES (only cpu-features and android-zlib)
ENABLED_LIBRARIES[LIBRARY_CPU_FEATURES]=1
ENABLED_LIBRARIES[LIBRARY_SYSTEM_ZLIB]=1

enable_main_build

# DETECT ANDROID NDK VERSION
export DETECTED_NDK_VERSION=$(grep -Eo "Revision.*" "${ANDROID_NDK_ROOT}"/source.properties | sed 's/Revision//g;s/=//g;s/ //g')
echo -e "\nINFO: Using Android NDK v${DETECTED_NDK_VERSION} provided at ${ANDROID_NDK_ROOT}\n" 1>>"${BASEDIR}"/build.log 2>&1
echo -e "INFO: Building FFmpeg for thumbnail generation (ARMv8-A only)\n" 1>>"${BASEDIR}"/build.log 2>&1

# SET DEFAULT BUILD OPTIONS
export GPL_ENABLED="no"
BUILD_VERSION=$(git describe --tags --always 2>>"${BASEDIR}"/build.log)

if [[ -z ${BUILD_VERSION} ]]; then
  echo -e "\n(*) error: Can not run git commands in this folder. See build.log.\n"
  exit 1
fi

# PROCESS BUILD OPTIONS (just copy build.gradle)
rm -f "${BASEDIR}"/android/ffmpeg-kit-android-lib/build.gradle 1>>"${BASEDIR}"/build.log 2>&1
cp "${BASEDIR}"/tools/android/build.gradle "${BASEDIR}"/android/ffmpeg-kit-android-lib/build.gradle 1>>"${BASEDIR}"/build.log 2>&1

# SET API LEVEL IN build.gradle
${SED_INLINE} "s/minSdkVersion .*/minSdkVersion ${API}/g" "${BASEDIR}"/android/ffmpeg-kit-android-lib/build.gradle 1>>"${BASEDIR}"/build.log 2>&1
${SED_INLINE} "s/versionCode ..0/versionCode ${API}0/g" "${BASEDIR}"/android/ffmpeg-kit-android-lib/build.gradle 1>>"${BASEDIR}"/build.log 2>&1

echo -e "\nBuilding ffmpeg-kit thumbnail-only library for Android (ARMv8-A)\n"
echo -e -n "INFO: Building ffmpeg-kit ${BUILD_VERSION} thumbnail-only library for Android: " 1>>"${BASEDIR}"/build.log 2>&1
echo -e "$(date)\n" 1>>"${BASEDIR}"/build.log 2>&1

# PRINT BUILD SUMMARY
echo "Architectures:"
echo "  arm64-v8a: yes"
echo ""
echo "Libraries:"
echo "  cpu-features: yes"
echo "  android-zlib: yes"
echo ""
echo "FFmpeg Configuration:"
echo "  Minimal build for thumbnail generation only"
echo "  Protocols: file, http, https, tcp, udp, crypto"
echo "  Demuxers: mov, matroska, mp4, avi, mpegts, flv, webm"
echo "  Decoders: h264, hevc, vp8, vp9"
echo "  Encoders: mjpeg, png"
echo "  Parsers: h264, hevc, vp8, vp9"
echo ""

echo -n -e "\nDownloading sources: "
echo -e "INFO: Downloading the source code of ffmpeg.\n" 1>>"${BASEDIR}"/build.log 2>&1

# DOWNLOAD GNU CONFIG
download_gnu_config

# DOWNLOAD FFMPEG SOURCE
ENABLED_LIBRARIES_FOR_DOWNLOAD=()
ENABLED_LIBRARIES_FOR_DOWNLOAD[50]=1  # LIBRARY_FFMPEG
downloaded_library_sources "${ENABLED_LIBRARIES_FOR_DOWNLOAD[@]}"
echo ""

# SAVE ORIGINAL API LEVEL
export ORIGINAL_API=${API}

# BUILD FOR ARM64-V8A ONLY
run_arch=${ARCH_ARM64_V8A}

if [[ ${ORIGINAL_API} -lt 21 ]]; then
  # 64 bit ABIs supported after API 21
  export API=21
else
  export API=${ORIGINAL_API}
fi

export ARCH=$(get_arch_name $run_arch)
export TOOLCHAIN=$(get_toolchain)
export TOOLCHAIN_ARCH=$(get_toolchain_arch)

# PREPARE BUILD DIRECTORIES
LIB_INSTALL_BASE="${BASEDIR}/prebuilt/$(get_target_build_directory)/$(get_target_arch)/$(get_library_name $LIBRARY_FFMPEG)"
export LIB_INSTALL_BASE

LIB_INSTALL_PREFIX="${LIB_INSTALL_BASE}"
export LIB_INSTALL_PREFIX

INSTALL_PKG_CONFIG_DIR="${LIB_INSTALL_BASE}/pkgconfig"
export INSTALL_PKG_CONFIG_DIR

mkdir -p "${LIB_INSTALL_BASE}" 1>>"${BASEDIR}"/build.log 2>&1
mkdir -p "${INSTALL_PKG_CONFIG_DIR}" 1>>"${BASEDIR}"/build.log 2>&1

# EXECUTE CUSTOM THUMBNAIL BUILD SCRIPT
HOST=$(get_host)
export HOST

# Source the custom ffmpeg-thumbnail.sh instead of regular ffmpeg.sh
. "${BASEDIR}"/scripts/android/ffmpeg-thumbnail.sh || exit 1

# GET BACK THE ORIGINAL API LEVEL
export API=${ORIGINAL_API}

# SET ARCHITECTURE TO BUILD
ANDROID_ARCHITECTURES="$(get_android_arch 2)"

# BUILD FFMPEG-KIT
if [[ -n ${ANDROID_ARCHITECTURES} ]]; then

  echo -n -e "\nffmpeg-kit: "

  # CREATE Application.mk FILE
  rm -f "${BASEDIR}/android/jni/Application.mk"
  
  BUILD_DATE="-DFFMPEG_KIT_BUILD_DATE=$(date +%Y%m%d 2>>"${BASEDIR}"/build.log)"
  
  cat >"${BASEDIR}/android/jni/Application.mk" <<EOF
APP_OPTIM := release

APP_ABI := ${ANDROID_ARCHITECTURES}

APP_STL := none

APP_PLATFORM := android-${API}

APP_CFLAGS := -O3 -DANDROID ${BUILD_DATE} -Wall -Wno-deprecated-declarations -Wno-pointer-sign -Wno-switch -Wno-unused-result -Wno-unused-variable

APP_LDFLAGS := -Wl,--hash-style=both
EOF

  # CLEAR OLD NATIVE LIBRARIES
  rm -rf "${BASEDIR}"/android/libs 1>>"${BASEDIR}"/build.log 2>&1
  rm -rf "${BASEDIR}"/android/obj 1>>"${BASEDIR}"/build.log 2>&1

  cd "${BASEDIR}"/android 1>>"${BASEDIR}"/build.log 2>&1 || exit 1

  # COPY EXTERNAL LIBRARY LICENSES
  LICENSE_BASEDIR="${BASEDIR}"/android/ffmpeg-kit-android-lib/src/main/res/raw
  rm -f "${LICENSE_BASEDIR}"/*.txt 1>>"${BASEDIR}"/build.log 2>&1 || exit 1

  # COPY LIBRARY LICENSE
  cp "${BASEDIR}"/LICENSE "${LICENSE_BASEDIR}"/license.txt 1>>"${BASEDIR}"/build.log 2>&1 || exit 1
  echo -e "DEBUG: Copied the ffmpeg-kit license successfully\n" 1>>"${BASEDIR}"/build.log 2>&1

  overwrite_file "${BASEDIR}"/tools/source/SOURCE "${LICENSE_BASEDIR}"/source.txt 1>>"${BASEDIR}"/build.log 2>&1 || exit 1
  echo -e "DEBUG: Copied source.txt successfully\n" 1>>"${BASEDIR}"/build.log 2>&1

  # BUILD NATIVE LIBRARY
  if [[ ${SKIP_ffmpeg_kit} -ne 1 ]]; then
    if [ "$(is_darwin_arm64)" == "1" ]; then
       arch -x86_64 "${ANDROID_NDK_ROOT}"/ndk-build -B 1>>"${BASEDIR}"/build.log 2>&1
    else
      "${ANDROID_NDK_ROOT}"/ndk-build -B 1>>"${BASEDIR}"/build.log 2>&1
    fi

    if [ $? -eq 0 ]; then
      echo "ok"
    else
      echo "failed"
      exit 1
    fi
  else
    echo "skipped"
  fi

  echo -e -n "\n"

  # DO NOT BUILD ANDROID ARCHIVE BY DEFAULT (can be enabled later if needed)
  echo -e "\nINFO: Skipping Android archive creation. Use gradlew manually if needed.\n" 1>>"${BASEDIR}"/build.log 2>&1
fi

echo -e "\n=========================================="
echo -e "Build completed successfully!"
echo -e "==========================================\n"
echo -e "Architecture: arm64-v8a"
echo -e "Native libraries location: ${BASEDIR}/android/libs/arm64-v8a/"
echo -e "FFmpeg installation: ${LIB_INSTALL_BASE}\n"
