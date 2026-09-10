# Protocol rule matrix

Primary source: [Arm IHI0033C](https://documentation-service.arm.com/static/6141bf0d674a052ae36ca811).
Classic source located: [IHI0011A](https://documentation-service.arm.com/static/5f916403f86e16515cdc3d71), full rule audit pending. B.b source review pending.

Stable executable registry: config/checkers.yaml. Conditions and observed signals are the corresponding branch in src/checker/ahb_checker.sv. No Classic/B.b conformance inferred from the Issue C rows.

Wait exception and response rules use independent vectors. Parity groups include tail widths and all named Issue C groups; group-specific negative qualification remains required. Environment watchdog and capability policy are classified separately.
