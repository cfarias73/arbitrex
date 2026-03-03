#!/bin/sh

# Fail this script if any subcommand fails.
set -e

# The default execution directory of this script is the ci_scripts directory.
cd .. # go to ios
cd .. # go to project root

# Install Flutter using git.
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Precache artifacts and get packages
flutter precache --ios
flutter pub get

# Install CocoaPods
cd ios
pod install

exit 0
