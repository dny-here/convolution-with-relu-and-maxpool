# ======================================================================
#  Makefile  --  Conv(3 kernels 3x3) + MaxPool 2x2 + ReLU
#  Simulator : Icarus Verilog (iverilog / vvp), golden model: Python 3
#
#  src/rtl        RTL modules
#  src/testbench  testbenches + golden models
#  build/         generated files (sim binaries, .hex, .vcd, logs)
#
#  make help      show all targets
# ======================================================================

RTL_DIR := src/rtl
TB_DIR  := src/testbench
BUILD   := build

IVERILOG ?= iverilog
VVP      ?= vvp
PYTHON   ?= python3
GTKWAVE  ?= gtkwave

# ---- test options (override on the command line) ----
MODE  ?= random      # random | mid | zeros | max_pos | max_neg | checker
SEED  ?= 1
SHIFT ?= 0           # output quantization: ReLU, >> SHIFT, saturate to 255

RTL_SRCS := $(wildcard $(RTL_DIR)/*.v)
IVFLAGS  := -g2012 -Wall -Wno-timescale

SIM_TOP    := $(BUILD)/sim_top
SIM_CUSTOM := $(BUILD)/sim_custom

.PHONY: help all run custom regress wave wave-custom lint clean

help:
	@echo "Targets:"
	@echo "  make run     [MODE=mid SEED=2 SHIFT=8]  general testbench (tb_top) vs golden.py"
	@echo "  make custom                             testbench for the given task data (SHIFT set in golden_custom.py)"
	@echo "  make regress                            all modes x SHIFT 0,6,9 + custom data"
	@echo "  make lint                               compile RTL only, with warnings"
	@echo "  make wave / wave-custom                 open the last waveform in GTKWave"
	@echo "  make clean                              remove build/"
	@echo ""
	@echo "Modes: random mid zeros max_pos max_neg checker"

all: run custom

$(BUILD):
	@mkdir -p $(BUILD)

# ---------------------------------------------------------------------
#  General testbench (tb_top) : golden.py writes image/kernel/expected .hex
# ---------------------------------------------------------------------
# SHIFT is a compile-time parameter, so the sim is rebuilt on every `make run`
run: | $(BUILD)
	$(IVERILOG) $(IVFLAGS) -P tb_top.SHIFT=$(SHIFT) -o $(SIM_TOP) $(TB_DIR)/tb_top.v $(RTL_SRCS)
	cd $(BUILD) && $(PYTHON) ../$(TB_DIR)/golden.py $(MODE) $(SEED) $(SHIFT) | tail -n 1
	cd $(BUILD) && $(VVP) sim_top | grep -E "PASS|FAIL|MISMATCH|ERROR|TIMEOUT"

# ---------------------------------------------------------------------
#  Directed testbench for the task's image/kernels
#  golden_custom.py regenerates src/testbench/tb_custom.v
# ---------------------------------------------------------------------
custom: | $(BUILD)
	$(PYTHON) $(TB_DIR)/golden_custom.py $(TB_DIR)/tb_custom.v > $(BUILD)/golden_custom_output.txt
	$(IVERILOG) $(IVFLAGS) -o $(SIM_CUSTOM) $(TB_DIR)/tb_custom.v $(RTL_SRCS)
	cd $(BUILD) && $(VVP) sim_custom | grep -v "VCD info"

# ---------------------------------------------------------------------
#  Regression
# ---------------------------------------------------------------------
regress: | $(BUILD)
	@fail=0; \
	for sh in 0 6 9; do \
	  $(IVERILOG) $(IVFLAGS) -P tb_top.SHIFT=$$sh -o $(SIM_TOP) $(TB_DIR)/tb_top.v $(RTL_SRCS) || exit 1; \
	  for m in random mid zeros max_pos max_neg checker; do \
	    for s in 1 2; do \
	      (cd $(BUILD) && $(PYTHON) ../$(TB_DIR)/golden.py $$m $$s $$sh >/dev/null); \
	      r=$$(cd $(BUILD) && $(VVP) sim_top | grep -E "PASS|FAIL" | head -n 1); \
	      printf "SHIFT=%-2s mode=%-8s seed=%s : %s\n" $$sh $$m $$s "$$r"; \
	      case "$$r" in PASS*) ;; *) fail=1;; esac; \
	    done; \
	  done; \
	done; \
	$(PYTHON) $(TB_DIR)/golden_custom.py $(TB_DIR)/tb_custom.v > $(BUILD)/golden_custom_output.txt; \
	$(IVERILOG) $(IVFLAGS) -o $(SIM_CUSTOM) $(TB_DIR)/tb_custom.v $(RTL_SRCS) || exit 1; \
	r=$$(cd $(BUILD) && $(VVP) sim_custom | grep -E "PASS|FAIL" | head -n 1); \
	echo "custom task data            : $$r"; \
	case "$$r" in PASS*) ;; *) fail=1;; esac; \
	if [ $$fail -eq 0 ]; then echo "REGRESSION PASSED"; else echo "REGRESSION FAILED"; exit 1; fi

# ---------------------------------------------------------------------
#  Misc
# ---------------------------------------------------------------------
lint: | $(BUILD)
	$(IVERILOG) $(IVFLAGS) -o $(BUILD)/lint.out $(RTL_SRCS)
	@echo "RTL compiled without errors"

wave:
	$(GTKWAVE) $(BUILD)/tb_top.vcd &

wave-custom:
	$(GTKWAVE) $(BUILD)/tb_custom.vcd &

clean:
	rm -rf $(BUILD)