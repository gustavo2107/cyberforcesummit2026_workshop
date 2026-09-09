# Taller — Análisis forense de un incidente OT con asistencia de IA

**CyberForce Summit 2026 · Track TECH-COM**

| | |
|---|---|
| **Duración** | 2 horas |
| **Formato** | Hands-on, equipos de 2–3 personas |
| **Nivel** | Intermedio |
| **Requisitos** | VM Linux con `tshark`, un asistente de IA con MCP |
| **Evidencia** | Captura real de TRITON/TRISIS (Nozomi Networks, BSD-3-Clause) |

---

## Qué es esto

Los participantes investigan una intrusión real contra un sistema instrumentado
de seguridad (SIS) industrial usando un asistente de IA conectado a `tshark` vía
MCP, y después contrastan sus hallazgos contra las investigaciones publicadas
por Dragos, FireEye/Mandiant y CISA.

La pregunta del taller no es *"¿qué pasó?"* — eso ya está publicado. Es:

> **¿Puede un analista de IA llegar solo a donde llegaron esas firmas, y cómo
> distingo cuando razona de cuando alucina?**

## Por qué este caso

La evidencia son 896 paquetes en 435 segundos, capturados durante la ejecución
real del malware contra un controlador Triconex.

Sin el disector de protocolo es tráfico UDP opaco: 896 tramas de `data`. Con el
disector es una historia completa de siete minutos, de reconocimiento a
ejecución.

Eso lo hace un banco de pruebas honesto para IA aplicada a forense: **TriStation
es un protocolo propietario y apenas documentado, así que el modelo no puede
resolverlo de memoria.** Tiene que trabajar con la evidencia o inventar — y
ambas cosas se notan.

## Inicio rápido

En una VM Ubuntu 24.04 limpia, **como usuario sin privilegios**:

```bash
git clone <url-de-este-repo> taller && cd taller
make bootstrap
```

Eso instala todo, descarga la evidencia y verifica la cadena. Salida esperada:

```
[ok] tshark encontrado (TShark (Wireshark) 4.2.2)
[ok] evidencia presente (896 paquetes)
[ok] disector TriStation cargado
[ok] protocolo detectado: TRISTATION
[ok] deteccion TRITON en 2 tramas

LISTO — el taller es viable en esta maquina.
```

Guía detallada de la VM: **[`docs/07-laboratorio-vm.md`](docs/07-laboratorio-vm.md)**

> ⚠️ **No uses `sudo` para correr los scripts.** Wireshark deshabilita los
> scripts Lua para superusuario, el disector no carga, y el síntoma es
> silencioso: verás `UDP` en lugar de `TRISTATION`. Es la falla número uno de
> este taller y cuesta media hora encontrarla en vivo.

## Objetivos del Makefile

```
make bootstrap    Provisiona la VM de cero a verificada
make evidence     Descarga la evidencia desde el origen
make verify       Valida la cadena completa
make stats        Resumen rápido de la captura
make triton       Tramas donde el disector detecta TRITON
make check-docs   Verifica que no falte documentación
make hooks        Activa el hook de pre-commit (gitleaks)
```

## Higiene del repositorio

Antes de tu primer commit:

```bash
make hooks
```

Activa un hook de pre-commit que bloquea el commit si detecta un token, una
llave privada, datos personales, o un intento de versionar la evidencia de
terceros. Usa [gitleaks](https://github.com/gitleaks/gitleaks) si está
instalado (`brew install gitleaks`) y, si no, corre igual unas comprobaciones
básicas sin dependencias.

Es deliberadamente local: te detiene **antes** de que el secreto salga de tu
máquina, a diferencia del secret scanning de GitHub, que avisa después.

## Estructura

```
docs/
  README.md              Índice y orden de lectura
  00-brief-escenario     Brief del participante — se reparte
  01-guia-instructor  ⚠️  Guion minuto a minuto
  02-workbook            Preguntas guiadas — se reparte
  03-rubrica          ⚠️  Verdad de referencia verificada
  04-lecturas            Fuentes primarias y datos de vigencia
  05-inyeccion        ⚠️  Ejercicio de prompt injection
  06-herramientas        La cadena técnica y por qué
  07-laboratorio-vm      Provisión de la VM, paso a paso
  08-publicacion         Checklist para pasar el repo a público
setup/
  SETUP.md               Instalación y trampas conocidas
  mcp-config.example.json
  Dockerfile             Alternativa a la VM
  docker-compose.yml
scripts/
  bootstrap-vm.sh        Provisión completa, idempotente
  fetch-evidence.sh      Descarga desde el origen + huellas SHA-256
  verify-setup.sh        Validación previa al taller
  install-hooks.sh       Activa el hook de pre-commit
.githooks/
  pre-commit             Bloquea commits con secretos o datos personales
prompts/
  00-reglas-de-anclaje   La regla que hace que el ejercicio sirva
  01-baseline            Prompts de arranque (y los que NO usar)
  02-experimento-contaminacion   Recuerdo vs. razonamiento
evidence/
  README.md              Cómo obtener el PCAP y qué esperar
  datos-sinteticos/      Datos ficticios generados para el laboratorio
```

## Datos del laboratorio

**Todo el contexto del escenario es ficticio y fue generado para este
laboratorio:** la empresa cliente (*Industrias ACME de México, S.A. de C.V.*),
la planta, los tickets de cambio, las direcciones IP y las fechas del
escenario. No corresponden a ninguna organización, sistema ni incidente real.

**No hay nombres de personas en ningún artefacto del taller.** Los tickets se
asignan a áreas responsables, nunca a individuos.

La **única** excepción es `malware_exec.pcap`: evidencia auténtica de un caso
público, sin modificar. Ver [`evidence/datos-sinteticos/README.md`](evidence/datos-sinteticos/README.md).


## Integridad de la evidencia

El PCAP es evidencia auténtica de un tercero y **no se modifica**. El ejercicio
de inyección usa artefactos en `evidence/datos-sinteticos/` que son **sintéticos y de
nuestra autoría**, declarados como tales en su propio README.

Adulterar la evidencia real invalidaría la comparación contra los reportes
públicos, que es el eje del taller.

## Créditos

Evidencia y disector: **Nozomi Networks**, BSD-3-Clause
([tricotools](https://github.com/NozomiNetworks/tricotools)). Este repositorio
no los redistribuye: `scripts/fetch-evidence.sh` los obtiene del origen.

Detalle completo de licencias y procedencia en [`NOTICE.md`](NOTICE.md).
