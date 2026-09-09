# Publicación del repositorio

Qué hacer el día que este repositorio pase de privado a público, y por qué se
publica como se publica.

---

## La decisión, y su razón

**El repositorio se publica completo, con la rúbrica y la guía del instructor
incluidas.**

Puede sonar contradictorio —son los archivos con las respuestas— así que
conviene dejar escrito el razonamiento, porque dentro de seis meses no va a ser
obvio.

El propósito de la versión pública es que **alguien más pueda impartir este
taller**. Quien vaya a hacerlo necesita la rúbrica: sin ella no sabe que el
`Run program` final fue rechazado, no sabe que el hallazgo es el `keyState`, y
no tiene con qué calificar. La guía del instructor y el diseño del ejercicio de
inyección son igual de necesarios.

En la versión pública, esos tres archivos no son una fuga: son lo que hace útil
al repositorio.

El único riesgo real —que los participantes del summit lleguen a las respuestas
antes de la sesión— **se resuelve por temporalidad, no por ocultamiento**: el
repositorio permanece privado hasta que la sesión termine. Después, las
respuestas ya no comprometen nada.

Esconder los letreros manteniendo los archivos habría sido seguridad por
oscuridad: cualquiera que clone el repositorio tiene los documentos completos,
y el historial de commits los delata en un minuto.

---

## Antes de publicar

- [ ] **La sesión del summit ya ocurrió.** Es la condición que habilita todo lo
      demás. No publicar antes.
- [ ] Revisar la descripción del repositorio: que diga qué es y para quién, y
      que no tenga erratas. Es lo primero que lee alguien que llega desde una
      búsqueda. Se edita en la página principal del repositorio → columna
      derecha → **About** → ⚙️.
- [ ] Verificar que no haya datos personales:

      # Autores del historial: solo debe aparecer la identidad noreply
      git log --format="%an <%ae>" | sort -u

      # Correos en archivos versionados que no sean noreply: no debe haber ninguno
      git grep -niE "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}" -- ':!*.md' \
        | grep -v "users.noreply.github.com"

      El chequeo es genérico a propósito: listar aquí los correos concretos que
      se quieren evitar publicaría justo lo que se pretende detectar.

- [ ] Verificar que la evidencia de terceros no esté versionada:

      git ls-files | grep tricotools     # no debe devolver nada

- [ ] Correr `make check-docs` y `./scripts/verify-setup.sh` en una máquina
      limpia. Lo que se publica tiene que funcionar recién clonado.
- [ ] Etiquetar la versión que se usó en el summit:

      git tag -a v1.0-summit -m "Versión impartida en CyberForce Summit 2026"
      git push origin v1.0-summit

      Así, si el material cambia después, queda constancia de qué versión se
      impartió ese día.

---

## Al publicar

**Settings → General → Danger Zone → Change repository visibility → Public.**

---

## Después de publicar

Estas dos no están disponibles en repos privados con cuenta gratuita, pero **se
habilitan solas al hacerlo público**. Es el momento de activarlas:

- [ ] **Settings → Advanced Security** → *Secret scanning* y *Push protection*.
      Complementan al hook de pre-commit: el hook te detiene antes de commitear,
      esto te cubre si alguien más contribuye.
- [ ] **Settings → Rulesets → New branch ruleset** sobre `main`:
      bloquear *force push* y *deletion*. En repo privado con cuenta gratuita
      GitHub avisa que no se aplican; en público sí.

Y para que se encuentre:

- [ ] **Topics** (en About → ⚙️): `ics-security`, `ot-security`, `dfir`,
      `triton`, `trisis`, `incident-response`, `ai-security`,
      `prompt-injection`, `workshop`.
- [ ] Enlazarlo desde las diapositivas del taller y desde donde publiques el
      material del summit.

---

## Lo que NO hay que hacer

**No publicar antes de que termine la sesión.** Es la única regla que importa
de todo este documento.

**No borrar los archivos del instructor para "proteger" el taller.** Ya ocurrió;
protegerlo no significa nada, y sin ellos el repositorio deja de servir para lo
que dice su descripción.

**No dejar de fijar la versión de la VM.** Si alguien clona esto en 2028, va a
querer saber contra qué versión de tshark se verificó todo. Está en
`docs/06-herramientas.md` y en `docs/07-laboratorio-vm.md`; mantenlo actualizado
si vuelves a probar sobre otra versión.
