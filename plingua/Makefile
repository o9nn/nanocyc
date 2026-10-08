ODIR = obj
SDIR = src
BDIR = bin
IDIR = include

OBJ_PLINGUA = y.tab.o lex.yy.o node_value.o scope.o syntax_tree.o system.o init.o parser.o pattern.o formats.o cplusplus.o 

OBJ_PSIM = psim.o command_line.o

OBJ_MLINGUA = mli_parser.o cytos_xml.o mlingua_main.o

OBJ_MSIM = mli_parser.o cytos_xml.o msim.o msim_main.o

OBJ_RLINGUA = rli_parser.o rlingua_main.o
      
BIN_PLINGUA = plingua

BIN_PSIM = psim

BIN_MLINGUA = mlingua

BIN_MSIM = msim

BIN_RLINGUA = rlingua

CFlags=-c -O3 -Wall -std=gnu++11 
LDFlags=-lfl -lboost_system -lboost_filesystem -lboost_program_options
CC=g++
RM=rm
FLEX=flex
BISON=bison

all: grammar compiler simulator mcompiler msimulator rcompiler extensions

# FinOps membrane reconciliation models (accospace + isabellex + fincosys)
FINOPS_MODELS = membrane_reconciliation_minimal fincosys_fixture_reconciliation accospace_grouped_reconciliation fincosys_records_reconciliation

# Chapter hybrids: geometric .mli and relevance .rli companions of psystems/*.pli.
MLI_HYBRIDS = \
	../psystems/ch02/ch02_singularity_assembly.mli \
	../psystems/ch02/ch02_fractal_tape.mli \
	../psystems/ch06/ch06_tubulin_ppm.mli \
	../psystems/ch06/ch06_nanodevice_tc.mli \
	../psystems/ch08/ch08_spiral_cylinders.mli \
	../psystems/ch08/ch08_knot_morphogenesis.mli \
	../psystems/ch08/ch08_knot_selfassembly.mli \
	../psystems/ch09/ch09_living_gel.mli

RLI_HYBRIDS = \
	../psystems/ch05/ch05_wheel_of_intelligence.rli \
	../psystems/ch05/ch05_creativity_primes.rli \
	../psystems/ch07/ch07_h3_decision_device.rli \
	../psystems/ch07/ch07_wheel_of_primes.rli \
	../psystems/ch10/ch10_ten_paradoxes.rli

check-extensions: mcompiler rcompiler $(BDIR)/test_mli_geometry_extensions $(BDIR)/test_rlingua
	@$(BDIR)/test_mli_geometry_extensions
	@$(BDIR)/test_rlingua
	@set -e; \
	for f in $(MLI_HYBRIDS); do \
	  echo "== $$f"; \
	  err=$$($(BDIR)/$(BIN_MLINGUA) -v -o /dev/null $$f 2>&1); \
	  echo "$$err" | grep -E 'Imports:[[:space:]]+[1-9]' >/dev/null || { echo "FAIL: no imports in $$f"; echo "$$err"; exit 1; }; \
	  echo "$$err" | grep -E 'symbols=[1-9]' >/dev/null || { echo "FAIL: companion has no symbols in $$f"; echo "$$err"; exit 1; }; \
	  echo "$$err" | grep -E 'Tiles:[[:space:]]+[1-9]' >/dev/null || { echo "FAIL: no tiles in $$f"; echo "$$err"; exit 1; }; \
	done; \
	for f in $(RLI_HYBRIDS); do \
	  echo "== $$f"; \
	  err=$$($(BDIR)/$(BIN_RLINGUA) -v -s 0 -o /dev/null $$f 2>&1); \
	  echo "$$err" | grep -E 'Imports:[[:space:]]+[1-9]' >/dev/null || { echo "FAIL: no imports in $$f"; echo "$$err"; exit 1; }; \
	  echo "$$err" | grep -E 'symbols=[1-9]' >/dev/null || { echo "FAIL: companion has no symbols in $$f"; echo "$$err"; exit 1; }; \
	  echo "$$err" | grep -E 'Nodes:[[:space:]]+[1-9]' >/dev/null || { echo "FAIL: no nodes in $$f"; echo "$$err"; exit 1; }; \
	done; \
	echo "check-extensions: 8 .mli + 5 .rli hybrids OK"

check-finops: compiler simulator
	@mkdir -p $(ODIR)/finops
	@for m in $(FINOPS_MODELS); do \
	  echo "== $$m"; \
	  $(BDIR)/$(BIN_PLINGUA) examples/finops/$$m.pli -o $(ODIR)/finops/$$m.json -n || exit 1; \
	  $(BDIR)/$(BIN_PSIM) $(ODIR)/finops/$$m.json -v 1 | grep -A1 'SKIN MEMBRANE' | tail -1; \
	done

