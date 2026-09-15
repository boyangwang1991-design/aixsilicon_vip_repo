# =============================================================================
# axi4_stream VIP Self Test Makefile
#
# 目标：
#   unit        L1 Unit Test（semantic/transaction/config/checker golden vectors）
#   compile     编译 VIP 库与 self-test 环境（生成可执行）
#   smoke       最小正向闭环（source -> register slice -> sink）
#   feature     限定符/多 key/数据模式/背压
#   corner      边界长度 / 无气泡连续 / 无 TLAST 连续流 / 长包
#   random      约束随机（固定 seed 可重放）
#   stress      压力（accepted beat 统计守恒、内存有界）
#   config      全部 ready policy 模式 / 语义 epoch
#   passive     PASSIVE 观测（REQ-MON-001）
#   mutation    源码变异实验（checker/scoreboard 检出能力）
#   regression  full tier（unit + 全部 feature 集）
#
# 全部编译/仿真中间产物与日志写入 BUILD_DIR/LOG_DIR（必须在 build/ 下）。
# 由 vip_tool.py regression 调用：make -C self_test <target> BUILD_DIR=.. LOG_DIR=.. SEED=..
# 仅支持 VCS/UVM 1.2；其他仿真器需先提供真实适配（缺支持记 BLOCKED）。
# =============================================================================

SIM       ?= vcs
ASSET_ROOT := $(abspath ..)
BUILD_DIR ?= $(ASSET_ROOT)/build/self_test
LOG_DIR   ?= $(BUILD_DIR)/logs
SEED      ?= 1
UVM_OPTS  ?= -ntb_opts uvm-1.2
INCLUDES  := $(foreach d,src src/transaction src/model src/agent src/sequences \
              src/coverage src/checker src/scoreboard src/env self_test/tb \
              self_test/tb,+incdir+$(ASSET_ROOT)/$(d))

TESTS := smoke feature corner random stress config passive reset perf cancel sched

# 负向 tier：必须命中“预期告警”。按 REQ-ERR-002，预期告警缺失才失败，
# 已解释的预期告警不算失败；另外出现未解释的额外告警同样失败。
NEG_TIERS := inject
# 允许出现的规则（预期告警白名单，含注入目标与连带告警）
NEG_ALLOWED := AXIS-P003 AXIS-P004 AXIS-P004-DATA AXIS-P004-KEEP AXIS-P004-STRB \
	AXIS-P004-LAST AXIS-P004-ID AXIS-P005

.PHONY: all prepare check_dirs unit compile checker_only $(TESTS) cdc mutation regression \
	structural coverage seed_matrix _sim_run clean

all: unit compile

