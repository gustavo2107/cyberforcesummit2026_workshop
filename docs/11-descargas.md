# Descargas — inventario completo

Todo lo que hay que bajar de internet para que el laboratorio funcione, en un
solo lugar. Existe por una razón operativa concreta: **el WiFi de un venue no
aguanta a treinta personas descargando al mismo tiempo**, y descubrirlo el día
del taller no tiene arreglo.

---

## Dos rutas, elige antes de descargar nada

**Ruta A — La OVA.** Construyes la VM una vez, con todo dentro, y la exportas.
Los participantes no descargan nada: copian un archivo de una USB. Es la ruta
recomendada, y hace irrelevante casi toda esta lista para ellos. Tú sí necesitas
la lista completa, una vez.

**Ruta B — Entorno propio.** Cada participante monta su máquina siguiendo
[`07-laboratorio-vm.md`](07-laboratorio-vm.md). Necesitan todo lo marcado como
obligatorio, y necesitan hacerlo **antes del evento**, no en el salón.

En la práctica se ofrecen las dos: la OVA en USB para quien llegue sin nada, y
la guía para quien prefiera su propio entorno.

---

## Tabla maestra

| # | Qué | Tamaño | ¿Obligatorio? | Cuándo |
|---|---|---|---|---|
| 1 | ISO Ubuntu Server 24.04 LTS | ~2.5–3 GB | Sí (ruta B) | Semanas antes |
| 2 | Paquetes del sistema (apt) | ~40–60 MB | Sí | Al provisionar |
| 3 | Este repositorio | < 1 MB | Sí | Al provisionar |
| 4 | Evidencia y disector (tricotools) | **484 KB** | Sí | Al provisionar |
| 5 | El MCP elegido | 5–50 MB | Sí | Al provisionar |
| 6 | Cliente de IA | variable | Sí | Antes del evento |
| 7 | gitleaks | **7.8 MB** | No | Sólo quien commitea |
| 8 | `crcmod` (pip) | < 1 MB | No | Sólo para el honeypot |
| 9 | Docker | ~100 MB | No | Sólo ruta alternativa |
| 10 | Lecturas en PDF | ~15 MB | No (sí para ti) | Semanas antes |

Los tamaños en **negritas** están medidos. Los demás son aproximados y varían
según mirror, versión y plataforma.

---

## 1. ISO de Ubuntu Server 24.04 LTS

**De dónde:** <https://ubuntu.com/download/server>

Es la versión con la que se verificó todo el laboratorio: tshark 4.2.2 con Lua
5.2.4. Debian 12 funciona igual. En versiones muy nuevas el disector —que es de
2018— podría requerir ajustes, así que **si cambias de base, verifica antes**.

Ubuntu publica los checksums junto al ISO. Compáralos.

---

## 2. Paquetes del sistema

```bash
sudo apt install -y tshark git python3 python3-pip jq curl ca-certificates
```

`tshark` arrastra `wireshark-common` y las librerías de Wireshark, que es de
dónde sale la mayor parte del peso.

### Pre-descargarlos sin instalar

Útil para armar un paquete offline o para medir cuánto pesa realmente en tu
mirror:

```bash
sudo apt-get install -d -y tshark git python3 python3-pip jq curl ca-certificates
du -sh /var/cache/apt/archives/
```

`-d` descarga los `.deb` a `/var/cache/apt/archives/` sin instalarlos. Esa
carpeta se puede copiar a otra máquina e instalar con
`sudo dpkg -i /ruta/*.deb`.

### La pregunta del setuid

Durante la instalación de `tshark` aparece una pregunta sobre si usuarios no
administradores pueden capturar tráfico. **Responde No.** Este laboratorio sólo
lee archivos PCAP, nunca captura de la interfaz, así que no hace falta el bit
setuid ni el grupo `wireshark`. Menos privilegio, menos superficie.

Para automatizarlo, `scripts/bootstrap-vm.sh` ya responde por ti.

---

## 3. Este repositorio

```bash
git clone <url-del-repositorio> taller
```

Menos de 1 MB: son documentos markdown, scripts y dos CSV. **No incluye la
evidencia** — ver el punto 4.

---

## 4. Evidencia y disector — tricotools

**De dónde:** <https://github.com/NozomiNetworks/tricotools> · BSD-3-Clause

**Cómo:**

```bash
./scripts/fetch-evidence.sh
```

No se versiona dentro de este repositorio a propósito: es obra de un tercero con
su propia licencia, y que cada quien lo obtenga del origen mantiene la
procedencia limpia.

