# AHB VIP user guide

# 1. Introduction
Development implementation of the AHB contract in `../ahb_contract.md`. Version 0.1.0 is a development candidate; it is not a qualified V1.0 release. Exact acceptance state is in `rtm.md` and `../reports/gate_status.md`.

# 2. Supported Capabilities
Manager Active, Subordinate Active, Passive and Disabled UVM agents; Lite and AHB5 pipeline, bursts, wait/error/reset; byte-addressable memory, security region policy, exclusive reservations, strobe and four USER phases; Issue C parity groups; standalone assertions; classical arbitration and RETRY/SPLIT retry policy. The implementation and tests are distinct from complete protocol/profile qualification.

# 3. Package Contents
`src/` source; `unit_test/` independent object/algorithm checks; `self_test/` directed/component/system benches; `config/` profiles/requirements/rules/acceptance; `examples/` minimal entry; `reports/` execution evidence and skill feedback; `.core` packaging.

# 4. Dependencies
SystemVerilog/UVM1.2 and VCS, GNU make; Python tools use the enclosing workflow's uv environment with PyYAML/jsonschema. No separate virtual environment is needed. Public assets have no private DUT hierarchy dependency. Commercial tool locations come from the environment.

# 5. Build and Compile
From this VIP directory:

```bash
make -C self_test smoke
make -C self_test full
uv run --no-sync python tools/run.py smoke --wait 3
uv run --no-sync python tools/run.py stress --seed 42 --count 5000
uv run --no-sync python tools/check_config.py
uv run --no-sync python tools/mutate.py
```

The development `full` executable set is not the larger contract full-acceptance denominator in config/regression.yaml. A missing simulator is NOT_RUN, never implicitly replaced by another simulator. Each run requires a completion oracle, zero unexpected UVM errors/fatals and process success. Compilation and runtime license access may require execution-environment permission.

Compilation order: `ahb_types_pkg.sv`, `ahb_if.sv`, `ahb_pkg.sv`, standalone assertion/arbiter modules, then the chosen testbench. Class `.sv` files are includes, not independent compilation units.

# 6. DUT Interface Connection
Instantiate `ahb_if #(AW,DW,BW,PW,MW,AU,DU,RU,PROFILE,SECURE,EXCLUSIVE,STROBE,PARITY)` with an external HCLK/HRESETn. Parameter positions match `ahb_agent` and `ahb_monitor`. PROFILE is 0 Lite, 1 AHB5, 2 Classic.

Manager drives address/control and write data. Subordinate drives HREADYOUT/response/read data. The environment supplies HREADY from the **data-phase** target mux, and HSEL from address decoding. The self-test 4×4 example explicitly registers data-phase selection. Never select data response using the current address HSEL. Classic HMASTER/HMASTLOCK are supplied by the arbiter; Master 0 in the reference arbiter is reserved for default IDLE ownership.

Clocking blocks use input `#1step` and output `#0` at posedge. Examples release reset on negedge. Passive agents have no output task. Optional zero-width ports use internal one-bit placeholders; disabled features have fixed semantic defaults. The current basic attribute-bin labels include these defaults; full capability-based bin pruning is not yet implemented. The existing HWIF Lite contract is incomplete for this input scope; no full HWIF binding compatibility is claimed.

# 8. Basic Configuration
Create `ahb_config` with factory, set its widths/features to match the physical interface and `mode`, then provide config_db entries before build:

```systemverilog
uvm_config_db#(ahb_config)::set(this,"manager*","cfg",cfg);
uvm_config_db#(virtual ahb_if)::set(null,"uvm_test_top.manager*","vif",bus);
```

The vif type must use exactly the same structural parameters. See `ahb_extensions_tb.sv` for 17-bit address/128-bit data AHB5 coexisting with 32-bit Lite. Changing an agent's path is supported; paths are supplied by the environment. Runtime responder `min_wait/max_wait/error_*` policy is sampled when an address is accepted. Structural profile, width, presence and endian configuration is frozen at agent build. A later mutation is diagnosed at the next sample with AHB-CONFIG-FROZEN.

# 11. Sending Transactions
Extend `ahb_base_seq`, start it on `agent.sequencer`. `submit(item)` queues a request; UVM `get_response(response)` waits for completion. `transfer(item,response)` combines them. `write(addr,data,size)` and `read(addr,data,size)` use bus-lane formatted data. `burst_transfer(first,length,responses)` submits a burst and collects responses. Data fields are 1024-bit containers; only the configured lanes participate.

`ahb_item` carries addr/write/size/burst/prot/lock/nonsecure/exclusive/master/auser/wuser/strobe/trans/tag. `raw=1` bypasses transaction validation for deliberate injection; normal traffic uses `raw=0`. `trans` is IDLE=0/BUSY=1/NONSEQ=2/SEQ=3. Response distinguishes ERROR, EXCLUSIVE_FAIL, RESET_ABORT, WATCHDOG, CANCEL_BEFORE_ACCEPT, RETRY and SPLIT from OKAY. `response` preserves actual HRESP separately.

