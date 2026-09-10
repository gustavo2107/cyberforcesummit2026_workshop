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
    tshark git python3 python3-pip pipx jq curl ca-certificates
else
  sudo dnf install -y -q wireshark-cli git python3 python3-pip pipx jq curl
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

  # Variante afinada para trabajo forense.
  # Los valores por omision de Ollama (num_ctx 2048, temperature 0.8) hacen
  # fallar este laboratorio por razones de configuracion, no del modelo.
  if command -v ollama >/dev/null 2>&1 && [[ -f "${REPO_ROOT}/setup/Modelfile" ]]; then
    if ollama create triton-analista -f "${REPO_ROOT}/setup/Modelfile" >/dev/null 2>&1; then
      ok "modelo afinado 'triton-analista' creado"
    else
      warn "no se pudo crear el modelo afinado; usa ${MODELO} directamente"
    fi
  fi

  # Cliente MCP para Ollama.
  #
  # Se instala con pipx y no con pip: desde Ubuntu 24.04 rige PEP 668, que
  # bloquea 'pip install --user' con "externally-managed-environment". pipx es
  # ademas la via correcta para una aplicacion de linea de comandos: le crea su
  # propio entorno aislado y la deja en el PATH.
  if command -v pipx >/dev/null 2>&1; then
    pipx ensurepath >/dev/null 2>&1 || true
    export PATH="${HOME}/.local/bin:${PATH}"
    if pipx install ollmcp >/dev/null 2>&1 || pipx upgrade ollmcp >/dev/null 2>&1; then
      ok "ollmcp instalado (cliente MCP para modelos locales)"
      warn "abre una terminal nueva, o corre 'exec \$SHELL', para que quede en el PATH"
    else
      warn "no se pudo instalar ollmcp; intenta: pipx install ollmcp"
    fi

    # Servidor MCP que expone tshark al modelo.
    #
    # Es wireshark-mcp (bx33661) y no mcp-wireshark (khuynh22): el segundo
    # instala limpio pero no arranca con el SDK actual de MCP -- revienta con
    # "AttributeError: 'Server' object has no attribute 'list_tools'".
    if pipx install wireshark-mcp >/dev/null 2>&1 || pipx upgrade wireshark-mcp >/dev/null 2>&1; then
      ok "wireshark-mcp instalado (servidor MCP de tshark)"
    else
      warn "no se pudo instalar wireshark-mcp; intenta: pipx install wireshark-mcp"
    fi
  else
    warn "pipx no disponible; instalalo con: sudo apt install pipx"
  fi
fi

# ---------------------------------------------------------------------------
# 5. Dependencia opcional del honeypot
# ---------------------------------------------------------------------------
info "Dependencia opcional (honeypot Triconex)"
# crcmod es una libreria, no una aplicacion: pipx no aplica. En Ubuntu 24.04
# viene empaquetada, que es la via limpia bajo PEP 668.
if sudo apt-get install -y -qq python3-crcmod 2>/dev/null; then
  ok "crcmod instalado desde el repositorio del sistema"
elif pip3 install --user --quiet --break-system-packages crcmod 2>/dev/null; then
  ok "crcmod instalado con pip"
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

  1. Arranca el cliente:
       ollmcp -m triton-analista -j setup/mcp-config.minimo.json

     El flag es --servers-json (-j). NO --mcp-server: ese espera la ruta a
     un script .py o .js y responde "Server script not found".

  2. Fija los parametros DENTRO del cliente -- este paso se salta solo:
       /mc     -> num_ctx 8192, temperature 0.1, seed 42
       /sc     -> guardar, queda en ~/.config/ollmcp/config.json

     Si en /mc aparecen como "-", el cliente no los esta enviando y el
     afinado del Modelfile se queda en el papel.  Ver docs/07 seccion 7.5.1.

  3. Validalo con la pregunta de control:
       "Corre: tshark -r malware_exec.pcap -c 1 y dime el protocolo"

     Debe responder TRISTATION *y verse la llamada a la herramienta*.
       - Responde UDP            -> el disector no cargo (ver setup/SETUP.md)
       - Responde sin llamar     -> el modelo esta inventando. Cambialo.

     La prueba dura de que el disector llego hasta el modelo es que
     frame.protocols termine en ":tristation".

  4. Cada consulta tarda del orden de minutos sobre CPU. Es normal.
     Midelo en TU maquina y dilo en voz alta al abrir la sesion.

Y cuando todo este en verde, TOMA UN SNAPSHOT de la VM.
  ->  docs/07-laboratorio-vm.md, paso 8
---------------------------------------------------------------------------
EOF
