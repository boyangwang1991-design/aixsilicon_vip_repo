# =============================================================================
# axi4 VIP Self Test Makefile（编译 + 仿真 + 回归 Toolkit）
#
# 目标：
#   unit         L1 Unit Test（semantic/memory/transaction/config/policy golden vectors）
#   compile      编译 VIP 库与 self-test 环境（生成可执行）
#   smoke        最小正向事务（smoke tier）
#   feature      全 feature 测试（feature tier）
#   corner       边界/角落测试（VAL-005/006/008/009）
#   negative     负向/RUL 检测率测试（§17.2/§19）
#   random       constrained random baseline（§35）
#   stress       大量事务压力测试（§36）
#   regression   全回归（full tier = smoke+feature+corner+negative+random+stress）
#   cov          收集覆盖率
#   clean        清理产物
#
# 由 vip_tool.py regression 调用：make -C self_test <target>
# 支持仿真器：SIM ?= vcs（可改为 xrun）
# =============================================================================

# ---- 仿真器选择 ----
SIM       ?= vcs

# ---- UVM ----
UVM_HOME  ?= $(VCS_HOME)/etc/uvm-1.2
UVM_OPTS  ?= -ntb_opts uvm-1.2

# ---- 目录（中间产物统一入 build/，由根 .gitignore 忽略）----
SRC_DIR   := ../src
TB_DIR    := .
SIM_DIR   ?= build
LOG_DIR   ?= build/logs

# ---- 编译文件 ----
FILELIST  := filelist.f
TOP       := axi4_smoke_tb

# ---- 工具 ----
PY        ?= uv run python

.PHONY: all unit compile smoke feature corner negative random stress regression full cov clean

all: unit compile

# =============================================================================
# L1 Unit Test（G2 门禁一部分：compile + unit PASS；无 UVM 启动、golden vector）
# 全部路径相对本 Makefile 解析（子 shell 内 cd unit_test 只影响 incdir 基准）
# =============================================================================
unit:
	@echo "=== RUN axi4 L1 unit test (semantic/memory/transaction) ==="
	mkdir -p $(SIM_DIR)/unit $(LOG_DIR)
	cd ../unit_test && vcs -sverilog -full64 -timescale=1ns/1ps -ntb_opts uvm-1.2 \
		+incdir+../src +incdir+../src/transaction \
		+incdir+../src/agent +incdir+../src/sequences \
		+incdir+../src/coverage +incdir+../src/checker \
		+incdir+../src/env \
		-f filelist.f -o ../self_test/$(SIM_DIR)/unit/simv > ../self_test/$(LOG_DIR)/unit_compile.log 2>&1 || \
		( cat ../self_test/$(LOG_DIR)/unit_compile.log; exit 1 )
	$(SIM_DIR)/unit/simv -l $(LOG_DIR)/unit_test.log > /dev/null 2>&1 || true
	@grep -q "UNIT_TEST_PASS" $(LOG_DIR)/unit_test.log && \
		grep -E "UNIT_TEST_SUMMARY" $(LOG_DIR)/unit_test.log || \
		( echo "FAIL: unit_test（见 $(LOG_DIR)/unit_test.log）"; grep "FAILED:" $(LOG_DIR)/unit_test.log; exit 1 )
	@echo "PASS: unit_test"

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
	@# 统一中间产物到 build/（VCS 在当前目录生成 csrc/ucli.key/vc_hdrs.h）
	@mv -f csrc $(SIM_DIR)/csrc 2>/dev/null || true
	@mv -f ucli.key vc_hdrs.h $(SIM_DIR)/ 2>/dev/null || true
else ifeq ($(SIM),xrun)
	xrun -sv -timescale 1ns/1ps \
		+incdir+$(SRC_DIR) +incdir+$(SRC_DIR)/transaction \
		+incdir+$(SRC_DIR)/agent +incdir+$(SRC_DIR)/sequences \
		+incdir+$(SRC_DIR)/coverage +incdir+$(SRC_DIR)/checker \
		+incdir+$(SRC_DIR)/env +incdir+. \
		-f $(FILELIST) -l $(LOG_DIR)/compile.log
else
	@echo "ERROR: 未支持的仿真器 SIM=$(SIM)（vcs/xrun）"
	@exit 1
endif

# =============================================================================
# 仿真（smoke / feature / corner / negative / random / stress / full 分层）
# =============================================================================
smoke: compile
	@echo "=== RUN axi4 smoke ==="
	$(MAKE) _sim_run UVM_TESTNAME=axi4_smoke_test ALLOW_ERRORS=0

feature: compile
	@echo "=== RUN axi4 feature ==="
	$(MAKE) _sim_run UVM_TESTNAME=axi4_feature_test ALLOW_ERRORS=0

corner: compile
	@echo "=== RUN axi4 corner ==="
	$(MAKE) _sim_run UVM_TESTNAME=axi4_corner_test ALLOW_ERRORS=1

