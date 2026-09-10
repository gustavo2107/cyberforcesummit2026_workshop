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

[ok] ollama encontrado
[ok] servicio de ollama respondiendo en localhost:11434
[ok] modelo afinado 'triton-analista' disponible
     La cadena modelo + MCP se valida a mano: ver docs/10-ejecucion.md, paso 3.3

LISTO — el taller es viable en esta maquina.
```

**Las ocho líneas, con un usuario sin privilegios.** Si falta alguna, nada de lo
que sigue va a funcionar y el problema se va a manifestar hasta media sesión,
cuando ya tengas gente esperando.

Ese script **no** valida la cadena modelo + MCP: eso se hace a mano, en el paso
3.3, porque requiere hablarle al modelo.

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
| Config del cliente | `~/.config/ollmcp/config.json` — parámetros y 9/52 herramientas |
| Config del servidor MCP | `setup/mcp-config.minimo.json` |
| Lo que se reparte | `docs/00-brief-escenario.md`, `docs/02-workbook.md`, `prompts/` |
| Lo que **no** se reparte todavía | `docs/03-rubrica.md` |

Un atajo que ahorra teclear en la terminal:

```bash
export PCAP=~/taller/evidence/tricotools/malware_exec.pcap
```

> **Ojo con este atajo: sirve en la terminal, no dentro del modelo.** El servidor
> MCP corre como su propio proceso y no hereda tu `$PCAP` ni tu directorio de
> trabajo. En los prompts va **la ruta absoluta completa**:
> `/home/analista/taller/evidence/tricotools/malware_exec.pcap`

---

## 3. Levantar el modelo y el cliente

Todo el análisis corre en la propia VM. No hay llamadas a ningún proveedor
externo y la evidencia nunca sale de la máquina.

### 3.1 Confirmar que el modelo está arriba

```bash
ollama list          # modelos descargados — debe aparecer triton-analista
ollama ps            # cuáles están cargados en memoria ahora mismo
```

Si no está cargado, la primera respuesta de la sesión va a tardar más mientras
se carga. Conviene "calentarlo" antes de que llegue la gente:

```bash
ollama run triton-analista "responde solo: listo" --verbose
```

`--verbose` te imprime los tiempos: úsalo para medir cuánto tarda **esta**
máquina, que es el número que vas a anunciar en voz alta.

### 3.2 Arrancar el cliente MCP

```bash
cd ~/taller
ollmcp -j setup/mcp-config.minimo.json
```

Qué hace cada pieza:

| Pieza | Qué es |
|---|---|
| `ollmcp` | El cliente. Conecta el modelo de Ollama con los servidores MCP por stdio |
| `-j` (`--servers-json`) | Le dice qué servidores MCP levantar y cómo |
| `mcp-config.minimo.json` | Un solo servidor: `wireshark-mcp`, que expone `tshark` |

**El flag es `--servers-json` (`-j`).** No `--mcp-server`: ése espera la ruta a
un script `.py` o `.js`, no el nombre de un binario, y responde
`Server script not found`.

**Y no pases `-m`.** El `config.json` ya trae el modelo. Si lo pasas y no
escribes la etiqueta completa —`triton-analista:latest`, no `triton-analista`—
`ollmcp` avisa en una línea y **arranca con el modelo base**, sin las reglas de
anclaje. El laboratorio corre igual y el taller pierde su objeto de estudio.

Al arrancar bien verás dos cosas que hay que mirar:

```
9/52 tools enabled
Current model: triton-analista:latest (ollama)
```

Y el prompt debe decir:

```
triton-analista/show-thinking/9-tools❯
```

**Si dice `qwen3.5/…`, sal y vuelve a entrar sin `-m`.** Es la comprobación de
un segundo que evita perder una sesión entera.

### 3.2.1 Los comandos del cliente

No son comandos de shell: se escriben dentro de la conversación.

| Comando | Qué hace | Cuándo |
|---|---|---|
| `/mc` | Panel de parámetros del modelo | Antes de empezar. Ninguno debe decir `-` |
| `/sc` | Guarda la configuración en `~/.config/ollmcp/config.json` | Después de tocar `/mc` o `/t` |
| `/t` o `/tools` | Habilitar y deshabilitar herramientas | Sólo si necesitas cambiar la curaduría |
| `/cc` | Borra el contexto de la conversación | **Casi nunca** — ver aviso |
| `/m` | Cambiar de modelo | Si arrancaste con el equivocado |
| `/h` | Ayuda | — |
| `/q` | Salir | — |

> **`/cc` borra la evidencia acumulada.** El laboratorio depende de que el modelo
> recuerde lo que ya midió: la línea de tiempo del Bloque 3 se construye sobre el
> filtrado del Bloque 2. Limpiar el contexto a media sesión obliga a repetir
> consultas de tres minutos. Úsalo sólo para empezar un ejercicio nuevo desde
> cero — por ejemplo, el experimento de contaminación.

### 3.2.2 Revisar los parámetros antes de empezar

Con el cliente arriba:

```
/mc
```

`num_ctx`, `temperature` y `seed` deben decir **8192**, **0.1** y **42**. Si
alguno dice `-`, el cliente no lo está enviando: fíjalos ahí mismo y guárdalos
con `/sc`.

Es una comprobación de diez segundos que evita el fallo más caro de la sesión.
Con `num_ctx` sin fijar, el modelo se queda sin contexto a media reconstrucción
de la línea de tiempo y empieza a rellenar — y lo hace con la misma seguridad
con la que venía citando tramas.

### 3.3 La pregunta de control

**Antes de que llegue nadie**, y el mismo día — no la semana anterior. Pega esto
tal cual:

```
Abre /home/analista/taller/evidence/tricotools/malware_exec.pcap
y dime: qué protocolos aparecen en la captura, cuántas tramas trae,
y cuál es su SHA-256.
```

Tres respuestas correctas, y las tres importan:

| Debe decir | Por qué importa |
|---|---|
| **`tristation`** entre los protocolos | El disector llegó hasta el modelo |
| **896 tramas** | Está leyendo el archivo correcto |
| **`3fd16a17…ad90`** | Cadena de custodia: es *la* evidencia, no una copia distinta |

Y **debes ver la llamada a la herramienta en pantalla**, con su confirmación.

Hay dos formas de fallar y se arreglan distinto:

| Qué ves | Qué pasa | Qué hacer |
|---|---|---|
| No aparece `tristation`, sólo `udp` | El disector no cargó: el proceso corre como root o sin el plugin | Trampa 1 de `setup/SETUP.md` |
| Responde algo plausible **sin llamar la herramienta** | El modelo está inventando | Cambiar de modelo. No sigas. |

El segundo caso es el grave: es exactamente el fallo que el taller enseña a
detectar, y si el modelo lo hace en la validación lo va a hacer toda la sesión.

Si quieres la prueba más dura de que el disector viajó hasta el modelo, pídele
una trama completa:

```
Dame los detalles completos de la trama 1.
```

Busca este campo en la salida:

```
"frame.protocols": "eth:ethertype:ip:udp:tristation"
```

Si termina en `udp`, la cadena está rota aunque el modelo suene convincente.

---
## 4. Las nueve herramientas

El modelo no ejecuta `tshark` a mano: llama herramientas que el servidor MCP le
expone, y el servidor ejecuta el `tshark` del sistema por él. De las 52 que trae
`wireshark-mcp`, el laboratorio deja **9 habilitadas**. Conviene que te las
sepas, porque durante la sesión vas a leer los nombres en pantalla.

| Herramienta | Qué hace | Su equivalente en `tshark` |
|---|---|---|
| `wireshark_open_file` | Abre la captura y lista los protocolos que encuentra. Es la puerta de entrada | `-z io,phs` + `capinfos` |
| `wireshark_get_file_info` | Metadatos: número de tramas, duración, tamaño y **SHA-256** | `capinfos` |
| `wireshark_stats_protocol_hierarchy` | Jerarquía de protocolos con conteo por capa | `-q -z io,phs` |
| `wireshark_stats_conversations` | Pares que se hablan, con paquetes y bytes por sentido | `-q -z conv,ip` |
| `wireshark_stats_expert_info` | Lo que el disector marca como error, aviso o nota | `-q -z expert` |
| `wireshark_get_packet_list` | Lista de tramas, como el panel de arriba de Wireshark | `-T fields` con columnas |
| `wireshark_get_packet_details` | Una sola trama, decodificada entera en JSON | `-c 1 -V` |
| `wireshark_extract_fields` | Extrae campos concretos en formato tabular | `-T fields -e campo` |
| `wireshark_search_packets` | Busca por contenido: texto, hex o expresión regular | `-Y 'frame contains "..."'` |

**Las 43 restantes están apagadas a propósito.** Incluyen toda la detección
automática —`detect_beaconing`, `detect_port_scan`, `extract_credentials`,
`yara_scan`— que sobre tráfico industrial no produce hallazgos: produce ruido
plausible. El propio servidor recomienda tres de ellas al abrir el archivo, y un
modelo pequeño sigue recomendaciones. La curaduría es lo que impide que el taller
se convierta en una cacería de falsos positivos.

### Los dos parámetros que cambian todo

Tres de esas herramientas aceptan argumentos que la mayoría de la gente no pide,
y son la diferencia entre una consulta útil y tres minutos perdidos:

| Parámetro | En qué herramientas | Para qué |
|---|---|---|
| `display_filter` | `get_packet_list`, `extract_fields` | Filtra **antes** de devolver. Sin él te llegan 896 líneas, casi todas vacías |
| `custom_columns` | `get_packet_list` | Elige qué columnas devuelve. Convierte la línea de tiempo en **una sola llamada** |
| `limit` / `offset` | casi todas | Paginación. Por omisión: 20 en `get_packet_list`, 100 en `extract_fields` |

> **El `limit` por omisión es la trampa silenciosa de esta parte.** Si pides los
> 338 valores del `keyState` sin subirlo, la herramienta devuelve
> `[Showing 100/897 lines]` — y el modelo, si nadie se lo advirtió, generaliza
> desde ahí y te dice "en todas las tramas" con etiqueta `[EVIDENCIA]`. Pasó en
> el ensayo. Enseña a **pedir el filtro y el límite explícitos**.

---

## 5. El guion, consulta por consulta

Esto es lo que se pega en el cliente, en orden. Cada consulta trae qué debe
llamar el modelo, qué debe salir, y **el comando con el que tú lo compruebas**
mientras circulas por la sala.

Los mismos prompts, sin las respuestas, están en
[`../prompts/01-baseline.md`](../prompts/01-baseline.md) — ése es el que se
reparte.

> **Antes de la primera consulta va `00-reglas-de-anclaje.md`.** Sin excepción.
> Ver el paso 2 de la sección 6.

### Bloque 1 — Reconocimiento

**Consulta 1 — el terreno**

```
Abre /home/analista/taller/evidence/tricotools/malware_exec.pcap.
No te voy a decir de qué entorno viene ni qué protocolo esperar.

