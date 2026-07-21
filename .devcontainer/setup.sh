#!/usr/bin/env bash
# Instala Flutter (canal stable) en el Codespace y prepara el proyecto.
# Se ejecuta automaticamente al crear el Codespace (ver devcontainer.json,
# postCreateCommand). No hace falta ejecutarlo a mano salvo que algo falle
# y quieras reintentarlo: bash .devcontainer/setup.sh

set -e

FLUTTER_DIR="$HOME/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  echo "Clonando Flutter (stable)..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_DIR"
else
  echo "Flutter ya estaba clonado en $FLUTTER_DIR, se omite el clon."
fi

# Añade Flutter al PATH de forma persistente (para toda nueva terminal
# que se abra en este Codespace), no solo para esta ejecucion del script.
if ! grep -q "flutter/bin" "$HOME/.bashrc" 2>/dev/null; then
  echo 'export PATH="$PATH:$HOME/flutter/bin"' >> "$HOME/.bashrc"
fi
export PATH="$PATH:$FLUTTER_DIR/bin"

echo ""
echo "Version de Flutter instalada:"
flutter --version

echo ""
echo "Descargando dependencias del proyecto (flutter pub get)..."
cd /workspaces/deck-tracker-app
flutter pub get

echo ""
echo "Precargando artefactos para el target web..."
flutter precache --web

echo ""
echo "Listo. Abre una terminal nueva (o ejecuta: source ~/.bashrc) y lanza:"
echo "  flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080"