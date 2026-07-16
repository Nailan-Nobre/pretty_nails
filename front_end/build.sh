#!/bin/bash
set -e

# Baixar Flutter SDK
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable $HOME/flutter
fi
export PATH="$HOME/flutter/bin:$PATH"

flutter pub get

# Se BACKEND_URL estiver vazio, usar o valor padrão
BACKEND_URL="${BACKEND_URL:-https://pretty-nails-do11.vercel.app}"

flutter build web --dart-define=BACKEND_URL=$BACKEND_URL --dart-define=ONESIGNAL_APP_ID=$ONESIGNAL_APP_ID