# Regression checks: catalog examples with documented halting configurations.
# Each run asserts the exact final multisets the example headers promise.
# Only the last CONFIGURATION block of the psim trace is inspected; each
# membrane block is parsed from its (SKIN) MEMBRANE ID header to its Multiset
# (tolerating intermediate metadata lines), and the multiset entries are
# sorted so assertions do not depend on the serializer's print order.
# Intelligible step output: sexpr/json/human/diff traces, width fallback,
# time-crystal collapse, and named rules.
check-trace: compiler simulator
	bash tests/test_trace.sh

check-examples: compiler simulator
	@mkdir -p $(ODIR)/examples
	@echo "== todo_g_gauge_parallel_transport (gauge invariance: wa{1} = wb{1})"; \
	$(BDIR)/$(BIN_PLINGUA) examples/todo_g_gauge_parallel_transport.pli -o $(ODIR)/examples/gauge.json -n || exit 1; \
	fin=$$($(BDIR)/$(BIN_PSIM) $(ODIR)/examples/gauge.json -v 1 -o $(ODIR)/examples/gauge_out.json | awk '/CONFIGURATION/{buf=""} {buf=buf $$0 "\n"} END{printf "%s", buf}'); \
	got=$$(echo "$$fin" | awk -v L="Label: c1," '/MEMBRANE ID:/{m=index($$0,L)>0} m&&sub(/^Multiset: /,""){print;m=0}' | tr ',' '\n' | sort | paste -sd,); \
	test "$$got" = "wa{1},wb{1}" || { echo "FAIL: c1 = '$$got', expected wa{1},wb{1}"; echo "$$fin"; exit 1; }; \
	echo "   OK: c1 halts with wa{1},wb{1}"
	@echo "== todo_enps_navigation_controller (ml = c+2*sl = 8, mr = c+2*sr = 16)"; \
	$(BDIR)/$(BIN_PLINGUA) examples/todo_enps_navigation_controller.pli -o $(ODIR)/examples/enps.json -n || exit 1; \
	trace=$$($(BDIR)/$(BIN_PSIM) $(ODIR)/examples/enps.json -v 1 -o $(ODIR)/examples/enps_out.json); \
	fin=$$(echo "$$trace" | awk '/CONFIGURATION/{buf=""} {buf=buf $$0 "\n"} END{printf "%s", buf}'); \
	got=$$(echo "$$fin" | awk -v L="Label: 1," '/MEMBRANE ID:/{m=index($$0,L)>0} m&&sub(/^Multiset: /,""){print;m=0}' | tr ',' '\n' | sort | paste -sd,); \
	test "$$got" = "ml*8,mr*16" || { echo "FAIL: body = '$$got', expected ml*8,mr*16"; echo "$$fin"; exit 1; }; \
	mid=$$(echo "$$trace" | awk '/^CONFIGURATION: 2$$/{f=1} /^CONFIGURATION: 3$$/{f=0} f'); \
	got=$$(echo "$$mid" | awk -v L="Label: 2," '/MEMBRANE ID:/{m=index($$0,L)>0} m&&sub(/^Multiset: /,""){print;m=0}' | tr ',' '\n' | sort | paste -sd,); \
	test "$$got" = "c*2,e{1}*2,e{2}*2,p{1},vl*5,vr*5,xr*4" || { echo "FAIL: controller at step 2 = '$$got' (enzyme/token rate bounds violated)"; echo "$$mid"; exit 1; }; \
	echo "   OK: body halts with ml*8,mr*16; step-2 controller shows xr*4 (enzyme-bounded 2/step)"
	@echo "== todo_kp_flame_agent_coordination (board archives idle*5, logs done*5)"; \
	$(BDIR)/$(BIN_PLINGUA) examples/todo_kp_flame_agent_coordination.pli -o $(ODIR)/examples/kp.json -n || exit 1; \
	fin=$$($(BDIR)/$(BIN_PSIM) $(ODIR)/examples/kp.json -v 1 -o $(ODIR)/examples/kp_out.json | awk '/CONFIGURATION/{buf=""} {buf=buf $$0 "\n"} END{printf "%s", buf}'); \
	got=$$(echo "$$fin" | awk -v L="Label: 9," '/MEMBRANE ID:/{m=index($$0,L)>0} m&&sub(/^Multiset: /,""){print;m=0}' | tr ',' '\n' | sort | paste -sd,); \
	test "$$got" = "done*5,idle*5" || { echo "FAIL: board = '$$got', expected done*5,idle*5"; echo "$$fin"; exit 1; }; \
	test "$$(echo "$$fin" | awk '/MEMBRANE ID:/{w=($$0~/Label: [1-4],/); if(w)t++} w&&/^Multiset: /{if($$0=="Multiset: idle")n++; w=0} END{print t "/" n}')" = "5/5" || { echo "FAIL: expected exactly 5 worker membrane instances (labels 1-4), all idle"; echo "$$fin"; exit 1; }; \
	echo "   OK: board halts with done*5,idle*5 and 5 idle workers"

