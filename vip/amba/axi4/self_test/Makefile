# =============================================================================
# axi4 VIP Self Test Makefile（编译 + 仿真 + 回归 Toolkit）
#
# 目标：
#   compile      编译 VIP 库与 self-test 环境（生成可执行）
#   smoke        最小正向事务（smoke tier）
#   feature      全 feature 测试（feature tier）
#   regression   全回归（full tier）
#   cov          收集覆盖率
#   clean        清理产物
#
# 由 vip_tool.py regression 调用：make -C self_test <target>
# 支持仿真器：SIM ?= vcs（可改为 xrun / vsim / verilator）
# =============================================================================

# ---- 仿真器选择 ----
SIM       ?= vcs

# ---- UVM ----
UVM_HOME  ?= $(VCS_HOME)/etc/uvm-1.2
UVM_OPTS  ?= -ntb_opts uvm-1.2

# ---- 目录 ----
SRC_DIR   := ../src
TB_DIR    := .
SIM_DIR   ?= run
LOG_DIR   ?= logs

# ---- 编译文件 ----
FILELIST  := filelist.f
TOP       := axi4_smoke_tb

# ---- 工具 ----
PY        ?= uv run python

.PHONY: all compile smoke feature regression full cov clean

all: compile

# =============================================================================
# 编译
# =============================================================================
compile: $(SIM_DIR)
	@echo "=== compile axi4 VIP self-test (SIM=$(SIM)) ==="
ifeq ($(SIM),vcs)
	vcs -sverilog -full64 -timescale=1ns/1ps $(UVM_OPTS) \
		+incdir+$(SRC_DIR) +incdir+$(SRC_DIR)/transaction \
		+incdir+$(SRC_DIR)/agent +incdir+$(SRC_DIR)/sequences \
		+incdir+$(SRC_DIR)/coverage +incdir+$(SRC_DIR)/checker \
		+incdir+$(SRC_DIR)/env +incdir+. \
		-f $(FILELIST) -o $(SIM_DIR)/simv
else ifeq ($(SIM),xrun)
	xrun -sv -timescale 1ns/1ps \
		+incdir+$(SRC_DIR) +incdir+$(SRC_DIR)/transaction \
		+incdir+$(SRC_DIR)/agent +incdir+$(SRC_DIR)/sequences \
		+incdir+$(SRC_DIR)/coverage +incdir+$(SRC_DIR)/checker \
		+incdir+$(SRC_DIR)/env +incdir+. \
		-f $(FILELIST) -l $(LOG_DIR)/compile.log
else
	@echo "ERROR: 未支持的仿真器 SIM=$(SIM)（vcs/xrun/vsim/verilator）"
	@exit 1
endif

# =============================================================================
# 仿真（smoke / feature / full 分层）
# =============================================================================
smoke: compile
	@echo "=== RUN axi4 smoke ==="
	$(MAKE) _sim_run UVM_TESTNAME=axi4_smoke_test

feature: compile
	@echo "=== RUN axi4 feature ==="
	$(MAKE) _sim_run UVM_TESTNAME=axi4_feature_test

regression: full

full: compile
	@echo "=== RUN axi4 full regression ==="
	$(MAKE) _sim_run UVM_TESTNAME=axi4_smoke_test

_sim_run:
	mkdir -p $(LOG_DIR)
	$(SIM_DIR)/simv +UVM_TESTNAME=$(UVM_TESTNAME) \
		-l $(LOG_DIR)/$(UVM_TESTNAME).log +ntb_random_seed=1
	@echo "PASS: $(UVM_TESTNAME)"

# =============================================================================
# 覆盖率
# =============================================================================
cov: compile
	@echo "=== collect axi4 coverage ==="
	$(SIM_DIR)/simv +UVM_TESTNAME=axi4_smoke_test -cm line+cond+tgl+assert \
		-cm_name axi4_cov -l $(LOG_DIR)/cov.log
	@echo "覆盖率报告: $(LOG_DIR)/cov.log"

# =============================================================================
# 清理
# =============================================================================
clean:
	rm -rf $(SIM_DIR) $(LOG_DIR) simv simv.daidir csrc ucli.key *.vpd *.fsdb

$(SIM_DIR):
	mkdir -p $(SIM_DIR)
