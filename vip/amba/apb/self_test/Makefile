# =============================================================================
# apb VIP Self Test Makefile（编译 + 仿真 + 回归 Toolkit）
#
# 目标：
#   unit         L1 Unit Test（types golden vectors，无 UVM）
#   compile      编译 VIP 库与 self-test 环境
#   smoke        最小正向事务（smoke tier，UT01/02）
#   feature      feature 测试（UT03/04/11/12）
#   corner       边界测试（UT05/06 wait）
#   error        错误场景（UT07 slverr / UT15 negative / anti-overcheck UT17/18）
#   random       constrained random baseline
#   regression   全回归
#   cov          覆盖率收集
#   clean        清理
#
# 由 vip_tool.py regression 调用：make -C self_test <target>
# 支持仿真器：SIM ?= vcs（xrun 预留）
# =============================================================================

SIM       ?= vcs
UVM_HOME  ?= $(VCS_HOME)/etc/uvm-1.2
UVM_OPTS  ?= -ntb_opts uvm-1.2

SRC_DIR   := ../src
TB_DIR    := .
SIM_DIR   ?= build
LOG_DIR   ?= build/logs

FILELIST  := filelist.f
TOP       := apb_smoke_tb

.PHONY: all unit compile smoke feature corner error random apb5 regression full cov cov_sweep clean

all: unit compile

# =============================================================================
# L1 Unit Test（G2 门禁一部分：compile + unit PASS）
# =============================================================================
unit:
	@echo "=== RUN apb L1 unit test (types + transaction + config golden vectors) ==="
	mkdir -p $(SIM_DIR)/unit $(LOG_DIR)
	cd ../unit_test && vcs -sverilog -full64 -timescale=1ns/1ps $(UVM_OPTS) \
		+incdir+../src \
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
	@echo "=== compile apb VIP self-test (SIM=$(SIM)) ==="
ifeq ($(SIM),vcs)
	vcs -sverilog -full64 -timescale=1ns/1ps $(UVM_OPTS) \
		+incdir+$(SRC_DIR) +incdir+$(SRC_DIR)/transaction \
		+incdir+$(SRC_DIR)/agent +incdir+$(SRC_DIR)/sequences \
		+incdir+$(SRC_DIR)/coverage +incdir+$(SRC_DIR)/checker \
		+incdir+$(SRC_DIR)/env +incdir+$(SRC_DIR)/ral +incdir+. \
		-f $(FILELIST) -o $(SIM_DIR)/simv
	@mv -f csrc $(SIM_DIR)/csrc 2>/dev/null || true
	@mv -f ucli.key vc_hdrs.h $(SIM_DIR)/ 2>/dev/null || true
else ifeq ($(SIM),xrun)
	@echo "xrun: NOT_RUN（预预留，ENG-001）"
endif

$(SIM_DIR):
	mkdir -p $(SIM_DIR) $(LOG_DIR)

# =============================================================================
# 回归 tier
# =============================================================================
smoke: compile
	@echo "=== RUN smoke（UT01/UT02 basic write/read）==="
	$(SIM_DIR)/simv +UVM_TESTNAME=apb_smoke_test +UVM_VERBOSITY=UVM_LOW \
		-l $(LOG_DIR)/smoke.log
	@grep -q "UVM_ERROR :    0" $(LOG_DIR)/smoke.log || \
		( echo "FAIL: smoke"; exit 1 )
	@echo "PASS: smoke"

feature: compile
	@echo "=== RUN feature（UT03/04/11/12）==="
	$(SIM_DIR)/simv +UVM_TESTNAME=apb_feature_test -l $(LOG_DIR)/feature.log
	@grep -q "UVM_ERROR :    0" $(LOG_DIR)/feature.log || ( echo "FAIL: feature"; exit 1 )
	@echo "PASS: feature"

corner: compile
	@echo "=== RUN corner（UT05/UT06 wait states）==="
	$(SIM_DIR)/simv +UVM_TESTNAME=apb_corner_test -l $(LOG_DIR)/corner.log
	@grep -q "UVM_ERROR :    0" $(LOG_DIR)/corner.log || ( echo "FAIL: corner"; exit 1 )
	@echo "PASS: corner"

error: compile
	@echo "=== RUN error（UT07/15 + anti-overcheck UT17/18）==="
	$(SIM_DIR)/simv +UVM_TESTNAME=apb_error_test -l $(LOG_DIR)/error.log
	@grep -q "UVM_ERROR :    0" $(LOG_DIR)/error.log || ( echo "FAIL: error"; exit 1 )
	@echo "PASS: error"

random: compile
	@echo "=== RUN random baseline ==="
	$(SIM_DIR)/simv +UVM_TESTNAME=apb_random_test +ntb_random_seed=1 -l $(LOG_DIR)/random.log
	@grep -q "UVM_ERROR :    0" $(LOG_DIR)/random.log || ( echo "FAIL: random"; exit 1 )
	@echo "PASS: random"

