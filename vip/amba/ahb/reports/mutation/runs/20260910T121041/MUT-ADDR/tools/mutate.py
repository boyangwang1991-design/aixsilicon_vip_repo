"""Run real source mutations in isolated copies; production source is never modified."""
from pathlib import Path
import argparse,hashlib,shutil,subprocess,time
import yaml
ROOT=Path(__file__).resolve().parents[1]
MUTATIONS=[
 ('MUT-ADDR','src/ahb_types_pkg.sv','step_bytes=64\'d1 << size;','step_bytes=64\'d2 << size;','unit','FAILED: wrap_'),
 ('MUT-PIPE','src/agent/ahb_monitor.sv','pending.data=pending.write?s.wdata:s.rdata;','pending.addr=s.address.addr; pending.data=pending.write?s.wdata:s.rdata;','vectors','FAILED: V01_data_association'),
 ('MUT-ERROR','src/checker/ahb_checker.sv','if(s.resp!=0 && s.ready===1 && !(previous!=null','if(0 && s.resp!=0 && s.ready===1 && !(previous!=null','negative','FAILED: expected AHB-CHECK-ERROR-TWO'),
 ('MUT-MASK','src/model/ahb_memory.sv',"mask=active_mask(t.addr,t.size,bus_bytes,endian)&t.strobe;\n    writes++;\n    for(int i=0;i<(1<<t.size);i++) begin","mask=t.strobe;\n    writes++;\n    for(int i=0;i<bus_bytes;i++) begin",'unit','FAILED: inactive_strobe'),
 ('MUT-EXCL','src/model/ahb_memory.sv','foreach(remove_ids[i]) reservations.delete(remove_ids[i]);','// mutation: omit invalidation','unit','FAILED: granule_invalidation'),
 ('MUT-PARITY','src/ahb_types_pkg.sv','result[i]=1;','result[i]=0;','unit','FAILED: parity_tail')]
parser=argparse.ArgumentParser();parser.add_argument('--case',default='all');a=parser.parse_args()
run_id=time.strftime('%Y%m%dT%H%M%S',time.gmtime());base=ROOT/'reports/mutation/runs'/run_id;base.mkdir(parents=True)
results=[]
for mid,filename,old,new,tier,oracle in MUTATIONS:
    if a.case not in ('all',mid):continue
    target=base/mid
    for folder in ('src','unit_test','self_test','config','tools'):
        shutil.copytree(ROOT/folder,target/folder,ignore=shutil.ignore_patterns('build','csrc','simv*','__pycache__','*.log','ucli.key'))
    f=target/filename;text=f.read_text();assert text.count(old)==1,(mid,text.count(old));f.write_text(text.replace(old,new))
    command=['uv','run','--no-sync','python',str(target/'tools/run.py'),tier]
    log=base/f'{mid}.log'
    with log.open('w') as output:
        proc=subprocess.run(command,cwd=ROOT,stdout=output,stderr=subprocess.STDOUT,timeout=400)
    reports=list((target/'reports/regression').glob('*.yaml'))
    report=yaml.safe_load(reports[0].read_text()) if reports else {}
    case=report.get('cases',[{}])[0];runlog=target/case.get('log','absent.log')
    contents=runlog.read_text(errors='replace') if runlog.is_file() else ''
    detected=case.get('compile_exit')==0 and case.get('run_exit') is not None and oracle in contents
    entry={'id':mid,'priority':'P0','required':True,'status':'PASS' if detected else 'FAIL','plan_ref':'docs/validation-plan.md#19-violation--mutation-validation','source_ref':filename,'evidence':str(log.relative_to(ROOT)),'test_log':str(runlog.relative_to(ROOT)),'expected_failure':oracle,'command':command}
    results.append(entry);print(mid,entry['status'],flush=True)
summary={'schema_version':'1.0','generated_at':run_id,'cases':results,'source_fingerprint':hashlib.sha256(b''.join(f.read_bytes() for f in sorted((ROOT/'src').rglob('*.sv')))).hexdigest()}
(ROOT/'reports/mutation/mutation_summary.yaml').write_text(yaml.safe_dump(summary,sort_keys=False))
raise SystemExit(0 if results and all(r['status']=='PASS' for r in results) else 1)