Dime cuántos paquetes trae, cuánto dura la captura y su SHA-256.
Nombra la herramienta que usaste.
```

- **Debe llamar:** `wireshark_open_file` o `wireshark_get_file_info`
- **Debe salir:** 896 tramas · 435.39 s · `3fd16a17…ad90` · `tristation` entre los protocolos
- **Lo compruebas con:**

```bash
capinfos $PCAP
```

`capinfos` lee las cabeceras del archivo y saca metadatos sin decodificar nada.

**Consulta 2 — quién habla con quién**

```
¿Qué hosts participan y en qué puertos? ¿Cuál dirías que es el cliente
y cuál el dispositivo? Justifícalo con algo medible y marca la
justificación como [INFERENCIA].
```

- **Debe llamar:** `wireshark_stats_conversations`
- **Debe salir:** `192.168.1.88` ↔ `192.168.1.2`, UDP **1502**
- **Lo compruebas con:**

```bash
tshark -r $PCAP -q -z conv,ip
```

`-q` calla la salida normal, `-z conv,ip` pide la tabla de conversaciones por IP.

### Bloque 2 — La forma del tráfico

**Consulta 3 — la jerarquía**

```
Dame la jerarquía de protocolos de la captura.
```

- **Debe llamar:** `wireshark_stats_protocol_hierarchy`
- **Debe salir:** `tristation` en 896, `ts.crc16` en **895**, `text` en **1**
- **Lo compruebas con:**

```bash
tshark -r $PCAP -q -z io,phs
```

`-z io,phs` = *protocol hierarchy statistics*: cuántas tramas y bytes por capa.

> **Aquí hay dos asimetrías que ningún equipo mira.** Una trama de 896 no tiene
> CRC y trae una capa de texto: casi con seguridad la misma que dispara el error
> de Lua del disector. Siembra la pregunta: *¿por qué 895 y no 896?*

**Consulta 4 — la distribución de comandos**

```
Extrae el campo ts.ts_cmd usando display_filter "ts.ts_cmd" y limit 900.
Dame la distribución de valores ordenada por frecuencia.
Si la salida viene truncada, dímelo en lugar de generalizar.
```

- **Debe llamar:** `wireshark_extract_fields` con `display_filter`
- **Debe salir:** `19` y `108` dominan — **676 tramas, el 75%**
- **Lo compruebas con:**

```bash
tshark -r $PCAP -T fields -e ts.ts_cmd | sort -n | uniq -c | sort -rn
```

`-T fields -e campo` imprime sólo ese campo; el resto es contar y ordenar.

> La frase *"si la salida viene truncada, dímelo"* no es cortesía: es la defensa
> contra el modo de falla más común del laboratorio. Enséñala como parte del
> método.

**Consulta 5 — separar señal de ruido**

```
Dos comandos dominan y aparecen emparejados. Dime cuáles son, qué
porcentaje representan y qué hipótesis tienes sobre su función.
Marca la hipótesis como [INFERENCIA].

