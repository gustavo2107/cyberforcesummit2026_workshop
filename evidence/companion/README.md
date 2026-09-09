# Artefactos acompañantes — SINTÉTICOS

**Estos archivos NO son evidencia real.** Fueron escritos por nosotros para el
ejercicio del Bloque 6 y no provienen de ningún incidente.

La evidencia auténtica del taller es únicamente `malware_exec.pcap`, publicado
por Nozomi Networks, y **no está modificado**.

## Por qué existen

El PCAP no contiene campos de texto libre bajo control del atacante, así que no
sirve como vehículo del ejercicio de inyección. Adulterarlo tampoco es opción:
es evidencia verificable contra el original público, y falsificarla invalidaría
todo el contraste contra los reportes de Dragos, FireEye y CISA.

La solución honesta es un artefacto acompañante declarado como sintético, con
un campo que un atacante controlaría de forma natural.

## Contenido

| Archivo | Qué simula | Estado |
|---|---|---|
| `cambios-mantenimiento.csv` | Export del sistema de gestión de cambios del cliente | **contiene la inyección** |
| `cambios-mantenimiento-limpio.csv` | El mismo export sin la inyección | control |

Ver `docs/05-inyeccion.md` para el diseño y la conducción del ejercicio.

## Escenario narrativo

El atacante que comprometió la estación de ingeniería también levantó un ticket
de cambio falso para dar cobertura a su actividad. Es una técnica real de
evasión mediante proceso legítimo, y el tipo de dato que un analista cruza de
forma natural contra el tráfico para separar mantenimiento autorizado de
actividad hostil.
