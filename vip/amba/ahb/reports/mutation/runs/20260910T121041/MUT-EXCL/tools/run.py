"""Reproducible AHB development regression; success requires explicit oracles."""
import argparse, hashlib, json, os, re, shutil, subprocess, time
from pathlib import Path
import yaml
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('tier',choices=['unit','smoke','vectors','negative','extensions','full','compile','burst','error','reset','stress','classic','ral','widths','classic_agent','system']);p.add_argument('--seed',type=int,default=1);p.add_argument('--wait',type=int,default=0);p.add_argument('--count',type=int,default=1000);p.add_argument('--sim',choices=['vcs','xrun'],default='vcs');args=p.parse_args()
logs=ROOT/'reports/logs';logs.mkdir(parents=True,exist_ok=True)
summary={'timestamp':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),'seed':args.seed,'tool':args.sim,'cases':[]}
summary['source_fingerprint']=hashlib.sha256(b''.join(str(f.relative_to(ROOT)).encode()+f.read_bytes() for folder in ('src','unit_test','self_test/tb','config') for f in sorted((ROOT/folder).rglob('*')) if f.is_file() and f.suffix in ('.sv','.yaml','.json','.f'))).hexdigest()
summary['run_id']=time.strftime('%Y%m%dT%H%M%S',time.gmtime())+'-'+summary['source_fingerprint'][:8]
logs=logs/summary['run_id'];logs.mkdir()
summary['config_fingerprint']=hashlib.sha256(json.dumps({'seed':args.seed,'wait':args.wait,'tier':args.tier,'count':args.count},sort_keys=True).encode()).hexdigest()
def call(command,cwd,path):
    started=time.monotonic()
    with path.open('w') as f:
        try:r=subprocess.run(command,cwd=cwd,stdout=f,stderr=subprocess.STDOUT,timeout=180);code=r.returncode
        except (OSError,subprocess.TimeoutExpired) as e:f.write(str(e));code=124
    return code,path.read_text(errors='replace'),time.monotonic()-started
if args.sim!='vcs':
    (ROOT/'reports/portability.yaml').write_text(yaml.safe_dump({'status':'NOT_RUN','tool':args.sim,'reason':'xrun is not installed/qualified in this environment'}))
    raise SystemExit(10)
version=subprocess.run(['vcs','-ID'],capture_output=True,text=True,errors='replace',timeout=30).stdout if args.sim=='vcs' else 'NOT_RUN'
summary['tool_version']=version
cases=['unit','vectors','smoke','negative','extensions','burst','error','reset','classic','ral','widths','classic_agent','system'] if args.tier=='full' else [args.tier]
for tier in cases:
    target='smoke' if tier=='compile' else 'scenarios' if tier in ('burst','error','reset','stress') else tier
    cwd=ROOT/('unit_test' if target=='unit' else 'self_test');build=ROOT/'self_test/build/current'/target;build.mkdir(parents=True,exist_ok=True)
    top={'unit':'ahb_unit_tb','smoke':'ahb_smoke_tb','vectors':'ahb_vectors_tb','negative':'ahb_negative_tb','extensions':'ahb_extensions_tb','scenarios':'ahb_scenarios_tb','classic':'ahb_classic_tb','ral':'ahb_ral_tb','widths':'ahb_widths_tb','classic_agent':'ahb_classic_agent_tb','system':'ahb_system_tb'}[target]
    filelist='filelist.f' if target in ('unit','smoke') else target+'.f'
    command=['vcs','-full64','-sverilog','-ntb_opts','uvm-1.2','-timescale=1ns/1ps','-f',filelist,'-top',top,'-Mdir='+str(build/'csrc'),'-o',str(build/'simv')]
    rec={'tier':tier,'seed':args.seed,'wait':args.wait,'command':command,'compile_log':str(logs.relative_to(ROOT)/f'{target}_compile.log')}
    code,text,elapsed=call(command,cwd,logs/f'{target}_compile.log');rec['compile_exit']=code;rec['compile_seconds']=elapsed
    rec['status']='PASS' if code==0 else 'BLOCKED' if 'Failed to obtain license' in text or code==124 else 'FAIL'
    if code==0 and tier!='compile':
        logfile=logs/f'{tier}_s{args.seed}_w{args.wait}.log'
        command=[str(build/'simv'),'-no_save',f'+ntb_random_seed={args.seed}',f'+WAIT={args.wait}',f'+CASE={tier}',f'+COUNT={args.count}']
        code,text,elapsed=call(command,ROOT,logfile)
        oracle={'unit':'UNIT_TEST_PASS','smoke':'AHB_TEST_PASS','vectors':'AHB_VECTOR_PASS','negative':'AHB_NEGATIVE_PASS','extensions':'AHB_EXTENSIONS_PASS','burst':'AHB_SCENARIO_PASS','error':'AHB_SCENARIO_PASS','reset':'AHB_SCENARIO_PASS','stress':'AHB_SCENARIO_PASS','classic':'AHB_CLASSIC_PASS','ral':'AHB_RAL_PASS','widths':'AHB_WIDTHS_PASS','classic_agent':'AHB_CLASSIC_AGENT_PASS','system':'AHB_SYSTEM_PASS'}[tier]
        bad=bool(re.search(r'UVM_(?:ERROR|FATAL)\s*:\s*[1-9]|^UVM_(?:ERROR|FATAL)\s+(?!:)\S|^Error:|^Fatal:|FAILED:',text,re.M))
        rec.update(run_command=command,run_exit=code,run_seconds=elapsed,log=str(logfile.relative_to(ROOT)),oracle=oracle,status='PASS' if code==0 and oracle in text and not bad else 'FAIL')
        if 'Failed to obtain license' in text:rec['status']='BLOCKED'
    summary['cases'].append(rec);print(tier,rec['status'],flush=True)
    if rec['status']!='PASS': print(text[-5000:],flush=True)
summary['status']='PASS' if all(c['status']=='PASS' for c in summary['cases']) else 'FAIL'
report=ROOT/'reports/regression'/f'{args.tier}_s{args.seed}_w{args.wait}.yaml';report.parent.mkdir(exist_ok=True);report.write_text(yaml.safe_dump(summary,sort_keys=False))
raise SystemExit(0 if summary['status']=='PASS' else 1)