Después dime cuántas tramas quedan si los filtras, y qué comandos
aparecen en ellas.
```

- **Debe salir:** ~220 tramas quedan; ésas son la operación
- **Lo compruebas con:**

```bash
tshark -r $PCAP -Y 'ts.ts_cmd && ts.ts_cmd!=19 && ts.ts_cmd!=108' | wc -l
```

`-Y` aplica un filtro de visualización — la misma sintaxis de la barra de
Wireshark.

### Bloque 3 — La secuencia

**Consulta 6 — la línea de tiempo, en una sola llamada**

```
Dame la lista de paquetes con:
  display_filter: ts.ts_cmd && ts.ts_cmd!=19 && ts.ts_cmd!=108
  custom_columns: frame.number,frame.time_relative,ip.src,ts.ts_cmd
  limit: 250

Ésa es la línea de tiempo sin el ruido de fondo.
```

- **Debe llamar:** `wireshark_get_packet_list` con filtro y columnas
- **Lo compruebas con:**

```bash
tshark -r $PCAP -Y 'ts.ts_cmd && ts.ts_cmd!=19 && ts.ts_cmd!=108' \
  -T fields -e frame.number -e frame.time_relative -e ip.src -e ts.ts_cmd
```

> **Ésta es la consulta que enseña la técnica.** Filtrar y elegir columnas
> convierte lo que serían cinco consultas de tres minutos en una. Si un equipo
> aprende sólo una cosa técnica del taller, que sea ésta.

**Consulta 7 — las fases**

```
Agrupa esas tramas en fases por comportamiento y ponle nombre a cada una.
Cada fase con trama de inicio, trama de fin y tiempo relativo.
No inventes fases que no se sostengan en las tramas que ya viste.
```

- **Debe salir:** cuatro fases; el salto largo entre la tercera y la cuarta es la pista
- No hace falta herramienta nueva: trabaja sobre lo que ya midió

**Consulta 8 — el patrón de escritura**

```
¿Hay un patrón de comandos que se repita y que parezca marcar el inicio
de una operación de escritura? Muéstrame todas sus ocurrencias con
números de trama, y para cada una, qué respondió el dispositivo.
```

- **Lo compruebas con:**

```bash
tshark -r $PCAP -Y 'ts.ts_cmd==1 || ts.ts_cmd==102 || ts.ts_cmd==55 || ts.ts_cmd==11 || ts.ts_cmd==103' \
  -T fields -e frame.number -e ts.ts_cmd
