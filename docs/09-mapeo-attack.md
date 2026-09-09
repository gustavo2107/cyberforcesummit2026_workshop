# Mapeo a MITRE ATT&CK for ICS

> **Versión de referencia: ATT&CK v19.2 (6 de agosto de 2026).**
> Este mapeo se hizo contra las páginas vivas de attack.mitre.org, verificando
> cada ID y cada nombre. Si estás leyendo esto después de una release nueva,
> revísalo: ATT&CK publica dos versiones grandes al año y ahora además releases
> ágiles. MITRE publica un *crosswalk* en JSON para migrar entre versiones.

---

## La advertencia que hace útil este documento

Un mapeo a ATT&CK es el lugar perfecto para colar afirmaciones sin anclaje.

La captura del taller cubre **una sola etapa** del ataque: la comunicación entre
la estación de ingeniería y el controlador de seguridad. El acceso inicial, el
movimiento lateral, el compromiso de la estación y todo el trabajo interno del
payload **no están en esta evidencia**. Están en los reportes.

Por eso este documento tiene dos tablas y no una. Mezclarlas sería contradecir
en silencio la regla que el taller enseña desde el minuto uno.

---

## Tabla A — Demostrado por esta captura

Cada línea se puede verificar corriendo el comando indicado sobre
`malware_exec.pcap`.

| ID | Técnica | Evidencia | Verificación |
|---|---|---|---|
| **T0885** | Commonly Used Port | Todo el tráfico sobre UDP/1502, el puerto por defecto de TriStation | `tshark -r $PCAP -T fields -e udp.dstport \| sort -u` |
| **T0869** | Standard Application Layer Protocol | Las 896 tramas son TriStation, protocolo propietario de Triconex | `tshark -r $PCAP -q -z io,phs` |
| **T0868** | Detect Operating Mode | 338 pares `Get CP status` / respuesta; las respuestas exponen `keyState` y `runState` | `tshark -r $PCAP -Y 'ts.ts_cmd==108' -T fields -e ts.ts_cp_keyState -e ts.ts_cp_runState` |
| **T0845** | Program Upload | 26 `Upload program` (cmd 65) y 72 `Upload function` (cmd 66): el atacante **lee** la lógica antes de tocarla | `tshark -r $PCAP -Y 'ts.ts_cmd==65 \|\| ts.ts_cmd==66'` |
| **T0843.003** | Program Download: **Program Append** | 3 `Allocate program` (cmd 55). El disector marca TRITON en las tramas **75** y **887** | `tshark -r $PCAP -Y '_ws.expert.message contains "TRITON"'` |
| **T0821** | Modify Controller Tasking | El controlador acepta las escrituras: `Modification accepted` en tramas **78** y **890** | `tshark -r $PCAP -Y 'ts.ts_cmd==103'` |
| **T0858** | Change Operating Mode | `Run program` (cmd 20) en trama **891**. Ver nota abajo: **fue rechazado** | `tshark -r $PCAP -Y 'ts.ts_cmd==20 \|\| ts.ts_cmd==100'` |
| **T1692.001** | Unauthorized Message: Command Message | Toda la sesión son mensajes de comando no autorizados contra el SIS | la captura completa |

### Dos notas que importan

**T0858 se intentó y falló.** La trama 891 envía `Run program`; la 892 responde
`Command rejected`. La técnica está *presente como intento*, no como éxito. Un
mapeo que la liste sin esa distinción está reportando mal la evidencia — y es
exactamente el error que el Bloque 3 del workbook está diseñado para provocar.

**El `keyState` no es una técnica del atacante.** `keyState = 0x01 [Program]`,
constante en las 338 respuestas, es una **condición del entorno** que hizo
posible T0843.003. No lo mapees como técnica: el atacante no cambió la llave, se
la encontró puesta. Es un hallazgo de configuración, y es el más importante del
taller.

---

## Por qué T0843.003 y no .001 ni .002

Ésta es la determinación analítica interesante del mapeo, y es posible **sólo
desde abril de 2026**: la v19 de ATT&CK dividió `T0843 Program Download` en tres
sub-técnicas por primera vez.

- **T0843.001 Download All** exige que el controlador entre en estado de paro.
  **La evidencia lo descarta:** `runState = 0x00 [Running]` durante los 435
  segundos completos. El proceso nunca se detuvo.
- **T0843.002 Online Edit** y **T0843.003 Program Append** permiten que el
  controlador siga corriendo. Ambas son compatibles con lo anterior.
- Entre esas dos, la evidencia apunta a **Program Append**: el comando que se
  usa es `Allocate program` — asignar un programa **nuevo**, no editar el
  existente.

