# TVIP-AXI Smoke Test Makefile
# 用于验证 TVIP-AXI 引入后的基本功能

TVIP_AXI_HOME := $(shell pwd)/../upstream
TUE_HOME := $(TVIP_AXI_HOME)/tue
TVIP_COMMON_HOME := $(TVIP_AXI_HOME)/tvip-common

export TVIP_AXI_HOME
export TUE_HOME
export TVIP_COMMON_HOME

# VCS 编译选项
VCS_ARGS := -full64 -lca -sverilog -timescale=1ns/1ps
VCS_ARGS += -ntb_opts uvm-1.2
VCS_ARGS += +define+UVM_NO_DEPRECATED+UVM_OBJECT_MUST_HAVE_CONSTRUCTOR
VCS_ARGS += -top top
VCS_ARGS += -l compile.log

# 仿真选项
SIMV_ARGS := -l simv.log +ntb_random_seed_automatic

# 文件列表
FILE_LISTS := $(TUE_HOME)/compile.f
FILE_LISTS += $(TVIP_COMMON_HOME)/compile.f
FILE_LISTS += $(TVIP_AXI_HOME)/compile.f
FILE_LISTS += $(TVIP_AXI_HOME)/sample/env/compile.f

# 源文件
SOURCE_FILES := $(TVIP_AXI_HOME)/sample/env/tvip_axi_sample_delay.sv
SOURCE_FILES += $(TVIP_AXI_HOME)/sample/env/top.sv

# 测试用例
TESTS := default request_delay response_delay ready_delay out_of_order_response read_interleave

.PHONY: all compile sim clean $(TESTS)

all: compile $(TESTS)

compile:
	@echo "=== Compiling TVIP-AXI ==="
	vcs $(VCS_ARGS) $(addprefix -f , $(FILE_LISTS)) $(SOURCE_FILES)

$(TESTS): compile
	@echo "=== Running test: $@ ==="
	@mkdir -p $@
	@cd $@ && ../simv $(SIMV_ARGS) -f ../$(TVIP_AXI_HOME)/sample/work/$@/test.f

clean:
	rm -rf simv* csrc *.log *.key *.vpd *.fsdb DVEfiles verdiLog
	rm -rf $(TESTS)
