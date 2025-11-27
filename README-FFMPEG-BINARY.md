# FFmpeg Binary Build for Android + GitHub Actions

Automated build system untuk compile FFmpeg sebagai standalone binary untuk Android ARMv8-A, dengan GitHub Actions CI/CD.

## 🎯 Overview

Project ini menyediakan:
- ✅ Standalone FFmpeg binary untuk Android (tidak perlu library)
- ✅ Automated build via GitHub Actions
- ✅ Minimal configuration untuk thumbnail generation
- ✅ Optimized untuk size dan performance
- ✅ Include `ffmpeg` dan `ffprobe` binaries

## 📋 Requirements

### Local Build

- **Android NDK** (r21+, recommended r26b)
- **Build tools:** wget, tar, xz-utils
- **OS:** Linux or macOS
- **Arch:** x86_64 (untuk host machine)

### GitHub Actions

Tidak ada requirements - semua dependencies di-install otomatis.

## 🚀 Quick Start

### Option 1: Build Locally

```bash
# Set Android NDK path (jika belum set)
export ANDROID_NDK_ROOT=/path/to/android-ndk

# Run build script
chmod +x build-ffmpeg-binary.sh
./build-ffmpeg-binary.sh
```

### Option 2: Build via GitHub Actions

1. **Push ke repository** atau **trigger manual**:
   - Go to Actions tab di GitHub
   - Select "Build FFmpeg Binary for Android"
   - Click "Run workflow"

2. **Download artifacts** setelah build selesai:
   - Go to workflow run page
   - Scroll ke "Artifacts" section
   - Download `ffmpeg-android-arm64-binary` atau `ffmpeg-android-arm64-tarball`

## 📦 Output

Setelah build selesai, Anda akan mendapat:

```
output/
├── bin/
│   ├── ffmpeg      # Main binary (~8-10MB)
│   └── ffprobe     # Metadata tool (~6-8MB)
└── ...
```

**Tarball** (di GitHub Actions):
```
ffmpeg-android-arm64.tar.gz
├── ffmpeg
└── ffprobe
```

## 📱 Usage on Android Device

### 1. Push Binary to Device

```bash
adb push output/bin/ffmpeg /data/local/tmp/
adb shell chmod +x /data/local/tmp/ffmpeg
```

### 2. Test Binary

```bash
# Check version
adb shell /data/local/tmp/ffmpeg -version

# List supported formats
adb shell /data/local/tmp/ffmpeg -formats

# List supported codecs
adb shell /data/local/tmp/ffmpeg -codecs
```

### 3. Generate Thumbnail

```bash
# Extract frame at 5 seconds as JPEG
adb shell /data/local/tmp/ffmpeg -i /sdcard/video.mp4 -ss 00:00:05 -vframes 1 /sdcard/thumb.jpg

# Extract frame as PNG with specific size
adb shell /data/local/tmp/ffmpeg -i /sdcard/video.mp4 -ss 5 -vf scale=320:240 -vframes 1 /sdcard/thumb.png
```

### 4. Use ffprobe for Metadata

```bash
# Get video information
adb shell /data/local/tmp/ffprobe /sdcard/video.mp4

# Get duration, resolution, etc in JSON format
adb shell /data/local/tmp/ffprobe -v quiet -print_format json -show_format -show_streams /sdcard/video.mp4
```

## 🔧 Configuration

### FFmpeg Build Configuration

Build ini menggunakan konfigurasi minimal:

#### Enabled Components

**Protocols:**
- `file` - File I/O
- `http`, `https` - HTTP streaming
- `tcp`, `udp` - Network protocols
- `crypto` - Encryption support

**Demuxers (Input Formats):**
- `mov`, `mp4` - QuickTime/MP4
- `matroska`, `webm` - MKV/WebM
- `avi` - AVI container
- `mpegts` - MPEG Transport Stream
- `flv` - Flash Video

**Decoders:**
- `h264` (AVC) - Most common video codec
- `hevc` (H.265) - Modern high-efficiency codec
- `vp8`, `vp9` - WebM video codecs

**Encoders:**
- `mjpeg` - Motion JPEG (for video thumbnails)
- `png` - PNG images

**Parsers:**
- `h264`, `hevc`, `vp8`, `vp9` - Stream parsers

**Libraries:**
- `swscale` - Video scaling/conversion
- `swresample` - Audio resampling
- `zlib` - Compression

#### Disabled Components

- ❌ All audio codecs (except built-in)
- ❌ All filters (except swscale)
- ❌ Hardware acceleration (NVENC, VAAPI, etc.)
- ❌ External libraries (x264, x265, etc.)
- ❌ Network servers
- ❌ GUI tools (ffplay)

### Modify Configuration

Edit `build-ffmpeg-binary.sh`, section "Configure FFmpeg":

```bash
./configure \
  # ... existing flags ...
  --enable-decoder=mpeg4 \     # Add MPEG-4 decoder
  --enable-encoder=h264 \      # Add H.264 encoder (if needed)
  # ... more flags ...
```

## 🤖 GitHub Actions Workflow

