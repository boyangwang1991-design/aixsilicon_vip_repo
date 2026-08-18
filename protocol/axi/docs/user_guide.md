# AXI VIP 用户指南

## 概述

AIXSILICON AXI VIP 是基于 TVIP-AXI 引入的 AXI4/AXI4-Lite 协议验证 IP。采用 overlay 策略，保持上游代码完整性，同时提供本地扩展能力。

## 快速开始

### 编译

```bash
cd tests/
make compile
```

### 运行测试

```bash
# 运行默认测试
make default

# 运行所有测试
make all

# 运行特定测试
make request_delay
make response_delay
```

## 目录结构

```
protocol/axi/
├── upstream/              # 上游 TVIP-AXI 代码（只读）
│   ├── src/               # VIP 源码
│   ├── sample/            # 示例环境
│   ├── tue/               # UVM 扩展库
│   └── tvip-common/       # VIP 通用库
├── aixsilicon/            # 本地适配与扩展
├── tests/                 # 测试用例
├── docs/                  # 文档
├── metadata/              # 元数据
│   ├── vip.yaml           # VIP 配置
│   ├── provenance.yaml    # 来源记录
│   └── sbom.spdx.json     # SBOM
├── NOTICE                 # 版权声明
├── aix_vip_axi_1.0.0.core # FuseSoC Core
└── README.md
```

## 功能特性

### 支持的协议

- AXI4（完整功能）
- AXI4-Lite

### Agent 类型

- **Master Agent**：发起读写事务
- **Slave Agent**：响应事务，支持可配置延迟
- **Passive Monitor**：被动监控总线活动

### 高级特性

- 可配置地址宽度、数据宽度、ID 宽度
- 支持延迟写数据和响应
- 支持间隙写数据和读响应
- 支持乱序响应
- 支持读交织
- 内置 UVM RAL adapter 和 predictor

## 配置示例

```systemverilog
tvip_axi_configuration cfg = new();
cfg.address_width = 32;
cfg.data_width = 64;
cfg.id_width = 4;
cfg.support_out_of_order_response = 1;
cfg.support_read_interleave = 1;
```

## 仿真器支持

| 仿真器 | 状态 | 备注 |
|---|---|---|
| VCS | beta | 已验证 |
| Xcelium | beta | 需 `-warn_multiple_driver` |
| Questa | unsupported | - |
| Verilator | unsupported | - |

## 测试用例

| 用例 | 描述 |
|---|---|
| default | 基本读写测试 |
| request_delay | 延迟请求测试 |
| response_delay | 延迟响应测试 |
| ready_delay | Ready 信号延迟测试 |
| out_of_order_response | 乱序响应测试 |
| read_interleave | 读交织测试 |
| wvalid_preceding_awvalid | WVALID 先于 AWVALID 测试 |

## 已知限制

1. 尚未实现 Protocol Checker 的完整负向测试
2. 尚未与 PULP AXI 进行交叉验证
3. 尚未支持 exclusive/atomic 事务

## 参考

- [TVIP-AXI 上游仓库](https://github.com/taichi-ishitani/tvip-axi)
- ARM AMBA AXI Protocol Specification (IHI 0022)
