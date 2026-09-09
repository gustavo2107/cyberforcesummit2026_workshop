# Herramientas

Qué usa el taller, para qué sirve cada pieza y por qué está elegida así.

---

## Cadena principal

| Herramienta | Versión de referencia | Rol en el taller |
|---|---|---|
| `tshark` | 4.2.2 (Lua 5.2.4) | Motor de análisis. Todo lo que se afirma en el taller sale de un comando suyo. |
| `TriStation.lua` | 2018-04-04 | Disector del protocolo. Convierte 896 tramas opacas en una historia legible. |
| MCP de tshark | variable | Puente entre el asistente de IA y `tshark`. |
| `capinfos` | viene con tshark | Metadatos de la captura (bloque 1 del workbook). |
| `git` | cualquiera reciente | Obtener el repo y la evidencia. |

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
