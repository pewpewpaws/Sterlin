#!/usr/bin/env bash

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

echo -e "${BLUE}${BOLD}▶ 1/3 Building Release APK...${NC}"
flutter build apk --release

echo -e "\n${BLUE}${BOLD}▶ 2/3 Installing to phone via ADB...${NC}"
adb install -r "$APK_PATH"

echo -e "\n${BLUE}${BOLD}▶ 3/3 Copying Sterlin.apk to phone's Downloads folder...${NC}"
adb push "$APK_PATH" /sdcard/Download/Sterlin.apk
echo -e "${GREEN}✔ Copied to phone's ${BOLD}/sdcard/Download/Sterlin.apk${NC}"

echo -e "\n${GREEN}${BOLD}🎉 Build, install, and copy to phone complete!${NC}"
