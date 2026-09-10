# Laboratorio — provisión de la VM Linux

Guía paso a paso para construir la máquina virtual del taller, validarla y
distribuirla a los participantes.

Esta es la **ruta principal** del laboratorio. Docker (`setup/docker-compose.yml`)
queda como alternativa para quien ya tenga ese flujo montado.

---

## 1. Especificación de la VM

| Recurso | Mínimo | Recomendado | Por qué |
|---|---|---|---|
| vCPU | 4 | 8 | La inferencia en CPU escala con núcleos |
| RAM | 8 GB | 16 GB | El modelo ocupa ~4 GB residentes |
| Disco | 30 GB | 40 GB | Pesos del modelo, Ollama, sistema y evidencia |
| Red | NAT con salida a internet | igual | Sólo durante la preparación |

> **Estas cifras subieron respecto a versiones anteriores de esta guía.** El
> laboratorio corre ahora un modelo de lenguaje local, y eso cambia el piso: con
> 2 GB de RAM no arranca. Si vas a distribuir la VM, confirma que las laptops de
> tus participantes tengan holgura para asignarle 8 GB.

**Sistema operativo:** Ubuntu Server 24.04 LTS. Es la referencia con la que se
validó este repositorio (tshark 4.2.2, Lua 5.2.4). Debian 12 funciona igual.

**Por qué NAT con internet:** sólo se necesita durante la preparación, para
descargar paquetes y la evidencia. Durante el taller la VM puede correr
aislada — de hecho es preferible, porque obliga a trabajar con la evidencia
local y no con búsquedas web.

> **Hipervisor.** Cualquiera sirve (VirtualBox, VMware, UTM, Proxmox). Elige el
> que puedas exportar en el formato que vayan a consumir tus participantes, y
> pruébalo en una máquina que no sea la tuya antes del evento.

---

## 2. Usuario del laboratorio

**Este paso no es cosmético: es un requisito funcional.**

```bash
sudo adduser analista
sudo usermod -aG sudo analista    # opcional, para que pueda instalar
su - analista
```

Todo el trabajo del taller se hace como `analista`, **nunca como root y nunca
con `sudo`**. Wireshark deshabilita los scripts Lua cuando corre como
superusuario, y sin Lua el disector de TriStation no carga. El síntoma es
silencioso: no hay error, simplemente ves `UDP` en lugar de `TRISTATION` y el
taller entero se queda sin sustancia.

Si sólo te vas a llevar una cosa de este documento, que sea ésta.

---

## 3. Paquetes base

```bash
sudo apt update
sudo apt install -y git python3 python3-pip pipx jq curl ca-certificates
```

### tshark

Durante la instalación aparece una pregunta sobre si usuarios no
administradores deben poder capturar tráfico. **Responde No.**

En este taller sólo se leen archivos PCAP, nunca se captura de la interfaz, así
que no hace falta el bit setuid ni el grupo `wireshark`. Menos privilegio, menos
superficie.

```bash
sudo apt install -y tshark
tshark --version | head -1
```

Para automatizarlo sin la pregunta interactiva:

```bash
echo "wireshark-common wireshark-common/install-setuid boolean false" \
  | sudo debconf-set-selections
sudo DEBIAN_FRONTEND=noninteractive apt install -y tshark
```

### Node.js — sólo si vas a usar un MCP en npm

```bash
sudo apt install -y nodejs npm
node --version
```

---

## 4. El repositorio y la evidencia

```bash
cd ~
git clone <url-de-tu-repo-privado> taller
cd taller
./scripts/fetch-evidence.sh
```

`fetch-evidence.sh` descarga `tricotools` desde el repositorio de Nozomi
Networks e imprime las huellas SHA-256. **Guárdalas y compártelas con los
participantes** para que todos verifiquen que trabajan sobre el mismo archivo.

Huellas de referencia (verificadas al construir este repositorio):

```
malware_exec.pcap  3fd16a177d9748d8aff0c7a8565cbe2808c6cc254259f6613647bb512af4ad90
TriStation.lua     05fe82c2fa90a6ca69dd7473ffb220a1bdf4bebece896906d79b2a28a7b08fed
```

Si no coinciden, alguien está trabajando sobre otro archivo. Averigua por qué
antes de seguir.

---

## 5. Instalar el disector

La ruta de plugins **cambia entre versiones de Wireshark**. No la asumas: 
pregúntasela a tu binario.

```bash
tshark -G folders | grep -i "Personal Lua Plugins"
# → Personal Lua Plugins: /home/analista/.local/lib/wireshark/plugins

mkdir -p ~/.local/lib/wireshark/plugins
cp ~/taller/evidence/tricotools/TriStation.lua ~/.local/lib/wireshark/plugins/
```

Comprobación rápida de que quedó registrado:

```bash
tshark -G protocols | grep -i tristation
```

Sin salida significa que no cargó. Regresa al paso 2 y confirma que no eres
root.

---

## 6. Verificación

```bash
cd ~/taller
./scripts/verify-setup.sh
```

Salida esperada:

```
[ok] tshark encontrado (TShark (Wireshark) 4.2.2)
[ok] evidencia presente (896 paquetes)
[ok] disector TriStation cargado
[ok] protocolo detectado: TRISTATION
[ok] deteccion TRITON en 2 tramas

LISTO — el taller es viable en esta maquina.
```

**No avances hasta ver las cinco líneas `[ok]`.** Todo lo que sigue depende de
que el disector esté cargado.

---

## 7. El modelo local

El laboratorio corre **todo el análisis en la propia VM**. No hay llamadas a
ningún proveedor externo, no hacen falta cuentas ni tokens, y la evidencia nunca
sale de la máquina — que para un taller de forense OT no es un detalle menor.

> ⚠️ **Esta sección no está verificada de punta a punta**, a diferencia del
> resto de la guía. La cadena `tshark` + disector sí se corrió y se comprobó; la
> combinación Ollama + modelo + cliente MCP está documentada desde las fuentes
> del punto 7.4, pero **tienes que validarla tú en tu VM antes del taller.**

### 7.1 Ollama

```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama --version
```

Ollama es el runtime: descarga los pesos, los sirve por una API local y gestiona
la memoria. Corre como servicio y escucha en `localhost:11434`.

### 7.2 El modelo

```bash
ollama pull qwen3.5:4b
```

**Por qué éste y no uno más grande.** En la evaluación de tool calling de 2026
citada en `06-herramientas.md`, Qwen3.5 4B obtuvo **97.5% de acierto** sobre 40
casos deterministas — el primer lugar, por encima de modelos cinco veces
mayores. Pesa 3.4 GB.

Eso importa porque el laboratorio no le pide al modelo que escriba bonito: le
pide que **invoque `tshark`, lea el resultado y no invente entre una llamada y
otra**. Ahí es donde los modelos locales se separan, y donde muchos grandes
fallan más que este pequeño.

En CPU pura, un modelo de 4B responde en segundos, no al instante. Adviértelo a
la sala: la espera es normal y no es que se haya trabado.

### 7.3 Afinar el modelo

Los valores por omisión de Ollama (2048 tokens de contexto, temperatura 0.8)
hacen fallar este laboratorio por razones que no son del modelo. `setup/Modelfile`
los corrige:

```bash
ollama create triton-analista -f setup/Modelfile
ollama list      # debe aparecer triton-analista
```

El detalle de qué cambia y por qué está en `06-herramientas.md`. Lo importante:
**no toca el disector, la evidencia ni la detección de TRITON.** Sólo configura
al analista.

### 7.4 El cliente MCP

```bash
sudo apt install -y pipx     # si seguiste el paso 3, ya lo tienes
pipx install ollmcp
pipx ensurepath
exec $SHELL                  # recarga el PATH — sin esto, "command not found"
ollmcp --help                # confirma
```

Si después del `exec $SHELL` sigue sin encontrarse, confirma que sí quedó
instalado llamándolo por su ruta:

```bash
~/.local/bin/ollmcp --help
```

`ollmcp` es el puente: conecta el modelo de Ollama con los servidores MCP por
stdio, maneja el ciclo de llamada a herramientas y tiene modo agente y
confirmación humana. Requiere Python 3.11 o superior.

> **Se instala con `pipx`, no con `pip`.** Desde Ubuntu 24.04 rige PEP 668:
> `pip install --user` falla con `externally-managed-environment` porque el
> Python del sistema está gestionado por apt. `pipx` es además la vía correcta
> para una aplicación de línea de comandos — le crea su propio entorno aislado
> y la deja en el PATH, sin tocar el Python del sistema.

### 7.5 El servidor MCP de tshark

Es la pieza que le da a `ollmcp` acceso a `tshark`. El criterio de elección es
uno solo: **que invoque el `tshark` del sistema en lugar de traer su propio
parser**. Así hereda el disector sin escribir una línea de código, y es la razón
por la que este taller cabe en dos horas.

**Usa `wireshark-mcp`.** Es el único de los candidatos que se probó corriendo de
punta a punta en esta cadena, y funciona.

```bash
pipx install wireshark-mcp
which wireshark-mcp          # → /home/analista/.local/bin/wireshark-mcp
pipx list                    # anota la versión: va en tu bitácora del taller
```

> Se instala con **`pipx`, no con `pip`** — misma razón que `ollmcp`: PEP 668 en
> Ubuntu 24.04. Y es una aplicación de línea de comandos, que es justo para lo
> que `pipx` existe.

