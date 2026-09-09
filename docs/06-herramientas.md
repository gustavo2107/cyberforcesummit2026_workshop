# Herramientas

Qué usa el taller, para qué sirve cada pieza y por qué está elegida así.

---

## Cadena principal

| Herramienta | Versión de referencia | Rol en el taller |
|---|---|---|
| `tshark` | 4.2.2 (Lua 5.2.4) | Motor de análisis. Todo lo que se afirma en el taller sale de un comando suyo. |
| `TriStation.lua` | 2018-04-04 | Disector del protocolo. Convierte 896 tramas opacas en una historia legible. |
| **Ollama** | — | Runtime del modelo local. Sirve los pesos por API en `localhost:11434`. |
| **Qwen3.5 4B** | 3.4 GB | El analista. Elegido por su desempeño llamando herramientas, no por su prosa. |
| **`ollmcp`** | — | Cliente MCP para Ollama. Conecta el modelo con los servidores por stdio. |
| MCP de tshark | variable | Puente entre el cliente y `tshark`. |
| `capinfos` | viene con tshark | Metadatos de la captura (bloque 1 del workbook). |
| `git` | cualquiera reciente | Obtener el repo y la evidencia. |

### Por qué un modelo local, y por qué éste

**Local** porque elimina de golpe las tres fallas más comunes de un taller con
IA: que el WiFi del venue no aguante, que el proveedor tenga un mal día, y que
los participantes no traigan cuenta. Además la evidencia nunca sale de la
máquina, que en un taller de forense OT no es un detalle menor.

**Qwen3.5 4B** porque el laboratorio no le pide al modelo que escriba bien: le
pide que **invoque `tshark`, lea el resultado y no invente entre una llamada y
otra**. En la evaluación de tool calling de 2026 sobre 40 casos deterministas,
este modelo de 3.4 GB obtuvo **97.5% de acierto** — primer lugar, por encima de
modelos cinco veces mayores. Ahí es donde los locales se separan.

En CPU pura responde en segundos, no al instante. Es esperable y hay que
advertirlo a la sala.

### Afinar el modelo — sin tocar la detección

Los valores por omisión de Ollama están pensados para conversación, no para
análisis forense. Dejarlos como vienen produce fallas que **parecen del modelo
y son de configuración**:

| Parámetro | Por omisión | Qué provoca aquí |
|---|---|---|
| `num_ctx` | **2048 tokens** | La salida de `tshark` desborda el contexto y el modelo pierde la evidencia a media sesión |
| `temperature` | **0.8** | Ajuste para escritura creativa. Fabrica justo la confabulación que el taller enseña a detectar |

Un solo `tshark -V` de una trama ya son cientos de tokens, y una línea de tiempo
de 216 tramas no cabe ni de lejos en 2048. El modelo se queda sin evidencia,
y como no sabe decir "se me olvidó", rellena. Culparlo de eso sería injusto.

`setup/Modelfile` construye una variante afinada:

```bash
ollama create triton-analista -f setup/Modelfile
ollmcp --model triton-analista --mcp-server <tu-config>
```

Qué cambia, y por qué cada cosa:

- **`num_ctx 8192`** — alcanza para el flujo del workbook. Con 16 GB de RAM
  puedes subirlo a 16384; el costo en memoria del caché de atención crece
  rápido, así que no más de lo que la máquina aguante.
- **`temperature 0.1` y `seed 42`** — dos corridas sobre la misma evidencia dan
  prácticamente la misma respuesta. Eso hace el taller reproducible y hace que
  el video de respaldo se parezca a lo que ve la sala.
- **Un `SYSTEM` con las reglas de anclaje** ya incorporadas, más la instrucción
  de llamar **una herramienta a la vez**. Esto último ataca una debilidad
  conocida de los modelos locales pequeños: encadenan llamadas en paralelo
  cuando cada paso depende del anterior.
**Dónde está la línea.** El `SYSTEM` **no contiene una sola respuesta del
taller**, y eso es verificable: no menciona el `keyState`, ni las tramas 75 y
887, ni que el `Run program` final fue rechazado, ni ningún código de comando.

Lo único que le dice sobre el protocolo es que el disector traduce los códigos
por él, y cómo descubrir los campos disponibles con `tshark -V`. Es método, no
contenido.

> Una versión anterior incluía una tabla de códigos de comando, argumentando que
> era la misma traducción que el disector imprime. Se retiró: si hay que
> argumentar por qué algo no es una fuga, es mejor quitarlo. La tabla tampoco
> aportaba nada que el disector no diera solo.

Es la misma información que un participante humano tiene a la mano en `docs/`.
La diferencia es que el humano sabe leer un protocolo industrial y el modelo
no ha visto TriStation nunca.

> **Un efecto secundario que conviene conocer:** un modelo de 4B sabe bastante
> menos de TRITON que uno de frontera. Eso hace el análisis a ciegas más limpio
> —hay menos que recitar— pero debilita el experimento de contaminación de
> `../prompts/02-experimento-contaminacion.md`, que se apoya justamente en que
> el modelo conozca el caso. Si quieres esa demostración en toda su fuerza,
> córrela aparte contra un modelo grande.

### Por qué `tshark` y no Wireshark gráfico

Tres razones, en orden de importancia:

