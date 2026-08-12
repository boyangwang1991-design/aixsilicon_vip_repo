# APB VIP User Guide

## 快速接入

```systemverilog
// 1. 例化接口并连接 DUT
apb_if u_apb_if (.pclk(pclk), .presetn(presetn), .psel(psel),
                 .penable(penable), .paddr(paddr), .pwrite(pwrite),
                 .pwdata(pwdata), .prdata(prdata), .pready(pready),
                 .pslverr(pslverr));

// 2. 配置 config object
apb_config cfg = apb_config::type_id::create("cfg");
cfg.mode = vip_common_pkg::VIP_ACTIVE_MASTER;
uvm_config_db#(apb_config)::set(this, "env.apb_agent", "cfg", cfg);
uvm_config_db#(virtual apb_if)::set(this, "env.apb_agent.*", "vif", u_apb_if);

// 3. 连接 agent 的 analysis port 到 scoreboard/coverage
```

## 在 UVM 环境中装配

```systemverilog
// env 中创建 agent
apb_agent apb0 = apb_agent::type_id::create("apb0", this);
```

## Sequence 使用

```systemverilog
apb_read_seq  rd;  apb_write_seq wr;
// base / normal / stress / negative 序列见 seq/ 目录
```

## 生成新 VIP 模板

复制本目录并全局重命名 `apb_*` → `<vip>_*`，修改 VLNV 与 metadata。