grammar: y.tab.c lex.yy.c

compiler: $(OBJ_PLINGUA) $(BIN_PLINGUA) 

simulator: $(OBJ_PSIM) $(BIN_PSIM)

mcompiler: $(OBJ_MLINGUA) $(BIN_MLINGUA)

msimulator: $(OBJ_MSIM) $(BIN_MSIM)

rcompiler: $(OBJ_RLINGUA) $(BIN_RLINGUA)

$(BIN_PLINGUA): $(patsubst %,$(ODIR)/%,$(OBJ_PLINGUA))
	@mkdir -p $(BDIR)
	$(CC) $^ $(LDFlags) -o $(BDIR)/$@ 
	
$(BIN_PSIM): $(patsubst %,$(ODIR)/%,$(OBJ_PSIM))
	@mkdir -p $(BDIR)
	$(CC) $^ $(LDFlags) -o $(BDIR)/$@ 	

$(BIN_MLINGUA): $(patsubst %,$(ODIR)/%,$(OBJ_MLINGUA))
	@mkdir -p $(BDIR)
	$(CC) $^ -o $(BDIR)/$@

$(BIN_MSIM): $(patsubst %,$(ODIR)/%,$(OBJ_MSIM))
	@mkdir -p $(BDIR)
	$(CC) $^ -o $(BDIR)/$@

$(BIN_RLINGUA): $(patsubst %,$(ODIR)/%,$(OBJ_RLINGUA))
	@mkdir -p $(BDIR)
	$(CC) $^ -o $(BDIR)/$@

%.o: $(SDIR)/%.cpp	
	@mkdir -p $(ODIR)
	$(CC) $(CFlags) -I$(IDIR) -o $(ODIR)/$@ $<

%.o: $(SDIR)/psystem/%.cpp	
	@mkdir -p $(ODIR)
	$(CC) $(CFlags) -I$(IDIR) -o $(ODIR)/$@ $<

%.o: $(SDIR)/parser/%.cpp	
	@mkdir -p $(ODIR)
	$(CC) $(CFlags) -I$(IDIR) -o $(ODIR)/$@ $<

%.o: $(SDIR)/simulator/%.cpp	
	@mkdir -p $(ODIR)
	$(CC) $(CFlags) -I$(IDIR) -o $(ODIR)/$@ $<


%.o: $(SDIR)/simulator/psim/%.cpp	
	@mkdir -p $(ODIR)
	$(CC) $(CFlags) -I$(IDIR) -o $(ODIR)/$@ $<

%.o: $(SDIR)/generators/cplusplus/%.cpp	
	@mkdir -p $(ODIR)
	$(CC) $(CFlags) -I$(IDIR) -o $(ODIR)/$@ $<

%.o: $(SDIR)/msystem/%.cpp
	@mkdir -p $(ODIR)
	$(CC) $(CFlags) -I$(IDIR) -o $(ODIR)/$@ $<

%.o: $(SDIR)/rlingua/%.cpp
	@mkdir -p $(ODIR)
	$(CC) $(CFlags) -I$(IDIR) -o $(ODIR)/$@ $<

# RR/OpenCog extension targets (header-only + standalone demos)
extensions: $(BDIR)/rr_simple_demo $(BDIR)/rr_demo $(BDIR)/demo_repl $(BDIR)/test_rr_enhanced $(BDIR)/test_next_directions $(BDIR)/test_opencog_integration $(BDIR)/adaptive_foraging $(BDIR)/test_rlingua $(BDIR)/test_e2e $(BDIR)/test_mli_geometry_extensions

$(BDIR)/rr_simple_demo: examples/rr/rr_simple_demo.cpp
	@mkdir -p $(BDIR)
	$(CC) -O3 -Wall -std=gnu++11 -I$(IDIR) -o $@ $<

$(BDIR)/rr_demo: examples/rr/rr_demo.cpp
	@mkdir -p $(BDIR)
	$(CC) -O3 -Wall -std=gnu++11 -I$(IDIR) -o $@ $<

