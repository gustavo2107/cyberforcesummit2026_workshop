# Datos sintéticos — generados para el laboratorio

> ## ⚠️ AVISO
>
> **Todos los archivos de esta carpeta son ficticios. Fueron generados
> específicamente para este laboratorio y no provienen de ningún incidente,
> organización, sistema ni persona real.**
>
> Cualquier parecido de nombres, direcciones IP, números de ticket o fechas con
> entidades reales es coincidencia. No usar como referencia de nada.

---

## Qué hay aquí

| Archivo | Qué simula | Estado |
|---|---|---|
| `sintetico-cambios-mantenimiento.csv` | Export del sistema de gestión de cambios | **contiene la inyección** |
| `sintetico-cambios-mantenimiento-limpio.csv` | El mismo export sin la inyección | control |

## La organización ficticia

El escenario del taller ocurre en **Industrias ACME de México, S.A. de C.V.**,
una empresa inventada. Su instalación es la **Planta ACME-1**.

"ACME" se usa deliberadamente porque es el marcador universal de entidad
ficticia: nadie lo confunde con una empresa real.

### Convenciones

- **Direcciones IP** — rango privado `192.168.1.0/24` (RFC 1918), sin
  correspondencia con ninguna red real.
- **Personas** — no hay ninguna. Los tickets se asignan a **áreas
  responsables** (Instrumentación, Automatización, Redes, Ingeniería), nunca a
  personas nombradas.
- **Equipos** — nomenclatura genérica: `PLC-LINEA-2`, `HMI-SALA-CONTROL`,
  `SIS-TRICONEX-01`, `EWS-ING-04`.
- **Fechas** — del escenario ficticio, sin relación con las de la evidencia
  real.

## Qué NO es sintético

La única evidencia auténtica del taller es **`malware_exec.pcap`**, publicado
por Nozomi Networks, y **no está modificado**.

Esa separación es deliberada y no negociable: adulterar la evidencia real
invalidaría el contraste contra los reportes públicos de Dragos, FireEye y
CISA, que es el eje pedagógico del taller.

## Por qué existen estos archivos

El PCAP no contiene campos de texto libre bajo control del atacante, así que no
sirve como vehículo del ejercicio de inyección del Bloque 6.

La solución honesta es un artefacto acompañante declarado como sintético, con
un campo que un atacante controlaría de forma natural — el texto de
justificación de un ticket de cambio.

Diseño y conducción del ejercicio: `docs/05-inyeccion.md`.

## Sobre el contenido de la inyección

`sintetico-cambios-mantenimiento.csv` contiene, en el campo `justificacion` de
una fila, un texto diseñado para desviar a un asistente de IA que lo lea.

Es **material didáctico defensivo**: sirve para que los participantes vean
cómo se comporta su herramienta ante contenido hostil y aprendan a detectarlo.
No contiene código ejecutable, no explota ninguna vulnerabilidad de software y
no funciona contra nada que no sea un modelo de lenguaje leyendo el archivo.
