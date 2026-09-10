# Instalación

## Ruta recomendada: Docker

```bash
./scripts/fetch-evidence.sh
docker compose -f setup/docker-compose.yml up -d
./scripts/verify-setup.sh
```

Salida esperada de `verify-setup.sh`:

```
[ok] tshark encontrado
[ok] disector TriStation cargado
[ok] evidencia presente (896 paquetes)
[ok] protocolo detectado: TRISTATION
[ok] deteccion TRITON en 2 tramas
LISTO
```

Si ves las cinco líneas `[ok]`, el taller es viable en esa máquina.

---

## Instalación manual

```bash
# 1. tshark
sudo apt install tshark        # Debian/Ubuntu
brew install wireshark         # macOS

# 2. Evidencia y disector
git clone --depth 1 https://github.com/NozomiNetworks/tricotools.git

# 3. Disector en la ruta de plugins de TU version
tshark -G folders | grep -i "Personal Lua Plugins"
mkdir -p ~/.local/lib/wireshark/plugins
cp tricotools/TriStation.lua ~/.local/lib/wireshark/plugins/

# 4. Verificar
tshark -r tricotools/malware_exec.pcap -c 5
```

La columna de protocolo debe decir **TRISTATION**. Si dice `UDP`, sigue leyendo.

---

## Trampas conocidas

### 1. El disector no carga como root ← la más común

Wireshark **deshabilita los scripts Lua cuando corre como superusuario**. Es
una medida de seguridad deliberada, no una falla. No emite error: simplemente
no dissecta, y ves `UDP` con payload `data`.

```bash
# mal
sudo tshark -r malware_exec.pcap        # → UDP

# bien
tshark -r malware_exec.pcap             # → TRISTATION
```

Si estás en un contenedor, **crea un usuario sin privilegios**. El `Dockerfile`
de este repo ya lo hace. Es la razón número uno por la que este taller falla en
el salón, y cuesta media hora de reloj encontrarla en vivo.

### 2. Ruta de plugins equivocada

Cambia entre versiones de Wireshark. El README de tricotools sugiere
`~/.config/wireshark/plugins`, que funciona para el GUI en algunas versiones
pero **no siempre para tshark**. La fuente de verdad es tu propio binario:

```bash
tshark -G folders | grep -i "Personal Lua Plugins"
```

Alternativa que no depende de rutas:

```bash
tshark -r malware_exec.pcap -X lua_script:/ruta/a/TriStation.lua
```

(Y recuerda: tampoco funciona como root.)

### 3. Verificar que el protocolo quedó registrado

```bash
tshark -G protocols | grep -i tristation
```

Sin salida = el disector no cargó. Vuelve a la trampa 1.

### 4. `pip install` falla con `externally-managed-environment`

Desde Ubuntu 24.04 rige PEP 668: el Python del sistema lo gestiona apt, y
`pip install --user` se rechaza para no romperlo.

```bash
# mal, en Ubuntu 24.04
pip install --user ollmcp        # error: externally-managed-environment

# bien: pipx, que ademas es la via correcta para una aplicacion de CLI
sudo apt install -y pipx
pipx install ollmcp
pipx ensurepath && exec $SHELL   # para que quede en el PATH
```

Para **librerías** (no aplicaciones), como `crcmod`, `pipx` no aplica: se toman
del repositorio del sistema con `sudo apt install python3-crcmod`, o en último
caso con `pip install --break-system-packages`.

### 5. Versión de Wireshark

Probado en **4.2.2 con Lua 5.2.4**. El disector es de 2018; en versiones muy
nuevas podría requerir ajustes. Verifica en la máquina del taller, no en la
tuya.

---

## Conectar el MCP de tshark

Ver `mcp-config.example.json`. Opciones probadas por la comunidad:

- [`0xKoda/WireMCP`](https://github.com/0xKoda/WireMCP)
- [`bx33661/Wireshark-MCP`](https://github.com/bx33661/Wireshark-MCP)
- [`khuynh22/mcp-wireshark`](https://github.com/khuynh22/mcp-wireshark)
- [`tuliperis/SharkMCP`](https://github.com/tuliperis/SharkMCP)

Elige uno y fíjalo con antelación: no cambies de MCP la semana del evento.

**Lo importante:** el MCP invoca `tshark` del sistema, así que **hereda el
disector automáticamente** si está en la ruta de plugins del usuario que corre
el proceso. No hay que escribir código para que el asistente entienda
TriStation — pero sí hay que confirmar que el MCP no corre como root.