$(BDIR)/demo_repl: src/rr/demo_repl.cpp
	@mkdir -p $(BDIR)
	$(CC) -O2 -Wall -std=gnu++11 -I$(IDIR) -o $@ $<

$(BDIR)/test_rr_enhanced: src/rr/test_rr_enhanced.cpp
	@mkdir -p $(BDIR)
	$(CC) -O2 -Wall -std=gnu++11 -I$(IDIR) -o $@ $<

$(BDIR)/test_next_directions: src/rr/test_next_directions.cpp
	@mkdir -p $(BDIR)
	$(CC) -O2 -Wall -std=gnu++11 -I$(IDIR) -o $@ $<

$(BDIR)/test_opencog_integration: src/rr/test_opencog_integration.cpp
	@mkdir -p $(BDIR)
	$(CC) -O2 -Wall -std=gnu++11 -I$(IDIR) -o $@ $<

$(BDIR)/adaptive_foraging: examples/rr/adaptive_foraging.cpp
	@mkdir -p $(BDIR)
	$(CC) -O3 -Wall -std=gnu++11 -I$(IDIR) -o $@ $<

$(BDIR)/test_rlingua: src/rr/test_rlingua.cpp src/rlingua/rli_parser.cpp
	@mkdir -p $(BDIR)
	$(CC) -O2 -Wall -std=gnu++11 -I$(IDIR) -o $@ $^

$(BDIR)/test_e2e: src/rr/test_e2e.cpp
	@mkdir -p $(BDIR)
	$(CC) -O2 -Wall -std=gnu++11 -I$(IDIR) -o $@ $<

$(BDIR)/test_mli_geometry_extensions: src/msystem/test_mli_geometry_extensions.cpp src/msystem/mli_parser.cpp
	@mkdir -p $(BDIR)
	$(CC) -O2 -Wall -std=gnu++11 -I$(IDIR) -o $@ $^

%.o: $(SDIR)/parser/%.c	
	@mkdir -p $(ODIR)
	$(CC) $(CFlags) -I$(IDIR) -o $(ODIR)/$@ $<

y.tab.c: $(SDIR)/parser/plingua.y
	$(BISON) -o $(SDIR)/parser/$@ -yd $<

lex.yy.c: $(SDIR)/parser/plingua.l
	$(FLEX) -o $(SDIR)/parser/$@ $<  
	
clean:
	$(RM) -f $(patsubst %,$(ODIR)/%,$(OBJ_PLINGUA)) $(patsubst %,$(ODIR)/%,$(OBJ_PSIM)) $(patsubst %,$(ODIR)/%,$(OBJ_MLINGUA)) $(patsubst %,$(ODIR)/%,$(OBJ_MSIM)) $(patsubst %,$(ODIR)/%,$(OBJ_RLINGUA)) $(BDIR)/$(BIN_PLINGUA) $(BDIR)/$(BIN_PSIM) $(BDIR)/$(BIN_MLINGUA) $(BDIR)/$(BIN_MSIM) $(BDIR)/$(BIN_RLINGUA) $(BDIR)/rr_simple_demo $(BDIR)/rr_demo $(BDIR)/demo_repl $(BDIR)/test_rr_enhanced $(BDIR)/test_next_directions $(BDIR)/test_opencog_integration $(BDIR)/adaptive_foraging $(BDIR)/test_rlingua $(BDIR)/test_e2e $(BDIR)/test_mli_geometry_extensions $(SDIR)/parser/y.tab.c $(SDIR)/parser/y.tab.h $(SDIR)/parser/lex.yy.c
	
install:
	@mkdir -p /usr/local/PLingua/$(BIN_PLINGUA)/
	@mkdir -p /usr/local/PLingua/$(BIN_PSIM)/
	@cp $(BDIR)/$(BIN_PLINGUA) /usr/local/PLingua/$(BIN_PLINGUA)/
	@cp $(BDIR)/$(BIN_PSIM) /usr/local/PLingua/$(BIN_PSIM)/
	@cp LICENSE /usr/local/PLingua/
	@ln -sf /usr/local/PLingua/$(BIN_PLINGUA)/$(BIN_PLINGUA) /usr/local/bin/
	@ln -sf /usr/local/PLingua/$(BIN_PSIM)/$(BIN_PSIM) /usr/local/bin/
	@cp -rf $(IDIR)/cereal/ /usr/local/include/
	@mkdir -p /usr/local/include/plingua/
	@cp -f $(IDIR)/serialization.* /usr/local/include/plingua/
