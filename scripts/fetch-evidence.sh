#!/usr/bin/env bash
# Descarga la evidencia y el disector desde la fuente original.
# No versionamos el PCAP en este repo: viene de terceros, con su propia
# licencia, y queremos que cada quien lo obtenga verificablemente del origen.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${REPO_ROOT}/evidence/tricotools"
UPSTREAM="https://github.com/NozomiNetworks/tricotools.git"

if [[ -d "${DEST}/.git" ]]; then
  echo "[i] Ya existe ${DEST} — actualizando"
  git -C "${DEST}" pull --ff-only
else
  echo "[i] Clonando ${UPSTREAM}"
  git clone --depth 1 "${UPSTREAM}" "${DEST}"
fi

PCAP="${DEST}/malware_exec.pcap"
LUA="${DEST}/TriStation.lua"

for f in "${PCAP}" "${LUA}"; do
  [[ -f "$f" ]] || { echo "[!] Falta $f"; exit 1; }
done

echo
echo "[ok] Evidencia en:  ${PCAP}"
echo "[ok] Disector en:   ${LUA}"
echo
echo "Huellas para verificar integridad (compáralas con las de tus participantes):"
sha256sum "${PCAP}" "${LUA}" 2>/dev/null || shasum -a 256 "${PCAP}" "${LUA}"
echo
echo "Siguiente paso: ./scripts/verify-setup.sh"
