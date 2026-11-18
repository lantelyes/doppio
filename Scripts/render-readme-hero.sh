#!/bin/bash
# Renders Design/readme-hero.html to docs/assets/hero.png at 2x with headless Chrome.
set -euo pipefail
cd "$(dirname "$0")/.."
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
"$CHROME" --headless=new --hide-scrollbars --force-device-scale-factor=2 \
  --default-background-color=00000000 --window-size=880,440 \
  --screenshot="$PWD/docs/assets/hero.png" "file://$PWD/Design/readme-hero.html" 2>/dev/null
sips -g pixelWidth -g pixelHeight docs/assets/hero.png | tail -2
