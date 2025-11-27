# FFmpeg Thumbnail-Only Build for Android

Build script khusus untuk compile FFmpeg Android yang minimal, optimized untuk thumbnail generation saja.

## Requirements

- Android SDK (set `ANDROID_SDK_ROOT`)
- Android NDK (set `ANDROID_NDK_ROOT`)
- Git
- Bash
- Build tools (make, gcc, etc.)

## Konfigurasi Build

Script ini akan build FFmpeg dengan konfigurasi minimal:

### Architecture
- **arm64-v8a (ARMv8-A) only**
- NEON enabled
- ASM optimization enabled

### FFmpeg Components

**Protocols:**
- file, http, https, tcp, udp, crypto

**Demuxers:**
- mov, matroska, mp4, avi, mpegts, flv, webm

**Decoders:**
- h264, hevc, vp8, vp9

**Encoders:**
- mjpeg, png

**Parsers:**
- h264, hevc, vp8, vp9

**Libraries:**
- swscale (untuk scaling/conversion)
- swresample (untuk audio resampling)
- zlib (Android system zlib)

## Cara Menggunakan

### 1. Set Environment Variables

```bash
export ANDROID_SDK_ROOT=/path/to/android/sdk
export ANDROID_NDK_ROOT=/path/to/android/ndk
```

### 2. Jalankan Build Script

```bash
cd /home/muhfdelxander/Project/FFMPEG/ffmpeg-kit
./build-thumbnail-android.sh
```

### 3. Output

Setelah build selesai, Anda akan mendapatkan:

- **Native libraries (.so):** `android/libs/arm64-v8a/`
- **FFmpeg installation:** `prebuilt/android-arm64/arm64-v8a/ffmpeg/`
- **Build log:** `build.log`

## Files yang Dibuat

1. **build-thumbnail-android.sh** - Main build launcher script
   - Mengatur environment untuk build ARM64 only
   - Download FFmpeg source
   - Memanggil custom FFmpeg configuration script
   - Build native libraries

2. **scripts/android/ffmpeg-thumbnail.sh** - Custom FFmpeg configuration
   - Konfigurasi `./configure` dengan flag minimal
   - `--disable-everything` kemudian enable hanya yang diperlukan
   - Optimized untuk size dengan `--enable-small`

## Troubleshooting

### Error: ANDROID_SDK_ROOT not defined
```bash
export ANDROID_SDK_ROOT=/path/to/android/sdk
```

### Error: ANDROID_NDK_ROOT not defined
```bash
export ANDROID_NDK_ROOT=/path/to/android/ndk
```

### Build failed - check build.log
```bash
tail -100 build.log
```

### Clean build (jika perlu rebuild dari awal)
```bash
# Delete prebuilt directory
rm -rf prebuilt/

# Delete source downloads
rm -rf src/ffmpeg

# Run build again
./build-thumbnail-android.sh
```

## Integrasi dengan Android Project

Setelah build selesai, copy native libraries ke project Android Anda:

```bash
# Copy .so files
cp android/libs/arm64-v8a/*.so /path/to/your/android/project/src/main/jniLibs/arm64-v8a/
```

## Notes

- Build ini **hanya untuk ARMv8-A** (arm64-v8a). Jika perlu architecture lain, edit `build-thumbnail-android.sh`
- Library yang dihasilkan **sangat minimal** dan hanya bisa untuk thumbnail generation
- Tidak termasuk fitur audio encoding/decoding selain yang necessary untuk video processing
- Static library disabled, hanya build shared library (.so) untuk Android JNI
