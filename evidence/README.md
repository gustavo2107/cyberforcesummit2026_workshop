# Evidencia

## Qué va aquí

`tricotools/` — se crea al correr `scripts/fetch-evidence.sh`. Contiene el
PCAP y el disector publicados por Nozomi Networks. **No se versiona en este
repositorio** (ver `.gitignore`).

`datos-sinteticos/` — artefactos sintéticos creados para el ejercicio del
Bloque 6. Estos sí se versionan, y están declarados como sintéticos en su
propio README.

## Por qué no versionamos el PCAP

Tres razones:

1. Es obra de un tercero con su propia licencia. Que cada quien lo obtenga del
   origen mantiene la procedencia limpia.
2. Que los participantes lo descarguen de la fuente y comparen huellas SHA-256
   es, en sí mismo, una lección de cadena de custodia.
3. Mantiene este repositorio ligero y sin evidencia de terceros redistribuida.

## Obtenerla

```bash
./scripts/fetch-evidence.sh
```

El script imprime las huellas SHA-256. **Compártelas con los participantes
antes del evento** para que verifiquen que todos trabajan sobre el mismo
archivo.

## Qué esperar

| Propiedad | Valor |
|---|---|
| Paquetes | 896 |
| Duración | 435.39 s |
| Hosts | 192.168.1.88 ↔ 192.168.1.2 |
| Transporte | UDP, puerto 1502 |
| Protocolo sin disector | `data` |
| Protocolo con disector | `TRISTATION` |
| Detecciones TRITON | 2 (tramas 75 y 887) |

Si tus números no coinciden, algo está mal en el setup. Corre
`scripts/verify-setup.sh`.