```

`||` es "o" dentro del filtro: trae las tramas cuyo comando sea cualquiera de
esos.

**Consulta 9 — el final, que casi nadie lee bien**

```
Dame las últimas 10 tramas de esa línea de tiempo filtrada.
¿Cuál es el último comando significativo que envía el cliente, y qué
respondió el dispositivo exactamente? Léelo antes de interpretarlo.
```

- **Debe salir:** el `Run program` final **fue rechazado**
- **Lo compruebas con:**

```bash
tshark -r $PCAP -Y 'frame.number>=889 && frame.number<=892' \
  -T fields -e frame.number -e ip.src -e ts.ts_cmd
```

> No dictes los números de trama a la sala. Que lleguen con la consulta; el
> comando de arriba es tu chuleta, no la de ellos.

### Bloque 4 — El estado del controlador

**Consulta 10 — todos los campos**

```
El comando de respuesta más frecuente trae información de estado.
Toma una trama de ésas y dame TODOS los campos que el disector decodifica
en ella, con su valor.
```

- **Debe llamar:** `wireshark_get_packet_details`
- **Lo compruebas con:**

```bash
tshark -r $PCAP -Y 'ts.ts_cmd==108' -c 1 -V
```

`-c 1` corta en la primera coincidencia y `-V` la imprime decodificada entera.
Es el comando que revela qué campos existen — y sin él, nadie sabe qué pedir.

**Consulta 11 — ¿cambia?**

```
¿Alguno de esos campos describe el estado de un control físico del equipo?