#### Lo que se probó y no sirve

`mcp-wireshark` **no arranca**. Instala limpio con `pipx` —v0.5.0 sobre Python
3.12.3— y ahí se acaba la buena noticia: al primer intento de listar
herramientas revienta.

```
AttributeError: 'Server' object has no attribute 'list_tools'
```

Es una incompatibilidad con el SDK actual de MCP, no un error de configuración:
no hay flag que lo arregle. Queda documentado porque *instalar* no es
*funcionar*, y una versión previa de esta guía lo recomendaba como "el más
simple" habiendo verificado sólo que se instalaba. La lección aplica a todo el
laboratorio: la única prueba que cuenta es la que llega hasta la salida.

| Proyecto | Estado |
|---|---|
| **`wireshark-mcp`** ([bx33661](https://github.com/bx33661/Wireshark-MCP)) | **Verificado corriendo.** `pipx install wireshark-mcp` |
| `mcp-wireshark` ([khuynh22](https://github.com/khuynh22/mcp-wireshark)) | **Instala pero no arranca** — `AttributeError` sobre `list_tools` |
| `WireMCP` ([0xKoda](https://github.com/0xKoda/WireMCP)) | Sin verificar. Node 16+, `git clone` + `npm install` |

**Fíjalo con semanas de antelación.** No cambies de servidor MCP la semana del
evento.

#### Conectarlo con el modelo

La configuración va en formato MCP estándar y ya está escrita en
`setup/mcp-config.minimo.json`:

```json
{
  "mcpServers": {
    "tshark": {
      "command": "wireshark-mcp"
    }
  }
}
```

Arrancas el cliente apuntando a ese archivo:

```bash
cd ~/taller
ollmcp --model triton-analista --servers-json setup/mcp-config.minimo.json
```

En corto: `ollmcp -m triton-analista -j setup/mcp-config.minimo.json`

> **El flag es `--servers-json`, no `--mcp-server`.** Es el error fácil de
> cometer: `--mcp-server` existe, pero espera **la ruta a un script `.py` o
> `.js`**, no el nombre de un binario. Si le pasas el nombre de un binario
> responde `Server script not found`. Para un servidor instalado en el PATH, la
> vía es el archivo JSON.
>
> Usa `mcp-config.minimo.json` y no `mcp-config.example.json`: el de ejemplo
> lleva comentarios dentro del JSON para explicar las opciones, y un parser
> estricto los rechaza.

**Verificado** con `ollmcp` sobre Ubuntu 24.04, septiembre 2026.

### 7.5.1 Fijar los parámetros dentro del cliente

**Este paso no es opcional, y es el que más fácil se salta.**

`ollmcp` mantiene su propia configuración de modelo. Aunque hayas construido
`triton-analista` con el `Modelfile`, al abrir el panel de parámetros puedes
encontrarte esto:

```
/mc
```

```
num_ctx        -
temperature    -
seed           -
```

Un guión no quiere decir 8192, ni 0.1: quiere decir que **el cliente no está
enviando ese parámetro**, y lo que acabe usando el runtime queda fuera de tu
control. Con `num_ctx` sin fijar vuelves al problema de raíz — el modelo pierde
la evidencia a media sesión y, como no sabe decir "se me olvidó", rellena.

Fíjalos a mano en el panel `/mc`:

| Parámetro | Valor |
|---|---|
| `num_ctx` | `8192` |
| `temperature` | `0.1` |
| `seed` | `42` |

Y **guárdalos**, para que sobrevivan al siguiente arranque:

```
/sc
```

La configuración queda en `~/.config/ollmcp/config.json`. En la VM del taller,
`/home/analista/.config/ollmcp/config.json`.

> **Para la OVA:** ese archivo tiene que estar dentro de la imagen antes de
> exportarla. Si no, cada participante arranca con los parámetros en `-` y el
> laboratorio se comporta distinto en cada máquina — que es justo lo que la
> snapshot existe para evitar. Confírmalo con `cat` antes de tomar el snapshot
> del paso 8.

### 7.6 La validación

Con todo arriba, arranca el cliente apuntando al servidor MCP y hazle la
pregunta de control:

```
Corre: tshark -r malware_exec.pcap -c 1
y dime qué protocolo reporta.
```

**Debe responder `TRISTATION`, y debes ver la llamada a la herramienta en
pantalla.**

Dos formas de fallar, y conviene distinguirlas:

- **Responde `UDP`** — el disector no cargó. El proceso corre como root o con un
  usuario sin el plugin. Ver la trampa 1 de `setup/SETUP.md`.
- **Responde algo plausible sin llamar la herramienta** — el modelo está
  inventando. Es el fallo que el taller entero enseña a detectar, y si lo hace
  en la validación lo va a hacer toda la sesión. Cambia de modelo antes de
  seguir.

Cuando responde bien, la prueba de que el disector viajó hasta el modelo es el
campo `frame.protocols`, que en esta captura termina en `tristation`:

```
"frame.protocols": "eth:ethertype:ip:udp:tristation"
```

Ésa es la línea que confirma que la cadena completa —`ollmcp` → `wireshark-mcp`
→ `tshark` del sistema → `TriStation.lua`— está entera. Si termina en `udp`, el
disector se quedó en el camino.

#### Lo que vas a ver en pantalla, y conviene saber de antemano

Tres cosas de la herramienta —no del caso— que salen en cuanto empiezas a
consultar. Ninguna es un problema; todas confunden si te agarran en frío:

- **Las herramientas se listan con `/tools`, y su numeración cambia entre
  versiones del servidor.** No memorices números ni los pongas en el material
  del participante: lo que se dicta en voz alta es el nombre.
- **Pedir la lista de paquetes con `limit: 1` devuelve cabeceras, no
  contenido.** Para ver los campos que decodifica el disector, la vía sigue
  siendo `tshark -r <archivo> -c 1 -V`.
- **El resumen de *expert info* da frecuencias, no números de trama.** Sirve
  para saber *qué* aparece y *cuántas veces*; para saber *dónde*, hace falta
  otra consulta.

#### Cuánto tarda

En la VM de referencia, cada consulta —la ida y vuelta completa: el modelo
decide, llama la herramienta, lee el resultado y responde— tardó alrededor de
**tres minutos** sobre CPU.

Ese número depende por entero del equipo: núcleos, RAM y si hay GPU. Mídelo en
tu ensayo, en la máquina que vas a usar, y **dilo en voz alta al abrir la
sesión**. Un participante que espera respuesta instantánea cree que algo se
rompió a los veinte segundos, y reinicia el cliente a media consulta.

### 7.7 Si el modelo local no da el ancho

No lo fuerces. La ruta con un proveedor en la nube sigue siendo válida y está
documentada en `06-herramientas.md`. Perderías la independencia de la red del
venue, pero ganarías capacidad — y el taller funciona con ambas.

Decídelo en tu ensayo, no en el salón.

## 8. Snapshot — no te la saltes

Con la verificación en verde:

```bash
history -c
sudo apt clean
sudo rm -rf /tmp/*
```

Y toma un snapshot del hipervisor llamado **`baseline-verificada`**.

Esa snapshot es tu red de seguridad: si un participante destruye su entorno a
media sesión, revierte en treinta segundos en lugar de perderlo. Toma la
snapshot **después** de verificar, nunca antes.

---

## 9. Distribución a participantes

| Método | Cuándo conviene | Nota |
|---|---|---|
| Exportar OVA | Grupo pequeño, laptops variadas | 3–5 GB; entrégalo en USB, no por WiFi del venue |
| Vagrant box | Audiencia técnica cómoda con CLI | Más ligero de distribuir |
| Guía + repo | Audiencia que prefiere su propio entorno | Requiere que sigan esta guía **antes** del evento |

**Recomendación:** ofrece las tres. Publica la guía y el repo con 48 horas de
anticipación, y lleva la OVA en dos memorias USB. Siempre hay alguien que llega
sin nada preparado, y dos USB circulando cuestan menos que veinte minutos de
descarga simultánea sobre el WiFi del venue.

---

## 10. Lista de verificación previa

- [ ] VM construida y verificación en verde
- [ ] **Modelo local descargado y respondiendo** (`ollama list`)
- [ ] **`wireshark-mcp` instalado y arrancando** (`which wireshark-mcp`)
- [ ] **Parámetros fijados en `/mc` y guardados con `/sc`** — que ninguno muestre `-`
- [ ] **`~/.config/ollmcp/config.json` existe y está dentro de la imagen**
- [ ] **La pregunta de control devuelve TRISTATION, con llamada visible a la herramienta**
- [ ] **`frame.protocols` termina en `tristation`**
- [ ] Tiempo por consulta medido en esta máquina, para decirlo en la sesión
- [ ] Snapshot `baseline-verificada` tomada
- [ ] Probada en una máquina **que no sea la tuya**, con 8 GB asignados
- [ ] Huellas SHA-256 comunicadas a los participantes
- [ ] OVA exportada y copiada a dos USB
- [ ] Video de respaldo del flujo completo grabado
- [ ] Dos mesas de rescate con el entorno ya corriendo

Con el modelo corriendo en local, el laboratorio ya no depende de la red del
venue. Eso elimina la falla más común, pero **no elimina la necesidad del video
de respaldo**: un modelo pequeño puede portarse mal en vivo, y el video te deja
seguir dando el taller como demo guiada.
