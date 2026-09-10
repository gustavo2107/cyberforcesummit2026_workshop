# Ejecución del laboratorio

Qué hacer cuando la máquina ya está lista. Este documento se lee justo después
de que `verify-setup.sh` da verde, y cubre el hueco entre "el entorno funciona"
y "estoy impartiendo el taller".

Si todavía no llegas a ese punto, ve primero a
[`07-laboratorio-vm.md`](07-laboratorio-vm.md).

---

## 1. Punto de partida

Antes de seguir, esto tiene que ser cierto:

```bash
cd ~/taller
./scripts/verify-setup.sh
```

```
[ok] tshark encontrado (TShark (Wireshark) 4.2.2)
[ok] evidencia presente (896 paquetes)
[ok] disector TriStation cargado
[ok] protocolo detectado: TRISTATION
[ok] deteccion TRITON en 2 tramas

LISTO — el taller es viable en esta maquina.
```

**Las cinco líneas, con un usuario sin privilegios.** Si falta alguna, nada de
lo que sigue va a funcionar y el problema se va a manifestar hasta media sesión,
cuando ya tengas gente esperando.

---

## 2. El terreno

Conviene tener claro dónde vive cada cosa antes de empezar, porque durante la
sesión vas a estar señalando rutas en voz alta.

| Qué | Dónde |
|---|---|
| Raíz de trabajo | `~/taller` — todos los comandos salen de aquí |
| La evidencia | `evidence/tricotools/malware_exec.pcap` |
| El disector | `~/.local/lib/wireshark/plugins/TriStation.lua` |
| El modelo | Ollama, en `localhost:11434` — `ollama list` para verlo |
| Lo que se reparte | `docs/00-brief-escenario.md`, `docs/02-workbook.md`, `prompts/` |
| Lo que **no** se reparte todavía | `docs/03-rubrica.md` |

Un atajo que ahorra teclear durante la sesión:

```bash
export PCAP=~/taller/evidence/tricotools/malware_exec.pcap
```

---

## 3. Levantar el modelo y el cliente

Todo el análisis corre en la propia VM. No hay llamadas a ningún proveedor
externo y la evidencia nunca sale de la máquina.

### 3.1 Confirmar que el modelo está arriba

```bash
ollama list          # debe aparecer triton-analista
ollama ps            # muestra si ya está cargado en memoria
```

Si no está cargado, la primera respuesta de la sesión va a tardar más mientras
se carga. Conviene "calentarlo" antes de que llegue la gente:

```bash
ollama run triton-analista "responde solo: listo" --verbose
```

### 3.2 Arrancar el cliente MCP

```bash
cd ~/taller
ollmcp --model triton-analista --servers-json setup/mcp-config.minimo.json
```

El flag es **`--servers-json`** (o `-j`). No `--mcp-server`: ése espera la ruta
a un script `.py` o `.js`, no el nombre de un binario, y responde
`Server script not found` si le pasas uno.

### 3.3 La pregunta de control

**Antes de que llegue nadie**, y el mismo día — no la semana anterior:

```
Corre: tshark -r malware_exec.pcap -c 1
y dime qué protocolo reporta.
```

**Debe responder `TRISTATION`, y debes ver la llamada a la herramienta en
pantalla.**

Hay dos formas de fallar y conviene distinguirlas, porque se arreglan distinto:

| Qué ves | Qué pasa | Qué hacer |
|---|---|---|
| Responde `UDP` | El disector no cargó: el proceso corre como root o sin el plugin | Trampa 1 de `setup/SETUP.md` |
| Responde algo plausible **sin llamar la herramienta** | El modelo está inventando | Cambiar de modelo. No sigas. |

El segundo caso es el grave: es exactamente el fallo que el taller enseña a
detectar, y si el modelo lo hace en la validación lo va a hacer toda la sesión.

---

## 4. La secuencia de una sesión

Los tiempos están en [`01-guia-instructor.md`](01-guia-instructor.md). Esto es la
mecánica: quién hace qué, y en qué orden.

### Paso 1 — Repartir, sin explicar de más

Entrega `docs/00-brief-escenario.md` y `docs/02-workbook.md`.

**No menciones TRITON, ni Triconex, ni petroquímica.** Todo el valor del
ejercicio depende de que trabajen a ciegas: si saben de qué caso se trata, sus
asistentes van a recitar en lugar de analizar, y no habrá forma de distinguir
una cosa de la otra.

### Paso 2 — Las reglas de anclaje, antes de cualquier pregunta

Cada participante pega el contenido de
[`../prompts/00-reglas-de-anclaje.md`](../prompts/00-reglas-de-anclaje.md) al
inicio de su conversación con el asistente.

Esto va primero y sin excepción. Es lo que obliga al modelo a separar
`[EVIDENCIA]` de `[INFERENCIA]` de `[CONOCIMIENTO]`, y sin ello el resto del
taller no se puede medir. Un participante que empieza a preguntar sin haber
pegado las reglas va a producir un reporte que se lee bien y no prueba nada.

### Paso 3 — Los bloques

Trabajan el workbook en orden. `prompts/01-baseline.md` trae prompts de arranque
para cada bloque, y también la lista de los que **no** hay que usar.

| Bloque | Qué se busca | Cuánto |
|---|---|---|
| 1 y 2 | Reconocer el terreno y la forma del tráfico | 15 min |
| 3 | Construir la línea de tiempo | 30 min |
| 4 | El estado del controlador — **aquí está el hallazgo** | 20 min |
| 5 | Redactar el reporte y la lista de no-anclados | dentro de los anteriores |

