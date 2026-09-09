# Laboratorio — provisión de la VM Linux

Guía paso a paso para construir la máquina virtual del taller, validarla y
distribuirla a los participantes.

Esta es la **ruta principal** del laboratorio. Docker (`setup/docker-compose.yml`)
queda como alternativa para quien ya tenga ese flujo montado.

---

## 1. Especificación de la VM

| Recurso | Mínimo | Recomendado |
|---|---|---|
| vCPU | 2 | 2 |
| RAM | 2 GB | 4 GB |
| Disco | 15 GB | 20 GB |
| Red | NAT con salida a internet | igual |

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
sudo apt install -y git python3 python3-pip jq curl ca-certificates
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

## 7. El MCP de tshark

Elige uno y **fíjalo con semanas de antelación**. No cambies de MCP la semana
del evento.

```bash
# ejemplo con un MCP distribuido por npm
npm install -g <paquete-del-mcp-elegido>
```

Configura tu cliente de IA con `setup/mcp-config.example.json` como base,
ajustando rutas absolutas.

**La verificación que importa** — pídele al asistente, antes del taller:

> Corre `tshark -r malware_exec.pcap -c 1` y dime qué protocolo reporta.

Debe responder **TRISTATION**. Si responde `UDP`, el proceso del MCP está
corriendo como root o con otro usuario que no tiene el disector instalado. Si
no lo detectas aquí, lo vas a detectar en el salón cuando el asistente empiece
a inventar para llenar el hueco.

---

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
- [ ] Snapshot `baseline-verificada` tomada
- [ ] Probada en una máquina **que no sea la tuya**
- [ ] Huellas SHA-256 comunicadas a los participantes
- [ ] MCP fijado y validado con la pregunta del paso 7
- [ ] OVA exportada y copiada a dos USB
- [ ] Video de respaldo del flujo completo grabado
- [ ] Dos mesas de rescate con el entorno ya corriendo

El video de respaldo no es opcional. Si se cae el WiFi o el proveedor de IA
tiene un mal día, el taller se convierte en demo guiada y sigue funcionando.
Sin el video, se acaba.