Dos fuentes independientes lo corroboran: la entrada **S1009** documenta que
Triton llama a `SafeAppendProgramMod`, y la campaña **C0030** está mapeada por
MITRE a `T0843.003`.

Es un buen ejercicio para el taller: tres sub-técnicas plausibles, y un solo
byte de la evidencia —`runState`— elimina una. Eso es mapeo como análisis, no
como etiquetado.

---

## Tabla B — Documentado por los reportes, fuera de esta evidencia

Nada de esto se puede sostener con el PCAP. Se incluye para dimensionar el
alcance, no para reportarlo como hallazgo.

### Interior del payload — requiere análisis de binario

| ID | Técnica | Fuente |
|---|---|---|
| T0890 | Exploitation for Privilege Escalation | S1009 — vulnerabilidad en el firmware Tricon MP3008 |
| T0820 | Exploitation for Evasion | S1009 — deshabilita la verificación de consistencia RAM/ROM |
| T1693.001 | Modify Firmware: System Firmware | S1009 — lectura y escritura arbitraria en memoria |
| T0874 | Hooking | S1009 — cambia el puntero de función de un comando TriStation |
| T0834 | Native API | S1009 — syscalls en shellcode PowerPC |
| T0872 | Indicator Removal on Host | S1009 — escribe un programa señuelo en memoria |
| T0849 | Masquerading | S1009 — se hace pasar por `trilog.exe` |
| T0853 | Scripting | S1009 — framework en Python |
| T0880 | Loss of Safety | S1009 — el objetivo del ataque |
| T0846.002 | Remote System Discovery: Broadcast Discovery | S1009 — descubrimiento por broadcast UDP/1502 |

> `T0846.002` merece atención: la captura **no** muestra descubrimiento. El
> tráfico va dirigido a una IP concreta desde la primera trama, o sea que el
> atacante ya sabía dónde estaba el controlador. Esa etapa ocurrió antes y no
> quedó registrada aquí.

### Cadena de intrusión completa — campaña C0030 (junio a agosto 2017, TEMP.Veles)

Acceso inicial y movimiento lateral, todo del lado de TI: `T1595` Active
Scanning, `T1003.001` OS Credential Dumping (Mimikatz), `T1059.001` PowerShell,
`T0886` Remote Services (jump boxes RDP), `T0859` Valid Accounts, `T0867`
Lateral Tool Transfer, `T1036.005` Masquerading, `T1053.005` Scheduled Task,
`T0830` Adversary-in-the-Middle, `T0828` Loss of Productivity and Revenue
(la planta paró más de una semana).

---

## Lo que enseña la comparación

**Ocho técnicas se sostienen con la captura. Alrededor de treinta están
documentadas.**

Esa proporción es la lección. La evidencia de red te da la etapa final y nada
más: no el acceso inicial, no el movimiento lateral, no lo que el payload hacía
dentro del controlador, no el impacto. Un analista que lea los reportes y crea
que "eso está en la captura" acaba de importar treinta afirmaciones que no puede
probar.

Es el mismo error que comete un modelo de lenguaje al que se le dice de qué caso
se trata — y es exactamente lo que mide el experimento de contaminación en
`prompts/02-experimento-contaminacion.md`.

---

## Uso en el taller

**No lo metas al workbook.** Añadir un bloque de mapeo a las dos horas te obliga
a recortar el Bloque 4, que es donde ocurre el hallazgo.

Dónde sí funciona:

- **Diapositiva de cierre.** "Esto que acaban de reconstruir, en el vocabulario
  que su SOC ya usa." Proyecta la Tabla A.
- **Ejercicio opcional posterior**, para quien quiera seguirle: mapea tu propia
  línea de tiempo y compárala con la Tabla A.
- **El puente al lunes.** La Tabla A es una lista de detecciones concretas para
  una red OT: tráfico TriStation fuera de ventana de mantenimiento,
  `Allocate program` no autorizado, y sobre todo **monitoreo de `keyState`**.

---

## Corrección de una referencia

Versiones anteriores de este repositorio citaban a Triton como **S0013** en
`collaborate.mitre.org/attackics`. Ese sitio está descontinuado y **en el ATT&CK
actual S0013 es PlugX**, un RAT sin ninguna relación con esto.

Las referencias correctas y vigentes son:

- **[S1009 — Triton](https://attack.mitre.org/software/S1009/)** (el software)
- **[C0030 — Triton Safety Instrumented System Attack](https://attack.mitre.org/campaigns/C0030/)** (la campaña)

Si encuentras la referencia vieja en algún material derivado, corrígela. Citar
el ID de otro malware en una charla técnica es de los errores que el público
nota.
