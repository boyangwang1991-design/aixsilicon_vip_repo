# 架构文档

本目录存放 VIP Repository 总体架构与实现路线图文档。

> **设计与编码方法（六层架构、统一端口、ADR、代码规范）已收编到私有 skill
> [`vip-repo-maintainer`](../../../aixsilicon_skill_repo/skills/vip-repo-maintainer/references/repository-conventions.md)**
> （`references/repository-conventions.md` §8-§11），不再在仓库内重复维护。

## 目录

- [`roadmap.md`](roadmap.md) —— 实现路线图（阶段 0~6 与出口定义）

## 总体架构

```mermaid
flowchart TD
    DUT["IP / CBB / Subsystem / SoC"]
    IF["Interface Contract"]
    AGT["Protocol Agent"]
    SYS["System Service VIP"]
    CHK["Checker / Coverage / SVA"]
    COM["DV Common"]
    FLOW["FuseSoC + DV Flow"]

    IF --> DUT
    IF --> AGT
    COM --> AGT
    AGT --> DUT
    SYS --> DUT
    AGT --> CHK
    DUT --> CHK
    FLOW --> AGT
    FLOW --> CH
