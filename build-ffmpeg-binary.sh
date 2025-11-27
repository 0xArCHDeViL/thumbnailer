#!/bin/bash

# ============================================================================
# FFmpeg Binary Build Script for Android (ARMv8-A)
# Minimal configuration for thumbnail generation
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "FFmpeg Binary Build for Android (ARMv8-A)"
echo "=========================================="

# ============================================================================
# Configuration
# ============================================================================

FFMPEG_VERSION="6.1"
ANDROID_API_LEVEL=24
ANDROID_ARCH="aarch64"
TARGET_TRIPLE="aarch64-linux-android"

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/ffmpeg-build"
SOURCE_DIR="${BUILD_DIR}/ffmpeg-${FFMPEG_VERSION}"
OUTPUT_DIR="${SCRIPT_DIR}/output"
TOOLCHAIN_DIR="${BUILD_DIR}/toolchain"

# ============================================================================
# Check Prerequisites
# ============================================================================

echo -e "\n${YELLOW}[1/6]${NC} Checking prerequisites..."

if [ -z "${ANDROID_NDK_ROOT}" ]; then
    # Try to find NDK in common locations
    if [ -d "${HOME}/Android/Sdk/ndk" ]; then
        # Find latest NDK version
        ANDROID_NDK_ROOT=$(ls -d ${HOME}/Android/Sdk/ndk/* | sort -V | tail -n1)
        export ANDROID_NDK_ROOT
        echo "Found NDK at: ${ANDROID_NDK_ROOT}"
    else
        echo -e "${RED}ERROR: ANDROID_NDK_ROOT not set and NDK not found${NC}"
        echo "Please set ANDROID_NDK_ROOT environment variable"
        echo "Example: export ANDROID_NDK_ROOT=/path/to/android-ndk"
        exit 1
    fi
fi

echo "Android NDK: ${ANDROID_NDK_ROOT}"

# Check for required tools
for tool in wget tar; do
    if ! command -v $tool &> /dev/null; then
        echo -e "${RED}ERROR: $tool not found${NC}"
        echo "Please install $tool"
        exit 1
    fi
done

# ============================================================================
# Setup Build Directory
# ============================================================================

echo -e "\n${YELLOW}[2/6]${NC} Setting up build directory..."

mkdir -p "${BUILD_DIR}"
mkdir -p "${OUTPUT_DIR}"

# ============================================================================
# Download FFmpeg Source
# ============================================================================

echo -e "\n${YELLOW}[3/6]${NC} Downloading FFmpeg source..."

if [ ! -d "${SOURCE_DIR}" ]; then
    cd "${BUILD_DIR}"
    
    FFMPEG_TARBALL="ffmpeg-${FFMPEG_VERSION}.tar.xz"
    
    if [ ! -f "${FFMPEG_TARBALL}" ]; then
        echo "Downloading FFmpeg ${FFMPEG_VERSION}..."
        wget -q --show-progress "https://ffmpeg.org/releases/${FFMPEG_TARBALL}"
    fi
    
    echo "Extracting FFmpeg source..."
    tar -xf "${FFMPEG_TARBALL}"
    
    echo "FFmpeg source ready at: ${SOURCE_DIR}"
else
    echo "FFmpeg source already exists, skipping download"
fi

# ============================================================================
# Setup Android NDK Toolchain
# ============================================================================

echo -e "\n${YELLOW}[4/6]${NC} Setting up Android NDK toolchain..."

# NDK toolchain paths
NDK_TOOLCHAIN="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64"

# Check if toolchain exists
if [ ! -d "${NDK_TOOLCHAIN}" ]; then
    # Try darwin (macOS)
    NDK_TOOLCHAIN="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/darwin-x86_64"
    if [ ! -d "${NDK_TOOLCHAIN}" ]; then
        echo -e "${RED}ERROR: NDK toolchain not found${NC}"
        exit 1
    fi
fi

# Setup toolchain environment
export PATH="${NDK_TOOLCHAIN}/bin:${PATH}"
export CC="${NDK_TOOLCHAIN}/bin/${TARGET_TRIPLE}${ANDROID_API_LEVEL}-clang"
export CXX="${NDK_TOOLCHAIN}/bin/${TARGET_TRIPLE}${ANDROID_API_LEVEL}-clang++"
export AR="${NDK_TOOLCHAIN}/bin/llvm-ar"
export AS="${CC}"
export LD="${NDK_TOOLCHAIN}/bin/ld"
export RANLIB="${NDK_TOOLCHAIN}/bin/llvm-ranlib"
export STRIP="${NDK_TOOLCHAIN}/bin/llvm-strip"

# Compiler flags
export CFLAGS="-O3 -fPIC -DANDROID -D__ANDROID_API__=${ANDROID_API_LEVEL}"
export LDFLAGS="-lm -lz -llog"

echo "Toolchain configured for ${TARGET_TRIPLE}"

# ============================================================================
# Configure FFmpeg
# ============================================================================

echo -e "\n${YELLOW}[5/6]${NC} Configuring FFmpeg..."

cd "${SOURCE_DIR}"

echo "Running configure with minimal flags..."

# Clean previous build (only if previously configured)
if [ -f "config.h" ]; then
    echo "Cleaning previous build..."
    make distclean 2>/dev/null || true
fi


./configure \
  --prefix="${OUTPUT_DIR}" \
  --enable-cross-compile \
  --target-os=android \
  --arch=${ANDROID_ARCH} \
  --cpu=armv8-a \
  --cross-prefix="${NDK_TOOLCHAIN}/bin/llvm-" \
  --cc="${CC}" \
  --cxx="${CXX}" \
  --enable-static \
  --disable-shared \
  --enable-small \
  --disable-debug \
  --disable-stripping \
  --enable-neon \
  --enable-asm \
  --enable-inline-asm \
  --disable-symver \
  --enable-pthreads \
  \
  --disable-ffplay \
  --disable-doc \
  \
  --disable-everything \
  \
  --enable-protocol=file \
  --enable-protocol=http \
  --enable-protocol=https \
  --enable-protocol=tcp \
  --enable-protocol=udp \
  --enable-protocol=crypto \
  \
  --enable-demuxer=mov \
  --enable-demuxer=matroska \
  --enable-demuxer=mp4 \
  --enable-demuxer=avi \
  --enable-demuxer=mpegts \
  --enable-demuxer=flv \
  --enable-demuxer=webm \
  \
  --enable-decoder=h264 \
  --enable-decoder=hevc \
  --enable-decoder=vp8 \
  --enable-decoder=vp9 \
  \
  --enable-swscale \
  --enable-swresample \
  \
  --enable-encoder=mjpeg \
  --enable-muxer=mjpeg \
  --enable-encoder=png \
  --enable-muxer=png \
  \
  --enable-parser=h264 \
  --enable-parser=hevc \
  --enable-parser=vp8 \
  --enable-parser=vp9 \
  \
  --enable-zlib

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: FFmpeg configure failed${NC}"
    echo "Check the error messages above"
    exit 1
fi

echo -e "${GREEN}Configuration successful${NC}"

# ============================================================================
# Build FFmpeg
# ============================================================================

echo -e "\n${YELLOW}[6/6]${NC} Building FFmpeg binaries..."

# Get number of CPU cores for parallel build
if command -v nproc &> /dev/null; then
    JOBS=$(nproc)
else
    JOBS=4
fi

echo "Building with ${JOBS} parallel jobs..."

make -j${JOBS}

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: FFmpeg build failed${NC}"
    exit 1
fi

echo "Installing binaries..."
make install

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: FFmpeg install failed${NC}"
    exit 1
fi

# ============================================================================
# Strip Binaries
# ============================================================================

echo "Stripping binaries to reduce size..."
${STRIP} "${OUTPUT_DIR}/bin/ffmpeg"
${STRIP} "${OUTPUT_DIR}/bin/ffprobe"

# Get size after stripping
FFMPEG_SIZE_BEFORE=$(du -h "${OUTPUT_DIR}/bin/ffmpeg" | cut -f1)
FFPROBE_SIZE_BEFORE=$(du -h "${OUTPUT_DIR}/bin/ffprobe" | cut -f1)

# ============================================================================
# UPX Compression (Maximum Size Reduction)
# ============================================================================

echo "Compressing binaries with UPX for maximum size reduction..."

# Check if UPX is available
if command -v upx &> /dev/null; then
    echo "Using UPX to compress binaries..."
    
    # Compress with best compression
    upx --best --lzma "${OUTPUT_DIR}/bin/ffmpeg" 2>&1 | grep -v "WARNING" || true
    upx --best --lzma "${OUTPUT_DIR}/bin/ffprobe" 2>&1 | grep -v "WARNING" || true
    
    echo -e "${GREEN}UPX compression completed${NC}"
else
    echo -e "${YELLOW}WARNING: UPX not found, skipping compression${NC}"
    echo "Install UPX for ~60% size reduction:"
    echo "  Ubuntu/Debian: sudo apt-get install upx-ucl"
    echo "  macOS: brew install upx"
fi


# ============================================================================
# Summary
# ============================================================================

echo ""
echo "=========================================="
echo -e "${GREEN}Build completed successfully!${NC}"
echo "=========================================="
echo ""
echo "Output directory: ${OUTPUT_DIR}"
echo ""
echo "Binary Sizes:"
FFMPEG_SIZE=$(du -h "${OUTPUT_DIR}/bin/ffmpeg" | cut -f1)
FFPROBE_SIZE=$(du -h "${OUTPUT_DIR}/bin/ffprobe" | cut -f1)

if command -v upx &> /dev/null; then
    echo "  ffmpeg:  ${FFMPEG_SIZE_BEFORE} → ${FFMPEG_SIZE} (compressed)"
    echo "  ffprobe: ${FFPROBE_SIZE_BEFORE} → ${FFPROBE_SIZE} (compressed)"
else
    echo "  ffmpeg:  ${FFMPEG_SIZE}"
    echo "  ffprobe: ${FFPROBE_SIZE}"
fi
echo ""
echo "Test the binaries:"
echo "  adb push ${OUTPUT_DIR}/bin/ffmpeg /data/local/tmp/"
echo "  adb shell chmod +x /data/local/tmp/ffmpeg"
echo "  adb shell /data/local/tmp/ffmpeg -version"
echo ""