Burst helper crosses a 1KB boundary only by starting a new NONSEQ for finite INCR requests; fixed bursts that cross are rejected. It does not silently repair arbitrary raw requests. Exclusive pairs use single-beat requests and a data-phase HEXOKAY result. Completed response objects preserve UVM sequence/transaction identity.

# 18. Response and Device Customization
Inject `ahb_response_policy` via config_db key `policy` on the subordinate driver. Override `select_response(item,waits,response)` or use scripted queues. `ahb_region_policy` additionally checks address, direction, privilege and security; overlapping regions require distinct priorities.

Inject `ahb_memory` using config_db key `memory`. `peek/poke/load/dump`, sparse 64-bit addressing, explicit initialization validity, INIT_X/ZERO/CONSTANT/ADDRESS/RANDOM policies and reservation invalidation are available. `ahb_register_memory` demonstrates read-clear/W1C/RO/WO, and `ahb_fifo_memory` demonstrates completion-time FIFO effects. Reads never pop/clear during waits. Failed writes do not commit by default. Device-specific error side effects require an explicit override.

Backdoor calls must be scheduled away from the bus sample/commit edge, for example at negedge, when deterministic same-cycle ordering is required. Multiple responders may share a memory handle; simultaneous conflicting commits currently follow simulation call order and are not qualified as a deterministic system conflict policy. Use serialized access or an environment-owned arbiter pending that qualification.

# 20. Passive Observation and Checking
The interface exposes nets; manual procedural stimulus must drive local variables connected with assign, as demonstrated by ahb_vectors_tb. Analysis subscribers must treat received objects as read-only and clone for editing; monitor deep copies protect its own state. `agent.monitor.transaction_ap` publishes completed/aborted beats, `request_ap` accepted addresses, `cycle_ap` sampled cycles, `error_ap` diagnostics and `burst_ap` bounded aggregate chunks. `history_limit` caps aggregation; `bounded_chunk` is a streaming chunk boundary, not protocol burst termination. Protocol-only mode cannot establish data integrity without independent observations/model initialization.

Rules are enumerated in config/checkers.yaml. Per-rule enable/severity and explicit waiver reason/expiry are configurable. Environment watchdog and DUT capability diagnostics are separate categories. Cycle watchdog does not progress if HCLK stops; each example also has an independent simulation-time watchdog.

# 25. Coverage
Covergroups are diagnostic views. `AHB_BIN` logs export exact bin IDs/hits and normal/error/abort categories; `AHB_STATS` reports completed beats, useful bytes and waits. Use compatible bin-set unions; never merge percentages by maximum. Mandatory contract coverage closure remains explicitly separate.

# 29. RAL Integration
Create `ahb_reg_adapter`, set `adapter.cfg`, attach it to a register map/manager sequencer, and connect monitor.transaction_ap to `ahb_reg_predictor.bus_in`. The predictor updates only confirmed successful completions. Sparse enables without HWSTRB are rejected; no implicit read-modify-write. See self_test/tb/ahb_ral_tb.sv for executable integration.

# 34. System Comparison
`ahb_bridge_scoreboard` has upstream/downstream analysis inputs. Supply `ahb_translation_policy` with widths, endian, address map, error fanout and attribute overrides. Each instance checks one ordered path. Missing/duplicate bytes remain queued and cause check_phase failure. USER transforms require an explicit override and opt-in comparison. Visibility beyond connected observation paths is not inferred.

# 37. Common Issues
A vif config_db type mismatch means physical and component parameters differ. Constant wait usually means HREADY was not connected to the data-phase response. Unknown first reads reflect the default INIT_X policy; preload memory or explicitly choose another policy. Missing UVM response can also mean the caller abandoned/terminated its sequence; accepted bus work must be drained or reset.

# 39. Machine-readable Metadata
Profiles and dependencies: config/profiles.yaml and profile.schema.json. Required acceptance: regression.yaml. Original IDs: requirements.yaml. Rule registry: checkers.yaml. Run manifests carry tool version, seed, configuration/source fingerprints and log paths.

# 41. Limitations
See requirement.md §23 and RTM for authoritative full-contract gaps. Cross-tool/IEEE1800.2 compatibility, complete per-profile 100-seed coverage, all mandatory crosses, all legal checker exceptions and system atomicity/exclusive visibility are not implied by smoke success. B.b/Classic source audits and protocol-specific distinctions require complete review before release. Same-cycle shared-memory conflicts, sequence kill/re-submit policies, full USER transform policies and all negative injection combinations need additional qualification. No automatic V1.0 release is performed.

# 42. Version Compatibility
0.1.0 is a local development candidate. No change is made to the supplied contract, existing APB/AXI assets, registry release state or catalog. API stability starts only after qualification/versioned release.

# 43. Reporting Issues
Provide profile YAML, simulator/UVM version, seed, source fingerprint, rule ID, command and the matching reports/logs run. Skill feedback is separately maintained in reports/skill-improvement-report.md.

# 45. User Guide Completion Checklist
Commands, actual APIs, roles, timing, models, independent observations, RAL and limitations are documented from the implementation.

# 46. Definition of User Guide Complete
A reproducible smoke and an explicit full-contract evidence state are required; this guide does not replace the RTM.