Mientras trabajan, circula y siembra la pregunta incómoda: *¿tu asistente te dijo
qué protocolo es antes de que tú se lo dijeras? ¿Cómo lo supo?*

### Paso 4 — La revelación

Aquí se abre `docs/03-rubrica.md` y se contrasta.

El orden que funciona: primero el caso y el sector, después la línea de tiempo
real contra la de ellos, y **al final el `keyState`**. Guarda la llave para el
cierre; es el momento en que la sala hace silencio.

### Paso 5 — El Bloque 6

El ejercicio de inyección. Se conduce como está descrito en
[`05-inyeccion.md`](05-inyeccion.md) y va al final, nunca antes: si lo adelantas,
los participantes se ponen paranoicos y el ejercicio forense se contamina.

### Paso 6 — La entrega

Cada equipo entrega cuatro cosas: la línea de tiempo con números de trama, un
párrafo de qué ocurrió, una frase de qué control lo habría impedido, y **la lista
de afirmaciones que su IA hizo y no pudieron anclar**.

Esa última lista es la que se discute en el cierre. Un equipo que entrega cinco
afirmaciones no ancladas aprendió más que uno que entrega cero y las escondió —
dilo al principio de la sesión, o nadie la va a entregar con honestidad.

---

## 5. Plan B — el laboratorio sin IA

**Todo el workbook se puede completar con `tshark` a secas.** Con el modelo en
local ya no dependes de la red del venue, pero siguen existiendo formas de
quedarte sin asistente: que el modelo se atore, que consuma toda la RAM de una
laptop apretada, o que empiece a inventar de forma evidente a media sesión.

Si eso pasa, el taller no se acaba: cambia de forma.

Lo pierdes es la mitad de la lección sobre alucinación. Conservas toda la parte
forense, que es la mitad que se aplica el lunes.

```bash
export PCAP=~/taller/evidence/tricotools/malware_exec.pcap
```

### Bloque 1 — Reconocimiento

```bash
capinfos $PCAP | grep -E "Number of packets|Capture duration"
tshark -r $PCAP -q -z conv,ip
tshark -r $PCAP -q -z io,phs
```

### Bloque 2 — Forma del tráfico

```bash
# distribución de comandos
tshark -r $PCAP -T fields -e ts.ts_cmd | sort -n | uniq -c | sort -rn

# el ruido de fondo, filtrado
tshark -r $PCAP -Y 'ts.ts_cmd && ts.ts_cmd!=19 && ts.ts_cmd!=108' | wc -l
```

### Bloque 3 — La secuencia

```bash
# línea de tiempo sin el polling
tshark -r $PCAP -Y 'ts.ts_cmd && ts.ts_cmd!=19 && ts.ts_cmd!=108' \
  -T fields -e frame.number -e frame.time_relative -e ip.src -e ts.ts_cmd

# el patrón de escritura
tshark -r $PCAP -Y 'ts.ts_cmd==1 || ts.ts_cmd==102 || ts.ts_cmd==55 || ts.ts_cmd==11 || ts.ts_cmd==103' \
  -T fields -e frame.number -e ts.ts_cmd

# el final — léelo con cuidado
tshark -r $PCAP -Y 'frame.number>=889 && frame.number<=892' \
  -T fields -e frame.number -e ip.src -e ts.ts_cmd
```

### Bloque 4 — Estado del controlador

```bash
tshark -r $PCAP -Y 'ts.ts_cp_keyState' \
  -T fields -e ts.ts_cp_keyState -e ts.ts_cp_runState | sort | uniq -c
```

### Atajos del Makefile

Para proyectar en pantalla sin teclear filtros largos:

```bash
make stats     # metadatos, conversaciones y distribución de comandos
make triton    # las tramas donde el disector detecta TRITON
```

### Si además se cae todo

El video de respaldo. Por eso se graba: el taller se convierte en demo guiada y
sigue funcionando. Sin él, se acaba.

---

## 6. Después de la sesión

- Reparte [`03-rubrica.md`](03-rubrica.md) y [`04-lecturas.md`](04-lecturas.md)
  a quien quiera seguirle.
- El experimento de contaminación de
  [`../prompts/02-experimento-contaminacion.md`](../prompts/02-experimento-contaminacion.md)
  funciona bien como ejercicio para después: compara una sesión a ciegas contra
  una en la que se le dice al modelo de qué caso se trata.
- El mapeo de [`09-mapeo-attack.md`](09-mapeo-attack.md) es el puente al lunes:
  convierte lo que reconstruyeron en detecciones concretas para una red OT.
- Si el repositorio va a hacerse público, sigue
  [`08-publicacion.md`](08-publicacion.md).

---

## Resumen en una pantalla

```
verify-setup.sh en verde, usuario sin privilegios
        ↓
MCP validado — debe responder TRISTATION
        ↓
repartir brief + workbook   (sin decir TRITON)
        ↓
pegar reglas de anclaje     (antes de cualquier pregunta)
        ↓
bloques 1-2 → 3 → 4         (el hallazgo está en el 4)
        ↓
revelación: abrir la rúbrica, keyState al final
        ↓
bloque 6: la inyección
        ↓
entrega, incluida la lista de no-anclados
```
