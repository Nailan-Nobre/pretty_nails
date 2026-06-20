#!/bin/bash
set -e

# Baixar Flutter SDK
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable $HOME/flutter
fi
export PATH="$HOME/flutter/bin:$PATH"

flutter pub get

flutter build web --dart-define=BACKEND_URL=$BACKEND_URL
