#!/usr/bin/env bash
#
# install-hooks.sh — activa los hooks de git versionados en .githooks/
#
# Los hooks viven en .githooks/ (versionado) en lugar de .git/hooks/ (que no
# se versiona), y se activan apuntando core.hooksPath a esa carpeta. Asi
# cualquiera que clone el repositorio los obtiene con un solo comando.
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

git config core.hooksPath .githooks
chmod +x .githooks/* 2>/dev/null || true

echo "[ok] hooks activados (core.hooksPath = .githooks)"
echo "     instalados: $(ls -1 .githooks | tr '\n' ' ')"
echo

if command -v gitleaks >/dev/null 2>&1; then
  echo "[ok] gitleaks $(gitleaks version 2>/dev/null || echo '') encontrado"
else
  echo "[!] gitleaks NO esta instalado."
  echo "    El hook va a correr solo las comprobaciones basicas."
  echo "    Para cobertura completa:"
  echo "        macOS:  brew install gitleaks"
  echo "        Linux:  https://github.com/gitleaks/gitleaks/releases"
fi

echo
echo "Para probarlo sin arriesgar nada:"
echo "    echo 'ghp_0123456789012345678901234567890123' > /tmp/prueba.txt"
echo "    cp /tmp/prueba.txt ./prueba-hook.txt && git add prueba-hook.txt"
echo "    git commit -m 'prueba'      # debe BLOQUEARSE"
echo "    git restore --staged prueba-hook.txt && rm prueba-hook.txt"