prepare:
	@test "$(SIM)" = vcs || (echo 'BLOCKED: this template supports only VCS'; exit 10)
	@case "$(abspath $(BUILD_DIR))/" in */build/*) ;; *) echo 'BUILD_DIR must be under build'; exit 2;; esac
	@case "$(abspath $(LOG_DIR))/" in */build/*) ;; *) echo 'LOG_DIR must be under build'; exit 2;; esac
	@mkdir -p $(BUILD_DIR)/unit $(BUILD_DIR)/smoke $(LOG_DIR)
	@test -d "$(ASSET_ROOT)/src" || (echo 'ASSET_ROOT/src missing'; exit 2)

# ---------------------------------------------------------------------------
# 生成 build 内的绝对路径 filelist（编译 CWD 保持在 build，源仓不被写入）
# ---------------------------------------------------------------------------
$(BUILD_DIR)/unit/filelist.f: $(ASSET_ROOT)/unit_test/filelist.f | prepare
	@sed 's|\.\./|$(ASSET_ROOT)/|g' $(ASSET_ROOT)/unit_test/filelist.f > $@

$(BUILD_DIR)/smoke/filelist.f: $(ASSET_ROOT)/self_test/filelist.f | prepare
	@sed 's|\.\./|$(ASSET_ROOT)/|g' $(ASSET_ROOT)/self_test/filelist.f > $@

# ---------------------------------------------------------------------------
# L1 Unit Test（无 UVM 启动；golden vector 断言）
# ---------------------------------------------------------------------------
unit: $(BUILD_DIR)/unit/filelist.f
	cd $(BUILD_DIR)/unit && vcs -sverilog -full64 -timescale=1ns/1ps $(UVM_OPTS) \
		-f filelist.f -Mdir=csrc -o simv > $(LOG_DIR)/unit_compile.log 2>&1
	cd $(BUILD_DIR)/unit && ./simv -no_save +ntb_random_seed=$(SEED) -l $(LOG_DIR)/unit_test.log
	@grep -q 'UNIT_TEST_PASS' $(LOG_DIR)/unit_test.log && \
	 ! grep -q 'UNIT_TEST_FAIL' $(LOG_DIR)/unit_test.log && \
	 ! grep -q '^FAILED:' $(LOG_DIR)/unit_test.log
	@echo VIP_RUN_SEED=$(SEED)

# ---------------------------------------------------------------------------
# 编译 self-test 环境
# ---------------------------------------------------------------------------
compile: $(BUILD_DIR)/smoke/filelist.f
	cd $(BUILD_DIR)/smoke && vcs -sverilog -full64 -timescale=1ns/1ps $(UVM_OPTS) \
		$(INCLUDES) -f filelist.f -Mdir=csrc -o simv > $(LOG_DIR)/compile.log 2>&1

# ---------------------------------------------------------------------------
# CHECKER_ONLY：不依赖 UVM package、不启动驱动线程（REQ-SCP-005）
# ---------------------------------------------------------------------------
checker_only: prepare
	cd $(BUILD_DIR)/smoke && vcs -sverilog -full64 -timescale=1ns/1ps \
		+incdir+$(ASSET_ROOT)/src \
		$(ASSET_ROOT)/src/axi4_stream_types_pkg.sv \
		$(ASSET_ROOT)/src/axi4_stream_if.sv \
		$(ASSET_ROOT)/src/checker/axi4_stream_assertions.sv \
		$(ASSET_ROOT)/self_test/tb/axi4_stream_checker_only_tb.sv \
		-Mdir=csrc_co -o simv_co > $(LOG_DIR)/checker_only_compile.log 2>&1
	cd $(BUILD_DIR)/smoke && ./simv_co -no_save -l $(LOG_DIR)/checker_only.log
	@grep -q 'AXIS_CHECKER_ONLY_PASS' $(LOG_DIR)/checker_only.log && \
	 ! grep -q 'AXIS_CHECKER_ONLY_FAIL' $(LOG_DIR)/checker_only.log
	@echo VIP_RUN_SEED=$(SEED)

# ---------------------------------------------------------------------------
# 各测试 tier
# ---------------------------------------------------------------------------
$(TESTS): compile
	$(MAKE) _sim_run UVM_TESTNAME=axi4_stream_$@_test

# 负向 tier：断言模式 + 额外告警检查
$(NEG_TIERS): compile
	$(MAKE) _neg_run UVM_TESTNAME=axi4_stream_$@_test

# CDC tier：使用异步 FIFO DUT 与双时钟/双复位（REQ-RST-005）
cdc: compile
	$(MAKE) _sim_run_opt UVM_TESTNAME=axi4_stream_cdc_test PLUSARGS="+DUT=cdc"

_sim_run:
	$(MAKE) _sim_run_opt UVM_TESTNAME=$(UVM_TESTNAME) \
		PLUSARGS="+AXIS_COV_FILE=$(LOG_DIR)/cov_$(UVM_TESTNAME).txt"""

_sim_run_opt:
	cd $(BUILD_DIR)/smoke && ./simv -no_save +UVM_TESTNAME=$(UVM_TESTNAME) \
		+ntb_random_seed=$(SEED) +AXIS_SEED=$(SEED) $(PLUSARGS) -l $(LOG_DIR)/$(UVM_TESTNAME).log
	@ok=0; \
	 grep -q 'AXIS_.*_PASS' $(LOG_DIR)/$(UVM_TESTNAME).log && ok=1; \
	 test $$ok = 1
	@errs=$$(grep -oE 'UVM_ERROR : *[0-9]+' $(LOG_DIR)/$(UVM_TESTNAME).log | grep -oE '[0-9]+' | tail -1); \
	 fatals=$$(grep -oE 'UVM_FATAL : *[0-9]+' $(LOG_DIR)/$(UVM_TESTNAME).log | grep -oE '[0-9]+' | tail -1); \
	 test "$$errs" = 0 && test "$$fatals" = 0
	@echo VIP_RUN_SEED=$(SEED)

# ---------------------------------------------------------------------------
# 负向 tier 判定（REQ-ERR-002）
#   1) 必须打印 AXIS_*_PASS（由测试自身核对预期命中）
#   2) 无 UVM_FATAL
#   3) 出现的规则必须全部在 NEG_ALLOWED 白名单内（无未解释额外告警）
# ---------------------------------------------------------------------------
_neg_run:
	cd $(BUILD_DIR)/smoke && ./simv -no_save +UVM_TESTNAME=$(UVM_TESTNAME) \
		+ntb_random_seed=$(SEED) +AXIS_SEED=$(SEED) \
		+AXIS_COV_FILE=$(LOG_DIR)/cov_$(UVM_TESTNAME).txt -l $(LOG_DIR)/$(UVM_TESTNAME).log
	@ok=0; \
	 grep -q 'AXIS_.*_PASS' $(LOG_DIR)/$(UVM_TESTNAME).log && ok=1; \
	 test $$ok = 1
	@fatals=$$(grep -oE 'UVM_FATAL : *[0-9]+' $(LOG_DIR)/$(UVM_TESTNAME).log | grep -oE '[0-9]+' | tail -1); \
	 test "$$fatals" = 0
	@rules=$$(grep -oE 'AXIS-(P|A|W|C|I)[0-9]{3}(-[A-Z]+)?' $(LOG_DIR)/$(UVM_TESTNAME).log | sort -u); \
	 allow=" $(NEG_ALLOWED) "; \
	 for r in $$rules; do \
	   case "$$allow" in *" $$r "*) ;; *) echo "UNEXPECTED_WARNING: $$r"; exit 1;; esac; \
	 done; \
	 echo "负向 tier 预期告警白名单校验通过：$$rules"
	@echo VIP_RUN_SEED=$(SEED)

# ---------------------------------------------------------------------------
# 源码变异实验（在 build 内的隔离副本执行；源仓不被修改）
# ---------------------------------------------------------------------------
# RUN_ROOT = <VIP根>/build/<run-id>；由 LOG_DIR（=RUN_ROOT/logs）推导，
# 与 vip_tool regression 传入的 BUILD_DIR（=RUN_ROOT/work/build）区分开。
MUT_RUN_ROOT ?= $(abspath $(LOG_DIR))/..

mutation: prepare
	uv run --no-sync python ../tools/mutate.py --build-dir $(MUT_RUN_ROOT) --log-dir $(LOG_DIR) \
		--seed $(SEED) > $(LOG_DIR)/mutation.log 2>&1
	@tail -20 $(LOG_DIR)/mutation.log

# ---------------------------------------------------------------------------
# 静态结构检查（REQ-CHK-004：黑盒 SVA 无法证明的项用结构检查补充）
# ---------------------------------------------------------------------------
structural: prepare
	uv run --no-sync python ../tools/structural_check.py --log-dir $(LOG_DIR)

# ---------------------------------------------------------------------------
# 多 seed 矩阵（REQ-ACC-005：核心合法场景 >= 20 个固定 seed）
# ---------------------------------------------------------------------------
SEED_TIERS ?= smoke feature corner
seed_matrix: prepare
	uv run --no-sync python ../tools/seed_matrix.py --vip-root $(ASSET_ROOT) \
		--build-dir $(MUT_RUN_ROOT) --log-dir $(LOG_DIR) \
		--tiers "$(SEED_TIERS)" --seeds 20 --seed-start 1

regression: unit
	$(MAKE) $(TESTS) SEED=$(SEED)
	$(MAKE) $(NEG_TIERS) SEED=$(SEED)
	$(MAKE) cdc SEED=$(SEED)
	$(MAKE) structural
	$(MAKE) mutation SEED=$(SEED)
	$(MAKE) seed_matrix SEED=$(SEED)
	@echo VIP_RUN_SEED=$(SEED)

clean:
	rm -rf $(BUILD_DIR)