| Archivo | Tamaño | Para qué |
|---|---|---|
| `malware_exec.pcap` | 170 KB | La evidencia. Captura de la ejecución real del malware |
| `TriStation.lua` | 44 KB | El disector. Sin él la evidencia es tráfico opaco |
| `triconex_honeypot.py` | 12 KB | Opcional. Simula un controlador SIS |

Total con el historial de git: **484 KB**. Es la descarga más pequeña de toda la
lista y la única imprescindible.

### Verificación de integridad

`fetch-evidence.sh` imprime las huellas. Deben ser:

```
malware_exec.pcap  3fd16a177d9748d8aff0c7a8565cbe2808c6cc254259f6613647bb512af4ad90
TriStation.lua     05fe82c2fa90a6ca69dd7473ffb220a1bdf4bebece896906d79b2a28a7b08fed
```

**Compártelas con los participantes antes del evento.** Si a alguien no le
coinciden, está trabajando sobre otro archivo y sus resultados no van a cuadrar
con la rúbrica. De paso es una lección de cadena de custodia que sale gratis.

---

## 5. El MCP

Elige uno de [`06-herramientas.md`](06-herramientas.md) y **fíjalo con semanas
de anticipación.** No cambies de MCP la semana del evento.

Según el proyecto, se instala con `npm install -g` o con `pip install`. Los
distribuidos por npm arrastran `nodejs` y `npm`, que suman al peso.

> El criterio de elección no es el tamaño: es que invoque el `tshark` del
> sistema en lugar de traer su propio parser. Así hereda el disector sin que
> haya que escribir código.

---

## 6. Cliente de IA

El que vayas a usar en el taller. **Verifica dos cosas antes del evento:**

- Que la cuenta esté activa y con cupo suficiente para toda la sala
- Que el venue no bloquee el dominio del proveedor

Ambas cosas se descubren tarde y ninguna se arregla en el momento.

---

## 7. Opcionales

**gitleaks** — <https://github.com/gitleaks/gitleaks/releases> · 7.8 MB (Linux x64)

```bash
brew install gitleaks     # macOS
```

Sólo lo necesita quien vaya a commitear al repositorio. El hook de pre-commit
funciona sin él, con comprobaciones básicas.

**crcmod** — `pip install --user crcmod`. Sólo para `triconex_honeypot.py`.

**Docker** — únicamente si usas la ruta alternativa de `setup/docker-compose.yml`
en lugar de la VM.

---

## 8. Lecturas — para quien imparte

Los reportes de [`04-lecturas.md`](04-lecturas.md) son PDFs y páginas web. Bájalos
con semanas de anticipación: son para preparar, no para consultar en vivo.

Los tres que conviene tener guardados en local, porque son los que vas a citar:

- **Dragos — TRISIS** (whitepaper)
- **CISA — MAR-17-352-01 HatMan** (PDF)
- **Nozomi — Black Hat USA 2018, whitepaper de Carcano** (PDF)

Unos 15 MB entre los tres. Guárdalos junto a tus diapositivas: si te piden la
fuente en escenario, no quieres depender de la red del venue para mostrarla.

---

## 9. Lo que NO se descarga

**Binarios de malware.** Este laboratorio no los usa, no los distribuye y no los
necesita. La evidencia es tráfico de red, y el PCAP de Nozomi está *stripped*.

Existe [`MDudek-ICS/TRISIS-TRITON-HATMAN`](https://github.com/MDudek-ICS/TRISIS-TRITON-HATMAN)
con los binarios originales y decompilados. Es **material de preparación del
instructor**, si lo quieres para entender el payload a fondo. No se reparte, no
se ejecuta en el venue, y no forma parte de ninguna ruta del laboratorio.

La logística de treinta laptops con malware real en la red de un venue es un
problema que no quieres tener.

---

## 10. Preparar el paquete offline

Lo que conviene llevar en USB el día del evento:

- [ ] La **OVA exportada** con todo dentro, en **dos** memorias distintas
- [ ] El repositorio clonado, por si alguien prefiere partir de ahí
- [ ] `tricotools` ya descargado (484 KB, cabe en cualquier lado)
- [ ] Los `.deb` pre-descargados de `/var/cache/apt/archives/`, por si alguien
      monta su VM en el momento
- [ ] El **video de respaldo** del flujo completo
- [ ] Las huellas SHA-256 impresas o en un archivo de texto

Dos memorias, no una. Circulan en paralelo y una se puede corromper.

**Lo que no cabe en la USB es la conexión al proveedor de IA.** Ése es el único
punto que sigue dependiendo de la red del venue, y es exactamente para lo que
existen el video de respaldo y el plan B de
[`10-ejecucion.md`](10-ejecucion.md).
