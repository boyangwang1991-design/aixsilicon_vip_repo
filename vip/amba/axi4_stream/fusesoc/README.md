# FuseSoC 构建说明

通过 suite 的 gen-core 生成 RUN_ROOT/core 下的 core 和源码快照；显式指定 run-id。生成物只在本 VIP 的 build，不写源码根、不上传。本目录只保存构建说明，复杂 filesets/targets 配置位于 config/build.yaml。