1. **El MCP invoca `tshark`, no la GUI.** Si los participantes trabajan en la
   interfaz gráfica y el asistente en línea de comandos, no están viendo lo
   mismo y la regla de anclaje se vuelve inverificable.
2. **Un comando se pega en un reporte; un clic no.** El anclaje exige que cada
   afirmación venga con el comando que la produce.
3. **Se automatiza.** La rúbrica de este repositorio se verificó ejecutando los
   mismos comandos que van a correr los participantes.

Wireshark gráfico es bienvenido para explorar. Pero lo que se entrega va con
comando.

### Por qué el disector es indispensable

Sin él, `tshark` reporta 896 tramas de `data` sobre UDP. Literalmente nada.

Con él, aparecen los códigos de función de TriStation traducidos a texto, la
dirección de cada mensaje, la extracción de programas PLC transmitidos y la
detección de firmas de TRITON.

Esa diferencia **es** la lección central del taller sobre IA aplicada a
dominios especializados: el modelo no puede razonar sobre lo que no puede
decodificar. La inteligencia no sustituye al conocimiento del protocolo — lo
consume.

---

## El MCP de tshark

Opciones probadas por la comunidad, en orden de simplicidad de arranque:

| Proyecto | Nota |
|---|---|
| [`0xKoda/WireMCP`](https://github.com/0xKoda/WireMCP) | Enfocado en análisis de tráfico para LLMs |
| [`bx33661/Wireshark-MCP`](https://github.com/bx33661/Wireshark-MCP) | Respuestas respaldadas por datos reales de tshark |
| [`khuynh22/mcp-wireshark`](https://github.com/khuynh22/mcp-wireshark) | Instalable con pip, multiplataforma |
| [`tuliperis/SharkMCP`](https://github.com/tuliperis/SharkMCP) | Captura y análisis |

**Criterio de elección:** que invoque el `tshark` del sistema en lugar de traer
su propio parser. Así hereda el disector automáticamente, sin escribir código.
Es la razón por la que este taller es viable en dos horas.

**Advertencia que aplica a todos:** el proceso del MCP **no debe correr como
root**. Ver `setup/SETUP.md`, trampa 1.

---

## Herramientas del instructor (no del participante)

| Herramienta | Para qué |
|---|---|
| `triconex_honeypot.py` | Viene en `tricotools`. Simula un controlador SIS respondiendo a reconocimiento. Sirve para generar tráfico propio y compararlo con el del atacante real. Requiere `crcmod`. |
| Wireshark gráfico | Preparar capturas de pantalla y el video de respaldo. |
| [`MDudek-ICS/TRISIS-TRITON-HATMAN`](https://github.com/MDudek-ICS/TRISIS-TRITON-HATMAN) | Binarios originales y decompilados. **Material de preparación del instructor. No se distribuye ni se ejecuta en el venue.** |

### Hook de pre-commit

El repositorio trae un hook que bloquea commits con tokens, llaves privadas,
correos personales o intentos de versionar la evidencia de terceros. **No se
activa solo:** `core.hooksPath` es configuración local y no viaja en el
repositorio, así que después de clonar hay que correrlo una vez.

```bash
make hooks          # activa .githooks/
brew install gitleaks   # opcional, para cobertura completa
```

Sin gitleaks el hook corre igual unas comprobaciones básicas sin dependencias.
Con gitleaks añade el catálogo completo de reglas del proyecto.

Es deliberadamente local: te detiene **antes** de que el secreto salga de tu
máquina, a diferencia del secret scanning de GitHub, que avisa después — y que
además no está disponible en repositorios privados con cuenta gratuita.

> Si agregas reglas a `.gitleaks.toml`, recuerda que gitleaks usa RE2 y **no
> soporta lookahead ni lookbehind**. Una regla con `(?!...)` no falla la
> validación: hace que gitleaks entre en pánico y el hook reviente en cada
> commit. Pruébala con `gitleaks detect --config .gitleaks.toml --no-git`.

---

## Lo que este taller deliberadamente NO usa

**Plataformas comerciales de forense OT.** Son excelentes y ninguno de los
participantes va a tener licencia el lunes siguiente. El taller se diseñó para
que todo lo aprendido se pueda aplicar con herramientas libres.

**Frameworks de emulación de adversarios (Atomic Red Team, Caldera).** Generan
telemetría sintética cuya respuesta ya conoces. Aquí el punto es exactamente el
contrario: evidencia real, con una verdad de referencia publicada por terceros
e independiente de este taller.

**Extracción automatizada de IOCs.** En esta captura no hay IOCs
operativamente útiles, y pedirlos es invitar al modelo a inventarlos. Ver
`prompts/01-baseline.md`, sección de prompts que no se deben usar.

---

## Compatibilidad de versiones

El disector es de abril de 2018. Está verificado en **tshark 4.2.2 con Lua
5.2.4**.

En versiones muy nuevas de Wireshark podría requerir ajustes: la API de Lua
cambia entre versiones mayores. **Verifica en la máquina del taller, no en la
tuya**, y hazlo con semanas de anticipación, no la noche anterior.

Si el disector deja de cargar tras una actualización, la ruta rápida es fijar
la versión de la VM y no actualizarla — es un entorno de laboratorio de un solo
uso, no un servidor de producción.
