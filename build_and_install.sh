#!/usr/bin/env bash

set -e

# ==============================================================================
# Flutter Build & Install Script
# ==============================================================================

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Default options
BUILD_MODE="release"
SPLIT_PER_ABI=false
CLEAN_BUILD=false
AUTO_LAUNCH=false
TARGET_DEVICE=""
PACKAGE_NAME="com.pewpewpaws.sterlin"

print_banner() {
  echo -e "${CYAN}${BOLD}"
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║              Flutter Build & Install Assistant               ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
}

print_help() {
  echo -e "${BOLD}Usage:${NC} ./build_and_install.sh [options]"
  echo ""
  echo -e "${BOLD}Options:${NC}"
  echo "  -r, --release          Build in release mode (default)"
  echo "  -d, --debug            Build in debug mode"
  echo "  -s, --split-per-abi    Split APKs per ABI (arm64-v8a, armeabi-v7a, etc.)"
  echo "  -c, --clean            Run 'flutter clean' and 'flutter pub get' before building"
  echo "  -l, --launch           Automatically launch the app after installing"
  echo "  -t, --target <device>  Specify target ADB device ID"
  echo "  -h, --help             Show this help message"
  echo ""
  echo -e "${BOLD}Examples:${NC}"
  echo "  ./build_and_install.sh                      # Release build & install"
  echo "  ./build_and_install.sh -d -l                # Debug build, install, & launch"
  echo "  ./build_and_install.sh -r -s -l             # Split-ABI release build, install, & launch"
  echo "  ./build_and_install.sh --clean --release    # Clean build & install"
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -r|--release)
      BUILD_MODE="release"
      shift
      ;;
    -d|--debug)
      BUILD_MODE="debug"
      shift
      ;;
    -s|--split-per-abi)
      SPLIT_PER_ABI=true
      shift
      ;;
    -c|--clean)
      CLEAN_BUILD=true
      shift
      ;;
    -l|--launch)
      AUTO_LAUNCH=true
      shift
      ;;
    -t|--target)
      TARGET_DEVICE="$2"
      shift 2
      ;;
    -h|--help)
      print_banner
      print_help
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      print_help
      exit 1
      ;;
  esac
done

print_banner

# Step 1: Check dependencies
echo -e "${BLUE}▶ Checking prerequisites...${NC}"
if ! command -v flutter &> /dev/null; then
  echo -e "${RED}✖ Error: 'flutter' command not found in PATH.${NC}"
  exit 1
fi

if ! command -v adb &> /dev/null; then
  echo -e "${YELLOW}⚠ Warning: 'adb' not found in PATH. Will attempt installation via 'flutter install'.${NC}"
  USE_ADB=false
else
  USE_ADB=true
fi

# Step 2: Check connected devices if ADB is available
ADB_CMD="adb"
if [ "$USE_ADB" = true ]; then
  if [ -n "$TARGET_DEVICE" ]; then
    ADB_CMD="adb -s $TARGET_DEVICE"
  fi

  DEVICES=$($ADB_CMD devices | grep -v "List of devices" | grep "device$" | awk '{print $1}')
  DEVICE_COUNT=$(echo "$DEVICES" | grep -v '^$' | wc -l || true)

  if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}⚠ No connected ADB devices detected.${NC}"
    echo -e "  Please make sure your device is connected via USB with USB Debugging enabled, or start an emulator."
    echo -e "  The script will build the APK and prompt you to install when a device is ready."
  elif [ "$DEVICE_COUNT" -eq 1 ]; then
    DEVICE_ID=$(echo "$DEVICES" | tr -d '[:space:]')
    echo -e "${GREEN}✔ Found connected device: ${BOLD}${DEVICE_ID}${NC}"
    if [ -z "$TARGET_DEVICE" ]; then
      ADB_CMD="adb -s $DEVICE_ID"
    fi
  else
    echo -e "${CYAN}ℹ Multiple connected devices found:${NC}"
    echo "$DEVICES"
    if [ -z "$TARGET_DEVICE" ]; then
      FIRST_DEVICE=$(echo "$DEVICES" | head -n 1)
      echo -e "${YELLOW}Using first device: ${FIRST_DEVICE} (override with -t <id>)${NC}"
      ADB_CMD="adb -s $FIRST_DEVICE"
    fi
  fi
fi

