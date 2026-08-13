# HAC-IF VIP User Guide

## 快速开始

```systemverilog
// 在 TB 中创建 HAC-IF 环境
hac_if_env env;
env = hac_if_env::type_id::create("env", this);
// 配置 Profile
env.m_cfg.profile = hac_if_pkg::HAC_P2;
env.m_cfg.has_ctrl = 1;
env.m_cfg.has_mem   = 1;
env.m_cfg.has_event = 1;
```

## 模式选择

- `ACTIVE_CORE`：驱动 Core 侧（发起任务命令、访存请求）；
- `ACTIVE_SHELL`：驱动 Shell 侧（responder，返回完成/响应）；
- `PASSIVE`：仅采样。

## 运行虚拟序列

```systemverilog
hac_virtual_sequence seq;
seq = hac_virtual_sequence::type_id::create("seq");
seq.start(env.m_vseqr);
```

## 依赖

- HWIF `aix:interface:hac_if:0.1.0`（类型与接口）；
- `aix:vip:common:^1.0`；
- AXI Adapter 一致性环境可选依赖 `aixsilicon:cbb:hac_axi_adapter` + `aix:vip:axi`。