# ---------------------------------------------------------------------------
# APB5 专项（UT13/14/20/21）：独立编译 top=apb_smoke_tb5（HAS_PNSE/PWAKEUP/USER/CHK 全开）
# 独立 simv 避免与主 tb 的 run_test 冲突
# ---------------------------------------------------------------------------
apb5:
	@echo "=== compile+run APB5 专项（rme/user/wakeup/check，cp_pas 闭合）==="
	mkdir -p $(SIM_DIR)/apb5 $(LOG_DIR)
	vcs -sverilog -full64 -timescale=1ns/1ps $(UVM_OPTS) \
		+incdir+$(SRC_DIR) +incdir+$(SRC_DIR)/transaction \
		+incdir+$(SRC_DIR)/agent +incdir+$(SRC_DIR)/sequences \
		+incdir+$(SRC_DIR)/coverage +incdir+$(SRC_DIR)/checker \
		+incdir+$(SRC_DIR)/env +incdir+$(SRC_DIR)/ral +incdir+. \
		-f filelist_apb5.f -o $(SIM_DIR)/apb5/simv > $(LOG_DIR)/apb5_compile.log 2>&1 || \
		( cat $(LOG_DIR)/apb5_compile.log; exit 1 )
	$(SIM_DIR)/apb5/simv +UVM_TESTNAME=apb_apb5_test +UVM_VERBOSITY=UVM_LOW \
		+ntb_random_seed=1 -l $(LOG_DIR)/apb5.log
	@grep -q "UVM_ERROR :    0" $(LOG_DIR)/apb5.log || ( echo "FAIL: apb5"; grep "UVM_ERROR\|UVM_FATAL" $(LOG_DIR)/apb5.log | head; exit 1 )
	@echo "PASS: apb5"

cov_sweep: compile
	@echo "=== RUN coverage sweep（G4 专项：strb/prot/addr/slverr/reset-abort bins）==="
	$(SIM_DIR)/simv +UVM_TESTNAME=apb_cov_sweep_test +UVM_VERBOSITY=UVM_LOW \
		+ntb_reset_abort=1 -l $(LOG_DIR)/cov_sweep.log
	@grep -q "UVM_ERROR :    0" $(LOG_DIR)/cov_sweep.log || ( echo "FAIL: cov_sweep"; exit 1 )
	@echo "PASS: cov_sweep"

# FI / Mutation（G5）：检出判定——预期出现 SVA/CHK error；判定 FI_ALL_DETECTED
fi: compile
	@echo "=== RUN fault injection（FI-001..005 mutation）==="
	-$(SIM_DIR)/simv +UVM_TESTNAME=apb_fi_test -l $(LOG_DIR)/fi.log
	@grep -q "FI_ALL_DETECTED" $(LOG_DIR)/fi.log && \
		grep -E "FI_SUMMARY" $(LOG_DIR)/fi.log || \
		( echo "FAIL: fi（mutation 检出率<100%）"; grep "FI_SUMMARY" $(LOG_DIR)/fi.log; exit 1 )
	@echo "PASS: fi (mutation detection rate 100%)"

regression: smoke feature corner error random
	@echo "PASS: regression (all tiers)"

mutation: fi
	@echo "PASS: mutation"

full: unit regression
	@echo "PASS: full (unit + regression)"

# =============================================================================
# 覆盖率（G4）
#   cov       : 全 functional tier（smoke/feature/corner/error/random）采样 + merge + 汇总
#   （fi/mutation tier 不并入 G4 功能性覆盖——其目标是检测率，见 mutation target）
# =============================================================================
COV_OPTS := -cm line+cond+tgl+assert -cm_dir $(SIM_DIR)/cov
COV_TIERS := smoke feature corner error random sweep

cov: compile
	@echo "=== collect apb coverage (6 functional tier functional merge) ==="
	mkdir -p $(SIM_DIR)/cov $(LOG_DIR)
	@for t in $(COV_TIERS); do \
		echo "[$$t]"; \
		if [ "$$t" = "sweep" ]; then tn=apb_cov_sweep_test; extra="+ntb_reset_abort=1"; else tn=apb_$${t}_test; extra=""; fi; \
		$(SIM_DIR)/simv +UVM_TESTNAME=$$tn +UVM_VERBOSITY=UVM_LOW $$extra \
			$(COV_OPTS) -cm_name apb_cov_$${t} \
			-l $(LOG_DIR)/cov_$${t}.log || exit 1; \
	done
	@echo "=== 功能覆盖（各 tier 汇总，取自 sim log）==="
	@for t in $(COV_TIERS); do \
		echo "[$$t]"; \
		grep -E "\[APB_COV\]" $(LOG_DIR)/cov_$${t}.log | tail -16; \
	done
	@echo "G4 功能覆盖证据：$(LOG_DIR)/cov_<tier>.log（[APB_COV] 行）；urg 合并需 license"

clean:
	rm -rf $(SIM_DIR) csrc ucli.key vc_hdrs.h simv* *.log
