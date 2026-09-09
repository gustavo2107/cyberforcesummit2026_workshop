# Taller — Análisis forense de un incidente OT con asistencia de IA

**CyberForce Summit 2026 · Track TECH-COM**
Duración: 2 horas · Formato: hands-on · Nivel: intermedio

---

## Qué es esto

Un taller donde los participantes investigan una intrusión real en un sistema
instrumentado de seguridad (SIS) industrial usando un asistente de IA conectado
a `tshark` vía MCP, y después contrastan sus hallazgos contra las
investigaciones publicadas por Dragos, FireEye/Mandiant y CISA.

La pregunta que responde el taller no es "¿qué pasó?" — eso ya está publicado.
Es **"¿puede un analista de IA llegar solo a lo que llegaron esas firmas, y cómo
distingo cuando razona de cuando alucina?"**

## Por qué este caso

La evidencia es un PCAP de 896 paquetes tomado durante la ejecución real del
malware contra un controlador Triconex. Sin el disector de protocolo es tráfico
UDP opaco: 896 tramas de `data`. Con el disector es una historia completa de
siete minutos, de reconocimiento a ejecución.

Eso hace del caso un banco de pruebas honesto para IA aplicada a forense:
TriStation es un protocolo propietario y apenas documentado, así que el modelo
**no puede resolverlo de memoria**. Tiene que trabajar con la evidencia o
inventar — y ambas cosas se notan.

## Estructura del repositorio

```
docs/
  00-brief-escenario.md     Brief del participante (SIN spoilers) — se reparte
  01-guia-instructor.md     Guion minuto a minuto — CONTIENE SPOILERS
  02-workbook.md            Preguntas guiadas — se reparte
  03-rubrica.md             Verdad de referencia — CONTIENE SPOILERS
  04-lecturas.md            Fuentes primarias, ordenadas
  05-inyeccion.md           Diseño del ejercicio de inyección — SPOILERS
setup/
  Dockerfile                Entorno reproducible
  docker-compose.yml
  mcp-config.example.json   Configuración del MCP de tshark
  SETUP.md                  Instalación y trampas conocidas
scripts/
  fetch-evidence.sh         Descarga la evidencia desde la fuente original
  verify-setup.sh           Valida la cadena completa antes del taller
prompts/
  00-reglas-de-anclaje.md   La regla que hace que el ejercicio sirva
  01-baseline.md            Prompts de arranque para participantes
  02-experimento-contaminacion.md   Recuerdo vs. razonamiento
evidence/
  README.md                 Cómo obtener el PCAP (no se versiona aquí)
  companion/                Artefactos sintéticos de nuestra autoría
```

## Inicio rápido

```bash
./scripts/fetch-evidence.sh     # descarga tricotools desde GitHub
docker compose -f setup/docker-compose.yml up -d
./scripts/verify-setup.sh       # confirma que el disector carga
```

Si `verify-setup.sh` pasa, el taller es viable en esa máquina. Si no pasa,
lee `setup/SETUP.md` antes de seguir.

## Advertencia sobre spoilers

Los archivos marcados **SPOILERS** contienen las respuestas. Si vas a
participar en el taller y no a impartirlo, quédate en `docs/00`, `docs/02` y
`prompts/`.

## Integridad de la evidencia

El PCAP es evidencia auténtica y **no se modifica**. El ejercicio de inyección
usa artefactos acompañantes en `evidence/companion/` que son **sintéticos y de
nuestra autoría**, claramente marcados como tales. Adulterar la evidencia real
invalidaría la comparación contra los reportes públicos, que es todo el punto
del taller.

## Créditos y licencia

Ver `NOTICE.md`. La evidencia y el disector son trabajo de Nozomi Networks
bajo licencia BSD-3-Clause. Los materiales didácticos de este repositorio son
propios.