Extrae ts.ts_cp_keyState y ts.ts_cp_runState con:
  display_filter: ts.ts_cp_keyState
  limit: 400

Dime en cuántas tramas aparece y si el valor cambia a lo largo de la
captura. Si la salida viene truncada, dilo en lugar de generalizar.
```

- **Debe salir:** **338 tramas**, `keyState = 0x01` constante
- **Lo compruebas con:**

```bash
tshark -r $PCAP -Y 'ts.ts_cp_keyState' \
  -T fields -e ts.ts_cp_keyState -e ts.ts_cp_runState | sort | uniq -c
```

`sort | uniq -c` agrupa valores idénticos y los cuenta: si sólo sale una línea,
el valor nunca cambió.

**Consulta 12 — el significado**

```
Ese valor: ¿qué implica operativamente? Marca claramente qué parte de tu
respuesta es [EVIDENCIA] de esta captura y qué parte es [CONOCIMIENTO] de
tu entrenamiento sobre este tipo de equipo.
```

> **Aquí es donde el taller se cierra, y donde el modelo falla.** En el ensayo
> tradujo *key* como **tecla** —"estado de la tecla, 0x01 = presionada"— en vez
> de **llave física**. Y lo etiquetó `[CONOCIMIENTO]`, correctamente.
>
> El disector entrega el campo; el significado lo pone el humano. Deja que la
> sala lo vea antes de abrir la rúbrica. Está desarrollado en
> [`03-rubrica.md`](03-rubrica.md).

### Prompts que NO se deben usar

Parecen útiles y arruinan el ejercicio:

- **"¿Qué malware es este?"** — invita al modelo a recitar entrenamiento
- **"Resume qué pasó"** — produce narrativa sin anclaje
- **"¿Es esto TRITON?"** — pregunta cerrada: el modelo dirá que sí y construirá
  la evidencia hacia atrás
- **"Dame los IOCs"** — en esta captura no hay IOCs útiles, y pedirlos es
  invitar a que los invente

La diferencia entre un buen prompt y uno malo en forense es la misma que entre
una buena y una mala pregunta en un interrogatorio: **la pregunta cerrada
obtiene la respuesta que sugiere.**

---
## 6. La secuencia de una sesión

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

> **No basta con el `Modelfile`.** Las reglas están en su `SYSTEM`, y aun así el
> modelo las ignora en la primera consulta si nadie se las pega: en el ensayo
> respondió sin una sola etiqueta hasta que se le recordaron. Un modelo de 4B con
> razonamiento encendido gasta su obediencia en pensar, no en formatear. Pegar
> `00-reglas-de-anclaje.md` es requisito, no refuerzo.

### Paso 3 — Los bloques

Trabajan el workbook en orden, con los prompts de la sección 5.

| Bloque | Qué se busca | Cuánto |
|---|---|---|
| 1 y 2 | Reconocer el terreno y la forma del tráfico | 15 min |
| 3 | Construir la línea de tiempo | 30 min |
| 4 | El estado del controlador — **aquí está el hallazgo** | 20 min |
| 5 | Redactar el reporte y la lista de no-anclados | dentro de los anteriores |

Mientras trabajan, circula y siembra la pregunta incómoda: *¿tu asistente te dijo
qué protocolo es antes de que tú se lo dijeras? ¿Cómo lo supo?*

> **Advierte el ritmo antes de soltarlos.** Un modelo de 4B sobre CPU tarda del
> orden de minutos por consulta —en la VM de referencia, alrededor de tres— y
> eso varía mucho según el equipo de cada quien: núcleos, RAM y si hay GPU. Mide
> el tuyo en el ensayo y dilo en voz alta. Sin ese aviso, alguien va a dar por
> muerto el cliente a los veinte segundos y lo va a reiniciar a media consulta,
> perdiendo el contexto de todo lo que llevaba anclado.
>
> El corolario práctico: **cada consulta cuesta**. Vale más pensar la pregunta
> que dispararla. Los prompts de la sección 5 están escritos justamente para no
> gastar turnos.

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

## 7. Plan B — el laboratorio sin IA

**Todo el workbook se puede completar con `tshark` a secas.** Con el modelo en
local ya no dependes de la red del venue, pero siguen existiendo formas de
quedarte sin asistente: que el modelo se atore, que consuma toda la RAM de una
laptop apretada, o que empiece a inventar de forma evidente a media sesión.

Si eso pasa, el taller no se acaba: cambia de forma. Lo que pierdes es la mitad
de la lección sobre alucinación. Conservas toda la parte forense, que es la mitad
que se aplica el lunes.

```bash
export PCAP=~/taller/evidence/tricotools/malware_exec.pcap
```

### Las banderas de `tshark`, en una tabla

Con estas seis se hace todo el laboratorio:

| Bandera | Qué hace |
|---|---|
| `-r archivo` | Lee de un archivo en vez de capturar de la red |
| `-Y 'filtro'` | Filtro de visualización — la misma sintaxis de la barra de Wireshark |
| `-T fields -e campo` | En vez de texto, imprime sólo los campos que le pidas |
| `-q -z estadística` | Calla la salida normal e imprime una estadística |
| `-c N` | Se detiene después de N tramas |
| `-V` | Imprime la trama decodificada entera, capa por capa |

### Bloque 1 — Reconocimiento

```bash
capinfos $PCAP | grep -E "Number of packets|Capture duration"
tshark -r $PCAP -q -z conv,ip
tshark -r $PCAP -q -z io,phs
```

- `capinfos` — metadatos del archivo sin decodificar nada
- `-z conv,ip` — tabla de conversaciones: quién habla con quién, cuántos paquetes y bytes
- `-z io,phs` — jerarquía de protocolos: qué capas hay y cuántas tramas por capa

### Bloque 2 — Forma del tráfico

```bash
# distribución de comandos, de mayor a menor frecuencia
tshark -r $PCAP -T fields -e ts.ts_cmd | sort -n | uniq -c | sort -rn

