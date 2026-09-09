# Créditos, licencias y procedencia

## Evidencia y disector — Nozomi Networks

`malware_exec.pcap`, `TriStation.lua` y `triconex_honeypot.py` son obra de
**Nozomi Networks**, publicados en
<https://github.com/NozomiNetworks/tricotools> bajo **licencia BSD-3-Clause**.

Autores del disector: Younes Dragoni (@ydragoni) y Alessandro Di Pinto
(@adipinto), Nozomi Networks Security Research, abril 2018.

Este repositorio **no incluye copia** de esos archivos: `scripts/fetch-evidence.sh`
los obtiene del origen. Así cada participante verifica la procedencia por su
cuenta y la licencia upstream se respeta sin ambigüedad.

El PCAP es una captura *stripped* tomada durante la ejecución real del malware
en el laboratorio de Nozomi.

## Investigaciones de referencia

La rúbrica del taller se contrasta contra:

- **Dragos** — *TRISIS: Analyzing Safety System Targeting Malware*, dic 2017
- **FireEye/Mandiant** — *Attackers Deploy New ICS Attack Framework TRITON*,
  dic 2017, y *A Totally Tubular Treatise on TRITON and TriStation*, jun 2018
- **CISA** — *MAR-17-352-01 HatMan: Safety System Targeted Malware*
- **Nozomi Networks** — Black Hat USA 2018, Andrea Carcano et al.
- **MITRE ATT&CK for ICS** — Software S0013

Enlaces completos en `docs/04-lecturas.md`.

## Materiales de este repositorio

El brief, el workbook, la rúbrica, la guía del instructor, los prompts, los
scripts y los artefactos sintéticos de `evidence/companion/` son obra propia,
bajo la licencia en `LICENSE`.

## Lo que este repositorio NO contiene

- **Binarios de malware.** Ni TRITON ni ninguna muestra ejecutable. El
  repositorio `MDudek-ICS/TRISIS-TRITON-HATMAN` contiene los binarios
  originales y decompilados; es material de preparación del instructor, **no
  se distribuye en el taller ni se ejecuta en el venue**.
- **Datos de ninguna víctima real.** El escenario del brief es ficticio y los
  artefactos acompañantes son sintéticos.

## Nota sobre la víctima

La prensa reportó ampliamente que el incidente ocurrió en una planta
petroquímica en Arabia Saudita. **Los reportes técnicos originales de Dragos y
FireEye no nombran a la víctima.** Si mencionas el nombre en el taller,
atribúyelo a la cobertura periodística y no a los reportes técnicos.
