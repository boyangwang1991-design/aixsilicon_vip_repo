"""Repair the Suite scaffold core using the actual ordered source/include contract."""
from pathlib import Path
import re,yaml
r=Path(__file__).resolve().parents[1]
rtl=['src/ahb_types_pkg.sv','src/ahb_if.sv','src/ahb_pkg.sv','src/checker/ahb_assertions.sv','src/classic/ahb_arbiter.sv']
for name in re.findall(r'`include "([^"]+)"',(r/'src/ahb_pkg.sv').read_text()):
    if name=='uvm_macros.svh':continue
    rtl.append({'src/'+name:{'is_include_file':True,'include_path':'src'}})
filesets={'rtl':{'files':rtl,'file_type':'systemVerilogSource'}}
targets={'default':{'filesets':['rtl']}}
options={'vcs':{'vcs_options':['-full64','-ntb_opts','uvm-1.2','-timescale=1ns/1ps'],'run_options':['-no_save']}}
for tier,top in {'smoke':'ahb_smoke_tb','vectors':'ahb_vectors_tb','negative':'ahb_negative_tb','extensions':'ahb_extensions_tb','scenarios':'ahb_scenarios_tb','classic':'ahb_classic_tb','classic_agent':'ahb_classic_agent_tb','ral':'ahb_ral_tb','system':'ahb_system_tb','widths':'ahb_widths_tb'}.items():
    files=['self_test/tb/'+top+'.sv']
    if tier=='smoke':files.insert(0,{'self_test/tb/ahb_smoke_env.sv':{'is_include_file':True,'include_path':'self_test/tb'}})
    filesets[tier]={'files':files,'file_type':'systemVerilogSource'}
    targets[tier]={'default_tool':'vcs','filesets':['rtl',tier],'toplevel':top,'tools':options}
unit_files=[{str(p.relative_to(r)):{'is_include_file':True,'include_path':'unit_test'}} for p in sorted((r/'unit_test').glob('*.sv')) if p.name!='ahb_unit_tb.sv']+['unit_test/ahb_unit_tb.sv']
filesets['unit']={'files':unit_files,'file_type':'systemVerilogSource'}
targets['unit_sim']={'default_tool':'vcs','filesets':['rtl','unit'],'toplevel':'ahb_unit_tb','tools':options}
# Regression target runs the independent cycle vectors; the full command matrix lives in Makefile.
targets['regression']={**targets['vectors'],'description':'Independent waveform regression; use make full for complete development matrix'}
core={'name':'aixsilicon:vip:ahb:0.1.0','description':'AHB VIP development candidate; see reports for qualification state','filesets':filesets,'targets':targets}
path=r/'aixsilicon_vip_ahb_0.1.0.core';path.write_text('CAPI=2:\n'+yaml.safe_dump(core,sort_keys=False));print(path)
