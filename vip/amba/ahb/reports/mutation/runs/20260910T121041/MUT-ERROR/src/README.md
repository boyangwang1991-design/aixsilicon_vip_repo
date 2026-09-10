# AHB source layout

Compile ahb_types_pkg.sv, ahb_if.sv, then ahb_pkg.sv. Class sources below transaction/agent/checker/model/coverage/sequences/scoreboard/ral/env are included by the package and must not be compiled as independent files. ahb_assertions.sv and classic/ahb_arbiter.sv are standalone modules.

See ../docs/user-guide.md for supported APIs and ../docs/rtm.md for actual requirement closure. A source file alone is not qualification evidence.
