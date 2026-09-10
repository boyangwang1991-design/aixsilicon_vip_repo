# AHB VIP — Gate Status

Gate PASS requires all predecessor gates PASS. Successful development evidence is listed separately; no implicit waiver.

| Gate | Status | Evidence |
| --- | --- | --- |
| G0 Requirement | NOT_RUN | docs/requirement.md; full legacy specification audit pending |
| G1 Architecture | NOT_RUN | docs/architecture.md; full-contract component scope not closed |
| G2 Code + Unit | NOT_RUN | reports/regression/full_s1_w0.yaml; development compile/unit pass, predecessor gates pending |
| G3 Self-Verification | NOT_RUN | reports/regression/regression_summary.yaml; full contract matrix not closed |
| G4 Coverage | FAIL | reports/coverage/coverage_summary.yaml; mandatory holes open |
| G5 Qualification | **FAIL** | [qualification_summary.yaml](qualification_summary.yaml) |
| G6 Release | NOT_RUN | No qualified release produced |
