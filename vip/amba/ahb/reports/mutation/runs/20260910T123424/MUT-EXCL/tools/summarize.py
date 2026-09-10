"""Aggregate observed evidence without turning missing acceptance into a PASS."""
from pathlib import Path
from datetime import datetime, timezone
import collections
import re
import yaml

root = Path(__file__).resolve().parents[1]
reports = root / 'reports'
full = yaml.safe_load((reports / 'regression/full_s1_w0.yaml').read_text())
contract = yaml.safe_load((root / 'config/regression.yaml').read_text())
now = datetime.now(timezone.utc).isoformat()
rtm = (root / 'docs/rtm.md').read_text()
rows = [line.split('|') for line in rtm.splitlines() if line.startswith('| AHB-')]
ids = [r[1].strip() for r in rows]
original = [r['id'] for r in yaml.safe_load((root / 'config/requirements.yaml').read_text())['requirements']]
assert ids == original and len(set(ids)) == 169
states = {r[1].strip(): r[5].strip() for r in rows}
counts = dict(collections.Counter(states.values()))
summary = {'schema_version': '1.0', 'generated_at': now, 'tier': 'full', 'required_tiers': contract['required_tiers'], 'seed': full['seed'], 'config_fingerprint': full['config_fingerprint'], 'source_fingerprint': full['source_fingerprint'], 'tools': {'vcs': full['tool_version'], 'second_commercial': 'NOT_RUN', 'IEEE1800.2': 'NOT_RUN'}, 'unit': {'status': next(c['status'] for c in full['cases'] if c['tier'] == 'unit'), 'evidence': 'reports/regression/full_s1_w0.yaml'}, 'development_regression': {'status': full['status'], 'cases': len(full['cases']), 'evidence': 'reports/regression/full_s1_w0.yaml'}, 'regression': {'status': 'NOT_RUN', 'evidence': 'reports/regression/full_s1_w0.yaml', 'reason': 'Full contract requires missing implementation, feature isolation, coverage and portability acceptance; development full is not the contract full.'}, 'requirements': {'total': 169, 'states': counts, 'evidence': 'docs/rtm.md'}}
for name, filename in [('stress', 'stress_s1_w0.yaml'), ('fixed_seed_witnesses', 'seed_matrix.yaml')]:
    path = reports / 'regression' / filename
    if path.exists():
        value = yaml.safe_load(path.read_text())
        summary[name] = {'status': value['status'], 'source_matches_development': value['source_fingerprint'] == full['source_fingerprint'], 'evidence': str(path.relative_to(root)), 'note': value.get('scope', 'See individual oracle, count and RSS; this is not a leak proof')}
        if name == 'stress':
            summary[name].update({k: value['cases'][0][k] for k in ('effective_beats', 'peak_rss_kib', 'run_seconds') if k in value['cases'][0]})
(reports / 'regression/regression_summary.yaml').write_text(yaml.safe_dump(summary, sort_keys=False))

observations = []
warnings = []
for case in full['cases']:
    if 'log' in case:
        for instance, bin_id, hits in re.findall(r'AHB_BIN instance=(\S+) id=(\S+) hits=(\d+)', (root / case['log']).read_text()):
            observations.append({'run_id': full['run_id'], 'tier': case['tier'], 'instance': instance, 'id': bin_id, 'hits': int(hits)})
    compile_text = (root / case['compile_log']).read_text()
    for code in re.findall(r'Warning-\[([^]]+)\]', compile_text):
        warnings.append({'tier': case['tier'], 'code': code, 'log': case['compile_log']})
(reports / 'coverage/observed_bins.yaml').write_text(yaml.safe_dump({'scope': 'Per-run/tier/instance observations, no denominator or cross-config percentage inferred', 'source_fingerprint': full['source_fingerprint'], 'bins': observations}, sort_keys=False))
holes = [{'id': rid, 'mandatory': True, 'status': 'OPEN', 'reason': 'Full acceptance not closed; see RTM row'} for rid, state in states.items() if state != 'PASS']
cov = {'schema_version': '1.0', 'generated_at': now, 'run_ids': [full['run_id']], 'config_fingerprint': full['config_fingerprint'], 'source_fingerprint': full['source_fingerprint'], 'metrics': {'requirement_coverage': {'value': round(100 * counts.get('PASS', 0) / 169, 3), 'status': 'FAIL', 'definition': 'Fully accepted requirement IDs / 169; not source-code coverage'}, **{n: {'value': None, 'status': 'NOT_RUN', 'reason': 'Complete mandatory bin denominator / coverage database not yet available'} for n in ('feature_coverage', 'cross_coverage', 'assertion_coverage')}}, 'contract_thresholds': {'mandatory_function_bins': 100, 'mandatory_cross_bins': 100}, 'observed_bins': 'reports/coverage/observed_bins.yaml', 'holes': holes}
(reports / 'coverage/coverage_summary.yaml').write_text(yaml.safe_dump(cov, sort_keys=False))
(reports / 'coverage/hole_analysis.md').write_text('# Coverage holes\n\n实际命中记录在 observed_bins.yaml，按运行、用例、实例分别保留，不把不同配置百分比取最大值当合并。\n\n强制扩展、经典仲裁、reset/phase、ERROR位置、exclusive干扰及完整性能统计模型尚未闭合。没有获批不可达项豁免。完整需求缺口逐条见 docs/rtm.md；机器报告保留所有非PASS项。\n')
(reports / 'compile_warning_review.yaml').write_text(yaml.safe_dump({'generated_at': now, 'source_fingerprint': full['source_fingerprint'], 'warnings': warnings, 'status': 'PASS' if not warnings else 'NOT_RUN', 'scope': 'VCS compile warning scan, not a dedicated SV lint proof'}, sort_keys=False))
(reports / 'gate_status.md').write_text('''# AHB VIP — Gate Status

Gate PASS requires all predecessor gates PASS. Successful development evidence is listed separately; no implicit waiver.

| Gate | Status | Evidence |
| --- | --- | --- |
| G0 Requirement | NOT_RUN | docs/requirement.md; full legacy specification audit pending |
| G1 Architecture | NOT_RUN | docs/architecture.md; full-contract component scope not closed |
| G2 Code + Unit | NOT_RUN | reports/regression/full_s1_w0.yaml; development compile/unit pass, predecessor gates pending |
| G3 Self-Verification | NOT_RUN | reports/regression/regression_summary.yaml; full contract matrix not closed |
| G4 Coverage | FAIL | reports/coverage/coverage_summary.yaml; mandatory holes open |
| G5 Qualification | NOT_RUN | Run qualify --write after aggregation |
| G6 Release | NOT_RUN | No qualified release produced |
'''.replace('\n+', '\n'))
print({'development': full['status'], 'requirements': counts, 'observed_bins': len(observations), 'compile_warnings': len(warnings)})
