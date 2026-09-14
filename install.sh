set -e

APP_NAME="MonitorBar"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "==> Nettoyage de $BUILD_DIR"
rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

echo "==> Compilation"
clang -fobjc-arc -O2 -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
    main.m AppDelegate.m OverlayView.m \
    cpu.c ram.c gpu.m \
    -framework Cocoa -framework Metal -framework Foundation

echo "==> Copie de Info.plist"
cp Info.plist "$APP_BUNDLE/Contents/Info.plist"

echo "==> Signature ad-hoc (limite les blocages Gatekeeper en local)"
codesign --force --deep --sign - "$APP_BUNDLE"

echo ""
echo "==> Terminé : $APP_BUNDLE"
echo "    Lance-le avec : open \"$APP_BUNDLE\""