# Step 3: Clean build if requested
if [ "$CLEAN_BUILD" = true ]; then
  echo ""
  echo -e "${BLUE}▶ Cleaning project and getting packages...${NC}"
  flutter clean
  flutter pub get
fi

# Step 4: Build APK
echo ""
echo -e "${BLUE}▶ Building APK (${BUILD_MODE} mode)...${NC}"
BUILD_ARGS=("build" "apk" "--$BUILD_MODE")
if [ "$SPLIT_PER_ABI" = true ]; then
  BUILD_ARGS+=("--split-per-abi")
fi

echo -e "${CYAN}$ flutter ${BUILD_ARGS[*]}${NC}"
flutter "${BUILD_ARGS[@]}"

# Step 5: Locate APK
APK_DIR="build/app/outputs/flutter-apk"
APK_PATH=""

if [ "$SPLIT_PER_ABI" = true ]; then
  # Try to find device architecture if adb is available
  if [ "$USE_ADB" = true ] && [ "$DEVICE_COUNT" -gt 0 ]; then
    DEVICE_ABI=$($ADB_CMD shell getprop ro.product.cpu.abi | tr -d '\r\n')
    echo -e "${CYAN}Device ABI: ${DEVICE_ABI}${NC}"
    if [ -f "$APK_DIR/app-${DEVICE_ABI}-${BUILD_MODE}.apk" ]; then
      APK_PATH="$APK_DIR/app-${DEVICE_ABI}-${BUILD_MODE}.apk"
    fi
  fi

  # Fallback to arm64-v8a or first available
  if [ -z "$APK_PATH" ] || [ ! -f "$APK_PATH" ]; then
    if [ -f "$APK_DIR/app-arm64-v8a-${BUILD_MODE}.apk" ]; then
      APK_PATH="$APK_DIR/app-arm64-v8a-${BUILD_MODE}.apk"
    else
      APK_PATH=$(find "$APK_DIR" -name "app-*-${BUILD_MODE}.apk" | head -n 1)
    fi
  fi
else
  APK_PATH="$APK_DIR/app-${BUILD_MODE}.apk"
fi

if [ ! -f "$APK_PATH" ]; then
  echo -e "${RED}✖ Error: APK not found at expected path: ${APK_PATH}${NC}"
  exit 1
fi

APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
echo -e "${GREEN}✔ APK built successfully!${NC}"
echo -e "  ${BOLD}Location:${NC} $APK_PATH"
echo -e "  ${BOLD}Size:${NC} $APK_SIZE"

# Step 6: Install on Device
echo ""
echo -e "${BLUE}▶ Installing APK to device...${NC}"

if [ "$USE_ADB" = true ]; then
  # Wait for device if none was connected earlier
  if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}Waiting for device to connect via ADB (Ctrl+C to cancel)...${NC}"
    adb wait-for-device
    DEVICES=$(adb devices | grep -v "List of devices" | grep "device$" | awk '{print $1}')
    DEVICE_ID=$(echo "$DEVICES" | head -n 1 | tr -d '[:space:]')
    ADB_CMD="adb -s $DEVICE_ID"
    echo -e "${GREEN}✔ Device connected: ${DEVICE_ID}${NC}"
  fi

  echo -e "${CYAN}$ $ADB_CMD install -r \"$APK_PATH\"${NC}"
  if $ADB_CMD install -r "$APK_PATH"; then
    echo -e "${GREEN}✔ Successfully installed on device!${NC}"
  else
    echo -e "${RED}✖ Failed to install via ADB.${NC}"
    exit 1
  fi
else
  echo -e "${CYAN}$ flutter install --$BUILD_MODE${NC}"
  flutter install --"$BUILD_MODE"
fi

# Step 7: Launch app if requested
if [ "$AUTO_LAUNCH" = true ]; then
  echo ""
  echo -e "${BLUE}▶ Launching app...${NC}"
  if [ "$USE_ADB" = true ]; then
    $ADB_CMD shell monkey -p "$PACKAGE_NAME" -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1 || {
      $ADB_CMD shell am start -n "$PACKAGE_NAME/.MainActivity" > /dev/null 2>&1 || true
    }
    echo -e "${GREEN}✔ App launched!${NC}"
  fi
fi

echo ""
echo -e "${GREEN}${BOLD}🎉 Build & Install Complete!${NC}"
