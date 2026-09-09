#!/usr/bin/env bash
#
# bootstrap-vm.sh — provisiona la VM Linux del taller de cero a verificada.
#
# Idempotente: se puede correr varias veces sin romper nada.
#
# USO:
#   ./scripts/bootstrap-vm.sh
#
# NO lo corras con sudo. El script pide sudo sólo para instalar paquetes.
# Wireshark deshabilita los scripts Lua cuando corre como superusuario, así
# que el disector debe instalarse en el HOME del usuario sin privilegios que
# va a hacer el análisis — y ese usuario eres tú al correr esto.
#
# Probado en Ubuntu 24.04 LTS y Debian 12.
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

info() { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '  \033[0;32m[ok]\033[0m %s\n' "$*"; }
warn() { printf '  \033[0;33m[!]\033[0m %s\n' "$*"; }
die()  { printf '\n\033[0;31m[ERROR]\033[0m %s\n\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# 0. Comprobaciones previas
# ---------------------------------------------------------------------------
info "Comprobaciones previas"

if [[ "$(id -u)" -eq 0 ]]; then
  die "Estas corriendo como root.

  tshark DESHABILITA los scripts Lua para superusuario. Si instalas el
  disector como root, el analisis no va a funcionar y el sintoma es
  silencioso: veras 'UDP' en lugar de 'TRISTATION'.

  Crea un usuario sin privilegios y vuelve a correr esto como el:
      sudo adduser analista
      su - analista"
fi
ok "usuario sin privilegios: $(whoami)"

command -v sudo >/dev/null 2>&1 || die "se requiere sudo para instalar paquetes"

# Detectar gestor de paquetes
if command -v apt-get >/dev/null 2>&1; then
  PKG=apt
elif command -v dnf >/dev/null 2>&1; then
  PKG=dnf
else
  die "gestor de paquetes no reconocido. Instala manualmente: tshark git python3 jq
  y despues corre ./scripts/fetch-evidence.sh && ./scripts/verify-setup.sh"
fi
ok "gestor de paquetes: ${PKG}"

# ---------------------------------------------------------------------------
# 1. Paquetes
# ---------------------------------------------------------------------------
info "Instalando paquetes base"

if [[ "${PKG}" == "apt" ]]; then
  # Responder la pregunta del setuid ANTES de instalar tshark.
  # Respondemos 'false': este taller solo LEE archivos pcap, nunca captura
  # de la interfaz, asi que no hace falta el bit setuid ni el grupo wireshark.
  echo "wireshark-common wireshark-common/install-setuid boolean false" \
    | sudo debconf-set-selections

  sudo apt-get update -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    tshark git python3 python3-pip jq curl ca-certificates
else
  sudo dnf install -y -q wireshark-cli git python3 python3-pip jq curl
fi

command -v tshark >/dev/null 2>&1 || die "tshark no quedo instalado"
ok "tshark $(tshark --version 2>/dev/null | head -1 | sed 's/.*(Wireshark) //;s/ .*//')"
ok "git $(git --version | awk '{print $3}')"

# ---------------------------------------------------------------------------
# 2. Evidencia
# ---------------------------------------------------------------------------
info "Descargando evidencia"
"${REPO_ROOT}/scripts/fetch-evidence.sh"

# ---------------------------------------------------------------------------
# 3. Disector
# ---------------------------------------------------------------------------
info "Instalando el disector TriStation"

# La ruta de plugins cambia entre versiones de Wireshark. No la asumimos:
# se la preguntamos al binario que acabamos de instalar.
PLUGIN_DIR="$(tshark -G folders 2>/dev/null \
  | awk -F'\t' '/Personal Lua Plugins/ {print $2}' \
  | tr -d ' ')"

if [[ -z "${PLUGIN_DIR}" ]]; then
  PLUGIN_DIR="${HOME}/.local/lib/wireshark/plugins"
  warn "no se pudo leer la ruta de plugins; usando ${PLUGIN_DIR}"
fi

mkdir -p "${PLUGIN_DIR}"
cp "${REPO_ROOT}/evidence/tricotools/TriStation.lua" "${PLUGIN_DIR}/"
ok "disector en ${PLUGIN_DIR}/TriStation.lua"

# ---------------------------------------------------------------------------
# 4. Modelo local (Ollama + pesos + cliente MCP)
#
# Se puede omitir con:  SIN_MODELO=1 ./scripts/bootstrap-vm.sh
# Utiles si vas a usar un proveedor en la nube en lugar del modelo local.
# ---------------------------------------------------------------------------
MODELO="${MODELO:-qwen3.5:4b}"

if [[ "${SIN_MODELO:-0}" == "1" ]]; then
  info "Modelo local: omitido (SIN_MODELO=1)"
else
  info "Instalando el modelo local"

  if command -v ollama >/dev/null 2>&1; then
    ok "ollama ya instalado ($(ollama --version 2>/dev/null | head -1))"
  else
    echo "  Descargando Ollama..."
    if curl -fsSL https://ollama.com/install.sh | sh; then
      ok "ollama instalado"
    else
      warn "no se pudo instalar ollama"
      warn "instalalo a mano desde https://ollama.com y vuelve a correr esto"
    fi
  fi

  if command -v ollama >/dev/null 2>&1; then
    # El servicio puede tardar en levantar tras la instalacion
    for i in 1 2 3 4 5; do
      curl -sf http://localhost:11434/api/tags >/dev/null 2>&1 && break
      sleep 2
    done

    if ollama list 2>/dev/null | grep -q "^${MODELO%%:*}"; then
      ok "modelo ${MODELO} ya descargado"
    else
      echo "  Descargando ${MODELO} — son ~3.4 GB, puede tardar."
      if ollama pull "${MODELO}"; then
        ok "modelo ${MODELO} descargado"
      else
        warn "no se pudo descargar ${MODELO}"
      fi
    fi
  fi

  # Cliente MCP para Ollama
  if pip3 install --user --quiet --upgrade ollmcp 2>/dev/null; then
    ok "ollmcp instalado (cliente MCP para modelos locales)"
  else
    warn "no se pudo instalar ollmcp; instalalo con: pip install --user ollmcp"
  fi
fi

# ---------------------------------------------------------------------------
# 5. Dependencia opcional del honeypot
# ---------------------------------------------------------------------------
info "Dependencia opcional (honeypot Triconex)"
if pip3 install --user --quiet crcmod 2>/dev/null; then
  ok "crcmod instalado — triconex_honeypot.py disponible"
else
  warn "no se pudo instalar crcmod; el honeypot no funcionara (opcional)"
fi

# ---------------------------------------------------------------------------
# 6. Verificacion
# ---------------------------------------------------------------------------
info "Verificando la cadena completa"
"${REPO_ROOT}/scripts/verify-setup.sh"

cat <<'EOF'

---------------------------------------------------------------------------
Siguiente paso: conectar el servidor MCP de tshark.

  1. Elige un servidor MCP  ->  docs/06-herramientas.md
  2. Configuralo            ->  setup/mcp-config.example.json
  3. Arranca el cliente:
       ollmcp --model qwen3.5:4b --mcp-server <tu-config>
  4. Validalo con la pregunta de control:
       "Corre: tshark -r malware_exec.pcap -c 1 y dime el protocolo"

     Debe responder TRISTATION *y verse la llamada a la herramienta*.
       - Responde UDP            -> el disector no cargo (ver setup/SETUP.md)
       - Responde sin llamar     -> el modelo esta inventando. Cambialo.

Y cuando todo este en verde, TOMA UN SNAPSHOT de la VM.
  ->  docs/07-laboratorio-vm.md, paso 8
---------------------------------------------------------------------------
EOF
