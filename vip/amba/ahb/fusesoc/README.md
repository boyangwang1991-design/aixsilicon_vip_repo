# FuseSoC 集成

稳定构建输入为 config/build.yaml，记录 filesets、targets 和 unit_runner。使用当前 vip-development-suite 的 gen-core，在冻结输入自己的 build/run-id/core 中生成 core 与源码快照。类文件按 include 规则组织，不能重复编译。

从 build 内运行 FuseSoC，并显式把其 --build-root 设置到同次运行的 work 子目录；生成 core、编译产物及日志不回写源码根。归档 core 不是当前源仓已认证或已发布的证明。
