# Lecturas

Ordenadas por cuándo conviene leerlas, no alfabéticamente.

---

## Para preparar el taller

**1. Dragos — TRISIS: Analyzing Safety System Targeting Malware** (14 dic 2017)
<https://www.dragos.com/resources/whitepaper/trisis-analyzing-safety-system-targeting-malware/>

El mejor punto de entrada. Explica qué es un SIS y por qué atacarlo es
distinto a todo lo demás, antes de meterse al malware. Si solo lees una cosa,
lee esta.

**2. Mandiant/FireEye — Attackers Deploy New ICS Attack Framework TRITON** (14 dic 2017)
<https://www.mandiant.com/resources/blog/attackers-deploy-new-ics-attack-framework-triton>

El reporte original de la firma que llevó la respuesta a incidentes. La
narrativa de cómo se llegó de IT a la estación de ingeniería del SIS.

**3. FireEye — A Totally Tubular Treatise on TRITON and TriStation** (jun 2018)
<https://www.fireeye.com/blog/threat-research/2018/06/totally-tubular-treatise-on-triton-and-tristation.html>

**La pieza clave para este taller.** Ingeniería inversa del protocolo
TriStation: es de donde salen los códigos de función que el disector traduce.
Sin esto, el PCAP es ruido. Léela con calma y toma notas.

**4. CISA — MAR-17-352-01 HatMan (Update B)**
<https://www.cisa.gov/sites/default/files/documents/MAR-17-352-01%20HatMan%20-%20Safety%20System%20Targeted%20Malware%20(Update%20B).pdf>

El análisis del gobierno estadounidense; entra al payload que corría dentro del
controlador. El documento más árido de la lista y el que más peso institucional
te da al citarlo en escenario.

**5. Nozomi — Black Hat USA 2018, whitepaper de Carcano**
<https://i.blackhat.com/us-18/Wed-August-8/us-18-Carcano-TRITON-How-It-Disrupted-Safety-Systems-And-Changed-The-Threat-Landscape-Of-Industrial-Control-Systems-Forever-wp.pdf>

De los mismos autores del disector que vas a usar. Explica cómo llegaron a los
indicadores que dispara la detección de las tramas 75 y 887.

---

## Herramienta y evidencia

**NozomiNetworks/tricotools** — <https://github.com/NozomiNetworks/tricotools>
PCAP, disector y honeypot. BSD-3-Clause.

**Nozomi — Wireshark Dissector for TriStation Protocol**
<https://www.nozominetworks.com/blog/new-triton-analysis-tool-wireshark-dissector-for-tristation-protocol>

---

## Complementarias

**Midnight Blue — Analyzing the TRITON industrial malware**
<https://www.midnightblue.nl/blog/analyzing-the-triton-industrial-malware>
Ingeniería inversa independiente; buen contraste con los reportes comerciales.

**MITRE ATT&CK for ICS — S0013**
<https://collaborate.mitre.org/attackics/index.php/Software/S0013>
Para la diapositiva de TTPs.

**DTIC — Cyber Risk to Mission Case Study: Triton**
<https://apps.dtic.mil/sti/trecms/pdf/AD1183008.pdf>
Enfoque de riesgo a la misión. De aquí sale el argumento de negocio.

---

## Vigencia — la diapositiva que necesitas lista

La objeción "el caso es de 2017" va a salir. Ten esto a la mano:

**FBI PIN — TRITON Malware Remains Threat to Global Critical Infrastructure** (mar 2022)
<https://www.ic3.gov/CSA/2022/220325.pdf>
Cinco años después del incidente, el FBI publicando que el malware sigue
vigente. Mata la objeción en una diapositiva.

**Dragos — 2026 OT Cybersecurity Year in Review**
<https://www.dragos.com/blog/dragos-2026-ot-cybersecurity-year-in-review>

Los datos que cierran la brecha temporal:

- 26 grupos de amenaza rastreados, 11 activos en 2025, 3 nuevos
- **AZURITE se especializa en estaciones de ingeniería OT** — exactamente el
  vector de este caso
- KAMACITE mapeó sistemáticamente lazos de control en infraestructura
- VOLTZITE investigó qué condiciones disparan paros de proceso
- Ransomware industrial: +64% en 2025; de 80 a 119 grupos; 3,300
  organizaciones afectadas
- **Manufactura: más de dos tercios de todas las víctimas**
- Permanencia promedio en OT: 42 días. Con visibilidad en OT: contención en 5.

**El argumento de fondo, para decirlo en voz alta:** los SIS tienen ciclos de
vida de 20 a 30 años. Ese Triconex sigue en producción. TriStation no ha
cambiado. En OT el parcheo es la excepción, no la regla — el reflejo de "ya
está parcheado" es un reflejo de TI aplicado a un dominio donde no aplica.

Este caso no es historia. Es la plantilla para la que se están preparando hoy.
