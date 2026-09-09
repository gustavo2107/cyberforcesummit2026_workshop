# Taller — análisis forense de incidente OT con asistencia de IA
#
# Atajos para las tareas comunes. Todo esto se puede hacer a mano con los
# scripts de scripts/; el Makefile sólo evita teclear rutas.
#
# NO uses sudo con ninguno de estos objetivos: tshark deshabilita Lua para
# superusuario y el disector no cargará.

SHELL := /bin/bash
.DEFAULT_GOAL := help

PCAP := evidence/tricotools/malware_exec.pcap

.PHONY: help
help:  ## Muestra esta ayuda
	@echo "Taller TRITON — objetivos disponibles:"
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'
	@echo
	@echo "Empieza con:  make bootstrap"

.PHONY: bootstrap
bootstrap:  ## Provisiona la VM de cero a verificada (Ubuntu/Debian)
	@./scripts/bootstrap-vm.sh

.PHONY: evidence
evidence:  ## Descarga la evidencia desde el origen (Nozomi Networks)
	@./scripts/fetch-evidence.sh

.PHONY: verify
verify:  ## Valida la cadena completa antes del taller
	@./scripts/verify-setup.sh

.PHONY: stats
stats:  ## Resumen rápido de la captura (requiere setup verificado)
	@echo "--- metadatos ---"
	@capinfos -c -u $(PCAP) 2>/dev/null | grep -E "Number of packets|Capture duration"
	@echo
	@echo "--- conversaciones ---"
	@tshark -r $(PCAP) -q -z conv,ip 2>/dev/null | sed -n '5,7p'
	@echo
	@echo "--- distribución de comandos ---"
	@tshark -r $(PCAP) -T fields -e ts.ts_cmd 2>/dev/null \
		| sort -n | uniq -c | sort -rn | head -15

.PHONY: triton
triton:  ## Muestra las tramas donde el disector detecta TRITON
	@tshark -r $(PCAP) -Y '_ws.expert.message contains "TRITON"' \
		-T fields -e frame.number -e frame.time_relative -e ts.ts_signature 2>/dev/null

.PHONY: clean
clean:  ## Borra la evidencia descargada (se recupera con 'make evidence')
	@rm -rf evidence/tricotools
	@echo "evidencia eliminada — recupérala con: make evidence"

.PHONY: hooks
hooks:  ## Activa el hook de pre-commit (gitleaks)
	@./scripts/install-hooks.sh

.PHONY: check-docs
check-docs:  ## Verifica que no falte ningún documento del taller
	@for f in docs/00-brief-escenario.md docs/01-guia-instructor.md \
	          docs/02-workbook.md docs/03-rubrica.md docs/04-lecturas.md \
	          docs/05-inyeccion.md docs/06-herramientas.md \
	          docs/07-laboratorio-vm.md docs/08-publicacion.md \
	         docs/09-mapeo-attack.md docs/10-ejecucion.md; do \
		[[ -f "$$f" ]] && echo "  [ok] $$f" || echo "  [!!] FALTA $$f"; \
	done
