# Examples

The minimal runnable UVM environment is self_test/tb/ahb_smoke_tb.sv and ahb_smoke_env.sv. Run `make -C self_test smoke`. Mixed structural parameter types and all Issue C extensions are demonstrated by self_test/tb/ahb_extensions_tb.sv. RAL integration is in self_test/tb/ahb_ral_tb.sv. All clocks/resets are owned by the example, never by the agent.
