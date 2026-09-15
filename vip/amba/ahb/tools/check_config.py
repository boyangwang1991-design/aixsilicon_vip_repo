"""Validate public YAML profiles and authoritative requirement identity preservation."""
from pathlib import Path
import hashlib,json,re
import jsonschema,yaml
from output import run_root
RUN=run_root()
root=Path(__file__).resolve().parents[1]
profiles=yaml.safe_load((root/'config/profiles.yaml').read_text())
jsonschema.validate(profiles,json.loads((root/'config/profile.schema.json').read_text()))
for name,c in profiles['profiles'].items():
    if c['protocol']!='AHB5' and (any(c[k] for k in ('secure','exclusive','strobe','parity')) or c['prot_width']==7):raise ValueError(name+': profile/features')
    if c['user_data_width']>c['data_width']//2:raise ValueError(name+': USER data width')
    if c['issue']!='C' and (c['addr_width']!=32 or c['burst_width']!=3 or c['strobe'] or c['parity'] or c['user_resp_width']):raise ValueError(name+': issue compatibility')
    if (c['protocol']=='AHB_CLASSIC')!=(c['issue']=='A'):raise ValueError(name+': classic issue')
ids=re.findall(r'^\| (AHB-[A-Z]+-\d{3}) \|',(root/'docs/contract.md').read_text(),re.M)
actual=[r['id'] for r in yaml.safe_load((root/'config/requirements.yaml').read_text())['requirements']]
assert len(ids)==len(set(ids))==169 and actual==ids
result={'status':'PASS','profiles':{k:hashlib.sha256(json.dumps(v,sort_keys=True,separators=(',',':')).encode()).hexdigest() for k,v in profiles['profiles'].items()},'requirements':len(ids)}
(RUN/'evidence/config_check.yaml').write_text(yaml.safe_dump(result));print(result)
