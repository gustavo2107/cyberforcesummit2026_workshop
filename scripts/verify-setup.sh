#!/usr/bin/env bash
# Valida la cadena completa antes del taller.
# Si esto pasa, el taller es viable en esta maquina.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PCAP="${REPO_ROOT}/evidence/tricotools/malware_exec.pcap"
LUA="${REPO_ROOT}/evidence/tricotools/TriStation.lua"
FAIL=0

ok()   { echo "[ok] $*"; }
bad()  { echo "[!!] $*"; FAIL=1; }

# 1. tshark
if command -v tshark >/dev/null 2>&1; then
  ok "tshark encontrado ($(tshark --version 2>/dev/null | head -1 | cut -d' ' -f1-3))"
else
  bad "tshark no encontrado — ver setup/SETUP.md"
  exit 1
fi

# 2. root? (la trampa numero uno)
if [[ "$(id -u)" -eq 0 ]]; then
  bad "estas corriendo como root: tshark DESHABILITA Lua para superusuario."
  bad "     el disector no va a cargar. usa un usuario sin privilegios."
fi

# 3. evidencia
if [[ -f "${PCAP}" ]]; then
  N=$(tshark -r "${PCAP}" 2>/dev/null | wc -l | tr -d ' ')
  if [[ "${N}" == "896" ]]; then
    ok "evidencia presente (${N} paquetes)"
  else
    bad "evidencia presente pero con ${N} paquetes — se esperaban 896"
  fi
else
  bad "falta ${PCAP} — corre ./scripts/fetch-evidence.sh"
  exit 1
fi

# 4. disector cargado
PROTO=$(tshark -r "${PCAP}" -c 1 -T fields -e _ws.col.protocol 2>/dev/null | tr -d ' ')
if [[ "${PROTO}" == "TRISTATION" ]]; then
  ok "disector TriStation cargado"
  ok "protocolo detectado: ${PROTO}"
else
  bad "protocolo detectado: '${PROTO}' — se esperaba TRISTATION"
  bad "     el disector NO esta cargado. rutas de plugins:"
  tshark -G folders 2>/dev/null | grep -i "Personal Lua Plugins" | sed 's/^/       /'
  bad "     copia ${LUA} ahi, o usa -X lua_script:${LUA}"
fi

# 5. deteccion TRITON
HITS=$(tshark -r "${PCAP}" -Y '_ws.expert.message contains "TRITON"' 2>/dev/null | wc -l | tr -d ' ')
if [[ "${HITS}" == "2" ]]; then
  ok "deteccion TRITON en ${HITS} tramas"
else
  bad "deteccion TRITON en ${HITS} tramas — se esperaban 2"
fi

# 6. modelo local (informativo: el taller admite tambien un proveedor en la nube)
MODELO="${MODELO:-qwen3.5:4b}"
echo
if command -v ollama >/dev/null 2>&1; then
  ok "ollama encontrado"
  if curl -sf http://localhost:11434/api/tags >/dev/null 2>&1; then
    ok "servicio de ollama respondiendo en localhost:11434"
    if ollama list 2>/dev/null | grep -q "^triton-analista"; then
      ok "modelo afinado 'triton-analista' disponible"
    elif ollama list 2>/dev/null | grep -q "^${MODELO%%:*}"; then
      ok "modelo base ${MODELO} disponible"
      echo "[--] falta el afinado — ollama create triton-analista -f setup/Modelfile"
      echo "     Sin afinar, num_ctx=2048 y temperature=0.8 hacen fallar el analisis."
    else
      echo "[--] modelo ${MODELO} no descargado — ollama pull ${MODELO}"
    fi
  else
    echo "[--] ollama instalado pero el servicio no responde"
  fi
else
  echo "[--] ollama no encontrado (normal si vas a usar un proveedor en la nube)"
fi
echo "     La cadena modelo + MCP se valida a mano: ver docs/10-ejecucion.md, paso 3.3"

echo
if [[ "${FAIL}" -eq 0 ]]; then
  echo "LISTO — el taller es viable en esta maquina."
else
  echo "HAY FALLAS — revisa setup/SETUP.md antes del evento."
  exit 1
fi