negative: compile
	@echo "=== RUN axi4 negative ==="
	$(MAKE) _sim_run UVM_TESTNAME=axi4_negative_test ALLOW_ERRORS=4

random: compile
	@echo "=== RUN axi4 random ==="
	$(MAKE) _sim_run UVM_TESTNAME=axi4_random_test ALLOW_ERRORS=0

stress: compile
	@echo "=== RUN axi4 stress ==="
	$(MAKE) _sim_run UVM_TESTNAME=axi4_stress_test ALLOW_ERRORS=0

# error tier：时序注入（early-WLAST/unstable payload）→ UVM_ERROR 为预期检出，
# 阈值判定（MIN_ERRORS）：实际检出数 ≥ MIN_ERRORS 且 test 内 report_phase 校验无超限
error: compile
	@echo "=== RUN axi4 error (timing injection) ==="
	$(MAKE) _sim_run_min UVM_TESTNAME=axi4_error_test MIN_ERRORS=2

regression: full

# full = 6 tier 稳定回归；error tier（RUL-017 monitor 对账）调试中，独立 target：
#   make -C self_test error   # NOT_RUN 状态：检出路径待 monitor 重建调试（run_log S08）
full: compile
	@echo "=== RUN axi4 full regression (6 tests) ==="
	$(MAKE) _sim_run UVM_TESTNAME=axi4_smoke_test ALLOW_ERRORS=0
	$(MAKE) _sim_run UVM_TESTNAME=axi4_feature_test ALLOW_ERRORS=0
	$(MAKE) _sim_run UVM_TESTNAME=axi4_corner_test ALLOW_ERRORS=1
	$(MAKE) _sim_run UVM_TESTNAME=axi4_negative_test ALLOW_ERRORS=4
	$(MAKE) _sim_run UVM_TESTNAME=axi4_random_test ALLOW_ERRORS=0
	$(MAKE) _sim_run UVM_TESTNAME=axi4_stress_test ALLOW_ERRORS=0

# 单测试运行入口（make _sim_run UVM_TESTNAME=<name> ALLOW_ERRORS=<expected>）
# 判定：UVM_ERROR 计数 == ALLOW_ERRORS 且 UVM_FATAL == 0 → PASS
# （corner/negative 为负向注入测试，预期违规数由 ALLOW_ERRORS 显式声明）
_sim_run:
	mkdir -p $(LOG_DIR)
	$(SIM_DIR)/simv +UVM_TESTNAME=$(UVM_TESTNAME) \
		-l $(LOG_DIR)/$(UVM_TESTNAME).log +ntb_random_seed=1
	@errs=$$(grep -oE "UVM_ERROR : *[0-9]+" $(LOG_DIR)/$(UVM_TESTNAME).log | grep -oE "[0-9]+" | tail -1); \
	fatals=$$(grep -oE "UVM_FATAL : *[0-9]+" $(LOG_DIR)/$(UVM_TESTNAME).log | grep -oE "[0-9]+" | tail -1); \
	if [ "$$fatals" != "0" ] || [ "$$errs" != "$(ALLOW_ERRORS)" ]; then \
		echo "FAIL: $(UVM_TESTNAME) (UVM_ERROR=$$errs expected=$(ALLOW_ERRORS) UVM_FATAL=$$fatals, 详见 $(LOG_DIR)/$(UVM_TESTNAME).log)"; \
		exit 1; \
	fi; \
	echo "PASS: $(UVM_TESTNAME) (UVM_ERROR=$$errs == expected=$(ALLOW_ERRORS))"

# 阈值判定入口（error tier：时序注入检出数 ≥ MIN_ERRORS 即 PASS；精确上限由测试内 report_phase 校验）
_sim_run_min:
	mkdir -p $(LOG_DIR)
	$(SIM_DIR)/simv +UVM_TESTNAME=$(UVM_TESTNAME) \
		-l $(LOG_DIR)/$(UVM_TESTNAME).log +ntb_random_seed=1
	@errs=$$(grep -oE "UVM_ERROR : *[0-9]+" $(LOG_DIR)/$(UVM_TESTNAME).log | grep -oE "[0-9]+" | tail -1); \
	fatals=$$(grep -oE "UVM_FATAL : *[0-9]+" $(LOG_DIR)/$(UVM_TESTNAME).log | grep -oE "[0-9]+" | tail -1); \
	if [ "$$fatals" != "0" ] || [ "$$errs" -lt "$(MIN_ERRORS)" ]; then \
		echo "FAIL: $(UVM_TESTNAME) (UVM_ERROR=$$errs < MIN=$(MIN_ERRORS) UVM_FATAL=$$fatals, 详见 $(LOG_DIR)/$(UVM_TESTNAME).log)"; \
		exit 1; \
	fi; \
	echo "PASS: $(UVM_TESTNAME) (UVM_ERROR=$$errs >= MIN=$(MIN_ERRORS))"

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
