#!/bin/bash
# Embeds src/unshorten.sh into the plist and zips the bundle.
set -e
cd "$(dirname "$0")/src"
plutil -replace objects.0.config.script -string "$(cat unshorten.sh)" info.plist
rm -f ../Unshorten.alfredworkflow
zip -j ../Unshorten.alfredworkflow info.plist icon.png clean.png full.png