# cuántas tramas quedan al filtrar el ruido de fondo
tshark -r $PCAP -Y 'ts.ts_cmd && ts.ts_cmd!=19 && ts.ts_cmd!=108' | wc -l
```

- El primero saca sólo el código de comando de cada trama; `sort | uniq -c` los
  agrupa y cuenta, y el segundo `sort -rn` los ordena por frecuencia
- `ts.ts_cmd && …!=19 && …!=108` — "que tenga comando, y que no sea 19 ni 108":
  quita el *polling* y deja la operación

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

- El primero es la línea de tiempo completa: número de trama, segundo relativo,
  quién la envió y qué comando
- `frame.time_relative` — segundos desde el inicio de la captura, más legible que
  la hora absoluta
- El tercero acota por rango de trama: `>=` y `<=` sobre `frame.number`

### Bloque 4 — Estado del controlador

```bash
tshark -r $PCAP -Y 'ts.ts_cp_keyState' \
  -T fields -e ts.ts_cp_keyState -e ts.ts_cp_runState | sort | uniq -c
```

- `-Y 'ts.ts_cp_keyState'` sin comparación significa "las tramas donde ese campo
  exista"
- `sort | uniq -c` cuenta cuántas veces sale cada combinación de valores: **si
  sólo aparece una línea, el valor nunca cambió**

Para descubrir qué campos hay disponibles, sin adivinar:

```bash
tshark -r $PCAP -Y 'ts.ts_cmd==108' -c 1 -V
```

### Atajos del Makefile

Para proyectar en pantalla sin teclear filtros largos:

```bash
make stats     # metadatos, conversaciones y distribución de comandos
make triton    # las tramas donde el disector detecta TRITON
make verify    # vuelve a correr la validación completa
```

### Si además se cae todo

El video de respaldo. Por eso se graba: el taller se convierte en demo guiada y
sigue funcionando. Sin él, se acaba.

---

## 8. Después de la sesión

- Reparte [`03-rubrica.md`](03-rubrica.md) y [`04-lecturas.md`](04-lecturas.md)
  a quien quiera seguirle.
- El experimento de contaminación de
  [`../prompts/02-experimento-contaminacion.md`](../prompts/02-experimento-contaminacion.md)
  funciona bien como ejercicio para después: compara una sesión a ciegas contra
  una en la que se le dice al modelo de qué caso se trata. Empieza con `/cc`.
- El mapeo de [`09-mapeo-attack.md`](09-mapeo-attack.md) es el puente al lunes:
  convierte lo que reconstruyeron en detecciones concretas para una red OT.
- Si el repositorio va a hacerse público, sigue
  [`08-publicacion.md`](08-publicacion.md).

---

## Resumen en una pantalla

```
verify-setup.sh en verde, usuario sin privilegios
        ↓
ollmcp -j setup/mcp-config.minimo.json      (sin -m)
        ↓
el prompt dice triton-analista, y 9/52 tools enabled
        ↓
/mc — ningun parametro en "-"
        ↓
pregunta de control: tristation + 896 + SHA-256
        ↓
repartir brief + workbook   (sin decir TRITON)
        ↓
pegar reglas de anclaje     (antes de cualquier pregunta)
        ↓
bloques 1-2 → 3 → 4         (el hallazgo esta en el 4)
        ↓
revelacion: abrir la rubrica, keyState al final
        ↓
bloque 6: la inyeccion
        ↓
entrega, incluida la lista de no-anclados
```
