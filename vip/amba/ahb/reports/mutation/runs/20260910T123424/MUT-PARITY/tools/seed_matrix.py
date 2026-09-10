"""Run already compiled profile witnesses at 100 fixed seeds; keep every log.

This does not replace feature-isolation or functional coverage acceptance.
Run tools/run.py full immediately before this command; binaries must match it.
"""
import concurrent.futures
import hashlib
import re
import subprocess
import time
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
baseline = yaml.safe_load((ROOT / 'reports/regression/full_s1_w0.yaml').read_text())
assert baseline['status'] == 'PASS'
fingerprint = hashlib.sha256(b''.join(str(f.relative_to(ROOT)).encode()+f.read_bytes() for folder in ('src','unit_test','self_test/tb','config') for f in sorted((ROOT/folder).rglob('*')) if f.is_file() and f.suffix in ('.sv','.yaml','.json','.f'))).hexdigest()
assert fingerprint == baseline['source_fingerprint'], 'Rebuild full regression first'
run_id = time.strftime('%Y%m%dT%H%M%S', time.gmtime())
logdir = ROOT / 'reports/logs' / ('seeds-' + run_id)
logdir.mkdir()
profiles = {'lite32': ('smoke', 'AHB_TEST_PASS'), 'ahb5_128': ('extensions', 'AHB_EXTENSIONS_PASS'), 'classic32': ('classic_agent', 'AHB_CLASSIC_AGENT_PASS')}


def run(job):
    profile, seed = job
    target, oracle = profiles[profile]
    logfile = logdir / f'{profile}_s{seed}.log'
    binary = next(arg for c in baseline['cases'] if c['tier'] == target for arg in c['run_command'] if arg.endswith('/simv'))
    command = [binary, '-no_save', f'+ntb_random_seed={seed}']
    started = time.monotonic()
    with logfile.open('w') as stream:
        try:
            code = subprocess.run(command, cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT, timeout=60).returncode
        except subprocess.TimeoutExpired:
            code = 124
    output = logfile.read_text(errors='replace')
    bad = re.search(r'UVM_(?:ERROR|FATAL)\s*:\s*[1-9]|^UVM_(?:ERROR|FATAL)\s+(?!:)\S|^Error:|^Fatal:|FAILED:', output, re.M)
    return {'profile': profile, 'seed': seed, 'status': 'PASS' if code == 0 and oracle in output and not bad else 'FAIL', 'exit': code, 'seconds': time.monotonic()-started, 'command': command, 'log': str(logfile.relative_to(ROOT))}


cases = []
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
    for result in pool.map(run, [(p, s) for p in profiles for s in range(1, 101)]):
        cases.append(result)
        if result['seed'] % 20 == 0 or result['status'] != 'PASS':
            print(result['profile'], result['seed'], result['status'], flush=True)
summary = {'status': 'PASS' if all(c['status'] == 'PASS' for c in cases) else 'FAIL', 'run_id': run_id, 'source_fingerprint': fingerprint, 'tool_version': baseline['tool_version'], 'baseline': 'reports/regression/full_s1_w0.yaml', 'scope': '100 fixed-seed executions of each profile witness; directed tests, not full per-profile feature closure', 'cases': cases}
(ROOT / 'reports/regression/seed_matrix.yaml').write_text(yaml.safe_dump(summary, sort_keys=False))
raise SystemExit(0 if summary['status'] == 'PASS' else 1)