### Workflow Features

| Feature | Description |
|---------|-------------|
| **Auto-trigger** | Runs on push to main/master |
| **Manual trigger** | Can be triggered manually with custom FFmpeg version |
| **Artifact upload** | Uploads binaries with 90-day retention |
| **Build info** | Generates detailed build information |
| **Release creation** | Auto-creates release on tag push |

### Workflow Triggers

```yaml
# Auto-run on push
on:
  push:
    branches: [ main, master ]
  
  # Manual trigger with options  
  workflow_dispatch:
    inputs:
      ffmpeg_version:
        description: 'FFmpeg version to build'
        default: '6.1'
```

### Manual Trigger

1. Go to **Actions** tab in GitHub
2. Select **"Build FFmpeg Binary for Android"**
3. Click **"Run workflow"**
4. Optional: Specify custom FFmpeg version
5. Click **"Run workflow"** button

### Download Artifacts

After workflow completes:

1. Go to workflow run page
2. Scroll to **"Artifacts"** section
3. Download:
   - `ffmpeg-android-arm64-binary` - ffmpeg binary only
   - `ffprobe-android-arm64-binary` - ffprobe binary only
   - `ffmpeg-android-arm64-tarball` - Both binaries in tar.gz
   - `build-info` - Build information text file

## 🏷️ Creating Releases

### Automatic Release on Tag

```bash
# Tag your commit
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

GitHub Actions akan otomatis:
1. Build FFmpeg binary
2. Create GitHub Release
3. Upload tarball ke release assets

## 🐛 Troubleshooting

### Local Build Issues

#### Error: `ANDROID_NDK_ROOT not set`

**Solution:**
```bash
export ANDROID_NDK_ROOT=/path/to/android-ndk
# Or let script auto-detect from ~/Android/Sdk/ndk/
```

#### Error: `wget: command not found`

**Solution (Ubuntu/Debian):**
```bash
sudo apt-get install wget tar xz-utils
```

**Solution (macOS):**
```bash
brew install wget
```

#### Error: `Configure failed`

**Solution:** Check build log for specific error. Common issues:
- NDK toolchain not found
- Missing dependencies
- Incompatible NDK version

### GitHub Actions Issues

#### Workflow not triggering

**Check:**
- Workflow file is in `.github/workflows/` directory
- File extension is `.yml` or `.yaml`
- YAML syntax is valid
- Branch name matches trigger configuration

#### Build fails on GitHub but works locally

**Check:**
- GitHub runner is Ubuntu (script has Linux-specific paths)
- NDK version matches (workflow uses r26b)
- File permissions are correct

### Android Device Issues

#### Error: `Permission denied`

**Solution:**
```bash
adb shell chmod +x /data/local/tmp/ffmpeg
```

#### Error: `cannot execute binary file`

**Reasons:**
- Binary built for wrong architecture
- Corrupted file during transfer
- SELinux restrictions

**Solution:**
```bash
# Check binary architecture
file ffmpeg  # Should show: ARM aarch64

# Try pushing to different location
adb push ffmpeg /data/data/com.termux/files/usr/bin/
```

## 📊 Build Time & Size

### Build Time

| Environment | Time |
|-------------|------|
| Local (8-core CPU) | ~10-15 minutes |
| GitHub Actions | ~8-12 minutes |

### Binary Size

| Binary | Unstripped | Stripped |
|--------|------------|----------|
| ffmpeg | ~12MB | ~8-10MB |
| ffprobe | ~8MB | ~6-8MB |

### Size Optimization

Current optimizations:
- ✅ `--enable-small` - Optimize for size
- ✅ `--disable-debug` - No debug symbols
- ✅ `strip` command - Remove symbols

Further optimization (optional):
```bash
# Install UPX
sudo apt-get install upx-ucl

# Compress binary (reduces ~60%)
upx --best output/bin/ffmpeg
# Result: ~3-4MB but slower startup
```

## 🔐 Security Notes

- Binaries are built from official FFmpeg source
- No external libraries (except Android system libs)
- Static linking untuk minimize dependencies
- No network code in binary itself (protocols are for file access)

## 📄 Files Structure

```
.
├── build-ffmpeg-binary.sh          # Main build script
├── .github/
│   └── workflows/
│       └── build-ffmpeg.yml        # GitHub Actions workflow
├── README-FFMPEG-BINARY.md         # This file
├── ffmpeg-build/                   # Build directory (temporary)
│   ├── ffmpeg-6.1/                # FFmpeg source
│   └── ffmpeg-6.1.tar.xz          # Source tarball
└── output/                         # Build output
    ├── bin/
    │   ├── ffmpeg                  # FFmpeg binary
    │   └── ffprobe                 # FFprobe binary
    └── share/                      # Documentation, etc.
```

## 🙏 Credits

- **FFmpeg project:** https://ffmpeg.org/
- **Android NDK:** https://developer.android.com/ndk
- **GitHub Actions:** https://github.com/features/actions

## 📝 License

FFmpeg is licensed under LGPL 2.1 or later.

This build script is provided as-is without warranty.
